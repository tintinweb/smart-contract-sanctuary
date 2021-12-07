/**
 *Submitted for verification at BscScan.com on 2021-12-07
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



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

// File: contracts/timelock.sol

pragma solidity ^0.8.4;


contract Timelock {
  address payable public immutable owner;

  constructor(address payable _owner) {
    owner = _owner; 
  }
function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }
  function deposit(address token, uint amount) external {
    require(!isContract(msg.sender));
    IERC20(token).transferFrom(msg.sender, address(this), amount);
  }

  receive() external payable {}

  function withdraw(address token, uint amount, address to) external {
    require(!isContract(msg.sender));
    require(msg.sender == owner, 'only owner');
    if(token == address(0)) { 
      owner.transfer(amount);
    } else {
      //IERC20(token).transfer(to, amount);
      IERC20(token).approve(address(this), amount);
      IERC20(token).transferFrom(address(this),to, amount);
    }
  }

  function emergencyWithdraw(address token)external {
    require(!isContract(msg.sender));
    require(msg.sender == owner, 'only owner');
    //approve
    uint contractbalance=IERC20(token).balanceOf(address(this));
    IERC20(token).approve(address(this), contractbalance);
    IERC20(token).transferFrom(address(this),msg.sender, (contractbalance));
  }

}