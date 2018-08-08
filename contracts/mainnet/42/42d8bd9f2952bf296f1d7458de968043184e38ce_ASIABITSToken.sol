pragma solidity ^0.4.24;

contract ASIABITSToken {
    /* ERC20 Public variables of the token */
    string public constant version = &#39;ASB0 0.1&#39;;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    /* ERC20 This creates an array with all balances */
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;


    /* store the block number when a withdrawal has been requested*/
    mapping (address => withdrawalRequest) public withdrawalRequests;
    struct withdrawalRequest {
    uint sinceTime;
    uint256 amount;
    }

    uint256 public constant initialSupply = 500000000;

    /**
     * ERC20 events these generate a public event on the blockchain that will notify clients
    */
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    event Deposited(address indexed by, uint256 amount);

    /**
     * Initializes contract with initial supply tokens to the creator of the contract
     * In our case, there&#39;s no initial supply. Tokens will be created as ether is sent
     * to the fall-back function. Then tokens are burned when ether is withdrawn.
     */
    function ASIABITSToken(
    string tokenName,
    uint8 decimalUnits,
    string tokenSymbol
    ) {

        balanceOf[msg.sender] = initialSupply;              // Give the creator all initial tokens (0 in this case)
        totalSupply = initialSupply * 1000000000000000000;  // Update total supply (0 in this case)
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
        decimals = decimalUnits;                            // Amount of decimals for display purposes
    }

  
    modifier notPendingWithdrawal {
        if (withdrawalRequests[msg.sender].sinceTime > 0) throw;
        _;
    }


    function transfer(address _to, uint256 _value) notPendingWithdrawal {
        if (balanceOf[msg.sender] < _value) throw;           
        if (balanceOf[_to] + _value < balanceOf[_to]) throw; 
        if (withdrawalRequests[_to].sinceTime > 0) throw;   
        balanceOf[msg.sender] -= _value;                     
        balanceOf[_to] += _value;                          
        Transfer(msg.sender, _to, _value);               
    }

 
    function approve(address _spender, uint256 _value) notPendingWithdrawal
    returns (bool success) {
        if ((_value != 0) && (allowance[msg.sender][_spender] != 0)) throw;
        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;                                      // we must return a bool as part of the ERC20
    }


    /**
     * ERC-20 Approves and then calls the receiving contract
    */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) notPendingWithdrawal
    returns (bool success) {

        if (!approve(_spender, _value)) return false;

        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) {
            throw;
        }
        return true;
    }

  
    function transferFrom(address _from, address _to, uint256 _value)
    returns (bool success) {
        // on the behalf of _from
        if (withdrawalRequests[_from].sinceTime > 0) throw;   
        if (withdrawalRequests[_to].sinceTime > 0) throw;     
        if (balanceOf[_from] < _value) throw;                 
        if (balanceOf[_to] + _value < balanceOf[_to]) throw; 
        if (_value > allowance[_from][msg.sender]) throw;     
        balanceOf[_from] -= _value;                           
        balanceOf[_to] += _value;                            
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }

    /**
     * Fallback function when sending ether to the contract
     * Gas use: 65051
    */
    function () payable notPendingWithdrawal {
        uint256 amount = msg.value;         // amount that was sent
        if (amount == 0) throw;             // need to send some ETH
        balanceOf[msg.sender] += amount;    // mint new tokens
        totalSupply += amount;              // track the supply
        Transfer(0, msg.sender, amount);    // notify of the event
        Deposited(msg.sender, amount);
    }
}