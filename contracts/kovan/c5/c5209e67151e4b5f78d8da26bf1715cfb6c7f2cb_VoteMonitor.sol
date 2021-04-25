/**
 *Submitted for verification at Etherscan.io on 2021-04-25
*/

pragma solidity ^0.5.16;

contract OwnedLike {
    function owner() external view returns(address);
}

contract ERC20Like {
    function transfer(address _to, uint256 _value) public returns (bool success);
}

contract VoteMonitor {
    OwnedLike constant B_CDP_MANAGER = OwnedLike(0x3f30c2381CD8B917Dd96EB2f1A4F96D91324BBed);
    address constant public NEW_MAKER_EXEC = address(0xaEd8E3b2441031971ECe303694dFB5e4dd8bcAED);
    address constant public MAKER_DISTRIBUTOR = address(0x2FdA31aF983d36d521dc6DE0Fabc87777334DC6c);

    OwnedLike constant B_COMPOUND_REGISTRY = OwnedLike(0xbF698dF5591CaF546a7E087f5806E216aFED666A);
    address constant public NEW_COMPOUND_EXEC = address(0xd3d2cE885BE9a4cE079423d40E4e5bbBDF2e7962);
    address constant public COMPOUND_DISTRIBUTOR = address(0x20428d7F2a5F9024F2A148580f58e397c3718873);

    ERC20Like constant BPRO = ERC20Like(0xbbBBBBB5AA847A2003fbC6b5C16DF0Bd1E725f61);

    uint constant public QTY = 500_000e18;

    uint public deploymentTime;
    bool public sentMaker;
    bool public sentCompound;

    constructor() public {
        deploymentTime = now;
    }

    function makerApproved() public view returns(bool) {
        return B_CDP_MANAGER.owner() == NEW_MAKER_EXEC;
    }

    function compoundApproved() public view returns(bool) {
        return B_COMPOUND_REGISTRY.owner() == NEW_COMPOUND_EXEC;
    }

    function softGrace() public view returns(bool) {
        return now > deploymentTime + 2 weeks;
    }

    function sendMaker() external {
        require(! sentMaker, "already-sent");
        require(makerApproved(), "vote-didn't-pass");
        require(compoundApproved() || softGrace(), "wait-for-compound");

        sentMaker = true;
        require(BPRO.transfer(MAKER_DISTRIBUTOR, QTY), "transfer-failed");
    }

    function sendCompound() external {
        require(! sentCompound, "already-sent");
        require(compoundApproved(), "vote-didn't-pass");
        require(makerApproved() || softGrace(), "wait-for-maker");

        sentCompound = true;
        require(BPRO.transfer(COMPOUND_DISTRIBUTOR, QTY), "transfer-failed");
    }
}