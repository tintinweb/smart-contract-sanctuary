pragma solidity ^0.5.8;



// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
     require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

contract Administration is SafeMath {
    // ----------------------------------------------------------------------------
    // Variables
    // ----------------------------------------------------------------------------
    address payable CEOAddress;
    address public CTOAddress;
    address Signer;

    bool public paused = false;
    
    // ----------------------------------------------------------------------------
    // Events
    // ----------------------------------------------------------------------------
    event Pause();
    event Unpause();
    event CTOTransfer(address newCTO, address oldCTO);

    // ---------------------------------------------------------------------------- 
    // Modifiers
    // ----------------------------------------------------------------------------
    modifier onlyCEO() {
        require(msg.sender == CEOAddress);
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == CEOAddress || msg.sender == CTOAddress);
        _;
    }

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused() {
        require(paused);
        _;
    }

    // ----------------------------------------------------------------------------
    // Public Functions
    // ----------------------------------------------------------------------------
    function setCTO(address _newAdmin) public onlyCEO {
        require(_newAdmin != address(0));
        emit CTOTransfer(_newAdmin, CTOAddress);
        CTOAddress = _newAdmin;
    }

    function withdrawBalance() external onlyCEO {
        CEOAddress.transfer(address(this).balance);
    }

    function pause() public onlyAdmin whenNotPaused returns(bool) {
        paused = true;
        emit Pause();
        return true;
    }

    function unpause() public onlyAdmin whenPaused returns(bool) {
        paused = false;
        emit Unpause();
        return true;
    }
}

