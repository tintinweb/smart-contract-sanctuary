// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../../TokenSet.sol";

contract TokenSetArtDropAlphas is TokenSet {

    /**
     * Unordered List
     */
    constructor(
        address _registry,
        uint16 _traitId
        ) 
        TokenSet (
            "Alphas with ArtDrop Trait",
            _registry,
            _traitId
        ) {
    }

}

// TODO: refactor to use permille calls
//
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IECRegistry {
    function getImplementer(uint16 traitID) external view returns (address);
    function addressCanModifyTrait(address, uint16) external view returns (bool);
    function addressCanModifyTraits(address, uint16[] memory) external view returns (bool);
    function hasTrait(uint16 traitID, uint16 tokenID) external view returns (bool);
    function setTrait(uint16 traitID, uint16 tokenID, bool) external;
}

contract TokenSet is Ownable {

    IECRegistry                 public ECRegistry;
    uint16            immutable public traitId;
    bytes32                     public name;
    uint16                      public actualSize;
    mapping(uint16 => uint16)   public data;
    uint8                       public setType = 1;


    /**
     * Virtual data set, ordering not guaranteed because removal 
     * just replaces position with last item and decreases collection size
     */
    constructor(bytes32 _name, address _registry, uint16 _traitId) {
        name = _name;
        ECRegistry = IECRegistry(_registry);
        traitId = _traitId;
    }

    /**
     * @notice Add a token to the end of the list
     */
    function add(uint16 _id) public onlyAllowed {
        data[actualSize] = _id;
        actualSize++;
    }

    /**
     * @notice Add a token to the end of the list
     */
    function batchAdd(uint16[] calldata _id) public onlyAllowed {
        for(uint16 i = 0; i < _id.length; i++) {
            data[actualSize++] = _id[i];
        }
    }

    /**
     * @notice Remove the token at virtual position
     */
    function remove(uint32 _pos, uint16 _permille) public onlyAllowed {
        // copy value of last item in set to position and decrease length by 1
        actualSize--;
        data[getInternalPosition(_pos, _permille)] = data[actualSize];
    }

    /**
     * @notice Get the token at actual position
     */
    function getAtIndex(uint16 _index) public view returns (uint16) {
        return data[_index];
    }

    /**
     * @notice Get the token at virtual position
     */
    function get(uint32 _pos, uint16 _permille) public view returns (uint16) {
        return data[getInternalPosition(_pos, _permille)];
    }

    /**
     * @notice Retrieve list size
     */
    function size(uint16 _permille) public view returns (uint256) {
        return actualSize * _permille;
    }

    /**
     * @notice Retrieve internal position for a virtual position
     */
    function getInternalPosition(uint32 _pos, uint16 _permille) public view returns(uint16) {
        uint256 realPosition = _pos / _permille;
        require(realPosition < actualSize, "TokenSet: Index out of bounds.");
        return uint16(realPosition);
    }

    modifier onlyAllowed() {
        require(
            ECRegistry.addressCanModifyTrait(msg.sender, traitId),
            "TokenSet: Not Authorised" 
        );
        _;
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