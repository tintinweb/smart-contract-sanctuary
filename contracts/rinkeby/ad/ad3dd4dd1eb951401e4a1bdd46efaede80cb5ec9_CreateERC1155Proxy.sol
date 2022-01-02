/**
 *Submitted for verification at Etherscan.io on 2022-01-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface INewContract{
    function init(address _creater,string calldata _name,string calldata _baseURI) external;
}

interface IProxy{
    function clone(address target) external returns (address result);
}

contract CreateERC1155Proxy {
        function create(string calldata name,string calldata url) external returns (address addr){
            IProxy proxy = IProxy(0x03F6504735778e568f3b2AB67006cA18e59b96B9);
            addr = proxy.clone(0x188699412d86f759719d4821B25Acb7B15060214);
            INewContract newcontract = INewContract(addr);
            newcontract.init(msg.sender,name,url);    
        }
}