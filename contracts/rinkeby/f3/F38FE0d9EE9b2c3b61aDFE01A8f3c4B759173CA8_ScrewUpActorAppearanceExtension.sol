// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./base/ScrewUpInGameActorExtension.sol";
import "./Interfaces/IScrewUpActorAppearanceExtension.sol";

//This read-only contact use for keep combination with Character Appearance.
contract ScrewUpActorAppearanceExtension is ScrewUpInGameActorExtension,IScrewUpActorAppearanceExtension {

    //Appearance part meta
    //partId => part meta data.
    mapping(uint256 => FAppearancePart) private _parts;

    uint256[] private _partIds;

    uint256[] private _presetIds;

    //Represet status preset name.
    mapping(uint256 => string) private _presetNames;

    //presetId => (partId => presetValue)
    mapping(uint256 => mapping(uint256 => uint256)) private _presets;

    //actorId => (partId => value)
    mapping(uint256 => mapping(uint256 => uint256)) private  _actor_appearances;

    //Fire when update status definition.
    event OnPartMetadataUpdated(uint256 partId,string partName,uint8 valueType);

    //Fire when Actor appearance updated
    event OnActorAppearancesUpdated(uint256 indexed actorId,uint256[] _ids,uint256[] _values);

    constructor(string memory name_,address contractAddress_) 
        ScrewUpInGameActorExtension(name_,contractAddress_) {
        
        }

    function _hasPartId(uint256 _partId) internal view returns(bool){
        for(uint256 i = 0; i < _partIds.length; i++){
            if(_partIds[i] == _partId)
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
    function updatePartPreset(uint256 _presetId,uint256[] memory _ids,uint256[] memory _values) external onlyOwner {
        require(_ids.length == _values.length,"Part Ids and Preset values length misamatch");
        if(!_hasPresetid(_presetId))
            _presetIds.push(_presetId);

        for(uint256 i = 0; i < _ids.length; i++)
            _presets[_presetId][_ids[i]] = _values[i];
    }
    function updatePresetName(uint256 _presetId,string memory _presetName) external onlyOwner {
        _presetNames[_presetId] = _presetName;
    }

    function updatePartData(uint256 _partId, uint8 _valueType,string memory _partname) external onlyOwner {
        _parts[_partId] = FAppearancePart(_partId,EValueType(_valueType),_partname);
        if(!_hasPartId(_partId))
            _partIds.push(_partId);
        emit OnPartMetadataUpdated(_partId,_partname,_valueType);
    }
    function updatePartName(uint256 _partId,string memory _partname) external onlyOwner {
        if(!_hasPartId(_partId))
            _partIds.push(_partId);
        _parts[_partId].PartName = _partname;
    }
    function hasPartDefined(uint256 _partId) external view virtual override returns (bool){
        return (_parts[_partId].ValueType != EValueType.None);
    }
    function getPartMeta(uint256 _partId) external view virtual override returns (FAppearancePart memory){
        return _parts[_partId];
    }
    function getAllPartsMeta() external view virtual override returns (FAppearancePart[] memory){
        uint256 partCount = 0;
        for(uint256 i = 0; i < _partIds.length; i++){
            if(_parts[_partIds[i]].ValueType != EValueType.None)
                partCount++;
        }

        uint256 counter = 0;
        FAppearancePart[] memory _metas = new FAppearancePart[](partCount);
        for(uint256 i = 0; i < _partIds.length; i++)
        {
            if(_parts[_partIds[i]].ValueType != EValueType.None)
            {
                _metas[counter] = _parts[_partIds[i]];
                counter++;
            }
        }
        return _metas;
    }
    function getPresetParts(uint256 _presetId) external view virtual override returns (uint256[] memory _outIds,uint256[] memory _outValues){
        
        _outIds = new uint256[](_partIds.length);
        _outValues = new uint256[](_partIds.length);

        for(uint256 i = 0; i < _partIds.length; i++){
           uint256 _preset = _presets[_presetId][_partIds[i]];
           _outIds[i] = _partIds[i];
           _outValues[i] = _preset;
        }
    }
    function getAllPresetsMetadata() external view virtual override returns (FPresetMeta[] memory){
        FPresetMeta[] memory _metas = new FPresetMeta[](_presetIds.length);
        for(uint256 i = 0; i < _presetIds.length; i++)
            _metas[i] = FPresetMeta(_presetIds[i],_presetNames[_presetIds[i]]);
        return _metas;
    }

    function changeAppearanceFor(address _addr,uint256 actorId,uint256[] memory pIds,uint256[] memory pValues) external onlyOwnerOrGameActor{
        
        require(_addr != address(0),"Null address");
        require(_hasGameActorContract(),"No GameActorContact");
        require(_isOwnedActor(_addr,actorId),"Not Owner");
        _applyActorAppearance(actorId,pIds,pValues);
    }
    function changeAppearance(uint256 actorId,uint256[] memory pIds,uint256[] memory pValues) external{
        require(msg.sender != address(0),"Null address");
        require(_hasGameActorContract(),"No GameActorContact");
        require(_isOwnedActor(msg.sender,actorId),"Not Owner");
        _applyActorAppearance(actorId,pIds,pValues);
    }
    function initialAppearanceFor(address _addr,uint256 actorId,uint256 presetId) external virtual override onlyOwnerOrGameActor{
        
        require(_addr != address(0),"Null address");
        require(_hasGameActorContract(),"No GameActorContact");
        require(_isOwnedActor(_addr,actorId),"Not Owner");
        _applyActorAppearanceWithPreset(actorId,presetId);
    }

    function _applyActorAppearanceWithPreset(uint256 actorId,uint256 presetId) internal{
        uint256[] memory _pIds = new uint256[](_partIds.length);
        uint256[] memory _pValues = new uint256[](_partIds.length);
        for(uint256 i = 0; i < _partIds.length; i++){
           uint256 _preset = _presets[presetId][_partIds[i]];
           _actor_appearances[actorId][_partIds[i]] = _preset;

           _pIds[i] = _partIds[i];
           _pValues[i] = _preset;
        }
        emit OnActorAppearancesUpdated(actorId,_pIds,_pValues);
    }
    function _applyActorAppearance(uint256 actorId,uint256[] memory pIds,uint256[] memory pValues) internal{
        for (uint256 i = 1; i <= pIds.length; i++) 
            _actor_appearances[actorId][pIds[i]] = pValues[i];
        emit OnActorAppearancesUpdated(actorId,pIds,pValues);
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
 * @dev Interface of use for all of ScrewUp NFT token.
 */
interface IScrewUpActorAppearanceExtension{
   
    enum EValueType { None,Enum, Scalar, Color}
    struct FAppearancePart {
        uint256 PartId;
        EValueType ValueType;
        string PartName;
    }
    struct FPresetMeta {
        uint256 Id; 
        string Symbol;
    }


    function hasPartDefined(uint256 _partId) external view returns (bool);
    function getPartMeta(uint256 _partId) external view returns (FAppearancePart memory);
    function getAllPartsMeta() external view returns (FAppearancePart[] memory);
    function getPresetParts(uint256 _presetId) external view returns (uint256[] memory _outIds,uint256[] memory _outValues);
    function getAllPresetsMetadata() external view returns (FPresetMeta[] memory);
    function initialAppearanceFor(address _addr,uint256 actorId,uint256 presetId) external;
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
 * @dev Interface of use for all of ScrewUp NFT token.
 */
interface IScrewUpInGameActor {

     struct FElement {
        uint256 Id; 
        uint256 Value;
    }

    function createActorFor(address _addr,uint256 statusPresetId,uint256 appearancePresetId) external;
    function destroyActorFor(address _addr,uint256 actorId) external;
    function getActorCount(address _addr) external view returns (uint256);
    function isOwnedActor(address _addr,uint256 actorId) external view returns(bool);
    function isActorExists(uint256 actorId) external view returns(bool);

    function getOwnedActors(address _addr) external view returns(uint256[] memory);
    

    function getStatusDefinitionContact() external view returns(address);
    function getAppearanceExtensionContact() external view returns(address);

    function addStatusesFor(address _addr,uint256 actorId,uint256[] memory _statusIds,uint256[] memory _toAddValues) external;
    function upgradeStatusesFor(address _addr,uint256 actorId,uint256[] memory statusIds,uint256[] memory upgradePoints) external;
    function gainUpgradePointFor(address _addr,uint256 actorId,uint256 categoryId,uint256 points) external;
}