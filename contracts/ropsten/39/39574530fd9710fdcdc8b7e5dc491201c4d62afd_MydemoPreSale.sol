pragma solidity ^0.4.23;

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev Transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

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
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
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
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}


contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


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
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}


contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
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
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}


contract MydemoConstant {
    // hard cap of Mydemo token i.e total number of token which can be ever minted
    uint256 constant TOKEN_HARDCAP = 48000000;

    // hard cap for pre ico
    uint256 constant PRESALE_HARDCAP = 3000000;

    // hard cap for crowdsale
    uint256 constant CROWDSALE_HARDCAP = 27000000;

    // token distribution share for different team while minting defined in multiple of 1000
    uint256 constant TEAM_TOKENS_PERCENT =  28000;
    uint256 constant ADVISORS_TOKENS_PERCENT= 4000;
    uint256 constant BOUNTY_TOKENS_PERCENT = 3200;
    uint256 constant FLOAT_TOKENS_PERCENT =  21600; 

    // Bonus Discount&#39;s upto Investment&#39;s
    uint256 constant BONUS_DISCOUNT_1 = 1500000;
    uint256 constant BONUS_DISCOUNT_2 = 2500000;
    uint256 constant BONUS_DISCOUNT_3 = 3000000;

     // Bonus percentage
    uint256 constant BONUS_DISCOUNT_PERCENT_1 = 50;
    uint256 constant BONUS_DISCOUNT_PERCENT_2 = 17;
    uint256 constant BONUS_DISCOUNT_PERCENT_3 = 8;

    // different wallets to store token
    address constant TEAM_ADDRESS = 0xb2c8C4dEB09417dCEE037B1d5c3108fbFeb76F6E;
    address constant ADVISOR_ADDRESS = 0x48399FA38d4e6fA73CB23C10B2A7bF3303e282Cc;
    address constant BOUNTY_ADDRESS = 0xe08C74508d0998f3f15A28c2be6a423Feeb9bfc2;
    address constant FLOAT_WALLET = 0xdC0591F7D9F622788dad9d19eF9a2BDB0fD8Be60;

    // Token Name and Symbol
    string constant TOKEN_NAME = "Mydemo Token";
    string constant TOKEN_SYMBOL = "MDT";
}


contract MydemoToken is MydemoConstant, StandardToken, Ownable {
    // Different Events need to be emitted
    event MintingFinished();
    event MintingAddressAdded(address indexed _address);
    event MintingAddressRemoved(address indexed _address);
    event TransferAddressAdded(address indexed _address);
    event Mint(address indexed _address, uint256 _amount);

    // Pause token transfer, after successfully finished crowdsale it becomes false to enable transfer.
    bool public isLocked = true;
    bool public isMintingFinished = false;

    // Accounts who can transfer token even if paused. Works only during crowdsale.
    mapping(address => bool) adrAllowedForTransfer;
    mapping(address => bool) adrAllowedForMinting;

    modifier onlyAllowedForTransfer {
        if(isLocked) {
            require(adrAllowedForTransfer[msg.sender] == true);
            _;
        } else {
            _;
        }
    }

    modifier onlyAllowedForMinting {
        require(adrAllowedForMinting[msg.sender] == true);
        _;
    }

    modifier canMint {
        require(!isMintingFinished);
        _;
    }

    /**
    *@dev Set it for using mint function
    *@param it is the address of the deployed project
    */
    function setAllowedForMinting(address _address) external onlyOwner  {
        adrAllowedForMinting[_address] = true;
        emit MintingAddressAdded(_address);
    }

    /**
    *@dev Set it for using mint function
    *@param it is the address of the deployed project
    */
    function setDisallowedForMinting(address _address) external onlyOwner  {
        adrAllowedForMinting[_address] = false;
        emit MintingAddressRemoved(_address);
    }

    function checkAllowedAddressForMinting(address _address) external view onlyOwner returns (bool){
        return adrAllowedForMinting[_address];
    }

    function approveProject(address _investorAddress, uint256 _value) onlyAllowedForTransfer public {
        allowed[_investorAddress][msg.sender] = _value;
        emit Approval(_investorAddress, msg.sender, _value);
    }

    /**
    *@dev Set it before using transferfunction 
    *@param it is the address of the deployed project
    */
    function setAllowedForTransfer(address _address) external onlyOwner {
        adrAllowedForTransfer[_address] = true;
        emit TransferAddressAdded(_address);
    }

    function checkAllowedAddressFoTransfer(address _address) external view onlyOwner returns (bool){
        return adrAllowedForTransfer[_address];
    }

    function name() public pure returns (string) {
        return TOKEN_NAME;
    }

    function symbol() public pure returns (string) {
        return TOKEN_SYMBOL;
    }

    function transferFrom(address _from, address _to, uint256 _value) public onlyAllowedForTransfer returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function transfer(address _to, uint256 _value) public onlyAllowedForTransfer returns (bool) {
        return super.transfer(_to, _value);
    }

    /**
    * @dev Function to mint tokens
    */
    function mint(address _to, uint256 _amount) onlyAllowedForMinting canMint public {
        require(totalSupply_.add(_amount) <= TOKEN_HARDCAP, "Token Hardcap Reached!");
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
    }

    /**
    * @dev Function to stop minting new tokens.
    * @return True if the operation was successful.
    */
    function finishMinting() onlyAllowedForMinting canMint public {
        isMintingFinished = true;
        isLocked = false;
        emit MintingFinished();
    }
}

