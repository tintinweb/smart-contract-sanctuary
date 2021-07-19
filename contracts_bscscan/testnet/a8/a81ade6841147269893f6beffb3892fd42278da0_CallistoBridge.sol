/**
 *Submitted for verification at BscScan.com on 2021-07-19
*/

// SPDX-License-Identifier: No License (None)
pragma solidity ^0.8.0;

interface IBEP20TokenCloned {
    // initialize cloned token just for BEP20TokenCloned
    function initialize(address newOwner, string calldata name, string calldata symbol, uint8 decimals) external;
    function mint(address user, uint256 amount) external;
    function burnFrom(address account, uint256 amount) external returns(bool);
    function burn(uint256 amount) external returns(bool);
}

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

abstract contract Ownable {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
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
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract CallistoBridge is Ownable {
    using TransferHelper for address;

    address constant MAX_NATIVE_COINS = address(31); // addresses from address(1) to MAX_NATIVE_COINS are considered as native coins 
                                            // CLO = address(1)
    struct Token {
        address token;
        bool isWrapped;
    }
    address public authority;   // authority has to sign claim transaction (message) 
    address public tokenImplementation;    // implementation of wrapped token
    address public feeTo; // send fee to this address
    mapping(uint256 => mapping(bytes32 => bool)) public isTxProcessed;   // chainID => txID => isProcessed
    mapping(uint256 => mapping(address => Token)) public tokenPair;     // chainID => token address => Token struct

    event SetAuthority(address previousAuthority, address newAuthority);
    event SetFeeTo(address previousFeeTo, address newFeeTo);
    event Deposit(address indexed token, address indexed sender, uint256 value, uint256 toChainId, address toToken);
    event Claim(address indexed token, address indexed to, uint256 value, bytes32 txId, uint256 fromChainId, address fromToken);
    event Fee(address indexed sender, uint256 fee);
    event CreatePair(address toToken, bool isWrapped, address fromToken, uint256 fromChainId);

    constructor (address _tokenImplementation) {
        require(_tokenImplementation != address(0), "Wrong tokenImplementation");
        tokenImplementation = _tokenImplementation;
        feeTo = msg.sender;
    }

    // set Authority address
    function setAuthority(address newAuthority) external onlyOwner{
        require(newAuthority != address(0), "Zero address");
        address previousAuthority = authority;
        authority = newAuthority;
        emit SetAuthority(previousAuthority, newAuthority);
    }

    // set fee receiver address
    function setFeeTo(address newFeeTo) external onlyOwner{
        require(newFeeTo != address(0), "Zero address");
        address previousFeeTo = feeTo;
        feeTo = newFeeTo;
        emit SetFeeTo(previousFeeTo, newFeeTo);
    }

    // Create wrapped token for foreign token
    function createWrappedToken(
        address fromToken,
        uint256 fromChainId,
        string memory name,
        string memory symbol,
        uint8 decimals
    )
        external
        onlyOwner
    {
        require(fromToken != address(0), "Wrong token address");
        bytes32 salt = keccak256(abi.encodePacked(fromToken, fromChainId));
        address wrappedToken = Clones.cloneDeterministic(tokenImplementation, salt);
        IBEP20TokenCloned(wrappedToken).initialize(owner(), name, symbol, decimals);
        tokenPair[fromChainId][wrappedToken] = Token(fromToken, true);
        emit CreatePair(wrappedToken, true, fromToken, fromChainId);
    }

    // Create pair from foreign wrapped token to native token
    function createPair(address toToken, address fromToken, uint256 fromChainId) external onlyOwner {
        require(tokenPair[fromChainId][toToken].token == address(0), "Pair already exist");
        tokenPair[fromChainId][toToken] = Token(fromToken, false);
        emit CreatePair(toToken, false, fromToken, fromChainId);
    }

    // returns token address on native chain or address(0) if no pair
    function getPairFor(address fromToken, uint256 fromChainId) external view returns(address){
        bytes32 salt = keccak256(abi.encodePacked(fromToken, fromChainId));
        address toToken = Clones.predictDeterministicAddress(tokenImplementation, salt, address(this));
        if (tokenPair[fromChainId][toToken].token == address(0)) toToken = address(0);
        return toToken;
    }

    function getHash(
        bytes32 txId,
        address to, 
        uint256 value, 
        uint256 fromChainId
    )
        public
        view
        returns(bytes32)
    {
        return keccak256(abi.encodePacked(to, value, txId, fromChainId, block.chainid));
    }

    // claim
    function claim(
        address token,
        bytes32 txId,
        address to, 
        uint256 value, 
        uint256 fromChainId, 
        bytes32 r, 
        bytes32 s, 
        uint8 v
    ) 
        external 
    {
        require(!isTxProcessed[fromChainId][txId], "Transaction already processed");
        Token memory pair = tokenPair[fromChainId][token];
        require(pair.token != address(0), "There is no pair");
        isTxProcessed[fromChainId][txId] = true;
        bytes32 messageHash = keccak256(abi.encodePacked(token, to, value, txId, fromChainId, block.chainid));
        require(ecrecover(messageHash, v, r, s) == authority, "Wrong signature");
        if (token <= MAX_NATIVE_COINS) {
            to.safeTransferETH(value);
        } else {
            if(pair.isWrapped) {
                IBEP20TokenCloned(token).mint(to, value);
            } else {
                token.safeTransfer(to, value);
            }
        }
        emit Claim(token, to, value, txId, fromChainId, pair.token);
    }

    function depositTokens(address token, uint256 value, uint256 toChainId) external payable {
        Token memory pair = tokenPair[toChainId][token];
        require(pair.token != address(0), "There is no pair");
        uint256 fee = msg.value;
        if (token <= MAX_NATIVE_COINS) {
            require(value <= msg.value, "Wrong value");
            fee -= value;
        } else {
            if(pair.isWrapped) {
                IBEP20TokenCloned(token).burnFrom(msg.sender, value);
            } else {
                token.safeTransferFrom(msg.sender, address(this), value);
            }
        }
        if (fee != 0) {
            feeTo.safeTransferETH(fee);
            emit Fee(msg.sender, fee);
        }
        emit Deposit(token, msg.sender, value, toChainId, pair.token);
    }
}