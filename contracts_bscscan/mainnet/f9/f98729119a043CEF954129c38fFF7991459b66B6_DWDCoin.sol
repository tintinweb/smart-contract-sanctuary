/**
 *Submitted for verification at BscScan.com on 2021-07-08
*/

// SPDX-License-Identifier: GPL-3.0
// Author: Farhadur Rahim

pragma solidity ^0.8.0;

/**
 * @dev Interface of the BEP20 standard as defined in the EIP.
 */
interface IBEP20 {
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
 * @dev Interface for the optional metadata functions from the BEP20 standard.
 *
 * _Available since v4.1._
 */
interface IBEP20Metadata is IBEP20 {
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
 * @dev Implementation of the {IBEP20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {BEP20PresetMinterPauser}.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IBEP20-approve}.
 */
contract BEP20 is Context, IBEP20, IBEP20Metadata {
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
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {BEP20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IBEP20-balanceOf} and {IBEP20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IBEP20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {BEP20-balanceOf}.
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
     * @dev See {IBEP20-transfer}.
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
     * @dev See {IBEP20-allowance}.
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
     * @dev See {IBEP20-approve}.
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
     * @dev See {IBEP20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {BEP20}.
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
            "BEP20: transfer amount exceeds allowance"
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
     * problems described in {IBEP20-approve}.
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
     * problems described in {IBEP20-approve}.
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
            "BEP20: decreased allowance below zero"
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
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "BEP20: transfer amount exceeds balance"
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
        require(account != address(0), "BEP20: mint to the zero address");

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
        require(account != address(0), "BEP20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "BEP20: burn amount exceeds balance");
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
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

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


contract DWDCoin is BEP20, Ownable {
    struct WebDirectory {
        uint256 id;
        string title;
        string url;
        string description;
        string category;
        string screenshot;
        address user;
        uint256 createdAt;
    }

    // mapping weblinks in web directory
    mapping(uint256 => WebDirectory) private weblinks;

    // count user submissions
    mapping(address => uint256) private userSubmissionCounter;

    // count submissions agaist each category
    mapping(bytes32 => uint256) private catSubmissionCounter;

    // tracking web-url being duplicated
    mapping(bytes32 => string) private trackingLink;

    // count submissions
    uint256 private submissionCount;

    // holding each rewarded token amounts
    struct RewardToken {
        uint256[] tokenAmount;
    }

    // mapping rewarded tokens against each account
    mapping(address => RewardToken) private rewardHolder;

    // event logs sent from and to who (to) and how much tokens were rewarded
    event RewardEvent(address _from, address _to, uint256 _amount);

    // self executable constructor
    constructor(string memory name, string memory symbol)
        BEP20(name = "Decentralize Web Directory Coin", symbol = "DWDC")
    {
        // Mint 100 tokens to msg.sender
        // Similar to how
        // 1 dollar = 100 cents
        // 1 token = 1 * (10 ** decimals)
        // who deploy the contract gets totalSupply assign to him
        _mint(msg.sender, 100 * 10**uint256(decimals()));
    }

    /**
     * @dev onlyOwner can call this for further add more tokenSupply
     */
    function mint(uint256 _amount) public onlyOwner returns (bool) {
        _mint(msg.sender, _amount);

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This public function is equivalent to {transfer}, and can be used to
     * reward a participant for any action
     *
     * Emits a {RewardEvent} event.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function rewardToken(address recipient, uint256 amount)
        public
        onlyOwner
        returns (bool)
    {
        require(recipient != address(0), "BEP20: transfer to the zero address");

        // call internal function {transfer} to send rewarded token
        transfer(recipient, amount);

        // push the amount of tokens to reward holder for accounting purpose
        rewardHolder[recipient].tokenAmount.push(amount);

        // broadcast reward event to log
        emit RewardEvent(msg.sender, recipient, amount);

        return true;
    }

    /**
     * @dev count number of rewards against an account
     *
     * Requirements:
     *
     * - `_account` reward holder's address.
     */
    function countRewardOf(address _account)
        public
        view
        returns (uint256 length)
    {
        return rewardHolder[_account].tokenAmount.length;
    }

    /**
     * @dev amount of the last reward token against an account
     * always return reward's token amount from last index
     *
     * Requirements:
     *
     * - `_account` reward holder's address.
     */
    function getLastRewardOf(address _account) public view returns (uint256) {
        uint256 lastIndex = countRewardOf(_account) - 1;
        return rewardHolder[_account].tokenAmount[lastIndex];
    }

    /**
     * @dev display all the rewarded token against an account
     * return the rewarded token amounts as an array
     *
     * Requirements:
     *
     * - `_account` reward holder's address.
     */
    function getAllRewardOf(address _account)
        public
        view
        returns (uint256[] memory)
    {
        return rewardHolder[_account].tokenAmount;
    }

    /**
     * @dev storing content submission
     * return true/false
     *
     * Requirements:
     *
     * - `title` website title.
     * - `url` website address.
     * - `description` description about website.
     * - `category` type of industry.
     * - `screenshot` type of industry.
     */
    function submissionToDir(
        string memory title,
        string memory url,
        string memory description,
        string memory category,
        string memory screenshot
    ) public returns (bool) {
        bytes32 hashLink = keccak256(abi.encode(url));
        bytes32 hashCatName = keccak256(abi.encode(category));

        if (verifyDuplicacy(trackingLink[hashLink], url)) return false;

        weblinks[submissionCount] = WebDirectory(
            submissionCount,
            title,
            url,
            description,
            category,
            screenshot,
            msg.sender,
            block.timestamp
        );

        // update the tracker array
        trackingLink[hashLink] = url;

        // increment user's submission counter
        userSubmissionCounter[msg.sender] += 1;

        // increment category submission counter
        catSubmissionCounter[hashCatName] += 1;

        // increament
        submissionCount++;

        return true;
    }

    /**
     * @dev get all content/weblinks from directory
     * return the entries as an array
     *
     */
    function getWebLinks() public view returns (WebDirectory[] memory) {
        WebDirectory[] memory WDlink = new WebDirectory[](submissionCount);
        for (uint256 i = 0; i < submissionCount; i++) {
            WebDirectory storage submission = weblinks[i];
            WDlink[i] = submission;
        }
        return WDlink;
    }

    /**
     * @dev get a single content/weblink from directory
     * return data as an array
     *
     * Requirements:
     *
     * - `_index` numeric index of the weblink.
     */
    function getLink(uint256 _index)
        public
        view
        returns (WebDirectory[] memory)
    {
        WebDirectory[] memory WDlink = new WebDirectory[](1);
        WDlink[0] = weblinks[_index];
        return WDlink;
    }

    /**
     * @dev get all content/weblink agaist an user
     * return data as an array
     *
     * Requirements:
     *
     * - `_account` address of the user.
     */
    function getSubmissionOf(address _account)
        public
        view
        returns (WebDirectory[] memory)
    {
        WebDirectory[] memory WDlink = new WebDirectory[](
            userSubmissionCounter[_account]
        );

        uint256 _index = 0;
        for (uint256 i = 0; i < submissionCount; i++) {
            if (weblinks[i].user == _account) {
                WebDirectory storage submission = weblinks[i];
                WDlink[_index] = submission;
                _index++;
            }
        }
        return WDlink;
    }

    /**
     * @dev get all content/weblink under a category
     * return data as an array
     *
     * Requirements:
     *
     * - `_category` category hash.
     */
    function findByCategory(bytes32 _category)
        public
        view
        returns (WebDirectory[] memory)
    {
        //bytes32 hashCatName = keccak256(abi.encode(_category));

        WebDirectory[] memory WDlink = new WebDirectory[](
            catSubmissionCounter[_category]
        );

        uint256 _index = 0;
        for (uint256 i = 0; i < submissionCount; i++) {
            if (keccak256(abi.encode(weblinks[i].category)) == _category) {
                WebDirectory storage submission = weblinks[i];
                WDlink[_index] = submission;
                _index++;
            }
        }
        return WDlink;
    }

    /**
     * @dev count total number of submission against an user
     * return data as an integer
     *
     * Requirements:
     *
     * - `_account` user address.
     */
    function countSubmissionOf(address _account) public view returns (uint256) {
        return userSubmissionCounter[_account];
    }

    /**
     * @dev count total number of submission under a category
     * return data as an integer
     *
     * Requirements:
     *
     * - `_category` category hash.
     */
    function countLinksInCatOf(bytes32 _category)
        public
        view
        returns (uint256)
    {
        //bytes32 hashCatName = keccak256(abi.encode(_category));
        return catSubmissionCounter[_category];
    }

    /**
     * @dev verify two string if equals
     * return true/false as an boolean
     *
     * Requirements:
     *
     * - `a` string one.
     * - `b` string two.
     */
    function verifyDuplicacy(string memory a, string memory b)
        private
        pure
        returns (bool)
    {
        return (keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked((b))));
    }
}