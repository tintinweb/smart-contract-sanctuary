contract TerraNullius {
  struct Claim { address claimant; string message; uint block_number; }
  Claim[] public claims;

  function claim(string message) {
    uint index = claims.length;
    claims.length++;
    claims[index] = Claim(msg.sender, message, block.number);
  }

  function number_of_claims() returns(uint result) {
    return claims.length;
  }
}