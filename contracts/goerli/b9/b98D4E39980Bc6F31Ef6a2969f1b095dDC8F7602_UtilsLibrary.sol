// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IOption.sol";

library UtilsLibrary {
    function getOptionInfo(address optionAddress) internal view returns (IOption.OptionInfo memory optionInfo) {
        IOption option = IOption(optionAddress);
        optionInfo = IOption.OptionInfo(
            option.underlyingAsset(),
            option.strikeAsset(),
            option.oracle(),
            option.strikePrice(),
            option.expiryTime(),
            option.isCall()
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOption {
    struct OptionInfo {
        address underlyingAsset;
        address strikeAsset;
        address oracle;
        uint256 strikePrice;
        uint256 expiryTime;
        bool isCall;
    }

    function underlyingAsset() external view returns (address);

    function strikeAsset() external view returns (address);

    function oracle() external view returns (address);

    function strikePrice() external view returns (uint256);

    function expiryTime() external view returns (uint256);

    function isCall() external view returns (bool);
}

