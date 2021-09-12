/**
 *Submitted for verification at BscScan.com on 2021-09-11
*/

/**
 *Submitted for verification at BscScan.com on 2021-08-19
*/

/**
 *Submitted for verification at BscScan.com on 2021-08-11
 */

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

//licence here :)

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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
 */
contract HashUpERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint8 private _decimals;
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
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
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
        return _decimals;
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

// interface IGameContract {
//     function setModerator(address newModerator) external view returns (bool);

//     function setNewAdmin(address newAdmin) external view returns (bool);

//     function changeAdmin(address newAdmin) external returns (bool);

//     function getTypeOfContract() external view returns (string memory);

//     function setDescription(string memory newDescription) external view returns (bool);

//     function getDescription() external view returns (string memory);

//     function setIcon(string memory newIconUrl) external view returns (bool);

//     function getIcon() external view returns (string memory);
// }

contract GameContract is HashUpERC20 {
    address admin;
    address moderator;

    string title;
    string description;
    string iconUrl;
    string gameUrl;
    string gameLandingPageUrl;
    string typeOfContract = "GAME";

    //game social media
    string telegramUrl;
    string facebookUrl;
    string instagramUrl;
    string linkedinUrl;
    string trailerUrl;

    //creator media
    string creatorCompanyName;
    string creatorCompanyUrl;
    string creatorCompanyIconUrl;
    string creatorCompanyLogoUrl;

    uint8 public minAge;
    uint256 public startPriceInUSD;
    uint256 public startPriceInHash;
    string[] public tags;
    string[] public hashtags;
    uint256 public premiereTimestamp;

    //creator other games
    address[] public creatorGames;

    modifier isAdmin() {
        require(msg.sender == admin, "Caller is not admin");
        _;
    }

    modifier isAdminOrModerator() {
        require(
            msg.sender == admin || msg.sender == moderator,
            "Caller is not admin or moderator"
        );
        _;
    }

    event AdminSet(address indexed oldAdmin, address indexed newAdmin);
    event ModeratorSet(
        address indexed oldModerator,
        address indexed newModerator
    );

    constructor(
        uint8 decimals_,
        uint256 initialSupply_,
        string memory name_,
        string memory symbol_,
        string memory gameUrl_,
        string memory iconUrl_,
        string memory description_,
        string memory gameLandingPageUrl_,
        uint256 premiereTimestamp_,
        uint256 startPriceInUSD_
    ) HashUpERC20(name_, symbol_, decimals_) {
        _mint(msg.sender, initialSupply_);

        admin = msg.sender;
        moderator = msg.sender;

        title = name_;
        description = description_;
        iconUrl = iconUrl_;
        gameUrl = gameUrl_;
        gameLandingPageUrl = gameLandingPageUrl_;
        startPriceInUSD = startPriceInUSD_;
        premiereTimestamp = premiereTimestamp_;
    }

    function getGameContractVersion() public pure returns (uint8) {
        return 1;
    }

    function setModerator(address newModerator) public isAdmin returns (bool) {
        moderator = newModerator;
        return true;
    }

    function setNewAdmin(address newAdmin) public isAdmin returns (bool) {
        admin = newAdmin;
        return true;
    }

    function changeAdmin(address newAdmin)
        external
        isAdminOrModerator
        returns (bool)
    {
        emit AdminSet(admin, newAdmin);
        admin = newAdmin;
        return true;
    }

    function getTitle() public view returns (string memory) {
        return title;
    }

    function getTypeOfContract() public view returns (string memory) {
        return typeOfContract;
    }

    function setDescription(string memory newDescription)
        public
        isAdminOrModerator
        returns (bool)
    {
        description = newDescription;
        return true;
    }

    function getDescription() public view returns (string memory) {
        return description;
    }

    function setIcon(string memory newIconUrl)
        public
        isAdminOrModerator
        returns (bool)
    {
        iconUrl = newIconUrl;
        return true;
    }

    function getIcon() public view returns (string memory) {
        return iconUrl;
    }

    function setGameUrl(string memory newGameUrl)
        public
        isAdminOrModerator
        returns (bool)
    {
        gameUrl = newGameUrl;
        return true;
    }

    function getGameUrl() public view returns (string memory) {
        return gameUrl;
    }

    function setGameLandingPageUrl(string memory newLandingPageUrl)
        public
        isAdminOrModerator
        returns (bool)
    {
        gameLandingPageUrl = newLandingPageUrl;
        return true;
    }

    function getGameLandingPageUrl() public view returns (string memory) {
        return gameLandingPageUrl;
    }

    function setTelegramUrl(string memory newTelegramUrl)
        public
        isAdminOrModerator
        returns (bool)
    {
        telegramUrl = newTelegramUrl;
        return true;
    }

    function getTelegramUrl() public view returns (string memory) {
        return telegramUrl;
    }

    function setFacebookUrl(string memory newFacebookUrl)
        public
        isAdminOrModerator
        returns (bool)
    {
        facebookUrl = newFacebookUrl;
        return true;
    }

    function getFacebookUrl() public view returns (string memory) {
        return facebookUrl;
    }

    function setInstagramUrl(string memory newInstagramUrl)
        public
        isAdminOrModerator
        returns (bool)
    {
        instagramUrl = newInstagramUrl;
        return true;
    }

    function getInstagramUrl() public view returns (string memory) {
        return instagramUrl;
    }

    function setLinkedinUrl(string memory newLinkedinUrl)
        public
        isAdminOrModerator
        returns (bool)
    {
        linkedinUrl = newLinkedinUrl;
        return true;
    }

    function getLinkedinUrl() public view returns (string memory) {
        return linkedinUrl;
    }

    function setTrailerUrl(string memory newTrailerUrl)
        public
        isAdminOrModerator
        returns (bool)
    {
        trailerUrl = newTrailerUrl;
        return true;
    }

    function getTrailerUrl() public view returns (string memory) {
        return trailerUrl;
    }

    function pushCreatorGame(address creatorGame)
        public
        isAdminOrModerator
        returns (bool)
    {
        creatorGames.push(creatorGame);
        return true;
    }

    function removeForCreatorGameArray(uint256 index)
        public
        isAdminOrModerator
        returns (bool)
    {
        creatorGames[index] = creatorGames[creatorGames.length - 1];
        creatorGames.pop();
        return true;
    }

    function getCreatorGames() public view returns (address[] memory) {
        return creatorGames;
    }

    // string creatorCompanyUrl;

    function setCreatorCompanyName(string memory newCompanyName)
        public
        isAdminOrModerator
        returns (bool)
    {
        creatorCompanyName = newCompanyName;
        return true;
    }

    function getCreatorCompanyName() public view returns (string memory) {
        return creatorCompanyName;
    }

    function setCreatorCompanyUrl(string memory newCompanyUrl)
        public
        isAdminOrModerator
        returns (bool)
    {
        creatorCompanyUrl = newCompanyUrl;
        return true;
    }

    function getCreatorCompanyUrl() public view returns (string memory) {
        return creatorCompanyUrl;
    }

    function setCreatorCompanyIconUrl(string memory newCompanyIconUrl)
        public
        isAdminOrModerator
        returns (bool)
    {
        creatorCompanyIconUrl = newCompanyIconUrl;
        return true;
    }

    function getCreatorCompanyIconUrl() public view returns (string memory) {
        return creatorCompanyIconUrl;
    }

    //creatorCompanyLogoUrl

    function setCreatorCompanyLogoUrl(string memory newCreatorCompanyLogo)
        public
        isAdminOrModerator
        returns (bool)
    {
        creatorCompanyLogoUrl = newCreatorCompanyLogo;
        return true;
    }

    function getCreatorCompanyLogoUrl() public view returns (string memory) {
        return creatorCompanyLogoUrl;
    }

    //social likes and dislike module

    address[] private likes;
    address[] private dislikes;

    mapping(address => bool) public isAddressLike;
    mapping(address => bool) public isAddressDislike;

    function likeGame() public returns (bool) {
        require(isAddressLike[msg.sender] == false);

        if (isAddressDislike[msg.sender]) {
            isAddressDislike[msg.sender] = false;
            dislikes.pop();
        }

        likes.push(msg.sender);
        isAddressLike[msg.sender] = true;
        return true;
    }

    function dislikeGame() public returns (bool) {
        require(isAddressDislike[msg.sender] == false);

        if (isAddressLike[msg.sender]) {
            isAddressLike[msg.sender] = false;
            likes.pop();
        }

        dislikes.push(msg.sender);
        isAddressDislike[msg.sender] = true;
        return true;
    }

    function getIsAddressLike(address user) public view returns (bool) {
        return isAddressLike[user];
    }

    function getIsAddressDislike(address user) public view returns (bool) {
        return isAddressDislike[user];
    }

    function getLikes() public view returns (uint256) {
        return likes.length;
    }

    function getDislikes() public view returns (uint256) {
        return dislikes.length;
    }

    function setMinAge(uint8 minAge_) public isAdminOrModerator returns (bool) {
        minAge = minAge_;
        return true;
    }

    function getMinAge() public view returns (uint8) {
        return minAge;
    }

    function getStartPriceInUSD() public view returns (uint256) {
        return startPriceInUSD;
    }

    function getPremiereTimestamp() public view returns (uint256) {
        return premiereTimestamp;
    }

    function setStartPriceInHash(uint256 startPriceInHash_)
        public
        isAdminOrModerator
        returns (bool)
    {
        startPriceInHash = startPriceInHash_;
        return true;
    }

    function getStartPriceInHash() public view returns (uint256) {
        return startPriceInHash;
    }

    // string[] public tags;
    function setTags(string[] memory tags_)
        public
        isAdminOrModerator
        returns (bool)
    {
        tags = tags_;
        return true;
    }

    function getTags() public view returns (string[] memory) {
        return tags;
    }
    
    struct JsonInterface {
        string    title;
        string    description;
        string    symbol;
        string    iconUrl;
        string    gameUrl;
        string    gameLandingPageUrl;
        string    typeOfContract;
        uint8     gameContractVersion;
        uint256   balanceForUser;
    
        string    telegramUrl;
        string    facebookUrl;
        string    instagramUrl;
        string    linkedinUrl;
        string    trailerUrl;
    
        string    creatorCompanyName;
        string    creatorCompanyUrl;
        string    creatorCompanyIconUrl;
        string    creatorCompanyLogoUrl;
    
        uint8     minAge;
        uint256   startPriceInUSD;
        uint256   startPriceInHash;
        string[]  tags;
        uint256   premiereTimestamp;
    
        address[] creatorGames;
    }

    /**
     * Dumps all public contract data for a user at the given address.
     */
    function toJson(address user) public view returns (JsonInterface memory) {
        return JsonInterface(
            title,
            description,
            symbol(),
            iconUrl,
            gameUrl,
            gameLandingPageUrl,
            typeOfContract,
            getGameContractVersion(),
            balanceOf(user),
            telegramUrl,
            facebookUrl,
            instagramUrl,
            linkedinUrl,
            trailerUrl,
            creatorCompanyName,
            creatorCompanyUrl,
            creatorCompanyIconUrl,
            creatorCompanyLogoUrl,
            minAge,
            startPriceInUSD,
            startPriceInHash,
            tags,
            premiereTimestamp,
            creatorGames
        );
    }
}