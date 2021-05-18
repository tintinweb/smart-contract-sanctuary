# @version ^0.2.11




tokens_stakeados: public(uint256)
segundos: public(uint256)
tokens_totales: public(uint256)
tokens_per_second: public(uint256)
rewards_a_repartir: public(uint256)
porcentaje: public(uint256)

@external
def __init__():
  self.tokens_stakeados = as_wei_value(500, 'ether')
  self.segundos = 86400
  self.tokens_totales = as_wei_value(1800, 'ether')
  self.tokens_per_second = as_wei_value(0.0011, 'ether')
  self.rewards_a_repartir = self.segundos*self.tokens_per_second
  self.porcentaje = self.tokens_stakeados/self.tokens_totales