contract Creative is Administration {
    // ----------------------------------------------------------------------------
    // Variables
    // ----------------------------------------------------------------------------
    struct Bet {
        uint[4] amount;
        uint timestamp;
    }
    
    struct Contract {
        uint result; //0-while running, 1-4 winner
        uint sides;
        uint StartTime;
        uint BetEndTime;
        uint ContractTime;
        mapping(address => Bet) PlayerToBet;
        mapping(address => bool) IfPlayed;
        mapping(address => bool) IfClaimed;
    }
    
    Contract[] contracts;
    
    uint public minBet = 10 finney;
    uint public maxBet = 10000 ether;
    
    uint TimeFactor;
    
    uint public contractFee = 100 finney;
    uint public taxRate = 9750;
    
    // ----------------------------------------------------------------------------
    // Mappings
    // ----------------------------------------------------------------------------
    mapping (uint => uint) TotalAmount;
    mapping (uint => uint[4]) EachAmount;
    mapping (uint => uint) TotalPlayers;
    
    // ----------------------------------------------------------------------------
    // Events
    // ----------------------------------------------------------------------------
    event ContractCreated(uint indexed contractId, uint sides, uint[4] eachAmount, address creator, uint contractTime, uint betEndTime);
    event NewBetSuccess(address indexed player, uint indexed side, uint[4] indexed amount, uint timeFactor);
    event BetAdjustSuccess(address indexed player, uint indexed side, uint[4] indexed amount, uint timeFactor);
    event ContractRevealed(uint indexed contractId, uint indexed result);
    event ContractClaimed(address indexed winner, uint indexed reward);
    
    // ----------------------------------------------------------------------------
    // Internal Functions
    // ----------------------------------------------------------------------------
    function _calculateTimeFactor(uint _betEndTime, uint _startTime) internal view returns (uint) {
        return (_betEndTime - now)*100/(_betEndTime - _startTime);
    }
    
    // ----------------------------------------------------------------------------
    // Public Functions
    // ----------------------------------------------------------------------------
    constructor(address _CTOAddress) public {
        CEOAddress = msg.sender;
        CTOAddress = _CTOAddress;
    }
    
    function createContract(uint sides, uint[4] memory amounts, uint contractTime, uint betEndTime) public payable whenNotPaused returns (uint) {
        require(amounts[0] > 0 || amounts[1] > 0 || amounts[2] > 0 || amounts[3] > 0, "SEER OFFICAL WARNING: At least bet on one side");
        uint total = amounts[0] + amounts[1] + amounts[2] + amounts[3];
        require(sides >= 2 && sides <= 4, "SEER OFFICAL WARNING: Can only have 2-4 sides");
        require(msg.value >= (total + contractFee), "SEER OFFICAL WARNING: Does not send enough ETH");
        require((now + 1 hours) <= betEndTime, "SEER OFFICAL WARNING: At least have one hour bet time");
        require((contractTime - now)/3 >= (betEndTime - now), "SEER OFFICAL WARNING: Bet time need to be less or equal than 1/3 of total contract time");
        Bet memory _bet = Bet({
            amount: amounts,
            timestamp: _calculateTimeFactor(betEndTime, now)
        });
        Contract memory _contract = Contract({
           result: 0,
           sides: sides,
           StartTime: now,
           BetEndTime: betEndTime,
           ContractTime: contractTime
        });
        uint newContractId = contracts.push(_contract) - 1;
        Contract storage newContract = contracts[newContractId];
        newContract.PlayerToBet[msg.sender] = _bet;
        newContract.IfPlayed[msg.sender] = true;
        TotalAmount[newContractId] = total;
        EachAmount[newContractId] = amounts;
        TotalPlayers[newContractId] = 1;
        emit ContractCreated(newContractId, sides, amounts, msg.sender, contractTime, betEndTime);
        return 0;
    }
    
    function betContract(uint contractId, uint side, uint amount) public payable whenNotPaused returns (bool) {
        require(TotalAmount[contractId] > 0, "SEER OFFICAL WARNING: Contract has not been created");
        require(amount >= minBet && amount <= maxBet, "SEER OFFICAL WARNING: Does not meet min or max bet requirement");
        require(msg.value >= amount, "SEER OFFICAL WARNING: Does not send enough ETH");
        Contract storage _contract = contracts[contractId];
        require(side < _contract.sides, "SEER OFFICAL WARNING: You did not in correct side range");
        require(now < _contract.BetEndTime, "SEER OFFICAL WARNING: Contract cannot be bet anymore");
        require(_contract.result == 0, "SEER OFFICAL WARNING: Contact terminated");
        uint timeFactor = _calculateTimeFactor(_contract.BetEndTime, _contract.StartTime);
        if(_contract.IfPlayed[msg.sender] == true) {
            Bet storage _bet = _contract.PlayerToBet[msg.sender];
            _bet.amount[side] += amount;
            _bet.timestamp = timeFactor;
            EachAmount[contractId][side] += amount;
            TotalAmount[contractId] += amount;
            emit BetAdjustSuccess(msg.sender, side, _bet.amount, timeFactor);
        } else {
            uint[4] memory _amount;
            _amount[side] = amount;
            Bet memory _bet = Bet({
                amount: _amount,
                timestamp: timeFactor
            });
            _contract.IfPlayed[msg.sender] = true;
            _contract.PlayerToBet[msg.sender] = _bet;
            EachAmount[contractId][side] += amount;
            TotalAmount[contractId] += amount;
            TotalPlayers[contractId] += 1;
            emit NewBetSuccess(msg.sender, side, _amount, timeFactor);
        }
        return true;
    }
    
    function revealContract(uint contractId, uint result) public whenNotPaused onlyAdmin {
        require(result >= 1 && result<= 4, "SEER OFFICAL WARNING: Cannot recogonize result");
        Contract storage _contract = contracts[contractId];
        require(now > _contract.ContractTime, "SEER OFFICAL WARNING: Contract cannot be revealed yet");
        _contract.result = result;
        emit ContractRevealed(contractId, result);
    }
    
    function claimContract(uint contractId) public whenNotPaused returns (uint) {
        require(TotalAmount[contractId] > 0, "SEER OFFICAL WARNING: Contract has not been created");
        Contract storage _contract = contracts[contractId];
        require(_contract.result > 0, "SEER OFFICAL WARNING: Contract has not been revealed");
        require(_contract.IfPlayed[msg.sender] == true, "SEER OFFICAL WARNING: You did not play this contract");
        require(_contract.IfClaimed[msg.sender] == false, "SEER OFFICAL WARNING: You already claimed reward");
        uint reward;
        uint[4] memory _amount = _contract.PlayerToBet[msg.sender].amount;
        require(_amount[_contract.result - 1] > 0, "SEER OFFICAL WARNING: You are not qualified");
        reward = _amount[_contract.result - 1]*taxRate*TotalAmount[contractId]/EachAmount[contractId][_contract.result - 1]/10000;
        msg.sender.transfer(reward);
        _contract.IfClaimed[msg.sender] == true;
        emit ContractClaimed(msg.sender, reward);
        return reward;
    }
    
    function adjustBetLimit(uint _minBet, uint _maxBet) public onlyAdmin {
        minBet = _minBet;
        maxBet = _maxBet;
    }
    
    function adjustFee(uint _fee) public onlyAdmin {
        contractFee = _fee;
    }
    
    function adjustTax(uint _tax) public onlyAdmin {
        taxRate = _tax;
    }
    
    function getContractAmount(uint contractId) public view returns (
        uint totalAmount,
        uint amountOne,
        uint amountTwo,
        uint amountThree,
        uint amountFour
    ) {
        totalAmount = TotalAmount[contractId];
        amountOne = EachAmount[contractId][0];
        amountTwo = EachAmount[contractId][1];
        amountThree = EachAmount[contractId][2];
        amountFour = EachAmount[contractId][3];
    }
    
    function getContractPlayerNum(uint contractId) public view returns (uint totalPlayer) {
        totalPlayer = TotalPlayers[contractId];
    }
    
    function getIfPlayed(uint contractId, address player) public view returns (bool ifPlayed) {
        ifPlayed = contracts[contractId].IfPlayed[player];
    }
    
    function getContractTime(uint contractId) public view returns (
        uint contractTime,
        uint betEndTime
    ) {
        contractTime = contracts[contractId].ContractTime;
        betEndTime = contracts[contractId].BetEndTime;
    }
    
    function getContractBet(uint contractId, address player) public view returns (
        uint[4] memory amounts,
        uint timeFactor
    ) {
        amounts = contracts[contractId].PlayerToBet[player].amount;
        timeFactor = contracts[contractId].PlayerToBet[player].timestamp;
    }
    
    function getContractResult(uint contractId) public view returns (uint result) {
        result =  contracts[contractId].result;
    }
    
    function getIfClaimed(uint contractId, address player) public view returns (bool ifClaimed) {
        ifClaimed = contracts[contractId].IfClaimed[player];
    }
}