// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../interfaces/LandERC721Spec.sol";
import "../lib/NFTSvg.sol";

/**
 * @title Land Descriptor Implementation
 *
 * @notice Basic implementation of the LandDescriptor interface
 *
 * @author Pedro Bergamini, Basil Gorin
 */
contract LandDescriptorImpl is LandDescriptor {
	/**
	 * @inheritdoc LandDescriptor
	 */
	function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
		// assuming the function was called by the LandERC721 contract itself,
		// fetch the token metadata from it
		LandLib.PlotView memory _plot = LandERC721Metadata(msg.sender).viewMetadata(_tokenId);

		// unpack the `_plot` structure and delegate generation into the lib
		return NFTSvg.constructTokenURI(
			_plot.regionId,
			_plot.x,
			_plot.y,
			_plot.tierId,
			_plot.size,
			_plot.landmarkTypeId,
			_plot.sites
		);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

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
	function viewMetadata(uint256 _tokenId) external view returns (LandLib.PlotView memory);

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
	function getMetadata(uint256 _tokenId) external view returns (LandLib.PlotStore memory);

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
	function hasMetadata(uint256 _tokenId) external view returns (bool);

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

/**
 * @title Land Descriptor
 *
 * @notice Auxiliary module which is dynamically injected into LandERC721 contract
 *      to override the default ERC721.tokenURI behaviour
 *
 * @notice This can be used, for example, to enable on-chain generation of the SVG
 *      image representation of the land plot, encoding it into base64 string, and
 *      using it instead of token URI pointing to some off-chain sotrage location
 *
 * @dev Can be dynamically injected into LandERC721 at any time, can be dynamically detached
 *      from the LandERC721 once attached (injected)
 *
 * @author Pedro Bergamini, Basil Gorin
 */
interface LandDescriptor {
	/**
	 * @notice Creates SVG image with the land plot metadata painted on it,
	 *      encodes the generated SVG into base64 URI string
	 *
	 * @param _tokenId token ID of the land plot to generate SVG for
	 */
	function tokenURI(uint256 _tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./LandLib.sol";
import "base64-sol/base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "prb-math/contracts/PRBMathUD60x18.sol";

/**
 * @title NFT Svg
 *
 * @notice Provide functions to generate SVG image representation of the LandERC721, and other
 *      auxiliary functions to construct token metadata JSON, and encode it into base64 format.
 *
 * @notice base64 is the OpenSea standard for NFT SVG images. The SVG JSON generated by the
 *      `constructTokenURI` is meant to be used in the marketplace.
 *
 * @notice `_mainSvg(uint16,uint8)` function holds the main structure with the dimensions for
 *      the image, the retuning array contains flags that are to be replaced by another SVG component,
 *      FUTURE_BOARD_CONTAINER.
 *
 * @notice `_siteBaseSvg(uint16,uint16,uint8)` will generate a site's component string,
 *      given it's coordinates and typeId.
 *
 * @notice `_boardSvg(uint16,uint8)` returns the template for the board component, depending on the
 *      size of the grid and tier ID, LANDMARK and SITES_POSITIONED will need to be replaced in a loop.
 * @notice `_generateLandmarkSvg(uint16,uint8)` will generate the landmark SVG string given grid size
 *      and landmark type ID.
 *
 * @notice Replacement schema:
 *      - LANDMARK -> `_generateLandmarkSvg(uint16,uint8)`
 *      - SITES_POSITIONED -> `_generateSites(LandLib.Site[] memory)`
 *      - FUTURE_BOARD_CONTAINER -> _generateLandBoard(uint8,uint16,uint8,LandLib.Site[] memory)`
 *
 * @notice Loop flag replacement is chosen instead of using function parameters when the replacement
 *      involves a complex component with considerable string length.
 *
 * @notice The coordinates for the SVG are transformed in a way that there'll be `gridSize/2` grid squares
 *      in the isomorphic grid, given that a square has a size of 3.
 *
 * @author Pedro Bergamini, Yuri Fernandes, Estevan Wisoczynski
 */
library NFTSvg {
	using Strings for uint256;
	using PRBMathUD60x18 for uint256;

	/**
	 * @dev Returns the main svg array component, used in the top level of the generated land SVG.
	 *
	 * @param _gridSize The size of the grid
	 * @param _tierId PlotView.tierId land tier id
	 * @return The base for the land SVG, need to substitute LAND_TIER_ID and FUTURE_BOARD_CONTAINER
	 */
	function _mainSvg(uint16 _gridSize, uint8 _tierId) private pure returns (string[11] memory) {
		// Multiply by 3 to get number of grid squares = dimension of the isomorphic grid size

		return [
			"<svg height='",
			uint256(_gridSize * 3 + 6).toString(),
			"' width='",
			uint256(_gridSize * 3).toString(),
			"' stroke-width='2' xmlns='http://www.w3.org/2000/svg'>",
			"<rect rx='5%' ry='5%' width='100%' height='99%' fill='url(#BOARD_BOTTOM_BORDER_COLOR_TIER_",
			uint256(_tierId).toString(),
			")' stroke='none'/>",
			"<svg height='97.6%' width='100%' stroke-width='2' xmlns='http://www.w3.org/2000/svg'>",
			"FUTURE_BOARD_CONTAINER", // This line should be replaced in the loop
			"</svg>"
		];
	}

	/**
	 * @dev Returns the site base svg array component, used to represent
	 *      a site inside the land board.
	 *
	 * @param _x Sites.x position
	 * @param _y Sites.y position
	 * @param _typeId Sites.typeId
	 * @return The base SVG element for the sites
	 */
	function _siteBaseSvg(uint16 _x, uint16 _y, uint8 _typeId) private pure returns (string memory) {
		string[] memory siteBaseSvgArray = new string[](7);
		siteBaseSvgArray[0] = "<svg x='";
		siteBaseSvgArray[1] = uint256(_x).toString();
		siteBaseSvgArray[2] = "' y='";
		siteBaseSvgArray[3] = uint256(_y).toString();
		siteBaseSvgArray[4] = "' width='6' height='6' xmlns='http://www.w3.org/2000/svg'><use href='#SITE_TYPE_";
		siteBaseSvgArray[5] = uint256(_typeId).toString();
		siteBaseSvgArray[6] = "' /></svg>";

		return _joinArray(siteBaseSvgArray);
	}

	/**
	 * @dev Returns the site base svg array component, used to represent
	 *      a landmark inside the land board.
	 *
	 * @param _gridSize The size of the grid
	 * @param _landmarkTypeId landmark type defined by its ID
	 * @return Concatenation of the landmark SVG component to be added the board SVG
	 */
	function _generateLandmarkSvg(uint16 _gridSize, uint8 _landmarkTypeId) private pure returns (string memory) {
		uint256 landmarkPos = uint256(_gridSize - 2).fromUint().div(uint256(2).fromUint()).mul(uint256(3).fromUint());
		string memory landmarkFloatX;
		string memory landmarkFloatY;
		if (_gridSize % 2 == 0) {
			landmarkFloatX = landmarkPos.toUint().toString();
			landmarkFloatY = (landmarkPos.toUint() - 3).toString();
		} else {
			landmarkFloatX = (landmarkPos.ceil().toUint() + 1).toString();
			landmarkFloatY = (landmarkPos.floor().toUint() - 1).toString();
		}

		string[] memory landmarkSvgArray = new string[](7);
		landmarkSvgArray[0] = "<svg x='";
		landmarkSvgArray[1] = landmarkFloatX;
		landmarkSvgArray[2] = "' y='";
		landmarkSvgArray[3] = landmarkFloatY;
		landmarkSvgArray[4] = "' width='6' height='6' xmlns='http://www.w3.org/2000/svg'><use href='#LANDMARK_TYPE_";
		landmarkSvgArray[5] = uint256(_landmarkTypeId).toString();
		landmarkSvgArray[6] = "'/></svg>";

		return _joinArray(landmarkSvgArray);
	}

	/**
	 * @dev Returns the land board base svg array component, which has its color changed
	 *      later in other functions.
	 *
	 * @param _gridSize The size of the grid
	 * @param _tierId PlotView.tierId land tier id
	 * @return Array of board SVG component parts
	 */
	function _boardSvg(uint16 _gridSize, uint8 _tierId) private pure returns (string[141] memory) {
		uint256 scaledGridSize = uint256(_gridSize).fromUint().div(uint256(2).fromUint()).mul(uint256(3).fromUint());
		string memory scaledGridSizeString = string(
			abi.encodePacked(
				scaledGridSize.toUint().toString(),
				".",
				truncateString(scaledGridSize.frac().toString(), 0, 2)
			)
		);
		return [
		"<defs><symbol id='SITE_TYPE_1' width='6' height='6'>", // Site Carbon
		"<svg width='6' height='6' viewBox='0 0 14 14' fill='none' xmlns='http://www.w3.org/2000/svg'>",
		"<rect x='1.12' y='1' width='12' height='12' fill='url(#site-type-1)' stroke='white' stroke-opacity='0.5'/>",
		"<defs><linearGradient id='site-type-1' x1='13.12' y1='1' x2='1.12' y2='13' gradientUnits='userSpaceOnUse'>",
		"<stop stop-color='#565656'/><stop offset='1'/></linearGradient></defs></svg></symbol>",
		"<symbol id='SITE_TYPE_2' width='6' height='6'>", // Site Silicon
		"<svg width='6' height='6' viewBox='0 0 12 12' fill='none' xmlns='http://www.w3.org/2000/svg'>",
		"<rect x='1.12' y='1' width='10' height='10' fill='url(#paint0_linear_1321_129011)' stroke='white' stroke-opacity='0.5'/>",
		"<defs><linearGradient id='paint0_linear_1321_129011' x1='11.12' y1='1' x2='1.12' y2='11' gradientUnits='userSpaceOnUse'>",
		"<stop stop-color='#CBE2FF'/><stop offset='1' stop-color='#EFEFEF'/></linearGradient></defs></svg></symbol>",
		"<symbol id='SITE_TYPE_3' width='6' height='6'>", // Site Hydrogen
		"<svg width='6' height='6' viewBox='0 0 12 12' fill='none' xmlns='http://www.w3.org/2000/svg'>",
		"<rect x='1.12' y='1' width='10' height='10' fill='url(#paint0_linear_1320_145814)' stroke='white' stroke-opacity='0.5'/>",
		"<defs><linearGradient id='paint0_linear_1320_145814' x1='11.12' y1='1' x2='-0.862058' y2='7.11845' gradientUnits='userSpaceOnUse'>",
		"<stop stop-color='#8CD4D9'/><stop offset='1' stop-color='#598FA6'/></linearGradient></defs></svg></symbol>",
		"<symbol id='SITE_TYPE_4' width='6' height='6'>", // Site Crypton
		"<svg width='6' height='6' viewBox='0 0 12 12' fill='none' xmlns='http://www.w3.org/2000/svg'>",
		"<rect x='1.12' y='1' width='10' height='10' fill='url(#paint0_linear_1321_129013)' stroke='white' stroke-opacity='0.5'/>",
		"<defs><linearGradient id='paint0_linear_1321_129013' x1='11.12' y1='1' x2='1.12' y2='11' gradientUnits='userSpaceOnUse'>",
		"<stop offset='1' stop-color='#52FF00'/></linearGradient></defs></svg></symbol>",
		"<symbol id='SITE_TYPE_5' width='6' height='6'>", // Site Hyperion
		"<svg width='6' height='6' viewBox='0 0 12 12' fill='none' xmlns='http://www.w3.org/2000/svg'>",
		"<rect x='1.12' y='1' width='10' height='10' fill='url(#paint0_linear_1321_129017)' stroke='white' stroke-opacity='0.5'/>",
		"<defs><linearGradient id='paint0_linear_1321_129017' x1='11.12' y1='1' x2='1.12' y2='11' gradientUnits='userSpaceOnUse'>",
		"<stop stop-color='#31F27F'/><stop offset='0.296875' stop-color='#F4BE86'/><stop offset='0.578125' stop-color='#B26FD2'/>",
		"<stop offset='0.734375' stop-color='#7F70D2'/><stop offset='1' stop-color='#8278F2'/></linearGradient></defs></svg></symbol>",
		"<symbol id='SITE_TYPE_6' width='6' height='6'><svg width='6' height='6' viewBox='0 0 12 12' fill='none' xmlns='http://www.w3.org/2000/svg'>", // Site Solon
		"<rect x='1.12' y='1' width='10' height='10' fill='url(#paint0_linear_1321_129015)' stroke='white' stroke-opacity='0.5'/>",
		"<defs><linearGradient id='paint0_linear_1321_129015' x1='11.12' y1='1' x2='1.11999' y2='11' gradientUnits='userSpaceOnUse'>",
		"<stop stop-color='white'/><stop offset='0.544585' stop-color='#FFD600'/><stop offset='1' stop-color='#FF9900'/>",
		"</linearGradient></defs></svg></symbol><linearGradient id='BOARD_BOTTOM_BORDER_COLOR_TIER_5' xmlns='http://www.w3.org/2000/svg'>",
		"<stop stop-color='#BE13AE'/></linearGradient><linearGradient id='BOARD_BOTTOM_BORDER_COLOR_TIER_4' xmlns='http://www.w3.org/2000/svg'>",
		"<stop stop-color='#1F7460'/></linearGradient><linearGradient id='BOARD_BOTTOM_BORDER_COLOR_TIER_3' xmlns='http://www.w3.org/2000/svg'>",
		"<stop stop-color='#6124AE'/></linearGradient><linearGradient id='BOARD_BOTTOM_BORDER_COLOR_TIER_2' xmlns='http://www.w3.org/2000/svg'>",
		"<stop stop-color='#5350AA'/></linearGradient><linearGradient id='BOARD_BOTTOM_BORDER_COLOR_TIER_1' xmlns='http://www.w3.org/2000/svg'>",
		"<stop stop-color='#2C2B67'/></linearGradient><linearGradient id='GRADIENT_BOARD_TIER_5' x1='100%' y1='0' x2='100%' y2='100%' gradientUnits='userSpaceOnUse' xmlns='http://www.w3.org/2000/svg'>",
		"<stop offset='0.130208' stop-color='#EFD700'/><stop offset='0.6875' stop-color='#FF57EE'/><stop offset='1' stop-color='#9A24EC'/>",
		"</linearGradient><linearGradient id='GRADIENT_BOARD_TIER_4' x1='50%' y1='100%' x2='50%' y2='0' gradientUnits='userSpaceOnUse' xmlns='http://www.w3.org/2000/svg'>",
		"<stop stop-color='#239378'/><stop offset='1' stop-color='#41E23E'/></linearGradient>",
		"<linearGradient id='GRADIENT_BOARD_TIER_3' x1='50%' y1='100%' x2='50%' y2='0' gradientUnits='userSpaceOnUse' xmlns='http://www.w3.org/2000/svg'>",
		"<stop stop-color='#812DED'/><stop offset='1' stop-color='#F100D9'/></linearGradient>",
		"<linearGradient id='GRADIENT_BOARD_TIER_2' x1='50%' y1='0' x2='50%' y2='100%' gradientUnits='userSpaceOnUse' xmlns='http://www.w3.org/2000/svg'>",
		"<stop stop-color='#7DD6F2'/><stop offset='1' stop-color='#625EDC'/></linearGradient>",
		"<linearGradient id='GRADIENT_BOARD_TIER_1' x1='50%' y1='0' x2='50%' y2='100%' gradientUnits='userSpaceOnUse' xmlns='http://www.w3.org/2000/svg'>",
		"<stop stop-color='#4C44A0'/><stop offset='1' stop-color='#2F2C83'/></linearGradient>",
		"<linearGradient id='ROUNDED_BORDER_TIER_5' x1='100%' y1='16.6%' x2='100%' y2='100%' gradientUnits='userSpaceOnUse' xmlns='http://www.w3.org/2000/svg'>",
		"<stop stop-color='#D2FFD9'/><stop offset='1' stop-color='#F32BE1'/></linearGradient>",
		"<linearGradient id='ROUNDED_BORDER_TIER_4' x1='100%' y1='16.6%' x2='100%' y2='100%' gradientUnits='userSpaceOnUse' xmlns='http://www.w3.org/2000/svg'>",
		"<stop stop-color='#fff' stop-opacity='0.38'/><stop offset='1' stop-color='#fff' stop-opacity='0.08'/></linearGradient>",
		"<linearGradient id='ROUNDED_BORDER_TIER_3' x1='100%' y1='16.6%' x2='100%' y2='100%' gradientUnits='userSpaceOnUse' xmlns='http://www.w3.org/2000/svg'>",
		"<stop stop-color='#fff' stop-opacity='0.38'/><stop offset='1' stop-color='#fff' stop-opacity='0.08'/></linearGradient>",
		"<linearGradient id='ROUNDED_BORDER_TIER_2' x1='100%' y1='16.6%' x2='100%' y2='100%' gradientUnits='userSpaceOnUse' xmlns='http://www.w3.org/2000/svg'>",
		"<stop stop-color='#fff' stop-opacity='0.38'/><stop offset='1' stop-color='#fff' stop-opacity='0.08'/></linearGradient>",
		"<linearGradient id='ROUNDED_BORDER_TIER_1' x1='100%' y1='16.6%' x2='100%' y2='100%' gradientUnits='userSpaceOnUse' xmlns='http://www.w3.org/2000/svg'>",
		"<stop stop-color='#fff' stop-opacity='0.38'/><stop offset='1' stop-color='#fff' stop-opacity='0.08'/></linearGradient>",
		"<pattern id='smallGrid' width='3' height='3' patternUnits='userSpaceOnUse' patternTransform='rotate(45 ",
		string(abi.encodePacked(scaledGridSizeString, " ", scaledGridSizeString)),
		")'><path d='M 3 0 L 0 0 0 3' fill='none' stroke-width='0.3%' stroke='#130A2A' stroke-opacity='0.2' />",
		"</pattern><symbol id='LANDMARK_TYPE_1' width='6' height='6'><svg width='6' height='6' viewBox='0 0 14 14' fill='none' xmlns='http://www.w3.org/2000/svg'>",
		"<rect x='1.12' y='1' width='12' height='12' fill='url(#paint0_linear_2371_558677)' stroke='white' stroke-opacity='0.5'/>",
		"<rect x='4.72' y='4.59998' width='4.8' height='4.8' fill='url(#paint1_linear_2371_558677)'/>",
		"<rect x='4.72' y='4.59998' width='4.8' height='4.8' fill='white'/>",
		"<defs><linearGradient id='paint0_linear_2371_558677' x1='13.12' y1='1' x2='1.12' y2='13' gradientUnits='userSpaceOnUse'>",
		"<stop stop-color='#565656'/><stop offset='1'/></linearGradient>",
		"<linearGradient id='paint1_linear_2371_558677' x1='9.52' y1='4.59998' x2='4.72' y2='9.39998' gradientUnits='userSpaceOnUse'>",
		"<stop stop-color='#565656'/><stop offset='1'/></linearGradient></defs></svg></symbol>",
		"<symbol id='LANDMARK_TYPE_2' width='6' height='6'><svg width='6' height='6' viewBox='0 0 12 12' fill='none' xmlns='http://www.w3.org/2000/svg'>",
		"<rect x='1.12' y='1' width='10' height='10' fill='url(#paint0_linear_2371_558683)' stroke='white' stroke-opacity='0.5'/>",
		"<rect x='4.12' y='4' width='4' height='4' fill='url(#paint1_linear_2371_558683)'/><rect x='4.12' y='4' width='4' height='4' fill='white'/>",
		"<rect x='3.62' y='3.5' width='5' height='5' stroke='black' stroke-opacity='0.1'/>",
		"<defs><linearGradient id='paint0_linear_2371_558683' x1='11.12' y1='1' x2='-0.862058' y2='7.11845' gradientUnits='userSpaceOnUse'>",
		"<stop stop-color='#8CD4D9'/><stop offset='1' stop-color='#598FA6'/></linearGradient>",
		"<linearGradient id='paint1_linear_2371_558683' x1='8.12' y1='4' x2='4.12' y2='8' gradientUnits='userSpaceOnUse'>",
		"<stop stop-color='#565656'/><stop offset='1'/></linearGradient></defs></svg></symbol>",
		"<symbol id='LANDMARK_TYPE_3' width='6' height='6'><svg width='6' height='6' viewBox='0 0 12 12' fill='none' xmlns='http://www.w3.org/2000/svg'>",
		"<rect x='1.12' y='1' width='10' height='10' fill='url(#paint0_linear_2371_558686)' stroke='white' stroke-opacity='0.5'/>",
		"<rect x='4.12' y='4' width='4' height='4' fill='url(#paint1_linear_2371_558686)'/><rect x='4.12' y='4' width='4' height='4' fill='white'/>",
		"<rect x='3.62' y='3.5' width='5' height='5' stroke='black' stroke-opacity='0.1'/>",
		"<defs><linearGradient id='paint0_linear_2371_558686' x1='11.12' y1='1' x2='1.12' y2='11' gradientUnits='userSpaceOnUse'>",
		"<stop stop-color='#CBE2FF'/><stop offset='1' stop-color='#EFEFEF'/></linearGradient>",
		"<linearGradient id='paint1_linear_2371_558686' x1='8.12' y1='4' x2='4.12' y2='8' gradientUnits='userSpaceOnUse'>",
		"<stop stop-color='#565656'/><stop offset='1'/></linearGradient></defs></svg></symbol>",
		"<symbol id='LANDMARK_TYPE_4' width='6' height='6'><svg width='6' height='6' viewBox='0 0 12 12' fill='none' xmlns='http://www.w3.org/2000/svg'>",
		"<rect x='1.12' y='1' width='10' height='10' fill='url(#paint0_linear_2371_558689)' stroke='white' stroke-opacity='0.5'/>",
		"<rect x='4.12' y='4' width='4' height='4' fill='url(#paint1_linear_2371_558689)'/><rect x='4.12' y='4' width='4' height='4' fill='white'/>",
		"<rect x='3.62' y='3.5' width='5' height='5' stroke='black' stroke-opacity='0.1'/>",
		"<defs><linearGradient id='paint0_linear_2371_558689' x1='11.12' y1='1' x2='1.12' y2='11' gradientUnits='userSpaceOnUse'>",
		"<stop stop-color='#184B00'/><stop offset='1' stop-color='#52FF00'/></linearGradient>",
		"<linearGradient id='paint1_linear_2371_558689' x1='8.12' y1='4' x2='4.12' y2='8' gradientUnits='userSpaceOnUse'>",
		"<stop stop-color='#565656'/><stop offset='1'/></linearGradient></defs></svg></symbol>",
		"<symbol id='LANDMARK_TYPE_5' width='6' height='6'><svg width='6' height='6' viewBox='0 0 12 12' fill='none' xmlns='http://www.w3.org/2000/svg'>",
		"<rect x='1.12' y='1' width='10' height='10' fill='url(#paint0_linear_2371_558695)' stroke='white' stroke-opacity='0.5'/>",
		"<rect x='4.12' y='4' width='4' height='4' fill='url(#paint1_linear_2371_558695)'/>",
		"<rect x='4.12' y='4' width='4' height='4' fill='white'/><rect x='3.62' y='3.5' width='5' height='5' stroke='black' stroke-opacity='0.1'/>",
		"<defs><linearGradient id='paint0_linear_2371_558695' x1='11.12' y1='1' x2='1.12' y2='11' gradientUnits='userSpaceOnUse'>",
		"<stop stop-color='#31F27F'/><stop offset='0.296875' stop-color='#F4BE86'/><stop offset='0.578125' stop-color='#B26FD2'/>",
		"<stop offset='0.734375' stop-color='#7F70D2'/><stop offset='1' stop-color='#8278F2'/></linearGradient>",
		"<linearGradient id='paint1_linear_2371_558695' x1='8.12' y1='4' x2='4.12' y2='8' gradientUnits='userSpaceOnUse'>",
		"<stop stop-color='#565656'/><stop offset='1'/></linearGradient></defs></svg></symbol>",
		"<symbol id='LANDMARK_TYPE_6' width='6' height='6'><svg width='6' height='6' viewBox='0 0 12 12' fill='none' xmlns='http://www.w3.org/2000/svg'>",
		"<rect x='1.12' y='1' width='10' height='10' fill='url(#paint0_linear_2371_558692)' stroke='white' stroke-opacity='0.5'/>",
		"<rect x='4.12' y='4' width='4' height='4' fill='url(#paint1_linear_2371_558692)'/><rect x='4.12' y='4' width='4' height='4' fill='white'/>",
		"<rect x='3.62' y='3.5' width='5' height='5' stroke='black' stroke-opacity='0.1'/><defs><linearGradient id='paint0_linear_2371_558692' x1='11.12' y1='1' x2='1.11999' y2='11' gradientUnits='userSpaceOnUse'>",
		"<stop stop-color='white'/><stop offset='0.544585' stop-color='#FFD600'/><stop offset='1' stop-color='#FF9900'/></linearGradient>",
		"<linearGradient id='paint1_linear_2371_558692' x1='8.12' y1='4' x2='4.12' y2='8' gradientUnits='userSpaceOnUse'>",
		"<stop stop-color='#565656'/><stop offset='1'/></linearGradient></defs></svg></symbol>",
		"<symbol id='LANDMARK_TYPE_7' width='6' height='6'><svg width='6' height='6' viewBox='0 0 12 12' fill='none' xmlns='http://www.w3.org/2000/svg'>",
		"<rect x='1.12' y='1' width='10' height='10' fill='url(#paint0_linear_2373_559424)' stroke='white' stroke-opacity='0.5'/>",
		"<rect x='3.12' y='3' width='6' height='6' fill='url(#paint1_linear_2373_559424)'/><rect x='3.12' y='3' width='6' height='6' fill='white'/>",
		"<rect x='2.62' y='2.5' width='7' height='7' stroke='black' stroke-opacity='0.1'/>",
		"<defs><linearGradient id='paint0_linear_2373_559424' x1='11.12' y1='1' x2='1.11999' y2='11' gradientUnits='userSpaceOnUse'>",
		"<stop stop-color='#08CE01'/><stop offset='0.171875' stop-color='#CEEF00'/><stop offset='0.34375' stop-color='#51F980'/>",
		"<stop offset='0.5' stop-color='#2D51ED'/><stop offset='0.671875' stop-color='#0060F1'/><stop offset='0.833333' stop-color='#F100D9'/>",
		"<stop offset='1' stop-color='#9A24EC'/></linearGradient><linearGradient id='paint1_linear_2373_559424' x1='9.12' y1='3' x2='3.12' y2='9' gradientUnits='userSpaceOnUse'>",
		"<stop stop-color='#565656'/><stop offset='1'/></linearGradient></defs></svg></symbol>",
		"</defs><rect width='100%' height='100%' fill='url(#GRADIENT_BOARD_TIER_",
		uint256(_tierId).toString(), // This line should be replaced in the loop
		")' stroke='none' rx='5%' ry='5%'/><svg x='",
		_gridSize % 2 == 0 ? "-17%" : "-18%",
		"' y='",
		_gridSize % 2 == 0 ? "-17%" : "-18%",
		"' width='",
		_gridSize % 2 == 0 ? "117%" : "117.8%",
		"' height='",
		_gridSize % 2 == 0 ? "116.4%" : "117.8%",
		"' ><g transform='scale(1.34)' rx='5%' ry='5%' ><rect x='",
		_gridSize % 2 == 0 ? "11%" : "11.6%",
		"' y='",
		_gridSize % 2 == 0 ? "11.2%" : "11.6%",
		"' width='",
		_gridSize % 2 == 0 ? "63.6%" : "63.0%",
		"' height='",
		_gridSize % 2 == 0 ? "63.8%" : "63.2%",
		"' fill='url(#smallGrid)' stroke='none'  rx='3%' ry='3%' /><g transform='rotate(45 ",
		string(abi.encodePacked(scaledGridSizeString, " ", scaledGridSizeString, ")'>")),
		"LANDMARK", // This line should be replaced by the Landmark in the loop
		"SITES_POSITIONED", // This line should be replaced in the loop
		"</g></g></svg>",
		"<rect xmlns='http://www.w3.org/2000/svg' x='0.3' y='0.3' width='99.7%' height='99.7%' fill='none' stroke='url(#ROUNDED_BORDER_TIER_",
		uint256(_tierId).toString(),
		")' stroke-width='1' rx='4.5%' ry='4.5%'/></svg>"
		];

	}

	/**
	 * @dev Calculates string for the land name based on plot data.
	 *
	 * @param _regionId PlotView.regionId
	 * @param _x PlotView.x coordinate
	 * @param _y PlotView.y coordinate
	 * @return SVG name attribute
	 */
	function _generateLandName(uint8 _regionId, uint16 _x, uint16 _y) private pure returns (string memory) {
		string memory region;
		if (_regionId == 1) {
			region = "Taiga Boreal";
		} else if (_regionId == 2) {
			region = "Crystal Shores";
		} else if (_regionId == 3) {
			region = "Shardbluff Labyrinth";
		} else if (_regionId == 4) {
			region = "Abyssal Basin";
		} else if (_regionId == 5) {
			region = "Crimson Waste";
		} else if (_regionId == 6) {
			region = "Brightland Steppes";
		} else if (_regionId == 7) {
			region = "Halcyon Sea";
		} else {
			revert("Invalid region ID");
		}
		return string(
			abi.encodePacked(
				region,
				" (",
				uint256(_x).toString(),
				", ",
				uint256(_y).toString(),
				")"
			)
		);
	}

	/**
	 * @dev Calculates the string for the land metadata description.
	 */
	function _generateLandDescription() private pure returns (string memory) {
		return "One Description for all:\\n"
			"Illuvium Land is a digital piece of real estate in the Illuvium universe that players can mine for fuels through Illuvium Zero. "
			"Fuels are ERC-20 tokens that are used in Illuvium games and can be traded on the marketplace. Higher-tiered lands produce more fuel."
			"\\n\\nLearn more about Illuvium Land at illuvidex.illuvium.io/land.";
	}

	/**
	 * @dev Populates the mainSvg array with the land tier id and the svg returned
	 *      by the _generateLandBoard. Expects it to generate the land svg inside 
	 *      the container.
	 * 
	 * @param _landmarkTypeId landmark type defined by its ID
	 * @param _tierId PlotView.tierId land tier id
	 * @param _gridSize The size of the grid
	 * @param _sites Array of plot sites coming from PlotView struct
	 * @return The SVG image component
	 */
	function _generateSVG(
		uint8 _landmarkTypeId,
		uint8 _tierId,
		uint16 _gridSize,
		LandLib.Site[] memory _sites
	) private pure returns (string memory) {
		string[11] memory _mainSvgTemplate = _mainSvg(_gridSize, _tierId);
		string[] memory _mainSvgArray = new string[](_mainSvgTemplate.length);

		for (uint256 i = 0; i < _mainSvgTemplate.length; i++) {
			if (keccak256(bytes(_mainSvgTemplate[i])) == keccak256(bytes("FUTURE_BOARD_CONTAINER"))) {
				_mainSvgArray[i] = _generateLandBoard(_tierId, _gridSize, _landmarkTypeId, _sites);
				continue;
			}
			_mainSvgArray[i] = _mainSvgTemplate[i];
		}
		return _joinArray(_mainSvgArray);
	}

	/**
	 * @dev Generates the plot svg containing all sites inside and color according
	 *      to the tier
	 * 
	 * @param _tierId PlotView.tierId land tier id
	 * @param _gridSize The size of the grid
	 * @param _landmarkTypeId landmark type defined by its ID
	 * @param _sites Array of plot sites coming from PlotView struct
	 * @return The board component for the land SVG
	 */
	function _generateLandBoard(
		uint8 _tierId,
		uint16 _gridSize,
		uint8 _landmarkTypeId,
		LandLib.Site[] memory _sites
	) private pure returns (string memory) {
		string[141] memory _boardSvgTemplate = _boardSvg(_gridSize, _tierId);
		string[] memory _boardSvgArray = new string[](_boardSvgTemplate.length);

		for (uint256 i = 0; i < _boardSvgTemplate.length; i++) {
			if (keccak256(bytes(_boardSvgTemplate[i])) == keccak256(bytes("SITES_POSITIONED"))) {
				_boardSvgArray[i] = _generateSites(_sites);
				continue;
			}
			if (keccak256(bytes(_boardSvgTemplate[i])) == keccak256(bytes("LANDMARK"))) {
				_boardSvgArray[i] = _generateLandmarkSvg(_gridSize, _landmarkTypeId);
				continue;
			}
			_boardSvgArray[i] = _boardSvgTemplate[i];
		}
		return _joinArray(_boardSvgArray);
	}

	/**
	 * @dev Generates each site inside the land svg board with is position and color.
	 *
	 * @param _sites Array of plot sites coming from PlotView struct
	 * @return The sites components for the land SVG
	 */
	function _generateSites(LandLib.Site[] memory _sites) private pure returns (string memory) {
		string[] memory _siteSvgArray = new string[](_sites.length);
		for (uint256 i = 0; i < _sites.length; i++) {
			_siteSvgArray[i] = _siteBaseSvg(
				_convertToSvgPositionX(_sites[i].x),
				_convertToSvgPositionY(_sites[i].y),
				_sites[i].typeId
			);
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
	 * @param _gridSize The size of the grid
	 * @param _landmarkTypeId landmark type defined by its ID
	 * @param _sites Array of plot sites coming from PlotView struct
	 */
	function constructTokenURI(
		uint8 _regionId,
		uint16 _x,
		uint16 _y,
		uint8 _tierId,
		uint16 _gridSize,
		uint8 _landmarkTypeId,
		LandLib.Site[] memory _sites
	) internal pure returns (string memory) {
		string memory name = _generateLandName(_regionId, _x, _y);
		string memory description = _generateLandDescription();
		string memory image = Base64.encode(bytes(_generateSVG(_landmarkTypeId, _tierId, _gridSize, _sites)));

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
			)
		);
	}

	/**
	 * @dev Concatenate string array into one string.
	 *
	 * @param _svgArray Array containing SVG strings/elements
	 * @return Concatenated SVG string
	 */
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

	/**
	 * @dev Convert site X position to fit into the board.
	 *
	 * @param _positionX X coordinate of the site
	 * @return Transformed X coordinate
	 */
	function _convertToSvgPositionX(uint16 _positionX) private pure returns (uint16) {
		return _positionX * 3;
	}

	/**
	 * @dev Convert site Y position to fit into the board.
	 *
	 * @param _positionY Y coordinate of the site
	 * @return Transformed Y coordinate
	 */
	function _convertToSvgPositionY(uint16 _positionY) private pure returns (uint16) {
		return _positionY * 3;
	}

	/**
	 * @dev Truncate string at a certain position and size.
	 *
	 * @param _str String to be truncated
	 * @param _from The initial position to start slicing
	 * @param _size The size of the resulting substring
	 * @return Truncated string
	 */
	function truncateString(string memory _str, uint256 _from, uint256 _size) internal pure returns (string memory) {
		bytes memory stringBytes = bytes(_str);
		if (_from + _size >= stringBytes.length) {
			return _str;
		}

		bytes memory truncatedBytes = new bytes(_size);
		uint256 j;
		for (uint256 i = _from; i < _from + _size; i++) {
			truncatedBytes[j] = stringBytes[i];
			j++;
		}

		return string(truncatedBytes);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

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
		 *        1) Taiga Boreal
		 *        2) Crystal Shores
		 *        3) Shardbluff Labyrinth
		 *        4) Abyssal Basin
		 *        5) Crimson Waste
		 *        6) Brightland Steppes
		 *        7) Halcyon Sea
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
	function plotView(PlotStore memory store) internal pure returns (PlotView memory) {
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
	) internal pure returns (Site[] memory sites) {
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

		// define coordinate system: an isomorphic grid on a square of size [size, size]
		// transform coordinate system (3): pack an isomorphic grid on a rectangle of size [size, 1 + size / 2]
		// transform coordinate system (4): (x, y) -> y * size + x (two-dimensional Cartesian -> one-dimensional segment)
		// define temporary array to determine sites' coordinates
		uint16[] memory coords;
		// generate site coordinates in a transformed coordinate system (on a one-dimensional segment)
		// cut off four elements in the end of the segment to reserve space in the center for a landmark
		(seed, coords) = getCoords(seed, totalSites, normalizedSize * (1 + normalizedSize / 2) - 4);

		// allocate number of sites required
		sites = new Site[](totalSites);

		// define the variables used inside the loop outside the loop to help compiler optimizations
		// site type ID is de facto uint8, we're using uint16 for convenience with `nextRndUint16`
		uint16 typeId;
		// site coordinates (x, y)
		uint16 x;
		uint16 y;

		// determine the element and fuel sites one by one
		for(uint8 i = 0; i < totalSites; i++) {
			// determine next random number in the sequence, and random site type from it
			(seed, typeId) = nextRndUint16(seed, i < elementSites? 1: 4, 3);

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
			if(x >= normalizedSize / 2 - 1 && x <= normalizedSize / 2
			&& y >= normalizedSize / 2 - 1 && y <= normalizedSize / 2) {
				// `x` is aligned over the free space in the end of the segment
				// x += normalizedSize / 2 + 2 * (normalizedSize / 2 - x) + 2 * (normalizedSize / 2 - y) - 4;
				x += 5 * normalizedSize / 2 - 2 * (x + y) - 4;
				// `y` is fixed over the free space in the end of the segment
				y = normalizedSize / 2;
			}

			// if `N/2` is odd recover previously cut off border coordinates x = N/2 - 1, y = N/2 - 1
			// if `N` is odd recover previously cut off border coordinates x = N - 1, y = N - 1
			uint16 offset = gridSize / siteSize % 2 + gridSize % siteSize;

			// based on the determined site type and coordinates, allocate the site
			sites[i] = Site({
				typeId: uint8(typeId),
				// reverse transform coordinate system (2): recover borders (x, y) => (x + 1, y + 1)
				// if `N/2` is odd recover previously cut off border coordinates x = N/2 - 1, y = N/2 - 1
				// reverse transform coordinate system (1): (x, y) => (n * x, n * y), where n is site size
				// if `N` is odd recover previously cut off border coordinates x = N - 1, y = N - 1
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
	function getLandmark(uint256 seed, uint8 tierId) internal pure returns (uint8 landmarkTypeId) {
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
	) internal pure returns (uint256 nextSeed, uint16[] memory coords) {
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

		// shuffle the array to compensate for the sorting made before
		seed = shuffle(seed, coords);

		// return the updated used seed, and generated coordinates
		return (seed, coords);
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
	) internal pure returns (
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
	function loc(PlotView memory plot) internal pure returns (uint40) {
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
	function loc(PlotStore memory plot) internal pure returns (uint40) {
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
	function loc(Site memory site) internal pure returns (uint32) {
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
				// return its index if yes
				return int256(i - 1);
			}
		}

		// return `-1` if no violation was found - array is strictly monotonically increasing
		return -1;
	}

	/**
	 * @dev Shuffles an array if integers by making random permutations
	 *      in the amount equal to the array size
	 *
	 * @dev The input seed is considered to be already used to derive some random value
	 *      from it, therefore the function derives a new one by hashing the previous one
	 *      before generating the random value; the output seed is "used" - output random
	 *      value is derived from it
	 *
	 * @param seed random seed to consume and derive next random value from
	 * @param arr an array to shuffle
	 * @return nextSeed next pseudo-random "used" seed
	 */
	function shuffle(uint256 seed, uint16[] memory arr) internal pure returns(uint256 nextSeed) {
		// define index `j` to permute with loop index `i` outside the loop to help compiler optimizations
		uint16 j;

		// iterate over the array one single time
		for(uint16 i = 0; i < arr.length; i++) {
			// determine random index `j` to swap with the loop index `i`
			(seed, j) = nextRndUint16(seed, 0, uint16(arr.length));

			// do the swap
			(arr[i], arr[j]) = (arr[j], arr[i]);
		}

		// return the updated used seed
		return seed;
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
	function quickSort(uint16[] memory arr, int256 left, int256 right) private pure {
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

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
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

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

import "./PRBMath.sol";

/// @title PRBMathUD60x18
/// @author Paul Razvan Berg
/// @notice Smart contract library for advanced fixed-point math that works with uint256 numbers considered to have 18
/// trailing decimals. We call this number representation unsigned 60.18-decimal fixed-point, since there can be up to 60
/// digits in the integer part and up to 18 decimals in the fractional part. The numbers are bound by the minimum and the
/// maximum values permitted by the Solidity type uint256.
library PRBMathUD60x18 {
    /// @dev Half the SCALE number.
    uint256 internal constant HALF_SCALE = 5e17;

    /// @dev log2(e) as an unsigned 60.18-decimal fixed-point number.
    uint256 internal constant LOG2_E = 1_442695040888963407;

    /// @dev The maximum value an unsigned 60.18-decimal fixed-point number can have.
    uint256 internal constant MAX_UD60x18 =
        115792089237316195423570985008687907853269984665640564039457_584007913129639935;

    /// @dev The maximum whole value an unsigned 60.18-decimal fixed-point number can have.
    uint256 internal constant MAX_WHOLE_UD60x18 =
        115792089237316195423570985008687907853269984665640564039457_000000000000000000;

    /// @dev How many trailing decimals can be represented.
    uint256 internal constant SCALE = 1e18;

    /// @notice Calculates the arithmetic average of x and y, rounding down.
    /// @param x The first operand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The second operand as an unsigned 60.18-decimal fixed-point number.
    /// @return result The arithmetic average as an unsigned 60.18-decimal fixed-point number.
    function avg(uint256 x, uint256 y) internal pure returns (uint256 result) {
        // The operations can never overflow.
        unchecked {
            // The last operand checks if both x and y are odd and if that is the case, we add 1 to the result. We need
            // to do this because if both numbers are odd, the 0.5 remainder gets truncated twice.
            result = (x >> 1) + (y >> 1) + (x & y & 1);
        }
    }

    /// @notice Yields the least unsigned 60.18 decimal fixed-point number greater than or equal to x.
    ///
    /// @dev Optimized for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
    /// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
    ///
    /// Requirements:
    /// - x must be less than or equal to MAX_WHOLE_UD60x18.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number to ceil.
    /// @param result The least integer greater than or equal to x, as an unsigned 60.18-decimal fixed-point number.
    function ceil(uint256 x) internal pure returns (uint256 result) {
        if (x > MAX_WHOLE_UD60x18) {
            revert PRBMathUD60x18__CeilOverflow(x);
        }
        assembly {
            // Equivalent to "x % SCALE" but faster.
            let remainder := mod(x, SCALE)

            // Equivalent to "SCALE - remainder" but faster.
            let delta := sub(SCALE, remainder)

            // Equivalent to "x + delta * (remainder > 0 ? 1 : 0)" but faster.
            result := add(x, mul(delta, gt(remainder, 0)))
        }
    }

    /// @notice Divides two unsigned 60.18-decimal fixed-point numbers, returning a new unsigned 60.18-decimal fixed-point number.
    ///
    /// @dev Uses mulDiv to enable overflow-safe multiplication and division.
    ///
    /// Requirements:
    /// - The denominator cannot be zero.
    ///
    /// @param x The numerator as an unsigned 60.18-decimal fixed-point number.
    /// @param y The denominator as an unsigned 60.18-decimal fixed-point number.
    /// @param result The quotient as an unsigned 60.18-decimal fixed-point number.
    function div(uint256 x, uint256 y) internal pure returns (uint256 result) {
        result = PRBMath.mulDiv(x, SCALE, y);
    }

    /// @notice Returns Euler's number as an unsigned 60.18-decimal fixed-point number.
    /// @dev See https://en.wikipedia.org/wiki/E_(mathematical_constant).
    function e() internal pure returns (uint256 result) {
        result = 2_718281828459045235;
    }

    /// @notice Calculates the natural exponent of x.
    ///
    /// @dev Based on the insight that e^x = 2^(x * log2(e)).
    ///
    /// Requirements:
    /// - All from "log2".
    /// - x must be less than 133.084258667509499441.
    ///
    /// @param x The exponent as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function exp(uint256 x) internal pure returns (uint256 result) {
        // Without this check, the value passed to "exp2" would be greater than 192.
        if (x >= 133_084258667509499441) {
            revert PRBMathUD60x18__ExpInputTooBig(x);
        }

        // Do the fixed-point multiplication inline to save gas.
        unchecked {
            uint256 doubleScaleProduct = x * LOG2_E;
            result = exp2((doubleScaleProduct + HALF_SCALE) / SCALE);
        }
    }

    /// @notice Calculates the binary exponent of x using the binary fraction method.
    ///
    /// @dev See https://ethereum.stackexchange.com/q/79903/24693.
    ///
    /// Requirements:
    /// - x must be 192 or less.
    /// - The result must fit within MAX_UD60x18.
    ///
    /// @param x The exponent as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function exp2(uint256 x) internal pure returns (uint256 result) {
        // 2^192 doesn't fit within the 192.64-bit format used internally in this function.
        if (x >= 192e18) {
            revert PRBMathUD60x18__Exp2InputTooBig(x);
        }

        unchecked {
            // Convert x to the 192.64-bit fixed-point format.
            uint256 x192x64 = (x << 64) / SCALE;

            // Pass x to the PRBMath.exp2 function, which uses the 192.64-bit fixed-point number representation.
            result = PRBMath.exp2(x192x64);
        }
    }

    /// @notice Yields the greatest unsigned 60.18 decimal fixed-point number less than or equal to x.
    /// @dev Optimized for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
    /// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
    /// @param x The unsigned 60.18-decimal fixed-point number to floor.
    /// @param result The greatest integer less than or equal to x, as an unsigned 60.18-decimal fixed-point number.
    function floor(uint256 x) internal pure returns (uint256 result) {
        assembly {
            // Equivalent to "x % SCALE" but faster.
            let remainder := mod(x, SCALE)

            // Equivalent to "x - remainder * (remainder > 0 ? 1 : 0)" but faster.
            result := sub(x, mul(remainder, gt(remainder, 0)))
        }
    }

    /// @notice Yields the excess beyond the floor of x.
    /// @dev Based on the odd function definition https://en.wikipedia.org/wiki/Fractional_part.
    /// @param x The unsigned 60.18-decimal fixed-point number to get the fractional part of.
    /// @param result The fractional part of x as an unsigned 60.18-decimal fixed-point number.
    function frac(uint256 x) internal pure returns (uint256 result) {
        assembly {
            result := mod(x, SCALE)
        }
    }

    /// @notice Converts a number from basic integer form to unsigned 60.18-decimal fixed-point representation.
    ///
    /// @dev Requirements:
    /// - x must be less than or equal to MAX_UD60x18 divided by SCALE.
    ///
    /// @param x The basic integer to convert.
    /// @param result The same number in unsigned 60.18-decimal fixed-point representation.
    function fromUint(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            if (x > MAX_UD60x18 / SCALE) {
                revert PRBMathUD60x18__FromUintOverflow(x);
            }
            result = x * SCALE;
        }
    }

    /// @notice Calculates geometric mean of x and y, i.e. sqrt(x * y), rounding down.
    ///
    /// @dev Requirements:
    /// - x * y must fit within MAX_UD60x18, lest it overflows.
    ///
    /// @param x The first operand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The second operand as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function gm(uint256 x, uint256 y) internal pure returns (uint256 result) {
        if (x == 0) {
            return 0;
        }

        unchecked {
            // Checking for overflow this way is faster than letting Solidity do it.
            uint256 xy = x * y;
            if (xy / x != y) {
                revert PRBMathUD60x18__GmOverflow(x, y);
            }

            // We don't need to multiply by the SCALE here because the x*y product had already picked up a factor of SCALE
            // during multiplication. See the comments within the "sqrt" function.
            result = PRBMath.sqrt(xy);
        }
    }

    /// @notice Calculates 1 / x, rounding toward zero.
    ///
    /// @dev Requirements:
    /// - x cannot be zero.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the inverse.
    /// @return result The inverse as an unsigned 60.18-decimal fixed-point number.
    function inv(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            // 1e36 is SCALE * SCALE.
            result = 1e36 / x;
        }
    }

    /// @notice Calculates the natural logarithm of x.
    ///
    /// @dev Based on the insight that ln(x) = log2(x) / log2(e).
    ///
    /// Requirements:
    /// - All from "log2".
    ///
    /// Caveats:
    /// - All from "log2".
    /// - This doesn't return exactly 1 for 2.718281828459045235, for that we would need more fine-grained precision.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the natural logarithm.
    /// @return result The natural logarithm as an unsigned 60.18-decimal fixed-point number.
    function ln(uint256 x) internal pure returns (uint256 result) {
        // Do the fixed-point multiplication inline to save gas. This is overflow-safe because the maximum value that log2(x)
        // can return is 196205294292027477728.
        unchecked {
            result = (log2(x) * SCALE) / LOG2_E;
        }
    }

    /// @notice Calculates the common logarithm of x.
    ///
    /// @dev First checks if x is an exact power of ten and it stops if yes. If it's not, calculates the common
    /// logarithm based on the insight that log10(x) = log2(x) / log2(10).
    ///
    /// Requirements:
    /// - All from "log2".
    ///
    /// Caveats:
    /// - All from "log2".
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the common logarithm.
    /// @return result The common logarithm as an unsigned 60.18-decimal fixed-point number.
    function log10(uint256 x) internal pure returns (uint256 result) {
        if (x < SCALE) {
            revert PRBMathUD60x18__LogInputTooSmall(x);
        }

        // Note that the "mul" in this block is the assembly multiplication operation, not the "mul" function defined
        // in this contract.
        // prettier-ignore
        assembly {
            switch x
            case 1 { result := mul(SCALE, sub(0, 18)) }
            case 10 { result := mul(SCALE, sub(1, 18)) }
            case 100 { result := mul(SCALE, sub(2, 18)) }
            case 1000 { result := mul(SCALE, sub(3, 18)) }
            case 10000 { result := mul(SCALE, sub(4, 18)) }
            case 100000 { result := mul(SCALE, sub(5, 18)) }
            case 1000000 { result := mul(SCALE, sub(6, 18)) }
            case 10000000 { result := mul(SCALE, sub(7, 18)) }
            case 100000000 { result := mul(SCALE, sub(8, 18)) }
            case 1000000000 { result := mul(SCALE, sub(9, 18)) }
            case 10000000000 { result := mul(SCALE, sub(10, 18)) }
            case 100000000000 { result := mul(SCALE, sub(11, 18)) }
            case 1000000000000 { result := mul(SCALE, sub(12, 18)) }
            case 10000000000000 { result := mul(SCALE, sub(13, 18)) }
            case 100000000000000 { result := mul(SCALE, sub(14, 18)) }
            case 1000000000000000 { result := mul(SCALE, sub(15, 18)) }
            case 10000000000000000 { result := mul(SCALE, sub(16, 18)) }
            case 100000000000000000 { result := mul(SCALE, sub(17, 18)) }
            case 1000000000000000000 { result := 0 }
            case 10000000000000000000 { result := SCALE }
            case 100000000000000000000 { result := mul(SCALE, 2) }
            case 1000000000000000000000 { result := mul(SCALE, 3) }
            case 10000000000000000000000 { result := mul(SCALE, 4) }
            case 100000000000000000000000 { result := mul(SCALE, 5) }
            case 1000000000000000000000000 { result := mul(SCALE, 6) }
            case 10000000000000000000000000 { result := mul(SCALE, 7) }
            case 100000000000000000000000000 { result := mul(SCALE, 8) }
            case 1000000000000000000000000000 { result := mul(SCALE, 9) }
            case 10000000000000000000000000000 { result := mul(SCALE, 10) }
            case 100000000000000000000000000000 { result := mul(SCALE, 11) }
            case 1000000000000000000000000000000 { result := mul(SCALE, 12) }
            case 10000000000000000000000000000000 { result := mul(SCALE, 13) }
            case 100000000000000000000000000000000 { result := mul(SCALE, 14) }
            case 1000000000000000000000000000000000 { result := mul(SCALE, 15) }
            case 10000000000000000000000000000000000 { result := mul(SCALE, 16) }
            case 100000000000000000000000000000000000 { result := mul(SCALE, 17) }
            case 1000000000000000000000000000000000000 { result := mul(SCALE, 18) }
            case 10000000000000000000000000000000000000 { result := mul(SCALE, 19) }
            case 100000000000000000000000000000000000000 { result := mul(SCALE, 20) }
            case 1000000000000000000000000000000000000000 { result := mul(SCALE, 21) }
            case 10000000000000000000000000000000000000000 { result := mul(SCALE, 22) }
            case 100000000000000000000000000000000000000000 { result := mul(SCALE, 23) }
            case 1000000000000000000000000000000000000000000 { result := mul(SCALE, 24) }
            case 10000000000000000000000000000000000000000000 { result := mul(SCALE, 25) }
            case 100000000000000000000000000000000000000000000 { result := mul(SCALE, 26) }
            case 1000000000000000000000000000000000000000000000 { result := mul(SCALE, 27) }
            case 10000000000000000000000000000000000000000000000 { result := mul(SCALE, 28) }
            case 100000000000000000000000000000000000000000000000 { result := mul(SCALE, 29) }
            case 1000000000000000000000000000000000000000000000000 { result := mul(SCALE, 30) }
            case 10000000000000000000000000000000000000000000000000 { result := mul(SCALE, 31) }
            case 100000000000000000000000000000000000000000000000000 { result := mul(SCALE, 32) }
            case 1000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 33) }
            case 10000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 34) }
            case 100000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 35) }
            case 1000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 36) }
            case 10000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 37) }
            case 100000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 38) }
            case 1000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 39) }
            case 10000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 40) }
            case 100000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 41) }
            case 1000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 42) }
            case 10000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 43) }
            case 100000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 44) }
            case 1000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 45) }
            case 10000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 46) }
            case 100000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 47) }
            case 1000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 48) }
            case 10000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 49) }
            case 100000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 50) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 51) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 52) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 53) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 54) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 55) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 56) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 57) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 58) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 59) }
            default {
                result := MAX_UD60x18
            }
        }

        if (result == MAX_UD60x18) {
            // Do the fixed-point division inline to save gas. The denominator is log2(10).
            unchecked {
                result = (log2(x) * SCALE) / 3_321928094887362347;
            }
        }
    }

    /// @notice Calculates the binary logarithm of x.
    ///
    /// @dev Based on the iterative approximation algorithm.
    /// https://en.wikipedia.org/wiki/Binary_logarithm#Iterative_approximation
    ///
    /// Requirements:
    /// - x must be greater than or equal to SCALE, otherwise the result would be negative.
    ///
    /// Caveats:
    /// - The results are nor perfectly accurate to the last decimal, due to the lossy precision of the iterative approximation.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the binary logarithm.
    /// @return result The binary logarithm as an unsigned 60.18-decimal fixed-point number.
    function log2(uint256 x) internal pure returns (uint256 result) {
        if (x < SCALE) {
            revert PRBMathUD60x18__LogInputTooSmall(x);
        }
        unchecked {
            // Calculate the integer part of the logarithm and add it to the result and finally calculate y = x * 2^(-n).
            uint256 n = PRBMath.mostSignificantBit(x / SCALE);

            // The integer part of the logarithm as an unsigned 60.18-decimal fixed-point number. The operation can't overflow
            // because n is maximum 255 and SCALE is 1e18.
            result = n * SCALE;

            // This is y = x * 2^(-n).
            uint256 y = x >> n;

            // If y = 1, the fractional part is zero.
            if (y == SCALE) {
                return result;
            }

            // Calculate the fractional part via the iterative approximation.
            // The "delta >>= 1" part is equivalent to "delta /= 2", but shifting bits is faster.
            for (uint256 delta = HALF_SCALE; delta > 0; delta >>= 1) {
                y = (y * y) / SCALE;

                // Is y^2 > 2 and so in the range [2,4)?
                if (y >= 2 * SCALE) {
                    // Add the 2^(-m) factor to the logarithm.
                    result += delta;

                    // Corresponds to z/2 on Wikipedia.
                    y >>= 1;
                }
            }
        }
    }

    /// @notice Multiplies two unsigned 60.18-decimal fixed-point numbers together, returning a new unsigned 60.18-decimal
    /// fixed-point number.
    /// @dev See the documentation for the "PRBMath.mulDivFixedPoint" function.
    /// @param x The multiplicand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The multiplier as an unsigned 60.18-decimal fixed-point number.
    /// @return result The product as an unsigned 60.18-decimal fixed-point number.
    function mul(uint256 x, uint256 y) internal pure returns (uint256 result) {
        result = PRBMath.mulDivFixedPoint(x, y);
    }

    /// @notice Returns PI as an unsigned 60.18-decimal fixed-point number.
    function pi() internal pure returns (uint256 result) {
        result = 3_141592653589793238;
    }

    /// @notice Raises x to the power of y.
    ///
    /// @dev Based on the insight that x^y = 2^(log2(x) * y).
    ///
    /// Requirements:
    /// - All from "exp2", "log2" and "mul".
    ///
    /// Caveats:
    /// - All from "exp2", "log2" and "mul".
    /// - Assumes 0^0 is 1.
    ///
    /// @param x Number to raise to given power y, as an unsigned 60.18-decimal fixed-point number.
    /// @param y Exponent to raise x to, as an unsigned 60.18-decimal fixed-point number.
    /// @return result x raised to power y, as an unsigned 60.18-decimal fixed-point number.
    function pow(uint256 x, uint256 y) internal pure returns (uint256 result) {
        if (x == 0) {
            result = y == 0 ? SCALE : uint256(0);
        } else {
            result = exp2(mul(log2(x), y));
        }
    }

    /// @notice Raises x (unsigned 60.18-decimal fixed-point number) to the power of y (basic unsigned integer) using the
    /// famous algorithm "exponentiation by squaring".
    ///
    /// @dev See https://en.wikipedia.org/wiki/Exponentiation_by_squaring
    ///
    /// Requirements:
    /// - The result must fit within MAX_UD60x18.
    ///
    /// Caveats:
    /// - All from "mul".
    /// - Assumes 0^0 is 1.
    ///
    /// @param x The base as an unsigned 60.18-decimal fixed-point number.
    /// @param y The exponent as an uint256.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function powu(uint256 x, uint256 y) internal pure returns (uint256 result) {
        // Calculate the first iteration of the loop in advance.
        result = y & 1 > 0 ? x : SCALE;

        // Equivalent to "for(y /= 2; y > 0; y /= 2)" but faster.
        for (y >>= 1; y > 0; y >>= 1) {
            x = PRBMath.mulDivFixedPoint(x, x);

            // Equivalent to "y % 2 == 1" but faster.
            if (y & 1 > 0) {
                result = PRBMath.mulDivFixedPoint(result, x);
            }
        }
    }

    /// @notice Returns 1 as an unsigned 60.18-decimal fixed-point number.
    function scale() internal pure returns (uint256 result) {
        result = SCALE;
    }

    /// @notice Calculates the square root of x, rounding down.
    /// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
    ///
    /// Requirements:
    /// - x must be less than MAX_UD60x18 / SCALE.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the square root.
    /// @return result The result as an unsigned 60.18-decimal fixed-point .
    function sqrt(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            if (x > MAX_UD60x18 / SCALE) {
                revert PRBMathUD60x18__SqrtOverflow(x);
            }
            // Multiply x by the SCALE to account for the factor of SCALE that is picked up when multiplying two unsigned
            // 60.18-decimal fixed-point numbers together (in this case, those two numbers are both the square root).
            result = PRBMath.sqrt(x * SCALE);
        }
    }

    /// @notice Converts a unsigned 60.18-decimal fixed-point number to basic integer form, rounding down in the process.
    /// @param x The unsigned 60.18-decimal fixed-point number to convert.
    /// @return result The same number in basic integer form.
    function toUint(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            result = x / SCALE;
        }
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

