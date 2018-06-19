pragma solidity ^0.4.23;

contract token {
    function transferFrom(address sender, address receiver, uint amount) returns(bool success) {}
    function burn() {}
}

library SafeMath {
    function mul(uint a, uint b) internal returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function sub(uint a, uint b) internal returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal returns (uint) {
        uint c = a + b;
        assert(c >= a && c >= b);
        return c;
    }
}

contract EphronIndiaCoinICO {
    using SafeMath for uint;
    // The maximum amount of tokens to be sold
    uint constant public maxGoal = 900000; // 275 Milion CoinPoker Tokens
    // There are different prices and amount available in each period
    uint public prices = 100000; // 1ETH = 4200CHP, 1ETH = 3500CHP
    uint public amount_stages = 27500; // the amount stages for different prices
    // How much has been raised by crowdsale (in ETH)
    uint public amountRaised;
    // The number of tokens already sold
    uint public tokensSold = 0;
    // The start date of the crowdsale
    uint constant public start = 1526470200; // Friday, 19 January 2018 10:00:00 GMT
    // The end date of the crowdsale
    uint constant public end = 1531675800; // Friday, 26 January 2018 10:00:00 GMT
    // The balances (in ETH) of all token holders
    mapping(address => uint) public balances;
    // Indicates if the crowdsale has been ended already
    bool public crowdsaleEnded = false;
    // Tokens will be transfered from this address
    address public tokenOwner;
    // The address of the token contract
    token public tokenReward;
    // The wallet on which the funds will be stored
    address wallet;
    // Notifying transfers and the success of the crowdsale
    event Finalize(address _tokenOwner, uint _amountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution, uint _amountRaised);

    // ---- FOR TEST ONLY ----
    uint _current = 0;
    function current() public returns (uint) {
        // Override not in use
        if(_current == 0) {
            return now;
        }
        return _current;
    }
    function setCurrent(uint __current) {
        _current = __current;
    }
    //------------------------

    // Constructor/initialization
    function EphronIndiaCoinICO(address tokenAddr, address walletAddr, address tokenOwnerAddr) {
        tokenReward = token(tokenAddr);
        wallet = walletAddr;
        tokenOwner = tokenOwnerAddr;
    }

    // Exchange CHP by sending ether to the contract.
    function() payable {
        if (msg.sender != wallet) // Do not trigger exchange if the wallet is returning the funds
            exchange(msg.sender);
    }

    // Make an exchangement. Only callable if the crowdsale started and hasn&#39;t been ended, also the maxGoal wasn&#39;t reached yet.
    // The current token price is looked up by available amount. Bought tokens is transfered to the receiver.
    // The sent value is directly forwarded to a safe wallet.
    function exchange(address receiver) payable {
        uint amount = msg.value;
        uint price = getPrice();
        uint numTokens = amount.mul(price);

        require(numTokens > 0);
        require(!crowdsaleEnded && current() >= start && current() <= end && tokensSold.add(numTokens) <= maxGoal);

        wallet.transfer(amount);
        balances[receiver] = balances[receiver].add(amount);

        // Calculate how much raised and tokens sold
        amountRaised = amountRaised.add(amount);
        tokensSold = tokensSold.add(numTokens);

        assert(tokenReward.transferFrom(tokenOwner, receiver, numTokens));
        FundTransfer(receiver, amount, true, amountRaised);
    }
    
     // Looks up the current token price
    function getPrice() constant returns (uint price) {
        return prices;
    }

    // Manual exchange tokens for BTC,LTC,Fiat contributions.
    // @param receiver who tokens will go to.
    // @param value an amount of tokens.
    function manualExchange(address receiver, uint value) {
        require(msg.sender == tokenOwner);
        require(tokensSold.add(value) <= maxGoal);
        tokensSold = tokensSold.add(value);
        assert(tokenReward.transferFrom(tokenOwner, receiver, value));
    }

   

    modifier afterDeadline() { if (current() >= end) _; }

    // Checks if the goal or time limit has been reached and ends the campaign
    function finalize() afterDeadline {
        require(!crowdsaleEnded);
        tokenReward.burn(); // Burn remaining tokens but the reserved ones
        Finalize(tokenOwner, amountRaised);
        crowdsaleEnded = true;
    }

    // Allows the funders to withdraw their funds if the goal has not been reached.
    // Only works after funds have been returned from the wallet.
    function safeWithdrawal() afterDeadline {
        uint amount = balances[msg.sender];
        if (address(this).balance >= amount) {
            balances[msg.sender] = 0;
            if (amount > 0) {
                msg.sender.transfer(amount);
                FundTransfer(msg.sender, amount, false, amountRaised);
            }
        }
    }
}