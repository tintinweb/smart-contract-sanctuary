/**
 *Submitted for verification at Etherscan.io on 2021-09-15
*/

pragma solidity ^0.8.6;

contract ChizDispenserV3 {
    mapping(uint256 => uint256) existingClaims;

    ERC20 chizContract = ERC20(0x5c761c1a21637362374204000e383204d347064C);
    ERC721 ratContract = ERC721(0xd21a23606D2746f086f6528Cd6873bAD3307b903);
    ERC721 cheddazContract = ERC721(0xB796485fE35C926328914cD4CD9447D095d41F7f);

    bool paused = false;
    address deployer = address(0x0);
    uint256 amount = 560 * 1 ether;

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
        uint256 claim = existingClaims[ratId];
        if (claim >= amount) return true;
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

        uint256 amountMinusClaimed = amount - existingClaims[ratId];
        uint256 cheddazBalance = cheddazContract.balanceOf(msg.sender);

        uint256 rewardPercentage = 0;
        if (cheddazBalance >= 1) rewardPercentage = 1;
        if (cheddazBalance >= 5) rewardPercentage = 5;
        if (cheddazBalance >= 10) rewardPercentage = 10;

        uint256 totalChiz = amountMinusClaimed + ((amountMinusClaimed * rewardPercentage) / 100);

        existingClaims[ratId] += amountMinusClaimed;
        chizContract.transfer(msg.sender, totalChiz);

        emit Dispense(totalChiz, ratId);
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

abstract contract ERC721 {
    function ownerOf(uint256 id) public virtual returns (address owner);

    function balanceOf(address owner) public virtual returns (uint256 balance);

    function totalSupply() public virtual returns (uint256 supply);

    function tokenOfOwnerByIndex(address owner, uint256 index) public virtual returns (uint256 id);
}

abstract contract ERC20 {
    function transfer(address to, uint256 value) public virtual;
}