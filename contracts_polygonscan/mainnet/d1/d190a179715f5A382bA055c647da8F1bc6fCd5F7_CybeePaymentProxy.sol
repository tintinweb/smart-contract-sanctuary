// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "../MetaTransaction/NativeMetaTransaction.sol";
import "../MetaTransaction/ContextMixin.sol";

import "./CybeeProxy.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract CybeePaymentProxy is
    NativeMetaTransaction,
    CybeeProxy,
    Pausable,
    ContextMixin
{
    uint256 public maticPrice = 30 ether; // 30 MATIC
    uint256 public tokenPrice = 0.015 ether; // 0.015 WETH

    uint256 private _proxyPhasedSalesCount = 10_000;
    mapping(address => bool) private _minters;

    event MinterAdded(address indexed minter);
    event MinterRemoved(address indexed minter);

    constructor(address _cybee) {
        addMinter(_msgSender());

        _initializeProxy(_cybee);
        _initializeEIP712("Cybee");
    }

    function _msgSender() internal view override returns (address sender) {
        return ContextMixin.msgSender();
    }

    function mintCybee(address to, uint256 count) public payable whenNotPaused {
        if (!isMinter(_msgSender())) {
            if (msg.value == 0) {
                IERC20 paymentToken = IERC20(paymentToken());
                uint256 amount = tokenPrice * count;
                require(
                    paymentToken.transferFrom(
                        _msgSender(),
                        address(this),
                        amount
                    )
                );
            } else {
                require(
                    maticPrice * count <= msg.value,
                    "MATIC value sent is not correct"
                );
            }
        }
        _mintCybee(to, count);
    }

    function withdrawMatic() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No MATIC to withdraw");
        payable(_msgSender()).transfer(balance);
    }

    function withdrawToken() public onlyOwner {
        IERC20 token = IERC20(paymentToken());
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "No token to withdraw");
        token.transfer(address(this), balance);
    }

    function _checkPhasedSales(uint256 count) private {
        if (cybee.totalSupply() < _proxyPhasedSalesCount) {
            if (cybee.totalSupply() + count == _proxyPhasedSalesCount) {
                _pause();
                cybee.setPause(true);
            } else if (cybee.totalSupply() + count > _proxyPhasedSalesCount) {
                require(false, "Exceeds maximum Cybees supply");
            }
        }
    }

    function _mintCybee(address _to, uint256 _count) private {
        _checkPhasedSales(_count);

        address[] memory addresses = new address[](1);
        addresses[0] = _to;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = _count;

        cybee.claim(addresses, amounts);
    }

    function setPhasedSalesCount(uint256 _count) public override onlyOwner {
        super.setPhasedSalesCount(_count);
        _proxyPhasedSalesCount = _count;
    }

    function setMaticPrice(uint256 _price) public onlyOwner {
        maticPrice = _price;
    }

    function setTokenPrice(uint256 _price) public onlyOwner {
        tokenPrice = _price;
        setPrice(_price);
    }

    function pauseProxy() public onlyOwner {
        _pause();
    }

    function unpauseProxy() public onlyOwner {
        _unpause();
    }

    // AccessControl
    function transferProxyOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function renounceProxyOwnership() public onlyOwner {
        _transferOwnership(address(0));
    }

    function isMinter(address account) public view returns (bool) {
        return _minters[account];
    }

    function addMinter(address account) public onlyOwner {
        require(account != address(0), "Minter cannot be the zero address");
        require(!_minters[account], "Minter already added");

        _minters[account] = true;
        emit MinterAdded(account);
    }

    function removeMinter(address account) public onlyOwner {
        require(account != address(0), "Minter cannot be the zero address");
        require(_minters[account], "Minter not added");

        _minters[account] = false;
        emit MinterRemoved(account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./EIP712Base.sol";

contract NativeMetaTransaction is EIP712Base {
    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    bytes32 private constant META_TRANSACTION_TYPEHASH =
        keccak256(
            bytes(
                "MetaTransaction(uint256 nonce,address from,bytes functionSignature)"
            )
        );

    mapping(address => uint256) nonces;

    event MetaTransactionExecuted(
        address userAddress,
        address payable relayerAddress,
        bytes functionSignature
    );

    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public payable returns (bytes memory) {
        MetaTransaction memory metaTx = MetaTransaction({
            nonce: nonces[userAddress],
            from: userAddress,
            functionSignature: functionSignature
        });

        require(
            verify(userAddress, metaTx, sigR, sigS, sigV),
            "Signer and signature do not match"
        );

        nonces[userAddress] = nonces[userAddress] + 1;

        emit MetaTransactionExecuted(
            userAddress,
            payable(msg.sender),
            functionSignature
        );

        (bool success, bytes memory returnData) = address(this).call(
            abi.encodePacked(functionSignature, userAddress)
        );
        require(success, "Failed to execute meta transaction");

        return returnData;
    }

    function getNonce(address user) public view returns (uint256) {
        return nonces[user];
    }

    function hashMetaTransaction(MetaTransaction memory metaTx)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    META_TRANSACTION_TYPEHASH,
                    metaTx.nonce,
                    metaTx.from,
                    keccak256(metaTx.functionSignature)
                )
            );
    }

    function verify(
        address signer,
        MetaTransaction memory metaTx,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) internal view returns (bool) {
        require(signer != address(0), "NativeMetaTransaction: INVALID_SIGNER");
        return
            signer ==
            ecrecover(
                toTypedMessageHash(hashMetaTransaction(metaTx)),
                sigV,
                sigR,
                sigS
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

abstract contract ContextMixin {
    function msgSender() internal view returns (address payable sender) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = payable(msg.sender);
        }
        return sender;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./ICybee.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CybeeProxy is Ownable {
    ICybee public cybee;

    function _initializeProxy(address _cybee) internal {
        cybee = ICybee(_cybee);
    }

    // Addition Methods

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 balance = cybee.balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](balance);
        for (uint256 i = 0; i < balance; i++) {
            tokenIds[i] = cybee.tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    // Delegated Methods

    function claim(address[] memory _owners, uint256[] memory _tokenIds)
        public
        onlyOwner
    {
        cybee.claim(_owners, _tokenIds);
    }

    function transferOwnership(address newOwner) public override onlyOwner {
        cybee.transferOwnership(newOwner);
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        cybee.setBaseURI(_baseURI);
    }

    function setPause(bool pause) public onlyOwner {
        cybee.setPause(pause);
    }

    function setPaymentToken(address _token) public onlyOwner {
        cybee.setPaymentToken(_token);
    }

    function paymentToken() public view returns (address) {
        return address(cybee.paymentToken());
    }

    function setPhasedSalesCount(uint256 phasedSalesCount)
        public
        virtual
        onlyOwner
    {
        cybee.setPhasedSalesCount(phasedSalesCount);
    }

    function setPrice(uint256 _pricePerItem) public onlyOwner {
        cybee.setPrice(_pricePerItem);
    }

    function withdrawAll() public onlyOwner {
        cybee.withdrawAll();
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract Initializable {
    bool inited = false;

    modifier initializer() {
        require(!inited, "Already initialized");
        _;
        inited = true;
    }
}

contract EIP712Base is Initializable {
    struct EIP721Domain {
        string name;
        string version;
        address verifyingContract;
        bytes32 salt;
    }

    string public constant ERC712_VERSION = "1";

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
        keccak256(
            bytes(
                "EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)"
            )
        );

    bytes32 internal domainSeperator;

    function _initializeEIP712(string memory name) internal initializer {
        _setDomainSeperator(name);
    }

    function _setDomainSeperator(string memory name) internal {
        domainSeperator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(ERC712_VERSION)),
                address(this),
                bytes32(getChainId())
            )
        );
    }

    function getDomainSeperator() public view returns (bytes32) {
        return domainSeperator;
    }

    function getChainId() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    function toTypedMessageHash(bytes32 messageHash)
        internal
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19\x01", getDomainSeperator(), messageHash)
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface ICybee {
    // ERC721
    function totalSupply() external view returns (uint256);

    function balanceOf(address _owner) external view returns (uint256);

    function tokenOfOwnerByIndex(address _owner, uint256 _index)
        external
        view
        returns (uint256);

    // Ownable
    function transferOwnership(address newOwner) external;

    function renounceOwnership() external;

    // Cybee
    function mint(uint256 count) external;

    function claim(address[] memory recipients, uint256[] memory amounts)
        external;

    function withdrawAll() external;

    function setBaseURI(string memory baseURI) external;

    function setPhasedSalesCount(uint256 count) external;

    function setPause(bool pause) external;

    function setPrice(uint256 price) external;

    function price(uint256 count) external view returns (uint256);

    function setPaymentToken(address token) external;

    function paymentToken() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
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