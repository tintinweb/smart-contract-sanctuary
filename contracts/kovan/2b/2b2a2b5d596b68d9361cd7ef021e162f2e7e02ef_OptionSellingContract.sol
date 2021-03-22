/**
 *Submitted for verification at Etherscan.io on 2021-03-22
*/

pragma solidity ^0.7.6;

// SPDX-License-Identifier: MIT

interface IERC20 {

  function totalSupply() external view returns (uint256);
  function decimals() external view returns (uint8);
  function symbol() external view returns (string memory);
  function name() external view returns (string memory);
  function getOwner() external view returns (address);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address _owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract OptionSellingContract {
    IERC20 buyingTokenContract;
    uint buyingAmount;
    address public buyerAddress;
    IERC20 sellingtokenContract;
    uint sellingAmount;
    address public sellerAddress;
    
    bool public isInitialised;
    uint public soldAmount;
    uint public boughtAmount;
    
    constructor () {
        buyingTokenContract = IERC20(0xdB9Cf4ea1b6f53d366c2E2B92e06860df128fa9F);
        buyingAmount = 40e18;
        buyerAddress = 0xbbEa3c23C39a8156178283e85A53563B13F096d2;
        sellingtokenContract = IERC20(0xb7bA68a13542889F717A7c447bC09E4486440cC4);
        sellingAmount = 120000000e8;
        sellerAddress = 0x746afe85063c06ccA2D53d8f9e5B560742e6e374;
    }
    
    function initializeContract() public {
        require(msg.sender == sellerAddress);
        sellingtokenContract.transferFrom(msg.sender, address(this), sellingAmount);
        isInitialised = true;
    }
    
    function executeSell() public {
        require(msg.sender == sellerAddress || msg.sender == buyerAddress);
        
        uint buyingBalance = buyingTokenContract.balanceOf(address(this));
        if (buyingAmount - boughtAmount < buyingBalance){
            buyingTokenContract.transfer(buyerAddress, buyingBalance - (buyingAmount - boughtAmount));
            buyingBalance = buyingAmount - boughtAmount;
        }
        boughtAmount += buyingBalance;
        buyingTokenContract.transfer(sellerAddress, buyingBalance);
        
        
        uint activeSoldAmount = (buyingBalance * (sellingAmount*10000000000/buyingAmount))/10000000000;
        soldAmount += activeSoldAmount;
        sellingtokenContract.transfer(buyerAddress, activeSoldAmount);
    }
    
    function sellingTokenBalance() public view returns (uint){
        return sellingtokenContract.balanceOf(address(this));
    }
    
    function buyingTokenBalance() public view returns (uint){
        return buyingTokenContract.balanceOf(address(this));
    }
    
    function salvageTokensFromContract(address tokenAddress, address to, uint amount) public {
        require(msg.sender == buyerAddress);
        require(boughtAmount == buyingAmount);
        IERC20(tokenAddress).transfer(to, amount);
    }
}