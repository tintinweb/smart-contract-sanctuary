# @version ^0.2.11

tokens_stakeados: public(uint256)
segundos: public(uint256)
tokens_totales: public(uint256)
tokens_per_second: public(uint256)
rewards_a_repartir: public(uint256)
porcentaje_scaled: public(uint256)
tokens_stakeados_scaled: public(uint256)

parte_entera: public(uint256)
parte_fraccion: public(uint256)
@external
def __init__():
  self.tokens_stakeados = as_wei_value(500, 'ether')
  self.tokens_stakeados_scaled = self.tokens_stakeados * 10**10
  self.segundos = 86400
  self.tokens_totales = as_wei_value(1800, 'ether')
  self.tokens_per_second = as_wei_value(0.0011, 'ether')
  self.rewards_a_repartir = self.segundos*self.tokens_per_second
  self.porcentaje_scaled = self.tokens_stakeados_scaled/self.tokens_totales
  self.parte_entera = self.porcentaje_scaled/(10**10)
  self.parte_fraccion = self.porcentaje_scaled%(10**10)