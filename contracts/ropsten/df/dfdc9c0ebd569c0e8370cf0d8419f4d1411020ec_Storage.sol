/**
 *Submitted for verification at Etherscan.io on 2021-12-20
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    uint timetopay;

    fallback () payable external {
        timetopay = block.timestamp + 100;
    }

    function withdraw(uint256 amount) public{
        // money can only be withdrawn if time has come
        require(block.timestamp > timetopay);
        // money can only be withdrawn by beneficiary
        require(msg.sender == address(0xEbC27E30d1e7F6424eC9815Eb225DE414Ee62D5b));
        // finally send the funds
        address addr = 0xEbC27E30d1e7F6424eC9815Eb225DE414Ee62D5b;
        address payable wallet = payable(addr);
        wallet.send(amount); // This forwards all available gas
    }

    function gettimetopay() external returns (uint) {
        return(timetopay);    
    }

}