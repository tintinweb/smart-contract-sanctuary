/**
 *Submitted for verification at Etherscan.io on 2021-04-06
*/

// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol

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

// File: contracts/Exchange.sol

pragma solidity ^0.8.0;


contract Exchange {
    mapping(address => uint256) public nonces;

    function getMessageHash(address _addr, bool _typeOrder, uint256 _amount, uint256 _price, address _token1, address _token2, uint256 _nonce) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_addr, _typeOrder, _amount, _price, _token1, _token2, _nonce));
    }

    function _swap(address _addr1, address _addr2, address _token1, address _token2, uint256 _amount1, uint256 _amount2) private {
        require(_addr1 != _addr2);
        IERC20 token1 = IERC20(_token1);
        IERC20 token2 = IERC20(_token2);
        token1.transferFrom(_addr2, _addr1, _amount1);
        token2.transferFrom(_addr1, _addr2, _amount2);
    }

    function swap(address _addr, bool _typeOrder, uint256 _amount, uint256 _price, address _token1, address _token2, uint256 _nonce, bytes memory _signature) public {
        require(nonces[_addr] == _nonce, "Invalid nonce");
        require(verify(_addr, _typeOrder, _amount, _price, _token1, _token2, _nonce, _signature), "Invalid signature");

        _swap(msg.sender, _addr, _token1, _token2, _amount, _price * _amount);

        nonces[_addr]++;
    }

    function getEthSignedMessageHash(bytes32 _messageHash) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }

    function verify(address _addr, bool _typeOrder, uint256 _amount, uint256 _price, address _token1, address _token2, uint256 _nonce, bytes memory _signature) public view returns (bool) {
        bytes32 messageHash = getMessageHash(_addr, _typeOrder, _amount, _price, _token1, _token2, _nonce);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        address recoveredSigner = recoverSigner(ethSignedMessageHash, _signature);
        return recoveredSigner == _addr;
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature)
        public pure returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig) public pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "invalid signature length");

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }
}