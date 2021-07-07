/**
 *Submitted for verification at Etherscan.io on 2021-07-07
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

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

/*
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
this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
return msg.data;
}
}

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
* We have followed general OpenZeppelin guidelines: functions revert instead
* of returning `false` on failure. This behavior is nonetheless conventional
* and does not conflict with the expectations of ERC20 applications.
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
contract ERC20 is Context, IERC20 {
mapping (address => uint256) private _balances;

mapping (address => mapping (address => uint256)) private _allowances;

uint256 private _totalSupply;

string private _name;
string private _symbol;

/**
* @dev Sets the values for {name} and {symbol}.
*
* The defaut value of {decimals} is 18. To select a different value for
* {decimals} you should overload it.
*
* All three of these values are immutable: they can only be set once during
* construction.
*/
constructor (string memory name_, string memory symbol_) {
_name = name_;
_symbol = symbol_;
}

/**
* @dev Returns the name of the token.
*/
function name() public view virtual returns (string memory) {
return _name;
}

/**
* @dev Returns the symbol of the token, usually a shorter version of the
* name.
*/
function symbol() public view virtual returns (string memory) {
return _symbol;
}

/**
* @dev Returns the number of decimals used to get its user representation.
* For example, if `decimals` equals `2`, a balance of `505` tokens should
* be displayed to a user as `5,05` (`505 / 10 ** 2`).
*
* Tokens usually opt for a value of 18, imitating the relationship between
* Ether and Wei. This is the value {ERC20} uses, unless this function is
* overloaded;
*
* NOTE: This information is only used for _display_ purposes: it in
* no way affects any of the arithmetic of the contract, including
* {IERC20-balanceOf} and {IERC20-transfer}.
*/
function decimals() public view virtual returns (uint8) {
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
function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
_transfer(sender, recipient, amount);

uint256 currentAllowance = _allowances[sender][_msgSender()];
require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
_approve(sender, _msgSender(), currentAllowance - amount);

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
_approve(_msgSender(), spender, currentAllowance - subtractedValue);

return true;
}

/**
* @dev Moves tokens `amount` from `sender` to `recipient`.
*
* This is internal function is equivalent to {transfer}, and can be used to
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
function _transfer(address sender, address recipient, uint256 amount) internal virtual {
require(sender != address(0), "ERC20: transfer from the zero address");
require(recipient != address(0), "ERC20: transfer to the zero address");

_beforeTokenTransfer(sender, recipient, amount);

uint256 senderBalance = _balances[sender];
require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
_balances[sender] = senderBalance - amount;
_balances[recipient] += amount;

emit Transfer(sender, recipient, amount);
}

/** @dev Creates `amount` tokens and assigns them to `account`, increasing
* the total supply.
*
* Emits a {Transfer} event with `from` set to the zero address.
*
* Requirements:
*
* - `to` cannot be the zero address.
*/
function _mint(address account, uint256 amount) internal virtual {
require(account != address(0), "ERC20: mint to the zero address");

_beforeTokenTransfer(address(0), account, amount);

_totalSupply += amount;
_balances[account] += amount;
emit Transfer(address(0), account, amount);
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
_balances[account] = accountBalance - amount;
_totalSupply -= amount;

emit Transfer(account, address(0), amount);
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
function _approve(address owner, address spender, uint256 amount) internal virtual {
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
* will be to transferred to `to`.
* - when `from` is zero, `amount` tokens will be minted for `to`.
* - when `to` is zero, `amount` of ``from``'s tokens will be burned.
* - `from` and `to` are never both zero.
*
* To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
*/
function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}
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
constructor () {
address msgSender = _msgSender();
_owner = msgSender;
emit OwnershipTransferred(address(0), msgSender);
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
emit OwnershipTransferred(_owner, address(0));
_owner = address(0);
}

/**
* @dev Transfers ownership of the contract to a new account (`newOwner`).
* Can only be called by the current owner.
*/
function transferOwnership(address newOwner) public virtual onlyOwner {
require(newOwner != address(0), "Ownable: new owner is the zero address");
emit OwnershipTransferred(_owner, newOwner);
_owner = newOwner;
}
}

