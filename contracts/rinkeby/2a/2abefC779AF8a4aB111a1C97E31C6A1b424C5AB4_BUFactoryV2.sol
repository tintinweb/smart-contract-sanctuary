pragma solidity 0.6.2;


import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/EnumerableMap.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interface/IBUFactory.sol";
import "./interface/INFT.sol";


contract BUFactory is IBUFactory, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using EnumerableMap for EnumerableMap.UintToAddressMap;

    uint256 constant HUNDRED = 100;

    uint256 constant BU_SOLDIER = 1;
    uint256 constant BU_DEFIER = 2;
    uint256 constant BU_IGNITER = 3;
    uint256 constant BU_GENERAL = 4;

    uint256 public _buId;
    INFT public _battleUnit;

    mapping(address => bool) public _minters;
    mapping(uint256 => BattleUnit) public _battleUnits;
    mapping(uint256 => BattleUnit) public _buTemplates;

    struct BattleUnit {
        uint256 id;
        uint256 blockNum;
        uint256 ruleId;
        uint256 category;
        uint256 nftType;
        uint256 level;
        uint256 levelFactor;
        uint256 poc;
        uint256[] extras;
    }

    event MintBattleUnit(
        uint256 indexed id,
        uint256 blockNum,
        uint256 ruleId,
        uint256 category,
        uint256 nftType,
        uint256 poc
    );

    event BurnBattleUnit(
        uint256 indexed id,
        uint256 category,
        uint256 nftType,
        uint256 poc
    );

    event UpgradeBattleUnit(
        uint256 indexed id,
        uint256 level
    );

    constructor (
        INFT bu
    ) public {
        require(address(bu) != address(0));
        _battleUnit = bu;
        _buId = 10000;
    }

    function addMinter(address minter) public onlyOwner {
        _minters[minter] = true;
    }

    function removeMinter(address minter) public onlyOwner {
        _minters[minter] = false;
    }

    function setCardId(uint256 newId) public onlyOwner {
        _buId = newId;
    }

    function setCardContract(address addr) public onlyOwner {
        _battleUnit = INFT(addr);
    }

    function addCardTemplate(uint256 category, uint256 nftType, uint256 level, uint256 levelFactor, uint256 poc, uint256[] memory extras) public onlyOwner {
        _buTemplates[nftType] = BattleUnit({id : 0, blockNum : 0, ruleId : 0, category : category, nftType : nftType, level : level, levelFactor : levelFactor, poc : poc, extras : extras});
    }

    function getSoldier(uint256 tokenId) override
    external view
    returns (
        uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256
    ){
        BattleUnit memory bu = getBU(tokenId);
        return (
        bu.id,
        bu.blockNum,
        bu.ruleId,
        bu.category,
        bu.nftType,
        bu.poc,
        bu.extras[0],
        bu.extras[1],
        bu.extras[2]
        );
    }

    function getIgniter(uint256 tokenId) override
    external view
    returns (
        uint256, uint256, uint256, uint256, uint256, uint256, uint256
    ){
        BattleUnit memory bu = getBU(tokenId);
        return (
        bu.id,
        bu.blockNum,
        bu.ruleId,
        bu.category,
        bu.nftType,
        bu.poc,
        bu.extras[0]
        );
    }

    function getDefier(uint256 tokenId) override
    external view
    returns (
        uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256
    ){
        BattleUnit memory bu = getBU(tokenId);
        return (
        bu.id,
        bu.blockNum,
        bu.ruleId,
        bu.category,
        bu.nftType,
        bu.poc,
        bu.extras[0],
        bu.extras[1],
        bu.extras[2],
        bu.extras[3]
        );
    }

    function getGeneral(uint256 tokenId) override
    external view
    returns (
        uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256
    ){
        BattleUnit memory bu = getBU(tokenId);
        return (
        bu.id,
        bu.blockNum,
        bu.ruleId,
        bu.category,
        bu.nftType,
        bu.poc,
        bu.extras[0],
        bu.extras[1],
        bu.extras[2],
        bu.extras[3],
        bu.extras[4],
        bu.extras[5]
        );
    }

    function getBattleUnit(uint256 tokenId) override public view
    returns (
        uint256, uint256, uint256, uint256, uint256, uint256, uint256[] memory extras
    ){
        BattleUnit memory bu = getBU(tokenId);
        return (
        bu.id,
        bu.blockNum,
        bu.ruleId,
        bu.category,
        bu.nftType,
        bu.poc,
        bu.extras
        );
    }

    function getBU(uint256 tokenId) internal view returns (BattleUnit memory) {
        BattleUnit memory bu = _battleUnits[tokenId];
        if (bu.levelFactor > 0 && bu.level > 1) {
            uint256 levelSub = bu.level.sub(1);
            for (uint256 idx = 0; idx < bu.extras.length; idx++) {
                if (bu.extras[idx] > 0) {
                    bu.extras[idx] = bu.extras[idx].mul((bu.levelFactor.add(1)) ** levelSub).div(100 ** levelSub);
                }
            }
            if (bu.poc > 0) {
                bu.poc = bu.poc.mul((bu.levelFactor.add(1)) ** levelSub).div(100 ** levelSub);
            }
        }
        return bu;
    }

    function getFactor(uint256 tokenId) public view returns (uint256){
        return HUNDRED.add(_battleUnits[tokenId].level.sub(1).mul(_battleUnits[tokenId].levelFactor));
    }

    function mint(address receiver, uint256 ruleId, uint256 category, uint256 nftType, uint256 level) override external returns (uint256){
        require(_minters[msg.sender], "!minter");
        _buId = _buId.add(1);

        BattleUnit memory bu;
        BattleUnit memory template = _buTemplates[nftType];

        bu.id = _buId;
        bu.blockNum = block.number;
        bu.ruleId = ruleId;

        bu.category = template.category;
        bu.nftType = template.nftType;
        bu.level = level;
        bu.poc = template.poc;
        bu.extras = template.extras;

        _battleUnits[_buId] = bu;
        _battleUnit.mint(receiver, _buId);
        return _buId;
    }

    function upgrade(uint256 tokenId) override external {
        require(_minters[msg.sender], "!minter");

        BattleUnit storage bu = _battleUnits[tokenId];
        require(bu.id > 0, "SOVI: not exist");

        bu.level = bu.level.add(1);

        emit UpgradeBattleUnit(tokenId, bu.level);
    }

    function burn(uint256 tokenId) override external {
        BattleUnit memory bu = _battleUnits[tokenId];
        require(bu.id > 0, "SOVI: not exist");

        _battleUnit.safeTransferFrom(msg.sender, address(this), tokenId);
        _battleUnit.burn(tokenId);

        emit BurnBattleUnit(bu.id, bu.category, bu.nftType, bu.poc);
        bu.id = 0;
        delete _battleUnits[tokenId];
    }
}

