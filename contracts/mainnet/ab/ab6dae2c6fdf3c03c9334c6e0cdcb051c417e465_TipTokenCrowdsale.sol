pragma solidity ^0.4.23;


/**
* @title SafeMath
* @dev Math operations with safety checks that throw on error
*/
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return a / b;
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
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    constructor() public {
        owner = msg.sender;
    }

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract Administratable is Ownable {
    mapping (address => bool) admins;

    event AdminAdded(address indexed _admin);

    event AdminRemoved(address indexed _admin);

    modifier onlyAdmin() {
        require(admins[msg.sender]);
        _;
    }

    function addAdmin(address _addressToAdd) external onlyOwner {
        require(_addressToAdd != address(0));
        admins[_addressToAdd] = true;

        emit AdminAdded(_addressToAdd);
    }

    function removeAdmin(address _addressToRemove) external onlyOwner {
        require(_addressToRemove != address(0));
        admins[_addressToRemove] = false;

        emit AdminRemoved(_addressToRemove);
    }
}
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

contract ERC20 {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}
contract ERC865 is ERC20 {

    function transferPreSigned(
        bytes _signature,
        address _to,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce
    )
        public
        returns (bool);

    function approvePreSigned(
        bytes _signature,
        address _spender,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce
    )
        public
        returns (bool);

    function increaseApprovalPreSigned(
        bytes _signature,
        address _spender,
        uint256 _addedValue,
        uint256 _fee,
        uint256 _nonce
    )
        public
        returns (bool);

    function decreaseApprovalPreSigned(
        bytes _signature,
        address _spender,
        uint256 _subtractedValue,
        uint256 _fee,
        uint256 _nonce
    )
        public
        returns (bool);

    function transferFromPreSigned(
        bytes _signature,
        address _from,
        address _to,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce
    )
        public
        returns (bool);

    function revokeSignature(bytes _signature)
    public
    returns (bool);

}

contract StandardToken is ERC20  {

  using SafeMath for uint256;

  mapping (address => mapping (address => uint256)) internal allowed;

  mapping(address => uint256) public balances;

  uint256 _totalSupply;

  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
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

}