/// @notice Emitted when the result overflows uint256.
error PRBMath__MulDivFixedPointOverflow(uint256 prod1);

/// @notice Emitted when the result overflows uint256.
error PRBMath__MulDivOverflow(uint256 prod1, uint256 denominator);

/// @notice Emitted when one of the inputs is type(int256).min.
error PRBMath__MulDivSignedInputTooSmall();

/// @notice Emitted when the intermediary absolute result overflows int256.
error PRBMath__MulDivSignedOverflow(uint256 rAbs);

/// @notice Emitted when the input is MIN_SD59x18.
error PRBMathSD59x18__AbsInputTooSmall();

/// @notice Emitted when ceiling a number overflows SD59x18.
error PRBMathSD59x18__CeilOverflow(int256 x);

/// @notice Emitted when one of the inputs is MIN_SD59x18.
error PRBMathSD59x18__DivInputTooSmall();

/// @notice Emitted when one of the intermediary unsigned results overflows SD59x18.
error PRBMathSD59x18__DivOverflow(uint256 rAbs);

/// @notice Emitted when the input is greater than 133.084258667509499441.
error PRBMathSD59x18__ExpInputTooBig(int256 x);

/// @notice Emitted when the input is greater than 192.
error PRBMathSD59x18__Exp2InputTooBig(int256 x);

