pragma solidity 0.4.25;


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
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
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

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    uint256 totalSupply_;

    /**
    * @dev total number of tokens in existence
    */
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        // SafeMath.sub will throw if there is not enough balance.
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
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;

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
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    /**
     * approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     */
    function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
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

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
        assert(token.transfer(to, value));
    }

    function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
        assert(token.transferFrom(from, to, value));
    }

    function safeApprove(ERC20 token, address spender, uint256 value) internal {
        assert(token.approve(spender, value));
    }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    _owner = msg.sender;
  }

  /**
   * @return the address of the owner.
   */
  function owner() public view returns(address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  /**
   * @return true if `msg.sender` is the owner of the contract.
   */
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}


/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

  /**
   * @dev Burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   */
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
    // no need to require value <= totalSupply, since that would imply the
    // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
}

/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/openzeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
contract MintableToken is StandardToken, Ownable {
    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    bool public mintingFinished = false;

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    /**
    * @dev Function to mint tokens
    * @param _to The address that will receive the minted tokens.
    * @param _amount The amount of tokens to mint.
    * @return A boolean that indicates if the operation was successful.
    */
    function mint(address _to, uint256 _amount) onlyOwner canMint internal returns (bool) {
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

    /**
    * @dev Function to stop minting new tokens.
    * @return True if the operation was successful.
    */
    function finishMinting() onlyOwner canMint public returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }
}

contract BuyBack is Ownable {
    using SafeMath for uint256;
    
    mapping(address => uint256) public staked;
    mapping(address => uint256) public forced;
    mapping(address => bool) public verified;
    bool public closed  = false;
    bool public finalized  = false;
    BlueOceanToken private token;
    uint256 public price;
    uint256 public buybackPercentage;
    
    event TokenholderCheck(address tokenHolder, string checksProofHash);
    event Participation(address owner, uint256 stake);
    event BuyBackClosed(uint256 time);
    
    constructor(BlueOceanToken _token, uint256 _price, uint256 _buybackPercentage) payable public {
        require(_buybackPercentage > 0 && _buybackPercentage <= 100);
        
        token = _token;
        price = _price;
        buybackPercentage = _buybackPercentage;
        transferOwnership(token.owner());
    }
    
    function participate(address _holder) public {
        require(msg.sender == address(token));
        require(!closed);
        require(token.balanceOf(_holder) > 0, "Buyback participation denied, you do not posses any stakable tokens!");
        require(verified[_holder], "Buyback participation denied, please complete the Tokenholder Checks on the SwissVCT platform!");
        require(token.balanceOf(_holder) == token.allowance(_holder, address(this)), "You must appove the BuyBack contract to stake all your tokens!");
        
        uint256 stake = token.balanceOf(_holder);
        uint256 boughtTokensAmount = stake.mul(buybackPercentage).div(100);
        uint256 buybackPay = boughtTokensAmount.mul(price).div(10**18);

        staked[_holder] = staked[_holder].add(stake.sub(boughtTokensAmount));

        require(token.transferFrom(_holder, address(this), stake));
        require(token.transfer(owner(), boughtTokensAmount));
        _holder.transfer(buybackPay);

        emit Participation(_holder, stake);
    }
    
    function verifyHolder(address _tokenHolder, string _checkProofHash) onlyOwner public {
        verified[_tokenHolder] = true;
        emit TokenholderCheck(_tokenHolder, _checkProofHash);
    }
    
    function unstake() public {
        require(closed, "The buyback process is not over yet, please await the closing event!");
        _unstake(msg.sender);
    }
    
    function forceUnstake(address _participant) public onlyOwner {
        _unstake(_participant);
    }
    
    function _unstake(address _owner) internal {
        uint256 stake = staked[_owner];
        staked[_owner] = 0;
        require(token.transfer(_owner, stake));
    }
    
    function close() onlyOwner public {
        closed = true;
        emit BuyBackClosed(now);
        token.freezeTrading();
    }
    
    function isActive() public view returns(bool) {
        return !closed && !finalized;
    }
    
    function isFinalized() public view returns(bool) {
        return finalized;
    }
    
    function getStake(address _owner) public view returns(uint256) {
        return staked[_owner];
    }
        
    function forceBuyback(address _holder) public onlyOwner {
        require(closed);
        require(!finalized);
        require(forced[_holder] == 0);

        uint256 forceBuybackAmount = buybackPercentage.mul(token.balanceOf(_holder)).div(100);
        token.forceBuyback(_holder, forceBuybackAmount);
        forced[_holder] = forceBuybackAmount;
    }

    function finalize() onlyOwner public {
        require(closed);
        require(!finalized);

        // withdraw the unclaimed ETH
        require(owner().send(address(this).balance), "Failed to transfer the remaining Ether!");
        token.unfreezeTrading();
        finalized = true;
    }
    
    function () public payable {
        require(msg.sender == owner());
    }
}

