/**
 *Submitted for verification at Etherscan.io on 2021-05-08
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.5.16;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: @openzeppelin/contracts/token/ERC20/ERC20Detailed.sol



/**
 * @dev Optional functions from the ERC20 standard.
 */
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

// File: @openzeppelin/contracts/GSN/Context.sol


/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/ownership/Ownable.sol


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/HPLUS.sol





library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
    function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
    uint256 c = add(a,m);
    uint256 d = sub(c,1);
    return mul(div(d,m),m);
  }
}

contract HedgePlus is ERC20Detailed,Ownable{
  using SafeMath for uint256;

  // State Variables
  string constant _name = "HedgePlus";
  string constant _symbol = "HPLUS";
  uint8 public constant _decimal = 18;
  uint256 TOTAL_SUPPLY;
  uint256 public taxPercentage = 200; // 2% Tax Deduction


  // Tokenomics
  uint256 private constant PrePublicSale_Amount = 63_00_000 ether;
  uint256 private constant Platform_Amount = 42_00_000 ether;
  uint256 private constant TEAM_Amount = 21_00_000 ether;
  uint256 private constant OPERATIONS_Amount = 21_00_000 ether;
  uint256 private constant EXCHANGES_Amount = 21_00_000 ether;
  uint256 private constant MARKETING_Amount = 21_00_000 ether;
  uint256 private constant PROMOTIONS_Amount = 10_50_000 ether;
  uint256 private constant LEGAL_Amount = 10_50_000 ether;

  address private  PrePublicSale;
  address private  Platform;
  address private  TEAM;
  address private  OPERATIONS;
  address private  EXCHANGES;
  address private  MARKETING;
  address private  PROMOTIONS;
  address private  LEGAL;

  address private MarketMakingWallet; 

  // Mappings in the Contracts
  mapping (address => uint256) private _balances;
  mapping(address => bool) public isBlackListed;
  mapping (address => mapping (address => uint256)) private _allowances;

 constructor(
    address _prePublic,
    address _platform,
    address _team,
    address _operations,
    address _exchanges,
    address _marketing,
    address _promotions,
    address _legal,
    address _marketMakingAddress
    ) public ERC20Detailed(_name,_symbol,_decimal){
   
    TOTAL_SUPPLY = 21_000_000 ether;

    PrePublicSale = _prePublic;
    Platform = _platform;
    TEAM = _team;
    OPERATIONS = _operations;
    EXCHANGES = _exchanges;
    MARKETING = _marketing;
    PROMOTIONS = _promotions;
    LEGAL = _legal;

    MarketMakingWallet = _marketMakingAddress;
    
    _mint(_prePublic,PrePublicSale_Amount);
    _mint(_platform,Platform_Amount);
    _mint(_team,TEAM_Amount);
    _mint(_operations,OPERATIONS_Amount);
    _mint(_exchanges,EXCHANGES_Amount);
    _mint(_marketing,MARKETING_Amount);
    _mint(_promotions,PROMOTIONS_Amount);
    _mint(_legal,LEGAL_Amount);
  }

  function totalSupply() public view returns (uint256) {
    return TOTAL_SUPPLY;
  }

  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }

  function allowance(address owner, address spender) public view returns (uint256) {
    return _allowances[owner][spender];
  }

  /**
    * @notice - Mints new tokens equal to Total Supply.
    * @dev    - Only called once in the constructor.
    * @param account owner's address
    * @param amount Total Tokens to be minted
    */
  function _mint(address account, uint256 amount) internal {
    require(account != address(0), "Error MSG_1: Invalid Address Passed");

    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

    function changeMarketMakingAddress(address _marketMakingAddress) external onlyOwner returns(bool){
      require (_marketMakingAddress != address(0),"Error MSG_1: Invalid Address Passed");
      MarketMakingWallet = _marketMakingAddress;
      return true;
  }

 
   /**
    * @notice - External Functions for BlackListing specific addresses 
    * @dev    - Only Acceble by the Owner of the contract
    * @param _userAddresses array of addresses of the Users
    * @return - true if Function executes successfully
    */
    function blackListAddress(address[] calldata _userAddresses) external onlyOwner returns(bool){
      _addBlackList(_userAddresses);
    }
    
  /**
    * @notice - External Functions for Removing BlackListed TAG from addresses  
    * @dev    - Only Acceble by the Owner of the contract
    * @param _userAddresses array of addresses of the Users
    * @return - true if Function executes successfully
    */
    function whiteList(address[] calldata _userAddresses) external onlyOwner returns(bool){
      _removeFromBlackList(_userAddresses);
    }



   /**
    * @notice - Internal Functions for BlackListing specific addresses 
    * @param _userAddresses array of addresses of the Users
    * @return - true if Function executes successfully
    */
    function _addBlackList(address[] memory _userAddresses) internal returns(bool){
      uint256 total_addresses = _userAddresses.length;
      for(uint256 i=0;i<total_addresses;i++){
        require (!isBlackListed[_userAddresses[i]],"Error MSG_2: User Address is Already BlackListed");
        isBlackListed[_userAddresses[i]] = true;
      }
      return true;
    }

     /**
    * @notice - Internal Functions for Removing BlackListed TAG from addresses 
    * @param _userAddresses array of addresses of the Users
    * @return - true if Function executes successfully
    */
    function _removeFromBlackList(address[] memory _userAddresses) internal returns(bool){
      uint256 total_addresses = _userAddresses.length;
      for(uint256 i=0;i<total_addresses;i++){
        require (isBlackListed[_userAddresses[i]],"Error MSG_2: User Address is NOT Blacklisted");
        isBlackListed[_userAddresses[i]] = false;
      }
      return true;
    }
  /**
    * @notice - Calculates the Tax Amount to be deducted based on the Args passed and Base Percent
    * @param _amount -amount of tokens on which the tax is to be calculated    
    */
    function calculateTaxAmount(uint256 _amount) internal view returns(uint256){
      uint256 roundValue = _amount.ceil(taxPercentage);
      uint256 taxAmount = roundValue.mul(taxPercentage).div(10000);
    return taxAmount;
    }
    
  /**
    * @notice - Transfers tokens to reciever and includes tax deduction mechanism
    * @param _recipient -reciever of tokens.
    * @param _amount -amount of tokens to be transferred.
    * @return bool - TRUE if executes successfully 
    */
    function transfer(address _recipient, uint256 _amount) public returns(bool) {
    require (!isBlackListed[msg.sender] && !isBlackListed[_recipient] ,"Error MSG_2: Either Sender or Recipient is Blacklisted");
    require (_amount > 0,"Error MSG_4:Amount Cannot be ZERO");
    require(balanceOf(msg.sender) >= _amount,"ERROR MSG_3: InSufficient Balance of Sender");

    uint256 taxAmount = calculateTaxAmount(_amount);
    uint256 transferrableTokens = _amount.sub(taxAmount);
    uint256 tokensToBurn = taxAmount.div(2);

    _balances[msg.sender] = _balances[msg.sender].sub(_amount);
    _balances[_recipient] = _balances[_recipient].add(transferrableTokens);
    
    //HALF of Tax Amount is sent to Market Making Wallet.
    require(MarketMakingWallet != address(0),"Error MSG:Market Making Wallet is INVALID ADDRESS");
    _balances[MarketMakingWallet] = _balances[MarketMakingWallet].add(tokensToBurn);
    // HAlF of Tax amount of tokens being burnt
    TOTAL_SUPPLY = TOTAL_SUPPLY.sub(tokensToBurn);

    emit Transfer(msg.sender, _recipient, transferrableTokens);
    emit Transfer(msg.sender, address(0), tokensToBurn);
    return true;
  }
  /**
    * @notice - Transfers tokens to reciever and includes tax deduction mechanism
    * @param _sender -sender of tokens
    * @param _recipient -reciever of tokens.
    * @param _amount -amount of tokens to be transferred.
    * @return bool - TRUE if executes successfully 
    */
  function transferFrom(address _sender,address _recipient,uint256 _amount) public returns(bool res){
    require(_recipient != address(0), "Error MSG_1: Invalid Recipient Address Passed");
    require (!isBlackListed[msg.sender] && !isBlackListed[_recipient],"Error MSG_2: Either Sender or Recipient is Blacklisted");
    require (_amount > 0,"Error MSG_4:Amount Cannot be ZERO");
    require(balanceOf(_sender) >= _amount,"ERROR MSG_3: InSufficient Balance of Sender");
    require(_allowances[_sender][msg.sender] >= _amount,"ERROR MSG_4: InSufficient Allowance of Sender");

    uint256 taxAmount = calculateTaxAmount(_amount);
    uint256 transferrableTokens = _amount.sub(taxAmount);
    uint256 tokensToBurn = taxAmount.div(2);

    _balances[_sender] = _balances[_sender].sub(_amount);
    _balances[_recipient] = _balances[_recipient].add(transferrableTokens);
    
    //HALF of Tax Amount is sent to Market Making Wallet.
       require(MarketMakingWallet != address(0),"Error MSG:Market Making Wallet is INVALID ADDRESS");
    _balances[MarketMakingWallet] = _balances[MarketMakingWallet].add(tokensToBurn);
    // Tax amount of tokens being burnt
    TOTAL_SUPPLY = TOTAL_SUPPLY.sub(tokensToBurn);

    // Allowance Mapping is being Updated
    _allowances[_sender][msg.sender] = _allowances[_sender][msg.sender].sub(_amount);
    
    // Emission of EVents
    emit Transfer(_sender, _recipient, transferrableTokens);
    emit Transfer(_sender, address(0), tokensToBurn);
    return true;
  }

    /**
    * @notice - Approves Spender with specific amount of tokens to be used on owner's behalf
    * @param _spender -address that is approved to use tokens
    * @param _amount -amount of tokens to be approved.
    * @return bool - TRUE if executes successfully 
    */
  function approve(address _spender, uint256 _amount) public returns(bool) {
    require(_spender != address(0), "Error MSG_1: Invalid Spender Address Passed");
    require (!isBlackListed[msg.sender] && !isBlackListed[_spender] ,"Error MSG_2: Either Sender or Recipient is Blacklisted");

    _allowances[msg.sender][_spender] = _amount;
    emit Approval(msg.sender, _spender, _amount);
    return true;
  }
  
  /**
    * @notice - Increases the Approved amount for the spender
    * @param _spender -address that is approved to use tokens
    * @param _amount -amount of tokens to be approved.
    * @return bool - TRUE if executes successfully 
    */
  function increaseAllowance(address _spender, uint256 _amount) public returns (bool) {
      require(_spender != address(0), "Error MSG_1: Invalid Spender Address Passed");
      _allowances[msg.sender][_spender] += _amount;
      emit Approval(msg.sender, _spender,_allowances[msg.sender][_spender]);
      return true;
    }

  /**
    * @notice - Decreases the Approved amount for the spender
    * @param _spender -address that is approved to use tokens
    * @param _amount -amount of tokens to be approved.
    * @return bool - TRUE if executes successfully 
    */
  function decreaseAllowance(address _spender, uint256 _amount) public returns (bool) {
    require(_spender != address(0), "Error MSG_1: Invalid Spender Address Passed");
    _allowances[msg.sender][_spender] = _allowances[msg.sender][_spender].sub(_amount);
    emit Approval(msg.sender, _spender,_allowances[msg.sender][_spender]);
    return true;
  }


    /**
    * @notice - Burns specifc amount of tokens from the caller address
    * @param _amount  the amount of token to be burnt
    * @return bool - TRUE if executes successfully 
    */
  function burnTokens(uint256 _amount) external{
    require (!isBlackListed[msg.sender],"Error MSG_2:User is Blacklisted");

    _burnTokens(msg.sender,_amount);    
  }


    /**
    * @notice -Allows a user to Burn tokens as per his allowances
    * @param _spender the address that is approved to use/burn the tokens
    * @param _amount  the amount of token to be burnt
    * @return bool - TRUE if executes successfully 
    */
  function  _burnTokensFrom(address _spender,uint256 _amount) external{
    require(_allowances[_spender][msg.sender] >= _amount,"ERROR MSG_4: InSufficient Allowance of Sender");

    _allowances[_spender][msg.sender] = _allowances[_spender][msg.sender].sub(_amount);
    _burnTokens(_spender,_amount);
  }

    /**
    * @notice - Burns tokens from a given address
    * @param _account the address of the caller from the which the token is to be burnt
    * @param _amount  the amount of token to be burnt
    * @return bool - TRUE if executes successfully 
    */
  function  _burnTokens(address _account,uint256 _amount) internal returns(bool) {
    require(_account != address(0), "Error MSG_1: Invalid Account Address Passed");
    require (_amount > 0,"Error MSG_4:Amount Cannot be ZERO");
    require(balanceOf(_account) >= _amount,"ERROR MSG_3: InSufficient Balance of Sender");

    TOTAL_SUPPLY = TOTAL_SUPPLY.sub(_amount);
    _balances[_account] = _balances[_account].sub(_amount);
    emit Transfer(_account,address(0),_amount);

    return true;
    
  }
  
}