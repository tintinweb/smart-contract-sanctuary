/**
 *Submitted for verification at Etherscan.io on 2022-01-12
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.6;

contract Test{

    mapping(address => uint256) public addrs;
    mapping(uint256 => address) public ids;
    uint[] public indexs;

    function deposit(address _depositor) external returns (bool) {

        uint id = addrs[_depositor];
        if(0 ==id){
            addrs[_depositor] = indexs.length;
            ids[indexs.length] = _depositor;
            indexs[indexs.length]= indexs.length;
        }

        return true;
    }

    function redeem(address _recipient) external returns (bool) {

        uint id = addrs[_recipient];

        delete addrs[_recipient];
        delete ids[id];
        delete indexs[id];

        return true;
    }


}