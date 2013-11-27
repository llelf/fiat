Require Import List Ensembles String.

Set Asymmetric Patterns.
Set Implicit Arguments.
Set Universe Polymorphism.
Generalizable All Variables.


Delimit Scope comp_scope with comp.
Create HintDb comp discriminated.

Section funcs.
  Variable funcs : string -> Type * Type.
  Inductive Comp : Type -> Type :=
  | Return : forall A, A -> Comp A
  | Bind : forall A B, Comp A -> (A -> Comp B) -> Comp B
  | Call : forall x, fst (funcs x) -> Comp (snd (funcs x))
  | Pick : forall A, Ensemble A -> Comp A.

  Bind Scope comp_scope with Comp.
  Global Arguments Bind A%type B%type _%comp _.

  Notation "x >>= y" := (Bind x y) (at level 60, no associativity) : comp_scope.
  Notation "x <- y ; z" := (Bind y (fun x => z)) (at level 70, right associativity) : comp_scope.
  Notation "x ;; z" := (Bind x (fun _ => z)) (at level 70, right associativity) : comp_scope.
  Notation "f [[ x ]]" := (@Call f x) (at level 40) : comp_scope.
  Notation "{ x  |  P }" := (@Pick _ (fun x => P)) : comp_scope.
  Notation "{ x : A  |  P }" := (@Pick A (fun x => P)) : comp_scope.

  Inductive formula (vars : Type) :=
  | Atomic : vars -> formula vars
  | And : formula vars -> formula vars -> formula vars
  | Not : formula vars -> formula vars.

  Fixpoint get_vars vars (f : formula vars) : list vars :=
    match f with
      | Atomic x => x::nil
      | And x y => get_vars x ++ get_vars y
      | Not x => get_vars x
    end.

  Fixpoint subst_vars vars (bool_map : vars -> vars + bool) (f : formula vars)
  : formula vars + bool
    := match f with
         | Atomic x => match bool_map x with
                         | inl x' => inl (Atomic x')
                         | inr b => inr b
                       end
         | And x y => match subst_vars bool_map x, subst_vars bool_map y with
                        | inl x', inl y' => inl (And x' y')
                        | inr true, y' => y'
                        | inr false, _ => inr false
                        | x', inr true => x'
                        | _, inr false => inr false
                      end
         | Not x => match subst_vars bool_map x with
                      | inl x' => inl (Not x')
                      | inr b => inr (negb b)
                    end
       end.

  Definition sat (sat_func : forall var (f : formula var), Comp bool) var (f : formula var) : Comp bool :=
    (x0 <- { x0 : { x0 : var & (forall x0', {x0 = x0'} + {x0 <> x0'}) }
           | List.In (projT1 x0) (get_vars f) };
     let x0_val := projT1 x0 in
     let dec_eq_x0 := projT2 x0 in
     let bool_map_t v := if dec_eq_x0 v then inr true else inl v in
     let bool_map_f v := if dec_eq_x0 v then inr true else inl v in
     let formula_t := subst_vars bool_map_t f in
     let formula_f := subst_vars bool_map_f f in
     match formula_t, formula_f with
       | inl f_t, inl f_f => t_comp <- sat_func _ f_t;
       f_comp <- sat_func _ f_f;
       Return (orb t_comp f_comp)
       | inr true, _ => Return true
       | _, inr true => Return true
       | inr false, inr false => Return false
       | inr false, inl f_f => sat_func _ f_f
       | inl f_t, inr false => sat_func _ f_t
     end)%comp.

  Inductive computes_to (denote_funcs : forall name, fst (funcs name) -> Comp (snd (funcs name)))
  : forall A, Comp A -> A -> Type :=
  | ReturnComputes : forall A v, @computes_to denote_funcs A (Return v) v
  | BindComputes : forall A B comp_a f comp_a_value comp_b_value,
                     @computes_to denote_funcs A comp_a comp_a_value
                     -> @computes_to denote_funcs B (f comp_a_value) comp_b_value
                     -> @computes_to denote_funcs B (Bind comp_a f) comp_b_value
  | PickComputes : forall A (P : Ensemble A) v, P v -> @computes_to denote_funcs A (Pick P) v
  | CallComputes : forall name (input : fst (funcs name)) (output_v : snd (funcs name)),
                     @computes_to denote_funcs _ (denote_funcs name input) output_v
                     -> @computes_to denote_funcs _ (Call name input) output_v.


End funcs.

  Notation "x >>= y" := (Bind x y) (at level 60, no associativity) : comp_scope.
  Notation "x <- y ; z" := (Bind y (fun x => z)) (at level 70, right associativity) : comp_scope.
  Notation "x ;; z" := (Bind x (fun _ => z)) (at level 70, right associativity) : comp_scope.
  Notation "f [[ x ]]" := (@Call _ f x) (at level 40) : comp_scope.
  Notation "{ x  |  P }" := (@Pick _ _ (fun x => P)) : comp_scope.
  Notation "{ x : A  |  P }" := (@Pick _ A (fun x => P)) : comp_scope.
Inductive Elem T : list T -> Type :=
| First : forall x l, Elem (x::l)
| Next : forall x l, Elem l -> Elem (x::l).

Fixpoint get_elem T l (x : @Elem T l) : T :=
  match x with
    | First x l => x
    | Next x l' x' => @get_elem T l' x'
  end.

Inductive InT A : A -> list A -> Type :=
| InFirst : forall x l, InT x (x::l)
| InNext : forall x y l, InT x l -> InT x (y::l).

(*Definition InT_app_commut A (x : A) l1 l2 (e : InT x (l1 ++ l2)) : InT x (l2 ++ l1).
Proof.
  revert x l2 e.
  induction l1;
  simpl in *.
  - intros; induction e; simpl; constructor; assumption.
  - intros.
    inversion e; subst.
    + induction l2; simpl; constructor.
      apply IHl2; constructor.
    + induction l2; simpl.
      clear X IHl1.
      generali
      induction l1; simpl in *.
      * assumption.
      * idtac.
      apply (IHl1 _ nil).
    + idtac.
    Show Proof.
    refine (match e as e in (InT _ x l) return match e with
                                  |


    inversion_clear e; try constructor.

    Print InT_rect.
    refine
    inversion e.
    induction e.
    destruct e
    induction e; simpl.
    eapply IHl1.
    simpl in *.
    constructor.
*)

Fixpoint elem_of_inT A x l (i : @InT A x l) : Elem l
  := match i in (InT _ l0) return (Elem l0) with
       | InFirst x l0 => First x l0
       | InNext x y l0 i0 => Next y (@elem_of_inT A x l0 i0)
     end.
(*
Fixpoint inT_app A (l1 l2 : list A) x (e : (InT x l1) + (InT x l2)) : InT x (l1 ++ l2).
destruct e.
destruct i.
constructor.
simpl.
constructor.
apply inT_app.
left.
assumption.
destruct i.
*)

Class Exhaustible (T : Type) :=
  { AllElements : list T;
    AllElements_all : forall i, InT i AllElements }.

Section proof_by_exhaustion.
  Context `{Exhaustible idx}.
  Variable P : idx -> Prop.

  Variable dec_idxes : forall i : Elem AllElements,
                         {P (get_elem i)} + {~P (get_elem i)}.

  Definition dec_P : forall i, {P i} + {~P i}.
  Proof.
    intro i.
    generalize (dec_idxes (elem_of_inT (AllElements_all i))).
    generalize (AllElements_all i).
    clear dec_idxes.
    intro i0.
    induction i0.
    - exact (fun x => x).
    - exact IHi0.
  Defined.
End proof_by_exhaustion.

Section base.
  Local Obligation Tactic := repeat (intros [] || intro || constructor).

  Program Instance: Exhaustible bool := {| AllElements := true::false::nil |}.
  Program Instance: Exhaustible unit := {| AllElements := tt::nil |}.
  Program Instance: Exhaustible True := {| AllElements := I::nil |}.
  Program Instance: Exhaustible False := {| AllElements := nil |}.
  Program Instance: Exhaustible Datatypes.Empty_set := {| AllElements := nil |}.
  (*Instance ex_prod `{Exhaustible A, Exhaustible B}
  : Exhaustible (A * B) := {| AllElements := fold_right (fun (a : A) acc => acc ++ map (fun b : B => (a, b)) AllElements) nil AllElements |}.
  Proof.
    intros [? ?].

  Instance ex_sum `{Exhaustible A, Exhaustible B}
  : Exhaustible (A + B) := {| AllElements := map inl AllElements ++ map inr AllElements |}.
  Proof.
    intros [a|b].

  intros [];
  repeat constructor.
Defined.
*)
End base.

Section simple_sat_solver.
  Section var.
    Variable idx : Type.
    Inductive atomic_term :=
    | Negated : idx -> atomic_term
    | Unnegated : idx -> atomic_term
    | ConstBool : bool -> atomic_term.

    Definition disjunct_clause := list atomic_term.

    Definition cnf_formula := list disjunct_clause.

    Section denote.
      Variable d : idx -> bool.

      Definition denote_atomic_term (t : atomic_term) :=
        match t with
          | Negated i => negb (d i)
          | Unnegated i => d i
          | ConstBool b => b
        end.

      Definition denote_disjunct_clause (t : disjunct_clause) :=
        fold_left orb (map denote_atomic_term t) false.

      Definition denote_cnf_formula (t : cnf_formula) :=
        fold_left andb (map denote_disjunct_clause t) true.
    End denote.
  End var.

  Section list.
    Variable tag : Type.

    Fixpoint map_of_list X
             (vars : list tag)
             (l : list X)
             (default : X)
             (i : Elem vars)
    : X
      := match i with
           | First _ _ => match l with
                            | nil => default
                            | x0 :: _ => x0
                          end
           | Next x l0 i0 =>
 @map_of_list X l0 (tl l) default i0
         end.

    Fixpoint solve_cnf_formula (vars : list tag) (t : cnf_formula (Elem vars))
    : { ds : list bool | denote_cnf_formula (map_of_list vars ds false) = true }
      + { forall f, denote_cnf_formula


    Definition empty_formula := cnf_formula nil.
  Fixpoint denote_formula (x : empty_formula)
