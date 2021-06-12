/**
 *Submitted for verification at Etherscan.io on 2021-06-12
*/

pragma solidity ^0.4.15;

contract GluonBinaryOptions {

    address public owner;

    enum Result { Unresolved, Yes, No, Undecided }
    
    struct Option {
        string optionCode; //e.g. BTC-45000 : BTC will be more than 45000 USD before expiry, ETH-3500
        bytes32 identifier;
        string description;
        uint expiryBlock;
        bool resolved;
        Result result;
        uint totalPot;                
        mapping(uint8 => uint) betsByOutcome; 
    }

    struct Bet {
        uint amount;
        Result predictedResult;
        bool paidOut;
    }

    mapping(uint => Option) public optionsArray;
    uint public optionsCount;
    mapping(bytes32 => Option) public Options;

    mapping(address => mapping(bytes32 => Bet)) public Bets;

    

    constructor () public {
        owner = msg.sender;
    }

    function getResultBalance(bytes32 identifier, Result result)
        isValidResult(result)
        public 
        constant 
        returns(uint balance) {
            return Options[identifier].betsByOutcome[uint8(result)];
    }

    function getTotalPot(bytes32 identifier) 
        public
        constant 
        returns(uint totalPot) {
            return Options[identifier].totalPot;
    }    
       
    function addBinaryOption(string optionCode, string description, uint durationInBlocks) isOwner() public returns(bool success){
        bytes32 id = keccak256(abi.encodePacked(optionCode, description, durationInBlocks));
        return addBinaryOption(id, optionCode, description, durationInBlocks);
    }   
    function addBinaryOption(bytes32 identifier, string optionCode, string description, uint durationInBlocks)
        isOwner()
        private returns(bool success) {
        
        require(durationInBlocks > 0);

        require(Options[identifier].expiryBlock == 0);

        Option memory option;
        option.expiryBlock = block.number + durationInBlocks;
        option.optionCode = optionCode;
        option.identifier = identifier;
        option.description = description;
        option.resolved = false;
        option.result = Result.Unresolved;
        Options[identifier] = option;
        optionsArray[optionsCount] = option;
        optionsCount ++;
        return true;
    }
    /*function predict(string optionCode, Result result) public isValidResult(result)
        payable returns(bool success) {
        bytes32 id = keccak256(abi.encodePacked(optionCode));
        return predict(id, result);
    }*/
    function placeBet(bytes32 identifier, Result result) public
        isValidResult(result)
        payable returns(bool success) {

        require(msg.value > 0);

        require(Options[identifier].expiryBlock > 0);

        require(Options[identifier].expiryBlock >= block.number);

        require(!Options[identifier].resolved);

        require(Bets[msg.sender][identifier].amount == 0);

        Option storage option = Options[identifier];

        option.betsByOutcome[uint8(result)] += msg.value;
        option.totalPot += msg.value;

        Bet memory bet;
        bet.amount = msg.value;
        bet.predictedResult = result;
        Bets[msg.sender][identifier] = bet;

        return true;
    }
    /*function resolveOption(string optionCode) isOwner() public returns(bool success){
        return resolveOption(keccak256(abi.encodePacked(optionCode)));
    }*/
    function resolveOption(bytes32 identifier) 
        isOwner()
        public 
        returns(bool success) {

        Option storage option = Options[identifier];
        option.resolved = true;
        
        return true;
    }
    /*function setOptionResult(string optionCode, Result result)
    isOwner() public returns(bool success)
    {
        return setOptionResult(keccak256(abi.encodePacked(optionCode)), result);
    }*/

    function setOptionResult(bytes32 identifier, Result result) 
        isOwner()
        public
        returns(bool success) {
        
        require(result == Result.Yes || result == Result.No || result == Result.Undecided);
        
        Option storage option = Options[identifier];
        
        require(option.resolved);
        
        option.result = result;
        
        return true;        
    }
    /*function requestPayout(string optionCode)
        public 
        returns(bool success) {
            return requestPayout(keccak256(abi.encodePacked(optionCode)));
    }*/
    function receivePayment(bytes32 identifier)
        public 
        returns(bool success) {
        
        Option storage option = Options[identifier];

        require(option.expiryBlock > 0);

        Bet storage bet = Bets[msg.sender][identifier];
        
        require(bet.amount > 0);

        require(!bet.paidOut);
        
        if(!option.resolved) {
            require(option.expiryBlock > block.number);
        }
        
        uint totalPot = option.totalPot;
        uint ResultBalance = getResultBalance(identifier, bet.predictedResult);

        uint r = 1;

        if (option.result != Result.Undecided) {
            require(bet.predictedResult == option.result);
            
            r = totalPot / ResultBalance;
        }
        
        uint payoutAmount = r * bet.amount;

        bet.paidOut = true;
        option.totalPot -= payoutAmount;
        msg.sender.transfer(payoutAmount);
        
        return true;
    }

    function kill() isOwner() public {
        selfdestruct(owner);
    }

    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier isValidResult(Result result) {
        require(result == Result.Yes || result == Result.No);
        _;
    }
}