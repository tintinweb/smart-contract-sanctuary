pragma solidity ^0.4.18;

    contract owned {
        address public owner;

        constructor() owned() internal {
            owner = msg.sender;
        }

        modifier onlyOwner {
            require(msg.sender == owner);
            _;
        }

        function transferOwnership(address newOwner) onlyOwner internal {
            owner = newOwner;
        }
        
    }
    
interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }     




    contract apecashProject is owned {
         string public name;
string public symbol;
uint8 public decimals;

uint public _totalSupply = 250000000000000000000000000;
        
        /* This creates an array with all balances */
        mapping (address => uint256) public balanceOf;
        uint256 public totalSupply;
        
            event Transfer(address indexed from, address indexed to, uint256 value);
        // This generates a public event on the blockchain that will notify clients
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);
        
        /* Initializes contract with initial supply tokens to the creator of the contract */
        
    constructor() public {
        totalSupply = 250000000000000000000000000;  // Update total supply with the decimal amount
        balanceOf[msg.sender] = 250000000000000000000000000;                // Give the creator all initial tokens
        name = "ApeCash";                                   // Set the name for display purposes
        symbol = "APE";                               // Set the symbol for display purposes
        decimals = 18;                            // Amount of decimals for display purposes
    }
    

        /* Send coins */
        function transfer(address _to, uint256 _value) public {
        /* Check if sender has balance and for overflows */
        require(balanceOf[msg.sender] >= _value && balanceOf[_to] + _value >= balanceOf[_to]);

        /* Add and subtract new balances */
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        
                /* Notify anyone listening that this transfer took place */
        emit Transfer(msg.sender, _to, _value);
    }
    
      /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require(balanceOf[_to] + _value > balanceOf[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        // Subtract from the sender
        balanceOf[_from] -= _value;
        // Add the same to the recipient
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }
    
  
    
    }