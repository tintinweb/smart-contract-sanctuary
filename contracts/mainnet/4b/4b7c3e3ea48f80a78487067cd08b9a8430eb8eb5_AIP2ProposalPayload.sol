/**
 *Submitted for verification at Etherscan.io on 2020-11-17
*/

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

interface ITokenDistributor {

  function initialize(address[] memory _receivers, uint[] memory _percentages) external;

  function distribute(IERC20[] memory _tokens) external;

  function getDistribution()
    external
    view
    returns (address[] memory receivers, uint256[] memory percentages);
}

interface IProxyWithAdminActions {
  event AdminChanged(address previousAdmin, address newAdmin);

  function upgradeToAndCall(address newImplementation, bytes calldata data) external payable;

  function changeAdmin(address newAdmin) external;
}

interface IProposalExecutor {
    function execute() external;
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 * From https://github.com/OpenZeppelin/openzeppelin-contracts
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

/**
 * @title AIP2ProposalPayload
 * @notice Proposal payload to be executed by the Aave Governance contract via DELEGATECALL
 * - Updates the TokenDistributor contract as defined by the AIP-2
 * @author Aave
 **/
contract AIP2ProposalPayload is IProposalExecutor {
  event ProposalExecuted();

  address public constant DISTRIBUTOR_IMPL = 0x62C936a16905AfC49B589a41d033eE222A2325Ad;
  address public constant DISTRIBUTOR_PROXY = 0xE3d9988F676457123C5fD01297605efdD0Cba1ae;
  address public constant AAVE_COLLECTOR = 0x464C71f6c2F760DdA6093dCB91C24c39e5d6e18c;
  address public constant REFERRAL_WALLET = 0x2fbB0c60a41cB7Ea5323071624dCEAD3d213D0Fa;

  /**
   * @dev Payload execution function, called once a proposal passed in the Aave governance
   */
  function execute() external override {
    address[] memory receivers = new address[](2);
    receivers[0] = AAVE_COLLECTOR;
    receivers[1] = REFERRAL_WALLET;

    uint256[] memory percentages = new uint256[](2);
    percentages[0] = uint256(8000);
    percentages[1] = uint256(2000);

    bytes memory params =
      abi.encodeWithSelector(
        ITokenDistributor(DISTRIBUTOR_IMPL).initialize.selector,
        receivers,
        percentages
      );

    IProxyWithAdminActions(DISTRIBUTOR_PROXY).upgradeToAndCall(DISTRIBUTOR_IMPL, params);

    emit ProposalExecuted();
  }
}