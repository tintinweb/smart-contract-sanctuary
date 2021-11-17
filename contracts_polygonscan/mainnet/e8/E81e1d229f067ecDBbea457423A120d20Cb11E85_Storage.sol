/**
 *Submitted for verification at polygonscan.com on 2021-11-17
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {
    
    struct Ele {
        uint256[] values;
        address token;
    }

    uint256 number;
    
    event Stored(uint256 indexed num);

    event LogValue(uint256 indexed value);
    
    event LogAddress(address value);
    
    event Loged(string msg);
    
    event Loged2(uint256 value, address token);

    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function store(uint256 num) public {
        number = num;
        emit Stored(num);
    }
    
    function store2(address[] memory addresses) public {
        emit LogAddress(addresses[0]);
    }
    
    function give(uint amount) public {
        payable(msg.sender).transfer(amount);
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public returns (uint256){
        emit LogValue(number);
        return number;
    }
    
    function test() public pure returns (uint) {
        while (true) {}
        return 10;
    }
    
    function testAddress(Ele memory ele) public {
        emit Loged2(ele.values[0], ele.token);
    }
    
    // fallback () payable external {
        
    // }
}