// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "IGamblePool.sol";
import "IFund.sol";
import "IBurn.sol";

contract FundBurn01 is IFund {


    bool public registeredInPool;
    uint256 public rewardForCurrentEpoch;

    IGamblePool public  gamblePool;


    modifier onlyFund() {
      require(msg.sender == address(gamblePool));
      _;
    }

    function registerFund() external override returns (bool) {
        require(!registeredInPool, "Already registered");
        gamblePool = IGamblePool(msg.sender);
        registeredInPool = true;
        return registeredInPool;
    }

    function newReward(uint256 _amount) external override onlyFund returns (bool) {
        rewardForCurrentEpoch += _amount;
        return true;
    }

    function withdrawAndBurn(uint256 _amount) external {
        require(msg.sender == gamblePool.owner(), "Onle owner");
        require(_amount <= rewardForCurrentEpoch, "Too much for burn");
        rewardForCurrentEpoch -= _amount;
        gamblePool.withdraw(_amount);
        IBurn(gamblePool.projectToken()).burn(_amount);
    }


    /////////////////////////////////////////////////////////////////
    //  All functions below for interface compatibilty ONLY       ///
    /////////////////////////////////////////////////////////////////

    function joinFund(address _user) external override returns (bool) {
        return true;
    }

    function claimReward(address _user) external override onlyFund 
        returns 
    (uint256 userRewardAmount) 
    { 
        return 0;
    }

    function claimRewardForEpoch(address _user, uint256 _epoch) 
        public 
        override 
        onlyFund 
        returns 
    (uint256 userRewardAmount)
    {
        return 0;
    }

    function updateUserState(address _user) external override onlyFund {
        registeredInPool;
    }

    function getAvailableReward(address _user) external view override returns (uint256) {
       return 0;
    }

    function getAvailableReward(address _user, uint256 _epoch) external view override returns (uint256) {
        return 0;
    }

    function isJoined(address _user) external view override returns (bool joined) {
        return true;
    } 
 
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IGamblePool  {
    function totalStaked() external view returns(uint256);
    
    // Main acount with amount of tokens that are frozen in bets.
    // Sub Account for totalStaked
    function inBetsAmount() external view returns(uint256);  
    
    //Main acount with amount of tokens in all funds
    function fundBalance() external view returns(uint256);

    function getGamesCount() external view returns (uint256);

    function getUsersBetsCount(address _user) external view returns (uint256);

    function getUsersBetAmountByIndex(address _user, uint256 _index) 
        external 
        view 
        returns (uint256);

    function getUserBalance(address _user) external view returns(uint256);

    //function accruedPoints(address _user) external view returns(uint256 points);

    function SCALE() external view returns (uint256);

    function owner() external view returns (address);

    function withdraw(uint256 _amount) external;

    function projectToken() external view returns(address);
    function lastSettledCreator() external view returns(address);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;


interface IFund {

    function registerFund() external returns (bool); 

    function joinFund(address _user) external  returns (bool);

    function claimReward(address _user) external returns (uint256);

    function claimRewardForEpoch(address _user, uint256 _epoch) external returns (uint256);

    function updateUserState(address _user) external;

    function newReward(uint256 _amount) external returns (bool);

    function isJoined(address _user) external view returns (bool);

    function getAvailableReward(address _user) external view returns (uint256);

    function getAvailableReward(address _user, uint256 _epoch) external view returns (uint256); 
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IBurn is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function burn(uint256 _amount) external;
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