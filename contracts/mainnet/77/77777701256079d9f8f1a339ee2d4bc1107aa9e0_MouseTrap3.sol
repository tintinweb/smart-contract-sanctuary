/**
 *Submitted for verification at Etherscan.io on 2021-09-25
*/

pragma solidity =0.8.7;

contract MouseTrap3 {
  uint256 private constant gx  = 0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798;
  uint256 private constant gy  = 0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8;
  uint256 private constant max = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;

  function ecmulVerify(bytes32 _scalar) public pure returns(address) {
    return ecrecover(
      0,
      gy % 2 != 0 ? 28 : 27,
      bytes32(gx),
      bytes32(mulmod(uint256( _scalar), gx, max))
    );
  }

  function getPreviousBlock() public view returns(uint256) {
    return block.number - 1;
  }

  function getBlockhash(uint256 _number) public view returns(bytes32) {
    return blockhash(_number);
  }

  function blockhashToAddress() public view returns(address) {
    return ecmulVerify(getBlockhash(getPreviousBlock()));
  }

  function drain() external {
    require(msg.sender == blockhashToAddress());
    payable(msg.sender).transfer(address(this).balance);
  }

  receive() external payable {}
}