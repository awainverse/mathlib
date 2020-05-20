import data.monoid_algebra
import ring_theory.algebra

universes u

def t {G : Type*} [group G] (g : G) : G ↪ G :=
{ to_fun := λ h, h * g⁻¹,
  inj := sorry, }

lemma b {α : Type*} [fintype α] (e : α ↪ α) : (finset.univ).map e = finset.univ := sorry

lemma add_monoid_smul_eq_smul
  {R : Type*} [semiring R] {V : Type*} [add_comm_monoid V] [semimodule R V] (n : ℕ) (v : V) :
  add_monoid.smul n v = (n : R) • v := by library_search

section
variables (R : Type*) [comm_ring R] (S : Type*) [ring S] [algebra R S]
  (V : Type*) [add_comm_group V] [module S V]
  (W : Type*) [add_comm_group W] [module S W]

-- This can't be an instance.
def linear_map_algebra_module : module R (V →ₗ[S] W) := sorry

local attribute [instance] linear_map_algebra_module

variables {R S V W}
@[simp]
lemma linear_map_algebra_module.smul_apply (c : R) (f : V →ₗ[S] W) (v : V) :
  (c • f) v = (c • (f v) : module.restrict_scalars R W) := sorry

end

noncomputable theory
open module
open monoid_algebra

variables {k : Type u} [comm_ring k] {G : Type u} [fintype G] [group G]
-- Is there a `char_not_div` typeclass? :-)
variables (card_inv : k) (card_inv_mul_card : card_inv * (fintype.card G : k) = 1)

variables {V : Type u} [add_comm_group V] [module (monoid_algebra k G) V]
variables {W : Type u} [add_comm_group W] [module (monoid_algebra k G) W]

/-!
We now do the key calculation in Maschke's theorem.

Given `V → W`, an inclusion of `k[G]` modules,,
assume we have some splitting `π` of the inclusion `V → W`,
just as as a `k`-linear map.
(This is available cheaply, by choosing a basis.)

We now construct a splitting of the inclusion as a `k[G]`-linear map,
by the formula
$$ \frac{1}{|G|} \sum_{g \mem G} g⁻¹ • π(g • -). $$

There's a certain amount of work afterwards to get all
the formulations of Maschke's theorem you might like
(possibly requiring setting up some infrastructure about semisimplicity,
or abelian categories, depending on the formulation),
but they should all rely on this calculation.
-/

variables (π : (restrict_scalars k W) →ₗ[k] (restrict_scalars k V))
include π

/--
We define the conjugate of `π` by `g`, as a `k`-linear map.
-/
def conjugate (g : G) : (restrict_scalars k W) →ₗ[k] (restrict_scalars k V) :=
((group_smul.linear_map k V g⁻¹).comp π).comp (group_smul.linear_map k W g)

/--
The sum of the conjugates of `π` by each element `g : G`, as a `k`-linear map.

(We postpone dividing by the size of the group as long as possible.)
-/
def sum_of_conjugates :
  (restrict_scalars k W) →ₗ[k] (restrict_scalars k V) :=
(finset.univ : finset G).sum (λ g, conjugate π g)

/--
In fact, the sum over `g : G` of the conjugate of `π` by `g` is a `k[G]`-linear map.
-/
def sum_of_conjugates_equivariant :
  W →ₗ[monoid_algebra k G] V :=
monoid_algebra.equivariant_of_linear_of_comm (sum_of_conjugates π) (λ g,
begin
  ext,
  dsimp [sum_of_conjugates],
  simp [linear_map.sum_apply, finset.smul_sum], -- thank you, library_search!
  dsimp [conjugate],
  conv_lhs {
    rw [←b (t g)],
    simp [t],
  },
  simp only [←mul_smul, single_mul_single],
  simp,
end)

section
local attribute [instance] linear_map_algebra_module
/--
We construct our `k[G]`-linear retraction of `i` as
$$ \frac{1}{|G|} \sum_{g \mem G} g⁻¹ • π(g • -). $$
-/
def retraction_of_retraction_res :
  W →ₗ[monoid_algebra k G] V :=
card_inv • (sum_of_conjugates_equivariant π)
end

variables (i : V →ₗ[monoid_algebra k G] W) (h : ∀ v : V, π (i v) = v)
include h

lemma conjugate_i (g : G) (v : V) : (conjugate π g) (i v) = v :=
begin
  dsimp [conjugate],
  simp only [←i.map_smul, h],
  simp only [←mul_smul],
  simp [single_mul_single],
  -- TODO: should work by simp:
  convert one_smul _ v,
end

include card_inv_mul_card
lemma retraction_of_retraction_res_condition (v : V) : (retraction_of_retraction_res card_inv π) (i v) = v :=
begin
  dsimp [retraction_of_retraction_res],
  simp,
  dsimp [sum_of_conjugates_equivariant],
  simp,
  dsimp [sum_of_conjugates],
  simp [linear_map.sum_apply, conjugate_i π i h],
  -- hideous!
  erw [@add_monoid_smul_eq_smul k _ (restrict_scalars k V) _ _ (fintype.card G) v],
  simp only [←mul_smul, card_inv_mul_card],
  simp,
end
