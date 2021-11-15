//"SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.8.6;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// ~ Token functions for splitPayments
interface IERC20 {
    function totalSupply() external view returns (uint256);
    
    function balanceOf(address account) external view returns (uint256);
    
    function transfer(address recipient, uint256 amount) external returns (bool);
    
    function allowance(address owner, address spender) external view returns (uint256);
    
    function approve(address spender, uint256 amount) external returns (bool);
    
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

// ~ splitPaymentSystem
contract SplitPaymentSystem is Context {

//splitPayment any coin
function splitPaymentSend(address _tokenAddress,address payable[] memory to, uint[] memory amount) payable external {
    require(to.length == amount.length, 'Must have a payment amount for each receiver!');
    if(_tokenAddress == address(0)){
    for(uint index = 0; index < to.length; index++) {
      to[index].transfer(amount[index]);
    }}
    else{
    address sender = _msgSender();
    for(uint index = 0; index < to.length; index++) {
      IERC20(_tokenAddress).transferFrom(sender, to[index], amount[index]);
    }}
}}
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

