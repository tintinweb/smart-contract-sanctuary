/**
 *Submitted for verification at BscScan.com on 2021-07-21
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
    
    uint256 public threshold;   // minimum number of signatures required to approve swap
    address public tokenImplementation;    // implementation of wrapped token
    address public feeTo; // send fee to this address
    address[] public authorities;   // list of authorities
    mapping(address => bool) isAuthority; // authority has to sign claim transaction (message)
    mapping(uint256 => mapping(bytes32 => bool)) public isTxProcessed;   // chainID => txID => isProcessed
    mapping(uint256 => mapping(address => Token)) public tokenPair;     // chainID => token address => Token struct

    event SetAuthority(address authority, bool isEnable);
    event SetFeeTo(address previousFeeTo, address newFeeTo);
    event SetThreshold(uint256 threshold);
    event Deposit(address indexed token, address indexed sender, uint256 value, uint256 toChainId, address toToken);
    event Claim(address indexed token, address indexed to, uint256 value, bytes32 txId, uint256 fromChainId, address fromToken);
    event Fee(address indexed sender, uint256 fee);
    event CreatePair(address toToken, bool isWrapped, address fromToken, uint256 fromChainId);

    constructor (address _tokenImplementation) {
        require(_tokenImplementation != address(0), "Wrong tokenImplementation");
        tokenImplementation = _tokenImplementation;
        feeTo = msg.sender;
        threshold = 1;
    }

    // get number of authorities
    function getAuthoritiesNumber() external view returns(uint256) {
        return authorities.length;
    }

    // set/remove Authority address
    function setAuthority(address authority, bool isEnable) external onlyOwner{
        require(authority != address(0), "Zero address");
        if (isEnable) {
            require(!isAuthority[authority], "Authority already enabled");
            require(authorities.length < 50, "Too much authorities");   // to avoid OUT_OF_GAS exception
            isAuthority[authority] = true;
            authorities.push(authority);
        } else {
            require(isAuthority[authority], "Authority already disabled");
            isAuthority[authority] = false;
            uint n = authorities.length;    // use local variable to save gas
            for (uint i = 0; i < n; i++) {  // maximum number of authorities is 50
                if(authorities[i] == authority) {
                    authorities[i] = authorities[n-1];
                    authorities.pop();
                    break;
                }
            }
        }
        emit SetAuthority(authority, isEnable);
    }

    // set fee receiver address
    function setFeeTo(address newFeeTo) external onlyOwner{
        require(newFeeTo != address(0), "Zero address");
        address previousFeeTo = feeTo;
        feeTo = newFeeTo;
        emit SetFeeTo(previousFeeTo, newFeeTo);
    }

    // set threshold - minimum number of signatures required to approve swap
    function setThreshold(uint256 _threshold) external onlyOwner{
        require(threshold != 0 && threshold <= authorities.length, "Wrong threshold");
        threshold = _threshold;
        emit SetThreshold(threshold);
    }

    // Create wrapped token for foreign token
    function createWrappedToken(
        address fromToken,      // foreign token address
        uint256 fromChainId,    // foreign chain ID where token deployed
        string memory name,     // wrapped token name
        string memory symbol,   // wrapped token symbol
        uint8 decimals          // wrapped token decimals (should be the same as in original token)
    )
        external
        onlyOwner
    {
        require(fromToken != address(0), "Wrong token address");
        bytes32 salt = keccak256(abi.encodePacked(fromToken, fromChainId));
        address wrappedToken = Clones.cloneDeterministic(tokenImplementation, salt);
        IBEP20TokenCloned(wrappedToken).initialize(owner(), name, symbol, decimals);
        tokenPair[fromChainId][wrappedToken] = Token(fromToken, true);
        emit CreatePair(wrappedToken, true, fromToken, fromChainId); //wrappedToken - wrapped token contract address
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

    function depositTokens(
        address token,      // token that user send (if token address < 32, then send native coin)
        uint256 value,      // tokens value
        uint256 toChainId   // destination chain Id where will be claimed tokens
    ) 
        external
        payable 
    {
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

    // claim
    function claim(
        address token,          // token to receive
        bytes32 txId,           // deposit transaction hash on fromChain 
        address to,             // user address
        uint256 value,          // value of tokens
        uint256 fromChainId,    // chain ID where user deposited
        bytes calldata sig      // authority signature
    ) 
        external 
    {
        bytes[] memory s = new bytes[](1);
        s[0] = sig;
        _claim(token, txId, to, value, fromChainId, s);
    }

    // claim Multi signature
    function claim(
        address token,          // token to receive
        bytes32 txId,           // deposit transaction hash on fromChain 
        address to,             // user address
        uint256 value,          // value of tokens
        uint256 fromChainId,    // chain ID where user deposited
        bytes[] calldata sig    // authority signature
    ) 
        external 
    {
        _claim(token, txId, to, value, fromChainId, sig);
    }

    // claim
    function _claim(
        address token,          // token to receive
        bytes32 txId,           // deposit transaction hash on fromChain 
        address to,             // user address
        uint256 value,          // value of tokens
        uint256 fromChainId,    // chain ID where user deposited
        bytes[] memory sig      // authority signature
    ) 
        internal 
    {
        uint256 t;
        require(!isTxProcessed[fromChainId][txId], "Transaction already processed");
        Token memory pair = tokenPair[fromChainId][token];
        require(pair.token != address(0), "There is no pair");
        isTxProcessed[fromChainId][txId] = true;
        bytes32 messageHash = keccak256(abi.encodePacked(token, to, value, txId, fromChainId, block.chainid));
        messageHash = prefixed(messageHash);
        for (uint i = 0; i < sig.length; i++) {
            if (isAuthority[recoverSigner(messageHash, sig[i])]) t++;
        }
        require(threshold <= t, "Require more signatures");

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

    // Signature methods

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (uint8 v, bytes32 r, bytes32 s)
    {
        require(sig.length == 65);
        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }
    }

    function recoverSigner(bytes32 message, bytes memory sig)
        internal
        pure
        returns (address)
    {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = splitSignature(sig);

        return ecrecover(message, v, r, s);
    }

    // Builds a prefixed hash to mimic the behavior of eth_sign.
    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }     
}