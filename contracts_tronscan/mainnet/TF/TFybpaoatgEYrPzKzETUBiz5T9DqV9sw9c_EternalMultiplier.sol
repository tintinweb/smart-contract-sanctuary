//SourceUnit: x130.sol

pragma solidity ^0.4.25;

contract EternalMultiplier {

    //The deposit structure holds all the info about the deposit made
    struct Deposit {
        address depositor; // The depositor address
        uint deposit;   // The deposit amount
        uint payout; // Amount already paid
    }

    uint public roundDuration = 14400;
    
    mapping (uint => Deposit[]) public queue;  // The queue
    mapping (uint => mapping (address => uint)) public depositNumber; // Investor deposit index
    mapping (uint => uint) public currentReceiverIndex; // The index of the depositor in the queue
    mapping (uint => uint) public totalInvested; // Total invested amount
    mapping (address => uint) public totalIn;
    mapping (address => uint) public totalOut;
    
    uint public tokenId = 1002830;
    uint public initialMiningStage = 1265;
    uint public initialBlockNumber = initialMiningStage * roundDuration;
    uint public totalFrozen;
    mapping (address => uint) public frozen; // Frozen tokens
    
    uint public prizeFund;
    bool public prizeReceived;
    address public lastInvestor;
    uint public lastInvestedAt;

    address public support = msg.sender;
    
    uint public totalInvestorsAll;
    uint public totalInvestedAll;
    mapping (address => bool) public registered; // Registered users
    mapping (address => address) public referrers; // Referrers
    
    event Registered(address user);
    event Invest(address user, uint stage, uint amount);
    
    function calcMiningReward(uint stage) public view returns (uint) {
        if (stage < initialMiningStage + 100) {
            return 100 + initialMiningStage - stage;
        } else {
            return 0;
        }
    }

    //This function receives all the deposits
    //stores them and make immediate payouts
    function invest(address referrerAddress) public payable {
        require(block.number >= initialBlockNumber);
        require(block.number % roundDuration < roundDuration - 20);
        uint stage = block.number / roundDuration;
        require(stage >= initialMiningStage);

        if(msg.value > 0){
            require(gasleft() >= 250000); // We need gas to process queue
            require(msg.value >= 100000000 && msg.value <= calcMaxDeposit(stage)); // Too small and too big deposits are not accepted
            require(depositNumber[stage][msg.sender] == 0); // Investor should not already be in the queue

            // Add the investor into the queue
            queue[stage].push( Deposit(msg.sender, msg.value, 0) );
            depositNumber[stage][msg.sender] = queue[stage].length;

            totalInvested[stage] += msg.value;
            totalInvestedAll += msg.value;

            prizeFund += msg.value / 25;
            lastInvestor = msg.sender;
            lastInvestedAt = block.number;
            prizeReceived = false;
            
            support.transfer(msg.value * 3 / 25);
            
            _register(referrerAddress);
            if (referrers[msg.sender] != 0x0) {
                referrers[msg.sender].transfer(msg.value / 20);
            }
            
            uint miningReward = calcMiningReward(stage);
            if (miningReward > 0) {
              msg.sender.transferToken(msg.value * miningReward, tokenId);
            }
            
            totalIn[msg.sender] += msg.value;
            
            emit Invest(msg.sender, stage, msg.value);

            // Pay to first investors in line
            pay(stage);
        }
    }

    // Used to pay to current investors
    // Each new transaction processes 1 - 4+ investors in the head of queue
    // depending on balance and gas left
    function pay(uint stage) internal {

        uint money = address(this).balance - prizeFund;
        uint multiplier = calcMultiplier(stage);

        // We will do cycle on the queue
        for (uint i = 0; i < queue[stage].length; i++){

            uint idx = currentReceiverIndex[stage] + i;  //get the index of the currently first investor

            Deposit storage dep = queue[stage][idx]; // get the info of the first investor

            uint totalPayout = dep.deposit * multiplier / 100;
            uint leftPayout;

            if (totalPayout > dep.payout) {
                leftPayout = totalPayout - dep.payout;
            }

            if (money >= leftPayout) { //If we have enough money on the contract to fully pay to investor

                if (leftPayout > 0) {
                    dep.depositor.transfer(leftPayout); // Send money to him
                    totalOut[dep.depositor] += leftPayout;
                    money -= leftPayout;
                }

                // this investor is fully paid, so remove him
                depositNumber[stage][dep.depositor] = 0;
                delete queue[stage][idx];

            } else{

                // Here we don't have enough money so partially pay to investor
                dep.depositor.transfer(money); // Send to him everything we have
                totalOut[dep.depositor] += money;
                dep.payout += money;       // Update the payout amount
                break;                     // Exit cycle

            }

            if (gasleft() <= 55000) {         // Check the gas left. If it is low, exit the cycle
                break;                       // The next investor will process the line further
            }
        }

        currentReceiverIndex[stage] += i; //Update the index of the current first investor
    }

    // Get current queue size
    function getQueueLength(uint stage) public view returns (uint) {
        return queue[stage].length;
    }

    // Get max deposit for your investment
    function calcMaxDeposit(uint stage) public view returns (uint) {

        if (totalInvested[stage] <= 100000000000) { // 100,000 TRX
            return 10000000000; // 10,000 TRX
        } else if (totalInvested[stage] <= 200000000000) { // 200,000 TRX
            return 20000000000; // 20,000 TRX
        } else if (totalInvested[stage] <= 500000000000) { // 500,000 TRX
            return 50000000000; // 50,000 TRX
        } else {
            return 500000000000; // 500,000 TRX
        }

    }

    // How many percent for your deposit to be multiplied at now
    function calcMultiplier(uint stage) public view returns (uint) {

        if (totalInvested[stage] <= 100000000000) { // 100,000 TRX
            return 130;
        } else if (totalInvested[stage] <= 200000000000) { // 200,000 TRX
            return 120;
        } else if (totalInvested[stage] <= 500000000000) { // 500,000 TRX
            return 115;
        } else {
            return 110;
        }

    }

    function _register(address referrerAddress) internal {
        if (!registered[msg.sender]) {   
            if (registered[referrerAddress] && referrerAddress != msg.sender) {
                referrers[msg.sender] = referrerAddress;
            }

            totalInvestorsAll++;
            registered[msg.sender] = true;

            emit Registered(msg.sender);
        }
    }

    function register(address referrerAddress) external {
        _register(referrerAddress);
    }

    function freeze(address referrerAddress) external payable {
        require(msg.tokenid == tokenId);
        require(msg.tokenvalue > 0);

        _register(referrerAddress);

        frozen[msg.sender] += msg.tokenvalue;
        totalFrozen += msg.tokenvalue;
    }

    function unfreeze() external {
        totalFrozen -= frozen[msg.sender];
        msg.sender.transferToken(frozen[msg.sender], tokenId);
        frozen[msg.sender] = 0;
    }

    function allowGetPrizeFund(address user) public view returns (bool) {
        return !prizeReceived && lastInvestor == user && block.number >= lastInvestedAt + 100 && prizeFund >= 2000000;
    }

    function getPrizeFund() external {
        require(allowGetPrizeFund(msg.sender));
        uint amount = prizeFund / 2;
        msg.sender.transfer(amount);
        prizeFund -= amount;
        prizeReceived = true;
    }

}