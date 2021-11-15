// Copyright (C) 2021 Exponent

// This file is part of Exponent.

// Exponent is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// Exponent is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with Exponent.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.8.0;
import "./interface/AggregatorV3Interface.sol";
import "./interface/enzyme/IComptroller.sol";
import "./interface/enzyme/IPolicyManager.sol";

library XPNUtils {
    int256 public constant ONE = 1e18;
    int256 public constant chainlinkONE = 1e8;
    // @notice enzyme fees ID for fees invocation
    uint256 constant FEE_INVOCATION = 0;
    // @notice enzyme fees ID for fees payout
    uint256 constant FEE_PAYOUT = 0;
    // @notice enzyme ID for removing tracked asset
    uint256 constant REMOVE_TRACKED = 2;
    // @notice enzyme ID for adding tracked asset
    uint256 constant ADD_TRACKED = 1;

    function compareStrings(string memory first, string memory second)
        public
        pure
        returns (bool)
    {
        return (keccak256(abi.encodePacked((first))) ==
            keccak256(abi.encodePacked((second))));
    }

    function parseChainlinkPrice(address _feed) external view returns (int256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(_feed);
        (
            uint80 roundID,
            int256 price,
            ,
            uint256 timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();

        require(timeStamp != 0, "Chainlink: round is not complete");
        require(answeredInRound >= roundID, "Chainlink: stale data");
        require(price != 0, "Chainlink: returned 0");
        int256 priceScaled = (price * ONE) / int256(10)**priceFeed.decimals();
        return priceScaled;
    }

    function buyEnzymeShares(address _comptroller, uint256 _amount)
        external
        returns (uint256)
    {
        address[] memory buyer = new address[](1);
        uint256[] memory amount = new uint256[](1);
        uint256[] memory expect = new uint256[](1);
        buyer[0] = address(this);
        amount[0] = _amount;
        expect[0] = 1;
        uint256[] memory sharesBought = IComptroller(_comptroller).buyShares(
            buyer, // this contract as a single buyer
            amount, // amount of shares to purchase
            expect // expect at least 1 share
        );
        return sharesBought[0]; // should have bought only a single share amount
    }

    function redeemEnzymeShares(address _comptroller, uint256 _amount)
        external
        returns (address[] memory, uint256[] memory)
    {
        address[] memory additionalAssets = new address[](0);
        address[] memory assetsToSkip = new address[](0);
        return
            IComptroller(_comptroller).redeemSharesDetailed(
                _amount, // quantity of shares to redeem
                additionalAssets, // no additional assets
                assetsToSkip // don't skip any assets
            );
    }

    // @dev performs 2 actions: settle current fee on Enzyme vault and mint
    //      new shares to vault owner representing accrued fees
    function invokeAndPayoutEnzymeFees(
        address _comptroller,
        address _feeManager,
        address[] memory _fees
    ) external {
        // calculate and settle the current fees accrued on the fund
        IComptroller(_comptroller).callOnExtension(
            _feeManager,
            FEE_INVOCATION, // 0 is action ID for invoking fees
            ""
        );
        // payout the outstanding shares to enzyme vault owner (this contract)
        IComptroller(_comptroller).callOnExtension(
            _feeManager,
            FEE_PAYOUT, // 1 is action ID for payout of outstanding shares
            abi.encode(_fees) // payout using all the fees available ie. performance and management fee
        );
    }

    // @notice declare self as the sole depositor of the enzyme vault contract
    // @dev address(this) is called in the execution context of the caller
    function enforceSoleEnzymeDepositor(
        address _comptroller,
        address _policyManager,
        address _whitelistPolicy
    ) external {
        address[] memory buyersToAdd = new address[](1);
        address[] memory buyersToRemove = new address[](0);
        buyersToAdd[0] = address(this);

        IPolicyManager(_policyManager).enablePolicyForFund(
            _comptroller,
            _whitelistPolicy,
            abi.encode(buyersToAdd, buyersToRemove)
        );
    }

    function addEnzymeTrackedAsset(
        address _comptroller,
        address _integrationManager,
        address _asset
    ) external {
        address[] memory assets = new address[](1);
        assets[0] = _asset;
        bytes memory addTrackedArgs = abi.encode(assets);
        IComptroller(_comptroller).callOnExtension(
            _integrationManager,
            ADD_TRACKED,
            abi.encode(assets)
        );
    }

    function removeEnzymeTrackedAsset(
        address _comptroller,
        address _integrationManager,
        address _asset
    ) external {
        address[] memory assets = new address[](1);
        assets[0] = _asset;
        bytes memory removeTrackedArgs = abi.encode(assets);
        IComptroller(_comptroller).callOnExtension(
            _integrationManager,
            REMOVE_TRACKED,
            abi.encode(assets)
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.0;

interface IComptroller {
    function buyShares(
        address[] calldata,
        uint256[] calldata,
        uint256[] calldata
    ) external returns (uint256[] memory sharesReceivedAmounts_);

    function redeemSharesDetailed(
        uint256,
        address[] calldata,
        address[] calldata
    ) external returns (address[] memory, uint256[] memory);

    function callOnExtension(
        address,
        uint256,
        bytes calldata
    ) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.0;

interface IPolicyManager {
    function enablePolicyForFund(
        address,
        address,
        bytes calldata
    ) external;
}

