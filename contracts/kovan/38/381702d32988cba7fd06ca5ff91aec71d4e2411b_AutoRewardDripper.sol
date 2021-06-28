/**
 *Submitted for verification at Etherscan.io on 2021-06-28
*/

/// AutoRewardDripper.sol

// Copyright (C) 2021 Reflexer Labs, INC
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.6.7;

abstract contract TokenLike {
    function balanceOf(address) virtual public view returns (uint256);
    function transfer(address, uint256) virtual external returns (bool);
}

contract AutoRewardDripper {
    // --- Auth ---
    mapping (address => uint) public authorizedAccounts;
    /**
     * @notice Add auth to an account
     * @param account Account to add auth to
     */
    function addAuthorization(address account) virtual external isAuthorized {
        authorizedAccounts[account] = 1;
        emit AddAuthorization(account);
    }
    /**
     * @notice Remove auth from an account
     * @param account Account to remove auth from
     */
    function removeAuthorization(address account) virtual external isAuthorized {
        authorizedAccounts[account] = 0;
        emit RemoveAuthorization(account);
    }
    /**
    * @notice Checks whether msg.sender can call an authed function
    **/
    modifier isAuthorized {
        require(authorizedAccounts[msg.sender] == 1, "AutoRewardDripper/account-not-authorized");
        _;
    }

    // --- Variables ---
    // Last block when a reward was given
    uint256   public lastRewardBlock;
    // Amount of tokens distributed per block
    uint256   public rewardPerBlock;
    // The timeline (in number of blocks) used to calculate rewardPerBlock
    uint256   public rewardTimeline;
    // Last time when the reward was calculated
    uint256   public lastRewardCalculation;
    // Delay between reward calculations
    uint256   public rewardCalculationDelay;
    // The address that can request rewards
    address   public requestor;
    // The reward token being distributed
    TokenLike public rewardToken;

    uint256 public constant MAX_REWARD_TIMELINE = 2592000;

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    event ModifyParameters(bytes32 indexed parameter, uint256 data);
    event ModifyParameters(bytes32 indexed parameter, address data);
    event DripReward(address requestor, uint256 amountToTransfer);
    event TransferTokenOut(address dst, uint256 amount);
    event RecomputePerBlockReward(uint256 rewardPerBlock);

    constructor(
      address requestor_,
      address rewardToken_,
      uint256 rewardTimeline_,
      uint256 rewardCalculationDelay_
    ) public {
        require(requestor_ != address(0), "AutoRewardDripper/null-requoestor");
        require(rewardToken_ != address(0), "AutoRewardDripper/null-reward-token");
        require(rewardTimeline_ > 0, "AutoRewardDripper/null-reward-time");
        require(rewardTimeline_ <= MAX_REWARD_TIMELINE, "AutoRewardDripper/high-reward-timeline");
        require(rewardCalculationDelay_ > 0, "AutoRewardDripper/null-reward-calc-delay");

        authorizedAccounts[msg.sender] = 1;

        rewardTimeline         = rewardTimeline_;
        requestor              = requestor_;
        rewardCalculationDelay = rewardCalculationDelay_;
        rewardToken            = TokenLike(rewardToken_);
        lastRewardBlock        = block.number;

        emit AddAuthorization(msg.sender);
        emit ModifyParameters("rewardTimeline", rewardTimeline);
        emit ModifyParameters("rewardCalculationDelay", rewardCalculationDelay);
        emit ModifyParameters("requestor", requestor);
        emit ModifyParameters("lastRewardBlock", lastRewardBlock);
    }

    // --- Boolean ---
    function either(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := or(x, y)}
    }

    // --- Math ---
    function subtract(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "AutoRewardDripper/sub-underflow");
    }
    function multiply(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "AutoRewardDripper/mul-overflow");
    }

    // --- Administration ---
    /*
    * @notify Modify an uint256 parameter
    * @param parameter The name of the parameter to modify
    * @param data New value for the parameter
    */
    function modifyParameters(bytes32 parameter, uint256 data) external isAuthorized {
        if (parameter == "lastRewardBlock") {
            require(data >= block.number, "AutoRewardDripper/invalid-last-reward-block");
            lastRewardBlock = data;
        } else if (parameter == "rewardPerBlock") {
            require(data > 0, "AutoRewardDripper/invalid-reward-per-block");
            rewardPerBlock = data;
        } else if (parameter == "rewardCalculationDelay") {
            require(data > 0, "AutoRewardDripper/invalid-reward-calculation-delay");
            rewardCalculationDelay = data;
        } else if (parameter == "rewardTimeline") {
            require(data > 0 && data <= MAX_REWARD_TIMELINE, "AutoRewardDripper/invalid-reward-timeline");
            rewardTimeline = data;
        }
        else revert("AutoRewardDripper/modify-unrecognized-param");
        emit ModifyParameters(parameter, data);
    }
    /*
    * @notify Modify an address parameter
    * @param parameter The name of the parameter to modify
    * @param data New value for the parameter
    */
    function modifyParameters(bytes32 parameter, address data) external isAuthorized {
        require(data != address(0), "AutoRewardDripper/null-data");
        if (parameter == "requestor") {
            requestor = data;
        }
        else revert("AutoRewardDripper/modify-unrecognized-param");
        emit ModifyParameters(parameter, data);
    }

    // --- Core Logic ---
    /*
    * @notice Transfer tokens to a custom address
    * @param dst The destination address for the tokens
    * @param amount The amount of tokens transferred
    */
    function transferTokenOut(address dst, uint256 amount) external isAuthorized {
        require(dst != address(0), "AutoRewardDripper/null-dst");
        require(amount > 0, "AutoRewardDripper/null-amount");

        rewardToken.transfer(dst, amount);

        emit TransferTokenOut(dst, amount);
    }
    /*
    * @notify Send rewards to the requestor
    */
    function dripReward() external {
        dripReward(msg.sender);
    }
    /*
    * @notify Recompute rewardPerBlock
    */
    function recomputePerBlockReward() public {
        uint256 remainingBalance = rewardToken.balanceOf(address(this));
        if (either(remainingBalance == 0, subtract(now, lastRewardCalculation) < rewardCalculationDelay)) return;
        lastRewardCalculation    = now;
        rewardPerBlock           = (rewardTimeline >= remainingBalance) ? remainingBalance : remainingBalance / rewardTimeline;
        emit RecomputePerBlockReward(rewardPerBlock);
    }
    /*
    * @notify Send rewards to an address defined by the requestor
    */
    function dripReward(address to) public {
        if (lastRewardBlock >= block.number) return;
        require(msg.sender == requestor, "AutoRewardDripper/invalid-caller");

        uint256 remainingBalance = rewardToken.balanceOf(address(this));
        uint256 amountToTransfer = multiply(subtract(block.number, lastRewardBlock), rewardPerBlock);
        amountToTransfer         = (amountToTransfer > remainingBalance) ? remainingBalance : amountToTransfer;

        lastRewardBlock = block.number;
        recomputePerBlockReward();

        if (amountToTransfer == 0) return;
        rewardToken.transfer(to, amountToTransfer);

        emit DripReward(to, amountToTransfer);
    }
}