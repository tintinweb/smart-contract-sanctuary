//Arkius Public Benefit Corporation Privileged & Confidential
// SPDX-License-Identifier: None
pragma solidity 0.8.0;

import "./interfaces/IERC20Metadata.sol";
import "./utils/Ownable.sol";

contract ArkiusGovernanceToken is Ownable, IERC20Metadata {

    /**
     * @notice structure for storing the snapshots
     */
    struct Snapshot {
        uint128  blockNumber;
        uint256  value;
        uint128  timestamp;
    }

    /**
     * @dev contains the mapping from userAddress => snapshotCount => Snapshot(structure)
     *
     */
    mapping(address => mapping(uint256 => Snapshot)) public snapshots;

    /**
     * @dev Keeps track of the latest snapshot taken by the user.
     */
    mapping(address => uint256) private countsSnapshots;

    /**
     * @dev holds the balance of every user.
     */
    mapping(address => uint256) private balances;

    /**
     * @dev holds the locked balance of every user.
     */
    mapping(address => uint256) private lockedBalances;

    /**
     * @dev Addresses which belong to arkius are true.
     */
    mapping(address => bool) private arkiusValidated;

    /**
     * @dev ACCOUNT owner alot some tokens to another user(spender),
     * so spender can use token of Account owner, and thus reducing
     * a transaction of transferring tokens.
     */
    mapping(address => mapping (address => uint256)) private allowances;

    // {m_totalSupply} holds  the total amount of tokens minted so far.
    uint256 private _totalSupply;

    // {c_name} contains the name of the token.
    string constant private _name = "Arkius Governance Token";

    // {c_symbol} contains the symbol of the token.
    string constant private _symbol = "AGT";

    // tokenManager Only tokenManager can call the functions of this contract.
    address private _tokenManager;

    /**
     * Emitted when the `sender` set the `account` as token Manager
     */
    event SetManager(address indexed sender, address indexed account);

    /**
     * Emitted when the `sender` set the `account` as valid or invalid `value`.
     */
    event AddressValidated(address indexed sender, address indexed account, bool indexed value);

    /**
     * Emitted when `owner` takes the Snapshot.
     *
     * Notice:- `owner` is referred to the msg.sender and
     * not to the owner of the contract.
     */
    event SnapshotDone(address indexed owner, uint256 indexed balance, uint128 indexed timestamp);

    /**
     * @dev Checks if the function caller is
     * a tokenManager or not.
     *
     * if not then revert the function.
     */
    modifier onlyTokenManager() {
        require(_msgSender() == _tokenManager, 'Caller is not Token Manager');
        _;
    }

    constructor(address multisigAddress) Ownable(multisigAddress) {
        
    }

    /**
     * @dev Returns the name of the token.
     * @return name returns the name of the token
     */
    function name() public pure override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public pure override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public pure override returns (uint256) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Total balance of 'account', including locked and unlocked balance.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return balances[account];
    }

    /**
     * @dev Locked balance of 'account'.
     */
    function lockedBalanceOf(address account) external view override returns (uint256) {
        return lockedBalances[account];
    }

    /**
     * @dev Unlocked balance of 'account'.
     */
    function unlockedBalanceOf(address account) external view returns (uint256) {
        return balances[account] - lockedBalances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount, false);
        return true;
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transferUnlock(address recipient, uint256 amount) external override returns (bool) {
        require(arkiusValidated[_msgSender()], "Invalid sender address.");
        _transfer(_msgSender(), recipient, amount, true);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view override returns (uint256) {
        return allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public override returns (bool) {
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
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount, false);

        uint256 currentAllowance = allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

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
    function transferFromUnlock(address sender, address recipient, uint256 amount) external override returns (bool) {
        require(arkiusValidated[sender], "Invalid sender address.");
        _transfer(sender, recipient, amount, true);

        uint256 currentAllowance = allowances[sender][_msgSender()];
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
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        _approve(_msgSender(), spender, allowances[_msgSender()][spender] + addedValue);
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
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {

        uint256 currentAllowance = allowances[_msgSender()][spender];

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
    function _transfer(address sender, address recipient, uint256 amount, bool unlock) internal {

        require(sender    != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance         = balances[sender];
        uint256 senderLockedBalance   = lockedBalances[sender];

        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");

        //If the recipient is an Arkius address, it can receive locked tokens as it is.
        //If amount to be transferred is greater than locked balance, then the unlocked amount will be transferred.
        if((arkiusValidated[recipient] && !unlock) || (arkiusValidated[sender] && !unlock)){
            balances[sender]    = senderBalance - amount;
            balances[recipient] = balances[recipient] + amount;

            if(amount>senderLockedBalance){
                amount = senderLockedBalance;
            }

            lockedBalances[sender]    = senderLockedBalance - amount;
            lockedBalances[recipient] = lockedBalances[recipient] + amount;
        }

        //If the sender is an Arkius address, the recipient gets the tokens unlocked and locked tokens are burnt.
        else if(arkiusValidated[sender]){

            balances[sender]    = senderBalance - amount;
            balances[recipient] = balances[recipient] + amount;

            if(amount>senderLockedBalance){
                lockedBalances[sender] = 0;
            }
            else{
                lockedBalances[sender] = senderLockedBalance - amount;
            }
        }
        //If it is a normal transaction, users can only transfer unlocked tokens.
        else {
            require(senderBalance - lockedBalances[sender]>=amount, "ERC20: Not enough unlocked balance.");
            balances[sender]    = senderBalance - amount;
            balances[recipient] = balances[recipient] - amount;
        }

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * This internal function is equivalent to `mint`, and can be used to
     * e.g. generate (mint) new tokens.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        require(amount   > 0, "Zero Token can't be minted");

        // _beforeTokenTransfer(address(0), account, amount);

        _totalSupply            = _totalSupply + amount;
        balances[account]       = balances[account] + amount;
        lockedBalances[account] = lockedBalances[account] + amount;

        emit Transfer(address(0), account, amount);
    }

    /** @dev Creates `amount` locked tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *      - `to` cannot be the zero address.
     */

    function mint(address account, uint256 amount) external override onlyTokenManager {
        _mint(account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * This internal function is equivalent to `burn`, and can be used to
     * e.g. destroy (burn) the tokens by sending them at address 0x00..
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        // _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance  = balances[account];
        uint256 lockedAccountBalance  = lockedBalances[account];

        require(accountBalance - lockedAccountBalance >= amount, "ERC20: burn amount exceeds unlocked balance");

        balances[account]     = accountBalance - amount;
        _totalSupply          = _totalSupply - amount;

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Destroys `amount` unlocked tokens from `account`, reducing the
     * total supply.
     *
     * This internal function is equivalent to `burn`, and can be used to
     * e.g. destroy (burn) the tokens by sending them at address 0x00..
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function burn(address account, uint256 amount) external override onlyTokenManager {
        _burn(account, amount);
    }

    /**
     * @dev sets the `account` as the tokenManager.
     * Give access to `account` to operate the function
     * of the token Contract.
     *
     * @param account Address of the tokenManager
     *
     * Emits the {SetManager} event.
     */
    function setTokenManager(address account) external onlyOwner {
        require(account != address(0), "Invalid address.");
        _tokenManager = account;
        emit SetManager(_msgSender(), account);
    }

    /**
     * @dev sets the `account` as a valid recipient of locked balances.
     *
     * @param account Address to be validated.
     * @param value   value to be set (true:valid, false:invalid).
     *
     * Emits the {AddressValidated} event.
     */
    function setAddressValidation(address account, bool value) external onlyOwner {
        arkiusValidated[account] = value;
        emit AddressValidated(_msgSender(), account, value);
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
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner   != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }


    /**
     * @dev Writes a snapshot for the caller.
     * @notice It captures the balance of the caller
     *         and the timestamp at which the function is called.
     * Emits an {Snapshot} event.
     */
    function writeSnapshot() external {
        uint128 currentBlock      = uint128(block.number);
        uint256 balanceAtSnapshot = balanceOf(_msgSender());
        uint128 timestamp         = uint128(block.timestamp);

        uint256 count = 0;

        uint256 ownerCountOfSnapshots = countsSnapshots[_msgSender()];

        mapping(uint256 => Snapshot) storage snapshotsOwner = snapshots[_msgSender()];

        if (ownerCountOfSnapshots > 0) {
            count = ownerCountOfSnapshots - 1;
        }

        // Doing multiple operations in the same block (If new snapshot is in the same block as previous then updating the value)
        if (ownerCountOfSnapshots != 0 && snapshotsOwner[count].blockNumber == currentBlock) {

            snapshotsOwner[count].value     = balanceAtSnapshot;
            snapshotsOwner[count].timestamp = timestamp;
        } else {
            snapshotsOwner[ownerCountOfSnapshots] = Snapshot(currentBlock, balanceAtSnapshot, timestamp);
            countsSnapshots[_msgSender()]       = ownerCountOfSnapshots + 1;
        }

        emit SnapshotDone(_msgSender(), balanceAtSnapshot, timestamp);
    }

    function lastSnapshot(address add) external view returns(uint256) {
        return countsSnapshots[add];
    }

    function tokenManager() external view returns(address) {
        return _tokenManager;
    }

    function isValidatedAddress(address addr) external view returns(bool) {
        return arkiusValidated[addr];
    }
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "./IERC20.sol";

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
    function decimals() external view returns (uint256);
}

//SPDX-License-Identifier:None
pragma solidity 0.8.0;

import './Context.sol';

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;
    address private _nominatedOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OwnershipNominated(address indexed previousOwner, address indexed newOwner);
    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor (address multisig) {
        _owner = multisig;
        emit OwnershipTransferred(address(0), multisig);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() external view returns (address) {
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
    function renounceOwnership() external onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Nominate new Owner of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function nominateNewOwner(address newOwner) external onlyOwner {
        _nominatedOwner = newOwner;
        emit OwnershipNominated(_owner,newOwner);
    }

    /**
     * @dev Nominated Owner can accept the Ownership of the contract.
     * Can only be called by the nominated owner.
     */
    function acceptOwnership() external {
        require(msg.sender == _nominatedOwner, "Ownable: You must be nominated before you can accept ownership");
        emit OwnershipTransferred(_owner, _nominatedOwner);
        _owner = _nominatedOwner;
        _nominatedOwner = address(0);
    }
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

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
     * @dev Returns the amount of locked tokens owned by `account`.
     */
    function lockedBalanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`, and unlocks it.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferUnlock(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance. The amount is also unlocked.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFromUnlock(address sender, address recipient, uint256 amount) external returns (bool);
    
    /**
     * @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     * Emits a {Transfer} event with `from` set to the zero address.
     */
    function mint(address account, uint256 amount) external;

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     */
    function burn(address account, uint256 amount) external;

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

//SPDX-License-Identifier:None
pragma solidity 0.8.0;

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
abstract contract Context {

    /// Empty constructor, to prevent people from mistakenly deploying
    /// an instance of this contract, which should be used via inheritance.

    constructor () { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {

        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}