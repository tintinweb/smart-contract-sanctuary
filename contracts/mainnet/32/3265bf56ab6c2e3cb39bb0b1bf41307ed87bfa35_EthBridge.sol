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
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Bridge {

    address immutable private bridgeOwner;
    uint256 private currentNonce;
    mapping (uint256 => mapping(uint256 => bool)) private nonces;

    event TokenSentToBridge(address _token, address _sender, uint256 _amount, uint256 _nonce, uint256 _fromChainId, uint256 _toChainId, string _data);
    event TokenWithdrawnFromBridge(address _token, address _sender, uint256 _amount, uint256 _nonce, uint256 _fromChainId, uint256 _toChainId);

    constructor () {
        bridgeOwner = msg.sender;
    }

    function convertTo(address _token, uint256 _amount, uint256 _toChainId, string memory _data) external {
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        currentNonce++;

        emit TokenSentToBridge(_token, msg.sender, _amount, currentNonce, _getChainId(), _toChainId, _data);
    }

    function convertFrom(bytes calldata _params, bytes calldata _messageLength, bytes calldata _signature) external {
        address _signer = _decodeSignature(_params, _messageLength, _signature);
        require(_signer == bridgeOwner, "BadSigner");

        (address _token, address _sender, uint256 _amount, uint256 _nonce, uint256 _fromChainId, uint256 _toChainId) = abi.decode(_params, (address, address, uint256, uint256, uint256, uint256));
        require(_toChainId == _getChainId(), "WrongChain");
        require(nonces[_fromChainId][_nonce] == false, "NonceRepeated");

        nonces[_fromChainId][_nonce] = true;
        IERC20(_token).transfer(_sender, _amount);

        emit TokenWithdrawnFromBridge(_token, _sender, _amount, _nonce, _fromChainId, _toChainId);
    }

    function getOwner() external view returns(address) {
        return bridgeOwner;
    }

    function getNonce(uint256 _chainId, uint256 _nonce) external view returns(bool) {
        return nonces[_chainId][_nonce];
    }

    function getCurrentNonce() external view returns(uint256) {
        return currentNonce;
    }

    function _decodeSignature(bytes memory _message, bytes memory _messageLength, bytes memory _signature) internal pure returns (address) {
        // Check the signature length
        if (_signature.length != 65) return (address(0));

        bytes32 messageHash = keccak256(abi.encodePacked(hex"19457468657265756d205369676e6564204d6573736167653a0a", _messageLength, _message));
        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(_signature, 0x20))
            s := mload(add(_signature, 0x40))
            v := byte(0, mload(add(_signature, 0x60)))
        }

        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) return address(0);

        if (v != 27 && v != 28) return address(0);
        
        return ecrecover(messageHash, v, r, s);
    }

    function _getChainId() internal view returns(uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Bridge.sol";

contract EthBridge is Bridge {

    constructor () Bridge() {
    }
}