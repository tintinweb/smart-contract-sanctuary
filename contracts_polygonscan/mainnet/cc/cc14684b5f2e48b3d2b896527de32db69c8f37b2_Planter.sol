// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";
import "../access/IAccessRestriction.sol";
import "../gsn/RelayRecipient.sol";
import "./IPlanter.sol";

/** @title Planter contract */
contract Planter is Initializable, RelayRecipient, IPlanter {
    using SafeCastUpgradeable for uint256;

    struct PlanterData {
        uint8 planterType;
        uint8 status;
        uint16 countryCode;
        uint32 score;
        uint32 supplyCap;
        uint32 plantedCount;
        int64 longitude;
        int64 latitude;
    }

    /** NOTE {isPlanter} set inside the initialize to {true} */
    bool public override isPlanter;

    IAccessRestriction public accessRestriction;

    /** NOTE mapping of planter address to PlanterData */
    mapping(address => PlanterData) public override planters;

    /** NOTE mapping of planter address to address of invitedBy */
    mapping(address => address) public override invitedBy;

    /** NOTE mapping of planter address to organization address that planter is member of it */
    mapping(address => address) public override memberOf;

    /** NOTE mapping of organization address to mapping of planter address to portionValue */
    mapping(address => mapping(address => uint256))
        public
        override organizationMemberShare;

    /** NOTE modifier to check msg.sender has admin role */
    modifier onlyAdmin() {
        accessRestriction.ifAdmin(_msgSender());
        _;
    }

    /** NOTE modifier to check msg.sender has data manager role */
    modifier onlyDataManager() {
        accessRestriction.ifDataManager(_msgSender());
        _;
    }

    /** NOTE modifier for check if function is not paused */
    modifier ifNotPaused() {
        accessRestriction.ifNotPaused();
        _;
    }

    /** NOTE modifier for check _planter is exist*/
    modifier existPlanter(address _planter) {
        require(planters[_planter].planterType > 0, "Planter not exist");
        _;
    }

    /** NOTE modifier for check valid address */
    modifier validAddress(address _address) {
        require(_address != address(0), "Invalid address");
        _;
    }

    /** NOTE modifier for check msg.sender planterType is organization*/
    modifier onlyOrganization() {
        require(
            planters[_msgSender()].planterType == 2,
            "Planter not organization"
        );
        _;
    }

    /** NOTE modifier for check msg.sender has TreejerContract role*/
    modifier onlyTreejerContract() {
        accessRestriction.ifTreejerContract(_msgSender());
        _;
    }

    /// @inheritdoc IPlanter
    function initialize(address _accessRestrictionAddress)
        external
        override
        initializer
    {
        IAccessRestriction candidateContract = IAccessRestriction(
            _accessRestrictionAddress
        );
        require(candidateContract.isAccessRestriction());
        isPlanter = true;
        accessRestriction = candidateContract;
    }

    /// @inheritdoc IPlanter
    function setTrustedForwarder(address _address)
        external
        override
        onlyAdmin
        validAddress(_address)
    {
        trustedForwarder = _address;
    }

    /// @inheritdoc IPlanter
    function join(
        uint8 _planterType,
        int64 _longitude,
        int64 _latitude,
        uint16 _countryCode,
        address _invitedBy,
        address _organization
    ) external override ifNotPaused {
        require(
            accessRestriction.isPlanter(_msgSender()) &&
                planters[_msgSender()].planterType == 0,
            "Exist or not planter"
        );

        require(
            _planterType == 1 || _planterType == 3,
            "Invalid planterType"
        );

        if (_planterType == 3) {
            require(
                planters[_organization].planterType == 2,
                "Invalid organization"
            );
        }

        if (_invitedBy != address(0)) {
            require(
                _invitedBy != _msgSender() &&
                    accessRestriction.isPlanter(_invitedBy),
                "Invalid invitedBy"
            );

            invitedBy[_msgSender()] = _invitedBy;
        }

        uint8 status = 1;

        if (_planterType == 3) {
            memberOf[_msgSender()] = _organization;
            status = 0;
        }

        PlanterData storage planterData = planters[_msgSender()];

        planterData.planterType = _planterType;
        planterData.status = status;
        planterData.countryCode = _countryCode;
        planterData.supplyCap = 100;
        planterData.longitude = _longitude;
        planterData.latitude = _latitude;

        emit PlanterJoined(_msgSender());
    }

    /// @inheritdoc IPlanter
    function joinByAdmin(
        address _planter,
        uint8 _planterType,
        int64 _longitude,
        int64 _latitude,
        uint16 _countryCode,
        address _invitedBy,
        address _organization
    ) external override ifNotPaused onlyDataManager {
        require(
            accessRestriction.isPlanter(_planter) &&
                planters[_planter].planterType == 0,
            "Exist or not planter"
        );

        require(
            _planterType == 1 || _planterType == 3,
            "Invalid planterType"
        );

        if (_planterType == 3) {
            require(
                planters[_organization].planterType == 2,
                "Invalid organization"
            );

            memberOf[_planter] = _organization;
        }

        if (_invitedBy != address(0)) {
            require(
                _invitedBy != _planter &&
                    accessRestriction.isPlanter(_invitedBy),
                "Invalid invitedBy"
            );

            invitedBy[_planter] = _invitedBy;
        }

        PlanterData storage planterData = planters[_planter];

        planterData.planterType = _planterType;
        planterData.status = 1;
        planterData.countryCode = _countryCode;
        planterData.supplyCap = 100;
        planterData.longitude = _longitude;
        planterData.latitude = _latitude;

        emit PlanterJoined(_planter);
    }

    /// @inheritdoc IPlanter
    function joinOrganization(
        address _organization,
        int64 _longitude,
        int64 _latitude,
        uint16 _countryCode,
        uint32 _supplyCap,
        address _invitedBy
    ) external override ifNotPaused onlyDataManager {
        require(
            planters[_organization].planterType == 0 &&
                accessRestriction.isPlanter(_organization),
            "Exist or not planter"
        );

        if (_invitedBy != address(0)) {
            require(
                _invitedBy != _msgSender() &&
                    accessRestriction.isPlanter(_invitedBy),
                "Invalid invitedBy"
            );

            invitedBy[_organization] = _invitedBy;
        }

        PlanterData storage planterData = planters[_organization];

        planterData.planterType = 2;
        planterData.status = 1;
        planterData.countryCode = _countryCode;
        planterData.supplyCap = _supplyCap;
        planterData.longitude = _longitude;
        planterData.latitude = _latitude;

        emit OrganizationJoined(_organization);
    }

    /// @inheritdoc IPlanter
    function updatePlanterType(uint8 _planterType, address _organization)
        external
        override
        ifNotPaused
        existPlanter(_msgSender())
    {
        require(
            _planterType == 1 || _planterType == 3,
            "Invalid planterType"
        );

        PlanterData storage planterData = planters[_msgSender()];

        require(
            planterData.status == 0 || planterData.status == 1,
            "Invalid planter status"
        );

        require(planterData.planterType != 2, "Caller is organization");

        if (_planterType == 3) {
            require(
                planters[_organization].planterType == 2,
                "Invalid organization"
            );

            memberOf[_msgSender()] = _organization;

            planterData.status = 0;
        } else {
            require(
                planterData.planterType == 3,
                "Planter type same"
            );

            memberOf[_msgSender()] = address(0);

            if (planterData.status == 0) {
                planterData.status = 1;
            }
        }

        planterData.planterType = _planterType;

        emit PlanterUpdated(_msgSender());
    }

    /// @inheritdoc IPlanter
    function acceptPlanterByOrganization(address _planter, bool _acceptance)
        external
        override
        ifNotPaused
        onlyOrganization
    {
        require(
            memberOf[_planter] == _msgSender() &&
                planters[_planter].status == 0,
            "Request not exists"
        );

        PlanterData storage planterData = planters[_planter];

        if (_acceptance) {
            planterData.status = 1;

            emit AcceptedByOrganization(_planter);
        } else {
            planterData.status = 1;
            planterData.planterType = 1;
            memberOf[_planter] = address(0);

            emit RejectedByOrganization(_planter);
        }
    }

    /// @inheritdoc IPlanter
    function updateSupplyCap(address _planter, uint32 _supplyCap)
        external
        override
        ifNotPaused
        onlyDataManager
        existPlanter(_planter)
    {
        PlanterData storage planterData = planters[_planter];
        require(_supplyCap > planterData.plantedCount, "Invalid supplyCap");
        planterData.supplyCap = _supplyCap;
        if (planterData.status == 2) {
            planterData.status = 1;
        }
        emit PlanterUpdated(_planter);
    }

    /// @inheritdoc IPlanter
    function manageAssignedTreePermission(
        address _planter,
        address _assignedPlanterAddress
    ) external override onlyTreejerContract returns (bool) {
        PlanterData storage planterData = planters[_planter];
        if (planterData.planterType > 0) {
            if (
                planterData.status == 1 &&
                (_planter == _assignedPlanterAddress ||
                    (planterData.planterType == 3 &&
                        memberOf[_planter] == _assignedPlanterAddress))
            ) {
                planterData.plantedCount += 1;

                if (planterData.plantedCount >= planterData.supplyCap) {
                    planterData.status = 2;
                }
                return true;
            }
        }

        return false;
    }

    /// @inheritdoc IPlanter
    function updateOrganizationMemberShare(
        address _planter,
        uint256 _organizationMemberShareAmount
    ) external override ifNotPaused onlyOrganization {
        require(planters[_planter].status > 0, "Invalid planter status");
        require(memberOf[_planter] == _msgSender(), "Not memberOf");
        require(
            _organizationMemberShareAmount < 10001,
            "Invalid share"
        );

        organizationMemberShare[_msgSender()][
            _planter
        ] = _organizationMemberShareAmount;

        emit OrganizationMemberShareUpdated(_planter);
    }

    /// @inheritdoc IPlanter
    function reducePlantedCount(address _planter)
        external
        override
        existPlanter(_planter)
        onlyTreejerContract
    {
        PlanterData storage planterData = planters[_planter];

        planterData.plantedCount -= 1;

        if (planterData.status == 2) {
            planterData.status = 1;
        }
    }

    /// @inheritdoc IPlanter
    function manageTreePermission(address _planter)
        external
        override
        existPlanter(_planter)
        onlyTreejerContract
        returns (bool)
    {
        PlanterData storage planterData = planters[_planter];

        if (planterData.status == 1) {
            planterData.plantedCount += 1;

            if (planterData.plantedCount == planterData.supplyCap) {
                planterData.status = 2;
            }
            return true;
        }
        return false;
    }

    /// @inheritdoc IPlanter
    function getOrganizationMemberData(address _planter)
        external
        view
        override
        returns (
            bool,
            address,
            address,
            uint256
        )
    {
        PlanterData storage planterData = planters[_planter];
        if (planterData.status == 4 || planterData.planterType == 0) {
            return (false, address(0), address(0), 0);
        } else {
            if (
                planterData.planterType == 1 ||
                planterData.planterType == 2 ||
                planterData.status == 0
            ) {
                return (true, address(0), invitedBy[_planter], 10000);
            } else {
                return (
                    true,
                    memberOf[_planter],
                    invitedBy[_planter],
                    organizationMemberShare[memberOf[_planter]][_planter]
                );
            }
        }
    }

    /// @inheritdoc IPlanter
    function canAssignTree(address _planter)
        external
        view
        override
        returns (bool)
    {
        PlanterData storage planterData = planters[_planter];

        return planterData.status == 1 || planterData.planterType == 2;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

/** @title AccessRestriction interface*/

interface IAccessRestriction is IAccessControlUpgradeable {
    /** @dev pause functionality */
    function pause() external;

    /** @dev unpause functionality */
    function unpause() external;

    function initialize(address _deployer) external;

    /** @return true if AccessRestriction contract has been initialized  */
    function isAccessRestriction() external view returns (bool);

    /**
     * @dev check if given address is planter
     * @param _address input address
     */
    function ifPlanter(address _address) external view;

    /**
     * @dev check if given address has planter role
     * @param _address input address
     * @return if given address has planter role
     */
    function isPlanter(address _address) external view returns (bool);

    /**
     * @dev check if given address is admin
     * @param _address input address
     */
    function ifAdmin(address _address) external view;

    /**
     * @dev check if given address has admin role
     * @param _address input address
     * @return if given address has admin role
     */
    function isAdmin(address _address) external view returns (bool);

    /**
     * @dev check if given address is Treejer contract
     * @param _address input address
     */
    function ifTreejerContract(address _address) external view;

    /**
     * @dev check if given address has Treejer contract role
     * @param _address input address
     * @return if given address has Treejer contract role
     */
    function isTreejerContract(address _address) external view returns (bool);

    /**
     * @dev check if given address is data manager
     * @param _address input address
     */
    function ifDataManager(address _address) external view;

    /**
     * @dev check if given address has data manager role
     * @param _address input address
     * @return if given address has data manager role
     */
    function isDataManager(address _address) external view returns (bool);

    /**
     * @dev check if given address is verifier
     * @param _address input address
     */
    function ifVerifier(address _address) external view;

    /**
     * @dev check if given address has verifier role
     * @param _address input address
     * @return if given address has verifier role
     */
    function isVerifier(address _address) external view returns (bool);

    /**
     * @dev check if given address is script
     * @param _address input address
     */
    function ifScript(address _address) external view;

    /**
     * @dev check if given address has script role
     * @param _address input address
     * @return if given address has script role
     */
    function isScript(address _address) external view returns (bool);

    /**
     * @dev check if given address is DataManager or Treejer contract
     * @param _address input address
     */
    function ifDataManagerOrTreejerContract(address _address) external view;

    /** @dev check if functionality is not puased */
    function ifNotPaused() external view;

    /** @dev check if functionality is puased */
    function ifPaused() external view;

    /** @return if functionality is paused*/
    function paused() external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.6;

import "./../external/gsn/BaseRelayRecipient.sol";

/** @title RelayRecipient contract  */
contract RelayRecipient is BaseRelayRecipient {
    /** @dev return version recipient */
    function versionRecipient() external pure override returns (string memory) {
        return "2.2.0+treejer.irelayrecipient";
    }
}

// SPDX-License-Identifier: GPL-3.0-only
// solhint-disable no-inline-assembly
pragma solidity >=0.7.6;

import "./interfaces/IRelayRecipient.sol";

/**
 * A base contract to be inherited by any contract that want to receive relayed transactions
 * A subclass must use "_msgSender()" instead of "msg.sender"
 */
abstract contract BaseRelayRecipient is IRelayRecipient {
    /*
     * Forwarder singleton we accept calls from
     */
    address public trustedForwarder;

    function isTrustedForwarder(address forwarder)
        public
        view
        override
        returns (bool)
    {
        return forwarder == trustedForwarder;
    }

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, return the original sender.
     * otherwise, return `msg.sender`.
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender()
        internal
        view
        virtual
        override
        returns (address payable ret)
    {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return payable(msg.sender);
        }
    }

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise, return `msg.data`
     * should be used in the contract instead of msg.data, where the difference matters (e.g. when explicitly
     * signing or hashing the
     */
    function _msgData()
        internal
        view
        virtual
        override
        returns (bytes memory ret)
    {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length - 20];
        } else {
            return msg.data;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.7.6;

/**
 * a contract must implement this interface in order to support relayed transaction.
 * It is better to inherit the BaseRelayRecipient as its implementation.
 */
abstract contract IRelayRecipient {

    /**
     * return if the forwarder is trusted to forward relayed transactions to us.
     * the forwarder is required to verify the sender's signature, and verify
     * the call is not a replay.
     */
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, then the real sender is appended as the last 20 bytes
     * of the msg.data.
     * otherwise, return `msg.sender`
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal virtual view returns (address payable);

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise (if the call was made directly and not through the forwarder), return `msg.data`
     * should be used in the contract instead of msg.data, where this difference matters.
     */
    function _msgData() internal virtual view returns (bytes memory);

    function versionRecipient() external virtual view returns (string memory);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

interface IPlanter {
    /** @dev emitted when a planter join with address {planter} */
    event PlanterJoined(address planter);

    /** @dev emitted when an organization join with address {organization} */
    event OrganizationJoined(address organization);

    /** @dev emitted when a planters data updated (supplyCap , planterType) */
    event PlanterUpdated(address planter);

    /**
     * @dev emitted when a planter with address {planter} is
     * accepted by organization
     */
    event AcceptedByOrganization(address planter);

    /**
     * @dev emitted when a planter with address {planter} is
     * rejected by organization
     */
    event RejectedByOrganization(address planter);

    /** @dev emited when a planter with address {planter} payment portion updated */
    event OrganizationMemberShareUpdated(address planter);

    /** @dev set {_address} to trusted forwarder */
    function setTrustedForwarder(address _address) external;

    /**
     * @dev based on {_planterType} a planter can join as individual planter or
     * member of an organization
     * NOTE member of organization planter status set to pendding and wait to be
     * accepted by organization.
     * NOTE emit a {PlanterJoined} event
     * @param _planterType type of planter: 1 for individual and 3 for member of organization
     * @param _longitude longitude value
     * @param _latitude latitude value
     * @param _countryCode country code
     * @param _invitedBy address of referrer
     * @param _organization address of organization to be member of
     */
    function join(
        uint8 _planterType,
        int64 _longitude,
        int64 _latitude,
        uint16 _countryCode,
        address _invitedBy,
        address _organization
    ) external;

    /**
     * @dev admin add a individual planter or
     * member of an organization planter based on {_planterType}
     * NOTE member of organization planter status set to active and no need for
     * accepting by organization
     * NOTE emit a {PlanterJoined} event
     * @param _planter address of planter
     * @param _planterType type of planter: 1 for individual and 3 for member of organization
     * @param _longitude longitude value
     * @param _latitude latitude value
     * @param _countryCode country code
     * @param _invitedBy address of referrer
     * @param _organization address of organization to be member of
     */
    function joinByAdmin(
        address _planter,
        uint8 _planterType,
        int64 _longitude,
        int64 _latitude,
        uint16 _countryCode,
        address _invitedBy,
        address _organization
    ) external;

    /**
     * @dev admin add a planter as organization (planterType 2) so planterType 3
     * can be member of these planters.
     * NOTE emit a {OrganizationJoined} event
     * @param _organization address of organization planter
     * @param _longitude longitude value
     * @param _latitude latitude value
     * @param _countryCode country code
     * @param _supplyCap planting supplyCap of organization planter
     * @param _invitedBy address of referrer
     */

    function joinOrganization(
        address _organization,
        int64 _longitude,
        int64 _latitude,
        uint16 _countryCode,
        uint32 _supplyCap,
        address _invitedBy
    ) external;

    /**
     * @dev planter with planterType 1 , 3 can update their planterType
     * NOTE planterType 3 (member of organization) can change to
     * planterType 1 (individual planter) with input value {_planterType}
     * of 1 and zeroAddress as {_organization}
     * or choose other organization to be member of with
     * input value {_planterType} of 3 and {_organization}.
     * NOTE planterType 1 can only change to planterType 3 with input value
     * {_planter} of 3 and {_organization}
     * if planter planterType 3 choose another oraganization or planter with
     * planterType 1 change it's planterType to 3,they must be accepted by the
     * organization to be an active planter
     * NOTE emit a {PlanterUpdated} event
     * @param _planterType type of planter
     * @param _organization address of organization
     */
    function updatePlanterType(uint8 _planterType, address _organization)
        external;

    /**
     * @dev organization can accept planter to be it's member or reject
     * NOTE emit a {AcceptedByOrganization} or {RejectedByOrganization} event
     * @param _planter address of planter
     * @param _acceptance accept or reject
     */
    function acceptPlanterByOrganization(address _planter, bool _acceptance)
        external;

    /**
     * @dev admin update supplyCap of planter
     * NOTE emit a {PlanterUpdated} event
     * @param _planter address of planter to update supplyCap
     * @param _supplyCap supplyCap that set to planter supplyCap
     */
    function updateSupplyCap(address _planter, uint32 _supplyCap) external;

    /**
     * @dev return if a planter can plant a tree and increase planter plantedCount 1 time.
     * @param _planter address of planter who want to plant tree
     * @param _assignedPlanterAddress address of planter that tree assigned to
     * @return if a planter can plant a tree or not
     */
    function manageAssignedTreePermission(
        address _planter,
        address _assignedPlanterAddress
    ) external returns (bool);

    /**
     * @dev oragnization can update the share of its members
     * NOTE emit a {OrganizationMemberShareUpdated} event
     * @param _planter address of planter
     * @param _organizationMemberShareAmount member share value
     */
    function updateOrganizationMemberShare(
        address _planter,
        uint256 _organizationMemberShareAmount
    ) external;

    /**
     * @dev when planting of {_planter} rejected, plantedCount of {_planter}
     * must reduce by 1 and if planter status is full, set it to active.
     * @param _planter address of planter
     */
    function reducePlantedCount(address _planter) external;

    /**
     * @dev check that planter {_planter} can plant regular tree
     * NOTE if plantedCount reach to supplyCap status of planter
     * set to full (value of full is '2')
     * @param _planter address of planter
     * @return true in case of planter status is active (value of active is '1')
     */
    function manageTreePermission(address _planter) external returns (bool);

    /**
     * @dev initialize AccessRestriction contract and set true for isPlanter
     * @param _accessRestrictionAddress set to the address of AccessRestriction contract
     */
    function initialize(address _accessRestrictionAddress) external;

    /**
     * @return true in case of Planter contract has been initialized
     */
    function isPlanter() external view returns (bool);

    /**
     * @dev return planter data
     * @param _planter planter address to get data
     * @return planterType
     * @return status
     * @return countryCode
     * @return score
     * @return supplyCap
     * @return plantedCount
     * @return longitude
     * @return latitude
     */
    function planters(address _planter)
        external
        view
        returns (
            uint8 planterType,
            uint8 status,
            uint16 countryCode,
            uint32 score,
            uint32 supplyCap,
            uint32 plantedCount,
            int64 longitude,
            int64 latitude
        );

    /** @return referrer address of {_planter} */
    function invitedBy(address _planter) external view returns (address);

    /** @return organization address of {_planter} */
    function memberOf(address _planter) external view returns (address);

    /** @return share of {_planter} in {_organization} */
    function organizationMemberShare(address _organization, address _planter)
        external
        view
        returns (uint256);

    /**
     * @dev return organization member data
     * @param _planter address of organization member planter to get data
     * @return true in case of valid planter
     * @return address of organization that {_planter} is member of it.
     * @return address of referrer
     * @return share of {_plnater}
     */
    function getOrganizationMemberData(address _planter)
        external
        view
        returns (
            bool,
            address,
            address,
            uint256
        );

    /**
     * @dev check allowance to assign tree to planter
     * @param _planter address of assignee planter
     * @return true in case of active planter or orgnization planter and false otherwise
     */
    function canAssignTree(address _planter) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCastUpgradeable {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    function hasRole(bytes32 role, address account) external view returns (bool);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function renounceRole(bytes32 role, address account) external;
}

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
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