contract ERC865Token is ERC865, StandardToken {

    /* Nonces of transfers performed */
    mapping(bytes => bool) nonces;

    event TransferPreSigned(address indexed from, address indexed to, address indexed delegate, uint256 amount, uint256 fee);
    event ApprovalPreSigned(address indexed from, address indexed to, address indexed delegate, uint256 amount, uint256 fee);
    event SignatureRevoked(bytes signature, address indexed from);

    /**
     * @notice Submit a presigned transfer
     * @param _signature bytes The signature, issued by the owner.
     * @param _to address The address which you want to transfer to.
     * @param _value uint256 The amount of tokens to be transferred.
     * @param _fee uint256 The amount of tokens paid to msg.sender, by the owner.
     * @param _nonce uint256 Presigned transaction number.
     */
    function transferPreSigned(
        bytes _signature,
        address _to,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce
    )
        public
        returns (bool)
    {
        require(_to != address(0));
        require(!nonces[_signature]);

        bytes32 hashedTx = transferPreSignedHashing(address(this), _to, _value, _fee, _nonce);

        address from = recover(hashedTx, _signature);
        require(from != address(0));

        nonces[_signature] = true;

        balances[from] = balances[from].sub(_value).sub(_fee);
        balances[_to] = balances[_to].add(_value);
        balances[msg.sender] = balances[msg.sender].add(_fee);

        emit Transfer(from, _to, _value);
        emit Transfer(from, msg.sender, _fee);
        emit TransferPreSigned(from, _to, msg.sender, _value, _fee);
        return true;
    }

    /**
     * @notice Submit a presigned approval
     * @param _signature bytes The signature, issued by the owner.
     * @param _spender address The address which will spend the funds.
     * @param _value uint256 The amount of tokens to allow.
     * @param _fee uint256 The amount of tokens paid to msg.sender, by the owner.
     * @param _nonce uint256 Presigned transaction number.
     */
    function approvePreSigned(
        bytes _signature,
        address _spender,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce
    )
        public
        returns (bool)
    {
        require(_spender != address(0));
        require(!nonces[_signature]);

        bytes32 hashedTx = approvePreSignedHashing(address(this), _spender, _value, _fee, _nonce);
        address from = recover(hashedTx, _signature);
        require(from != address(0));

        nonces[_signature] = true;

        allowed[from][_spender] = _value;
        balances[from] = balances[from].sub(_fee);
        balances[msg.sender] = balances[msg.sender].add(_fee);

        emit Approval(from, _spender, _value);
        emit Transfer(from, msg.sender, _fee);
        emit ApprovalPreSigned(from, _spender, msg.sender, _value, _fee);
        return true;
    }

    /**
     * @notice Increase the amount of tokens that an owner allowed to a spender.
     * @param _signature bytes The signature, issued by the owner.
     * @param _spender address The address which will spend the funds.
     * @param _addedValue uint256 The amount of tokens to increase the allowance by.
     * @param _fee uint256 The amount of tokens paid to msg.sender, by the owner.
     * @param _nonce uint256 Presigned transaction number.
     */
    function increaseApprovalPreSigned(
        bytes _signature,
        address _spender,
        uint256 _addedValue,
        uint256 _fee,
        uint256 _nonce
    )
        public
        returns (bool)
    {
        require(_spender != address(0));
        require(!nonces[_signature]);

        bytes32 hashedTx = increaseApprovalPreSignedHashing(address(this), _spender, _addedValue, _fee, _nonce);
        address from = recover(hashedTx, _signature);
        require(from != address(0));

        nonces[_signature] = true;

        allowed[from][_spender] = allowed[from][_spender].add(_addedValue);
        balances[from] = balances[from].sub(_fee);
        balances[msg.sender] = balances[msg.sender].add(_fee);

        emit Approval(from, _spender, allowed[from][_spender]);
        emit Transfer(from, msg.sender, _fee);
        emit ApprovalPreSigned(from, _spender, msg.sender, allowed[from][_spender], _fee);
        return true;
    }

    /**
     * @notice Decrease the amount of tokens that an owner allowed to a spender.
     * @param _signature bytes The signature, issued by the owner
     * @param _spender address The address which will spend the funds.
     * @param _subtractedValue uint256 The amount of tokens to decrease the allowance by.
     * @param _fee uint256 The amount of tokens paid to msg.sender, by the owner.
     * @param _nonce uint256 Presigned transaction number.
     */
    function decreaseApprovalPreSigned(
        bytes _signature,
        address _spender,
        uint256 _subtractedValue,
        uint256 _fee,
        uint256 _nonce
    )
        public
        returns (bool)
    {
        require(_spender != address(0));
        require(!nonces[_signature]);

        bytes32 hashedTx = decreaseApprovalPreSignedHashing(address(this), _spender, _subtractedValue, _fee, _nonce);
        address from = recover(hashedTx, _signature);
        require(from != address(0));

        nonces[_signature] = true;

        uint oldValue = allowed[from][_spender];
        if (_subtractedValue > oldValue) {
            allowed[from][_spender] = 0;
        } else {
            allowed[from][_spender] = oldValue.sub(_subtractedValue);
        }
        balances[from] = balances[from].sub(_fee);
        balances[msg.sender] = balances[msg.sender].add(_fee);

        emit Approval(from, _spender, _subtractedValue);
        emit Transfer(from, msg.sender, _fee);
        emit ApprovalPreSigned(from, _spender, msg.sender, allowed[from][_spender], _fee);
        return true;
    }

    /**
     * @notice Transfer tokens from one address to another
     * @param _signature bytes The signature, issued by the spender.
     * @param _from address The address which you want to send tokens from.
     * @param _to address The address which you want to transfer to.
     * @param _value uint256 The amount of tokens to be transferred.
     * @param _fee uint256 The amount of tokens paid to msg.sender, by the spender.
     * @param _nonce uint256 Presigned transaction number.
     */
    function transferFromPreSigned(
        bytes _signature,
        address _from,
        address _to,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce
    )
        public
        returns (bool)
    {
        require(_to != address(0));
        require(!nonces[_signature]);

        bytes32 hashedTx = transferFromPreSignedHashing(address(this), _from, _to, _value, _fee, _nonce);

        address spender = recover(hashedTx, _signature);
        require(spender != address(0));

        nonces[_signature] = true;

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][spender] = allowed[_from][spender].sub(_value);

        balances[spender] = balances[spender].sub(_fee);
        balances[msg.sender] = balances[msg.sender].add(_fee);
        nonces[_signature] = true;

        emit Transfer(_from, _to, _value);
        emit Transfer(spender, msg.sender, _fee);
        return true;
    }

    /**
     * Revote previously approved signature
     * @param  _signature bytes The signature to revoke
     * @return bool  Returns true if revocation was successful
     */
    function revokeSignature(bytes _signature) public returns (bool) {
        require(!nonces[_signature]);
        nonces[_signature] = true;

        emit SignatureRevoked(_signature, msg.sender);
        return true;
    }


    /**
     * @notice Hash (keccak256) of the payload used by transferPreSigned
     * @param _token address The address of the token.
     * @param _to address The address which you want to transfer to.
     * @param _value uint256 The amount of tokens to be transferred.
     * @param _fee uint256 The amount of tokens paid to msg.sender, by the owner.
     * @param _nonce uint256 Presigned transaction number.
     */
    function transferPreSignedHashing(
        address _token,
        address _to,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce
    )
        public
        pure
        returns (bytes32)
    {
        /* "48664c16": transferPreSignedHashing(address,address,address,uint256,uint256,uint256) */
        return keccak256(bytes4(0x48664c16), _token, _to, _value, _fee, _nonce);
    }

    /**
     * @notice Hash (keccak256) of the payload used by approvePreSigned
     * @param _token address The address of the token
     * @param _spender address The address which will spend the funds.
     * @param _value uint256 The amount of tokens to allow.
     * @param _fee uint256 The amount of tokens paid to msg.sender, by the owner.
     * @param _nonce uint256 Presigned transaction number.
     */
    function approvePreSignedHashing(
        address _token,
        address _spender,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce
    )
        public
        pure
        returns (bytes32)
    {
        /* "f7ac9c2e": approvePreSignedHashing(address,address,uint256,uint256,uint256) */
        return keccak256(bytes4(0xf7ac9c2e), _token, _spender, _value, _fee, _nonce);
    }

    /**
     * @notice Hash (keccak256) of the payload used by increaseApprovalPreSigned
     * @param _token address The address of the token
     * @param _spender address The address which will spend the funds.
     * @param _addedValue uint256 The amount of tokens to increase the allowance by.
     * @param _fee uint256 The amount of tokens paid to msg.sender, by the owner.
     * @param _nonce uint256 Presigned transaction number.
     */
    function increaseApprovalPreSignedHashing(
        address _token,
        address _spender,
        uint256 _addedValue,
        uint256 _fee,
        uint256 _nonce
    )
        public
        pure
        returns (bytes32)
    {
        /* "a45f71ff": increaseApprovalPreSignedHashing(address,address,uint256,uint256,uint256) */
        return keccak256(bytes4(0xa45f71ff), _token, _spender, _addedValue, _fee, _nonce);
    }

     /**
      * @notice Hash (keccak256) of the payload used by decreaseApprovalPreSigned
      * @param _token address The address of the token
      * @param _spender address The address which will spend the funds.
      * @param _subtractedValue uint256 The amount of tokens to decrease the allowance by.
      * @param _fee uint256 The amount of tokens paid to msg.sender, by the owner.
      * @param _nonce uint256 Presigned transaction number.
      */
    function decreaseApprovalPreSignedHashing(
        address _token,
        address _spender,
        uint256 _subtractedValue,
        uint256 _fee,
        uint256 _nonce
    )
        public
        pure
        returns (bytes32)
    {
        /* "59388d78": decreaseApprovalPreSignedHashing(address,address,uint256,uint256,uint256) */
        return keccak256(bytes4(0x59388d78), _token, _spender, _subtractedValue, _fee, _nonce);
    }

    /**
     * @notice Hash (keccak256) of the payload used by transferFromPreSigned
     * @param _token address The address of the token
     * @param _from address The address which you want to send tokens from.
     * @param _to address The address which you want to transfer to.
     * @param _value uint256 The amount of tokens to be transferred.
     * @param _fee uint256 The amount of tokens paid to msg.sender, by the spender.
     * @param _nonce uint256 Presigned transaction number.
     */
    function transferFromPreSignedHashing(
        address _token,
        address _from,
        address _to,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce
    )
        public
        pure
        returns (bytes32)
    {
        /* "b7656dc5": transferFromPreSignedHashing(address,address,address,uint256,uint256,uint256) */
        return keccak256(bytes4(0xb7656dc5), _token, _from, _to, _value, _fee, _nonce);
    }

    /**
     * @notice Recover signer address from a message by using his signature
     * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
     * @param sig bytes signature, the signature is generated using web3.eth.sign()
     */
    function recover(bytes32 hash, bytes sig) public pure returns (address) {
      bytes32 r;
      bytes32 s;
      uint8 v;

      //Check the signature length
      if (sig.length != 65) {
        return (address(0));
      }

      // Divide the signature in r, s and v variables
      assembly {
        r := mload(add(sig, 32))
        s := mload(add(sig, 64))
        v := byte(0, mload(add(sig, 96)))
      }

      // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
      if (v < 27) {
        v += 27;
      }

      // If the version is correct return the signer address
      if (v != 27 && v != 28) {
        return (address(0));
      } else {
        return ecrecover(hash, v, r, s);
      }
    }

}

