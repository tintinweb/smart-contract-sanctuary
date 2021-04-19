/**
 *Submitted for verification at Etherscan.io on 2021-04-19
*/

pragma solidity >=0.7.0 <0.8.0;
//SPDX-License-Identifier: MIT
contract Storage {
    uint256 public number;
    bool public need_initilization = true;
    address public admin;
    modifier ifAdmin {
        require(msg.sender == admin);
        _;
    }
    function initilize(address aadmin, uint256 n) external {
        if (need_initilization == false) return;
        admin = aadmin;
        number = n;
        need_initilization = false;
    }
    function store(uint256 num) external ifAdmin {
        number = num;
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (uint256){
        return number;
    }
}