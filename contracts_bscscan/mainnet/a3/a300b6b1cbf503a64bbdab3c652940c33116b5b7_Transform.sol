/**
 *Submitted for verification at BscScan.com on 2021-11-18
*/

// SPDX-License-Identifier: unlicensed

pragma solidity ^0.8.10;

interface NFT {
     function mint(address to) external;
}

contract Transform {
    address _owner;
    
    constructor() {
	    _owner = msg.sender;
    }

    function mints(address con, address[] memory _to) public payable {
        require(msg.sender == _owner);
        NFT contract_erc = NFT(con);

        for (uint256 i=0; i < _to.length; i++) {
            contract_erc.mint(_to[i]);
        }
        
        payable(msg.sender).transfer(msg.value);
    }
    
}