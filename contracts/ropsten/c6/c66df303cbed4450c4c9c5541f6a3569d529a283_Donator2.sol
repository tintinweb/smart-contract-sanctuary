pragma solidity ^0.4.11;

/// TUTORIAL CONTRACT DO NOT USE IN PRODUCTION
/// @title Donations collecting contract


contract Donator2 {
   uint public donationsTotal;
   uint public donationsUsd;
   uint public donationsCount;
   uint public defaultUsdRate;

    function Donator2() {
      defaultUsdRate = 350;
    }

    // fallback function
    function () payable {
        donate(defaultUsdRate);
    }

    modifier nonZeroValue() { if (!(msg.value > 0)) throw; _; }

    function donate(uint usd_rate) public payable nonZeroValue {
        donationsTotal += msg.value;
        donationsCount += 1;
        defaultUsdRate = usd_rate;
        uint inUsd = msg.value * usd_rate / 1 ether;
        donationsUsd += inUsd;
    }

    //demo only allows ANYONE to withdraw
    function withdrawAll() external {
        require(msg.sender.send(this.balance));
    }
}