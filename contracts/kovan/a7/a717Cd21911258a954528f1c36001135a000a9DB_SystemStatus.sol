/**
 *Submitted for verification at Etherscan.io on 2021-05-21
*/

// Sources flattened with hardhat v2.3.0 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// File @openzeppelin/contracts/access/[email protected]


pragma solidity ^0.8.0;

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
    constructor () {
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


// File contracts/Interface/ISystemStatus.sol

interface ISystemStatus {


    // global access list controller
    function accessControl(bytes32 section, address account) external view returns (bool canSuspend, bool canResume);


    // Be similar with the feature of requir(), the following function is used to check whether the section is active or not.
    function requireSystemActive() external view;

    function requireRewardPoolActive() external view;

    function requireCollectionTradingActive() external view;

    function requireActivitiesActive() external view;

    function requireStableCoinActive() external view;

    function requireDAOActive() external view;

    // status of key functions of each system section
    // function voterecordingActive() external view;

    function requireFunctionActive(string memory functionname, bytes32 section) external view;


    // whether tbe system is upgrading or not
    function isSystemUpgrading() external view returns (bool);
    
    // check the details of suspension of each section.
    function getSuspensionStatus(bytes32 section) external view returns(
        bool suspend,
        uint reason,
        uint timestamp,
        address operator
    );

    function getFunctionSuspendstionStatus(string memory functionname, bytes32 section) external view returns(
        bool suspend,
        uint reason,
        uint timestamp,
        address operator
    );


}


// File contracts/SystemController/SystemStatus.sol

// the systemStatus contract is referring to Synthetix's logic
pragma solidity ^0.8.0;
contract SystemStatus is Ownable {

    struct Sectionstatus {
        bool canSuspend;
        bool canResume;
    }

    struct functionstatus {
        bytes32 functionname;
        bytes32 section;
        bool canSuspend;
        bool canResume;
    }

    mapping(bytes32 => mapping(address => Sectionstatus)) public SectionAccessControl;
    mapping(bytes32 => mapping(address => functionstatus)) public FunctionAccessControl;

    struct Suspendsion {
        bool suspended;
        // refer to synthetix's design 
        // 0 => no reason, 1 => upgrading, 2 => accident, 3+ => defined by system usage
        uint8 reason;
        uint timestamp;
        address operator;
    }
    mapping(bytes32 => Suspendsion) public SectionSuspendsionStatus;
    mapping(bytes32 => mapping (bytes32 => Suspendsion)) public FunctionSuspendsionStatus;

    // Suspension public systemSuspension;
    // Suspension public RewardPoolSuspension;
    // Suspension public CollectionTradingSuspension;
    // Suspension public ActivitiesSuspension;
    // Suspension public StableCoinSuspension;
    // Suspension public DAOSuspension;

    // uint public delay;

    uint248 public constant SUSPENSION_REASON_UPGRADE = 1;

    bytes32 public constant SECTION_SYSTEM = "System";
    bytes32 public constant SECTION_REWARDPOOL = "RewardPool";
    bytes32 public constant SECTION_COLLECTIONT_TRADING = "CollectionTrading";
    bytes32 public constant SECTION_ACTIVITIES = "Activities";
    bytes32 public constant SECTION_STABLECOIN = "StableCoin";
    bytes32 public constant SECTION_DAO = "DAO";

    bytes32 public constant TOKENMINT = "tokenmint";
    bytes32 public constant TOKENBURN = "tokenburn";
    bytes32 public constant RELEASE = "release";
    
    // constructor () {}

    /** ========== public view functions ========== */

    function isSystemUpgrading() public view returns (bool) {
        return SectionSuspendsionStatus[SECTION_SYSTEM].suspended && SectionSuspendsionStatus[SECTION_SYSTEM].reason == SUSPENSION_REASON_UPGRADE;
    }

    function getSectionSuspendsionStatus(bytes32 section) public view returns(
        bool suspended,
        uint reason,
        uint timestamp,
        address operator
        ) 
    {
        Suspendsion memory suspendsionStatus = SectionSuspendsionStatus[section];
        suspended = suspendsionStatus.suspended;
        reason = suspendsionStatus.reason;
        timestamp = suspendsionStatus.timestamp;
        operator = suspendsionStatus.operator;
    }
    
    function getFunctionSuspendstionStatus(bytes32 functionname, bytes32 section) public view returns(
        bool suspended,
        uint reason,
        uint timestamp,
        address operator
    )
    {
        Suspendsion memory suspendsionStatus = FunctionSuspendsionStatus[functionname][section];
        suspended = suspendsionStatus.suspended;
        reason = suspendsionStatus.reason;
        timestamp = suspendsionStatus.timestamp;
        operator = suspendsionStatus.operator;
    }

    function requireSystemActive() public view {
        _internalRequireSystemActive();
    }

    function requireRewardPoolActive() public view {
        _internalRequireSystemActive();
        _internalRequireRewardPoolActive();
    }

    function requireCollectionTradingActive() public view {
        _internalRequireSystemActive();
        _internalRequireCollectionTradingActive();
    }

    function requireActivitiesActive() public view {
        _internalRequireSystemActive();
        _internalRequireActivitiesActive();
    }

    function requireStableCoinActive() public view {
        _internalRequireSystemActive();
        _internalRequireStableCoinActive();
    }

    function requireDAOActive() public view {
        _internalRequireSystemActive();
        _internalRequireDAOActive();
    }


    /** ========== external mutative OnlyOwner functions ========== */

    // update section access list

    function updateSectionAccessControl(
        bytes32 section,
        address account,
        bool canSuspend,
        bool canResume
    ) external onlyOwner {
        _internalUpdateSectionAccessControl(section, account, canSuspend, canResume);
    }

    function updateSectionAccessControls(
        bytes32[] calldata sections,
        address[] calldata accounts,
        bool[] calldata canSuspends,
        bool[] calldata canResumes
    ) external onlyOwner {
        require(
            sections.length == accounts.length &&
            accounts.length == canSuspends.length &&
            canSuspends.length == canResumes.length,
            "Input array lengths must match"
        );
        for (uint i = 0; i < sections.length; i++) {
            _internalUpdateSectionAccessControl(sections[i], accounts[i], canSuspends[i], canResumes[i]);
        }
    }

    // update function access list

    function updateFunctionAccessControl(
        bytes32 functionname,
        bytes32 section,
        address account,
        bool canSuspend,
        bool canResume
    ) external onlyOwner {
        _internalUpdateFunctionAccessControl(functionname, section, account, canSuspend, canResume);
    }

    function updateFunctionAccessControls(
        bytes32[] memory functionnames,
        bytes32[] memory sections,
        address[] memory accounts,
        bool[] memory canSuspends,
        bool[] memory canResumes
    ) external onlyOwner {
        require(
            functionnames.length == sections.length &&
            sections.length == accounts.length &&
            accounts.length == canSuspends.length &&
            canSuspends.length == canResumes.length,
            "Input array lengths must match"
        );
    for (uint i = 0; i < sections.length; i++) {
            _internalUpdateFunctionAccessControl(functionnames[i], sections[i], accounts[i], canSuspends[i], canResumes[i]);
        }
    }

    /** ========== external mutative functions ========== */


    function SectionSuspend(bytes32 section, uint8 reason) external {
        _internalSectionSuspend(section, reason);

        uint timestamp = SectionSuspendsionStatus[section].timestamp;
        if(section == SECTION_SYSTEM) { emit SystemSuspended(reason,timestamp,_msgSender());}
        else if(section == SECTION_REWARDPOOL) { emit RewardPoolSuspended(reason,timestamp,_msgSender());}
        else if(section == SECTION_COLLECTIONT_TRADING) { emit CollectionTradingSuspended(reason,timestamp,_msgSender());}
        else if(section == SECTION_ACTIVITIES) { emit ActivitiesSuspended(reason,timestamp,_msgSender());}
        else if(section == SECTION_STABLECOIN) { emit StableCoinSuspended(reason,timestamp,_msgSender());}
        else if(section == SECTION_DAO) { emit DAOSuspended(reason,timestamp,_msgSender());}
    }

    function SectionResume(bytes32 section) external {
        _internalSectionResume(section);

        uint timestamp = SectionSuspendsionStatus[section].timestamp;
        if(section == SECTION_SYSTEM) { emit SystemResumed(timestamp, _msgSender());}
        else if(section == SECTION_REWARDPOOL) { emit RewardPoolResumed(timestamp, _msgSender());}
        else if(section == SECTION_COLLECTIONT_TRADING) { emit CollectionTradingResumed(timestamp, _msgSender());}
        else if(section == SECTION_ACTIVITIES) { emit ActivitiesResumed(timestamp, _msgSender());}
        else if(section == SECTION_STABLECOIN) { emit StableCoinResumed(timestamp, _msgSender());}
        else if(section == SECTION_DAO) { emit DAOResumed(timestamp, _msgSender());}
    }

    function FunctionSuspend(bytes32 functionname, bytes32 section, uint8 reason) external {
        _internalFunctionSuspend(functionname, section, reason);
        uint timestamp = FunctionSuspendsionStatus[functionname][section].timestamp;
        emit FunctionSuspended(functionname, section, reason, timestamp, _msgSender());
    }

    function FunctionResume(bytes32 functionname, bytes32 section) external {
        _internalFunctionResume(functionname, section);
        uint timestamp = FunctionSuspendsionStatus[functionname][section].timestamp;
        emit FunctionResumed(functionname, section, 0, timestamp, _msgSender());
    }
     

    /** ========== external view functions ========== */




    // function active requirement
    function requireFunctionActive(bytes32 functionname, bytes32 section) external view {
        if(section == SECTION_SYSTEM) { requireSystemActive(); }
        else if(section == SECTION_REWARDPOOL) { requireRewardPoolActive();}
        else if(section == SECTION_COLLECTIONT_TRADING) { requireCollectionTradingActive();}
        else if(section == SECTION_ACTIVITIES) { requireActivitiesActive();}
        else if(section == SECTION_STABLECOIN) { requireStableCoinActive();}
        else if(section == SECTION_DAO) { requireDAOActive();}

        _internalRequireFunctionActive(functionname,section);
    }






    /** ========== internal mutative functions ========== */

    // section internal suspend

    function _internalSectionSuspend(bytes32 section, uint8 reason) internal allownadmin {
        _requireSectionAccessToSuspend(section);
        _privateSectionSuspend(section, reason);

    }

    function _internalSectionResume(bytes32 section) internal allownadmin {
        _requireSectionAccessToResume(section);
        _privateSectionResume(section);
    }

    // function internal suspend

    function _internalFunctionSuspend(bytes32 functionname, bytes32 section, uint8 reason) internal allownadmin {
        _requireFunctionAccessToSuspend(functionname, section);
        _privateFunctionSuspend(functionname,section,reason);
    }

    function _internalFunctionResume(bytes32 functionname, bytes32 section) internal allownadmin {
        _requireFunctionAccessToResume(functionname, section);
        _privateFunctionResume(functionname, section);
    }

    // section access list update

    function _internalUpdateSectionAccessControl(
        bytes32 section,
        address account,
        bool canSuspend,
        bool canResume
    ) internal  {
        _privateUpdateSectionAccessControl(section, account, canSuspend,canResume);
    }

    // function access list update

    function _internalUpdateFunctionAccessControl(
        bytes32 functionname,
        bytes32 section,
        address account,
        bool canSuspend,
        bool canResume
    ) internal  {
        _privateUpdateFunctionAccessControl(functionname, section, account, canSuspend, canResume);
    }

    /** ========== internal view functions ========== */

    // section require access

    function _requireSectionAccessToSuspend(bytes32 section) internal view {
        require(SectionAccessControl[section][_msgSender()].canSuspend, "Restricted to access control list");
    }

    function _requireSectionAccessToResume(bytes32 section) internal view {
        require(SectionAccessControl[section][_msgSender()].canResume, "Restricted to access control list");
    }
    
    // function require access

    function _requireFunctionAccessToSuspend(bytes32 functionname, bytes32 section) internal view {
        require(
            section == SECTION_SYSTEM ||
            section == SECTION_REWARDPOOL ||
            section == SECTION_COLLECTIONT_TRADING ||
            section == SECTION_ACTIVITIES ||
            section == SECTION_STABLECOIN ||
            section == SECTION_DAO,
            "Invalid section supplied"
        );
        require(FunctionAccessControl[functionname][_msgSender()].section == section, "the section of this function don't match");
        require(FunctionAccessControl[functionname][_msgSender()].canSuspend, "Restricted to access control list");
    }

    function _requireFunctionAccessToResume(bytes32 functionname, bytes32 section) internal view {
        require(
            section == SECTION_SYSTEM ||
            section == SECTION_REWARDPOOL ||
            section == SECTION_COLLECTIONT_TRADING ||
            section == SECTION_ACTIVITIES ||
            section == SECTION_STABLECOIN ||
            section == SECTION_DAO,
            "Invalid section supplied"
        );
        require(FunctionAccessControl[functionname][_msgSender()].section == section, "the section of this function don't match");
        require(FunctionAccessControl[functionname][_msgSender()].canResume, "Restricted to access control list");
    }



    /** the following part is used to judge if each section of system is active or not. 
        that means the suspended is false or not. */


    function _internalRequireSystemActive() internal view {
        require(
            SectionSuspendsionStatus[SECTION_SYSTEM].suspended,
            SectionSuspendsionStatus[SECTION_SYSTEM].reason == SUSPENSION_REASON_UPGRADE
                ? "system is upgrading, please wait"
                : "system is suspended. Operation prohibited"
        );
    }

    function _internalRequireRewardPoolActive() internal view {
        require(SectionSuspendsionStatus[SECTION_REWARDPOOL].suspended, "RewardPool is suspended. Operation prohibited");
    }

    function _internalRequireCollectionTradingActive() internal view {
        require(SectionSuspendsionStatus[SECTION_COLLECTIONT_TRADING].suspended, "Collection Trading is suspended. Operation prohibited");
    }

    function _internalRequireActivitiesActive() internal view {
        require(SectionSuspendsionStatus[SECTION_ACTIVITIES].suspended, "Activities of system is suspended. Operation prohibited");
    }

    function _internalRequireStableCoinActive() internal view {
        require(SectionSuspendsionStatus[SECTION_STABLECOIN].suspended, "Stable Coin section is suspended. Operation prohibited");
    }

    function _internalRequireDAOActive() internal view {
        require(SectionSuspendsionStatus[SECTION_DAO].suspended, "DAO section is suspended. Operation prohibited");
    }



    /** the following part is used to judge if the function of each section of system is active or not. */

    function _internalRequireFunctionActive(bytes32 functionname, bytes32 section) internal view {
        require(FunctionSuspendsionStatus[functionname][section].suspended, "the current function is suspended, Operation prohibited");
    }






    /** ========== private mutative functions ========== */

    // section private suspend

    function _privateSectionSuspend(bytes32 section, uint8 reason) private {
        SectionSuspendsionStatus[section].suspended = true;
        SectionSuspendsionStatus[section].reason = reason;
        SectionSuspendsionStatus[section].timestamp = block.timestamp;
        SectionSuspendsionStatus[section].operator = _msgSender();
    }

    function _privateSectionResume(bytes32 section) private {
        SectionSuspendsionStatus[section].suspended = false;
        SectionSuspendsionStatus[section].reason = 0;
        SectionSuspendsionStatus[section].timestamp = 0;
        SectionSuspendsionStatus[section].operator = address(0);
    }

    function _privateUpdateSectionAccessControl(
        bytes32 section,
        address account,
        bool canSuspend,
        bool canResume
    ) private {
        require(
            section == SECTION_SYSTEM ||
            section == SECTION_REWARDPOOL ||
            section == SECTION_COLLECTIONT_TRADING ||
            section == SECTION_ACTIVITIES ||
            section == SECTION_STABLECOIN ||
            section == SECTION_DAO,
            "Invalid section supplied"
        );
        SectionAccessControl[section][account].canSuspend = canSuspend;
        SectionAccessControl[section][account].canResume = canResume;
        emit SectionAccessControlUpdated(section, account, canSuspend, canResume);
    }

    // fucntion private suspend

    function _privateFunctionSuspend(bytes32 functionname, bytes32 section, uint8 reason) private {
        FunctionSuspendsionStatus[functionname][section].suspended = true;
        FunctionSuspendsionStatus[functionname][section].reason = reason;
        FunctionSuspendsionStatus[functionname][section].timestamp = block.timestamp;
        FunctionSuspendsionStatus[functionname][section].operator = _msgSender();
    }

    function _privateFunctionResume(bytes32 functionname, bytes32 section) private {
        FunctionSuspendsionStatus[functionname][section].suspended = false;
        FunctionSuspendsionStatus[functionname][section].reason = 0;
        FunctionSuspendsionStatus[functionname][section].timestamp = 0;
        FunctionSuspendsionStatus[functionname][section].operator = address(0);
    }

    function _privateUpdateFunctionAccessControl(
        bytes32 functionname,
        bytes32 section,
        address account,
        bool canSuspend,
        bool canResume
    ) private {
        require(
            section == SECTION_SYSTEM ||
            section == SECTION_REWARDPOOL ||
            section == SECTION_COLLECTIONT_TRADING ||
            section == SECTION_ACTIVITIES ||
            section == SECTION_STABLECOIN ||
            section == SECTION_DAO,
            "Invalid section supplied"
        );
        FunctionAccessControl[functionname][account].functionname = functionname;
        FunctionAccessControl[functionname][account].section = section;
        FunctionAccessControl[functionname][account].canSuspend = canSuspend;
        FunctionAccessControl[functionname][account].canResume = canResume;
        emit FunctionAccessControlUpdated(functionname,section,account,canSuspend,canResume);
    }

    /** ========== modifier ========== */
    modifier allownadmin() {
        require(owner() == _msgSender(), "you're not the admin or authorized user");
        _;
    }

    /** ========== event ========== */
    event SectionAccessControlUpdated(bytes32 section, address account, bool canSuspend, bool canResume);
    event FunctionAccessControlUpdated(bytes32 functionname, bytes32 section, address account, bool canSuspend, bool canResume);

    event SystemSuspended(uint reason, uint timestamp, address operator);
    event RewardPoolSuspended(uint reason, uint timestamp, address operator);
    event CollectionTradingSuspended(uint reason, uint timestamp, address operator);
    event ActivitiesSuspended(uint reason, uint timestamp, address operator);
    event StableCoinSuspended(uint reason, uint timestamp, address operator);
    event DAOSuspended(uint reason, uint timestamp, address operator);

    event SystemResumed(uint timestamp, address operator);
    event RewardPoolResumed(uint timestamp, address operator);
    event CollectionTradingResumed(uint timestamp, address operator);
    event ActivitiesResumed(uint timestamp, address operator);
    event StableCoinResumed(uint timestamp, address operator);
    event DAOResumed(uint timestamp, address operator);

    event FunctionSuspended(bytes32 functionname, bytes32 section, uint reason, uint timestamp, address operator);
    event FunctionResumed(bytes32 functionname, bytes32 section, uint reason, uint timestamp, address operator);
}