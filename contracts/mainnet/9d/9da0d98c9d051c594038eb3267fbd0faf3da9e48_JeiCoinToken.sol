pragma solidity ^0.4.24;

/*********************************************************************************
 *********************************************************************************
 *
 * Name of the project: JeiCoin Gold Token
 * BiJust
 * Ethernity.live
*
 * v1.5
 *
 *********************************************************************************
 ********************************************************************************/

 /* ERC20 contract interface */

contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) constant returns (uint256);
    function transfer(address to, uint256 value) returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


// The Token. A TokenWithDates ERC20 token
contract JeiCoinToken {

    // Token public variables
    string public name;
    string public symbol;
    uint8 public decimals; 
    string public version = &#39;v1.5&#39;;
    uint256 public totalSupply;
    uint public price;
    bool public locked;
    uint multiplier;

    address public rootAddress;
    address public Owner;

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowed;
    mapping(address => bool) public freezed;

    mapping(address => uint) public maxIndex; // To store index of last batch: points to the next one
    mapping(address => uint) public minIndex; // To store index of first batch
    mapping(address => mapping(uint => Batch)) public batches; // To store batches with quantities and ages

    struct Batch {
        uint quant;
        uint age;
    }

    // ERC20 events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);


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
    	if ( locked && msg.sender != rootAddress && msg.sender != Owner ) revert();
		_;    	
    }

    modifier isUnfreezed(address _to) {
    	if ( freezed[msg.sender] || freezed[_to] ) revert();
    	_;
    }

    // Safe math
    function safeSub(uint x, uint y) pure internal returns (uint z) {
        require((z = x - y) <= x);
    }


    // Token constructor
    constructor(address _root) {        
        locked = false;
        name = &#39;JeiCoin Gold&#39;; 
        symbol = &#39;JEIG&#39;; 
        decimals = 18; 
        multiplier = 10 ** uint(decimals);
        totalSupply = 63000000 * multiplier; // 63,000,000 tokens
        if (_root != 0x0) rootAddress = _root; else rootAddress = msg.sender;  
        Owner = msg.sender;

        // Asign total supply to the balance and to the first batch
        balances[rootAddress] = totalSupply; 
        batches[rootAddress][0].quant = totalSupply;
        batches[rootAddress][0].age = now;
        maxIndex[rootAddress] = 1;
    }


    // Only root function

    function changeRoot(address _newRootAddress) onlyRoot returns(bool){
        rootAddress = _newRootAddress;
        return true;
    }

    // Only owner functions

    // To send ERC20 tokens sent accidentally
    function sendToken(address _token,address _to , uint _value) onlyOwner returns(bool) {
        ERC20Basic Token = ERC20Basic(_token);
        require(Token.transfer(_to, _value));
        return true;
    }

    function changeOwner(address _newOwner) onlyOwner returns(bool) {
        Owner = _newOwner;
        return true;
    }
       
    function unlock() onlyOwner returns(bool) {
        locked = false;
        return true;
    }

    function lock() onlyOwner returns(bool) {
        locked = true;
        return true;
    }

    function freeze(address _address) onlyOwner returns(bool) {
        freezed[_address] = true;
        return true;
    }

    function unfreeze(address _address) onlyOwner returns(bool) {
        freezed[_address] = false;
        return true;
    }

    function burn(uint256 _value) onlyOwner returns(bool) {
        require (balances[msg.sender] >= _value);
        balances[msg.sender] = balances[msg.sender] - _value;
        totalSupply = safeSub( totalSupply,  _value );
        emit Transfer(msg.sender, 0x0,_value);
        return true;
    }

    // Public token functions
    // Standard transfer function
    function transfer(address _to, uint _value) isUnlocked public returns (bool success) {
        require(msg.sender != _to);
        if (balances[msg.sender] < _value) return false;
        if (freezed[msg.sender] || freezed[_to]) return false; // Check if destination address is freezed
        balances[msg.sender] = balances[msg.sender] - _value;
        balances[_to] = balances[_to] + _value;

        updateBatches(msg.sender, _to, _value);

        emit Transfer(msg.sender,_to,_value);
        return true;
        }


    function transferFrom(address _from, address _to, uint256 _value) isUnlocked public returns(bool) {
        require(_from != _to);
        if ( freezed[_from] || freezed[_to] ) return false; // Check if destination address is freezed
        if ( balances[_from] < _value ) return false; // Check if the sender has enough
    	if ( _value > allowed[_from][msg.sender] ) return false; // Check allowance

        balances[_from] = balances[_from] - _value; // Subtract from the sender
        balances[_to] = balances[_to] + _value; // Add the same to the recipient

        allowed[_from][msg.sender] = allowed[_from][msg.sender] - _value;

        updateBatches(_from, _to, _value);

        emit Transfer(_from,_to,_value);
        return true;
    }

    function approve(address _spender, uint _value) public returns(bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }


    // Public getters

    function isLocked() public view returns(bool) {
        return locked;
    }

    function balanceOf(address _owner) public view returns(uint256 balance) {
        return balances[_owner];
    }

    function allowance(address _owner, address _spender) public view returns(uint256) {
        return allowed[_owner][_spender];
    }


    // To read batches from external tokens

    function getBatch(address _address , uint _batch) public view returns(uint _quant,uint _age) {
        return (batches[_address][_batch].quant , batches[_address][_batch].age);
    }

    function getFirstBatch(address _address) public view returns(uint _quant,uint _age) {
        return (batches[_address][minIndex[_address]].quant , batches[_address][minIndex[_address]].age);
    }

    // Private function to register quantity and age of batches from sender and receiver (TokenWithDates)
    function updateBatches(address _from,address _to,uint _value) private {
        // Discounting tokens from batches AT SOURCE
        uint count = _value;
        uint i = minIndex[_from];
         while(count > 0) { // To iterate over the mapping. // && i < maxIndex is just a protection from infinite loop, that should not happen anyways
            uint _quant = batches[_from][i].quant;
            if ( count >= _quant ) { // If there is more to send than the batch
                // Empty batch and continue counting
                count -= _quant; // First rest the batch to the count
                batches[_from][i].quant = 0; // Then empty the batch
                minIndex[_from] = i + 1;
                } else { // If this batch is enough to send everything
                    // Empty counter and adjust the batch
                    batches[_from][i].quant -= count; // First adjust the batch, just in case anything rest
                    count = 0; // Then empty the counter and thus stop loop
                    }
            i++;
        } // Closes while loop

        // Counting tokens for batches AT TARGET
        // Prepare struct
        Batch memory thisBatch;
        thisBatch.quant = _value;
        thisBatch.age = now;
        // Assign batch and move the index
        batches[_to][maxIndex[_to]] = thisBatch;
        maxIndex[_to]++;
    }

}