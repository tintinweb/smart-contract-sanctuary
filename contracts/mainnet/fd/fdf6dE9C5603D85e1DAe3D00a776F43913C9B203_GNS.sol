// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "../base/Multicall.sol";
import "../bancor/BancorFormula.sol";
import "../upgrades/GraphUpgradeable.sol";
import "../utils/TokenUtils.sol";

import "./IGNS.sol";
import "./GNSStorage.sol";

/**
 * @title GNS
 * @dev The Graph Name System contract provides a decentralized naming system for subgraphs
 * used in the scope of the Graph Network. It translates Subgraphs into Subgraph Versions.
 * Each version is associated with a Subgraph Deployment. The contract has no knowledge of
 * human-readable names. All human readable names emitted in events.
 * The contract implements a multicall behaviour to support batching multiple calls in a single
 * transaction.
 */
contract GNS is GNSV2Storage, GraphUpgradeable, IGNS, Multicall {
    using SafeMath for uint256;

    // -- Constants --

    uint256 private constant MAX_UINT256 = 2**256 - 1;

    // 100% in parts per million
    uint32 private constant MAX_PPM = 1000000;

    // Equates to Connector weight on bancor formula to be CW = 1
    uint32 private constant defaultReserveRatio = 1000000;

    // -- Events --

    event SubgraphNFTUpdated(address subgraphNFT);

    /**
     * @dev Emitted when graph account sets its default name
     */
    event SetDefaultName(
        address indexed graphAccount,
        uint256 nameSystem, // only ENS for now
        bytes32 nameIdentifier,
        string name
    );

    /**
     * @dev Emitted when the subgraph metadata is updated.
     */
    event SubgraphMetadataUpdated(uint256 indexed subgraphID, bytes32 subgraphMetadata);

    /**
     * @dev Emitted when a subgraph version is updated.
     */
    event SubgraphVersionUpdated(
        uint256 indexed subgraphID,
        bytes32 indexed subgraphDeploymentID,
        bytes32 versionMetadata
    );

    /**
     * @dev Emitted when a curator mints signal.
     */
    event SignalMinted(
        uint256 indexed subgraphID,
        address indexed curator,
        uint256 nSignalCreated,
        uint256 vSignalCreated,
        uint256 tokensDeposited
    );

    /**
     * @dev Emitted when a curator burns signal.
     */
    event SignalBurned(
        uint256 indexed subgraphID,
        address indexed curator,
        uint256 nSignalBurnt,
        uint256 vSignalBurnt,
        uint256 tokensReceived
    );

    /**
     * @dev Emitted when a subgraph is created.
     */
    event SubgraphPublished(
        uint256 indexed subgraphID,
        bytes32 indexed subgraphDeploymentID,
        uint32 reserveRatio
    );

    /**
     * @dev Emitted when a subgraph is upgraded to point to a new
     * subgraph deployment, burning all the old vSignal and depositing the GRT into the
     * new vSignal curve.
     */
    event SubgraphUpgraded(
        uint256 indexed subgraphID,
        uint256 vSignalCreated,
        uint256 tokensSignalled,
        bytes32 indexed subgraphDeploymentID
    );

    /**
     * @dev Emitted when a subgraph is deprecated.
     */
    event SubgraphDeprecated(uint256 indexed subgraphID, uint256 withdrawableGRT);

    /**
     * @dev Emitted when a curator withdraws GRT from a deprecated subgraph
     */
    event GRTWithdrawn(
        uint256 indexed subgraphID,
        address indexed curator,
        uint256 nSignalBurnt,
        uint256 withdrawnGRT
    );

    // -- Modifiers --

    /**
     * @dev Emitted when a legacy subgraph is claimed
     */
    event LegacySubgraphClaimed(address indexed graphAccount, uint256 subgraphNumber);

    /**
     * @dev Modifier that allows only a subgraph operator to be the caller
     */
    modifier onlySubgraphAuth(uint256 _subgraphID) {
        require(ownerOf(_subgraphID) == msg.sender, "GNS: Must be authorized");
        _;
    }

    // -- Functions --

    /**
     * @dev Initialize this contract.
     */
    function initialize(
        address _controller,
        address _bondingCurve,
        address _subgraphNFT
    ) external onlyImpl {
        Managed._initialize(_controller);

        // Dependencies
        bondingCurve = _bondingCurve;

        // Settings
        _setOwnerTaxPercentage(500000);
        _setSubgraphNFT(_subgraphNFT);
    }

    /**
     * @dev Approve curation contract to pull funds.
     */
    function approveAll() external override {
        graphToken().approve(address(curation()), MAX_UINT256);
    }

    // -- Config --

    /**
     * @dev Set the owner fee percentage. This is used to prevent a subgraph owner to drain all
     * the name curators tokens while upgrading or deprecating and is configurable in parts per million.
     * @param _ownerTaxPercentage Owner tax percentage
     */
    function setOwnerTaxPercentage(uint32 _ownerTaxPercentage) external override onlyGovernor {
        _setOwnerTaxPercentage(_ownerTaxPercentage);
    }

    /**
     * @dev Internal: Set the owner tax percentage. This is used to prevent a subgraph owner to drain all
     * the name curators tokens while upgrading or deprecating and is configurable in parts per million.
     * @param _ownerTaxPercentage Owner tax percentage
     */
    function _setOwnerTaxPercentage(uint32 _ownerTaxPercentage) private {
        require(_ownerTaxPercentage <= MAX_PPM, "Owner tax must be MAX_PPM or less");
        ownerTaxPercentage = _ownerTaxPercentage;
        emit ParameterUpdated("ownerTaxPercentage");
    }

    /**
     * @dev Set the NFT registry contract
     * NOTE: Calling this function will break the ownership model unless
     * it is replaced with a fully migrated version of the NFT contract state
     * Use with care.
     * @param _subgraphNFT Address of the ERC721 contract
     */
    function setSubgraphNFT(address _subgraphNFT) public onlyGovernor {
        _setSubgraphNFT(_subgraphNFT);
    }

    /**
     * @dev Internal: Set the NFT registry contract
     * @param _subgraphNFT Address of the ERC721 contract
     */
    function _setSubgraphNFT(address _subgraphNFT) private {
        require(
            _subgraphNFT != address(0) && Address.isContract(_subgraphNFT),
            "NFT must be valid"
        );
        subgraphNFT = ISubgraphNFT(_subgraphNFT);
        emit SubgraphNFTUpdated(_subgraphNFT);
    }

    // -- Actions --

    /**
     * @dev Allows a graph account to set a default name
     * @param _graphAccount Account that is setting its name
     * @param _nameSystem Name system account already has ownership of a name in
     * @param _nameIdentifier The unique identifier that is used to identify the name in the system
     * @param _name The name being set as default
     */
    function setDefaultName(
        address _graphAccount,
        uint8 _nameSystem,
        bytes32 _nameIdentifier,
        string calldata _name
    ) external override {
        require(_graphAccount == msg.sender, "GNS: Only you can set your name");
        emit SetDefaultName(_graphAccount, _nameSystem, _nameIdentifier, _name);
    }

    /**
     * @dev Allows a subgraph owner to update the metadata of a subgraph they have published
     * @param _subgraphID Subgraph ID
     * @param _subgraphMetadata IPFS hash for the subgraph metadata
     */
    function updateSubgraphMetadata(uint256 _subgraphID, bytes32 _subgraphMetadata)
        public
        override
        onlySubgraphAuth(_subgraphID)
    {
        _setSubgraphMetadata(_subgraphID, _subgraphMetadata);
    }

    /**
     * @dev Publish a new subgraph.
     * @param _subgraphDeploymentID Subgraph deployment for the subgraph
     * @param _versionMetadata IPFS hash for the subgraph version metadata
     * @param _subgraphMetadata IPFS hash for the subgraph metadata
     */
    function publishNewSubgraph(
        bytes32 _subgraphDeploymentID,
        bytes32 _versionMetadata,
        bytes32 _subgraphMetadata
    ) external override notPaused {
        // Subgraph deployment must be non-empty
        require(_subgraphDeploymentID != 0, "GNS: Cannot set deploymentID to 0 in publish");

        // Init the subgraph
        address subgraphOwner = msg.sender;
        uint256 subgraphID = _nextSubgraphID(subgraphOwner);
        SubgraphData storage subgraphData = _getSubgraphData(subgraphID);
        subgraphData.subgraphDeploymentID = _subgraphDeploymentID;
        subgraphData.reserveRatio = defaultReserveRatio;

        // Mint the NFT. Use the subgraphID as tokenID.
        // This function will check the if tokenID already exists.
        _mintNFT(subgraphOwner, subgraphID);
        emit SubgraphPublished(subgraphID, _subgraphDeploymentID, defaultReserveRatio);

        // Set the token metadata
        _setSubgraphMetadata(subgraphID, _subgraphMetadata);

        emit SubgraphVersionUpdated(subgraphID, _subgraphDeploymentID, _versionMetadata);
    }

    /**
     * @dev Publish a new version of an existing subgraph.
     * @param _subgraphID Subgraph ID
     * @param _subgraphDeploymentID Subgraph deployment ID of the new version
     * @param _versionMetadata IPFS hash for the subgraph version metadata
     */
    function publishNewVersion(
        uint256 _subgraphID,
        bytes32 _subgraphDeploymentID,
        bytes32 _versionMetadata
    ) external override notPaused onlySubgraphAuth(_subgraphID) {
        // Perform the upgrade from the current subgraph deployment to the new one.
        // This involves burning all signal from the old deployment and using the funds to buy
        // from the new deployment.
        // This will also make the change to target to the new deployment.

        // Subgraph check
        SubgraphData storage subgraphData = _getSubgraphOrRevert(_subgraphID);

        // New subgraph deployment must be non-empty
        require(_subgraphDeploymentID != 0, "GNS: Cannot set deploymentID to 0 in publish");

        // New subgraph deployment must be different than current
        require(
            _subgraphDeploymentID != subgraphData.subgraphDeploymentID,
            "GNS: Cannot publish a new version with the same subgraph deployment ID"
        );

        // This is to prevent the owner from front running its name curators signal by posting
        // its own signal ahead, bringing the name curators in, and dumping on them
        ICuration curation = curation();
        require(
            !curation.isCurated(_subgraphDeploymentID),
            "GNS: Owner cannot point to a subgraphID that has been pre-curated"
        );

        // Move all signal from previous version to new version
        // NOTE: We will only do this as long as there is signal on the subgraph
        if (subgraphData.nSignal > 0) {
            // Burn all version signal in the name pool for tokens (w/no slippage protection)
            // Sell all signal from the old deployment
            uint256 tokens = curation.burn(
                subgraphData.subgraphDeploymentID,
                subgraphData.vSignal,
                0
            );

            // Take the owner cut of the curation tax, add it to the total
            // Upgrade is only callable by the owner, we assume then that msg.sender = owner
            address subgraphOwner = msg.sender;
            uint256 tokensWithTax = _chargeOwnerTax(
                tokens,
                subgraphOwner,
                curation.curationTaxPercentage()
            );

            // Update pool: constant nSignal, vSignal can change (w/no slippage protection)
            // Buy all signal from the new deployment
            (subgraphData.vSignal, ) = curation.mint(_subgraphDeploymentID, tokensWithTax, 0);

            emit SubgraphUpgraded(
                _subgraphID,
                subgraphData.vSignal,
                tokensWithTax,
                _subgraphDeploymentID
            );
        }

        // Update target deployment
        subgraphData.subgraphDeploymentID = _subgraphDeploymentID;

        emit SubgraphVersionUpdated(_subgraphID, _subgraphDeploymentID, _versionMetadata);
    }

    /**
     * @dev Deprecate a subgraph. The bonding curve is destroyed, the vSignal is burned, and the GNS
     * contract holds the GRT from burning the vSignal, which all curators can withdraw manually.
     * Can only be done by the subgraph owner.
     * @param _subgraphID Subgraph ID
     */
    function deprecateSubgraph(uint256 _subgraphID)
        external
        override
        notPaused
        onlySubgraphAuth(_subgraphID)
    {
        // Subgraph check
        SubgraphData storage subgraphData = _getSubgraphOrRevert(_subgraphID);

        // Burn signal only if it has any available
        if (subgraphData.nSignal > 0) {
            subgraphData.withdrawableGRT = curation().burn(
                subgraphData.subgraphDeploymentID,
                subgraphData.vSignal,
                0
            );
        }

        // Deprecate the subgraph and do cleanup
        subgraphData.disabled = true;
        subgraphData.vSignal = 0;
        subgraphData.reserveRatio = 0;
        // NOTE: We don't reset the following variable as we use it to test if the Subgraph was ever created
        // subgraphData.subgraphDeploymentID = 0;

        // Burn the NFT
        _burnNFT(_subgraphID);

        emit SubgraphDeprecated(_subgraphID, subgraphData.withdrawableGRT);
    }

    /**
     * @dev Deposit GRT into a subgraph and mint signal.
     * @param _subgraphID Subgraph ID
     * @param _tokensIn The amount of tokens the nameCurator wants to deposit
     * @param _nSignalOutMin Expected minimum amount of name signal to receive
     */
    function mintSignal(
        uint256 _subgraphID,
        uint256 _tokensIn,
        uint256 _nSignalOutMin
    ) external override notPartialPaused {
        // Subgraph checks
        SubgraphData storage subgraphData = _getSubgraphOrRevert(_subgraphID);

        // Pull tokens from sender
        address curator = msg.sender;
        TokenUtils.pullTokens(graphToken(), curator, _tokensIn);

        // Get name signal to mint for tokens deposited
        (uint256 vSignal, ) = curation().mint(subgraphData.subgraphDeploymentID, _tokensIn, 0);
        uint256 nSignal = vSignalToNSignal(_subgraphID, vSignal);

        // Slippage protection
        require(nSignal >= _nSignalOutMin, "GNS: Slippage protection");

        // Update pools
        subgraphData.vSignal = subgraphData.vSignal.add(vSignal);
        subgraphData.nSignal = subgraphData.nSignal.add(nSignal);
        subgraphData.curatorNSignal[curator] = subgraphData.curatorNSignal[curator].add(nSignal);

        emit SignalMinted(_subgraphID, curator, nSignal, vSignal, _tokensIn);
    }

    /**
     * @dev Burn signal for a subgraph and return the GRT.
     * @param _subgraphID Subgraph ID
     * @param _nSignal The amount of nSignal the nameCurator wants to burn
     * @param _tokensOutMin Expected minimum amount of tokens to receive
     */
    function burnSignal(
        uint256 _subgraphID,
        uint256 _nSignal,
        uint256 _tokensOutMin
    ) external override notPartialPaused {
        // Subgraph checks
        SubgraphData storage subgraphData = _getSubgraphOrRevert(_subgraphID);

        // Curator balance checks
        address curator = msg.sender;
        uint256 curatorNSignal = subgraphData.curatorNSignal[curator];
        require(
            _nSignal <= curatorNSignal,
            "GNS: Curator cannot withdraw more nSignal than they have"
        );

        // Get tokens for name signal amount to burn
        uint256 vSignal = nSignalToVSignal(_subgraphID, _nSignal);
        uint256 tokens = curation().burn(subgraphData.subgraphDeploymentID, vSignal, _tokensOutMin);

        // Update pools
        subgraphData.vSignal = subgraphData.vSignal.sub(vSignal);
        subgraphData.nSignal = subgraphData.nSignal.sub(_nSignal);
        subgraphData.curatorNSignal[curator] = subgraphData.curatorNSignal[curator].sub(_nSignal);

        // Return the tokens to the nameCurator
        require(graphToken().transfer(curator, tokens), "GNS: Error sending tokens");

        emit SignalBurned(_subgraphID, curator, _nSignal, vSignal, tokens);
    }

    /**
     * @dev Withdraw tokens from a deprecated subgraph.
     * When the subgraph is deprecated, any curator can call this function and
     * withdraw the GRT they are entitled for its original deposit
     * @param _subgraphID Subgraph ID
     */
    function withdraw(uint256 _subgraphID) external override notPartialPaused {
        // Subgraph validations
        SubgraphData storage subgraphData = _getSubgraphData(_subgraphID);
        require(subgraphData.disabled == true, "GNS: Must be disabled first");
        require(subgraphData.withdrawableGRT > 0, "GNS: No more GRT to withdraw");

        // Curator validations
        address curator = msg.sender;
        uint256 curatorNSignal = subgraphData.curatorNSignal[curator];
        require(curatorNSignal > 0, "GNS: No signal to withdraw GRT");

        // Get curator share of tokens to be withdrawn
        uint256 tokensOut = curatorNSignal.mul(subgraphData.withdrawableGRT).div(
            subgraphData.nSignal
        );
        subgraphData.curatorNSignal[curator] = 0;
        subgraphData.nSignal = subgraphData.nSignal.sub(curatorNSignal);
        subgraphData.withdrawableGRT = subgraphData.withdrawableGRT.sub(tokensOut);

        // Return tokens to the curator
        TokenUtils.pushTokens(graphToken(), curator, tokensOut);

        emit GRTWithdrawn(_subgraphID, curator, curatorNSignal, tokensOut);
    }

    /**
     * @dev Calculate tax that owner will have to cover for upgrading or deprecating.
     * @param _tokens Tokens that were received from deprecating the old subgraph
     * @param _owner Subgraph owner
     * @param _curationTaxPercentage Tax percentage on curation deposits from Curation contract
     * @return Total tokens that will be sent to curation, _tokens + ownerTax
     */
    function _chargeOwnerTax(
        uint256 _tokens,
        address _owner,
        uint32 _curationTaxPercentage
    ) private returns (uint256) {
        if (_curationTaxPercentage == 0 || ownerTaxPercentage == 0) {
            return 0;
        }

        // Tax on the total bonding curve funds
        uint256 taxOnOriginal = _tokens.mul(_curationTaxPercentage).div(MAX_PPM);
        // Total after the tax
        uint256 totalWithoutOwnerTax = _tokens.sub(taxOnOriginal);
        // The portion of tax that the owner will pay
        uint256 ownerTax = taxOnOriginal.mul(ownerTaxPercentage).div(MAX_PPM);

        uint256 totalWithOwnerTax = totalWithoutOwnerTax.add(ownerTax);

        // The total after tax, plus owner partial repay, divided by
        // the tax, to adjust it slightly upwards. ex:
        // 100 GRT, 5 GRT Tax, owner pays 100% --> 5 GRT
        // To get 100 in the protocol after tax, Owner deposits
        // ~5.26, as ~105.26 * .95 = 100
        uint256 totalAdjustedUp = totalWithOwnerTax.mul(MAX_PPM).div(
            uint256(MAX_PPM).sub(uint256(_curationTaxPercentage))
        );

        uint256 ownerTaxAdjustedUp = totalAdjustedUp.sub(_tokens);

        // Get the owner of the subgraph to reimburse the curation tax
        TokenUtils.pullTokens(graphToken(), _owner, ownerTaxAdjustedUp);

        return totalAdjustedUp;
    }

    /**
     * @dev Calculate subgraph signal to be returned for an amount of tokens.
     * @param _subgraphID Subgraph ID
     * @param _tokensIn Tokens being exchanged for subgraph signal
     * @return Amount of subgraph signal and curation tax
     */
    function tokensToNSignal(uint256 _subgraphID, uint256 _tokensIn)
        public
        view
        override
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        SubgraphData storage subgraphData = _getSubgraphData(_subgraphID);
        (uint256 vSignal, uint256 curationTax) = curation().tokensToSignal(
            subgraphData.subgraphDeploymentID,
            _tokensIn
        );
        uint256 nSignal = vSignalToNSignal(_subgraphID, vSignal);
        return (vSignal, nSignal, curationTax);
    }

    /**
     * @dev Calculate tokens returned for an amount of subgraph signal.
     * @param _subgraphID Subgraph ID
     * @param _nSignalIn Subgraph signal being exchanged for tokens
     * @return Amount of tokens returned for an amount of subgraph signal
     */
    function nSignalToTokens(uint256 _subgraphID, uint256 _nSignalIn)
        public
        view
        override
        returns (uint256, uint256)
    {
        // Get subgraph or revert if not published
        // It does not make sense to convert signal from a disabled or non-existing one
        SubgraphData storage subgraphData = _getSubgraphOrRevert(_subgraphID);
        uint256 vSignal = nSignalToVSignal(_subgraphID, _nSignalIn);
        uint256 tokensOut = curation().signalToTokens(subgraphData.subgraphDeploymentID, vSignal);
        return (vSignal, tokensOut);
    }

    /**
     * @dev Calculate subgraph signal to be returned for an amount of subgraph deployment signal.
     * @param _subgraphID Subgraph ID
     * @param _vSignalIn Amount of subgraph deployment signal to exchange for subgraph signal
     * @return Amount of subgraph signal that can be bought
     */
    function vSignalToNSignal(uint256 _subgraphID, uint256 _vSignalIn)
        public
        view
        override
        returns (uint256)
    {
        SubgraphData storage subgraphData = _getSubgraphData(_subgraphID);

        // Handle initialization by using 1:1 version to name signal
        if (subgraphData.vSignal == 0) {
            return _vSignalIn;
        }

        return
            BancorFormula(bondingCurve).calculatePurchaseReturn(
                subgraphData.nSignal,
                subgraphData.vSignal,
                subgraphData.reserveRatio,
                _vSignalIn
            );
    }

    /**
     * @dev Calculate subgraph deployment signal to be returned for an amount of subgraph signal.
     * @param _subgraphID Subgraph ID
     * @param _nSignalIn Subgraph signal being exchanged for subgraph deployment signal
     * @return Amount of subgraph deployment signal that can be returned
     */
    function nSignalToVSignal(uint256 _subgraphID, uint256 _nSignalIn)
        public
        view
        override
        returns (uint256)
    {
        SubgraphData storage subgraphData = _getSubgraphData(_subgraphID);
        return
            BancorFormula(bondingCurve).calculateSaleReturn(
                subgraphData.nSignal,
                subgraphData.vSignal,
                subgraphData.reserveRatio,
                _nSignalIn
            );
    }

    /**
     * @dev Get the amount of subgraph signal a curator has.
     * @param _subgraphID Subgraph ID
     * @param _curator Curator address
     * @return Amount of subgraph signal owned by a curator
     */
    function getCuratorSignal(uint256 _subgraphID, address _curator)
        public
        view
        override
        returns (uint256)
    {
        return _getSubgraphData(_subgraphID).curatorNSignal[_curator];
    }

    /**
     * @dev Return the total signal on the subgraph.
     * @param _subgraphID Subgraph ID
     * @return Total signal on the subgraph
     */
    function subgraphSignal(uint256 _subgraphID) external view override returns (uint256) {
        return _getSubgraphData(_subgraphID).nSignal;
    }

    /**
     * @dev Return the total tokens on the subgraph at current value.
     * @param _subgraphID Subgraph ID
     * @return Total tokens on the subgraph
     */
    function subgraphTokens(uint256 _subgraphID) external view override returns (uint256) {
        uint256 signal = _getSubgraphData(_subgraphID).nSignal;
        if (signal > 0) {
            (, uint256 tokens) = nSignalToTokens(_subgraphID, signal);
            return tokens;
        }
        return 0;
    }

    /**
     * @dev Create subgraphID for legacy subgraph and mint ownership NFT.
     * @param _graphAccount Account that created the subgraph
     * @param _subgraphNumber The sequence number of the created subgraph
     * @param _subgraphMetadata IPFS hash for the subgraph metadata
     */
    function migrateLegacySubgraph(
        address _graphAccount,
        uint256 _subgraphNumber,
        bytes32 _subgraphMetadata
    ) external {
        // Must be an existing legacy subgraph
        bool legacySubgraphExists = legacySubgraphData[_graphAccount][_subgraphNumber]
            .subgraphDeploymentID != 0;
        require(legacySubgraphExists == true, "GNS: Subgraph does not exist");

        // Must not be a claimed subgraph
        uint256 subgraphID = _buildSubgraphID(_graphAccount, _subgraphNumber);
        require(
            legacySubgraphKeys[subgraphID].account == address(0),
            "GNS: Subgraph was already claimed"
        );

        // Store a reference for a legacy subgraph
        legacySubgraphKeys[subgraphID] = IGNS.LegacySubgraphKey({
            account: _graphAccount,
            accountSeqID: _subgraphNumber
        });

        // Delete state for legacy subgraph
        legacySubgraphs[_graphAccount][_subgraphNumber] = 0;

        // Mint the NFT and send to owner
        // The subgraph owner is the graph account that created it
        _mintNFT(_graphAccount, subgraphID);
        emit LegacySubgraphClaimed(_graphAccount, _subgraphNumber);

        // Set the token metadata
        _setSubgraphMetadata(subgraphID, _subgraphMetadata);
    }

    /**
     * @dev Return whether a subgraph is published.
     * @param _subgraphID Subgraph ID
     * @return Return true if subgraph is currently published
     */
    function isPublished(uint256 _subgraphID) public view override returns (bool) {
        return _isPublished(_getSubgraphData(_subgraphID));
    }

    /**
     * @dev Build a subgraph ID based on the account creating it and a sequence number for that account.
     * Subgraph ID is the keccak hash of account+seqID
     * @return Subgraph ID
     */
    function _buildSubgraphID(address _account, uint256 _seqID) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(_account, _seqID)));
    }

    /**
     * @dev Return the next subgraphID given the account that is creating the subgraph.
     * NOTE: This function updates the sequence ID for the account
     * @return Sequence ID for the account
     */
    function _nextSubgraphID(address _account) internal returns (uint256) {
        return _buildSubgraphID(_account, _nextAccountSeqID(_account));
    }

    /**
     * @dev Return a new consecutive sequence ID for an account and update to the next value.
     * NOTE: This function updates the sequence ID for the account
     * @return Sequence ID for the account
     */
    function _nextAccountSeqID(address _account) internal returns (uint256) {
        uint256 seqID = nextAccountSeqID[_account];
        nextAccountSeqID[_account] = nextAccountSeqID[_account].add(1);
        return seqID;
    }

    /**
     * @dev Get subgraph data.
     * This function will first look for a v1 subgraph and return it if found.
     * @param _subgraphID Subgraph ID
     * @return Subgraph Data
     */
    function _getSubgraphData(uint256 _subgraphID) private view returns (SubgraphData storage) {
        // If there is a legacy subgraph created return it
        LegacySubgraphKey storage legacySubgraphKey = legacySubgraphKeys[_subgraphID];
        if (legacySubgraphKey.account != address(0)) {
            return legacySubgraphData[legacySubgraphKey.account][legacySubgraphKey.accountSeqID];
        }
        // Return new subgraph type
        return subgraphs[_subgraphID];
    }

    /**
     * @dev Return whether a subgraph is published.
     * @param _subgraphData Subgraph Data
     * @return Return true if subgraph is currently published
     */
    function _isPublished(SubgraphData storage _subgraphData) internal view returns (bool) {
        return _subgraphData.subgraphDeploymentID != 0 && _subgraphData.disabled == false;
    }

    /**
     * @dev Return the subgraph data or revert if not published or deprecated.
     * @param _subgraphID Subgraph ID
     * @return Subgraph Data
     */
    function _getSubgraphOrRevert(uint256 _subgraphID)
        internal
        view
        returns (SubgraphData storage)
    {
        SubgraphData storage subgraphData = _getSubgraphData(_subgraphID);
        require(_isPublished(subgraphData) == true, "GNS: Must be active");
        return subgraphData;
    }

    // -- NFT --

    /**
     * @dev Return the owner of a subgraph.
     * @param _tokenID Subgraph ID
     * @return Owner address
     */
    function ownerOf(uint256 _tokenID) public view override returns (address) {
        return subgraphNFT.ownerOf(_tokenID);
    }

    /**
     * @dev Mint the NFT for the subgraph.
     * @param _owner Owner address
     * @param _tokenID Subgraph ID
     */
    function _mintNFT(address _owner, uint256 _tokenID) internal {
        subgraphNFT.mint(_owner, _tokenID);
    }

    /**
     * @dev Burn the NFT for the subgraph.
     * @param _tokenID Subgraph ID
     */
    function _burnNFT(uint256 _tokenID) internal {
        subgraphNFT.burn(_tokenID);
    }

    /**
     * @dev Set the subgraph metadata.
     * @param _tokenID Subgraph ID
     * @param _subgraphMetadata IPFS hash of the subgraph metadata
     */
    function _setSubgraphMetadata(uint256 _tokenID, bytes32 _subgraphMetadata) internal {
        subgraphNFT.setSubgraphMetadata(_tokenID, _subgraphMetadata);

        // Even if the following event is emitted in the NFT we emit it here to facilitate
        // subgraph indexing
        emit SubgraphMetadataUpdated(_tokenID, _subgraphMetadata);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.7.6;
pragma abicoder v2;

import "./IMulticall.sol";

// Inspired by https://github.com/Uniswap/uniswap-v3-periphery/blob/main/contracts/base/Multicall.sol
// Note: Removed payable from the multicall

/**
 * @title Multicall
 * @notice Enables calling multiple methods in a single call to the contract
 */
abstract contract Multicall is IMulticall {
    /// @inheritdoc IMulticall
    function multicall(bytes[] calldata data) external override returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);

            if (!success) {
                // Next 5 lines from https://ethereum.stackexchange.com/a/83577
                if (result.length < 68) revert();
                assembly {
                    result := add(result, 0x04)
                }
                revert(abi.decode(result, (string)));
            }

            results[i] = result;
        }
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";