contract BlueOceanToken is BurnableToken, MintableToken {
    string public constant name = "BlueOcean Token";
    string public constant symbol = "BOT";
    uint8 public constant decimals = 18;

    /// when the token sale is closed no more minting is possible
    bool public saleClosed = false;

    /// open the trading for everyone
    bool public tradingOpen = false;
    
    BuyBack public currentBuyback;

    /// Only allowed to execute before the token sale is closed
    modifier beforeSaleClosed {
        require(!saleClosed);
        _;
    }

    /// Only allow to be called by the BuyBack contract 
    modifier onlyBuyback {
        require(msg.sender == address(currentBuyback));
        _;
    }
    
    event Investment(string indexed txId, address indexed beneficiary, string currency, uint256 investmentAmount, uint256 tokensAmount);

    constructor() public {}
    
    function mintInvestment(string _currency, string _txId, uint256 _investmentAmount, address _beneficiary, uint256 _tokensAmount) 
                                public onlyOwner beforeSaleClosed returns (bool) {
        emit Investment(_txId, _beneficiary, _currency, _investmentAmount, _tokensAmount);
        return mint(_beneficiary, _tokensAmount);
    }

    /// @dev reallocates the unsold and leftover bounty tokens
    function closeSale() external onlyOwner beforeSaleClosed {
        /// No more minting is possible
        finishMinting();
        saleClosed = true;
    }
    
    function freezeTrading() onlyBuyback public {
        tradingOpen = false;
    }
    
    function unfreezeTrading() onlyBuyback public {
        tradingOpen = true;
    }
        
    function forceBuyback(address _holder, uint256 _tokens) onlyBuyback public {
        allowed[_holder][address(this)] = _tokens;
        emit Approval(_holder, address(this), _tokens);
        require(transferFrom(_holder, owner(), _tokens));
    }

    function activateBuyback(uint256 _ethPerTokenPrice, uint256 _buybackPercentage) onlyOwner public payable {
        require(currentBuyback == address(0) || currentBuyback.isFinalized());
        
        currentBuyback = new BuyBack(this, _ethPerTokenPrice, _buybackPercentage);
    }
    
    function finalizeBuyback() onlyOwner public {
        currentBuyback.finalize();
    }
    
    function participateBuyback() public {
        require(currentBuyback != address(0) && currentBuyback.isActive());

        approve(address(currentBuyback), balances[msg.sender]);
        currentBuyback.participate(msg.sender);
    }

    /// @dev Trading limited
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        /// XXX: a minimum amount that can be transferred is there 
        /// to protect the Buybacks from token fractioning sabotage attacks
                    /* || (_value > 10 ** decimals || _value == balanceOf(from)) */
        if(tradingOpen || msg.sender == address(this) || msg.sender == address(currentBuyback)) {
            return super.transferFrom(_from, _to, _value);
        }
        return false;
    }

    /// @dev Trading limited
    function transfer(address _to, uint256 _value) public returns (bool) {
        if(tradingOpen || msg.sender == address(this) || msg.sender == address(currentBuyback)) {
            return super.transfer(_to, _value);
        }
        return false;
    }
}