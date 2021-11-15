import "../interfaces/IHypervisor.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Router {
  IHypervisor public pos;
  IERC20 public token0;
  IERC20 public token1;
  address public owner;
  address payable public client;
  address public keeper;
  uint256 MAX_INT = 2**256 - 1;

  constructor(
    address _token0,
    address _token1,
    address _pos
  ) {
    owner = msg.sender;
    client = msg.sender;
    keeper = msg.sender;
    token0 = IERC20(_token0);
    token1 = IERC20(_token1);
    pos = IHypervisor(_pos);
    token0.approve(_pos, MAX_INT);
    token1.approve(_pos, MAX_INT);
    pos.approve(_pos, MAX_INT);
  }

  function deposit(
        uint256 deposit0,
        uint256 deposit1
  ) external {
    require(msg.sender == keeper, "Only keeper allowed to execute deposit");
    pos.deposit(deposit0, deposit1, client);
  }

  function depositAll() external {
    require(msg.sender == keeper, "Only keeper allowed to execute deposit");
    pos.deposit(
      token0.balanceOf(address(this)),
      token1.balanceOf(address(this)),
      client
    );
  }

  function withdraw(uint256 shares) external {
    require(msg.sender == client, "Only client allowed to withdraw");
    pos.transferFrom(client, address(this), shares);
    pos.withdraw(shares, client, address(this));
  }

  function withdrawAll() external {
    require(msg.sender == client, "Only client allowed to withdraw");
    pos.transferFrom(client, address(this), pos.balanceOf(client)); 
    pos.withdraw(pos.balanceOf(address(this)), client, address(this));
  }

  function sweepTokens(address token) external {
    require(msg.sender == owner, "Only owner allowed to pull tokens");
    IERC20(token).transfer(owner, IERC20(token).balanceOf(address(this)));
  }

  function sweepEth() external {
    require(msg.sender == owner, "Only owner allowed to pull tokens");
    client.transfer(address(this).balance);
  }

  function transferClient(address payable newClient) external {
    require(msg.sender == owner, "Only owner allowed to change client");
    client = newClient;
  }

  function transferKeeper(address newKeeper) external {
    require(msg.sender == owner, "Only owner allowed to change keeper");
    keeper = newKeeper; 
  }

  function transferOwnership(address newOwner) external {
    require(msg.sender == owner, "Only owner alloed to change owner");
    owner = newOwner;
  }

}

// SPDX-License-Identifier: Unlicense

pragma solidity 0.7.6;

interface IHypervisor {
    function deposit(
        uint256,
        uint256,
        address
    ) external returns (uint256);

    function withdraw(
        uint256,
        address,
        address
    ) external returns (uint256, uint256);

    function balanceOf(address) external returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

