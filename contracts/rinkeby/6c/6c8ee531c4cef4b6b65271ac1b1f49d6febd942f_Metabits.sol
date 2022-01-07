/**
 *Submitted for verification at Etherscan.io on 2022-01-07
*/

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

pragma solidity ^0.8.0;

interface IBoars {
    function balanceOf(address _user) external view returns(uint256);
    function ownerOf(uint256 _tokenId) external view returns(address);
    function totalSupply() external view returns (uint256);
}

contract Metabits is ERC20("$Metabits", "MTB"), Ownable {
    address public angryBoarsContractAddress;
    address public angryMeerKatsContractAddress;
    address public genesisContractAddress;
    struct ContractSettings {
        uint256 baseRate;
        uint256 start;
        uint256 end;
    }

    ContractSettings public boarsContractSettings;
    ContractSettings public meerkatsContractSettings;
    ContractSettings public genesisContractSettings;
    IBoars public iBoars;
    IBoars public iMeerKats;
    IBoars public iGenesis;
    IBoars public iSymbiosis;

    // Prevents new contracts from being added or changes to disbursement if permanently locked
    bool public isLocked = false;
    mapping(bytes32 => uint256) public boarsLastClaim;
    mapping(bytes32 => uint256) public meerkatsLastClaim;
    mapping(bytes32 => uint256) public genesisLastClaim;

    event RewardPaid(address indexed user, uint256 reward);

    constructor(address _angryBoarsAddress,address _angryMeerKatsAddress,address _genesisContractAddress, uint256 _boarsBaseRate, uint256 _meerkatsBaseRate, uint256 _genesisBaseRate) {
        angryBoarsContractAddress = _angryBoarsAddress;
        angryMeerKatsContractAddress = _angryMeerKatsAddress;
        genesisContractAddress = _genesisContractAddress;
        iBoars = IBoars(angryBoarsContractAddress);
        iMeerKats = IBoars(angryMeerKatsContractAddress);
        iGenesis = IBoars(genesisContractAddress);
        // initialize contractSettings
        boarsContractSettings = ContractSettings({
        baseRate: _boarsBaseRate * 10 ** 18,
        start: 1641408173,
        end: 1672944173
        });
        meerkatsContractSettings = ContractSettings({
        baseRate: _meerkatsBaseRate  * 10 ** 18,
        start: 1641408173,
        end: 1672944173
        });
        genesisContractSettings = ContractSettings({
        baseRate: _genesisBaseRate  * 10 ** 18,
        start: 1641408173,
        end: 1672944173
        });
    }

    function setBoarsContractSettings(uint256 _baseRate, uint256 _start, uint256 _end) public onlyOwner {
        require(!isLocked, "Cannot modify end dates after lock");
        boarsContractSettings.baseRate = _baseRate  * 10 ** 18;
        boarsContractSettings.start = _start;
        boarsContractSettings.end = _end;
    }

    function setMeerkatsContractSettings(uint256 _baseRate, uint256 _start, uint256 _end) public onlyOwner {
        require(!isLocked, "Cannot modify end dates after lock");
        meerkatsContractSettings.baseRate = _baseRate  * 10 ** 18;
        meerkatsContractSettings.start = _start;
        meerkatsContractSettings.end = _end;
    }

    function setGenesisContractSettings(uint256 _baseRate, uint256 _start, uint256 _end) public onlyOwner {
        require(!isLocked, "Cannot modify end dates after lock");
        genesisContractSettings.baseRate = _baseRate  * 10 ** 18;
        genesisContractSettings.start = _start;
        genesisContractSettings.end = _end;
    }

    function claimRewardForBoar(uint256 _boarTokenId) public returns (uint256) {
        uint256 totalUnclaimedReward1 = 0;
        require(boarsContractSettings.end > block.timestamp, "Time for claiming has expired.");
        require(iBoars.ownerOf(_boarTokenId) == msg.sender, "Caller does not own the token being claimed for.");

        totalUnclaimedReward1 = computeUnclaimedRewardForBoars(_boarTokenId);

        // update the lastClaim date for tokenId and contractAddress
        bytes32 lastClaimKey = keccak256(abi.encode(_boarTokenId));
        boarsLastClaim[lastClaimKey] = block.timestamp;

        // mint the tokens and distribute to msg.sender
        _mint(msg.sender, totalUnclaimedReward1);
        emit RewardPaid(msg.sender, totalUnclaimedReward1);

        return totalUnclaimedReward1;
    }

    function claimRewardForMeerKat( uint256 _meerKatTokenId) public returns (uint256) {
        uint256 totalUnclaimedReward2 = 0;
         require(meerkatsContractSettings.end > block.timestamp, "Time for claiming has expired.");
        require(iMeerKats.ownerOf(_meerKatTokenId) == msg.sender, "Caller does not own the token being claimed for.");

        totalUnclaimedReward2 = computeUnclaimedRewardForMeerKats(_meerKatTokenId);

        // update the lastClaim date for tokenId and contractAddress
        bytes32 lastClaimMeerKatKey = keccak256(abi.encode(_meerKatTokenId));
        meerkatsLastClaim[lastClaimMeerKatKey] = block.timestamp;
        // mint the tokens and distribute to msg.sender
        _mint(msg.sender, totalUnclaimedReward2);
        emit RewardPaid(msg.sender, totalUnclaimedReward2);

        return totalUnclaimedReward2;
    }

    function claimRewardForGenesis(uint256 _genesisTokenId) public returns (uint256) {
        uint256 totalUnclaimedReward1 = 0;
        require(genesisContractSettings.end > block.timestamp, "Time for claiming has expired.");
        require(iGenesis.ownerOf(_genesisTokenId) == msg.sender, "Caller does not own the token being claimed for.");

        totalUnclaimedReward1 = computeUnclaimedRewardForGenesis(_genesisTokenId);

        // update the lastClaim date for tokenId and contractAddress
        bytes32 lastClaimKey = keccak256(abi.encode(_genesisTokenId));
        genesisLastClaim[lastClaimKey] = block.timestamp;

        // mint the tokens and distribute to msg.sender
        _mint(msg.sender, totalUnclaimedReward1);
        emit RewardPaid(msg.sender, totalUnclaimedReward1);

        return totalUnclaimedReward1;
    }

    function claimRewardsForBoars(uint256[] calldata _boarsTokenIds) public returns (uint256) {
        require(boarsContractSettings.end > block.timestamp, "Time for claiming has expired");

        uint256 totalUnclaimedReward1 = 0;

        for(uint256 i = 0; i < _boarsTokenIds.length; i++) {
            uint256 _boarsTokenId = _boarsTokenIds[i];

            require(iBoars.ownerOf(_boarsTokenId) == msg.sender, "Caller does not own the token being claimed for.");

            uint256 unclaimedReward = computeUnclaimedRewardForBoars(_boarsTokenId);
            totalUnclaimedReward1 = totalUnclaimedReward1 + unclaimedReward;

            // update the lastClaim date for tokenId and contractAddress
            bytes32 lastClaimKey = keccak256(abi.encode(_boarsTokenId));
            boarsLastClaim[lastClaimKey] = block.timestamp;
        }
        // mint the tokens and distribute to msg.sender
        _mint(msg.sender, totalUnclaimedReward1);
        emit RewardPaid(msg.sender, totalUnclaimedReward1);

        return totalUnclaimedReward1;
    }

function claimRewardsForMeerKats(uint256[] calldata _meerTokenIds) public returns (uint256) {
        require(meerkatsContractSettings.end > block.timestamp, "Time for claiming has expired");

        uint256 totalUnclaimedReward2 = 0;

        for(uint256 i = 0; i < _meerTokenIds.length; i++) {
            uint256 _meerTokenId = _meerTokenIds[i];

            require(iMeerKats.ownerOf(_meerTokenId) == msg.sender, "Caller does not own the token being claimed for.");

            uint256 unclaimedReward = computeUnclaimedRewardForMeerKats(_meerTokenId);
            totalUnclaimedReward2 = totalUnclaimedReward2 + unclaimedReward;

            // update the lastClaim date for tokenId and contractAddress
            bytes32 lastClaimKey = keccak256(abi.encode(_meerTokenId));
            meerkatsLastClaim[lastClaimKey] = block.timestamp;
        }
        // mint the tokens and distribute to msg.sender
        _mint(msg.sender, totalUnclaimedReward2);
        emit RewardPaid(msg.sender, totalUnclaimedReward2);

        return totalUnclaimedReward2;
    }

    function claimRewardsForGenesis(uint256[] calldata _genesisTokenIds) public returns (uint256) {
        require(genesisContractSettings.end > block.timestamp, "Time for claiming has expired");

        uint256 totalUnclaimedReward1 = 0;

        for(uint256 i = 0; i < _genesisTokenIds.length; i++) {
            uint256 _genesisTokenId = _genesisTokenIds[i];

            require(iGenesis.ownerOf(_genesisTokenId) == msg.sender, "Caller does not own the token being claimed for.");

            uint256 unclaimedReward = computeUnclaimedRewardForBoars(_genesisTokenId);
            totalUnclaimedReward1 = totalUnclaimedReward1 + unclaimedReward;

            // update the lastClaim date for tokenId and contractAddress
            bytes32 lastClaimKey = keccak256(abi.encode(_genesisTokenId));
            genesisLastClaim[lastClaimKey] = block.timestamp;
        }
        // mint the tokens and distribute to msg.sender
        _mint(msg.sender, totalUnclaimedReward1);
        emit RewardPaid(msg.sender, totalUnclaimedReward1);

        return totalUnclaimedReward1;
    }

    function permanentlyLock() public onlyOwner {
        isLocked = true;
    }

    function getUnclaimedRewardAmountForBoars(uint256 _tokenId) public view returns (uint256) {
        return computeUnclaimedRewardForBoars(_tokenId);
    }

        function getUnclaimedRewardAmountForMeerKats(uint256 _tokenId) public view returns (uint256) {
        return computeUnclaimedRewardForMeerKats(_tokenId);
    }

    function getUnclaimedRewardAmountForGenesis(uint256 _tokenId) public view returns (uint256) {
        return computeUnclaimedRewardForGenesis(_tokenId);
    }

    function getUnclaimedRewardsAmountForBoars(uint256[] calldata _tokenIds) public view returns (uint256) {

        uint256 totalUnclaimedRewards = 0;

        for(uint256 i = 0; i < _tokenIds.length; i++) {
            totalUnclaimedRewards += computeUnclaimedRewardForBoars(_tokenIds[i]);
        }

        return totalUnclaimedRewards;
    }

    function getUnclaimedRewardsAmountForMeerKats(uint256[] calldata _tokenIds) public view returns (uint256) {

        uint256 totalUnclaimedRewards = 0;

        for(uint256 i = 0; i < _tokenIds.length; i++) {
            totalUnclaimedRewards += computeUnclaimedRewardForMeerKats(_tokenIds[i]);
        }

        return totalUnclaimedRewards;
    }

    function getUnclaimedRewardsAmountForGenesis(uint256[] calldata _tokenIds) public view returns (uint256) {

        uint256 totalUnclaimedRewards = 0;

        for(uint256 i = 0; i < _tokenIds.length; i++) {
            totalUnclaimedRewards += computeUnclaimedRewardForGenesis(_tokenIds[i]);
        }

        return totalUnclaimedRewards;
    }

    function getTotalUnclaimedRewardsForBoarsContract() public view returns (uint256) {
        uint256 totalUnclaimedRewards = 0;
        uint256 totalSupply = iBoars.totalSupply();

        for(uint256 i = 0; i < totalSupply; i++) {
            totalUnclaimedRewards += computeUnclaimedRewardForBoars(i);
        }

        return totalUnclaimedRewards;
    }

    function getTotalUnclaimedRewardsForMeerKatsContract() public view returns (uint256) {
        uint256 totalUnclaimedRewards = 0;
        uint256 totalSupply = iMeerKats.totalSupply();

        for(uint256 i = 0; i < totalSupply; i++) {
            totalUnclaimedRewards += computeUnclaimedRewardForMeerKats(i);
        }

        return totalUnclaimedRewards;
    }

    function getTotalUnclaimedRewardsForGenesisContract() public view returns (uint256) {
        uint256 totalUnclaimedRewards = 0;
        uint256 totalSupply = iGenesis.totalSupply();

        for(uint256 i = 0; i < totalSupply; i++) {
            totalUnclaimedRewards += computeUnclaimedRewardForGenesis(i);
        }

        return totalUnclaimedRewards;
    }

    function getBoarsLastClaimedTime(uint256 _tokenId) public view returns (uint256) {

        bytes32 lastClaimKey = keccak256(abi.encode(_tokenId));

        return boarsLastClaim[lastClaimKey];
    }

    function getMeerkatsLastClaimedTime(uint256 _tokenId) public view returns (uint256) {

        bytes32 lastClaimKey = keccak256(abi.encode(_tokenId));

        return meerkatsLastClaim[lastClaimKey];
    }

    function getGenesisLastClaimedTime(uint256 _tokenId) public view returns (uint256) {

        bytes32 lastClaimKey = keccak256(abi.encode(_tokenId));

        return genesisLastClaim[lastClaimKey];
    }

    function computeAccumulatedReward(uint256 _lastClaimDate, uint256 _baseRate, uint256 currentTime) internal pure returns (uint256) {
        require(currentTime > _lastClaimDate, "Last claim date must be smaller than block timestamp");

        uint256 secondsElapsed = currentTime - _lastClaimDate;
        uint256 accumulatedReward = secondsElapsed * _baseRate / 1 days;

        return accumulatedReward;
    }

    function computeUnclaimedRewardForBoars(uint256 _tokenId) internal view returns (uint256) {

        // Will revert if tokenId does not exist
        iBoars.ownerOf(_tokenId);

        // build the hash for lastClaim based on contractAddress and tokenId
        bytes32 lastClaimKey = keccak256(abi.encode(_tokenId));
        uint256 lastClaimDate = boarsLastClaim[lastClaimKey];
        uint256 baseRate = boarsContractSettings.baseRate;

        // if there has been a lastClaim, compute the value since lastClaim
        if (lastClaimDate != uint256(0)) {
            return computeAccumulatedReward(lastClaimDate, baseRate, block.timestamp);
        }
        
        else {
            // if there has not been a lastClaim, add the initIssuance + computed value since contract startDate
            uint256 totalReward = computeAccumulatedReward(boarsContractSettings.start, baseRate, block.timestamp);

            return totalReward;
        }
    }

    function computeUnclaimedRewardForMeerKats(uint256 _tokenId) internal view returns (uint256) {

        // Will revert if tokenId does not exist
        iMeerKats.ownerOf(_tokenId);

        // build the hash for lastClaim based on contractAddress and tokenId
        bytes32 lastClaimKey = keccak256(abi.encode(_tokenId));
        uint256 lastClaimDate = meerkatsLastClaim[lastClaimKey];
        uint256 baseRate = meerkatsContractSettings.baseRate;

        // if there has been a lastClaim, compute the value since lastClaim
        if (lastClaimDate != uint256(0)) {
            return computeAccumulatedReward(lastClaimDate, baseRate, block.timestamp);
        }
        
        else {
            // if there has not been a lastClaim, add the initIssuance + computed value since contract startDate
            uint256 totalReward = computeAccumulatedReward(meerkatsContractSettings.start, baseRate, block.timestamp);

            return totalReward;
        }
    }

    function computeUnclaimedRewardForGenesis(uint256 _tokenId) internal view returns (uint256) {

        // Will revert if tokenId does not exist
        iGenesis.ownerOf(_tokenId);

        // build the hash for lastClaim based on contractAddress and tokenId
        bytes32 lastClaimKey = keccak256(abi.encode(_tokenId));
        uint256 lastClaimDate = genesisLastClaim[lastClaimKey];
        uint256 baseRate = genesisContractSettings.baseRate;

        // if there has been a lastClaim, compute the value since lastClaim
        if (lastClaimDate != uint256(0)) {
            return computeAccumulatedReward(lastClaimDate, baseRate, block.timestamp);
        }
        
        else {
            // if there has not been a lastClaim, add the initIssuance + computed value since contract startDate
            uint256 totalReward = computeAccumulatedReward(genesisContractSettings.start, baseRate, block.timestamp);

            return totalReward;
        }
    }
    
    function updateTimeForGenesis(uint256 _tokenId) external {
        require(msg.sender == address(iGenesis));
        bytes32 lastClaimKey = keccak256(abi.encode(_tokenId));
        genesisLastClaim[lastClaimKey] = block.timestamp;
    }

    function updateTimeForMetakidz1(uint256 _tokenId) external {
        require(msg.sender == address(iBoars));
        bytes32 lastClaimKey = keccak256(abi.encode(_tokenId));
        boarsLastClaim[lastClaimKey] = block.timestamp;
    }

    function updateTimeForMetakidz2(uint256 _tokenId) external {
        require(msg.sender == address(iMeerKats));
        bytes32 lastClaimKey = keccak256(abi.encode(_tokenId));
        meerkatsLastClaim[lastClaimKey] = block.timestamp;
    }

    function burn(address _from, uint256 _amount) external {
		require(msg.sender == address(iSymbiosis) || msg.sender == address(iMeerKats));
		_burn(_from, _amount);
	}
	
	function setSymbiosis(address symbiosisAddress) public onlyOwner {
	    iSymbiosis = IBoars(symbiosisAddress);
	}
    function setMeerkats(address _meerkats) public onlyOwner {
	    angryMeerKatsContractAddress = _meerkats;
        iMeerKats = IBoars(_meerkats);
	}
    function setBoars(address _boars) public onlyOwner {
	    angryBoarsContractAddress = _boars;
        iBoars =  IBoars(_boars);
	}
    function setGenesis(address _genesis) public onlyOwner {
	    genesisContractAddress = _genesis;
        iGenesis =  IBoars(_genesis);
	}
}