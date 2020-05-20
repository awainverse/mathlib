/-
Copyright (c) 2017 Johannes Hölzl. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Johannes Hölzl, Yury G. Kudryashov, Scott Morrison
-/
import data.finsupp ring_theory.algebra

/-!
# Monoid algebras

When the domain of a `finsupp` has a multiplicative or additive structure, we can define
a convolution product. To mathematicians this structure is known as the "monoid algebra",
i.e. the finite formal linear combinations over a given semiring of elements of the monoid.
The "group ring" ℤ[G] or the "group algebra" k[G] are typical uses.

In this file we define `monoid_algebra k G := G →₀ k`, and `add_monoid_algebra k G`
in the same way, and then define the convolution product on these.

When the domain is additive, this is used to define polynomials:
```
polynomial α := add_monoid_algebra ℕ α
mv_polynominal σ α := add_monoid_algebra (σ →₀ ℕ) α
```

When the domain is multiplicative, e.g. a group, this will be used to define the group ring.

## Implementation note
Unfortunately because additive and multiplicative structures both appear in both cases,
it doesn't appear to be possible to make much use of `to_additive`, and we just settle for
saying everything twice.

Similarly, I attempted to just define `add_monoid_algebra k G := monoid_algebra k (multiplicative G)`,
but the definitional equality `multiplicative G = G` leaks through everywhere, and
seems impossible to use.
-/

noncomputable theory
open_locale classical

open finset finsupp

universes u₁ u₂ u₃
variables (k : Type u₁) (G : Type u₂)

section
variables [semiring k]

/--
The monoid algebra over a semiring `k` generated by the monoid `G`.
It is the type of finite formal `k`-linear combinations of terms of `G`,
endowed with the convolution product.
-/
@[derive [inhabited, add_comm_monoid]]
def monoid_algebra : Type (max u₁ u₂) := G →₀ k

end

namespace monoid_algebra

variables {k G}
local attribute [reducible] monoid_algebra

section
variables [semiring k] [monoid G]

/-- The product of `f g : monoid_algebra k G` is the finitely supported function
  whose value at `a` is the sum of `f x * g y` over all pairs `x, y`
  such that `x * y = a`. (Think of the group ring of a group.) -/
instance : has_mul (monoid_algebra k G) :=
⟨λf g, f.sum $ λa₁ b₁, g.sum $ λa₂ b₂, single (a₁ * a₂) (b₁ * b₂)⟩

lemma mul_def {f g : monoid_algebra k G} :
  f * g = (f.sum $ λa₁ b₁, g.sum $ λa₂ b₂, single (a₁ * a₂) (b₁ * b₂)) :=
rfl

lemma mul_apply (f g : monoid_algebra k G) (x : G) :
  (f * g) x = (f.sum $ λa₁ b₁, g.sum $ λa₂ b₂, if a₁ * a₂ = x then b₁ * b₂ else 0) :=
begin
  rw [mul_def],
  simp only [finsupp.sum_apply, single_apply],
end
end

section
variables [semiring k] [monoid G]

lemma support_mul (a b : monoid_algebra k G) :
  (a * b).support ⊆ a.support.bind (λa₁, b.support.bind $ λa₂, {a₁ * a₂}) :=
subset.trans support_sum $ bind_mono $ assume a₁ _,
  subset.trans support_sum $ bind_mono $ assume a₂ _, support_single_subset

/-- The unit of the multiplication is `single 1 1`, i.e. the function
  that is `1` at `1` and zero elsewhere. -/
instance : has_one (monoid_algebra k G) :=
⟨single 1 1⟩

lemma one_def : (1 : monoid_algebra k G) = single 1 1 :=
rfl

-- TODO: the simplifier unfolds 0 in the instance proof!
private lemma zero_mul (f : monoid_algebra k G) : 0 * f = 0 :=
by simp only [mul_def, sum_zero_index]

private lemma mul_zero (f : monoid_algebra k G) : f * 0 = 0 :=
by simp only [mul_def, sum_zero_index, sum_zero]

