/*

     (       )    )    )
     )\ ) ( /( ( /( ( /(     (  (
    (()/( )\()))\()))\())  ( )\ )\
     /(_)|(_)\((_)\((_)\  ))((_|(_)
    (_))  _((_)_((_)_((_)/((_)  _
    | _ \| || \ \/ / || (_))| || |
    |  _/| __ |>  <| __ / -_) || |
    |_|  |_||_/_/\_\_||_\___|_||_|

    PHXHell - A game of timing and luck.
      made by ToCsIcK

    Inspired by EthAnte by TechnicalRise

*/
pragma solidity ^0.4.21;

// Contract must implement this interface in order to receive ERC223 tokens
contract ERC223ReceivingContract {
    function tokenFallback(address _from, uint _value, bytes _data) public;
}

// We only need the signature of the transfer method
contract ERC223Interface {
    function transfer(address _to, uint _value) public returns (bool);
}

// SafeMath is good
library SafeMath {
    function mul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }

    function max64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

contract PhxHell is ERC223ReceivingContract {
    using SafeMath for uint;

    uint public balance;        // Current balance
    uint public lastFund;       // Time of last fund
    address public lastFunder;  // Address of the last person who funded
    address phxAddress;         // PHX main net address

    uint constant public stakingRequirement = 5e17;   // 0.5 PHX
    uint constant public period = 1 hours;

    // Event to record the end of a game so it can be added to a &#39;history&#39; page
    event GameOver(address indexed winner, uint timestamp, uint value);

    // Takes PHX address as a parameter so you can point at another contract during testing
    function PhxHell(address _phxAddress)
        public {
        phxAddress = _phxAddress;
    }

    // Called to force a payout without having to restake
    function payout()
        public {

        // If there&#39;s no pending winner, don&#39;t do anything
        if (lastFunder == 0)
            return;

        // If timer hasn&#39;t expire, don&#39;t do anything
        if (now.sub(lastFund) < period)
            return;

        uint amount = balance;
        balance = 0;

        // Send the total balance to the last funder
        ERC223Interface phx = ERC223Interface(phxAddress);
        phx.transfer(lastFunder, amount);

        // Fire event
        GameOver( lastFunder, now, amount );

        // Reset the winner
        lastFunder = address(0);
    }

    // Called by the ERC223 contract (PHX) when sending tokens to this address
    function tokenFallback(address _from, uint _value, bytes)
    public {

        // Make sure it is PHX we are receiving
        require(msg.sender == phxAddress);

        // Make sure it&#39;s enough PHX
        require(_value >= stakingRequirement);

        // Payout if someone won already
        payout();

        // Add to the balance and reset the timer
        balance = balance.add(_value);
        lastFund = now;
        lastFunder = _from;
    }
}