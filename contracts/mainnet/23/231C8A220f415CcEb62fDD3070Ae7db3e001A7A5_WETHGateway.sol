// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {Ownable} from './Ownable.sol';
import {IERC20} from './IERC20.sol';
import {IWETH} from './IWETH.sol';
import {IWETHGateway} from './IWETHGateway.sol';
import {IMarginPool} from './IMarginPool.sol';
import {IXToken} from './IXToken.sol';
import {ICreditDelegationToken} from './ICreditDelegationToken.sol';
import {ReserveConfiguration} from './ReserveConfiguration.sol';
import {UserConfiguration} from './UserConfiguration.sol';
import {Helpers} from './Helpers.sol';
import {DataTypes} from './DataTypes.sol';

contract WETHGateway is IWETHGateway, Ownable {
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using UserConfiguration for DataTypes.UserConfigurationMap;

  IWETH internal immutable WETH;
  IMarginPool internal immutable POOL;
  IXToken internal immutable xWETH;
  ICreditDelegationToken internal immutable dWETH;

  /**
   * @dev Sets the WETH address and the MarginPoolAddressesProvider address. Infinite approves margin pool.
   * @param weth Address of the Wrapped Ether contract
   * @param pool Address of the MarginPool contract
   **/
  constructor(address weth, address pool) public {
    IMarginPool poolInstance = IMarginPool(pool);
    WETH = IWETH(weth);
    POOL = poolInstance;
    xWETH = IXToken(poolInstance.getReserveData(weth).xTokenAddress);
    dWETH = ICreditDelegationToken(poolInstance.getReserveData(weth).variableDebtTokenAddress);
    IWETH(weth).approve(pool, uint256(-1));
  }

  /**
   * @dev deposits WETH into the reserve, using native ETH. A corresponding amount of the overlying asset (xTokens)
   * is minted.
   * @param onBehalfOf address of the user who will receive the xTokens representing the deposit
   **/
  function depositETH(address onBehalfOf) external payable override {
    WETH.deposit{value: msg.value}();
    POOL.deposit(address(WETH), msg.value, onBehalfOf);
  }

  /**
   * @dev withdraws the WETH _reserves of msg.sender.
   * @param amount amount of xWETH to withdraw and receive native ETH
   * @param to address of the user who will receive native ETH
   */
  function withdrawETH(uint256 amount, address to) external override {
    uint256 userBalance = xWETH.balanceOf(msg.sender);
    uint256 amountToWithdraw = amount;

    // if amount is equal to uint(-1), the user wants to redeem everything
    if (amount == type(uint256).max) {
      amountToWithdraw = userBalance;
    }
    xWETH.transferFrom(msg.sender, address(this), amountToWithdraw);
    POOL.withdraw(address(WETH), amountToWithdraw, address(this));
    WETH.withdraw(amountToWithdraw);
    _safeTransferETH(to, amountToWithdraw);
  }

  /**
   * @dev borrow WETH, unwraps to ETH and send both the ETH and DebtTokens to msg.sender, via `approveDelegation` and onBehalf argument in `MarginPool.borrow`.
   * @param amount the amount of ETH to borrow
   */
  function borrowETH(
    uint256 amount
  ) external override {
    POOL.borrow(address(WETH), amount, msg.sender);
    WETH.withdraw(amount);
    _safeTransferETH(msg.sender, amount);
  }

  /**
   * @dev transfer ETH to an address, revert if it fails.
   * @param to recipient of the transfer
   * @param value the amount to send
   */
  function _safeTransferETH(address to, uint256 value) internal {
    (bool success, ) = to.call{value: value}(new bytes(0));
    require(success, 'ETH_TRANSFER_FAILED');
  }

  /**
   * @dev transfer ERC20 from the utility contract, for ERC20 recovery in case of stuck tokens due
   * direct transfers to the contract address.
   * @param token token to transfer
   * @param to recipient of the transfer
   * @param amount amount to send
   */
  function emergencyTokenTransfer(
    address token,
    address to,
    uint256 amount
  ) external onlyOwner {
    IERC20(token).transfer(to, amount);
  }

  /**
   * @dev transfer native Ether from the utility contract, for native Ether recovery in case of stuck Ether
   * due selfdestructs or transfer ether to pre-computated contract address before deployment.
   * @param to recipient of the transfer
   * @param amount amount to send
   */
  function emergencyEtherTransfer(address to, uint256 amount) external onlyOwner {
    _safeTransferETH(to, amount);
  }

  /**
   * @dev Get WETH address used by WETHGateway
   */
  function getWETHAddress() external view returns (address) {
    return address(WETH);
  }

  /**
   * @dev Get xWETH address used by WETHGateway
   */
  function getXWETHAddress() external view returns (address) {
    return address(xWETH);
  }

  /**
   * @dev Get MarginPool address used by WETHGateway
   */
  function getMarginPoolAddress() external view returns (address) {
    return address(POOL);
  }

  /**
   * @dev Only WETH contract is allowed to transfer ETH here. Prevent other addresses to send Ether to this contract.
   */
  receive() external payable {
    require(msg.sender == address(WETH), 'Receive not allowed');
  }

  /**
   * @dev Revert fallback calls
   */
  fallback() external payable {
    revert('Fallback not allowed');
  }
}