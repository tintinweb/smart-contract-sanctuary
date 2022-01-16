// // SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../access/IAccessRestriction.sol";
import "../tree/ITreeFactory.sol";
import "../tree/IAttribute.sol";
import "../treasury/IPlanterFund.sol";
import "../gsn/RelayRecipient.sol";
import "./IHonoraryTree.sol";

/** @title HonoraryTree */

contract HonoraryTree is Initializable, RelayRecipient, IHonoraryTree {
    struct Recipient {
        uint64 expiryDate;
        uint64 startDate;
        uint64 coefficient;
    }

    /** NOTE {isHonoraryTree} set inside the initialize to {true} */
    bool public override isHonoraryTree;

    uint256 public override claimedCount;
    uint256 public override currentTreeId;
    uint256 public override upTo;
    uint256 public override prePaidTreeCount;

    /**NOTE {referralTreePaymentToPlanter} is share of planter when a tree claimed for someone*/
    uint256 public override referralTreePaymentToPlanter;
    /**NOTE {referralTreePaymentToAmbassador} is share of ambassador when a tree claimed for someone*/
    uint256 public override referralTreePaymentToAmbassador;

    /** NOTE mapping of recipient address to Recipient struct */
    mapping(address => Recipient) public override recipients;
    /** NOTE array of symbols */
    uint64[] public override symbols;
    /** array of bool to show a symbol is used or not*/
    bool[] public override used;

    IAccessRestriction public accessRestriction;
    ITreeFactory public treeFactory;
    IPlanterFund public planterFundContract;
    IAttribute public attribute;
    IERC20Upgradeable public daiToken;

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

    /** NOTE modifier for check if function is not paused*/
    modifier ifNotPaused() {
        accessRestriction.ifNotPaused();
        _;
    }

    /** NOTE modifier for check valid address */
    modifier validAddress(address _address) {
        require(_address != address(0), "Invalid address");
        _;
    }

    /// @inheritdoc IHonoraryTree
    function initialize(
        address _accessRestrictionAddress,
        uint256 _referralTreePaymentToPlanter,
        uint256 _referralTreePaymentToAmbassador
    ) external override initializer {
        IAccessRestriction candidateContract = IAccessRestriction(
            _accessRestrictionAddress
        );
        require(candidateContract.isAccessRestriction());
        isHonoraryTree = true;
        accessRestriction = candidateContract;
        referralTreePaymentToPlanter = _referralTreePaymentToPlanter;
        referralTreePaymentToAmbassador = _referralTreePaymentToAmbassador;
    }

    /// @inheritdoc IHonoraryTree
    function setTrustedForwarder(address _address)
        external
        override
        onlyAdmin
        validAddress(_address)
    {
        trustedForwarder = _address;
    }

    /// @inheritdoc IHonoraryTree
    function setDaiTokenAddress(address _daiTokenAddress)
        external
        override
        onlyAdmin
        validAddress(_daiTokenAddress)
    {
        IERC20Upgradeable candidateContract = IERC20Upgradeable(
            _daiTokenAddress
        );
        daiToken = candidateContract;
    }

    /// @inheritdoc IHonoraryTree
    function setAttributesAddress(address _address)
        external
        override
        onlyAdmin
    {
        IAttribute candidateContract = IAttribute(_address);
        require(candidateContract.isAttribute());
        attribute = candidateContract;
    }

    /// @inheritdoc IHonoraryTree
    function setTreeFactoryAddress(address _address)
        external
        override
        onlyAdmin
    {
        ITreeFactory candidateContract = ITreeFactory(_address);
        require(candidateContract.isTreeFactory());
        treeFactory = candidateContract;
    }

    /// @inheritdoc IHonoraryTree
    function setPlanterFundAddress(address _address)
        external
        override
        onlyAdmin
    {
        IPlanterFund candidateContract = IPlanterFund(_address);
        require(candidateContract.isPlanterFund());
        planterFundContract = candidateContract;
    }

    /// @inheritdoc IHonoraryTree
    function setTreeRange(
        address _sponsor,
        uint256 _startTreeId,
        uint256 _upTo
    ) external override ifNotPaused onlyDataManager {
        require(_upTo > _startTreeId, "Invalid range");
        require(upTo == currentTreeId, "Cant set range");

        bool isAvailable = treeFactory.manageSaleTypeBatch(
            _startTreeId,
            _upTo,
            5
        );
        require(isAvailable, "Tree not available");

        currentTreeId = _startTreeId;
        upTo = _upTo;

        int256 extraPrePaid = int256(_upTo - _startTreeId) -
            int256(prePaidTreeCount);

        if (extraPrePaid > 0) {
            bool success = daiToken.transferFrom(
                _sponsor,
                address(planterFundContract),
                uint256(extraPrePaid) *
                    (referralTreePaymentToPlanter +
                        referralTreePaymentToAmbassador)
            );

            require(success, "Unsuccessful transfer");

            prePaidTreeCount = 0;
        } else {
            prePaidTreeCount = uint256(-extraPrePaid);
        }

        emit TreeRangeSet();
    }

    /// @inheritdoc IHonoraryTree
    function releaseTreeRange() external override ifNotPaused onlyDataManager {
        treeFactory.resetSaleTypeBatch(currentTreeId, upTo, 5);
        prePaidTreeCount += upTo - currentTreeId;
        upTo = 0;
        currentTreeId = 0;
        emit TreeRangeReleased();
    }

    /// @inheritdoc IHonoraryTree
    function reserveSymbol(uint64 _uniquenessFactor)
        external
        override
        ifNotPaused
        onlyDataManager
    {
        attribute.reserveSymbol(_uniquenessFactor);
        symbols.push(_uniquenessFactor);
        used.push(false);
    }

    /// @inheritdoc IHonoraryTree
    function releaseReservedSymbol()
        external
        override
        ifNotPaused
        onlyDataManager
    {
        for (uint256 i = 0; i < symbols.length; i++) {
            if (!used[i]) {
                attribute.releaseReservedSymbol(symbols[i]);
            }
        }

        delete symbols;
        delete used;
        claimedCount = 0;
    }

    /// @inheritdoc IHonoraryTree
    function addRecipient(
        address _recipient,
        uint64 _startDate,
        uint64 _expiryDate,
        uint64 _coefficient
    ) external override ifNotPaused onlyDataManager {
        Recipient storage recipientData = recipients[_recipient];

        recipientData.expiryDate = _expiryDate;
        recipientData.startDate = _startDate;
        recipientData.coefficient = _coefficient;

        emit RecipientAdded(_recipient);
    }

    /// @inheritdoc IHonoraryTree
    function updateRecipient(
        address _recipient,
        uint64 _startDate,
        uint64 _expiryDate,
        uint64 _coefficient
    ) external override ifNotPaused onlyDataManager {
        Recipient storage recipientData = recipients[_recipient];

        require(recipientData.startDate > 0, "Recipient not exist");

        recipientData.expiryDate = _expiryDate;
        recipientData.startDate = _startDate;
        recipientData.coefficient = _coefficient;
        emit RecipientUpdated(_recipient);
    }

    /// @inheritdoc IHonoraryTree
    function updateReferralTreePayments(
        uint256 _referralTreePaymentToPlanter,
        uint256 _referralTreePaymentToAmbassador
    ) external override ifNotPaused onlyDataManager {
        referralTreePaymentToPlanter = _referralTreePaymentToPlanter;
        referralTreePaymentToAmbassador = _referralTreePaymentToAmbassador;

        emit ReferralTreePaymentsUpdated(
            _referralTreePaymentToPlanter,
            _referralTreePaymentToAmbassador
        );
    }

    /// @inheritdoc IHonoraryTree
    function claim() external override ifNotPaused {
        Recipient storage recipientData = recipients[_msgSender()];

        require(
            recipientData.expiryDate > block.timestamp &&
                recipientData.startDate < block.timestamp &&
                recipientData.startDate > 0,
            "Cant claim"
        );

        require(currentTreeId < upTo, "Tree not available");
        require(claimedCount < symbols.length, "Insufficient symbol");

        bool flag = false;

        uint256 randomValue = uint256(
            keccak256(
                abi.encode(
                    recipientData.expiryDate,
                    recipientData.startDate,
                    msg.data,
                    currentTreeId
                )
            )
        );

        uint64 selectedSymbol = 0;
        uint256 remainedSymbolCount;
        uint256 selectedFreeSymbolIndex;
        uint256 index;

        for (uint256 i = 0; i < symbols.length; i++) {
            remainedSymbolCount = symbols.length - claimedCount;
            selectedFreeSymbolIndex = remainedSymbolCount > 0
                ? randomValue % remainedSymbolCount
                : 0;
            index = 0;

            for (uint256 j = 0; j < symbols.length; j++) {
                if (!used[j]) {
                    if (index == selectedFreeSymbolIndex) {
                        claimedCount += 1;
                        used[j] = true;

                        (, uint128 status) = attribute
                            .uniquenessFactorToSymbolStatus(symbols[j]);

                        if (status == 1) {
                            selectedSymbol = symbols[j];
                            flag = true;
                        }

                        break;
                    }
                    index += 1;
                }
            }
            if (flag) {
                break;
            }
        }

        if (flag) {
            uint64 uniquenessFactor = attribute.manageAttributeUniquenessFactor(
                currentTreeId
            );

            attribute.setAttribute(
                currentTreeId,
                uniquenessFactor,
                selectedSymbol,
                18,
                recipientData.coefficient
            );

            planterFundContract.updateProjectedEarnings(
                currentTreeId,
                referralTreePaymentToPlanter,
                referralTreePaymentToAmbassador
            );

            treeFactory.mintAssignedTree(currentTreeId, _msgSender());

            emit Claimed(currentTreeId);

            currentTreeId += 1;

            delete recipients[_msgSender()];
        } else {
            emit ClaimFailed(_msgSender());
        }
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

/** @title Attribute interfce */
interface IAttribute {
    /**
     * @dev emitted when unique attribute generated successfully
     * @param treeId id of tree to generate attribute for
     */
    event AttributeGenerated(uint256 treeId);

    /**
     * @dev emitted when attribute genertion failed
     * @param treeId id of tree that attribute generation failed
     */
    event AttributeGenerationFailed(uint256 treeId);

    /**
     * @dev emitted when a symbol reserved
     * @param uniquenessFactor unique symbol to reserve
     */
    event SymbolReserved(uint64 uniquenessFactor);

    /**
     * @dev emitted when reservation of a unique symbol released
     * @param uniquenessFactor unique symbol to release reservation
     */
    event ReservedSymbolReleased(uint64 uniquenessFactor);

    /** @dev set {_address} to TreeToken contract address */
    function setTreeTokenAddress(address _address) external;

    /**
     * @dev admin set Base Token contract address
     * @param _baseTokenAddress set to the address of Dai contract
     */
    function setBaseTokenAddress(address _baseTokenAddress) external;

    /**
     * @dev admin set Dex tokens list
     * @param _tokens an array of tokens in dex exchange with high liquidity
     */
    function setDexTokens(address[] calldata _tokens) external;

    /**
     * @dev admin set DexRouter contract address
     * @param _dexRouterAddress set to the address of DexRouter contract
     */
    function setDexRouterAddress(address _dexRouterAddress) external;

    /**
     * @dev reserve a unique symbol
     * @param _uniquenessFactor unique symbol to reserve
     * NOTE emit a {SymbolReserved} event
     */
    function reserveSymbol(uint64 _uniquenessFactor) external;

    /**
     * @dev release reservation of a unique symbol by admin
     * @param _uniquenessFactor unique symbol to release reservation
     * NOTE emit a {ReservedSymbolReleased} event
     */
    function releaseReservedSymbolByAdmin(uint64 _uniquenessFactor) external;

    /**
     * @dev release reservation of a unique symbol
     * @param _uniquenessFactor unique symbol to release reservation
     * NOTE emit a {ReservedSymbolReleased} event
     */
    function releaseReservedSymbol(uint64 _uniquenessFactor) external;

    /**
     * @dev admin assigns symbol and attribute to the specified treeId
     * @param _treeId id of tree
     * @param _attributeUniquenessFactor unique attribute code to assign
     * @param _symbolUniquenessFactor unique symbol to assign
     * @param _generationType type of attribute assignement
     * @param _coefficient coefficient value
     * NOTE emit a {AttributeGenerated} event
     */
    function setAttribute(
        uint256 _treeId,
        uint64 _attributeUniquenessFactor,
        uint64 _symbolUniquenessFactor,
        uint8 _generationType,
        uint64 _coefficient
    ) external;

    /**
     * @dev generate a random unique symbol using tree attributes 64 bit value
     * @param _treeId id of tree
     * @param _randomValue base random value
     * @param _funder address of funder
     * @param _funderRank rank of funder based on trees owned in treejer
     * @param _generationType type of attribute assignement
     * NOTE emit a {AttributeGenerated} or {AttributeGenerationFailed} event
     * @return if unique symbol generated successfully
     */
    function createSymbol(
        uint256 _treeId,
        bytes32 _randomValue,
        address _funder,
        uint8 _funderRank,
        uint8 _generationType
    ) external returns (bool);

    /**
     * @dev generate a random unique attribute using tree attributes 64 bit value
     * @param _treeId id of tree
     * @param _generationType generation type
     * NOTE emit a {AttributeGenerated} or {AttributeGenerationFailed} event
     * @return if unique attribute generated successfully
     */
    function createAttribute(uint256 _treeId, uint8 _generationType)
        external
        returns (bool);

    /**
     * @dev check and generate random attributes for honorary trees
     * @param _treeId id of tree
     * @return a unique random value
     */
    function manageAttributeUniquenessFactor(uint256 _treeId)
        external
        returns (uint64);

    /**
     * @dev initialize AccessRestriction contract and set true for isAttribute
     * @param _accessRestrictionAddress set to the address of AccessRestriction contract
     */
    function initialize(address _accessRestrictionAddress) external;

    /** @return true in case of Attribute contract has been initialized */
    function isAttribute() external view returns (bool);

    /** @return total number of special tree created */
    function specialTreeCount() external view returns (uint8);

    /**
     * @return DaiToken address
     */
    function baseTokenAddress() external view returns (address);

    /**
     * @dev return generation count
     * @param _attribute generated attributes
     * @return generation count
     */
    function uniquenessFactorToGeneratedAttributesCount(uint64 _attribute)
        external
        view
        returns (uint32);

    /**
     * @dev return SymbolStatus
     * @param _uniqueSymbol unique symbol
     * @return generatedCount
     * @return status
     */
    function uniquenessFactorToSymbolStatus(uint64 _uniqueSymbol)
        external
        view
        returns (uint128 generatedCount, uint128 status);

    function dexTokens(uint256 _index) external view returns (address);

    /**
     * @dev the function tries to calculate the rank of funder based trees owned in Treejer
     * @param _funder address of funder
     */
    function getFunderRank(address _funder) external view returns (uint8);
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

// // SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

/** @title IHonoraryTree */

interface IHonoraryTree {
    /** @dev emitted when a tree range set for honorary trees */
    event TreeRangeSet();
    /** @dev emitted when a tree range released from honorary trees */
    event TreeRangeReleased();

    /**
     * @dev emitted when admin add a recipient
     * @param recipient address of recipient
     */
    event RecipientAdded(address recipient);

    /**
     * @dev emitted when admin update date of a recipient
     * @param recipient address of recipient
     */
    event RecipientUpdated(address recipient);

    /** @dev emitted when referral tree payments set by admin
     * @param referralTreePaymentToPlanter referral tree payment to planter amount
     * @param referralTreePaymentToAmbassador referral tree payment to ambassador amount
     */
    event ReferralTreePaymentsUpdated(
        uint256 referralTreePaymentToPlanter,
        uint256 referralTreePaymentToAmbassador
    );

    /** @dev emitted when a tree claimed by recipient
     * @param treeId is id of climed tree
     */
    event Claimed(uint256 treeId);

    /** @dev emitted when claim failed
     * @param recipient address of recipient
     */
    event ClaimFailed(address recipient);

    /**
     * @dev return symbol in {_index}
     * @param _index is index of array
     * @return symbol in {_index}
     */
    function symbols(uint256 _index) external returns (uint64 symbol);

    /**
     * @dev return if symbol in {_index} is used or not
     * @param _index is index of array
     * @return isUsed , if symbol in {_index} is used or not
     */
    function used(uint256 _index) external returns (bool isUsed);

    /** @dev admin set {_address} to trust forwarder*/
    function setTrustedForwarder(address _address) external;

    /** @dev admin set {_daiTokenAddress} to DaiToken contract address */
    function setDaiTokenAddress(address _daiTokenAddress) external;

    /** @dev admin set {_address} to Attribute contract address */
    function setAttributesAddress(address _address) external;

    /** @dev admin set {_address} to TreeFactory contract address */
    function setTreeFactoryAddress(address _address) external;

    /** @dev admin set {_address} to PlanterFund contract address */
    function setPlanterFundAddress(address _address) external;

    /**
     * @dev admin set a range of trees with saleType of '0' for honorary trees
     * NOTE saleType of tree set to '5'
     * NOTE the prepaid amount is deducted from the total amount t pay
     * NOTE emit a {TreeRangeSet} event
     * @param _sponsor address of account pay for value of honorary trees
     * @param _startTreeId start tree id of honorary tree to claim
     * @param _upTo end tree id of honorary tree to claim
     */

    function setTreeRange(
        address _sponsor,
        uint256 _startTreeId,
        uint256 _upTo
    ) external;

    /**
     * @dev admin release tree range
     * NOTE saleType of trees set to '0'
     * NOTE calculate prePaidCount value to deducte from number of tree count
     * when new tree range set
     * NOTE emit a {TreeRangeReleased} event
     */
    function releaseTreeRange() external;

    /**
     * @dev admin reserve a symbol
     * @param _uniquenessFactor unique symbol to reserve
     */
    function reserveSymbol(uint64 _uniquenessFactor) external;

    /**
     * @dev admin release all reserved and not used symbols
     */
    function releaseReservedSymbol() external;

    /**
     * @dev admin add recipient
     * NOTE emit a {RecipientAdded} event
     * @param _recipient address of recipient
     * @param _startDate start date for {_recipient} to claim tree
     * @param _expiryDate expiry date for {_recipient} to claim tree
     * @param _coefficient coefficient value
     */
    function addRecipient(
        address _recipient,
        uint64 _startDate,
        uint64 _expiryDate,
        uint64 _coefficient
    ) external;

    /**
     * @dev admin update {_recipient} data
     * NOTE emit a {RecipientUpdated} event
     * @param _recipient address of recipient to update date
     * @param _startDate new start date for {_recipient} to claim tree
     * @param _expiryDate new expiry date for {_recipient} to claim tree
     * @param _coefficient coefficient value
     */
    function updateRecipient(
        address _recipient,
        uint64 _startDate,
        uint64 _expiryDate,
        uint64 _coefficient
    ) external;

    /** @dev admin can set referral tree payments
     * NOTE emit a {ReferralTreePaymentsUpdated} event
     * @param _referralTreePaymentToPlanter is referral tree payment to planter amount
     * @param _referralTreePaymentToAmbassador is referral tree payment to ambassador amount
     */
    function updateReferralTreePayments(
        uint256 _referralTreePaymentToPlanter,
        uint256 _referralTreePaymentToAmbassador
    ) external;

    /**
     * @dev recipient claim a tree and tree minted to recipient.
     * projected earnings updated and random attributes set for that tree
     * NOTE emit a {Claimed} or {ClaimFailed} event
     */

    function claim() external;

    /**
     * @dev initialize accessRestriction contract and set true for isHonoraryTree
     * set referralTreePaymentToPlanter and referralTreePaymentToAmbassador initial value
     * @param _accessRestrictionAddress set to the address of accessRestriction contract
     * @param _referralTreePaymentToPlanter initial planter fund
     * @param _referralTreePaymentToAmbassador initial ambassador fund
     */

    function initialize(
        address _accessRestrictionAddress,
        uint256 _referralTreePaymentToPlanter,
        uint256 _referralTreePaymentToAmbassador
    ) external;

    /**
     * @dev return data of an recipient {_address}
     * @param _address of recipient to get data
     * @return expiryDate
     * @return startDate
     */
    function recipients(address _address)
        external
        view
        returns (
            uint64 expiryDate,
            uint64 startDate,
            uint64 coefficient
        );

    /** @return true in case of HonoraryTree contract have been initialized */
    function isHonoraryTree() external view returns (bool);

    /** @return number of claimed trees */
    function claimedCount() external view returns (uint256);

    /** @return id of tree to claim */
    function currentTreeId() external view returns (uint256);

    /** @return maximum id of trees can be claimed up to it */
    function upTo() external view returns (uint256);

    /** @return tree count that paid before for it*/
    function prePaidTreeCount() external view returns (uint256);

    /** @return referralTreePaymentToPlanter amount */
    function referralTreePaymentToPlanter() external view returns (uint256);

    /** @return referralTreePaymentToAmbassador amount */
    function referralTreePaymentToAmbassador() external view returns (uint256);
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
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
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