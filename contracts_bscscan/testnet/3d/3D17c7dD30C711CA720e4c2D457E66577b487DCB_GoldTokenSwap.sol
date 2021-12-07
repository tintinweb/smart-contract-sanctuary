// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}
contract GoldTokenSwap {
  uint rate=10;
  address public owner = msg.sender;
  receive() external payable {}

  function BNBtoToken() public payable{
  //require(msg.value>10000000000000000);
  IERC20 tokenContract = IERC20(0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee);
 uint256 _amountTo =msg.value*rate;
  tokenContract.transfer(msg.sender, _amountTo);
  }

   function TokentoBNB(uint256 amount) public{
  //require(amount>10000000000000000);
  IERC20 tokenContract = IERC20(0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee);
  tokenContract.transferFrom(msg.sender, address(this), amount);
 uint256 _amountTo =amount/rate;
  payable(msg.sender).transfer(_amountTo);
  }

  function updateRate(uint _rate) restricted public {
    rate=_rate;
  }
  
  function widthDrawToken(uint256 amount) public restricted{
    IERC20 tokenContract = IERC20(0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee);
    tokenContract.transfer(msg.sender, amount);
  }

   function widthDrawBNB(uint256 amount) public restricted{
    payable(msg.sender).transfer(amount);
  }

  modifier restricted() {
    require(
      msg.sender == owner,
      "This function is restricted to the contract's owner"
    );
    _;
  }

 
}