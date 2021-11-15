// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.6;
import "./interfaces/IFeeDistribution.sol";
import "./interfaces/IFoundation.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract FeeDistributionHelper {

  IFeeDistribution public constant feeDistribution = IFeeDistribution(0x3f93dE882dA8150Dc98a3a1F4626E80E3282df46);
  IFoundation public constant foundation = IFoundation(0x492530fc97522d142bc57710bE57fA57A43Dc911);
  IERC20 public constant usdp = IERC20(0x1456688345527bE1f37E9e627DA0837D6f08C925);

  modifier s() {
    require(feeDistribution.canSwap(msg.sender), "FeeDistributionHelper: can't claim, swap and distribute");
    _;
  }

  /**
    @notice minDuckAmount must be set to prevent sandwich attack
    @param usdpAmount The amount of USDP being swapped and distributed
    @param minDuckAmount The minimum amount of DUCK being distributed
  **/
  function claimSwapAndDistribute(uint usdpAmount, uint minDuckAmount) public s returns(uint) {
    foundation.distribute();
    return feeDistribution.swapAndDistribute(usdpAmount, minDuckAmount);
  }

  // @dev This function should be manually changed to "view" in the ABI
  function viewDistribution() external s returns(uint usdp_, uint duck_) {
    foundation.distribute();
    return feeDistribution.viewDistribution();
  }
}

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

// SPDX-License-Identifier: bsl-1.1

pragma solidity ^0.8.6;

interface IFoundation {

  function submitLiquidationFee(uint fee) external;

  function distribute() external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.6;

interface IFeeDistribution {

  function canSwap(address who) external returns(bool);

  function swapAndDistribute(uint usdpAmount, uint minDuckAmount) external returns(uint);

  // @dev This function should be manually changed to "view" in the ABI
  function viewDistribution() external returns(uint usdp_, uint duck_);
}

