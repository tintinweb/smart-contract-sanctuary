pragma solidity ^0.4.25;

/**
 *
 * Best Multiplier - profitable financial game
 * Honest, fully automated smart quick turn contract with a jackpot system
 *
 * Web              - https://bestmultiplier.biz
 * Telegram channel - https://t.me/bestMultiplierNews
 * Telegram chat    - https://t.me/bestMultiplier
 *
 *  - Contribution allocation schemes:
 *    -- 90% players
 *    -- 5% jackpot
 *    -- 3.25% promotion
 *    -- 1.75% support
 *
 *  - Limits:
 *    -- Min deposit: 0.01 ETH
 *    -- Min deposit for jackpot: 0.05 ETH
 *    -- Max deposit: 7 ETH
 *    -- Max gas price: 50 GWEI
 *
 * Recommended gas limit: 300000
 * Recommended gas price: https://ethgasstation.info/
 *
 */
contract BestMultiplier1 {

    uint constant MINIMAL_DEPOSIT = 0.01 ether; // minimum deposit for participation in the game
    uint constant MAX_DEPOSIT = 7 ether; // maximum possible deposit

    uint constant JACKPOT_MINIMAL_DEPOSIT = 0.05 ether; // minimum deposit for jackpot
    uint constant JACKPOT_DURATION = 20 minutes; // the duration of the jackpot after which the winner will be determined

    uint constant JACKPOT_PERCENTAGE = 500; // jackpot winner gets 5% of all deposits
    uint constant PROMOTION_PERCENTAGE = 325; // 3.25% will be sent to the promotion of the project
    uint constant PAYROLL_PERCENTAGE = 175; // 1.75% will be sent to support the project

    uint constant MAX_GAS_PRICE = 50; // maximum price for gas in gwei

    // These 2 addresses, one of which is a backup, can set a new time to start the game.
    address constant MANAGER = 0x4b8419BAf71A013C9D39b26a6a8C7BF7B25B5F32;
    address constant RESERVE_MANAGER = 0x4b8419BAf71A013C9D39b26a6a8C7BF7B25B5F32;

    // Address where ETH will be sent for project promotion
    address constant PROMOTION_FUND = 0x4b8419BAf71A013C9D39b26a6a8C7BF7B25B5F32;

    // Address where ETH will be sent to support the project
    address constant SUPPORT_FUND = 0x4b8419BAf71A013C9D39b26a6a8C7BF7B25B5F32;

    struct Deposit {
        address member;
        uint amount;
    }

    struct Jackpot {
        address lastMember;
        uint time;
        uint amount;
    }

    Deposit[] public deposits; // keeps a history of all deposits
    Jackpot public jackpot; // stores the data for the current jackpot

    uint public totalInvested; // how many ETH were collected for this game
    uint public currentIndex; // current deposit index
    uint public startTime; // start time game. If this value is 0, the contract is temporarily stopped

    // this function called every time anyone sends a transaction to this contract
    function () public payable {

        // the contract can only take ETH when the game is running
        require(isRunning());

        // gas price check
        require(tx.gasprice <= MAX_GAS_PRICE * 1000000000);

        address member = msg.sender; // address of the current player who sent the ETH
        uint amount = msg.value; // the amount sent by this player

        // ckeck to jackpot winner
        if (now - jackpot.time >= JACKPOT_DURATION && jackpot.time > 0) {

            send(member, amount); // return this deposit to the sender

            if (!payouts()) { // send remaining payouts
                return;
            }

            send(jackpot.lastMember, jackpot.amount); // send jackpot to winner
            startTime = 0; // stop queue
            return;
        }

        // deposit check
        require(amount >= MINIMAL_DEPOSIT && amount <= MAX_DEPOSIT);

        // add member to jackpot
        if (amount >= JACKPOT_MINIMAL_DEPOSIT) {
            jackpot.lastMember = member;
            jackpot.time = now;
        }

        // update variables in storage
        deposits.push( Deposit(member, amount * calcMultiplier() / 100) );
        totalInvested += amount;
        jackpot.amount += amount * JACKPOT_PERCENTAGE / 10000;

        // send fee
        send(SUPPORT_FUND, amount * PAYROLL_PERCENTAGE / 10000);
        //send(PROMOTION_FUND, amount * PROMOTION_PERCENTAGE / 10000);

        // send payouts
        payouts();

    }

    // This function sends amounts to players who are in the current queue
    // Returns true if all available ETH is sent
    function payouts() internal returns(bool complete) {

        uint balance = address(this).balance;

        // impossible but better to check
        balance = balance >= jackpot.amount ? balance - jackpot.amount : 0;

        uint countPayouts;

        for (uint i = currentIndex; i < deposits.length; i++) {

            Deposit storage deposit = deposits[currentIndex];

            if (balance >= deposit.amount) {

                send(deposit.member, deposit.amount);
                balance -= deposit.amount;
                delete deposits[currentIndex];
                currentIndex++;
                countPayouts++;

                // Maximum of one request can send no more than 15 payments
                // This was done so that players could not spend too much gas in 1 transaction
                if (countPayouts >= 15) {
                    break;
                }

            } else {

                send(deposit.member, balance);
                deposit.amount -= balance;
                complete = true;
                break;

            }
        }

    }

    // This function safely sends the ETH by the passed parameters
    function send(address _receiver, uint _amount) internal {

        if (_amount > 0 && address(_receiver) != 0) {
            _receiver.transfer(msg.value);
        }

    }

    // This function makes the game restart on a specific date when it is stopped or in waiting mode
    // (Available only to managers)
    function restart(uint _time) public {

        require(MANAGER == msg.sender || RESERVE_MANAGER == msg.sender);
        require(!isRunning());
        require(_time >= now + 10 minutes);

        currentIndex = deposits.length; // skip investors from old queue
        startTime = _time; // set the time to start the project
        totalInvested = 0;

        delete jackpot;

    }

    // Returns true if the game is in stopped mode
    function isStopped() public view returns(bool) {
        return startTime == 0;
    }

    // Returns true if the game is in waiting mode
    function isWaiting() public view returns(bool) {
        return startTime > now;
    }

    // Returns true if the game is in running mode
    function isRunning() public view returns(bool) {
        return !isWaiting() && !isStopped();
    }

    // How many percent for your deposit to be multiplied at now
    function calcMultiplier() public view returns (uint) {

        if (totalInvested <= 75 ether) return 120;
        if (totalInvested <= 200 ether) return 130;
        if (totalInvested <= 350 ether) return 135;

        return 140; // max value
    }

    // This function returns all active player deposits in the current queue
    function depositsOfMember(address _member) public view returns(uint[] amounts, uint[] places) {

        uint count;
        for (uint i = currentIndex; i < deposits.length; i++) {
            if (deposits[i].member == _member) {
                count++;
            }
        }

        amounts = new uint[](count);
        places = new uint[](count);

        uint id;
        for (i = currentIndex; i < deposits.length; i++) {

            if (deposits[i].member == _member) {
                amounts[id] = deposits[i].amount;
                places[id] = i - currentIndex + 1;
                id++;
            }

        }

    }

    // This function returns detailed information about the current game
    function stats() public view returns(
        string status,
        uint timestamp,
        uint timeStart,
        uint timeJackpot,
        uint queueLength,
        uint invested,
        uint multiplier,
        uint jackpotAmount,
        address jackpotMember
    ) {

        if (isStopped()) {
            status = "stopped";
        } else if (isWaiting()) {
            status = "waiting";
        } else {
            status = "running";
        }

        if (isWaiting()) {
            timeStart = startTime - now;
        }

        if (now - jackpot.time < JACKPOT_DURATION) {
            timeJackpot = JACKPOT_DURATION - (now - jackpot.time);
        }

        timestamp = now;
        queueLength = deposits.length - currentIndex;
        invested = totalInvested;
        jackpotAmount = jackpot.amount;
        jackpotMember = jackpot.lastMember;
        multiplier = calcMultiplier();

    }

}