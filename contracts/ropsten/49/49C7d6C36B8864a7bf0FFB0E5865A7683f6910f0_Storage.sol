/**
 *Submitted for verification at Etherscan.io on 2021-11-30
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    uint256 number;
    address payable public  owner ;
    constructor() 
    {
        number = 110;
        owner = payable(msg.sender);
    }
    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function store(uint256 num) payable public {
        number = num;
        owner.transfer(msg.value);
    }

    function _getMyBalance()
        // external
        public
        view
        returns(uint256)
    {
        return msg.sender.balance;
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (uint256){
        return number;
    }
}