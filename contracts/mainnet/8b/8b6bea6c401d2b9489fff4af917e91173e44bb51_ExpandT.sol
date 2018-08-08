/**
 * ERC-20 Standard Token Smart Contract Interface.
 */

pragma solidity ^0.4.11;

/**
 * ERC-20 standard token interface, as defined
 * <a href="http://github.com/ethereum/EIPs/issues/20">here</a>.
 */
contract ERC20Interface {
  /**
   * Get total number of tokens in circulation.
   */
  uint256 public totalSupply;

  /**
   * @dev Get number of tokens currently belonging to given owner.
   *
   * @param _owner address to get number of tokens currently belonging to the
   *         owner of
   * @return number of tokens currently belonging to the owner of given address
   */
  function balanceOf (address _owner) constant returns (uint256 balance);

  /**
   * @dev Transfer given number of tokens from message sender to given recipient.
   *
   * @param _to address to transfer tokens to the owner of
   * @param _value number of tokens to transfer to the owner of given address
   * @return true if tokens were transferred successfully, false otherwise
   */
  function transfer (address _to, uint256 _value) returns (bool success);

  /**
   * @dev Transfer given number of tokens from given owner to given recipient.
   *
   * @param _from address to transfer tokens from the owner of
   * @param _to address to transfer tokens to the owner of
   * @param _value number of tokens to transfer from given owner to given
   *         recipient
   * @return true if tokens were transferred successfully, false otherwise
   */
  function transferFrom (address _from, address _to, uint256 _value)
  returns (bool success);

  /**
   * @dev Allow given spender to transfer given number of tokens from message sender.
   *
   * @param _spender address to allow the owner of to transfer tokens from
   *         message sender
   * @param _value number of tokens to allow to transfer
   * @return true if token transfer was successfully approved, false otherwise
   */
  function approve (address _spender, uint256 _value) returns (bool success);

  /**
   * @dev Tell how many tokens given spender is currently allowed to transfer from
   * given owner.
   *
   * @param _owner address to get number of tokens allowed to be transferred
   *        from the owner of
   * @param _spender address to get number of tokens allowed to be transferred
   *        by the owner of
   * @return number of tokens given spender is currently allowed to transfer
   *         from given owner
   */
  function allowance (address _owner, address _spender) constant
  returns (uint256 remaining);

  /**
   * @dev Logged when tokens were transferred from one owner to another.
   *
   * @param _from address of the owner, tokens were transferred from
   * @param _to address of the owner, tokens were transferred to
   * @param _value number of tokens transferred
   */
  event Transfer (address indexed _from, address indexed _to, uint256 _value);

  /**
   * @dev Logged when owner approved his tokens to be transferred by some spender.
   *
   * @param _owner owner who approved his tokens to be transferred
   * @param _spender spender who were allowed to transfer the tokens belonging
   *        to the owner
   * @param _value number of tokens belonging to the owner, approved to be
   *        transferred by the spender
   */
  event Approval (
    address indexed _owner, address indexed _spender, uint256 _value);
}

contract Owned {
    address public owner;
    address public newOwner;

    function Owned() {
        owner = msg.sender;
    }

    modifier ownerOnly {
        assert(msg.sender == owner);
        _;
    }

    /**
     * @dev Transfers ownership. New owner has to accept in order ownership change to take effect
     */
    function transferOwnership(address _newOwner) public ownerOnly {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

    /**
     * @dev Accepts transferred ownership
     */
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = 0x0;
    }

    event OwnerUpdate(address _prevOwner, address _newOwner);
}

/**
 * Safe Math Smart Contract.  
 */
 
pragma solidity ^0.4.11;

/**
 * Provides methods to safely add, subtract and multiply uint256 numbers.
 */
