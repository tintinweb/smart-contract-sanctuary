/*
    Copyright 2021 Universal Dollar Devs, based on the works of the Empty Set Squad

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./Market.sol";
import "./Regulator.sol";
import "./Bonding.sol";
import "./Govern.sol";
import "../Constants.sol";
import "../oracle/IPool.sol";

contract Implementation is State, Bonding, Market, Regulator, Govern {
    using SafeMath for uint256;

    event Advance(uint256 indexed epoch, uint256 block, uint256 timestamp);
    event Incentivization(address indexed account, uint256 amount);

    function initialize() initializer public {
        // upgrade pool
        IPool(pool()).upgrade(0x64c8A67Da288C1332F3eFA672c3588D9905218B2);
    }

    function advance() external {
        Decimal.D256 memory price = oracleCapture();

        uint256 incentive = Decimal.from(Constants.getAdvanceIncentiveUsd())
                            .div(price)
                            .asUint256();
        uint256 maxIncentive = Constants.getAdvanceMaxIncentive();
        incentive = (incentive < maxIncentive) ? incentive : maxIncentive;

        incentivize(msg.sender, incentive);

        Bonding.step();
        Regulator.step(price);
        Market.step();

        emit Advance(epoch(), block.number, block.timestamp);
    }

    // Override for the distribution of penalty
    function boostStream() public returns (uint256) {
        uint256 penalty = Bonding.boostStream();

        // distribute penalty if more than one dollar
        distribute(penalty);

        return penalty;
    }

    // Distribution of penalty from Pool contract
    function distributePenalty(uint256 penalty) external onlyPool {
        // distribute penalty if more than one dollar
        distribute(penalty);
    }

    function incentivize(address account, uint256 amount) private {
        mintToAccount(account, amount);
        emit Incentivization(account, amount);
    }
}