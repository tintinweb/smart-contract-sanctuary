/**
 *Submitted for verification at Etherscan.io on 2021-09-13
*/

// File: IChildToken.sol

pragma solidity ^0.5.11;

interface IChildToken {
    event WithdrawTo(address indexed to);
    function deposit(address user, bytes calldata depositData) external;
}

// File: ChainIdMixin.sol

pragma solidity ^0.5.2;

contract ChainIdMixin {
  bytes constant public networkId = "c4abb0ddd80a413f35f9db2d5b4bc573417b95c4";
  uint256 constant public CHAINID = 1;
}

// File: EIP712.sol

pragma solidity ^0.5.2;


contract LibEIP712Domain is ChainIdMixin {
    string internal constant EIP712_DOMAIN_SCHEMA = "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)";
    bytes32 public constant EIP712_DOMAIN_SCHEMA_HASH = keccak256(
        abi.encodePacked(EIP712_DOMAIN_SCHEMA)
    );

    string internal constant EIP712_DOMAIN_NAME = "Matic Network";
    string internal constant EIP712_DOMAIN_VERSION = "1";
    uint256 internal constant EIP712_DOMAIN_CHAINID = CHAINID;

    bytes32 public EIP712_DOMAIN_HASH;

    constructor() public {
        EIP712_DOMAIN_HASH = keccak256(
            abi.encode(
                EIP712_DOMAIN_SCHEMA_HASH,
                keccak256(bytes(EIP712_DOMAIN_NAME)),
                keccak256(bytes(EIP712_DOMAIN_VERSION)),
                EIP712_DOMAIN_CHAINID,
                address(this)
            )
        );
    }

    function hashEIP712Message(bytes32 hashStruct)
        internal
        view
        returns (bytes32 result)
    {
        return _hashEIP712Message(hashStruct, EIP712_DOMAIN_HASH);
    }

    function hashEIP712MessageWithAddress(bytes32 hashStruct, address add)
        internal
        view
        returns (bytes32 result)
    {
        bytes32 domainHash = keccak256(
            abi.encode(
                EIP712_DOMAIN_SCHEMA_HASH,
                keccak256(bytes(EIP712_DOMAIN_NAME)),
                keccak256(bytes(EIP712_DOMAIN_VERSION)),
                EIP712_DOMAIN_CHAINID,
                add
            )
        );
        return _hashEIP712Message(hashStruct, domainHash);
    }

    function _hashEIP712Message(bytes32 hashStruct, bytes32 domainHash)
        internal
        pure
        returns (bytes32 result)
    {
        assembly {
            // Load free memory pointer
            let memPtr := mload(64)

            mstore(
                memPtr,
                0x1901000000000000000000000000000000000000000000000000000000000000
            ) // EIP191 header
            mstore(add(memPtr, 2), domainHash) // EIP712 domain hash
            mstore(add(memPtr, 34), hashStruct) // Hash of struct

            // Compute hash
            result := keccak256(memPtr, 66)
        }
    }
}

// File: LibTokenTransferOrder.sol

pragma solidity ^0.5.2;


contract LibTokenTransferOrder is LibEIP712Domain {
    string internal constant EIP712_TOKEN_TRANSFER_ORDER_SCHEMA = "TokenTransferOrder(address spender,uint256 tokenIdOrAmount,bytes32 data,uint256 expiration)";
    bytes32 public constant EIP712_TOKEN_TRANSFER_ORDER_SCHEMA_HASH = keccak256(
        abi.encodePacked(EIP712_TOKEN_TRANSFER_ORDER_SCHEMA)
    );

    struct TokenTransferOrder {
        address spender;
        uint256 tokenIdOrAmount;
        bytes32 data;
        uint256 expiration;
    }

    function getTokenTransferOrderHash(
        address spender,
        uint256 tokenIdOrAmount,
        bytes32 data,
        uint256 expiration
    ) public view returns (bytes32 orderHash) {
        orderHash = hashEIP712Message(
            hashTokenTransferOrder(spender, tokenIdOrAmount, data, expiration)
        );
    }

    function hashTokenTransferOrder(
        address spender,
        uint256 tokenIdOrAmount,
        bytes32 data,
        uint256 expiration
    ) internal pure returns (bytes32 result) {
        bytes32 schemaHash = EIP712_TOKEN_TRANSFER_ORDER_SCHEMA_HASH;

        // Assembly for more efficiently computing:
        // return keccak256(abi.encode(
        //   schemaHash,
        //   spender,
        //   tokenIdOrAmount,
        //   data,
        //   expiration
        // ));

        assembly {
            // Load free memory pointer
            let memPtr := mload(64)

            mstore(memPtr, schemaHash) // hash of schema
            mstore(
                add(memPtr, 32),
                and(spender, 0xffffffffffffffffffffffffffffffffffffffff)
            ) // spender
            mstore(add(memPtr, 64), tokenIdOrAmount) // tokenIdOrAmount
            mstore(add(memPtr, 96), data) // hash of data
            mstore(add(memPtr, 128), expiration) // expiration

            // Compute hash
            result := keccak256(memPtr, 160)
        }
        return result;
    }
}

