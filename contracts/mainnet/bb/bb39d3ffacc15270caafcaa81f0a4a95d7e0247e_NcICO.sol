pragma solidity ^0.4.15;

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
        assert(b &lt;= a);
        return a - b;
    }

    function add(uint a, uint b) internal returns (uint) {
        uint c = a + b;
        assert(c &gt;= a &amp;&amp; c &gt;= b);
        return c;
    }
}

contract NcICO {
    using SafeMath for uint;
    uint public prices;
    // The start date of the crowdsale
    uint public start; // Friday, 19 January 2018 10:00:00 GMT
    // The end date of the crowdsale
    uint public end; // Friday, 26 January 2018 10:00:00 GMT
    // The balances (in ETH) of all token holders
    mapping(address =&gt; uint) public balances;
    // Indicates if the crowdsale has been ended already
    bool public crowdsaleEnded = false;
    // Tokens will be transfered from this address
    address public tokenOwner;
    // The address of the token contract
    token public tokenReward;
    // The wallet on which the funds will be stored
    address wallet;
    uint public amountRaised;
    uint public deadline;
    //uint public price;
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
    function NcICO(
        address tokenAddr, 
        address walletAddr, 
        address tokenOwnerAddr,
        uint durationInMinutes,
        uint etherCostOfEachToken
        //uint startTime,
        //uint endTime,
        //uint price
        ) {
        tokenReward = token(tokenAddr);
        wallet = walletAddr;
        tokenOwner = tokenOwnerAddr;
        deadline = now + durationInMinutes * 1 minutes;
        //start = startTime;
        //end = endTime;
        prices = etherCostOfEachToken * 0.0000001 ether;
    }

    // Exchange CHP by sending ether to the contract.
    function() payable {
        //  require(!crowdsaleClosed);
        // uint amount = msg.value;
        // balances[msg.sender] += amount;
        // amountRaised += amount;
        // tokenReward.transfer(msg.sender, amount / prices);
        // FundTransfer(msg.sender, amount, true);
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

        require(numTokens &gt; 0);
        //require(!crowdsaleEnded &amp;&amp; current() &gt;= start &amp;&amp; current() &lt;= end &amp;&amp; tokensSold.add(numTokens) &lt;= maxGoal);

        wallet.transfer(amount);
        balances[receiver] = balances[receiver].add(amount);

        // Calculate how much raised and tokens sold
        amountRaised = amountRaised.add(amount);
       //tokensSold = tokensSold.add(numTokens);

        assert(tokenReward.transferFrom(tokenOwner, receiver, numTokens));
        FundTransfer(receiver, amount, true, amountRaised);
    }

    // Manual exchange tokens for BTC,LTC,Fiat contributions.
    // @param receiver who tokens will go to.
    // @param value an amount of tokens.
    function manualExchange(address receiver, uint value) {
        require(msg.sender == tokenOwner);
       // require(tokensSold.add(value) &lt;= maxGoal);
        //tokensSold = tokensSold.add(value);
        assert(tokenReward.transferFrom(tokenOwner, receiver, value));
    }

    // Looks up the current token price
    function getPrice() constant returns (uint price) {
        // for(uint i = 0; i &lt; amount_stages.length; i++) {
        //     if(tokensSold &lt; amount_stages[i])
        //         return prices[i];
        // }
       // return prices[prices.length-1];
       
       return prices;
    }

    modifier afterDeadline() { if (current() &gt;= end) _; }

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
        if (address(this).balance &gt;= amount) {
            balances[msg.sender] = 0;
            if (amount &gt; 0) {
                msg.sender.transfer(amount);
                FundTransfer(msg.sender, amount, false, amountRaised);
            }
        }
    }
}