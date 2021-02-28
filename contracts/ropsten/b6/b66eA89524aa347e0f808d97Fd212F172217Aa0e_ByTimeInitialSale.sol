/**
 *Submitted for verification at Etherscan.io on 2021-02-28
*/

pragma solidity >= 0.7.0;

// -------------------------------------------------------------------
// 
// Contract name: ByTimeInitialSale
// Token contract: BTM
// -------------------------------------------------------------------
// SPDX-License-Identifier: MIT
// -------------------------------------------------------------------

interface IBTM {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

library SafeMath {
  function safeMul(uint a, uint b) internal pure returns (uint) {
    uint c = a * b;
    require(a == 0 || c / a == b);
    return c;
  }
}

contract ByTimeInitialSale {

    using SafeMath for uint;
    // using SafeERC20 for IERC20;

    address payable admin;
    IBTM public immutable btmContract;
    uint256 public constant tokenPrice = 1; // 1 ETH = 1BTM // constant: fixed at compile time
    uint256 public tokensSold;

    event SellBtm(uint btmAmount, address btmRecipient);

    constructor(address _btmContract) {
        admin = msg.sender;
        btmContract = IBTM(_btmContract);
    }

    function buyBtmForEth(uint256 _numberOfTokens) public payable {
        require(msg.value == _numberOfTokens.safeMul(tokenPrice), "Require that ETH sent is equal to tokens");
        require(btmContract.balanceOf(address(this)) >= _numberOfTokens, "Require that are enough tokens in the contract");
        require(btmContract.transfer(msg.sender, _numberOfTokens), "Transfer was not completed, maybe contract address sold all the tokens");

        tokensSold += _numberOfTokens;

        emit SellBtm(_numberOfTokens, msg.sender);
    }

     function endSale() public payable {
        require(msg.sender == admin, "Only admin can end the sale");
        require(btmContract.transfer(admin, btmContract.balanceOf(address(this))));

        // UPDATE: Let's not destroy the contract here
        // Just transfer the balance to the admin
        admin.transfer(address(this).balance);
    }
}