pragma solidity 0.6.2;

/*
#    Copyright (C) 2017  alianse777
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#    https://github.com/alianse777/solidity-standard-library.git
*/

import "@openzeppelin/contracts/math/SafeMath.sol";

library AdditionalMath {

    using SafeMath for uint256;

   /**
    * @dev Compute square root of x
    * @param x num to sqrt
    * @return sqrt(x)
    */
   function sqrt(uint x) internal pure returns (uint){
       uint n = x / 2;
       uint lstX = 0;
       while (n != lstX){
           lstX = n;
           n = (n + x/n) / 2; 
       }
       return uint(n);
   }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

//SPDX-License-Identifier: MIT
/*
* MIT License
* ===========
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/

pragma solidity 0.6.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IERC20Burnable.sol";
import "./interfaces/ITreasury.sol";
import "./interfaces/ISwapRouter.sol";
import "./LPTokenWrapper.sol";
import "./AdditionalMath.sol";
import "@openzeppelin/contracts/math/Math.sol";

contract AlunaBoostPool is LPTokenWrapper, Ownable {
    
    using AdditionalMath for uint256;
    
    IERC20 public rewardToken;
    IERC20 public boostToken;
    ITreasury public treasury;
    SwapRouter public swapRouter;
    IERC20 public stablecoin;
    
    
    uint256 public tokenCapAmount;
    uint256 public starttime;
    uint256 public duration;
    uint256 public periodFinish;
    uint256 public rewardRate;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    uint256 public constant SECONDS_IN_A_DAY = 86400;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    
    // booster variables
    // variables to keep track of totalSupply and balances (after accounting for multiplier)
    uint256 public boostedTotalSupply;
    uint256 public lastBoostPurchase; // timestamp of lastBoostPurchase
    mapping(address => uint256) public boostedBalances;
    mapping(address => uint256) public numBoostersBought; // each booster = 5% increase in stake amt
    mapping(address => uint256) public nextBoostPurchaseTime; // timestamp for which user is eligible to purchase another booster
    uint256 public globalBoosterPrice = 2000e18;
    uint256 public boostThreshold = 10;
    uint256 public boostScaleFactor = 20;
    uint256 public scaleFactor = 100;

    event RewardAdded(uint256 reward);
    event RewardPaid(address indexed user, uint256 reward);

    modifier checkStart() {
        require(block.timestamp >= starttime,"not start");
        _;
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    constructor(
        uint256 _tokenCapAmount,
        IERC20 _stakeToken,
        IERC20 _rewardToken,
        IERC20 _boostToken,
        address _treasury,
        SwapRouter _swapRouter,
        uint256 _starttime,
        uint256 _duration
    ) public LPTokenWrapper(_stakeToken) {
        tokenCapAmount = _tokenCapAmount;
        boostToken = _boostToken;
        rewardToken = _rewardToken;
        treasury = ITreasury(_treasury);
        stablecoin = treasury.defaultToken();
        swapRouter = _swapRouter;
        starttime = _starttime;
        lastBoostPurchase = _starttime;
        duration = _duration;
        boostToken.safeApprove(address(_swapRouter), uint256(-1));
        stablecoin.safeApprove(address(treasury), uint256(-1));
    }
    
    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (boostedTotalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(1e18)
                    .div(boostedTotalSupply)
            );
    }

    function earned(address account) public view returns (uint256) {
        return
            boostedBalances[account]
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                .div(1e18)
                .add(rewards[account]);
    }

    function getBoosterPrice(address user)
        public view returns (uint256 boosterPrice, uint256 newBoostBalance)
    {
        if (boostedTotalSupply == 0) return (0,0);

        // each previously user-purchased booster will increase price in 5%,
        // that is, 1 booster means 5% increase, 2 boosters mean 10% and so on
        uint256 boostersBought = numBoostersBought[user];
        boosterPrice = globalBoosterPrice.mul(boostersBought.mul(5).add(100)).div(100);

        // increment boostersBought by 1
        boostersBought = boostersBought.add(1);

        // if no. of boosters exceed threshold, increase booster price by boostScaleFactor
        // for each exceeded booster
        if (boostersBought >= boostThreshold) {
            boosterPrice = boosterPrice
                .mul((boostersBought.sub(boostThreshold)).mul(boostScaleFactor).add(100))
                .div(100);
        }

        // 2.5% decrease for every 2 hour interval since last global boost purchase
        boosterPrice = calculateBoostDevaluation(boosterPrice, 975, 1000, (block.timestamp.sub(lastBoostPurchase)).div(2 hours));

        // adjust price based on expected increase in boost supply
        // each booster will increase balance in an order of 10%
        // boostersBought has been incremented by 1 already
        newBoostBalance = balanceOf(user)
            .mul(boostersBought.mul(10).add(100))
            .div(100);
        // uint256 boostBalanceIncrease = newBoostBalance.sub(boostedBalances[user]);
        boosterPrice = boosterPrice
            .mul(balanceOf(user))
            .div(boostedTotalSupply);
    }

    // stake visibility is public as overriding LPTokenWrapper's stake() function
    function stake(uint256 amount) public updateReward(msg.sender) override checkStart  {
        require(amount != 0, "Cannot stake 0");
        super.stake(amount);

        // check user cap
        require(
            balanceOf(msg.sender) <= tokenCapAmount || block.timestamp >= starttime.add(SECONDS_IN_A_DAY),
            "token cap exceeded"
        );

        // boosters do not affect new amounts
        boostedBalances[msg.sender] = boostedBalances[msg.sender].add(amount);
        boostedTotalSupply = boostedTotalSupply.add(amount);

        _getReward(msg.sender);

        // transfer token last, to follow CEI pattern
        stakeToken.safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount) public updateReward(msg.sender) override checkStart {
        require(amount != 0, "Cannot withdraw 0");
        super.withdraw(amount);
        
        // reset boosts :(
        numBoostersBought[msg.sender] = 0;

        // update boosted balance and supply
        updateBoostBalanceAndSupply(msg.sender, 0);

        // in case _getReward function fails, continue
        //(bool success, ) = address(this).call(
        //    abi.encodeWithSignature(
        //       "_getReward(address)",
        //       msg.sender
        //   )
        //);
        
        // to remove compiler warning
        //success;

        // transfer token last, to follow CEI pattern
        stakeToken.safeTransfer(msg.sender, amount);
    }

    function getReward() external updateReward(msg.sender) checkStart {
        _getReward(msg.sender);
    }

    function exit() external {
        withdraw(balanceOf(msg.sender));
    }

    function setScaleFactorsAndThreshold(
        uint256 _boostThreshold,
        uint256 _boostScaleFactor,
        uint256 _scaleFactor
    ) external onlyOwner
    {
        boostThreshold = _boostThreshold;
        boostScaleFactor = _boostScaleFactor;
        scaleFactor = _scaleFactor;
    }
    
    function boost() external updateReward(msg.sender) checkStart {
        require(
            block.timestamp > nextBoostPurchaseTime[msg.sender],
            "early boost purchase"
        );

        // save current booster price, since transfer is done last
        // since getBoosterPrice() returns new boost balance, avoid re-calculation
        (uint256 boosterAmount, uint256 newBoostBalance) = getBoosterPrice(msg.sender);
        // user's balance and boostedSupply will be changed in this function
        applyBoost(msg.sender, newBoostBalance);
        
        _getReward(msg.sender);

        boostToken.safeTransferFrom(msg.sender, address(this), boosterAmount);
        
        IERC20Burnable burnableBoostToken = IERC20Burnable(address(boostToken));

        // burn 25%
        uint256 burnAmount = boosterAmount.div(4);
        burnableBoostToken.burn(burnAmount);
        boosterAmount = boosterAmount.sub(burnAmount);
        
        // swap to stablecoin
        address[] memory routeDetails = new address[](3);
        routeDetails[0] = address(boostToken);
        routeDetails[1] = swapRouter.WETH();
        routeDetails[2] = address(stablecoin);
        uint[] memory amounts = swapRouter.swapExactTokensForTokens(
            boosterAmount,
            0,
            routeDetails,
            address(this),
            block.timestamp + 100
        );

        // transfer to treasury
        // index 2 = final output amt
        treasury.deposit(stablecoin, amounts[2]);
    }

    function notifyRewardAmount(uint256 reward)
        external
        onlyOwner
        updateReward(address(0))
    {
        rewardRate = reward.div(duration);
        lastUpdateTime = starttime;
        periodFinish = starttime.add(duration);
        emit RewardAdded(reward);
    }
    
    function updateBoostBalanceAndSupply(address user, uint256 newBoostBalance) internal {
        // subtract existing balance from boostedSupply
        boostedTotalSupply = boostedTotalSupply.sub(boostedBalances[user]);
    
        // when applying boosts,
        // newBoostBalance has already been calculated in getBoosterPrice()
        if (newBoostBalance == 0) {
            // each booster adds 10% to current stake amount, that is 1 booster means 10%,
            // two boosters mean 20% and so on
            newBoostBalance = balanceOf(user).mul(numBoostersBought[user].mul(10).add(100)).div(100);
        }

        // update user's boosted balance
        boostedBalances[user] = newBoostBalance;
    
        // update boostedSupply
        boostedTotalSupply = boostedTotalSupply.add(newBoostBalance);
    }

    function applyBoost(address user, uint256 newBoostBalance) internal {
        // increase no. of boosters bought
        numBoostersBought[user] = numBoostersBought[user].add(1);

        updateBoostBalanceAndSupply(user, newBoostBalance);
        
        // increase next purchase eligibility by an hour
        nextBoostPurchaseTime[user] = block.timestamp.add(3600);

        // increase global booster price by 1%
        globalBoosterPrice = globalBoosterPrice.mul(101).div(100);

        lastBoostPurchase = block.timestamp;
    }

    function _getReward(address user) internal {
        uint256 reward = earned(user);
        if (reward != 0) {
            rewards[user] = 0;
            emit RewardPaid(user, reward);
            rewardToken.safeTransfer(user, reward);
        }
    }

    /// Imported from: https://forum.openzeppelin.com/t/does-safemath-library-need-a-safe-power-function/871/7
   /// Modified so that it takes in 3 arguments for base
   /// @return the eventually newly calculated boost price
   function calculateBoostDevaluation(uint256 a, uint256 b, uint256 c, uint256 exponent) internal pure returns (uint256) {
        if (exponent == 0) {
            return a;
        }
        else if (exponent == 1) {
            return a.mul(b).div(c);
        }
        else if (a == 0 && exponent != 0) {
            return 0;
        }
        else {
            uint256 z = a.mul(b).div(c);
            for (uint256 i = 1; i < exponent; i++)
                z = z.mul(b).div(c);
            return z;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../GSN/Context.sol";
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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

//SPDX-License-Identifier: MIT
/*
* MIT License
* ===========
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/

pragma solidity ^0.6.2;

interface IERC20Burnable {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function burn(uint256 amount) external;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.6.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface ITreasury {
    function defaultToken() external view returns (IERC20);
    function deposit(IERC20 token, uint256 amount) external;
    function withdraw(uint256 amount, address withdrawAddress) external;
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

//SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.6.2;


interface SwapRouter {
    function WETH() external pure returns (address);
    function swapExactTokensForTokens(
      uint amountIn,
      uint amountOutMin,
      address[] calldata path,
      address to,
      uint deadline
    ) external returns (uint[] memory amounts);
}

//SPDX-License-Identifier: MIT
/*
* MIT License
* ===========
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/

pragma solidity 0.6.2;


import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";


contract LPTokenWrapper {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 private _totalSupply;

    IERC20 public stakeToken;

    mapping(address => uint256) private _balances;

    constructor(IERC20 _stakeToken) public {
        stakeToken = _stakeToken;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function stake(uint256 amount) public virtual {
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        // safeTransferFrom shifted to last line of overridden method
    }

    function withdraw(uint256 amount) public virtual {
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        // safeTransfer shifted to last line of overridden method
    }    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

//SPDX-License-Identifier: MIT
/*
* MIT License
* ===========
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/

pragma solidity 0.6.2;


import "./interfaces/ITreasury.sol";
import "./interfaces/ISwapRouter.sol";
import "./LPTokenWrapperWithSlash.sol";
import "./AdditionalMath.sol";

contract AlunaGov is LPTokenWrapperWithSlash {
    
    using AdditionalMath for uint256;


    struct Proposal {
        address proposer;
        address withdrawAddress;
        uint256 withdrawAmount;
        mapping(address => uint256) forVotes;
        mapping(address => uint256) againstVotes;
        uint256 totalForVotes;
        uint256 totalAgainstVotes;
        uint256 totalSupply;
        uint256 start; // block start;
        uint256 end; // start + period
        string url;
        string title;
    }

    // 1% = 100
    uint256 public constant MIN_QUORUM_PUNISHMENT = 500; // 5%
    uint256 public constant MIN_QUORUM_THRESHOLD = 3000; // 30%
    uint256 public constant PERCENTAGE_PRECISION = 10000;
    uint256 public constant WITHDRAW_THRESHOLD = 1e21; // 1000 yCRV
    uint256 public constant proposalPeriod = 2 days;
    uint256 public constant lockPeriod = 3 days;
    uint256 public constant minimum = 1337e18; // 1337 ALN
    uint256 public proposalCount;

    IERC20 public stablecoin;
    ITreasury public treasury;
    SwapRouter public swapRouter;

    mapping(address => uint256) public voteLock; // timestamp that boost stakes are locked after voting
    mapping (uint256 => Proposal) public proposals;

    constructor(IERC20 _stakeToken, ITreasury _treasury, SwapRouter _swapRouter)
        public
        LPTokenWrapperWithSlash(_stakeToken)
    {
        treasury = _treasury;
        stablecoin = treasury.defaultToken();
        swapRouter = _swapRouter;
        stablecoin.safeApprove(address(treasury), uint256(-1));
        stakeToken.safeApprove(address(_swapRouter), uint256(-1));
    }

    function propose(
        string calldata _url,
        string calldata _title,
        uint256 _withdrawAmount,
        address _withdrawAddress
    ) external {
        require(balanceOf(msg.sender) > minimum, "stake more boost");
        proposals[proposalCount++] = Proposal({
            proposer: msg.sender,
            withdrawAddress: _withdrawAddress,
            withdrawAmount: _withdrawAmount,
            totalForVotes: 0,
            totalAgainstVotes: 0,
            totalSupply: 0,
            start: block.timestamp,
            end: proposalPeriod.add(block.timestamp),
            url: _url,
            title: _title
            });
        voteLock[msg.sender] = lockPeriod.add(block.timestamp);
    }

    function voteFor(uint256 id) external {
        require(proposals[id].start < block.timestamp , "<start");
        require(proposals[id].end > block.timestamp , ">end");
        require(proposals[id].againstVotes[msg.sender] == 0, "cannot switch votes");
        uint256 userVotes = AdditionalMath.sqrt(balanceOf(msg.sender));
        uint256 votes = userVotes.sub(proposals[id].forVotes[msg.sender]);
        proposals[id].totalForVotes = proposals[id].totalForVotes.add(votes);
        proposals[id].forVotes[msg.sender] = userVotes;

        voteLock[msg.sender] = lockPeriod.add(block.timestamp);
    }

    function voteAgainst(uint256 id) external {
        require(proposals[id].start < block.timestamp , "<start");
        require(proposals[id].end > block.timestamp , ">end");
        require(proposals[id].forVotes[msg.sender] == 0, "cannot switch votes");
        uint256 userVotes = AdditionalMath.sqrt(balanceOf(msg.sender));
        uint256 votes = userVotes.sub(proposals[id].againstVotes[msg.sender]);
        proposals[id].totalAgainstVotes = proposals[id].totalAgainstVotes.add(votes);
        proposals[id].againstVotes[msg.sender] = userVotes;

        voteLock[msg.sender] = lockPeriod.add(block.timestamp);
    }

    function stake(uint256 amount) public override {
        super.stake(amount);
    }

    function withdraw(uint256 amount) public override {
        require(voteLock[msg.sender] < block.timestamp, "tokens locked");
        super.withdraw(amount);
    }

    function resolveProposal(uint256 id) external {
        require(proposals[id].proposer != address(0), "non-existent proposal");
        require(proposals[id].end < block.timestamp , "ongoing proposal");
        require(proposals[id].totalSupply == 0, "already resolved");

        // update proposal total supply
        proposals[id].totalSupply = AdditionalMath.sqrt(totalSupply());

        uint256 quorum = getQuorum(id);

        if ((quorum < MIN_QUORUM_PUNISHMENT) && proposals[id].withdrawAmount > WITHDRAW_THRESHOLD) {
            // user's stake gets slashed, converted to stablecoin and sent to treasury
            uint256 amount = slash(proposals[id].proposer);
            convertAndSendTreasuryFunds(amount);
        } else if (
            (quorum > MIN_QUORUM_THRESHOLD) &&
            (proposals[id].totalForVotes > proposals[id].totalAgainstVotes)
         ) {
            // treasury to send funds to proposal
            treasury.withdraw(
                proposals[id].withdrawAmount,
                proposals[id].withdrawAddress
            );
        }
    }
    
    function convertAndSendTreasuryFunds(uint256 amount) internal {
        address[] memory routeDetails = new address[](3);
        routeDetails[0] = address(stakeToken);
        routeDetails[1] = swapRouter.WETH();
        routeDetails[2] = address(stablecoin);
        uint[] memory amounts = swapRouter.swapExactTokensForTokens(
            amount,
            0,
            routeDetails,
            address(this),
            block.timestamp + 100
        );
        // 0 = input token amt, 1 = weth output amt, 2 = stablecoin output amt
        treasury.deposit(stablecoin, amounts[2]);
    }

    function getQuorum(uint256 id) public view returns (uint256){
        // sum votes, multiply by precision, divide by square rooted total supply
        require(proposals[id].proposer != address(0), "non-existent proposal");
        
        uint256 _totalSupply;      
        
        if (proposals[id].totalSupply == 0) {
            _totalSupply = AdditionalMath.sqrt(totalSupply());
        } else {
            _totalSupply = proposals[id].totalSupply;
        }             
        uint256 _quorum = 
            (proposals[id].totalForVotes.add(proposals[id].totalAgainstVotes))
            .mul(PERCENTAGE_PRECISION)
            .div(_totalSupply);

        return _quorum;
    }
}

//SPDX-License-Identifier: MIT
/*
* MIT License
* ===========
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/

pragma solidity 0.6.2;


import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";


contract LPTokenWrapperWithSlash {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 private _totalSupply;

    IERC20 public stakeToken;

    mapping(address => uint256) private _balances;

    constructor(IERC20 _stakeToken) public {
        stakeToken = _stakeToken;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function stake(uint256 amount) public virtual {
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        stakeToken.safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount) public virtual {
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        stakeToken.safeTransfer(msg.sender, amount);
    }

    function slash(address proposer) internal returns (uint256 amount) {
        amount = _balances[proposer];
        _totalSupply = _totalSupply.sub(amount);
        _balances[proposer] = 0;
    }
}

//SPDX-License-Identifier: MIT
/*
* MIT License
* ===========
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/

pragma solidity ^0.6.2;


interface IGovernance {
    function getStablecoin() external view returns (address);
}

//SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.6.2;

interface IUniswapV2Factory {
  function getPair(address tokenA, address tokenB) external view returns (address pair);
  function createPair(address tokenA, address tokenB) external returns (address pair);
}

//SPDX-License-Identifier: MIT
/*
* MIT License
* ===========
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/

pragma solidity ^0.6.2;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";


contract BoostToken is ERC20, ERC20Burnable {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint;


    address public governance;
    mapping (address => bool) public minters;

    constructor () public ERC20("Boosted Finance", "BOOST") {
        governance = msg.sender;
        addMinter(governance);
        // underlying _mint function has hard limit 
        mint(governance, 1e23);
    }

    function mint(address account, uint amount) public {
        require(minters[msg.sender], "!minter");
        _mint(account, amount);
    }

    function setGovernance(address _governance) public {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function addMinter(address _minter) public {
        require(msg.sender == governance, "!governance");
        minters[_minter] = true;
    }

    function removeMinter(address _minter) public {
        require(msg.sender == governance, "!governance");
        minters[_minter] = false;
    }

    function burn(uint256 amount) public override {
        _burn(msg.sender, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../../GSN/Context.sol";
import "./ERC20.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }
}

pragma solidity ^0.6.2;

import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";


contract Token is ERC20Burnable {
    
    
    constructor (string memory _name, string memory _symbol, uint8 _decimals) public ERC20( _name, _symbol) {
        _mint(msg.sender , 100000000000000000000000000); // 100 mil tokens
        _setupDecimals(_decimals);
    }
}

pragma solidity ^0.6.2;


contract WETH9 {
    string public name     = "Wrapped Ether";
    string public symbol   = "WETH";
    uint8  public decimals = 18;

    event  Approval(address indexed src, address indexed guy, uint wad);
    event  Transfer(address indexed src, address indexed dst, uint wad);
    event  Deposit(address indexed dst, uint wad);
    event  Withdrawal(address indexed src, uint wad);

    mapping (address => uint)                       public  balanceOf;
    mapping (address => mapping (address => uint))  public  allowance;

    constructor () public payable {
        deposit();
    }

    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint wad) public {
        require(balanceOf[msg.sender] >= wad);
        balanceOf[msg.sender] -= wad;
        msg.sender.transfer(wad);
        emit Withdrawal(msg.sender, wad);
    }

    function totalSupply() public view returns (uint) {
        return address(this).balance;
    }

    function approve(address guy, uint wad) public returns (bool) {
        allowance[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
        return true;
    }

    function transfer(address dst, uint wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint wad)
        public
        returns (bool)
    {
        require(balanceOf[src] >= wad);

        if (src != msg.sender && allowance[src][msg.sender] != uint(-1)) {
            require(allowance[src][msg.sender] >= wad);
            allowance[src][msg.sender] -= wad;
        }

        balanceOf[src] -= wad;
        balanceOf[dst] += wad;

        emit Transfer(src, dst, wad);

        return true;
    }
}

//SPDX-License-Identifier: MIT
/*
* MIT License
* ===========
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/

pragma solidity 0.6.2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ITreasury.sol";
import "./interfaces/ISwapRouter.sol";


contract Treasury is Ownable, ITreasury {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public override defaultToken;
    SwapRouter public swapRouter;
    address public ecoFund;
    address public gov;
    address internal govSetter;

    mapping(address => uint256) public ecoFundAmts;

    // 1% = 100
    uint256 public constant MAX_FUND_PERCENTAGE = 1500; // 15%
    uint256 public constant PERCENTAGE_PRECISION = 10000; // 100%
    uint256 public fundPercentage = 500; // 5%
    
    
    constructor(SwapRouter _swapRouter, IERC20 _defaultToken, address _ecoFund) public {
        swapRouter = _swapRouter;
        defaultToken = _defaultToken;
        ecoFund = _ecoFund;
        govSetter = msg.sender;
    }

    function setGov(address _gov) external {
        require(msg.sender == govSetter, "not authorized");
        gov = _gov;
        govSetter = address(0);
    }

    function setSwapRouter(SwapRouter _swapRouter) external onlyOwner {
        swapRouter = _swapRouter;
    }

    function setEcoFund(address _ecoFund) external onlyOwner {
        ecoFund = _ecoFund;
    }

    function setFundPercentage(uint256 _fundPercentage) external onlyOwner {
        require(_fundPercentage <= MAX_FUND_PERCENTAGE, "exceed max percent");
        fundPercentage = _fundPercentage;
    }

    function balanceOf(IERC20 token) public view returns (uint256) {
        return token.balanceOf(address(this)).sub(ecoFundAmts[address(token)]);
    }

    function deposit(IERC20 token, uint256 amount) external override {
        // portion allocated to ecoFund
        ecoFundAmts[address(token)] = amount.mul(fundPercentage).div(PERCENTAGE_PRECISION);
        token.safeTransferFrom(msg.sender, address(this), amount);
    }

    // only default token withdrawals allowed
    function withdraw(uint256 amount, address withdrawAddress) external override {
        require(msg.sender == gov, "caller not gov");
        require(balanceOf(defaultToken) >= amount, "insufficient funds");
        defaultToken.safeTransfer(withdrawAddress, amount);
    }

    function convertToDefaultToken(address[] calldata routeDetails, uint256 amount) external {
        require(routeDetails[0] != address(defaultToken), "src can't be defaultToken");
        require(routeDetails[routeDetails.length - 1] == address(defaultToken), "dest not defaultToken");
        IERC20 srcToken = IERC20(routeDetails[0]);
        require(balanceOf(srcToken) >= amount, "insufficient funds");
        if (srcToken.allowance(address(this), address(swapRouter)) <= amount) {
            srcToken.safeApprove(address(swapRouter), uint256(-1));
        }
        uint[] memory swappedAmounts = swapRouter.swapExactTokensForTokens(
            amount,
            0,
            routeDetails,
            address(this),
            block.timestamp + 100
        );
        require(swappedAmounts.length != 0, "Swap failed");
    }

    function withdrawEcoFund(IERC20 token, uint256 amount) external {
        ecoFundAmts[address(token)] = ecoFundAmts[address(token)].sub(amount);
        token.safeTransfer(ecoFund, amount);
    }
}

