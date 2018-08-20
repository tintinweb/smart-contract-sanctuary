pragma solidity ^0.4.24;

/******************************************/
/*       Netkiller ADVANCED TOKEN         */
/******************************************/
/* Author netkiller <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="214f44554a484d4d4453614c524f0f424e4c">[email&#160;protected]</a>>   */
/* Home http://www.netkiller.cn           */
/* Version 2018-08-09  airdrop & exchange */
/******************************************/
library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Ownable {
    
    address public owner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

contract NetkillerAdvancedToken is Ownable {
    
    using SafeMath for uint256;
    
    string public name;
    string public symbol;
    uint public decimals;
    // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply;
    
    // This creates an array with all balances
    mapping (address => uint256) internal balances;
    mapping (address => mapping (address => uint256)) internal allowed;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);
    
    
    mapping (address => bool) public frozenAccount;
    event FrozenFunds(address indexed target, bool frozen);

    bool public lock = false;                   // Global lock

    /**
     * Constrctor function
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol,
        uint decimalUnits
    ) public {
        owner = msg.sender;
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol; 
        decimals = decimalUnits;
        totalSupply = initialSupply * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        balances[msg.sender] = totalSupply;                // Give the creator all initial token
    }

    modifier isLock {
        require(!lock);
        _;
    }
    
    function setLock(bool _lock) onlyOwner public returns (bool status){
        lock = _lock;
        return lock;
    }

    function balanceOf(address _address) view public returns (uint256 balance) {
        return balances[_address];
    }
    
    /* Internal transfer, only can be called by this contract */
    function _transfer(address _from, address _to, uint256 _value) isLock internal {
        require (_to != address(0));                        // Prevent transfer to 0x0 address. Use burn() instead
        require (balances[_from] >= _value);                // Check if the sender has enough
        require (balances[_to] + _value > balances[_to]);   // Check for overflows
        require(!frozenAccount[_from]);                     // Check if sender is frozen
        //require(!frozenAccount[_to]);                       // Check if recipient is frozen
        balances[_from] = balances[_from].sub(_value);      // Subtract from the sender
        balances[_to] = balances[_to].add(_value);          // Add the same to the recipient
        emit Transfer(_from, _to, _value);
    }

     function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);     // Check allowance
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    function allowance(address _owner, address _spender) view public returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = (allowed[msg.sender][_spender].add(_addedValue));
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function burn(uint256 _value) onlyOwner public returns (bool success) {
        require(balances[msg.sender] >= _value);                    // Check if the sender has enough
        balances[msg.sender] = balances[msg.sender].sub(_value);    // Subtract from the sender
        totalSupply = totalSupply.sub(_value);                      // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) onlyOwner public returns (bool success) {
        require(balances[_from] >= _value);                                      // Check if the targeted balance is enough
        require(_value <= allowed[_from][msg.sender]);                           // Check allowance
        balances[_from] = balances[_from].sub(_value);                           // Subtract from the targeted balance
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);     // Subtract from the sender&#39;s allowance
        totalSupply = totalSupply.sub(_value);                                   // Update totalSupply
        emit Burn(_from, _value);
        return true;
    }

    function mintToken(address _to, uint256 _amount) onlyOwner public {
        uint256 amount = _amount * 10 ** uint256(decimals);
        totalSupply = totalSupply.add(amount);
        balances[_to] = balances[_to].add(amount);
        emit Transfer(this, _to, amount);
    }

    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }
    
    uint256 public buyPrice;
    function setPrices(uint256 _buyPrice) onlyOwner public {
        buyPrice = _buyPrice;
    }
    
  
    uint256 public airdropTotalSupply;          // Airdrop Total Supply
    uint256 public airdropCurrentTotal;    	    // Airdrop Current Total 
    uint256 public airdropAmount;        		// Airdrop amount
    mapping(address => bool) public touched;    // Airdrop history account
    event Airdrop(address indexed _address, uint256 indexed _value);
    
    function setAirdropTotalSupply(uint256 _amount) onlyOwner public {
        airdropTotalSupply = _amount * 10 ** uint256(decimals);
    }
    
    function setAirdropAmount(uint256 _amount) onlyOwner public{
        airdropAmount = _amount * 10 ** uint256(decimals);
    }
    
    function () public payable {
        if (msg.value == 0 && !touched[msg.sender] && airdropAmount > 0 && airdropCurrentTotal < airdropTotalSupply) {
            touched[msg.sender] = true;
            airdropCurrentTotal = airdropCurrentTotal.add(airdropAmount);
            _transfer(owner, msg.sender, airdropAmount); 
            emit Airdrop(msg.sender, airdropAmount);
    
        }else{
            owner.transfer(msg.value);
            _transfer(owner, msg.sender, msg.value * buyPrice);    
        }
    }

    function batchFreezeAccount(address[] _target, bool _freeze) public returns (bool success) {
        for (uint i=0; i<_target.length; i++) {
            freezeAccount(_target[i], _freeze);
        }
        return true;
    }

    function airdrop(address[] _to, uint256 _value) public returns (bool success) {
        
        require(_value > 0 && balanceOf(msg.sender) >= _value.mul(_to.length));
        
        for (uint i=0; i<_to.length; i++) {
            _transfer(msg.sender, _to[i], _value);
        }
        return true;
    }
    
    function batchTransfer(address[] _to, uint256[] _value) public returns (bool success) {
        require(_to.length == _value.length);

        uint256 amount = 0;
        for(uint n=0;n<_value.length;n++){
            amount = amount.add(_value[n]);
        }
        
        require(amount > 0 && balanceOf(msg.sender) >= amount);
        
        for (uint i=0; i<_to.length; i++) {
            transfer(_to[i], _value[i]);
        }
        return true;
    }
}