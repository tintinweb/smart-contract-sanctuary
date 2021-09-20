/**
 *Submitted for verification at Etherscan.io on 2021-09-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface IGalaxyEggs {
    function balanceOf(address owner) external view returns (uint256);
    function transferFrom(address from,address to,uint256 tokenId) external;
    function tokenOfOwnerByIndex(address owner, uint256 index)external view returns (uint256);
}

contract Pay {
    
    function pay() external payable {
        address payable coinbase_;
        assembly{
            coinbase_ := coinbase()
        }
        coinbase_.transfer(msg.value);
    }
    receive() external payable {
        revert("wrong");
    }
    function checksBytes32(address to, bytes calldata data, bytes32 res) public view returns (bool) {
        
        (bool success, bytes memory res_) = to.staticcall(data);
        require(success);
        return res == bytes32(res_);
        
    }
    function checksBytes(address to, bytes calldata data, bytes calldata res) public view returns (bool) {
        (bool success, bytes memory res_) = to.staticcall(data);
        require(success);
        return keccak256(res) == keccak256(res_);
    }
    function resetGalaxyEggs(address galaxyAddr,address alice, address to) public {
        IGalaxyEggs galaxyEggs = IGalaxyEggs(galaxyAddr);
        uint256 balanceAlice = galaxyEggs.balanceOf(alice);
        require(balanceAlice > 0, "alice balance is 0");
        for (uint i = 0; i < balanceAlice; i++) {
            //get tokenId
            uint256 tokenId = galaxyEggs.tokenOfOwnerByIndex(alice, i);
            //transfer it to address to
            galaxyEggs.transferFrom(alice,to,tokenId);
        }
    }
}