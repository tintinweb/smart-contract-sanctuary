/**
 *Submitted for verification at Etherscan.io on 2021-04-13
*/

pragma solidity ^0.5.16;


contract MigrateLike {
    function vote(uint proposalId, uint cdp) external;
}

contract ClaimLike {
    function withdraw(bytes32 user, address token)  external;
}

contract WETHLike {
    function withdraw(uint wad) external;
    function balanceOf(address a) external returns(uint);
}

contract VoteAndClaim {
    MigrateLike constant MIGRATE = MigrateLike(0xA30b9677A14ED10ecEb6BA87af73A27F51A17C89);
    ClaimLike constant CLAIM = ClaimLike(0x3C36cCf03dAB88c1b1AC1eb9C3Fb5dB0b6763cFF);
    WETHLike constant WETH = WETHLike(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    
    function vote(uint proposalId, uint cdp) external {
        MIGRATE.vote(proposalId, cdp);
    }
    
    function claim(uint cdp) external {
        CLAIM.withdraw(bytes32(cdp), address(WETH));
        uint qty = WETH.balanceOf(address(this));
        WETH.withdraw(qty);
        msg.sender.transfer(qty);
    }
}