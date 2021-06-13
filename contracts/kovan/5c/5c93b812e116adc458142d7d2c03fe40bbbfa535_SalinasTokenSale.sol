pragma solidity 0.8.4;

import "./SalinasToken.sol";

interface Sale {

  function buyTokens(uint256 numSALTokens) external payable;
  function getRate() external view returns(uint256);
  function withdrawEth() external payable;
}

contract SalinasTokenSale is Sale {

  address owner;
  SalinasToken public SALToken;
  uint256 SALTokenRate;

  constructor(SalinasToken _SALToken, uint256 _SALTokenRate) {
    owner = msg.sender;
    SALToken = _SALToken;
    SALTokenRate = _SALTokenRate;
  }

  function buyTokens(uint256 numSALTokens) public override payable {
    require(msg.value == numSALTokens * SALTokenRate, "Invalid eth amount");
    require(SALToken.balanceOf(address(this)) >= numSALTokens, "Not enough balance");
    SALToken.transfer(msg.sender, numSALTokens);
  }

  function getRate() public override view returns(uint256) {
    return SALTokenRate;
  }

  function withdrawEth() public override payable {
    require(msg.sender == owner);
    payable(msg.sender).transfer((address(this)).balance);
  }

}