// File: [email protected]/contracts/GSN/Context.sol

pragma solidity ^0.5.0;

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: [email protected]/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
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
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: [email protected]/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: ChildToken.sol

pragma solidity ^0.5.2;




contract ChildToken is Ownable, LibTokenTransferOrder {
    using SafeMath for uint256;

    // ERC721/ERC20 contract token address on root chain
    address public token;
    address public childChain;
    address public parent;

    mapping(bytes32 => bool) public disabledHashes;

    modifier onlyChildChain() {
        require(
            msg.sender == childChain,
            "Child token: caller is not the child chain contract"
        );
        _;
    }

    event LogFeeTransfer(
        address indexed token,
        address indexed from,
        address indexed to,
        uint256 amount,
        uint256 input1,
        uint256 input2,
        uint256 output1,
        uint256 output2
    );

    event ChildChainChanged(
        address indexed previousAddress,
        address indexed newAddress
    );

    event ParentChanged(
        address indexed previousAddress,
        address indexed newAddress
    );

    // function deposit(address user, uint256 amountOrTokenId) public;
    function withdraw(uint256 amountOrTokenId) public payable;

    function ecrecovery(bytes32 hash, bytes memory sig)
        public
        pure
        returns (address result)
    {
        bytes32 r;
        bytes32 s;
        uint8 v;
        if (sig.length != 65) {
            return address(0x0);
        }
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := and(mload(add(sig, 65)), 255)
        }
        // https://github.com/ethereum/go-ethereum/issues/2053
        if (v < 27) {
            v += 27;
        }
        if (v != 27 && v != 28) {
            return address(0x0);
        }
        // get address out of hash and signature
        result = ecrecover(hash, v, r, s);
        // ecrecover returns zero on error
        require(result != address(0x0), "Error in ecrecover");
    }

    // change child chain address
    function changeChildChain(address newAddress) public onlyOwner {
        require(
            newAddress != address(0),
            "Child token: new child address is the zero address"
        );
        emit ChildChainChanged(childChain, newAddress);
        childChain = newAddress;
    }

    // change parent address
    function setParent(address newAddress) public onlyOwner {
        require(
            newAddress != address(0),
            "Child token: new parent address is the zero address"
        );
        emit ParentChanged(parent, newAddress);
        parent = newAddress;
    }
}

// File: BaseERC20.sol

pragma solidity ^0.5.2;


contract BaseERC20 is ChildToken {
    event Deposit(
        address indexed token,
        address indexed from,
        uint256 amount,
        uint256 input1,
        uint256 output1
    );

    event Withdraw(
        address indexed token,
        address indexed from,
        uint256 amount,
        uint256 input1,
        uint256 output1
    );

    event LogTransfer(
        address indexed token,
        address indexed from,
        address indexed to,
        uint256 amount,
        uint256 input1,
        uint256 input2,
        uint256 output1,
        uint256 output2
    );

    constructor() public {}

    function transferWithSig(
        bytes calldata sig,
        uint256 amount,
        bytes32 data,
        uint256 expiration,
        address to
    ) external returns (address from) {
        require(amount > 0);
        require(
            expiration == 0 || block.number <= expiration,
            "Signature is expired"
        );

        bytes32 dataHash = hashEIP712MessageWithAddress(
            hashTokenTransferOrder(msg.sender, amount, data, expiration),
            address(this)
        );

        require(disabledHashes[dataHash] == false, "Sig deactivated");
        disabledHashes[dataHash] = true;

        from = ecrecovery(dataHash, sig);
        _transferFrom(from, address(uint160(to)), amount);
    }

    function balanceOf(address account) external view returns (uint256);
    function _transfer(address sender, address recipient, uint256 amount)
        internal;

    /// @param from Address from where tokens are withdrawn.
    /// @param to Address to where tokens are sent.
    /// @param value Number of tokens to transfer.
    /// @return Returns success of function call.
    function _transferFrom(address from, address to, uint256 value)
        internal
        returns (bool)
    {
        uint256 input1 = this.balanceOf(from);
        uint256 input2 = this.balanceOf(to);
        _transfer(from, to, value);
        emit LogTransfer(
            token,
            from,
            to,
            value,
            input1,
            input2,
            this.balanceOf(from),
            this.balanceOf(to)
        );
        return true;
    }
}

