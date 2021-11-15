pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IRouter.sol";

contract Crafting is Ownable {

    address tokenX1;
    address tokenX2;
    address tokenX3;
    address tokenY;

    IRouter router = IRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);

    uint tokensDecimals = 8;
    uint craftingTime = 30 days;
    uint depositRatio = 50;
    
    uint rewardMultiplierX1 = 14;
    uint rewardMultiplierY = 95;

    uint rateX1OverX2 = 1000;

    uint MAX_UINT = 2**256 - 1;

    struct Reward {
        address receiver;
        uint id;
        uint rewardX1;
        uint rewardY;
        uint collectedRewardX1;
        uint collectedRewardY;
        uint lockTime;
    }

    mapping (address => uint) public addressRewardsCount;

    Reward[] public rewards;

    function init(address _tokenX1, address _tokenX2, address _tokenX3, address _tokenY) external onlyOwner {
        tokenX1 = _tokenX1;
        tokenX2 = _tokenX2;
        tokenX3 = _tokenX3;
        tokenY = _tokenY;
    }

    function _getPriceInX2(address _token) public view returns(uint) {
        address[] memory path = new address[](2);
        path[0] = _token;
        path[1] = tokenX2;
        uint[] memory amounts = router.getAmountsOut(1, path);
        return amounts[0];
    }

    function approveContracts() external {
        IERC20(tokenX1).approve(address(this), MAX_UINT);
        IERC20(tokenX2).approve(address(this), MAX_UINT);
        IERC20(tokenX3).approve(address(this), MAX_UINT);
    }

    function deposit(uint _amountX1, uint _amountX2, uint _amountX3) external {
        require((_amountX2 / (10**tokensDecimals)) >= 1, "amountX2 Should be >=1");

        uint amountX1InX2 = _amountX1 * rateX1OverX2;
        uint amountX3InX2 = _amountX3 * _getPriceInX2(tokenX3);

        uint totalDepositInX2 = amountX1InX2 + _amountX2 + amountX3InX2;
        // Z is X1 + X2 in X2
        uint zNormalized = (amountX1InX2 + _amountX2)/depositRatio;
        uint x3Normalized = amountX3InX2/(100-depositRatio);
        uint step = totalDepositInX2 * 150 / 100;

        require(approximatelyEqual(zNormalized, x3Normalized, step), "Bad amounts ratio");

        uint rewardInY = ((totalDepositInX2 / _getPriceInX2(tokenY)) / 100) * rewardMultiplierY;
        uint rewardInX1 = ((totalDepositInX2 / rateX1OverX2) / 100) * rewardMultiplierX1;

        IERC20(tokenX1).transferFrom(msg.sender, address(this), _amountX1);
        IERC20(tokenX2).transferFrom(msg.sender, address(this), _amountX2);
        IERC20(tokenX3).transferFrom(msg.sender, address(this), _amountX3);

        rewards.push(Reward(msg.sender, rewards.length, rewardInX1, rewardInY, 0, 0, block.timestamp + craftingTime));
        addressRewardsCount[msg.sender] += 1;
    }

    function claimReward(uint _id) external {
        require(_id < rewards.length, "Trying to claim non-existant reward");

        Reward storage reward = rewards[_id];
        require(msg.sender == reward.receiver, "The reward doesn't belong to provided address");

        uint currentTime = block.timestamp;

        require((reward.collectedRewardX1 < reward.rewardX1) || (reward.collectedRewardY < reward.rewardY), "Reward already collected");

        if(currentTime >= reward.lockTime + craftingTime) {
            uint leftRewardX1 = reward.rewardX1 - reward.collectedRewardX1;
            uint leftRewardY = reward.rewardY - reward.collectedRewardY;

            IERC20(tokenX1).transfer(msg.sender, leftRewardX1);
            IERC20(tokenY).transfer(msg.sender, leftRewardY);

            reward.collectedRewardX1 += leftRewardX1;
            reward.collectedRewardY += leftRewardY;
        } else {
            uint currentRewardX1 = (reward.rewardX1 * (block.timestamp - reward.lockTime)) / craftingTime;
            uint currentRewardY = (reward.rewardY * (block.timestamp - reward.lockTime)) / craftingTime;

            IERC20(tokenX1).transfer(msg.sender, currentRewardX1);
            IERC20(tokenY).transfer(msg.sender, currentRewardY);
        }

        // reward.received = true;
        addressRewardsCount[msg.sender] -= 1;
    }

    function setCraftingTime(uint _craftingTime) external onlyOwner {
        craftingTime = _craftingTime;
    }

    function setDepositRatio(uint _ratio) external onlyOwner {
        depositRatio = _ratio;
    }

    function setRouter(address _router) external onlyOwner {
        router = IRouter(_router);
    }

    function getAllAvailableRewards(address _receiver) external view returns(Reward[] memory) {
        Reward[] memory result = new Reward[](addressRewardsCount[msg.sender]);

        uint counter = 0;
        for(uint i = 0; i < rewards.length; i++) {
            if(rewards[i].receiver == _receiver) {
                result[counter] = rewards[i];
                counter++;
            }
        }

        return result;
    }

    function approximatelyEqual(uint _a, uint _b, uint _epsilon) internal pure returns(bool) {
        int a = int(_a);
        int b = int(_b);
        uint diff = abs(a - b);

        if(diff <= _epsilon) {
            return true;
        } else {
            return false;
        }
    }

    function abs(int _a) internal pure returns(uint) {
        if(_a >= 0) {
            return uint(_a);
        } else {
            return uint(-_a);
        }
    }

    function addLiquidityX1(uint _amount) external onlyOwner {
        IERC20(tokenX1).transferFrom(msg.sender, address(this), _amount);
    }

    function addLiquidityY(uint _amount) external onlyOwner {
        IERC20(tokenY).transferFrom(msg.sender, address(this), _amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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

pragma solidity ^0.8.0;

interface IRouter {
    function getAmountsOut(uint256 amountIn, address[] memory path) external view returns(uint[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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

