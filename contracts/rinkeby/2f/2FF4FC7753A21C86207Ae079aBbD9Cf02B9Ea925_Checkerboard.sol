// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../contracts/INumbreERC721.sol";

contract Checkerboard {
    using SafeMath for uint;

    uint public maxLimit;
    uint public interval;
    address public owner;
    mapping(uint256 => uint256[]) public tokenInterval;
    address public ERC721;
    struct Piece {
        address owner;
        uint level;
        uint tokenId;
        uint lastBlock;
    }

    // pieces on board
    Piece[50][50] public pieces;

    event PlayPiece(uint fromX, uint fromY, address owner, uint tokenId);
    event MovePiece(uint fromX, uint fromY, uint toX, uint toY, uint fromTokenId, uint toTokenId);
    event MovePieceEatSmall(uint fromX, uint fromY, uint toX, uint toY, uint fromTokenId, uint toTokenId);
    event MovePieceHitBig(uint fromX, uint fromY, uint toX, uint toY, uint fromTokenId, uint toTokenId);
    event MovePieceSameLevel(uint fromX, uint fromY, uint toX, uint toY, uint fromTokenId, uint toTokenId);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor (uint _maxLimit, uint _interval, address _ERC721) {
        maxLimit = _maxLimit;
        interval = _interval;
        ERC721 = _ERC721;
        owner = msg.sender;
    }

    function playPiece(
        uint256 _x,
        uint256 _y,
        uint256 _tokenId
    ) public {

        require(pieces[_x][_y].level == 0, "there has another piece");
        address _owner;
        uint _level;
        (_level, , ,_owner, ) = INumbreERC721( ERC721 ).getPieceInfo(_tokenId);
        require(msg.sender == _owner, "you are not owner");

        pieces[_x][_y] = Piece({
            owner :_owner,
            level : _level,
            tokenId : _tokenId,
            lastBlock:block.number
        });

        changeLevel(_tokenId, 0, _x, _y, 1, 0);
        emit PlayPiece(_x, _y, _owner, _tokenId);
    }

    function movePiece(
        uint256 _fromX,
        uint256 _fromY,
        uint256 _toX,
        uint256 _toY
    ) public {
        require(_fromX != _toX || _fromY != _toY, "Can't play same position");

        Piece storage fromPiece = pieces[_fromX][_fromY];
        Piece storage toPiece = pieces[_toX][_toY];
        uint _fromTokenId = fromPiece.tokenId;
        require(block.number - fromPiece.lastBlock >= interval, "Interval must >= 1 hour");
        require(block.number - tokenInterval[_fromTokenId][0] > interval * 24, "Interval 8 times in 24 hour");

        address player;
        (, , ,player,) = INumbreERC721( ERC721 ).getPieceInfo(fromPiece.tokenId);
        require(msg.sender == player, "you are not player");

        require(toPiece.owner != fromPiece.owner, "You can't eat your piece");

        if (toPiece.level != 0) {
            if(toPiece.level < fromPiece.level) {
                toPiece.level = fromPiece.level.add(1);
                toPiece.tokenId = fromPiece.tokenId;
                toPiece.owner = fromPiece.owner;
                toPiece.lastBlock = block.number;
                changeLevel(fromPiece.tokenId, 1, _toX, _toY, 2, 1);
                changeLevel(toPiece.tokenId, -1, 0, 0, 2, 1);
                emit MovePieceEatSmall(_fromX, _fromY, _toX, _toY, _fromTokenId, toPiece.tokenId);
            } else if (toPiece.level == fromPiece.level) {
                changeLevel(fromPiece.tokenId, -1, 0, 0, 2, 1);
                changeLevel(toPiece.tokenId, -1, 0, 0, 2, 1);
                emit MovePieceSameLevel(_fromX, _fromY, _toX, _toY, _fromTokenId, toPiece.tokenId);
                blankingPosition(_toX, _toY);
            } else {
                toPiece.level = toPiece.level.sub(fromPiece.level);
                changeLevel(toPiece.tokenId, -1, _toX, _toY, 2, fromPiece.level);
                changeLevel(fromPiece.tokenId, -1, 0, 0, 2, 1);
                emit MovePieceHitBig(_fromX, _fromY, _toX, _toY, _fromTokenId, toPiece.tokenId);
            }
            // emit EatPiece();
        } else {
            toPiece.level = fromPiece.level;
            toPiece.tokenId = fromPiece.tokenId;
            toPiece.owner = fromPiece.owner;
            toPiece.lastBlock = block.number;
            changeLevel(fromPiece.tokenId, 0, _toX, _toY, 2, 0);
            emit MovePiece(_fromX, _fromY, _toX, _toY, _fromTokenId, 0);
        }

        blankingPosition(_fromX, _fromY);

    }

    function handleTokenInterval(uint256 tokenId) internal {
        uint256[] storage intervals = tokenInterval[tokenId];
        if (intervals.length == 8) {
            for (uint i = 0; i<intervals.length-1; i++){
                intervals[i] = intervals[i+1];
            }
            delete intervals[intervals.length-1];
        }

        intervals.push(block.number);
        tokenInterval[tokenId] = intervals;
    }


    function changeLevel(uint _tokenId, int handleType, uint256 x, uint256 y, uint256 isPlay, uint256 level) internal {
        uint256 tokenLevel;
        (tokenLevel, , , ,) = INumbreERC721( ERC721 ).getPieceInfo(_tokenId);
        if (handleType == 1) {
            tokenLevel = tokenLevel.add(level);
        } else {
            tokenLevel = tokenLevel.sub(level);
        }
        INumbreERC721( ERC721 ).updatePieceInfo(_tokenId, tokenLevel, x, y, isPlay);
    }

    function blankingPosition(uint _across, uint _down) internal {
        pieces[_across][_down] = (Piece({level : 0, tokenId : 0, owner:address(0), lastBlock:0}));
    }

    function autoUpdateLevel(uint256 _tokenId, uint256 _x, uint256 _y) onlyOwner public {
        Piece memory piece = pieces[_x][_y];
        piece.level.add(1);
        INumbreERC721( ERC721 ).updatePieceInfo(_tokenId, piece.level, _x, _y, 3);
    }

    function autoOffPiece(uint256 _tokenId, uint256 _x, uint256 _y) onlyOwner public {
        uint256 level = pieces[_x][_y].level;
        blankingPosition(_x, _y);
        INumbreERC721( ERC721 ).updatePieceInfo(_tokenId, level, 0, 0, 4);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface INumbreERC721 {
    function getPieceInfo(uint256 tokenId) external view returns (uint256 level, uint256 x, uint256 y, address user, uint256 seasonId);

    function updatePieceInfo(uint256 tokenId, uint256 level, uint256 x, uint256 y, uint256 _type) external;

    function mint(address user, uint256 seasonId) external returns (uint256);

    function getSeasonMaxToken(uint256 seasonId) external view returns (uint256[] memory tokenIds);

    function numbreOwnerOf(uint256 tokenId) external view returns (address user);
}