contract Pausable is Ownable {
    event Paused();
    event Unpaused();

    bool public paused = false;


    /**
    * @dev Modifier to make a function callable only when the contract is not paused.
    */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
    * @dev Modifier to make a function callable only when the contract is paused.
    */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
    * @dev called by the owner to pause, triggers stopped state
    */
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Paused();
    }

    /**
    * @dev called by the owner to unpause, returns to normal state
    */
    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpaused();
    }
}

contract Crowdsale {
  using SafeMath for uint256;

  // The token being sold
  ERC20 public token;

  // Address where funds are collected
  address public wallet;

  // How many token units a buyer gets per wei
  uint256 public rate;

  // Amount of wei raised
  uint256 public weiRaised;

  // Amount of token sold in wei
  uint256 public tokenWeiSold;

  /**
   * Event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  /**
   * @param _rate Number of token units a buyer gets per wei
   * @param _wallet Address where collected funds will be forwarded to
   * @param _token Address of the token being sold
   */
  constructor(uint256 _rate, address _wallet, ERC20 _token) public {
    require(_rate > 0);
    require(_wallet != address(0));
    require(_token != address(0));

    rate = _rate;
    wallet = _wallet;
    token = _token;
  }

  // -----------------------------------------
  // Crowdsale external interface
  // -----------------------------------------

  /**
   * @dev fallback function ***DO NOT OVERRIDE***
   */
  function () external payable {
    buyTokens(msg.sender);
  }

  /**
   * @dev low level token purchase ***DO NOT OVERRIDE***
   * @param _beneficiary Address performing the token purchase
   */
  function buyTokens(address _beneficiary) public payable {

    uint256 weiAmount = msg.value;
    _preValidatePurchase(_beneficiary, weiAmount);

    // calculate token amount to be created
    uint256 tokens = _getTokenAmount(weiAmount);

    // update state
    weiRaised = weiRaised.add(weiAmount);
    tokenWeiSold = tokenWeiSold.add(tokens);

    _processPurchase(_beneficiary, tokens);
    emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);

    _updatePurchasingState(_beneficiary, weiAmount);

    _forwardFunds();
    _postValidatePurchase(_beneficiary, weiAmount);
  }

  // -----------------------------------------
  // Internal interface (extensible)
  // -----------------------------------------

  /**
   * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use super to concatenate validations.
   * @param _beneficiary Address performing the token purchase
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
  }

  /**
   * @dev Validation of an executed purchase. Observe state and use revert statements to undo rollback when valid conditions are not met.
   * @param _beneficiary Address performing the token purchase
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _postValidatePurchase(address _beneficiary, uint256 _weiAmount) pure internal {
    // optional override
  }

  /**
   * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
   * @param _beneficiary Address performing the token purchase
   * @param _tokenAmount Number of tokens to be emitted
   */
  function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
    token.transfer(_beneficiary, _tokenAmount);
  }

  /**
   * @dev Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
   * @param _beneficiary Address receiving the tokens
   * @param _tokenAmount Nu mber of tokens to be purchased
   */
  function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
    _deliverTokens(_beneficiary, _tokenAmount);
  }

  /**
   * @dev Override for extensions that require an internal state to check for validity (current user contributions, etc.)
   * @param _beneficiary Address receiving the tokens
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _updatePurchasingState(address _beneficiary, uint256 _weiAmount) pure internal {
    // optional override
  }

  /**
   * @dev Override to extend the way in which ether is converted to tokens.
   * @param _weiAmount Value in wei to be converted into tokens
   * @return Number of tokens that can be purchased with the specified _weiAmount
   */
  function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
    return _weiAmount.mul(rate);
  }

  /**
   * @dev Determines how ETH is stored/forwarded on purchases.
   */
  function _forwardFunds() internal {
    wallet.transfer(msg.value);
  }
}

