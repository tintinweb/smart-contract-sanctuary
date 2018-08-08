pragma solidity ^0.4.11;

  /**
   * Provides methods to safely add, subtract and multiply uint256 numbers.
   */
  contract SafeMath {
    uint256 constant private MAX_UINT256 =
      0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    /**
     * Add two uint256 values, revert in case of overflow.
     *
     * @param x first value to add
     * @param y second value to add
     * @return x + y
     */
    function safeAdd (uint256 x, uint256 y)
    constant internal
    returns (uint256 z) {
      require (x <= MAX_UINT256 - y);
      return x + y;
    }

    /**
     * Subtract one uint256 value from another, throw in case of underflow.
     *
     * @param x value to subtract from
     * @param y value to subtract
     * @return x - y
     */
    function safeSub (uint256 x, uint256 y)
    constant internal
    returns (uint256 z) {
      require(x >= y);
      return x - y;
    }

    /**
     * Multiply two uint256 values, throw in case of overflow.
     *
     * @param x first value to multiply
     * @param y second value to multiply
     * @return x * y
     */
    function safeMul (uint256 x, uint256 y)
    constant internal
    returns (uint256 z) {
      if (y == 0) return 0; // Prevent division by zero at the next line
      require (x <= MAX_UINT256 / y);
      return x * y;
    }
  }

  /**
   * ERC-20 standard token interface, as defined
   * <a href="http://github.com/ethereum/EIPs/issues/20">here</a>.
   */
  contract Token {
    /**
     * Get total number of tokens in circulation.
     *
     * @return total number of tokens in circulation
     */
    function totalSupply () constant returns (uint256 supply);

    /**
     * Get number of tokens currently belonging to given owner.
     *
     * @param _owner address to get number of tokens currently belonging to the
     *        owner of
     * @return number of tokens currently belonging to the owner of given address
     */
    function balanceOf (address _owner) constant returns (uint256 balance);

    /**
     * Transfer given number of tokens from message sender to given recipient.
     *
     * @param _to address to transfer tokens to the owner of
     * @param _value number of tokens to transfer to the owner of given address
     * @return true if tokens were transferred successfully, false otherwise
     */
    function transfer (address _to, uint256 _value) returns (bool success);

    /**
     * Transfer given number of tokens from given owner to given recipient.
     *
     * @param _from address to transfer tokens from the owner of
     * @param _to address to transfer tokens to the owner of
     * @param _value number of tokens to transfer from given owner to given
     *        recipient
     * @return true if tokens were transferred successfully, false otherwise
     */
    function transferFrom (address _from, address _to, uint256 _value)
    returns (bool success);

    /**
     * Allow given spender to transfer given number of tokens from message sender.
     *
     * @param _spender address to allow the owner of to transfer tokens from
     *        message sender
     * @param _value number of tokens to allow to transfer
     * @return true if token transfer was successfully approved, false otherwise
     */
    function approve (address _spender, uint256 _value) returns (bool success);

    /**
     * Tell how many tokens given spender is currently allowed to transfer from
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
     * Logged when tokens were transferred from one owner to another.
     *
     * @param _from address of the owner, tokens were transferred from
     * @param _to address of the owner, tokens were transferred to
     * @param _value number of tokens transferred
     */
    event Transfer (address indexed _from, address indexed _to, uint256 _value);

    /**
     * Logged when owner approved his tokens to be transferred by some spender.
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

  /**
   * Abstract Token Smart Contract that could be used as a base contract for
   * ERC-20 token contracts.
   */
  contract AbstractToken is Token, SafeMath {

    /**
     * Address of the fund of this smart contract.
     */
    address fund;

    /**
     * Create new Abstract Token contract.
     */
    function AbstractToken () {
      // Do nothing
    }


    /**
     * Get number of tokens currently belonging to given owner.
     *
     * @param _owner address to get number of tokens currently belonging to the
     *        owner of
     * @return number of tokens currently belonging to the owner of given address
     */
     function balanceOf (address _owner) constant returns (uint256 balance) {
      return accounts [_owner];
    }

    /**
     * Transfer given number of tokens from message sender to given recipient.
     *
     * @param _to address to transfer tokens to the owner of
     * @param _value number of tokens to transfer to the owner of given address
     * @return true if tokens were transferred successfully, false otherwise
     */
    function transfer (address _to, uint256 _value) returns (bool success) {
      uint256 feeTotal = fee();

      if (accounts [msg.sender] < _value) return false;
      if (_value > feeTotal && msg.sender != _to) {
        accounts [msg.sender] = safeSub (accounts [msg.sender], _value);
        
        accounts [_to] = safeAdd (accounts [_to], safeSub(_value, feeTotal));

        processFee(feeTotal);

        Transfer (msg.sender, _to, safeSub(_value, feeTotal));
        
      }
      return true;
    }

    /**
     * Transfer given number of tokens from given owner to given recipient.
     *
     * @param _from address to transfer tokens from the owner of
     * @param _to address to transfer tokens to the owner of
     * @param _value number of tokens to transfer from given owner to given
     *        recipient
     * @return true if tokens were transferred successfully, false otherwise
     */
    function transferFrom (address _from, address _to, uint256 _value)
    returns (bool success) {
      uint256 feeTotal = fee();

      if (allowances [_from][msg.sender] < _value) return false;
      if (accounts [_from] < _value) return false;

      allowances [_from][msg.sender] =
        safeSub (allowances [_from][msg.sender], _value);

      if (_value > feeTotal && _from != _to) {
        accounts [_from] = safeSub (accounts [_from], _value);

        
        accounts [_to] = safeAdd (accounts [_to], safeSub(_value, feeTotal));

        processFee(feeTotal);

        Transfer (_from, _to, safeSub(_value, feeTotal));
      }

      return true;
    }

    function fee () constant returns (uint256);

    function processFee(uint256 feeTotal) internal returns (bool);

    /**
     * Allow given spender to transfer given number of tokens from message sender.
     *
     * @param _spender address to allow the owner of to transfer tokens from
     *        message sender
     * @param _value number of tokens to allow to transfer
     * @return true if token transfer was successfully approved, false otherwise
     */
    function approve (address _spender, uint256 _value) returns (bool success) {
      allowances [msg.sender][_spender] = _value;
      Approval (msg.sender, _spender, _value);

      return true;
    }

    /**
     * Tell how many tokens given spender is currently allowed to transfer from
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
    returns (uint256 remaining) {
      return allowances [_owner][_spender];
    }

    /**
     * Mapping from addresses of token holders to the numbers of tokens belonging
     * to these token holders.
     */
    mapping (address => uint256) accounts;

    /**
     * Mapping from addresses of token holders to the mapping of addresses of
     * spenders to the allowances set by these token holders to these spenders.
     */
    mapping (address => mapping (address => uint256)) allowances;
  }

  contract ParagonCoinToken is AbstractToken {
    /**
     * Initial number of tokens.
     */
    uint256 constant INITIAL_TOKENS_COUNT = 200000000e6;

    /**
     * Address of the owner of this smart contract.
     */
    address owner;

   

    /**
     * Total number of tokens ins circulation.
     */
    uint256 tokensCount;

    /**
     * Create new ParagonCoin Token Smart Contract, make message sender to be the
     * owner of smart contract, issue given number of tokens and give them to
     * message sender.
     */
    function ParagonCoinToken (address fundAddress) {
      tokensCount = INITIAL_TOKENS_COUNT;
      accounts [msg.sender] = INITIAL_TOKENS_COUNT;
      owner = msg.sender;
      fund = fundAddress;
    }

    /**
     * Get name of this token.
     *
     * @return name of this token
     */
    function name () constant returns (string name) {
      return "PRG";
    }

    /**
     * Get symbol of this token.
     *
     * @return symbol of this token
     */
    function symbol () constant returns (string symbol) {
      return "PRG";
    }


    /**
     * Get number of decimals for this token.
     *
     * @return number of decimals for this token
     */
    function decimals () constant returns (uint8 decimals) {
      return 6;
    }

    /**
     * Get total number of tokens in circulation.
     *
     * @return total number of tokens in circulation
     */
    function totalSupply () constant returns (uint256 supply) {
      return tokensCount;
    }

    

    /**
     * Transfer given number of tokens from message sender to given recipient.
     *
     * @param _to address to transfer tokens to the owner of
     * @param _value number of tokens to transfer to the owner of given address
     * @return true if tokens were transferred successfully, false otherwise
     */
    function transfer (address _to, uint256 _value) returns (bool success) {
      return AbstractToken.transfer (_to, _value);
    }

    /**
     * Transfer given number of tokens from given owner to given recipient.
     *
     * @param _from address to transfer tokens from the owner of
     * @param _to address to transfer tokens to the owner of
     * @param _value number of tokens to transfer from given owner to given
     *        recipient
     * @return true if tokens were transferred successfully, false otherwise
     */
    function transferFrom (address _from, address _to, uint256 _value)
    returns (bool success) {
      return AbstractToken.transferFrom (_from, _to, _value);
    }

    function fee () constant returns (uint256) {
      return safeAdd(safeMul(tokensCount, 5)/1e11, 25000);
    }

    function processFee(uint256 feeTotal) internal returns (bool) {
        uint256 burnFee = feeTotal/2;
        uint256 fundFee = safeSub(feeTotal, burnFee);

        accounts [fund] = safeAdd (accounts [fund], fundFee);
        tokensCount = safeSub (tokensCount, burnFee); // ledger burned toke

        Transfer (msg.sender, fund, fundFee);

        return true;
    }

    /**
     * Change how many tokens given spender is allowed to transfer from message
     * spender.  In order to prevent double spending of allowance, this method
     * receives assumed current allowance value as an argument.  If actual
     * allowance differs from an assumed one, this method just returns false.
     *
     * @param _spender address to allow the owner of to transfer tokens from
     *        message sender
     * @param _currentValue assumed number of tokens currently allowed to be
     *        transferred
     * @param _newValue number of tokens to allow to transfer
     * @return true if token transfer was successfully approved, false otherwise
     */
    function approve (address _spender, uint256 _currentValue, uint256 _newValue)
    returns (bool success) {
      if (allowance (msg.sender, _spender) == _currentValue)
        return approve (_spender, _newValue);
      else return false;
    }

    /**
     * Burn given number of tokens belonging to message sender.
     *
     * @param _value number of tokens to burn
     * @return true on success, false on error
     */
    function burnTokens (uint256 _value) returns (bool success) {
      if (_value > accounts [msg.sender]) return false;
      else if (_value > 0) {
        accounts [msg.sender] = safeSub (accounts [msg.sender], _value);
        tokensCount = safeSub (tokensCount, _value);
        return true;
      } else return true;
    }

    /**
     * Set new owner for the smart contract.
     * May only be called by smart contract owner.
     *
     * @param _newOwner address of new owner of the smart contract
     */
    function setOwner (address _newOwner) {
      require (msg.sender == owner);

      owner = _newOwner;
    }

    
    /**
     * Set new fund address for the smart contract.
     * May only be called by smart contract owner.
     *
     * @param _newFund new fund address of the smart contract
     */
    function setFundAddress (address _newFund) {
      require (msg.sender == owner);

      fund = _newFund;
    }

  }