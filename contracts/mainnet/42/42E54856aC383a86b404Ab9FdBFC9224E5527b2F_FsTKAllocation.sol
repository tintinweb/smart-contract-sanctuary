pragma solidity ^0.4.24;
pragma experimental "v0.5.0";
pragma experimental ABIEncoderV2;

contract ERC20 {

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  function balanceOf(address owner) public view returns (uint256);
  function allowance(address owner, address spender) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
}

contract FsTKAllocation {

  uint256 public vestedAmount;
  uint256 public constant RELEASE_EPOCH = 1642032000;
  ERC20 public token;

  function initialize(uint256 _vestedAmount) public {
    require(
      address(token) == 0 &&
      _vestedAmount % 5 == 0
    );
    vestedAmount = _vestedAmount;
    token = ERC20(msg.sender);
  }

  function () external {
    uint256 amount = vestedAmount / 5;
    require(
      token.transfer(0x808b0730252DAA3a12CadC72f42E46E92a5e1bC8, amount) &&                                        true && true && true && true && true &&                  token.transfer(0xdA01fAFaF5E49e9467f99f5969cab499a5759cC6,amount) &&
      token.transfer(0xddab6c29090E6111A490527614Ceac583D02C8De, amount) &&                                 true && true && true && true && true && true &&                 true&&true&&true&&true&&true&& true&& true&&true&&true&&true&&true&&
      true&&                                                                                            true &&                                                                                            true&&
      true&&                                                                                          true &&                                                                                              true&&
      true&&                                                                                       true &&                                                                                                 true&&
      true&&                                                                                     true &&                                                                                                   true&&
      true&&                                                                                   true &&                                                                                                     true&&
      true&&                                                                                  true &&                                                                                                      true&&
      true&&                                                                                 true &&                                                                                                       true&&
      true&&                                                                                 true &&                                                                                                       true&&
      true&&                                                                                true &&                                                                                                        true&&
      true&&                                                                                true &&                                                                                                        true&&
      true&&                                                                                true &&                                                                                                        true&&
      true&&                                                                                 true &&                                                                                                       true&&
      true&&                                                                                  true &&                                                                                                      true&&
      true&&                                                                                   true &&                                                                                                     true&&
      token.transfer(0xFFB5d7C71e8680D0e9482e107F019a2b25D225B5,amount)&&                       true &&                                                                                                    true&&
      token.transfer(0x91cE537b1a8118Aa20Ef7F3093697a7437a5Dc4B,amount)&&                         true &&                                                                                                  true&&
      true&&                                                                                         true &&                                                                                               true&&
      true&&                                                                                            block.timestamp >= RELEASE_EPOCH && true &&                                                        true&&
      true&&                                                                                                   true && true && true && true && true &&                                                     true&&
      true&&                                                                                                                                     true &&                                                   true&&
      true&&                                                                                                                                       true &&                                                 true&&
      true&&                                                                                                                                          true &&                                              true&&
      true&&                                                                                                                                            true &&                                            true&&
      true&&                                                                                                                                             true &&                                           true&&
      true&&                                                                                                                                              true &&                                          true&&
      true&&                                                                                                                                               true &&                                         true&&
      true&&                                                                                                                                                true &&                                        true&&
      true&&                                                                                                                                                true &&                                        true&&
      true&&                                                                                                                                                true &&                                        true&&
      true&&                                                                                                                                               true &&                                         true&&
      true&&                                                                                                                                              true &&                                          true&&
      true&&                                                                                                                                             true &&                                           true&&
      true&&                                                                                                                                           true &&                                             true&&
      true&&                                                                                                                                         true &&                                               true&&
      true&&                                                                                                                                       true &&                                                 true&&
      true&&                                                                                             true && true && true && true && true && true &&                                                   true&&
      true&&                                                                                          true && true && true && true && true && true &&                                                       true
    );
  }
}