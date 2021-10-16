/**
 *Submitted for verification at Etherscan.io on 2021-10-15
*/

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

interface IPUNK {
    function punkIndexToAddress(uint256 punkID) external view returns (address);
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

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC165).interfaceId;
    }
}

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

/// @title Papi Token for NNW holders!
/// @author Will Papper <https://twitter.com/WillPapper>
/// @notice This contract mints Papi Token for NNW holders and provides
/// administrative functions to the NNW DAO. It allows:
/// * NNW holders to claim Papi Token
/// * A DAO to set seasons for new opportunities to claim Papi Token
/// * A DAO to mint Papi Token for use within the NNW ecosystem
/// @custom:unaudited This contract has not been audited. Use at your own risk.
contract papiToken is Context, Ownable, ERC20 {
    // NNW contract is available at https://etherscan.io/address/0xEDBaca315748B5a539cf7FB97447A62680b36575
    address public NNWContractAddress =
        0xEDBaca315748B5a539cf7FB97447A62680b36575;
    IERC721Enumerable public NNWContract;

    address public cdbcontractAddress =
        0x3bE1c7BF44c5483D99Fe7D425E38C583788aA7B5;
    IERC721Enumerable public cdbcontract;

    address public toadzContractAddress =
        0xc52a8934C39CbEc091EEe77653BF085bB386FeFd;
    IERC721Enumerable public toadContract;

    address public punksContractAddress =
        0xc52a8934C39CbEc091EEe77653BF085bB386FeFd;
    IPUNK public punksContract;

    function daoSetcdbContractAddress(address cdbContractAddress_)
        external
        onlyOwner
    {
        cdbcontractAddress = cdbContractAddress_;
        cdbcontract = IERC721Enumerable(cdbcontractAddress);
    }

    function daoSetToadzContractAddress(address toadzContractAddress_)
        external
        onlyOwner
    {
        toadzContractAddress = toadzContractAddress_;
        toadContract = IERC721Enumerable(toadzContractAddress);
    }

    function daoSetPunksContractAddress(address punksContractAddress_)
        external
        onlyOwner
    {
        punksContractAddress = punksContractAddress_;
        punksContract = IPUNK(punksContractAddress);
    }

    // Give out 10,000 Papi Token for every NNW Bag that a user holds
    uint256 public papiTokenPerTokenId = 10000 * (10**decimals());

    // tokenIdStart of 1 is based on the following lines in the NNW contract:
    /** 
    function claim(uint256 tokenId) public nonReentrant {
        require(tokenId > 0 && tokenId < 7778, "Token ID invalid");
        _safeMint(_msgSender(), tokenId);
    }
    */
    uint256 public cdbtokenIdStart = 1;
    uint256 public toadtokenIdStart = 1;
    uint256 public NNWtokenIdStart = 1;
    uint256 public punkstokenIdStart = 0;

    // tokenIdEnd of 8000 is based on the following lines in the NNW contract:
    /**
        function ownerClaim(uint256 tokenId) public nonReentrant onlyOwner {
        require(tokenId > 7777 && tokenId < 8001, "Token ID invalid");
        _safeMint(owner(), tokenId);
    }
    */
    uint256 public cdbtokenIdEnd = 5200;
    uint256 public toadtokenIdEnd = 6969;
    uint256 public NNWtokenIdEnd = 8000;
    uint256 public punkstokenIdEnd = 9999;

    // Seasons are used to allow users to claim tokens regularly. Seasons are
    // decided by the DAO.
    uint256 public season = 0;

    // Track claimed tokens within a season
    // IMPORTANT: The format of the mapping is:
    // claimedForSeason[season][tokenId][claimed]
    mapping(uint256 => mapping(uint256 => bool))
        public seasonNNWClaimedByTokenId;
    mapping(uint256 => mapping(uint256 => bool))
        public seasonCdbClaimedByTokenId;
    mapping(uint256 => mapping(uint256 => bool))
        public seasonToadClaimedByTokenId;

    mapping(uint256 => mapping(uint256 => bool))
        public seasonOGpunksClaimedByTokenId;

    constructor() Ownable() ERC20("Papi Token", "PAPI") {
        // Transfer ownership to the NNW DAO
        // Ownable by OpenZeppelin automatically sets owner to msg.sender, but
        // we're going to be using a separate wallet for deployment
        //transferOwnership(0x8A9458F8bDF830E31e5A8dca7125EAc444CB92aa);
        NNWContract = IERC721Enumerable(NNWContractAddress);
        cdbcontract = IERC721Enumerable(cdbcontractAddress);
        toadContract = IERC721Enumerable(toadzContractAddress);
        punksContract = IPUNK(punksContractAddress);
    }

    /// @notice Claim Papi Token for a given NNW ID
    /// @param tokenId The tokenId of the NNW NFT
    function claimById(uint256 tokenId, uint256 contractID) external {
        // Follow the Checks-Effects-Interactions pattern to prevent reentrancy
        // attacks

        // Checks

        // Check that the msgSender owns the token that is being claimed
        require(contractID == 1 || contractID == 2 || contractID == 3);

        if (contractID == 1) {
            require(
                _msgSender() == NNWContract.ownerOf(tokenId),
                "MUST_OWN_TOKEN_ID"
            );
        }

        if (contractID == 2) {
            require(
                _msgSender() == cdbcontract.ownerOf(tokenId),
                "MUST_OWN_TOKEN_ID"
            );
        }

        if (contractID == 3) {
            require(
                _msgSender() == toadContract.ownerOf(tokenId),
                "MUST_OWN_TOKEN_ID"
            );
        }

        // Further Checks, Effects, and Interactions are contained within the
        // _claim() function
        _claim(tokenId, _msgSender(), contractID);
    }

    /// @notice Claim Papi Token for all tokens owned by the sender
    /// @notice This function will run out of gas if you have too much NNW! If
    /// this is a concern, you should use claimRangeForOwner and claim Papi
    /// Token in batches.
    function claimAllForOwner(uint256 contractID) external {
        require(contractID == 1 || contractID == 2 || contractID == 3);

        // Checks
        if (contractID == 1) {
            uint256 tokenBalanceOwner = NNWContract.balanceOf(_msgSender());
            require(tokenBalanceOwner > 0, "NO_TOKENS_OWNED");
            for (uint256 i = 0; i < tokenBalanceOwner; i++) {
                // Further Checks, Effects, and Interactions are contained within
                // the _claim() function
                _claim(
                    NNWContract.tokenOfOwnerByIndex(_msgSender(), i),
                    _msgSender(),
                    contractID
                );
            }
        }

        if (contractID == 2) {
            uint256 tokenBalanceOwner = cdbcontract.balanceOf(_msgSender());
            require(tokenBalanceOwner > 0, "NO_TOKENS_OWNED");
            for (uint256 i = 0; i < tokenBalanceOwner; i++) {
                // Further Checks, Effects, and Interactions are contained within
                // the _claim() function
                _claim(
                    cdbcontract.tokenOfOwnerByIndex(_msgSender(), i),
                    _msgSender(),
                    contractID
                );
            }
        }

        if (contractID == 3) {
            uint256 tokenBalanceOwner = toadContract.balanceOf(_msgSender());
            require(tokenBalanceOwner > 0, "NO_TOKENS_OWNED");
            for (uint256 i = 0; i < tokenBalanceOwner; i++) {
                // Further Checks, Effects, and Interactions are contained within
                // the _claim() function
                _claim(
                    toadContract.tokenOfOwnerByIndex(_msgSender(), i),
                    _msgSender(),
                    contractID
                );
            }
        }

        // i < tokenBalanceOwner because tokenBalanceOwner is 1-indexed
    }

    /// @notice Claim Papi Token for all tokens owned by the sender within a
    /// given range
    /// @notice This function is useful if you own too much NNW to claim all at
    /// once or if you want to leave some NNW unclaimed. If you leave NNW
    /// unclaimed, however, you cannot claim it once the next season starts.
    function claimRangeForOwner(
        uint256 ownerIndexStart,
        uint256 ownerIndexEnd,
        uint256 contractID
    ) external {
        require(contractID == 1 || contractID == 2 || contractID == 3);

        if (contractID == 1) {
            uint256 tokenBalanceOwner = NNWContract.balanceOf(_msgSender());
            require(tokenBalanceOwner > 0, "NO_TOKENS_OWNED");
            require(
                ownerIndexStart >= 0 && ownerIndexEnd < tokenBalanceOwner,
                "INDEX_OUT_OF_RANGE"
            );
            for (uint256 i = ownerIndexStart; i <= ownerIndexEnd; i++) {
                // Further Checks, Effects, and Interactions are contained within
                // the _claim() function
                _claim(
                    NNWContract.tokenOfOwnerByIndex(_msgSender(), i),
                    _msgSender(),
                    contractID
                );
            }
        }

        if (contractID == 2) {
            uint256 tokenBalanceOwner = cdbcontract.balanceOf(_msgSender());
            require(tokenBalanceOwner > 0, "NO_TOKENS_OWNED");
            require(
                ownerIndexStart >= 0 && ownerIndexEnd < tokenBalanceOwner,
                "INDEX_OUT_OF_RANGE"
            );
            for (uint256 i = ownerIndexStart; i <= ownerIndexEnd; i++) {
                // Further Checks, Effects, and Interactions are contained within
                // the _claim() function
                _claim(
                    cdbcontract.tokenOfOwnerByIndex(_msgSender(), i),
                    _msgSender(),
                    contractID
                );
            }
        }

        if (contractID == 3) {
            uint256 tokenBalanceOwner = toadContract.balanceOf(_msgSender());
            require(tokenBalanceOwner > 0, "NO_TOKENS_OWNED");
            require(
                ownerIndexStart >= 0 && ownerIndexEnd < tokenBalanceOwner,
                "INDEX_OUT_OF_RANGE"
            );
            for (uint256 i = ownerIndexStart; i <= ownerIndexEnd; i++) {
                // Further Checks, Effects, and Interactions are contained within
                // the _claim() function
                _claim(
                    toadContract.tokenOfOwnerByIndex(_msgSender(), i),
                    _msgSender(),
                    contractID
                );
            }
        }
    }

    // Claim Punks

    function claimPunksById(uint256 tokenId) external {
        require(
            _msgSender() == punksContract.punkIndexToAddress(tokenId),
            "MUST_OWN_TOKEN_ID"
        );
        _claim(tokenId, _msgSender(), 4);
    }

    function claimPunksByMultiId(uint256[] memory tokenId) external {
        for (uint256 i = 0; i < tokenId.length; i++) {
            require(
                _msgSender() == punksContract.punkIndexToAddress(tokenId[i]),
                "MUST_OWN_TOKEN_ID"
            );
            _claim(tokenId[i], _msgSender(), 4);
        }
    }

    /// @dev Internal function to mint NNW upon claiming
    function _claim(
        uint256 tokenId,
        address tokenOwner,
        uint256 contractID
    ) internal {
        // Checks
        // Check that the token ID is in range
        // We use >= and <= to here because all of the token IDs are 0-indexed
        if (contractID == 1) {
            require(
                tokenId >= NNWtokenIdStart && tokenId <= NNWtokenIdEnd,
                "TOKEN_ID_OUT_OF_RANGE"
            );
            require(
                !seasonNNWClaimedByTokenId[season][tokenId],
                "GOLD_CLAIMED_FOR_TOKEN_ID"
            );
            seasonNNWClaimedByTokenId[season][tokenId] = true;
            _mint(tokenOwner, papiTokenPerTokenId);
        }

        if (contractID == 2) {
            require(
                tokenId >= cdbtokenIdStart && tokenId <= cdbtokenIdEnd,
                "TOKEN_ID_OUT_OF_RANGE"
            );
            require(
                !seasonCdbClaimedByTokenId[season][tokenId],
                "GOLD_CLAIMED_FOR_TOKEN_ID"
            );
            seasonCdbClaimedByTokenId[season][tokenId] = true;
            _mint(tokenOwner, papiTokenPerTokenId);
        }

        if (contractID == 3) {
            require(
                tokenId >= toadtokenIdStart && tokenId <= toadtokenIdEnd,
                "TOKEN_ID_OUT_OF_RANGE"
            );
            require(
                !seasonToadClaimedByTokenId[season][tokenId],
                "GOLD_CLAIMED_FOR_TOKEN_ID"
            );
            seasonToadClaimedByTokenId[season][tokenId] = true;
            _mint(tokenOwner, papiTokenPerTokenId);
        }

        if (contractID == 4) {
            require(
                tokenId >= punkstokenIdStart && tokenId <= punkstokenIdEnd,
                "TOKEN_ID_OUT_OF_RANGE"
            );
            require(
                !seasonOGpunksClaimedByTokenId[season][tokenId],
                "GOLD_CLAIMED_FOR_TOKEN_ID"
            );
            seasonOGpunksClaimedByTokenId[season][tokenId] = true;
            _mint(tokenOwner, papiTokenPerTokenId);
        }
    }

    /// @notice Allows the DAO to mint new tokens for use within the NNW
    /// Ecosystem
    /// @param amountDisplayValue The amount of NNW to mint. This should be
    /// input as the display value, not in raw decimals. If you want to mint
    /// 100 NNW, you should enter "100" rather than the value of 100 * 10^18.
    function daoMint(uint256 amountDisplayValue) external onlyOwner {
        _mint(owner(), amountDisplayValue * (10**decimals()));
    }

    /// @notice Allows the DAO to set a new contract address for NNW. This is
    /// relevant in the event that NNW migrates to a new contract.
    /// @param NNWContractAddress_ The new contract address for NNW
    function daoSetNNWContractAddress(address NNWContractAddress_)
        external
        onlyOwner
    {
        NNWContractAddress = NNWContractAddress_;
        NNWContract = IERC721Enumerable(NNWContractAddress);
    }

    /// @notice Allows the DAO to set the token IDs that are eligible to claim
    /// NNW
    /// @param tokenIdStart_ The start of the eligible token range
    /// @param tokenIdEnd_ The end of the eligible token range
    /// @dev This is relevant in case a future NNW contract has a different
    /// total supply of NNW
    function daoSetTokenIdRange(
        uint256 tokenIdStart_,
        uint256 tokenIdEnd_,
        uint256 contractID
    ) external onlyOwner {
        require(
            contractID == 1 ||
                contractID == 2 ||
                contractID == 3 ||
                contractID == 4
        );

        if (contractID == 1) {
            NNWtokenIdStart = tokenIdStart_;
            NNWtokenIdEnd = tokenIdEnd_;
        }

        if (contractID == 2) {
            cdbtokenIdStart = tokenIdStart_;
            cdbtokenIdEnd = tokenIdEnd_;
        }

        if (contractID == 3) {
            toadtokenIdStart = tokenIdStart_;
            toadtokenIdEnd = tokenIdEnd_;
        }

        if (contractID == 4) {
            punkstokenIdStart = tokenIdStart_;
            punkstokenIdEnd = tokenIdEnd_;
        }
    }

    /// @notice Allows the DAO to set a season for new Papi Token claims
    /// @param season_ The season to use for claiming NNW
    function daoSetSeason(uint256 season_) public onlyOwner {
        season = season_;
    }

    /// @notice Allows the DAO to set the amount of Papi Token that is
    /// claimed per token ID
    /// @param papiTokenDisplayValue The amount of NNW a user can claim.
    /// This should be input as the display value, not in raw decimals. If you
    /// want to mint 100 NNW, you should enter "100" rather than the value of
    /// 100 * 10^18.
    function daoSetpapiTokenPerTokenId(uint256 papiTokenDisplayValue)
        public
        onlyOwner
    {
        papiTokenPerTokenId = papiTokenDisplayValue * (10**decimals());
    }

    /// @notice Allows the DAO to set the season and Papi Token per token ID
    /// in one transaction. This ensures that there is not a gap where a user
    /// can claim more Papi Token than others
    /// @param season_ The season to use for claiming NNW
    /// @param papiTokenDisplayValue The amount of NNW a user can claim.
    /// This should be input as the display value, not in raw decimals. If you
    /// want to mint 100 NNW, you should enter "100" rather than the value of
    /// 100 * 10^18.
    /// @dev We would save a tiny amount of gas by modifying the season and
    /// papiToken variables directly. It is better practice for security,
    /// however, to avoid repeating code. This function is so rarely used that
    /// it's not worth moving these values into their own internal function to
    /// skip the gas used on the modifier check.
    function daoSetSeasonAndpapiTokenPerTokenID(
        uint256 season_,
        uint256 papiTokenDisplayValue
    ) external onlyOwner {
        daoSetSeason(season_);
        daoSetpapiTokenPerTokenId(papiTokenDisplayValue);
    }
}