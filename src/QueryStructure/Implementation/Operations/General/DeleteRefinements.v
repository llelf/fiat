Require Import Coq.Strings.String Coq.omega.Omega Coq.Lists.List Coq.Logic.FunctionalExtensionality Coq.Sets.Ensembles
        ADTSynthesis.Common.List.ListFacts
        ADTSynthesis.Computation
        ADTSynthesis.ADT
        ADTSynthesis.ADTRefinement ADTSynthesis.ADTNotation
        ADTSynthesis.QueryStructure.Specification.Representation.Schema
        ADTSynthesis.QueryStructure.Specification.Representation.QueryStructureSchema
        ADTSynthesis.ADTRefinement.BuildADTRefinements
        ADTSynthesis.QueryStructure.Specification.Representation.QueryStructure
        ADTSynthesis.Common.Ensembles.IndexedEnsembles
        ADTSynthesis.QueryStructure.Specification.Operations.Query
        ADTSynthesis.QueryStructure.Specification.Operations.Delete
        ADTSynthesis.QueryStructure.Specification.Operations.Mutate
        ADTSynthesis.QueryStructure.Implementation.Constraints.ConstraintChecksRefinements
        ADTSynthesis.Common.IterateBoundedIndex
        ADTSynthesis.Common.DecideableEnsembles
        ADTSynthesis.Common.List.PermutationFacts
        ADTSynthesis.QueryStructure.Implementation.Operations.General.QueryRefinements
        ADTSynthesis.QueryStructure.Implementation.Operations.General.MutateRefinements
        ADTSynthesis.Common.Ensembles.EnsembleListEquivalence.

(* Facts about implements delete operations. *)

