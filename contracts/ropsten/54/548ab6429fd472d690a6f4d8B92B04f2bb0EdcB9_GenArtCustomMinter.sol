pragma solidity ^0.5.0;

import './GenArtMinterV2_DoodleLabs.sol';
import './SafeMath.sol';

contract GenArtCustomMinter is GenArt721Minter_DoodleLabs {
    using SafeMath for uint256;

    event PurchaseMany(uint256 projectId, uint256 amount);

    constructor(address _genArtCore) GenArt721Minter_DoodleLabs(_genArtCore) public {}

    function purchaseMany(uint256 projectId, uint256 amount) public payable returns (uint256[] memory _tokenId) {
        uint256[] memory tokenIds = new uint256[](amount);

        // Refund ETH if user accidentially overpays
        // This is not needed for ERC20 tokens
        if (msg.value > 0) {
            uint256 pricePerTokenInWei = genArtCoreContract.projectIdToPricePerTokenInWei(projectId);
            uint256 refund = msg.value.sub(pricePerTokenInWei.mul(amount));

            if (refund > 0) {
                msg.sender.transfer(refund);
            }
        }

        for (uint256 i = 0; i < amount; i++) {
            tokenIds[i] = purchaseTo(msg.sender, projectId, true);
        }

        emit PurchaseMany(projectId, amount);
        return tokenIds;
    }

}