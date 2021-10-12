/**
 *Submitted for verification at BscScan.com on 2021-10-11
*/

// Sources flattened with hardhat v2.6.5 https://hardhat.org
 
// File @openzeppelin/contracts/utils/[email protected]
 
// SPDX-License-Identifier: MIT
 
pragma solidity ^0.8.0;
 
/**
* @dev Provides information about the current execution context, including the
* sender of the transaction and its data. While these are generally available
* via msg.sender and msg.data, they should not be accessed in such a direct
* manner, since when dealing with meta-transactions the account sending and
* paying for execution may not be the actual sender (as far as an application
* is concerned).
*
* This contract is only required for intermediate, library-like contracts.
*/
abstract contract Context {
   function _msgSender() internal view virtual returns (address) {
       return msg.sender;
   }
 
   function _msgData() internal view virtual returns (bytes calldata) {
       return msg.data;
   }
}
 
 
// File @openzeppelin/contracts/access/[email protected]
 
 
pragma solidity ^0.8.0;
 
/**
* @dev Contract module which provides a basic access control mechanism, where
* there is an account (an owner) that can be granted exclusive access to
* specific functions.
*
* By default, the owner account will be the one that deploys the contract. This
* can later be changed with {transferOwnership}.
*
* This module is used through inheritance. It will make available the modifier
* `onlyOwner`, which can be applied to your functions to restrict their use to
* the owner.
*/
abstract contract Ownable is Context {
   address private _owner;
 
   event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
 
   /**
    * @dev Initializes the contract setting the deployer as the initial owner.
    */
   constructor() {
       _setOwner(_msgSender());
   }
 
   /**
    * @dev Returns the address of the current owner.
    */
   function owner() public view virtual returns (address) {
       return _owner;
   }
 
   /**
    * @dev Throws if called by any account other than the owner.
    */
   modifier onlyOwner() {
       require(owner() == _msgSender(), "Ownable: caller is not the owner");
       _;
   }
 
   /**
    * @dev Leaves the contract without owner. It will not be possible to call
    * `onlyOwner` functions anymore. Can only be called by the current owner.
    *
    * NOTE: Renouncing ownership will leave the contract without an owner,
    * thereby removing any functionality that is only available to the owner.
    */
   function renounceOwnership() public virtual onlyOwner {
       _setOwner(address(0));
   }
 
   /**
    * @dev Transfers ownership of the contract to a new account (`newOwner`).
    * Can only be called by the current owner.
    */
   function transferOwnership(address newOwner) public virtual onlyOwner {
       require(newOwner != address(0), "Ownable: new owner is the zero address");
       _setOwner(newOwner);
   }
 
   function _setOwner(address newOwner) private {
       address oldOwner = _owner;
       _owner = newOwner;
       emit OwnershipTransferred(oldOwner, newOwner);
   }
}
 
 
// File @openzeppelin/contracts/token/ERC20/[email protected]
 
pragma solidity ^0.8.0;
 
/**
* @dev Interface of the ERC20 standard as defined in the EIP.
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
   function transferFrom(
       address sender,
       address recipient,
       uint256 amount
   ) external returns (bool);
 
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
 
 
// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]
 
 
pragma solidity ^0.8.0;
 
/**
* @dev Interface for the optional metadata functions from the ERC20 standard.
*
* _Available since v4.1._
*/
interface IERC20Metadata is IERC20 {
   /**
    * @dev Returns the name of the token.
    */
   function name() external view returns (string memory);
 
   /**
    * @dev Returns the symbol of the token.
    */
   function symbol() external view returns (string memory);
 
   /**
    * @dev Returns the decimals places of the token.
    */
   function decimals() external view returns (uint8);
}
 
 
// File @openzeppelin/contracts/token/ERC20/[email protected]
 
 
pragma solidity ^0.8.0;
 
 
 
