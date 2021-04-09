/**
 *Submitted for verification at Etherscan.io on 2021-04-09
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;



// Part: IKnownOrigin

interface IKnownOrigin {

    /**
    * @dev Public entry point for purchasing an edition on behalf of someone else
    * @dev Reverts if edition is invalid
    * @dev Reverts if payment not provided in full
    * @dev Reverts if edition is sold out
    * @dev Reverts if edition is not active or available
    */
    function purchaseTo(address _to, uint256 _editionNumber)
    external
    payable
    returns (uint256);

    /**
    * @dev Main entry point for looking up edition config/metadata
    * @dev Reverts if invalid edition number provided
    */
    function detailsOfEdition(uint256 editionNumber) 
    external 
    view
    returns (
        bytes32 _editionData,
        uint256 _editionType,
        uint256 _startDate,
        uint256 _endDate,
        address _artistAccount,
        uint256 _artistCommission,
        uint256 _priceInWei,
        string memory _tokenURI,
        uint256 _totalSupply,
        uint256 _totalAvailable,
        bool _active
    );
}

// File: KnownOriginMarket.sol

library KnownOriginMarket {

    address public constant KNOWNORIGIN = 0xFBeef911Dc5821886e1dda71586d90eD28174B7d;

    function buyAssetsForEth(bytes memory data, address recipient) public {
        uint256[] memory editionNumbers;
        (editionNumbers) = abi.decode(
            data,
            (uint256[])
        );

        for (uint256 i = 0; i < editionNumbers.length; i++) {
            _buyAssetFromMarket(editionNumbers[i], estimateAssetPriceInEth(editionNumbers[i]), recipient);
        }
    }

    function estimateAssetPriceInEth(uint256 editionNumber) public view returns(uint256 priceInWei) {
        // Get price to mint the next print
        (,,,,,,priceInWei,,,,) = IKnownOrigin(KNOWNORIGIN).detailsOfEdition(editionNumber);
    }

    function estimateBatchAssetPriceInEth(bytes memory data) public view returns(uint256 totalCost) {
        uint256[] memory editionNumbers;
        (editionNumbers) = abi.decode(
            data,
            (uint256[])
        );

        for (uint256 i = 0; i < editionNumbers.length; i++) {
            uint256 priceInWei;
            (,,,,,,priceInWei,,,,) = IKnownOrigin(KNOWNORIGIN).detailsOfEdition(editionNumbers[i]);
            totalCost += priceInWei;
        }
    }

    function _buyAssetFromMarket(uint256 _editionNumber, uint256 _price, address _recipient) internal {
        bytes memory _data = abi.encodeWithSelector(IKnownOrigin(KNOWNORIGIN).purchaseTo.selector, _recipient, _editionNumber);

        (bool success, ) = KNOWNORIGIN.call{value:_price}(_data);
        require(success, "_buyAssetFromMarket: KnownOrigin buy failed.");
    }
}