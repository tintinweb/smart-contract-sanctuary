pragma solidity ^0.4.23;

/*********************************************************************************
 *********************************************************************************
 *
 * Name of the project: JeiCoin Swapper
 * Ethernity.live 
 *
 *********************************************************************************
 ********************************************************************************/

 /* ERC20 contract interface */

contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) constant returns (uint256);
    function transfer(address to, uint256 value) returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract TokenWithDates {
    function getBatch(address _address , uint _batch) public constant returns(uint _quant,uint _age);
    function getFirstBatch(address _address) public constant returns(uint _quant,uint _age);
    function resetBatches(address _address);
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool);
    mapping(address => uint) public maxIndex; 
    mapping(address => uint) public minIndex;
    uint8 public decimals;
}

// JeiCoin Swapper

contract JeiCoinSwapper {

    string public version = "v1.5";
    address public rootAddress;
    address public Owner;
    bool public locked;
    address public tokenAdd;
    address public tokenSpender;
    TokenWithDates public token;
    uint fortNight = 15;
    mapping(address => uint) public lastFortnightPayed;
    uint public initialDate;
    uint[] public yearlyInterest;

    // Modifiers

    modifier onlyOwner() {
        if ( msg.sender != rootAddress && msg.sender != Owner ) revert();
        _;
    }

    modifier onlyRoot() {
        if ( msg.sender != rootAddress ) revert();
        _;
    }

    modifier isUnlocked() {
    	require(!locked);
		_;    	
    }

    // Events

    event Batch(uint batchAmount , uint batchAge , uint totalAmount);
    event Message(string message);


    // Contract constructor
    constructor() public {  
        rootAddress = msg.sender;        
        Owner = msg.sender;

        // Addresses
        tokenAdd = address(0x9da0D98c9d051c594038eb3267fBd0FAf3Da9e48);
        tokenSpender = address(0xAd50cACa8cD726600840E745D0AE6B6E78861dBc);
        token = TokenWithDates(tokenAdd);  

        initialDate = now;

        yearlyInterest.push(70); // Yearly interest for first year: 70%
        yearlyInterest.push(50); // For second year: 50%
        yearlyInterest.push(20); // And so on: 20%
        yearlyInterest.push(10); // 10%
    }


    // Main function to pay interests
    function payInterests() isUnlocked public {
        if (fortnightsFromLast() == 0) { // Check for a fortnight passed
            emit Message("0 fortnights passed");
            return;
        }
        uint amountToPay = calculateInterest(msg.sender);
        if (amountToPay == 0) {
            emit Message("There are not 150 tokens with interests to pay");
            return;
            }
        // Success
        lastFortnightPayed[msg.sender] = now;
        require(token.transferFrom(tokenSpender,msg.sender,amountToPay));
    }

    // Getters from token

    function getBatch(address _address , uint _index) public view returns (uint _quant , uint _age) {
        return (token.getBatch(_address,_index));
    }

    function getFirstBatch(address _address) public view returns (uint _quant , uint _age) {
        return (token.getFirstBatch(_address));
    }

    // Private functions

    // Calculates total interest to pay, by checking all batches. Called by main function
    function calculateInterest(address _address) private returns (uint _amount) {
        uint totalAmount = 0; // Total amount to pay
        uint tokenCounted; // Valid tokens counted
        uint intBatch; // interest for each batch in percentage
        uint batchInterest; // Interests for each batch in absolute value
        uint batchAmount;
        uint batchDate;
        for (uint i = token.minIndex(_address); i < token.maxIndex(_address); i++) {
            ( batchAmount , batchDate) = token.getBatch(_address,i); // Get batch data
            intBatch = interest(batchDate); // Calculate interest of this batch
            batchInterest = batchAmount * intBatch / 1 ether / 100; // Apply interest to the batch amount
            if (intBatch > 0) tokenCounted += batchAmount; // Count valid tokens (those with interests)
            totalAmount += batchInterest; // Count total to pay
            emit Batch(
                batchAmount,
                secToDays(softSub(now,batchDate)),
                batchInterest
                );
        }
        // Only pays if there are 150 valid tokens or more
        if ( tokenCounted >= 150 ether ) return totalAmount; else return 0;
    }

    // Sub-function to calculate interest of each batch. Called by calculateInterest for each batch found
    function interest(uint _batchDate) private view returns (uint _interest) {
        uint _age = secToDays(softSub(now,_batchDate)); // Calculate age in days
        while ( _age >= 106 ) { // If it has more than 3 months + 12 days + 3 (eligible to be paid again)
            _age = _age - 103; // Rest every cycle of 91 + 12
        }
        if (_age < 3 ) return 0;
        if (_age > 91) return 0;
        // uint _months = _age / 30; 
        uint _tokenFortnights = _age / fortNight;
        uint _fortnightsFromLast = fortnightsFromLast();
        if ( _tokenFortnights > _fortnightsFromLast ) _tokenFortnights = _fortnightsFromLast;
        uint yearsNow = secToDays(now - initialDate) / 365; // years from initial date
        if (yearsNow > 3) yearsNow = 3;
        _interest = 1 ether * yearlyInterest[yearsNow] * _tokenFortnights / 24 ; // Prorated interest to a fortnight, per each fortnight of token
    }

    function secToDays(uint _time) private pure returns(uint _days) {
        return _time / 60 / 60 / 24; // Days
        // return (_time / 60); // Minutes
    }

    function fortnightsFromLast() public view returns(uint _fortnights) {
        // Fortnights from launching
        _fortnights = secToDays(softSub(now,initialDate)) / fortNight;
        // Fortnights since last payment (now from launching - last payment from launching)
        _fortnights = softSub(_fortnights, secToDays(softSub(lastFortnightPayed[msg.sender],initialDate)) / fortNight);
    }

    // Safe math
    function safeAdd(uint x, uint y) private pure returns (uint z) {
        require((z = x + y) >= x);
    }
    // Returns 0 if operation overflows
    function softSub(uint x, uint y) private pure returns (uint z) {
        z = x - y;
        if (z > x ) z = 0;
    }

    // Admin functions

    function lock() onlyOwner public {
        locked = true;
    }

    function unLock() onlyOwner public {
        locked = false;
    }

    function changeOwner(address _owner) onlyOwner public {
        Owner = _owner;
    }

    function changeRoot(address _root) onlyRoot public {
        rootAddress = _root;
    }

    // To send ERC20 tokens sent accidentally
    function sendToken(address _token,address _to , uint _value) onlyOwner returns(bool) {
        ERC20Basic Token = ERC20Basic(_token);
        require(Token.transfer(_to, _value));
        return true;
    }
}