contract BancorFormula {
    using SafeMath for uint256;

    uint16 public constant version = 6;

    uint256 private constant ONE = 1;
    uint32 private constant MAX_RATIO = 1000000;
    uint8 private constant MIN_PRECISION = 32;
    uint8 private constant MAX_PRECISION = 127;

    /**
     * @dev Auto-generated via 'PrintIntScalingFactors.py'
     */
    uint256 private constant FIXED_1 = 0x080000000000000000000000000000000;
    uint256 private constant FIXED_2 = 0x100000000000000000000000000000000;
    uint256 private constant MAX_NUM = 0x200000000000000000000000000000000;

    /**
     * @dev Auto-generated via 'PrintLn2ScalingFactors.py'
     */
    uint256 private constant LN2_NUMERATOR = 0x3f80fe03f80fe03f80fe03f80fe03f8;
    uint256 private constant LN2_DENOMINATOR = 0x5b9de1d10bf4103d647b0955897ba80;

    /**
     * @dev Auto-generated via 'PrintFunctionOptimalLog.py' and 'PrintFunctionOptimalExp.py'
     */
    uint256 private constant OPT_LOG_MAX_VAL = 0x15bf0a8b1457695355fb8ac404e7a79e3;
    uint256 private constant OPT_EXP_MAX_VAL = 0x800000000000000000000000000000000;

    /**
     * @dev Auto-generated via 'PrintFunctionConstructor.py'
     */
    uint256[128] private maxExpArray;

    constructor() {
        //  maxExpArray[  0] = 0x6bffffffffffffffffffffffffffffffff;
        //  maxExpArray[  1] = 0x67ffffffffffffffffffffffffffffffff;
        //  maxExpArray[  2] = 0x637fffffffffffffffffffffffffffffff;
        //  maxExpArray[  3] = 0x5f6fffffffffffffffffffffffffffffff;
        //  maxExpArray[  4] = 0x5b77ffffffffffffffffffffffffffffff;
        //  maxExpArray[  5] = 0x57b3ffffffffffffffffffffffffffffff;
        //  maxExpArray[  6] = 0x5419ffffffffffffffffffffffffffffff;
        //  maxExpArray[  7] = 0x50a2ffffffffffffffffffffffffffffff;
        //  maxExpArray[  8] = 0x4d517fffffffffffffffffffffffffffff;
        //  maxExpArray[  9] = 0x4a233fffffffffffffffffffffffffffff;
        //  maxExpArray[ 10] = 0x47165fffffffffffffffffffffffffffff;
        //  maxExpArray[ 11] = 0x4429afffffffffffffffffffffffffffff;
        //  maxExpArray[ 12] = 0x415bc7ffffffffffffffffffffffffffff;
        //  maxExpArray[ 13] = 0x3eab73ffffffffffffffffffffffffffff;
        //  maxExpArray[ 14] = 0x3c1771ffffffffffffffffffffffffffff;
        //  maxExpArray[ 15] = 0x399e96ffffffffffffffffffffffffffff;
        //  maxExpArray[ 16] = 0x373fc47fffffffffffffffffffffffffff;
        //  maxExpArray[ 17] = 0x34f9e8ffffffffffffffffffffffffffff;
        //  maxExpArray[ 18] = 0x32cbfd5fffffffffffffffffffffffffff;
        //  maxExpArray[ 19] = 0x30b5057fffffffffffffffffffffffffff;
        //  maxExpArray[ 20] = 0x2eb40f9fffffffffffffffffffffffffff;
        //  maxExpArray[ 21] = 0x2cc8340fffffffffffffffffffffffffff;
        //  maxExpArray[ 22] = 0x2af09481ffffffffffffffffffffffffff;
        //  maxExpArray[ 23] = 0x292c5bddffffffffffffffffffffffffff;
        //  maxExpArray[ 24] = 0x277abdcdffffffffffffffffffffffffff;
        //  maxExpArray[ 25] = 0x25daf6657fffffffffffffffffffffffff;
        //  maxExpArray[ 26] = 0x244c49c65fffffffffffffffffffffffff;
        //  maxExpArray[ 27] = 0x22ce03cd5fffffffffffffffffffffffff;
        //  maxExpArray[ 28] = 0x215f77c047ffffffffffffffffffffffff;
        //  maxExpArray[ 29] = 0x1fffffffffffffffffffffffffffffffff;
        //  maxExpArray[ 30] = 0x1eaefdbdabffffffffffffffffffffffff;
        //  maxExpArray[ 31] = 0x1d6bd8b2ebffffffffffffffffffffffff;
        maxExpArray[32] = 0x1c35fedd14ffffffffffffffffffffffff;
        maxExpArray[33] = 0x1b0ce43b323fffffffffffffffffffffff;
        maxExpArray[34] = 0x19f0028ec1ffffffffffffffffffffffff;
        maxExpArray[35] = 0x18ded91f0e7fffffffffffffffffffffff;
        maxExpArray[36] = 0x17d8ec7f0417ffffffffffffffffffffff;
        maxExpArray[37] = 0x16ddc6556cdbffffffffffffffffffffff;
        maxExpArray[38] = 0x15ecf52776a1ffffffffffffffffffffff;
        maxExpArray[39] = 0x15060c256cb2ffffffffffffffffffffff;
        maxExpArray[40] = 0x1428a2f98d72ffffffffffffffffffffff;
        maxExpArray[41] = 0x13545598e5c23fffffffffffffffffffff;
        maxExpArray[42] = 0x1288c4161ce1dfffffffffffffffffffff;
        maxExpArray[43] = 0x11c592761c666fffffffffffffffffffff;
        maxExpArray[44] = 0x110a688680a757ffffffffffffffffffff;
        maxExpArray[45] = 0x1056f1b5bedf77ffffffffffffffffffff;
        maxExpArray[46] = 0x0faadceceeff8bffffffffffffffffffff;
        maxExpArray[47] = 0x0f05dc6b27edadffffffffffffffffffff;
        maxExpArray[48] = 0x0e67a5a25da4107fffffffffffffffffff;
        maxExpArray[49] = 0x0dcff115b14eedffffffffffffffffffff;
        maxExpArray[50] = 0x0d3e7a392431239fffffffffffffffffff;
        maxExpArray[51] = 0x0cb2ff529eb71e4fffffffffffffffffff;
        maxExpArray[52] = 0x0c2d415c3db974afffffffffffffffffff;
        maxExpArray[53] = 0x0bad03e7d883f69bffffffffffffffffff;
        maxExpArray[54] = 0x0b320d03b2c343d5ffffffffffffffffff;
        maxExpArray[55] = 0x0abc25204e02828dffffffffffffffffff;
        maxExpArray[56] = 0x0a4b16f74ee4bb207fffffffffffffffff;
        maxExpArray[57] = 0x09deaf736ac1f569ffffffffffffffffff;
        maxExpArray[58] = 0x0976bd9952c7aa957fffffffffffffffff;
        maxExpArray[59] = 0x09131271922eaa606fffffffffffffffff;
        maxExpArray[60] = 0x08b380f3558668c46fffffffffffffffff;
        maxExpArray[61] = 0x0857ddf0117efa215bffffffffffffffff;
        maxExpArray[62] = 0x07ffffffffffffffffffffffffffffffff;
        maxExpArray[63] = 0x07abbf6f6abb9d087fffffffffffffffff;
        maxExpArray[64] = 0x075af62cbac95f7dfa7fffffffffffffff;
        maxExpArray[65] = 0x070d7fb7452e187ac13fffffffffffffff;
        maxExpArray[66] = 0x06c3390ecc8af379295fffffffffffffff;
        maxExpArray[67] = 0x067c00a3b07ffc01fd6fffffffffffffff;
        maxExpArray[68] = 0x0637b647c39cbb9d3d27ffffffffffffff;
        maxExpArray[69] = 0x05f63b1fc104dbd39587ffffffffffffff;
        maxExpArray[70] = 0x05b771955b36e12f7235ffffffffffffff;
        maxExpArray[71] = 0x057b3d49dda84556d6f6ffffffffffffff;
        maxExpArray[72] = 0x054183095b2c8ececf30ffffffffffffff;
        maxExpArray[73] = 0x050a28be635ca2b888f77fffffffffffff;
        maxExpArray[74] = 0x04d5156639708c9db33c3fffffffffffff;
        maxExpArray[75] = 0x04a23105873875bd52dfdfffffffffffff;
        maxExpArray[76] = 0x0471649d87199aa990756fffffffffffff;
        maxExpArray[77] = 0x04429a21a029d4c1457cfbffffffffffff;
        maxExpArray[78] = 0x0415bc6d6fb7dd71af2cb3ffffffffffff;
        maxExpArray[79] = 0x03eab73b3bbfe282243ce1ffffffffffff;
        maxExpArray[80] = 0x03c1771ac9fb6b4c18e229ffffffffffff;
        maxExpArray[81] = 0x0399e96897690418f785257fffffffffff;
        maxExpArray[82] = 0x0373fc456c53bb779bf0ea9fffffffffff;
        maxExpArray[83] = 0x034f9e8e490c48e67e6ab8bfffffffffff;
        maxExpArray[84] = 0x032cbfd4a7adc790560b3337ffffffffff;
        maxExpArray[85] = 0x030b50570f6e5d2acca94613ffffffffff;
        maxExpArray[86] = 0x02eb40f9f620fda6b56c2861ffffffffff;
        maxExpArray[87] = 0x02cc8340ecb0d0f520a6af58ffffffffff;
        maxExpArray[88] = 0x02af09481380a0a35cf1ba02ffffffffff;
        maxExpArray[89] = 0x0292c5bdd3b92ec810287b1b3fffffffff;
        maxExpArray[90] = 0x0277abdcdab07d5a77ac6d6b9fffffffff;
        maxExpArray[91] = 0x025daf6654b1eaa55fd64df5efffffffff;
        maxExpArray[92] = 0x0244c49c648baa98192dce88b7ffffffff;
        maxExpArray[93] = 0x022ce03cd5619a311b2471268bffffffff;
        maxExpArray[94] = 0x0215f77c045fbe885654a44a0fffffffff;
        maxExpArray[95] = 0x01ffffffffffffffffffffffffffffffff;
        maxExpArray[96] = 0x01eaefdbdaaee7421fc4d3ede5ffffffff;
        maxExpArray[97] = 0x01d6bd8b2eb257df7e8ca57b09bfffffff;
        maxExpArray[98] = 0x01c35fedd14b861eb0443f7f133fffffff;
        maxExpArray[99] = 0x01b0ce43b322bcde4a56e8ada5afffffff;
        maxExpArray[100] = 0x019f0028ec1fff007f5a195a39dfffffff;
        maxExpArray[101] = 0x018ded91f0e72ee74f49b15ba527ffffff;
        maxExpArray[102] = 0x017d8ec7f04136f4e5615fd41a63ffffff;
        maxExpArray[103] = 0x016ddc6556cdb84bdc8d12d22e6fffffff;
        maxExpArray[104] = 0x015ecf52776a1155b5bd8395814f7fffff;
        maxExpArray[105] = 0x015060c256cb23b3b3cc3754cf40ffffff;
        maxExpArray[106] = 0x01428a2f98d728ae223ddab715be3fffff;
        maxExpArray[107] = 0x013545598e5c23276ccf0ede68034fffff;
        maxExpArray[108] = 0x01288c4161ce1d6f54b7f61081194fffff;
        maxExpArray[109] = 0x011c592761c666aa641d5a01a40f17ffff;
        maxExpArray[110] = 0x0110a688680a7530515f3e6e6cfdcdffff;
        maxExpArray[111] = 0x01056f1b5bedf75c6bcb2ce8aed428ffff;
        maxExpArray[112] = 0x00faadceceeff8a0890f3875f008277fff;
        maxExpArray[113] = 0x00f05dc6b27edad306388a600f6ba0bfff;
        maxExpArray[114] = 0x00e67a5a25da41063de1495d5b18cdbfff;
        maxExpArray[115] = 0x00dcff115b14eedde6fc3aa5353f2e4fff;
        maxExpArray[116] = 0x00d3e7a3924312399f9aae2e0f868f8fff;
        maxExpArray[117] = 0x00cb2ff529eb71e41582cccd5a1ee26fff;
        maxExpArray[118] = 0x00c2d415c3db974ab32a51840c0b67edff;
        maxExpArray[119] = 0x00bad03e7d883f69ad5b0a186184e06bff;
        maxExpArray[120] = 0x00b320d03b2c343d4829abd6075f0cc5ff;
        maxExpArray[121] = 0x00abc25204e02828d73c6e80bcdb1a95bf;
        maxExpArray[122] = 0x00a4b16f74ee4bb2040a1ec6c15fbbf2df;
        maxExpArray[123] = 0x009deaf736ac1f569deb1b5ae3f36c130f;
        maxExpArray[124] = 0x00976bd9952c7aa957f5937d790ef65037;
        maxExpArray[125] = 0x009131271922eaa6064b73a22d0bd4f2bf;
        maxExpArray[126] = 0x008b380f3558668c46c91c49a2f8e967b9;
        maxExpArray[127] = 0x00857ddf0117efa215952912839f6473e6;
    }

    /**
     * @dev given a token supply, reserve balance, ratio and a deposit amount (in the reserve token),
     * calculates the return for a given conversion (in the main token)
     *
     * Formula:
     * Return = _supply * ((1 + _depositAmount / _reserveBalance) ^ (_reserveRatio / 1000000) - 1)
     *
     * @param _supply              token total supply
     * @param _reserveBalance      total reserve balance
     * @param _reserveRatio        reserve ratio, represented in ppm, 1-1000000
     * @param _depositAmount       deposit amount, in reserve token
     *
     * @return purchase return amount
     */
    function calculatePurchaseReturn(
        uint256 _supply,
        uint256 _reserveBalance,
        uint32 _reserveRatio,
        uint256 _depositAmount
    ) public view returns (uint256) {
        // validate input
        require(
            _supply > 0 && _reserveBalance > 0 && _reserveRatio > 0 && _reserveRatio <= MAX_RATIO,
            "invalid parameters"
        );

        // special case for 0 deposit amount
        if (_depositAmount == 0) return 0;

        // special case if the ratio = 100%
        if (_reserveRatio == MAX_RATIO) return _supply.mul(_depositAmount) / _reserveBalance;

        uint256 result;
        uint8 precision;
        uint256 baseN = _depositAmount.add(_reserveBalance);
        (result, precision) = power(baseN, _reserveBalance, _reserveRatio, MAX_RATIO);
        uint256 temp = _supply.mul(result) >> precision;
        return temp - _supply;
    }

    /**
     * @dev given a token supply, reserve balance, ratio and a sell amount (in the main token),
     * calculates the return for a given conversion (in the reserve token)
     *
     * Formula:
     * Return = _reserveBalance * (1 - (1 - _sellAmount / _supply) ^ (1000000 / _reserveRatio))
     *
     * @param _supply              token total supply
     * @param _reserveBalance      total reserve
     * @param _reserveRatio        constant reserve Ratio, represented in ppm, 1-1000000
     * @param _sellAmount          sell amount, in the token itself
     *
     * @return sale return amount
     */
    function calculateSaleReturn(
        uint256 _supply,
        uint256 _reserveBalance,
        uint32 _reserveRatio,
        uint256 _sellAmount
    ) public view returns (uint256) {
        // validate input
        require(
            _supply > 0 &&
                _reserveBalance > 0 &&
                _reserveRatio > 0 &&
                _reserveRatio <= MAX_RATIO &&
                _sellAmount <= _supply,
            "invalid parameters"
        );

        // special case for 0 sell amount
        if (_sellAmount == 0) return 0;

        // special case for selling the entire supply
        if (_sellAmount == _supply) return _reserveBalance;

        // special case if the ratio = 100%
        if (_reserveRatio == MAX_RATIO) return _reserveBalance.mul(_sellAmount) / _supply;

        uint256 result;
        uint8 precision;
        uint256 baseD = _supply - _sellAmount;
        (result, precision) = power(_supply, baseD, MAX_RATIO, _reserveRatio);
        uint256 temp1 = _reserveBalance.mul(result);
        uint256 temp2 = _reserveBalance << precision;
        return (temp1 - temp2) / result;
    }

    /**
     * @dev given two reserve balances/ratios and a sell amount (in the first reserve token),
     * calculates the return for a conversion from the first reserve token to the second reserve token (in the second reserve token)
     * note that prior to version 4, you should use 'calculateCrossConnectorReturn' instead
     *
     * Formula:
     * Return = _toReserveBalance * (1 - (_fromReserveBalance / (_fromReserveBalance + _amount)) ^ (_fromReserveRatio / _toReserveRatio))
     *
     * @param _fromReserveBalance      input reserve balance
     * @param _fromReserveRatio        input reserve ratio, represented in ppm, 1-1000000
     * @param _toReserveBalance        output reserve balance
     * @param _toReserveRatio          output reserve ratio, represented in ppm, 1-1000000
     * @param _amount                  input reserve amount
     *
     * @return second reserve amount
     */
    function calculateCrossReserveReturn(
        uint256 _fromReserveBalance,
        uint32 _fromReserveRatio,
        uint256 _toReserveBalance,
        uint32 _toReserveRatio,
        uint256 _amount
    ) public view returns (uint256) {
        // validate input
        require(
            _fromReserveBalance > 0 &&
                _fromReserveRatio > 0 &&
                _fromReserveRatio <= MAX_RATIO &&
                _toReserveBalance > 0 &&
                _toReserveRatio > 0 &&
                _toReserveRatio <= MAX_RATIO
        );

        // special case for equal ratios
        if (_fromReserveRatio == _toReserveRatio)
            return _toReserveBalance.mul(_amount) / _fromReserveBalance.add(_amount);

        uint256 result;
        uint8 precision;
        uint256 baseN = _fromReserveBalance.add(_amount);
        (result, precision) = power(baseN, _fromReserveBalance, _fromReserveRatio, _toReserveRatio);
        uint256 temp1 = _toReserveBalance.mul(result);
        uint256 temp2 = _toReserveBalance << precision;
        return (temp1 - temp2) / result;
    }

    /**
     * @dev given a smart token supply, reserve balance, total ratio and an amount of requested smart tokens,
     * calculates the amount of reserve tokens required for purchasing the given amount of smart tokens
     *
     * Formula:
     * Return = _reserveBalance * (((_supply + _amount) / _supply) ^ (MAX_RATIO / _totalRatio) - 1)
     *
     * @param _supply              smart token supply
     * @param _reserveBalance      reserve token balance
     * @param _totalRatio          total ratio, represented in ppm, 2-2000000
     * @param _amount              requested amount of smart tokens
     *
     * @return amount of reserve tokens
     */
    function calculateFundCost(
        uint256 _supply,
        uint256 _reserveBalance,
        uint32 _totalRatio,
        uint256 _amount
    ) public view returns (uint256) {
        // validate input
        require(
            _supply > 0 && _reserveBalance > 0 && _totalRatio > 1 && _totalRatio <= MAX_RATIO * 2
        );

        // special case for 0 amount
        if (_amount == 0) return 0;

        // special case if the total ratio = 100%
        if (_totalRatio == MAX_RATIO) return (_amount.mul(_reserveBalance) - 1) / _supply + 1;

        uint256 result;
        uint8 precision;
        uint256 baseN = _supply.add(_amount);
        (result, precision) = power(baseN, _supply, MAX_RATIO, _totalRatio);
        uint256 temp = ((_reserveBalance.mul(result) - 1) >> precision) + 1;
        return temp - _reserveBalance;
    }

    /**
     * @dev given a smart token supply, reserve balance, total ratio and an amount of smart tokens to liquidate,
     * calculates the amount of reserve tokens received for selling the given amount of smart tokens
     *
     * Formula:
     * Return = _reserveBalance * (1 - ((_supply - _amount) / _supply) ^ (MAX_RATIO / _totalRatio))
     *
     * @param _supply              smart token supply
     * @param _reserveBalance      reserve token balance
     * @param _totalRatio          total ratio, represented in ppm, 2-2000000
     * @param _amount              amount of smart tokens to liquidate
     *
     * @return amount of reserve tokens
     */
    function calculateLiquidateReturn(
        uint256 _supply,
        uint256 _reserveBalance,
        uint32 _totalRatio,
        uint256 _amount
    ) public view returns (uint256) {
        // validate input
        require(
            _supply > 0 &&
                _reserveBalance > 0 &&
                _totalRatio > 1 &&
                _totalRatio <= MAX_RATIO * 2 &&
                _amount <= _supply
        );

        // special case for 0 amount
        if (_amount == 0) return 0;

        // special case for liquidating the entire supply
        if (_amount == _supply) return _reserveBalance;

        // special case if the total ratio = 100%
        if (_totalRatio == MAX_RATIO) return _amount.mul(_reserveBalance) / _supply;

        uint256 result;
        uint8 precision;
        uint256 baseD = _supply - _amount;
        (result, precision) = power(_supply, baseD, MAX_RATIO, _totalRatio);
        uint256 temp1 = _reserveBalance.mul(result);
        uint256 temp2 = _reserveBalance << precision;
        return (temp1 - temp2) / result;
    }

    /**
     * @dev General Description:
     *     Determine a value of precision.
     *     Calculate an integer approximation of (_baseN / _baseD) ^ (_expN / _expD) * 2 ^ precision.
     *     Return the result along with the precision used.
     *
     * Detailed Description:
     *     Instead of calculating "base ^ exp", we calculate "e ^ (log(base) * exp)".
     *     The value of "log(base)" is represented with an integer slightly smaller than "log(base) * 2 ^ precision".
     *     The larger "precision" is, the more accurately this value represents the real value.
     *     However, the larger "precision" is, the more bits are required in order to store this value.
     *     And the exponentiation function, which takes "x" and calculates "e ^ x", is limited to a maximum exponent (maximum value of "x").
     *     This maximum exponent depends on the "precision" used, and it is given by "maxExpArray[precision] >> (MAX_PRECISION - precision)".
     *     Hence we need to determine the highest precision which can be used for the given input, before calling the exponentiation function.
     *     This allows us to compute "base ^ exp" with maximum accuracy and without exceeding 256 bits in any of the intermediate computations.
     *     This functions assumes that "_expN < 2 ^ 256 / log(MAX_NUM - 1)", otherwise the multiplication should be replaced with a "safeMul".
     *     Since we rely on unsigned-integer arithmetic and "base < 1" ==> "log(base) < 0", this function does not support "_baseN < _baseD".
     */
    function power(
        uint256 _baseN,
        uint256 _baseD,
        uint32 _expN,
        uint32 _expD
    ) internal view returns (uint256, uint8) {
        require(_baseN < MAX_NUM);

        uint256 baseLog;
        uint256 base = (_baseN * FIXED_1) / _baseD;
        if (base < OPT_LOG_MAX_VAL) {
            baseLog = optimalLog(base);
        } else {
            baseLog = generalLog(base);
        }

        uint256 baseLogTimesExp = (baseLog * _expN) / _expD;
        if (baseLogTimesExp < OPT_EXP_MAX_VAL) {
            return (optimalExp(baseLogTimesExp), MAX_PRECISION);
        } else {
            uint8 precision = findPositionInMaxExpArray(baseLogTimesExp);
            return (
                generalExp(baseLogTimesExp >> (MAX_PRECISION - precision), precision),
                precision
            );
        }
    }

    /**
     * @dev computes log(x / FIXED_1) * FIXED_1.
     * This functions assumes that "x >= FIXED_1", because the output would be negative otherwise.
     */
    function generalLog(uint256 x) internal pure returns (uint256) {
        uint256 res = 0;

        // If x >= 2, then we compute the integer part of log2(x), which is larger than 0.
        if (x >= FIXED_2) {
            uint8 count = floorLog2(x / FIXED_1);
            x >>= count; // now x < 2
            res = count * FIXED_1;
        }

        // If x > 1, then we compute the fraction part of log2(x), which is larger than 0.
        if (x > FIXED_1) {
            for (uint8 i = MAX_PRECISION; i > 0; --i) {
                x = (x * x) / FIXED_1; // now 1 < x < 4
                if (x >= FIXED_2) {
                    x >>= 1; // now 1 < x < 2
                    res += ONE << (i - 1);
                }
            }
        }

        return (res * LN2_NUMERATOR) / LN2_DENOMINATOR;
    }

    /**
     * @dev computes the largest integer smaller than or equal to the binary logarithm of the input.
     */
    function floorLog2(uint256 _n) internal pure returns (uint8) {
        uint8 res = 0;

        if (_n < 256) {
            // At most 8 iterations
            while (_n > 1) {
                _n >>= 1;
                res += 1;
            }
        } else {
            // Exactly 8 iterations
            for (uint8 s = 128; s > 0; s >>= 1) {
                if (_n >= (ONE << s)) {
                    _n >>= s;
                    res |= s;
                }
            }
        }

        return res;
    }

    /**
     * @dev the global "maxExpArray" is sorted in descending order, and therefore the following statements are equivalent:
     * - This function finds the position of [the smallest value in "maxExpArray" larger than or equal to "x"]
     * - This function finds the highest position of [a value in "maxExpArray" larger than or equal to "x"]
     */
    function findPositionInMaxExpArray(uint256 _x) internal view returns (uint8) {
        uint8 lo = MIN_PRECISION;
        uint8 hi = MAX_PRECISION;

        while (lo + 1 < hi) {
            uint8 mid = (lo + hi) / 2;
            if (maxExpArray[mid] >= _x) lo = mid;
            else hi = mid;
        }

        if (maxExpArray[hi] >= _x) return hi;
        if (maxExpArray[lo] >= _x) return lo;

        require(false);
        return 0;
    }

    /**
     * @dev this function can be auto-generated by the script 'PrintFunctionGeneralExp.py'.
     * it approximates "e ^ x" via maclaurin summation: "(x^0)/0! + (x^1)/1! + ... + (x^n)/n!".
     * it returns "e ^ (x / 2 ^ precision) * 2 ^ precision", that is, the result is upshifted for accuracy.
     * the global "maxExpArray" maps each "precision" to "((maximumExponent + 1) << (MAX_PRECISION - precision)) - 1".
     * the maximum permitted value for "x" is therefore given by "maxExpArray[precision] >> (MAX_PRECISION - precision)".
     */
    function generalExp(uint256 _x, uint8 _precision) internal pure returns (uint256) {
        uint256 xi = _x;
        uint256 res = 0;

        xi = (xi * _x) >> _precision;
        res += xi * 0x3442c4e6074a82f1797f72ac0000000; // add x^02 * (33! / 02!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x116b96f757c380fb287fd0e40000000; // add x^03 * (33! / 03!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x045ae5bdd5f0e03eca1ff4390000000; // add x^04 * (33! / 04!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00defabf91302cd95b9ffda50000000; // add x^05 * (33! / 05!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x002529ca9832b22439efff9b8000000; // add x^06 * (33! / 06!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00054f1cf12bd04e516b6da88000000; // add x^07 * (33! / 07!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000a9e39e257a09ca2d6db51000000; // add x^08 * (33! / 08!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x000012e066e7b839fa050c309000000; // add x^09 * (33! / 09!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x000001e33d7d926c329a1ad1a800000; // add x^10 * (33! / 10!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000002bee513bdb4a6b19b5f800000; // add x^11 * (33! / 11!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00000003a9316fa79b88eccf2a00000; // add x^12 * (33! / 12!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000000048177ebe1fa812375200000; // add x^13 * (33! / 13!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000000005263fe90242dcbacf00000; // add x^14 * (33! / 14!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x000000000057e22099c030d94100000; // add x^15 * (33! / 15!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000000000057e22099c030d9410000; // add x^16 * (33! / 16!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00000000000052b6b54569976310000; // add x^17 * (33! / 17!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00000000000004985f67696bf748000; // add x^18 * (33! / 18!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x000000000000003dea12ea99e498000; // add x^19 * (33! / 19!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00000000000000031880f2214b6e000; // add x^20 * (33! / 20!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x000000000000000025bcff56eb36000; // add x^21 * (33! / 21!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x000000000000000001b722e10ab1000; // add x^22 * (33! / 22!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000000000000000001317c70077000; // add x^23 * (33! / 23!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00000000000000000000cba84aafa00; // add x^24 * (33! / 24!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00000000000000000000082573a0a00; // add x^25 * (33! / 25!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00000000000000000000005035ad900; // add x^26 * (33! / 26!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x000000000000000000000002f881b00; // add x^27 * (33! / 27!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000000000000000000000001b29340; // add x^28 * (33! / 28!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00000000000000000000000000efc40; // add x^29 * (33! / 29!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000000000000000000000000007fe0; // add x^30 * (33! / 30!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000000000000000000000000000420; // add x^31 * (33! / 31!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000000000000000000000000000021; // add x^32 * (33! / 32!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000000000000000000000000000001; // add x^33 * (33! / 33!)

        return res / 0x688589cc0e9505e2f2fee5580000000 + _x + (ONE << _precision); // divide by 33! and then add x^1 / 1! + x^0 / 0!
    }

    /**
     * @dev computes log(x / FIXED_1) * FIXED_1
     * Input range: FIXED_1 <= x <= LOG_EXP_MAX_VAL - 1
     * Auto-generated via 'PrintFunctionOptimalLog.py'
     * Detailed description:
     * - Rewrite the input as a product of natural exponents and a single residual r, such that 1 < r < 2
     * - The natural logarithm of each (pre-calculated) exponent is the degree of the exponent
     * - The natural logarithm of r is calculated via Taylor series for log(1 + x), where x = r - 1
     * - The natural logarithm of the input is calculated by summing up the intermediate results above
     * - For example: log(250) = log(e^4 * e^1 * e^0.5 * 1.021692859) = 4 + 1 + 0.5 + log(1 + 0.021692859)
     */
    function optimalLog(uint256 x) internal pure returns (uint256) {
        uint256 res = 0;

        uint256 y;
        uint256 z;
        uint256 w;

        if (x >= 0xd3094c70f034de4b96ff7d5b6f99fcd8) {
            res += 0x40000000000000000000000000000000;
            x = (x * FIXED_1) / 0xd3094c70f034de4b96ff7d5b6f99fcd8;
        } // add 1 / 2^1
        if (x >= 0xa45af1e1f40c333b3de1db4dd55f29a7) {
            res += 0x20000000000000000000000000000000;
            x = (x * FIXED_1) / 0xa45af1e1f40c333b3de1db4dd55f29a7;
        } // add 1 / 2^2
        if (x >= 0x910b022db7ae67ce76b441c27035c6a1) {
            res += 0x10000000000000000000000000000000;
            x = (x * FIXED_1) / 0x910b022db7ae67ce76b441c27035c6a1;
        } // add 1 / 2^3
        if (x >= 0x88415abbe9a76bead8d00cf112e4d4a8) {
            res += 0x08000000000000000000000000000000;
            x = (x * FIXED_1) / 0x88415abbe9a76bead8d00cf112e4d4a8;
        } // add 1 / 2^4
        if (x >= 0x84102b00893f64c705e841d5d4064bd3) {
            res += 0x04000000000000000000000000000000;
            x = (x * FIXED_1) / 0x84102b00893f64c705e841d5d4064bd3;
        } // add 1 / 2^5
        if (x >= 0x8204055aaef1c8bd5c3259f4822735a2) {
            res += 0x02000000000000000000000000000000;
            x = (x * FIXED_1) / 0x8204055aaef1c8bd5c3259f4822735a2;
        } // add 1 / 2^6
        if (x >= 0x810100ab00222d861931c15e39b44e99) {
            res += 0x01000000000000000000000000000000;
            x = (x * FIXED_1) / 0x810100ab00222d861931c15e39b44e99;
        } // add 1 / 2^7
        if (x >= 0x808040155aabbbe9451521693554f733) {
            res += 0x00800000000000000000000000000000;
            x = (x * FIXED_1) / 0x808040155aabbbe9451521693554f733;
        } // add 1 / 2^8

        z = y = x - FIXED_1;
        w = (y * y) / FIXED_1;
        res +=
            (z * (0x100000000000000000000000000000000 - y)) /
            0x100000000000000000000000000000000;
        z = (z * w) / FIXED_1; // add y^01 / 01 - y^02 / 02
        res +=
            (z * (0x0aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa - y)) /
            0x200000000000000000000000000000000;
        z = (z * w) / FIXED_1; // add y^03 / 03 - y^04 / 04
        res +=
            (z * (0x099999999999999999999999999999999 - y)) /
            0x300000000000000000000000000000000;
        z = (z * w) / FIXED_1; // add y^05 / 05 - y^06 / 06
        res +=
            (z * (0x092492492492492492492492492492492 - y)) /
            0x400000000000000000000000000000000;
        z = (z * w) / FIXED_1; // add y^07 / 07 - y^08 / 08
        res +=
            (z * (0x08e38e38e38e38e38e38e38e38e38e38e - y)) /
            0x500000000000000000000000000000000;
        z = (z * w) / FIXED_1; // add y^09 / 09 - y^10 / 10
        res +=
            (z * (0x08ba2e8ba2e8ba2e8ba2e8ba2e8ba2e8b - y)) /
            0x600000000000000000000000000000000;
        z = (z * w) / FIXED_1; // add y^11 / 11 - y^12 / 12
        res +=
            (z * (0x089d89d89d89d89d89d89d89d89d89d89 - y)) /
            0x700000000000000000000000000000000;
        z = (z * w) / FIXED_1; // add y^13 / 13 - y^14 / 14
        res +=
            (z * (0x088888888888888888888888888888888 - y)) /
            0x800000000000000000000000000000000; // add y^15 / 15 - y^16 / 16

        return res;
    }

    /**
     * @dev computes e ^ (x / FIXED_1) * FIXED_1
     * input range: 0 <= x <= OPT_EXP_MAX_VAL - 1
     * auto-generated via 'PrintFunctionOptimalExp.py'
     * Detailed description:
     * - Rewrite the input as a sum of binary exponents and a single residual r, as small as possible
     * - The exponentiation of each binary exponent is given (pre-calculated)
     * - The exponentiation of r is calculated via Taylor series for e^x, where x = r
     * - The exponentiation of the input is calculated by multiplying the intermediate results above
     * - For example: e^5.521692859 = e^(4 + 1 + 0.5 + 0.021692859) = e^4 * e^1 * e^0.5 * e^0.021692859
     */
    function optimalExp(uint256 x) internal pure returns (uint256) {
        uint256 res = 0;

        uint256 y;
        uint256 z;

        z = y = x % 0x10000000000000000000000000000000; // get the input modulo 2^(-3)
        z = (z * y) / FIXED_1;
        res += z * 0x10e1b3be415a0000; // add y^02 * (20! / 02!)
        z = (z * y) / FIXED_1;
        res += z * 0x05a0913f6b1e0000; // add y^03 * (20! / 03!)
        z = (z * y) / FIXED_1;
        res += z * 0x0168244fdac78000; // add y^04 * (20! / 04!)
        z = (z * y) / FIXED_1;
        res += z * 0x004807432bc18000; // add y^05 * (20! / 05!)
        z = (z * y) / FIXED_1;
        res += z * 0x000c0135dca04000; // add y^06 * (20! / 06!)
        z = (z * y) / FIXED_1;
        res += z * 0x0001b707b1cdc000; // add y^07 * (20! / 07!)
        z = (z * y) / FIXED_1;
        res += z * 0x000036e0f639b800; // add y^08 * (20! / 08!)
        z = (z * y) / FIXED_1;
        res += z * 0x00000618fee9f800; // add y^09 * (20! / 09!)
        z = (z * y) / FIXED_1;
        res += z * 0x0000009c197dcc00; // add y^10 * (20! / 10!)
        z = (z * y) / FIXED_1;
        res += z * 0x0000000e30dce400; // add y^11 * (20! / 11!)
        z = (z * y) / FIXED_1;
        res += z * 0x000000012ebd1300; // add y^12 * (20! / 12!)
        z = (z * y) / FIXED_1;
        res += z * 0x0000000017499f00; // add y^13 * (20! / 13!)
        z = (z * y) / FIXED_1;
        res += z * 0x0000000001a9d480; // add y^14 * (20! / 14!)
        z = (z * y) / FIXED_1;
        res += z * 0x00000000001c6380; // add y^15 * (20! / 15!)
        z = (z * y) / FIXED_1;
        res += z * 0x000000000001c638; // add y^16 * (20! / 16!)
        z = (z * y) / FIXED_1;
        res += z * 0x0000000000001ab8; // add y^17 * (20! / 17!)
        z = (z * y) / FIXED_1;
        res += z * 0x000000000000017c; // add y^18 * (20! / 18!)
        z = (z * y) / FIXED_1;
        res += z * 0x0000000000000014; // add y^19 * (20! / 19!)
        z = (z * y) / FIXED_1;
        res += z * 0x0000000000000001; // add y^20 * (20! / 20!)
        res = res / 0x21c3677c82b40000 + y + FIXED_1; // divide by 20! and then add y^1 / 1! + y^0 / 0!

        if ((x & 0x010000000000000000000000000000000) != 0)
            res = (res * 0x1c3d6a24ed82218787d624d3e5eba95f9) / 0x18ebef9eac820ae8682b9793ac6d1e776; // multiply by e^2^(-3)
        if ((x & 0x020000000000000000000000000000000) != 0)
            res = (res * 0x18ebef9eac820ae8682b9793ac6d1e778) / 0x1368b2fc6f9609fe7aceb46aa619baed4; // multiply by e^2^(-2)
        if ((x & 0x040000000000000000000000000000000) != 0)
            res = (res * 0x1368b2fc6f9609fe7aceb46aa619baed5) / 0x0bc5ab1b16779be3575bd8f0520a9f21f; // multiply by e^2^(-1)
        if ((x & 0x080000000000000000000000000000000) != 0)
            res = (res * 0x0bc5ab1b16779be3575bd8f0520a9f21e) / 0x0454aaa8efe072e7f6ddbab84b40a55c9; // multiply by e^2^(+0)
        if ((x & 0x100000000000000000000000000000000) != 0)
            res = (res * 0x0454aaa8efe072e7f6ddbab84b40a55c5) / 0x00960aadc109e7a3bf4578099615711ea; // multiply by e^2^(+1)
        if ((x & 0x200000000000000000000000000000000) != 0)
            res = (res * 0x00960aadc109e7a3bf4578099615711d7) / 0x0002bf84208204f5977f9a8cf01fdce3d; // multiply by e^2^(+2)
        if ((x & 0x400000000000000000000000000000000) != 0)
            res = (res * 0x0002bf84208204f5977f9a8cf01fdc307) / 0x0000003c6ab775dd0b95b4cbee7e65d11; // multiply by e^2^(+3)

        return res;
    }

    /**
     * @dev deprecated, backward compatibility
     */
    function calculateCrossConnectorReturn(
        uint256 _fromConnectorBalance,
        uint32 _fromConnectorWeight,
        uint256 _toConnectorBalance,
        uint32 _toConnectorWeight,
        uint256 _amount
    ) public view returns (uint256) {
        return
            calculateCrossReserveReturn(
                _fromConnectorBalance,
                _fromConnectorWeight,
                _toConnectorBalance,
                _toConnectorWeight,
                _amount
            );
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.7.6;

import "./IGraphProxy.sol";

/**
 * @title Graph Upgradeable
 * @dev This contract is intended to be inherited from upgradeable contracts.
 */
contract GraphUpgradeable {
    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Check if the caller is the proxy admin.
     */
    modifier onlyProxyAdmin(IGraphProxy _proxy) {
        require(msg.sender == _proxy.admin(), "Caller must be the proxy admin");
        _;
    }

    /**
     * @dev Check if the caller is the implementation.
     */
    modifier onlyImpl() {
        require(msg.sender == _implementation(), "Caller must be the implementation");
        _;
    }

    /**
     * @dev Returns the current implementation.
     * @return impl Address of the current implementation
     */
    function _implementation() internal view returns (address impl) {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            impl := sload(slot)
        }
    }

    /**
     * @dev Accept to be an implementation of proxy.
     */
    function acceptProxy(IGraphProxy _proxy) external onlyProxyAdmin(_proxy) {
        _proxy.acceptUpgrade();
    }

    /**
     * @dev Accept to be an implementation of proxy and then call a function from the new
     * implementation as specified by `_data`, which should be an encoded function call. This is
     * useful to initialize new storage variables in the proxied contract.
     */
    function acceptProxyAndCall(IGraphProxy _proxy, bytes calldata _data)
        external
        onlyProxyAdmin(_proxy)
    {
        _proxy.acceptUpgradeAndCall(_data);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.7.6;

import "../token/IGraphToken.sol";

library TokenUtils {
    /**
     * @dev Pull tokens from an address to this contract.
     * @param _graphToken Token to transfer
     * @param _from Address sending the tokens
     * @param _amount Amount of tokens to transfer
     */
    function pullTokens(
        IGraphToken _graphToken,
        address _from,
        uint256 _amount
    ) internal {
        if (_amount > 0) {
            require(_graphToken.transferFrom(_from, address(this), _amount), "!transfer");
        }
    }

    /**
     * @dev Push tokens from this contract to a receiving address.
     * @param _graphToken Token to transfer
     * @param _to Address receiving the tokens
     * @param _amount Amount of tokens to transfer
     */
    function pushTokens(
        IGraphToken _graphToken,
        address _to,
        uint256 _amount
    ) internal {
        if (_amount > 0) {
            require(_graphToken.transfer(_to, _amount), "!transfer");
        }
    }

    /**
     * @dev Burn tokens held by this contract.
     * @param _graphToken Token to burn
     * @param _amount Amount of tokens to burn
     */
    function burnTokens(IGraphToken _graphToken, uint256 _amount) internal {
        if (_amount > 0) {
            _graphToken.burn(_amount);
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.7.6;

interface IGNS {
    // -- Pool --

    struct SubgraphData {
        uint256 vSignal; // The token of the subgraph-deployment bonding curve
        uint256 nSignal; // The token of the subgraph bonding curve
        mapping(address => uint256) curatorNSignal;
        bytes32 subgraphDeploymentID;
        uint32 reserveRatio;
        bool disabled;
        uint256 withdrawableGRT;
    }

    struct LegacySubgraphKey {
        address account;
        uint256 accountSeqID;
    }

    // -- Configuration --

    function approveAll() external;

    function setOwnerTaxPercentage(uint32 _ownerTaxPercentage) external;

    // -- Publishing --

    function setDefaultName(
        address _graphAccount,
        uint8 _nameSystem,
        bytes32 _nameIdentifier,
        string calldata _name
    ) external;

    function updateSubgraphMetadata(uint256 _subgraphID, bytes32 _subgraphMetadata) external;

    function publishNewSubgraph(
        bytes32 _subgraphDeploymentID,
        bytes32 _versionMetadata,
        bytes32 _subgraphMetadata
    ) external;

    function publishNewVersion(
        uint256 _subgraphID,
        bytes32 _subgraphDeploymentID,
        bytes32 _versionMetadata
    ) external;

    function deprecateSubgraph(uint256 _subgraphID) external;

    // -- Curation --

    function mintSignal(
        uint256 _subgraphID,
        uint256 _tokensIn,
        uint256 _nSignalOutMin
    ) external;

    function burnSignal(
        uint256 _subgraphID,
        uint256 _nSignal,
        uint256 _tokensOutMin
    ) external;

    function withdraw(uint256 _subgraphID) external;

    // -- Getters --

    function ownerOf(uint256 _tokenID) external view returns (address);

    function subgraphSignal(uint256 _subgraphID) external view returns (uint256);

    function subgraphTokens(uint256 _subgraphID) external view returns (uint256);

    function tokensToNSignal(uint256 _subgraphID, uint256 _tokensIn)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function nSignalToTokens(uint256 _subgraphID, uint256 _nSignalIn)
        external
        view
        returns (uint256, uint256);

    function vSignalToNSignal(uint256 _subgraphID, uint256 _vSignalIn)
        external
        view
        returns (uint256);

    function nSignalToVSignal(uint256 _subgraphID, uint256 _nSignalIn)
        external
        view
        returns (uint256);

    function getCuratorSignal(uint256 _subgraphID, address _curator)
        external
        view
        returns (uint256);

    function isPublished(uint256 _subgraphID) external view returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.7.6;
pragma abicoder v2;

import "../governance/Managed.sol";

import "./erc1056/IEthereumDIDRegistry.sol";
import "./IGNS.sol";
import "./ISubgraphNFT.sol";

abstract contract GNSV1Storage is Managed {
    // -- State --

    // In parts per hundred
    uint32 public ownerTaxPercentage;

    // Bonding curve formula
    address public bondingCurve;

    // Stores what subgraph deployment a particular legacy subgraph targets
    // A subgraph is defined by (graphAccountID, subgraphNumber)
    // A subgraph can target one subgraph deployment (bytes32 hash)
    // (graphAccountID, subgraphNumber) => subgraphDeploymentID
    mapping(address => mapping(uint256 => bytes32)) internal legacySubgraphs;

    // Every time an account creates a subgraph it increases a per-account sequence ID
    // account => seqID
    mapping(address => uint256) public nextAccountSeqID;

    // Stores all the signal deposited on a legacy subgraph
    // (graphAccountID, subgraphNumber) => SubgraphData
    mapping(address => mapping(uint256 => IGNS.SubgraphData)) public legacySubgraphData;

    // [DEPRECATED] ERC-1056 contract reference
    // This contract is used for managing identities
    IEthereumDIDRegistry private __DEPRECATED_erc1056Registry;
}

abstract contract GNSV2Storage is GNSV1Storage {
    // Use it whenever a legacy (v1) subgraph NFT was claimed to maintain compatibility
    // Keep a reference from subgraphID => (graphAccount, subgraphNumber)
    mapping(uint256 => IGNS.LegacySubgraphKey) public legacySubgraphKeys;

    // Store data for all NFT-based (v2) subgraphs
    // subgraphID => SubgraphData
    mapping(uint256 => IGNS.SubgraphData) public subgraphs;

    // Contract that represents subgraph ownership through an NFT
    ISubgraphNFT public subgraphNFT;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.7.6;
pragma abicoder v2;

/**
 * @title Multicall interface
 * @notice Enables calling multiple methods in a single call to the contract
 */
interface IMulticall {
    /**
     * @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
     * @param data The encoded function data for each of the calls to make to this contract
     * @return results The results from each of the calls passed in via data
     */
    function multicall(bytes[] calldata data) external returns (bytes[] memory results);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.7.6;

interface IGraphProxy {
    function admin() external returns (address);

    function setAdmin(address _newAdmin) external;

    function implementation() external returns (address);

    function pendingImplementation() external returns (address);

    function upgradeTo(address _newImplementation) external;

    function acceptUpgrade() external;

    function acceptUpgradeAndCall(bytes calldata data) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IGraphToken is IERC20 {
    // -- Mint and Burn --

    function burn(uint256 amount) external;

    function mint(address _to, uint256 _amount) external;

    // -- Mint Admin --

    function addMinter(address _account) external;

    function removeMinter(address _account) external;

    function renounceMinter() external;

    function isMinter(address _account) external view returns (bool);

    // -- Permit --

    function permit(
        address _owner,
        address _spender,
        uint256 _value,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.7.6;

import "./IController.sol";

import "../curation/ICuration.sol";
import "../epochs/IEpochManager.sol";
import "../rewards/IRewardsManager.sol";
import "../staking/IStaking.sol";
import "../token/IGraphToken.sol";

/**
 * @title Graph Managed contract
 * @dev The Managed contract provides an interface to interact with the Controller.
 * It also provides local caching for contract addresses. This mechanism relies on calling the
 * public `syncAllContracts()` function whenever a contract changes in the controller.
 *
 * Inspired by Livepeer:
 * https://github.com/livepeer/protocol/blob/streamflow/contracts/Controller.sol
 */
contract Managed {
    // -- State --

    // Controller that contract is registered with
    IController public controller;
    mapping(bytes32 => address) private addressCache;
    uint256[10] private __gap;

    // -- Events --

    event ParameterUpdated(string param);
    event SetController(address controller);

    /**
     * @dev Emitted when contract with `nameHash` is synced to `contractAddress`.
     */
    event ContractSynced(bytes32 indexed nameHash, address contractAddress);

    // -- Modifiers --

    function _notPartialPaused() internal view {
        require(!controller.paused(), "Paused");
        require(!controller.partialPaused(), "Partial-paused");
    }

    function _notPaused() internal view {
        require(!controller.paused(), "Paused");
    }

    function _onlyGovernor() internal view {
        require(msg.sender == controller.getGovernor(), "Caller must be Controller governor");
    }

    function _onlyController() internal view {
        require(msg.sender == address(controller), "Caller must be Controller");
    }

    modifier notPartialPaused() {
        _notPartialPaused();
        _;
    }

    modifier notPaused() {
        _notPaused();
        _;
    }

    // Check if sender is controller.
    modifier onlyController() {
        _onlyController();
        _;
    }

    // Check if sender is the governor.
    modifier onlyGovernor() {
        _onlyGovernor();
        _;
    }

    // -- Functions --

    /**
     * @dev Initialize the controller.
     */
    function _initialize(address _controller) internal {
        _setController(_controller);
    }

    /**
     * @notice Set Controller. Only callable by current controller.
     * @param _controller Controller contract address
     */
    function setController(address _controller) external onlyController {
        _setController(_controller);
    }

    /**
     * @dev Set controller.
     * @param _controller Controller contract address
     */
    function _setController(address _controller) internal {
        require(_controller != address(0), "Controller must be set");
        controller = IController(_controller);
        emit SetController(_controller);
    }

    /**
     * @dev Return Curation interface.
     * @return Curation contract registered with Controller
     */
    function curation() internal view returns (ICuration) {
        return ICuration(_resolveContract(keccak256("Curation")));
    }

    /**
     * @dev Return EpochManager interface.
     * @return Epoch manager contract registered with Controller
     */
    function epochManager() internal view returns (IEpochManager) {
        return IEpochManager(_resolveContract(keccak256("EpochManager")));
    }

    /**
     * @dev Return RewardsManager interface.
     * @return Rewards manager contract registered with Controller
     */
    function rewardsManager() internal view returns (IRewardsManager) {
        return IRewardsManager(_resolveContract(keccak256("RewardsManager")));
    }

    /**
     * @dev Return Staking interface.
     * @return Staking contract registered with Controller
     */
    function staking() internal view returns (IStaking) {
        return IStaking(_resolveContract(keccak256("Staking")));
    }

    /**
     * @dev Return GraphToken interface.
     * @return Graph token contract registered with Controller
     */
    function graphToken() internal view returns (IGraphToken) {
        return IGraphToken(_resolveContract(keccak256("GraphToken")));
    }

    /**
     * @dev Resolve a contract address from the cache or the Controller if not found.
     * @return Address of the contract
     */
    function _resolveContract(bytes32 _nameHash) internal view returns (address) {
        address contractAddress = addressCache[_nameHash];
        if (contractAddress == address(0)) {
            contractAddress = controller.getContractProxy(_nameHash);
        }
        return contractAddress;
    }

    /**
     * @dev Cache a contract address from the Controller registry.
     * @param _name Name of the contract to sync into the cache
     */
    function _syncContract(string memory _name) internal {
        bytes32 nameHash = keccak256(abi.encodePacked(_name));
        address contractAddress = controller.getContractProxy(nameHash);
        if (addressCache[nameHash] != contractAddress) {
            addressCache[nameHash] = contractAddress;
            emit ContractSynced(nameHash, contractAddress);
        }
    }

    /**
     * @dev Sync protocol contract addresses from the Controller registry.
     * This function will cache all the contracts using the latest addresses
     * Anyone can call the function whenever a Proxy contract change in the
     * controller to ensure the protocol is using the latest version
     */
    function syncAllContracts() external {
        _syncContract("Curation");
        _syncContract("EpochManager");
        _syncContract("RewardsManager");
        _syncContract("Staking");
        _syncContract("GraphToken");
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.7.6;

interface IEthereumDIDRegistry {
    function identityOwner(address identity) external view returns (address);

    function setAttribute(
        address identity,
        bytes32 name,
        bytes calldata value,
        uint256 validity
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ISubgraphNFT is IERC721 {
    // -- Config --

    function setMinter(address _minter) external;

    function setTokenDescriptor(address _tokenDescriptor) external;

    function setBaseURI(string memory _baseURI) external;

    // -- Actions --

    function mint(address _to, uint256 _tokenId) external;

    function burn(uint256 _tokenId) external;

    function setSubgraphMetadata(uint256 _tokenId, bytes32 _subgraphMetadata) external;

    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.6.12 <0.8.0;

interface IController {
    function getGovernor() external view returns (address);

    // -- Registry --

    function setContractProxy(bytes32 _id, address _contractAddress) external;

    function unsetContractProxy(bytes32 _id) external;

    function updateController(bytes32 _id, address _controller) external;

    function getContractProxy(bytes32 _id) external view returns (address);

    // -- Pausing --

    function setPartialPaused(bool _partialPaused) external;

    function setPaused(bool _paused) external;

    function setPauseGuardian(address _newPauseGuardian) external;

    function paused() external view returns (bool);

    function partialPaused() external view returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.7.6;

import "./IGraphCurationToken.sol";

interface ICuration {
    // -- Configuration --

    function setDefaultReserveRatio(uint32 _defaultReserveRatio) external;

    function setMinimumCurationDeposit(uint256 _minimumCurationDeposit) external;

    function setCurationTaxPercentage(uint32 _percentage) external;

    function setCurationTokenMaster(address _curationTokenMaster) external;

    // -- Curation --

    function mint(
        bytes32 _subgraphDeploymentID,
        uint256 _tokensIn,
        uint256 _signalOutMin
    ) external returns (uint256, uint256);

    function burn(
        bytes32 _subgraphDeploymentID,
        uint256 _signalIn,
        uint256 _tokensOutMin
    ) external returns (uint256);

    function collect(bytes32 _subgraphDeploymentID, uint256 _tokens) external;

    // -- Getters --

    function isCurated(bytes32 _subgraphDeploymentID) external view returns (bool);

    function getCuratorSignal(address _curator, bytes32 _subgraphDeploymentID)
        external
        view
        returns (uint256);

    function getCurationPoolSignal(bytes32 _subgraphDeploymentID) external view returns (uint256);

    function getCurationPoolTokens(bytes32 _subgraphDeploymentID) external view returns (uint256);

    function tokensToSignal(bytes32 _subgraphDeploymentID, uint256 _tokensIn)
        external
        view
        returns (uint256, uint256);

    function signalToTokens(bytes32 _subgraphDeploymentID, uint256 _signalIn)
        external
        view
        returns (uint256);

    function curationTaxPercentage() external view returns (uint32);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.7.6;

interface IEpochManager {
    // -- Configuration --

    function setEpochLength(uint256 _epochLength) external;

    // -- Epochs

    function runEpoch() external;

    // -- Getters --

    function isCurrentEpochRun() external view returns (bool);

    function blockNum() external view returns (uint256);

    function blockHash(uint256 _block) external view returns (bytes32);

    function currentEpoch() external view returns (uint256);

    function currentEpochBlock() external view returns (uint256);

    function currentEpochBlockSinceStart() external view returns (uint256);

    function epochsSince(uint256 _epoch) external view returns (uint256);

    function epochsSinceUpdate() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.7.6;

interface IRewardsManager {
    /**
     * @dev Stores accumulated rewards and snapshots related to a particular SubgraphDeployment.
     */
    struct Subgraph {
        uint256 accRewardsForSubgraph;
        uint256 accRewardsForSubgraphSnapshot;
        uint256 accRewardsPerSignalSnapshot;
        uint256 accRewardsPerAllocatedToken;
    }

    // -- Params --

    function setIssuanceRate(uint256 _issuanceRate) external;

    // -- Denylist --

    function setSubgraphAvailabilityOracle(address _subgraphAvailabilityOracle) external;

    function setDenied(bytes32 _subgraphDeploymentID, bool _deny) external;

    function setDeniedMany(bytes32[] calldata _subgraphDeploymentID, bool[] calldata _deny)
        external;

    function isDenied(bytes32 _subgraphDeploymentID) external view returns (bool);

    // -- Getters --

    function getNewRewardsPerSignal() external view returns (uint256);

    function getAccRewardsPerSignal() external view returns (uint256);

    function getAccRewardsForSubgraph(bytes32 _subgraphDeploymentID)
        external
        view
        returns (uint256);

    function getAccRewardsPerAllocatedToken(bytes32 _subgraphDeploymentID)
        external
        view
        returns (uint256, uint256);

    function getRewards(address _allocationID) external view returns (uint256);

    // -- Updates --

    function updateAccRewardsPerSignal() external returns (uint256);

    function takeRewards(address _allocationID) external returns (uint256);

    // -- Hooks --

    function onSubgraphSignalUpdate(bytes32 _subgraphDeploymentID) external returns (uint256);

    function onSubgraphAllocationUpdate(bytes32 _subgraphDeploymentID) external returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.6.12 <0.8.0;
pragma abicoder v2;

import "./IStakingData.sol";

interface IStaking is IStakingData {
    // -- Allocation Data --

    /**
     * @dev Possible states an allocation can be
     * States:
     * - Null = indexer == address(0)
     * - Active = not Null && tokens > 0
     * - Closed = Active && closedAtEpoch != 0
     * - Finalized = Closed && closedAtEpoch + channelDisputeEpochs > now()
     * - Claimed = not Null && tokens == 0
     */
    enum AllocationState {
        Null,
        Active,
        Closed,
        Finalized,
        Claimed
    }

    // -- Configuration --

    function setMinimumIndexerStake(uint256 _minimumIndexerStake) external;

    function setThawingPeriod(uint32 _thawingPeriod) external;

    function setCurationPercentage(uint32 _percentage) external;

    function setProtocolPercentage(uint32 _percentage) external;

    function setChannelDisputeEpochs(uint32 _channelDisputeEpochs) external;

    function setMaxAllocationEpochs(uint32 _maxAllocationEpochs) external;

    function setRebateRatio(uint32 _alphaNumerator, uint32 _alphaDenominator) external;

    function setDelegationRatio(uint32 _delegationRatio) external;

    function setDelegationParameters(
        uint32 _indexingRewardCut,
        uint32 _queryFeeCut,
        uint32 _cooldownBlocks
    ) external;

    function setDelegationParametersCooldown(uint32 _blocks) external;

    function setDelegationUnbondingPeriod(uint32 _delegationUnbondingPeriod) external;

    function setDelegationTaxPercentage(uint32 _percentage) external;

    function setSlasher(address _slasher, bool _allowed) external;

    function setAssetHolder(address _assetHolder, bool _allowed) external;

    // -- Operation --

    function setOperator(address _operator, bool _allowed) external;

    function isOperator(address _operator, address _indexer) external view returns (bool);

    // -- Staking --

    function stake(uint256 _tokens) external;

    function stakeTo(address _indexer, uint256 _tokens) external;

    function unstake(uint256 _tokens) external;

    function slash(
        address _indexer,
        uint256 _tokens,
        uint256 _reward,
        address _beneficiary
    ) external;

    function withdraw() external;

    function setRewardsDestination(address _destination) external;

    // -- Delegation --

    function delegate(address _indexer, uint256 _tokens) external returns (uint256);

    function undelegate(address _indexer, uint256 _shares) external returns (uint256);

    function withdrawDelegated(address _indexer, address _newIndexer) external returns (uint256);

    // -- Channel management and allocations --

    function allocate(
        bytes32 _subgraphDeploymentID,
        uint256 _tokens,
        address _allocationID,
        bytes32 _metadata,
        bytes calldata _proof
    ) external;

    function allocateFrom(
        address _indexer,
        bytes32 _subgraphDeploymentID,
        uint256 _tokens,
        address _allocationID,
        bytes32 _metadata,
        bytes calldata _proof
    ) external;

    function closeAllocation(address _allocationID, bytes32 _poi) external;

    function closeAllocationMany(CloseAllocationRequest[] calldata _requests) external;

    function closeAndAllocate(
        address _oldAllocationID,
        bytes32 _poi,
        address _indexer,
        bytes32 _subgraphDeploymentID,
        uint256 _tokens,
        address _allocationID,
        bytes32 _metadata,
        bytes calldata _proof
    ) external;

    function collect(uint256 _tokens, address _allocationID) external;

    function claim(address _allocationID, bool _restake) external;

    function claimMany(address[] calldata _allocationID, bool _restake) external;

    // -- Getters and calculations --

    function hasStake(address _indexer) external view returns (bool);

    function getIndexerStakedTokens(address _indexer) external view returns (uint256);

    function getIndexerCapacity(address _indexer) external view returns (uint256);

    function getAllocation(address _allocationID) external view returns (Allocation memory);

    function getAllocationState(address _allocationID) external view returns (AllocationState);

    function isAllocation(address _allocationID) external view returns (bool);

    function getSubgraphAllocatedTokens(bytes32 _subgraphDeploymentID)
        external
        view
        returns (uint256);

    function getDelegation(address _indexer, address _delegator)
        external
        view
        returns (Delegation memory);

    function isDelegator(address _indexer, address _delegator) external view returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.7.6;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IGraphCurationToken is IERC20Upgradeable {
    function initialize(address _owner) external;

    function burnFrom(address _account, uint256 _amount) external;

    function mint(address _to, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.6.12 <0.8.0;

interface IStakingData {
    /**
     * @dev Allocate GRT tokens for the purpose of serving queries of a subgraph deployment
     * An allocation is created in the allocate() function and consumed in claim()
     */
    struct Allocation {
        address indexer;
        bytes32 subgraphDeploymentID;
        uint256 tokens; // Tokens allocated to a SubgraphDeployment
        uint256 createdAtEpoch; // Epoch when it was created
        uint256 closedAtEpoch; // Epoch when it was closed
        uint256 collectedFees; // Collected fees for the allocation
        uint256 effectiveAllocation; // Effective allocation when closed
        uint256 accRewardsPerAllocatedToken; // Snapshot used for reward calc
    }

    /**
     * @dev Represents a request to close an allocation with a specific proof of indexing.
     * This is passed when calling closeAllocationMany to define the closing parameters for
     * each allocation.
     */
    struct CloseAllocationRequest {
        address allocationID;
        bytes32 poi;
    }

    // -- Delegation Data --

    /**
     * @dev Delegation pool information. One per indexer.
     */
    struct DelegationPool {
        uint32 cooldownBlocks; // Blocks to wait before updating parameters
        uint32 indexingRewardCut; // in PPM
        uint32 queryFeeCut; // in PPM
        uint256 updatedAtBlock; // Block when the pool was last updated
        uint256 tokens; // Total tokens as pool reserves
        uint256 shares; // Total shares minted in the pool
        mapping(address => Delegation) delegators; // Mapping of delegator => Delegation
    }

    /**
     * @dev Individual delegation data of a delegator in a pool.
     */
    struct Delegation {
        uint256 shares; // Shares owned by a delegator in the pool
        uint256 tokensLocked; // Tokens locked for undelegation
        uint256 tokensLockedUntil; // Block when locked tokens can be withdrawn
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
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