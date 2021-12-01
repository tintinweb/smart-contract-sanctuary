// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IGameBase.sol";
import "../interfaces/IGamePot.sol";
import "../interfaces/IBonusNFT.sol";
import "../interfaces/IDSG.sol";

interface IDSGT is IDSG {
    function ticketMint(address player, uint256 amount) external;
}

interface IRandomizer {
    function getRandom() external returns (bytes32);

    function available() external returns (bool);
}

interface IVault {
    function depositBNB() external payable;
}

interface IBoxAuction {
    function unlockNFT(uint256 board, uint256 box) external;
}

interface IBonusBoard {
    function isReady(uint256 board) external view returns (bool);

    function addCredits(uint256 board, address player) external;
}

contract GameBase is ReentrancyGuard, Pausable, Ownable, IGameBase {
    //--------- Libraries ----------//
    using SafeMath for uint256;

    //---------- Contracts ----------//
    IGamePot internal POT;
    IVault internal VAULT;
    IBoxAuction internal BOX_AUCT;
    IDSG internal DSG;
    IDSGT internal DSGT;
    IRandomizer internal RANDOM;
    IBonusNFT internal BONUS_NFT;
    IBonusBoard internal BONUS;

    //---------- Variables ----------//
    address payable internal LIQ_GEN;
    bool internal initialized;
    uint256 internal feeLINK;
    uint256 public rollAmount;

    //---------- Storage -----------//
    struct BoxInfo {
        address owner;
        uint256 owned;
        uint256 cost;
        uint256 turns;
        bool inUse;
    }

    struct PlayerBoard {
        uint256 box;
        uint256 lastRoll;
        uint256 lastAmount;
        uint256 lastResult;
        uint256 loops;
    }

    struct PlayerInfo {
        bool rolling;
        uint256 level;
    }

    struct Request {
        address player;
        uint256 board;
    }

    mapping(address => mapping(uint256 => PlayerBoard)) public BoardPlayer;
    mapping(bytes32 => Request) private PlayerRequest;
    mapping(uint256 => mapping(uint256 => BoxInfo)) public BoardBoxes;
    mapping(address => PlayerInfo) public Player;
    uint256[48] internal BoxType;
    uint256[48] internal BoxRarity;

    //---------- Events -----------//
    event DiceRolled(
        bytes32 indexed requestId,
        address indexed roller,
        uint256 board
    );
    event DiceLanded(address indexed roller, bytes32 requestId, uint256 result);
    event BoxFilled(
        uint256 indexed board,
        uint256 indexed box,
        address indexed owner,
        uint256 turns,
        uint256 rarity
    );
    event PayedRent(
        uint256 indexed board,
        uint256 indexed box,
        address indexed owner,
        uint256 amount
    );    
    event WinBonus(
        uint256 indexed board,
        address indexed owner
    );
    event WinBonusNFT(
        uint256 indexed board,
        address indexed owner,
        uint256 nft
    );

    //---------- Constructor ----------//
    constructor(address dsg, address randomizer) {
        rollAmount = 1 ether; // 1 MATIC
        feeLINK = 0.01 * 10**18; // 0.01 MATIC
        DSG = IDSG(dsg);
        RANDOM = IRandomizer(randomizer);
    }

    //---------- Modifiers ----------//
    modifier notContract() {
        require(!_isContract(msg.sender), "Contract not allowed");
        require(msg.sender == tx.origin, "Proxy contract not allowed");
        _;
    }

    modifier onlyAuction() {
        require(address(BOX_AUCT) == _msgSender());
        _;
    }

    modifier onlyRandomizer() {
        require(_msgSender() == address(RANDOM));
        _;
    }

    //----------- Internal Functions -----------//
    function _isContract(address _addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }

    function destinyBox(
        address payable player,
        uint256 board,
        uint256 targetBox,
        uint256 randomness
    ) internal virtual returns (bool) {
        BoxInfo storage b = BoardBoxes[board][targetBox];
        PlayerBoard storage p = BoardPlayer[player][board];
        uint256 amount = p.lastAmount;
        uint256 btype = BoxType[targetBox];
        p.lastAmount = 0;
        if (btype == 1) {
            uint256 id = randomness.mod(3).add(1);
            BONUS_NFT.mintPrize(player, id);
            LIQ_GEN.transfer(amount);
            emit WinBonusNFT(board, player, id);
            return true;
        }
        if (btype == 2) {
            if (BONUS.isReady(board)) {
                BONUS.addCredits(board, player);
                emit WinBonus(board, player);
            }
            LIQ_GEN.transfer(amount);
            return true;
        }
        if (btype == 3) {
            POT.payWinner(board, player);
            LIQ_GEN.transfer(amount);
            return true;
        }
        if (btype == 4) {
            if (b.inUse) {
                b.turns = b.turns.sub(1);
                address owner = b.owner;
                b.owned = b.owned.add(amount);
                if (b.turns == 0) {
                    BOX_AUCT.unlockNFT(board, targetBox);
                    b.owner = address(0);
                    b.inUse = false;
                }
                DSGT.ticketMint(player, 1 ether);
                payable(owner).transfer(amount);
                emit PayedRent(board, targetBox, owner, amount);
                return true;
            } else {
                LIQ_GEN.transfer(amount);
                return true;
            }
        }
        return false;
    }

    function boxOverflow(uint256 actualbox, uint256 result)
        internal
        virtual
        returns (uint256, bool)
    {
        if (actualbox.add(result) > 47) {
            return (actualbox.add(result).sub(47), true);
        }
        return (actualbox.add(result), false);
    }

    //----------- External Functions -----------//
    function playerLevel(address player) public view returns (uint256) {
        return Player[player].level.add(1);
    }

    function checkBox(uint256 board, uint256 box)
        external
        view
        override
        returns (
            uint256 boxType,
            bool free,
            uint256 rarity,
            address owner,
            uint256 owned,
            uint256 cost,
            uint256 turns
        )
    {
            uint256 _board = board;
            uint256 _box = box;
        return (
            BoxType[_box],
            !BoardBoxes[_board][_box].inUse,
            BoxRarity[_box],
            BoardBoxes[_board][_box].owner,
            BoardBoxes[_board][_box].owned,
            BoardBoxes[_board][_box].cost,
            BoardBoxes[_board][_box].turns
        );
    }

    function checkPlayer(uint256 board, address player)
        external
        view
        override
        returns (
            uint256 box,
            uint256 lastRoll,
            uint256 lastAmount,
            uint256 lastResult,
            bool isRolling,
            uint256 loops,
            uint256 level
        )
    {
        return (
            BoardPlayer[player][board].box,
            BoardPlayer[player][board].lastRoll,
            BoardPlayer[player][board].lastAmount,
            BoardPlayer[player][board].lastResult,
            Player[player].rolling,
            BoardPlayer[player][board].loops,
            playerLevel(player)
        );
    }

    function rollDice(uint256 board)
        public
        payable
        whenNotPaused
        notContract
        nonReentrant
        returns (bytes32 requestId)
    {
        require(board > 0, "Invalid board");
        require(playerLevel(_msgSender()) >= board, "Level too low");
        require(msg.value == rollAmount.mul(board), "Invalid amount");
        require(RANDOM.available(), "Randomizer error");
        require(!Player[_msgSender()].rolling, "Player awaiting result");
        uint256 withoutLink = msg.value.sub(feeLINK);
        uint256 toVault = (withoutLink.mul(2000)).div(10000);
        VAULT.depositBNB{value: toVault}();
        payable(address(RANDOM)).transfer(feeLINK);
        uint256 amount = withoutLink.sub(toVault);
        bytes32 RequestId = RANDOM.getRandom();
        Player[_msgSender()].rolling = true;
        PlayerBoard storage i = BoardPlayer[_msgSender()][board];
        i.lastRoll = block.timestamp;
        i.lastAmount = amount;
        PlayerRequest[RequestId].player = _msgSender();
        PlayerRequest[RequestId].board = board;
        emit DiceRolled(RequestId, _msgSender(), board);
        return (RequestId);
    }

    function spendBonus(
        uint256 board,
        uint256 box,
        uint256 nft,
        uint256 targetBox
    ) external whenNotPaused notContract nonReentrant {
        require(board > 0 && box > 0 && nft > 0, "Invalid inputs");
        require(playerLevel(_msgSender()) >= board, "Level to low");
        if (nft == 1) {
            BoxInfo storage b = BoardBoxes[board][box];
            require(b.inUse && b.owner == _msgSender());
            BONUS_NFT.burn(_msgSender(), nft, 1);
            b.turns = b.turns.add(1);
        }
        if (nft == 2) {
            PlayerBoard storage i = BoardPlayer[_msgSender()][board];
            BoxInfo storage b = BoardBoxes[board][box];
            require(b.inUse);
            require(
                i.box == box && block.timestamp < i.lastRoll.add(15 minutes)
            );
            BONUS_NFT.burn(_msgSender(), nft, BoxRarity[box]);
            BOX_AUCT.unlockNFT(board, box);
            b.owner = address(0);
            b.inUse = false;
            b.turns = 0;
        }
        if (nft == 3) {
            BONUS_NFT.burn(_msgSender(), nft, 1);
            Player[_msgSender()].level = Player[_msgSender()].level.add(1);
        }
        if (nft == 4) {
            require(BoxType[targetBox] == 4);
            BONUS_NFT.burn(_msgSender(), nft, 1);
            BoardPlayer[_msgSender()][board].box = targetBox;
        }
    }

    function fillBox(
        uint256 board,
        uint256 box,
        address owner,
        uint256 cost,
        uint256 turns
    ) external override onlyAuction returns (bool) {
        BoxInfo storage b = BoardBoxes[board][box];
        require(BoxType[box] == 4 && !b.inUse);
        b.inUse = true;
        b.owner = owner;
        b.turns = turns;
        b.cost = cost;
        b.owned = 0;
        emit BoxFilled(board, box, owner, turns, uint256(BoxRarity[box]));
        return b.inUse;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function safeWithdrawn() external whenPaused onlyOwner {
        if (DSG.balanceOf(address(this)) > 0) {
            DSG.transfer(_msgSender(), DSG.balanceOf(address(this)));
        }
    }

    function resetPlayer(uint256 board, address player) external onlyOwner {
        delete BoardPlayer[player][board];
        Player[player].rolling = false;
    }

    function resetBox(uint256 board, uint256 box) external onlyOwner {
        BoxInfo storage b = BoardBoxes[board][box];
        b.inUse = false;
        b.owner = address(0);
        b.turns = 0;
    }

    function init(
        address pot,
        address auction,
        address dsgt,
        address nftBonus,
        address vault,
        address liqGenerator,
        address bonus
    ) external onlyOwner {
        require(
            pot != address(0) &&
                auction != address(0) &&
                dsgt != address(0) &&
                nftBonus != address(0) &&
                bonus != address(0) &&
                liqGenerator != address(0) &&
                vault != address(0)
        );
        require(!initialized);
        POT = IGamePot(pot);
        BOX_AUCT = IBoxAuction(auction);
        DSGT = IDSGT(dsgt);
        VAULT = IVault(vault);
        BONUS_NFT = IBonusNFT(nftBonus);
        BONUS = IBonusBoard(bonus);
        LIQ_GEN = payable(liqGenerator);
        initialized = true;
        BoxType = [
            0,
            4,
            4,
            4,
            4,
            4,
            4,
            4,
            4,
            4,
            4,
            4,
            2,
            4,
            4,
            4,
            4,
            4,
            4,
            4,
            4,
            4,
            4,
            4,
            1,
            4,
            4,
            4,
            4,
            4,
            4,
            4,
            4,
            4,
            4,
            4,
            3,
            4,
            4,
            4,
            4,
            4,
            4,
            4,
            4,
            4,
            4,
            4
        ];
        BoxRarity = [
            0,
            1,
            2,
            1,
            1,
            4,
            1,
            3,
            1,
            2,
            1,
            1,
            0,
            2,
            1,
            1,
            3,
            2,
            1,
            1,
            3,
            1,
            2,
            1,
            0,
            2,
            1,
            2,
            4,
            1,
            2,
            1,
            3,
            1,
            1,
            2,
            0,
            1,
            2,
            1,
            1,
            3,
            1,
            2,
            1,
            1,
            2,
            3
        ];
    }

    function setFeeLink(uint256 fee) external onlyOwner {
        require(fee > 0);
        feeLINK = fee;
    }

    function returnRandom(bytes32 requestId, uint256 randomness)
        external
        onlyRandomizer
    {
        address player = PlayerRequest[requestId].player;
        uint256 board = PlayerRequest[requestId].board;
        delete PlayerRequest[requestId];
        uint256 result = randomness.mod(10).add(2);
        if (player != address(0)) {
            (uint256 destBox, bool overflowing) = boxOverflow(
                BoardPlayer[player][board].box,
                result
            );
            require(destinyBox(payable(player), board, destBox, randomness));
            PlayerBoard storage pb = BoardPlayer[player][board];
            PlayerInfo storage p = Player[player];
            pb.box = destBox;
            pb.lastResult = result;
            p.rolling = false;
            if (overflowing && playerLevel(player) == board) {
                pb.loops = pb.loops.add(1);
                if (pb.loops == 5) {
                    p.level = p.level.add(1);
                    pb.loops = 0;
                }
            }
        }
        emit DiceLanded(player, requestId, result);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
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

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
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
pragma solidity ^0.8.9;

interface IGamePot {
    function payWinner(uint256 board, address winner) external;
    function currentPot(uint256 board) external view returns(uint256);
    function depositDSG(uint256 amount) external;
    function depositBoardDSG(uint256 board, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IGameBase {
    function checkBox(uint256 board, uint256 box)
        external
        view
        returns (
            uint256 boxType,
            bool free,
            uint256 rarity,
            address owner,
            uint256 owned,
            uint256 cost,
            uint256 turns
        );

    function checkPlayer(uint256 board, address player)
        external
        view
        returns (
            uint256 box,
            uint256 lastRoll,
            uint256 lastAmount,
            uint256 lastResult,
            bool isRolling,
            uint256 loops,
            uint256 level
        );

    function fillBox(
        uint256 board,
        uint256 box,
        address owner,
        uint256 cost,
        uint256 turns
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDSG is IERC20 {
    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IBonusNFT is IERC1155 {
    function totalSupplyOf(uint256 id) external view returns (uint256);

    function mintPrize(address account, uint256 id) external;

    function burn(
        address account,
        uint256 id,
        uint256 value
    ) external;
}