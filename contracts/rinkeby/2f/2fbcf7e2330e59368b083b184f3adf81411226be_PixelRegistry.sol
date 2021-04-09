/**
 *Submitted for verification at Etherscan.io on 2021-04-08
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

contract Encoding {
    uint16 constant clearLow = 0xff00;
    uint16 constant clearHigh = 0x00ff;
    uint16 constant numShiftDigits = 8;
    uint16 constant MAX_ID = 25443;
    uint16 constant internal X_MAX = 100;  // 100 FLP per pixel
    uint16 constant internal Y_MAX = 100;  // 100 FLP per pixel

    function encode(uint16 x, uint16 y) external pure returns (uint16) {
        return _encode(x, y);
    }

    function decode(uint16 id) external pure returns (uint16, uint16) {
        return _decode(id);
    }

    function _encode(uint16 x, uint16 y) internal pure returns (uint16) {
        uint16 pixelId = ((x << numShiftDigits) & clearLow) | (y & clearHigh);
        return pixelId;
    }

    // Not every decode pair of values are valid. (x, y) can be out of range.
    function _decode(uint16 id) internal pure returns (uint16, uint16) {
        require(_isIdValid(id), "The id is invalid!");
        uint16 x = (id & clearLow) >> numShiftDigits;
        uint16 y = id & clearHigh;
        require(x < X_MAX && y < Y_MAX, "(x, y) is out of range.");
        return (x, y);
    }

    function _isIdValid(uint16 id) internal pure returns(bool) {
        return id <= MAX_ID;
    }

}


contract PixelStorage {

    struct Pixel {
        uint16 _x;  // [0, 100)
        uint16 _y;  // [0, 100)
    }

    uint256 constant internal DEFAULT_PIXEL_PRICE = 100;  // 100 FLP per pixel
    uint16 constant internal MAX_PIXEL_SUPPLY = 10000;
    uint16 constant internal FOUR_AJACENT_PIXEL = 4;
    uint16 constant internal EIGHT_AJACENT_PIXEL = 8;

    mapping(address => uint) internal latestPing;
    mapping(uint16 => string) internal _pixelMetadata;

    mapping(uint16 => bool) internal _xExist; // if a x coordinate exist
    mapping(uint16 => bool) internal _yExist; // if a y coordinate exist
    mapping(uint16 => mapping(uint16 => bool)) internal _xyExist; // if a (x, y) coordinate exist

    // A mapping from pixelId to pixelPrice
    // pixelPrice can be the min between minimum price at 100FLP or the median
    // of last transaction prices of the 8 immediate surrounding pixels in FLP.
    // An oracle to read FLP price will be necessary.
    mapping(uint16 => uint256) internal _pixelPrices;
}


interface IPixelRegistry {

    function generatePixel(uint16 x, uint16 y) external;
    function generateManyPixel(uint16[] memory x, uint16[] memory y) external;
    function pixelExist(uint16 x, uint16 y) external view returns (bool);
    function getTotalPixelSupply() external view returns(uint16);
    function getRemainingPixelSupply() external view returns(uint16);

    function removePixel(uint16 x, uint16 y) external;  // What to do with it?

    function getPixelId(uint16 x, uint16 y) external view returns(uint16);
    function getPixelXY(uint16 id) external view returns(uint16, uint16);
    function getPixelIndex(uint16 x, uint16 y) external view returns(uint256);

    function getAdjacentPixel(uint16 x, uint16 y, uint16 n) external view returns(uint16[] memory, uint16[] memory, uint256);
    function getPixelMetadata(uint16 x, uint16 y) external view returns(string memory);

    function convert(uint16 x, uint16 y) external;

    // Transaction-related functions.
    function getPixelPrice(uint16 x, uint16 y) external view returns(uint256);

    // Role-related functions

    // security-related functions
    function ping() external;

    event GeneratePixel(uint16 x, uint16 y);
    event GenerateManyPixel(uint16[] x, uint16[] y);
    event Convert(uint16 x, uint16 y);

}


contract PixelRegistry is Encoding, IPixelRegistry, PixelStorage {


    // TODO: think about a better verb for minting a pixel.
    // It changes the status from existing on board yet not owned by
    // any owner to being owned by an owner
    // This is used if a unit frame is purchased from ground up.
    // A pixel, as an intermediary, is created.

    // Total number of pixels have been minted.
    uint16 private _totalPixelSupply;
    uint256 private _pixelIndex;

    // TOOD: onlyOwner
    // TODO: to implement owner
    function generatePixel(uint16 x, uint16 y) public override {
        // require(msg.sender == _owner);
        _generatePixel(x, y);
    }

    function generateManyPixel(uint16[] memory x, uint16[] memory y) public override {
        for (uint256 i = 0; i < x.length; i++) {
            _generatePixel(x[i], y[i]);
        }
    }

    function pixelExist(uint16 x, uint16 y) public view override returns(bool) {
        return _pixelExist(x, y);
    }

    // Getter for _totalPixelSupply;
    function getTotalPixelSupply() public view override returns(uint16) {
        return _totalPixelSupply;
    }

    // Getter for _totalPixelSupply;
    function getRemainingPixelSupply() public view override returns(uint16) {
        return MAX_PIXEL_SUPPLY - _totalPixelSupply;
    }

    function getPixelId(uint16 x, uint16 y) public pure override returns(uint16) {
        return _encode(x, y);
    }

    function getPixelXY(uint16 id) public pure override returns(uint16, uint16) {
        return _decode(id);
    }

    function getPixelIndex(uint16 x, uint16 y) external view override returns(uint256) {
        return _getPixelIndex(x, y);
    }

    function getAdjacentPixel(uint16 x, uint16 y, uint16 n) external pure override returns(uint16[] memory, uint16[] memory, uint256) {
        require(n == 4 || n == 8, "Only 4 or 8 adjacent pixels.");
        if (n == 4) {
            return _getAdjacent4Pixel(x, y);
        } else {
            return _getAdjacent8Pixel(x, y);
        }
    }

    function getPixelPrice(uint16 x, uint16 y) external view override returns(uint256) {
        return _getPixelPrice(x, y);
    }

    // Although pixels may not be initialized to exist, some of them
    // may still have graphs on them, to form the background theme.
    // Think more about it.
    function getPixelMetadata(uint16 x, uint16 y) external view override returns (string memory) {
        return _getPixelMetadata(_getPixelId(x, y));
    }

    function convert(uint16 x, uint16 y) external override {
        // Convert a pixel into a frame.
        // May need a bridge or a type variable.
    }

    function _convert(uint16 x, uint16 y) internal {

    }

    // TODO: does all generator need to return true?
    function _generatePixel(uint16 x, uint16 y) internal returns(bool) {
        require(_isPixelValid(x, y), "Point is invalid!");
        require(!_pixelExist(x, y), "The pixel has been generated!");

        _xExist[x] = true;
        _yExist[y] = true;
        _xyExist[x][y] = true;

        _totalPixelSupply++;
        _pixelIndex++;

        _setPixelPrice(x, y);

        emit GeneratePixel(x, y);

        return true;
    }

    function removePixel(uint16 x, uint16 y) public pure override {
        _removePixel(x, y);
    }

    function _removePixel(uint16 x, uint16 y) internal pure returns(bool) {
        //TODO: remove a pixel
        if (x | y > 0) {
            return true;
        } else {
            return false;
        }
    }

    // Id is used internally for reference.
    function _getPixelId(uint16 x, uint16 y) internal pure returns(uint16) {
        return _encode(x, y);
    }

    // decode an id to coordinates
    function _getPixelXY(uint16 id) internal pure returns(uint16, uint16) {
        return _decode(id);
    }

    // TODO: need further improvements
    // an index is an non-decreasing sequence of integers representing
    // the cumulative pixels that have ever been generated. It can be much larger
    // than the total supply, since pixels can be generated anew or from existing
    // frames.
    function _getPixelIndex(uint16 x, uint16 y) internal view returns(uint256) {
        require(x | y > 0);
        return _pixelIndex;
    }

    // a one-time checker to make sure coordinates of any given point are valid.
    // Here x < X_MAX also implies, only points inside the board, not on top and
    // right edges are valid, i.e., (, 100) is invalid, (100, ) is invalid,
    // although they can be the top right corner of a pixel, but these points
    // are not selectable, i.e., not the points we can work with.
    // Whenever we say if a pixel or a frame is valid, it implies this pixel or
    // frame has not been created. Once it's been created, it must be valid,
    // otherwise, it won't be created.
    function _isPixelValid(uint16 x, uint16 y) internal pure returns(bool) {
        if (x < X_MAX && y < Y_MAX) {
            return true;
        } else {
            return false;
        }
    }

    // Likewise, many pixels are created as intermediaries to
    // create a frame from ground up.
    // TODO: double check if this function and the previous one is necessary.
    // Intuitively, yes; habitually, yes, but practically, maybe not.
    function _generateManyPixel(uint16[] memory x, uint16[] memory y) internal returns(bool) {
        require(x.length == y.length, "X and Y must have the same length.");
        require(x.length < 40, "Cannot generate more than 40 pixels at once.");
        for (uint16 i = 0; i < x.length; i++) {
              _generatePixel(x[i], y[i]);
        }
        return true;
    }

    // NOTE: a pixel exists for two reasons:
    // 1. prior to the creation of a frame
    // 2. posterior to the demolishment of a frame, i.e.,
    // once a frame is demolished, it will become the ownerless status.
    // An ownerless pixel can be purchased at a price to be determined later.

    // TODO:
    function _getPrice(Pixel memory pixel) internal returns(uint256) {
        // require: 1. existence of this pixel
        // 1 implies this pixel used to belong to a frame
        // The price of it can be determined with a few mechanisms:
        // 1. Gaussian average; 2. previous price at discount
    }

    // Check if a pixel has existed, i.e., if it has been generated.
    function _pixelExist(uint16 x, uint16 y) internal view returns(bool) {
        return _xyExist[x][y];
    }

    function _getPixelMetadata(uint16 pixelId) internal view returns (string memory) {
        return _pixelMetadata[pixelId];
    }

    // This setter is only called when someone wants to buy an unused pixel.
    // If a pixel has been used, and is coming from being demolished, the price
    // would be also calling this function, i.e., median of the prices of
    // surrounding pixels.
    function _setPixelPrice(uint16 x, uint16 y) internal {
        require(_pixelExist(x, y), "This pixel has not been created.");

        uint16[] memory xs;
        uint16[] memory ys;
        uint256 counter;
        uint256 sumOfPrices;

        (xs, ys, counter) = _getAdjacent8Pixel(x, y);

        for (uint16 i = 0; i < counter; i++) {
            sumOfPrices += _getPixelPrice(xs[i], ys[i]);
        }

        uint256 newPrice = sumOfPrices/xs.length > DEFAULT_PIXEL_PRICE ? DEFAULT_PIXEL_PRICE : sumOfPrices/xs.length;

        uint16 pixelId = _getPixelId(x, y);
        _pixelPrices[pixelId] = newPrice;
    }

    // These two functions can be combined.
    function _getAdjacent4Pixel(uint16 x, uint16 y) internal pure returns(uint16[] memory, uint16[] memory, uint256) {
        int16 xMin = x > 0 ? int16(-1) : int16(0);
        int16 xMax = x < 99 ? int16(1) : int16(0);
        int16 yMin = y > 0 ? int16(-1) : int16(0);
        int16 yMax = y < 99 ? int16(1) : int16(0);

        uint16[] memory xs = new uint16[](FOUR_AJACENT_PIXEL);
        uint16[] memory ys = new uint16[](FOUR_AJACENT_PIXEL);
        uint256 counter;

        for (int16 dx = xMin; dx <= xMax; dx++) {
            for (int16 dy = yMin; dy <= yMax; dy++) {
                if (dx | dy != 0 && dx * dy == 0) {
                    xs[counter] = uint16(int16(x) + dx);
                    ys[counter] = uint16(int16(y) + dy);
                    counter += 1;
                }
            }
        }

        return (xs, ys, counter);
    }

    function _getAdjacent8Pixel(uint16 x, uint16 y) internal pure returns(uint16[] memory, uint16[] memory, uint256) {
        int16 xMin = x > 0 ? int16(-1) : int16(0);
        int16 xMax = x < 99 ? int16(1) : int16(0);
        int16 yMin = y > 0 ? int16(-1) : int16(0);
        int16 yMax = y < 99 ? int16(1) : int16(0);

        uint16[] memory xs = new uint16[](EIGHT_AJACENT_PIXEL);
        uint16[] memory ys = new uint16[](EIGHT_AJACENT_PIXEL);
        uint256 counter;

        for (int16 dx = xMin; dx <= xMax; dx++) {
            for (int16 dy = yMin; dy <= yMax; dy++) {
                if (dx | dy != 0) {
                    xs[counter] = uint16(int16(x) + dx);
                    ys[counter] = uint16(int16(y) + dy);
                    counter += 1;
                }
            }
        }

        return (xs, ys, counter);
    }

    // This is to get the latest prices of surrounding pixels. Although unsold
    // pixels may have a different prices in their own transaction, but in
    // this function, we use the default price for unsold ones.
    function _getPixelPrice(uint16 x, uint16 y) internal view returns(uint256) {
        uint16 pixelId = _getPixelId(x, y);
        if(_pixelExist(x, y)) {
            return _pixelPrices[pixelId];
        } else {
            return DEFAULT_PIXEL_PRICE;
        }
    }

    function ping() public override {}

    // Role-related functions
    // function _isUpdateAuthorized(address operator, uint256 estateId) internal view returns (bool) {
    //   address owner = ownerOf(estateId);

    //   return isApprovedOrOwner(operator, estateId)
    //     || updateOperator[estateId] == operator
    //     || updateManager[owner][operator];
    // }

    // function _isLandUpdateAuthorized(
    //   address operator,
    //   uint256 estateId,
    //   uint256 landId)
    //   internal returns (bool) {
    //   return _isUpdateAuthorized(operator, estateId) || registry.updateOperator(landId) == operator;
    // }

}