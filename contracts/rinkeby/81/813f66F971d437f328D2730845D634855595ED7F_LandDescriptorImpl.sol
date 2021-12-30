// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../interfaces/LandERC721Spec.sol";
import "../interfaces/LandDescriptorSpec.sol";
import "../lib/NFTSvg.sol";

contract LandDescriptorImpl {
	 /**
	  * @dev Generates a base64 json metada file based on data supplied by the
		*      land contract.
		* @dev Plot data should be returned from the land contract in order to use
		*      the NFTSvg library which is called
		* 
		* @param _plot Plot view data containing Sites array
	  */
		function tokenURI(LandLib.PlotView calldata _plot) external pure returns (string memory) {
				NFTSvg.SiteSVGData[] memory sites = new NFTSvg.SiteSVGData[](_plot.sites.length);

				for (uint256 i = 0; i < _plot.sites.length; i++) {
						sites[i] = NFTSvg.SiteSVGData({
							typeId: _plot.sites[i].typeId,
							x: _plot.sites[i].x,
							y: _plot.sites[i].y
						});
				}

				return NFTSvg.constructTokenURI(_plot.regionId, _plot.x, _plot.y, _plot.tierId, sites);
		}

		
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../lib/LandLib.sol";

/**
 * @title Land ERC721 Metadata
 *
 * @notice Defines metadata-related capabilities for LandERC721 token.
 *      This interface should be treated as a definition of what metadata is for LandERC721,
 *      and what operations are defined/allowed for it.
 *
 * @author Basil Gorin
 */
interface LandERC721Metadata {
	/**
	 * @notice Presents token metadata in a well readable form,
	 *      with the Internal Land Structure included, as a `PlotView` struct
	 *
	 * @notice Reconstructs the internal land structure of the plot based on the stored
	 *      Tier ID, Plot Size, Generator Version, and Seed
	 *
	 * @param _tokenId token ID to query metadata view for
	 * @return token metadata as a `PlotView` struct
	 */
	function viewMetadata(uint256 _tokenId) external view returns(LandLib.PlotView memory);

	/**
	 * @notice Presents token metadata "as is", without the Internal Land Structure included,
	 *      as a `PlotStore` struct;
	 *
	 * @notice Doesn't reconstruct the internal land structure of the plot, allowing to
	 *      access Generator Version, and Seed fields "as is"
	 *
	 * @param _tokenId token ID to query on-chain metadata for
	 * @return token metadata as a `PlotStore` struct
	 */
	function getMetadata(uint256 _tokenId) external view returns(LandLib.PlotStore memory);

	/**
	 * @notice Verifies if token has its metadata set on-chain; for the tokens
	 *      in existence metadata is immutable, it can be set once, and not updated
	 *
	 * @dev If `exists(_tokenId) && hasMetadata(_tokenId)` is true, `setMetadata`
	 *      for such a `_tokenId` will always throw
	 *
	 * @param _tokenId token ID to check metadata existence for
	 * @return true if token ID specified has metadata associated with it
	 */
	function hasMetadata(uint256 _tokenId) external view returns(bool);

	/**
	 * @dev Sets/updates token metadata on-chain; same metadata struct can be then
	 *      read back using `getMetadata()` function, or it can be converted to
	 *      `PlotView` using `viewMetadata()` function
	 *
	 * @dev The metadata supplied is validated to satisfy (regionId, x, y) uniqueness;
	 *      non-intersection of the sites coordinates within a plot is guaranteed by the
	 *      internal land structure generator algorithm embedded into the `viewMetadata()`
	 *
	 * @dev Metadata for non-existing tokens can be set and updated unlimited
	 *      amount of times without any restrictions (except the constraints above)
	 * @dev Metadata for an existing token can only be set, it cannot be updated
	 *      (`setMetadata` will throw if metadata already exists)
	 *
	 * @param _tokenId token ID to set/updated the metadata for
	 * @param _plot token metadata to be set for the token ID
	 */
	function setMetadata(uint256 _tokenId, LandLib.PlotStore memory _plot) external;

	/**
	 * @dev Removes token metadata
	 *
	 * @param _tokenId token ID to remove metadata for
	 */
	function removeMetadata(uint256 _tokenId) external;

	/**
	 * @dev Mints the token and assigns the metadata supplied
	 *
	 * @dev Creates new token with the token ID specified
	 *      and assigns an ownership `_to` for this token
	 *
	 * @dev Unsafe: doesn't execute `onERC721Received` on the receiver.
	 *      Consider minting with `safeMint` (and setting metadata before),
	 *      for the "safe mint" like behavior
	 *
	 * @param _to an address to mint token to
	 * @param _tokenId token ID to mint and set metadata for
	 * @param _plot token metadata to be set for the token ID
	 */
	function mintWithMetadata(address _to, uint256 _tokenId, LandLib.PlotStore memory _plot) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./LandERC721Spec.sol";

/**
 * @title Land Descriptor interface
 *
 * @dev Defines parameters required to generate the dynamic tokenURI based on
 *      land metadata.
 */

interface LandDescriptor {
		/**
		 * @dev Creates a base64 uri with the land svg image data embedded
		 * 
		 * @param _plot Plot view data containing Sites array
		 */
		 function tokenURI(LandLib.PlotView calldata _plot) external pure returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../lib/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

library NFTSvg {
		using Strings for uint256;
		struct SiteSVGData {
			// site type id
			uint8 typeId;
			// x coordinate
			uint16 x;
			// y coordinate
			uint16 y;
		}

		/**
		 * @dev Pure function that returns the main svg array component, used in the
		 *      top level of the generated land SVG.
		 */
		function _mainSvg() private pure returns (string[6] memory mainSvg) {
				mainSvg = [
					"<svg width='280' height='280' viewBox='0 0 280 283' fill='none' stroke='#000' strokeWidth='2'  xmlns='http://www.w3.org/2000/svg'>",
					"<rect rx='8' ry='8' x='0.5' y='263' width='279' height='20' fill='url(#BOARD_BOTTOM_BORDER_COLOR_TIER_",
					"LAND_TIER_ID",
					")' stroke='none'/>",
					"FUTURE_BOARD_CONTAINER", // This line should be replaced in the loop
					"</svg>"
				];
		}

		/**
		 * @dev Pure function that returns the site base svg array component, used to represent
		 *      a site inside the land board.
		 */
		function _siteBaseSvg() private pure returns (string[10] memory siteBaseSvg) {
				siteBaseSvg = [
					"<svg viewBox='0.1 -0.4 16 16' x='",
					"SITE_X_POSITION", // This line should be replaced in the loop
					"' y='",
					"SITE_Y_POSITION", // This line should be replaced in the loop
					"' width='16' height='16' xmlns='http://www.w3.org/2000/svg'> ",
					"<rect fill='url(#SITE_TYPE_",
					"SITE_TYPE_ID", // This line should be replaced in the loop
					")' width='4.7' height='4.7' stroke-opacity='0' transform='translate(0.7 0.7)'/>",
					"<rect  width='5' height='5' stroke='#fff' stroke-opacity='0.5' transform='translate(0.5 0.5)'/>",
					"</svg>"
				];
		}

		/**
		 * @dev Returns the land board base svg array component, which has its color changed
		 *      later in other functions.
		 */
		function _boardSvg() private pure returns (string[105] memory boardSvg) {
				boardSvg = [
					"<svg x='0' y='0' viewBox='0 0 280 280' width='280' height='280' xmlns='http://www.w3.org/2000/svg' >",
					"<defs>",
					"<linearGradient id='SITE_TYPE_5' gradientTransform='rotate(45)' xmlns='http://www.w3.org/2000/svg'>",
					"<stop offset='0%' stop-color='#31F27F' />",
					"<stop offset='29.69%' stop-color='#F4BE86' />",
					"<stop offset='57.81%' stop-color='#B26FD2' />",
					"<stop offset='73.44%' stop-color='#7F70D2' />",
					"<stop offset='100%' stop-color='#8278F2' />",
					"</linearGradient>",
					"<linearGradient id='SITE_TYPE_4' gradientTransform='rotate(45)' xmlns='http://www.w3.org/2000/svg'>",
					"<stop offset='0%' stop-color='#184B00' />",
					"<stop offset='100%' stop-color='#52FF00' />",
					"</linearGradient>",
					"<linearGradient id='SITE_TYPE_2' gradientTransform='rotate(45)' xmlns='http://www.w3.org/2000/svg'>",
					"<stop offset='0%' stop-color='#CBE2FF' />",
					"<stop offset='100%' stop-color='#EFEFEF' />",
					"</linearGradient>",
					"<linearGradient id='SITE_TYPE_3' gradientTransform='rotate(45)' xmlns='http://www.w3.org/2000/svg'>",
					"<stop offset='0%' stop-color='#8CD4D9' />",
					"<stop offset='100%' stop-color='#598FA6' />",
					"</linearGradient>",
					"<linearGradient id='SITE_TYPE_1' gradientTransform='rotate(45)' xmlns='http://www.w3.org/2000/svg'>",
					"<stop offset='0%' stop-color='#565656' />",
					"<stop offset='100%' stop-color='#000000' />",
					"</linearGradient>",
					"<linearGradient id='SITE_TYPE_6' gradientTransform='rotate(45)' xmlns='http://www.w3.org/2000/svg'>",
					"<stop offset='0%' stop-color='#FFFFFF' />",
					"<stop offset='54.46%' stop-color='#FFD600' />",
					"<stop offset='100%' stop-color='#FF9900' />",
					"</linearGradient>",
					"<linearGradient id='BOARD_BOTTOM_BORDER_COLOR_TIER_5' xmlns='http://www.w3.org/2000/svg'>",
					"<stop stop-color='#BE13AE'/>",
					"</linearGradient>",
					"<linearGradient id='BOARD_BOTTOM_BORDER_COLOR_TIER_4' xmlns='http://www.w3.org/2000/svg'>",
					"<stop stop-color='#1F7460'/>",
					"</linearGradient>",
					"<linearGradient id='BOARD_BOTTOM_BORDER_COLOR_TIER_3' xmlns='http://www.w3.org/2000/svg'>",
					"<stop stop-color='#6124AE'/>",
					"</linearGradient>",
					"<linearGradient id='BOARD_BOTTOM_BORDER_COLOR_TIER_2' xmlns='http://www.w3.org/2000/svg'>",
					"<stop stop-color='#5350AA'/>",
					"</linearGradient>",
					"<linearGradient id='BOARD_BOTTOM_BORDER_COLOR_TIER_1' xmlns='http://www.w3.org/2000/svg'>",
					"<stop stop-color='#2C2B67'/>",
					"</linearGradient>",
					"<linearGradient id='GRADIENT_BOARD_TIER_5' x1='280' y1='0' x2='280' y2='280' gradientUnits='userSpaceOnUse' xmlns='http://www.w3.org/2000/svg'>",
					"<stop offset='0.130208' stop-color='#EFD700'/>",
					"<stop offset='0.6875' stop-color='#FF57EE'/>",
					"<stop offset='1' stop-color='#9A24EC'/>",
					"</linearGradient>",
					"<linearGradient id='GRADIENT_BOARD_TIER_4' x1='143.59' y1='279.506' x2='143.59' y2='2.74439e-06' gradientUnits='userSpaceOnUse' xmlns='http://www.w3.org/2000/svg'>",
					"<stop stop-color='#239378'/>",
					"<stop offset='1' stop-color='#41E23E'/>",
					"</linearGradient>",
					"<linearGradient id='GRADIENT_BOARD_TIER_3' x1='143.59' y1='279.506' x2='143.59' y2='2.74439e-06' gradientUnits='userSpaceOnUse' xmlns='http://www.w3.org/2000/svg'>",
					"<stop stop-color='#812DED'/>",
					"<stop offset='1' stop-color='#F100D9'/>",
					"</linearGradient>",
					"<linearGradient id='GRADIENT_BOARD_TIER_2' x1='143.59' y1='1.02541e-05' x2='143.59' y2='280' gradientUnits='userSpaceOnUse' xmlns='http://www.w3.org/2000/svg'>",
					"<stop stop-color='#7DD6F2'/>",
					"<stop offset='1' stop-color='#625EDC'/>",
					"</linearGradient>",
					"<linearGradient id='GRADIENT_BOARD_TIER_1' x1='143.59' y1='1.02541e-05' x2='143.59' y2='280' gradientUnits='userSpaceOnUse' xmlns='http://www.w3.org/2000/svg'>",
					"<stop stop-color='#4C44A0'/>",
					"<stop offset='1' stop-color='#2F2C83'/>",
					"</linearGradient>",
					"<linearGradient id='ROUNDED_BORDER_TIER_5' x1='280' y1='50' x2='280' y2='280' gradientUnits='userSpaceOnUse' xmlns='http://www.w3.org/2000/svg'>",
					"<stop stop-color='#D2FFD9'/>",
					"<stop offset='1' stop-color='#F32BE1'/>",
					"</linearGradient>",
					"<linearGradient id='ROUNDED_BORDER_TIER_4' x1='280' y1='50' x2='280' y2='280' gradientUnits='userSpaceOnUse' xmlns='http://www.w3.org/2000/svg'>",
					"<stop stop-color='#fff' stop-opacity='0.38'/>",
					"<stop offset='1' stop-color='#fff' stop-opacity='0.08'/>",
					"</linearGradient>",
					"<linearGradient id='ROUNDED_BORDER_TIER_3' x1='280' y1='50' x2='280' y2='280' gradientUnits='userSpaceOnUse' xmlns='http://www.w3.org/2000/svg'>",
					"<stop stop-color='#fff' stop-opacity='0.38'/>",
					"<stop offset='1' stop-color='#fff' stop-opacity='0.08'/>",
					"</linearGradient>",
					"<linearGradient id='ROUNDED_BORDER_TIER_2' x1='280' y1='50' x2='280' y2='280' gradientUnits='userSpaceOnUse' xmlns='http://www.w3.org/2000/svg'>",
					"<stop stop-color='#fff' stop-opacity='0.38'/>",
					"<stop offset='1' stop-color='#fff' stop-opacity='0.08'/>",
					"</linearGradient>",
					"<linearGradient id='ROUNDED_BORDER_TIER_1' x1='280' y1='50' x2='280' y2='280' gradientUnits='userSpaceOnUse' xmlns='http://www.w3.org/2000/svg'>",
					"<stop stop-color='#fff' stop-opacity='0.38'/>",
					"<stop offset='1' stop-color='#fff' stop-opacity='0.08'/>",
					"</linearGradient>",
					"<pattern id='smallGrid' width='3' height='3' patternUnits='userSpaceOnUse' patternTransform='translate(-1.5 3.6) rotate(45) scale(1.28)'>",
					"<path d='M 3 0 L 0 0 0 3' fill='none'  stroke='#130A2A' stroke-opacity='0.2'/>",
					"</pattern>",
					"</defs>",
					"<g fill='none' stroke-width='0'>",
					"<rect width='280' height='280' fill='url(#GRADIENT_BOARD_TIER_",
					"LAND_TIER_ID", // This line should be replaced in the loop
					")' stroke='none' rx='8' ry='8'/>",
					"</g>",
					"<rect x='1' y='1' width='278' height='277.5' fill='url(#smallGrid)' stroke='none' rx='8' ry='8'/>    ",
					"<g transform='translate(0 -84.8) rotate(45 140 140) scale(1.37)'>",
					"<svg viewBox='0 0.5 307 306' width='287' height='286'>",
					"SITES_POSITIONED", // This line should be replaced in the loop
					"</svg>",
					"</g>",
					"<rect x='0.5' y='0.4' width='279' height='278.5'  stroke='url(#ROUNDED_BORDER_TIER_",
					"LAND_TIER_ID", // This line should be replaced in the loop
					")' stroke-width='1'  rx='7' ry='7' xmlns='http://www.w3.org/2000/svg'/>",
					"</svg>"
				];

}
 /**
  * @dev Calculates string for the land name based on plot data.
	* 
	* @param _regionId PlotView.regionId
	* @param _x PlotView.x coordinate
	* @param _y PlotView.y coordinate
	* @param _tierId PlotView.tierId land tier id
  */

	function _generateLandName(uint8 _regionId,  uint16 _x,  uint16 _y, uint8 _tierId) private pure returns (string memory) {
		return string(
			abi.encodePacked(
				"Land Tier ",
				uint256(_tierId).toString(),
				" - (",
				uint256(_regionId).toString(),
				", ",
				uint256(_x).toString(),
				", ",
				uint256(_y).toString()
			)
		);
	}
 
  /**
	 * @dev Calculates the string for the land metadata description.
	 */
	function _generateLandDescription() private pure returns (string memory) {
		return "Describes the asset to which this NFT represents";
	}
	/**
	 * @dev Populates the mainSvg array with the land tier id and the svg returned
	 *      by the _generateLandBoard. Expects it to generate the land svg inside 
	 *      the container.
	 * 
	 * @param _tierId PlotView.tierId land tier id
	 * @param _sites Array of plot sites coming from PlotView struct
	 */
	function _generateSVG(uint8 _tierId, SiteSVGData[] memory _sites) private pure returns (string memory) {
			string[] memory _mainSvgArray = new string[](_mainSvg().length);

			for(uint256 i = 0; i < _mainSvg().length; i++) {
					if (keccak256(bytes(_mainSvg()[i])) == keccak256(bytes("LAND_TIER_ID"))) {
							_mainSvgArray[i] = uint256(_tierId).toString();
							continue;
					}
					if(keccak256(bytes(_mainSvg()[i])) == keccak256(bytes("FUTURE_BOARD_CONTAINER"))) {
							_mainSvgArray[i] = _generateLandBoard(_tierId, _sites);
							continue;
					}
					_mainSvgArray[i] = _mainSvg()[i];
			}
			return _joinArray(_mainSvgArray);
	}

	/**
	 * @dev Generates the plot svg containing all sites inside and color according
	 *      to the tier
	 * 
	 * @param _tierId PlotView.tierId land tier id
	 * @param _sites Array of plot sites coming from PlotView struct
	 */
	function _generateLandBoard(uint8 _tierId, SiteSVGData[] memory _sites) private pure returns (string memory) {
			string[] memory _boardSvgArray = new string[](_boardSvg().length);

			for (uint256 i = 0; i < _boardSvg().length; i++) {
				if (keccak256(bytes(_boardSvg()[i])) == keccak256(bytes("LAND_TIER_ID"))) {
						_boardSvgArray[i] = uint256(_tierId).toString();
						continue;
				}
				if (keccak256(bytes(_boardSvg()[i])) == keccak256(bytes("SITES_POSITIONED"))) {
						_boardSvgArray[i] = _generateSites(_sites);
						continue;
				}
				_boardSvgArray[i] = _boardSvg()[i];
  		}
  		return _joinArray(_boardSvgArray);
	}
 
 /**
  * @dev Generates each site inside the land svg board with is position and color.
	*
	* @param _sites Array of plot sites coming from PlotView struct
  */
	function _generateSites(SiteSVGData[] memory _sites) private pure returns (string memory) {
			string[] memory _siteSvgArray = new string[](_sites.length);
			for (uint256 i = 0; i < _sites.length; i++) {
						_siteSvgArray[i] = _generatePositionAndColor(_sites[i]);
			}

			return _joinArray(_siteSvgArray);
	}
 
 /**
  * @dev Called inside `_generateSites()`, expects to receive each site and 
	*      return the individual svg with the correct position inside the board and
	*      color.
  */
	function _generatePositionAndColor(SiteSVGData memory _site) private pure returns (string memory) {
			string[] memory _siteSvgArray = new string[](_siteBaseSvg().length);

		  for (uint256 i = 0; i < _siteBaseSvg().length; i++) {
					if (keccak256(bytes(_siteBaseSvg()[i])) == keccak256(bytes("SITE_TYPE_ID"))) {
						_siteSvgArray[i] = uint256(_site.typeId).toString();
						continue;
					}
					if (keccak256(bytes(_siteBaseSvg()[i])) == keccak256(bytes("SITE_X_POSITION"))) {
						_siteSvgArray[i] = _convertToSvgPosition(_site.x);
						continue;
					}
					if (keccak256(bytes(_siteBaseSvg()[i])) == keccak256(bytes("SITE_Y_POSITION"))) {
						_siteSvgArray[i] = _convertToSvgPosition(_site.y);
						continue;
					}
					_siteSvgArray[i] = _siteBaseSvg()[i];
		}
		return _joinArray(_siteSvgArray);
	}
  /**
	 * @dev Main function, entry point to generate the complete land svg with all
	 *      populated sites, correct color, and attach to the JSON metadata file
	 *      created using Base64 lib.
	 * @dev Returns the JSON metadata formatted file used by NFT platforms to display
	 *      the land data.
	 * @dev Can be updated in the future to change the way land name, description, image
	 *      and other traits are displayed.
	 *
	 * @param _regionId PlotView.regionId
	 * @param _x PlotView.x coordinate
	 * @param _y PlotView.y coordinate
	 * @param _tierId PlotView.tierId land tier id
	 * @param _sites Array of plot sites coming from PlotView struct
	 */
	function constructTokenURI(uint8 _regionId, uint16 _x, uint16 _y, uint8 _tierId, SiteSVGData[] memory _sites) internal pure returns (string memory) {
			string memory name = _generateLandName(_regionId, _x, _y, _tierId);
			string memory description = _generateLandDescription();
			string memory image = Base64.encode(bytes(_generateSVG(_tierId, _sites)));

			return string(
				abi.encodePacked("data:application/json;base64, ", Base64.encode(
					bytes(
								abi.encodePacked('{"name":"',
								name,
								'", "description":"',
								description,
								'", "image": "',
								'data:image/svg+xml;base64,',
								image,
								'"}')
						)	
					)
				));

	}

	function _joinArray(string[] memory _svgArray) private pure returns (string memory) {
		string memory svg;
		for (uint256 i = 0; i < _svgArray.length; i++) {
				if (i != 0) {
					svg = string(abi.encodePacked(svg, _svgArray[i]));
				} else {
					svg = _svgArray[i];
				}
		}

		return svg;
	}

	function _convertToSvgPosition(uint256 _position) private pure returns (string memory) {
			return (_position * 3 - 6).toString();
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/**
 * @title Land Library
 *
 * @notice A library defining data structures related to land plots (used in Land ERC721 token),
 *      and functions transforming these structures between view and internal (packed) representations,
 *      in both directions.
 *
 * @notice Due to some limitations Solidity has (ex.: allocating array of structures in storage),
 *      and due to the specific nature of internal land structure
 *      (landmark and resource sites data is deterministically derived from a pseudo random seed),
 *      it is convenient to separate data structures used to store metadata on-chain (store),
 *      and data structures used to present metadata via smart contract ABI (view)
 *
 * @notice Introduces helper functions to detect and deal with the resource site collisions
 *
 * @author Basil Gorin
 */
library LandLib {
	/**
	 * @title Resource Site View
	 *
	 * @notice Resource Site, bound to a coordinates (x, y) within the land plot
	 *
	 * @notice Resources can be of two major types, each type having three subtypes:
	 *      - Element (Carbon, Silicon, Hydrogen), or
	 *      - Fuel (Crypton, Hyperion, Solon)
	 *
	 * @dev View only structure, used in public API/ABI, not used in on-chain storage
	 */
	struct Site {
		/**
		 * @dev Site type:
		 *        1) Carbon (element),
		 *        2) Silicon (element),
		 *        3) Hydrogen (element),
		 *        4) Crypton (fuel),
		 *        5) Hyperion (fuel),
		 *        6) Solon (fuel)
		 */
		uint8 typeId;

		/**
		 * @dev x-coordinate within a plot
		 */
		uint16 x;

		/**
		 * @dev y-coordinate within a plot
		 */
		uint16 y;
	}

	/**
	 * @title Land Plot View
	 *
	 * @notice Land Plot, bound to a coordinates (x, y) within the region,
	 *      with a rarity defined by the tier ID, sites, and (optionally)
	 *      a landmark, positioned on the internal coordinate grid of the
	 *      specified size within a plot.
	 *
	 * @notice Land plot coordinates and rarity are predefined (stored off-chain).
	 *      Number of sites (and landmarks - 0/1) is defined by the land rarity.
	 *      Positions of sites, types of sites/landmark are randomized and determined
	 *      upon land plot creation.
	 *
	 * @dev View only structure, used in public API/ABI, not used in on-chain storage
	 */
	struct PlotView {
		/**
		 * @dev Region ID defines the region on the map in IZ:
		 *        1) Abyssal Basin
		 *        2) Brightland Steppes
		 *        3) Shardbluff Labyrinth
		 *        4) Crimson Waste
		 *        5) Halcyon Sea
		 *        6) Taiga Boreal
		 *        7) Crystal Shores
		 */
		uint8 regionId;

		/**
		 * @dev x-coordinate within the region
		 */
		uint16 x;

		/**
		 * @dev y-coordinate within the region
		 */
		uint16 y;

		/**
		 * @dev Tier ID defines land rarity and number of sites within the plot
		 */
		uint8 tierId;

		/**
		 * @dev Plot size, limits the (x, y) coordinates for the sites
		 */
		uint16 size;

		/**
		 * @dev Landmark Type ID:
		 *        0) no Landmark
		 *        1) Carbon Landmark,
		 *        2) Silicon Landmark,
		 *        3) Hydrogen Landmark (Eternal Spring),
		 *        4) Crypton Landmark,
		 *        5) Hyperion Landmark,
		 *        6) Solon Landmark (Fallen Star),
		 *        7) Arena
		 *
		 * @dev Landmark is always positioned in the center of internal grid
		 */
		uint8 landmarkTypeId;

		/**
		 * @dev Number of Element Sites (Carbon, Silicon, or Hydrogen) this plot contains,
		 *      matches the number of element sites in sites[] array
		 */
		uint8 elementSites;

		/**
		 * @dev Number of Fuel Sites (Crypton, Hyperion, or Solon) this plot contains,
		 *      matches the number of fuel sites in sites[] array
		 */
		uint8 fuelSites;

		/**
		 * @dev Element/fuel sites within the plot
		 */
		Site[] sites;
	}

	/**
	 * @title Land Plot Store
	 *
	 * @notice Land Plot data structure as it is stored on-chain
	 *
	 * @notice Contains the data required to generate `PlotView` structure:
	 *      - regionId, x, y, tierId, size, landmarkTypeId, elementSites, and fuelSites are copied as is
	 *      - version and seed are used to derive array of sites (together with elementSites, and fuelSites)
	 *
	 * @dev On-chain optimized structure, has limited usage in public API/ABI
	 */
	struct PlotStore {
		/**
		 * @dev Region ID defines the region on the map in IZ:
		 *        1) Abyssal Basin
		 *        2) Brightland Steppes
		 *        3) Shardbluff Labyrinth
		 *        4) Crimson Waste
		 *        5) Halcyon Sea
		 *        6) Taiga Boreal
		 *        7) Crystal Shores
		 */
		uint8 regionId;

		/**
		 * @dev x-coordinate within the region
		 */
		uint16 x;

		/**
		 * @dev y-coordinate within the region
		 */
		uint16 y;

		/**
		 * @dev Tier ID defines land rarity and number of sites within the plot
		 */
		uint8 tierId;

		/**
		 * @dev Plot Size, limits the (x, y) coordinates for the sites
		 */
		uint16 size;

		/**
		 * @dev Landmark Type ID:
		 *        0) no Landmark
		 *        1) Carbon Landmark,
		 *        2) Silicon Landmark,
		 *        3) Hydrogen Landmark (Eternal Spring),
		 *        4) Crypton Landmark,
		 *        5) Hyperion Landmark,
		 *        6) Solon Landmark (Fallen Star),
		 *        7) Arena
		 *
		 * @dev Landmark is always positioned in the center of internal grid
		 */
		uint8 landmarkTypeId;

		/**
		 * @dev Number of Element Sites (Carbon, Silicon, or Hydrogen) this plot contains
		 */
		uint8 elementSites;

		/**
		 * @dev Number of Fuel Sites (Crypton, Hyperion, or Solon) this plot contains
		 */
		uint8 fuelSites;

		/**
		 * @dev Generator Version, reserved for the future use in order to tweak the
		 *      behavior of the internal land structure algorithm
		 */
		uint8 version;

		/**
		 * @dev Pseudo-random Seed to generate Internal Land Structure,
		 *      should be treated as already used to derive Landmark Type ID
		 */
		uint160 seed;
	}


	/**
	 * @dev Expands `PlotStore` data struct into a `PlotView` view struct
	 *
	 * @dev Derives internal land structure (resource sites the plot has)
	 *      from Number of Element/Fuel Sites, Plot Size, and Seed;
	 *      Generator Version is not currently used
	 *
	 * @param store on-chain `PlotStore` data structure to expand
	 * @return `PlotView` view struct, expanded from the on-chain data
	 */
	function plotView(PlotStore memory store) internal pure returns(PlotView memory) {
		// copy most of the fields as is, derive resource sites array inline
		return PlotView({
			regionId:       store.regionId,
			x:              store.x,
			y:              store.y,
			tierId:         store.tierId,
			size:           store.size,
			landmarkTypeId: store.landmarkTypeId,
			elementSites:   store.elementSites,
			fuelSites:      store.fuelSites,
			// derive the resource sites from Number of Element/Fuel Sites, Plot Size, and Seed
			sites:          getResourceSites(store.seed, store.elementSites, store.fuelSites, store.size, 2)
		});
	}

	/**
	 * @dev Based on the random seed, tier ID, and plot size, determines the
	 *      internal land structure (resource sites the plot has)
	 *
	 * @dev Function works in a deterministic way and derives the same data
	 *      for the same inputs; the term "random" in comments means "pseudo-random"
	 *
	 * @param seed random seed to consume and derive the internal structure
	 * @param elementSites number of element sites plot has
	 * @param fuelSites number of fuel sites plot has
	 * @param gridSize plot size `N` of the land plot to derive internal structure for
	 * @param siteSize implied size `n` of the resource sites
	 * @return sites randomized array of resource sites
	 */
	function getResourceSites(
		uint256 seed,
		uint8 elementSites,
		uint8 fuelSites,
		uint16 gridSize,
		uint8 siteSize
	) internal pure returns(Site[] memory sites) {
		// derive the total number of sites
		uint8 totalSites = elementSites + fuelSites;

		// denote the grid (plot) size `N`
		// denote the resource site size `n`

		// transform coordinate system (1): normalization (x, y) => (x / n, y / n)
		// if `N` is odd this cuts off border coordinates x = N - 1, y = N - 1
		uint16 normalizedSize = gridSize / siteSize;

		// after normalization (1) is applied, isomorphic grid becomes effectively larger
		// due to borders capturing effect, for example if N = 4, and n = 2:
		//      | .. |                                              |....|
		// grid |....| becomes |..| normalized which is effectively |....|
		//      |....|         |..|                                 |....|
		//      | .. |                                              |....|
		// transform coordinate system (2): cut the borders, and reduce grid size to be multiple of 2
		// if `N/2` is odd this cuts off border coordinates x = N/2 - 1, y = N/2 - 1
		normalizedSize = (normalizedSize - 2) / 2 * 2;

		// define coordinate system: isomorphic grid on a square of size [size, size]
		// transform coordinate system (3): pack isomorphic grid on a rectangle of size [size, 1 + size / 2]
		// transform coordinate system (4): (x, y) -> y * size + x (two-dimensional Cartesian -> one-dimensional segment)
		// generate site coordinates in a transformed coordinate system (on a one-dimensional segment)
		uint16[] memory coords; // define temporary array to determine sites' coordinates
		// cut off four elements in the end of the segment to reserve space in the center for a landmark
		(seed, coords) = getCoords(seed, totalSites, normalizedSize * (1 + normalizedSize / 2) - 4);

		// allocate number of sites required
		sites = new Site[](totalSites);

		// define the variables used inside the loop outside the loop to help compiler optimizations
		// site type ID
		uint8 typeId;
		// site coordinates (x, y)
		uint16 x;
		uint16 y;

		// determine the element and fuel sites one by one
		for(uint8 i = 0; i < totalSites; i++) {
			// determine next random number in the sequence, and random site type from it
			(seed, typeId) = nextRndUint8(seed, i < elementSites? 1: 4, 3);

			// determine x and y
			// reverse transform coordinate system (4): x = size % i, y = size / i
			// (back from one-dimensional segment to two-dimensional Cartesian)
			x = coords[i] % normalizedSize;
			y = coords[i] / normalizedSize;

			// reverse transform coordinate system (3): unpack isomorphic grid onto a square of size [size, size]
			// fix the "(0, 0) left-bottom corner" of the isomorphic grid
			if(2 * (1 + x + y) < normalizedSize) {
				x += normalizedSize / 2;
				y += 1 + normalizedSize / 2;
			}
			// fix the "(size, 0) right-bottom corner" of the isomorphic grid
			else if(2 * x > normalizedSize && 2 * x > 2 * y + normalizedSize) {
				x -= normalizedSize / 2;
				y += 1 + normalizedSize / 2;
			}

			// move the site from the center (four positions near the center) to a free spot
			if(x >= normalizedSize / 2 - 1 && x <= normalizedSize / 2 && y >= normalizedSize / 2 - 1 && y <= normalizedSize / 2) {
				// `x` is aligned over the free space in the end of the segment
				// x += normalizedSize / 2 + 2 * (normalizedSize / 2 - x) + 2 * (normalizedSize / 2 - y) - 4;
				x += 5 * normalizedSize / 2 - 2 * (x + y) - 4;
				// `y` is fixed over the free space in the end of the segment
				y = normalizedSize / 2;
			}

			// if `N/2` is odd recover previously cut off border coordinates x = N/2 - 1, y = N/2 - 1
			// if `N` is odd this recover previously cut off border coordinates x = N - 1, y = N - 1
			uint16 offset = gridSize / siteSize % 2 + gridSize % siteSize;

			// based on the determined site type and coordinates, allocate the site
			sites[i] = Site({
			typeId: typeId,
				// reverse transform coordinate system (2): recover borders (x, y) => (x + 1, y + 1)
				// if `N/2` is odd recover previously cut off border coordinates x = N/2 - 1, y = N/2 - 1
				// reverse transform coordinate system (1): (x, y) => (n * x, n * y), where n is site size
				// if `N` is odd this recover previously cut off border coordinates x = N - 1, y = N - 1
				x: (1 + x) * siteSize + offset,
				y: (1 + y) * siteSize + offset
			});
		}
	}

	/**
	 * @dev Based on the random seed and tier ID determines the landmark type of the plot.
	 *      Random seed is consumed for tiers 3 and 4 to randomly determine one of three
	 *      possible landmark types.
	 *      Tier 5 has its landmark type predefined (arena), lower tiers don't have a landmark.
	 *
	 * @dev Function works in a deterministic way and derives the same data
	 *      for the same inputs; the term "random" in comments means "pseudo-random"
	 *
	 * @param seed random seed to consume and derive the landmark type based on
	 * @param tierId tier ID of the land plot
	 * @return landmarkTypeId landmark type defined by its ID
	 */
	function getLandmark(uint256 seed, uint8 tierId) internal pure returns(uint8 landmarkTypeId) {
		// depending on the tier, land plot can have a landmark
		// tier 3 has an element landmark (1, 2, 3)
		if(tierId == 3) {
			// derive random element landmark
			return uint8(1 + seed % 3);
		}
		// tier 4 has a fuel landmark (4, 5, 6)
		if(tierId == 4) {
			// derive random fuel landmark
			return uint8(4 + seed % 3);
		}
		// tier 5 has an arena landmark
		if(tierId == 5) {
			// 7 - arena landmark
			return 7;
		}

		// lower tiers (0, 1, 2) don't have any landmark
		// tiers greater than 5 are not defined
		return 0;
	}

	/**
	 * @dev Derives an array of integers with no duplicates from the random seed;
	 *      each element in the array is within [0, size) bounds and represents
	 *      a two-dimensional Cartesian coordinate point (x, y) presented as one-dimensional
	 *
	 * @dev Function works in a deterministic way and derives the same data
	 *      for the same inputs; the term "random" in comments means "pseudo-random"
	 *
	 * @dev The input seed is considered to be already used to derive some random value
	 *      from it, therefore the function derives a new one by hashing the previous one
	 *      before generating the random value; the output seed is "used" - output random
	 *      value is derived from it
	 *
	 * @param seed random seed to consume and derive coordinates from
	 * @param length number of elements to generate
	 * @param size defines array element bounds [0, size)
	 * @return nextSeed next pseudo-random "used" seed
	 * @return coords the resulting array of length `n` with random non-repeating elements
	 *      in [0, size) range
	 */
	function getCoords(
		uint256 seed,
		uint8 length,
		uint16 size
	) internal pure returns(uint256 nextSeed, uint16[] memory coords) {
		// allocate temporary array to store (and determine) sites' coordinates
		coords = new uint16[](length);

		// generate site coordinates one by one
		for(uint8 i = 0; i < coords.length; i++) {
			// get next number and update the seed
			(seed, coords[i]) = nextRndUint16(seed, 0, size);
		}

		// sort the coordinates
		sort(coords);

		// find the if there are any duplicates, and while there are any
		for(int256 i = findDup(coords); i >= 0; i = findDup(coords)) {
			// regenerate the element at duplicate position found
			(seed, coords[uint256(i)]) = nextRndUint16(seed, 0, size);
			// sort the coordinates again
			// TODO: check if this doesn't degrade the performance significantly (note the pivot in quick sort)
			sort(coords);
		}

		// return the updated and used seed
		return (seed, coords);
	}

	/**
	 * @dev Based on the random seed, generates next random seed, and a random value
	 *      not lower than given `offset` value and able to have `options` different
	 *      and equiprobable values, that is in the [offset, offset + options) range
	 *
	 * @dev The input seed is considered to be already used to derive some random value
	 *      from it, therefore the function derives a new one by hashing the previous one
	 *      before generating the random value; the output seed is "used" - output random
	 *      value is derived from it
	 *
	 * @param seed random seed to consume and derive next random value from
	 * @param offset the minimum possible output
	 * @param options number of different possible values to output
	 * @return nextSeed next pseudo-random "used" seed
	 * @return rndVal random value in the [offset, offset + options) range
	 */
	function nextRndUint8(
		uint256 seed,
		uint8 offset,
		uint8 options
	) internal pure returns(
		uint256 nextSeed,
		uint8 rndVal
	) {
		// generate next random seed first
		nextSeed = uint256(keccak256(abi.encodePacked(seed)));

		// derive random value with the desired properties from
		// the newly generated seed
		rndVal = offset + uint8(nextSeed % options);
	}

	/**
	 * @dev Based on the random seed, generates next random seed, and a random value
	 *      not lower than given `offset` value and able to have `options` different
	 *      possible values
	 *
	 * @dev The input seed is considered to be already used to derive some random value
	 *      from it, therefore the function derives a new one by hashing the previous one
	 *      before generating the random value; the output seed is "used" - output random
	 *      value is derived from it
	 *
	 * @param seed random seed to consume and derive next random value from
	 * @param offset the minimum possible output
	 * @param options number of different possible values to output
	 * @return nextSeed next pseudo-random "used" seed
	 * @return rndVal random value in the [offset, offset + options) range
	 */
	function nextRndUint16(
		uint256 seed,
		uint16 offset,
		uint16 options
	) internal pure returns(
		uint256 nextSeed,
		uint16 rndVal
	) {
		// generate next random seed first
		nextSeed = uint256(keccak256(abi.encodePacked(seed)));

		// derive random value with the desired properties from
		// the newly generated seed
		rndVal = offset + uint16(nextSeed % options);
	}

	/**
	 * @dev Plot location is a combination of (regionId, x, y), it's effectively
	 *      a 3-dimensional coordinate, unique for each plot
	 *
	 * @dev The function extracts plot location from the plot and represents it
	 *      in a packed form of 3 integers constituting the location: regionId | x | y
	 *
	 * @param plot `PlotView` view structure to extract location from
	 * @return Plot location (regionId, x, y) as a packed integer
	 */
/*
	function loc(PlotView memory plot) internal pure returns(uint40) {
		// tightly pack the location data and return
		return uint40(plot.regionId) << 32 | uint32(plot.y) << 16 | plot.x;
	}
*/

	/**
	 * @dev Plot location is a combination of (regionId, x, y), it's effectively
	 *      a 3-dimensional coordinate, unique for each plot
	 *
	 * @dev The function extracts plot location from the plot and represents it
	 *      in a packed form of 3 integers constituting the location: regionId | x | y
	 *
	 * @param plot `PlotStore` data store structure to extract location from
	 * @return Plot location (regionId, x, y) as a packed integer
	 */
	function loc(PlotStore memory plot) internal pure returns(uint40) {
		// tightly pack the location data and return
		return uint40(plot.regionId) << 32 | uint32(plot.y) << 16 | plot.x;
	}

	/**
	 * @dev Site location is a combination of (x, y), unique for each site within a plot
	 *
	 * @dev The function extracts site location from the site and represents it
	 *      in a packed form of 2 integers constituting the location: x | y
	 *
	 * @param site `Site` view structure to extract location from
	 * @return Site location (x, y) as a packed integer
	 */
/*
	function loc(Site memory site) internal pure returns(uint32) {
		// tightly pack the location data and return
		return uint32(site.y) << 16 | site.x;
	}
*/

	/**
	 * @dev Finds first pair of repeating elements in the array
	 *
	 * @dev Assumes the array is sorted ascending:
	 *      returns `-1` if array is strictly monotonically increasing,
	 *      index of the first duplicate found otherwise
	 *
	 * @param arr an array of elements to check
	 * @return index found duplicate index, or `-1` if there are no repeating elements
	 */
	function findDup(uint16[] memory arr) internal pure returns (int256 index) {
		// iterate over the array [1, n], leaving the space in the beginning for pair comparison
		for(uint256 i = 1; i < arr.length; i++) {
			// verify if there is a strict monotonically increase violation
			if(arr[i - 1] >= arr[i]) {
				// return false if yes
				return int256(i - 1);
			}
		}

		// return `-1` if no violation was found - array is strictly monotonically increasing
		return -1;
	}

	/**
	 * @dev Sorts an array of integers using quick sort algorithm
	 *
	 * @dev Quick sort recursive implementation
	 *      Source:   https://gist.github.com/subhodi/b3b86cc13ad2636420963e692a4d896f
	 *      See also: https://www.geeksforgeeks.org/quick-sort/
	 *
	 * @param arr an array to sort
	 */
	function sort(uint16[] memory arr) internal pure {
		quickSort(arr, 0, int256(arr.length) - 1);
	}

	/**
	 * @dev Quick sort recursive implementation
	 *      Source:     https://gist.github.com/subhodi/b3b86cc13ad2636420963e692a4d896f
	 *      Discussion: https://blog.cotten.io/thinking-in-solidity-6670c06390a9
	 *      See also:   https://www.geeksforgeeks.org/quick-sort/
	 */
	// TODO: review the implementation code
	function quickSort(uint16[] memory arr, int256 left, int256 right) internal pure {
		int256 i = left;
		int256 j = right;
		if(i >= j) {
			return;
		}
		uint16 pivot = arr[uint256(left + (right - left) / 2)];
		while(i <= j) {
			while(arr[uint256(i)] < pivot) {
				i++;
			}
			while(pivot < arr[uint256(j)]) {
				j--;
			}
			if(i <= j) {
				(arr[uint256(i)], arr[uint256(j)]) = (arr[uint256(j)], arr[uint256(i)]);
				i++;
				j--;
			}
		}
		if(left < j) {
			quickSort(arr, left, j);
		}
		if(i < right) {
			quickSort(arr, i, right);
		}
	}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
/// @notice Copied from https://github.com/Brechtpd/base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}