contract MydemoPreSale is MydemoConstant, Ownable {
    using SafeMath for uint256;

    //instance of Mydemo Token
    MydemoToken public token;

    // variable to hold number of tokens sold (for which user paid) in pre sale
    uint256 public soldTokens;

    // variable to hold number of total number of tokens minted in pre sale including bonus and everything
    uint256 public mintedTokens;

    // START TIME as seconds since unix epoch
    //uint256 public openingTime;
	uint256 public openingTime = 1532682370;
	
    // END TIME as seconds since unix epoch
    //uint256 public closingTime; 
	uint256 public closingTime = 1532689569;  
	
    // uint256 private totalBonusToken;

    // boolean hold status(open/close) of pre sale
    bool public isFinalized;

    // boolean to hold setup function is called or not, to make sure setup can be called only once
    bool public isSetupDone;

    // boolean to pause/resume pre sale
    bool public isPaused;

    //Different Events need to be emitted
    event SetupCalled(uint256 startTime, uint256 endTime);
    event SaleEnded(string reason, uint256 time);
    event SalePaused(uint256 time);
    event SaleResumed(uint256 time);

    constructor(address _tokenAddress) public Ownable() {
        token = MydemoToken(_tokenAddress);
        isFinalized = false;
        isSetupDone = false;
        isPaused = false;
    }

    /**
    * @dev Reverts if not in crowdsale time range.
    */
    modifier onlyWhileOpen {
        require(isSetupDone, "Please call setup function first!");
        require(!isFinalized, "Sale is finalized!");
        require(!isPaused, "Sale is paused!");
        if(block.timestamp >= openingTime && block.timestamp <= closingTime) {
            _;
        } else {
            //deadline reached
            if(!isFinalized) {
                isFinalized = true;
                emit SaleEnded("Deadline Crossed", block.timestamp);
            }
            revert("Outside the contract time!");
        }
    }

    function setup(uint256 _openingTime, uint256 _endTime) external onlyOwner {
        require(!isSetupDone);
        require(_openingTime != 0 && _endTime != 0);
        require(_endTime >= _openingTime);
        require(_endTime > block.timestamp);
        openingTime = _openingTime;
        closingTime = _endTime;
        isSetupDone = true;
        emit SetupCalled(_openingTime, _endTime);
    }

    /**
    * @dev external function for contract owner to pause the sale
    */
    function pauseSale() external onlyOwner onlyWhileOpen {
        require(!isPaused);
        isPaused = true;
        emit SalePaused(block.timestamp);
    }

    /**
    * @dev external function for contract owner to resume the sale if paused
    */
    function resumeSale() external onlyOwner onlyWhileOpen {
        require(isPaused);
        isPaused = false;
        emit SaleResumed(block.timestamp);
    }

    /**
    *@dev function to calculate and distribute token for team on every purchase
    */
    function _distributeTeamToken(uint256 _tokenAmount) private {
        uint teamTokens = _tokenAmount.mul(TEAM_TOKENS_PERCENT).div(100000);
        token.mint(TEAM_ADDRESS, teamTokens);
        mintedTokens = mintedTokens.add(teamTokens);
    }

    /**
    *@dev function to calculate and distribute token for advisors on every purchase
    */
    function _distributeAdvisorsToken(uint256 _tokenAmount) private {
        uint256 advisorTokens = _tokenAmount.mul(ADVISORS_TOKENS_PERCENT).div(100000);
        token.mint(ADVISOR_ADDRESS, advisorTokens);
        mintedTokens = mintedTokens.add(advisorTokens);
    }

    /**
    *@dev function to calculate and distribute token for bounty on every purchase
    */
    function _distributeBountyToken(uint256 _tokenAmount) private {
        uint256 bountyTokens = _tokenAmount.mul(BOUNTY_TOKENS_PERCENT).div(100000);
        token.mint(BOUNTY_ADDRESS, bountyTokens);
        mintedTokens = mintedTokens.add(bountyTokens);
    }

    /**
    *@dev function to calculate and distribute token for Float Wallet on every purchase
    */
    function _distributeFloatWalletToken(uint256 _tokenAmount) private {
        uint256 floatTokens = _tokenAmount.mul(FLOAT_TOKENS_PERCENT).div(100000);
        token.mint(FLOAT_WALLET, floatTokens);
        mintedTokens = mintedTokens.add(floatTokens);
    }

    /**
    *@dev function to calculate and distribute token to purchaser
    */
    function _distributeTokenToPurchaser(address _address, uint256 _tokenAmount) private {
        uint totalBonusToken = calculateBonusToken(_tokenAmount);
        uint totalToken = _tokenAmount.add(totalBonusToken);
        token.mint(_address, totalToken);
        mintedTokens = mintedTokens.add(totalToken);
    }

    // low level token purchase function
    function sellTokens(address _address, uint256 _tokenAmount)  public onlyOwner onlyWhileOpen {
        require(_tokenAmount > 0, "Minimum purchase amount should be greater then 0!");
        require(soldTokens.add(_tokenAmount) <= PRESALE_HARDCAP, "You can not purchase more then hard cap!");
        require(_address != 0x0);

        _distributeTokenToPurchaser(_address, _tokenAmount);
        _distributeTeamToken(_tokenAmount);
        _distributeAdvisorsToken(_tokenAmount);
        _distributeBountyToken(_tokenAmount);
        _distributeFloatWalletToken(_tokenAmount);

        // Hard Cap is reached
        if(soldTokens == PRESALE_HARDCAP) {
            isFinalized = true;
            emit SaleEnded("Hardcap Reached", block.timestamp);
        }
    }

    /**
    *@dev Calculate bonus tokens for purchaser
     */
    function calculateBonusToken(uint256 _tokenAmount) internal returns(uint256) {
        uint discountPercent;
        uint bonusTokenSupply;
        (discountPercent, bonusTokenSupply) = getDiscountAndSupply();

        if(_tokenAmount <= bonusTokenSupply) {
            soldTokens = soldTokens.add(_tokenAmount);
            return _tokenAmount.mul(discountPercent).div(100);
        } else {
            uint bonusToken = bonusTokenSupply.mul(discountPercent).div(100);
            soldTokens = soldTokens.add(bonusTokenSupply);
            return bonusToken + calculateBonusToken(_tokenAmount - bonusTokenSupply);
        }
    }

    /**
    *@dev get bonus percent and amount of token left
     */
    function getDiscountAndSupply() private view returns(uint, uint){
        if( 0 <= soldTokens && soldTokens < BONUS_DISCOUNT_1) {
            return(BONUS_DISCOUNT_PERCENT_1, BONUS_DISCOUNT_1 - soldTokens);
        } else if( BONUS_DISCOUNT_1 <= soldTokens && soldTokens < BONUS_DISCOUNT_2) {
            return(BONUS_DISCOUNT_PERCENT_2, BONUS_DISCOUNT_2 - soldTokens);
        } else if(BONUS_DISCOUNT_2 <= soldTokens && soldTokens < BONUS_DISCOUNT_3) {
            return(BONUS_DISCOUNT_PERCENT_3, BONUS_DISCOUNT_3 - soldTokens);
        } else {
            return(0, PRESALE_HARDCAP - soldTokens);
        }
    }

    function setSaleFinish() external onlyOwner {
        require(!isFinalized);
        isFinalized = true;
        emit SaleEnded("Requested By Owner", block.timestamp);
    }
}