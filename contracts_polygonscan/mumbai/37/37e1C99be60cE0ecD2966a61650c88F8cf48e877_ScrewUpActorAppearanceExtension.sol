// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./base/ScrewUpInGameActorExtension.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./Interfaces/IScrewUpActorAppearanceExtension.sol";

//This read-only contact use for keep combination with Character Appearance.
contract ScrewUpActorAppearanceExtension is ScrewUpInGameActorExtension,IScrewUpActorAppearanceExtension {

    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _partIds;
    Counters.Counter private _presetIds;

    //partId => EvalueType.
    mapping(uint256 => EValueType) private _part_valuetypes;
    
    //partId => ValueRange
    mapping(uint256 => FRange) private _part_valueranges;

    //partId => Enum
    mapping(uint256 => FEnum) private _part_valueenums;
    
    //partId => value types.
    mapping(uint256 => string) private _part_names;

    //partId => isDefined.
    mapping(uint256 => bool) private _part_defined;

    //Represet status preset name.
    mapping(uint256 => string) private _preset_names;

    //Preset id
    mapping(uint256 => bool) private _preset_defined;

    //Preset id for each speciment.
    mapping(uint256 => mapping(uint256 => bool)) private _preset_speciment_defined;

    //presetId => specimentId => (partId => presetValue)
    mapping(uint256 => mapping(uint256 => mapping(uint256 => uint256))) private _presets;

    //actorId => specimentId => (partId => value)
    mapping(uint256 => mapping(uint256 => mapping(uint256 => uint256))) private  _actor_appearances;

    //actorId =>  presetId
    mapping(uint256 =>  uint256) private  _actor_pt_presets;

    //Fire when update status definition.
    event OnPartDefinitionUpdated(uint256 partId,string partName,uint8 valueType,string valueTypeSymbol);

    //Fire when defined part enum value type updated
    event OnPartEnumUpdated(uint256 partId,uint256[] values,string[] names);

    //Fire when defined part range value type updated
    event OnPartRangeUpdated(uint256 partId,uint256 minValue,uint256 maxValue);

    //Fire when update status definition.
    event OnPartsPresetUpdated(uint256 presetId,uint256 specimentId,uint256 partId,uint256 partValue);

    event OnPartsPresetNameUpdated(uint256 presetId,string partName);

    //Fire when Actor appearance updated
    event OnActorAppearanceUpdated(uint256 indexed actorId,uint256 specimentId,uint256 _id,uint256 _value);

    mapping (EValueType => string) private _valueTypeToText;
    mapping (string => EValueType) private _textToValueType;

    constructor(string memory name_,address contractAddress_) 
        ScrewUpInGameActorExtension(name_,contractAddress_) {

           _valueTypeToText[EValueType.Enum] = "enum";
           _valueTypeToText[EValueType.Range] = "range";
           _valueTypeToText[EValueType.Vector4] = "vector4";
            
           _textToValueType["enum"] = EValueType.Enum;
           _textToValueType["range"] = EValueType.Range;
           _textToValueType["vector4"] = EValueType.Vector4;
        }

 
    function isPartDefined(uint256 partId) public view virtual override returns (bool){
        return _part_defined[partId];
    }
    function defineParts(string[] memory partNames, string[] memory  valueTypes) external onlyOwner returns(uint256[] memory) {
        require(partNames.length == valueTypes.length,"Name and Value length mismatch");
        uint256[] memory newPartIds = new uint256[](partNames.length);
        for(uint256 i = 0; i < partNames.length; i++){
            _partIds.increment();
            uint256 newPartId = _partIds.current();
            _part_defined[newPartId] = true;
            _part_names[newPartId] = partNames[i];
            _part_valuetypes[newPartId] =_textToValueType[valueTypes[i]];
            emit OnPartDefinitionUpdated(newPartId,_part_names[newPartId],uint8(_part_valuetypes[newPartId]),valueTypes[i]);
        }
        return newPartIds;
    }
    function setPartValueRange(uint256 partId,uint256 minValue,uint256 maxValue) external onlyOwner {
        require(_part_defined[partId],"Part not defined");
        require(_part_valuetypes[partId] == EValueType.Range,"Value type not scalar");
        _part_valueranges[partId] = FRange(minValue,maxValue);
       emit OnPartRangeUpdated(partId,minValue,maxValue);
    }
    function setPartValueEnum(uint256 partId,string[] memory optionNames,uint256[] memory optionValues) external onlyOwner{
        require(_part_defined[partId],"Part not defined");
        require(_part_valuetypes[partId] == EValueType.Enum,"Value type not scalar");
        _part_valueenums[partId] = FEnum(optionValues,optionNames);
        emit OnPartEnumUpdated(partId,optionValues,optionNames);
    }
    function updatePartNames(uint256[] memory partIds,string[] memory partNames) external onlyOwner {
        require(partIds.length == partNames.length,"Name and Id length mismatch");
        for(uint256 i = 0; i < partIds.length; i++){
            if(_part_defined[partIds[i]]){
                _part_names[partIds[i]] = partNames[i];
                EValueType valueType = _part_valuetypes[partIds[i]];
                emit OnPartDefinitionUpdated(partIds[i],partNames[i],uint8(valueType),_valueTypeToText[valueType]);
            }
        }
    }
    function updatePartValueTypes(uint256[] memory partIds,string[] memory valueTypes) external onlyOwner {
        require(partIds.length == valueTypes.length,"ValueTypes and Id length mismatch");
        for(uint256 i = 0; i < partIds.length; i++){
            if(_part_defined[partIds[i]]){
                EValueType newValueType = _getValueTypeByTypename(valueTypes[i]);
                if(_part_valuetypes[partIds[i]] != newValueType){
                    _part_valuetypes[partIds[i]] = newValueType;
                    delete _part_valueranges[partIds[i]];
                    delete _part_valueenums[partIds[i]];
                }
                emit OnPartDefinitionUpdated(partIds[i],_part_names[partIds[i]],uint8(newValueType),valueTypes[i]);
            }
        }
    }
    function getPartDefinitions() external view virtual override returns (FAppearancePart[] memory){
        uint256 lastPartId = _partIds.current();
        FAppearancePart[] memory _metas = new FAppearancePart[](lastPartId);
        for(uint256 pId = 1; pId <= lastPartId; pId++)
            _metas[pId-1] = FAppearancePart(pId,_part_valuetypes[pId],_part_valueranges[pId],_part_names[pId],_part_valueenums[pId]);
        return _metas;
    }
    function isPartsPresetDefined(uint256 presetId) public view returns (bool){
        return _preset_defined[presetId];
    }
    function definePartPreset(string memory presetName,uint256[] memory partIds,uint256[] memory partValues) external onlyOwner {
        require(partIds.length == partValues.length,"PartIds and Preset values length misamatch");
        _presetIds.increment();
        uint256 newPresetId = _presetIds.current();
        _preset_names[newPresetId] = presetName;
        _preset_defined[newPresetId] = true;
        for(uint256 i = 0; i < partIds.length; i++){
            _presets[newPresetId][0][partIds[i]] = partValues[i];
            emit OnPartsPresetUpdated(newPresetId,0,partIds[i],partValues[i]);
        }
        emit OnPartsPresetNameUpdated(newPresetId,presetName);
    }
    function updatePresetName(uint256[] memory presetIds,string[] memory presetNames) external onlyOwner {
       require(presetIds.length == presetNames.length,"Id and Name length mismatch");
       for(uint256 i = 0; i < presetIds.length; i++){
            _preset_names[presetIds[i]] = presetNames[i];
            emit OnPartsPresetNameUpdated(presetIds[i],presetNames[i]);
       }
    }
    function updatePresetValues(uint256 presetId,uint256 specimentId,uint256[] memory partIds,uint256[] memory partValues)  external onlyOwner{
        require(isPartsPresetDefined(presetId),"Id and Name length mismatch");
        for(uint256 i = 0; i < partIds.length; i++){
            _presets[presetId][specimentId][partIds[i]] = partValues[i];
            _preset_speciment_defined[presetId][specimentId] = true;
            emit OnPartsPresetUpdated(presetId,specimentId,partIds[i],partValues[i]);
        }
    }
    function getPartPresetDefinition(uint256 lastSpecimentId) external view virtual override returns (FPresetDeinition[] memory){
        uint256 lastPresetId = _presetIds.current();
        FPresetDeinition[] memory _metas = new FPresetDeinition[](lastPresetId);
        for(uint256 pId = 1; pId <= lastPresetId; pId++){
            FPresetDeinition memory _definition;
            _definition.Id = pId;
            _definition.Name = _preset_names[pId];
            _definition.Speciments = new FSpeciment[](lastSpecimentId + 1);
            for(uint256 spId = 0; spId <= lastSpecimentId; spId++){
                uint256 lastPartId = _partIds.current();
                _definition.Speciments[spId].SpecimentId = spId;
                _definition.Speciments[spId].Values = new FPartValue[](lastPartId);
                for(uint256 ptId = 1; ptId <=  lastPartId; ptId++)
                    _definition.Speciments[spId].Values[ptId-1] = FPartValue(ptId, _presets[pId][spId][ptId]);
                _metas[pId-1] = _definition;
            }
        }
        return _metas;
    }
    function changeAppearanceFor(address _addr,uint256 actorId,uint256 speciment,uint256[] memory pIds,uint256[] memory pValues) external virtual override onlyOwnerOrGameActor{
        
        require(_addr != address(0),"Null address");
        require(_hasGameActorContract(),"No GameActorContact");
        require(_isOwnedActor(_addr,actorId),"Not Owner");
        _applyActorAppearance(actorId,speciment,pIds,pValues);
    }
    function initialAppearanceFor(address _addr,uint256 actorId,uint256 specimentId,uint256 presetId) external virtual override onlyOwnerOrGameActor{
        
        require(_addr != address(0),"Null address");
        require(_hasGameActorContract(),"No GameActorContact");
        require(_isOwnedActor(_addr,actorId),"Not Owner");
        _applyActorAppearanceWithPreset(actorId,specimentId,presetId);
        _actor_pt_presets[actorId] = presetId;
    }
    function getActorsAppearances(uint256[] memory actorIds,uint256[] memory specimentIds) external view virtual override returns(FActorAppearances[] memory){
        require(actorIds.length == specimentIds.length,"Actor and Speciment Id mismatch");
        FActorAppearances[] memory _appearances = new FActorAppearances[](actorIds.length);
        for(uint256 i = 0; i < actorIds.length; i++)
           _appearances[i].Values = _getActorAppearances(actorIds[i],specimentIds[i]);
        return _appearances;
    }
    function getActorAppearances(uint256 actorId,uint256 specimentId) public view virtual override returns(FPartValue[] memory){
        return _getActorAppearances(actorId,specimentId);
    }
    function _applyActorAppearanceWithPreset(uint256 actorId,uint256 specimentId,uint256 presetId) internal{
        uint256 _specId = _preset_speciment_defined[presetId][specimentId] ? specimentId : 0;
        uint256 lastPartId = _partIds.current();
        for(uint256 ptId = 1; ptId <= lastPartId; ptId++){
           uint256 _preset = _presets[presetId][_specId][ptId];
           _actor_appearances[actorId][_specId][ptId] = _preset;
           emit OnActorAppearanceUpdated(actorId,_specId,ptId,_preset);
        }
    }
    function _applyActorAppearance(uint256 actorId,uint256 specimentId,uint256[] memory partIds,uint256[] memory partValues) internal{
        for (uint256 i = 1; i <= partIds.length; i++) {
            if(_part_defined[partIds[i]]){
                if(_checkPartValueToApply(partIds[i],partValues[i])){
                    _actor_appearances[actorId][specimentId][partIds[i]] = partValues[i];
                    emit OnActorAppearanceUpdated(actorId,specimentId,partIds[i],partValues[i]);
                }
            }
        }
    }
    function _checkPartValueToApply(uint256 partId,uint256 value) internal view returns (bool){
        if(_part_valuetypes[partId] == EValueType.Enum)
            return _isOneOfEnumChoice(partId,value);
        if(_part_valuetypes[partId] == EValueType.Range)
            return _isInRange(partId,value);
        return true;
    }
    function _isOneOfEnumChoice(uint256 partId,uint256 value) internal view returns(bool){
        require(_part_valueenums[partId].Values.length > 0,"Enum not defined");
        for(uint256 i = 0; i < _part_valueenums[partId].Values.length; i++){
            if(_part_valueenums[partId].Values[i] == value)
                return true;
        }
        return false;
    } 
    function _isInRange(uint256 partId,uint256 value) internal view returns(bool){
        uint256 _minValue = _part_valueranges[partId].MinValue;
        uint256 _maxValue = _part_valueranges[partId].MaxValue;
        if(_minValue == _maxValue && _minValue == 0)
            return true; //Range(0,0) mean no range.

        require(_minValue < _maxValue,"Range define but invalid");
        return value >= _minValue && value <= _maxValue;
    }
    function _getValueTypeByTypename(string memory valueType) internal view returns (EValueType) {
        return _textToValueType[valueType];
    }
    function _getValueTypeText(EValueType valueType) internal view returns (string memory) {
        return _valueTypeToText[valueType];
    }
    function _getActorAppearances(uint256 actorId,uint256 specimentId) internal view  returns(FPartValue[] memory){
        uint256 lastPartId = _partIds.current();
        FPartValue[] memory _appearances = new FPartValue[](lastPartId);
        for(uint256 ptId = 1; ptId <= lastPartId; ptId++)
            _appearances[ptId-1] = FPartValue(ptId,_actor_appearances[actorId][specimentId][ptId]);
        return _appearances;
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
interface IScrewUpActorAppearanceExtension{
   
    enum EValueType { None,Enum, Range, Vector4}
    
    struct FPartValue {
        uint256 Id; 
        uint256 Value;
    }
    struct FAppearancePart {
        uint256 PartId;
        EValueType ValueType;
        FRange Range;
        string PartName;
        FEnum Enum;
    }
    struct FPresetDeinition {
        uint256 Id;
        FSpeciment[] Speciments;
        string Name;
    }
    struct FSpeciment {
        uint256 SpecimentId; 
        FPartValue[] Values;
    }
    struct FRange{
        uint256 MinValue;
        uint256 MaxValue;
    }
    struct FEnum{
        uint256[] Values;
        string[] Names;
    }

    struct FActorAppearances{
        FPartValue[] Values;
    }

    function getActorsAppearances(uint256[] memory actorIds,uint256[] memory specimentIds) external view returns(FActorAppearances[] memory);
    function getActorAppearances(uint256 actorId,uint256 specimentId) external view returns(FPartValue[] memory);

    function isPartDefined(uint256 _partId) external view returns (bool);
    function getPartDefinitions() external view returns (FAppearancePart[] memory);
    
    function getPartPresetDefinition(uint256 lastSpecimentIds) external view returns (FPresetDeinition[] memory);
    function initialAppearanceFor(address _addr,uint256 actorId,uint256 specimentId,uint256 presetId) external;
    function changeAppearanceFor(address _addr,uint256 actorId,uint256 speciment,uint256[] memory pIds,uint256[] memory pValues) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of use for all of ScrewUp NFT token.
 */
interface IScrewUpInGameActor {

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