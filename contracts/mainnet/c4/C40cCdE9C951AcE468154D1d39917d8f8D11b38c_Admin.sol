pragma solidity 0.7.6;

import "../../interfaces/IHypervisor.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Admin {

    address public admin;
    address public advisor;

    modifier onlyAdvisor {
        require(msg.sender == advisor, "only advisor");
        _;
    }

    modifier onlyAdmin {
        require(msg.sender == admin, "only admin");
        _;
    }

    constructor(address _admin, address _advisor) public {
        admin = _admin;
        advisor = _advisor;
    }

    function rebalance(
        address _hypervisor,
        int24 _baseLower,
        int24 _baseUpper,
        int24 _limitLower,
        int24 _limitUpper,
        address _feeRecipient,
        int256 swapQuantity
    ) external onlyAdvisor {
        IHypervisor(_hypervisor).rebalance(_baseLower, _baseUpper, _limitLower, _limitUpper, _feeRecipient, swapQuantity);
    }

    function emergencyWithdraw(
        address _hypervisor,
        IERC20 token,
        uint256 amount
    ) external onlyAdmin {
        IHypervisor(_hypervisor).emergencyWithdraw(token, amount);
    }

    function emergencyBurn(
        address _hypervisor,
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity
    ) external onlyAdmin {
        IHypervisor(_hypervisor).emergencyBurn(tickLower, tickUpper, liquidity);
    }

    function setDepositMax(address _hypervisor, uint256 _deposit0Max, uint256 _deposit1Max) external onlyAdmin {
        IHypervisor(_hypervisor).setDepositMax(_deposit0Max, _deposit1Max);
    }

    function setMaxTotalSupply(address _hypervisor, uint256 _maxTotalSupply) external onlyAdmin {
        IHypervisor(_hypervisor).setMaxTotalSupply(_maxTotalSupply);
    }

    function toggleWhitelist(address _hypervisor) external onlyAdmin {
        IHypervisor(_hypervisor).toggleWhitelist();
    }

    function appendList(address _hypervisor, address[] memory listed) external onlyAdmin {
        IHypervisor(_hypervisor).appendList(listed);
    }

    function transferAdmin(address newAdmin) external onlyAdmin {
        admin = newAdmin;
    }

    function transferAdvisor(address newAdvisor) external onlyAdmin {
        advisor = newAdvisor;
    }

    function transferHypervisorOwner(address _hypervisor, address newOwner) external onlyAdmin {
        IHypervisor(_hypervisor).transferOwnership(newOwner);
    }

    function rescueERC20(IERC20 token, address recipient) external onlyAdmin {
        require(token.transfer(recipient, token.balanceOf(address(this))));
    }

}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IHypervisor {

    /* user functions */

    function rebalance(
        int24 _baseLower,
        int24 _baseUpper,
        int24 _limitLower,
        int24 _limitUpper,
        address _feeRecipient,
        int256 swapQuantity
    ) external;

    function setMaxTotalSupply(uint256 _maxTotalSupply) external;

    function setDepositMax(uint256 _deposit0Max, uint256 _deposit1Max) external;

    function appendList(address[] memory listed) external;

    function toggleWhitelist() external;

    function emergencyWithdraw(IERC20 token, uint256 amount) external;

    function emergencyBurn(
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity
    ) external;

    function transferOwnership(address newOwner) external;
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

