// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../access/IAccessRestriction.sol";
import "../gsn/RelayRecipient.sol";
import "../tree/ITree.sol";
import "../treasury/IPlanterFund.sol";
import "../planter/IPlanter.sol";
import "./ITreeFactory.sol";

/** @title TreeFactory Contract */
contract TreeFactory is Initializable, RelayRecipient, ITreeFactory {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using SafeCastUpgradeable for uint256;
    using SafeCastUpgradeable for uint32;

    struct TreeData {
        address planter;
        uint256 species;
        uint32 countryCode;
        uint32 saleType;
        uint64 treeStatus;
        uint64 plantDate;
        uint64 birthDate;
        string treeSpecs;
    }

    struct TreeUpdate {
        string updateSpecs;
        uint64 updateStatus;
    }

    struct TempTree {
        uint64 birthDate;
        uint64 plantDate;
        uint64 countryCode;
        uint64 otherData;
        address planter;
        string treeSpecs;
    }

    CountersUpgradeable.Counter private _pendingRegularTreeId;

    /** NOTE {isTreeFactory} set inside the initialize to {true} */
    bool public override isTreeFactory;
    uint256 public override lastRegualarTreeId;
    uint256 public override treeUpdateInterval;

    IAccessRestriction public accessRestriction;
    ITree public treeToken;
    IPlanterFund public planterFund;
    IPlanter public planterContract;

    /** NOTE mapping of treeId to TreeData Struct */
    mapping(uint256 => TreeData) public override trees;
    /** NOTE mapping of treeId to TreeUpdate struct */
    mapping(uint256 => TreeUpdate) public override treeUpdates;
    /** NOTE mapping of treeId to TempTree struct */
    mapping(uint256 => TempTree) public override tempTrees;

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

    /** NOTE modifier to check msg.sender has verifier role */
    modifier onlyVerifier() {
        accessRestriction.ifVerifier(_msgSender());
        _;
    }

    /** NOTE modifier for check if function is not paused*/
    modifier ifNotPaused() {
        accessRestriction.ifNotPaused();
        _;
    }

    /** NOTE modifier to check msg.sender has script role */
    modifier onlyScript() {
        accessRestriction.ifScript(_msgSender());
        _;
    }

    /** NOTE modifier for check msg.sender has TreejerContract role */
    modifier onlyTreejerContract() {
        accessRestriction.ifTreejerContract(_msgSender());
        _;
    }

    /** NOTE modifier for check tree has not pending update */
    modifier notHavePendingUpdate(uint256 _treeId) {
        require(
            treeUpdates[_treeId].updateStatus != 1,
            "Pending update exists"
        );
        _;
    }

    /** NOTE modifier for check valid address */
    modifier validAddress(address _address) {
        require(_address != address(0), "Invalid address");
        _;
    }

    /// @inheritdoc ITreeFactory
    function initialize(address _accessRestrictionAddress)
        external
        override
        initializer
    {
        IAccessRestriction candidateContract = IAccessRestriction(
            _accessRestrictionAddress
        );

        require(candidateContract.isAccessRestriction());

        isTreeFactory = true;
        accessRestriction = candidateContract;
        lastRegualarTreeId = 10000;
        treeUpdateInterval = 604800;
    }

    /// @inheritdoc ITreeFactory
    function setTrustedForwarder(address _address)
        external
        override
        onlyAdmin
        validAddress(_address)
    {
        trustedForwarder = _address;
    }

    /// @inheritdoc ITreeFactory
    function setPlanterFundAddress(address _address)
        external
        override
        onlyAdmin
    {
        IPlanterFund candidateContract = IPlanterFund(_address);

        require(candidateContract.isPlanterFund());

        planterFund = candidateContract;
    }

    /// @inheritdoc ITreeFactory
    function setPlanterContractAddress(address _address)
        external
        override
        onlyAdmin
    {
        IPlanter candidateContract = IPlanter(_address);

        require(candidateContract.isPlanter());

        planterContract = candidateContract;
    }

    /// @inheritdoc ITreeFactory
    function setTreeTokenAddress(address _address) external override onlyAdmin {
        ITree candidateContract = ITree(_address);

        require(candidateContract.isTree());

        treeToken = candidateContract;
    }

    /// @inheritdoc ITreeFactory
    function setUpdateInterval(uint256 _seconds)
        external
        override
        ifNotPaused
        onlyDataManager
    {
        treeUpdateInterval = _seconds;

        emit TreeUpdateIntervalChanged();
    }

    /// @inheritdoc ITreeFactory
    function listTree(uint256 _treeId, string calldata _treeSpecs)
        external
        override
        ifNotPaused
        onlyDataManager
    {
        require(trees[_treeId].treeStatus == 0, "Duplicate tree");

        TreeData storage treeData = trees[_treeId];

        treeData.treeStatus = 2;
        treeData.treeSpecs = _treeSpecs;

        emit TreeListed(_treeId);
    }

    function resetTreeStatusBatch(uint256 _startTreeId, uint256 _endTreeId)
        external
        override
        ifNotPaused
        onlyDataManager
    {
        for (uint256 i = _startTreeId; i < _endTreeId; i++) {
            if (trees[i].treeStatus == 2) {
                trees[i].treeStatus = 0;
            }
        }

        emit TreeStatusBatchReset();
    }

    /// @inheritdoc ITreeFactory
    function assignTree(uint256 _treeId, address _planter)
        external
        override
        ifNotPaused
        onlyDataManager
    {
        TreeData storage treeData = trees[_treeId];

        require(treeData.treeStatus == 2, "Invalid tree");

        require(
            planterContract.canAssignTree(_planter),
            "Not allowed planter"
        );

        treeData.planter = _planter;

        emit TreeAssigned(_treeId);
    }

    /// @inheritdoc ITreeFactory
    function plantAssignedTree(
        uint256 _treeId,
        string calldata _treeSpecs,
        uint64 _birthDate,
        uint16 _countryCode
    ) external override ifNotPaused {
        TreeData storage treeData = trees[_treeId];

        require(treeData.treeStatus == 2, "Invalid tree status");

        bool canPlant = planterContract.manageAssignedTreePermission(
            _msgSender(),
            treeData.planter
        );

        require(canPlant, "Permission denied");

        if (_msgSender() != treeData.planter) {
            treeData.planter = _msgSender();
        }

        TreeUpdate storage treeUpdateData = treeUpdates[_treeId];

        treeUpdateData.updateSpecs = _treeSpecs;
        treeUpdateData.updateStatus = 1;

        treeData.countryCode = _countryCode;
        treeData.birthDate = _birthDate;
        treeData.plantDate = block.timestamp.toUint64();
        treeData.treeStatus = 3;

        emit AssignedTreePlanted(_treeId);
    }

    /// @inheritdoc ITreeFactory
    function verifyAssignedTree(uint256 _treeId, bool _isVerified)
        external
        override
        ifNotPaused
        onlyVerifier
    {
        TreeData storage treeData = trees[_treeId];

        require(treeData.treeStatus == 3, "Invalid tree status");

        TreeUpdate storage treeUpdateData = treeUpdates[_treeId];

        if (_isVerified) {
            treeData.treeSpecs = treeUpdateData.updateSpecs;
            treeData.treeStatus = 4;
            treeUpdateData.updateStatus = 3;

            emit AssignedTreeVerified(_treeId);
        } else {
            treeData.treeStatus = 2;
            treeUpdateData.updateStatus = 2;
            planterContract.reducePlantedCount(treeData.planter);

            emit AssignedTreeRejected(_treeId);
        }
    }

    /// @inheritdoc ITreeFactory
    function updateTree(uint256 _treeId, string memory _treeSpecs)
        external
        override
        ifNotPaused
    {
        require(
            trees[_treeId].planter == _msgSender(),
            "Not owned tree"
        );

        require(trees[_treeId].treeStatus > 3, "Tree not planted");

        require(
            treeUpdates[_treeId].updateStatus != 1,
            "Pending update"
        );

        require(
            block.timestamp >=
                trees[_treeId].plantDate +
                    ((trees[_treeId].treeStatus * 3600) + treeUpdateInterval),
            "Early update"
        );

        TreeUpdate storage treeUpdateData = treeUpdates[_treeId];

        treeUpdateData.updateSpecs = _treeSpecs;
        treeUpdateData.updateStatus = 1;

        emit TreeUpdated(_treeId);
    }

    /// @inheritdoc ITreeFactory
    function verifyUpdate(uint256 _treeId, bool _isVerified)
        external
        override
        ifNotPaused
        onlyVerifier
    {
        require(
            treeUpdates[_treeId].updateStatus == 1,
            "Not pending update"
        );

        require(trees[_treeId].treeStatus > 3, "Tree not planted");

        TreeUpdate storage treeUpdateData = treeUpdates[_treeId];

        if (_isVerified) {
            TreeData storage treeData = trees[_treeId];

            treeUpdateData.updateStatus = 3;

            uint32 age = ((block.timestamp - treeData.plantDate) / 3600)
                .toUint32();

            if (age > treeData.treeStatus) {
                treeData.treeStatus = age;
            }

            treeData.treeSpecs = treeUpdateData.updateSpecs;

            if (treeToken.exists(_treeId)) {
                planterFund.updatePlanterTotalClaimed(
                    _treeId,
                    treeData.planter,
                    treeData.treeStatus
                );
            }

            emit TreeUpdatedVerified(_treeId);
        } else {
            treeUpdateData.updateStatus = 2;

            emit TreeUpdateRejected(_treeId);
        }
    }

    /// @inheritdoc ITreeFactory
    function manageSaleType(uint256 _treeId, uint32 _saleType)
        external
        override
        onlyTreejerContract
        returns (uint32)
    {
        if (treeToken.exists(_treeId)) {
            return 1;
        }

        TreeData storage treeData = trees[_treeId];

        uint32 currentSaleType = treeData.saleType;

        if (currentSaleType == 0) {
            treeData.saleType = _saleType;
            if (treeData.treeStatus == 0) {
                treeData.treeStatus = 2;
            }
        }

        return currentSaleType;
    }

    /// @inheritdoc ITreeFactory
    function mintAssignedTree(uint256 _treeId, address _funder)
        external
        override
        onlyTreejerContract
    {
        trees[_treeId].saleType = 0;
        treeToken.mint(_funder, _treeId);
    }

    /// @inheritdoc ITreeFactory
    function resetSaleType(uint256 _treeId)
        external
        override
        onlyTreejerContract
    {
        trees[_treeId].saleType = 0;
    }

    /// @inheritdoc ITreeFactory
    function resetSaleTypeBatch(
        uint256 _startTreeId,
        uint256 _endTreeId,
        uint256 _saleType
    ) external override onlyTreejerContract {
        for (uint256 i = _startTreeId; i < _endTreeId; i++) {
            TreeData storage treeData = trees[i];

            if (treeData.saleType == _saleType) {
                treeData.saleType = 0;

                if (treeData.treeStatus == 2) {
                    treeData.planter = address(0);
                }
            }
        }
    }

    /// @inheritdoc ITreeFactory
    function manageSaleTypeBatch(
        uint256 _startTreeId,
        uint256 _endTreeId,
        uint32 _saleType
    ) external override onlyTreejerContract returns (bool) {
        for (uint256 i = _startTreeId; i < _endTreeId; i++) {
            if (trees[i].saleType > 0 || treeToken.exists(i)) {
                return false;
            }
        }
        for (uint256 j = _startTreeId; j < _endTreeId; j++) {
            TreeData storage treeData = trees[j];

            treeData.saleType = _saleType;

            if (treeData.treeStatus == 0) {
                treeData.treeStatus = 2;
            }
        }
        return true;
    }

    /// @inheritdoc ITreeFactory
    function plantTree(
        string calldata _treeSpecs,
        uint64 _birthDate,
        uint16 _countryCode
    ) external override ifNotPaused {
        require(planterContract.manageTreePermission(_msgSender()));

        tempTrees[_pendingRegularTreeId.current()] = TempTree(
            _birthDate,
            block.timestamp.toUint64(),
            _countryCode,
            0,
            _msgSender(),
            _treeSpecs
        );

        emit TreePlanted(_pendingRegularTreeId.current());

        _pendingRegularTreeId.increment();
    }

    /// @inheritdoc ITreeFactory
    function updateLastRegualarTreeId(uint256 _lastRegualarTreeId)
        external
        override
        ifNotPaused
        onlyDataManager
    {
        require(
            _lastRegualarTreeId > lastRegualarTreeId,
            "Invalid lastRegualarTreeId"
        );

        lastRegualarTreeId = _lastRegualarTreeId;

        emit LastRegualarTreeIdUpdated(_lastRegualarTreeId);
    }

    /// @inheritdoc ITreeFactory
    function verifyTree(uint256 _tempTreeId, bool _isVerified)
        external
        override
        ifNotPaused
        onlyVerifier
    {
        TempTree storage tempTreeData = tempTrees[_tempTreeId];

        require(tempTreeData.plantDate > 0, "Regular Tree not exists");

        if (_isVerified) {
            uint256 tempLastRegularTreeId = lastRegualarTreeId + 1;

            while (
                !(trees[tempLastRegularTreeId].treeStatus == 0 &&
                    trees[tempLastRegularTreeId].saleType == 0)
            ) {
                tempLastRegularTreeId = tempLastRegularTreeId + 1;
            }

            lastRegualarTreeId = tempLastRegularTreeId;

            TreeData storage treeData = trees[lastRegualarTreeId];

            treeData.plantDate = tempTreeData.plantDate;
            treeData.countryCode = uint16(tempTreeData.countryCode);
            treeData.birthDate = tempTreeData.birthDate;
            treeData.treeSpecs = tempTreeData.treeSpecs;
            treeData.planter = tempTreeData.planter;
            treeData.treeStatus = 4;

            if (!treeToken.exists(lastRegualarTreeId)) {
                treeData.saleType = 4;
            }
            emit TreeVerified(lastRegualarTreeId, _tempTreeId);
        } else {
            emit TreeRejected(_tempTreeId);
        }

        delete tempTrees[_tempTreeId];
    }

    /// @inheritdoc ITreeFactory
    function mintTree(uint256 _lastFundedTreeId, address _funder)
        external
        override
        onlyTreejerContract
        returns (uint256)
    {
        uint256 tempLastFundedTreeId = _lastFundedTreeId + 1;

        bool flag = (trees[tempLastFundedTreeId].treeStatus == 0 &&
            trees[tempLastFundedTreeId].saleType == 0) ||
            (trees[tempLastFundedTreeId].treeStatus > 3 &&
                trees[tempLastFundedTreeId].saleType == 4);

        while (!flag) {
            tempLastFundedTreeId = tempLastFundedTreeId + 1;

            flag =
                (trees[tempLastFundedTreeId].treeStatus == 0 &&
                    trees[tempLastFundedTreeId].saleType == 0) ||
                (trees[tempLastFundedTreeId].treeStatus > 3 &&
                    trees[tempLastFundedTreeId].saleType == 4);
        }

        trees[tempLastFundedTreeId].saleType = 0;

        treeToken.mint(_funder, tempLastFundedTreeId);

        return tempLastFundedTreeId;
    }

    /// @inheritdoc ITreeFactory
    function mintTreeById(uint256 _treeId, address _funder)
        external
        override
        onlyTreejerContract
    {
        TreeData storage treeData = trees[_treeId];

        require(
            treeData.treeStatus > 3 && treeData.saleType == 4,
            "Tree not planted"
        );

        treeData.saleType = 0;

        treeToken.mint(_funder, _treeId);
    }

    /// @inheritdoc ITreeFactory
    function updateTreeSpecs(uint64 _treeId, string calldata _treeSpecs)
        external
        override
        ifNotPaused
        onlyScript
        notHavePendingUpdate(_treeId)
    {
        trees[_treeId].treeSpecs = _treeSpecs;

        emit TreeSpecsUpdated(_treeId, _treeSpecs);
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

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
/** @title Tree interface */
interface ITree is IERC721Upgradeable {
    /**
     * @dev initialize AccessRestriction contract, baseURI and set true for isTree
     * @param _accessRestrictionAddress set to the address of AccessRestriction contract
     * @param baseURI_ initial baseURI
     */
    function initialize(
        address _accessRestrictionAddress,
        string calldata baseURI_
    ) external;

    /** @dev admin set {baseURI_} to baseURI */
    function setBaseURI(string calldata baseURI_) external;

    /**
     * @dev mint {_tokenId} to {_to}
     */
    function mint(address _to, uint256 _tokenId) external;

    /**
     * @dev set attribute and symbol for a tokenId based on {_uniquenessFactor}
     * NOTE symbol set when {_generationType} is more than 15 (for HonoraryTree and IncremetalSale)
     * @param _tokenId id of token
     * @param _uniquenessFactor uniqueness factor
     * @param _generationType type of generation
     */
    function setAttributes(
        uint256 _tokenId,
        uint256 _uniquenessFactor,
        uint8 _generationType
    ) external;

    /**
     * @dev check attribute existance for a tokenId
     * @param _tokenId id of token
     * @return true if attributes exist for {_tokenId}
     */
    function attributeExists(uint256 _tokenId) external returns (bool);

    /**
     * @return true in case of Tree contract have been initialized
     */
    function isTree() external view returns (bool);

    function baseURI() external view returns (string memory);

    /**
     * @dev return attribute data
     * @param _tokenId id of token to get data
     * @return attribute1
     * @return attribute2
     * @return attribute3
     * @return attribute4
     * @return attribute5
     * @return attribute6
     * @return attribute7
     * @return attribute8
     * @return generationType
     */
    function attributes(uint256 _tokenId)
        external
        view
        returns (
            uint8 attribute1,
            uint8 attribute2,
            uint8 attribute3,
            uint8 attribute4,
            uint8 attribute5,
            uint8 attribute6,
            uint8 attribute7,
            uint8 attribute8,
            uint8 generationType
        );

    /**
     * @dev return symbol data
     * @param _tokenId id of token to get data
     * @return shape
     * @return trunkColor
     * @return crownColor
     * @return coefficient
     * @return generationType
     */
    function symbols(uint256 _tokenId)
        external
        view
        returns (
            uint8 shape,
            uint8 trunkColor,
            uint8 crownColor,
            uint8 coefficient,
            uint8 generationType
        );

    /**
     * @dev check that _tokenId exist or not
     * @param _tokenId id of token to check existance
     * @return true if {_tokenId} exist
     */
    function exists(uint256 _tokenId) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

/** @title PlanterFund interfce */
interface IPlanterFund {
    /**
     * @dev emitted when planter total claimable amount updated
     * @param treeId id of tree that planter total claimable amount updated for
     * @param planter address of planter
     * @param amount amount added to planter total claimable amount
     * @param ambassador address of ambassador
     */
    event PlanterTotalClaimedUpdated(
        uint256 treeId,
        address planter,
        uint256 amount,
        address ambassador
    );

    /**
     * @dev emitted when a planter withdraw
     * @param amount amount of withdraw
     * @param account address of planter
     */
    event BalanceWithdrew(uint256 amount, address account);

    /**
     * @dev emitted when admin withdraw noAmbsassador balance
     * @param amount amount to withdraw
     * @param account address of destination account
     * @param reason reason of withdraw
     */
    event NoAmbsassadorBalanceWithdrew(
        uint256 amount,
        address account,
        string reason
    );

    /**
     * @dev emitted when ProjectedEarning set for tree
     * @param treeId id of tree ProjectedEarning set for
     * @param planterAmount planter amount
     * @param ambassadorAmount ambassador amount
     */
    event ProjectedEarningUpdated(
        uint256 treeId,
        uint256 planterAmount,
        uint256 ambassadorAmount
    );

    /** @dev emitted when minimum withdrable amount set */
    event MinWithdrawableAmountUpdated();

    /** @dev set {_address} to trusted forwarder */
    function setTrustedForwarder(address _address) external;

    /** @dev set {_address} to Planter contract address */
    function setPlanterContractAddress(address _address) external;

    /** @dev set {_address} to DaiToken contract address */
    function setDaiTokenAddress(address _address) external;

    /**
     * @dev set {_address} to outgoingAddress
     */
    function setOutgoingAddress(address payable _address) external;

    /**
     * @dev admin set the minimum amount to withdraw
     * NOTE emit a {MinWithdrawableAmountUpdated} event
     * @param _amount is minimum withdrawable amount
     */
    function updateWithdrawableAmount(uint256 _amount) external;

    /**
     * @dev set projected earnings
     * NOTE emit a {ProjectedEarningUpdated} event
     * @param _treeId id of tree to set projected earning for
     * @param _planterAmount planter amount
     * @param _ambassadorAmount ambassador amount
     */
    function updateProjectedEarnings(
        uint256 _treeId,
        uint256 _planterAmount,
        uint256 _ambassadorAmount
    ) external;

    /**
     * @dev based on the {_treeStatus} planter total claimable amount updated in every tree
     * update verifying
     * NOTE emit a {PlanterTotalClaimedUpdated} event
     * @param _treeId id of a tree that planter's total claimable amount updated for
     * @param _planter  address of planter to fund
     * @param _treeStatus status of tree
     */
    function updatePlanterTotalClaimed(
        uint256 _treeId,
        address _planter,
        uint64 _treeStatus
    ) external;

    /**
     * @dev planter withdraw {_amount} from balances
     * NOTE emit a {BalanceWithdrew} event
     * @param _amount amount to withdraw
     */
    function withdrawBalance(uint256 _amount) external;

    /**
     * @dev admin withdraw from noAmbsassador totalBalances
     * NOTE amount transfer to outgoingAddress
     * NOTE emit a {NoAmbsassadorBalanceWithdrew} event
     * @param _amount amount to withdraw
     * @param _reason reason to withdraw
     */
    function withdrawNoAmbsassadorBalance(
        uint256 _amount,
        string calldata _reason
    ) external;

    /**
     * @dev initialize AccessRestriction contract, minWithdrawable and set true
     * for isAllocation
     * @param _accessRestrictionAddress set to the address of AccessRestriction contract
     */
    function initialize(address _accessRestrictionAddress) external;

    /**
     * @return true in case of PlanterFund contract has been initialized
     */
    function isPlanterFund() external view returns (bool);

    /** @return minimum amount to withdraw */
    function minWithdrawable() external view returns (uint256);

    /**
     * @return outgoing address
     */
    function outgoingAddress() external view returns (address);

    /**
     * @dev return totalBalances struct data
     * @return planter total balance
     * @return ambassador total balance
     * @return noAmbsassador total balance
     */
    function totalBalances()
        external
        view
        returns (
            uint256 planter,
            uint256 ambassador,
            uint256 noAmbsassador
        );

    /**
     * @return treeToPlanterProjectedEarning of {_treeId}
     */
    function treeToPlanterProjectedEarning(uint256 _treeId)
        external
        view
        returns (uint256);

    /**
     * @return treeToAmbassadorProjectedEarning of {_treeId}
     */
    function treeToAmbassadorProjectedEarning(uint256 _treeId)
        external
        view
        returns (uint256);

    /**
     * @return treeToPlanterTotalClaimed of {_treeId}
     */
    function treeToPlanterTotalClaimed(uint256 _treeId)
        external
        view
        returns (uint256);

    /**
     * @return balance of {_planter}
     */
    function balances(address _planter) external view returns (uint256);
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

/** @title TreeFactory interfce */
interface ITreeFactory {
    /**
     * @dev emitted when a tree list
     * @param treeId id of tree to list
     */
    event TreeListed(uint256 treeId);

    /**
     * @dev emitted when a tree assigned to planter
     * @param treeId id of tree to assign
     */
    event TreeAssigned(uint256 treeId);

    /**
     * @dev emitted when  assigned tree planted
     * @param treeId id of tree that planted
     */
    event AssignedTreePlanted(uint256 treeId);

    /**
     * @dev emitted when planting of assigned tree verified
     * @param treeId id of tree that verified
     */
    event AssignedTreeVerified(uint256 treeId);

    /**
     * @dev emitted when planting of assigned tree rejected
     * @param treeId id of tree that rejected
     */
    event AssignedTreeRejected(uint256 treeId);

    /**
     * @dev emitted when planter send update request to tree
     * @param treeId id of tree that update request sent for
     */
    event TreeUpdated(uint256 treeId);

    /**
     * @dev emitted when update request for tree verified
     * @param treeId id of tree that update request verified
     */
    event TreeUpdatedVerified(uint256 treeId);

    /**
     * @dev emitted when update request for tree rejected
     * @param treeId id of tree that update request rejected
     */
    event TreeUpdateRejected(uint256 treeId);

    /**
     * @dev emitted when regular tree planted
     * @param treeId id of regular tree id that planted
     */
    event TreePlanted(uint256 treeId);

    /**
     * @dev emitted when planting for regular tree verified
     * @param treeId id of tree that verified
     * @param tempTreeId id of tempTree
     */
    event TreeVerified(uint256 treeId, uint256 tempTreeId);

    /**
     * @dev emitted when planting for regular tree rejected
     * @param treeId id of tree that rejected
     */
    event TreeRejected(uint256 treeId);

    /** @dev emitted when new treeUpdateInterval set */
    event TreeUpdateIntervalChanged();

    /**
     * @dev emitted when treeSpecs of tree updated
     * @param treeId id of tree to update treeSpecs
     */
    event TreeSpecsUpdated(uint256 treeId, string treeSpecs);

    event LastRegualarTreeIdUpdated(uint256 lastRegualarTreeId);

    event TreeStatusBatchReset();

    /** @dev set {_address} to trusted forwarder */
    function setTrustedForwarder(address _address) external;

    /** @dev set {_address} to PlanterFund contract address */
    function setPlanterFundAddress(address _address) external;

    /** @dev set {_address} to Planter contract address */
    function setPlanterContractAddress(address _address) external;

    /** @dev set {_address} to TreeToken contract address */
    function setTreeTokenAddress(address _address) external;

    /** @dev admin set the minimum time to send next update request
     * NOTE emit an {TreeUpdateIntervalChanged} event
     * @param _seconds time to next update request
     */
    function setUpdateInterval(uint256 _seconds) external;

    /**
     * @dev admin list tree
     * NOTE emited a {TreeListed} event
     * @param _treeId id of tree to list
     * @param _treeSpecs tree specs
     */
    function listTree(uint256 _treeId, string calldata _treeSpecs) external;

    function resetTreeStatusBatch(uint256 _startTreeId, uint256 _endTreeId)
        external;

    /**
     * @dev admin assign an existing tree to planter
     * NOTE tree must be not planted
     * NOTE emited a {TreeAssigned} event
     * @param _treeId id of tree to assign
     * @param _planter assignee planter
     */
    function assignTree(uint256 _treeId, address _planter) external;

    /**
     * @dev planter with permission to plant, can plant its assigned tree
     * NOTE emited an {AssignedTreePlanted} event
     * @param _treeId id of tree to plant
     * @param _treeSpecs tree specs
     * @param _birthDate birth date of tree
     * @param _countryCode country code of tree
     */
    function plantAssignedTree(
        uint256 _treeId,
        string calldata _treeSpecs,
        uint64 _birthDate,
        uint16 _countryCode
    ) external;

    /**
     * @dev admin or allowed verifier can verify or reject plant for assigned tree.
     * NOTE emited an {AssignedTreeVerified} or {AssignedTreeRejected} event
     * @param _treeId id of tree to verifiy
     * @param _isVerified true for verify and false for reject
     */
    function verifyAssignedTree(uint256 _treeId, bool _isVerified) external;

    /**
     * @dev planter of tree send update request for tree
     * NOTE emited a {TreeUpdated} event
     * @param _treeId id of tree to update
     * @param _treeSpecs tree specs
     */
    function updateTree(uint256 _treeId, string memory _treeSpecs) external;

    /**
     * @dev admin or allowed verifier can verifiy or reject update request for tree.
     * NOTE based on the current time of verifing and plant date, age of tree
     * calculated and set as the treeStatus
     * NOTE if a token exist for that tree (minted before) planter of tree funded
     * based on calculated tree status
     * NOTE emited a {TreeUpdatedVerified} or {TreeUpdateRejected} event
     * @param _treeId id of tree to verify update request
     * @param _isVerified true for verify and false for reject
     */
    function verifyUpdate(uint256 _treeId, bool _isVerified) external;

    /**
     * @dev check if a tree is free to take part in sale and set {_saleType}
     * to saleType of tree when tree is not in use
     * @param _treeId id of tree to check
     * @param _saleType saleType for tree
     * @return 0 if a tree ready for a sale and 1 if a tree is in use or minted before
     */
    function manageSaleType(uint256 _treeId, uint32 _saleType)
        external
        returns (uint32);

    /**
     * @dev mint a tree to funder and set saleType to 0
     * @param _treeId id of tree to mint
     * @param _funder address of funder to mint tree for
     */
    function mintAssignedTree(uint256 _treeId, address _funder) external;

    /**
     * @dev reset saleType value of tree
     * @param _treeId id of tree to reset saleType value
     */
    function resetSaleType(uint256 _treeId) external;

    /**
     * @dev reset saleType of trees in range of {_startTreeId} and {_endTreeId}
     * with saleType value of {_saleType}
     * @param _startTreeId starting tree id to reset saleType
     * @param _endTreeId ending tree id to reset saleType
     * @param _saleType saleType value of trees
     */
    function resetSaleTypeBatch(
        uint256 _startTreeId,
        uint256 _endTreeId,
        uint256 _saleType
    ) external;

    /**
     * @dev set {_saleType} to saleType of trees in range {_startTreeId} and {_endTreeId}
     * @param _startTreeId starting tree id to set saleType value
     * @param _endTreeId _ending tree id to set saleType value
     * @param _saleType saleType value
     * @return true if all trees saleType value successfully set and false otherwise
     */
    function manageSaleTypeBatch(
        uint256 _startTreeId,
        uint256 _endTreeId,
        uint32 _saleType
    ) external returns (bool);

    /**
     * @dev planter plant a tree
     * NOTE emited a {TreePlanted} event
     * @param _treeSpecs tree specs
     * @param _birthDate birthDate of the tree
     * @param _countryCode country code of tree
     */
    function plantTree(
        string calldata _treeSpecs,
        uint64 _birthDate,
        uint16 _countryCode
    ) external;

    function updateLastRegualarTreeId(uint256 _lastRegualarTreeId) external;

    /**
     * @dev admin or allowed verifier can verify or rejects the pending trees
     * NOTE emited a {TreeVerified} or {TreeRejected} event
     * @param _tempTreeId tempTreeId to verify
     * @param _isVerified true for verify and false for reject
     */
    function verifyTree(uint256 _tempTreeId, bool _isVerified) external;

    /**
     * @dev mint a tree to funder of tree
     * @param _lastFundedTreeId The last tree funded in the regular sale
     * @param _funder funder of a new tree sold in Regular
     * @return the last tree funded after update
     */
    function mintTree(uint256 _lastFundedTreeId, address _funder)
        external
        returns (uint256);

    /**
     * @dev mint an already planted tree with id to funder
     * @param _treeId tree id to mint
     * @param _funder address of funder
     */
    function mintTreeById(uint256 _treeId, address _funder) external;

    /**
     * @dev script role update treeSpecs
     * NOTE emit a {TreeSpecsUpdated} event
     * @param _treeId id of tree to update treeSpecs
     * @param _treeSpecs new tree specs
     */
    function updateTreeSpecs(uint64 _treeId, string calldata _treeSpecs)
        external;

    /**
     * @dev initialize AccessRestriction contract,lastRegualarTreeId,treeUpdateInterval
     * and set true for isTreeFactory
     * @param _accessRestrictionAddress set to the address of AccessRestriction contract
     */
    function initialize(address _accessRestrictionAddress) external;

    /** @return true in case of TreeFactory contract has been initialized */
    function isTreeFactory() external view returns (bool);

    /** @return lastRegularTreeId */
    function lastRegualarTreeId() external view returns (uint256);

    /** @return minimum time to send next update request */
    function treeUpdateInterval() external view returns (uint256);

    /** return Tree data
     * @param _treeId  id of tree to get data
     * @return planter
     * @return species
     * @return countryCode
     * @return saleType
     * @return treeStatus
     * @return plantDate
     * @return birthDate
     * @return treeSpecs
     */
    function trees(uint256 _treeId)
        external
        view
        returns (
            address,
            uint256,
            uint32,
            uint32,
            uint64,
            uint64,
            uint64,
            string memory
        );

    /** return TreeUpdate data
     8 @param _treeId id of tree to get data
     * @return updateSpecs
     * @return updateStatus
     */
    function treeUpdates(uint256 _treeId)
        external
        view
        returns (string memory, uint64);

    /** return TempTree data
     * @param _tempTreeId id of tempTree to get data
     * @return birthDate
     * @return plantDate
     * @return countryCode
     * @return otherData
     * @return planter
     * @return treeSpecs
     */
    function tempTrees(uint256 _tempTreeId)
        external
        view
        returns (
            uint64,
            uint64,
            uint64,
            uint64,
            address,
            string memory
        );
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

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}