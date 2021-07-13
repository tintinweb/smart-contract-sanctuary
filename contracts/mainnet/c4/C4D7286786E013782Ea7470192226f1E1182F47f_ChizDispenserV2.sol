/**
 *Submitted for verification at Etherscan.io on 2021-07-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract ChizDispenserV2 {
    struct Claim {
        bool claimed;
        uint256 ratId;
    }

    mapping(uint256 => Claim) existingClaims;

    ChizDispenser chizDispenser = ChizDispenser(0x5e7fDe13483e5b51da88D2898e0f6a6d7B0c6899);
    ERC721 ratContract = ERC721(0xd21a23606D2746f086f6528Cd6873bAD3307b903);
    ERC20 chizContract = ERC20(0x5c761c1a21637362374204000e383204d347064C);

    bool paused = false;
    address deployer;
    uint256 amount = 10000 * 1 ether;

    event Dispense(uint256 amount, uint256 ratId);

    constructor() {
        deployer = msg.sender;
    }

    modifier onlyDeployer() {
        require(msg.sender == deployer);
        _;
    }

    modifier pauseable() {
        require(paused == false, 'contract is paused');
        _;
    }

    modifier isNotClaimed(uint256 ratId) {
        bool claimed = isClaimed(ratId);
        require(claimed == false, 'tokens for this rat have already been claimed');
        _;
    }

    function isClaimed(uint256 ratId) public view returns (bool) {
        Claim memory claim = existingClaims[ratId];
        if (claim.claimed) return true;
        (bool claimed, ) = chizDispenser.existingClaims(ratId);
        if (claimed) return true;
        return false;
    }

    function pause() public onlyDeployer {
        paused = true;
    }

    function unpause() public onlyDeployer {
        paused = false;
    }

    function setAmount(uint256 newAmount) public onlyDeployer pauseable {
        amount = newAmount;
    }

    function withdraw(uint256 withdrawAmount) public onlyDeployer pauseable {
        chizContract.transfer(msg.sender, withdrawAmount);
    }

    function claimChiz(uint256 ratId) public pauseable isNotClaimed(ratId) {
        address ratOwner = ratContract.ownerOf(ratId);
        require(msg.sender == ratOwner, 'caller is not owner of this rat');

        existingClaims[ratId] = Claim(true, ratId);
        chizContract.transfer(msg.sender, amount);

        emit Dispense(amount, ratId);
    }

    function multiClaimChiz(uint256[] memory ratIds) public pauseable {
        for (uint256 i = 0; i < ratIds.length; i++) {
            bool claimed = isClaimed(ratIds[i]);
            if (!claimed) claimChiz(ratIds[i]);
        }
    }

    function megaClaimChiz() public pauseable {
        uint256 ratBalance = ratContract.balanceOf(msg.sender);
        for (uint256 i = 0; i < ratBalance; i++) {
            uint256 tokenId = ratContract.tokenOfOwnerByIndex(msg.sender, i);
            bool claimed = isClaimed(tokenId);
            if (!claimed) claimChiz(tokenId);
        }
    }
}

abstract contract ChizDispenser {
    struct Claim {
        bool claimed;
        uint256 ratId;
    }
    mapping(uint256 => Claim) public existingClaims;

    function claimChiz(uint256 ratId) public virtual;
}

abstract contract ERC721 {
    function ownerOf(uint256 id) public virtual returns (address owner);

    function balanceOf(address owner) public virtual returns (uint256 balance);

    function tokenOfOwnerByIndex(address owner, uint256 index) public virtual returns (uint256 id);
}

abstract contract ERC20 {
    function transfer(address to, uint256 value) public virtual;
}