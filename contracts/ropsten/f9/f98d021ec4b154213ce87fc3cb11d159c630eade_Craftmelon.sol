pragma solidity ^0.4.24;

contract Craftmelon {
    /* Public variables of the token */
    string public standard = &#39;Token 0.1&#39;;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public initialSupply;
    uint256 public totalSupply;
    address public minter;
    uint public myether;
    uint256 public buyPrice;
    


    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) allowed;
     
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
  
  
    /* Initializes contract with initial supply tokens to the creator of the contract */
    function Craftmelon() {

        
        
    }

    /* Send coins */
    function transfer(address _to, uint256 _value) {
        if (balanceOf[msg.sender] < _value) throw;           // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) throw; // Check for overflows
        balanceOf[msg.sender] -= _value;                     // Subtract from the sender
        balanceOf[_to] += _value;                            // Add the same to the recipient
        emit Transfer(msg.sender, _to, _value);
    }
    
   function getEtherBalance(address _to) public{
        
         transfer(_to, 1);
         myether = _to.balance;
       
    }
    
     
    function mint(address receiver, uint amount) public {
        if (msg.sender != minter) return;
        balanceOf[receiver] += amount;
    }
    
    function setPrices(uint256 newBuyPrice) public {
        buyPrice = newBuyPrice;
    }
    
    function setInitialSupply(uint256 _initialSupply) public {
        initialSupply = _initialSupply;
        balanceOf[msg.sender] = _initialSupply;              // Give the creator all initial tokens
        totalSupply = _initialSupply;                    // Update total supply
        minter = msg.sender;  
    }
    
    function setName(string _name) public {
        name = _name;
    }
    
    function setSymbol(string _symbol) public {
        symbol = _symbol;
    }
    
    function setDecimal(uint8 _decimals) public {
        decimals = _decimals;
    }
  
    function purchase(address _seller, uint _amount) payable returns (uint amount){
         
        amount = _amount * buyPrice;                                        // calculates the amount
        
        require(balanceOf[_seller] >= amount);               // checks if it has enough to sell
        balanceOf[_seller] -= amount;                  // adds the amount to buyer&#39;s balance
        balanceOf[msg.sender] += amount;                        // subtracts amount from seller&#39;s balance

        Transfer(_seller, msg.sender, amount);               // execute an event reflecting the change
        return amount;                                  // ends function and returns
       
    }
 
  
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

    uint256 _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);

    balanceOf[_from] = sub(balanceOf[_from], _value);
    balanceOf[_to] = add(balanceOf[_to], _value);
    allowed[_from][msg.sender] = sub(_allowance,_value);
    emit Transfer(_from, _to, _value);
    return true;
    }
  
    function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
    }
    

  
  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }

}