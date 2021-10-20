// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IMapBase.sol";

pragma solidity ^0.8.0;


/// @title MapBase
/// @notice This contract hosts the data for the Jay Pegs Auto Mart courtesy roadmaps for 2007 Kia Sedona Owners
/// @notice This contract is experimental and has not been audited. Use at your own risk.

contract MapBase is Ownable, IMapBase {

    struct ParcelInfo {
        string viewBox;
        string[] polygonWater;
        string[] polygonGAAL;
        string[] polygonFL;
        string[] cities;
        string[] polylineRoad1;
        string[] polylineRoad2;
        string[] cityDots;
        string[] cityNames;
        string[] waterNames;
        string paths;
    }

    ParcelInfo[] internal parcelInfo;

    string[] private fillColors = [
        "#9ec7f3",
        "#f7d3aa",
        "#ffffe0",
        "#ff0",
        "#ffc0cb",
        "#ee82ee",
        "#f08080",
        "#ffd700",
        "#98fb98",
        "#7fffD4",
        "#00bfff"
        "#daa520"
    ];

    string[] private strokeColors = [
        "#4090d0",
        "#a08070",
        "#d0c0a0",
        "#f00",
        "#ff69b4",
        "#808080",
        "#f00",
        "#ff8c00",
        "#32cd32",
        "#40e0d0",
        "#1e90ff",
        "#ffdead"
    ];

    string[] private roadColors = [
        "#e0584e",
        "#004d00",
        "#000080",
        "#696969",
        "#69f420",
        "#420420"
    ];

    string[] private dona = [
        '<polygon points="-16.707 -14.22-18.96 -14.43-19.747 -14.663-20 -15.187-19.873 -16.04-19.677 -16.317-18.873 -17.043-16.64 -17.83-16.247 -17.973-13.657 -19.487-11.75 -20-5.263 -19.98-4.583 -19.86-4.303 -19.63-3.223 -17.757-3.02 -16.213-3.15 -14.837-3.75 -14.583-4.163 -14.573-7.097 -14.387-7.6 -14.367-11.287 -14.263-14.933 -14.163-16.707 -14.22" fill="',
        '"/><circle cx="-15.75" cy="-14.5" r="1.55" fill="#FFF"/><circle cx="-15.75" cy="-14.5" r="1" fill="none" stroke="#000" stroke-width=".5"/><circle cx="-6.25" cy="-14.5" r="1.55" fill="#FFF"/><circle cx="-6.25" cy="-14.5" r="1" fill="none" stroke="#000" stroke-width=".5"/><animateMotion dur="'
        's" begin="',
        's" path="',
        '" repeatCount="indefinite"/>'  
    ];

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function addParcel (
        string memory _viewBox,
        string[] memory _polygonWater,
        string[] memory _polygonGAAL,
        string[] memory _polygonFL,
        string[] memory _cities,
        string[] memory _polylineRoad1,
        string[] memory _polylineRoad2,
        string[] memory _cityDots,
        string[] memory _cityNames,
        string[] memory _waterNames,
        string memory _paths
    ) public onlyOwner {
        parcelInfo.push(
            ParcelInfo({
                viewBox: _viewBox,
                polygonWater: _polygonWater,
                polygonGAAL: _polygonGAAL,
                polygonFL: _polygonFL,
                cities: _cities,
                polylineRoad1: _polylineRoad1,
                polylineRoad2: _polylineRoad2,
                cityDots: _cityDots,
                cityNames: _cityNames,
                waterNames: _waterNames,
                paths: _paths
            })
        );
    }

    function updateParcel (
        uint256 parcelID,
        string[] memory _polygonWater,
        string[] memory _polygonGAAL,
        string[] memory _polygonFL,
        string[] memory _cities,
        string[] memory _polylineRoad1,
        string[] memory _polylineRoad2,
        string[] memory _cityDots,
        string[] memory _cityNames,
        string[] memory _waterNames,
        string memory _paths
    ) public onlyOwner {
        ParcelInfo storage parcel = parcelInfo[parcelID];

        parcel.polygonWater = _polygonWater;
        parcel.polygonGAAL = _polygonGAAL;
        parcel.polygonFL = _polygonFL;
        parcel.cities =  _cities;
        parcel.polylineRoad1 = _polylineRoad1;
        parcel.polylineRoad2 = _polylineRoad2;
        parcel.cityDots = _cityDots;
        parcel.cityNames =  _cityNames;
        parcel.waterNames = _waterNames;
        parcel.paths = _paths;
    }

    function parcelLength() external view override  returns (uint256) {
        return parcelInfo.length;
    }

    function getParcel(uint256 _tokenId, uint256 _randSeed) public view override returns (uint256){
        return random(string(abi.encodePacked(_randSeed, toString(_tokenId)))) % parcelInfo.length;
    }

    function getViewBox(uint256 _tokenId, uint256 _randSeed) public view override returns (string memory){
        uint256 parcelId = getParcel(_tokenId, _randSeed);
        ParcelInfo storage parcel = parcelInfo[parcelId];
        return parcel.viewBox;
    }

    function getColorCode(uint256 _tokenId, uint256 _randSeed, string memory _keyPrefix) internal view returns (uint256){
        return random(string(abi.encodePacked(_randSeed, _keyPrefix, toString(_tokenId)))) % fillColors.length;
    }

    function getRoadColor(uint256 _tokenId, uint256 _randSeed, string memory _keyPrefix) internal view returns (string memory){
        uint256 rand = random(string(abi.encodePacked(_randSeed, _keyPrefix, toString(_tokenId))));
        return roadColors[rand % roadColors.length];
    }

    function readPolygons(uint256 _tokenId, uint256 _randSeed) external view override returns (string memory) {
        
        uint256 parcelId = getParcel(_tokenId, _randSeed);
        ParcelInfo storage parcel = parcelInfo[parcelId];

        string memory buildPolygons;
        
        uint256 colorWater = getColorCode(_tokenId, _randSeed, "WATER");
        uint256 colorGAAL = getColorCode(_tokenId, _randSeed, "GAAL");
        uint256 colorFL = getColorCode(_tokenId, _randSeed, "FLORIDA");
        uint256 colorCity = getColorCode(_tokenId, _randSeed, "CITIES");

        // lay down sea in first position
        buildPolygons =  string(abi.encodePacked('<polygon points="', parcel.polygonWater[0], '" fill="', fillColors[colorWater], '" stroke="', strokeColors[colorWater], '"/>'));

        for(uint256 i=0; i<parcel.polygonGAAL.length; i++){
            buildPolygons =  string(abi.encodePacked(buildPolygons, '<polygon points="', parcel.polygonGAAL[i], '" fill="', fillColors[colorGAAL], '" stroke="', strokeColors[colorGAAL], '"/>'));
        }

        for(uint256 i=0; i<parcel.polygonFL.length; i++){
            buildPolygons =  string(abi.encodePacked(buildPolygons, '<polygon points="', parcel.polygonFL[i], '" fill="', fillColors[colorFL], '" stroke="', strokeColors[colorFL], '"/>'));
        }

        //All other water should be listed from array position 1 onward
        for(uint256 i=1; i<parcel.polygonWater.length; i++){
            buildPolygons =  string(abi.encodePacked(buildPolygons, '<polygon points="', parcel.polygonWater[i], '" fill="', fillColors[colorWater], '" stroke="', strokeColors[colorWater], '"/>'));
        }

        for(uint256 i=0; i<parcel.cities.length; i++){
            buildPolygons =  string(abi.encodePacked(buildPolygons, '<polygon points="', parcel.cities[i], '" fill="', fillColors[colorCity], '" stroke="', strokeColors[colorCity], '"/>'));
        }

        return buildPolygons;
    }

    function readPolylines(uint256 _tokenId, uint256 _randSeed) external view override returns (string memory) {
        
        uint256 parcelId = getParcel(_tokenId, _randSeed);
        ParcelInfo storage parcel = parcelInfo[parcelId];

        string memory buildPolylines;
        string memory colorRoad1 = getRoadColor(_tokenId, _randSeed, "HIGHWAYS");
        string memory colorRoad2 = getRoadColor(_tokenId, _randSeed, "COUNTRYROADS");

        for(uint256 i=0; i<parcel.polylineRoad1.length; i++){
            buildPolylines = string(abi.encodePacked(buildPolylines, '<polyline points="', parcel.polylineRoad1[i], '" fill="none" stroke="', colorRoad1, '"/>'));
        }

        for(uint256 i=0; i<parcel.polylineRoad2.length; i++){
            buildPolylines = string(abi.encodePacked(buildPolylines, '<polyline points="', parcel.polylineRoad2[i], '" fill="none" stroke="', colorRoad2, '"/>'));
        }
        
        return buildPolylines;
    }

    function readDots(uint256 _tokenId, uint256 _randSeed) external view override returns (string memory) {
        
        uint256 parcelId = getParcel(_tokenId, _randSeed);
        ParcelInfo storage parcel = parcelInfo[parcelId];

        string memory buildDots;

        for(uint256 i=0; i<parcel.cityDots.length; i++){
            buildDots = string(abi.encodePacked(buildDots, parcel.cityDots[i]));
        }

        return buildDots;
    }

    function readText(uint256 _tokenId, uint256 _randSeed) external view override returns (string memory) {
        
        uint256 parcelId = getParcel(_tokenId, _randSeed);
        ParcelInfo storage parcel = parcelInfo[parcelId];

        string memory buildText;

        for(uint256 i=0; i<parcel.cityNames.length; i++){
            buildText = string(abi.encodePacked(parcel.cityNames[i]));
        }

        uint256 colorWater = getColorCode(_tokenId, _randSeed, "WATER");

        for(uint256 i=0; i<parcel.waterNames.length; i++){
            buildText = string(abi.encodePacked(buildText, '<text fill="', strokeColors[colorWater], parcel.waterNames[i]));
        }

        return buildText;
    }

    function readDonas(uint256 _tokenId, uint256 _randSeed, uint256 donaPower) external view override returns (string memory) {
        
        uint256 parcelId = getParcel(_tokenId, _randSeed);
        ParcelInfo storage parcel = parcelInfo[parcelId];

        string memory buildDrivingDonas;

        for (uint256 i=0; i<donaPower; i++) {
            buildDrivingDonas = string(abi.encodePacked(dona[0]));
            
            if (donaPower > 5){
                if (i == 9) {
                    buildDrivingDonas = string(abi.encodePacked(buildDrivingDonas, getColorCode(_tokenId, _randSeed, toString(i + 2007)), dona[1], toString(5), dona[2], donaPower, dona[3], parcel.paths, dona[4]));
                } else {
                    buildDrivingDonas = string(abi.encodePacked(buildDrivingDonas, getColorCode(_tokenId, _randSeed, toString(i + 2007)), dona[1], toString(15), dona[2], donaPower, dona[3], parcel.paths, dona[4]));
                }
            } else {
                buildDrivingDonas = string(abi.encodePacked(buildDrivingDonas, getColorCode(_tokenId, _randSeed, "KIASEDONA"), dona[1], toString(10), dona[2], donaPower, dona[3], parcel.paths, dona[4]));
            }
        }
        
        return buildDrivingDonas;
    }

    function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
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

    constructor(){}
    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of MapBase declared to support ERC165 detection.
 */
interface IMapBase {

    function parcelLength() external view returns (uint256);

    function getParcel(uint256 _tokenId, uint256 _randSeed) external view returns (uint256);

    function getViewBox(uint256 _tokenId, uint256 _randSeed) external view returns (string memory);

    function readPolygons(uint256 _tokenId, uint256 _randSeed) external view returns (string memory);

    function readPolylines(uint256 _tokenId, uint256 _randSeed) external view returns (string memory);

    function readDots(uint256 _tokenId, uint256 _randSeed) external view returns (string memory);

    function readText(uint256 _tokenId, uint256 _randSeed) external view returns (string memory);

    function readDonas(uint256 _tokenId, uint256 _randSeed, uint256 _donaPower) external view returns (string memory);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}