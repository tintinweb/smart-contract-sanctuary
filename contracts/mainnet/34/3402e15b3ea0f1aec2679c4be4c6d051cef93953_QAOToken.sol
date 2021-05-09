/**
 *Submitted for verification at Etherscan.io on 2021-05-08
*/

// Sources flattened with hardhat v2.2.1 https://hardhat.org

// File openzeppelin-solidity/contracts/token/ERC20/[email protected]

// SPDX-License-Identifier: MIT

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


// File openzeppelin-solidity/contracts/utils/[email protected]



pragma solidity ^0.8.0;

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


// File contracts/ERC20Customized.sol



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
        _balances[address(0)] = _balances[address(0)] + amount;

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


// File contracts/ERC20BurnableCustomized.sol



pragma solidity ^0.8.0;


/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        _approve(account, _msgSender(), currentAllowance - amount);
        _burn(account, amount);
    }
}


// File openzeppelin-solidity/contracts/access/[email protected]



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


// File contracts/QAOToken.sol

pragma solidity 0.8.1;


contract QAOToken is ERC20Burnable, Ownable {

    uint256 private constant DAY_IN_SEC = 86400;
    uint256 private constant DIV_ACCURACY = 1 ether;

    uint256 public constant DAILY_MINT_AMOUNT = 100000000 ether;
    uint256 public constant ANNUAL_TREASURY_MINT_AMOUNT = 1000000000000 ether;
    uint256 private _mintMultiplier = 1 ether;

    uint256 private _mintAirdropShare = 0.45 ether;
    uint256 private _mintLiqPoolShare = 0.45 ether;
    uint256 private _mintApiRewardShare = 0.1 ether;

    /* by default minting will be disabled */
    bool private mintingIsActive = false;

    /* track the total airdrop amount, because we need a stable value to avoid fifo winners on withdrawing airdrops */
    uint256 private _totalAirdropAmount;

    /* timestamp which specifies when the next mint phase should happen */
    uint256 private _nextMintTimestamp;

    /* treasury minting and withdrawing variables */
    uint256 private _annualTreasuryMintCounter = 0; 
    uint256 private _annualTreasuryMintTimestamp = 0;
    address private _treasuryGuard;
    bool private _treasuryLockGuard = false;
    bool private _treasuryLockOwner = false;

    /* pools */
    address private _airdropPool;
    address private _liquidityPool;
    address private _apiRewardPool;

    /* voting engine */
    address private _votingEngine;


    constructor( address swapLiqPool, address treasuryGuard) ERC20("QAO", unicode"🌐") {

        _mint(swapLiqPool, 9000000000000 ether);

        _treasuryGuard = treasuryGuard;
        _annualTreasuryMint();
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _applyMintSchedule();
        _annualTreasuryMint();
        return ERC20.transfer(recipient, amount);
    }

    /*******************************************************************
     * Standard minting functionality
     *******************************************************************/

    /* turn on minting. make sure you specified the addresses of the receiving pools first */
    function activateMinting() public onlyOwner {
        require(!mintingIsActive, "QAO Token: Minting has already been activated");
        require(_airdropPool != address(0), "QAO Token: Please specify the address of the airdrop pool before activating minting.");
        require(_liquidityPool != address(0), "QAO Token: Please specify the address of the liquidity pool before activating minting.");
        require(_apiRewardPool != address(0), "QAO Token: Please specify the address of the api reward pool before activating minting.");

        mintingIsActive = true;
        _mintToPools();
        _nextMintTimestamp = block.timestamp + DAY_IN_SEC;
    }

    /* apply minting for the current day and reprocess any missed day */
    function _applyMintSchedule() private {
        if (mintingIsActive){
            while (block.timestamp >= _nextMintTimestamp){
                _mintToPools();
                _nextMintTimestamp = _nextMintTimestamp + DAY_IN_SEC;
            }
        }
    }

    /* calculate minting supply for each pool and mint tokens to them */
    function _mintToPools() private {
        uint256 totalMintAmount = (DAILY_MINT_AMOUNT * _mintMultiplier) / DIV_ACCURACY;
        uint256 airdropAmount = (totalMintAmount * _mintAirdropShare) / DIV_ACCURACY;
        uint256 liqPoolAmount = (totalMintAmount * _mintLiqPoolShare) / DIV_ACCURACY;
        uint256 apiRewardAmount = (totalMintAmount * _mintApiRewardShare) / DIV_ACCURACY;

        _mint(_airdropPool, airdropAmount);
        _mint(_liquidityPool, liqPoolAmount);
        _mint(_apiRewardPool, apiRewardAmount);
    }

    /* Get amount of days passed since the provided timestamp */
    function _getPassedDays(uint256 timestamp) private view returns (uint256) {
        uint256 secondsDiff = block.timestamp - timestamp;
        return (secondsDiff / DAY_IN_SEC);
    }

    /*******************************************************************
     * Treasury functionality
     *******************************************************************/
    function _annualTreasuryMint() private {
        if (block.timestamp >= _annualTreasuryMintTimestamp && _annualTreasuryMintCounter < 4) {
            _annualTreasuryMintTimestamp = block.timestamp + (365 * DAY_IN_SEC);
            _annualTreasuryMintCounter = _annualTreasuryMintCounter + 1;
            _mint(address(this), ANNUAL_TREASURY_MINT_AMOUNT);
        }
    }

    function unlockTreasuryByGuard() public {
        require(_msgSender() == _treasuryGuard, "QAO Token: You shall not pass!");
        _treasuryLockGuard = true;
    }
    function unlockTreasuryByOwner() public onlyOwner {
        _treasuryLockOwner = true;
    }

    function withdrawFromTreasury(address recipient, uint256 amount) public onlyOwner {
        require(_treasuryLockGuard && _treasuryLockOwner, "QAO Token: Treasury is not unlocked.");
        _transfer(address(this), recipient, amount);
        _treasuryLockGuard = false;
        _treasuryLockOwner = false;
    }

    /*******************************************************************
     * Voting engine support functionality
     *******************************************************************/
    function setVotingEngine(address votingEngineAddr) public onlyOwner {
        _votingEngine = votingEngineAddr;
    }

    function votingEngine() public view returns (address) {
        return _votingEngine;
    }

    function mintVoteStakeReward(uint256 amount) public {
        require(_votingEngine != address(0), "QAO Token: Voting engine not set.");
        require(_msgSender() == _votingEngine, "QAO Token: Only the voting engine can call this function.");
        _mint(_votingEngine, amount);
    }

    /*******************************************************************
     * Getters/ Setters for mint multiplier
     *******************************************************************/ 
    function mintMultiplier() public view returns (uint256) {
        return _mintMultiplier;
    }
    function setMintMultiplier(uint256 newMultiplier) public onlyOwner {
        require(newMultiplier < _mintMultiplier, "QAO Token: Value of new multiplier needs to be lower than the current one.");
        _mintMultiplier = newMultiplier;
    }

    /*******************************************************************
     * Getters/ Setters for minting pools
     *******************************************************************/  
    function airdropPool() public view returns (address){
        return _airdropPool;
    }
    function setAirdropPool(address newAddress) public onlyOwner {
        require(newAddress != address(0), "QAO Token: Address Zero cannot be the airdrop pool.");
        _airdropPool = newAddress;
    }

    function liquidityPool() public view returns (address){
        return _liquidityPool;
    }
    function setLiquidityPool(address newAddress) public onlyOwner {
        require(newAddress != address(0), "QAO Token: Address Zero cannot be the liquidity pool.");
        _liquidityPool = newAddress;
    }

    function apiRewardPool() public view returns (address){
        return _apiRewardPool;
    }
    function setApiRewardPool(address newAddress) public onlyOwner {
        require(newAddress != address(0), "QAO Token: Address Zero cannot be the reward pool.");
        _apiRewardPool = newAddress;
    }

    /*******************************************************************
     * Getters/ Setters for minting distribution shares
     *******************************************************************/
    function mintAirdropShare() public view returns (uint256){
        return _mintAirdropShare;
    }
    function setMintAirdropShare(uint256 newShare) public onlyOwner {
        require((newShare + _mintLiqPoolShare + _mintApiRewardShare) <= 1 ether, "QAO Token: Sum of mint shares is greater than 100%.");
        _mintAirdropShare = newShare;
    }

    function mintLiqPoolShare() public view returns (uint256){
        return _mintLiqPoolShare;
    }
    function setMintLiqPoolShare(uint256 newShare) public onlyOwner {
        require((newShare + _mintAirdropShare + _mintApiRewardShare) <= 1 ether, "QAO Token: Sum of mint shares is greater than 100%.");
        _mintLiqPoolShare = newShare;
    }

    function mintApiRewardShare() public view returns (uint256){
        return _mintApiRewardShare;
    }
    function setMintApiRewardShare(uint256 newShare) public onlyOwner {
        require((newShare + _mintAirdropShare + _mintLiqPoolShare) <= 1 ether, "QAO Token: Sum of mint shares is greater than 100%.");
        _mintApiRewardShare = newShare;
    }
}