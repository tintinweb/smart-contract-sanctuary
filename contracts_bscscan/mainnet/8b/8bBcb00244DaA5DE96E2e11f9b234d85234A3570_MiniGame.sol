// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./SamoyedGame.sol";

contract MiniGame is SamoyedGame, ReentrancyGuard {
    using SafeMath for uint256;

    uint256 public currentRoomNo = 1;
    uint256 public nextWinnerDrawRoomNo = 1;
    uint256 public smoyCostPerSeat;
    uint256 public busdCostPerSeat;
    uint8 public immutable maxSeat = 16;
    uint256 public minimumSeatToImmediatelyBeginRound = 4;

    address public feeCollectorAddress;
    address public platformReserveAddress;
    address public godfatherPrizeAddress;
    address public puppyPrizeAddress;
    address public drawWinnerAddress;
    uint8 public feeCollectorRatio;
    uint8 public platformReserveRatio;
    uint8 public godfatherPrizeRatio;
    uint8 public puppyPrizeRatio;

    mapping(uint256 => address[16]) public sitAddress;
    mapping(uint256 => mapping(address => uint8[])) public addressSitQuantity;
    mapping(uint256 => mapping(address => bool)) public isAddressClaimedPrize;
    mapping(uint256 => uint8) public totalSit;
    mapping(uint256 => uint8) public winner;

    mapping(uint256 => mapping(address => bool)) public claimedWonPrize;

    event NewRoomCreated(uint256 roomNo);
    event SitEvent(address indexed sender, uint256 roomNo, uint8[] position);
    event WonEvent(address indexed sender, uint256 roomNo, uint8 position);
    event ClaimPrizeEvent(address indexed sender, uint256 roomNo, uint8 lose, uint8 won);
    event UpdateDrawWinner(address winnerDrawer);
    event UpdateCost(uint256 _smoyCostPerSeat, uint256 _busdCostPerSeat);
    event UpdateMinimumSeatToImmediatelyBeginRound(uint256 _minimumSeatToImmediatelyBeginRound);
    event UpdateFeeCollector(
        address feeCollectorAddress,
        address platformReserveAddress,
        address godfatherPrizeAddress,
        address puppyPrizeAddress
    );
    event UpdateFeeCollectorRatio(
        uint8 feeCollectorRatio,
        uint8 platformReserveRatio,
        uint8 godfatherPrizeRatio,
        uint8 puppyPrizeRatio
    );

    constructor(
        GodfatherStorage _godfatherStorage,
        PuppyStorage _puppyStorage,
        IBEP20 _smoyAddress,
        IBEP20 _busdAddress
    ) {
        godfatherStorage = _godfatherStorage;
        puppyStorage = _puppyStorage;
        smoyToken = _smoyAddress;
        busdToken = _busdAddress;
        smoyCostPerSeat = 200 ether;
        busdCostPerSeat = 39 ether;

        feeCollectorAddress = msg.sender;
        platformReserveAddress = msg.sender;
        godfatherPrizeAddress = msg.sender;
        puppyPrizeAddress = msg.sender;
        drawWinnerAddress = msg.sender;
        feeCollectorRatio = 40;
        platformReserveRatio = 10;
        godfatherPrizeRatio = 10;
        puppyPrizeRatio = 40;
    }

    function setDrawWinner(address winnerDrawer) external onlyOwner {
        drawWinnerAddress = winnerDrawer;

        emit UpdateDrawWinner(drawWinnerAddress);
    }

    function setCost(uint256 _smoyCostPerSeat, uint256 _busdCostPerSeat) public onlyOwner {
        smoyCostPerSeat = _smoyCostPerSeat;
        busdCostPerSeat = _busdCostPerSeat;

        emit UpdateCost(smoyCostPerSeat, busdCostPerSeat);
    }

    function setMinimumSeatToImmediatelyBeginRound(uint256 _minimumSeatToImmediatelyBeginRound) public onlyOwner {
        minimumSeatToImmediatelyBeginRound = _minimumSeatToImmediatelyBeginRound;

        emit UpdateMinimumSeatToImmediatelyBeginRound(minimumSeatToImmediatelyBeginRound);
    }

    function getAddressSitQuantityLength(uint256 roomNo, address sitterAddress) public view returns (uint8) {
        return uint8(addressSitQuantity[roomNo][sitterAddress].length);
    }

    function sitWithSmoy(uint8 sitQuantity, uint8[] memory sitPosition) external {
        uint256 totalCost = sitQuantity * smoyCostPerSeat;
        collectFee(smoyToken, totalCost);
        feeDistribute(smoyToken, totalCost);

        sit(sitQuantity, sitPosition);
    }

    function sitWithBUSD(uint8 sitQuantity, uint8[] memory sitPosition) external {
        uint256 totalCost = sitQuantity * busdCostPerSeat;
        collectFee(busdToken, totalCost);
        feeDistribute(busdToken, totalCost);

        sit(sitQuantity, sitPosition);
    }

    function sit(uint8 sitQuantity, uint8[] memory sitPosition) private nonReentrant {
        uint8 maxLoopLength = sitQuantity;
        require(totalSit[currentRoomNo] + sitQuantity <= maxSeat, "MiniGame: E1");
        if (sitPosition.length > 0) {
            require(sitQuantity == uint8(sitPosition.length), "MiniGame: E2");
            maxLoopLength = uint8(sitPosition.length);
        }
        uint8[] memory confirmSitPosition = new uint8[](maxLoopLength);
        uint8 willSitAtPosition = 0;
        uint8 sitSuccess = 0;
        for (uint8 i = 0; i < maxSeat; i++) {
            //uint8 willSitAtPosition=(sitPosition.length==0 ? 1 : 0 );
            //uint256 q = p % 2 != 0 ? a : b;
            if (sitPosition.length == 0) {
                if (sitAddress[currentRoomNo][i] == address(0)) {
                    willSitAtPosition = i;
                } else {
                    continue;
                }
            } else {
                require(sitPosition[i] < maxSeat, "MiniGame: GTE16");
                if (sitAddress[currentRoomNo][sitPosition[i]] == address(0)) {
                    willSitAtPosition = sitPosition[i];
                } else {
                    revert("MiniGame: DUPLICATE");
                }
            }
            sitAddress[currentRoomNo][willSitAtPosition] = msg.sender;
            addressSitQuantity[currentRoomNo][msg.sender].push(willSitAtPosition);
            confirmSitPosition[sitSuccess] = willSitAtPosition;

            totalSit[currentRoomNo]++;
            sitSuccess++;

            if (sitSuccess == maxLoopLength) {
                emit SitEvent(msg.sender, currentRoomNo, confirmSitPosition);
                break;
            }
        }
        if (totalSit[currentRoomNo] == maxSeat) {
            //printSitAddress(currentRoomNo);
            createNewRoom();
        }
    }

    function createNewRoom() private {
        currentRoomNo++;

        emit NewRoomCreated(currentRoomNo);
    }

    function drawWinner(uint256 salt) external nonReentrant {
        require(drawWinnerAddress == msg.sender, "MiniGame: UnAuthorized Drawer");
        require(nextWinnerDrawRoomNo <= currentRoomNo - 1, "MiniGame: WinnerDraw cannot exceed currentRoomNo");
        winner[nextWinnerDrawRoomNo] = random(salt);

        emit WonEvent(
            sitAddress[nextWinnerDrawRoomNo][winner[nextWinnerDrawRoomNo]],
            currentRoomNo,
            winner[nextWinnerDrawRoomNo]
        );
        nextWinnerDrawRoomNo++;
    }

    function immediatelyBeginRound() external nonReentrant {
        require(
            getAddressSitQuantityLength(currentRoomNo, msg.sender) >= minimumSeatToImmediatelyBeginRound,
            "MiniGame: Need at Least 4 Seats"
        );
        createNewRoom();
    }

    function random(uint256 salt) private view returns (uint8) {
        return uint8(uint256(keccak256(abi.encodePacked(block.timestamp, salt))) % maxSeat);
    }

    function claimWonPrize(uint8 wonRoomNo) public nonReentrant {
        require(wonRoomNo <= nextWinnerDrawRoomNo - 1, "MiniGame: WonRoomNo is greater than current");
        require(!isAddressClaimedPrize[wonRoomNo][msg.sender], "MiniGame: User already cliamed.");
        uint8 sitQuantity = getAddressSitQuantityLength(wonRoomNo, msg.sender);
        require(sitQuantity > 0, "MiniGame: No Seats Found");

        uint8 win = 0;
        uint8 lose = 0;
        uint8 winnerNo = winner[wonRoomNo];
        for (uint8 i = 0; i < sitQuantity; i++) {
            if (addressSitQuantity[wonRoomNo][msg.sender][i] == winnerNo) {
                win++;
            } else {
                lose++;
            }
        }

        if (win > 0) {
            mintPuppy();
        }
        if (lose > 0) {
            mintGodfather(0, lose);
        }
        isAddressClaimedPrize[wonRoomNo][msg.sender] = true;
        emit ClaimPrizeEvent(msg.sender, wonRoomNo, lose, win);
    }

    function mintGodfather(uint256 rarity, uint256 quantity) private returns (uint256[] memory) {
        uint256[] memory tokenIds = godfatherStorage.bulkMint(msg.sender, rarity, quantity);
        return tokenIds;
    }

    function mintPuppy() private returns (uint256) {
        uint256 tokenId = puppyStorage.mint(msg.sender);
        return tokenId;
    }

    function feeDistribute(IBEP20 _token, uint256 _amount) private {
        uint256 balance = _token.balanceOf(address(this));
        require(balance >= _amount, "MiniGame: INSUFFICIENT_BALANCE");

        uint256 _feeCollectorAmount = _amount.div(100).mul(feeCollectorRatio);
        uint256 _platformReserveAmount = _amount.div(100).mul(platformReserveRatio);
        uint256 _godfatherPrizeAmount = _amount.div(100).mul(godfatherPrizeRatio);
        uint256 _puppyPrizeAmount = _amount.div(100).mul(puppyPrizeRatio);

        TransferHelper.safeTransfer(address(_token), feeCollectorAddress, _feeCollectorAmount);
        TransferHelper.safeTransfer(address(_token), platformReserveAddress, _platformReserveAmount);
        TransferHelper.safeTransfer(address(_token), godfatherPrizeAddress, _godfatherPrizeAmount);
        TransferHelper.safeTransfer(address(_token), puppyPrizeAddress, _puppyPrizeAmount);
    }

    function setFeeCollectorAddress(
        address _feeCollectorAddress,
        address _platformReserveAddress,
        address _godfatherPrizeAddress,
        address _puppyPrizeAddress
    ) external onlyOwner nonReentrant {
        if (_feeCollectorAddress != address(0)) feeCollectorAddress = _feeCollectorAddress;
        if (_platformReserveAddress != address(0)) platformReserveAddress = _platformReserveAddress;
        if (_godfatherPrizeAddress != address(0)) godfatherPrizeAddress = _godfatherPrizeAddress;
        if (_puppyPrizeAddress != address(0)) puppyPrizeAddress = _puppyPrizeAddress;

        emit UpdateFeeCollector(
            _feeCollectorAddress,
            _platformReserveAddress,
            _godfatherPrizeAddress,
            _puppyPrizeAddress
        );
    }

    function setFeeCollectorRatio(
        uint8 _feeCollectorRatio,
        uint8 _platformReserveRatio,
        uint8 _godfatherPrizeRatio,
        uint8 _puppyPrizeRatio
    ) external onlyOwner nonReentrant {
        uint8 totalRatio = _feeCollectorRatio + _platformReserveRatio + _godfatherPrizeRatio + _puppyPrizeRatio;
        require(totalRatio == 100, "MiniGame: Incorrect Ratio, total must equals 100");

        feeCollectorRatio = _feeCollectorRatio;
        platformReserveRatio = _platformReserveRatio;
        godfatherPrizeRatio = _godfatherPrizeRatio;
        puppyPrizeRatio = _puppyPrizeRatio;

        emit UpdateFeeCollectorRatio(feeCollectorRatio, platformReserveRatio, godfatherPrizeRatio, puppyPrizeRatio);
    }
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
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/ISamoyedGame.sol";
import "../tokens/GodfatherStorage.sol";
import "../tokens/PuppyStorage.sol";
import "../libraries/TransferHelper.sol";
import "../interfaces/IBEP20.sol";

abstract contract SamoyedGame is Ownable, ISamoyedGame {
    GodfatherStorage internal godfatherStorage;
    PuppyStorage internal puppyStorage;
    IBEP20 internal smoyToken;
    IBEP20 public busdToken;

    function getSmoyToken() external view override returns (IBEP20) {
        return smoyToken;
    }

    function getGodfatherStorage() external view override returns (GodfatherStorage) {
        return godfatherStorage;
    }

    function getPuppyStorage() external view override returns (PuppyStorage) {
        return puppyStorage;
    }

    function setGodfatherStorageAddress(GodfatherStorage _godfatherStorage) external override onlyOwner {
        godfatherStorage = _godfatherStorage;
    }

    function setPuppyStorageAddress(PuppyStorage _puppyStorage) external override onlyOwner {
        puppyStorage = _puppyStorage;
    }

    function collectFee(IBEP20 _token, uint256 _amount) internal {
        uint256 balance = _token.balanceOf(msg.sender);
        require(balance >= _amount, "MiniGame: INSUFFICIENT_BALANCE");
        TransferHelper.safeTransferFrom(address(_token), msg.sender, address(this), _amount);
    }

    function withdrawSmoy(uint256 _amount) external onlyOwner {
        uint256 balance = smoyToken.balanceOf(address(this));
        require(balance >= _amount, "MiniGame: INSUFFICIENT_BALANCE SMOY");
        TransferHelper.safeTransfer(address(smoyToken), msg.sender, _amount);
    }

    function withdrawBusd(uint256 _amount) external onlyOwner {
        uint256 balance = busdToken.balanceOf(address(this));
        require(balance >= _amount, "MiniGame: INSUFFICIENT_BALANCE BUSD");
        TransferHelper.safeTransfer(address(busdToken), msg.sender, _amount);
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
pragma solidity 0.8.4;

import "./IBEP20.sol";
import "../tokens/GodfatherStorage.sol";
import "../tokens/PuppyStorage.sol";

interface ISamoyedGame {
    function getSmoyToken() external view returns (IBEP20);

    function getGodfatherStorage() external view returns (GodfatherStorage);

    function getPuppyStorage() external view returns (PuppyStorage);

    function setGodfatherStorageAddress(GodfatherStorage _godfatherStorage) external;

    function setPuppyStorageAddress(PuppyStorage _puppyStorage) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "./SamoyedStorage.sol";


contract GodfatherStorage is SamoyedStorage {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;
    uint256[] public currentTicketNumber;

    uint256 constant seasonNumber = 1;
    uint256 constant ticketType = 6;

    uint256 constant godfatherStartSequence=6291456;

    constructor() ERC721("Godfather", "GFT") {
        currentTicketNumber = getTicketMin();
        currentTicketNumber[0]=godfatherStartSequence;
    }

    function bulkMint(
        address player,
        uint256 r,
        uint256 mintQuantity
    ) external nonReentrant returns (uint256[] memory) {
        require(canMint[msg.sender], "GodfatherStorage: UnAuthorizeds Minter");
        uint256 isRarityAllowedToBeMint = getAllowedRarityMinting()[r];
        require(isRarityAllowedToBeMint == 1, "GodfatherStorage: Unsupported Rarity");
        uint256[] memory tokenIDArray = new uint256[](mintQuantity);
        uint256 tcur = currentTicketNumber[r];
        uint256 tokenIDIndex=0;
        if( r ==0 ){
            for (uint256 i = 0; i < mintQuantity; i++) {
                uint256 randomTokenId = random(tcur+i,godfatherStartSequence);
                if(!_exists(randomTokenId)){
                    _mint(player, randomTokenId);
                    tokenIDArray[tokenIDIndex] = randomTokenId;
                    tokenIDIndex++;
                }
            }
        }
        uint256 tmin = getTicketMin()[r];
        uint256 tmax = getTicketMax()[r];
        uint256 trv = getTicketValue()[r];
        require(tcur >= tmin, "GodfatherStorage: Cannot Below Min Value");
        require(tcur + (trv * (mintQuantity-tokenIDIndex)) - 1 <= tmax, "GodfatherStorage: Cannot Exceed Max Value");
        for (uint256 i = tokenIDIndex; i < mintQuantity; i++) {
            _mint(player, tcur);
            tokenIDArray[i] = tcur;
            tcur += trv;
        }
        currentTicketNumber[r] = tcur;
        return tokenIDArray;
    }

    function getBaseTicket(uint256 ticket) public pure returns (uint256) {
        uint256 i = 6;
        bool foundTicket = false;
        uint256[6] memory tmin = getTicketMin();
        uint256[6] memory tmax = getTicketMax();
        uint256[6] memory trv = getTicketValue();
        uint256[6] memory rarityAllowed = getAllowedRarityMinting();
        while (i >= 1) {
            i--;
            if (rarityAllowed[i] == 0) {
                continue;
            }
            if (ticket >= tmin[i] && ticket <= tmax[i]) {
                foundTicket = true;
                break;
            }
        }
        if (foundTicket) {
            return (ticket - (ticket % trv[i]));
        } else {
            return 0;
        }
    }

    function getRarity(uint256 tokenId) public view returns (uint256 _trv) {
        require(_exists(tokenId), "GodfatherStorage: ERC721URIStorage: URI query for nonexistent token");
        uint256[6] memory tminArray = getTicketMin();
        uint256[6] memory tmaxArray = getTicketMax();
        for (uint256 i = 0; i < 6; i++) {
            if (tokenId >= tminArray[i] && tokenId <= tmaxArray[i]) {
                return i;
            }
        }
    }

    function getRarityValue(uint256 tokenId) public view returns (uint256 _trv) {
        return getTicketValue()[getRarity(tokenId)];
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "GodfatherStorage: ERC721URIStorage: URI query for nonexistent token");
        uint256 rarity = getRarity(tokenId);
        uint256[6] memory trv = getTicketValue();
        return
            string(
                abi.encodePacked(
                    '{"s":',
                    uint256ToString(seasonNumber),
                    ',"t":',
                    uint256ToString(ticketType),
                    ',"r":',
                    uint256ToString(trv[rarity]),
                    ',"n":',
                    uint256ToString(tokenId),
                    "}"
                )
            );
    }

    function getTokenInformation(uint256 tokenId)
        external
        view
        returns (
            uint256 _seasonNumber,
            uint256 _ticketType,
            uint256 _rarity,
            uint256 _ticketNumber
        )
    {
        require(_exists(tokenId), "PuppyStorage: ERC721URIStorage: URI query for nonexistent token");
        uint256 rarity = getRarity(tokenId);
        uint256[6] memory trv = getTicketValue();
        return (seasonNumber, ticketType, trv[rarity], tokenId);
    }

    function getTicketMin() private pure returns (uint256[6] memory) {
        return [uint256(0), 10485760, 0, 0, 0, 0];
    }

    function getTicketMax() private pure returns (uint256[6] memory) {
        return [uint256(10485759), 16777215, 0, 0, 0, 0];
    }

    function getTicketValue() private pure returns (uint256[6] memory) {
        return [uint256(1), 2, 0, 0, 0, 0];
    }

    function getAllowedRarityMinting() private pure returns (uint256[6] memory) {
        return [uint256(1), 1, 0, 0, 0, 0];
    }

    function random(uint256 salt,uint256 divisor) private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, salt))) % divisor;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./SamoyedStorage.sol";

// import "hardhat/console.sol";

contract PuppyStorage is SamoyedStorage {
    // Pupppy Counter
    struct PuppyCounter {
        uint128 currentPack;
        uint128 nextTicketNumber;
    }

    uint256 constant seasonNumber = 1;
    uint256 constant ticketType = 2;
    uint256 constant ticketDivider = 256;

    uint256 public maxPackAllowed = 10;

    PuppyCounter public puppyCounter;

    constructor() ERC721("Puppy", "PUP") {
        puppyCounter = PuppyCounter({currentPack: 0, nextTicketNumber: 0});
    }

    function getTicketSharingAddress(uint256 puppyNumber) public view returns (address[] memory) {
        PuppyCounter memory _puppyCounter = puppyCounter;
        uint256 holderQuantity = _puppyCounter.currentPack + 1;
        if (puppyNumber >= _puppyCounter.nextTicketNumber) {
            holderQuantity--;
        }

        address[] memory sharingHolder = new address[](holderQuantity);
        for (uint256 i = 0; i < holderQuantity; i++) {
            uint256 tokenId = (i * ticketDivider) + puppyNumber;
            //console.log("i: %d, tokenId: %d", i, tokenId);
            sharingHolder[i] = ownerOf(tokenId);
        }
        return sharingHolder;
    }

    function setMaxPackAllowed(uint256 value) external onlyOwner {
        maxPackAllowed = value;
    }

    function mint(address player) public nonReentrant returns (uint256) {
        require(canMint[msg.sender], "PuppyStorage: UnAuthorized Minter");
        PuppyCounter memory _puppyCounter = puppyCounter;
        require(_puppyCounter.currentPack <= maxPackAllowed, "PuppyStorage: No more pack left");

        uint256 tokenId = (_puppyCounter.currentPack * 256) + _puppyCounter.nextTicketNumber;
        _mint(player, tokenId);
        // _setTokenURI(
        //     tokenId,
        //     string(
        //         abi.encodePacked(
        //             '{"s":',
        //             uint256ToString(1),
        //             ',"t":',
        //             uint256ToString(2),
        //             ',"p":',
        //             uint256ToString(_puppyCounter.currentPack),
        //             ',"n":',
        //             uint256ToString(_puppyCounter.nextTicketNumber),
        //             "}"
        //         )
        //     )
        // );

        // if nextTicketNumber > 255 , Start New Pack
        _puppyCounter.nextTicketNumber++;
        if (_puppyCounter.nextTicketNumber > 255) {
            // Start New Pack
            puppyCounter = PuppyCounter({currentPack: ++_puppyCounter.currentPack, nextTicketNumber: 0});
        } else {
            puppyCounter = _puppyCounter;
        }

        return tokenId;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "PuppyStorage: ERC721URIStorage: URI query for nonexistent token");
        uint256 _pack;
        uint256 _ticketNumber;
        (_pack, _ticketNumber) = getPackAndNumber(tokenId);

        return
            string(
                abi.encodePacked(
                    '{"s":',
                    uint256ToString(seasonNumber),
                    ',"t":',
                    uint256ToString(ticketType),
                    ',"p":',
                    uint256ToString(_pack),
                    ',"n":',
                    uint256ToString(_ticketNumber),
                    "}"
                )
            );
    }

    function getTokenInformation(uint256 tokenId)
        external
        view
        returns (
            uint256 _seasonNumber,
            uint256 _ticketType,
            uint256 _pack,
            uint256 _ticketNumber
        )
    {
        require(_exists(tokenId), "PuppyStorage: ERC721URIStorage: URI query for nonexistent token");
        uint256 __pack;
        uint256 __ticketNumber;
        (__pack, __ticketNumber) = getPackAndNumber(tokenId);

        return (seasonNumber, ticketType, __pack, __ticketNumber);
    }

    function getPackAndNumber(uint256 tokenId) public pure returns (uint256, uint256) {
        uint256 _remainder = tokenId / ticketDivider;
        uint256 _modulus = tokenId % ticketDivider;
        return (_remainder, _modulus);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeApprove: approve failed"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeTransfer: transfer failed"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::transferFrom: transferFrom failed"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(
            success,
            "TransferHelper::safeTransferETH: ETH transfer failed"
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../interfaces/ISamoyedStorage.sol";

abstract contract SamoyedStorage is ERC721Enumerable, Ownable, ISamoyedStorage, ReentrancyGuard {
    // ERC721 TokenURI Storage
    // mapping(uint256 => string) private _tokenURIs;
    mapping(address => bool) public canMint;

    function burn(uint256 tokenId) private {
        _burn(tokenId);
    }

    function addCanMint(address minter) external override onlyOwner {
        canMint[minter] = true;
    }

    function removeCanMint(address minter) external override onlyOwner {
        canMint[minter] = false;
    }

    // function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
    //     require(_exists(tokenId), "SamoyedStorage: ERC721URIStorage: URI set of nonexistent token");
    //     _tokenURIs[tokenId] = _tokenURI;
    // }

    // function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    //     require(_exists(tokenId), "SamoyedStorage: ERC721URIStorage: URI query for nonexistent token");
    //     return _tokenURIs[tokenId];
    // }

    function uint256ToString(uint256 value) internal pure returns (string memory) {
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface ISamoyedStorage {
    function addCanMint(address minter) external;

    function removeCanMint(address minter) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

