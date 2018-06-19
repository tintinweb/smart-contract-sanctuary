pragma solidity ^0.4.8;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract MyToken {
    /* Public variables of the token */
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    uint256 public multiple;
    address public owner;
    
    struct locked_balances_info{
        uint amount;
        uint time;
    }
    mapping(address => locked_balances_info[]) public lockedBalanceOf;

    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /* This generates a public event on the blockchain that will notify clients */
    event TransferAndLock(address indexed from, address indexed to, uint256 value, uint256 time);

    /* This notifies clients about the amount burnt */
    event Burn(address indexed from, uint256 value);


    /* Initializes contract with initial supply tokens to the creator of the contract */
    function MyToken(
        uint256 initialSupply,
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol
        ) public {
        balanceOf[msg.sender] = initialSupply;              // Give the creator all initial tokens
        totalSupply = initialSupply;                        // Update total supply
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
        decimals = decimalUnits; 
        multiple = 1;  
        owner = msg.sender;                         // Amount of decimals for display purposes
    }
    
    function setMultiple(uint _val) public {
        require(msg.sender == owner);
        multiple = _val;
       
    }

    /* Internal transfer, only can be called by this contract */
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);                               // Prevent transfer to 0x0 address. Use burn() instead
        
    if(balanceOf[_from] < _value) {
            uint length = lockedBalanceOf[_from].length;
            uint index = 0;
            if(length > 0){
                    for (uint i = 0; i < length; i++) {
                        if(now > lockedBalanceOf[_from][i].time){
                                balanceOf[_from] += lockedBalanceOf[_from][i].amount;
                                index++;
                        }else{
                                break;
                        }
                    }
        
                    if(index == length){
                        delete lockedBalanceOf[_from];
                    } else {
                        for (uint j = 0; j < length - index; j++) {
                                lockedBalanceOf[_from][j] = lockedBalanceOf[_from][j + index];
                        }
                        lockedBalanceOf[_from].length = length - index;
                        index = lockedBalanceOf[_from].length;
                    }
            }
    }

        if(multiple !=0 && _from != owner){
            uint remainder = balanceOf[_from]%multiple;
            if(!(_value%multiple ==0 || _value%multiple==remainder)){
            require(false);
            }
        
        }
        
        
            

        require (balanceOf[_from] >= _value);                // Check if the sender has enough
        require (balanceOf[_to] + _value > balanceOf[_to]); // Check for overflows
        balanceOf[_from] -= _value;                         // Subtract from the sender
        balanceOf[_to] += _value;                            // Add the same to the recipient
        Transfer(_from, _to, _value);
    }
    
    function balanceOf(address _owner) constant public returns (uint256 balance){
        balance = balanceOf[_owner];
        uint length = lockedBalanceOf[_owner].length;
        for (uint i = 0; i < length; i++) {
            balance += lockedBalanceOf[_owner][i].amount;
        }
    }
    
     function balanceOfOld(address _owner) constant public returns (uint256 balance) {
        balance = balanceOf[_owner];
    }
    
    function _transferAndLock(address _from, address _to, uint _value, uint _time) internal {
        
        if(multiple !=0 && _from != owner){
            uint remainder = balanceOf[_from]%multiple;
            if(!(_value%multiple ==0 || _value%multiple==remainder)){
            require(false);
            }
        
        }
        
        require (_to != 0x0);                               // Prevent transfer to 0x0 address. Use burn() instead
        require (balanceOf[_from] >= _value);                // Check if the sender has enough
        require (balanceOf[_to] + _value > balanceOf[_to]); // Check for overflows
        balanceOf[_from] -= _value;                         // Subtract from the sender
        //balanceOf[_to] += _value;                            // Add the same to the recipient
       
        lockedBalanceOf[_to].push(locked_balances_info(_value, _time));
        TransferAndLock(_from, _to, _value, _time);
    }

    /// @notice Send `_value` tokens to `_to` from your account
    /// @param _to The address of the recipient
    /// @param _value the amount to send
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }
    
    function transferAndLock(address _to, uint256 _value, uint _time) public {
        _transferAndLock(msg.sender, _to, _value, _time + now);
    }

    /// @notice Send `_value` tokens to `_to` in behalf of `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value the amount to send
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require (_value < allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /// @notice Allows `_spender` to spend no more than `_value` tokens in your behalf
    /// @param _spender The address authorized to spend
    /// @param _value the max amount they can spend
    function approve(address _spender, uint256 _value)
        public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /// @notice Allows `_spender` to spend no more than `_value` tokens in your behalf, and then ping the contract about it
    /// @param _spender The address authorized to spend
    /// @param _value the max amount they can spend
    /// @param _extraData some extra information to send to the approved contract
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }        

}