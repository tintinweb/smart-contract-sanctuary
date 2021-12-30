/**
 *Submitted for verification at Etherscan.io on 2021-12-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface INewContract{
    function init(address sender,string calldata init_name,string calldata init_uri) external;
}

interface IProxy{
    function clone(address target) external returns (address result);
}

contract CreateERC1155Proxy {
        function create(string calldata name,string calldata url) external returns (address addr){
            IProxy proxy = IProxy(0x5F1eDf1f94FA224FDC84163fB88b5037b4B2F5DE);
            addr = proxy.clone(0xf69dEe96CFC77699dceD1a212b7836CF769e4563);
            INewContract newcontract = INewContract(addr);
            newcontract.init(msg.sender,name,url);    

        }
}