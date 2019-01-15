pragma solidity ^0.4.18;

contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract LoveAirCoffee is ERC20 {
    
    address owner = msg.sender;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowed;
    
    // Public variables of the token
    string public name="Love Air Coffee";
    string public symbol="LAC";
    uint8 public decimals = 18;

    uint256 public totalSupply; 
    
    uint256 public tokensPerOneEther;
    
    bool public transferTokenNow=true;
    
    bool public frozenCoin=true;
    
    uint256 public minEther;
    uint256 public maxEther;

    enum State { Disabled, Enabled }
    
    State public state = State.Disabled;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    // This generates a public event on the blockchain that will notify clients
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
    
    function LoveAirCoffee(uint256 initialSupply) public{
        totalSupply = initialSupply * 10 ** uint256(decimals);
        balanceOf[msg.sender]=totalSupply;
        emit Transfer(address(0),owner,totalSupply);
    }
    
    function startBuyingTokens(bool _transferTokenNow,uint256 _minEther,uint256 _maxEther) public onlyOwner {
        require(state == State.Disabled);
        transferTokenNow = _transferTokenNow;
        minEther = _minEther * 10 ** uint256(decimals);
        maxEther = _maxEther * 10 ** uint256(decimals);
        state = State.Enabled;
    }
    
    function stopBuyingTokens() public onlyOwner {
        require(state == State.Enabled);
        state = State.Disabled;
    }
    
    function setFrozenCoin(bool _value) public onlyOwner {
        frozenCoin = _value;
    }

    // NewBuyPrice Price users can buy from the contract
    function setPrices(uint256 newBuyPrice) onlyOwner public {
        tokensPerOneEther = newBuyPrice;
    }

    // Buy tokens
    function () payable external {
        require(state == State.Enabled);
        require(msg.value >= minEther && msg.value <= maxEther);
        require(state == State.Enabled);
        if(transferTokenNow){
            uint256 tokens = (tokensPerOneEther * msg.value);
           _transfer(owner, msg.sender, tokens);   // makes the transferss 
        }

        owner.transfer(msg.value);
    }
    
    function allowance(address _owner, address _spender) constant public returns (uint256) {
        return allowed[_owner][_spender];
    }
    
    function balanceOf(address _owner) constant public returns (uint256) {
        return balanceOf[_owner];
    }

    /* Internal transfer, only can be called by this contract */
    function _transfer(address _from, address _to, uint256 _value) internal {
        require (_to != address(0x0));                          // Prevent transfer to 0x0 address. Use burn() instead
        require (balanceOf[_from] >= _value);                   // Check if the sender has enough
        require (balanceOf[_to] + _value >= balanceOf[_to]);    // Check for overflows
        balanceOf[_from] -= _value;                             // Subtract from the sender
        balanceOf[_to] += _value;                               // Add the same to the recipient
        emit Transfer(_from, _to, _value);
    }

    // Transfer tokens
    function transfer(address _to, uint256 _value) public returns (bool success) {
         require(!frozenCoin);
        _transfer(msg.sender, _to, _value);
        return true;
    }

    // Transfer tokens from other address
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(!frozenCoin);
        require(_value <= allowed[_from][msg.sender]);     // Check allowance
        allowed[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    //Allows `_spender` to spend no more than `_value` tokens in your behalf
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    //Destroy tokens
    function burn(uint256 _value) public returns (bool success) {
        require(!frozenCoin);
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }

    //Destroy tokens from other account
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(!frozenCoin);
        require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowed[_from][msg.sender]);    // Check allowance
        balanceOf[_from] -= _value;                         // Subtract from the targeted balance
        allowed[_from][msg.sender] -= _value;             // Subtract from the sender&#39;s allowance
        totalSupply -= _value;                              // Update totalSupply
        emit Burn(_from, _value);
        return true;
    }
}