// File: MRC20.sol

pragma solidity ^0.5.11;



/**
 * @title Matic token contract
 * @notice This contract is an ECR20 like wrapper over native ether (matic token) transfers on the matic chain
 * @dev ERC20 methods have been made payable while keeping their method signature same as other ChildERC20s on Matic
 */
contract MRC20 is BaseERC20, IChildToken {
    event Transfer(address indexed from, address indexed to, uint256 value);

    uint256 public currentSupply = 0;
    uint8 private constant DECIMALS = 18;
    bool isInitialized;

    constructor() public {}

    function initialize(address _childChain, address _token) public {
        // Todo: once BorValidator(@0x1000) contract added uncomment me
        // require(msg.sender == address(0x1000));
        require(!isInitialized, "The contract is already initialized");
        isInitialized = true;
        token = _token;
        _transferOwnership(_childChain);
    }

    function setParent(address) public {
        revert("Disabled feature");
    }

    function deposit(address user, bytes calldata depositData)
        external
        onlyOwner
    {
        uint256 amount = abi.decode(depositData, (uint256));
        _deposit(user, amount);
    }

    function _deposit(address user, uint256 amount) internal {
        // check for amount and user
        require(
            amount > 0 && user != address(0x0),
            "Insufficient amount or invalid user"
        );

        // input balance
        uint256 input1 = balanceOf(user);

        // transfer amount to user
        address payable _user = address(uint160(user));
        _user.transfer(amount);

        currentSupply = currentSupply.add(amount);

        // deposit events
        emit Deposit(token, user, amount, input1, balanceOf(user));
    }

    function withdraw(uint256 amount) public payable {
        address user = msg.sender;
        // input balance
        uint256 input = balanceOf(user);

        currentSupply = currentSupply.sub(amount);
        // check for amount
        require(
            amount > 0 && msg.value == amount,
            "Insufficient amount"
        );

        // withdraw event
        emit Withdraw(token, user, amount, input, balanceOf(user));
        emit Transfer(user, address(0), amount);
    }

    function withdrawTo(address to, uint256 amount) public payable {
        withdraw(amount);
        emit WithdrawTo(to);
    }

    function name() public pure returns (string memory) {
        return "Matic Token";
    }

    function symbol() public pure returns (string memory) {
        return "MATIC";
    }

    function decimals() public pure returns (uint8) {
        return DECIMALS;
    }

    function totalSupply() public view returns (uint256) {
        return 10000000000 * 10**uint256(DECIMALS);
    }

    function balanceOf(address account) public view returns (uint256) {
        return account.balance;
    }

    /// @dev Function that is called when a user or another contract wants to transfer funds.
    /// @param to Address of token receiver.
    /// @param value Number of tokens to transfer.
    /// @return Returns success of function call.
    function transfer(address to, uint256 value) public payable returns (bool) {
        if (msg.value != value) {
            return false;
        }
        return _transferFrom(msg.sender, to, value);
    }

    /**
   * @dev _transfer is invoked by _transferFrom method that is inherited from BaseERC20.
   * This enables us to transfer MaticEth between users while keeping the interface same as that of an ERC20 Token.
   */
    function _transfer(address sender, address recipient, uint256 amount)
        internal
    {
        require(recipient != address(this), "can't send to MRC20");
        address(uint160(recipient)).transfer(amount);
        emit Transfer(sender, recipient, amount);
    }
}