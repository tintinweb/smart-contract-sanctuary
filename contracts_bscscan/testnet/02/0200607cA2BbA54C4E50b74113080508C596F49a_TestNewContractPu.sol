/**
 *Submitted for verification at BscScan.com on 2021-07-16
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract TestNewContractPu {

    uint256 number;
    string abc;
    uint240 choose;
    
    uint256 public constant survey = 10000;
    
    constructor(
        uint256 _rewardTokenPerBlock,
        uint240 _startBlock
    ) public {
        number = _rewardTokenPerBlock;
        choose = _startBlock;
    }

    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function store(uint256 num, string memory a, uint240 ch) public {
        number = num;
        abc = a;
        choose = ch;
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (uint256, string memory, uint256){
        return (number,abc, choose) ;
    }
    
    function getPublicOne(uint256 a, string memory b, uint256 c) public view returns (uint256, string memory) {
        if(a == 1){
           return  (number, b);
        }else{
            return (survey, b);
        }
    }
    
    function getCalculator(uint256 a, uint256 b) public pure returns (uint256) {
        return (a+b);
    }
}