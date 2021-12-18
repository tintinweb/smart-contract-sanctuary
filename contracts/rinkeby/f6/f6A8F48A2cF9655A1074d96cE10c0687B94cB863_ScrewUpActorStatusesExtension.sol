// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Interfaces/IScrewUpActorStatusesExtension.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./base/ScrewUpInGameActorExtension.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./Interfaces/IScrewUpActorStatusUpgradePointPolicy.sol";


contract ScrewUpActorStatusesExtension is ScrewUpInGameActorExtension, IScrewUpActorStatusesExtension {

    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _statusIds;
    Counters.Counter private _presetIds;
    Counters.Counter private _upgradeCateIds;
 
    //Status definition
    //statusId => maxvalue;
    mapping(uint256 => uint256) private _status_maxvalues;

    //statusId => maxvalue;
    mapping(uint256 => string) private _status_names;

    //statusId => maxvalue;
    mapping(uint256 => bool) private _status_defined;

    //statusId => upgradePointPolicy address.
    mapping(uint256 => address) private _status_upgradepoint_policies;

    //statusId => categoryId category.
    mapping(uint256 => uint256) private _status_upgradepoint_categories;


    //presetId => (statusId => presetValue)
    //Keep track of reset data.
    mapping(uint256 => mapping(uint256 => uint256)) private _presets;

    //Represet status preset name.
    mapping(uint256 => string) private _preset_names;

    //Represet status preset name.
    mapping(uint256 => bool) private _preset_defined;

    //cateid => defined or not.
    mapping(uint256 => bool) private _upgrade_category_defined;

    //categoryId => name category.
    mapping(uint256 => string) private _upgradepoint_category_names;


    //actorId => (statusId => value)
    mapping(uint256 => mapping(uint256 => uint256)) private  _actor_statuses;

    //actorId => preset_id
    mapping(uint256 => uint256) private  _actor_st_presets;

    //actorId => (categoryId => points)
    mapping(uint256 => mapping(uint256 => uint256)) private  _actor_upgrade_points;

    constructor(string memory name_,address contractAddress_) 
        ScrewUpInGameActorExtension(name_,contractAddress_){}

    //Fire when update status definition.
    event OnStatusDefinitionUpdated(uint256 statusId, uint256 maxValue, string name);

    //Fire when upgrade category changed
    event OnStatusPresetValueUpdated(uint256 presetId,uint256 id,uint256 value);
    
    //Fire when status preset symbol updated.
    event OnStatusPresetNameUpdated(uint256 presetId,string name);

    //Fire when upgrade category changed
    event OnUpgradePointCategoryUpdated(uint256 cateId, string name);
    
    event OnStatusUpgradePolicyChanged(uint256 statusId, address policyAddress);
    
    event OnStatusUpgradePointCategoryChanged(uint256 statusId, uint256 cateId);
    
    event OnActorStatusUpdated(uint256 indexed actorId,uint256 statusId,uint256 statusValue);
    
    event OnPointGained(uint256 indexed actorId,uint256 cateId,uint256 points);
    
    event OnPointConsumed(uint256 indexed actorId,uint256 cateId,uint256 points);


 
    function defineStatuses(string[] memory _names,uint256[] memory _maxValues) external onlyOwner returns(uint256[] memory) {
        require(_maxValues.length == _names.length,"Max value and symbol mismatch");
        uint256[] memory _outIds = new uint256[](_maxValues.length);
        for(uint256 i = 0; i < _maxValues.length; i++){
            _statusIds.increment();
            uint256 newStatusId = _statusIds.current();
            _status_maxvalues[newStatusId] = _maxValues[i];
            _status_names[newStatusId] = _names[i];
            _status_defined[newStatusId] = true;
            _outIds[i] = newStatusId;
            emit OnStatusDefinitionUpdated(newStatusId,_maxValues[i],_names[i]);
        }
        return _outIds;
    }
    function isStatusDefined(uint256 _statusId) public view virtual override returns(bool){
        return _status_defined[_statusId];
    }
    function changeStatusMaxvalues(uint256[] memory ids,uint256[] memory maxValues) external onlyOwner{
        require(ids.length == maxValues.length,"Max value and symbol mismatch");
        for(uint256 i = 0; i < ids.length; i++){
            if(_status_defined[ids[i]]){
                _status_maxvalues[ids[i]] = maxValues[i];
                emit OnStatusDefinitionUpdated(ids[i],maxValues[i],_status_names[ids[i]]);
            }
        }
    }
    function changeStatusNames(uint256[] memory ids,string[] memory names) external onlyOwner{
        require(ids.length == names.length,"Max value and symbol mismatch");
        for(uint256 i = 0; i < ids.length; i++){
            if(_status_defined[ids[i]]){
                _status_names[ids[i]] = names[i];
                emit OnStatusDefinitionUpdated(ids[i],_status_maxvalues[ids[i]],names[i]);
            }
        }
    }
    function setUpgradePointPolicy(uint256[] memory statusIds,address policyAddress) external onlyOwner{
        for(uint256 i = 0; i < statusIds.length; i++){
            if(_status_defined[statusIds[i]]){
                _status_upgradepoint_policies[statusIds[i]] = policyAddress;
                emit OnStatusUpgradePolicyChanged(statusIds[i],policyAddress);
            }
        }
    }
    function setUpgradePointPolicyToAll(address policyAddress) external onlyOwner{
        uint256 lastStatusId = _statusIds.current();
        for(uint256 sId = 1; sId <= lastStatusId; sId++){
            _status_upgradepoint_policies[sId] = policyAddress;
            emit OnStatusUpgradePolicyChanged(sId,policyAddress);
        }
    }

    function isStatusPresetDefined(uint256 presetId) public view returns (bool){
        return _preset_defined[presetId];
    }
    function defineStatusPresets(string memory preset_name,uint256[] memory _ids,uint256[] memory _values) external onlyOwner returns(uint256) {
        require(_ids.length == _values.length,"Status Ids and Preset values length misamatch");
        _presetIds.increment();
        uint256 newPresetId = _presetIds.current();
        _preset_names[newPresetId] = preset_name;
        _preset_defined[newPresetId] = true;
        _setStatusPresetValues(newPresetId,_ids,_values);
        emit OnStatusPresetNameUpdated(newPresetId,preset_name);
        return newPresetId;
    }
    function changePresetNames(uint256[] memory _ids,string[] memory _names) external onlyOwner {
        require(_ids.length == _names.length,"PresetId and Name length mismatch");
        for(uint256 i = 0; i < _ids.length; i++){
           if(_status_defined[_ids[i]]){
                _preset_names[_ids[i]] = _names[i];
                emit OnStatusPresetNameUpdated(_ids[i],_names[i]);
           }
        }
    }
    function changeStatusPresetValues(uint256 presetId,uint256[] memory _ids,uint256[] memory _values) external {
        require(isStatusPresetDefined(presetId),"Preset not defined");
        _setStatusPresetValues(presetId,_ids,_values);
    }
    function isUpgradePointCategoryDefined(uint256 cateId) public view returns (bool){
        return (cateId == 0) || _upgrade_category_defined[cateId];
    }
    function defineUpgradePointCategories(string[] memory names) external onlyOwner {
        for(uint256 i = 0; i < names.length; i++){
            _upgradeCateIds.increment();
            uint256 newCateId = _upgradeCateIds.current();
            _upgrade_category_defined[newCateId] = true;
            _upgradepoint_category_names[newCateId] = names[i];   
            emit OnUpgradePointCategoryUpdated(newCateId,names[i]);
        }
    }
    function changeUpgradePointCategoryNames(uint256[] memory cateIds,string[] memory names) external onlyOwner{
        require(cateIds.length == names.length);
        for(uint256 i = 0; i < cateIds.length; i++){
            if(isUpgradePointCategoryDefined(cateIds[i])){
                _upgradepoint_category_names[cateIds[i]] = names[i];  
                emit OnUpgradePointCategoryUpdated(cateIds[i],names[i]);
            }
        }
    }

    function setUpgradePointCategory(uint256[] memory statusIds,uint256 cateId) external onlyOwner{
        require(isUpgradePointCategoryDefined(cateId) ,"Upgrade category undefined");
        for(uint256 i = 0; i < statusIds.length; i++){
            if(_status_defined[statusIds[i]]){
               _status_upgradepoint_categories[statusIds[i]] = cateId;
               emit OnStatusUpgradePointCategoryChanged(statusIds[i],cateId);
            }
        }
    }
   
    function getStatusPresetDefinitions() external view virtual override returns (FStatusPresetDefinition[] memory){
        uint256 lastPresetId = _presetIds.current();
        FStatusPresetDefinition[] memory _metas = new FStatusPresetDefinition[](lastPresetId);
        for(uint256 pid = 1; pid <= lastPresetId; pid++){
            FStatusPresetDefinition memory _definition;
            _definition.Id = pid;
            _definition.Name = _preset_names[pid];
            
            uint256 lastStatusId = _statusIds.current();
            _definition.Values = new FPointValue[](lastStatusId);
            for(uint256 sId = 1; sId <=  lastStatusId; sId++)
                _definition.Values[sId-1] = FPointValue(sId, _presets[pid][sId]);
            _metas[pid-1] = _definition;
        }
        return _metas;
    }
    function getUpgradePointCategoryDefinitions() external view virtual override returns (FMetaElement[] memory){
        uint256 lastCateId = _upgradeCateIds.current();
        FMetaElement[] memory _metas = new FMetaElement[](lastCateId + 1);
        for(uint256 cId = 0; cId <= lastCateId; cId++)
            _metas[cId] = FMetaElement(cId,_upgradepoint_category_names[cId]);
        return _metas;
    }
    function getStatusDefinitions() external view virtual override returns (FStatusDefinition[] memory){
        uint256 lastStatusId = _statusIds.current();
        FStatusDefinition[] memory _metas = new FStatusDefinition[](lastStatusId);
        for(uint256 sId = 1; sId <= lastStatusId; sId++)
             _metas[sId-1] = FStatusDefinition(sId,_status_maxvalues[sId],_status_upgradepoint_policies[sId],_status_upgradepoint_categories[sId],_status_names[sId]);
        return _metas;
    }
    function upgradeStatusesFor(address _addr,uint256 actorId,uint256[] memory statusIds,uint256[] memory upgradePoints) external virtual override onlyOwnerOrGameActor{
       _upgradeStatusesWithPoint(_addr,actorId,statusIds,upgradePoints);
    }
    function addStatusesFor(address _addr,uint256 actorId,uint256[] memory sIds,uint256[] memory toAddValues) external virtual override onlyOwnerOrGameActor{
        require(_addr != address(0),"Null address");
        require(_isOwnedActor(_addr,actorId),"Not Owner");
        _addStatuses(actorId,sIds,toAddValues);
    }
    function gainUpgradePointFor(address _addr,uint256 actorId,uint256 categoryId,uint256 points) external virtual override onlyOwnerOrGameActor{
       _gainUpgradePoint(_addr,actorId,categoryId,points);
    }
    function initialStatusesFor(address _addr,uint256 actorId,uint256 presetId) external virtual override onlyOwnerOrGameActor{
        
        require(_addr != address(0),"Null address");
        require(_isOwnedActor(_addr,actorId),"Not Owner");
        _applyActorStatusesWithPreset(actorId,presetId);
        _actor_st_presets[actorId] = presetId;
    }
    function cleanUpStatusesFor(address _addr,uint256 actorId) external virtual override onlyOwnerOrGameActor{
        require(_addr != address(0),"Null address");
        require(_isOwnedActor(_addr,actorId),"Not Owner");
        _actor_st_presets[actorId] = 0;
    }

    function getUpgradePoints(uint256 actorId) external view virtual override returns (FPointValue[] memory){
       return _getUpgradePoints(actorId);
    }
    function getActorStatuses(uint256 actorId) external view virtual override returns(FPointValue[] memory){
       return _getActorStatuses(actorId);
    }
    function getActorDatas(uint256[] memory actorIds) external view virtual override returns(FActorStatuses[] memory){
        FActorStatuses[] memory _actors = new  FActorStatuses[](actorIds.length);
        for(uint256 i = 0; i < actorIds.length; i++){
            _actors[i].Statuses = _getActorStatuses(actorIds[i]);
            _actors[i].UpgradePoints = _getUpgradePoints(actorIds[i]);
        }
        return _actors;
    }
   
    function _gainUpgradePoint(address _addr,uint256 actorId,uint256 categoryId,uint256 point) internal{
        require(_addr != address(0),"Null address");
        require(_isOwnedActor(_addr,actorId),"Not Owner");
        require(isUpgradePointCategoryDefined(categoryId),"No Point category");
        _actor_upgrade_points[actorId][categoryId] = _actor_upgrade_points[actorId][categoryId].add(point);
        emit OnPointGained(actorId,categoryId,point);
    }
    function _trimUpgradePoint(uint256 actorId,uint256 cateId,uint256 toUsePoint) internal view returns(uint256){
        return (toUsePoint <= _actor_upgrade_points[actorId][cateId]) ? toUsePoint : _actor_upgrade_points[actorId][cateId];
    }
    function _upgradeStatusesWithPoint(address _addr,uint256 actorId,uint256[] memory sIds,uint256[] memory upgradePoints) internal{
        require(sIds.length == upgradePoints.length,"Status and Point mismatch");
        require(_addr != address(0),"Null address");
        require(_isOwnedActor(_addr,actorId),"Not Owner");

        for(uint256 i = 0; i < sIds.length; i++){
            if(_status_defined[sIds[i]]){
                address _policyAddr = _status_upgradepoint_policies[sIds[i]];
                if(_policyAddr != address(0))
                {
                    uint256 pointCategory = _status_upgradepoint_categories[sIds[i]];
                    uint256 toConsumedPoint = _trimUpgradePoint(actorId,pointCategory,upgradePoints[i]);
                    uint256 toAddValue = IScrewUpActorStatusUpgradePointPolicy(_policyAddr).getStatusValueToAddFromPoint(_actor_statuses[actorId][sIds[i]], toConsumedPoint);
                    if(toConsumedPoint > 0)
                    {
                        uint256 curValue = _actor_statuses[actorId][sIds[i]];
                        uint256 newValue = curValue.add(toAddValue);
                        uint256 maxValue = _status_maxvalues[sIds[i]];
                        if(newValue > maxValue)
                            newValue =  maxValue;
                        if(newValue > curValue){
                            _actor_statuses[actorId][sIds[i]] = newValue;
                            _actor_upgrade_points[actorId][pointCategory] = _actor_upgrade_points[actorId][pointCategory].sub(toConsumedPoint);
                            emit OnPointConsumed(actorId,pointCategory,toConsumedPoint);
                            emit OnActorStatusUpdated(actorId,sIds[i],newValue);
                        }
                    }
                }
            }
        }
    }
    function _applyStatuses(uint256 actorId,uint256[] memory sIds,uint256[] memory sValues) internal{
        for (uint256 i = 0; i <= sIds.length; i++) {
            if(_status_defined[sIds[i]]){
                 _actor_statuses[actorId][sIds[i]] = sValues[i];
                emit OnActorStatusUpdated(actorId,sIds[i],sValues[i]); 
            }
        }
    }
    function _addStatuses(uint256 actorId,uint256[] memory sIds,uint256[] memory toAddValues) internal{
        for (uint256 i = 0; i <= sIds.length; i++) 
        {
            if(_status_defined[sIds[i]]){
                uint256 newValue = _actor_statuses[actorId][sIds[i]].add(toAddValues[i]);
                _actor_statuses[actorId][sIds[i]] = newValue;
                emit OnActorStatusUpdated(actorId,sIds[i],newValue);
            }
        }
    }
    function _applyActorStatusesWithPreset(uint256 actorId,uint256 presetId) internal{
        uint256 lastStatusId = _statusIds.current();
        for(uint256 sId = 1; sId <= lastStatusId; sId++)
        {
            if(_status_defined[sId] && _presets[presetId][sId] > 0){
                _actor_statuses[actorId][sId] = _presets[presetId][sId];
                emit OnActorStatusUpdated(actorId,sId,_presets[presetId][sId]);
            }
        }
    }
    function _setStatusPresetValues(uint256 presetId,uint256[] memory _ids,uint256[] memory _values) internal {
        for(uint256 i = 0; i < _ids.length; i++){
            if(_status_defined[_ids[i]]){
                _presets[presetId][_ids[i]] = _values[i];
                emit OnStatusPresetValueUpdated(presetId,_ids[i], _values[i]);
            }
        }
    }
    function _getUpgradePoints(uint256 actorId) internal view  returns (FPointValue[] memory){
        uint256 lastUpgradeCateId = _upgradeCateIds.current();
        FPointValue[] memory _points = new FPointValue[](lastUpgradeCateId + 1);
        for(uint256 cId = 0; cId <= lastUpgradeCateId; cId++)
            _points[cId] = FPointValue(cId,_actor_upgrade_points[actorId][cId]);
        return _points;
    }
    function _getActorStatuses(uint256 actorId) internal view returns(FPointValue[] memory){
        uint256 lastStatusIds = _statusIds.current();
        FPointValue[] memory _statuses = new FPointValue[](lastStatusIds);
        for(uint256 sId = 1; sId <= lastStatusIds; sId++)
            _statuses[sId-1] = FPointValue(sId,_actor_statuses[actorId][sId]);
        return _statuses;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of use for all of ScrewUp NFT token.
 */
interface IScrewUpActorStatusesExtension {
   
    struct FPointValue {
        uint256 Id; 
        uint256 Value;
    }

    struct FMetaElement {
        uint256 Id; 
        string Name;
    }

    struct FStatusDefinition {
        uint256 Id; 
        uint256 MaxValue;
        address UpgradePointPolicy;
        uint256 UpgradePointCategory;
        string Name;
    }
    struct FStatusPresetDefinition{
        uint256 Id; 
        FPointValue[] Values;
        string Name;
    }
    struct FActorStatuses {
       FPointValue[] Statuses;
       FPointValue[] UpgradePoints;
    }

    function isStatusDefined(uint256 _statusId) external view returns (bool);
    function getUpgradePointCategoryDefinitions() external view returns (FMetaElement[] memory);
    
    function getStatusDefinitions() external view returns (FStatusDefinition[] memory);
    function getStatusPresetDefinitions() external view returns (FStatusPresetDefinition[] memory);
    
    function initialStatusesFor(address _addr,uint256 actorId,uint256 presetId) external;
    function cleanUpStatusesFor(address _addr,uint256 actorId) external;

    function getUpgradePoints(uint256 actorId) external view returns (FPointValue[] memory);
    function getActorStatuses(uint256 actorId) external view returns(FPointValue[] memory);   
    function getActorDatas(uint256[] memory actorIds) external view returns(FActorStatuses[] memory);

    function upgradeStatusesFor(address _addr,uint256 actorId,uint256[] memory statusIds,uint256[] memory upgradePoints) external;
    function addStatusesFor(address _addr,uint256 actorId,uint256[] memory sIds,uint256[] memory toAddValues) external;
    function gainUpgradePointFor(address _addr,uint256 actorId,uint256 categoryId,uint256 points) external;
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

import "../Interfaces/IScrewUpInGameActor.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract ScrewUpInGameActorExtension is Ownable {

    address private _gameActorContract = address(0);
    
    string private _instanceName;

    IScrewUpInGameActor _ga = IScrewUpInGameActor(address(0));
    
    constructor(string memory name_,address contractAddress_) {
       _instanceName = name_;
       _setGameActorContactAddress(contractAddress_);
    }

    function getName() external view returns (string memory){return _instanceName;}
    
    function _isOwnedActor(address _addr,uint256 actorId) internal view returns (bool){
       return (_gameActorContract != address(0)) && _ga.isOwnedActor(_addr, actorId);
    }
    function _isActorExists(uint256 actorId) internal view returns (bool){
         return (_gameActorContract != address(0)) && _ga.isActorExists(actorId);
    }
    function _hasGameActorContract() internal view returns (bool){return _gameActorContract != address(0);}
    function setGameActorContactAddress (address tokenAddress) external onlyOwner {
       _setGameActorContactAddress(tokenAddress);
    }
    modifier onlyOwnerOrGameActor() {
        require((owner() == msg.sender || msg.sender == _gameActorContract) && (msg.sender != address(0)), "Owner or Game Actor");
        _;
    }
    function _setGameActorContactAddress (address _addr) internal {
         _gameActorContract = _addr;
         _ga = IScrewUpInGameActor(_addr);
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

pragma solidity ^0.8.0;

/**
 * @dev Interface of use for all of ScrewUp NFT token.
 */
interface IScrewUpActorStatusUpgradePointPolicy {

    struct FUpgradePointEntity {
        uint256 thesholdValue;
        uint256 addValuePerPoint;
    }
    
    function getStatusValueToAddFromPoint(uint256 _currentStatusValue,uint256 _pointToUse) external view  returns (uint256);
    function getAllPointEntity() external view  returns (FUpgradePointEntity[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//import "../Interfaces/IScrewUpActorStatusesExtension.sol";
//import "../Interfaces/IScrewUpActorSpecimentsExtension.sol";
//import "../Interfaces/IScrewUpActorAppearanceExtension.sol";

/**
 * @dev Interface of use for all of ScrewUp NFT token.
 */
interface IScrewUpInGameActor {

    /*struct FActorData {
        uint256 ActorId; 
        string ActorName;
        IScrewUpActorStatusesExtension.FPointValue[] ActorStatuses;
        IScrewUpActorStatusesExtension.FPointValue[] ActorUpgradePoints;
        IScrewUpActorSpecimentsExtension.FDefinition ActorSpeciment;
        IScrewUpActorAppearanceExtension.FPartValue[] ActorAppearances;
    }*/

    //function getActors(uint256[] memory actorIds) external view returns(FActorData[] memory);
    
    struct FActor {
        uint256 ActorId; 
        uint256 SpcecimentId;
        string ActorName;
    }

    function createActorFor(address _add,string memory newName,uint256 specimentId,uint256 statusPresetId,uint256 appearancePresetId) external;
    function destroyActorFor(address _addr,uint256 actorId) external;

    function isOwnedActor(address _addr,uint256 actorId) external view returns(bool);
    function isActorExists(uint256 actorId) external view returns(bool);
    function getOwnedActors(address _addr) external view returns(FActor[] memory);

    function getStatusExtensionContact() external view returns(address);
    function getAppearanceExtensionContact() external view returns(address);
    function getSpecimentExtensionContact() external view returns(address);

    function addStatusesFor(address _addr,uint256 actorId,uint256[] memory _statusIds,uint256[] memory _toAddValues) external;
    function upgradeStatusesFor(address _addr,uint256 actorId,uint256[] memory statusIds,uint256[] memory upgradePoints) external;
    function gainUpgradePointFor(address _addr,uint256 actorId,uint256 categoryId,uint256 points) external;
    function changeActorNameFor(address _addr,uint256 actorId,string memory newName) external;
    function changeSpecimentFor(address _addr,uint256 actorId,uint256 specimentId) external;
    function changeAppearanceFor(address _addr,uint256 actorId,uint256 speciment,uint256[] memory pIds,uint256[] memory pValues) external; 
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