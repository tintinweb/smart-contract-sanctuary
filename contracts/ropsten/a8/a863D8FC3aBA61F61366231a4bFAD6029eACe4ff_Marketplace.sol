/**
 *Submitted for verification at Etherscan.io on 2022-01-09
*/

// Sources flattened with hardhat v2.6.4 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/utils/introspection/[email protected]

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


// File @openzeppelin/contracts/token/ERC721/[email protected]

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

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
    function getApproved(uint256 tokenId) external view returns (address operator);

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
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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


// File @openzeppelin/contracts/security/[email protected]

pragma solidity ^0.8.0;

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}


// File contracts/Marketplace.sol

pragma solidity ^0.8.11;




contract Marketplace is Ownable, Pausable {
    struct Account {
        uint256 reservedBalance;
    }

    struct Transaction {
        address buyer;
        address seller;
        address nftContract;
        address erc20Contract;
        uint256 tokenId;
        uint256 price;
        uint256 fees;
        uint256 nonce;
        uint256 timestamp;
    }

    mapping(address => Account) public accounts;
    mapping(address => bool) public supportedErc20;
    address public immutable cryptobysWallet;
    address public immutable pauser;
    uint256 public timeoutSeconds;
    bytes32 public constant HASH_TYPE =
        keccak256(
            "Transaction(address buyer,address seller,address nftContract,address erc20Contract,uint256 tokenId,uint256 price,uint256 fees,uint256 nonce,uint256 timestamp)"
        );
    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;
    bytes32 private immutable _DOMAIN_SEPARATOR;

    event Trade(
        uint256 indexed id,
        address indexed buyer,
        address indexed seller,
        address nftContract,
        address erc20Contract,
        uint256 tokenId,
        uint256 price
    );

    constructor(
        address _cryptobysWallet,
        address _pauser,
        uint256 _timeoutSeconds,
        string memory _version,
        uint256 _chainId
    ) {
        cryptobysWallet = _cryptobysWallet;
        pauser = _pauser;
        timeoutSeconds = _timeoutSeconds;
        _HASHED_NAME = keccak256(bytes("Cryptobys"));
        _HASHED_VERSION = keccak256(bytes(_version));
        _TYPE_HASH = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                _TYPE_HASH,
                _HASHED_NAME,
                _HASHED_VERSION,
                _chainId,
                address(this)
            )
        );
    }

    receive() external payable {
        revert();
    }

    fallback() external payable {
        revert();
    }

    function pause() external whenNotPaused {
        require(msg.sender == pauser);
        _pause();
    }

    function unPause() external whenPaused {
        require(msg.sender == pauser);
        _unpause();
    }

    function addSupportedErc20(address contractAddress) external whenNotPaused onlyOwner {
        supportedErc20[contractAddress] = true;
    }

    function withdrawFees(uint256 amount) external payable whenNotPaused {
        require(msg.sender == cryptobysWallet, "Unauthorized");
        (bool transferSuccess, ) = cryptobysWallet.call{value: amount}("");
        require(transferSuccess, "Transfer failed");
    }

    function setTimeoutSeconds(uint256 _timeoutSeconds)
        external
        whenNotPaused
        onlyOwner
    {
        timeoutSeconds = _timeoutSeconds;
    }

    function getReservedBalance(address account)
        external
        view
        whenNotPaused
        returns (uint256)
    {
        return accounts[account].reservedBalance;
    }

    function depositReservedFunds() external payable whenNotPaused {
        accounts[msg.sender].reservedBalance =
            accounts[msg.sender].reservedBalance +
            msg.value;
    }

    function withdraw(uint256 amount) external payable {
        uint256 contractStartingBalance = address(this).balance;
        uint256 amountAvailable = accounts[msg.sender].reservedBalance;
        require(amount <= amountAvailable, "Insufficient available balance");
        // update account balance
        accounts[msg.sender].reservedBalance -= amount;
        assert((accounts[msg.sender].reservedBalance) >= 0);
        // delete if final balance account is 0
        if (accounts[msg.sender].reservedBalance == 0)
            delete accounts[msg.sender];
        // transfer the eth
        (bool transferSuccess, ) = msg.sender.call{value: amount}("");
        require(transferSuccess, "Failed to withdraw Eth");
        assert(address(this).balance == contractStartingBalance - amount);
    }

    function transactOnBid(
        Transaction memory _transaction,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external payable whenNotPaused {
        address signer = hashTyped(_transaction, _v, _r, _s);
        require(signer == this.owner(), "Unauthorized");
        
        validateTimestamp(_transaction.timestamp);
        require(
            msg.sender == _transaction.seller,
            "Can only be triggered by seller"
        );
        require(_transaction.erc20Contract == address(0), "Invalid transaction currency");
        require(
            accounts[_transaction.buyer].reservedBalance >= _transaction.price,
            "Insufficient funds"
        );
        accounts[_transaction.buyer].reservedBalance -= _transaction.price;

        // transfer the token
        IERC721(_transaction.nftContract).transferFrom(
            _transaction.seller,
            _transaction.buyer,
            _transaction.tokenId
        );

        uint256 amount = _transaction.price - _transaction.fees;

        // transfer the eth
        (bool transferSuccess, ) = _transaction.seller.call{value: amount}("");
        require(transferSuccess, "Failed to send Ether to seller");
        emit Trade(
            _transaction.nonce,
            _transaction.buyer,
            _transaction.seller,
            _transaction.nftContract,
            _transaction.erc20Contract,
            _transaction.tokenId,
            _transaction.price
        );
    }

    function transactErc20(
        Transaction memory _transaction,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external payable {
        address signer = hashTyped(_transaction, _v, _r, _s);
        require(signer == this.owner(), "Unauthorized");
        validateTimestamp(_transaction.timestamp);
        require(
            msg.sender == _transaction.buyer,
            "Can only be triggered by buyer"
        );
        require(supportedErc20[_transaction.erc20Contract]==true, "Unsupported ERC20 transaction currency");
        IERC721(_transaction.nftContract).transferFrom(
            _transaction.seller,
            _transaction.buyer,
            _transaction.tokenId
        );

        uint256 amount = _transaction.price - _transaction.fees;

        IERC20(_transaction.erc20Contract).transferFrom(
            _transaction.buyer,
            _transaction.seller,
            amount
        );
        IERC20(_transaction.erc20Contract).transferFrom(
            _transaction.buyer,
            address(this),
            _transaction.fees
        );
        emit Trade(
            _transaction.nonce,
            _transaction.buyer,
            _transaction.seller,
            _transaction.nftContract,
            _transaction.erc20Contract,
            _transaction.tokenId,
            _transaction.price
        );
    }

    function transact(
        Transaction memory _transaction,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external payable whenNotPaused {
        address signer = hashTyped(_transaction, _v, _r, _s);
        require(signer == this.owner(), "Unauthorized");
        validateTimestamp(_transaction.timestamp);
        require(
            msg.value == _transaction.price,
            "Money sent mismatch with price"
        );
        require(msg.sender == _transaction.buyer, "Must be initiated by buyer");
        require(_transaction.erc20Contract == address(0), "Invalid transaction currency");

        // transfer the token
        IERC721(_transaction.nftContract).transferFrom(
            _transaction.seller,
            _transaction.buyer,
            _transaction.tokenId
        );

        uint256 amount = msg.value - _transaction.fees;
        // transfer the eth
        (bool transferSuccess, ) = _transaction.seller.call{value: amount}("");
        require(transferSuccess, "Failed to send Ether to seller");

        emit Trade(
            _transaction.nonce,
            _transaction.buyer,
            _transaction.seller,
            _transaction.nftContract,
            _transaction.erc20Contract,
            _transaction.tokenId,
            _transaction.price
        );
    }

    function transactOwner(Transaction memory _transaction)
        external
        payable
        whenNotPaused
        onlyOwner
    {
        validateTimestamp(_transaction.timestamp);
        IERC721(_transaction.nftContract).transferFrom(
            _transaction.seller,
            _transaction.buyer,
            _transaction.tokenId
        );
    }

    function validateTimestamp(uint256 _timestamp)
        internal
        whenNotPaused
    {
        if (block.timestamp > _timestamp) {
            require(
                ((block.timestamp - _timestamp) < timeoutSeconds),
                "Transaction timed out"
            );
        }        
    }

    function hashTyped(
        Transaction memory _transaction,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public view returns (address) {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                _DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        HASH_TYPE,
                        _transaction.buyer,
                        _transaction.seller,
                        _transaction.nftContract,
                        _transaction.erc20Contract,
                        _transaction.tokenId,
                        _transaction.price,
                        _transaction.fees,
                        _transaction.nonce,
                        _transaction.timestamp
                    )
                )
            )
        );

        address signer = ecrecover(digest, _v, _r, _s);
        return signer;
    }
}