/**
* @dev Implementation of the {IERC20} interface.
*
* This implementation is agnostic to the way tokens are created. This means
* that a supply mechanism has to be added in a derived contract using {_mint}.
* For a generic mechanism see {ERC20PresetMinterPauser}.
*
* TIP: For a detailed writeup see our guide
* https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
* to implement supply mechanisms].
*
* We have followed general OpenZeppelin Contracts guidelines: functions revert
* instead returning `false` on failure. This behavior is nonetheless
* conventional and does not conflict with the expectations of ERC20
* applications.
*
* Additionally, an {Approval} event is emitted on calls to {transferFrom}.
* This allows applications to reconstruct the allowance for all accounts just
* by listening to said events. Other implementations of the EIP may not emit
* these events, as it isn't required by the specification.
*
* Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
* functions have been added to mitigate the well-known issues around setting
* allowances. See {IERC20-approve}.
*/
contract ERC20 is Context, IERC20, IERC20Metadata {
   mapping(address => uint256) private _balances;
 
   mapping(address => mapping(address => uint256)) private _allowances;
 
   uint256 private _totalSupply;
 
   string private _name;
   string private _symbol;
 
   /**
    * @dev Sets the values for {name} and {symbol}.
    *
    * The default value of {decimals} is 18. To select a different value for
    * {decimals} you should overload it.
    *
    * All two of these values are immutable: they can only be set once during
    * construction.
    */
   constructor(string memory name_, string memory symbol_) {
       _name = name_;
       _symbol = symbol_;
   }
 
   /**
    * @dev Returns the name of the token.
    */
   function name() public view virtual override returns (string memory) {
       return _name;
   }
 
   /**
    * @dev Returns the symbol of the token, usually a shorter version of the
    * name.
    */
   function symbol() public view virtual override returns (string memory) {
       return _symbol;
   }
 
   /**
    * @dev Returns the number of decimals used to get its user representation.
    * For example, if `decimals` equals `2`, a balance of `505` tokens should
    * be displayed to a user as `5.05` (`505 / 10 ** 2`).
    *
    * Tokens usually opt for a value of 18, imitating the relationship between
    * Ether and Wei. This is the value {ERC20} uses, unless this function is
    * overridden;
    *
    * NOTE: This information is only used for _display_ purposes: it in
    * no way affects any of the arithmetic of the contract, including
    * {IERC20-balanceOf} and {IERC20-transfer}.
    */
   function decimals() public view virtual override returns (uint8) {
       return 18;
   }
 
   /**
    * @dev See {IERC20-totalSupply}.
    */
   function totalSupply() public view virtual override returns (uint256) {
       return _totalSupply;
   }
 
   /**
    * @dev See {IERC20-balanceOf}.
    */
   function balanceOf(address account) public view virtual override returns (uint256) {
       return _balances[account];
   }
 
   /**
    * @dev See {IERC20-transfer}.
    *
    * Requirements:
    *
    * - `recipient` cannot be the zero address.
    * - the caller must have a balance of at least `amount`.
    */
   function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
       _transfer(_msgSender(), recipient, amount);
       return true;
   }
 
   /**
    * @dev See {IERC20-allowance}.
    */
   function allowance(address owner, address spender) public view virtual override returns (uint256) {
       return _allowances[owner][spender];
   }
 
   /**
    * @dev See {IERC20-approve}.
    *
    * Requirements:
    *
    * - `spender` cannot be the zero address.
    */
   function approve(address spender, uint256 amount) public virtual override returns (bool) {
       _approve(_msgSender(), spender, amount);
       return true;
   }
 
   /**
    * @dev See {IERC20-transferFrom}.
    *
    * Emits an {Approval} event indicating the updated allowance. This is not
    * required by the EIP. See the note at the beginning of {ERC20}.
    *
    * Requirements:
    *
    * - `sender` and `recipient` cannot be the zero address.
    * - `sender` must have a balance of at least `amount`.
    * - the caller must have allowance for ``sender``'s tokens of at least
    * `amount`.
    */
   function transferFrom(
       address sender,
       address recipient,
       uint256 amount
   ) public virtual override returns (bool) {
       _transfer(sender, recipient, amount);
 
       uint256 currentAllowance = _allowances[sender][_msgSender()];
       require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
       unchecked {
           _approve(sender, _msgSender(), currentAllowance - amount);
       }
 
       return true;
   }
 
   /**
    * @dev Atomically increases the allowance granted to `spender` by the caller.
    *
    * This is an alternative to {approve} that can be used as a mitigation for
    * problems described in {IERC20-approve}.
    *
    * Emits an {Approval} event indicating the updated allowance.
    *
    * Requirements:
    *
    * - `spender` cannot be the zero address.
    */
   function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
       _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
       return true;
   }
 
   /**
    * @dev Atomically decreases the allowance granted to `spender` by the caller.
    *
    * This is an alternative to {approve} that can be used as a mitigation for
    * problems described in {IERC20-approve}.
    *
    * Emits an {Approval} event indicating the updated allowance.
    *
    * Requirements:
    *
    * - `spender` cannot be the zero address.
    * - `spender` must have allowance for the caller of at least
    * `subtractedValue`.
    */
   function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
       uint256 currentAllowance = _allowances[_msgSender()][spender];
       require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
       unchecked {
           _approve(_msgSender(), spender, currentAllowance - subtractedValue);
       }
 
       return true;
   }
 
   /**
    * @dev Moves `amount` of tokens from `sender` to `recipient`.
    *
    * This internal function is equivalent to {transfer}, and can be used to
    * e.g. implement automatic token fees, slashing mechanisms, etc.
    *
    * Emits a {Transfer} event.
    *
    * Requirements:
    *
    * - `sender` cannot be the zero address.
    * - `recipient` cannot be the zero address.
    * - `sender` must have a balance of at least `amount`.
    */
   function _transfer(
       address sender,
       address recipient,
       uint256 amount
   ) internal virtual {
       require(sender != address(0), "ERC20: transfer from the zero address");
       require(recipient != address(0), "ERC20: transfer to the zero address");
 
       _beforeTokenTransfer(sender, recipient, amount);
 
       uint256 senderBalance = _balances[sender];
       require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
       unchecked {
           _balances[sender] = senderBalance - amount;
       }
       _balances[recipient] += amount;
 
       emit Transfer(sender, recipient, amount);
 
       _afterTokenTransfer(sender, recipient, amount);
   }
 
   /** @dev Creates `amount` tokens and assigns them to `account`, increasing
    * the total supply.
    *
    * Emits a {Transfer} event with `from` set to the zero address.
    *
    * Requirements:
    *
    * - `account` cannot be the zero address.
    */
   function _mint(address account, uint256 amount) internal virtual {
       require(account != address(0), "ERC20: mint to the zero address");
 
       _beforeTokenTransfer(address(0), account, amount);
 
       _totalSupply += amount;
       _balances[account] += amount;
       emit Transfer(address(0), account, amount);
 
       _afterTokenTransfer(address(0), account, amount);
   }
 
   /**
    * @dev Destroys `amount` tokens from `account`, reducing the
    * total supply.
    *
    * Emits a {Transfer} event with `to` set to the zero address.
    *
    * Requirements:
    *
    * - `account` cannot be the zero address.
    * - `account` must have at least `amount` tokens.
    */
   function _burn(address account, uint256 amount) internal virtual {
       require(account != address(0), "ERC20: burn from the zero address");
 
       _beforeTokenTransfer(account, address(0), amount);
 
       uint256 accountBalance = _balances[account];
       require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
       unchecked {
           _balances[account] = accountBalance - amount;
       }
       _totalSupply -= amount;
 
       emit Transfer(account, address(0), amount);
 
       _afterTokenTransfer(account, address(0), amount);
   }
 
   /**
    * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
    *
    * This internal function is equivalent to `approve`, and can be used to
    * e.g. set automatic allowances for certain subsystems, etc.
    *
    * Emits an {Approval} event.
    *
    * Requirements:
    *
    * - `owner` cannot be the zero address.
    * - `spender` cannot be the zero address.
    */
   function _approve(
       address owner,
       address spender,
       uint256 amount
   ) internal virtual {
       require(owner != address(0), "ERC20: approve from the zero address");
       require(spender != address(0), "ERC20: approve to the zero address");
 
       _allowances[owner][spender] = amount;
       emit Approval(owner, spender, amount);
   }
 
   /**
    * @dev Hook that is called before any transfer of tokens. This includes
    * minting and burning.
    *
    * Calling conditions:
    *
    * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
    * will be transferred to `to`.
    * - when `from` is zero, `amount` tokens will be minted for `to`.
    * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
    * - `from` and `to` are never both zero.
    *
    * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
    */
   function _beforeTokenTransfer(
       address from,
       address to,
       uint256 amount
   ) internal virtual {}
 
   /**
    * @dev Hook that is called after any transfer of tokens. This includes
    * minting and burning.
    *
    * Calling conditions:
    *
    * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
    * has been transferred to `to`.
    * - when `from` is zero, `amount` tokens have been minted for `to`.
    * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
    * - `from` and `to` are never both zero.
    *
    * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
    */
   function _afterTokenTransfer(
       address from,
       address to,
       uint256 amount
   ) internal virtual {}
}
 
 
// File contracts/BetToken.sol
 
