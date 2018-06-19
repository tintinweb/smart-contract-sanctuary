pragma solidity ^0.4.11;

contract owned {
    address public owner;

    function owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}

contract DSMath {

    function add(uint256 x, uint256 y) constant internal returns (uint256 z) {
        assert((z = x + y) >= x);
    }

    function sub(uint256 x, uint256 y) constant internal returns (uint256 z) {
        assert((z = x - y) <= x);
    }

    function mul(uint256 x, uint256 y) constant internal returns (uint256 z) {
        assert((z = x * y) >= x);
    }

    function div(uint256 x, uint256 y) constant internal returns (uint256 z) {
        z = x / y;
    }

    function min(uint256 x, uint256 y) constant internal returns (uint256 z) {
        return x <= y ? x : y;
    }

    function max(uint256 x, uint256 y) constant internal returns (uint256 z) {
        return x >= y ? x : y;
    }
}


contract queue {
    Queue public q;

    struct BuyTicket {
        address account;
        uint amount;
        uint time;
    }

    struct Queue {
        BuyTicket[] data;
        uint front;
        uint back;
    }

    function queueSize() constant returns (uint r) {
        r = q.back - q.front;
    }

    function queue() {
        q.data.length = 600000;
    }

    function pushQueue(BuyTicket ticket) internal {
        require((q.back + 1) % q.data.length != q.front);

        q.data[q.back] = ticket;
        q.back = (q.back + 1) % q.data.length;
    }

    function peekQueue() internal returns (BuyTicket r) {
        require(q.back != q.front);

        r = q.data[q.front];
    }

    function popQueue() internal {
        require(q.back != q.front);

        delete q.data[q.front];
        q.front = (q.front + 1) % q.data.length;
    }
}

