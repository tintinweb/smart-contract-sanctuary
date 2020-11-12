pragma solidity ^0.6.6;

import "./ArtSteward.sol"; // dont need an interface since it's a test contract

/*
Testing contract
*/

contract BlockReceiver {

    ArtSteward steward;

    constructor (address _steward) public {
        steward = ArtSteward(_steward);
    }

    function buy(uint256 currentPrice) public payable {
        uint256 price = 1 ether;
        // steward.buy{value: msg.value}(price, currentPrice);
        // note: for some reason, it can't determine difference between buy(uint256) & buy(uint256,uint256)
        // Thus: manually creating this call for testing
        address(steward).call.value(msg.value)(abi.encodeWithSignature("buy(uint256,uint256)", price, currentPrice));
    }

    function withdrawPullFunds() public {
        steward.withdrawPullFunds();
    }

    // no fallback
    // no receive
    // will cause ETH sends to revert
}