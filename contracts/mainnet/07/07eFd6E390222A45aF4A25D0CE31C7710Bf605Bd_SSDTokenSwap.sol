/**
 * Copyright (C) Siousada.io
 * All rights reserved.
 * Author: <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="88e1e6eee7c8fbe1e7fdfbe9ece9a6e1e7">[email&#160;protected]</a>
 *
 * MIT License
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy 
 * of this software and associated documentation files (the ""Software""), to 
 * deal in the Software without restriction, including without limitation the 
 * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or 
 * sell copies of the Software, and to permit persons to whom the Software is 
 * furnished to do so, subject to the following conditions: 
 *  The above copyright notice and this permission notice shall be included in 
 *  all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED AS IS, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN 
 * THE SOFTWARE.
 *
 */
pragma solidity ^0.4.11;

/**
 * Guards is a handful of modifiers to be used throughout this project
 */
contract Guarded {

    modifier isValidAmount(uint256 _amount) { 
        require(_amount > 0); 
        _; 
    }

    // ensure address not null, and not this contract address
    modifier isValidAddress(address _address) {
        require(_address != 0x0 && _address != address(this));
        _;
    }

}

contract Ownable {
    address public owner;

    /** 
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function Ownable() {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner. 
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to. 
     */
    function transferOwnership(address newOwner) onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


contract SSDTokenSwap is Guarded, Ownable {

    using SafeMath for uint256;

    mapping(address => uint256) contributions;          // contributions from public
    uint256 contribCount = 0;

    string public version = &#39;0.1.2&#39;;

    uint256 public StartTime = 1506009600;    // 22nd September 2017, 08:00:00 - 1506009600
    uint256 public EndTime = 1506528000;     // 28nd September 2017, 08:00:00 - 1506528000

    uint256 public totalEtherCap = 200222 ether;       // Total raised for ICO, at USD 211/ether
    uint256 public weiRaised = 0;                       // wei raised in this ICO
    uint256 public minContrib = 0.05 ether;             // min contribution accepted

    address public wallet = 0x2E0fc8E431cc1b4721698c9e82820D7A71B88400;

    event Contribution(address indexed _contributor, uint256 _amount);

    function SSDTokenSwap() {
    }

    // function to start the Token Sale
    function setStartTime(uint256 _StartTime) onlyOwner public {
        StartTime = _StartTime;
    }

    // function to stop the Token Swap 
    function setEndTime(uint256 _EndTime) onlyOwner public {
        EndTime = _EndTime;
    }

    // this function is to add the previous token sale balance.
    /// set the accumulated balance of `_weiRaised`
    function setWeiRaised(uint256 _weiRaised) onlyOwner public {
        weiRaised = weiRaised.add(_weiRaised);
    }

    // set the wallet address
    /// set the wallet at `_wallet`
    function setWallet(address _wallet) onlyOwner public {
        wallet = _wallet;
    }

    /// set the minimum contribution to `_minContrib`
    function setMinContribution(uint256 _minContrib) onlyOwner public {
        minContrib = _minContrib;
    }

    // @return true if token swap event has ended
    function hasEnded() public constant returns (bool) {
        return now <= EndTime;
    }

    // @return true if the token swap contract is active.
    function isActive() public constant returns (bool) {
        return now >= StartTime && now <= EndTime;
    }

    function () payable {
        processContributions(msg.sender, msg.value);
    }

    /**
     * Okay, we changed the process flow a bit where the actual SSD to ETH
     * mapping shall be calculated, and pushed to the contract once the
     * crowdsale is over.
     *
     * Then, the user can pull the tokens to their wallet.
     *
     */
    function processContributions(address _contributor, uint256 _weiAmount) payable {
        require(validPurchase());

        uint256 updatedWeiRaised = weiRaised.add(_weiAmount);

        // update state
        weiRaised = updatedWeiRaised;

        // notify event for this contribution
        contributions[_contributor] = contributions[_contributor].add(_weiAmount);
        contribCount += 1;
        Contribution(_contributor, _weiAmount);

        // forware the funds
        forwardFunds();
    }

    // @return true if the transaction can buy tokens
    function validPurchase() internal constant returns (bool) {
        bool withinPeriod = now >= StartTime && now <= EndTime;
        bool minPurchase = msg.value >= minContrib;

        // add total wei raised
        uint256 totalWeiRaised = weiRaised.add(msg.value);
        bool withinCap = totalWeiRaised <= totalEtherCap;

        // check all 3 conditions met
        return withinPeriod && minPurchase && withinCap;
    }

    // send ether to the fund collection wallet
    // override to create custom fund forwarding mechanisms
    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }

}