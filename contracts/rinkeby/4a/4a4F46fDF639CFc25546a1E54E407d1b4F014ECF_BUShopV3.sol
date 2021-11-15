pragma solidity 0.6.2;


import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "./interface/IBUFactoryV2.sol";
import "./interface/INFT.sol";
import "./interface/IPreSoldierFactory.sol";

contract BUShopV3 is Ownable, IERC721Receiver {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;

    uint256 constant BU_SOLDIER = 1;
    uint256 constant BU_DEFIER = 2;
    uint256 constant BU_IGNITER = 3;
    uint256 constant BU_GENERAL = 4;
    uint256 constant FOUR = 4;

    bytes32 private _randomHash;
    uint256 public _rateBase;
    uint256 public _maxClaimCount = 10;

    struct BuLottery {
        uint256 rate;
        uint256 cdBlocks;
        uint256 nextBlock;
    }

    struct BattleGround {
        string name;
        bool isOpen;
        uint256 assembleStartBlock;
        uint256 assembleEndBlock;
        uint256 assembleDiscount;
        uint256 endBlock;
        address[] payTokens;
    }

    struct BgPayType {
        bool enable;
        IERC20 payToken;
        uint256 tokenPrice;
        uint256 assembleAmount;
        uint256 totalAmount;
    }

    INFT _bu;
    IBUFactory _buFactory;
    INFT _preSoldier;
    IPreSoldierFactory _preSoldierFactory;

    mapping(uint256 => BattleGround) public _battleGrounds;
    mapping(uint256 => bool) public _existBattleGround;
    mapping(uint256 => uint256) public _preSoldierRecast;
    mapping(uint256 => BuLottery) public _buLotteries;

    mapping(uint256 => EnumerableSet.UintSet) private _bgCategories;
    mapping(uint256 => mapping(uint256 => EnumerableSet.UintSet)) private _bgNftTypes;

    mapping(uint256 => EnumerableSet.UintSet) private _bgPayTokens;
    mapping(uint256 => mapping(address => BgPayType)) private _bgPayTypes;

    event NFTReceived(address operator, address from, uint256 tokenId, bytes data);
    event NewBattleGround(uint256 bgId, string name, bool isOpen, uint256 assembleStartBlock, uint256 assembleEndBlock, uint256 assembleDiscount, uint256 endBlock);
    event ClaimBattleUnit(uint256 bgId, uint256 tokenId, uint256 category, uint256 nftType);
    event RecastPreSoldier(uint256 preSoldierId, uint256 buTokenId, uint256 category, uint256 nftType);
    event CombinePreSoldier(uint256[] preSoldierIds, uint256 buTokenId, uint256 category, uint256 nftType);

    modifier checkPayToken(uint256 bgId, address payToken) {
        require(_bgPayTypes[bgId][payToken].enable, "SOVI: unsupported token");
        _;
    }

    // @dev Initialize
    constructor (
        INFT bu,
        IBUFactory buFactory,
        INFT preSoldier,
        IPreSoldierFactory preSoldierFactory
    ) public {
        _bu = bu;
        _buFactory = buFactory;
        _preSoldier = preSoldier;
        _preSoldierFactory = preSoldierFactory;

        _rateBase = 10000;

        // Recast type mapping
        _preSoldierRecast[1] = 1;
        _preSoldierRecast[2] = 2;
        _preSoldierRecast[3] = 3;
        _preSoldierRecast[4] = 4;
        _preSoldierRecast[0] = 12;
    }

    function claim(uint256 bgId, address payToken, uint256 count) external payable checkPayToken(bgId, payToken) {
        BattleGround storage bg = _battleGrounds[bgId];
        bool isEnded = bg.endBlock > 0 && block.number >= bg.endBlock;
        require(bg.isOpen && !isEnded, "SOVI: not open");
        require(block.number >= bg.assembleStartBlock, "SOVI: not start");
        require(count > 0 && count <= _maxClaimCount, "SOVI: count error");
        require(_bgCategories[bgId].length() > 0, "SOVI: !categories");

        uint256 price = getPriceByToken(bgId, payToken).mul(count);
        require(price > 0, "SOVI: price error");
        if (payToken == address(0)) {
            require(msg.value >= price, "SOVI: insufficient cost");
        } else {
            IERC20(payToken).safeTransferFrom(msg.sender, address(this), price);
        }

        if (isAssemble(bgId)) {
            _bgPayTypes[bgId][payToken].assembleAmount = _bgPayTypes[bgId][payToken].assembleAmount.add(price);
        }
        _bgPayTypes[bgId][payToken].totalAmount = _bgPayTypes[bgId][payToken].totalAmount.add(price);

        for (uint256 idx; idx < count; idx ++) {
            lottery(bgId);
        }
    }

    function lottery(uint256 bgId) internal returns (uint256 tokenId){
        uint256 category = BU_SOLDIER;
        // [0~base)
        uint256 randomCategory = random(_rateBase) + 1;

        if (randomCategory <= _buLotteries[BU_GENERAL].rate && checkCategoryAndCD(bgId, BU_GENERAL)) {
            category = BU_GENERAL;
        } else if (randomCategory <= _buLotteries[BU_IGNITER].rate && checkCategoryAndCD(bgId, BU_IGNITER)) {
            category = BU_IGNITER;
        } else if (randomCategory <= _buLotteries[BU_DEFIER].rate && checkCategoryAndCD(bgId, BU_DEFIER)) {
            category = BU_DEFIER;
        }
        require(_bgNftTypes[bgId][category].length() > 0, "SOVI: empty");
        setCD(category);

        uint256 nftIdx = random(_bgNftTypes[bgId][category].length());
        uint256 nftType = _bgNftTypes[bgId][category].at(nftIdx);
        tokenId = _buFactory.mint(msg.sender, bgId, category, nftType, 1);

        emit ClaimBattleUnit(bgId, tokenId, category, nftType);
    }

    function random(uint256 size) internal returns (uint256) {
        require(size > 0);
        bytes32 hash = keccak256(abi.encodePacked(block.difficulty, now, msg.sender, _randomHash));
        _randomHash = hash;
        return uint256(hash) % size;
    }

    function checkCategoryAndCD(uint256 bgId, uint256 category) internal view returns (bool){
        return _bgCategories[bgId].contains(category) && block.number >= _buLotteries[category].nextBlock;
    }

    function setCD(uint256 categories) internal {
        _buLotteries[categories].nextBlock = block.number.add(_buLotteries[categories].cdBlocks);
    }

    function getPrice(uint256 bgId) public view returns (address[] memory, uint256[] memory){
        address[] memory tokens = _battleGrounds[bgId].payTokens;
        require(tokens.length > 0, "SOVI: !payTokens");

        uint256[] memory tokenPrices = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i ++) {
            tokenPrices[i] = getPriceByToken(bgId, tokens[i]);
        }

        return (tokens, tokenPrices);
    }

    function getPriceByToken(uint256 bgId, address payToken) public view returns (uint256){
        BattleGround storage bg = _battleGrounds[bgId];

        uint256 price = _bgPayTypes[bgId][payToken].tokenPrice;
        return isAssemble(bgId) ? price.mul(bg.assembleDiscount).div(100) : price;
    }

    function isAssemble(uint256 bgId) public view returns (bool){
        BattleGround storage bg = _battleGrounds[bgId];
        return block.number >= bg.assembleStartBlock && block.number < bg.assembleEndBlock;
    }

    // Recast pre soldiers into new ones
    function recastPreSoldiers(uint256 tokenId) external {
        require(tokenId > 0, "SOVI: tokenId error");

        _preSoldier.safeTransferFrom(msg.sender, address(this), tokenId);

        uint256 sType;
        (, sType,) = _preSoldierFactory.getPreSoldier(tokenId);

        uint256 nftType = _preSoldierRecast[sType];
        uint256 buTokenId = _buFactory.mint(msg.sender, 0, BU_DEFIER, nftType, 1);
        emit RecastPreSoldier(tokenId, buTokenId, BU_DEFIER, nftType);
    }

    // Combine former soldiers into new soldiers
    function combinePreSoldiers(uint256[] calldata tokenIds) external {
        require(tokenIds.length == FOUR, "SOVI: length != 4");
        uint256[] memory __tmp = new uint256[](FOUR);
        uint256 sType;
        for (uint256 idx = 0; idx < tokenIds.length; idx ++) {
            require(tokenIds[idx] > 0, "SOVI: tokenId error");

            (, sType,) = _preSoldierFactory.getPreSoldier(tokenIds[idx]);
            _preSoldier.safeTransferFrom(msg.sender, address(this), tokenIds[idx]);
            __tmp[sType - 1] = sType;
        }

        // Check for duplicates
        for (uint256 idx = 0; idx < __tmp.length; idx ++) {
            if (__tmp[idx] == 0) {
                revert("SOVI: duplicate token");
            }
        }

        uint256 nftType = _preSoldierRecast[0];
        uint256 buTokenId = _buFactory.mint(msg.sender, 0, BU_DEFIER, nftType, 1);
        emit CombinePreSoldier(tokenIds, buTokenId, BU_DEFIER, nftType);
    }

    function getBgCategories(uint256 bgId) external view returns (uint256[] memory) {
        uint256 len = _bgCategories[bgId].length();
        uint256[] memory categories = new uint256[](len);
        if (len > 0) {
            for (uint idx = 0; idx < len; idx ++) {
                categories[idx] = _bgCategories[bgId].at(idx);
            }
        }
        return categories;
    }

    function getBgNftTypes(uint256 bgId, uint256 category) external view returns (uint256[] memory) {
        uint256 len = _bgNftTypes[bgId][category].length();
        uint256[] memory nftTypes = new uint256[](len);
        if (len > 0) {
            for (uint idx = 0; idx < len; idx ++) {
                nftTypes[idx] = _bgNftTypes[bgId][category].at(idx);
            }
        }
        return nftTypes;
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data) override public returns (bytes4) {
        if (address(this) != operator) {
            return 0;
        }
        emit NFTReceived(operator, from, tokenId, data);
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    // ################## Functions for admin  ####################
    function addBattleGround(uint256 bgId, string calldata name, bool isOpen, uint256 assembleStartBlock, uint256 assembleEndBlock, uint256 assembleDiscount, uint256 endBlock, address[] calldata payTokens) external onlyOwner {
        require(!_existBattleGround[bgId], "SOVI: exist battle ground");

        _battleGrounds[bgId] = BattleGround(
        {
        name : name,
        isOpen : isOpen,
        assembleStartBlock : assembleStartBlock,
        assembleEndBlock : assembleEndBlock,
        assembleDiscount : assembleDiscount,
        endBlock : endBlock,
        payTokens : payTokens
        }
        );
        _existBattleGround[bgId] = true;
        emit NewBattleGround(bgId, name, isOpen, assembleStartBlock, assembleEndBlock, assembleDiscount, endBlock);
    }

    function setBattleGround(uint256 bgId, bool isOpen, uint256 assembleStartBlock, uint256 assembleEndBlock, uint256 assembleDiscount, uint256 endBlock) external onlyOwner {
        require(_existBattleGround[bgId], "SOVI: !exist battle ground");

        BattleGround storage bg = _battleGrounds[bgId];
        bg.isOpen = isOpen;
        bg.assembleStartBlock = assembleStartBlock;
        bg.assembleEndBlock = assembleEndBlock;
        bg.assembleDiscount = assembleDiscount;
        bg.endBlock = endBlock;
    }

    function addBgNftTypes(uint256 bgId, uint256 category, uint256[] calldata nftTypes) external onlyOwner {
        require(nftTypes.length > 0);
        _bgCategories[bgId].add(category);
        for (uint256 idx = 0; idx < nftTypes.length; idx ++) {
            _bgNftTypes[bgId][category].add(nftTypes[idx]);
        }
    }

    function removeBgNftTypes(uint256 bgId, uint256 category, uint256[] calldata nftTypes) external onlyOwner {
        require(nftTypes.length > 0);
        for (uint256 idx = 0; idx < nftTypes.length; idx ++) {
            _bgNftTypes[bgId][category].remove(nftTypes[idx]);
        }
        if (_bgNftTypes[bgId][category].length() == 0) {
            _bgCategories[bgId].remove(category);
        }
    }

    function setBgPayTypes(uint256 bgId, address payToken, uint256 tokenPrice) external onlyOwner {
        if (!_bgPayTypes[bgId][payToken].enable) {

            _battleGrounds[bgId].payTokens.push(payToken);
            _bgPayTypes[bgId][payToken] = BgPayType({enable : true, payToken : IERC20(payToken), tokenPrice : tokenPrice, assembleAmount : 0, totalAmount : 0});
        } else {
            _bgPayTypes[bgId][payToken].tokenPrice = tokenPrice;
        }
    }

    function removeBgPayTypes(uint256 bgId, address payToken) external onlyOwner checkPayToken(bgId, payToken) {
        delete _bgPayTypes[bgId][payToken];
    }

    function setBuLottery(uint256 category, uint256 rate, uint256 cdBlocks, uint256 nextBlock) external onlyOwner {
        _buLotteries[category].rate = rate;
        _buLotteries[category].cdBlocks = cdBlocks;
        if (nextBlock > 0) {
            _buLotteries[category].nextBlock = nextBlock;
        }
    }

    function setBuRateBase(uint256 newRateBase) external onlyOwner {
        _rateBase = newRateBase;
    }

    function setRecastMapping(uint256 oldType, uint256 newType) external onlyOwner {
        _preSoldierRecast[oldType] = newType;
    }

    function setMaxClaimCount(uint256 newCount) external onlyOwner {
        _maxClaimCount = newCount;
    }

    function mintForCampaign(uint256 ruleId, uint256 category, uint256 nftType, uint256 level, uint256 count) external onlyOwner {
        for (uint256 idx; idx < count; idx ++) {
            _buFactory.mint(msg.sender, ruleId, category, nftType, level);
        }
    }

    function fetchBalance(address _tokenAddress, address _receiverAddress, uint256 _amount) public onlyOwner {
        if (_receiverAddress == address(0)) {
            _receiverAddress = owner();
        }
        if (_tokenAddress == address(0)) {
            _amount = _amount == 0 ? address(this).balance : _amount;
            require(payable(_receiverAddress).send(_amount));
            return;
        }
        IERC20 token = IERC20(_tokenAddress);
        _amount = _amount == 0 ? token.balanceOf(address(this)) : _amount;
        token.transfer(_receiverAddress, _amount);
    }
}

