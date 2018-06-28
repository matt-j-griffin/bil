Require Import List.
Require Import Arith.
Require Import Omega.

Require Import bil.bil.


Fixpoint lift_above n (e : exp) : exp :=
match e with
| exp_var var5 => exp_var var5
| exp_letvar lid => exp_letvar (if lt_dec lid n then lid else (S lid))
| exp_int word5 => exp_int word5
| exp_mem e w v => exp_mem (lift_above n e) w v
| exp_load e1 e2 endian5 nat5 => exp_load (lift_above n e1) (lift_above n e2) endian5 nat5
| exp_store e1 e2 endian5 nat5 e3 =>
  exp_store (lift_above n e1) (lift_above n e2) endian5 nat5 (lift_above n e3)
| exp_binop e1 bop5 e2 => exp_binop (lift_above n e1) bop5 (lift_above n e2)
| exp_unop uop5 e => exp_unop uop5 (lift_above n e)
| exp_cast cast5 nat5 e => exp_cast cast5 nat5 (lift_above n e)
| exp_let e t eb => exp_let (lift_above n e) t (lift_above (S n) eb)
| exp_unk string5 type5 => exp_unk string5 type5
| exp_ite e1 e2 e3 => exp_ite (lift_above n e1) (lift_above n e2) (lift_above n e3)
| exp_ext hi lo e => exp_ext hi lo (lift_above n e)
| exp_concat e1 e2 => exp_concat (lift_above n e1) (lift_above n e2)
end.


Notation "^ e" := (lift_above 0 e) (at level 69, right associativity) : bil_exp_scope.

Fixpoint lift_above_m m n (e : exp) {struct e} : exp :=
match e with
| exp_var var5 => exp_var var5
| exp_letvar lid => exp_letvar (if lt_dec lid n then lid else (m + lid))
| exp_int word5 => exp_int word5
| exp_mem e w v => exp_mem (lift_above_m m n e) w v
| exp_load e1 e2 endian5 nat5 => exp_load (lift_above_m m n e1) (lift_above_m m n e2) endian5 nat5
| exp_store e1 e2 endian5 nat5 e3 =>
  exp_store (lift_above_m m n e1) (lift_above_m m n e2) endian5 nat5 (lift_above_m m n e3)
| exp_binop e1 bop5 e2 => exp_binop (lift_above_m m n e1) bop5 (lift_above_m m n e2)
| exp_unop uop5 e => exp_unop uop5 (lift_above_m m n e)
| exp_cast cast5 nat5 e => exp_cast cast5 nat5 (lift_above_m m n e)
| exp_let e t eb => exp_let (lift_above_m m n e) t (lift_above_m m (S n) eb)
| exp_unk string5 type5 => exp_unk string5 type5
| exp_ite e1 e2 e3 => exp_ite (lift_above_m m n e1) (lift_above_m m n e2) (lift_above_m m n e3)
| exp_ext hi lo e => exp_ext hi lo (lift_above_m m n e)
| exp_concat e1 e2 => exp_concat (lift_above_m m n e1) (lift_above_m m n e2)
end.

Lemma lift_above_above_m : forall m n e,
    lift_above_m m n (lift_above n e) = lift_above_m (S m) n e.
Proof.
  intros m n e; revert n; induction e; intro n; simpl; auto;
    try (repeat multimatch goal with
             [ H : forall n, _ = _ |- ?g] => try rewrite H; clear H
           end; reflexivity).
  - destruct (lt_dec lid5 n).
    destruct (lt_dec lid5 n).
    reflexivity.
    contradiction.
    destruct (lt_dec (S lid5) n).
    elim n0.
    omega.
    rewrite <- Nat.add_comm.
    simpl.
    rewrite <- Nat.add_comm.
    reflexivity.
Qed.

Lemma lift_above_0 : forall n e, lift_above_m 0 n e = e.
Proof.
  intros; revert n; induction e; intro n; simpl; auto;
    try (repeat multimatch goal with
             [ H : forall n, _ = _ |- ?g] => try rewrite H; clear H
           end; reflexivity).
  - destruct (lt_dec lid5 n);reflexivity.
Qed.

Notation "g ; lg |-- e ::: t" := (type_exp g lg e t) (at level 99) : type_scope.

Lemma in_delta_types : forall id type v d,
    type_delta d ->
    In (var_var id type, v) d ->
     nil; nil |-- v ::: type.
Proof.
  intros id type v d td v_in.
  induction td.
  - contradiction.
  - destruct v_in.
    + inversion H1.
      rewrite <- H5.
      rewrite <- H4.
      assumption.
    + apply IHtd; assumption.
Qed.



Definition var_id : var -> id :=
(fun v : var => match v with
                | var_var id0 _ => id0
                end).

