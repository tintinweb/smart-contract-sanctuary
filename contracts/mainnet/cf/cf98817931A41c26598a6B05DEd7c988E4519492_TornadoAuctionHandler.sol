// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import { IWETH } from "./interfaces/IWETH.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { EtherSend } from "../libraries/EtherSend.sol";
import { IEasyAuction } from "./interfaces/IEasyAuction.sol";
import { ImmutableGovernanceInformation } from "../ImmutableGovernanceInformation.sol";

/// @notice Handler which should help governance start an auction and transfer results of an auction to governance.
/// @dev The reasoning behind this contract is to not bloat governance with unnecessary logic.
contract TornadoAuctionHandler is ImmutableGovernanceInformation {
  using EtherSend for address;

  address public constant EasyAuctionAddress = 0x0b7fFc1f4AD541A4Ed16b40D8c37f0929158D101;
  address public constant WETHAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

  /// @notice main auction initialization function, please see: https://github.com/h-ivor/tornado-lottery-period/blob/only-vault-and-gas/contracts/auction/Auction.md
  /// @dev calls easy auction deployed on eth mainnet
  function initializeAuction(
    uint256 _auctionEndDate,
    uint96 _auctionedSellAmount,
    uint96 _minBuyAmount,
    uint256 _minBidPerOrder,
    uint256 _minFundingThreshold
  ) external onlyGovernance {
    require(IERC20(TornTokenAddress).balanceOf(address(this)) >= _auctionedSellAmount, "torn balance not enough");
    IERC20(TornTokenAddress).approve(EasyAuctionAddress, _auctionedSellAmount);

    IEasyAuction(EasyAuctionAddress).initiateAuction(
      IERC20(TornTokenAddress),
      IERC20(WETHAddress),
      0,
      _auctionEndDate,
      _auctionedSellAmount,
      _minBuyAmount,
      _minBidPerOrder,
      _minFundingThreshold,
      false,
      address(0x0000000000000000000000000000000000000000),
      new bytes(0)
    );
  }

  /// @notice function to transfer all eth and TORN dust to governance
  function convertAndTransferToGovernance() external {
    IWETH(WETHAddress).withdraw(IWETH(WETHAddress).balanceOf(address(this)));
    if (address(this).balance > 0) require(GovernanceAddress.sendEther(address(this).balance), "pay fail");
    if (IERC20(TornTokenAddress).balanceOf(address(this)) > 0)
      IERC20(TornTokenAddress).transfer(GovernanceAddress, IERC20(TornTokenAddress).balanceOf(address(this)));
  }

  /// @notice receive eth that should only allow mainnet WETH to send eth
  receive() external payable {
    require(msg.sender == WETHAddress, "only weth");
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface IWETH {
  function balanceOf(address account) external view returns (uint256);

  function deposit() external payable;

  function withdraw(uint256 wad) external;

  function totalSupply() external view returns (uint256);

  function approve(address guy, uint256 wad) external returns (bool);

  function transfer(address dst, uint256 wad) external returns (bool);

  function transferFrom(
    address src,
    address dst,
    uint256 wad
  ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12 || ^0.8.7;

/// @notice very short library which implements a method to transfer ether via <address>.call
library EtherSend {
  /**
  * @notice function to transfer ether via filling the value field of a call
  * @dev DICLAIMER: you must handle the possibility of reentrancy when using this function!!!
  * @param to address to be transferred to
  * @param amount amount to be transferred
  * @return success true if transfer successful
  * */
  function sendEther(address to, uint256 amount) internal returns (bool success) {
    (success, ) = payable(to).call{ value: amount }("");
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IEasyAuction {
  function initiateAuction(
    IERC20 _auctioningToken,
    IERC20 _biddingToken,
    uint256 orderCancellationEndDate,
    uint256 auctionEndDate,
    uint96 _auctionedSellAmount,
    uint96 _minBuyAmount,
    uint256 minimumBiddingAmountPerOrder,
    uint256 minFundingThreshold,
    bool isAtomicClosureAllowed,
    address accessManagerContract,
    bytes memory accessManagerContractData
  ) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

interface IGovernanceMultisigAddress {
  function returnMultisigAddress() external pure returns (address);
}

/**
 * @notice Contract which hold governance information. Useful for avoiding code duplication.
 * */
contract ImmutableGovernanceInformation {
  address internal constant GovernanceAddress = 0x5efda50f22d34F262c29268506C5Fa42cB56A1Ce;
  address internal constant TornTokenAddress = 0x77777FeDdddFfC19Ff86DB637967013e6C6A116C;

  modifier onlyGovernance() {
    require(msg.sender == GovernanceAddress, "only governance");
    _;
  }

  /**
   * @dev this modifier calls the pure governance returnMultisigAddress() function,
   *      if governance version is not -> vault-and-gas upgrade <= version
   *      then this will not work!
   */
  modifier onlyMultisig() {
    require(msg.sender == IGovernanceMultisigAddress(GovernanceAddress).returnMultisigAddress(), "only multisig");
    _;
  }

  /**
   * @notice Function to return a payable version of the governance address.
   * @return payable version of the address
   * */
  function returnPayableGovernance() internal pure returns (address payable) {
    return payable(GovernanceAddress);
  }
}