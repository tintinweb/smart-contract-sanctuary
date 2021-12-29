/**
 *Submitted for verification at Etherscan.io on 2021-12-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface INewContract{
    function init(address sender,string memory init_name,string memory init_symbol,string memory init_baseurl) external;
}

interface IProxy{
    function clone(address target) external returns (address result);
}

contract CreateERC721Proxy {
        function create() external returns (address addr){
            IProxy proxy = IProxy(0x5F1eDf1f94FA224FDC84163fB88b5037b4B2F5DE);
            addr = proxy.clone(0xf6FE45dbE5a14d5F2e9C21d175b6244fe3fb9DB9);
            INewContract newcontract = INewContract(addr);
            newcontract.init(msg.sender,"UKISHIMA NFT","UKI","https://www.ukishima.xyz");    

        }
}