pragma solidity ^0.6.2;


interface IBUFactory {

    function getSoldier(uint256 tokenId)
    external view
    returns (
        uint256 id,
        uint256 blockNum,
        uint256 ruleId,
        uint256 category,
        uint256 nftType,

        uint256 poc,
        uint256 pob,
        uint256 hp,
        uint256 reg
    );

    function getIgniter(uint256 tokenId)
    external view
    returns (
        uint256 id,
        uint256 blockNum,
        uint256 ruleId,
        uint256 category,
        uint256 nftType,

        uint256 poc,
        uint256 magic
    );

    function getDefier(uint256 tokenId)
    external view
    returns (
        uint256 id,
        uint256 blockNum,
        uint256 ruleId,
        uint256 category,
        uint256 nftType,

        uint256 poc,
        uint256 extra1,
        uint256 extra2,
        uint256 extra3,
        uint256 extra4
    );

    function getGeneral(uint256 tokenId)
    external view
    returns (
        uint256 id,
        uint256 blockNum,
        uint256 ruleId,
        uint256 category,
        uint256 nftType,

        uint256 poc,
        uint256 extra1,
        uint256 extra2,
        uint256 extra3,
        uint256 extra4,
        uint256 extra5,
        uint256 extra6
    );

    function getBattleUnit(uint256 tokenId) external view
    returns (
        uint256 id,
        uint256 blockNum,
        uint256 ruleId,
        uint256 category,
        uint256 nftType,

        uint256 poc,
        uint256[] memory extras
    );

    function mint(address receiver, uint256 ruleId, uint256 category, uint256 nftType, uint256 level) external returns (uint256);

    function upgrade(uint256 tokenId) external;

    function burn(uint256 tokenId) external;
}

pragma solidity ^0.6.2;

import "./IBUFactory.sol";


interface IBUFactoryV2 is IBUFactory {

    function increaseHP(uint256 tokenId, uint256 num) external;

    function decreaseHP(uint256 tokenId, uint256 num) external;
}

pragma solidity ^0.6.2;


import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface INFT is IERC721 {

    function mint(address to, uint256 tokenId) external returns (bool);

    function burn(uint256 tokenId) external;

    function addBanToken(uint256 tokenId) external;
}

pragma solidity ^0.6.2;

interface IPreSoldierFactory {
    function getPreSoldier(uint256 tokenId) external view
    returns (
        uint256 id,
        uint256 sType,
        uint256 weight
    );
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

