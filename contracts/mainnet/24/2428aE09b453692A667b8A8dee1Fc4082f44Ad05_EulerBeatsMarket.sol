/**
 *Submitted for verification at Etherscan.io on 2021-04-09
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;



// Part: IERC1155

interface IERC1155 {
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;
}

// Part: IEulerBeats

interface IEulerBeats {

    /**
     * @dev Function to mint prints from an existing seed. Msg.value must be sufficient.
     * @param seed The NFT id to mint print of
     * @param _owner The current on-chain owner of the seed
     */
    function mintPrint(uint256 seed, address payable _owner)
        external
        payable
        returns (uint256);

    /**
     * @dev Get the number of prints minted for the corresponding seed
     * @param seed The seed/original NFT token id
     */
    function seedToPrintsSupply(uint256 seed)
        external
        view
        returns (uint256);

    /**
     * @dev Function to get print price
     * @param printNumber the print number of the print Ex. if there are 2 existing prints, and you want to get the
     * next print price, then this should be 3 as you are getting the price to mint the 3rd print
     */
    function getPrintPrice(uint256 printNumber) external pure returns (uint256 price);

    function seedToOwner(uint256 seed) external view returns (address owner);

    /**
     * @dev The token id for the prints contains the seed/original NFT id
     * @param seed The seed/original NFT token id
     */
    function getPrintTokenIdFromSeed(uint256 seed) external pure returns (uint256);
}

// File: EulerBeatsMarket.sol

library EulerBeatsMarket {

    address public constant EULERBEATS = 0x8754F54074400CE745a7CEddC928FB1b7E985eD6;
    address public constant PRINTINGPRESS = 0x8Cac485c30641ece09dBeB2b5245E24dE4830F27;

    function buyAssetsForEth(bytes memory data, address recipient) public {
        uint256[] memory seeds;
        (seeds) = abi.decode(
            data,
            (uint256[])
        );
        
        for (uint256 i = 0; i < seeds.length; i++) {
            _buyAssetFromMarket(seeds[i], estimateAssetPriceInEth(seeds[i]), recipient);
        }
    }

    function estimateAssetPriceInEth(uint256 seed) public view returns(uint256) {
        // Get price to mint the next print
        return IEulerBeats(EULERBEATS).getPrintPrice(IEulerBeats(EULERBEATS).seedToPrintsSupply(seed) + 1);
    }

    function estimateBatchAssetPriceInEth(bytes memory data) public view returns(uint256 totalCost) {
        uint256[] memory seeds;
        (seeds) = abi.decode(
            data,
            (uint256[])
        );
        for (uint256 i = 0; i < seeds.length; i++) {
            totalCost += IEulerBeats(EULERBEATS).getPrintPrice(IEulerBeats(EULERBEATS).seedToPrintsSupply(seeds[i]) + 1);
        }
    }

    function _buyAssetFromMarket(uint256 _seed, uint256 _price, address _recipient) internal {
        bytes memory _data = abi.encodeWithSelector(IEulerBeats(PRINTINGPRESS).mintPrint.selector, _seed, IEulerBeats(EULERBEATS).seedToOwner(_seed));

        (bool success, ) = PRINTINGPRESS.call{value:_price}(_data);
        require(success, "_buyAssetFromMarket: EulerBeats buy failed.");

        IERC1155(EULERBEATS).safeTransferFrom(address(this), _recipient, IEulerBeats(EULERBEATS).getPrintTokenIdFromSeed(_seed), 1, "");
    }
}