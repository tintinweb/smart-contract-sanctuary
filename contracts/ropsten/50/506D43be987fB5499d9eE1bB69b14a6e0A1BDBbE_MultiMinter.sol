pragma solidity ^0.5.0;

import './GenArtMinterV2_DoodleLabs.sol';


contract MultiMinter is GenArt721Minter_DoodleLabs {

    constructor(address _genArtCore) GenArt721Minter_DoodleLabs(_genArtCore) public {}

    function purchaseMany(uint256 projectId, uint256 amount) public payable returns (uint256[] memory _tokenId) {
        uint256[] memory tokenIds = new uint256[](amount);

        uint256 pricePerTokenInWei = genArtCoreContract.projectIdToPricePerTokenInWei(projectId);
        uint256 refund = msg.value.sub(pricePerTokenInWei.mul(amount));

        if (refund > 0) {
            msg.sender.transfer(refund);
        }

        for (uint256 i = 0; i < amount; i++) {
            tokenIds[i] = purchaseTo(msg.sender, projectId, true);
        }

        return tokenIds;
    }

}