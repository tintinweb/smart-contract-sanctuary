/**
 *Submitted for verification at Etherscan.io on 2021-07-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract MegaChizDispenser {
    ERC721 ratContract = ERC721(0xd21a23606D2746f086f6528Cd6873bAD3307b903);
    ChizDispenser chizDispenserContract = ChizDispenser(0x5e7fDe13483e5b51da88D2898e0f6a6d7B0c6899);

    bool paused = false;
    address deployer;

    event MegaClaim(address owner);

    constructor() {
        deployer = msg.sender;
    }

    modifier onlyDeployer() {
        require(msg.sender == deployer);
        _;
    }

    modifier pauseable() {
        require(paused == false, "contract is paused");
        _;
    }

    function pause() public onlyDeployer {
        paused = true;
    }

    function unpause() public onlyDeployer {
        paused = false;
    }
    
    function megaClaimChiz() public pauseable {
        uint256 ratBalance = ratContract.balanceOf(msg.sender);
        for (uint i = 0; i < ratBalance; i++) {
            uint256 tokenId = ratContract.tokenOfOwnerByIndex(i);
            (bool claimed,) = chizDispenserContract.existingClaims(tokenId);
            if (!claimed) chizDispenserContract.claimChiz(tokenId);
        }
        emit MegaClaim(msg.sender);
    }
}

abstract contract ChizDispenser {
    struct Claim {
        bool claimed;
        uint256 ratId;
    }
    mapping(uint256 => Claim) public existingClaims;
    function claimChiz(uint256) public virtual;
}

abstract contract ERC721 {
    function balanceOf(address) public virtual returns (uint256);
    function tokenOfOwnerByIndex(uint256) public virtual returns (uint256);
}