Lemma typ_gamma_remove_var : forall g x g', typ_gamma (g ++ x :: g') -> typ_gamma (g ++ g').
Proof.
  intros g x g'; revert g g' x.
  induction g as [| x g].
  - simpl.
    intros g' x txg'.
    inversion txg'; assumption.
  -  simpl.
     intros g' x0 txgxn.
     inversion txgxn as [G | G id t nin tgxn x_eq_x].
     apply IHg in tgxn.
     fold var_id in nin.
     apply tg_cons.
     fold var_id.
     rewrite map_app.
     rewrite map_app in nin.
     simpl in nin.
     intro nin'.
     apply in_app_or in nin'.
     apply nin.
     apply in_or_app.
     destruct nin'.
     left; assumption.
     right; right; assumption.
     assumption.
Qed.

(*
Ltac unique_suffices_type_exp_base :=
match goal with
    | [ H_tG : typ_gamma ?G, H_G_eq : ?G = ?x :: ?g |- _ ] =>
      destruct H_tG; inversion H_G_eq;
        match goal with
        | [ H_g_eq : ?G = g |- _ ] =>
          rewrite H_g_eq in H_tG;
            apply t_int;
            assumption
        end
    end.

Lemma unique_suffices_type_exp : forall (g g' : gamma) x e t,
    In x (g ++ g')->
    type_exp (g ++ x::g') e t ->
    type_exp (g ++ g') e t.
Proof.
  intros g g' x e t x_in_g xg_te.
  remember (g ++ x :: g') as gxg'.
  induction xg_te.
  - destruct H0; inversion Heqgxg'.
    elim (app_cons_not_nil g g' x); assumption.
    destruct (eq_var (var_var id5 t) x).
    + rewrite <- e in x_in_g.
      apply t_var.
      * apply x_in_g.
      * apply H0.
    + rewrite Heqxg in H.
      destruct H.
      * elim n; symmetry; apply H.
      * apply t_var; assumption.
  - unique_suffices_type_exp_base.
  - apply (t_load _ e1 e2 ed sz nat5); auto.
  - apply (t_store _ e1 e2 ed sz e3); auto.
  - apply t_aop; auto.
  - apply (t_lop _ e1 lop5 e2 sz); auto.
  - apply t_uop; auto.
  - apply (t_cast _ _ _ _ nat5); auto.
  - apply t_let; auto.
    


Lemma fv_impl_exp_v : forall x e, In x (fv_exp e) -> In x (vars_in_exp e).
  intros x e.
  induction e.
  all: try (simpl; tauto).
  all: try (simpl;  intro x_in;  apply in_app_or in x_in; apply in_or_app; firstorder).
  - apply in_app_or in H.
    firstorder.
  - right.
    simpl; right.
    apply IHe2.
    apply (in_list_minus (fv_exp e2) (var5 :: nil)) in H.
    assumption.
  - apply in_app_or in H.
    firstorder.
Qed.
*)

Lemma type_exp_typ_gamma : forall g lg e t, g; lg |-- e ::: t -> typ_gamma g.
Proof.
  intros g lg e t te.
  induction te; auto.
Qed.

Ltac find_typed t :=
  multimatch goal with
  | [ e : t |- _ ] => e
  end.

Ltac do_for_all_exps tac :=
  first [ let app_tac := (apply t_letvarS) in tac app_tac
        | let app_tac := (apply t_letvarO) in tac app_tac
        | let app_tac := (apply t_var) in tac app_tac
        | let app_tac := (apply t_int) in tac app_tac
        | let app_tac := (apply t_unknown) in tac app_tac
        | let app_tac := (apply t_mem) in tac app_tac
        | let app_tac := (eapply t_load) in tac app_tac
        | let app_tac := (eapply t_store) in tac app_tac
        | let bop5 := find_typed bop in
          destruct bop5;
          first [ let app_tac := (apply t_aop) in tac app_tac
                | let app_tac := (eapply t_lop) in tac app_tac]
        | let app_tac := (apply t_aop) in tac app_tac
        | let app_tac := (eapply t_lop) in tac app_tac
        | let app_tac := (apply t_uop) in tac app_tac
        | let app_tac := (eapply t_cast) in tac app_tac
        | let app_tac := (eapply t_ite) in tac app_tac
        | let app_tac := (eapply t_extract) in tac app_tac
        | let app_tac := (eapply t_concat) in tac app_tac  ].

Lemma exp_weakening : forall g gw g' lg e t,
    (g ++ g');lg |-- e ::: t -> typ_gamma (g ++ gw ++ g') -> (g ++ gw ++ g');lg |-- e ::: t.
Proof.
  intros g gw g' lg e t et gt.
  remember (g ++ g') as G.
  generalize dependent g.
  induction et;
    intros g HeqG tGw;
    try constructor; auto.
  - rewrite HeqG in H.
    apply in_app_or in H.
    apply in_or_app.
    destruct H.
    + left; assumption.
    + right; apply in_or_app; right; assumption.
  - eapply t_load; auto; auto.
  - eapply t_lop; auto.
  - eapply t_cast; auto.
  - eapply t_extract; auto.
Qed.

(* TODO: put in bil.ott if works well *)
Notation "[m: e , w <- w' ]" := (exp_mem e w w') (at level 79) : bil_exp_scope.
Local Open Scope bil_exp_scope.

Ltac destruct_var_eqs :=
  repeat match goal with
           [ H : ?a = ?b |- _ ] =>
           (is_var a + is_var b);destruct H
         end.

Ltac on_all_hyps tac :=
  repeat match goal with
         | [ H : _ |- _ ] => progress tac H
         end.

(*Lemma type_exp_lift : forall g lg lg' e t m,
    g; lg |-- lift_above_m m 0 e ::: t ->
       g; lg'++lg |-- lift_above_m ((length lg')+m) 0 e ::: t.
Proof.
  intros g lg lg' e; revert g lg lg'.
  induction e; intros g lg lg' tt m te;
    try solve [
          induction lg'; simpl;  simpl in te;
          [ assumption
          | inversion IHlg'; constructor; assumption]].
  induction lg'; simpl; simpl in te;
    [ assumption
    | inversion IHlg'].
    apply t_letvarS;
    apply t_letvarO;
    assumption.
    apply t_letvarS.
    simpl in IHlg'.
    rewrite H, H1.
    assumption.

    simpl.
    inversion te.
    apply t_mem; auto.
    destruct_var_eqs.




Lemma exp_let_weakening_var : forall g lg wlg lg' lid t,
    g;lg++lg'|-- exp_letvar lid ::: t ->
      g; lg ++ wlg ++ lg' |-- lift_above_m (length wlg) (length lg) (exp_letvar lid) ::: t.
Proof.
  intros g lg wlg lg' lid t tlid.
  simpl.
  destruct (lt_dec lid (length lg)).
  - remember (exp_letvar lid) as e.
    inversion l.
    induction tlid; inversion Heqe.
    destruct lg.
    simpl in l; omega.
    
    + apply t_letvarO; assumption.
    + rewrite <- app_comm_cons.
      apply t_letvarS.
      apply IHlg.



    destruct lg; simpl in l; try omega.*)

Lemma canonical_word : forall w : word,
    w = Sized_Word.sized (Word.natToWord (projT1 w) (Word.wordToNat (projT2 w))).
Proof.
  intro w; destruct w.
  simpl.
  rewrite Word.natToWord_wordToNat.
  auto.
Qed.


Lemma exp_let_weakening_int : forall g lg lg' w t,
    g;lg|-- exp_int w ::: t -> g; lg ++ lg' |-- exp_int w ::: t.
Proof.
  induction lg.
  simpl.
  intros lg' w t tw.
  inversion tw.
  apply t_int; auto.
  intros lg' w t tw.
  inversion tw.
  apply t_int; auto.
Qed.

Lemma exp_let_weakening1 : forall g lg lg' e t,
    g;lg|-- e ::: t -> g; lg ++ lg' |-- e ::: t.
Proof.
  intros g lg lg' e t.
  revert lg lg' t.
  induction e;
    intros lg lg' tt te;
    inversion te;
    destruct_var_eqs;
    let app_tac t := t; eauto in
    try solve [do_for_all_exps app_tac].
  - rewrite <- app_comm_cons;
    apply t_letvarS;
    generalize dependent Gl;
    induction lid0;
    intros Gl te te1;
    inversion te;
    [rewrite <- app_comm_cons;
     apply t_letvarO;
     assumption
    | apply t_letvarS;
      apply IHlid0;
      [|apply t_letvarS];
      assumption].
  -apply t_mem; auto.
    apply exp_let_weakening_int.
    assumption.
  - apply t_let.
    apply IHe1.
    assumption.
    rewrite app_comm_cons.
    apply IHe2.
    assumption.
Qed.

Lemma exp_let_strengthening_letvar : forall g lg lg' lid t,
    lid < (length lg) ->
    g; lg ++ lg' |-- exp_letvar lid ::: t ->
       g;lg|-- exp_letvar lid ::: t.
Proof.
  intros.
  induction lg'.
  rewrite app_nil_r in H0.
  assumption.
  apply IHlg'.
  induction lg.
  simpl in H; omega.
  rewrite

Lemma exp_let_strengthening : forall g lg lg' e t,
    (forall i, In i (lfv_exp e) -> i < (length lg)) ->
    g; lg ++ lg' |-- e ::: t ->
       g;lg|-- e ::: t.
Proof.
  intros g lg lg' e t lfv_lt et.
  induction et; simpl in lfv_lt;
    simpl;
    let app_tac t := simpl; t; eauto in
    try solve [do_for_all_exps app_tac].
  specialize (lfv_lt 0 (or_introl eq_refl)).
  destruct lg;[simpl in lfv_lt; omega|].
  apply t_letvarO.

  induction e; simpl;
    intros lg lg' tt lfv_lt te;
    inversion te;
    let app_tac t := simpl; t; eauto in
    try solve [do_for_all_exps app_tac].
  - destruct_var_eqs.
    specialize (lfv_lt 0 (or_introl eq_refl)).
    destruct lg.
    simpl in lfv_lt; omega.
    rewrite <- app_comm_cons in H.
    inversion H.
    destruct_var_eqs.
    apply t_letvarO.
    assumption.
  - destruct_var_eqs.
    specialize (lfv_lt (S lid0) (or_introl eq_refl)).
    destruct lg;[simpl in lfv_lt; omega|].
    rewrite <- app_comm_cons in H.
    inversion H.
    apply t_letvarS.
    

Lemma exp_let_weakening : forall g lg wlg lg' e t,
    g;lg++lg'|-- e ::: t -> g; lg ++ wlg ++ lg' |-- lift_above_m (length wlg) (length lg) e ::: t.
Proof.
  intros g lg wlg lg' e; revert lg wlg lg'.
  induction e; intros; simpl; inversion H.
  - apply t_var; auto.
  - destruct (lt_dec 0 (length lg)).
    + destruct lg.
      simpl in l; omega.
      inversion H0.
      rewrite <- H6;
        rewrite H4.
      apply t_letvarO; auto.
    + rewrite Nat.add_comm.
      simpl.
      assert (length lg = 0).
      omega.
      apply length_zero_iff_nil in H5.
      rewrite H5.
      simpl.
      rewrite H5 in H0; simpl in H0.
      induction wlg.
      * simpl.
        rewrite <- H0.
        rewrite H4.
        apply t_letvarO.
        assumption.
      * simpl.
        apply t_letvarS.
        assumption.
  - destruct (lt_dec (S lid0) (length lg)).
    + apply exp_let_weakening1.
      destruct_var_eqs.
      remember (exp_letvar lid5) as e.
      destruct_var_eqs.
      
      induction H; inversion Heqe;
      destruct_var_eqs;
      inversion H2.
      rewrite <- H4.
      apply IHtype_exp.
      

      destruct lg; simpl in l; [> omega |].
      rewrite <- app_comm_cons.
      apply t_letvarS.
      inversion H0.
      apply le_S_n in l.
      induction lg.
      simpl in l; omega.
      

Lemma subst_lfv : forall x y e1 e2,
    In y (lfv_exp (letsubst_exp e1 x e2)) -> In y (lfv_exp e1) \/  In y (lfv_exp e2).
Proof.
  intros x y e1 e2 in_y_subst_e1.
  destruct (in_dec eq_letvar y (lfv_exp e1)).
  - left; assumption.
  - right; apply (subst_lfv_notin_e1 x y e1 e2); assumption.
Qed.

Ltac apply_all e t:=
  repeat match goal with
         | [ H : forall _ : t, _ |- _ ] =>
           specialize (H e)
         end.

Ltac subst_lfv_neq_rec_case :=
  intros e1 x_nin_lfv_e1 in_y_subst_e1;
  simpl in in_y_subst_e1;
  apply_all e1 exp;
  repeat (apply in_app_or in in_y_subst_e1;
          destruct in_y_subst_e1 as [in_subst_es_1 | in_y_subst_e1];
          try tauto).

Lemma subst_lfv_neq : forall x y e1 e2,
    ~ In x (lfv_exp e1) ->
    In y (lfv_exp (letsubst_exp e1 x e2)) -> ~ y = x.
Proof.
  intros x y e1 e2 x_nin_lfv_e1 in_y_subst_e1 x_eq_y.
  rewrite x_eq_y in in_y_subst_e1.
  generalize dependent e1.
  induction e2.
  all: try contradiction.
  all: auto.
  all: try solve [subst_lfv_neq_rec_case].
  - intros e1 x_nin_lfv_e1 in_y_subst_e1.
    simpl in in_y_subst_e1.
    destruct (eq_letvar letvar5 x).
    + contradiction.
    + destruct in_y_subst_e1.
      * contradiction.
      * tauto.
  - intros e1 x_nin_lfv_e1 in_y_subst_e1.
    simpl in in_y_subst_e1.
    apply in_app_or in in_y_subst_e1.
    destruct in_y_subst_e1 as [in_subst_es_1 | in_y_subst].
    + firstorder.
    + apply (IHe2_2 e1).
      * assumption.
      * destruct (eq_letvar letvar5 x).
        -- rewrite <- e in in_y_subst.
           apply in_list_minus in in_y_subst.
           destruct in_y_subst.
           simpl in H0.
           elim H0.
           left; reflexivity.
        -- apply in_list_minus in in_y_subst.
           destruct in_y_subst.
           assumption.
Qed.

Ltac in_subst_lfv_rec_case :=
  intros x y e1 xneq iny;
  simpl;
  simpl in iny;
  repeat
    match goal with
    | [ H : forall (x y : letvar) (e1 : exp), _ |- _ ] =>
      specialize H with x y e1
    end;
  repeat
    match goal with
    | [ H : ?P -> _, H' : ?P |- _ ] =>
      specialize (H H')
    end;
  repeat
    (try apply in_or_app;
     apply in_app_or in iny;
     destruct iny as [iny | iny];
     match goal with
     | [ H : ?P -> ?GL, H' : ?P |- ?GL \/ _ ] =>
       left; apply H; assumption
     | [ H : ?P -> ?GR, H' : ?P |- _ \/ ?GR ] =>
       right; apply H; assumption
     | [ |- _ \/ _ ] =>
       right
     end).


Lemma in_subst_lfv : forall x y e1 e2,
    x <> y ->
    In y (lfv_exp e2) ->
    In y (lfv_exp (letsubst_exp e1 x e2)).
Proof.
  intros x y e1 e2; revert x y e1; induction e2.
  all: try solve [auto | in_subst_lfv_rec_case].
  - simpl.
    intros x y e1 xneq yin.
    destruct yin as [yeq | fls]; try contradiction.
    destruct(eq_letvar letvar5 x).
    + rewrite e in yeq; contradiction.
    + simpl; left; assumption.
  - simpl.
    intros x y e1 xne yin.
    repeat
      match goal with
      | [ H : forall (x y : letvar) (e1 : exp), _ |- _ ] =>
        specialize H with x y e1
      end.
    repeat
      match goal with
      | [ H : ?P -> _, H' : ?P |- _ ] =>
        specialize (H H')
      end.
      destruct(eq_letvar letvar5 x).
      + rewrite e.
        rewrite e in yin.
        try apply in_or_app;
          apply in_app_or in yin;
          destruct yin as [yin | yin].
        * left; apply IHe2_1; assumption.
        * right; assumption.
      + try apply in_or_app;
          apply in_app_or in yin.
        destruct yin as [yin | yin].
        * left; apply IHe2_1; assumption.
        * right. apply in_list_minus.
          apply in_list_minus in yin.
          destruct yin.
          constructor; try apply IHe2_2; assumption.
Qed.

Ltac type_exp_no_lfv_rec_case :=
  simpl;
  repeat match goal with
         | [ H : ?e1 = nil |- ?e1 ++ ?e2 = nil ] =>
           rewrite H; simpl
         end;
  auto.

Lemma notin_nil : forall {A : Set} (l : list A), (forall e, ~In e l) -> l = nil.
Proof.
  intros A l nin.
  induction l.
  - reflexivity.
  - elim (nin a).
    simpl; left; reflexivity.
Qed.

Lemma type_exp_no_lfv : forall g e t, type_exp g e t -> lfv_exp e = nil.
Proof.
  intros g e t te.
  induction te.
  all: try solve [auto | type_exp_no_lfv_rec_case].
  - apply notin_nil.
    simpl.
    rewrite IHte1.
    simpl.
    intros x in_e_let.
    rewrite in_list_minus in in_e_let.
    destruct in_e_let.
    simpl in H0.
    pose proof in_nil as inn.
    specialize inn with (A := letvar).
    rewrite <- IHte2 in inn.
    destruct (inn x).
    apply in_subst_lfv; auto.
Qed.

Lemma letsubst_fv_exp : forall x y e1 e2,
      In y (fv_exp (letsubst_exp e1 x e2)) ->
      In y (fv_exp e1) \/ In y (fv_exp e2).
Proof.
  intros x y e1 e2 iny.
  induction e2.
  all:
    try solve
        [ auto
        | simpl;
          simpl in iny;
          repeat
            (apply in_app_or in iny;
             destruct iny as [iny | iny];
             firstorder)].
  - simpl in iny.
    destruct (eq_letvar letvar5 x); auto.
  - simpl.
    simpl in iny.
    apply in_app_or in iny;
      destruct iny as [iny | iny];
      firstorder.
    destruct (eq_letvar letvar5 x).
    + right; apply in_or_app; right; assumption.
    + specialize (IHe2_2 iny).
      destruct IHe2_2.
      * left; assumption.
      * right; apply in_or_app; right; assumption.
Qed.


Lemma nin_list_assoc : forall {A B: Set} eq x l,
            (forall e, ~In (x,e)l) -> list_assoc (A:=A) (B:=B) eq x l = None.
Proof.
  intros A B eq e l nin.
  induction l.
  - simpl; auto.
  - destruct a; simpl.
    simpl in nin.
    destruct (eq a e).
    specialize nin with (e0 := b).
    elim nin.
    left; f_equal; auto.
    apply IHl.
    intro e0;
    specialize nin with (e0 := e0).
    intro in_el.
    elim nin.
    right; assumption.
Qed.


Lemma let_multisubst_closed : forall l e,
    (forall x es, In (x,es) l -> ~In x (lfv_exp e)) ->
    let_multisubst_exp l e = e.
Proof.
  intros l e; revert l.
  induction e; auto;
    try solve [
          intros l e_closed;
          simpl;
          f_equal;
          match goal with
          | [ IH : forall l, _ -> let_multisubst_exp l ?e = ?e
                             |- let_multisubst_exp ?l ?e = ?e] =>
            apply IH
          end;
          intros x es in_l infv;
          elim (e_closed x es in_l);
          simpl;
          repeat (apply in_or_app;
                  auto;
                  right);
          auto].
  - intros l e_closed.
    induction l.
    + simpl; reflexivity.
    + destruct a.
      destruct (eq_letvar l0 letvar5).
      * destruct e0.
        specialize e_closed with (x := l0) (es := e).
        simpl in e_closed.
        elim e_closed;
        left; reflexivity.
      * simpl.
        destruct (eq_letvar l0 letvar5); try contradiction.
        simpl in e_closed.
        assert (forall e, ~In (letvar5,e) l).
        intros e0 lv5_inl.
        elim e_closed with (x := letvar5) (es := e0).
        right; assumption.
        left; reflexivity.
        pose proof (nin_list_assoc (A:=letvar)(B:=exp)) as nla.
        specialize (nla eq_letvar letvar5 l H).
        rewrite nla.
        reflexivity.
  - intros l e_closed;
    simpl;
    f_equal;
    match goal with
    | [ IH : forall l, _ -> let_multisubst_exp l ?e = ?e |- let_multisubst_exp ?l ?e = ?e] =>
      apply IH
    end;
    intros x es in_l infv.
    elim (e_closed x es in_l);
    simpl.
    repeat (apply in_or_app;
            auto).
    apply in_list_minus2 in in_l.
    destruct in_l.
    elim (e_closed x es).
    assumption.
    simpl.
    apply in_or_app.
    right.
    apply in_list_minus.
    auto.
Qed.

Lemma list_assoc_app : forall {A B} eq (l l' : list (A*B)) x,
    list_assoc eq x (l ++ l') = match list_assoc eq x l with
                                  | Some e => Some e
                                  | None => list_assoc eq x l'
                                end.
Proof.
  intros A B eq l l' x; induction l; simpl; auto.
  destruct a;
    simpl.
  destruct (eq a x); auto.
Qed.

Definition default {A : Set} (a : option A) base :=
  match a with Some e => e | None => base end.

Lemma option_match_fn : forall {A B : Set} (f : A -> B) x y,
    f (default x y) = default (option_map f x) (f y).
Proof.
  intros A B f x y.
  destruct x; simpl; reflexivity.
Qed.

Lemma option_match_fn' : forall {A B : Set} (f : A -> B) x y,
    f (default x y) = match x with Some x => f x | None => f y end.
Proof.
  intros A B f x y.
  destruct x; simpl; reflexivity.
Qed.

Lemma match_option_assoc : forall {A : Set} (x y : option A) (z : A),
    match match x with Some x' => Some x' | None => y  end with
    | Some e => e
    | None => z
    end
    = default x (default y z).
Proof.
  intros A x y z.
  destruct x; simpl; auto.
Qed.

Lemma list_assoc_res_in : forall {A B : Set} dec (x : A) (e : B) l,
    Some e = list_assoc dec x l -> In (x,e) l.
Proof.
  intros.
  induction l.
  simpl in H; inversion H.
  simpl.
  inversion H.
  destruct a.
  destruct (dec a x).
  inversion H1.
  left; f_equal; auto.
  right.
  apply IHl.
  assumption.
Qed.


Lemma list_minus2_distr : forall {A B : Set} eq (l l' : list (A * B)) (lm : list A),
    list_minus2 eq (l' ++ l) lm
    = (list_minus2 eq l' lm) ++ (list_minus2 eq l lm).
Proof.
  intros.
  induction l'.
  simpl; auto.
  destruct a.
  simpl.
  destruct (list_mem eq a lm).
  assumption.
  rewrite <- app_comm_cons.
  f_equal.
  assumption.
Qed.


Lemma let_multisubst_app : forall l l' e,
    (forall x es, In (x,es) l' -> lfv_exp es = nil) ->
    let_multisubst_exp l (let_multisubst_exp l' e) = let_multisubst_exp (l' ++ l) e.
Proof.
  intros l l' e; revert l l'.
  induction e; auto;
    intros l l' l'_exp_closed;
    simpl;
    try solve [f_equal;
    multimatch goal with
    | [ IH : forall l l', _ ->
         let_multisubst_exp l (let_multisubst_exp l' ?e)
         = let_multisubst_exp (l' ++ l) ?e
      |- let_multisubst_exp ?l (let_multisubst_exp ?l' ?e)
         = let_multisubst_exp (?l' ++ ?l) ?e ] =>
      apply IH; assumption
    end].
  - rewrite list_assoc_app.
    remember (list_assoc eq_letvar letvar5 l') as assoc_res.
    destruct assoc_res.
    specialize l'_exp_closed with (x := letvar5) (es := e).
    apply let_multisubst_closed.
    intros x es inxes nin.
    apply list_assoc_res_in in Heqassoc_res.
    apply l'_exp_closed in Heqassoc_res.
    rewrite Heqassoc_res in nin.
    tauto.
    simpl.
    reflexivity.
  - f_equal;
    try multimatch goal with
    | [ IH : forall l l', _ ->
         let_multisubst_exp l (let_multisubst_exp l' ?e)
         = let_multisubst_exp (l' ++ l) ?e
      |- let_multisubst_exp ?l (let_multisubst_exp ?l' ?e)
         = let_multisubst_exp (?l' ++ ?l) ?e ] =>
      apply IH; assumption
    end.
    rewrite list_minus2_distr.
    apply IHe2.
    intros x es inxeslm.
    apply l'_exp_closed with (x := x).
    apply in_list_minus2 in inxeslm.
    destruct inxeslm.
    assumption.
Qed.


Ltac var_in_fvs :=
  try apply in_or_app;
  first [ assumption | left; assumption | right; assumption | right; var_in_fvs].

Ltac strengthen_rec_case C :=
  apply C;
  repeat match goal with
  | [ HG : ?G = _, Ht : typ_gamma ?G |- _ ] =>
    rewrite HG in Ht;
    inversion Ht
         end;
  try auto;
  progress repeat match goal with
  | [ H1 : ?P1, H2 : ~ In ?x _, IH : ?P1 -> ~ In ?x _ -> ?P2 |- ?P2 ] =>
    apply IH; first [apply H1 | intro x_in; elim H2; simpl; var_in_fvs]
  end.

(*
Lemma fv_subst_notin : forall x e e',
    ~In x (fv_exp e) ->
    ~In x (fv_exp (subst_exp e x e')).
Proof.
  intros x e e'.
  remember (subst_exp e x e') as se.
  induction se.
  - intros ninxe.
    destruct (eq_var var5 x).
    rewrite e0 in Heqse.
    
      try (simpl in inxsubst; inversion inxsubst).
      contradiction.
  - intros e x nxe inxsubst.
    simpl in inxsubst; inversion inxsubst.
  - intros e x nxe inxsubst.
    simpl in inxsubst.
    apply in_app_or in inxsubst.
    inversion inxsubst.
    apply IHe'1.
*)

Lemma exp_strengthening : forall g e t x,
    type_exp (cons x g) e t -> ~ In x (fv_exp e) -> type_exp g e t.
Proof.
  intros g e t x te n_in_fv.
  fold gamma in g.
  remember (x :: g) as g'.
  induction te.
  - rewrite Heqg' in H.
    rewrite Heqg' in H0.
    simpl in n_in_fv.
    inversion H0.
    inversion H.
    + symmetry in H5.
      elim n_in_fv.
      left; assumption.
    + apply t_var.
      apply H5.
      apply H4.
  - rewrite Heqg' in H0.
    inversion H0.
    apply t_int; assumption.
  - strengthen_rec_case t_mem.
  - strengthen_rec_case (t_load g e1 e2 ed  sz' sz nat5).
  - strengthen_rec_case (t_store g e1 e2 ed sz' e3).
  - strengthen_rec_case (t_aop g e1 aop5 e2).
  - strengthen_rec_case (t_lop g e1 lop5 e2 sz).
  - strengthen_rec_case (t_uop g uop5 e1).
  - strengthen_rec_case (t_cast g cast5 sz e nat5).
  -  apply t_let.
     progress repeat match goal with
                     | [ H1 : ?P1, H2 : ~ In ?x _, IH : ?P1 -> ~ In ?x _ -> ?P2 |- ?P2 ] =>
                       apply IH; first [apply H1 | intro x_in; elim H2; simpl]
                     end.
     try apply in_or_app.
     left; assumption.
     progress repeat match goal with
                     | [ H1 : ?P1, H2 : ~ In ?x _, IH : ?P1 -> ~ In ?x _ -> ?P2 |- ?P2 ] =>
                       apply IH; first [apply H1 | intro x_in; elim H2; simpl]
                     end.
     try apply in_or_app.
     apply (letsubst_fv_exp (letvar_var id5 t) x).
     assumption.
  - apply t_unknown.
    inversion H.
    + rewrite Heqg' in H0; inversion H0.
    + rewrite Heqg' in H2.
      inversion H2.
      rewrite H5 in H1; assumption.
  - strengthen_rec_case t_ite.
  - strengthen_rec_case (t_extract g sz1 sz2 e sz).
  - strengthen_rec_case  t_concat.
Qed.

Ltac exp_exchange_simple_base G :=
  match goal with
  | [ H : typ_gamma G |- _ ] =>
    inversion H as [| G' id1' t1' notin_id1' G'_wf];
    inversion G'_wf as [| g' id2' t2' notin_id2' g'_wf];
    apply tg_cons;
    first [intro notin_id2; inversion notin_id2; contradiction
          | apply tg_cons; assumption]
  end.

(*
Lemma exp_exchange : forall id1 id2 t1 t2 g e t,
    id1 <> id2 ->
    ~ In id1 (map var_id g) ->
    ~ In id2 (map var_id g) ->
    type_exp ((var_var id1 t1) :: (var_var id2 t2) :: g) e t ->
    type_exp ((var_var id2 t2) :: (var_var id1 t1) :: g) e t.
Proof.
  intros id1 id2 t1 t2 g e t idneq id1_nin id2_nin te.
  remember (var_var id1 t1 :: var_var id2 t2 :: g) as G12.
  induction te.
  - rewrite HeqG12 in H.
    simpl in H.
    apply t_var.
    + simpl.
      firstorder.
    + inversion H0 as [| G' id1' t1' notin_id1' G'_wf];
        rewrite HeqG12 in H1; inversion H1.
      rewrite H3 in notin_id1'.
      inversion G'_wf as [| g' id2' t2' notin_id2' g'_wf].
      repeat (apply tg_cons;
              try first [intro notin_id2; inversion notin_id2; contradiction
                        | try apply tg_cons; assumption]).
      rewrite H5 in G'_wf.
      inversion G'_wf.
      assumption.
      

exp_exchange_simple_base (var_var id1 t1 :: var_var id2 t2 :: g).
  - apply t_int.
    exp_exchange_simple_base (var_var id1 t1 :: var_var id2 t2 :: g).
  - apply (t_load _ e1 e2 ed sz nat5); auto.
  - apply (t_store _ e1 e2 ed sz e3); auto.
  - apply t_aop; auto.
  - apply (t_lop _ e1 lop5 e2 sz); auto.
  - apply t_uop; auto.
  - apply (t_cast _ _ _ _ nat5); auto.
  - apply t_let.
    auto.
    apply type_exp_typ_gamma in te2.
    inversion te2.
    apply IHte2.
    + intro id5_in_g0.
      apply H1.
      simpl.
      inversion id5_in_g0.
      * simpl in H1; left; assumption.
      * right; right; assumption.
    + intro eq25.
      apply H1.
      simpl.
      right; left; assumption.
    + intro id2_in_g0.
      destruct id2_in_g0;  contradiction.
    + 
     rewrite H.
      destruct id5_in_g0.
      * simpl in H.
        apply type_exp_typ_gamma in te2.
        inversion te2.
        destruct H2.
        rewrite H.
        simpl; left; reflexivity.
      *
      inversion te2.
      inversion H0.
      fold var_id in H6.
      simpl in H6.
      
  - apply t_aop; auto.
  - apply t_aop; auto.
  - apply t_aop; auto.
  - apply t_aop; auto.
  - apply t_aop; auto.
  - apply t_aop; auto.
  - apply t_aop; auto.
  - apply t_aop; auto.
  - apply t_aop; auto.
  - apply t_aop; auto.
  - apply t_aop; auto.
  -
*)

(*
Definition as_imm_type

Fixpoint infer (g : gamma) (e : exp) : option type :=
  match e with
  | exp_var (var_var id t) => if In (var_var id t) g then Some t else None
  | exp_letvar (letvar_var _ t) => None
  | exp_int (existT _ sz _) => Some (type_imm sz)
  | exp_load em ew _ sz =>
    emt <- infer gamma em;
      ewt <- infer gama ew;
      wsz <- as_imm_type ewt;
 *)

Lemma type_exp_unique : forall g e t,
    type_exp g e t -> forall t', type_exp g e t' -> t = t'.
Proof.
  intros g e t te;
  induction te;
    intros t0 t0e;
    inversion t0e.
  all: try reflexivity.
  all: try match goal with
    | [ IH : forall t', type_exp ?g ?e t' -> ?GL = t',
          H : type_exp ?g ?e ?GR |- ?GL = ?GR ] =>
      apply IH; assumption
    end.
  - repeat match goal with
           | [ IH : forall t', type_exp ?g ?e t' -> _ = t',
                 H : type_exp ?g ?e _ |- _ ] =>
             apply IH in H
           end.
    inversion H2.
    inversion H4.
    reflexivity.
Qed.


Lemma subst_inversion : forall es x e,
    e <> exp_letvar x -> ~ In x (lfv_exp es) ->
    (forall y, [es./x]e = exp_var y -> e = exp_var y) /\
    (forall y, [es./x]e = exp_letvar y -> e = exp_letvar y /\ x <> y) /\
    (forall w, [es./x]e = exp_int w -> e = exp_int w) /\
    (forall e1 e2 ed sz, [es./x]e = exp_load ([es./x]e1) ([es./x]e2) ed sz ->
                         e = exp_load e1 e2 ed sz) /\
    (forall e1 e2 ed sz e3, [es./x]e = exp_store ([es./x]e1) ([es./x]e2) ed sz ([es./x]e3) ->
                            e = exp_store e1 e2 ed sz e3) /\
    (forall e1 op e2, [es./x]e = exp_binop ([es./x]e1) op ([es./x]e2) -> e = exp_binop e1 op e2) /\
    (forall op e1, [es./x]e = exp_unop op [es./x]e1 -> e = exp_unop op e1) /\
    (forall c sz e1, [es./x]e = exp_cast c sz [es./x]e1 -> e = exp_cast c sz e1) /\
    (forall e1 e2, [es./x]e = exp_let x [es./x]e1 e2 -> e = exp_let x e1 e2 ) /\
    (forall y e1 e2, [es./x]e = exp_let y [es./x]e1 [es./x]e2 -> x <> y -> e = exp_let y e1 e2 ) /\
    (forall str t, [es./x]e = exp_unk str t -> e = exp_unk str t) /\
    (forall e1 e2 e3, [es./x]e = exp_ite [es./x]e1 [es./x]e2 [es./x]e3 -> e = exp_ite e1 e2 e3) /\
    (forall sz1 sz2 e1, [es./x]e = exp_ext sz1 sz2 [es./x]e1 -> e = exp_ext sz1 sz2 e1) /\
    (forall e1 e2, [es./x]e = exp_concat [es./x]e1 [es./x]e2 -> e = exp_concat e1 e2).
Proof.
  intros es x e enl nisl.
  repeat constructor; induction e; simpl.
  all: try solve [try destruct (eq_letvar letvar5 x); intros; inversion H;
                  try first [reflexivity
                            | elim enl; f_equal; assumption]].
  simpl in H.
  destruct (eq_letvar letvar5 x); try (rewrite e in enl; contradiction).
  assumption.
  simpl in H.
  destruct (eq_letvar letvar5 x); try (rewrite e in enl; contradiction).
  intro.
  inversion H.
  elim n.
  rewrite H0.
  assumption.
Admitted.

(*
  intros.
  inversion H.


  simpl.
  all: try solve [intros; inversion H | auto].
  destruct (eq_letvar letvar5 x).
  rewrite e in enl; contradiction.
  auto.
  inversion H.

  all: try (destruct (eq_letvar letvar5 x); try (rewrite e in enl; contradiction)).
  simpl.
  try destruct (eq_letvar letvar5 x).
  rewrite e in enl; contradiction.
  auto.
  inversion H.
  simpl; try destruct (eq_letvar letvar5 x); try (rewrite e in enl; contradiction).
  auto.
  auto.
  - rewrite <- H.
    simpl.
    destruct (eq_letvar letvar5 x); try (rewrite e in enl; contradiction).
    reflexivity.
  - simpl in H.
    destruct (eq_letvar letvar5 x); try (rewrite e in enl; contradiction).
    inversion H.
    rewrite <- H1; intro eq; symmetry in eq; contradiction.
  - 
    destruct (eq_letvar letvar5 x); try (rewrite e in enl; contradiction).



  constructor.
  intros y H.
  inversion H.
  constructor.
  assumption.
  inversion H.
  simpl;
    intros;
    destruct (eq_letvar letvar5 x);
    solve [rewrite e in enl; contradiction | auto].
  constructor.
  induction e; simpl; try solve [auto | intros y H; inversion H].
  intros;
    destruct (eq_letvar letvar5 x).
  rewrite e in enl; contradiction.
  inversion H.
  rewrite H1 in n.
  firstorder.
  constructor.
  induction e; simpl; try solve [auto | intros y H; inversion H].
  intros;
    destruct (eq_letvar letvar5 x).
  rewrite e in enl; contradiction.
  auto.
  constructor.
  - induction e; simpl; try solve [auto | intros; inversion H].
    + intros.
      destruct (eq_letvar letvar5 x).
      rewrite e in enl; contradiction.
      inversion H.
    + intros.
      inversion H.
      destruct (eq_exp e0 (exp_letvar x));
        destruct (eq_exp e1 (exp_letvar x));
        destruct (eq_exp e2 (exp_letvar x));
        destruct (eq_exp e3 (exp_letvar x)).
      * rewrite e, e4, e5, e6.
        reflexivity.
      * rewrite e5 in H2.
        simpl in H2.
        destruct (eq_letvar x x); try contradiction.
        

Lemma subst_eq_esubst : forall e x es, es = [es./x]e -> e = exp_letvar x \/ e = es.
Proof.
  intros e x.
  induction e; simpl; auto; intros es es_eq.
  - destruct (eq_letvar letvar5 x).
    + rewrite e.
      left; reflexivity.
    + right; symmetry; assumption.
  - inversion es_eq.


elim n.
        

        rewrite e in H1.
        rewrite e4 in H1.
        
        repeat match goal with
             |

  constructor.
  *)

Lemma letsubst_inversion_var : forall es x e y,
    e <> exp_letvar x -> [es./x]e = exp_var y -> e = exp_var y.
Proof.
  intros es x e y enl.
  induction e.
  all: simpl; try solve [auto | intro H; inversion H].
  simpl;
    intros;
    destruct (eq_letvar letvar5 x);
    solve [rewrite e in enl; contradiction | auto].
Qed.


Lemma no_typed_letvar : forall g x t, ~ type_exp g (exp_letvar x) t.
Proof.
  intros g x e te.
  inversion te.
Qed.

Ltac letsubst_unused_rec_case :=
  f_equal;
  let H := match goal with
             [ H : forall x es, ~In x _ -> [es./x]?e = ?e |- [_./_]?e = ?e] => H
           end in
  apply H;
  auto;
  let nin := match goal with
               [ nin : ~In _ _ |- _ ] => nin
             end in
  intro; elim nin;
  apply in_or_app;
  first [left; assumption
        | right; apply in_list_minus;
          solve [firstorder]
        | solve [firstorder]].

Lemma letsubst_unused : forall x es e,
    ~In x (lfv_exp e) -> [es./x]e = e.
Proof.
  intros x es e; revert x es.
  induction e;
    simpl;
    auto;
    intros x es nin;
    try solve[letsubst_unused_rec_case].
  - destruct (eq_letvar letvar5 x);
      [> elim nin; left; assumption
      | reflexivity].
  - destruct (eq_letvar letvar5 x);
    letsubst_unused_rec_case.
Qed.

Ltac letsubst_distributes_rec_case :=
  f_equal;
  match goal with
    [ IH : forall x y es1 es2,
        _ -> _ -> _ -> [es1./x]([es2./y]?e) = [es2./y]([es1./x]?e)
        |- [?es1 ./ ?x] ([?es2 ./ ?y] ?e) = [?es2 ./ ?y] ([?es1 ./ ?x] ?e) ] =>
    apply IH; assumption
  end.

Lemma letsubst_distributes : forall x y es1 es2 e,
    ~In y (lfv_exp es1) ->
    lfv_exp es2 = nil ->
    x <> y -> ([es1./x][es2./y]e) = [es2./y][es1./x]e.
  intros x y es1 es2 e; revert x y es1 es2.
  induction e;
        intros x y es1 es2 yni1 es2_closed xne;
        simpl;
        try solve [auto | letsubst_distributes_rec_case].
  - destruct (eq_letvar letvar5 y).
    + destruct (eq_letvar letvar5 x).
      * rewrite <- e in xne;
          rewrite <- e0 in xne;
          contradiction.
      * simpl.
        destruct (eq_letvar letvar5 y).
        apply letsubst_unused;
          rewrite es2_closed;
          auto.
        rewrite e in n0.
        contradiction.
    + destruct (eq_letvar letvar5 x).
      * simpl.
        destruct (eq_letvar letvar5 x);
          rewrite letsubst_unused;
          tauto.
      * simpl.
        destruct (eq_letvar letvar5 x);
          destruct (eq_letvar letvar5 y);
          tauto.
  - destruct (eq_letvar letvar5 x) as [lv5xe | nlv5xe];
    destruct (eq_letvar letvar5 y)as [lv5ye | nlv5ye].
     + rewrite <- lv5xe in xne.
       rewrite <- lv5ye in xne.
       contradiction.
     + rewrite lv5xe.
       letsubst_distributes_rec_case.
     + rewrite lv5ye.
       letsubst_distributes_rec_case.
     + letsubst_distributes_rec_case.
Qed.

Ltac subst_type_exp app_tac :=
  inversion et;
  match goal with
    [ H : ?t = ?t' |- _ |-- _ ::: ?t ] => destruct H
  end;
  app_tac; auto.

Lemma subst_type_exp : forall g e t es id ts,
            g |-- e ::: t ->
            g |-- es ::: ts ->
            g |-- [es./letvar_var id ts] e ::: t.
Proof.
  intros g e t es id ts et est.
  generalize dependent t.
  induction e; simpl;
    auto;
    intros t et.
  - destruct (eq_letvar letvar5 (letvar_var id ts)).
    destruct letvar5.
    inversion et.
    assumption.
  - let app_tac := (apply t_mem) in
    subst_type_exp app_tac.
  - let app_tac := (apply t_load with (sz := sz) (nat5 := nat0)) in
    subst_type_exp app_tac.
  - let app_tac := (apply t_store with (sz := sz) (nat5 := nat0)) in
    subst_type_exp app_tac.
  - destruct bop5.
    + let app_tac := (apply t_aop) in
      subst_type_exp app_tac.
    + let app_tac := (apply t_lop with (sz := sz)) in
      subst_type_exp app_tac.
  - let app_tac := (apply t_uop) in
    subst_type_exp app_tac.
  - let app_tac := (apply t_cast with (nat5 := nat0)) in
    subst_type_exp app_tac.
  -

Ltac get_var_from_type_subst_goal :=
  match goal with
    [ |- _ |-- ?e ::: _] =>
    match e with context [[_./?x]_] => x
    end
  end.

Ltac get_hyp_with_goal_type :=
  match goal with
    [ te : ?g |-- _ ::: ?t |- ?g |-- _ ::: ?t ] => te
  end.

Ltac type_subst_dec_subst_in_IH x te :=
   (multimatch goal with
     [ IH : forall t es1, _ ->  _ -> forall es, _ -> ?g |-- [es./x]?ei ::: t |- ?g |-- ?e ::: _] =>
     lazymatch e with context [[es./x]ei] =>
                      idtac "resolving via" IH;
                      let eq_e := fresh "eq_ei" in
                      let neq_e := fresh "neq_ei" in
                      destruct (eq_exp ei (exp_letvar x)) as [eq_e | neq_e];
                      idtac;
                      try rewrite eq_e;
                      simpl;
                      try rewrite eq_e in IH;
                      simpl in IH;
                      try rewrite eq_e in te
     end
   end
   || fail "No inductive hypothesis found");
  simpl in te;
  destruct (eq_letvar x x); try contradiction;
  idtac "inverting typing rule hypothesis";
  inversion te.

Ltac destruct_equalities_on t :=
  repeat match goal with
         | [H : ?t1 = ?t2 |- _] =>
           let tty := type of t1 in
           unify tty t;
           idtac "destructing equality:" t1 "=" t2;
           destruct H
         end.

Ltac unify_typing_judgments :=
  repeat multimatch goal with
         | [ TE1 : ?g |-- ?e ::: ?t1, TE2 : ?g |-- ?e ::: ?t2, _ : ?t1 = ?t2 |- _ ] => fail
         | [ TE1 : ?g |-- ?e ::: ?t1, TE2 : ?g |-- ?e ::: ?t2, _ : ?t2 = ?t1 |- _ ] => fail
         | [ TE1 : ?g |-- ?e ::: ?t1, TE2 : ?g |-- ?e ::: ?t2 |- _ ] =>
           let teq := fresh "teq" in
           pose proof type_exp_unique as teq;
           specialize teq with (g := g) (t := t1) (t' := t2);
           specialize (teq e TE1 TE2);
           idtac "unified" TE1 "and" TE2 "via uniqueness of types";
           clear TE2;
           destruct teq
         end.

Ltac type_subst_solve_IH :=
  solve [first [solve [eauto]
        | match goal with
          | [ IH : forall t es1, _ -> _ -> forall es, _ -> ?g |-- [es./?x]?e ::: t,
                TES1 : ?g |-- [?es1./?x]?e ::: ?t'
                |- ?g |-- [?es./?x]?e ::: ?t ] =>
            apply IH with (es1 := es1); assumption
          | [ IH : forall t es1, _ -> _ -> forall es, _ -> ?g |-- es ::: t,
                TES1 : ?g |-- [?es1./?x]?e ::: ?t'
                |- ?g |-- ?e ::: ?t ] =>
            apply IH with (es1 := es1); assumption
          end]].

Ltac type_subst_rec_case app_tac :=
  let x := get_var_from_type_subst_goal in
  idtac "substituted variable:" x;
  let te := get_hyp_with_goal_type in
  idtac "typing judgment for e:" te;
  type_subst_dec_subst_in_IH x te;
  app_tac;
  destruct_equalities_on type;
  unify_typing_judgments;
  type_subst_solve_IH.

Lemma type_subst : forall id g es1 es2 e ts t,
    g |-- es1 ::: ts ->
    g |-- es2 ::: ts ->
    g |-- ([es1 ./ letvar_var id ts ] e) ::: t ->
    g |-- ([es2 ./ letvar_var id ts ] e) ::: t.
Proof.
  intros id g es1 es2 e ts t tes1 tes2 te.
  remember (letvar_var id ts) as x.
(*
  destruct (eq_exp e (exp_letvar x)).
  - rewrite e0.
    simpl.
    destruct (eq_letvar x x); try contradiction.
    rewrite e0 in te.
    simpl in te.
    destruct (eq_letvar x x); try contradiction.
    pose proof type_exp_unique as teqts.
    specialize teqts with g es1 t ts.
    specialize (teqts te tes1).
    rewrite teqts.
    assumption. *)
  - generalize dependent es2.
    generalize dependent es1.
    generalize dependent t.
    induction e;
      simpl;
      intros t es1 tes1 te es2 tes2;
      try assumption.
    + destruct (eq_letvar letvar5 x).
      * match goal with
        | [ H : ?g |-- ?e ::: ?t,
                H' : ?g |-- ?e ::: ?t' |- _] =>
          apply type_exp_unique with (t := t') in H as teq;
            try assumption;
            try rewrite <- teq;
            assumption
        end.
        * assumption.
   + do_to_all_exps type_subst_rec_case.
   + do_to_all_exps type_subst_rec_case.
   + do_to_all_exps type_subst_rec_case.
   + do_to_all_exps type_subst_rec_case.
   + do_to_all_exps type_subst_rec_case.
   + do_to_all_exps type_subst_rec_case.
   + destruct (eq_letvar letvar5 x).
     *  let x := get_var_from_type_subst_goal in
        idtac "substituted variable:" x;
          let te := get_hyp_with_goal_type in
          idtac "typing judgment for e:" te;
            type_subst_dec_subst_in_IH x te.
        eapply t_let;
          destruct_equalities_on letvar;
          destruct_equalities_on type;
          unify_typing_judgments;
          type_subst_solve_IH.
        eapply t_let.
          destruct_equalities_on letvar;
          destruct_equalities_on type;
          unify_typing_judgments;
          type_subst_solve_IH.
          destruct_equalities_on type;
          unify_typing_judgments.
          rewrite e in H.
          rewrite Heqx in H.
          inversion H.
          destruct H6, H7.
          rewrite <- Heqx.
          apply IHe2 with (es1 := [es1 ./ x] e1).
          assumption.
          rewrite <- Heqx in H5.
          assumption.
          apply IHe1 with (es1 := es1); auto.
     * let x := get_var_from_type_subst_goal in
        idtac "substituted variable:" x;
          let te := get_hyp_with_goal_type in
          idtac "typing judgment for e:" te;
            type_subst_dec_subst_in_IH x te.
       -- eapply t_let.
          destruct_equalities_on letvar;
            destruct_equalities_on type;
            unify_typing_judgments;
            type_subst_solve_IH.
          destruct_equalities_on type.
          remember (letvar_var id5 t0) as y.
          rewrite letsubst_unused.
          rewrite letsubst_unused in H5.
          unify_typing_judgments.
          assumption.
          rewrite type_exp_no_lfv with (g := g) (t := ts).
          simpl; auto.
          auto.
          rewrite type_exp_no_lfv with (g := g) (t := ts).
          simpl; auto.
          auto.
       -- eapply t_let.
          destruct_equalities_on letvar;
            destruct_equalities_on type;
            unify_typing_judgments;
            type_subst_solve_IH.
          destruct_equalities_on type.
          
          apply IHe2.

          type_subst_solve_IH.
          rewrite type_exp_no_lfv with (g := g) (t := ts).
          simpl; auto.
          
          rewrite type_exp_no_lfv with (g := g) (t := ts).
          simpl; auto.
          auto.

(* TODO: not true given the non-capture-avoiding substitution!
Lemma letsubst_distribute2 : forall es1 x es2 y e,
              ~In x (lfv_exp e) -> [[es1./x]es2./y]e = [es1./x][es2./y]e.
Proof.
  intros es1 x es2 y e nin.
  induction e; simpl; auto;
    try solve [f_equal;
               simpl in nin;
               auto
              |f_equal;
               simpl in nin;
               match goal with [IH : _ -> ?G |- ?G] => apply IH end;
               intro; elim nin;
               repeat (apply in_or_app;
                       auto;
                       right)].
  - destruct (eq_letvar letvar5 y); simpl; auto.
    destruct (eq_letvar letvar5 x); simpl; auto.
    simpl in nin; tauto.
  - destruct (eq_letvar letvar5 y);
      destruct (eq_letvar letvar5 x).
    + f_equal;
        simpl in nin;
        match goal with [IH : _ -> ?G |- ?G] => apply IH end;
        intro; elim nin;
          repeat (apply in_or_app;
                  auto;
                  right).
    + f_equal.
      simpl in nin;
        match goal with [IH : _ -> ?G |- ?G] => apply IH end;
        intro; elim nin;
          repeat (apply in_or_app;
                  auto;
                  right).
      symmetry.
      apply letsubst_unused.
      intro in2.
      elim nin.
      simpl.
      apply in_or_app.
      right.
      apply in_list_minus.
      constructor; auto.
      intro inxv5.
      simpl in inxv5.
      destruct inxv5; tauto.
    + rewrite e.
      (* TODO: fails because substitution isn't capture avoiding! *)
      f_equal.
      simpl in nin;
        match goal with [IH : _ -> ?G |- ?G] => apply IH end;
        intro; elim nin;
          repeat (apply in_or_app;
                  auto;
                  right).
      rewrite IHe2.
*)

Ltac type_subst_IH x te :=
  (multimatch goal with
     [ IH : forall t es1, _ ->  _ -> forall es, _ -> ?g |-- [es./x]?ei ::: t |- ?g |-- ?e ::: _] =>
     lazymatch e with context [[es./x]ei] =>
                      idtac "resolving via" IH;
                      let eq_e := fresh "eq_ei" in
                      let neq_e := fresh "neq_ei" in
                      destruct (eq_exp ei (exp_letvar x)) as [eq_e | neq_e];
                      idtac;
                      try rewrite eq_e;
                      simpl;
                      try rewrite eq_e in IH;
                      simpl in IH;
                      try rewrite eq_e in te
     end
   end;
    simpl in te;
  destruct (eq_letvar x x); try contradiction;
  inversion te)
   || fail "No inductive hypothesis found".

Ltac type_subst_rec_case' app_tac :=
  let x := get_var_from_type_subst_goal in
  idtac "substituted variable:" x;
  let te := get_hyp_with_goal_type in
  idtac "typing judgment for e:" te;
  (multimatch goal with
     [ IH : forall t es1, _ ->  _ -> forall es, _ -> ?g |-- [es./x]?ei ::: t |- ?g |-- ?e ::: _] =>
     lazymatch e with context [[es./x]ei] =>
                      idtac "resolving via" IH;
                      let eq_e := fresh "eq_ei" in
                      let neq_e := fresh "neq_ei" in
                      destruct (eq_exp ei (exp_letvar x)) as [eq_e | neq_e];
                      idtac;
                      try rewrite eq_e;
                      simpl;
                      try rewrite eq_e in IH;
                      simpl in IH;
                      try rewrite eq_e in te
     end
   end
   || fail "No inductive hypothesis found");
  simpl in te;
  destruct (eq_letvar x x); try contradiction;
  idtac "inverting typing rule hypothesis";
  inversion te;
  app_tac;
  repeat match goal with
         | [H : ?t1 = ?t2 |- _] =>
           let tty := type of t1 in
           unify tty type;
           idtac "destructing type equality:" H;
           destruct H
         end;
  repeat multimatch goal with
         | [ TE1 : ?g |-- ?e ::: ?t1, TE2 : ?g |-- ?e ::: ?t2, _ : ?t1 = ?t2 |- _ ] => fail
         | [ TE1 : ?g |-- ?e ::: ?t1, TE2 : ?g |-- ?e ::: ?t2, _ : ?t2 = ?t1 |- _ ] => fail
         | [ TE1 : ?g |-- ?e ::: ?t1, TE2 : ?g |-- ?e ::: ?t2 |- _ ] =>
           let teq := fresh "teq" in
           pose proof type_exp_unique as teq;
           specialize teq with (g := g) (t := t1) (t' := t2);
           specialize (teq e TE1 TE2);
           idtac "unified" TE1 "and" TE2 "via uniqueness of types";
           clear TE2;
           destruct teq
         end;
  first [assumption
        | match goal with
          | [ IH : forall t es1, _ -> _ -> forall es, _ -> ?g |-- [es./?x]?e ::: t,
                TES1 : ?g |-- [?es1./?x]?e ::: ?t'
                |- ?g |-- [?es./?x]?e ::: ?t ] =>
            apply IH with (es1 := es1); assumption
          | [ IH : forall t es1, _ -> _ -> forall es, _ -> ?g |-- es ::: t,
                TES1 : ?g |-- [?es1./?x]?e ::: ?t'
                |- ?g |-- ?e ::: ?t ] =>
            apply IH with (es1 := es1); assumption
          end]
  || fail "could not solve goal".


+let x := get_var_from_type_subst_goal in
  idtac "substituted variable:" x;
  let te := get_hyp_with_goal_type in
  idtac "typing judgment for e:" te;
    type_subst_IH x te.
  idtac "inverting typing rule hypothesis";
  inversion te.
Focus 2.



(*
 let app_tac := (apply t_mem) in
      type_subst_rec_case app_tac. *)
    +  let x := match goal with
             [ |- _ |-- ?e ::: _] =>
             match e with context [[_./?x]_] => x
             end end in
  idtac "substituted variable:" x;
  let te := match goal with
              [ te : ?g |-- _ ::: ?t |- ?g |-- _ ::: ?t ] => te
            end in
  idtac "typing judgment for e:" te;
  let resolve_letvar :=
      fun ei IHe te =>
        let eq_e := fresh "eq_ei" in
        let neq_e := fresh "neq_ei" in
        destruct (eq_exp ei (exp_letvar x)) as [eq_e | neq_e];
        idtac;
        try rewrite eq_e;
        simpl;
        (try rewrite eq_e in IHe);
        (simpl in IHe);
        (try rewrite eq_e in te) in
  (multimatch goal with
     [ IH : forall t es1, _ ->  _ -> forall es, _ -> ?g |-- [es./x]?ei ::: t |- ?g |-- ?e ::: _] =>
     lazymatch e with context [[es./x]ei] =>
                      idtac "resolving via" IH;
                      resolve_letvar ei IH te
     end
   end
   || fail "No inductive hypothesis found");
  simpl in te;
  destruct (eq_letvar x x); try contradiction;
  idtac "inverting typing rule hypothesis";
  inversion te.
        let nat5_var := fresh "nat5" in
           evar (nat5_var : nat);
           let sz_var := fresh "sz" in
           evar (sz_var : nat);
           idtac "t_load app"; apply t_load with (nat5 := nat5_var) (sz := sz_var).
        unfold sz0;
          
  repeat match goal with
         | [H : ?t1 = ?t2 |- _] =>
           let tty := type of t1 in
           unify tty type;
           idtac "destructing type equality:" H;
           destruct H
         end;
  repeat multimatch goal with
         | [ TE1 : ?g |-- ?e ::: ?t1, TE2 : ?g |-- ?e ::: ?t2, _ : ?t1 = ?t2 |- _ ] => fail
         | [ TE1 : ?g |-- ?e ::: ?t1, TE2 : ?g |-- ?e ::: ?t2, _ : ?t2 = ?t1 |- _ ] => fail
         | [ TE1 : ?g |-- ?e ::: ?t1, TE2 : ?g |-- ?e ::: ?t2 |- _ ] =>
           let teq := fresh "teq" in
           pose proof type_exp_unique as teq;
           specialize teq with (g := g) (t := t1) (t' := t2);
           specialize (teq e TE1 TE2);
           idtac "unified" TE1 "and" TE2 "via uniqueness of types";
           clear TE2;
           destruct teq
         end;
  first [eauto
        | match goal with
          | [ IH : forall t es1, _ -> _ -> forall es, _ -> ?g |-- [es./?x]?e ::: t,
                TES1 : ?g |-- [?es1./?x]?e ::: ?t'
                |- ?g |-- [?es./?x]?e ::: ?t ] =>
            apply IH with (es1 := es1); assumption
          | [ IH : forall t es1, _ -> _ -> forall es, _ -> ?g |-- es ::: t,
                TES1 : ?g |-- [?es1./?x]?e ::: ?t'
                |- ?g |-- ?e ::: ?t ] =>
            apply IH with (es1 := es1); assumption
          end]
  || fail "could not solve goal".



















 let app_tac := (
           let nat5 := fresh "nat5" in
           evar (nat5 : nat);
           let sz := fresh "sz" in
           evar (sz : nat);
           idtac "t_load app"; apply t_load with (nat5 := nat5) (sz := sz)) in
      type_subst_rec_case app_tac.

























let app_tac := (
           let nat5 := fresh "nat5" in
           evar (nat5 : nat);
           let sz := fresh "sz" in
           evar (nat5 : nat);
           idtac "t_load app"; apply t_load with (nat5 := nat5) (sz := sz)) in
      type_subst_rec_case app_tac.


 multimatch goal with
        [ sz : nat |- _ ] =>
        multimatch goal with
          [ nat5 : nat |- _ ] =>
          let app_tac := (apply t_load with (sz := sz) (nat5 := nat5)) in
          type_subst_rec_case app_tac
        end || fail "nat5 not found"
      end || fail "sz not found".

let app_tac_k := fun sz nat5 =>
                         (apply t_load with (sz := sz) (nat5 := nat5)
                         + fail 1 "could not apply load constructor with" sz nat5)in
      let app_tac_k' := fun sz =>
                         find_typed_k nat (app_tac_k sz) in
      let app_tac := ( find_typed_k nat app_tac_k')
      in type_subst_rec_case app_tac.
    + let app_tac := (apply t_load with (nat5 := nat0) (sz := sz)) in
      type_subst_rec_case app_tac.
    + let app_tac := (apply t_store with (nat5 := nat0) (sz := sz)) in
      type_subst_rec_case app_tac.
    + destruct bop5.
      * let app_tac := (apply t_aop with (aop5 := aop5)) in
        type_subst_rec_case app_tac.
      * let app_tac := (apply t_lop with (lop5 := lop5) (sz := sz)) in
        type_subst_rec_case app_tac.
    + let app_tac := (apply t_uop) in
      type_subst_rec_case app_tac.
    + let app_tac := (apply t_cast with (nat5 := nat0)) in
      type_subst_rec_case app_tac.
    + destruct (eq_letvar letvar5 x).
      *  destruct letvar5.
        inversion te.
        destruct H.
        destruct H1.
        destruct H4.
        destruct H0.
        destruct H2.
        apply t_let.
        apply IHe1 with (t := t0) (es1 := es1);
        rewrite <- e in IHe1;
        rewrite Heqx in e;
        inversion e;
        destruct H1;
          assumption.
        destruct x.
        inversion Heqx.
        destruct H0, H1.
        inversion e.
        destruct H0, H1.
        apply IHe2 with (es1 := [es1./letvar_var id0 t0]e1);
          try assumption.
        apply IHe1 with (es1 := es1);
          try assumption.
      * inversion te.
        destruct H2.
        apply t_let.
        apply IHe1 with (es1 := es1);
          try assumption.

Lemma subst_type_exp : forall g e t es id ts,
            g |-- e ::: t ->
            g |-- es ::: ts ->
            g |-- [es./letvar_var id ts] e :: t.

        apply IHe2 with (es1 := [es1./letvar_var id5 t0]e1).
    + let app_tac := (apply t_uop) in
      type_subst_rec_case app_tac.
    + let app_tac := (apply t_uop) in
      type_subst_rec_case app_tac.
    + let app_tac := (apply t_uop) in
      type_subst_rec_case app_tac.
    + 






let app_tac := (apply t_load with (nat5 := nat0)) in
      type_subst_rec_case app_tac.

    + let x := match goal with
                 [ |- _ |-- ?e ::: _] =>
                 match e with context [[_./?x]_] => x
                 end end in
      let resolve_letvar :=
          fun ei IHe te =>
            let eq_e := fresh "eq_ei" in
            let neq_e := fresh "neq_ei" in
            destruct (eq_exp ei (exp_letvar x)) as [eq_e | neq_e];
              try rewrite eq_e;
              simpl;
              (try rewrite eq_e in IHe);
              (simpl in IHe);
              (try rewrite eq_e in te) in
      multimatch goal with
        [ IH : forall t, _ -> forall es, _ -> ?g |-- [es./x]?ei ::: t |- ?g |-- ?e ::: _] =>
        lazymatch e with context [[es./x]ei] =>
                       resolve_letvar ei IH te
        end
      end;
      simpl in te;
          destruct (eq_letvar x x); try contradiction;
            inversion te;
            apply t_load with (nat5 := nat0);
            first [assumption |
                   match goal with
                   | [ IH : forall t, _ -> forall es, _ -> ?g |-- [es./?x]?e ::: t
                                                      |- ?g |-- [?es./?x]?e ::: ?t ] =>
                     apply IH; assumption
                   | [ IH : forall t, _ -> forall es, _ -> ?g |-- es ::: t
                                                      |- ?g |-- ?e ::: ?t ] =>
                     apply IH; assumption
                   end].


match goal with
[ IH : forall t, _ -> forall es, _ -> ?g |-- [es./x]?ei ::: t |- ?g |-- ?e ::: _] =>
match e with context [[es./x]ei] => resolve_letvar e1 IHe1 te
end
end


let resolve_letvar := fun e1 IHe1 te =>
destruct (eq_exp e1 (exp_letvar x)) as [eq_e1 | neq_e1];
        try rewrite eq_e1;
        simpl;
        try rewrite eq_e1 in IHe1;
        simpl in IHe1;
        try rewrite eq_e1 in te;

 apply t_load with (nat5 := nat0);
      apply t_store;




      inversion H5.
      specialize (teqts H5 H6).
      specialize teqts with g es1 (type_mem nat0 nat5) ts.
      specialize (teqts H5 tes1).
      rewrite teqts.
      assumption.

simpl in te. 
      destruct (eq_letvar letvar5 x).
      elim n. inversion e. reflexivity.
      simpl in te.
      
apply t_var with (t := type5). constructor with (t := type5).
    + apply subst_inversion in Heqe';
      try (rewrite Heqe'; simpl; constructor);
        try( rewrite type_exp_no_lfv with (g := G) (t := ts); simpl);
        auto.
    + 


apply subst_inversion with (es := es2) in Heqe';
      try (rewrite Heqe'; simpl; constructor);
        try( rewrite type_exp_no_lfv with (g := G) (t := ts); simpl);
        auto.











    generalize dependent es1.
    generalize dependent ts.
    generalize dependent x.
    induction te;
      simpl;
      intros x enl ts es1 tes1 e_subst1_eq es2 tes2;
      symmetry in e_subst1_eq.
    + apply letsubst_inversion_var in e_subst1_eq;
        try (rewrite e_subst1_eq; simpl; constructor);
        assumption.
    + apply subst_inversion in e_subst1_eq;
      try (rewrite e_subst1_eq; simpl; constructor);
        try( rewrite type_exp_no_lfv with (g := G) (t := ts); simpl);
        auto.
    + apply subst_inversion with (es := es2) in e_subst1_eq;
      try (rewrite e_subst1_eq; simpl; constructor);
        try( rewrite type_exp_no_lfv with (g := G) (t := ts); simpl);
        auto.

 apply subst_inversion in e_subst1_eq;
        try rewrite e_subst1_eq;
        first [ assumption
              | simpl; constructor].


  all: try solve [auto | assumption].
  - destruct (eq_letvar letvar5 x).
    pose proof type_exp_unique as teu.
    specialize teu with (g := g) (t := ts) (t' := t).
    specialize (teu es1 tes1 tses1) as teu1.
    rewrite <- teu1.
    assumption.
    assumption.
  - (* TODO: improve this tactic! *)
    let app_tac := (apply t_load with nat0) in
    type_subst_rec_case app_tac.
  - let app_tac := (apply t_store) in
    type_subst_rec_case app_tac.
  - let app_tac :=
        fun _ =>
          let sz := match goal with
                    | [ _ : type_exp _ _ (type_imm ?sz) |- _ ] => sz
                    end in
          first [ apply t_aop | apply t_lop with sz] in
    let t := match goal with
             | [ |- type_exp _ _ ?t ] => t
             end in
    type_subst_rec_case app_tac.
  - let app_tac := (apply t_uop) in
    type_subst_rec_case app_tac.
  - (* TODO: improve this tactic! *)
    let app_tac := (apply t_cast with nat0) in
    type_subst_rec_case app_tac.
  - destruct (eq_letvar letvar5 x);
      destruct letvar5;
      apply t_let;
      inversion tses1.
    + apply IHe1 with (es1 := es1) (ts := ts);  assumption.
    + apply IHe2 with (es2 := [es2./x]e1) (es1 := [es1./x]e1) (ts:=type5);
        try apply IHe1 with (es1:=es1) (es2:=es2) (ts := ts);
        assumption.
    + apply IHe1 with (es1 := es1) (ts := ts);  assumption.
    + rewrite letsubst_distributes with (es1 := [es2 ./ x] e1).
      inversion H6.
      

 apply IHe2 with (es2 := [es2./x]e1) (es1 := [es1./x]e1) (ts:=type5);
        try apply IHe1 with (es1:=es1) (es2:=es2) (ts := ts);
        assumption.

    rewrite e in tses1.
    apply t_let.
destruct letvar5.
    
    apply t_let.
    simpl in tses1.
    destruct t; inversion tses1.
      apply t_let.
    apply IHe1 with (ts := type5).
    
destruct (eq_letvar letvar5 x).
    + destruct letvar5.
      apply t_let.
      apply t_let with (e1 := [es2./x]e1) (t' := t).

    type_subst_rec_case app_tac.
  - 





Ltac type_subst_rec_case app_tac :=
  let t := match goal with
           | [ |- type_exp _ _ ?t ] => t
           end in
  try (destruct t; inversion tses1);
  first [app_tac | app_tac ()];
  try match goal with
      | [ H : forall ts t : type,
            _ -> _ ->
            type_exp ?G [_./?x]?e t ->
            type_exp ?G [_./?x]?e t |- _ ] =>
        apply H with (ts := ts)
      end; assumption.







destruct t; inversion tses1.
    apply t_load with (nat5 := nat0);
      match goal with
      | [ H : forall ts t : type, _ -> _ ->
                                  type_exp ?G [_./?x]?e t ->
                                  type_exp ?G [_./?x]?e t |- _ ] =>
        apply H with (ts := ts)
      end; try assumption.
  - destruct t; inversion tses1.
    apply t_store;
      try match goal with
          | [ H : forall ts t : type,
                _ -> _ ->
                type_exp ?G [_./?x]?e t ->
                type_exp ?G [_./?x]?e t |- _ ] =>
            apply H with (ts := ts)
          end; assumption.

    constructor.
    all: try assumption.
    apply IHe1 with (ts := ts).
    all: try assumption.
    apply IHe2 with (ts := ts).
    all: try assumption.
    apply IHe3 with (ts := ts).
    all: try assumption.

  remember  ([es1./x] e) as e'.
  induction tses1.
  - symmetry in Heqe'.
    apply subst_inversion_var in Heqe'.
    + rewrite Heqe';
        simpl;
        constructor;
        assumption.
    + intro eeql.
      

pose proof subst_inversion_var as s_inv_var.
    specialize (s_in_var 

  all: try solve [rewrite <- Heqe'; auto].
  

Ltac preservation_rec_case C :=
  match goal with
  | [ IH : ?A -> forall t : type, ?P t -> ?Q t,
        H : ?P ?t',
        td : ?A |- _ ] =>
    specialize (IH td) with t';
    apply C;
    try apply IH; assumption
  end.

Ltac preservation_base_case C :=
  match goal with
  | [ H : type_exp ?d _ _ |- type_exp ?d _ _] =>
    apply C;
    apply type_exp_typ_gamma in H;
    assumption
  end.


Lemma exp_preservation : forall d e e' t,
    type_delta d ->
    type_exp (map fst d) e t ->
    exp_step d e e' ->
    type_exp (map fst d) e' t.
Proof.
  intros d e e' t td te es.
  generalize dependent t.
  induction es; intros t0 te; inversion te.
  - pose proof in_delta_types as v_types.
    specialize v_types with id5 t0 v delta5.
    rewrite <- H1 in H0.
    rewrite H5 in H0.
    specialize (v_types td H0).
    rewrite <- H3.
    rewrite <- (app_nil_r G).
    rewrite <- (app_nil_l (G ++ nil)).
    apply (exp_weakening nil G nil).
    + simpl; auto.
    + simpl; rewrite app_nil_r; rewrite H3; assumption.
  - rewrite H4 in H; contradiction.
  - preservation_rec_case (t_load (map fst delta5) e1 e2' ed sz nat5).
  - preservation_rec_case (t_load (map fst delta5) e1' v2 ed sz nat5).
  - match goal with
    | [ H : type_exp ?d ?eh _ |- type_exp ?d ?e _ ] =>
      match eh with
      | context c [e] =>
        inversion H
      end
    end.
    assumption.
  - preservation_base_case t_unknown.
  - inversion H8.
    apply (t_load (map fst delta5) _ _ ed _ nat5);  assumption.
  - preservation_base_case t_unknown.
  - rewrite H4 in H11.
    inversion H11.
    rewrite H21 in H2.
    elim (n_Sn sz').
    omega.
  - rewrite H4 in H11.
    inversion H11.
    rewrite H21 in H2.
    elim (n_Sn sz').
    omega.
  - preservation_rec_case t_store.
  - preservation_rec_case t_store.
  - preservation_rec_case t_store.
  - rewrite H5 in H16.
    inversion H16.
    rewrite H27 in H3.
    elim (n_Sn sz').
    omega.
  - rewrite H5 in H16.
    inversion H16.
    rewrite H27 in H3.
    elim (n_Sn sz').
    omega.
  - apply t_let.
    match goal with
    | [ IH : ?A -> forall t : type, ?P t -> ?Q t,
          H : ?P ?t',
          td : ?A |- _ ] =>
      specialize (IH td) with t';
        try apply IH; assumption
    end.
    

  - strengthen_rec_case (t_aop g e1 aop5 e2).
  - strengthen_rec_case (t_lop g e1 lop5 e2 sz).
  - strengthen_rec_case (t_uop g uop5 e1).
  - strengthen_rec_case (t_cast g cast5 sz e nat5). apply t_load.

  Lemma wf_all_val : forall d x v, delta_wf d -> In (x,v) d -> is_val_of_exp v.
  Proof.
    intros d x v wf x_in.
    induction wf.
    - contradiction.
    - destruct x_in as [H_in | H_in].
      + inversion H_in.
        rewrite <- H3; assumption.
      + apply IHwf.
        assumption.
  Qed.
