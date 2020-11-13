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
    // Mappings
    // ----------------------------------------------------------------------------
    
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
    // Internal Functions
    // ----------------------------------------------------------------------------
    
    // ----------------------------------------------------------------------------
    // Public Functions
    // ----------------------------------------------------------------------------
    function setCTO(address _newAdmin) public onlyCEO {
        require(_newAdmin != address(0));
        emit CTOTransfer(_newAdmin, CTOAddress);
        CTOAddress = _newAdmin;
    }

    function withdrawBalance() external onlyAdmin {
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

contract TrumpBet is Administration {
    // ----------------------------------------------------------------------------
    // Variables
    // ----------------------------------------------------------------------------
    struct Bet {
        uint posAmount;
        uint negAmount;
        uint timestamp;
    }
    
    uint public TotalAmount;
    uint public TotalSupport;
    uint public TotalOppose;
    
    uint public TotalPlayers;
    
    uint minBet = 100 finney;
    uint maxBet = 10000 ether;
    
    uint public ContractTime;
    uint ElectionTime = 1604332800;//2020年11月3日
    uint TimeFactor;
    
    // ----------------------------------------------------------------------------
    // Mappings
    // ----------------------------------------------------------------------------
    mapping (address => Bet) PlayerToBet;
    mapping (address => bool) PlayerIfBet;
    
    // ----------------------------------------------------------------------------
    // Events
    // ----------------------------------------------------------------------------
    event NewBetSuccess(address indexed player, bool indexed opinion, uint indexed amount, uint timeFactor);
    event BetAdjustSuccess(address indexed player, uint indexed posAmount, uint indexed negAmount, uint timeFactor);
    
    // ---------------------------------------------------------------------------- 
    // Modifiers
    // ----------------------------------------------------------------------------
    
    // ----------------------------------------------------------------------------
    // Internal Functions
    // ----------------------------------------------------------------------------
    function _calculateTimeFactor() internal view returns (uint) {
        return safeSub(ElectionTime, now)*100/safeSub(ElectionTime,ContractTime);
    }
    
    // ----------------------------------------------------------------------------
    // Public Functions
    // ----------------------------------------------------------------------------
    constructor(address _CTOAddress) public {
        CEOAddress = msg.sender;
        CTOAddress = _CTOAddress;
        ContractTime = now;
    }
    
    function betTrump(uint _amount, bool _opinion) public payable whenNotPaused{
        require(msg.value >= _amount);
        require(_amount >= minBet && _amount <= maxBet); 
        uint currentFactor = _calculateTimeFactor();
        if(PlayerIfBet[msg.sender] = false) {
            if(_opinion == true){
                Bet memory _bet = Bet({
                    posAmount: _amount,
                    negAmount: 0,
                    timestamp: currentFactor
                });
                PlayerToBet[msg.sender] = _bet;
            } else {
                Bet memory _bet = Bet({
                    posAmount: 0,
                    negAmount: _amount,
                    timestamp: currentFactor
                });
                PlayerToBet[msg.sender] = _bet;
            }
            TotalPlayers += 1;
            PlayerIfBet[msg.sender] = true;
            emit NewBetSuccess(msg.sender, _opinion, _amount, currentFactor);
        } else {
            Bet storage _bet = PlayerToBet[msg.sender];
            if(_opinion == true){
                _bet.posAmount += _amount;
            } else {
               _bet.negAmount += _amount;
            }
            _bet.timestamp = _calculateTimeFactor();
            emit BetAdjustSuccess(msg.sender, _bet.posAmount, _bet.negAmount, currentFactor);
        }
        TotalAmount += _amount;
        if(_opinion == true){
            TotalSupport += _amount;
        } else {
            TotalOppose += _amount;
        }
    }
    
    function offlineBet(uint _amount, bool _opinion) public whenNotPaused onlyAdmin {
        TotalAmount += _amount;
        TotalPlayers += 1;
        if(_opinion == true){
            TotalSupport += _amount;
        } else {
            TotalOppose += _amount;
        }
    }
}