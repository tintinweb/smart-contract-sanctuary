/**
 *Submitted for verification at polygonscan.com on 2021-12-02
*/

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

pragma solidity ^0.5.2;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

pragma solidity ^0.5.2;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     * @notice Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/common/mixin/ChainIdMixin.sol

pragma solidity ^0.5.2;

contract ChainIdMixin {
  bytes constant public networkId = hex"89";
  uint256 constant public CHAINID = 137;
}

// File: contracts/child/misc/EIP712.sol

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
        bytes32 domainHash = EIP712_DOMAIN_HASH;

        // Assembly for more efficient computing:
        // keccak256(abi.encode(
        //     EIP191_HEADER,
        //     domainHash,
        //     hashStruct
        // ));

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
        return result;
    }
}

// File: contracts/child/misc/LibTokenTransferOrder.sol

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

// File: contracts/child/ChildToken.sol

pragma solidity ^0.5.2;




contract ChildToken is Ownable, LibTokenTransferOrder {
    using SafeMath for uint256;

    // ERC721/ERC20 contract token address on root chain
    address public token;
    address public parent;
    address public parentOwner;

    mapping(bytes32 => bool) public disabledHashes;

    modifier isParentOwner() {
        require(msg.sender == parentOwner);
        _;
    }

    function deposit(address user, uint256 amountOrTokenId) public;
    function withdraw(uint256 amountOrTokenId) public payable;
    function setParent(address _parent) public;

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
}

// File: contracts/child/BaseERC20.sol

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

        bytes32 dataHash = getTokenTransferOrderHash(
            msg.sender,
            amount,
            data,
            expiration
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

// File: contracts/child/MRC20.sol

pragma solidity ^0.5.11;


/**
 * @title Matic token contract
 * @notice This contract is an ECR20 like wrapper over native ether (matic token) transfers on the matic chain
 * @dev ERC20 methods have been made payable while keeping their method signature same as other ChildERC20s on Matic
 */
contract MRC20 is BaseERC20 {
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

    function deposit(address user, uint256 amount) public onlyOwner {
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