pragma solidity 0.8.9;
 
/**
* @title BetToken
*/
contract BetToken is ERC20 {
   uint256 public totalHolders;
   address public predictionMarket;
 
   event Mint(address indexed _to, uint256 _value);
   event Burn(address indexed _to, uint256 _value);
 
   /**
    * @dev The PositionToken constructor sets initial values.
    * @param _name string The name of the Position Token.
    * @param _symbol string The symbol of the Position Token.
    */
   constructor(string memory _name, string memory _symbol)
       ERC20(_name, _symbol)
   {
       predictionMarket = msg.sender;
   }
 
   /**
    * @dev Throws if called by any account other than PredictionMarket.
    */
   modifier onlyPredictionMarket() {
       require(msg.sender == predictionMarket, "PREDICTION_MARKET_ONLY");
       _;
   }
 
   /**
    * @dev Mints position tokens for a user.
    * @param _to address The address of beneficiary.
    * @param _value uint256 The amount of tokens to be minted.
    */
   function mint(address _to, uint256 _value) public onlyPredictionMarket {
       _mint(_to, _value);
       if (balanceOf(_to) == _value) totalHolders++;
       emit Mint(_to, _value);
   }
 
   /**
    * @dev Burns position tokens of a user.
    * @param _from address The address of beneficent.
    * @param _value uint256 The amount of tokens to be burned.
    */
   function burn(address _from, uint256 _value) public onlyPredictionMarket {
       _burn(_from, _value);
       if (balanceOf(_from) == 0) totalHolders--;
       emit Burn(_from, _value);
   }
 
   function burnAll(address _from) public onlyPredictionMarket {
       uint256 _value = balanceOf(_from);
       if (_value == 0) return;
       totalHolders--;
       _burn(_from, _value);
       emit Burn(_from, _value);
   }
 
   function transfer(address recipient, uint256 amount)
       public
       override
       returns (bool success)
   {
       if (balanceOf(recipient) == 0) totalHolders++;
       if (balanceOf(msg.sender) == amount) totalHolders--;
       success = super.transfer(recipient, amount);
       require(success, "ERR_TRANSFER_FAILED");
   }
 
   function transferFrom(
       address sender,
       address recipient,
       uint256 amount
   ) public override returns (bool success) {
       if (balanceOf(recipient) == 0) totalHolders++;
       if (balanceOf(sender) == amount) totalHolders--;
 
       success = super.transferFrom(sender, recipient, amount);
       require(success, "ERR_TRANSFER_FROM_FAILED");
   }
}
 
 
// File contracts/AggregatorV3Interface.sol
 
