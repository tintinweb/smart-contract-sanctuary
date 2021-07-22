// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

import "../../interfaces/punks/ICryptoPunks.sol";
import "../../interfaces/punks/IWrappedPunk.sol";
import "../../interfaces/mooncats/IMoonCatsWrapped.sol";
import "../../interfaces/mooncats/IMoonCatsRescue.sol";
import "../../interfaces/mooncats/IMoonCatAcclimator.sol";
import "../../interfaces/markets/tokens/IERC721.sol";

library Converter {

    struct MoonCatDetails {
        bytes5[] catIds;
        uint256[] oldTokenIds;
        uint256[] rescueOrders;
    }

    /**
    * @dev converts uint256 to a bytes(32) object
    */
    function _uintToBytes(uint256 x) internal pure returns (bytes memory b) {
        b = new bytes(32);
        assembly {
            mstore(add(b, 32), x)
        }
    }

    /**
    * @dev converts address to a bytes(32) object
    */
    function _addressToBytes(address a) internal pure returns (bytes memory) {
        return abi.encodePacked(a);
    }

    function mooncatToAcclimated(MoonCatDetails memory moonCatDetails) external {
        for (uint256 i = 0; i < moonCatDetails.catIds.length; i++) {
            // make an adoption offer to the Acclimated​MoonCats contract
            IMoonCatsRescue(0x60cd862c9C687A9dE49aecdC3A99b74A4fc54aB6).makeAdoptionOfferToAddress(
                moonCatDetails.catIds[i], 
                0, 
                0xc3f733ca98E0daD0386979Eb96fb1722A1A05E69
            );
        }
        // mint Acclimated​MoonCats
        IMoonCatAcclimator(0xc3f733ca98E0daD0386979Eb96fb1722A1A05E69).batchWrap(moonCatDetails.rescueOrders);
    }

    function wrappedToAcclimated(MoonCatDetails memory moonCatDetails) external {
        for (uint256 i = 0; i < moonCatDetails.oldTokenIds.length; i++) {
            // transfer the token to Acclimated​MoonCats to mint
            IERC721(0x7C40c393DC0f283F318791d746d894DdD3693572).safeTransferFrom(
                address(this),
                0xc3f733ca98E0daD0386979Eb96fb1722A1A05E69,
                moonCatDetails.oldTokenIds[i],
                abi.encodePacked(
                    _uintToBytes(moonCatDetails.rescueOrders[i]),
                    _addressToBytes(address(this))
                )
            );
        }
    }

    function mooncatToWrapped(MoonCatDetails memory moonCatDetails) external {
        for (uint256 i = 0; i < moonCatDetails.catIds.length; i++) {
            // make an adoption offer to the Acclimated​MoonCats contract               
            IMoonCatsRescue(0x60cd862c9C687A9dE49aecdC3A99b74A4fc54aB6).makeAdoptionOfferToAddress(
                moonCatDetails.catIds[i], 
                0, 
                0x7C40c393DC0f283F318791d746d894DdD3693572
            );
            // mint Wrapped Mooncat
            IMoonCatsWrapped(0x7C40c393DC0f283F318791d746d894DdD3693572).wrap(moonCatDetails.catIds[i]);
        }
    }

    function acclimatedToWrapped(MoonCatDetails memory moonCatDetails) external {
        // unwrap Acclimated​MoonCats to get Mooncats
        IMoonCatAcclimator(0xc3f733ca98E0daD0386979Eb96fb1722A1A05E69).batchUnwrap(moonCatDetails.rescueOrders);
        // Convert Mooncats to Wrapped Mooncats
        for (uint256 i = 0; i < moonCatDetails.rescueOrders.length; i++) {
            // make an adoption offer to the Acclimated​MoonCats contract               
            IMoonCatsRescue(0xc3f733ca98E0daD0386979Eb96fb1722A1A05E69).makeAdoptionOfferToAddress(
                moonCatDetails.catIds[i], 
                0, 
                0x7C40c393DC0f283F318791d746d894DdD3693572
            );
            // mint Wrapped Mooncat
            IMoonCatsWrapped(0x7C40c393DC0f283F318791d746d894DdD3693572).wrap(moonCatDetails.catIds[i]);
        }
    }

    function cryptopunkToWrapped(address punkProxy, uint256[] memory tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            // transfer the CryptoPunk to the userProxy
            ICryptoPunks(0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB).transferPunk(punkProxy, tokenIds[i]);
            // mint Wrapped CryptoPunk
            IWrappedPunk(0xb7F7F6C52F2e2fdb1963Eab30438024864c313F6).mint(tokenIds[i]);
        }
    }

    function wrappedToCryptopunk(uint256[] memory tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            IWrappedPunk(0xb7F7F6C52F2e2fdb1963Eab30438024864c313F6).burn(tokenIds[i]);
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

interface ICryptoPunks {
    function punkIndexToAddress(uint index) external view returns(address owner);
    function offerPunkForSaleToAddress(uint punkIndex, uint minSalePriceInWei, address toAddress) external;
    function buyPunk(uint punkIndex) external payable;
    function transferPunk(address to, uint punkIndex) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

interface IWrappedPunk {
    /**
     * @dev Mints a wrapped punk
     */
    function mint(uint256 punkIndex) external;

    /**
     * @dev Burns a specific wrapped punk
     */
    function burn(uint256 punkIndex) external;
    
    /**
     * @dev Registers proxy
     */
    function registerProxy() external;

    /**
     * @dev Gets proxy address
     */
    function proxyInfo(address user) external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

interface IMoonCatsWrapped {
    function wrap(bytes5 catId) external;
    function _catIDToTokenID(bytes5 catId) external view returns(uint256);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

interface IMoonCatsRescue {
    function acceptAdoptionOffer(bytes5 catId) payable external;
    function makeAdoptionOfferToAddress(bytes5 catId, uint price, address to) external;
    function giveCat(bytes5 catId, address to) external;
    function catOwners(bytes5 catId) external view returns(address);
    function rescueOrder(uint256 rescueIndex) external view returns(bytes5 catId);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

interface IMoonCatAcclimator {
    /**
     * @dev rewrap several MoonCats from the old wrapper at once
     * Owner needs to call setApprovalForAll in old wrapper first.
     * @param _rescueOrders an array of MoonCats, identified by rescue order, to rewrap
     * @param _oldTokenIds an array holding the corresponding token ID
     *        in the old wrapper for each MoonCat to be rewrapped
     */
    function batchReWrap(
        uint256[] memory _rescueOrders,
        uint256[] memory _oldTokenIds
    ) external;

    /**
     * @dev Take a list of unwrapped MoonCat rescue orders and wrap them.
     * @param _rescueOrders an array of MoonCats, identified by rescue order, to rewrap
     */
    function batchWrap(uint256[] memory _rescueOrders) external;

    /**
     * @dev Take a list of MoonCats wrapped in this contract and unwrap them.
     * @param _rescueOrders an array of MoonCats, identified by rescue order, to unwrap
     */
    function batchUnwrap(uint256[] memory _rescueOrders) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

interface IERC721 {
    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) external;
    
    function setApprovalForAll(address operator, bool approved) external;

    function approve(address to, uint256 tokenId) external;
    
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}