contract BaseAuction is Ownable {

// Creator and beneficiary can (and should) be different addresses
address payable public beneficiary;
ERC20 public stableCoinContract;

// Create the structure for an actor
struct Actor {
bool allowed;
uint256 pendingReturn;
}

// Create the structure of a bid
struct Bid {
uint256 amount;
uint256 timestamp;
}

// Create the stucture of an auction
struct Auction {
uint256 auctionEndTime;
bytes32 auctionChecksum;
uint256 lowestBid;
uint256 minDecrease;
bool lowestBidSet;
bool auctionEnded;
address lowestBidder;
uint256 factorNumerator;
uint256 factorDenominator;
}

// The mapping which links auctionID to an Auction struct
mapping (bytes16 => Auction) public auctions;

// The mapping which links auctionID an address to a bid
mapping (bytes16 => mapping(address => Bid)) public bids;

// The mapping which links addresses to actors
mapping (address => Actor) actors;

// Events
event AuctionStarted(
bytes16 auctionId,
bytes32 auctionChecksum,
uint256 endTime,
uint256 minDecrease,
uint256 factorNumerator,
uint256 factorDenominator);

event LowestBidDecreased(
bytes16 auctionId,
address bidder,
uint256 lowestBid);

event AuctionEnded(
bytes16 auctionId,
address winner,
uint256 lowestBid);

event ActorAdded(address actorAddress);
event ActorRemoved(address actorAddress);
event stableCoinContractUpdated(address stableCoinContract);

function _addActor(address _allowedAddress) internal returns (bool) {

Actor storage act = actors[_allowedAddress];
act.allowed = true;

emit ActorAdded(_allowedAddress);

return true;

}

function _removeActor(address _deniedAddress) internal returns (bool) {

Actor storage act = actors[_deniedAddress];
act.allowed = false;

emit ActorRemoved(_deniedAddress);

return true;

}

function _setStableCoinContract(address _newContractAddress) internal returns (bool) {

ERC20 candidateContract = ERC20(_newContractAddress);
stableCoinContract = candidateContract;

emit stableCoinContractUpdated(_newContractAddress);

return true;

}

modifier onlyAllowed(){

Actor storage act = actors[msg.sender];
require(act.allowed, "Only actors on the whitelist may interact with this contract.");
_;

}

}

contract InvoluteBaseAuctionInteraction is BaseAuction {

function _createAuction(bytes16 _auctionId,
bytes32 _auctionChecksum,
uint256 _biddingTime,
uint256 _minDecrease,
uint256 _factorNumerator,
uint256 _factorDenominator) internal returns(bool) {

require(_biddingTime == uint256(uint128(_biddingTime)));
require(_minDecrease == uint256(uint128(_minDecrease)));
require(_factorNumerator == uint256(uint128(_factorNumerator)));
require(_factorDenominator == uint256(uint128(_factorDenominator)));
require(_factorDenominator != 0);

Auction storage a = auctions[_auctionId];
require(a.auctionEndTime == 0, "Auction already started.");

a.auctionEndTime = block.timestamp + _biddingTime;
a.auctionChecksum = _auctionChecksum;
a.lowestBidSet = false;
a.auctionEnded = false;
a.minDecrease = _minDecrease;
a.factorNumerator = _factorNumerator;
a.factorDenominator = _factorDenominator;

emit AuctionStarted(
_auctionId,
a.auctionChecksum,
a.auctionEndTime,
a.minDecrease,
a.factorNumerator,
a.factorDenominator);

return true;

}

function _bid(bytes16 _auctionId, uint256 _amount) internal returns(bool) {

Auction storage a = auctions[_auctionId];

require(a.auctionEndTime > 0, "Auction not known.");
require(block.timestamp <= a.auctionEndTime, "Auction already ended.");
require(!a.lowestBidSet || _amount < (a.lowestBid - a.minDecrease),
"There already is a lower bid set or the minimum decrease requirement is not met.");

stableCoinContract.transferFrom(msg.sender, address(this), _amount * a.factorNumerator / a.factorDenominator);

Actor storage act = actors[msg.sender];

// Add current lowest bid to pending returns
if (a.lowestBidSet && a.lowestBid != 0) {
act.pendingReturn += a.lowestBid * a.factorNumerator / a.factorDenominator;
}

// Set the new lowest bid
a.lowestBidSet = true;
a.lowestBidder = msg.sender;
a.lowestBid = _amount;

bids[_auctionId][msg.sender].timestamp = block.timestamp;
bids[_auctionId][msg.sender].amount = _amount;


emit LowestBidDecreased(_auctionId, msg.sender, _amount);

return true;

}

function _withdraw() internal returns(bool) {

Actor storage act = actors[msg.sender];

uint256 amount = act.pendingReturn;
require(amount > 0, "Amount has to be more than 0.");

if (amount > 0) {

act.pendingReturn = 0;
if(!stableCoinContract.transfer(msg.sender, amount)){

act.pendingReturn = amount;
return false;

}

}
return true;
}

function _endAuction(bytes16 _auctionId) internal returns(bool) {

Auction storage a = auctions[_auctionId];

// 1. Requiremetns
require(a.auctionEndTime > 0, "Auction not known.");
require(block.timestamp >=  a.auctionEndTime, "Auction not yet ended.");
require(!a.auctionEnded, "auctionEnd has already been called.");

// 2. Effects
a.auctionEnded = true;
emit AuctionEnded(_auctionId, a.lowestBidder, a.lowestBid);

// 3. Interaction
stableCoinContract.transfer(beneficiary, a.lowestBid * a.factorNumerator / a.factorDenominator);

return true;

}

}