contract DeCenterToken is owned, queue, DSMath {
    string public standard = &#39;Token 0.1&#39;;
    string public name = &#39;DeCenter&#39;;
    string public symbol = &#39;DC&#39;;
    uint8 public decimals = 8;

    uint256 public totalSupply = 10000000000000000; // 100 million
    uint256 public availableTokens = 6000000000000000; // 60 million
    uint256 public teamAndExpertsTokens = 4000000000000000; // 40 million
    uint256 public price = 0.0000000001 ether; // 0.01 ether per token

    uint public startTime;
    uint public refundStartTime;
    uint public refundDuration = 3 days; // 3 years
    uint public firstStageDuration = 3 days; // 31 days
    uint public lastScheduledTopUp;
    uint public lastProcessedDay = 3;

    uint public maxDailyCap = 3333300000000; // 33 333 DC
    mapping (uint => uint) public dailyTotals;

    uint public queuedAmount;

    address public beneficiary;
    address public expertsAccount;
    address public teamAccount;

    mapping (address => uint256) public balanceOf;

    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);

    // for testing
    uint public cTime = 0;
    function setCTime(uint _cTime) onlyOwner {
        cTime = _cTime;
    }

    function DeCenterToken(
    address _beneficiary,
    address _expertsAccount,
    address _teamAccount,
    uint _startTime,
    uint _refundStartTime
    ) {
        beneficiary = _beneficiary;
        expertsAccount = _expertsAccount;
        teamAccount = _teamAccount;

        startTime = _startTime;
        refundStartTime = _refundStartTime;

        balanceOf[this] = totalSupply;

        scheduledTopUp();
    }

    function time() constant returns (uint) {
        // for testing
        if(cTime > 0) {
            return cTime;
        }

        return block.timestamp;
    }

    function today() constant returns (uint) {
        return dayFor(time());
    }

    function dayFor(uint timestamp) constant returns (uint) {
        return sub(timestamp, startTime) / 24 hours;
    }

    function lowerLimitForToday() constant returns (uint) {
        return today() * 1 ether;
    }

    function scheduledTopUp() onlyOwner {
        uint payment = 400000000000000; // 4 million tokens

        require(sub(time(), lastScheduledTopUp) >= 1 years);
        require(teamAndExpertsTokens >= payment * 2);

        lastScheduledTopUp = time();

        teamAndExpertsTokens -= payment;
        balanceOf[this] = sub(balanceOf[this], payment);
        balanceOf[expertsAccount] = add(balanceOf[expertsAccount], payment);

        teamAndExpertsTokens -= payment;
        balanceOf[this] = sub(balanceOf[this], payment);
        balanceOf[teamAccount] = add(balanceOf[teamAccount], payment);

        Transfer(this, expertsAccount, payment); // execute an event reflecting the change
        Transfer(this, teamAccount, payment); // execute an event reflecting the change
    }

    /* Allow another contract to spend some tokens in your behalf */
    function approve(address _spender, uint256 _value) returns (bool success) {
        allowance[msg.sender][_spender] = _value;

        return true;
    }

    function refund(uint256 _value) internal {
        require(time() > refundStartTime);
        require(this.balance >= _value * price);

        balanceOf[msg.sender] = sub(balanceOf[msg.sender], _value);
        balanceOf[this] = add(balanceOf[this], _value);
        availableTokens = add(availableTokens, _value);

        msg.sender.transfer(_value * price);

        Transfer(msg.sender, this, _value); // Notify anyone listening that this transfer took place
    }

    /* Send tokens */
    function transfer(address _to, uint256 _value) {
        require(balanceOf[msg.sender] >= _value); // Check if the sender has enough

        if (_to == address(this)) {
            refund(_value);
            return;
        }

        balanceOf[msg.sender] = sub(balanceOf[msg.sender], _value);
        balanceOf[_to] = add(balanceOf[_to], _value);

        Transfer(msg.sender, _to, _value); // Notify anyone listening that this transfer took place
    }

    /* A contract attempts to get the tokens */
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        require(balanceOf[_from] >= _value); // Check if the sender has enough
        require(_value <= allowance[_from][msg.sender]); // Check allowance

        allowance[_from][msg.sender] = sub(allowance[_from][msg.sender], _value); //  Subtract from the allowance
        balanceOf[_from] = sub(balanceOf[_from], _value); // Subtract from the sender
        balanceOf[_to] = add(balanceOf[_to], _value); // Add the same to the recipient

        Transfer(_from, _to, _value);

        return true;
    }

    function closeRefund() onlyOwner {
        require(time() - refundStartTime > refundDuration);

        beneficiary.transfer(this.balance);
    }

    /*
     *    Token purchasing has 2 stages:
     *       - First stage holds 31 days. There is no limit of buying.
     *       - Second stage holds ~5 years after. There will be limit of 333.33 ether per day.
     */
    function buy() payable {
        require(startTime <= time()); // check if ICO is going

        uint amount = div(msg.value, price);

        if (time() - startTime > firstStageDuration) { // second stage
            require(1 ether <= msg.value); // check min. limit
            require(msg.value <= 300 ether); // check max. limit

            // send 80% to beneficiary account, another 20% stays for refunding
            beneficiary.transfer(mul(div(msg.value, 5), 4));

            uint currentDay = lastProcessedDay + 1;
            uint limit = maxDailyCap - dailyTotals[currentDay];

            if (limit >= amount) {
                availableTokens = sub(availableTokens, amount);
                balanceOf[this] = sub(balanceOf[this], amount); // subtracts amount from seller&#39;s balance
                dailyTotals[currentDay] = add(dailyTotals[currentDay], amount);
                balanceOf[msg.sender] = add(balanceOf[msg.sender], amount); // adds the amount to buyer&#39;s balance

                Transfer(this, msg.sender, amount); // execute an event reflecting the change
            } else {
                queuedAmount = add(queuedAmount, amount);
                require(queuedAmount <= availableTokens);
                BuyTicket memory ticket = BuyTicket({account: msg.sender, amount: amount, time: time()});
                pushQueue(ticket);
            }

        } else { // first stage
            require(lowerLimitForToday() <= msg.value); // check min. limit
            require(amount <= availableTokens);

            // send 80% to beneficiary account, another 20% stays for refunding
            beneficiary.transfer(mul(div(msg.value, 5), 4));

            availableTokens = sub(availableTokens, amount);
            balanceOf[this] = sub(balanceOf[this], amount); // subtracts amount from seller&#39;s balance
            balanceOf[msg.sender] = add(balanceOf[msg.sender], amount); // adds the amount to buyer&#39;s balance

            Transfer(this, msg.sender, amount); // execute an event reflecting the change
        }
    }

    function processPendingTickets() onlyOwner {

        uint size = queueSize();
        uint ptr = 0;
        uint currentDay;
        uint limit;
        BuyTicket memory ticket;

        while (ptr < size) {
            currentDay = lastProcessedDay + 1;
            limit = maxDailyCap - dailyTotals[currentDay];

            // stop then trying to process future
            if (startTime + (currentDay - 1) * 1 days > time()) {
                return;
            }

            // limit to prevent out of gas error
            if (ptr > 50) {
                return;
            }

            ticket = peekQueue();

            if (limit < ticket.amount || ticket.time - 1000 seconds > startTime + (currentDay - 1) * 1 days) {
                lastProcessedDay += 1;
                continue;
            }

            popQueue();
            ptr += 1;

            availableTokens = sub(availableTokens, ticket.amount);
            queuedAmount = sub(queuedAmount, ticket.amount);
            dailyTotals[currentDay] = add(dailyTotals[currentDay], ticket.amount);
            balanceOf[this] = sub(balanceOf[this], ticket.amount);
            balanceOf[ticket.account] = add(balanceOf[ticket.account], ticket.amount); // adds the amount to buyer&#39;s balance

            Transfer(this, ticket.account, ticket.amount); // execute an event reflecting the change
        }
    }

    function() payable {
        buy();
    }
}