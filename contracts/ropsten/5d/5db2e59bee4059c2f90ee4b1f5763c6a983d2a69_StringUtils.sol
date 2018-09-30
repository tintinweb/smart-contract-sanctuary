library StringUtils {
  function equal(string _self, string _x) public pure returns (bool) {
    return keccak256(abi.encodePacked(_self)) == keccak256(abi.encodePacked(_x));
  }
}