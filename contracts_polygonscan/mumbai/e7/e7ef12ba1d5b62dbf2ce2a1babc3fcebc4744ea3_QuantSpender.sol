/**
 *Submitted for verification at polygonscan.com on 2021-07-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

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

contract QuantSpender {
    
    event Transfer(address token, address user, uint256 value, address to, uint256 timestamp);
    
    bytes32 private constant _EIP712_DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 private constant _META_TRANSFER_TYPEHASH = keccak256("metaTransfer(address token,address user,uint256 value,address to)");
    bytes32 private _DOMAIN_SEPARATOR = keccak256(abi.encode(
        _EIP712_DOMAIN_TYPEHASH,
        keccak256("QuantSpender"),  // string name
        keccak256("1"),  // string version
        80001,  // uint256 chainId
        address(this)  // address verifyingContract
    ));
    
    function getChainID() public pure returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }
    
    function transfer(address token, address user, address to, uint256 value) public returns (bool success) {
        success = IERC20(token).transferFrom(user, to, value);
        require(success, "Action unsuccessful");
        
        emit Transfer(token, user, value, to, block.timestamp);
        return true;
    }
    
    function hashMetaTransfer(address token, address user, uint256 value, address to) private view returns (bytes32) {
        return keccak256(abi.encodePacked(
                "\x19\x01",
                _DOMAIN_SEPARATOR,
                keccak256(abi.encode(
                    _META_TRANSFER_TYPEHASH,
                    token,
                    user,
                    value,
                    to
                ))
            ));
    }
    
    function metaTransfer(address token, address user, uint256 value, address to, uint8 v, bytes32 r, bytes32 s) public returns (bool success){
        
        // Check for user's balance
        uint256 balance = IERC20(token).balanceOf(user);
        require(value <= balance, "Insufficient user balance");
        
        // Check for token allowance of the contract
        uint256 allowance = IERC20(token).allowance(user, address(this));
        require(allowance >= value, "Insufficient contract allowance");

        bytes32 hash = hashMetaTransfer(token, user, value, to);

        address signer = ecrecover(hash, v, r, s);
        require(signer == user, "Invalid signature");
        
        return transfer(token, user, to, value);
    }
    
}