contract AllowanceCrowdsale is Crowdsale {
  using SafeMath for uint256;

  address public tokenWallet;

  /**
   * @dev Constructor, takes token wallet address.
   * @param _tokenWallet Address holding the tokens, which has approved allowance to the crowdsale
   */
  constructor(address _tokenWallet) public {
    require(_tokenWallet != address(0));
    tokenWallet = _tokenWallet;
  }

  /**
   * @dev Checks the amount of tokens left in the allowance.
   * @return Amount of tokens left in the allowance
   */
  function remainingTokens() public view returns (uint256) {
    return token.allowance(tokenWallet, this);
  }

  /**
   * @dev Overrides parent behavior by transferring tokens from wallet.
   * @param _beneficiary Token purchaser
   * @param _tokenAmount Amount of tokens purchased
   */
  function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
    token.transferFrom(tokenWallet, _beneficiary, _tokenAmount);
  }
}
contract CappedCrowdsale is Crowdsale {
    using SafeMath for uint256;

    uint256 public cap;

    /**
    * @dev Constructor, takes maximum amount of wei accepted in the crowdsale.
    * @param _cap Max amount of wei to be contributed
    */
    constructor(uint256 _cap) public {
        require(_cap > 0);
        cap = _cap;
    }

    /**
    * @dev Checks whether the cap has been reached.
    * @return Whether the cap was reached
    */
    function capReached() public view returns (bool) {
        return weiRaised >= cap;
    }

    /**
    * @dev Extend parent behavior requiring purchase to respect the funding cap.
    * @param _beneficiary Token purchaser
    * @param _weiAmount Amount of wei contributed
    */
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
        super._preValidatePurchase(_beneficiary, _weiAmount);
        require(weiRaised.add(_weiAmount) <= cap);
    }

}
contract TimedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public openingTime;
  uint256 public closingTime;

  /**
   * @dev Reverts if not in crowdsale time range.
   */
  modifier onlyWhileOpen {
    // solium-disable-next-line security/no-block-members
    require(block.timestamp >= openingTime && block.timestamp <= closingTime);
    _;
  }

  /**
   * @dev Constructor, takes crowdsale opening and closing times.
   * @param _openingTime Crowdsale opening time
   * @param _closingTime Crowdsale closing time
   */
  constructor(uint256 _openingTime, uint256 _closingTime) public {
    // solium-disable-next-line security/no-block-members
    require(_openingTime >= block.timestamp);
    require(_closingTime >= _openingTime);

    openingTime = _openingTime;
    closingTime = _closingTime;
  }

  /**
   * @dev Checks whether the period in which the crowdsale is open has already elapsed.
   * @return Whether crowdsale period has elapsed
   */
  function hasClosed() public view returns (bool) {
    // solium-disable-next-line security/no-block-members
    return block.timestamp > closingTime;
  }

  /**
   * @dev Extend parent behavior requiring to be within contributing period
   * @param _beneficiary Token purchaser
   * @param _weiAmount Amount of wei contributed
   */
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal onlyWhileOpen {
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }

}
contract WhitelistedCrowdsale is Crowdsale, Administratable {

  mapping(address => bool) public whitelist;

  /**
   * Event for logging adding to whitelist
   * @param _address the address to add to the whitelist
   */
  event AddedToWhitelist(address indexed _address);

  /**
   * Event for logging removing from whitelist
   * @param _address the address to remove from the whitelist
   */
  event RemovedFromWhitelist(address indexed _address);


  /**
   * @dev Reverts if beneficiary is not whitelisted. Can be used when extending this contract.
   */
  modifier isWhitelisted(address _beneficiary) {
    require(whitelist[_beneficiary]);
    _;
  }

  /**
   * @dev Adds single address to whitelist.
   * @param _beneficiary Address to be added to the whitelist
   */
  function addToWhitelist(address _beneficiary) external onlyAdmin {
    whitelist[_beneficiary] = true;
    emit AddedToWhitelist(_beneficiary);
  }

  /**
   * @dev Adds list of addresses to whitelist. Not overloaded due to limitations with truffle testing.
   * @param _beneficiaries Addresses to be added to the whitelist
   */
  function addManyToWhitelist(address[] _beneficiaries) external onlyAdmin {
    for (uint256 i = 0; i < _beneficiaries.length; i++) {
      whitelist[_beneficiaries[i]] = true;
    }
  }

  /**
   * @dev Removes single address from whitelist.
   * @param _beneficiary Address to be removed to the whitelist
   */
  function removeFromWhitelist(address _beneficiary) external onlyAdmin {
    whitelist[_beneficiary] = false;
    emit RemovedFromWhitelist(_beneficiary);
  }

  /**
   * @dev Extend parent behavior requiring beneficiary to be in whitelist.
   * @param _beneficiary Token beneficiary
   * @param _weiAmount Amount of wei contributed
   */
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal isWhitelisted(_beneficiary) {
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }

}