private lemma left_distrib (a b c : monoid_algebra k G) : a * (b + c) = a * b + a * c :=
by simp only [mul_def, sum_add_index, mul_add, _root_.mul_zero, single_zero, single_add,
  eq_self_iff_true, forall_true_iff, forall_3_true_iff, sum_add]

private lemma right_distrib (a b c : monoid_algebra k G) : (a + b) * c = a * c + b * c :=
by simp only [mul_def, sum_add_index, add_mul, _root_.mul_zero, _root_.zero_mul, single_zero,
  single_add, eq_self_iff_true, forall_true_iff, forall_3_true_iff, sum_zero, sum_add]

instance : semiring (monoid_algebra k G) :=
{ one       := 1,
  mul       := (*),
  one_mul   := assume f, by simp only [mul_def, one_def, sum_single_index, _root_.zero_mul,
    single_zero, sum_zero, zero_add, one_mul, sum_single],
  mul_one   := assume f, by simp only [mul_def, one_def, sum_single_index, _root_.mul_zero,
    single_zero, sum_zero, add_zero, mul_one, sum_single],
  zero_mul  := zero_mul,
  mul_zero  := mul_zero,
  mul_assoc := assume f g h, by simp only [mul_def, sum_sum_index, sum_zero_index, sum_add_index,
    sum_single_index, single_zero, single_add, eq_self_iff_true, forall_true_iff, forall_3_true_iff,
    add_mul, mul_add, add_assoc, mul_assoc, _root_.zero_mul, _root_.mul_zero, sum_zero, sum_add],
  left_distrib  := left_distrib,
  right_distrib := right_distrib,
  .. finsupp.add_comm_monoid }

lemma single_mul_single {a₁ a₂ : G} {b₁ b₂ : k} :
  (single a₁ b₁ : monoid_algebra k G) * single a₂ b₂ = single (a₁ * a₂) (b₁ * b₂) :=
(sum_single_index (by simp only [_root_.zero_mul, single_zero, sum_zero])).trans
  (sum_single_index (by rw [_root_.mul_zero, single_zero]))

section

variables (k G)

