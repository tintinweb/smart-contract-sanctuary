/**
 *Submitted for verification at Etherscan.io on 2021-04-27
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    uint256 number;
    string name;
    address owner;

    constructor(){
        owner = msg.sender;
        number = number+1;
        name = "xiaoming";
    }

    event storeLog(string indexed name);

    function store(string memory _name,address _owner) public {
        // require(num == 100, "num is error");
        name = _name;
        owner = _owner;
        emit storeLog(_name);
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (address,uint256){
        return (owner,number);
    }
}