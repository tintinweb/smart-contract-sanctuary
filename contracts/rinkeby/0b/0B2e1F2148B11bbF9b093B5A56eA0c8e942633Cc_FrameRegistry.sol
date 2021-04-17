/**
 *Submitted for verification at Etherscan.io on 2021-04-16
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

contract Algos {
    // TODO: check conditions. It may not be safe.
    function _sqrt(uint16 x) internal pure returns (uint16) {
        uint16 z = (x + 1) / 2;
        uint16 y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        return y;
    }
}

contract Encoding {
    uint16 constant clearLow = 0xff00;
    uint16 constant clearHigh = 0x00ff;
    uint16 constant numShiftDigits = 8;
    uint16 constant MAX_ID = 25443;
    uint16 constant private X_MAX = 100;  // 100 FLP per pixel
    uint16 constant private Y_MAX = 100;  // 100 FLP per pixel

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
        require(_isValidId(id), "The id is invalid!");
        uint16 x = (id & clearLow) >> numShiftDigits;
        uint16 y = id & clearHigh;
        require(x < X_MAX && y < Y_MAX, "(x, y) is out of range.");
        return (x, y);
    }

    function _isValidId(uint16 id) internal pure returns(bool) {
        return id <= MAX_ID;
    }

}

library EnumerableRangeSet {

    uint16 constant clearLow = 0xff00;
    uint16 constant clearHigh = 0x00ff;
    uint16 constant numShiftDigits = 8;
    uint16 constant MAX_ID = 25443;
    uint16 constant private X_MAX = 100;  // 100 FLP per pixel
    uint16 constant private Y_MAX = 100;  // 100 FLP per pixel

    struct Range {
        uint16 _start;
        uint16 _end;
    }

    struct RangeSet {
        Range[] _values;
        mapping(uint16 => uint256) _indexes;
    }

    function _encode(uint16 x, uint16 y) internal pure returns (uint16) {
        uint16 pixelId = ((x << numShiftDigits) & clearLow) | (y & clearHigh);
        return pixelId;
    }

    function _isValidId(uint16 id) internal pure returns(bool) {
        return id <= MAX_ID;
    }

    // Not every decode pair of values are valid. (x, y) can be out of range.
    function _decode(uint16 id) internal pure returns (uint16, uint16) {
        require(_isValidId(id), "The id is invalid!");
        uint16 x = (id & clearLow) >> numShiftDigits;
        uint16 y = id & clearHigh;
        require(x < X_MAX && y < Y_MAX, "(x, y) is out of range.");
        return (x, y);
    }

    function add(RangeSet storage rSet, Range memory rValue) internal returns(bool) {
        return _add(rSet, rValue);
    }

    function remove(RangeSet storage rSet, Range memory rValue) internal returns (bool) {
        return _remove(rSet, rValue);
    }

    function contains(RangeSet storage rSet, Range memory rValue) internal view returns (bool) {
        return _contains(rSet, rValue);
    }

    function length(RangeSet storage rSet) internal view returns (uint256) {
        return _length(rSet);
    }

    function at(RangeSet storage rSet, uint256 index) internal view returns (Range memory) {
        return _at(rSet, index);
    }

    function overlap(RangeSet storage rSet, Range memory rValue) internal view returns(Range[] memory) {
        (Range[] memory ranges, uint16 counter) = _overlap(rSet, rValue);
        Range[] memory thisRange = new Range[](counter);
        for (uint16 i = 0; i < counter; i++) {
            thisRange[i] = ranges[i];
        }

        return thisRange;
    }

    function overlapAny(RangeSet storage rSet, Range memory rValue) internal view returns(bool) {
        return _overlapAny(rSet, rValue);
    }

    function getKeys(RangeSet storage rSet) internal view returns(Range[] memory) {
        return _keys(rSet);
    }

    function _keys(RangeSet storage rSet) internal view returns(Range[] memory) {
        return rSet._values;
    }

    function _add(RangeSet storage rSet, Range memory rValue) private returns (bool) {
        if (!_contains(rSet, rValue)) {
            rSet._values.push(rValue);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            uint16 rangeId = _encode(rValue._start, rValue._start);
            rSet._indexes[rangeId] = rSet._values.length;
            return true;
        } else {
            return false;
        }
    }

    // When frames merge, existing frame ranges may have to be removed.
    // The removing logic needs to check other mapping as well. it may not be
    // as simple as the logic implemented below.
    // TODO: improve the logics.
    // Removing a set of ranges is fine. Additional care is taken at
    // the mapping step. Therefore, the logic in this library is sound.
    function _remove(RangeSet storage rSet, Range memory rValue) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint16 rangeId = _encode(rValue._start, rValue._start);
        uint256 valueIndex = rSet._indexes[rangeId];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = rSet._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            Range memory lastvalue = rSet._values[lastIndex];
            uint16 lastFrameRangeId = _encode(rValue._start, rValue._start);

            // Move the last value to the index where the value to delete is
            rSet._values[toDeleteIndex] = lastvalue;

            // Update the index for the moved value
            rSet._indexes[lastFrameRangeId] = valueIndex; // Replace lastvalue's index to valueIndex

            // Delete the slot where the moved value was stored
            rSet._values.pop();

            // Delete the index for the deleted slot
            delete rSet._indexes[rangeId];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(RangeSet storage rSet, Range memory rValue) private view returns (bool) {
        uint16 rangeId = _encode(rValue._start, rValue._start);
        return rSet._indexes[rangeId] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(RangeSet storage rSet) private view returns (uint256) {
        return rSet._values.length;
    }

    function _at(RangeSet storage rSet, uint256 index) private view returns (Range memory) {
        require(rSet._values.length > index, "EnumerableSet: index out of bounds");
        return rSet._values[index];
    }

    function _overlapAny(RangeSet storage rSet, Range memory rValue) private view returns (bool) {
        Range memory thisRange;
        for (uint256 i = 0; i < rSet._values.length; i++) {
            thisRange = rSet._values[i];
            if (_checkRangeOverlapping(thisRange, rValue)) {
                return true;
            }
        }
        return false;
    }

    function _overlap(RangeSet storage rSet, Range memory rValue) internal view returns(Range[] memory, uint16) {
        require(_overlapAny(rSet, rValue));
        Range memory thisRange;
        Range[] memory result = new Range[](rSet._values.length);
        uint16 counter;
        for (uint256 i = 0; i < rSet._values.length; i++) {
            thisRange = rSet._values[i];
            if (_checkRangeOverlapping(thisRange, rValue)) {
                result[counter] = thisRange;
                counter++;
            }
        }
        return (result, counter);
    }

    function _checkRangeOverlapping(Range memory range1, Range memory range2) internal pure returns(bool) {
        if (range1._end > range2._start && range1._end <= range2._end) return true;
        if (range2._end > range1._start && range2._end <= range1._end) return true;
        return false;
    }
}

contract FrameStorage {

    using EnumerableRangeSet for EnumerableRangeSet.RangeSet;
    using EnumerableRangeSet for EnumerableRangeSet.Range;

    // What is a finger print?
    bytes4 internal constant InterfaceId_VerifyFingerprint = bytes4(
        keccak256("verifyFingerprint(uint256,bytes)")
    );

    // From Estate to list of owned LAND ids (LANDs)
    // Is this necessary? no, it's clearly all pixels in it.
    // The pixels must have all been intialized given the auction event.
    // This might be useful, however, the mapped data structure should be
    // a set, which will be making checking trivial.
    mapping(uint256 => uint256[]) public framePixelIds;

    // frameId to Frame struct objects
    mapping(uint16 => bool) internal _frameExist;

    // Metadata of the Frame
    mapping(uint16 => string) internal _frameData;

    // frameId onSale or not.
    mapping(uint16 => bool) internal _isOnSale;

    // TODO: create a set of Range
    // It can do:
    // 1. check if a new range is contained in the set;
    // 2. check if a new range overlapps with any existing range;
    // 3. add a new range to the set, if the set does not already contain it
    // 4. length
    // 5. at, contains, remove
    // 6. Check two ranges at a time.

    // encode a range to an uint
    // create enumerableSet for uint
    // add some additional function to it

    EnumerableRangeSet.RangeSet internal _xRangeIds;
    mapping(uint16 => EnumerableRangeSet.RangeSet) internal _xRangeIdToYRangeIds;
    mapping(uint16 => mapping(uint16 => bool)) internal _xyExists;
}

interface IFrameRegistry {

    struct Frame {
        uint16 _x1;
        uint16 _y1;
        uint16 _x2;
        uint16 _y2;
    }

    enum XoY {InX, InY}

    function generateFrame(uint16 x1, uint16 y1, uint16 x2, uint16 y2) external;
    function getFrameId(uint16 x1, uint16 y1, uint16 x2, uint16 y2) external pure returns(uint16);
    function getFrame(uint16 frameId) external returns(Frame memory);

    function merge(uint16 frameId1, uint16 frameId2) external returns(bool);

    // Default split function, evenly splitting the longer side.
    function split(uint16 frameId) external returns(bool);

    // More customizable split function.
    function split(uint16 frameId, XoY xoy, uint16 nUnits) external returns(bool);

    // Updater to refresh the content on a frame
    function update(uint16 frameId) external;

    // Make a bidding offer to a frame
    function bid(uint16 frameId, uint256 price) external;

    // Ask a price to sell
    function ask(uint16 frameId, uint256 price) external;

    // Rent a slot
    function rent(uint16 frameId, uint16 slotId, uint256 price) external;

    event GenerateFrame(
        address indexed _owner,
        uint256 indexed _frameId
    );

    event Merge(
        address indexed _owner,
        uint16 frameId1,
        uint16 frameId2,
        uint16 frameId
    );

    event Split(
        address indexed _owner,
        uint16 frameId,
        uint16 frameId1,
        uint16 frameId2
    );

    event Update(
        address indexed _owner,
        address indexed _operator,
        uint16 frameId,
        string _data
    );

    event Bid(
        address indexed _bidder,
        uint16 frameId,
        uint256 price
    );
    event Ask(
        address indexed _owner,
        uint16 frameId,
        uint256 price
    );

    // add a pixel
    event AddPixel(
        uint256 indexed _estateId,
        uint256 indexed _landId
    );

    // remove a pixel
    event RemovePixel(
        uint256 indexed _estateId,
        uint256 indexed _landId,
        address indexed _destinatary
    );
}



contract FrameRegistry is Algos, Encoding, FrameStorage, IFrameRegistry {

    using EnumerableRangeSet for EnumerableRangeSet.RangeSet;
    using EnumerableRangeSet for EnumerableRangeSet.Range;

    uint16 private constant MAX_FRAME_HEIGHT = 10;
    uint16 private constant MAX_FRAME_WIDTH = 10;
    uint16 private constant MAX_FRAME_SIZE = 100;

    mapping(uint16 => Frame) internal _frames;

    // A frame only requires two points, four coordinates to
    // be uniquely identified. The same principle of making
    // a data structure as simple as possible also applies here.
    // Most of coordinates in this project are referring to the bottom
    // left of either a pixel or a frame. However, the last two coordinates
    // are referring to the top right corner for simplicity and convenience:
    // uint16 height and weith can be easily calculated by the four numbers.


    struct Range {
        uint16 _start;
        uint16 _end;
    }

    // The checking should not take a frame object as an input variable.
    // Once a frame has come to existence, it must be valid. Therefore,
    // the checking must happen before the creation step.
    // TODO: modify this function, find the right location to do the checking.
    // check if a frame is valid, multiple conditions should be considered:
    // 1. If numerically valid;
    // 2. If conflicting any pixel;
    // 3. If conflicing any frame;

    function _isValidFrame(Frame memory frame) internal pure returns(bool) {
        if ((frame._x2 > frame._x1) && (frame._y2 > frame._y1)) {
            return true;
        }
        return false;
    }

    // A range is used to represent either edge of a frame, i.e., it can be
    // vertical or horizontal coverage. We first assume it is a segment between
    // 1 and 10. The range has a range.
    function _isValidRange(Range memory range) internal pure returns(bool) {
        // double check: require range._start and range._end [0, 100]
        if (range._end > range._start) {
            if (range._end - range._start < 11) {
                if (range._end <= 100 && range._start >= 0) {
                    return true;
                }
            }
        }
        return false;
    }

    function _generateRange(uint16 start, uint16 end) internal pure returns(Range memory) {
        Range memory range = Range(start, end);
        require(_isValidRange(range), "This range is invalid.");
        return range;
    }

    function _getFrameRange(Frame memory frame) internal pure returns(Range memory, Range memory) {
        Range memory xRange = _generateRange(frame._x1, frame._x2);
        Range memory yRange = _generateRange(frame._y1, frame._y2);
        return (xRange, yRange);
    }

    // double check
    function _len(Range memory range) internal pure returns(uint16) {
        return range._end - range._start;
    }

    // It's intuitive to use (x, y) to label a pixel, but it's convenient to
    // label a frame using its Id, otherwise, it would use two coordinates, or
    // a name.
    // TODO: think about giving each frame a name.
    function _getFrameId(uint16 x, uint16 y) internal pure returns(uint16) {
        return _encode(x, y);
    }

    function _getFrameId(Frame memory frame) internal pure returns(uint16) {
        return _encode(frame._x1, frame._y1);
    }

    // a frameId and a rangeId may be the same, but it's ok, since they don't
    // get stored in the same data structures.
    function _getRangeId(uint16 start, uint16 end) internal pure returns(uint16) {
        return _encode(start, end);
    }

    // At first, I think the new frame is not conflicting with any pixel.
    // The second thought is, the frame generation event is separate from buying
    // event, because an existing pixel must be available for purchasing. It is
    // always on sale. Hence, there is no need to check if it's conflicting or not.
    // The real issue is if there is any pixel in this new frame in order to
    // calculate the price.
    // TODO: it's possible to check pixelId. The exact method is being developed.
    // 1. calculate pixelId1 and pixelId2, and see if there is any existing
    // pixelId in between. Suppose 3 are in between, decode them into (x, y),
    // check if each pixel is in the frame.

    function generateFrame(uint16 x1, uint16 y1, uint16 x2, uint16 y2) public override {
        _generateFrame(x1, y1, x2, y2);
    }

    function getFrameId(uint16 x1, uint16 y1, uint16 x2, uint16 y2) public pure override returns(uint16) {
        return _getFrameId(x1, y1);
    }

    // TODO: check existence of a frameId
    function getFrame(uint16 frameId) public override returns(Frame memory) {
        return _frames[frameId];
    }

    function merge(uint16 frameId1, uint16 frameId2) public override returns(bool) {
        _merge(_frames[frameId1], _frames[frameId2]);
        return true;
    }

    function split(uint16 frameId) public override returns(bool) {
        Frame memory frame = _frames[frameId];
        (uint16 width, uint16 height) = _frameSize(frame);
        XoY xoy = width >= height ? XoY.InX : XoY.InY;
        uint16 nUnits = xoy == XoY.InX ? width/2 : height/2;
        _split(frame, xoy, nUnits);
    }

    function split(uint16 frameId, XoY xoy, uint16 nUnits) public override returns(bool) {
        Frame memory frame = _frames[frameId];
        _split(frame, xoy, nUnits);
    }

    function update(uint16 frameId) public override {

    }

    function bid(uint16 frameId, uint256 price) public override {
        _bid(frameId, price);
    }

    function ask(uint16 frameId, uint256 price) public override {
        _ask(frameId, price);
    }

    function rent(uint16 frameId, uint16 slotId, uint256 price) public override {
        _rent();
    }

    function _generateFrame(uint16 x1, uint16 y1, uint16 x2, uint16 y2) internal {
        // TODO: require owner, the project owner to generate a frame.
        Frame memory frame = Frame(x1, y1, x2, y2);
        require(_isValidFrame(frame), "Numerically invalid!");

        uint16 frameId = _getFrameId(x1, y1);
        _frames[frameId] = frame;
        _frameExist[frameId] = true;

        // The existence of a pixel in a frame may not be a problem.
        // TODO: double check where this checking should be put.
        // require(!_checkPixelInFrame, "There exists a pixel in frame.");

        require(!_checkOverlappingFrame(frame), "Overlapping existing frames!");

        EnumerableRangeSet.Range memory xRange = EnumerableRangeSet.Range(x1, x2);
        EnumerableRangeSet.Range memory yRange = EnumerableRangeSet.Range(y1, y2);
        uint16 xRangeId = _encodeRange(xRange);
        uint16 yRangeId = _encodeRange(yRange);

        _xRangeIds.add(xRange);
        _xRangeIdToYRangeIds[xRangeId].add(yRange);
        _xyExists[xRangeId][yRangeId] = true;

        // emit GenerateFrame();
    }

    // This is to check if there exists a pixel in the frame.
    // Another function getting all pixels in a frame might be needed.
    // function _checkPixelInFrame(Frame memory frame) internal view returns(bool) {
    //     for (uint16 x = frame._x1; x < frame._x2; x++) {
    //         if (!_xExists[x]) continue;
    //         for (uint16 y = frame._y1; x < frame._y2; y++) {
    //             if (!_yExists[y]) continue;
    //             if (_xyExists[x][y]) return true;
    //         }
    //     }
    //     return false;
    // }

    function _encodeRange(EnumerableRangeSet.Range memory range) internal pure returns(uint16) {
        return _encode(range._start, range._end);
    }

    function _encodeRange(Range memory range) internal pure returns(uint16) {
        return _encode(range._start, range._end);
    }


    // Need to check what would change after certain frames are removed, merged,
    // splitted, etc.
    function _checkOverlappingFrame(Frame memory frame) internal returns(bool) {
        EnumerableRangeSet.Range memory xRange = EnumerableRangeSet.Range(frame._x1, frame._x2);
        EnumerableRangeSet.Range memory yRange = EnumerableRangeSet.Range(frame._y1, frame._y2);
        uint16 xRangeId;
        uint16 yRangeId;
        EnumerableRangeSet.Range[] memory xRanges;
        EnumerableRangeSet.Range[] memory yRanges;

        if (_xRangeIds.overlapAny(xRange)) {
            xRanges = _xRangeIds.overlap(xRange);
            for (uint16 i = 0; i < xRanges.length; i++) {
                xRangeId = _encodeRange(xRanges[i]);
                if(_xRangeIdToYRangeIds[xRangeId].overlapAny(yRange)) {
                    yRanges = _xRangeIdToYRangeIds[xRangeId].overlap(yRange);
                    for (uint16 j = 0; j < yRanges.length; j++) {
                        yRangeId = _encodeRange(yRanges[j]);
                        if (_xyExists[xRangeId][yRangeId]) return true;
                    }
                }
            }
        }
        return false;
    }

    // Once a frame is created, it must be valid. No need to check validity again.
    function _frameSize(Frame memory frame) internal pure returns(uint16, uint16) {
        uint16 width = frame._x2 - frame._x1;
        uint16 height = frame._y2 - frame._y1;
        return (width, height);
    }

    // Frames are not minted. Tokens are. The NFTs are minted.
    // Frames are simply linked with Tokens.
    // The holder of the NFT linked to this frame would have
    // all the rights of working on the frame. This mechanism has
    // not been designed.

    // function _setupManager() internal;
    // function _owner() internal;
    // function _linkNFT() internal;
    // function _getNFT() internal;
    // function _getNFTOwner() internal;

    function isPixelInFrame(uint16 x, uint16 y, Frame memory frame) public pure returns(bool) {
        return _isPixelInFrame(x, y, frame);
    }

    // Check if a point is inside of a given frame
    // TODO: this concept is unclear. If a frame exists, a pixel cannot be in a
    // frame; if a pixel exists, a frame can also exist, but the checking is not
    // done here. The right name would be if a point is in a frame.
    // return: boolean, if true, in the frame, otherwise, no
    function _isPixelInFrame(uint16 x, uint16 y, Frame memory frame) private pure returns(bool) {
        // require that pixel and frame exist.
        bool inXRange = (x >= frame._x1) && (x < frame._x2);
        if (!inXRange) return false;
        bool inYRange = (y >= frame._y1) && (y < frame._y2);
        if (!inYRange) return false;
        return true;
    }

    function _checkFrameExist(uint16 frameId) private view returns(bool) {
        return _frameExist[frameId];
    }

    function _abandon(Frame memory frame) internal {
        // TODO: a frame can be abandoned, which is defined as
        // 1. owner is switched to project owner;
        // 2. pixels in this frame are all completely splitted;
    }

    function _delete(Frame memory frame) internal returns(bool) {
        // TODO: implement the logics of deleting a frame
        // This is to imply a frame is no longer in existence
    }


    // May be unnecessary
    function _compare(Frame memory frame1, Frame memory frame2) internal returns(bool) {
        uint16 frameId1 = _getFrameId(frame1);
        uint16 frameId2 = _getFrameId(frame2);
        return frameId1 < frameId2 ? true : false;
    }

    //
    function _merge(Frame memory frame1, Frame memory frame2) internal returns(bool) {
        require(_isTwoFrameMergeable(frame1, frame2), "The two frames are not mergeable!");
        // TODO: if two frames are merged, the two frames will be deleted.
        // TODO: the newly created frame cannot be bigger than 10 by 10, i.e.,
        // the limit is 10 by 10.

        if (!_compare(frame1, frame2)) {
            (frame2, frame1) = (frame1, frame2);
        }

        uint16 newX1 = frame1._x1;
        uint16 newY1 = frame1._y1;
        uint16 newX2 = frame2._x2;
        uint16 newY2 = frame2._y2;

        _delete(frame1);
        _delete(frame2);

        _generateFrame(newX1, newY1, newX2, newY2);

        return true;
    }


    // TODO: to be tested.
    function _isTwoFrameMergeable(Frame memory frame1, Frame memory frame2) internal pure returns(bool) {
        // Do some checking

        // 1. If the mid points of two frames share the same X. width must be the same,
        // and sum of heights must be equal to 2 times of distance betwen two mid points.
        // 2. If the mid points of two frames share the same Y, height must be the same.
        // And sume of widths must be equal to 2 times of distance between two mid points.

        // Only these two possibilities.
        uint16 xm_1 = frame1._x1 + frame1._x2;
        uint16 xm_2 = frame2._x1 + frame2._x2;
        uint16 ym_1 = frame1._y1 + frame1._y2;
        uint16 ym_2 = frame2._y1 + frame2._y2;
        (uint16 width_1, uint16 height_1) = _frameSize(frame1);
        (uint16 width_2, uint16 height_2) = _frameSize(frame2);
        uint16 sumWidth = width_1 + width_2;
        uint16 sumHeight = height_1 + height_2;
        uint16 disMidX = xm_2 > xm_1 ? xm_2 - xm_1 : xm_1 - xm_2;
        uint16 disMidY = ym_2 > ym_1 ? ym_2 - ym_1 : ym_1 - ym_2;

        if (xm_1 == xm_2) {
            if (width_1 == width_2 && sumHeight == disMidY) {
                return true;
            }
        }

        if (ym_1 == ym_2) {
            if (height_1 == height_2 && sumWidth == disMidX) {
                return true;
            }
        }
        return false;
    }

    // As a matter of fact, as long as the two frames belong to two people,
    // they can be swapped if price difference needs to be paid. Hence,
    // swap can be overloaded. If the two agree on not paying any price difference,
    // a direct swap can happen.
    function _swap(Frame memory frame1, Frame memory frame2) internal returns(bool) {
        // TODO: as long as two parties agree to swap two frames, they
        // can do it. The logics must be laid out clearly.
        // Additional ERC20 payments may be necessary in the swap process.

        // What is really being swapped here, is the owner of two
        // frames.

        return false;
    }

    function _paySwap(Frame memory frame1, Frame memory frame2, uint256 price) internal returns(bool) {
        // TODO: whoever needs to pay the price difference will
        // call this function, i.e., the payer initiates the _paySwap function.
    }

    // This is only for equal price swap.
    function _isSwappable(Frame memory frame1, Frame memory frame2) internal returns(bool) {
        // 1. Two frames must be of equal size.
        // 2. Two frames must belong to two owners.
        // 3. The price difference is agreed upon. This condition may require
        // a separate function. Hence, as long as the above two conditions are
        // met, the two frames can be swapped.
        (uint16 h1, uint16 w1) = _frameSize(frame1);
        (uint16 h2, uint16 w2) = _frameSize(frame2);

        if (_ownerOf(frame1) != _ownerOf(frame2)) {
            if (h1 == h2 && w1 == w2) {
                return true;
            }
        }

        return false;
    }

    function _ownerOf(Frame memory frame) internal view returns(address) {
        return msg.sender;
    }

    function _isSplittable(Frame memory frame, XoY xoy, uint16 nUnits) internal returns(bool) {
        // TODO: to check a given frame is splitable or not.
        // The condition is
        // Would there be a cap of total NFTs ever possible, which means
        // beyond a certain number, no more split is allowed, since it's
        // creating 2 new NFTs and burning 1 existing one.
        (uint16 width, uint16 height) = _frameSize(frame);

        if (width * height == 1) return false;
        if (width == 1 && xoy == XoY.InX) return false;
        if (height == 1 && xoy == XoY.InY) return false;
        if (xoy == XoY.InX && width <= nUnits) return false;
        if (xoy == XoY.InY && height <= nUnits) return false;

        return true;
    }

    function _split(Frame memory frame, XoY xoy, uint16 nUnits) internal returns(bool) {
        require(_isSplittable(frame, xoy, nUnits), "Not possible to split!");

        uint16 x1_1 = frame._x1;
        uint16 y1_1 = frame._y1;

        uint16 x2_2 = frame._x2;
        uint16 y2_2 = frame._y2;

        uint16 x2_1;
        uint16 y2_1;

        uint16 x1_2;
        uint16 y1_2;

        if (xoy == XoY.InX) {
            x2_1 = x1_1 + nUnits;
            y2_1 = frame._y2;

            x1_2 = x2_1;
            y1_2 = y1_1;
        } else
        if (xoy == XoY.InY) {
            x2_1 = frame._x2;
            y2_1 = frame._y1 + nUnits;

            x1_2 = x2_1;
            y1_2 = y2_1;
        }

        _generateFrame(x1_1, y1_1, x2_1, y2_1);
        _generateFrame(x1_2, y1_2, x2_2, y2_2);
        _delete(frame);

        return true;
    }

    function _update(Frame memory frame) internal returns(bool) {
        // This is to update the content on top of the frame.
        // TODO: check if the update should be made to the NFT or
        // a frame.
        // This shall call the NFT's setURI function.
        // TO be implemented later.
        return false;
    }

    function _bid(uint16 frameId, uint256 price) internal returns(bool) {
        // TODO: for some potential buyer to make a bid to a frame/NFT on the
        // board.
        // 1. If NFT is on sale and the bid price is higher than or equal to
        // the ask price, a transfer is triggered.
        // 2. If NFT is on sale and the bid price is lower than the ask price,
        // but higher than the current highest bid price, update data; otherwise,
        // nothing would happen.
        // 3. If NFT is not on sale, only updating bid information is possible.

        return false;
    }

    function _ask(uint16 frameId, uint256 price) internal returns(bool) {
        // TODO: if a NFT is on-sale, then an ask price should be set.
        return false;
    }

    function _setOnSale(Frame memory frame) internal returns(bool) {
        require(!_isOnSale[_getFrameId(frame)], "Already on sale!");
        // TODO: change the status of a NFT/Frame from not on sale to on sale.
        // an ask price must be specificed.
        _isOnSale[_getFrameId(frame)] = true;
    }

    function _setNotOnSale(Frame memory frame) internal returns(bool) {
        require(_isOnSale[_getFrameId(frame)], "Already not on sale!");
        _isOnSale[_getFrameId(frame)] = false;

        return true;
    }

    function _rent() internal returns(bool) {
        // TODO: flip board can be rented to other people to earn FLP tokens.
        // Frames cannot be rented. It is always owned and maintained by the owner.
        // To rent flipbaord positions out, it is equivalent with giving the control
        // rights of updating contents on that board to somebody else.
        // Priority: low
        return true;
    }

    function _checkFrameOverlap(Frame memory frame1, Frame memory frame2) public pure returns(bool) {

        uint16 xm_1 = frame1._x1 + frame1._x2;
        uint16 ym_1 = frame1._y1 + frame1._y2;

        uint16 xm_2 = frame2._x1 + frame2._x2;
        uint16 ym_2 = frame2._y1 + frame2._y2;

        uint16 w1 = frame1._x2 - frame1._x1;
        uint16 h1 = frame1._y2 - frame1._y1;

        uint16 w2 = frame2._x2 - frame2._x1;
        uint16 h2 = frame2._y2 - frame2._y1;

        uint16 sumWidth = w1 + w2;
        uint16 sumHeight = h1 + h2;

        uint16 diffMidWidth = xm_1 > xm_2 ? xm_1 - xm_2 : xm_2 - xm_1;
        uint16 diffMidHeight = ym_1 > ym_2 ? ym_1 - ym_2 : ym_2 - ym_1;

        return (diffMidWidth < sumWidth) && (diffMidHeight < sumHeight);
    }

    function _getNumOfFlipboard(Frame memory frame) private pure returns(uint16) {
        uint16 width = frame._x2 - frame._x1;
        uint16 height = frame._y2 - frame._y1;
        uint16 numOfFlipboards = _sqrt(width * height);
        return numOfFlipboards;
    }

    // TODO: Move this into the library of EnumerableRange
    function _checkRangeOverlapping(Range memory range1, Range memory range2) public pure returns(bool) {
        if (range1._end > range2._start && range1._end <= range2._end) return true;
        if (range2._end > range1._start && range2._end <= range1._end) return true;
        return false;
    }
}