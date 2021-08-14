/**
 *Submitted for verification at Etherscan.io on 2021-08-14
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract zhongchou {
    struct needer {
        address payable neederAddr;
        uint globalAmount;
        uint getedAmount;
        uint founderCount;
        mapping (uint=>funder) map;
    }

    struct funder {
        address funderAddr;
        uint fundCount;
    }

    uint neederIndex;
    mapping (uint=> needer) public needers;

    function newNeeder(address payable _neederAddr, uint _amount) public {
        needer storage _needer = needers[neederIndex++];
        _needer.neederAddr = _neederAddr;
        _needer.globalAmount = _amount;
        _needer.getedAmount = 0;
        _needer.founderCount = 0;
    }

    function contribute(uint _index) public payable {
        needer storage _needer = needers[_index];
        _needer.getedAmount = msg.value;
        _needer.founderCount++;
        _needer.map[_needer.founderCount] = funder(msg.sender,msg.value);

    }

    function transfer2Needer(uint _index) public{
        needer storage _needer = needers[_index];
        _needer.neederAddr.transfer(_needer.getedAmount);
        
    }
}