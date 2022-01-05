//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BridgeBase.sol";

contract BridgeBsc is BridgeBase {
    constructor(
        address _tokenToBridge,
        address _bridgedTokenAddress,
        uint256 _chainIdFrom,
        uint256 _chainIdTo,
        string memory _chainNameFrom,
        string memory _chainNameTo
    )
        BridgeBase(
            _tokenToBridge,
            _bridgedTokenAddress,
            _chainIdFrom,
            _chainIdTo,
            _chainNameFrom,
            _chainNameTo
        )
    {}
}

pragma solidity ^0.8.0;

interface IToken {
  function mint(address to, uint amount) external;
  function burn(address owner, uint amount) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Itoken.sol";

contract BridgeBase {
    address public admin;
    IToken public token;
    IToken public bridgedToken;
    mapping(address => mapping(uint256 => bool)) public processedNonces;
    uint256 public totalSupply;
    uint256 public bridgedTotalSupply;
    uint256 chainId;
    string public chainName;
    mapping(uint256 => Chain) public bridgedChains;
    enum Step {
        Burn,
        Mint
    }
    event Transfer(
        address from,
        address to,
        uint256 amount,
        uint256 date,
        uint256 nonce,
        bytes signature,
        Step indexed step
    );
    struct Chain {
        uint256 chainId;
        string chainName;
        address bridgedTokenAddress;
        uint256 bridgedSupply;
    }
    event BridgedTokenUpdated(address bridgedTokenAddress, uint256 date);
    event NewChainAdded(
        uint256 chainId,
        string chainName,
        address tokenAddress,
        uint256 date
    );
    event BridgedTokens(
        uint256 chainId,
        address to,
        uint256 amount,
        uint256 date
    );
    event UnbridgedTokens(address to, uint256 amount, uint256 date);
    event ChainUpdated(
        uint256 chainId,
        string chainName,
        address tokenAddress,
        uint256 date
    );

    function addChain(
        uint256 _chainId,
        string memory _chainName,
        address _tokenAddress
    ) external {
        assert(msg.sender == admin);
        _addChain(_chainId, _chainName, _tokenAddress);
    }

    function _addChain(
        uint256 _chainId,
        string memory _chainName,
        address _tokenAddress
    ) internal {
        bridgedChains[_chainId] = Chain(_chainId, _chainName, _tokenAddress, 0);
        emit NewChainAdded(
            _chainId,
            _chainName,
            _tokenAddress,
            block.timestamp
        );
    }

    function updateChain(
        uint256 _chainId,
        string memory _chainName,
        address _tokenAddress
    ) external {
        assert(msg.sender == admin);
        bridgedChains[_chainId].bridgedTokenAddress = _tokenAddress;
        bridgedChains[_chainId].chainId = _chainId;
        bridgedChains[_chainId].chainName = _chainName;
        emit ChainUpdated(_chainId, _chainName, _tokenAddress, block.timestamp);
    }

    function updateBridgedToken(address _tokenAddress) external {
        assert(msg.sender == admin);
        bridgedToken = IToken(_tokenAddress);

        emit BridgedTokenUpdated(_tokenAddress, block.timestamp);
    }

    constructor(
        address _tokenToBridge,
        address _bridgedTokenAddress,
        uint256 _chainIdFrom,
        uint256 _chainIdTo,
        string memory _chainNameFrom,
        string memory _chainNameTo
    ) {
        admin = msg.sender;
        token = IToken(_tokenToBridge);
        totalSupply = 0;
        chainId = _chainIdFrom;
        chainName = _chainNameFrom;
        bridgedTotalSupply = 0;
        _addChain(_chainIdTo, _chainNameTo, _bridgedTokenAddress);
    }

    function bridgeTokens(uint256 _chainId, uint256 amount) public payable {
        token.burn(msg.sender, amount);
        totalSupply -= amount;

        emit BridgedTokens(_chainId, msg.sender, amount, block.timestamp);
    }

    function unbridgeTokens(address to, uint256 amount) public payable {
        assert(msg.sender == admin);
        token.burn(msg.sender, amount);
        totalSupply -= amount;

        emit UnbridgedTokens(to, amount, block.timestamp);
    }

    function burn(
        address to,
        uint256 amount,
        uint256 nonce,
        bytes calldata signature
    ) external {
        require(
            processedNonces[msg.sender][nonce] == false,
            "transfer already processed"
        );
        processedNonces[msg.sender][nonce] = true;
        token.burn(msg.sender, amount);
        emit Transfer(
            msg.sender,
            to,
            amount,
            block.timestamp,
            nonce,
            signature,
            Step.Burn
        );
    }

    function mint(
        address from,
        address to,
        uint256 amount,
        uint256 nonce,
        bytes calldata signature
    ) external {
        bytes32 message = prefixed(
            keccak256(abi.encodePacked(from, to, amount, nonce))
        );
        require(recoverSigner(message, signature) == from, "wrong signature");
        require(
            processedNonces[from][nonce] == false,
            "transfer already processed"
        );
        processedNonces[from][nonce] = true;
        totalSupply += amount;
        token.mint(to, amount);
        emit Transfer(
            from,
            to,
            amount,
            block.timestamp,
            nonce,
            signature,
            Step.Mint
        );
    }

    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
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

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            uint8,
            bytes32,
            bytes32
        )
    {
        require(sig.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }
}

// SPDX-License-Identifier: MIT

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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