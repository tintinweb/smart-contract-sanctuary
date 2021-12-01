/**
 *Submitted for verification at Etherscan.io on 2021-12-01
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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



contract BridgeBase {
    address public admin;
    IERC20 token;
    event Deposit(address indexed from, address indexed to, uint256 amount);
    event Withdraw(address indexed from, address indexed to, uint256 amount );

    mapping(bytes32 => bool) private txList;

    struct Sign {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    constructor(address _token) {
        admin = msg.sender;
        token = IERC20(_token);
    }

    function verifySign(bytes32 txId, address to, uint256 amount, Sign memory sign) internal view {
        bytes32 hash = keccak256(abi.encodePacked(txId,to,amount));
        require(admin == ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)), sign.v, sign.r, sign.s), "Owner sign verification failed");
    }

    function deposit(uint256 amount) public returns(bool) {
        require(amount != 0,"Bridge: amount shouldn't be zero");
        bool transferred = token.transferFrom(msg.sender, address(this), amount);
        require(transferred,"Bridge: token tranfer is not done");
        emit Deposit(msg.sender,address(this),amount);
        return true;   
    }

    function withdraw(bytes32 txID, uint256 amount, Sign memory sign) public returns (bool) {
        require(token.balanceOf(address(this)) > amount, "Bridge: amount Exceed the balance");
        require(!txList[txID],"Bridge: withdraw Transaction is already done");
        verifySign(txID, msg.sender, amount, sign);
        token.transfer(msg.sender, amount);
        txList[txID] = true;
        emit Withdraw(address(this), msg.sender, amount);
        return true;
    }

    function getTxdetails (bytes32 txID) public view returns(bool) {
        return txList[txID];
    }

}
contract BridgeETH is BridgeBase {
    constructor(address token) BridgeBase(token) {}
}