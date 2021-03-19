/**
 *Submitted for verification at Etherscan.io on 2021-03-18
*/

// SPDX-License-Identifier:	MIT
pragma solidity 0.5.0;

///	@title Pause for haidai oracle
///	@author haidai
///	@notice Base contract
///	@dev Not all function calls are currently implemented
contract Request {
    
    uint256 public numbers;
    
    event InitCallbacked(address sender, uint256 data);

    function _init_callback(uint256 _data) public {
        numbers = _data;
        emit InitCallbacked(msg.sender, _data);
    }
    
    function getNumber() public view returns(uint256) {
        return numbers;
    } 
}