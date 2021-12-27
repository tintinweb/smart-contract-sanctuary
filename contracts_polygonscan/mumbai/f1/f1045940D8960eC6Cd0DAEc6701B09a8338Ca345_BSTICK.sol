/**
 *Submitted for verification at polygonscan.com on 2021-12-26
*/

// SPDX-License-Identifier: GPL-3.0

/*  
    When you're here you're family #WYHYF
        __ ____ _______________________ __
      _/ // __ ) ___/_  __/  _/ ____/ //_/
     / __/ __  \__ \ / /  / // /   / ,<   
    (_  ) /_/ /__/ // / _/ // /___/ /| |  
   /  _/_____/____//_/ /___/\____/_/ |_|  
   /_/                           

    For franchisooooors of Non-Fungible Olive Gardens, 
    From passionate franchisoooors of Non-Fungible Olive Gardens
*/

pragma solidity ^0.8.7;

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

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
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
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
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
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
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
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
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
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
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
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
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
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

/// @title Fungible Breadsticks for NFOG
/// @custom:unaudited This contract has not been audited. Use at your own risk.
contract BSTICK is Context, Ownable, ERC20 {
    // Give out 20,000 Breadsticks for every Franchise that a user holds
    uint256 public bsticksPerNFOG = 20000 * (10**decimals());

    // Give out 1,000 Breadsticks for every review star (team decides 0-10 rating of review quality)
    uint256 public bsticksPerReviewStar = 1000 * (10**decimals());

    // Give out 1 Breadstick for every Breadstick NFT that a user holds
    uint256 public bsticksPerBreadstick = 1 * (10**decimals());

    // Give out 10,000 Breadstick for every Burnt Breadstick NFT that a user holds
    uint256 public bsticksPerBurntBreadstick = 10000 * (10**decimals());

    // Give out 10,000 Breadstick for every Proof of Pasta
    uint256 public bsticksPerProofOfPasta = 10000 * (10**decimals());

    // nfogIdStart of 1
    uint256 public nfogIdStart = 0;

    // nfogIdEnd of 879
    uint256 public nfogIdEnd = 879;

    // Courses are used to allow users to claim tokens regularly. Courses are
    // decided by the DAO.
    uint256 public course = 0;

    address private ownerWallet = 0x86C0aAa32B03A9ad61347372d7Aafc96FE13dE11;
    address private lpWallet = 0xDD51520dd5100936faFCbe7c2f1D8f318FFeDEd3;
    address private airdropBuffetWallet = 0x58f5d505919975f34e2Fb646837b2D5Dc8F578AA;
    address private charityWallet = 0xE0d4dF57ddb7555907312F4337087eB665462Cd0;
    address private marketingWallet = 0xE0d4dF57ddb7555907312F4337087eB665462Cd0;
    address private teamWallet = 0x5f870c2cD46ddDB6B109b855C49296A91c4e540c;

    // Track claimed tokens within a course for NFOG holders
    // IMPORTANT: The format of the mapping is:
    // courseClaimedByNFOGId[course][NFOGId][claimed]
    mapping(uint256 => mapping(uint256 => bool)) public courseClaimedByNFOGId;
    mapping(uint256 => mapping(uint256 => bool)) public courseClaimedByBreadstickId;

    constructor() Ownable() ERC20("Breadstick", "BSTICK") {
        // Distribute 25% to owner (for initial liquidity)
        _mint(ownerWallet, 250000000 * (10**decimals()));
        // Distribute 30% to LP incentives wallet
        _mint(lpWallet, 300000000 * (10**decimals()));
        // Distribute 25% to Airdrop Buffet Wallet
        _mint(airdropBuffetWallet, 250000000 * (10**decimals()));
        // Distribute 10% to Charity Wallet
        _mint(charityWallet, 100000000 * (10**decimals()));
        // Distribute 5% to Marketing Wallet
        _mint(marketingWallet, 50000000 * (10**decimals()));
        // Distribute 5% to Team Wallet
        _mint(teamWallet, 50000000 * (10**decimals()));
    }

    /// @notice Claim Breadsticks for a given NFOG ID
    /// @param receivers Addresses of wallets that hold NFOG NFT
    /// @param nfogIds The tokenId of the NFOG NFT
    function airdropNFOGFranchisors(address[] memory receivers, uint256[] memory nfogIds) external {
        require(_msgSender() == airdropBuffetWallet, "Can only be initiated by Airdrop Buffet Wallet");
        require(bsticksPerNFOG * receivers.length <= balanceOf(airdropBuffetWallet), "Airdrop Buffet Wallet doesn't have enough $BSTICK for this claim");

        for(uint256 i = 0; i < receivers.length; i++) {
            address receiver = receivers[i];
            _claim(true, bsticksPerNFOG, nfogIds[i], receiver);
        }
    }

    /// @notice Claim Breadsticks for given Breadstick IDs (address array and breadstickId array order MUST match)
    /// @param receivers Address of receivers
    /// @param breadstickIds The tokenId of the Breadstick NFTs 
    function airdropBreadsticks(address[] memory receivers, uint256[] memory breadstickIds) external {
        require(_msgSender() == airdropBuffetWallet, "Can only be initiated by Airdrop Buffet Wallet");
        require(bsticksPerBreadstick * receivers.length <= balanceOf(airdropBuffetWallet), "Airdrop Buffet Wallet doesn't have enough $BSTICK for this claim");
        
        for(uint256 i = 0; i < receivers.length; i++) {
            address receiver = receivers[i];
            _claim(false, bsticksPerBreadstick, breadstickIds[i], receiver);
        }
    }

    /// @notice Claim Breadsticks for a given Burnt Breadstick ID
    /// @param receiver Address of receiver
    /// @param breadstickId The tokenId of the Breadstick NFT
    function airdropBurntBreadstick(address receiver, uint256 breadstickId) external {
        require(_msgSender() == airdropBuffetWallet, "Can only be initiated by Airdrop Buffet Wallet");
        require(bsticksPerBurntBreadstick <= balanceOf(airdropBuffetWallet), "Airdrop Buffet Wallet doesn't have enough $BSTICK for this claim");
        require(breadstickId % 1000 == 0, "Not a burnt breadstick!");
    
        _claim(false, bsticksPerBurntBreadstick, breadstickId, receiver);
    }
    
    /// @notice Claim Breadsticks for writing reviews on Yelp/Google Reviews
    /// @param receivers Address of receivers
    /// @param ratings The rating of how good the review is (0-10)
    function airdropReviewers(address[] memory receivers, uint8[] memory ratings) external {
        // 0-10k $BSTICK for Proof of Pasta (pic of yourself at Olive Garden w/ identity proof)
        require(_msgSender() == airdropBuffetWallet, "Can only be initiated by Airdrop Buffet Wallet");
        require(receivers.length == ratings.length, "Make sure number of receivers equals number of ratings");
       
        for(uint256 i = 0; i < receivers.length; i++) {
            require(ratings[i] <= 10 && ratings[i] >= 0, "Rating must be between 0 and 10");
            // Rating * 1,000 $BSTICK reward
            uint bsticksForRating = ratings[i] * bsticksPerReviewStar;
            require(bsticksForRating <= balanceOf(airdropBuffetWallet), "Airdrop Buffet wallet doesn't have enough $BSTICK for this claim");
            transfer(receivers[i], bsticksForRating);
        }
    }

    /// @notice Claim Breadsticks for proof of eating at (pic of yourself at Olive Garden w/ identity proof)
    /// @param receivers Address of receivers
    function airdropProofOfPasta(address[] memory receivers) external {
        // 10k $BSTICK for Proof of Pasta 
        require(_msgSender() == airdropBuffetWallet, "Can only be initiated by airdrop buffet wallet");
        require(bsticksPerProofOfPasta * receivers.length <= balanceOf(airdropBuffetWallet), "Airdrop Buffet wallet doesn't have enough $BSTICK for this claim");
       
        for(uint256 i = 0; i < receivers.length; i++) {
            transfer(receivers[i], bsticksPerProofOfPasta);
        }
    }

    /// @dev Internal function to mint Breadsticks upon claiming 
    function _claim(bool isNFOG, uint256 amount, uint256 tokenId, address tokenOwner) internal {   
        // Check that Breadsticks have not already been claimed this course for a given tokenId
        if (isNFOG) {
            require(tokenId >= nfogIdStart && tokenId <= nfogIdEnd);
            require(!courseClaimedByNFOGId[course][tokenId], "$BSTICK already claimed for this NFOG for this course");
            courseClaimedByNFOGId[course][tokenId] = true;
        } else {
            require(!courseClaimedByBreadstickId[course][tokenId], "$BSTICK already claimed for this Breadstick for this course");
            courseClaimedByBreadstickId[course][tokenId] = true;
        }

        transfer(tokenOwner, amount);
    }

    /// @notice Allows the DAO to mint new tokens for use (very unlikely this will be used)
    /// @param amountDisplayValue The amount of Breadsticks to mint. This should be
    /// input as the display value, not in raw decimals. If you want to mint
    /// 100 Breadsticks, you should enter "100" rather than the value of 100 * 10^18.
    function daoMint(uint256 amountDisplayValue) external onlyOwner {
        _mint(owner(), amountDisplayValue * (10**decimals()));
    }

    /// @notice Allows the DAO to set a course for new breadsticks claims
    /// @param course_ The course to use for claiming Breadsticks
    function daoSetCourse(uint256 course_) public onlyOwner {
        course = course_;
    }

    /// @notice Allows the DAO to set the amount of Breadsticks that is
    /// claimed per NFOG
    /// @param bsticksDisplayValue The amount of Breadsticks a user can claim.
    function daoSetBSTICKSPerNFOG(uint256 bsticksDisplayValue)
        public
        onlyOwner
    {
        bsticksPerNFOG = bsticksDisplayValue * (10**decimals());
    }

    /// @notice Allows the DAO to set the amount of Breadsticks that is
    /// claimed per Breadstick NFT
    /// @param bsticksDisplayValue The amount of Breadsticks a user can claim.
    function daoSetBSTICKSPerBreadstick(uint256 bsticksDisplayValue)
        public
        onlyOwner
    {
        bsticksPerBreadstick = bsticksDisplayValue * (10**decimals());
    }

    /// @notice Allows the DAO to set the amount of Breadsticks that is
    /// claimed per Burnt Breadstick NFT
    /// @param bsticksDisplayValue The amount of Breadsticks a user can claim.
    function daoSetBSTICKSPerBurntBreadstick(uint256 bsticksDisplayValue)
        public
        onlyOwner
    {
        bsticksPerBurntBreadstick = bsticksDisplayValue * (10**decimals());
    }

    /// @notice Allows the DAO to set the amount of Breadsticks that is
    /// claimed per Proof of Pasta
    /// @param bsticksDisplayValue The amount of Breadsticks a user can claim.
    function daoSetBSTICKSPerProofOfPasta(uint256 bsticksDisplayValue)
        public
        onlyOwner
    {
        bsticksPerProofOfPasta = bsticksDisplayValue * (10**decimals());
    }

    /// @notice Allows the DAO to change the address for airdrop buffet, 
    /// which is the only address allowed to initiate airdrops
    /// @param addr The new address
    function daoSetAirdropBuffetWallet(address addr)
        public
        onlyOwner
    {
        airdropBuffetWallet = addr;
    }
}