contract PostDeliveryCrowdsale is TimedCrowdsale, Administratable {
  using SafeMath for uint256;

  mapping(address => uint256) public balances;
  /**
   * Event for logging when token sale tokens are withdrawn
   * @param _address the address to withdraw tokens for
   * @param _amount the amount withdrawn for this address
   */
  event TokensWithdrawn(address indexed _address, uint256 _amount);

  /**
   * @dev Withdraw tokens only after crowdsale ends.
   */
  function withdrawTokens(address _beneficiary) public onlyAdmin {
    require(hasClosed());
    uint256 amount = balances[_beneficiary];
    require(amount > 0);
    balances[_beneficiary] = 0;
    _deliverTokens(_beneficiary, amount);
    emit TokensWithdrawn(_beneficiary, amount);
  }

  /**
   * @dev Overrides parent by storing balances instead of issuing tokens right away.
   * @param _beneficiary Token purchaser
   * @param _tokenAmount Amount of tokens purchased
   */
  function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
    balances[_beneficiary] = balances[_beneficiary].add(_tokenAmount);
  }

  function getBalance(address _beneficiary) public returns (uint256) {
      return balances[_beneficiary];
  }

}

contract MultiRoundCrowdsale is  Crowdsale, Ownable {

    using SafeMath for uint256;

    struct SaleRound {
        uint256 start;
        uint256 end;
        uint256 rate;
        uint256 roundCap;
        uint256 minPurchase;
    }

    SaleRound seedRound;
    SaleRound presale;
    SaleRound crowdsaleWeek1;
    SaleRound crowdsaleWeek2;
    SaleRound crowdsaleWeek3;
    SaleRound crowdsaleWeek4;

    bool public saleRoundsSet = false;

    /**
     * Sets the parameters for each round.
     *
     * Each round is defined by an array, with each field mapping to a field in the SaleRound struct.
     * The array elements are as follows:
     * array[0]: start time of the round
     * array[1]: end time of the round
     * array[2]: the exchange rate of this round. i.e number of TIP per ETH
     * array[3]: The cumulative cap of this round
     * array[4]: Minimum purchase of this round
     *
     * @param _seedRound [description]
     * @param _presale [description]
     * @param _crowdsaleWeek1 [description]
     * @param _crowdsaleWeek2 [description]
     * @param _crowdsaleWeek3 [description]
     * @param _crowdsaleWeek4 [description]
     */
    function setTokenSaleRounds(uint256[5] _seedRound, uint256[5] _presale, uint256[5] _crowdsaleWeek1, uint256[5] _crowdsaleWeek2, uint256[5] _crowdsaleWeek3, uint256[5] _crowdsaleWeek4) external onlyOwner returns (bool) {
        // This function can only be called once
        require(!saleRoundsSet);

        // Check that each round end time is after the start time
        require(_seedRound[0] < _seedRound[1]);
        require(_presale[0] < _presale[1]);
        require(_crowdsaleWeek1[0] < _crowdsaleWeek1[1]);
        require(_crowdsaleWeek2[0] < _crowdsaleWeek2[1]);
        require(_crowdsaleWeek3[0] < _crowdsaleWeek3[1]);
        require(_crowdsaleWeek4[0] < _crowdsaleWeek4[1]);

        // Check that each round ends before the next begins
        require(_seedRound[1] < _presale[0]);
        require(_presale[1] < _crowdsaleWeek1[0]);
        require(_crowdsaleWeek1[1] < _crowdsaleWeek2[0]);
        require(_crowdsaleWeek2[1] < _crowdsaleWeek3[0]);
        require(_crowdsaleWeek3[1] < _crowdsaleWeek4[0]);

        seedRound      = SaleRound(_seedRound[0], _seedRound[1], _seedRound[2], _seedRound[3], _seedRound[4]);
        presale        = SaleRound(_presale[0], _presale[1], _presale[2], _presale[3], _presale[4]);
        crowdsaleWeek1 = SaleRound(_crowdsaleWeek1[0], _crowdsaleWeek1[1], _crowdsaleWeek1[2], _crowdsaleWeek1[3], _crowdsaleWeek1[4]);
        crowdsaleWeek2 = SaleRound(_crowdsaleWeek2[0], _crowdsaleWeek2[1], _crowdsaleWeek2[2], _crowdsaleWeek2[3], _crowdsaleWeek2[4]);
        crowdsaleWeek3 = SaleRound(_crowdsaleWeek3[0], _crowdsaleWeek3[1], _crowdsaleWeek3[2], _crowdsaleWeek3[3], _crowdsaleWeek3[4]);
        crowdsaleWeek4 = SaleRound(_crowdsaleWeek4[0], _crowdsaleWeek4[1], _crowdsaleWeek4[2], _crowdsaleWeek4[3], _crowdsaleWeek4[4]);

        saleRoundsSet = true;
        return saleRoundsSet;
    }

    function getCurrentRound() internal view returns (SaleRound) {
        require(saleRoundsSet);

        uint256 currentTime = block.timestamp;
        if (currentTime > seedRound.start && currentTime <= seedRound.end) {
            return seedRound;
        } else if (currentTime > presale.start && currentTime <= presale.end) {
            return presale;
        } else if (currentTime > crowdsaleWeek1.start && currentTime <= crowdsaleWeek1.end) {
            return crowdsaleWeek1;
        } else if (currentTime > crowdsaleWeek2.start && currentTime <= crowdsaleWeek2.end) {
            return crowdsaleWeek2;
        } else if (currentTime > crowdsaleWeek3.start && currentTime <= crowdsaleWeek3.end) {
            return crowdsaleWeek3;
        } else if (currentTime > crowdsaleWeek4.start && currentTime <= crowdsaleWeek4.end) {
            return crowdsaleWeek4;
        } else {
            revert();
        }
    }

    function getCurrentRate() public view returns (uint256) {
        require(saleRoundsSet);
        SaleRound memory currentRound = getCurrentRound();
        return currentRound.rate;
    }

    function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
        require(_weiAmount != 0);
        uint256 currentRate = getCurrentRate();
        require(currentRate != 0);

        return currentRate.mul(_weiAmount);
    }
}

