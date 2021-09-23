/**
 *Submitted for verification at Etherscan.io on 2021-09-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FinnoSplitter{
    uint public constant ONE_HUNDRED_PERCENT = 10000;
    uint finnoShare;
    address payable finnovant;
    address payable treasury;
    
    constructor(uint _finnoShare, address payable _finnovant, address payable _treasury){
        finnoShare = _finnoShare;
        finnovant = _finnovant;
        treasury = _treasury;
    }

    receive() external payable{
        finnovant.transfer(_applyPercent(finnoShare, msg.value));
        treasury.transfer(address(this).balance);
    }

    function _applyPercent(uint _percent, uint _val) private pure returns(uint){
        return((_val * _percent) / ONE_HUNDRED_PERCENT);
    }

}