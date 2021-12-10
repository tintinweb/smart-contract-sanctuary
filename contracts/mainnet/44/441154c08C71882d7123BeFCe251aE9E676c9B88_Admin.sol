/**
 *Submitted for verification at Etherscan.io on 2021-12-10
*/

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

pragma solidity 0.7.6;
pragma abicoder v2;


interface IHyperLiquidrium {

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


/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


pragma solidity 0.7.6;

contract Admin is ReentrancyGuard{
    
    event OwnerTransferPrepared(address hypervisor, address newOwner, address admin, uint256 timestamp);
    event OwnerTransferFullfilled(address hypervisor, address newOwner, address admin, uint256 timestamp);
    event AdminTransfer(address newAdmin, uint256 timestamp);
    event AdvisorTransfer(address newAdmin, uint256 timestamp);
    event RescueTokens(IERC20 token, address recipient, uint256 value);

    address public admin;
    address public advisor;
    
    
    struct OwnershipData {
        address newOwner;
        uint256 lastUpdatedTime;
    }

    mapping(address => OwnershipData) hypervisorOwner;

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
        IHyperLiquidrium(_hypervisor).rebalance(_baseLower, _baseUpper, _limitLower, _limitUpper, _feeRecipient, swapQuantity);
    }

    function emergencyWithdraw(
        address _hypervisor,
        IERC20 token,
        uint256 amount
    ) external onlyAdmin {
        IHyperLiquidrium(_hypervisor).emergencyWithdraw(token, amount);
    }

    function emergencyBurn(
        address _hypervisor,
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity
    ) external onlyAdmin {
        IHyperLiquidrium(_hypervisor).emergencyBurn(tickLower, tickUpper, liquidity);
    }

    function setDepositMax(address _hypervisor, uint256 _deposit0Max, uint256 _deposit1Max) external onlyAdmin {
        IHyperLiquidrium(_hypervisor).setDepositMax(_deposit0Max, _deposit1Max);
    }

    function setMaxTotalSupply(address _hypervisor, uint256 _maxTotalSupply) external onlyAdmin {
        IHyperLiquidrium(_hypervisor).setMaxTotalSupply(_maxTotalSupply);
    }

    function toggleWhitelist(address _hypervisor) external onlyAdmin {
        IHyperLiquidrium(_hypervisor).toggleWhitelist();
    }

    function appendList(address _hypervisor, address[] memory listed) external onlyAdmin {
        IHyperLiquidrium(_hypervisor).appendList(listed);
    }

    function transferAdmin(address newAdmin) external onlyAdmin {
        admin = newAdmin;
        emit AdminTransfer(newAdmin, block.timestamp);
    }

    function transferAdvisor(address newAdvisor) external onlyAdmin {
        advisor = newAdvisor;
        emit AdvisorTransfer(newAdvisor, block.timestamp);
    }

    function prepareHVOwnertransfer(address _hypervisor, address newOwner) external onlyAdmin {
        require(newOwner != address(0), "newOwner must not be zero");
        hypervisorOwner[_hypervisor] = OwnershipData(newOwner, block.timestamp + 86400);
        emit OwnerTransferPrepared(_hypervisor, newOwner, admin, block.timestamp);
    }

    function fullfillHVOwnertransfer(address _hypervisor, address newOwner) external onlyAdmin {
        OwnershipData storage data = hypervisorOwner[_hypervisor];
        require(data.newOwner == newOwner && data.lastUpdatedTime != 0 && data.lastUpdatedTime < block.timestamp, "owner or update time wrong");
        IHyperLiquidrium(_hypervisor).transferOwnership(newOwner);
        delete hypervisorOwner[_hypervisor];
        emit OwnerTransferFullfilled(_hypervisor, newOwner, admin, block.timestamp);
    }

    function rescueERC20(IERC20 token, address recipient) external nonReentrant onlyAdmin {
        require(token.transfer(recipient, token.balanceOf(address(this))), "transfer failed");
        emit RescueTokens(token,recipient,token.balanceOf(address(this)));
    }

}