pragma solidity 0.8.9;
 
interface IAggregatorV3Interface {
   function decimals() external view returns (uint8);
 
   function description() external view returns (string memory);
 
   function version() external view returns (uint256);
 
   // getRoundData and latestRoundData should both raise "No data present"
   // if they do not have data to report, instead of returning unset values
   // which could be misinterpreted as actual reported values.
   function getRoundData(uint80 _roundId)
       external
       view
       returns (
           uint80 roundId,
           int256 answer,
           uint256 startedAt,
           uint256 updatedAt,
           uint80 answeredInRound
       );
 
   function latestRoundData()
       external
       view
       returns (
           uint80 roundId,
           int256 answer,
           uint256 startedAt,
           uint256 updatedAt,
           uint80 answeredInRound
       );
}
 
 
// File contracts/PredictionMarket.sol
 
pragma solidity 0.8.9;
 
 
contract PredictionMarket is Ownable {
   uint256 public latestConditionIndex;
   uint256 public adminFeeRate;
   uint256 public ownerFeeRate;
   uint256 public marketCreationFee;
 
   address public operatorAddress;
   address public ethUsdOracleAddress;
 
   uint256 private _status;
 
   mapping(uint256 => ConditionInfo) public conditions;
 
   //owner/marketOwner => conditionIndex => feeClaimed
   mapping(address => mapping(uint256 => uint256)) public feeClaimed;
 
   //oracle address -> interval -> index
   mapping(address => mapping(uint256 => uint256)) public autoGeneratedMarkets;
   bool private _paused;
 
   struct ConditionInfo {
       string market;
       address oracle;
       int256 triggerPrice;
       uint256 settlementTime;
       bool isSettled;
       int256 settledPrice;
       address lowBetToken;
       address highBetToken;
       uint256 totalStakedAbove;
       uint256 totalStakedBelow;
       uint256 totalEthClaimable;
       address conditionOwner;
   }
 
   //conditionIndex
   mapping(uint256 => uint256) public betEndTime;
 
   event ConditionPrepared(
       address conditionOwner,
       uint256 indexed conditionIndex,
       address indexed oracle,
       uint256 indexed settlementTime,
       int256 triggerPrice,
       address lowBetTokenAddress,
       address highBetTokenAddress
   );
   event UserPrediction(
       uint256 indexed conditionIndex,
       address indexed userAddress,
       uint256 indexed etHStaked,
       uint8 prediction,
       uint256 timestamp
   );
   event UserClaimed(
       uint256 indexed conditionIndex,
       address indexed userAddress,
       uint256 indexed winningAmount
   );
   event ConditionSettled(
       uint256 indexed conditionIndex,
       int256 indexed settledPrice,
       uint256 timestamp
   );
   event NewMarketGenerated(
       uint256 indexed conditionIndex,
       address indexed oracle
   );
   event SetOperator(address operatorAddress);
   event SetMarketExpirationFee(uint256 adminFeeRate, uint256 ownerFeeRate);
   event SetMarketCreationFee(uint256 feeRate);
   event UpdateEthUsdOracleAddress(address oracle);
   event Paused(address account);
   event Unpaused(address account);
 
   modifier onlyOperator() {
       require(msg.sender == operatorAddress, "ERR_INVALID_OPERATOR");
       _;
   }
 
   modifier whenNotPaused() {
       require(!paused(), "PAUSED");
       _;
   }
 
   modifier whenPaused() {
       require(paused(), "NOT_PAUSED");
       _;
   }
 
   modifier whenMarketActive(uint256 _conditionIndex) {
       require(
           block.timestamp <= betEndTime[_conditionIndex],
           "ERR_INVALID_SETTLEMENT_TIME"
       );
 
       _;
   }
 
   modifier nonReentrant() {
       // On the first call to nonReentrant, _notEntered will be true
       require(_status != 2, "REENTRANT_CALL");
       _status = 2;
       _;
       _status = 1;
   }
 
   /**
    * @notice Construct a new Prediction Market contract
    * @param _ethUsdOracleAddress The address of ETH-USD oracle.
    */
   // solhint-disable-next-line
   constructor(address _ethUsdOracleAddress, address _operator) {
       require(
           _ethUsdOracleAddress != address(0),
           "ERR_ZERO_ADDRESS_FOR_ORACLE"
       );
       require(_operator != address(0), "ERR_ZERO_ADDRESS_FOR_OPERATOR");
 
       ethUsdOracleAddress = _ethUsdOracleAddress;
 
       adminFeeRate = 80;
       ownerFeeRate = 20;
       marketCreationFee = 5; //in dollars
 
       operatorAddress = _operator;
       _paused = false;
       _status = 1;
   }
 
   function setOperator(address _operatorAddress) external onlyOwner {
       require(_operatorAddress != address(0), "ERR_INVALID_OPERATOR_ADDRESS");
       operatorAddress = _operatorAddress;
       emit SetOperator(operatorAddress);
   }
 
   function setEthUsdOracleAddress(address _ethUsdOracleAddress)
       external
       onlyOwner
   {
       require(_ethUsdOracleAddress != address(0), "ERR_INVALID_ADDRESS");
       ethUsdOracleAddress = _ethUsdOracleAddress;
       emit UpdateEthUsdOracleAddress(ethUsdOracleAddress);
   }
 
   function setMarketExpirationFee(
       uint256 _adminFeeRate,
       uint256 _ownerFeeRate
   ) external onlyOwner {
       require(_adminFeeRate > 0 && _ownerFeeRate > 0, "ERR_FEE_TOO_LOW");
       require(
           _adminFeeRate <= 1000 && _ownerFeeRate <= 1000,
           "ERR_FEE_TOO_HIGH"
       );
 
       adminFeeRate = _adminFeeRate;
       ownerFeeRate = _ownerFeeRate;
       emit SetMarketExpirationFee(adminFeeRate, ownerFeeRate);
   }
 
   function setMarketCreationFee(uint256 _fee) external onlyOwner {
       require(_fee > 0 && _fee <= 1000, "ERR_INVALID_FEE");
       marketCreationFee = _fee;
       emit SetMarketCreationFee(marketCreationFee);
   }
 
   function execute(address oracle, uint256 interval) external onlyOperator {
       require(oracle != address(0), "ERR_INVALID_CONDITION_INDEX");
 
       uint256 index = autoGeneratedMarkets[oracle][interval];
 
       //settle and claim for previous index
       claimFor(payable(msg.sender), index);
 
       //prepare new condition
       int256 triggerPrice = getPrice(oracle);
       uint256 newIndex = _prepareCondition(
           oracle,
           interval,
           triggerPrice,
           false
       );
 
       autoGeneratedMarkets[oracle][interval] = newIndex;
       emit NewMarketGenerated(newIndex, oracle);
   }
 
   function paused() public view returns (bool) {
       return _paused;
   }
 
   function _pause() internal whenNotPaused {
       _paused = true;
       emit Paused(_msgSender());
   }
 
   function _unpause() internal whenPaused {
       _paused = false;
       emit Unpaused(_msgSender());
   }
 
   function togglePause(bool pause) external {
       require(
           msg.sender == operatorAddress || msg.sender == owner(),
           "ERR_INVALID_ADDRESS_ACCESS"
       );
       if (pause) _pause();
       else _unpause();
   }
 
   function safeTransferETH(address to, uint256 value) internal {
       // solhint-disable-next-line
       (bool success, ) = payable(to).call{value: value}(new bytes(0));
 
       // solhint-disable-next-line
       require(success, "ETH_TRANSFER_FAILED");
   }
 
   function getMarketCreationFee() public view returns (uint256 toDeduct) {
       int256 latestPrice = getPrice(ethUsdOracleAddress);
       toDeduct = (marketCreationFee * 1 ether) / uint256(latestPrice);
   }
 
   function _deductMarketCreationFee() internal returns (uint256 toDeduct) {
       toDeduct = getMarketCreationFee();
       require(msg.value >= toDeduct, "ERR_PROVIDE_FEE");
       safeTransferETH(owner(), toDeduct);
   }
 
   function prepareCondition(
       address _oracle,
       uint256 _settlementTimePeriod,
       int256 _triggerPrice,
       bool _initialize
   ) public payable whenNotPaused returns (uint256) {
       _deductMarketCreationFee();
       return
           _prepareCondition(
               _oracle,
               _settlementTimePeriod,
               _triggerPrice,
               _initialize
           );
   }
 
   function _prepareCondition(
       address _oracle,
       uint256 _settlementTimePeriod,
       int256 _triggerPrice,
       bool _initialize
   ) internal nonReentrant returns (uint256) {
       require(_oracle != address(0), "ERR_INVALID_ORACLE_ADDRESS");
       require(_settlementTimePeriod >= 300, "ERR_INVALID_SETTLEMENT_TIME");
 
       latestConditionIndex = latestConditionIndex + 1;
       ConditionInfo storage conditionInfo = conditions[latestConditionIndex];
 
       conditionInfo.market = IAggregatorV3Interface(_oracle).description();
       conditionInfo.oracle = _oracle;
       conditionInfo.settlementTime = _settlementTimePeriod + block.timestamp;
       conditionInfo.triggerPrice = _triggerPrice;
       conditionInfo.isSettled = false;
       conditionInfo.lowBetToken = address(
           new BetToken(
               "Low Bet Token",
               string(abi.encodePacked("LBT-", conditionInfo.market))
           )
       );
       conditionInfo.highBetToken = address(
           new BetToken(
               "High Bet Token",
               string(abi.encodePacked("HBT-", conditionInfo.market))
           )
       );
       conditionInfo.conditionOwner = msg.sender;
 
       //to prevent double initialisation of auto generated markets
       if (
           _initialize &&
           autoGeneratedMarkets[_oracle][_settlementTimePeriod] == 0
       ) {
           autoGeneratedMarkets[_oracle][
               _settlementTimePeriod
           ] = latestConditionIndex;
       }
 
       betEndTime[latestConditionIndex] =
           ((_settlementTimePeriod * 90) / 100) +
           block.timestamp;
 
       emit ConditionPrepared(
           msg.sender,
           latestConditionIndex,
           _oracle,
           conditionInfo.settlementTime,
           _triggerPrice,
           conditionInfo.lowBetToken,
           conditionInfo.highBetToken
       );
 
       return latestConditionIndex;
   }
 
   function probabilityRatio(uint256 _conditionIndex)
       external
       view
       returns (uint256 aboveProbabilityRatio, uint256 belowProbabilityRatio)
   {
       ConditionInfo storage conditionInfo = conditions[_conditionIndex];
       if (conditionInfo.isSettled) {
           return (0, 0);
       }
       uint256 ethStakedForAbove = BetToken(conditionInfo.highBetToken)
           .totalSupply();
       uint256 ethStakedForBelow = BetToken(conditionInfo.lowBetToken)
           .totalSupply();
 
       uint256 totalEthStaked = ethStakedForAbove + ethStakedForBelow;
 
       aboveProbabilityRatio = totalEthStaked > 0
           ? (ethStakedForAbove * (1e18)) / (totalEthStaked)
           : 0;
       belowProbabilityRatio = totalEthStaked > 0
           ? (ethStakedForBelow * (1e18)) / (totalEthStaked)
           : 0;
   }
 
   function userTotalETHStaked(uint256 _conditionIndex, address userAddress)
       external
       view
       returns (uint256 totalEthStaked)
   {
       ConditionInfo storage conditionInfo = conditions[_conditionIndex];
       uint256 ethStakedForAbove = BetToken(conditionInfo.highBetToken)
           .balanceOf(userAddress);
       uint256 ethStakedForBelow = BetToken(conditionInfo.lowBetToken)
           .balanceOf(userAddress);
 
       totalEthStaked = ethStakedForAbove + ethStakedForBelow;
   }
 
   function betOnCondition(uint256 _conditionIndex, uint8 _prediction)
       external
       payable
   {
       //call betOncondition
       betOnConditionFor(msg.sender, _conditionIndex, _prediction, msg.value);
   }
 
   function betOnConditionFor(
       address _user,
       uint256 _conditionIndex,
       uint8 _prediction,
       uint256 _amount
   )
       public
       payable
       whenNotPaused
       nonReentrant
       whenMarketActive(_conditionIndex)
   {
       ConditionInfo storage conditionInfo = conditions[_conditionIndex];
 
       require(_user != address(0), "ERR_INVALID_ADDRESS");
 
       require(
           conditionInfo.oracle != address(0),
           "ERR_INVALID_ORACLE_ADDRESS"
       );
 
       require(msg.value >= _amount && _amount != 0, "ERR_INVALID_AMOUNT");
       require(
           (_prediction == 0) || (_prediction == 1),
           "ERR_INVALID_PREDICTION"
       ); //prediction = 0 (price will be below), if 1 (price will be above)
 
       uint256 userETHStaked = _amount;
       if (_prediction == 0) {
           BetToken(conditionInfo.lowBetToken).mint(_user, userETHStaked);
       } else {
           BetToken(conditionInfo.highBetToken).mint(_user, userETHStaked);
       }
       emit UserPrediction(
           _conditionIndex,
           _user,
           userETHStaked,
           _prediction,
           block.timestamp
       );
   }
 
   function getPrice(address oracle)
       internal
       view
       returns (int256 latestPrice)
   {
       (, latestPrice, , , ) = IAggregatorV3Interface(oracle)
           .latestRoundData();
   }
 
   function settleCondition(uint256 _conditionIndex) public whenNotPaused {
       ConditionInfo storage conditionInfo = conditions[_conditionIndex];
       require(
           conditionInfo.oracle != address(0),
           "ERR_INVALID_ORACLE_ADDRESS"
       );
       require(
           block.timestamp >= conditionInfo.settlementTime,
           "ERR_INVALID_SETTLEMENT_TIME"
       );
       require(!conditionInfo.isSettled, "ERR_CONDITION_ALREADY_SETTLED");
 
       conditionInfo.isSettled = true;
       conditionInfo.totalStakedAbove = BetToken(conditionInfo.highBetToken)
           .totalSupply();
       conditionInfo.totalStakedBelow = BetToken(conditionInfo.lowBetToken)
           .totalSupply();
 
       uint256 total = conditionInfo.totalStakedAbove +
           conditionInfo.totalStakedBelow;
 
       conditionInfo.totalEthClaimable = _transferFees(
           total,
           _conditionIndex,
           conditionInfo.conditionOwner
       );
 
       conditionInfo.settledPrice = getPrice(conditionInfo.oracle);
 
       emit ConditionSettled(
           _conditionIndex,
           conditionInfo.settledPrice,
           block.timestamp
       );
   }
 
   function _transferFees(
       uint256 totalAmount,
       uint256 _conditionIndex,
       address conditionOwner
   ) internal returns (uint256 afterFeeAmount) {
       uint256 _fees = (totalAmount * (adminFeeRate + ownerFeeRate)) / (1000);
       afterFeeAmount = totalAmount - (_fees);
 
       uint256 ownerFees = (_fees * (ownerFeeRate)) / 1000;
       feeClaimed[conditionOwner][_conditionIndex] = ownerFees;
       feeClaimed[owner()][_conditionIndex] = _fees - (ownerFees);
 
       safeTransferETH(owner(), _fees - (ownerFees));
       safeTransferETH(conditionOwner, ownerFees);
   }
 
   function claim(uint256 _conditionIndex) public {
       //call claim with msg.sender as _for
       claimFor(payable(msg.sender), _conditionIndex);
   }
 
   function claimFor(address payable _userAddress, uint256 _conditionIndex)
       public
       whenNotPaused
       nonReentrant
   {
       require(_userAddress != address(0), "ERR_INVALID_USER_ADDRESS");
       ConditionInfo storage conditionInfo = conditions[_conditionIndex];
 
       BetToken lowBetToken = BetToken(conditionInfo.lowBetToken);
       BetToken highBetToken = BetToken(conditionInfo.highBetToken);
       if (!conditionInfo.isSettled) {
           settleCondition(_conditionIndex);
       }
 
       uint256 totalWinnerRedeemable;
       //Amount Redeemable including winnerRedeemable & user initial Stake
       if (conditionInfo.settledPrice > conditionInfo.triggerPrice) {
           //Users who predicted above price wins
           uint256 userStake = highBetToken.balanceOf(_userAddress);
 
           if (userStake == 0) {
               return;
           }
           totalWinnerRedeemable = getClaimAmount(
               conditionInfo.totalEthClaimable,
               conditionInfo.totalStakedAbove,
               userStake
           );
       } else if (conditionInfo.settledPrice < conditionInfo.triggerPrice) {
           //Users who predicted below price wins
           uint256 userStake = lowBetToken.balanceOf(_userAddress);
 
           if (userStake == 0) {
               return;
           }
           totalWinnerRedeemable = getClaimAmount(
               conditionInfo.totalEthClaimable,
               conditionInfo.totalStakedBelow,
               userStake
           );
       } else {
           safeTransferETH(owner(), conditionInfo.totalEthClaimable);
           totalWinnerRedeemable = 0;
           conditionInfo.totalEthClaimable = 0;
       }
 
       highBetToken.burnAll(_userAddress);
       lowBetToken.burnAll(_userAddress);
 
       if (totalWinnerRedeemable > 0) {
           _userAddress.transfer(totalWinnerRedeemable);
           conditionInfo.totalEthClaimable =
               conditionInfo.totalEthClaimable -
               (totalWinnerRedeemable);
       }
 
       emit UserClaimed(_conditionIndex, _userAddress, totalWinnerRedeemable);
   }
 
   function getClaimAmount(
       uint256 totalPayout,
       uint256 winnersTotalETHStaked,
       uint256 userStake
   ) internal pure returns (uint256 totalWinnerRedeemable) {
       totalWinnerRedeemable =
           (totalPayout * userStake) /
           winnersTotalETHStaked;
   }
 
   function getBalance(uint256 _conditionIndex, address _user)
       external
       view
       returns (uint256 lbtBalance, uint256 hbtBalance)
   {
       ConditionInfo storage condition = conditions[_conditionIndex];
       lbtBalance = BetToken(condition.lowBetToken).balanceOf(_user);
       hbtBalance = BetToken(condition.highBetToken).balanceOf(_user);
   }
}