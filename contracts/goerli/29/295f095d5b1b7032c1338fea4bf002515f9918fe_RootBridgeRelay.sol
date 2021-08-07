/**
 *Submitted for verification at Etherscan.io on 2021-08-06
*/

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

abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}
interface IPlasmaBridge {
  event DepositERC20(address indexed depositor, address indexed depositReceiver, address indexed rootToken, uint256 amount);
  //matic deposits
  function depositERC20ForUser(address _token, address _user, uint256 _amount) external;
}
interface IPOSBridge {
  event DepositERC20(address indexed depositor, address indexed depositReceiver, address indexed rootToken, bytes amount);
  event DepositETH(address indexed depositor, address indexed depositReceiver, uint256 amount);
  //eth deposits
  function depositEtherFor(address user) external payable;
  //erc20 deposits
  function depositFor(address user, address rootToken, bytes calldata depositData) external;
}
/**
 * @title XXX, LLC. 
 * @dev Implements Openzeppelin Audited Contracts
 * @author XXX
 *
 * @notice this contract is meant for forwarding ERC20 and ETH accross the polygon bridge system.
 * This contract is meant to be a logic contract to work in conjunction with a proxy network.
 */
contract RootBridgeRelay is Initializable {
  event Relay(address indexed destination, address indexed currency, uint256 amount);
  //ETHER address
  address constant public ETHER_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
  //max integer value
  uint256 constant public MAX_INT = 2**256 - 1;

  //polygon network receiving address
  address payable public recipient;
  // mainnet plasma bridge
  IPlasmaBridge public plasmaBridge;
  // mainnet PoS bridge
  IPOSBridge public posBridge;
  // mainnet predicate
  address public predicate;
  //erc20 token (mainnet)
  IERC20 public matic;

  /**
   * @notice initializes the contract with the addresses of the polygon PoS and Plasma bridges,
   * the address of the bridge predicate, and mainnet address of the matic ERC20 token
   * @dev the recipient receives the same address as there will be a corresponding address on the adjoining network
   * @dev the reason for the use of the initialize function belonging to the initializable class
   * is to allow this contract to behave as the logic contract behind proxies.
   * @dev this function is called with proxy deployment to update state data
   * @dev uses initializer modifier to only allow one initialization per proxy
   * @param plasma the address the polygon-plasma bridge on the mainnet
   * @param pos the address the polygon-pos bridge on the mainnet
   * @param plasma the address the polygon-token predicate on the mainnet
   */
  function initialize(IPlasmaBridge plasma, IPOSBridge pos, address predicate_, IERC20 matic_) public initializer() {
    recipient = payable(address(this));
    predicate = predicate_;
    plasmaBridge = plasma;
    posBridge = pos;
    matic = matic_;
  }

  /**
  * @notice pushes token transfers through to the appropriate bridge
  * @dev the contract is designed in a way where anyone can call the function without risking funds
  * @param token is address of the token that is desired to be pushed accross the bridge
  * @param amount is integer value of the quantity of the token
  * @return a boolean value indicating whether the operation succeeded.
  */
  function bridgeTransfer(IERC20 token, uint256 amount) external payable returns (bool) {
    if (token == matic) {
      transferERCToPlasmaBridge(amount);
    } else {
      transferERCToBridge(token, amount);
    }
    return true;
  }

  /**
  * @notice pushes token transfers through to the PoS bridge
  * @dev this is for ERC20 tokens that are not the matic token
  * @dev only tokens that are already mapped on the bridge will succeed
  * @param token is address of the token that is desired to be pushed accross the bridge
  * @param amount is integer value of the quantity of the token
  */
  function transferERCToBridge(IERC20 token, uint256 amount) internal {
    if (amount > token.allowance(recipient, predicate)) {approveERC20(token, predicate);}
    posBridge.depositFor(recipient, address(token), abi.encodePacked(amount));
    emit Relay(recipient, address(token), amount);
  }

  /**
  * @notice pushes matic token transfers through to the plasma bridge
  * @dev this is for the matic token
  * @param amount is integer value of the quantity of the matic token
  */
  function transferERCToPlasmaBridge(uint256 amount) internal {
    if (amount > matic.allowance(recipient, address(plasmaBridge))) {approveERC20(matic, address(plasmaBridge));}
    plasmaBridge.depositERC20ForUser(address(matic), recipient, amount);
    emit Relay(recipient, address(matic), amount);
  }

  /**
  * @notice pushes ETHER transfers through to the PoS bridge
  * @dev this function is called automatically when ETH is transferred to the contract
  * @dev WETH will be minted to the recipient
  * @param amount is integer value of the quantity of ETH
  */
  function transferETHToBridge(uint256 amount) internal {
    require(amount <= recipient.balance, "RootBridgeRelay: insufficient balance");
    posBridge.depositEtherFor{value: amount}(recipient);
    emit Relay(recipient, ETHER_ADDRESS, amount);
  }

  /**
  * @notice this approves any tokens for use by the predicate
  * @dev this function is called automatically when the allowance is not high enough for a particular token
  * @param token is address of the token needed to be approved
  * @param bridge is address of the token spender
  */
  function approveERC20(IERC20 token, address bridge) internal {
    require(token.approve(bridge, MAX_INT), "RootBridgeRelay: Failed to approve tokens");
  }

  /**
  * @notice receives ETHER
  * @dev this function is called automatically call transferETHToBridge() with the msg.value
  */
  receive() external payable {
    transferETHToBridge(msg.value);
  }
}