/-- Embedding of a monoid into its monoid algebra. -/
def of : G →* monoid_algebra k G :=
{ to_fun := λ a, single a 1,
  map_one' := rfl,
  map_mul' := λ a b, by rw [single_mul_single, one_mul] }

end

@[simp] lemma of_apply (a : G) : of k G a = single a 1 := rfl

lemma mul_single_apply_aux (f : monoid_algebra k G) (r : k)
  (x y z : G) (H : ∀ a, a * x = z ↔ a = y) :
  (f * single x r) z = f y * r :=
have A : ∀ a₁ b₁, (single x r).sum (λ a₂ b₂, ite (a₁ * a₂ = z) (b₁ * b₂) 0) =
  ite (a₁ * x = z) (b₁ * r) 0,
from λ a₁ b₁, sum_single_index $ by simp,
calc (f * single x r) z = sum f (λ a b, if (a = y) then (b * r) else 0) :
  -- different `decidable` instances make it not trivial
  by { simp only [mul_apply, A, H], congr, funext, split_ifs; refl }
... = if y ∈ f.support then f y * r else 0 : f.support.sum_ite_eq' _ _
... = f y * r : by split_ifs with h; simp at h; simp [h]

lemma mul_single_one_apply (f : monoid_algebra k G) (r : k) (x : G) :
  (f * single 1 r) x = f x * r :=
f.mul_single_apply_aux r _ _ _ $ λ a, by rw [mul_one]

lemma single_mul_apply_aux (f : monoid_algebra k G) (r : k) (x y z : G)
  (H : ∀ a, x * a = y ↔ a = z) :
  (single x r * f) y = r * f z :=
have f.sum (λ a b, ite (x * a = y) (0 * b) 0) = 0, by simp,
calc (single x r * f) y = sum f (λ a b, ite (x * a = y) (r * b) 0) :
  (mul_apply _ _ _).trans $ sum_single_index this
... = f.sum (λ a b, ite (a = z) (r * b) 0) :
  by { simp only [H], congr, ext; split_ifs; refl  }
... = if z ∈ f.support then (r * f z) else 0 : f.support.sum_ite_eq' _ _
... = _ : by split_ifs with h; simp at h; simp [h]

lemma single_one_mul_apply (f : monoid_algebra k G) (r : k) (x : G) :
  (single 1 r * f) x = r * f x :=
f.single_mul_apply_aux r _ _ _ $ λ a, by rw [one_mul]

end

instance [comm_semiring k] [comm_monoid G] : comm_semiring (monoid_algebra k G) :=
{ mul_comm := assume f g,
  begin
    simp only [mul_def, finsupp.sum, mul_comm],
    rw [finset.sum_comm],
    simp only [mul_comm]
  end,
  .. monoid_algebra.semiring }

instance [ring k] : has_neg (monoid_algebra k G) :=
by apply_instance

instance [ring k] [monoid G] : ring (monoid_algebra k G) :=
{ neg := has_neg.neg,
  add_left_neg := add_left_neg,
  .. monoid_algebra.semiring }

instance [comm_ring k] [comm_monoid G] : comm_ring (monoid_algebra k G) :=
{ mul_comm := mul_comm, .. monoid_algebra.ring}

instance [semiring k] : has_scalar k (monoid_algebra k G) :=
finsupp.has_scalar

instance [semiring k] : semimodule k (monoid_algebra k G) :=
finsupp.semimodule G k

instance [ring k] : module k (monoid_algebra k G) :=
finsupp.module G k

lemma single_one_comm [comm_semiring k] [monoid G] (r : k) (f : monoid_algebra k G) :
  single 1 r * f = f * single 1 r :=
by { ext, rw [single_one_mul_apply, mul_single_one_apply, mul_comm] }

instance [comm_semiring k] [monoid G] : algebra k (monoid_algebra k G) :=
{ to_fun := single 1,
  map_one' := rfl,
  map_mul' := λ x y, by rw [single_mul_single, one_mul],
  map_zero' := single_zero,
  map_add' := λ x y, single_add,
  smul_def' := λ r a, by { ext x, exact smul_apply.trans (single_one_mul_apply _ _ _).symm },
  commutes' := λ r f, single_one_comm r f }

@[simp] lemma coe_algebra_map [comm_semiring k] [monoid G] :
  (algebra_map k (monoid_algebra k G) : k → monoid_algebra k G) = single 1 :=
rfl

/-- Any monoid homomorphism `G →* R` can be lifted to an algebra homomorphism
`monoid_algebra k G →ₐ[k] R`. -/
def lift [comm_semiring k] [monoid G] {R : Type u₃} [semiring R] [algebra k R] :
  (G →* R) ≃ (monoid_algebra k G →ₐ[k] R) :=
{ inv_fun := λ f, ((f : monoid_algebra k G →+* R) : monoid_algebra k G →* R).comp (of k G),
  to_fun := λ F, { to_fun := λ f, f.sum (λ a b, b • F a),
    map_one' := by { rw [one_def, sum_single_index, one_smul, F.map_one], apply zero_smul },
    map_mul' :=
      begin
        intros f g,
        rw [mul_def, finsupp.sum_mul, finsupp.sum_sum_index];
          try { intros, simp only [zero_smul, add_smul], done },
        refine finset.sum_congr rfl (λ a ha, _), simp only [],
        rw [finsupp.mul_sum, finsupp.sum_sum_index];
          try { intros, simp only [zero_smul, add_smul], done },
        refine finset.sum_congr rfl (λ a' ha', _), simp only [],
        rw [sum_single_index, F.map_mul, algebra.mul_smul_comm, algebra.smul_mul_assoc,
          smul_smul, mul_comm],
        apply zero_smul
      end,
    map_zero' := sum_zero_index,
    map_add' := λ f g, by rw [sum_add_index]; intros; simp only [zero_smul, add_smul],
    commutes' := λ r, by rw [coe_algebra_map, sum_single_index, F.map_one, algebra.smul_def,
      mul_one]; apply zero_smul },
  left_inv := λ f, begin ext x, simp [sum_single_index] end,
  right_inv := λ F,
    begin
      ext f,
      conv_rhs { rw ← f.sum_single },
      simp [← F.map_smul, finsupp.sum, ← F.map_sum, smul_single_self]
    end }

instance [group G] [semiring k] :
  distrib_mul_action G (monoid_algebra k G) :=
finsupp.comap_distrib_mul_action_self

section
variables (k)
def group_smul.linear_map [group G] [comm_ring k]
  (V : Type u₃) [add_comm_group V] [module (monoid_algebra k G) V] (g : G) :
  (module.restrict_scalars k V) →ₗ[k] (module.restrict_scalars k V) :=
{ to_fun := λ v, (single g (1 : k) • v : V),
  add := λ x y, smul_add (single g (1 : k)) x y,
  smul := λ c x,
  by simp only [module.restrict_scalars_def, coe_algebra_map, ←mul_smul, single_one_comm], }

@[simp]
lemma group_smul.linear_map_apply [group G] [comm_ring k]
  (V : Type u₃) [add_comm_group V] [module (monoid_algebra k G) V] (g : G) (v : V) :
  (group_smul.linear_map k V g : module.restrict_scalars k V → module.restrict_scalars k V) v =
    (single g (1 : k) • v : V) := rfl

section
variables {k}
variables [group G] [comm_ring k]
  {V : Type u₃} {gV : add_comm_group V} {mV : module (monoid_algebra k G) V}
  {W : Type u₃} {gW : add_comm_group W} {mW : module (monoid_algebra k G) W}
  (f : (module.restrict_scalars k V) →ₗ[k] (module.restrict_scalars k W))
  (h : ∀ g : G, f.comp (group_smul.linear_map k V g) = (group_smul.linear_map k W g).comp f)
include h

def equivariant_of_linear_of_comm : V →ₗ[monoid_algebra k G] W :=
sorry

@[simp]
lemma equivariant_of_linear_of_comm_apply (v : V) : (equivariant_of_linear_of_comm f h) v = f v :=
sorry

end
end

universe ui
variable {ι : Type ui}

lemma prod_single [comm_semiring k] [comm_monoid G]
  {s : finset ι} {a : ι → G} {b : ι → k} :
  s.prod (λi, single (a i) (b i)) = single (s.prod a) (s.prod b) :=
finset.induction_on s rfl $ λ a s has ih, by rw [prod_insert has, ih,
  single_mul_single, prod_insert has, prod_insert has]

section -- We now prove some additional statements that hold for group algebras.
variables [semiring k] [group G]

lemma mul_apply_left (f g : monoid_algebra k G) (x : G) :
  (f * g) x = (f.sum $ λa₁ b₁, b₁ * (g (a₁⁻¹ * x))) :=
begin
  rw mul_apply,
  congr, funext,
  -- We need to massage the condition in the if statement first:
  have t : ∀ a₁ a₂, a₁⁻¹ * x = a₂ ↔ a₁ * a₂ = x := by { intros, split; rintro rfl; simp, },
  conv_lhs { congr, skip, funext, rw ←t, },
  -- but it's downhill from here.
  simp only [mem_support_iff, ne.def, finsupp.sum_ite_eq],
  split_ifs,
  { simp [h], },
  { refl, },
end

@[simp]
lemma mul_single_apply (f : monoid_algebra k G) (r : k) (x y : G) :
  (f * single x r) y = f (y * x⁻¹) * r :=
f.mul_single_apply_aux _ _ _ _ $ λ a, eq_mul_inv_iff_mul_eq.symm

-- If we'd assumed `comm_semiring`, we could deduce this from `mul_apply_left`.
lemma mul_apply_right (f g : monoid_algebra k G) (x : G) :
  (f * g) x = (g.sum $ λa₂ b₂, (f (x * a₂⁻¹)) * b₂) :=
begin
  rw mul_apply,
  rw finsupp.sum_comm,
  congr, funext,
  have t : ∀ a₁, a₁ * x' = x ↔ a₁ = x * x'⁻¹ := by { intros, split; rintro rfl; simp, },
  conv_lhs { congr, skip, funext, rw t, },
  simp only [mem_support_iff, ne.def, finsupp.sum_ite_eq'],
  split_ifs,
  { simp [h], },
  { refl, },
end

@[simp]
lemma single_mul_apply (r : k) (x : G) (f : monoid_algebra k G) (y : G) :
  (single x r * f) y = r * f (x⁻¹ * y) :=
begin
  rw mul_apply_right,
  have t : ∀ a₂, x = y * a₂⁻¹ ↔ x⁻¹ * y = a₂ := by { intros, split; rintro rfl; simp, },
  simp [single_apply, t],
  split_ifs; simp *
end

end

end monoid_algebra

section
variables [semiring k]

/--
The monoid algebra over a semiring `k` generated by the additive monoid `G`.
It is the type of finite formal `k`-linear combinations of terms of `G`,
endowed with the convolution product.
-/
@[derive [inhabited, add_comm_monoid]]
def add_monoid_algebra := G →₀ k

end

namespace add_monoid_algebra

variables {k G}
local attribute [reducible] add_monoid_algebra

section
variables [semiring k] [add_monoid G]

/-- The product of `f g : add_monoid_algebra k G` is the finitely supported function
  whose value at `a` is the sum of `f x * g y` over all pairs `x, y`
  such that `x + y = a`. (Think of the product of multivariate
  polynomials where `α` is the additive monoid of monomial exponents.) -/
instance : has_mul (add_monoid_algebra k G) :=
⟨λf g, f.sum $ λa₁ b₁, g.sum $ λa₂ b₂, single (a₁ + a₂) (b₁ * b₂)⟩

lemma mul_def {f g : add_monoid_algebra k G} :
  f * g = (f.sum $ λa₁ b₁, g.sum $ λa₂ b₂, single (a₁ + a₂) (b₁ * b₂)) :=
rfl

lemma mul_apply (f g : add_monoid_algebra k G) (x : G) :
  (f * g) x = (f.sum $ λa₁ b₁, g.sum $ λa₂ b₂, if a₁ + a₂ = x then b₁ * b₂ else 0) :=
begin
  rw [mul_def],
  simp only [finsupp.sum_apply, single_apply],
end

lemma support_mul (a b : add_monoid_algebra k G) :
  (a * b).support ⊆ a.support.bind (λa₁, b.support.bind $ λa₂, {a₁ + a₂}) :=
subset.trans support_sum $ bind_mono $ assume a₁ _,
  subset.trans support_sum $ bind_mono $ assume a₂ _, support_single_subset

/-- The unit of the multiplication is `single 1 1`, i.e. the function
  that is `1` at `0` and zero elsewhere. -/
instance : has_one (add_monoid_algebra k G) :=
⟨single 0 1⟩

lemma one_def : (1 : add_monoid_algebra k G) = single 0 1 :=
rfl

-- TODO: the simplifier unfolds 0 in the instance proof!
private lemma zero_mul (f : add_monoid_algebra k G) : 0 * f = 0 :=
by simp only [mul_def, sum_zero_index]

private lemma mul_zero (f : add_monoid_algebra k G) : f * 0 = 0 :=
by simp only [mul_def, sum_zero_index, sum_zero]

private lemma left_distrib (a b c : add_monoid_algebra k G) : a * (b + c) = a * b + a * c :=
by simp only [mul_def, sum_add_index, mul_add, _root_.mul_zero, single_zero, single_add,
  eq_self_iff_true, forall_true_iff, forall_3_true_iff, sum_add]

private lemma right_distrib (a b c : add_monoid_algebra k G) : (a + b) * c = a * c + b * c :=
by simp only [mul_def, sum_add_index, add_mul, _root_.mul_zero, _root_.zero_mul, single_zero,
  single_add, eq_self_iff_true, forall_true_iff, forall_3_true_iff, sum_zero, sum_add]

instance : semiring (add_monoid_algebra k G) :=
{ one       := 1,
  mul       := (*),
  one_mul   := assume f, by simp only [mul_def, one_def, sum_single_index, _root_.zero_mul,
    single_zero, sum_zero, zero_add, one_mul, sum_single],
  mul_one   := assume f, by simp only [mul_def, one_def, sum_single_index, _root_.mul_zero,
    single_zero, sum_zero, add_zero, mul_one, sum_single],
  zero_mul  := zero_mul,
  mul_zero  := mul_zero,
  mul_assoc := assume f g h, by simp only [mul_def, sum_sum_index, sum_zero_index, sum_add_index,
    sum_single_index, single_zero, single_add, eq_self_iff_true, forall_true_iff, forall_3_true_iff,
    add_mul, mul_add, add_assoc, mul_assoc, _root_.zero_mul, _root_.mul_zero, sum_zero, sum_add],
  left_distrib  := left_distrib,
  right_distrib := right_distrib,
  .. finsupp.add_comm_monoid }

lemma single_mul_single {a₁ a₂ : G} {b₁ b₂ : k} :
  (single a₁ b₁ : add_monoid_algebra k G) * single a₂ b₂ = single (a₁ + a₂) (b₁ * b₂) :=
(sum_single_index (by simp only [_root_.zero_mul, single_zero, sum_zero])).trans
  (sum_single_index (by rw [_root_.mul_zero, single_zero]))

section

variables (k G)

/-- Embedding of a monoid into its monoid algebra. -/
def of : multiplicative G →* add_monoid_algebra k G :=
{ to_fun := λ a, single a 1,
  map_one' := rfl,
  map_mul' := λ a b, by { rw [single_mul_single, one_mul], refl } }

end

@[simp] lemma of_apply (a : G) : of k G a = single a 1 := rfl

lemma mul_single_apply_aux (f : add_monoid_algebra k G) (r : k)
  (x y z : G) (H : ∀ a, a + x = z ↔ a = y) :
  (f * single x r) z = f y * r :=
have A : ∀ a₁ b₁, (single x r).sum (λ a₂ b₂, ite (a₁ + a₂ = z) (b₁ * b₂) 0) =
  ite (a₁ + x = z) (b₁ * r) 0,
from λ a₁ b₁, sum_single_index $ by simp,
calc (f * single x r) z = sum f (λ a b, if (a = y) then (b * r) else 0) :
  -- different `decidable` instances make it not trivial
  by { simp only [mul_apply, A, H], congr, funext, split_ifs; refl }
... = if y ∈ f.support then f y * r else 0 : f.support.sum_ite_eq' _ _
... = f y * r : by split_ifs with h; simp at h; simp [h]

lemma mul_single_zero_apply (f : add_monoid_algebra k G) (r : k) (x : G) :
  (f * single 0 r) x = f x * r :=
f.mul_single_apply_aux r _ _ _ $ λ a, by rw [add_zero]

lemma single_mul_apply_aux (f : add_monoid_algebra k G) (r : k) (x y z : G)
  (H : ∀ a, x + a = y ↔ a = z) :
  (single x r * f) y = r * f z :=
have f.sum (λ a b, ite (x + a = y) (0 * b) 0) = 0, by simp,
calc (single x r * f) y = sum f (λ a b, ite (x + a = y) (r * b) 0) :
  (mul_apply _ _ _).trans $ sum_single_index this
... = f.sum (λ a b, ite (a = z) (r * b) 0) :
  by { simp only [H], congr, ext; split_ifs; refl  }
... = if z ∈ f.support then (r * f z) else 0 : f.support.sum_ite_eq' _ _
... = _ : by split_ifs with h; simp at h; simp [h]

lemma single_zero_mul_apply (f : add_monoid_algebra k G) (r : k) (x : G) :
  (single 0 r * f) x = r * f x :=
f.single_mul_apply_aux r _ _ _ $ λ a, by rw [zero_add]


end

instance [comm_semiring k] [add_comm_monoid G] : comm_semiring (add_monoid_algebra k G) :=
{ mul_comm := assume f g,
  begin
    simp only [mul_def, finsupp.sum, mul_comm],
    rw [finset.sum_comm],
    simp only [add_comm]
  end,
  .. add_monoid_algebra.semiring }

instance [ring k] : has_neg (add_monoid_algebra k G) :=
by apply_instance

instance [ring k] [add_monoid G] : ring (add_monoid_algebra k G) :=
{ neg := has_neg.neg,
  add_left_neg := add_left_neg,
  .. add_monoid_algebra.semiring }

instance [comm_ring k] [add_comm_monoid G] : comm_ring (add_monoid_algebra k G) :=
{ mul_comm := mul_comm, .. add_monoid_algebra.ring}

instance [semiring k] : has_scalar k (add_monoid_algebra k G) :=
finsupp.has_scalar

instance [semiring k] : semimodule k (add_monoid_algebra k G) :=
finsupp.semimodule G k

instance [ring k] : module k (add_monoid_algebra k G) :=
finsupp.module G k

instance [comm_semiring k] [add_monoid G] : algebra k (add_monoid_algebra k G) :=
{ to_fun := single 0,
  map_one' := rfl,
  map_mul' := λ x y, by rw [single_mul_single, zero_add],
  map_zero' := single_zero,
  map_add' := λ x y, single_add,
  smul_def' := λ r a, by { ext x, exact smul_apply.trans (single_zero_mul_apply _ _ _).symm },
  commutes' := λ r f, show single 0 r * f = f * single 0 r,
    by ext; rw [single_zero_mul_apply, mul_single_zero_apply, mul_comm] }

@[simp] lemma coe_algebra_map [comm_semiring k] [add_monoid G] :
  (algebra_map k (add_monoid_algebra k G) : k → add_monoid_algebra k G) = single 0 :=
rfl

/-- Any monoid homomorphism `multiplicative G →* R` can be lifted to an algebra homomorphism
`add_monoid_algebra k G →ₐ[k] R`. -/
def lift [comm_semiring k] [add_monoid G] {R : Type u₃} [semiring R] [algebra k R] :
  (multiplicative G →* R) ≃ (add_monoid_algebra k G →ₐ[k] R) :=
{ inv_fun := λ f, ((f : add_monoid_algebra k G →+* R) : add_monoid_algebra k G →* R).comp (of k G),
  to_fun := λ F, { to_fun := λ f, f.sum (λ a b, b • F a),
    map_one' := by { rw [one_def, sum_single_index, one_smul], erw [F.map_one], apply zero_smul },
    map_mul' :=
      begin
        intros f g,
        rw [mul_def, finsupp.sum_mul, finsupp.sum_sum_index];
          try { intros, simp only [zero_smul, add_smul], done },
        refine finset.sum_congr rfl (λ a ha, _), simp only [],
        rw [finsupp.mul_sum, finsupp.sum_sum_index];
          try { intros, simp only [zero_smul, add_smul], done },
        refine finset.sum_congr rfl (λ a' ha', _), simp only [],
        rw [sum_single_index],
        erw [F.map_mul],
        rw [algebra.mul_smul_comm, algebra.smul_mul_assoc, smul_smul, mul_comm],
        apply zero_smul
      end,
    map_zero' := sum_zero_index,
    map_add' := λ f g, by rw [sum_add_index]; intros; simp only [zero_smul, add_smul],
    commutes' := λ r,
    begin
      rw [coe_algebra_map, sum_single_index],
      erw [F.map_one],
      rw [algebra.smul_def, mul_one],
      apply zero_smul
    end, },
  left_inv := λ f, begin ext x, simp [sum_single_index] end,
  right_inv := λ F,
    begin
      ext f,
      conv_rhs { rw ← f.sum_single },
      simp [← F.map_smul, finsupp.sum, ← F.map_sum, smul_single_self]
    end }

-- It is hard to state the equivalent of `distrib_mul_action G (monoid_algebra k G)`
-- because we've never discussed actions of additive groups.

universe ui
variable {ι : Type ui}

lemma prod_single [comm_semiring k] [add_comm_monoid G]
  {s : finset ι} {a : ι → G} {b : ι → k} :
  s.prod (λi, single (a i) (b i)) = single (s.sum a) (s.prod b) :=
finset.induction_on s rfl $ λ a s has ih, by rw [prod_insert has, ih,
  single_mul_single, sum_insert has, prod_insert has]

end add_monoid_algebra
