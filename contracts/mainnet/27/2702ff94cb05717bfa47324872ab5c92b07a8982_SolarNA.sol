pragma solidity ^0.4.0;


/// @title Abstract token contract - Functions to be implemented by token contracts.
contract Token {
    function transfer(address to, uint256 value) public returns (bool success);
    function transferFrom(address from, address to, uint256 value) public returns (bool success);
    function approve(address spender, uint256 value) public returns (bool success);

    // This is not an abstract function, because solc won&#39;t recognize generated getter functions for public variables as functions.
    function totalSupply() public constant returns (uint256 supply);
    function balanceOf(address owner) public constant returns (uint256 balance);
    function allowance(address owner, address spender) public constant returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


/// @title Standard token contract - Standard token interface implementation.
contract StandardToken is Token {

    /*
     *  Data structures
     */
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public maxSupply;

    /*
     *  Public functions
     */
    /// @dev Transfers sender&#39;s tokens to a given address. Returns success.
    /// @param _to Address of token receiver.
    /// @param _value Number of tokens to transfer.
    /// @return Returns success of function call.
    function transfer(address _to, uint256 _value)
        public
        returns (bool)
    {
        if (balances[msg.sender] < _value) {
            // Balance too low
            revert();
        }
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /// @dev Allows allowed third party to transfer tokens from one address to another. Returns success.
    /// @param _from Address from where tokens are withdrawn.
    /// @param _to Address to where tokens are sent.
    /// @param _value Number of tokens to transfer.
    /// @return Returns success of function call.
    function transferFrom(address _from, address _to, uint256 _value)
        public
        returns (bool)
    {
        if (balances[_from] < _value || allowed[_from][msg.sender] < _value) {
            // Balance or allowance too low
            revert();
        }
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    /// @dev Sets approved amount of tokens for spender. Returns success.
    /// @param _spender Address of allowed account.
    /// @param _value Number of approved tokens.
    /// @return Returns success of function call.
    function approve(address _spender, uint256 _value)
        public
        returns (bool)
    {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /*
     * Read functions
     */
    /// @dev Returns number of allowed tokens for given address.
    /// @param _owner Address of token owner.
    /// @param _spender Address of token spender.
    /// @return Returns remaining allowance for spender.
    function allowance(address _owner, address _spender)
        constant
        public
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }

    /// @dev Returns number of tokens owned by given address.
    /// @param _owner Address of token owner.
    /// @return Returns balance of owner.
    function balanceOf(address _owner)
        constant
        public
        returns (uint256)
    {
        return balances[_owner];
    }
}


// author: SuXeN
contract SolarNA is StandardToken {

    /*
     *  Token meta data
     */
    string constant public name = "SolarNA Token";
    string constant public symbol = "SOLA";
    uint8 constant public decimals = 3;
    address public owner;
    uint remaining;
    uint divPrice = 10 ** 12;

    /*
     *  Public functions
     */
    /// @dev Contract constructor function gives tokens to presale_addresses and leave 100k tokens for sale.
    /// @param presale_addresses Array of addresses receiving preassigned tokens.
    /// @param tokens Array of preassigned token amounts.
    /// NB: Max 4 presale_addresses
    function SolarNA(address[] presale_addresses, uint[] tokens)
        public
    {
        uint assignedTokens;
        owner = msg.sender;
        maxSupply = 500000 * 10**3;
        for (uint i=0; i<presale_addresses.length; i++) {
            if (presale_addresses[i] == 0) {
                // Address should not be null.
                revert();
            }
            balances[presale_addresses[i]] += tokens[i];
            assignedTokens += tokens[i];
            emit Transfer(0, presale_addresses[i], tokens[i]); // emit an event
        }
        /// If presale_addresses > 4 => The maxSupply will increase
        remaining = maxSupply - assignedTokens;
        assignedTokens += remaining;
        if (assignedTokens != maxSupply) {
            revert();
        }
    }

    /// Change price from 1000 SOLA = 1 ether to 500 SOLA = 1 ether 
    function changePrice(bool _conditon) public returns (uint) {
        require(msg.sender == owner);
        if (_conditon) {
            divPrice *= 2;
        }
        return divPrice;
    }

    function () public payable {
        /// Required msg.value > 0 and still remaining tokens
        uint value = msg.value / uint(divPrice);
        require(remaining >= value && value != 0);
        balances[msg.sender] += value;
        remaining -= value;
        emit Transfer(address(0), msg.sender, value);
    }
    
    /// Transfer all the funds in ETH to the owner
    function transferAll() public returns (bool) {
        require(msg.sender == owner);
        owner.transfer(address(this).balance);
        return true;
    }

    /// Return MaxSupply    
    function totalSupply()  public constant returns (uint256 supply) {
        return maxSupply;
    }
    
    /// Return remaining tokens
    function remainingTokens() public view returns (uint256) {
        return remaining;
    } 

}