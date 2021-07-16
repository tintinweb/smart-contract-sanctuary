// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "./DividendPayingToken.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract RecoveryProtocol is DividendPayingToken, Ownable {
    using SafeMath for uint256;
    using SafeMathInt for int256;

    uint256 public totalDividendsToDistribute;

    constructor() public DividendPayingToken("RecoveryProtocol", "RecoveryProtocol") {

    }

	receive() external override payable {
		require(msg.value.add(totalDividendsDistributed) <= totalDividendsToDistribute, "RecoveryProtocol: received too much money");
    	distributeDividends();
	}


    function _transfer(address, address, uint256) internal override {
        require(false, "RecoveryProtocol: No transfers allowed");
    }

    function setBalances(address[] calldata accounts, uint256[] calldata amounts) external onlyOwner {
    	require(accounts.length > 0 && accounts.length == amounts.length, "RecoveryProtocol: Invalid data");

    	for(uint256 i = 0; i < accounts.length; i++) {
    		address account = accounts[i];
    		uint256 amount = amounts[i];

    		require(balanceOf(account) == 0, "RecoveryProtocol: account already has a balance");

    		_setBalance(account, amount);

    		totalDividendsToDistribute = totalDividendsToDistribute.add(amount);
    	}
    }
   
}