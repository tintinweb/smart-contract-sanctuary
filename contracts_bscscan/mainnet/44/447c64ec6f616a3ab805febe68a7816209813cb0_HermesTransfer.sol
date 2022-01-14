/**
 *Submitted for verification at BscScan.com on 2022-01-14
*/

//SPDX-License-Identifier: Diemlibre Ware

/** 
 * This code/file/software is owned by Diemlibre and Diemlibre only.
 * All rights belong to Diemlibre.
 * Only Diemlibre authorizes the use of this code.
 * 
 * Hermes The Messenger God v1.0.0
**/

pragma solidity 0.8.4;

// IERC20 Interface
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


// Hermes The Messenger God v1.0.0
contract HermesTransfer {

  address owner;
  address self = address(0);
  bool isInit = false;

  // Only Owner modifier, this is trivial.
  modifier onlyOwner() {
    require(msg.sender == owner, "Only operator can call this function!");
    _;
  }

  // Must Init modifier, Hermes Transfer must know it's own address.
  modifier mustInit() {
    require(isInit,  "Contract must be Initialized!");
    _;
  }

  constructor() {
    owner = msg.sender;
  }

  // Initialize Hermes Transfer by providing its addrees.
  function init(address _self) external onlyOwner {
    self = _self;
    isInit = true;
  }

  // Make Hermes rest for a while, Maybe he has been working too much.
  function power(bool _powerState) external onlyOwner returns(bool) {
    isInit = _powerState;
    return isInit;
  }

  /**
  * Go Hermes Transfer, actually sends the tokens. Data is provided in 2 synchronised arrays.
  * NOTE: Just be reasonable with the array lenght like 250 items, don't do something stupid like 100k items.
  * Bottom line you are free to experiment with it.
  *
  * _tokenHolder must grant allowance to This Hermes Msg instance to spend on his/her behave.
  **/
  function transfer(
    address _tokenAddress, address _tokenHolder,
    address[] calldata _receivingAddress, uint256[] calldata _receivingAmounts
  ) external onlyOwner mustInit {
    require(_receivingAddress.length == _receivingAmounts.length, "Invalid input parameters!");
    
    uint256 totalAmt = 0;
    IERC20 token = IERC20(_tokenAddress);

    for(uint256 i = 0; i < _receivingAmounts.length; i++) {
      totalAmt += _receivingAmounts[i];
    }

    uint256 tokenAllowance = token.allowance(_tokenHolder, self);
    require(totalAmt > 0 && totalAmt <= tokenAllowance, "Insufficient liquidity!");

    for(uint256 j = 0; j < _receivingAddress.length; j++) {
      require(token.transferFrom(_tokenHolder, _receivingAddress[j], _receivingAmounts[j]), "Oops... Could not complete Transaction. Please try again later.");
    }
  }

  // Get the address of the Owner of This Hermes Messenger Instance, trivial stuff.
  function getOwner() external view returns(address) {
    return owner;
  }

  // Get the address of Hermes Messenger Instance, trivial stuff.
  function getSelf() external view returns(address) {
    return self;
  }

  // Get the state of This Hermes Messenger Instance, checking on him if he is still resting.
  function getPowerState() external view returns(bool) {
    return isInit;
  }
}