/// @notice Emitted when flooring a number underflows SD59x18.
error PRBMathSD59x18__FloorUnderflow(int256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format overflows SD59x18.
error PRBMathSD59x18__FromIntOverflow(int256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format underflows SD59x18.
error PRBMathSD59x18__FromIntUnderflow(int256 x);

/// @notice Emitted when the product of the inputs is negative.
error PRBMathSD59x18__GmNegativeProduct(int256 x, int256 y);

/// @notice Emitted when multiplying the inputs overflows SD59x18.
error PRBMathSD59x18__GmOverflow(int256 x, int256 y);

/// @notice Emitted when the input is less than or equal to zero.
error PRBMathSD59x18__LogInputTooSmall(int256 x);

/// @notice Emitted when one of the inputs is MIN_SD59x18.
error PRBMathSD59x18__MulInputTooSmall();

/// @notice Emitted when the intermediary absolute result overflows SD59x18.
error PRBMathSD59x18__MulOverflow(uint256 rAbs);

/// @notice Emitted when the intermediary absolute result overflows SD59x18.
error PRBMathSD59x18__PowuOverflow(uint256 rAbs);

/// @notice Emitted when the input is negative.
error PRBMathSD59x18__SqrtNegativeInput(int256 x);

/// @notice Emitted when the calculating the square root overflows SD59x18.
error PRBMathSD59x18__SqrtOverflow(int256 x);

/// @notice Emitted when addition overflows UD60x18.
error PRBMathUD60x18__AddOverflow(uint256 x, uint256 y);

/// @notice Emitted when ceiling a number overflows UD60x18.
error PRBMathUD60x18__CeilOverflow(uint256 x);

/// @notice Emitted when the input is greater than 133.084258667509499441.
error PRBMathUD60x18__ExpInputTooBig(uint256 x);

/// @notice Emitted when the input is greater than 192.
error PRBMathUD60x18__Exp2InputTooBig(uint256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format format overflows UD60x18.
error PRBMathUD60x18__FromUintOverflow(uint256 x);

/// @notice Emitted when multiplying the inputs overflows UD60x18.
error PRBMathUD60x18__GmOverflow(uint256 x, uint256 y);

/// @notice Emitted when the input is less than 1.
error PRBMathUD60x18__LogInputTooSmall(uint256 x);

/// @notice Emitted when the calculating the square root overflows UD60x18.
error PRBMathUD60x18__SqrtOverflow(uint256 x);

/// @notice Emitted when subtraction underflows UD60x18.
error PRBMathUD60x18__SubUnderflow(uint256 x, uint256 y);

/// @dev Common mathematical functions used in both PRBMathSD59x18 and PRBMathUD60x18. Note that this shared library
/// does not always assume the signed 59.18-decimal fixed-point or the unsigned 60.18-decimal fixed-point
/// representation. When it does not, it is explicitly mentioned in the NatSpec documentation.
library PRBMath {
    /// STRUCTS ///

    struct SD59x18 {
        int256 value;
    }

    struct UD60x18 {
        uint256 value;
    }

    /// STORAGE ///

    /// @dev How many trailing decimals can be represented.
    uint256 internal constant SCALE = 1e18;

    /// @dev Largest power of two divisor of SCALE.
    uint256 internal constant SCALE_LPOTD = 262144;

    /// @dev SCALE inverted mod 2^256.
    uint256 internal constant SCALE_INVERSE =
        78156646155174841979727994598816262306175212592076161876661_508869554232690281;

    /// FUNCTIONS ///

    /// @notice Calculates the binary exponent of x using the binary fraction method.
    /// @dev Has to use 192.64-bit fixed-point numbers.
    /// See https://ethereum.stackexchange.com/a/96594/24693.
    /// @param x The exponent as an unsigned 192.64-bit fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function exp2(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            // Start from 0.5 in the 192.64-bit fixed-point format.
            result = 0x800000000000000000000000000000000000000000000000;

            // Multiply the result by root(2, 2^-i) when the bit at position i is 1. None of the intermediary results overflows
            // because the initial result is 2^191 and all magic factors are less than 2^65.
            if (x & 0x8000000000000000 > 0) {
                result = (result * 0x16A09E667F3BCC909) >> 64;
            }
            if (x & 0x4000000000000000 > 0) {
                result = (result * 0x1306FE0A31B7152DF) >> 64;
            }
            if (x & 0x2000000000000000 > 0) {
                result = (result * 0x1172B83C7D517ADCE) >> 64;
            }
            if (x & 0x1000000000000000 > 0) {
                result = (result * 0x10B5586CF9890F62A) >> 64;
            }
            if (x & 0x800000000000000 > 0) {
                result = (result * 0x1059B0D31585743AE) >> 64;
            }
            if (x & 0x400000000000000 > 0) {
                result = (result * 0x102C9A3E778060EE7) >> 64;
            }
            if (x & 0x200000000000000 > 0) {
                result = (result * 0x10163DA9FB33356D8) >> 64;
            }
            if (x & 0x100000000000000 > 0) {
                result = (result * 0x100B1AFA5ABCBED61) >> 64;
            }
            if (x & 0x80000000000000 > 0) {
                result = (result * 0x10058C86DA1C09EA2) >> 64;
            }
            if (x & 0x40000000000000 > 0) {
                result = (result * 0x1002C605E2E8CEC50) >> 64;
            }
            if (x & 0x20000000000000 > 0) {
                result = (result * 0x100162F3904051FA1) >> 64;
            }
            if (x & 0x10000000000000 > 0) {
                result = (result * 0x1000B175EFFDC76BA) >> 64;
            }
            if (x & 0x8000000000000 > 0) {
                result = (result * 0x100058BA01FB9F96D) >> 64;
            }
            if (x & 0x4000000000000 > 0) {
                result = (result * 0x10002C5CC37DA9492) >> 64;
            }
            if (x & 0x2000000000000 > 0) {
                result = (result * 0x1000162E525EE0547) >> 64;
            }
            if (x & 0x1000000000000 > 0) {
                result = (result * 0x10000B17255775C04) >> 64;
            }
            if (x & 0x800000000000 > 0) {
                result = (result * 0x1000058B91B5BC9AE) >> 64;
            }
            if (x & 0x400000000000 > 0) {
                result = (result * 0x100002C5C89D5EC6D) >> 64;
            }
            if (x & 0x200000000000 > 0) {
                result = (result * 0x10000162E43F4F831) >> 64;
            }
            if (x & 0x100000000000 > 0) {
                result = (result * 0x100000B1721BCFC9A) >> 64;
            }
            if (x & 0x80000000000 > 0) {
                result = (result * 0x10000058B90CF1E6E) >> 64;
            }
            if (x & 0x40000000000 > 0) {
                result = (result * 0x1000002C5C863B73F) >> 64;
            }
            if (x & 0x20000000000 > 0) {
                result = (result * 0x100000162E430E5A2) >> 64;
            }
            if (x & 0x10000000000 > 0) {
                result = (result * 0x1000000B172183551) >> 64;
            }
            if (x & 0x8000000000 > 0) {
                result = (result * 0x100000058B90C0B49) >> 64;
            }
            if (x & 0x4000000000 > 0) {
                result = (result * 0x10000002C5C8601CC) >> 64;
            }
            if (x & 0x2000000000 > 0) {
                result = (result * 0x1000000162E42FFF0) >> 64;
            }
            if (x & 0x1000000000 > 0) {
                result = (result * 0x10000000B17217FBB) >> 64;
            }
            if (x & 0x800000000 > 0) {
                result = (result * 0x1000000058B90BFCE) >> 64;
            }
            if (x & 0x400000000 > 0) {
                result = (result * 0x100000002C5C85FE3) >> 64;
            }
            if (x & 0x200000000 > 0) {
                result = (result * 0x10000000162E42FF1) >> 64;
            }
            if (x & 0x100000000 > 0) {
                result = (result * 0x100000000B17217F8) >> 64;
            }
            if (x & 0x80000000 > 0) {
                result = (result * 0x10000000058B90BFC) >> 64;
            }
            if (x & 0x40000000 > 0) {
                result = (result * 0x1000000002C5C85FE) >> 64;
            }
            if (x & 0x20000000 > 0) {
                result = (result * 0x100000000162E42FF) >> 64;
            }
            if (x & 0x10000000 > 0) {
                result = (result * 0x1000000000B17217F) >> 64;
            }
            if (x & 0x8000000 > 0) {
                result = (result * 0x100000000058B90C0) >> 64;
            }
            if (x & 0x4000000 > 0) {
                result = (result * 0x10000000002C5C860) >> 64;
            }
            if (x & 0x2000000 > 0) {
                result = (result * 0x1000000000162E430) >> 64;
            }
            if (x & 0x1000000 > 0) {
                result = (result * 0x10000000000B17218) >> 64;
            }
            if (x & 0x800000 > 0) {
                result = (result * 0x1000000000058B90C) >> 64;
            }
            if (x & 0x400000 > 0) {
                result = (result * 0x100000000002C5C86) >> 64;
            }
            if (x & 0x200000 > 0) {
                result = (result * 0x10000000000162E43) >> 64;
            }
            if (x & 0x100000 > 0) {
                result = (result * 0x100000000000B1721) >> 64;
            }
            if (x & 0x80000 > 0) {
                result = (result * 0x10000000000058B91) >> 64;
            }
            if (x & 0x40000 > 0) {
                result = (result * 0x1000000000002C5C8) >> 64;
            }
            if (x & 0x20000 > 0) {
                result = (result * 0x100000000000162E4) >> 64;
            }
            if (x & 0x10000 > 0) {
                result = (result * 0x1000000000000B172) >> 64;
            }
            if (x & 0x8000 > 0) {
                result = (result * 0x100000000000058B9) >> 64;
            }
            if (x & 0x4000 > 0) {
                result = (result * 0x10000000000002C5D) >> 64;
            }
            if (x & 0x2000 > 0) {
                result = (result * 0x1000000000000162E) >> 64;
            }
            if (x & 0x1000 > 0) {
                result = (result * 0x10000000000000B17) >> 64;
            }
            if (x & 0x800 > 0) {
                result = (result * 0x1000000000000058C) >> 64;
            }
            if (x & 0x400 > 0) {
                result = (result * 0x100000000000002C6) >> 64;
            }
            if (x & 0x200 > 0) {
                result = (result * 0x10000000000000163) >> 64;
            }
            if (x & 0x100 > 0) {
                result = (result * 0x100000000000000B1) >> 64;
            }
            if (x & 0x80 > 0) {
                result = (result * 0x10000000000000059) >> 64;
            }
            if (x & 0x40 > 0) {
                result = (result * 0x1000000000000002C) >> 64;
            }
            if (x & 0x20 > 0) {
                result = (result * 0x10000000000000016) >> 64;
            }
            if (x & 0x10 > 0) {
                result = (result * 0x1000000000000000B) >> 64;
            }
            if (x & 0x8 > 0) {
                result = (result * 0x10000000000000006) >> 64;
            }
            if (x & 0x4 > 0) {
                result = (result * 0x10000000000000003) >> 64;
            }
            if (x & 0x2 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }
            if (x & 0x1 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }

            // We're doing two things at the same time:
            //
            //   1. Multiply the result by 2^n + 1, where "2^n" is the integer part and the one is added to account for
            //      the fact that we initially set the result to 0.5. This is accomplished by subtracting from 191
            //      rather than 192.
            //   2. Convert the result to the unsigned 60.18-decimal fixed-point format.
            //
            // This works because 2^(191-ip) = 2^ip / 2^191, where "ip" is the integer part "2^n".
            result *= SCALE;
            result >>= (191 - (x >> 64));
        }
    }

    /// @notice Finds the zero-based index of the first one in the binary representation of x.
    /// @dev See the note on msb in the "Find First Set" Wikipedia article https://en.wikipedia.org/wiki/Find_first_set
    /// @param x The uint256 number for which to find the index of the most significant bit.
    /// @return msb The index of the most significant bit as an uint256.
    function mostSignificantBit(uint256 x) internal pure returns (uint256 msb) {
        if (x >= 2**128) {
            x >>= 128;
            msb += 128;
        }
        if (x >= 2**64) {
            x >>= 64;
            msb += 64;
        }
        if (x >= 2**32) {
            x >>= 32;
            msb += 32;
        }
        if (x >= 2**16) {
            x >>= 16;
            msb += 16;
        }
        if (x >= 2**8) {
            x >>= 8;
            msb += 8;
        }
        if (x >= 2**4) {
            x >>= 4;
            msb += 4;
        }
        if (x >= 2**2) {
            x >>= 2;
            msb += 2;
        }
        if (x >= 2**1) {
            // No need to shift x any more.
            msb += 1;
        }
    }

    /// @notice Calculates floor(x*y÷denominator) with full precision.
    ///
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv.
    ///
    /// Requirements:
    /// - The denominator cannot be zero.
    /// - The result must fit within uint256.
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers.
    ///
    /// @param x The multiplicand as an uint256.
    /// @param y The multiplier as an uint256.
    /// @param denominator The divisor as an uint256.
    /// @return result The result as an uint256.
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
        // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2^256 + prod0.
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(x, y, not(0))
            prod0 := mul(x, y)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division.
        if (prod1 == 0) {
            unchecked {
                result = prod0 / denominator;
            }
            return result;
        }

        // Make sure the result is less than 2^256. Also prevents denominator == 0.
        if (prod1 >= denominator) {
            revert PRBMath__MulDivOverflow(prod1, denominator);
        }

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0].
        uint256 remainder;
        assembly {
            // Compute remainder using mulmod.
            remainder := mulmod(x, y, denominator)

            // Subtract 256 bit number from 512 bit number.
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
        // See https://cs.stackexchange.com/q/138556/92363.
        unchecked {
            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 lpotdod = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by lpotdod.
                denominator := div(denominator, lpotdod)

                // Divide [prod1 prod0] by lpotdod.
                prod0 := div(prod0, lpotdod)

                // Flip lpotdod such that it is 2^256 / lpotdod. If lpotdod is zero, then it becomes one.
                lpotdod := add(div(sub(0, lpotdod), lpotdod), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * lpotdod;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /// @notice Calculates floor(x*y÷1e18) with full precision.
    ///
    /// @dev Variant of "mulDiv" with constant folding, i.e. in which the denominator is always 1e18. Before returning the
    /// final result, we add 1 if (x * y) % SCALE >= HALF_SCALE. Without this, 6.6e-19 would be truncated to 0 instead of
    /// being rounded to 1e-18.  See "Listing 6" and text above it at https://accu.org/index.php/journals/1717.
    ///
    /// Requirements:
    /// - The result must fit within uint256.
    ///
    /// Caveats:
    /// - The body is purposely left uncommented; see the NatSpec comments in "PRBMath.mulDiv" to understand how this works.
    /// - It is assumed that the result can never be type(uint256).max when x and y solve the following two equations:
    ///     1. x * y = type(uint256).max * SCALE
    ///     2. (x * y) % SCALE >= SCALE / 2
    ///
    /// @param x The multiplicand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The multiplier as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function mulDivFixedPoint(uint256 x, uint256 y) internal pure returns (uint256 result) {
        uint256 prod0;
        uint256 prod1;
        assembly {
            let mm := mulmod(x, y, not(0))
            prod0 := mul(x, y)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        if (prod1 >= SCALE) {
            revert PRBMath__MulDivFixedPointOverflow(prod1);
        }

        uint256 remainder;
        uint256 roundUpUnit;
        assembly {
            remainder := mulmod(x, y, SCALE)
            roundUpUnit := gt(remainder, 499999999999999999)
        }

        if (prod1 == 0) {
            unchecked {
                result = (prod0 / SCALE) + roundUpUnit;
                return result;
            }
        }

        assembly {
            result := add(
                mul(
                    or(
                        div(sub(prod0, remainder), SCALE_LPOTD),
                        mul(sub(prod1, gt(remainder, prod0)), add(div(sub(0, SCALE_LPOTD), SCALE_LPOTD), 1))
                    ),
                    SCALE_INVERSE
                ),
                roundUpUnit
            )
        }
    }

    /// @notice Calculates floor(x*y÷denominator) with full precision.
    ///
    /// @dev An extension of "mulDiv" for signed numbers. Works by computing the signs and the absolute values separately.
    ///
    /// Requirements:
    /// - None of the inputs can be type(int256).min.
    /// - The result must fit within int256.
    ///
    /// @param x The multiplicand as an int256.
    /// @param y The multiplier as an int256.
    /// @param denominator The divisor as an int256.
    /// @return result The result as an int256.
    function mulDivSigned(
        int256 x,
        int256 y,
        int256 denominator
    ) internal pure returns (int256 result) {
        if (x == type(int256).min || y == type(int256).min || denominator == type(int256).min) {
            revert PRBMath__MulDivSignedInputTooSmall();
        }

        // Get hold of the absolute values of x, y and the denominator.
        uint256 ax;
        uint256 ay;
        uint256 ad;
        unchecked {
            ax = x < 0 ? uint256(-x) : uint256(x);
            ay = y < 0 ? uint256(-y) : uint256(y);
            ad = denominator < 0 ? uint256(-denominator) : uint256(denominator);
        }

        // Compute the absolute value of (x*y)÷denominator. The result must fit within int256.
        uint256 rAbs = mulDiv(ax, ay, ad);
        if (rAbs > uint256(type(int256).max)) {
            revert PRBMath__MulDivSignedOverflow(rAbs);
        }

        // Get the signs of x, y and the denominator.
        uint256 sx;
        uint256 sy;
        uint256 sd;
        assembly {
            sx := sgt(x, sub(0, 1))
            sy := sgt(y, sub(0, 1))
            sd := sgt(denominator, sub(0, 1))
        }

        // XOR over sx, sy and sd. This is checking whether there are one or three negative signs in the inputs.
        // If yes, the result should be negative.
        result = sx ^ sy ^ sd == 0 ? -int256(rAbs) : int256(rAbs);
    }

    /// @notice Calculates the square root of x, rounding down.
    /// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers.
    ///
    /// @param x The uint256 number for which to calculate the square root.
    /// @return result The result as an uint256.
    function sqrt(uint256 x) internal pure returns (uint256 result) {
        if (x == 0) {
            return 0;
        }

        // Set the initial guess to the closest power of two that is higher than x.
        uint256 xAux = uint256(x);
        result = 1;
        if (xAux >= 0x100000000000000000000000000000000) {
            xAux >>= 128;
            result <<= 64;
        }
        if (xAux >= 0x10000000000000000) {
            xAux >>= 64;
            result <<= 32;
        }
        if (xAux >= 0x100000000) {
            xAux >>= 32;
            result <<= 16;
        }
        if (xAux >= 0x10000) {
            xAux >>= 16;
            result <<= 8;
        }
        if (xAux >= 0x100) {
            xAux >>= 8;
            result <<= 4;
        }
        if (xAux >= 0x10) {
            xAux >>= 4;
            result <<= 2;
        }
        if (xAux >= 0x8) {
            result <<= 1;
        }

        // The operations can never overflow because the result is max 2^127 when it enters this block.
        unchecked {
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1; // Seven iterations should be enough
            uint256 roundedDownResult = x / result;
            return result >= roundedDownResult ? roundedDownResult : result;
        }
    }
}