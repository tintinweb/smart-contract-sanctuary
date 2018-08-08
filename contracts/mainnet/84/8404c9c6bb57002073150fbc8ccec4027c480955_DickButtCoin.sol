pragma solidity ^0.4.10;

contract DickButtCoin {
    /* Public variables of the token */
    string public standard = &#39;Token 0.69&#39;;
    string public name = "Dick Butt Coin";
    string public symbol = "DBC";
    uint8 public decimals = 0;
    uint256 public totalSupply = 0;

    /* This creates an array with all balances */
    mapping (address => uint256) _balance;
    mapping (address => bool) _used;
     
    mapping (address => mapping (address => uint256)) public allowance;

    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /* This notifies clients about the amount burnt */
    event Burn(address indexed from, uint256 value);
    
    bool active;
    uint public deactivateTime;
    
    function updateActivation() {
        active = (now < deactivateTime);
    }
    
    function balanceOf(address addr) constant returns(uint) {
        if(active && _used[addr] == false) {
            return _balance[addr] +1;
        }
        return _balance[addr];
    }

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function MyToken() 
    {
        deactivateTime = now + 90 days;

    }
    
    modifier checkInit(address addr) {
        if(active && _used[addr] == false) {
           _used[addr] = true;
           _balance[addr] ++; 
        }
        _;
    }

    /* Send coins */
    function transfer(address _to, uint256 _value) checkInit(msg.sender) {
        if (_to == 0x0) throw;                               // Prevent transfer to 0x0 address. Use burn() instead
        if (_balance[msg.sender] < _value) throw;           // Check if the sender has enough
        if (_balance[_to] + _value < _balance[_to]) throw; // Check for overflows
        _balance[msg.sender] -= _value;                     // Subtract from the sender
        _balance[_to] += _value;                            // Add the same to the recipient
        Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
    }

    /* Allow another contract to spend some tokens in your behalf */
    function approve(address _spender, uint256 _value) checkInit(msg.sender)
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (_to == 0x0) throw;                                // Prevent transfer to 0x0 address. Use burn() instead
        if (_balance[_from] < _value) throw;                 // Check if the sender has enough
        if (_balance[_to] + _value < _balance[_to]) throw;  // Check for overflows
        if (_value > allowance[_from][msg.sender]) throw;     // Check allowance
        _balance[_from] -= _value;                           // Subtract from the sender
        _balance[_to] += _value;                             // Add the same to the recipient
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }
}