/**
 *Submitted for verification at Etherscan.io on 2021-07-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract ChizDispenser {
    struct Claim {
        bool claimed;
        uint256 ratId;
    }

    mapping(uint256 => Claim) public existingClaims;

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
        require(paused == false, "contract is paused");
        _;
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
    
    function claimChiz(uint256 ratId) public pauseable {
        Claim memory claim = existingClaims[ratId];
        require(
            claim.claimed == false,
            "tokens have already been claimed for this rat"
        );

        address ratOwner = ratContract.ownerOf(ratId);
        require(msg.sender == ratOwner, "caller is not owner of this rat");

        existingClaims[ratId] = Claim(true, ratId);
        chizContract.transfer(msg.sender, amount);

        emit Dispense(amount, ratId);
    }
    
    function multiClaimChiz(uint256[] memory ratIds) public pauseable {
        for(uint i = 0; i < ratIds.length; i++) {
            claimChiz(ratIds[i]);
        }
    }
}

abstract contract ERC721 {
    function ownerOf(uint256 id) public virtual returns (address);
}

abstract contract ERC20 {
    function transfer(address to, uint256 value) public virtual;
}