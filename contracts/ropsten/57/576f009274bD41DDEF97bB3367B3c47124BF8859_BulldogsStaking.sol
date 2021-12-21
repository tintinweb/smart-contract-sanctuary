/**
 *Submitted for verification at Etherscan.io on 2021-12-20
*/

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

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

// File: v2/staking.sol



pragma solidity ^0.8.9;




/*
    Interfaces for Bohemian Bulldogs service Smart Contracts
*/
interface TokenContract {
    function allowanceFor(address spender) external view returns(uint256);
    function transfer(address _to, uint256 _value) external returns(bool);
    function balanceOf(address owner) external view returns(uint);
    function _burn(address account, uint256 amount) external;
}

interface NFTContract {
    function ownerOf(uint256 _tokenId) external view returns (address);
    function transferFrom(address from, address to, uint tokenId) external payable;
}
/*
    End of interfaces
*/


contract BulldogsStaking is ReentrancyGuard {

    //// Events
    event _adminSetCollectionEarnRate(uint collectionId, uint _earnRate);
    event _adminSetCollectionSwapCost(uint collectionId, uint _swapRate);
    event _adminSetTokensCollections(uint[] _tokenIds, uint _collectionId);
    event _adminSetBonus(address[] _address, uint amount);
    event _adminAddBonus(address[] _address, uint amount);

    event _userSetTokenCollection(uint _tokenId, uint _collectionId);
    event _setTokenContract(address _address);
    event _setNFTContract(address _address);

    event Staked(uint tokenId);
    event Unstaked(uint256 tokenId);
    event BBonesClaimed(address _address, uint amount);
    event bulldogUpgraded(uint tokenId);
    event bulldogSwapped(uint tokenId);

    // Base variables
    address private _owner;
    address private _tokenContractAddress;
    address private _nftContractAddress;

    // Minimal period before you can claim $BBONES, in blocks
    uint minStakingPeriod = 1;

    // Freeze after which you can claim and unstake, in blocks
    uint freezePeriod = 10;

    /* Data storage:
         Collections:
           1 - Street
           2 - Bohemian
           3 - Boho
           4 - Business
           5 - Business Smokers
           6 - Capsule
    */

    // tokenId -> collectionId
    mapping(uint => uint) public tokensData;

    // collectionId -> minStakingPeriod earn rate
    mapping(uint => uint) public earnRates;

    // collectionId -> upgradeability cost in $BBONES to the next one
    mapping(uint => uint) public upgradeabilityCost;

    // collectionId -> swapping cost in $BBONES, for interchange your NFT inside the same collection
    mapping(uint => uint) public swappingCost;

    // list of those, who tried to scam us. you'll regret.
    mapping(address => bool) public scammersList;

    // list of claimable bonuses
    mapping(address => uint) public bonuses;

    struct Staker {
        // list of staked tokenIds
        uint[] stakedTokens;

        // tokenId -> blockNumber
        mapping(uint => uint) tokenStakeBlock;
    }

    mapping(address => Staker) private stakeHolders;


    constructor () {
        _owner = msg.sender;

        earnRates[1] = 50;
        earnRates[2] = 100;
        earnRates[3] = 400;
        earnRates[4] = 1200;
        earnRates[5] = 1800;
        earnRates[6] = 0;

        upgradeabilityCost[1] = 100;
        upgradeabilityCost[2] = 400;
        upgradeabilityCost[3] = 2400;
        upgradeabilityCost[4] = 4800;

        swappingCost[1] = 50;
        swappingCost[2] = 200;
        swappingCost[3] = 1200;
        swappingCost[4] = 2400;
        swappingCost[5] = 3200;
    }


    /*
      Modifiers
    */
    modifier onlyOwner {
        require(msg.sender == _owner || msg.sender == address(this), "You're not owner");
        _;
    }

    modifier staked(uint tokenId)  {
         require(stakeHolders[msg.sender].tokenStakeBlock[tokenId] != 0, "You have not staked this token");
        _;
    }

    modifier notStaked(uint tokenId) {
        require(stakeHolders[msg.sender].tokenStakeBlock[tokenId] == 0, "You have already staked this token");
        _;
    }

    modifier freezePeriodPassed(uint tokenId) {
        uint blockNum = stakeHolders[msg.sender].tokenStakeBlock[tokenId];
        require(blockNum + freezePeriod <= block.number, "This token is freezed, try again later");
        _;
    }

    modifier ownerOfToken(uint tokenId) {
        require(msg.sender == NFTContract(_nftContractAddress).ownerOf(tokenId) || stakeHolders[msg.sender].tokenStakeBlock[tokenId] > 0, "You are not owner of this token");
        _;
    }
    /*
      End of modifiers
    */



    /*
      Storage-related functions
    */
    // Set/reset collection's earn rate
    function adminSetCollectionEarnRate(uint collectionId, uint _earnRate) external onlyOwner {
        earnRates[collectionId] = _earnRate;
        emit _adminSetCollectionEarnRate(collectionId, _earnRate);
    }

    // Set/reset collection's swap rate
    function adminSetCollectionSwapCost(uint collectionId, uint _swapCost) external onlyOwner {
        swappingCost[collectionId] = _swapCost;
        emit _adminSetCollectionSwapCost(collectionId, _swapCost);
    }

    // Set/reset token's earn rate
    function adminSetTokensCollections(uint[] memory _tokenIds, uint _collectionId) external onlyOwner {
        for (uint i=0; i < _tokenIds.length; i++) {
            tokensData[_tokenIds[i]] = _collectionId;
        }
        emit _adminSetTokensCollections(_tokenIds, _collectionId);
    }

    // Set bonuses to wallets
    function adminSetBonus(address[] memory _address, uint amount) onlyOwner external {
        for (uint i=0; i < _address.length; i++) {
            bonuses[_address[i]] = amount;
        }
        emit _adminSetBonus(_address, amount);
    }

    // Add bonuses to wallets
    function adminAddBonus(address[] memory _address, uint amount) onlyOwner public {
        for (uint i=0; i < _address.length; i++) {
            bonuses[_address[i]] += amount;
        }
        emit _adminAddBonus(_address, amount);
    }

    // Setting/removing scammer
    function adminManageScammers(address[] memory scammers) onlyOwner external {
        for (uint i=0; i < scammers.length; i++) {
            scammersList[scammers[i]] = !scammersList[scammers[i]];
        }
    }

    function userSetTokenCollection(uint _tokenId, uint _collectionId) internal {
        tokensData[_tokenId] = _collectionId;
        emit _userSetTokenCollection(_tokenId, _collectionId);
    }
    /*
       End of storage-related functions
    */



    /*
       Setters
    */
    function setTokenContract(address _address) public onlyOwner {
        _tokenContractAddress = _address;
        emit _setTokenContract(_address);
    }

    function setNFTContract(address _address) public onlyOwner {
        _nftContractAddress = _address;
        emit _setNFTContract(_address);
    }
    /*
       End of setters
    */



    /*
       Getters
    */

    // In how many blocks token can be unstaked
    function getBlocksTillUnfreeze(uint tokenId) public view returns(uint) {
        uint blocksPassed = block.number - stakeHolders[msg.sender].tokenStakeBlock[tokenId];
        if (blocksPassed >= freezePeriod) {
            return 0;
        }
        return freezePeriod - blocksPassed;
    }

    // Test function
    function aaaa() public view returns(uint) {
        return block.number;
    }

    function getTokenEarnRate(uint _tokenId) public view returns(uint tokenEarnRate) {
        return earnRates[tokensData[_tokenId]];
    }

    // Get token's unrealized pnl
    function getTokenUPNL(uint tokenId) public view returns(uint) {

        if (stakeHolders[msg.sender].tokenStakeBlock[tokenId] == 0) {
            return 0;
        }

        uint tokenBlockDiff = block.number - stakeHolders[msg.sender].tokenStakeBlock[tokenId];
        
        // Token has to be staked minimum number of blocks
        if (tokenBlockDiff >= minStakingPeriod && stakeHolders[msg.sender].tokenStakeBlock[tokenId] + freezePeriod <= block.number) {
            uint quotient;
            uint remainder;
            
            // if enough blocks have passed to get at least 1 payout => proceed
            (quotient, remainder) = superDivision(tokenBlockDiff, minStakingPeriod);
            if (quotient > 0) {
                uint blockRate = getTokenEarnRate(tokenId);
                uint tokenEarnings = blockRate * quotient;
                return tokenEarnings;

            }
        }
        return 0;
    }

    // Returns total unrealized pnl
    function getTotalUPNL() public view returns(uint) {
        uint totalUPNL = 0;

        uint tokensCount = stakeHolders[msg.sender].stakedTokens.length;
        for (uint i = 0; i < tokensCount; i++) {
            totalUPNL += getTokenUPNL(stakeHolders[msg.sender].stakedTokens[i]);
        }
        return totalUPNL;
    }

    /*
       End of getters
    */



    /*
       Staking functions
    */
    function stake(uint tokenId, uint tokenCollection) public nonReentrant ownerOfToken(tokenId) notStaked(tokenId) {
        // Setting token's collection if it wasn't set
        if (tokensData[tokenId] == 0) {
            userSetTokenCollection(tokenId, tokenCollection);
        }

        // Checking bulldog's collection to see whether it's upgradeable
        require(tokensData[tokenId] >= 1 && tokensData[tokenId] < 5, "Your bulldog cannot be upgraded further");

        // Making approved transfer from the main NFT contract
        NFTContract(_nftContractAddress).transferFrom(msg.sender, address(this), tokenId);

        // Writing changes to DB
        stakeHolders[msg.sender].tokenStakeBlock[tokenId] = block.number + 1;
        stakeHolders[msg.sender].stakedTokens.push(tokenId);
        
        emit Staked(tokenId);
    }

    function unstake(uint256 tokenId) public nonReentrant ownerOfToken(tokenId) staked(tokenId) freezePeriodPassed(tokenId) {
        stakeHolders[msg.sender].tokenStakeBlock[tokenId] = 0;

        uint tokensCount = stakeHolders[msg.sender].stakedTokens.length;
        for (uint i = 0; i < tokensCount; i++) {
            if (stakeHolders[msg.sender].stakedTokens[i] == tokenId) {
                delete stakeHolders[msg.sender].stakedTokens[i];
            }
        }

        // Adding unclaimed $BBONES to bonuses
        bonuses[msg.sender] += getTokenUPNL(tokenId);

        // Making approved transfer NFT back to its owner
        NFTContract(_nftContractAddress).transferFrom(address(this), msg.sender, tokenId);
        emit Unstaked(tokenId);
    }

    // divides two numbers and returns quotient & remainder
    function superDivision(uint numerator, uint denominator) internal pure returns(uint quotient, uint remainder) {
        quotient  = numerator / denominator;
        remainder = numerator - denominator * quotient;
    }

    // Call to get you staking reward
    function claimBBones(address _address) public nonReentrant {
        
        uint amountToPay = 0;
        uint tokensCount = stakeHolders[_address].stakedTokens.length;

        for (uint i = 0; i < tokensCount; i++) {
            uint tokenId = stakeHolders[_address].stakedTokens[i];
            uint tokenBlockDiff = block.number - stakeHolders[_address].tokenStakeBlock[tokenId];
            
            // Token has to be staked minimum number of blocks
            if (tokenBlockDiff >= minStakingPeriod && stakeHolders[_address].tokenStakeBlock[tokenId] + freezePeriod <= block.number) {
                uint quotient;
                uint remainder;
                
                // if enough blocks have passed to get at least 1 payout => proceed
                (quotient, remainder) = superDivision(tokenBlockDiff, minStakingPeriod);
                if (quotient > 0) {
                    uint blockRate = getTokenEarnRate(tokenId);
                    uint tokenEarnings = blockRate * quotient;
                    amountToPay += tokenEarnings;

                    stakeHolders[_address].tokenStakeBlock[tokenId] = block.number - remainder;
                }
            }
        }

        // Claiming bonuses if any
        if (bonuses[_address] > 0) {
            amountToPay += bonuses[_address];
            bonuses[_address] = 0;
        }

        TokenContract(_tokenContractAddress).transfer(_address, amountToPay);
        emit BBonesClaimed(_address, amountToPay);
    }

    // Get user's list of staked tokens
    function stakedTokensOf(address _address) public view returns (uint[] memory) {
        return stakeHolders[_address].stakedTokens;
    }
    /*
        End of staking
    */



    /*
        Upgrading
    */
    function upgradeBulldog(uint tokenId, uint tokenCollection, uint upgradeType) public nonReentrant ownerOfToken(tokenId) freezePeriodPassed(tokenId) {
        /*
            Upgrade types:
                1 - to the next collection
                2 - swap inside the same collection
        */

        // Setting token's collection if it wasn't set
        if (tokensData[tokenId] == 0) {
            userSetTokenCollection(tokenId, tokenCollection);
        }

        // Checking bulldog's collection to see whether it's upgradeable
        require(tokensData[tokenId] >= 1 && tokensData[tokenId] < 5, "Your bulldog cannot be upgraded further");

        // User has emough $BBONES to pay for the upgrade
        require(TokenContract(_tokenContractAddress).balanceOf(msg.sender) >= upgradeabilityCost[tokensData[tokenId]], "You don't have enough $BBONES");
        
        // Upgrading
        if (upgradeType == 1) {

            // If token is staked: save his UPNL and reset
            if (stakeHolders[msg.sender].tokenStakeBlock[tokenId] > 0) {
                stakeHolders[msg.sender].tokenStakeBlock[tokenId] = 0;

                // Adding unclaimed $BBONES to bonuses
                bonuses[msg.sender] += getTokenUPNL(tokenId);
            }
            tokensData[tokenId] += 1;
            TokenContract(_tokenContractAddress)._burn(msg.sender, upgradeabilityCost[tokensData[tokenId]]);
            emit bulldogUpgraded(tokenId);
        }

        // Swapping
        if (upgradeType == 2) {
            TokenContract(_tokenContractAddress)._burn(msg.sender, upgradeabilityCost[tokensData[tokenId]]);
            emit bulldogSwapped(tokenId);
        }   
    }
    /*
        End of upgrading
    */

}