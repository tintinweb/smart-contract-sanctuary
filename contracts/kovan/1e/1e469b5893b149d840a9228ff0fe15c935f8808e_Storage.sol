/**
 *Submitted for verification at Etherscan.io on 2021-04-19
*/

pragma solidity >=0.7.0 <0.8.0;
//SPDX-License-Identifier: MIT

interface IStorage {
    event change_value(uint256 value);
    function store(uint256) external;
    function retrieve() external view returns(uint256);
}

contract Storage is IStorage{
    uint256 public number;
    bool public finish_initilization = false;
    address public thisadmin;
    modifier Owner {
        require(msg.sender == thisadmin);
        _;
    }
    function initilize(address aadmin, uint256 n) external {
        if (finish_initilization == true) return;
        thisadmin = aadmin;
        number = n;
        finish_initilization = true;
    }
    function store(uint256 num) external override Owner {
        number = num;
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() external view override returns (uint256){
        return number;
    }
}