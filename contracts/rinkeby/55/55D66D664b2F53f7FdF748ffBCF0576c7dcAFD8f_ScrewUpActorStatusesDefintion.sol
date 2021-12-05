// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Interfaces/IScrewUpActorStatusesDefinition.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

//This read-only contact use for framing actor status on game
//Contain status definition and symbol.
//Contain upgrade policy contact address foreach status.
//Contain preset for init status for new actor.

contract ScrewUpActorStatusesDefintion is Ownable, IScrewUpActorStatusesDefinition {

    using SafeMath for uint256;
    
    //Status definition
    //statusId => upgradePointPolicy address.
    mapping(uint256 => FStatusDefinition) private _statusDefs;

    uint256[] private _statusIds;

    //statusId => upgradePointPolicy address.
    mapping(uint256 => address) private _upgradePointPolicies;

    //statusId => categoryId category.
    mapping(uint256 => uint256) private _upgradePointCategories;

    //categoryId => name category.
    mapping(uint256 => string) private _upgradeCategorySymbols;

    //presetId => (statusId => presetValue)
    //Keep track of reset data.
    mapping(uint256 => mapping(uint256 => uint256)) private _presets;

    //Represet status preset name.
    mapping(uint256 => string) private _presetNames;

    //Preset ids
    uint256[] private _presetIds;

    //Preset ids
    uint256[] private _upgradeCateIds;

    string private _title;

    constructor(string memory title_) {_title = title_;}

    //Fire when update status definition.
    event OnStatusDefinitionUpdated(uint256 statusId, uint256 maxValue, string name);

    //Fire when upgrade category changed
    event OnStatusPresetUpdated(uint256 presetId,uint256[] _ids,uint256[] _values);
    
    //Fire when status preset symbol updated.
    event OnStatusPresetSymbolUpdated(uint256 presetId,string symbol);

    //Fire when upgrade category changed
    event OnUpgradePointCategoryUpdated(uint256 cateId, string name);
    
    function getTitle() external view returns (string memory){return _title;}

    function _hasStatusId(uint256 _statusId) internal view returns(bool){
        for(uint256 i = 0; i < _statusIds.length; i++){
            if(_statusIds[i] == _statusId)
                return true;
        }
        return false;
    }
    function _hasPresetid(uint256 _presetId) internal view returns(bool){
        for(uint256 i = 0; i < _presetIds.length; i++){
            if(_presetIds[i] == _presetId)
                return true;
        }
        return false;
    } 
    function _hasUpgradeCategoryId(uint256 _cateId) internal view returns(bool){
        for(uint256 i = 0; i < _upgradeCateIds.length; i++){
            if(_upgradeCateIds[i] == _cateId)
                return true;
        }
        return false;
    }

    //Setup Status definition updatate.
    function updateStatusDefintion(uint256 _statusId,uint256 _maxValue,string memory _symbol) external onlyOwner {
        _statusDefs[_statusId] = FStatusDefinition(_maxValue,_symbol);
        if(!_hasStatusId(_statusId))
            _statusIds.push(_statusId);
        emit OnStatusDefinitionUpdated(_statusId,_maxValue,_symbol);
    }
    function updateSkillPointPolicy(uint256 _statusId,address _policyAddress) external onlyOwner{
        _upgradePointPolicies[_statusId] = _policyAddress;
    }
    function updateStatusPreset(uint256 _presetId,uint256[] memory _ids,uint256[] memory _values) external onlyOwner {
        require(_ids.length == _values.length,"Status Ids and Preset values length misamatch");
        if(!_hasPresetid(_presetId))
            _presetIds.push(_presetId);

        for(uint256 i = 0; i < _ids.length; i++)
            _presets[_presetId][_ids[i]] = _values[i];
        emit OnStatusPresetUpdated(_presetId,_ids, _values);
    }
    function updatePresetSymbols(uint256 _presetId,string memory _symbol) external onlyOwner {
        _presetNames[_presetId] = _symbol;
        emit OnStatusPresetSymbolUpdated(_presetId,_symbol);
    }
    function updateUpgradePointCategory(uint256 _cateId,string memory _symbol) external onlyOwner {
        if(!_hasUpgradeCategoryId(_cateId))
            _upgradeCateIds.push(_cateId);
        _upgradeCategorySymbols[_cateId] = _symbol;
       emit OnUpgradePointCategoryUpdated(_cateId,_symbol);
    }
 
    function getUpgradePointPolicy(uint256 _statusId) external view virtual override returns(address){
        return _upgradePointPolicies[_statusId];
    }
    function getStatusDefinition(uint256 _statusId) external view virtual override returns (uint256 _maxValue,string memory _symbol){
        _maxValue = _statusDefs[_statusId].MaxValue;
        _symbol = _statusDefs[_statusId].Symbol;
    }
    function hasStatusDefinition(uint256 _statusId) external view virtual override returns (bool){
        return (_statusDefs[_statusId].MaxValue > 0);
    }
    function getPresetStatuses(uint256 _presetId) external view virtual override returns (uint256[] memory _outIds,uint256[] memory _outValues){
        
        _outIds = new uint256[](_statusIds.length);
        _outValues = new uint256[](_statusIds.length);

        for(uint256 i = 0; i < _statusIds.length; i++){
           uint256 _preset = _presets[_presetId][_statusIds[i]];
           _outIds[i] = _statusIds[i];
           _outValues[i] = _preset;
        }
    }
    function getAllPresetsMetadata() external view virtual override returns (FMetaElement[] memory){
        FMetaElement[] memory _metas = new FMetaElement[](_presetIds.length);
        for(uint256 i = 0; i < _presetIds.length; i++)
            _metas[i] = FMetaElement(_presetIds[i],_presetNames[_presetIds[i]]);
        return _metas;
    }
    function getAllUpgradePointCategoriesMetadata() external view virtual override returns (FMetaElement[] memory){
       
        FMetaElement[] memory _metas = new FMetaElement[](_upgradeCateIds.length);
        for(uint256 i = 0; i < _upgradeCateIds.length; i++)
            _metas[i] = FMetaElement(_upgradeCateIds[i],_upgradeCategorySymbols[_upgradeCateIds[i]]);
        return _metas;
    }
    

    function getAllStatusesMetadata() external view virtual override returns (FMetaElement[] memory){return _getStatusesMetadata(_statusIds);}
    function getStatusesMetadata(uint256[] memory statusIds) external view virtual override returns (FMetaElement[] memory){ return _getStatusesMetadata(statusIds);}
    function getUpgradeCategoryId(uint256 _statusId) external view virtual override returns (uint256){
        return _upgradePointCategories[_statusId];
    }
    function getAllStatusIds() external view virtual override returns(uint256[] memory){
        return _statusIds;
    }
    function getPresetStatusIds(uint256 presetId) external view virtual override returns(uint256[] memory){
        uint256 statusCount = 0;
        for(uint256 i= 0; i< _statusIds.length; i++){
            if(_presets[presetId][_statusIds[i]] > 0)
               statusCount++;
        }
        uint256 Counter = 0;
        uint256[] memory _sIds = new uint256[](statusCount);
        for(uint256 i= 0; i< _statusIds.length; i++){
            if(_presets[presetId][_statusIds[i]] > 0)
            {
                _sIds[Counter] = _statusIds[i];
                Counter++;
            }
        }
        return _sIds;
    }
    function _getStatusesMetadata(uint256[] memory statusIds) internal view returns (FMetaElement[] memory){

        uint256 statusCount = 0;
        for(uint256 i = 0; i < statusIds.length; i++){
            if(_statusDefs[statusIds[i]].MaxValue > 0)
                statusCount++;
        }

        uint256 Counter = 0;
        FMetaElement[] memory _metas = new FMetaElement[](statusCount);
        for(uint256 i = 0; i < statusIds.length; i++)
        {
             if(_statusDefs[statusIds[i]].MaxValue > 0)
             {
                _metas[Counter] = FMetaElement(statusIds[i],_statusDefs[statusIds[i]].Symbol);
                Counter++;
             }
        }
        return _metas;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of use for all of ScrewUp NFT token.
 */
interface IScrewUpActorStatusesDefinition {
   
   struct FStatusDefinition {
        uint256 MaxValue; 
        string Symbol;
    }
    struct FStatusElement {
        uint256 statusId; 
        uint256 statusValue;
    }

    struct FMetaElement {
        uint256 Id; 
        string Symbol;
    }

    function getUpgradePointPolicy(uint256 _statusId) external view returns(address);
    function getUpgradeCategoryId(uint256 _statusId) external view returns (uint256);
    function getStatusDefinition(uint256 _statusId) external view returns (uint256 _maxValue,string memory _symbol);
    function hasStatusDefinition(uint256 _statusId) external view returns (bool);
    function getPresetStatuses(uint256 _presetId) external view returns (uint256[] memory _outIds,uint256[] memory _outValues);
    function getAllPresetsMetadata() external view returns (FMetaElement[] memory);
    function getAllStatusesMetadata() external view returns (FMetaElement[] memory);
    function getAllUpgradePointCategoriesMetadata() external view returns (FMetaElement[] memory);
    function getAllStatusIds() external view returns(uint256[] memory);
    function getPresetStatusIds(uint256 presetId) external view returns(uint256[] memory);
    function getStatusesMetadata(uint256[] memory statusIds) external view returns (FMetaElement[] memory);
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