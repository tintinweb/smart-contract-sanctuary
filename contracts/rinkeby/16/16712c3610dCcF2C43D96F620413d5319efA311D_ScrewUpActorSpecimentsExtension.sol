// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Interfaces/IScrewUpActorSpecimentsExtension.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./base/ScrewUpInGameActorExtension.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./Interfaces/IScrewUpActorStatusUpgradePointPolicy.sol";


contract ScrewUpActorSpecimentsExtension is ScrewUpInGameActorExtension, IScrewUpActorSpecimentsExtension {

    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _specimentIds;

    //specimentId => name;
    mapping(uint256 => string) private _speciment_names;

    //specimentId => bool;
    mapping(uint256 => bool) private _speciment_defined;

    //actorId => specimentId
    mapping(uint256 => uint256) private  _actor_speciments;


    constructor(string memory name_,address contractAddress_) 
        ScrewUpInGameActorExtension(name_,contractAddress_){}

    //Fire when update status definition.
    event OnSpeimentDefinitionUpdated(uint256 specimentId, string name);
    
    event OnActorSpecimentChanged(uint256 actorId,uint256 specimentId);
 
    function defineSpeciment(string[] memory _names) external onlyOwner returns(uint256[] memory) {
        require(_names.length > 0,"No speciment to define");
        uint256[] memory _outIds = new uint256[](_names.length);
        for(uint256 i = 0; i < _names.length; i++){
            _specimentIds.increment();
            uint256 newSpecimentId = _specimentIds.current();
            _speciment_names[newSpecimentId] = _names[i];
            _speciment_defined[newSpecimentId] = true;
            _outIds[i] = newSpecimentId;
            emit OnSpeimentDefinitionUpdated(newSpecimentId,_names[i]);
        }
        return _outIds;
    }
    function isSpecimentDefined(uint256 _specimentId) public view virtual override returns(bool){
        return _speciment_defined[_specimentId];
    }
    function changeSpecimentName(uint256[] memory specimentIds,string[] memory names) external onlyOwner{
        require(specimentIds.length == names.length,"Name and Id mismatch");
        for(uint256 i = 0; i < specimentIds.length; i++){
            if(_speciment_defined[specimentIds[i]]){
                _speciment_names[specimentIds[i]] = names[i];
                emit OnSpeimentDefinitionUpdated(specimentIds[i],names[i]);
            }
        }
    }
    function setSpecimentFor(address _addr,uint256 actorId,uint256 specimentId) external virtual override{
        require(_addr != address(0),"Null address");
        require(_isOwnedActor(_addr,actorId),"Not Owner");
        _actor_speciments[actorId] = specimentId;
        emit OnActorSpecimentChanged(actorId,specimentId);
    }
    function lastSpecimmentId() external view virtual override returns (uint256) {
        return _specimentIds.current();
    }
    function getSpecimentDefinitions() external view virtual override returns (FDefinition[] memory){
       uint256 lastSpecimentId =  _specimentIds.current();
       FDefinition[] memory _definitions = new FDefinition[](lastSpecimentId);
       for(uint256 spId = 1; spId <= lastSpecimentId; spId++)
           _definitions[spId-1] = FDefinition(spId,_speciment_names[spId]);
        return _definitions;
    }
    function getActorSpeciment(uint256 actorId) external view virtual override returns (uint256){
        return _actor_speciments[actorId];
    }
    function getSpeciments(uint256[] memory specimentIds) external view virtual override returns (FDefinition[] memory) {
       FDefinition[] memory _definitions = new FDefinition[](specimentIds.length);
       for(uint256 i = 0; i < specimentIds.length; i++)
           _definitions[i] = FDefinition(specimentIds[i],_speciment_names[specimentIds[i]]);
        return _definitions;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of use for all of ScrewUp NFT token.
 */
interface IScrewUpActorSpecimentsExtension{
   
    struct FDefinition {
        uint256 SpecimentId; 
        string SpecimentName;
    }

    function isSpecimentDefined(uint256 _specimentId) external view returns (bool);
    function setSpecimentFor(address _addr,uint256 actorId,uint256 specimentId) external;
    function lastSpecimmentId() external view returns (uint256);
    function getSpecimentDefinitions() external view returns (FDefinition[] memory);
    function getActorSpeciment(uint256 actorId) external view returns (uint256);
    function getSpeciments(uint256[] memory specimentIds) external view returns (FDefinition[] memory);
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