contract TipToken is ERC865Token, Ownable {
    using SafeMath for uint256;

    uint256 public constant TOTAL_SUPPLY = 10 ** 9;

    string public constant name = "Tip Token";
    string public constant symbol = "TIP";
    uint8 public constant decimals = 18;

    mapping (address => string) aliases;
    mapping (string => address) addresses;

    /**
     * Constructor
     */
    constructor() public {
        _totalSupply = TOTAL_SUPPLY * (10**uint256(decimals));
        balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }

    /**
     * Returns the available supple (total supply minus tokens held by owner)
     */
    function availableSupply() public view returns (uint256) {
        return _totalSupply.sub(balances[owner]).sub(balances[address(0)]);
    }

    /**
     * Token owner can approve for `spender` to transferFrom(...) `tokens`
     * from the token owner&#39;s account. The `spender` contract function
     * `receiveApproval(...)` is then executed
     */
    function approveAndCall(address spender, uint256 tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }

    /**
     * Don&#39;t accept ETH.
     */
    function () public payable {
        revert();
    }

    /**
     * Owner can transfer out any accidentally sent ERC20 tokens
     */
    function transferAnyERC20Token(address tokenAddress, uint256 tokens) public onlyOwner returns (bool success) {
        return ERC20(tokenAddress).transfer(owner, tokens);
    }

    /**
     * Sets the alias for the msg.sender&#39;s address.
     * @param alias the alias to attach to an address
     */
    function setAlias(string alias) public {
        aliases[msg.sender] = alias;
        addresses[alias] = msg.sender;
    }
}

