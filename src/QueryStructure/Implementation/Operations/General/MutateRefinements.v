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
        ADTSynthesis.QueryStructure.Specification.Operations.Mutate
        ADTSynthesis.QueryStructure.Implementation.Constraints.ConstraintChecksRefinements
        ADTSynthesis.Common.IterateBoundedIndex
        ADTSynthesis.Common.DecideableEnsembles
        ADTSynthesis.Common.List.PermutationFacts
        ADTSynthesis.QueryStructure.Implementation.Operations.General.QueryRefinements
        ADTSynthesis.Common.Ensembles.EnsembleListEquivalence.

(* Facts about implements delete operations. *)

Section MutateRefinements.

  Hint Resolve AC_eq_nth_In AC_eq_nth_NIn crossConstr.
  Hint Unfold SatisfiesCrossRelationConstraints
       SatisfiesAttributeConstraints
       SatisfiesTupleConstraints.

  Arguments GetUnConstrRelation : simpl never.
  Arguments UpdateUnConstrRelation : simpl never.
  Arguments replace_BoundedIndex : simpl never.
  Arguments BuildQueryStructureConstraints : simpl never.
  Arguments BuildQueryStructureConstraints' : simpl never.

  Program
    Definition Mutate_Valid
    (qsSchema : QueryStructureSchema)
    (qs : QueryStructure qsSchema)
    (Ridx : _)
    (MutatedTuples : @IndexedEnsemble (@Tuple (schemaHeading (QSGetNRelSchema _ Ridx))))
    (attrConstr :
       (forall tup : IndexedTuple,
         GetRelation qs Ridx tup
         -> SatisfiesAttributeConstraints Ridx (indexedElement tup))
       -> MutationPreservesAttributeConstraints MutatedTuples (SatisfiesAttributeConstraints Ridx))
    (tupConstr :
       (forall tup tup' : IndexedTuple,
          elementIndex tup <> elementIndex tup'
          -> GetRelation qs Ridx tup
          -> GetRelation qs Ridx tup'
          -> SatisfiesTupleConstraints Ridx (indexedElement tup) (indexedElement tup')) ->
       MutationPreservesTupleConstraints MutatedTuples (SatisfiesTupleConstraints Ridx))
    (* And is compatible with the cross-schema constraints. *)
    (CrossConstr :
       (@Iterate_Ensemble_BoundedIndex_filter
          (map relName (qschemaSchemas qsSchema))
          (fun idx : nat => if eq_nat_dec (ibound Ridx) idx then false else true)
          (fun Ridx' : BoundedIndex (map relName (qschemaSchemas qsSchema)) =>
             forall tup' : IndexedTuple,
               GetUnConstrRelation (DropQSConstraints qs) Ridx tup' ->
               SatisfiesCrossRelationConstraints Ridx Ridx' (indexedElement tup') (GetRelation qs Ridx'))) ->
       (forall Ridx' : BoundedIndex (map relName (qschemaSchemas qsSchema)),
          (Ridx' <> Ridx) ->
          MutationPreservesCrossConstraints MutatedTuples (GetRelation qs Ridx')
                                            (SatisfiesCrossRelationConstraints Ridx Ridx')))
    (CrossConstr' :
       (@Iterate_Ensemble_BoundedIndex_filter
          (map relName (qschemaSchemas qsSchema))
          (fun idx : nat => if eq_nat_dec (ibound Ridx) idx then false else true)
          (fun Ridx' : BoundedIndex (map relName (qschemaSchemas qsSchema)) =>
             forall tup' : IndexedTuple,
               GetUnConstrRelation (DropQSConstraints qs) Ridx' tup' ->
               SatisfiesCrossRelationConstraints Ridx' Ridx (indexedElement tup') (GetRelation qs Ridx))) ->
       (forall Ridx' : BoundedIndex (map relName (qschemaSchemas qsSchema)),
          (Ridx' <> Ridx) ->
          MutationPreservesCrossConstraints (GetRelation qs Ridx')
                                            MutatedTuples
                                            (SatisfiesCrossRelationConstraints Ridx' Ridx)))
  : QueryStructure qsSchema :=
    {| rels :=
         UpdateRelation _ (rels qs) Ridx {| rel := MutatedTuples|}
    |}.
  Next Obligation.
    unfold MutationPreservesAttributeConstraints,
    SatisfiesAttributeConstraints, QSGetNRelSchema, GetNRelSchema,
    GetRelation in *.
    set ((ith_Bounded _ (rels qs) Ridx )) as X in *; destruct X; simpl in *.
    destruct (attrConstraints
            (relSchema (nth_Bounded relName (qschemaSchemas qsSchema) Ridx))); eauto.
  Qed.
    Next Obligation.
    unfold MutationPreservesTupleConstraints,
    SatisfiesTupleConstraints, QSGetNRelSchema, GetNRelSchema,
    GetRelation in *.
    set ((ith_Bounded _ (rels qs) Ridx )) as X in *; destruct X; simpl in *.
    destruct (tupleConstraints
            (relSchema (nth_Bounded relName (qschemaSchemas qsSchema) Ridx))); eauto.
  Qed.
  Next Obligation.
    unfold MutationPreservesCrossConstraints,
    SatisfiesCrossRelationConstraints, QSGetNRelSchema, GetNRelSchema,
    GetRelation, UpdateRelation in *.
    case_eq (BuildQueryStructureConstraints qsSchema idx idx'); eauto.
    destruct (BoundedString_eq_dec Ridx idx'); subst; intros.
    - rewrite ith_replace_BoundIndex_eq; simpl.
      rewrite ith_replace_BoundIndex_neq in H1; eauto using string_dec.
      generalize (fun c => CrossConstr' c idx H0).
      rewrite H; intros H'; eapply H'; eauto.
      eapply (Iterate_Ensemble_filter_neq
                string_dec
                _
                (fun Ridx' : BoundedIndex (map relName (qschemaSchemas qsSchema)) =>
                   forall tup' : IndexedTuple,
                     GetUnConstrRelation (DropQSConstraints qs) Ridx' tup' ->
                     match BuildQueryStructureConstraints qsSchema Ridx' idx' with
                       | Some CrossConstr => CrossConstr (indexedElement tup') (GetRelation qs idx')
                       | None => True
                     end)).
      intros; generalize (crossConstr qs idx0 idx').
      rewrite GetRelDropConstraints in H3.
      destruct (BuildQueryStructureConstraints qsSchema idx0 idx');
        eauto.
    - rewrite ith_replace_BoundIndex_neq in *; eauto using string_dec.
      destruct (BoundedString_eq_dec Ridx idx); subst.
      + rewrite ith_replace_BoundIndex_eq in H1; simpl in *; eauto.
      generalize (fun c => CrossConstr c idx' (not_eq_sym n) _ H1).
      rewrite H; intros H'; eapply H'; eauto.
      eapply (Iterate_Ensemble_filter_neq
                string_dec
                _
                (fun Ridx' : BoundedIndex (map relName (qschemaSchemas qsSchema)) =>
                   forall tup' : IndexedTuple,
                     GetUnConstrRelation (DropQSConstraints qs) idx tup' ->
                     match BuildQueryStructureConstraints qsSchema idx Ridx' with
                       | Some CrossConstr => CrossConstr (indexedElement tup') (GetRelation qs Ridx')
                       | None => True
                     end)); intros.
      destruct (BoundedString_eq_dec idx0 idx); subst; try congruence.
      case_eq (BuildQueryStructureConstraints qsSchema idx idx0); intros; eauto.
      pose (crossConstr qs idx idx0) as crossConstr'; rewrite H4 in crossConstr'.
      eapply crossConstr'; eauto.
      unfold GetUnConstrRelation, DropQSConstraints in H3.
      rewrite <- ith_Bounded_imap in H3; eauto.
      + rewrite ith_replace_BoundIndex_neq in H1; eauto using string_dec.
        pose (crossConstr qs idx idx') as crossConstr'; rewrite H in crossConstr';
        eapply crossConstr'; eauto.
  Qed.

  Lemma QSMutateSpec_refine :
    forall qsSchema (qs : QueryStructure qsSchema) Ridx
           (MutatedTuples : @IndexedEnsemble (@Tuple (schemaHeading (QSGetNRelSchema _ Ridx)))),
      refine
        (Pick (QSMutateSpec {| qsHint := qs |} Ridx MutatedTuples))
        (attributeConstr <- {b |
                       (forall tup,
                          GetRelation qs Ridx tup
                          -> SatisfiesAttributeConstraints Ridx (indexedElement tup))
                       -> decides b
                                  (MutationPreservesAttributeConstraints
                                     MutatedTuples
                                     (SatisfiesAttributeConstraints Ridx))};
         tupleConstr <- {b |
                         (forall tup tup',
                            elementIndex tup <> elementIndex tup'
                            -> GetRelation qs Ridx tup
                            -> GetRelation qs Ridx tup'
                            -> SatisfiesTupleConstraints Ridx (indexedElement tup) (indexedElement tup'))
                         -> decides b
                               (MutationPreservesTupleConstraints
                                  MutatedTuples
                                  (SatisfiesTupleConstraints Ridx))};
         crossConstr <- {b |
                         (forall Ridx',
                            Ridx' <> Ridx ->
                            forall tup',
                              (GetRelation qs Ridx') tup'
                              -> SatisfiesCrossRelationConstraints
                                   Ridx' Ridx (indexedElement tup') (GetRelation qs Ridx))
                         -> decides
                              b
                              (forall Ridx',
                                 Ridx' <> Ridx
                                 -> MutationPreservesCrossConstraints
                                      (GetRelation qs Ridx')
                                      MutatedTuples
                                      (SatisfiesCrossRelationConstraints Ridx' Ridx))};
         crossConstr' <- {b |
                         (forall Ridx',
                            Ridx' <> Ridx ->
                            forall tup',
                              (GetRelation qs Ridx) tup'
                              -> SatisfiesCrossRelationConstraints
                                   Ridx Ridx' (indexedElement tup') (GetRelation qs Ridx'))
                         -> decides
                              b
                              (forall Ridx',
                                 Ridx' <> Ridx
                                 -> MutationPreservesCrossConstraints
                                      MutatedTuples
                                      (GetRelation qs Ridx')
                                      (SatisfiesCrossRelationConstraints Ridx Ridx'))};
         match attributeConstr, tupleConstr, crossConstr, crossConstr' with
           | true, true, true, true =>
             {qs' |
              (forall Ridx',
                 Ridx <> Ridx' ->
                 GetRelation qsHint Ridx' =
                 GetRelation qs' Ridx')
              /\ forall t,
                   GetRelation qs' Ridx t <-> MutatedTuples t
             }

           | _, _, _, _ => ret qsHint
         end).
  Proof.
    intros qsSchema qs Ridx MutatedTuples v Comp_v.
    do 4 (apply_in_hyp computes_to_inv; destruct_ex; split_and).
    repeat (apply_in_hyp computes_to_inv; destruct_ex; split_and); simpl in *.

    assert (decides x
                      (MutationPreservesAttributeConstraints
                         MutatedTuples
                       (SatisfiesAttributeConstraints Ridx)))
      as H0'
        by
          (apply H0;
           unfold SatisfiesAttributeConstraints, QSGetNRelSchema, GetNRelSchema;
           pose proof (attrconstr ((ith_Bounded relName (rels qs) Ridx))) as H';
           destruct (attrConstraints
                       (relSchema (nth_Bounded relName (qschemaSchemas qsSchema) Ridx)));
           [apply H' | ]; eauto); clear H0.

    assert (decides x0
                    (MutationPreservesTupleConstraints
                       MutatedTuples
                       (SatisfiesTupleConstraints Ridx)))
      as H1'
        by
          (apply H1;
           unfold SatisfiesTupleConstraints, QSGetNRelSchema, GetNRelSchema;
           pose proof (tupleconstr ((ith_Bounded relName (rels qs) Ridx))) as H';
           destruct (tupleConstraints
                       (relSchema (nth_Bounded relName (qschemaSchemas qsSchema) Ridx)));
           [apply H' | ]; eauto); clear H1.

    assert (decides x1
                    (forall Ridx' : BoundedString,
                       Ridx' <> Ridx ->
                       MutationPreservesCrossConstraints
                         (GetRelation qs Ridx')
                         MutatedTuples
                         (SatisfiesCrossRelationConstraints Ridx' Ridx)))
      as H2' by
          (apply H2; intros;
           pose proof (crossConstr qs Ridx' Ridx);
           unfold SatisfiesCrossRelationConstraints;
           destruct (BuildQueryStructureConstraints qsSchema Ridx' Ridx); eauto); clear H2.

    assert (decides x2
                    (forall Ridx' : BoundedString,
                       Ridx' <> Ridx ->
                       MutationPreservesCrossConstraints
                         MutatedTuples
                         (GetRelation qs Ridx')
                         (SatisfiesCrossRelationConstraints Ridx Ridx')))
      as H3' by
          (apply H3; intros;
           pose proof (crossConstr qs Ridx Ridx');
           unfold SatisfiesCrossRelationConstraints;
           destruct (BuildQueryStructureConstraints qsSchema Ridx Ridx'); eauto); clear H3.

    destruct x; destruct x0; destruct x1; destruct x2;
    try solve
        [econstructor; unfold QSMutateSpec; simpl in *; right; subst; intuition].
    econstructor; unfold QSMutateSpec; simpl in *; left; intuition;
    [ rewrite <- H; eauto
    | rewrite <- H; eauto
    | unfold Same_set, Included, In; eauto; intuition; eapply H0; eauto
    | rewrite H; intuition] .
  Qed.

  Lemma QSMutateSpec_UnConstr_refine' :
    forall qsSchema (qs : UnConstrQueryStructure qsSchema)
           (Ridx : @BoundedString (map relName (qschemaSchemas qsSchema)))
           (or : QueryStructure qsSchema)
           MutatedTuples,
      DropQSConstraints_AbsR or qs ->
      refine
        {or' | QSMutateSpec {|qsHint := or |} Ridx MutatedTuples or'}
        (attributeConstr <- {b |
                             (forall tup,
                                GetUnConstrRelation qs Ridx tup
                                -> SatisfiesAttributeConstraints Ridx (indexedElement tup))
                             -> decides b
                                        (MutationPreservesAttributeConstraints
                                           MutatedTuples
                                           (SatisfiesAttributeConstraints Ridx))};
         tupleConstr <- {b |
                         (forall tup tup',
                            elementIndex tup <> elementIndex tup'
                            -> GetUnConstrRelation qs Ridx tup
                            -> GetUnConstrRelation qs Ridx tup'
                            -> SatisfiesTupleConstraints Ridx (indexedElement tup) (indexedElement tup'))
                       -> decides b
                               (MutationPreservesTupleConstraints
                                  MutatedTuples
                                  (SatisfiesTupleConstraints Ridx))};
         crossConstr <- {b |
                         (forall Ridx',
                            Ridx' <> Ridx ->
                            forall tup',
                              (GetUnConstrRelation qs Ridx') tup'
                              -> SatisfiesCrossRelationConstraints
                                   Ridx' Ridx (indexedElement tup') (GetUnConstrRelation qs Ridx))
                         -> decides
                              b
                              (forall Ridx',
                                 Ridx' <> Ridx
                                 -> MutationPreservesCrossConstraints
                                      (GetUnConstrRelation qs Ridx')
                                      MutatedTuples
                                      (SatisfiesCrossRelationConstraints Ridx' Ridx))};
         crossConstr' <- {b |
                         (forall Ridx',
                            Ridx' <> Ridx ->
                            forall tup',
                              (GetUnConstrRelation qs Ridx tup')
                              -> SatisfiesCrossRelationConstraints
                                   Ridx Ridx' (indexedElement tup') (GetUnConstrRelation qs Ridx'))
                         -> decides
                              b
                              (forall Ridx',
                                 Ridx' <> Ridx
                                 -> MutationPreservesCrossConstraints
                                      MutatedTuples
                                      (GetUnConstrRelation qs Ridx')
                                      (SatisfiesCrossRelationConstraints Ridx Ridx'))};
         match attributeConstr, tupleConstr, crossConstr, crossConstr' with
           | true, true, true, true =>
             {or' | DropQSConstraints_AbsR or' (UpdateUnConstrRelation qs Ridx MutatedTuples)}
           | _, _, _, _ => ret or
         end).
  Proof.
    unfold DropQSConstraints_AbsR; intros; subst.
    setoid_rewrite QSMutateSpec_refine.
    repeat setoid_rewrite refineEquiv_bind_bind.
    repeat rewrite GetRelDropConstraints.
    f_equiv; unfold pointwise_relation; intros.
    f_equiv; unfold pointwise_relation; intros.
    f_equiv; unfold pointwise_relation; intros.
    { intros v Comp_v; subst; inversion_by computes_to_inv;
      unfold decides in *; find_if_inside; intros; econstructor; intros.
      - rewrite <- GetRelDropConstraints in *; eapply Comp_v; intros; eauto;
        eapply H; eauto; rewrite <- GetRelDropConstraints; eauto.
      - unfold not; intros; eapply Comp_v; intros; rewrite <- GetRelDropConstraints in *.
        + eapply H; eauto; rewrite <- GetRelDropConstraints; eauto.
        + rewrite GetRelDropConstraints; eauto.
    }
    f_equiv; unfold pointwise_relation; intros.
    { intros v Comp_v; subst; inversion_by computes_to_inv;
      unfold decides in *; find_if_inside; intros; econstructor; intros.
      - rewrite <- GetRelDropConstraints in *; eapply Comp_v; intros; eauto.
        rewrite GetRelDropConstraints; eapply H; eauto.
      - unfold not; intros; eapply Comp_v; intros; rewrite <- GetRelDropConstraints in *.
        + rewrite GetRelDropConstraints; eauto.
        + rewrite GetRelDropConstraints; eauto.
    }
    repeat find_if_inside; try reflexivity.
    intros v Comp_v; inversion_by computes_to_inv; subst; econstructor;
    simpl.
    rewrite <- GetRelDropConstraints;
      setoid_rewrite <- GetRelDropConstraints; subst; rewrite Comp_v;
      split; intros;
      unfold GetUnConstrRelation, DropQSConstraints, UpdateUnConstrRelation.
    rewrite ith_replace_BoundIndex_neq; repeat rewrite <- ith_Bounded_imap;
    eauto using string_dec.
    rewrite ith_replace_BoundIndex_eq; repeat rewrite <- ith_Bounded_imap;
    intuition.
  Qed.

  Lemma ComplementIntersection {A} :
    forall (ens : Ensemble A) (a : A),
      ~ In _ (Intersection A ens (Complement A ens)) a.
  Proof.
    unfold In, not; intros; inversion H; subst.
    unfold Complement, In in *; tauto.
  Qed.

  Corollary ComplementIntersectionIndexedList {heading}
  : forall (ens : Ensemble (@IndexedTuple heading)),
      UnIndexedEnsembleListEquivalence
        (Intersection IndexedTuple ens
                      (Complement IndexedTuple ens))
        [].

  Proof.
    unfold UnIndexedEnsembleListEquivalence.
    exists (@nil (@IndexedTuple heading)); simpl; intuition.
    - exfalso; eapply ComplementIntersection; eauto.
    - constructor.
  Qed.

  Lemma ibound_check_dec :
    forall b a : nat,
            (fun idx : nat =>
             if eq_nat_dec b idx then false else true) a = true <->
            (fun idx : nat => b <> idx) a.
  Proof.
    intros; simpl; find_if_inside; intuition.
  Qed.

  Lemma refine_Iterate_MutationPreservesCrossConstraints
  : forall qsSchema (qs : UnConstrQueryStructure qsSchema )
           (Ridx : @BoundedString (map relName (qschemaSchemas qsSchema)))
           MutatedTuples
           (or : QueryStructure qsSchema),
      DropQSConstraints_AbsR or qs
      ->
    ((forall Ridx' : BoundedString,
     Ridx' <> Ridx ->
     forall tup' : IndexedTuple,
     GetRelation or Ridx tup' ->
     SatisfiesCrossRelationConstraints Ridx Ridx' (indexedElement tup')
       (GetUnConstrRelation (DropQSConstraints or) Ridx')) ->
    forall Ridx' : BoundedString,
    Ridx' <> Ridx ->
    MutationPreservesCrossConstraints MutatedTuples
      (GetUnConstrRelation (DropQSConstraints or) Ridx')
      (SatisfiesCrossRelationConstraints Ridx Ridx')) ->
   Iterate_Ensemble_BoundedIndex_filter
     (fun idx : nat => if eq_nat_dec (ibound Ridx) idx then false else true)
     (fun Ridx' : BoundedIndex (map relName (qschemaSchemas qsSchema)) =>
      forall tup' : IndexedTuple,
      GetUnConstrRelation (DropQSConstraints or) Ridx tup' ->
      SatisfiesCrossRelationConstraints Ridx Ridx'
        (indexedElement tup') (GetRelation or Ridx')) ->
   forall Ridx' : BoundedIndex (map relName (qschemaSchemas qsSchema)),
   Ridx' <> Ridx ->
   MutationPreservesCrossConstraints
     MutatedTuples (GetRelation or Ridx')
     (SatisfiesCrossRelationConstraints Ridx Ridx').
  Proof.
    intros; rewrite <- GetRelDropConstraints in *; eapply H0; eauto.
    intros; rewrite GetRelDropConstraints in *.
    intros; eapply (proj1 (Iterate_Ensemble_BoundedIndex_filter_equiv
                             _
                             (Build_DecideableEnsemble _ _ (ibound_check_dec _) )) H1); eauto.
    unfold not; intros; eapply H3;
    eapply idx_ibound_eq; eauto using string_dec.
  Qed.

  Lemma refine_Iterate_MutationPreservesCrossConstraints'
  : forall qsSchema (qs : UnConstrQueryStructure qsSchema )
           (Ridx : @BoundedString (map relName (qschemaSchemas qsSchema)))
           MutatedTuples
           (or : QueryStructure qsSchema),
      DropQSConstraints_AbsR or qs
      ->
    ((forall Ridx' : BoundedString,
     Ridx' <> Ridx ->
     forall tup' : IndexedTuple,
       GetUnConstrRelation (DropQSConstraints or) Ridx' tup' ->
     SatisfiesCrossRelationConstraints Ridx' Ridx (indexedElement tup')
       (GetRelation or Ridx)) ->
    forall Ridx' : BoundedString,
    Ridx' <> Ridx ->
    MutationPreservesCrossConstraints
      (GetUnConstrRelation (DropQSConstraints or) Ridx')
      MutatedTuples
      (SatisfiesCrossRelationConstraints Ridx' Ridx)) ->
      Iterate_Ensemble_BoundedIndex_filter
    (fun idx : nat => if eq_nat_dec (ibound Ridx) idx then false else true)
    (fun Ridx' : BoundedIndex (map relName (qschemaSchemas qsSchema)) =>
     forall tup' : IndexedTuple,
     GetUnConstrRelation (DropQSConstraints or) Ridx' tup' ->
     SatisfiesCrossRelationConstraints Ridx' Ridx (indexedElement tup')
       (GetRelation or Ridx)) ->
  forall Ridx' : BoundedIndex (map relName (qschemaSchemas qsSchema)),
  Ridx' <> Ridx ->
  MutationPreservesCrossConstraints (GetRelation or Ridx') MutatedTuples
                                    (SatisfiesCrossRelationConstraints Ridx' Ridx).
    intros; rewrite <- GetRelDropConstraints in *; eapply H0; eauto.
    intros; eapply (proj1 (Iterate_Ensemble_BoundedIndex_filter_equiv
                             _
                             (Build_DecideableEnsemble _ _ (ibound_check_dec _) )) H1); eauto.
    unfold not; intros; eapply H3;
    eapply idx_ibound_eq; eauto using string_dec.
  Qed.

  Lemma QSMutateSpec_UnConstr_refine :
    forall qsSchema (qs : UnConstrQueryStructure qsSchema )
           (Ridx : @BoundedString (map relName (qschemaSchemas qsSchema)))
           MutatedTuples
           (or : QueryStructure qsSchema)
           refined_attrConstr refined_tupleConstr
           refined_crossConstr refined_crossConstr',
      DropQSConstraints_AbsR or qs
      -> refine {b | (forall tup,
                        GetUnConstrRelation qs Ridx tup
                        -> SatisfiesAttributeConstraints Ridx (indexedElement tup))
                     ->  decides b (MutationPreservesAttributeConstraints
                                      MutatedTuples
                                      (SatisfiesAttributeConstraints Ridx))}
                refined_attrConstr
      -> refine {b | (forall tup tup',
                        elementIndex tup <> elementIndex tup'
                          -> GetUnConstrRelation qs Ridx tup
                          -> GetUnConstrRelation qs Ridx tup'
                          -> SatisfiesTupleConstraints Ridx (indexedElement tup) (indexedElement tup'))
                     ->  decides b (MutationPreservesTupleConstraints
                                      MutatedTuples
                                      (SatisfiesTupleConstraints Ridx))}
                refined_tupleConstr
      -> refine {b |
                         (forall Ridx',
                            Ridx' <> Ridx ->
                            forall tup',
                              (GetUnConstrRelation qs Ridx') tup'
                              -> SatisfiesCrossRelationConstraints
                                   Ridx' Ridx (indexedElement tup') (GetUnConstrRelation qs Ridx))
                         -> decides
                              b
                              (forall Ridx',
                                 Ridx' <> Ridx
                                 -> MutationPreservesCrossConstraints
                                      (GetUnConstrRelation qs Ridx')
                                      MutatedTuples
                                      (SatisfiesCrossRelationConstraints Ridx' Ridx))}

           (* @Iterate_Decide_Comp_Pre
                           _
                           ((fun Ridx' =>
                               Ridx' <> Ridx
                               -> MutationPreservesCrossConstraints
                                    (GetUnConstrRelation qs Ridx')
                                    MutatedTuples
                                    (SatisfiesCrossRelationConstraints Ridx' Ridx)))
                           (@Iterate_Ensemble_BoundedIndex_filter
                              _ (fun idx =>
                                   if (eq_nat_dec (ibound Ridx) idx)
                                   then false else true)
                              (fun Ridx' =>
                                 forall tup',
                                   (GetUnConstrRelation qs Ridx') tup'
                                   -> SatisfiesCrossRelationConstraints
                                        Ridx' Ridx (indexedElement tup')
                                        (GetUnConstrRelation qs Ridx)))
           *)
                refined_crossConstr
      -> refine {b |
                         (forall Ridx',
                            Ridx' <> Ridx ->
                            forall tup',
                              (GetUnConstrRelation qs Ridx tup')
                              -> SatisfiesCrossRelationConstraints
                                   Ridx Ridx' (indexedElement tup') (GetUnConstrRelation qs Ridx'))
                         -> decides
                              b
                              (forall Ridx',
                                 Ridx' <> Ridx
                                 -> MutationPreservesCrossConstraints
                                      MutatedTuples
                                      (GetUnConstrRelation qs Ridx')
                                      (SatisfiesCrossRelationConstraints Ridx Ridx'))}
           (*@Iterate_Decide_Comp_Pre
                           _
                           ((fun Ridx' =>
                               Ridx' <> Ridx
                               -> MutationPreservesCrossConstraints
                                    MutatedTuples
                                    (GetUnConstrRelation qs Ridx')
                                    (SatisfiesCrossRelationConstraints Ridx Ridx')))
                           (@Iterate_Ensemble_BoundedIndex_filter
                              _ (fun idx =>
                                   if (eq_nat_dec (ibound Ridx) idx)
                                   then false else true)
                              (fun Ridx' =>
                                 forall tup',
                                   (GetUnConstrRelation qs Ridx) tup'
                                   -> SatisfiesCrossRelationConstraints
                                        Ridx Ridx' (indexedElement tup') (GetUnConstrRelation qs Ridx')))
                *)
                refined_crossConstr'
      ->
      refine
        (or' <- QSMutate {|qsHint := or |} Ridx MutatedTuples;
         nr' <- {nr' | DropQSConstraints_AbsR (fst or') nr'};
         ret (nr', snd or'))
        (attrConstr <- refined_attrConstr;
         tupleConstr <- refined_tupleConstr;
         crossConstr <- refined_crossConstr;
         crossConstr' <- refined_crossConstr';
            match attrConstr, tupleConstr, crossConstr, crossConstr' with
              | true, true, true, true =>
                mutated   <- Pick (UnIndexedEnsembleListEquivalence
                                     (Intersection _
                                                   (GetRelation or Ridx)
                                                   (Complement _ (GetUnConstrRelation (UpdateUnConstrRelation qs Ridx MutatedTuples) Ridx))));
              ret (UpdateUnConstrRelation qs Ridx MutatedTuples, mutated)
              | _, _, _, _ => ret (DropQSConstraints or, [])
            end).
  Proof.
    intros; simplify with monad laws.
    setoid_rewrite (@QSMutateSpec_UnConstr_refine' _ qs Ridx); eauto.
    setoid_rewrite <- H0; setoid_rewrite <- H1.
    setoid_rewrite <- H2; setoid_rewrite <- H3.
    simplify with monad laws;
      repeat (eapply refine_under_bind; intros; eauto); eauto.
    repeat find_if_inside;
      try solve
          [simplify with monad laws; refine pick val _;
           [ simplify with monad laws; refine pick val (DropQSConstraints or);
             try simplify with monad laws
           | eauto using ComplementIntersectionIndexedList]; reflexivity
          ].
    inversion_by computes_to_inv; simpl in *.
    unfold DropQSConstraints_AbsR in *; subst.
    repeat rewrite (fun Ridx => GetRelDropConstraints or Ridx) in *.
    refine pick val
           (Mutate_Valid
              or H4 H5
              (refine_Iterate_MutationPreservesCrossConstraints (refl_equal _) H7)
              (refine_Iterate_MutationPreservesCrossConstraints' (refl_equal _) H6));
      [ simplify with monad laws
      | unfold Mutate_Valid, DropQSConstraints,
        UpdateRelation, UpdateUnConstrRelation; simpl;
        repeat rewrite imap_replace_BoundedIndex by eauto using string_dec;
        simpl; reflexivity].

    f_equiv.
    - unfold GetRelation, GetUnConstrRelation, Mutate_Valid,
      UpdateRelation, DropQSConstraints, UpdateUnConstrRelation; simpl;
      repeat rewrite ith_replace_BoundIndex_eq; reflexivity.
    - unfold pointwise_relation; intros.
      refine pick val _;
        [ simplify with monad laws; reflexivity
        | unfold GetRelation, GetUnConstrRelation, Mutate_Valid,
          UpdateRelation, DropQSConstraints, UpdateUnConstrRelation; simpl;
          rewrite imap_replace_BoundedIndex by eauto using string_dec; try reflexivity ].
  Qed.

  Local Transparent QSMutate.

  Lemma refine_SatisfiesAttributeConstraintsMutate
  : forall (qsSchema : QueryStructureSchema)
           (qs : UnConstrQueryStructure qsSchema) (Ridx : BoundedString)
           MutatedTuples,
      refine
        {b | (forall tup,
                GetUnConstrRelation qs Ridx tup
                -> SatisfiesAttributeConstraints Ridx (indexedElement tup))
                     -> decides b (MutationPreservesAttributeConstraints
                                     MutatedTuples
                                     (SatisfiesAttributeConstraints Ridx))}
        match attrConstraints (QSGetNRelSchema qsSchema Ridx) with
          | Some Constr =>
            {b | (forall tup,
                          GetUnConstrRelation qs Ridx tup
                          -> SatisfiesAttributeConstraints Ridx (indexedElement tup))
                 -> decides b (MutationPreservesAttributeConstraints
                                 MutatedTuples
                                 (SatisfiesAttributeConstraints Ridx)) }
          | None => ret true
        end.
  Proof.
    intros; unfold MutationPreservesAttributeConstraints, SatisfiesAttributeConstraints;
    destruct (attrConstraints (QSGetNRelSchema qsSchema Ridx)); try reflexivity.
    intros v Comp_v; econstructor; inversion_by computes_to_inv; subst;
    simpl; tauto.
  Qed.

  Lemma refine_SatisfiesTupleConstraintsMutate
  : forall (qsSchema : QueryStructureSchema)
           (qs : UnConstrQueryStructure qsSchema) (Ridx : BoundedString)
           MutatedTuples,
      refine
        {b | (forall tup tup',
                elementIndex tup <> elementIndex tup'
                -> GetUnConstrRelation qs Ridx tup
                -> GetUnConstrRelation qs Ridx tup'
                -> SatisfiesTupleConstraints Ridx (indexedElement tup)
                                             (indexedElement tup'))
                     -> decides b (MutationPreservesTupleConstraints
                                     MutatedTuples
                                     (SatisfiesTupleConstraints Ridx))}
        match tupleConstraints (QSGetNRelSchema qsSchema Ridx) with
          | Some Constr =>
            {b | (forall tup tup',
                    elementIndex tup <> elementIndex tup'
                    -> GetUnConstrRelation qs Ridx tup
                    -> GetUnConstrRelation qs Ridx tup'
                    -> SatisfiesTupleConstraints Ridx (indexedElement tup)
                                                 (indexedElement tup'))
                 -> decides b
                            (MutationPreservesTupleConstraints
                               MutatedTuples
                               (SatisfiesTupleConstraints Ridx)) }
          | None => ret true
        end.
  Proof.
    intros; unfold MutationPreservesTupleConstraints, SatisfiesTupleConstraints;
    destruct (tupleConstraints (QSGetNRelSchema qsSchema Ridx)); try reflexivity.
    intros v Comp_v; econstructor; inversion_by computes_to_inv; subst;
    econstructor; inversion_by computes_to_inv; subst; simpl; tauto.
  Qed.

  Lemma refine_SatisfiesCrossConstraintsMutate
  : forall (qsSchema : QueryStructureSchema)
           (qs : UnConstrQueryStructure qsSchema) (Ridx : BoundedString)
           MutatedTuples,
      refine
        {b |
                         (forall Ridx',
                            Ridx' <> Ridx ->
                            forall tup',
                              (GetUnConstrRelation qs Ridx') tup'
                              -> SatisfiesCrossRelationConstraints
                                   Ridx' Ridx (indexedElement tup') (GetUnConstrRelation qs Ridx))
                         -> decides
                              b
                              (forall Ridx',
                                 Ridx' <> Ridx
                                 -> MutationPreservesCrossConstraints
                                      (GetUnConstrRelation qs Ridx')
                                      MutatedTuples
                                      (SatisfiesCrossRelationConstraints Ridx' Ridx))}
        (Iterate_Decide_Comp_opt'_Pre string
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
                                              (
                                                (MutationPreservesCrossConstraints
                                                   (GetUnConstrRelation qs Ridx')
                                                   MutatedTuples
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
                                               Ridx' Ridx (indexedElement tup') (GetUnConstrRelation qs Ridx)))).
  Proof.
    intros; simpl.
    unfold MutationPreservesCrossConstraints.
    setoid_rewrite <- refine_Iterate_Decide_Comp_Pre.
    setoid_rewrite Iterate_Decide_Comp_BoundedIndex_Pre.
    eapply refine_Iterate_Decide_Comp_equiv_Pre; eauto using string_dec.
    - unfold SatisfiesCrossRelationConstraints; intros.
      destruct (BoundedString_eq_dec Ridx idx);
        [congruence
        | destruct (BuildQueryStructureConstraints qsSchema idx Ridx); eauto].
    - unfold not; intros; eapply H.
      unfold SatisfiesCrossRelationConstraints in *.
      destruct (BoundedString_eq_dec Ridx idx);
      [ eauto
      | destruct (BuildQueryStructureConstraints qsSchema idx Ridx); eauto].
    - setoid_rewrite <- Iterate_Ensemble_filter_neq; eauto using string_dec.
  Qed.

  Lemma refine_SatisfiesCrossConstraintsMutate'
  : forall (qsSchema : QueryStructureSchema)
           (qs : UnConstrQueryStructure qsSchema) (Ridx : BoundedString)
           MutatedTuples,
      refine
        {b |
                         (forall Ridx',
                            Ridx' <> Ridx ->
                            forall tup',
                              (GetUnConstrRelation qs Ridx tup')
                              -> SatisfiesCrossRelationConstraints
                                   Ridx Ridx' (indexedElement tup') (GetUnConstrRelation qs Ridx'))
                         -> decides
                              b
                              (forall Ridx',
                                 Ridx' <> Ridx
                                 -> MutationPreservesCrossConstraints
                                      MutatedTuples
                                      (GetUnConstrRelation qs Ridx')
                                      (SatisfiesCrossRelationConstraints Ridx Ridx'))}
        (Iterate_Decide_Comp_opt'_Pre string
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
                                          BuildQueryStructureConstraints qsSchema Ridx
                                                                         Ridx'
                                        with
                                          | Some CrossConstr =>
                                            Some
                                              (
                                                (MutationPreservesCrossConstraints
                                                   MutatedTuples
                                                   (GetUnConstrRelation qs Ridx')
                                                   CrossConstr))
                                          | None => None
                                        end)
                                  (@Iterate_Ensemble_BoundedIndex_filter
                                     _ (fun idx =>
                                          if (eq_nat_dec (ibound Ridx) idx)
                                          then false else true)
                                     (fun Ridx' =>
                                        forall tup',
                                          (GetUnConstrRelation qs Ridx) tup'
                                          -> SatisfiesCrossRelationConstraints
                                               Ridx Ridx' (indexedElement tup') (GetUnConstrRelation qs Ridx')))).
  Proof.
    intros; simpl.
    unfold MutationPreservesCrossConstraints.
    setoid_rewrite <- refine_Iterate_Decide_Comp_Pre.
    setoid_rewrite Iterate_Decide_Comp_BoundedIndex_Pre.
    eapply refine_Iterate_Decide_Comp_equiv_Pre; eauto using string_dec.
    - unfold SatisfiesCrossRelationConstraints; intros.
      destruct (BoundedString_eq_dec Ridx idx);
        [congruence
        | destruct (BuildQueryStructureConstraints qsSchema Ridx idx); eauto].
    - unfold not; intros; eapply H.
      unfold SatisfiesCrossRelationConstraints in *.
      destruct (BoundedString_eq_dec Ridx idx);
      [ eauto
      | destruct (BuildQueryStructureConstraints qsSchema Ridx idx); eauto].
    - setoid_rewrite <- Iterate_Ensemble_filter_neq; eauto using string_dec.
  Qed.

  Lemma QSMutateSpec_UnConstr_refine_opt :
    forall qsSchema (qs : UnConstrQueryStructure qsSchema )
           (Ridx : @BoundedString (map relName (qschemaSchemas qsSchema)))
           (MutatedTuples : @IndexedEnsemble (@Tuple (schemaHeading (QSGetNRelSchema _ Ridx))))
           (or : QueryStructure qsSchema),
      DropQSConstraints_AbsR or qs ->
      refine
        (or' <- QSMutate {|qsHint := or |} Ridx MutatedTuples;
         nr' <- {nr' | DropQSConstraints_AbsR (fst or') nr'};
         ret (nr', snd or'))
        match (attrConstraints (QSGetNRelSchema qsSchema Ridx)),
              (tupleConstraints (QSGetNRelSchema qsSchema Ridx)) with
          | Some aConstr, Some tConstr =>
            attrConstr <- {b | (forall tup,
                                  GetUnConstrRelation qs Ridx tup
                                  -> aConstr (indexedElement tup))
                                  -> decides b (MutationPreservesAttributeConstraints
                                                  MutatedTuples
                                                  aConstr) };
              tupleConstr <- {b | (forall tup tup',
                                     elementIndex tup <> elementIndex tup'
                                     -> GetUnConstrRelation qs Ridx tup
                                     -> GetUnConstrRelation qs Ridx tup'
                                     -> tConstr (indexedElement tup) (indexedElement tup'))
                                  -> decides b (MutationPreservesTupleConstraints
                                                  MutatedTuples
                                                  tConstr) };
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
                                                     MutatedTuples
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
              crossConstr' <- (Iterate_Decide_Comp_opt'_Pre string
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
                                          BuildQueryStructureConstraints qsSchema Ridx
                                                                         Ridx'
                                        with
                                          | Some CrossConstr =>
                                            Some
                                              ((MutationPreservesCrossConstraints
                                                  MutatedTuples
                                                  (GetUnConstrRelation qs Ridx')
                                                  CrossConstr))
                                          | None => None
                                        end)
                                  (@Iterate_Ensemble_BoundedIndex_filter
                                     _ (fun idx =>
                                          if (eq_nat_dec (ibound Ridx) idx)
                                          then false else true)
                                     (fun Ridx' =>
                                        forall tup',
                                          (GetUnConstrRelation qs Ridx) tup'
                                          -> SatisfiesCrossRelationConstraints
                                               Ridx Ridx' (indexedElement tup') (GetUnConstrRelation qs Ridx'))));
              match attrConstr, tupleConstr, crossConstr, crossConstr' with
                | true, true, true, true =>
                  mutated   <- Pick (UnIndexedEnsembleListEquivalence
                                       (Intersection _
                                                     (GetRelation or Ridx)
                                                     (Complement _ (GetUnConstrRelation (UpdateUnConstrRelation qs Ridx MutatedTuples) Ridx))));
                    ret (UpdateUnConstrRelation qs Ridx MutatedTuples, mutated)
                | _, _, _, _ => ret (DropQSConstraints or, [])
              end
          | Some aConstr, None =>
            attrConstr <- {b | (forall tup,
                                  GetUnConstrRelation qs Ridx tup
                                  -> aConstr (indexedElement tup))
                               -> decides b (MutationPreservesAttributeConstraints
                                               MutatedTuples
                                               aConstr) };
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
                                                     MutatedTuples
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
              crossConstr' <- (Iterate_Decide_Comp_opt'_Pre string
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
                                          BuildQueryStructureConstraints qsSchema Ridx
                                                                         Ridx'
                                        with
                                          | Some CrossConstr =>
                                            Some
                                              ((MutationPreservesCrossConstraints
                                                  MutatedTuples
                                                  (GetUnConstrRelation qs Ridx')
                                                  CrossConstr))
                                          | None => None
                                        end)
                                  (@Iterate_Ensemble_BoundedIndex_filter
                                     _ (fun idx =>
                                          if (eq_nat_dec (ibound Ridx) idx)
                                          then false else true)
                                     (fun Ridx' =>
                                        forall tup',
                                          (GetUnConstrRelation qs Ridx) tup'
                                          -> SatisfiesCrossRelationConstraints
                                               Ridx Ridx' (indexedElement tup') (GetUnConstrRelation qs Ridx'))));
              match attrConstr, crossConstr, crossConstr' with
                | true, true, true =>
                  mutated   <- Pick (UnIndexedEnsembleListEquivalence
                                       (Intersection _
                                                     (GetRelation or Ridx)
                                                     (Complement _ (GetUnConstrRelation (UpdateUnConstrRelation qs Ridx MutatedTuples) Ridx))));
                    ret (UpdateUnConstrRelation qs Ridx MutatedTuples, mutated)
                | _, _, _ => ret (DropQSConstraints or, [])
            end
          | None, Some tConstr =>
              tupleConstr <- {b | (forall tup tup',
                                     elementIndex tup <> elementIndex tup'
                                     -> GetUnConstrRelation qs Ridx tup
                                     -> GetUnConstrRelation qs Ridx tup'
                                     -> tConstr (indexedElement tup) (indexedElement tup'))
                                  -> decides b (MutationPreservesTupleConstraints
                                                  MutatedTuples
                                                  tConstr) };
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
                                                     MutatedTuples
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
              crossConstr' <- (Iterate_Decide_Comp_opt'_Pre string
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
                                          BuildQueryStructureConstraints qsSchema Ridx
                                                                         Ridx'
                                        with
                                          | Some CrossConstr =>
                                            Some
                                              ((MutationPreservesCrossConstraints
                                                  MutatedTuples
                                                  (GetUnConstrRelation qs Ridx')
                                                  CrossConstr))
                                          | None => None
                                        end)
                                  (@Iterate_Ensemble_BoundedIndex_filter
                                     _ (fun idx =>
                                          if (eq_nat_dec (ibound Ridx) idx)
                                          then false else true)
                                     (fun Ridx' =>
                                        forall tup',
                                          (GetUnConstrRelation qs Ridx) tup'
                                          -> SatisfiesCrossRelationConstraints
                                               Ridx Ridx' (indexedElement tup') (GetUnConstrRelation qs Ridx'))));
              match tupleConstr, crossConstr, crossConstr' with
                | true, true, true =>
                  mutated   <- Pick (UnIndexedEnsembleListEquivalence
                                       (Intersection _
                                                     (GetRelation or Ridx)
                                                     (Complement _ (GetUnConstrRelation (UpdateUnConstrRelation qs Ridx MutatedTuples) Ridx))));
                    ret (UpdateUnConstrRelation qs Ridx MutatedTuples, mutated)
                | _, _, _ => ret (DropQSConstraints or, [])
              end
          | None, None =>
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
                                                     MutatedTuples
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
              crossConstr' <- (Iterate_Decide_Comp_opt'_Pre string
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
                                          BuildQueryStructureConstraints qsSchema Ridx
                                                                         Ridx'
                                        with
                                          | Some CrossConstr =>
                                            Some
                                              ((MutationPreservesCrossConstraints
                                                  MutatedTuples
                                                  (GetUnConstrRelation qs Ridx')
                                                  CrossConstr))
                                          | None => None
                                        end)
                                  (@Iterate_Ensemble_BoundedIndex_filter
                                     _ (fun idx =>
                                          if (eq_nat_dec (ibound Ridx) idx)
                                          then false else true)
                                     (fun Ridx' =>
                                        forall tup',
                                          (GetUnConstrRelation qs Ridx) tup'
                                          -> SatisfiesCrossRelationConstraints
                                               Ridx Ridx' (indexedElement tup') (GetUnConstrRelation qs Ridx'))));
              match crossConstr, crossConstr' with
                | true, true =>
                  mutated   <- Pick (UnIndexedEnsembleListEquivalence
                                       (Intersection _
                                                     (GetRelation or Ridx)
                                                     (Complement _ (GetUnConstrRelation (UpdateUnConstrRelation qs Ridx MutatedTuples) Ridx))));
                    ret (UpdateUnConstrRelation qs Ridx MutatedTuples, mutated)
                | _, _ => ret (DropQSConstraints or, [])
              end
        end.
  Proof.
    intros; rewrite QSMutateSpec_UnConstr_refine;
    eauto using
          refine_SatisfiesTupleConstraintsMutate,
    refine_SatisfiesAttributeConstraintsMutate,
    refine_SatisfiesCrossConstraintsMutate,
    refine_SatisfiesCrossConstraintsMutate'.
    - unfold SatisfiesTupleConstraints, SatisfiesAttributeConstraints.
      destruct (attrConstraints (QSGetNRelSchema qsSchema Ridx)).
      + destruct (tupleConstraints (QSGetNRelSchema qsSchema Ridx)).
        reflexivity.
        simplify with monad laws; f_equiv.
      + simplify with monad laws; f_equiv.
        destruct (tupleConstraints (QSGetNRelSchema qsSchema Ridx)).
        reflexivity.
        simplify with monad laws; f_equiv.
  Qed.

End MutateRefinements.