contract SafeMath {
 
  /**
   * @dev Add two uint256 values, throw in case of overflow.
   *
   * @param a first value to add
   * @param b second value to add
   * @return x + y
   */
    function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

  /**
   * @dev Subtract one uint256 value from another, throw in case of underflow.
   *
   * @param a value to subtract from
   * @param b value to subtract
   * @return a - b
   */
    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;
    }


  /**
   * @dev Multiply two uint256 values, throw in case of overflow.
   *
   * @param a first value to multiply
   * @param b second value to multiply
   * @return c = a * b
   */
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

 /**
   * @dev Divide two uint256 values, throw in case of overflow.
   *
   * @param a first value to divide
   * @param b second value to divide
   * @return c = a / b
   */
        function div(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a / b;
        return c;
    }
}

/*
 * TokenRecepient
 */

pragma solidity ^0.4.11;

contract TokenRecipient {
    /**
     * receive approval
     */
    function receiveApproval(address _from, uint256 _value, address _to, bytes _extraData);
}

/**
 * Standard Token Smart Contract that implements ERC-20 token interface
 */
contract ExpandT is ERC20Interface, SafeMath, Owned {

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    string public constant name = "ExpandT";
    string public constant symbol = "EXT";
    uint8 public constant decimals = 8;
    string public version = &#39;0.0.2&#39;;

    bool public transfersFrozen = false;

    /**
     * Protection against short address attack
     */
    modifier onlyPayloadSize(uint numwords) {
        assert(msg.data.length == numwords * 32 + 4);
        _;
    }

    /**
     * Check if transfers are on hold - frozen
     */
    modifier whenNotFrozen(){
        if (transfersFrozen) revert();
        _;
    }


    function ExpandT() ownerOnly {
        totalSupply = 1500000000000000;
        balances[owner] = totalSupply;
    }


    /**
     * Freeze token transfers.
     */
    function freezeTransfers () ownerOnly {
        if (!transfersFrozen) {
            transfersFrozen = true;
            Freeze (msg.sender);
        }
    }


    /**
     * Unfreeze token transfers.
     */
    function unfreezeTransfers () ownerOnly {
        if (transfersFrozen) {
            transfersFrozen = false;
            Unfreeze (msg.sender);
        }
    }


    /**
     * Transfer sender&#39;s tokens to a given address
     */
    function transfer(address _to, uint256 _value) whenNotFrozen onlyPayloadSize(2) returns (bool success) {
        require(_to != 0x0);

        balances[msg.sender] = sub(balances[msg.sender], _value);
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }


    /**
     * Transfer _from&#39;s tokens to _to&#39;s address
     */
    function transferFrom(address _from, address _to, uint256 _value) whenNotFrozen onlyPayloadSize(3) returns (bool success) {
        require(_to != 0x0);
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value);

        balances[_from] = sub(balances[_from], _value);
        balances[_to] += _value;
        allowed[_from][msg.sender] = sub(allowed[_from][msg.sender], _value);
        Transfer(_from, _to, _value);
        return true;
    }


    /**
     * Returns number of tokens owned by given address.
     */
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }


    /**
     * Sets approved amount of tokens for spender.
     */
    function approve(address _spender, uint256 _value) returns (bool success) {
        require(_value == 0 || allowed[msg.sender][_spender] == 0);
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }


    /**
     * Approve and then communicate the approved contract in a single transaction
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        TokenRecipient spender = TokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }


    /**
     * Returns number of allowed tokens for given address.
     */
    function allowance(address _owner, address _spender) onlyPayloadSize(2) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }


    /**
     * Peterson&#39;s Law Protection
     * Claim tokens
     */
    function claimTokens(address _token) ownerOnly {
        if (_token == 0x0) {
            owner.transfer(this.balance);
            return;
        }

        ExpandT token = ExpandT(_token);
        uint balance = token.balanceOf(this);
        token.transfer(owner, balance);

        Transfer(_token, owner, balance);
    }


    event Freeze (address indexed owner);
    event Unfreeze (address indexed owner);
}