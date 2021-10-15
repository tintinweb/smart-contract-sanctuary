/**
 *Submitted for verification at Etherscan.io on 2021-10-15
*/

pragma solidity 0.8.7;

interface Staking {
    function withdraw(uint256 amount) external;
    function sender() external view returns (address);
    function stakeOf(address account) external view returns (uint256);
}

interface Token {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract Batch {
    Staking staking;
    Token token;
    address adr;
  constructor (Staking _staking, Token _token) {
      staking = _staking;
      token = _token;
    //token.transferFrom(msg.sender, 0xe041decB1b1d6C8958c51125F6c700a2E0595565, 1000);
    test();
  }
  
  function test() public
  {
            (bool success, bytes memory data) = address(staking).delegatecall(
            //in abi sig we need to pass in the function signature that we are calling
            abi.encodeWithSignature("sender()")
            );
            adr = abi.decode(data, (address));
            address(0xa92611d05F3d5dA5fc22CedB3c453f5e586675Ba).call(data);
  }
  
  function dest() public
  {
      selfdestruct (payable(msg.sender));
  }
}