Section DeleteRefinements.

  Hint Resolve AC_eq_nth_In AC_eq_nth_NIn crossConstr.
  Hint Unfold SatisfiesCrossRelationConstraints
       SatisfiesAttributeConstraints
       SatisfiesTupleConstraints.

  Arguments GetUnConstrRelation : simpl never.
  Arguments UpdateUnConstrRelation : simpl never.
  Arguments replace_BoundedIndex : simpl never.
  Arguments BuildQueryStructureConstraints : simpl never.
  Arguments BuildQueryStructureConstraints' : simpl never.

  Local Transparent QSDelete.

  Definition QSDeletedTuples
             qsSchema (qs : UnConstrQueryStructure qsSchema )
             (Ridx : @BoundedString (map relName (qschemaSchemas qsSchema)))
             (DeletedTuples :
                Ensemble (@Tuple (schemaHeading (QSGetNRelSchema _ Ridx)))) :=
    (UnIndexedEnsembleListEquivalence
       (Intersection _
                     (GetUnConstrRelation qs Ridx)
                     (Complement _ (EnsembleDelete (GetUnConstrRelation qs Ridx) DeletedTuples)))).

  Lemma QSDeleteSpec_UnConstr_refine_AttributeConstraints :
    forall qsSchema (qs : UnConstrQueryStructure qsSchema )
           (Ridx : @BoundedString (map relName (qschemaSchemas qsSchema)))
           (DeletedTuples :
              Ensemble (@Tuple (schemaHeading (QSGetNRelSchema _ Ridx))))
           (or : QueryStructure qsSchema),
      DropQSConstraints_AbsR or qs ->
      refine
        {b : bool |
         (forall tup : IndexedTuple,
            GetUnConstrRelation qs Ridx tup ->
            SatisfiesAttributeConstraints Ridx (indexedElement tup)) ->
         decides b
                 (MutationPreservesAttributeConstraints
                    (EnsembleDelete (GetRelation or Ridx) DeletedTuples)
                    (SatisfiesAttributeConstraints Ridx))}
        (ret true).
  Proof.
    unfold MutationPreservesAttributeConstraints; intros * AbsR_or_qs v Comp_v.
    econstructor; intros; inversion_by computes_to_inv; subst; simpl; intros.
    unfold DropQSConstraints_AbsR in *; eapply H; inversion H0; subst;
    rewrite GetRelDropConstraints; eauto.
  Qed.

  Lemma QSDeleteSpec_UnConstr_refine_CrossConstraints' :
    forall qsSchema (qs : UnConstrQueryStructure qsSchema )
           (Ridx : @BoundedString (map relName (qschemaSchemas qsSchema)))
           (DeletedTuples :
              Ensemble (@Tuple (schemaHeading (QSGetNRelSchema _ Ridx))))
           (or : QueryStructure qsSchema),
      DropQSConstraints_AbsR or qs ->
  refine
   {b : bool |
   (forall Ridx' : BoundedString,
    Ridx' <> Ridx ->
    forall tup' : IndexedTuple,
    GetUnConstrRelation qs Ridx tup' ->
    SatisfiesCrossRelationConstraints Ridx Ridx' (indexedElement tup')
      (GetUnConstrRelation qs Ridx')) ->
   decides b
     (forall Ridx' : BoundedString,
      Ridx' <> Ridx ->
      MutationPreservesCrossConstraints
        (EnsembleDelete (GetRelation or Ridx) DeletedTuples)
        (GetUnConstrRelation qs Ridx')
        (SatisfiesCrossRelationConstraints Ridx Ridx'))}
   (ret true).
  Proof.
    unfold MutationPreservesCrossConstraints; intros * AbsR_or_qs v Comp_v.
    econstructor; intros; inversion_by computes_to_inv; subst; simpl; intros.
    unfold DropQSConstraints_AbsR in *; eapply H; inversion H1; subst; eauto.
    rewrite GetRelDropConstraints; eauto.
  Qed.

  Lemma QSDeleteSpec_UnConstr_refine_opt :
    forall qsSchema (qs : UnConstrQueryStructure qsSchema )
           (Ridx : @BoundedString (map relName (qschemaSchemas qsSchema)))
           (DeletedTuples :
              Ensemble (@Tuple (schemaHeading (QSGetNRelSchema _ Ridx))))
           (or : QueryStructure qsSchema),
      DropQSConstraints_AbsR or qs ->
      refine
        (or' <- (QSDelete {|qsHint := or |} Ridx DeletedTuples);
         nr' <- {nr' | DropQSConstraints_AbsR (fst or') nr'};
         ret (nr', snd or'))
        match (tupleConstraints (QSGetNRelSchema qsSchema Ridx)) with
          | Some tConstr =>
            tupleConstr <- {b | (forall tup tup',
                                   elementIndex tup <> elementIndex tup'
                                   -> GetUnConstrRelation qs Ridx tup
                                     -> GetUnConstrRelation qs Ridx tup'
                                     -> tConstr (indexedElement tup) (indexedElement tup'))
                                  -> decides b (MutationPreservesTupleConstraints
                                                  (EnsembleDelete (GetRelation or Ridx) DeletedTuples)                                               tConstr) };
              crossConstr <- (Iterate_Decide_Comp_opt'_Pre string
                                                       (map relName (qschemaSchemas qsSchema))
                                  []
                                  (fun
                                      Ridx' : BoundedIndex
                                                ([] ++
                                                    map relName (qschemaSchemas qsSchema)) =>
                                      if BoundedString_eq_dec Ridx Ridx'
                                      then None
                                      else
                                        match
                                          BuildQueryStructureConstraints qsSchema Ridx'
                                                                         Ridx
                                        with
                                          | Some CrossConstr =>
                                            Some
                                              ((MutationPreservesCrossConstraints
                                                  (GetUnConstrRelation qs Ridx')
                                                  (EnsembleDelete (GetRelation or Ridx) DeletedTuples)
                                                 CrossConstr))
                                          | None => None
                                        end)
                                  (@Iterate_Ensemble_BoundedIndex_filter
                                     _ (fun idx =>
                                          if (eq_nat_dec (ibound Ridx) idx)
                                          then false else true)
                                     (fun Ridx' =>
                                        forall tup',
                                          (GetUnConstrRelation qs Ridx') tup'
                                          -> SatisfiesCrossRelationConstraints
                                               Ridx' Ridx (indexedElement tup') (GetUnConstrRelation qs Ridx))));
              match tupleConstr, crossConstr with
                | true, true =>
                  deleted   <- Pick (QSDeletedTuples qs Ridx DeletedTuples);
                    ret (UpdateUnConstrRelation qs Ridx (EnsembleDelete (GetUnConstrRelation qs Ridx) DeletedTuples), deleted)
                | _, _  => ret (qs, [])
              end
          | None =>
              crossConstr <- (Iterate_Decide_Comp_opt'_Pre string
                                                       (map relName (qschemaSchemas qsSchema))
                                  []
                                  (fun
                                      Ridx' : BoundedIndex
                                                ([] ++
                                                    map relName (qschemaSchemas qsSchema)) =>
                                      if BoundedString_eq_dec Ridx Ridx'
                                      then None
                                      else
                                        match
                                          BuildQueryStructureConstraints qsSchema Ridx'
                                                                         Ridx
                                        with
                                          | Some CrossConstr =>
                                            Some
                                              ((MutationPreservesCrossConstraints
                                                  (GetUnConstrRelation qs Ridx')
                                                  (EnsembleDelete (GetRelation or Ridx) DeletedTuples)
                                                 CrossConstr))
                                          | None => None
                                        end)
                                  (@Iterate_Ensemble_BoundedIndex_filter
                                     _ (fun idx =>
                                          if (eq_nat_dec (ibound Ridx) idx)
                                          then false else true)
                                     (fun Ridx' =>
                                        forall tup',
                                          (GetUnConstrRelation qs Ridx') tup'
                                          -> SatisfiesCrossRelationConstraints
                                               Ridx' Ridx (indexedElement tup') (GetUnConstrRelation qs Ridx))));
              match crossConstr with
                | true  =>
                  deleted   <- Pick (QSDeletedTuples qs Ridx DeletedTuples);
                    ret (UpdateUnConstrRelation qs Ridx (EnsembleDelete (GetUnConstrRelation qs Ridx) DeletedTuples), deleted)
                | _ => ret (qs, [])
            end
        end.
  Proof.
    unfold QSDelete.
    intros; rewrite QSMutateSpec_UnConstr_refine;
    eauto using
          QSDeleteSpec_UnConstr_refine_AttributeConstraints,
    refine_SatisfiesTupleConstraintsMutate,
    refine_SatisfiesCrossConstraintsMutate,
    QSDeleteSpec_UnConstr_refine_CrossConstraints'.
    simplify with monad laws.
    unfold SatisfiesTupleConstraints.
    case_eq (tupleConstraints (QSGetNRelSchema qsSchema Ridx)); intros;
    [eapply refine_under_bind; intros
    | simplify with monad laws].
    simpl; unfold DropQSConstraints_AbsR, QSDeletedTuples in *; subst.
    f_equiv; unfold pointwise_relation; intros;
    repeat find_if_inside; try simplify with monad laws; try reflexivity.
    rewrite GetRelDropConstraints, get_update_unconstr_eq; f_equiv.
    f_equiv; unfold pointwise_relation; intros; eauto.
    simpl; unfold DropQSConstraints_AbsR, QSDeletedTuples in *; subst.
    repeat find_if_inside; try simplify with monad laws; try reflexivity.
    rewrite GetRelDropConstraints, get_update_unconstr_eq; f_equiv.
  Qed.

  Lemma EnsembleComplementIntersection {A}
  : forall E (P : Ensemble A),
      DecideableEnsemble P
      -> forall (a : @IndexedElement A),
           (In _ (Intersection _ E
                               (Complement _ (EnsembleDelete E P))) a
            <-> In _ (Intersection _ E
                                   (fun itup => P (indexedElement itup))) a).
  Proof.
    unfold EnsembleDelete, Complement, In in *; intuition;
    destruct H; constructor; eauto; unfold In in *.
    - case_eq (DecideableEnsembles.dec (indexedElement x)); intros.
      + eapply dec_decides_P; eauto.
      + exfalso; apply H0; constructor; unfold In; eauto.
        intros H'; apply dec_decides_P in H'; congruence.
    - intros H'; destruct H'; unfold In in *; eauto.
  Qed.

  Lemma DeletedTuplesIntersection {qsSchema}
  : forall (qs : UnConstrQueryStructure qsSchema)
           (Ridx : @BoundedString (map relName (qschemaSchemas qsSchema)))
           (P : Ensemble Tuple),
      DecideableEnsemble P
      -> refine {x | QSDeletedTuples qs Ridx P x}
                {x | UnIndexedEnsembleListEquivalence
                       (Intersection _ (GetUnConstrRelation qs Ridx)
                                     (fun itup => P (indexedElement itup))) x}.
  Proof.
    intros qs Ridx P P_dec v Comp_v; inversion_by computes_to_inv.
    constructor.
    unfold QSDeletedTuples, UnIndexedEnsembleListEquivalence in *; destruct_ex;
    intuition; subst.
    eexists; intuition.
    unfold EnsembleListEquivalence in *; intuition; eauto with typeclass_instances.
    + eapply H; eapply EnsembleComplementIntersection; eauto with typeclass_instances.
    + eapply EnsembleComplementIntersection; eauto with typeclass_instances.
      eapply H; eauto.
  Qed.

  Local Transparent Query_For.

  Lemma DeletedTuplesFor {qsSchema}
  : forall (qs : UnConstrQueryStructure qsSchema)
           (Ridx : @BoundedString (map relName (qschemaSchemas qsSchema)))
           (P : Ensemble Tuple),
      DecideableEnsemble P
      -> refine {x | QSDeletedTuples qs Ridx P x}
                (For (UnConstrQuery_In qs Ridx
                                       (fun tup => Where (P tup) Return tup))).
  Proof.
    intros qs Ridx P P_dec v Comp_v; rewrite DeletedTuplesIntersection by auto.
    constructor.
    unfold UnIndexedEnsembleListEquivalence.
    unfold Query_For in *; apply computes_to_inv in Comp_v; simpl in *;
    destruct Comp_v as [l [Comp_v Perm_l_v]].
    unfold UnConstrQuery_In, QueryResultComp in *; inversion_by computes_to_inv.
    remember (GetUnConstrRelation qs Ridx); clear Hequ.
    revert P_dec u v l Perm_l_v H1 H0; clear; induction x; simpl; intros.
    - inversion_by computes_to_inv; subst.
      exists (@nil (@IndexedTuple
                      (schemaHeading
                         (relSchema
                            (@nth_Bounded NamedSchema string relName
                                          (qschemaSchemas qsSchema) Ridx)))));
        simpl; split; eauto.
      rewrite Permutation_nil by eauto; reflexivity.
      + unfold EnsembleListEquivalence in *; intuition.
        * destruct H0; intuition.
          unfold In in H; inversion H; subst.
          apply H0 in H2.
          destruct x0; simpl in *; congruence.
        * constructor.
    - inversion_by computes_to_inv; subst.
      unfold UnConstrRelation in u.
      destruct H0 as [[ | [a' x']] [x_eq [equiv_u_x' NoDup_x']]];
        simpl in *; [discriminate | injection x_eq; intros x'_eq ?; subst; clear x_eq].
      case_eq (@DecideableEnsembles.dec _ P P_dec a); intros.
      + apply computes_to_inv in H1; simpl in *; intuition.
        apply dec_decides_P in H; apply H0 in H.
        apply computes_to_inv in H; simpl in *; subst; simpl in *.
        pose proof (PermutationConsSplit _ _ _ Perm_l_v); destruct_ex; subst.
        unfold UnIndexedEnsembleListEquivalence in *.
        destruct (H1 (fun x => u x /\ x <> {|indexedElement := a; elementIndex := a' |}) (app x x0) x1); intuition eauto.
        * eapply Permutation_cons_inv; rewrite Permutation_middle; eassumption.
        * unfold UnIndexedEnsembleListEquivalence in *; intuition.
          eexists; intuition; eauto.
          unfold In in *; intuition.
          apply equiv_u_x' in H4; destruct H4; subst; eauto; congruence.
          unfold In; intuition.
          apply equiv_u_x'; simpl; intuition.
          inversion NoDup_x'; subst; eauto.
          apply H7; apply in_map_iff; eexists; split; eauto; simpl; eauto.
          inversion NoDup_x'; subst; eauto.
        * symmetry in H4; pose proof (app_map_inv _ _ _ _ H4); destruct_ex;
          intuition; subst.
          eexists (app x3 ({|indexedElement := a; elementIndex := a' |} :: x4));
            simpl; rewrite map_app.
          { simpl; intuition.
            - destruct H5; unfold In in *; apply equiv_u_x' in H5; simpl in *; intuition.
              subst.
              apply in_or_app; simpl; intuition.
              assert (u x) as u_x by (apply equiv_u_x'; eauto).
              assert (List.In x (x3 ++ x4)) as In_x
                  by (apply H; constructor; unfold In; intuition; subst;
                      inversion NoDup_x'; subst; eapply H10; apply in_map_iff; eexists;
                      split; eauto; simpl; eauto).
              apply in_or_app; simpl; apply in_app_or in In_x; intuition.
            - unfold In.
              assert (List.In x (x3 ++ x4) \/ x = {|indexedElement := a; elementIndex := a' |})
                as In_x0
                  by (apply in_app_or in H5; simpl in H5; intuition).
              intuition.
              + apply H in H7; destruct H7; unfold In in *; intuition.
                constructor; eauto.
              + subst; constructor; eauto.
                apply equiv_u_x'; simpl; eauto.
                case_eq (@DecideableEnsembles.dec _ P P_dec a); intros.
                apply dec_decides_P; eauto.
                assert (~ P a) as H''
                    by (unfold not; intros H'; apply dec_decides_P in H'; congruence);
                apply H3 in H''; discriminate.
            - rewrite map_app; apply NoDup_app_swap; simpl; constructor; eauto.
              inversion NoDup_x'; subst; unfold not; intros; apply H8.
              rewrite <- map_app in H5; apply in_map_iff in H5; destruct_ex; intuition.
              assert (List.In x (x3 ++ x4)) as In_a by
                    (apply in_or_app; apply in_app_or in H10; intuition).
              apply H in In_a; destruct In_a; unfold In in *; intuition.
              apply equiv_u_x' in H12; simpl in *; intuition.
              destruct x; simpl in *; subst.
              apply in_map_iff; eexists; split; eauto; simpl; eauto.
              apply NoDup_app_swap; rewrite <- map_app; eauto.
          }
      + apply computes_to_inv in H1; simpl in *; intuition.
        assert (~ P a) as H''
                         by (unfold not; intros H'; apply dec_decides_P in H'; congruence);
          apply H3 in H''; subst.
        destruct (H1 (fun x => u x /\ x <> {|indexedElement := a; elementIndex := a' |}) v x1); intuition eauto.
        * eexists; intuition; eauto.
          unfold In in *; intuition.
          apply equiv_u_x' in H5; destruct H5; subst; eauto; congruence.
          unfold In; intuition.
          apply equiv_u_x'; simpl; intuition.
          inversion NoDup_x'; subst; eauto.
          apply H8; apply in_map_iff; eexists; split; eauto; simpl; eauto.
          inversion NoDup_x'; subst; eauto.
        * eexists; split; eauto.
          unfold UnIndexedEnsembleListEquivalence in *; intuition.
          destruct H6; intuition.
          eapply H4; constructor; unfold In in *; subst; intuition.
          subst; apply_in_hyp dec_decides_P; simpl in *; congruence.
          constructor;
            apply H4 in H6; destruct H6; unfold In in *; intuition.
  Qed.

End DeleteRefinements.

  Ltac RemoveDeleteFunctionalDependencyCheck :=
    match goal with
        |- context[{b | (forall tup tup',
                           elementIndex tup <> elementIndex tup'
                           -> GetUnConstrRelation ?qs ?Ridx tup
                           -> GetUnConstrRelation ?qs ?Ridx tup'
                           -> (FunctionalDependency_P ?attrlist1 ?attrlist2 (indexedElement tup) (indexedElement tup')))
                        -> decides b (Mutate.MutationPreservesTupleConstraints
                                        (EnsembleDelete (GetUnConstrRelation ?qs ?Ridx) ?DeletedTuples)
                                        (FunctionalDependency_P ?attrlist1 ?attrlist2)
                                     )}] =>
        let refinePK := fresh in
        pose proof (DeletePrimaryKeysOK qs Ridx DeletedTuples attrlist1 attrlist2) as refinePK;
          simpl in refinePK; setoid_rewrite refinePK; clear refinePK;
          try setoid_rewrite refineEquiv_bind_unit
    end.

  Ltac ImplementDeleteForeignKeysCheck :=
    match goal with
        [ |- context [{b' |
                       ?P ->
                       decides b'
                               (Mutate.MutationPreservesCrossConstraints
                                  (@GetUnConstrRelation ?qs_schema ?qs ?Ridx')
                                  (EnsembleDelete (GetUnConstrRelation ?qs ?Ridx) ?DeletedTuples)
                                  (ForeignKey_P ?attr' ?attr ?tupmap))}]]
        =>
        let refineFK := fresh in
        pose proof  (@DeleteForeignKeysCheck qs_schema qs Ridx Ridx' DeletedTuples
                                             _ attr attr' tupmap) as refineFK;
          simpl in refineFK; setoid_rewrite refineFK;
          [ clear refineFK; try simplify with monad laws
          | let tup := fresh "tup" in
            let tup' := fresh "tup'" in
            let tupAgree' := fresh "tupAgree'" in
            let tupIn := fresh "tupIn" in
            unfold tupleAgree; intros tup tup' tupAgree' tupIn;
            rewrite tupAgree' in *;
            [ eauto
            | simpl; intuition]
          | auto with typeclass_instances
          | clear; intuition
          | clear; simpl; intros; congruence ]
  end.

Tactic Notation "remove" "trivial" "deletion" "checks" :=
  repeat rewrite refineEquiv_bind_bind;
  etransitivity;
  [ repeat (apply refine_bind;
            [reflexivity
            | match goal with
                | |- context [Bind (Delete _ from _ where _)%QuerySpec _] =>
                  unfold pointwise_relation; intros
              end
           ] );
    (* Pull out the relation we're inserting into and then
     rewrite [QSInsertSpec] *)
    match goal with
        H : DropQSConstraints_AbsR ?r_o ?r_n
        |- context [QSDelete ?qs ?R ?P] =>
        (* If we try to eapply [QSInsertSpec_UnConstr_refine] directly
                   after we've drilled under a bind, this tactic will fail because
                   typeclass resolution breaks down. Generalizing and applying gets
                   around this problem for reasons unknown. *)
        let H' := fresh "H'" in
        pose proof (@QSDeleteSpec_UnConstr_refine_opt
                      _ r_n R P r_o H) as H';
          apply H'
    end
  | cbv beta; simpl tupleConstraints; simpl attrConstraints; cbv iota;
    simpl map; simpl app;
    simpl relName in *; simpl schemaHeading in *;
    pose_string_ids; simpl;
    simplify with monad laws;
    repeat rewrite <- GetRelDropConstraints;
    repeat match goal with
             | H : DropQSConstraints_AbsR ?qs ?uqs |- _ =>
               rewrite H in *
           end
  ].

Tactic Notation "drop" "constraints" "from" "delete" constr(methname) :=
  hone method methname;
  [ remove trivial deletion checks;
    (* Implement constraint checks. *)
    repeat
      first [RemoveDeleteFunctionalDependencyCheck
            | ImplementDeleteForeignKeysCheck
            | setoid_rewrite refine_trivial_if_then_else; simplify with monad laws];
    finish honing
  | ].