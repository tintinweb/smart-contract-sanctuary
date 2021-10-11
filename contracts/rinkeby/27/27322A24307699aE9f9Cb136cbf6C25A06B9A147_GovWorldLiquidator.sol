// SPDX-License-Identifier: agpl-3.0

pragma solidity ^0.8.0;
import "./GovLiquidatorBase.sol";
import "../../admin/admininterfaces/IGovWorldAdminRegistry.sol";

contract GovWorldLiquidator is GovLiquidatorBase {
    
    IGovWorldAdminRegistry govAdminRegistry;

    constructor(
        address _liquidator1,
        address _liquidator2,
        address _liquidator3,
        address _govWorldAdminRegistry
    ) {
        //owner becomes the default admin.
        _makeDefaultApproved(_liquidator1, LiquidatorAccess(true));
        _makeDefaultApproved(_liquidator2, LiquidatorAccess(true));
        _makeDefaultApproved(_liquidator3, LiquidatorAccess(true));

        govAdminRegistry = IGovWorldAdminRegistry(_govWorldAdminRegistry);
    }

    //modifier: only admin with AddTokenRole can add Token(s) or NFT(s)
    modifier onlyAddLiquidatorRole(address admin) {
        require(
            govAdminRegistry.isAddGovAdminRole(admin),
            "GL: msg.sender not a Gov Admin."
        );
        _;
    }

    /**
     * @dev makes _newLiquidator as a whitelisted liquidator
     * @param _newLiquidators Address of the new liquidators
     * @param _liquidatorRole access variables for _newLiquidator
     */
    function setLiquidator(
        address[] memory _newLiquidators,
        LiquidatorAccess[] memory _liquidatorRole
    ) external onlyAddLiquidatorRole(msg.sender) {
        for (uint256 i = 0; i < _newLiquidators.length; i++) {
            require(
                !_liquidatorExists(_newLiquidators[i], whitelistedLiquidators),
                "GL: Already Liquidator"
            );
            _makeDefaultApproved(_newLiquidators[i], _liquidatorRole[i]);
        }
    }

    function getAllLiquidators() public view returns (address[] memory) {
        return whitelistedLiquidators;
    }

    function getLiquidatorAccess(address _liquidator)
        public
        view
        returns (LiquidatorAccess memory)
    {
        return whitelistLiquidators[_liquidator];
    }
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "../../market/liquidator/IGovLiquidator.sol";

contract GovLiquidatorBase is Ownable, IGovLiquidator {

    //list of already approved liquidators.
    mapping(address => LiquidatorAccess) public whitelistLiquidators;

    //list of all approved liquidator addresses. Stores the key for mapping approvedLiquidators
    address[] whitelistedLiquidators;

    /**
    @dev function to check if address have liquidate role option
     */
    function isLiquidateAccess(address liquidator) external view override returns (bool) {
        return whitelistLiquidators[liquidator].liquidateRole;
    }
     /**
     * @dev makes _newLiquidator an approved liquidator and emits the event
     * @param _newLiquidator Address of the new liquidator
     * @param _liquidatorRole access variables for _newLiquidator
     */
    function _makeDefaultApproved(address _newLiquidator, LiquidatorAccess memory _liquidatorRole)
        internal
    {

        whitelistLiquidators[_newLiquidator] = _liquidatorRole;
        whitelistedLiquidators.push(_newLiquidator);
        
        emit NewLiquidatorApproved(_newLiquidator, _liquidatorRole);
    }

    function _liquidatorExists(address _liquidator, address [] memory from)
        internal
        pure
        returns (bool)
    {
        for (uint256 i = 0; i < from.length; i++) {
            if (from[i] == _liquidator) {
                return true;
            }
        }
        return false;
    }

}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

interface IGovWorldAdminRegistry {
    struct AdminAccess {
        //access-modifier variables to add projects to gov-intel
        bool addGovIntel;
        bool editGovIntel;
        //access-modifier variables to add tokens to gov-world protocol
        bool addToken;
        bool editToken;
        //access-modifier variables to add strategic partners to gov-world protocol
        bool addSp;
        bool editSp;
        //access-modifier variables to add gov-world admins to gov-world protocol
        bool addGovAdmin;
        bool editGovAdmin;
        //access-modifier variables to add bridges to gov-world protocol
        bool addBridge;
        bool editBridge;
        //access-modifier variables to add pools to gov-world protocol
        bool addPool;
        bool editPool;

        //superAdmin role assigned only by the super admin
        bool superAdmin;
    }

    event NewAdminApproved(address indexed _newAdmin, address indexed _addByAdmin);
    event NewAdminApprovedByAll(address indexed _newAdmin, AdminAccess _adminAccess);
    event RemoveAdminForApprove(address indexed _admin, address indexed _removedByAdmin);
    event AdminRemovedByAll(address indexed _admin, address indexed _removedByAdmin);
    event EditAdminApproved(address indexed _admin,address indexed _editedByAdmin);
    event AdminEditedApprovedByAll(address indexed _admin, AdminAccess _adminAccess);
    event AddAdminRejected(address indexed _newAdmin, address indexed _rejectByAdmin);
    event EditAdminRejected(address indexed _newAdmin, address indexed _rejectByAdmin);
    event RemoveAdminRejected(address indexed _newAdmin, address indexed _rejectByAdmin);
    event SuperAdminOwnershipTransfer(address indexed _superAdmin, AdminAccess _adminAccess);
    
    function isAddGovAdminRole(address admin)external view returns (bool);

    //using this function externally in Gov Tier Level Smart Contract
    function isEditAdminAccessGranted(address admin) external view returns (bool);

    //using this function externally in other Smart Contracts
    function isAddTokenRole(address admin) external view returns (bool);

    //using this function externally in other Smart Contracts
    function isEditTokenRole(address admin) external view returns (bool);

    //using this function externally in other Smart Contracts
    function isAddSpAccess(address admin) external view returns (bool);

    //using this function externally in other Smart Contracts
    function isEditSpAccess(address admin) external view returns (bool);

    //using this function externally in other Smart Contracts
    function isEditAPYPerAccess(address admin) external view returns (bool);
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

// SPDX-License-Identifier: agpl-3.0

pragma solidity ^0.8.0;

 struct LiquidatorAccess {
        bool liquidateRole;
    }

interface IGovLiquidator {

    event NewLiquidatorApproved(address indexed _newLiquidator, LiquidatorAccess _liquidatorRole);

    //using this function externally in the Token and NFT Loan Market Smart Contract
    function isLiquidateAccess(address liquidator) external view returns (bool);

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