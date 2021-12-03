// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IStaking.sol";
import "./interfaces/IStakingFactory.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract Staking is Context, IStaking {
    address immutable public CRAT_TOKEN;
    address immutable public FACTORY;

    GeneralInfo public info;

    struct GeneralInfo {
        address creator;
        uint256 stakedAmount;
        uint256 rewardAmount;
        uint256 endTime;
    }

    modifier onlyFactory(){
        require(_msgSender() == FACTORY, "Only factory");
        _;
    }

    modifier onlyCreator(){
        require(_msgSender() == info.creator, "Only creator");
        _;
    }

    constructor(address _CRAT, address _FACTORY) {
        CRAT_TOKEN = _CRAT;
        FACTORY = _FACTORY;
    }

    function initialize(
        uint256 stakedAmount,
        uint256 rewardAmount,
        uint256 endTime,
        address sender
    ) external override onlyFactory {
        info = GeneralInfo(sender, stakedAmount, rewardAmount, endTime);
    }

    function unstake() external onlyCreator {
        address sender = _msgSender();
        IStakingFactory(FACTORY).unstake(sender);
        if(block.timestamp > info.endTime){
            require(IERC20(CRAT_TOKEN).transferFrom(FACTORY, sender, info.rewardAmount + info.stakedAmount), "Transfer failed");
        }
        else {
            IStakingFactory(FACTORY).earlyUnstake(info.rewardAmount);
            require(IERC20(CRAT_TOKEN).transferFrom(FACTORY, sender, info.stakedAmount), "Staked transfer failed");
        }
        selfdestruct(payable(FACTORY));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStakingFactory {
    function earlyUnstake(uint256 amount) external;

    function unstake(address sender) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStaking {
    function initialize(
        uint256 stakedAmount,
        uint256 rewardAmount,
        uint256 endTime,
        address sender
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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