pragma solidity 0.6.2;


import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/EnumerableMap.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interface/IBUFactoryV2.sol";
import "./interface/INFT.sol";
import "./BUFactory.sol";


contract BUFactoryV2 is IBUFactoryV2, Ownable {
    using SafeMath for uint256;

    struct BattleUnit {
        uint256 id;
        uint256 blockNum;
        uint256 ruleId;
        uint256 category;
        uint256 nftType;
        uint256 level;
        uint256 levelFactor;

        uint256 poc;
        uint256[] extras;
    }

    event MintBattleUnit(
        uint256 indexed id,
        uint256 blockNum,
        uint256 ruleId,
        uint256 category,
        uint256 nftType,
        uint256 poc
    );

    event BurnBattleUnit(
        uint256 indexed id,
        uint256 category,
        uint256 nftType,
        uint256 poc
    );

    event UpgradeBattleUnit(
        uint256 indexed id,
        uint256 level
    );


    uint256 constant HUNDRED = 100;

    uint256 constant BU_SOLDIER = 1;
    uint256 constant BU_DEFIER = 2;
    uint256 constant BU_IGNITER = 3;
    uint256 constant BU_GENERAL = 4;

    IBUFactory public _buFactory;
    uint256 public _buId;
    INFT public _battleUnit;

    mapping(address => bool) public _minters;
    mapping(uint256 => BattleUnit) public _battleUnits;
    mapping(uint256 => BattleUnit) public _buTemplates;
    mapping(uint256 => uint256) public _buIncreaseHP;
    mapping(uint256 => uint256) public _buDecreaseHP;

    constructor (
        address bu_,
        address buFactory_
    ) public {
        require(bu_ != address(0));
        require(buFactory_ != address(0));

        _battleUnit = INFT(bu_);
        _buFactory = IBUFactory(buFactory_);
        _buId = 50000;
    }

    function addMinter(address minter) public onlyOwner {
        _minters[minter] = true;
    }

    function removeMinter(address minter) public onlyOwner {
        _minters[minter] = false;
    }

    function setCardId(uint256 newId) public onlyOwner {
        _buId = newId;
    }

    function setCardContract(address addr) public onlyOwner {
        _battleUnit = INFT(addr);
    }

    function addCardTemplate(uint256 category, uint256 nftType, uint256 level, uint256 levelFactor, uint256 poc, uint256[] memory extras) public onlyOwner {
        _buTemplates[nftType] = BattleUnit({id : 0, blockNum : 0, ruleId : 0, category : category, nftType : nftType, level : level, levelFactor : levelFactor, poc : poc, extras : extras});
    }

    function getSoldier(uint256 tokenId) override
    external view
    returns (
        uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256
    ){
        BattleUnit memory bu = getBU(tokenId);
        return (
        bu.id,
        bu.blockNum,
        bu.ruleId,
        bu.category,
        bu.nftType,
        bu.poc,
        bu.extras[0],
        bu.extras[1],
        bu.extras[2]
        );
    }

    function getIgniter(uint256 tokenId) override
    external view
    returns (
        uint256, uint256, uint256, uint256, uint256, uint256, uint256
    ){
        BattleUnit memory bu = getBU(tokenId);
        return (
        bu.id,
        bu.blockNum,
        bu.ruleId,
        bu.category,
        bu.nftType,
        bu.poc,
        bu.extras[0]
        );
    }

    function getDefier(uint256 tokenId) override
    external view
    returns (
        uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256
    ){
        BattleUnit memory bu = getBU(tokenId);
        return (
        bu.id,
        bu.blockNum,
        bu.ruleId,
        bu.category,
        bu.nftType,
        bu.poc,
        bu.extras[0],
        bu.extras[1],
        bu.extras[2],
        bu.extras[3]
        );
    }

    function getGeneral(uint256 tokenId) override
    external view
    returns (
        uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256
    ){
        BattleUnit memory bu = getBU(tokenId);
        return (
        bu.id,
        bu.blockNum,
        bu.ruleId,
        bu.category,
        bu.nftType,
        bu.poc,
        bu.extras[0],
        bu.extras[1],
        bu.extras[2],
        bu.extras[3],
        bu.extras[4],
        bu.extras[5]
        );
    }

    function getBattleUnit(uint256 tokenId) override public view
    returns (
        uint256, uint256, uint256, uint256, uint256, uint256, uint256[] memory extras
    ){
        BattleUnit memory bu = getBU(tokenId);
        return (
        bu.id,
        bu.blockNum,
        bu.ruleId,
        bu.category,
        bu.nftType,
        bu.poc,
        bu.extras
        );
    }

    function getBU(uint256 tokenId) internal view returns (BattleUnit memory) {
        BattleUnit memory bu = getV1(tokenId);
        if (bu.category == BU_SOLDIER) {
            uint256 _tmp = bu.extras[1].add(_buIncreaseHP[tokenId]);
            bu.extras[1] = _tmp < _buIncreaseHP[tokenId] ? _buIncreaseHP[tokenId].sub(_tmp) : 0;
        }
        return bu;
    }

    function getFactor(uint256 tokenId) public view returns (uint256){
        return HUNDRED.add(_battleUnits[tokenId].level.sub(1).mul(_battleUnits[tokenId].levelFactor));
    }

    function mint(address receiver, uint256 ruleId, uint256 category, uint256 nftType, uint256 level) override external returns (uint256){
        require(_minters[msg.sender], "!minter");
        _buId = _buId.add(1);

        BattleUnit memory bu;
        BattleUnit memory template = _buTemplates[nftType];

        bu.id = _buId;
        bu.blockNum = block.number;
        bu.ruleId = ruleId;

        bu.category = template.category;
        bu.nftType = template.nftType;
        bu.level = level;
        bu.poc = template.poc;
        bu.extras = template.extras;

        _battleUnits[_buId] = bu;
        _battleUnit.mint(receiver, _buId);
        return _buId;
    }

    function upgrade(uint256 tokenId) override external {
        require(_minters[msg.sender], "!minter");

        BattleUnit storage bu = _battleUnits[tokenId];
        require(bu.id > 0, "SOVI: not exist");

        bu.level = bu.level.add(1);

        emit UpgradeBattleUnit(tokenId, bu.level);
    }

    function burn(uint256 tokenId) override external {
        BattleUnit memory bu = _battleUnits[tokenId];
        require(bu.id > 0, "SOVI: not exist");

        _battleUnit.safeTransferFrom(msg.sender, address(this), tokenId);
        _battleUnit.burn(tokenId);

        emit BurnBattleUnit(bu.id, bu.category, bu.nftType, bu.poc);
        bu.id = 0;
        delete _battleUnits[tokenId];
    }

    function increaseHP(uint256 tokenId, uint256 num) override external {
        require(_minters[msg.sender], "!minter");
        _buIncreaseHP[tokenId] = _buIncreaseHP[tokenId].add(num);
    }

    function decreaseHP(uint256 tokenId, uint256 num) override external {
        require(_minters[msg.sender], "!minter");
        _buDecreaseHP[tokenId] = _buDecreaseHP[tokenId].add(num);
    }

    function getV1(uint256 tokenId_) internal view returns (BattleUnit memory bu){
        if (_battleUnits[tokenId_].id > 0) {
            bu = _battleUnits[tokenId_];
        }

        uint256 id;
        uint256 blockNum;
        uint256 ruleId;
        uint256 category;
        uint256 nftType;
        uint256 poc;
        uint256[] memory extras;
        (id, blockNum, ruleId, category, nftType, poc, extras) = _buFactory.getBattleUnit(tokenId_);

        bu.id = tokenId_;
        bu.blockNum = blockNum;
        bu.ruleId = ruleId;
        bu.category = category;
        bu.poc = poc;
        bu.nftType = nftType;
        bu.extras = extras;
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

import "../GSN/Context.sol";
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
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
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
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * As of v3.0.0, only maps of type `uint256 -> address` (`UintToAddressMap`) are
 * supported.
 */
library EnumerableMap {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct MapEntry {
        bytes32 _key;
        bytes32 _value;
    }

    struct Map {
        // Storage of map keys and values
        MapEntry[] _entries;

        // Position of the entry defined by a key in the `entries` array, plus 1
        // because index 0 means a key is not in the map.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function _set(Map storage map, bytes32 key, bytes32 value) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) { // Equivalent to !contains(map, key)
            map._entries.push(MapEntry({ _key: key, _value: value }));
            // The entry is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            map._entries[keyIndex - 1]._value = value;
            return false;
        }
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage map, bytes32 key) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) { // Equivalent to contains(map, key)
            // To delete a key-value pair from the _entries array in O(1), we swap the entry to delete with the last one
            // in the array, and then remove the last entry (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = keyIndex - 1;
            uint256 lastIndex = map._entries.length - 1;

            // When the entry to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            MapEntry storage lastEntry = map._entries[lastIndex];

            // Move the last entry to the index where the entry to delete is
            map._entries[toDeleteIndex] = lastEntry;
            // Update the index for the moved entry
            map._indexes[lastEntry._key] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved entry was stored
            map._entries.pop();

            // Delete the index for the deleted slot
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._indexes[key] != 0;
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }

   /**
    * @dev Returns the key-value pair stored at position `index` in the map. O(1).
    *
    * Note that there are no guarantees on the ordering of entries inside the
    * array, and it may change when more entries are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        require(map._entries.length > index, "EnumerableMap: index out of bounds");

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        return _get(map, key, "EnumerableMap: nonexistent key");
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     */
    function _get(Map storage map, bytes32 key, string memory errorMessage) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, errorMessage); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(UintToAddressMap storage map, uint256 key, address value) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

   /**
    * @dev Returns the element stored at position `index` in the set. O(1).
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint256(value)));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint256(_get(map._inner, bytes32(key))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     */
    function get(UintToAddressMap storage map, uint256 key, string memory errorMessage) internal view returns (address) {
        return address(uint256(_get(map._inner, bytes32(key), errorMessage)));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

    constructor () internal {
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