/// @title Involute Downward Auction Contract
/// @author Involute B.V.
/// @notice This contracts handles the downwards auctions of the Involute platform
contract InvoluteDownwardAuction is InvoluteBaseAuctionInteraction {

/// @notice Initializes the contract
/// @dev The earlier loaded contact classes also define the owner as the address that generates the contract
/// @param _beneficiary The auctions beneficiary, cannot be equal to the creator of the contract
/// @param _stableCoinContract The initial stablecoin address to link the auctions to
constructor(address _beneficiary, address _stableCoinContract) {

require(msg.sender != _beneficiary, "The beneficiary should differ from the creator, for security reasons.");
require(_stableCoinContract != address(0), "The stablecoin contract can not be the 0 contract");

beneficiary = payable(_beneficiary);
_setStableCoinContract(_stableCoinContract);


}

/// @notice Let the contract owner create auctions. The variables _factorNumerator and _factorDenominator will be
/// applied to the bids for the transfer of amounts only. The bids will be defined in monthly payable sums for the
/// service (e.g. insurance or energy). Example: for a bid of 1000, a _factorNumerator of 2 and a _factorDenominator
/// of 5 the bid will be represented by 1000, the actual withdrawn funds are 1000 * 2 / 5 = 400
/// @param _auctionId The GUID of the auction
/// @param _auctionChecksum The amount of stablecoin units to bid
/// @param _biddingTime The time in seconds that an auction is open to take in bids
/// @param _minDecrease The minimum decrease, compared to the current lowest bid, in units of the stableCoinContract
/// @param _factorNumerator The numerator which is used to multiply bids with before withdrawl
/// @param _factorDenominator The denominator which is used to multiply bids with before withdrawl
/// @return bool which represents true for successful creation, false otherwise
function createAuction(bytes16 _auctionId,
bytes32 _auctionChecksum,
uint256 _biddingTime,
uint256 _minDecrease,
uint256 _factorNumerator,
uint256 _factorDenominator) onlyOwner external returns(bool) {

return _createAuction(
_auctionId,
_auctionChecksum,
_biddingTime,
_minDecrease,
_factorNumerator,
_factorDenominator);

}

/// @notice Allows the owner of the contract to add actors to the contract which can place bids
/// @param _allowedAddress The address of the actor to be allowed
/// @return bool which represents true for successful addition, false otherwise
function addActor(address _allowedAddress) onlyOwner external returns(bool) {
return _addActor(_allowedAddress);
}

/// @notice Allows the owner of the contract to remove actors to the contract
/// @param _deniedAddress The address of the actor to be removed from the list of allowed addresses
/// @return bool which represents true for successful removal, false otherwise
function removeActor(address _deniedAddress) onlyOwner external returns(bool) {
return _removeActor(_deniedAddress);
}

/// @notice Lets the owner of the contract change the stablecoin contract in which the actors can bid
/// @param _stableCoinContract the address of the new stablecoin contract
/// @return bool which represents true for successful change of the contract, false otherwise
function setStableCoinContract(address _stableCoinContract) onlyOwner external returns(bool) {
return _setStableCoinContract(_stableCoinContract);
}

/// @notice Let allowed actors place a bid
/// @param _auctionId The GUID of the auction
/// @param _amount The amount of stablecoin units to bid
/// @return bool which represents true for successful bid, false otherwise
function bid(bytes16 _auctionId, uint256 _amount) onlyAllowed external returns(bool) {
return _bid(_auctionId, _amount);
}

/// @notice Let addresses withdraw funds
/// @dev All addresses are allowed to call this function, as they can be removed from the allowed list
/// and still have funds left
/// @return bool which represents true for successful withdrawl, false otherwise
function withdraw() external returns(bool){
return _withdraw();
}

/// @notice Let all addresses end an auction
/// @dev sends the funds to the beneficiary address
/// @param _auctionId The auction to end
function endAuction(bytes16 _auctionId) external returns(bool){
return _endAuction(_auctionId);
}

}