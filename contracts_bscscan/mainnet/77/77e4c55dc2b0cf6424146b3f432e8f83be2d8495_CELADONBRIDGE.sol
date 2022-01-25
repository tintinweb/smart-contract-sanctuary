/**
 *Submitted for verification at BscScan.com on 2022-01-25
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;
interface IBEP20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8);

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory);

  /**
  * @dev Returns the token name.
  */
  function name() external view returns (string memory);

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view returns (address);

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
  function allowance(address _owner, address spender) external view returns (uint256);

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



contract BridgeBase {
    address public admin;
    IBEP20 public token;
    event Deposit(address indexed from, address indexed to, uint256 amount);
    event Withdraw(address indexed from, address indexed to, uint256 amount);

    mapping(bytes32 => bool) private txList;

    struct Sign {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    constructor(address _token) {
        admin = msg.sender;
        token = IBEP20(_token);
    }

    function verifySign(bytes32 txId, address to, uint256 amount, Sign memory sign) internal view {
        bytes32 hash = keccak256(abi.encodePacked(txId,to,amount));
        require(admin == ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)), sign.v, sign.r, sign.s), "Owner sign verification failed");
    }

    function deposit(uint256 amount) public returns(bool) {
        require(amount != 0,"Bridge: amount shouldn't be zero");
        bool transferred = token.transferFrom(msg.sender, address(this), amount);
        require(transferred,"Bridge: token transfer is not done");
        emit Deposit(msg.sender, address(this), amount);
        return true;   
    }

    function withdraw(bytes32 txID, uint256 amount, Sign memory sign) public returns (bool) {
        require(token.balanceOf(address(this)) > amount, "Bridge: amount exceeds the balance");
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
contract CELADONBRIDGE is BridgeBase {
    constructor(address token) BridgeBase(token) {}
}