contract TipTokenCrowdsale is MultiRoundCrowdsale, CappedCrowdsale, WhitelistedCrowdsale, AllowanceCrowdsale, PostDeliveryCrowdsale, Pausable {

    /**
     * Contract name
     * String name - the name of the contract
     */
    string public constant name = "Tip Token Crowdsale";


    /**
     * @param _vault Address where collected funds will be forwarded to
     * @param _tokenWallet Address holding the tokens, which has approved allowance to the crowdsale
     * @param _cap the maximum number of tokens to be collected in the sale
     * @param _token Address of the token being sold
     */
    constructor(
        ERC20 _token,
        address _tokenWallet,
        address _vault,
        uint256 _cap,
        uint256 _start, uint256 _end, uint256 _baseRate
        ) public
        Crowdsale(_baseRate, _vault, _token)
        CappedCrowdsale(_cap)
        TimedCrowdsale(_start, _end)
        PostDeliveryCrowdsale()
        WhitelistedCrowdsale()
        AllowanceCrowdsale(_tokenWallet)
        MultiRoundCrowdsale()
        {
    }

    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal whenNotPaused() {
        super._preValidatePurchase(_beneficiary, _weiAmount);

        SaleRound memory currentRound = getCurrentRound();
        require(weiRaised.add(_weiAmount) <= currentRound.roundCap);
        require(balances[_beneficiary].add(_weiAmount) >= currentRound.minPurchase);
    }

    function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
        return MultiRoundCrowdsale._getTokenAmount(_weiAmount);
    }

    function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
        AllowanceCrowdsale._deliverTokens(_beneficiary, _tokenAmount);
    }
}