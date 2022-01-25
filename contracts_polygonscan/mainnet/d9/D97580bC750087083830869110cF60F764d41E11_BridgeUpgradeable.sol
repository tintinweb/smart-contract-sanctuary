// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./interfaces/IVoterUpgradeable.sol";
import "./interfaces/IERC20Upgradeable.sol";

import "./interfaces/IDepositExecute.sol";
import "./interfaces/ILiquidityPool.sol";
import "./interfaces/IERCHandler.sol";
import "./interfaces/IERCHandlerDecimals.sol";
import "./interfaces/IGenericHandler.sol";
import "./interfaces/IWETH.sol";

/**
    @title Facilitates deposits, creation and voting of deposit proposals, and deposit executions.
    @author Router Protocol
 */
contract BridgeUpgradeable is
    Initializable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable
{
    function fetch_chainID() public view virtual returns (uint8) {
        return _chainID;
    }

    function fetch_expiry() public view virtual returns (uint256) {
        return _expiry;
    }

    function fetch_whitelistEnabled() public view virtual returns (bool) {
        return _whitelistEnabled;
    }

    function fetch_depositCounts(uint8 _id) public view virtual returns (uint64) {
        return _depositCounts[_id];
    }

    function fetch_resourceIDToHandlerAddress(bytes32 _id) public view virtual returns (address) {
        return _resourceIDToHandlerAddress[_id];
    }

    function fetch_proposals(bytes32 _id) public view virtual returns (uint256) {
        return _proposals[_id];
    }

    function fetch_whitelist(address _beneficiary) public view virtual returns (bool) {
        return _whitelist[_beneficiary];
    }

    function GetProposalHash(
        uint8 chainID,
        uint64 depositNonce,
        bytes32 dataHash
    ) public pure virtual returns (bytes32) {
        bytes32 proposalHash = keccak256(abi.encodePacked(chainID, depositNonce, dataHash));
        return proposalHash;
    }

    function HasVotedOnProposal(
        uint8 chainID,
        uint64 depositNonce,
        bytes32 dataHash
    ) public view virtual returns (bool) {
        bytes32 proposalHash = keccak256(abi.encodePacked(chainID, depositNonce, dataHash));
        uint256 id = _proposals[proposalHash];
        return _voter.Voted(id, msg.sender);
    }

    // View Functions

    // Data Structure Starts
    uint8 private _chainID;
    uint256 private _expiry;
    bool private _whitelistEnabled;
    bytes32 public constant FEE_SETTER_ROLE = keccak256("FEE_SETTER_ROLE");
    bytes32 public constant RELAYER_ROLE = keccak256("RELAYER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant RESOURCE_SETTER = keccak256("RESOURCE_SETTER");
    bytes32 public constant EMERGENCY_ROLE = keccak256("EMERGENCY_ROLE");
    uint256 public totalRelayers;

    uint64 public _quorum;

    IVoterUpgradeable public _voter;

    // enum ProposalStatus { Inactive, Active, Passed, Executed, Cancelled }

    mapping(uint8 => uint64) private _depositCounts;

    mapping(bytes32 => address) private _resourceIDToHandlerAddress;

    mapping(bytes32 => uint256) private _proposals;

    mapping(address => bool) private _whitelist;

    mapping(uint256 => proposalStruct) private _proposalDetails;

    struct proposalStruct {
        uint8 chainID;
        uint64 depositNonce;
        bytes32 dataHash;
        bytes32 resourceID;
    }

    // Data Structure Ends

    event quorumChanged(uint64 quorum);
    event expiryChanged(uint256 expiry);
    event ProposalEvent(
        uint8 originChainID,
        uint64 depositNonce,
        IVoterUpgradeable.ProposalStatus status,
        bytes32 dataHash
    );
    event ProposalVote(
        uint8 originChainID,
        uint64 depositNonce,
        IVoterUpgradeable.ProposalStatus status,
        bytes32 dataHash
    );
    event Deposit(uint8 indexed destinationChainID, bytes32 indexed resourceID, uint64 indexed depositNonce);
    event Stake(address indexed staker, uint256 amount, address pool);
    event Unstake(address indexed unstaker, uint256 amount, address pool);
    event FeeSetterAdded(address feeSetter);
    event FeeSetterRemoved(address feeSetter);
    event AddedWhitelist(address whitelistAddress);
    event RemovedWhitelist(address whitelistAddress);
    event WhitelistingSetting(bool status);
    event AdminWithdraw(address handler, address tokenAddress, address recipient, uint256 amountOrTokenID);
    event Settlement(
        uint8 indexed originChainID,
        uint64 indexed depositNonce,
        address settlementToken,
        uint256 settlementAmount,
        IVoterUpgradeable.ProposalStatus status
    );
    /**
        @notice RelayerAdded Event
        @notice Creates a event when Relayer Role is granted.
        @param relayer Address of relayer.
    */
    event RelayerAdded(address relayer);

    /**
        @notice RelayerRemoved Event
        @notice Creates a event when Relayer Role is revoked.
        @param relayer Address of relayer.
    */
    event RelayerRemoved(address relayer);

    // Modifier Section Starts

    modifier onlyAdminOrRelayer() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender) || hasRole(RELAYER_ROLE, msg.sender),
            "sender is not relayer or admin"
        );
        _;
    }

    modifier isWhitelisted() {
        if (_whitelistEnabled) {
            require(_whitelist[msg.sender], "address is not whitelisted");
        }
        _;
    }

    modifier isWhitelistEnabled() {
        require(_whitelistEnabled, "BridgeUpgradeable: White listing is not enabled");
        _;
    }

    modifier isResourceID(bytes32 _id) {
        require(_resourceIDToHandlerAddress[_id] != address(0), "BridgeUpgradeable: No handler for resourceID");
        _;
    }

    modifier isProposalExists(
        uint8 chainID,
        uint64 depositNonce,
        bytes32 dataHash
    ) {
        bytes32 proposalHash = keccak256(abi.encodePacked(chainID, depositNonce, dataHash));
        require(_proposals[proposalHash] != 0, "BridgeUpgradeable: Proposal Already Exists");
        _;
    }

    // Modifier Section ends

    receive() external payable {}

    // Upgrade Section Starts
    /**
        @notice Initializes Bridge, creates and grants {msg.sender} the admin role,
        creates and grants {initialRelayers} the relayer role.
        @param chainID ID of chain the Bridge contract exists on.
        @param quorum Number of votes needed for a deposit proposal to be considered passed.
     */
    function initialize(
        uint8 chainID,
        uint256 quorum,
        uint256 expiry,
        address voter
    ) external initializer {
        __AccessControl_init();
        __Pausable_init();

        // Constructor Fx
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _voter = IVoterUpgradeable(voter);

        _chainID = chainID;
        _quorum = uint64(quorum);
        _expiry = expiry;

        // Constructor Fx
    }

    function _authorizeUpgrade(address newImplementation) internal virtual override onlyRole(DEFAULT_ADMIN_ROLE) {}

    // Upgrade Section Ends

    // Access Control Section Starts

    /**
        @notice grantRole function
        @dev Overrides the grant role in accessControl contract.
        @dev If RELAYER_ROLE is granted then it would mint 1 voting token as voting weights.
        @dev The Token minted would be notional and non transferable type.
        @param role Hash of the role being granted
        @param account address to which role is being granted
    */
    function grantRole(bytes32 role, address account)
        public
        virtual
        override
        nonReentrant
        onlyRole(getRoleAdmin(role))
    {
        super.grantRole(role, account);
        if (role == RELAYER_ROLE && _voter.balanceOf(account) == 0 ether) {
            _voter.mint(account);
            totalRelayers = totalRelayers + 1;
            emit RelayerAdded(account);
        }
    }

    /**
        @notice revokeRole function
        @dev Overrides the grant role in accessControl contract.
        @dev If RELAYER_ROLE is revoked then it would burn 1 voting token as voting weights.
        @dev The Token burned would be notional and non transferable type.
        @param role Hash of the role being revoked
        @param account address to which role is being revoked
    */
    function revokeRole(bytes32 role, address account)
        public
        virtual
        override
        nonReentrant
        onlyRole(getRoleAdmin(role))
    {
        super.revokeRole(role, account);
        if (role == RELAYER_ROLE && _voter.balanceOf(account) == 1 ether) {
            _voter.burn(account);
            totalRelayers = totalRelayers - 1;
            emit RelayerRemoved(account);
        }
    }

    // Access Control Section Ends

    // Whitelist Section Starts
    /**
        @dev Adds single address to _whitelist.
        @param _beneficiary Address to be added to the _whitelist
    */
    function addToWhitelist(address _beneficiary) public virtual onlyRole(DEFAULT_ADMIN_ROLE) isWhitelistEnabled {
        _whitelist[_beneficiary] = true;
        emit AddedWhitelist(_beneficiary);
    }

    /**
        @dev Removes single address from _whitelist.
        @param _beneficiary Address to be removed to the _whitelist
    */
    function removeFromWhitelist(address _beneficiary) public virtual onlyRole(DEFAULT_ADMIN_ROLE) isWhitelistEnabled {
        _whitelist[_beneficiary] = false;
        emit RemovedWhitelist(_beneficiary);
    }

    /**
        @dev setWhitelisting whitelisting process.
    */
    function setWhitelisting(bool value) public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _whitelistEnabled = value;
        emit WhitelistingSetting(value);
    }

    // Whitelist Section Ends

    // Pause Section Starts

    /**
        @notice Pauses deposits, proposal creation and voting, and deposit executions.
        @notice Only callable by an address that currently has the admin role.
    */
    function pause() public virtual onlyRole(PAUSER_ROLE) whenNotPaused {
        _pause();
    }

    /**
        @notice Unpauses deposits, proposal creation and voting, and deposit executions.
        @notice Only callable by an address that currently has the admin role.
     */
    function unpause() public virtual onlyRole(PAUSER_ROLE) whenPaused {
        _unpause();
    }

    // Pause Section Ends

    // Ancilary Admin Functions Starts

    /**
        @notice Modifies the number of votes required for a proposal to be considered passed.
        @notice Only callable by an address that currently has the admin role.
        @param newQuorum Value {newQuorum} will be changed to.
        @notice Emits {quorumChanged} event.
     */
    function adminChangeQuorum(uint256 newQuorum) public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _quorum = uint64(newQuorum);
        emit quorumChanged(_quorum);
    }

    /**
        @notice Modifies the block expiry for a proposal.
        @notice Only callable by an address that currently has the admin role.
        @param newExpiry will be new value of _expiry.
        @notice Emits {expiryChanged} event.
     */
    function adminChangeExpiry(uint256 newExpiry) public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _expiry = newExpiry;
        emit expiryChanged(_quorum);
    }

    /**
        @notice Sets a new resource for handler contracts that use the IERCHandler interface,
        and maps the {handlerAddress} to {resourceID} in {_resourceIDToHandlerAddress}.
        @notice Only callable by an address that currently has the admin role.
        @param handlerAddress Address of handler resource will be set for.
        @param resourceID ResourceID to be used when making deposits.
        @param tokenAddress Address of contract to be called when a deposit is made and a deposited is executed.
     */
    function adminSetResource(
        address handlerAddress,
        bytes32 resourceID,
        address tokenAddress
    ) public virtual onlyRole(RESOURCE_SETTER) {
        _resourceIDToHandlerAddress[resourceID] = handlerAddress;
        IERCHandler handler = IERCHandler(handlerAddress);
        handler.setResource(resourceID, tokenAddress);
    }

    /**
        @notice Sets a new resource for handler contracts that use the IERCHandler interface,
        and maps the {handlerAddress} to {resourceID} in {_resourceIDToHandlerAddress}.
        @notice Only callable by an address that currently has the admin role.
        @param handlerAddress Address of handler resource will be set for.
        @param tokenAddress token contract for setting config.
        @param destinationChainID destinationChainID to be used when setting config.
        @param decimals decimals for token on target chain.
     */
    function adminSetTokenDecimals(
        address handlerAddress,
        address tokenAddress,
        uint8 destinationChainID,
        uint8 decimals
    ) public virtual onlyRole(RESOURCE_SETTER) {
        IERCHandlerDecimals handler = IERCHandlerDecimals(handlerAddress);
        handler.setTokenDecimals(tokenAddress, destinationChainID, decimals);
    }

    function adminSetOneSplitAddress(address handlerAddress, address contractAddress)
        public
        virtual
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        IERCHandler handler = IERCHandler(handlerAddress);
        handler.setOneSplitAddress(contractAddress);
    }

    /**
    @notice Creates new liquidity pool
    @notice Only callable by an address that currently has the admin role.
    @param handlerAddress Address of handler resource will be set for.
    @param tokenAddress Address of token for which pool needs to be created.
 */
    function adminSetLiquidityPool(
        string memory name,
        string memory symbol,
        uint8 decimals,
        address handlerAddress,
        address tokenAddress,
        address lpAddress
    ) public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        IERCHandler handler = IERCHandler(handlerAddress);
        handler.setLiquidityPool(name, symbol, decimals, tokenAddress, lpAddress);
    }

    function adminSetLiquidityPoolOwner(
        address handlerAddress,
        address newOwner,
        address tokenAddress,
        address lpAddress
    ) public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        IERCHandler handler = IERCHandler(handlerAddress);
        handler.setLiquidityPoolOwner(newOwner, tokenAddress, lpAddress);
    }

    /**
        @notice Sets a new resource for handler contracts that use the IGenericHandler interface,
        and maps the {handlerAddress} to {resourceID} in {_resourceIDToHandlerAddress}.
        @notice Only callable by an address that currently has the admin role.
        @param handlerAddress Address of handler resource will be set for.
        @param resourceID ResourceID to be used when making deposits.
        @param contractAddress Address of contract to be called when a deposit is made and a deposited is executed.
     */
    function adminSetGenericResource(
        address handlerAddress,
        bytes32 resourceID,
        address contractAddress,
        bytes4 depositFunctionSig,
        uint256 depositFunctionDepositerOffset,
        bytes4 executeFunctionSig
    ) public virtual onlyRole(RESOURCE_SETTER) {
        _resourceIDToHandlerAddress[resourceID] = handlerAddress;
        IGenericHandler handler = IGenericHandler(handlerAddress);
        handler.setResource(
            resourceID,
            contractAddress,
            depositFunctionSig,
            depositFunctionDepositerOffset,
            executeFunctionSig
        );
    }

    /**
        @notice Sets a resource as burnable for handler contracts that use the IERCHandler interface.
        @notice Only callable by an address that currently has the admin role.
        @param handlerAddress Address of handler resource will be set for.
        @param tokenAddress Address of contract to be called when a deposit is made and a deposited is executed.
        @param status Boolean flag to change burnable status.
     */
    function adminSetBurnable(
        address handlerAddress,
        address tokenAddress,
        bool status
    ) public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        IERCHandler handler = IERCHandler(handlerAddress);
        handler.setBurnable(tokenAddress, status);
    }

    /**
        @notice Used to manually withdraw funds from ERC safes.
        @param handlerAddress Address of handler to withdraw from.
        @param tokenAddress Address of token to withdraw.
        @param recipient Address to withdraw tokens to.
        @param amount the amount of ERC20 tokens to withdraw.
     */
    function adminWithdraw(
        address handlerAddress,
        address tokenAddress,
        address recipient,
        uint256 amount
    ) public virtual nonReentrant onlyRole(EMERGENCY_ROLE) {
        IERCHandler handler = IERCHandler(handlerAddress);
        handler.withdraw(tokenAddress, recipient, amount);
        emit AdminWithdraw(handlerAddress, tokenAddress, recipient, amount);
    }

    /**
        @notice Used to manually withdraw funds from ERC safes.
        @param handlerAddress Address of handler to withdraw from.
        @param tokenAddress Address of token to withdraw.
        @param recipient Address to withdraw tokens to.
        @param amount the amount of ERC20 tokens to withdraw.
     */
    function adminWithdrawFees(
        address handlerAddress,
        address tokenAddress,
        address recipient,
        uint256 amount
    ) public virtual nonReentrant onlyRole(EMERGENCY_ROLE) {
        IERCHandler handler = IERCHandler(handlerAddress);
        handler.withdrawFees(tokenAddress, recipient, amount);
        emit AdminWithdraw(handlerAddress, tokenAddress, recipient, amount);
    }

    /**
       @notice Used to set feeStatus
       @notice Only callable by admin.
    */
    function adminSetFeeStatus(bytes32 resourceID, bool status) public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        address handlerAddress = _resourceIDToHandlerAddress[resourceID];
        IERCHandler handler = IERCHandler(handlerAddress);
        handler.toggleFeeStatus(status);
    }

    // Fee Function Starts

    /**
       @notice Used to set fee
       @notice Only callable by feeSetter.
    */
    function setBridgeFee(
        bytes32 resourceID,
        uint8 destinationChainID,
        address feeTokenAddress,
        uint256 transferFee,
        uint256 exchangeFee,
        bool accepted
    ) public virtual onlyRole(FEE_SETTER_ROLE) {
        address handlerAddress = _resourceIDToHandlerAddress[resourceID];
        IERCHandler handler = IERCHandler(handlerAddress);
        require(handler.getFeeStatus(), "fee is not enabled");
        handler.setBridgeFee(destinationChainID, feeTokenAddress, transferFee, exchangeFee, accepted);
    }

    function getBridgeFee(
        bytes32 resourceID,
        uint8 destChainID,
        address feeTokenAddress
    ) public view returns (uint256, uint256) {
        address handlerAddress = _resourceIDToHandlerAddress[resourceID];
        IERCHandler handler = IERCHandler(handlerAddress);
        return handler.getBridgeFee(destChainID, feeTokenAddress);
    }

    // Fee Function Ends

    // Deposit Function Starts

    function deposit(
        uint8 destinationChainID,
        bytes32 resourceID,
        bytes calldata data,
        uint256[] memory distribution,
        uint256[] memory flags,
        address[] memory path,
        address feeTokenAddress
    ) public virtual nonReentrant whenNotPaused isWhitelisted {
        _deposit(destinationChainID, resourceID, data, distribution, flags, path, feeTokenAddress);
    }

    function depositETH(
        uint8 destinationChainID,
        bytes32 resourceID,
        bytes calldata data,
        uint256[] memory distribution,
        uint256[] memory flags,
        address[] memory path,
        address feeTokenAddress
    ) public payable virtual nonReentrant whenNotPaused isWhitelisted {
        IERCHandler ercHandler = IERCHandler(_resourceIDToHandlerAddress[resourceID]);
        require(address(ercHandler) != address(0), "resourceID not mapped to handler");
        require(msg.value > 0, "depositETH: No native assets transferred");

        address weth = ercHandler._WETH();

        IWETH(weth).deposit{ value: msg.value }();
        require(IWETH(weth).transfer(msg.sender, msg.value));

        _deposit(destinationChainID, resourceID, data, distribution, flags, path, feeTokenAddress);
    }

    function _deposit(
        uint8 destinationChainID,
        bytes32 resourceID,
        bytes calldata data,
        uint256[] memory distribution,
        uint256[] memory flags,
        address[] memory path,
        address feeTokenAddress
    ) private {
        IDepositExecute.SwapInfo memory swapDetails = unpackDepositData(data);

        swapDetails.depositer = msg.sender;
        swapDetails.distribution = distribution;
        swapDetails.flags = flags;
        swapDetails.path = path;
        swapDetails.feeTokenAddress = feeTokenAddress;

        swapDetails.handler = _resourceIDToHandlerAddress[resourceID];
        require(swapDetails.handler != address(0), "resourceID not mapped to handler");

        swapDetails.depositNonce = ++_depositCounts[destinationChainID];

        IDepositExecute depositHandler = IDepositExecute(swapDetails.handler);
        depositHandler.deposit(resourceID, destinationChainID, swapDetails.depositNonce, swapDetails);

        emit Deposit(destinationChainID, resourceID, swapDetails.depositNonce);
    }

    function unpackDepositData(bytes calldata data)
        internal
        pure
        returns (IDepositExecute.SwapInfo memory depositData)
    {
        IDepositExecute.SwapInfo memory swapDetails;
        uint256 isDestNative;
        (
            swapDetails.srcTokenAmount,
            swapDetails.srcStableTokenAmount,
            swapDetails.destStableTokenAmount,
            swapDetails.destTokenAmount,
            isDestNative,
            swapDetails.lenRecipientAddress,
            swapDetails.lenSrcTokenAddress,
            swapDetails.lenDestTokenAddress
        ) = abi.decode(data, (uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256));
        swapDetails.isDestNative = isDestNative == 0 ? false : true;
        swapDetails.index = 256; // 32 * 6 -> 8
        bytes memory recipient = bytes(data[swapDetails.index:swapDetails.index + swapDetails.lenRecipientAddress]);
        swapDetails.index = swapDetails.index + swapDetails.lenRecipientAddress;
        bytes memory srcToken = bytes(data[swapDetails.index:swapDetails.index + swapDetails.lenSrcTokenAddress]);
        swapDetails.index = swapDetails.index + swapDetails.lenSrcTokenAddress;
        bytes memory destStableToken = bytes(
            data[swapDetails.index:swapDetails.index + swapDetails.lenDestTokenAddress]
        );
        swapDetails.index = swapDetails.index + swapDetails.lenDestTokenAddress;
        bytes memory destToken = bytes(data[swapDetails.index:swapDetails.index + swapDetails.lenDestTokenAddress]);

        bytes20 srcTokenAddress;
        bytes20 destStableTokenAddress;
        bytes20 destTokenAddress;
        bytes20 recipientAddress;
        assembly {
            srcTokenAddress := mload(add(srcToken, 0x20))
            destStableTokenAddress := mload(add(destStableToken, 0x20))
            destTokenAddress := mload(add(destToken, 0x20))
            recipientAddress := mload(add(recipient, 0x20))
        }
        swapDetails.srcTokenAddress = srcTokenAddress;
        swapDetails.destStableTokenAddress = address(destStableTokenAddress);
        swapDetails.destTokenAddress = destTokenAddress;
        swapDetails.recipient = address(recipientAddress);

        return swapDetails;
    }

    // Deposit Function Ends

    /**
       @notice Allows staking into liquidity pools.
       @notice Only callable when Bridge is not paused.
       @param handler handler address
       @param tokenAddress Asset which needs to be staked.
       @param amount Amount that needs to be staked.
       @notice Emits {Stake} event.
    */
    function stake(
        address handler,
        address tokenAddress,
        uint256 amount
    ) public virtual nonReentrant whenNotPaused {
        ILiquidityPool depositHandler = ILiquidityPool(handler);
        depositHandler.stake(msg.sender, tokenAddress, amount);
        emit Stake(msg.sender, amount, tokenAddress);
    }

    /**
       @notice Allows staking ETH into liquidity pools.
       @notice Only callable when Bridge is not paused.
       @param handler handler address
       @notice Emits {Stake} event.
    */
    function stakeETH(
        address handler
    ) public payable virtual nonReentrant whenNotPaused {
        ILiquidityPool depositHandler = ILiquidityPool(handler);
        IERCHandler ercHandler = IERCHandler(handler);
        address WETH = ercHandler._WETH();
        uint256 amount = msg.value;
        require(amount > 0, "stakeETH: insufficient eth provided");

        IWETH(WETH).deposit{ value: amount }();
        assert(IWETH(WETH).transfer(handler, amount));
        depositHandler.stakeETH(msg.sender, WETH, amount);
        emit Stake(msg.sender, amount, WETH);
    }

    /**
       @notice Allows unstaking from liquidity pools.
       @notice Only callable when Bridge is not paused.
       @param handler handler address
       @param tokenAddress Asset which needs to be unstaked.
       @param amount Amount that needs to be unstaked.
       @notice Emits {Unstake} event.
    */
    function unstake(
        address handler,
        address tokenAddress,
        uint256 amount
    ) public virtual nonReentrant whenNotPaused {
        ILiquidityPool depositHandler = ILiquidityPool(handler);
        depositHandler.unstake(msg.sender, tokenAddress, amount);
        emit Unstake(msg.sender, amount, tokenAddress);
    }

    /**
       @notice Allows unstaking ETH from liquidity pools.
       @notice Only callable when Bridge is not paused.
       @param handler handler address
       @param amount Amount that needs to be unstaked.
       @notice Emits {Unstake} event.
    */
    function unstakeETH(
        address handler,
        uint256 amount
    ) public virtual nonReentrant whenNotPaused {
        ILiquidityPool depositHandler = ILiquidityPool(handler);
        IERCHandler ercHandler = IERCHandler(handler);
        address WETH = ercHandler._WETH();
        depositHandler.unstakeETH(msg.sender, WETH, amount);
        emit Unstake(msg.sender, amount, WETH);
    }

    // Stating/UnStaking Function Ends

    // Voting Function starts

    /**
        @notice Returns a proposal.
        @param originChainID Chain ID deposit originated from.
        @param depositNonce ID of proposal generated by proposal's origin Bridge contract.
        @param dataHash Hash of data to be provided when deposit proposal is executed.
     */
    function getProposal(
        uint8 originChainID,
        uint64 depositNonce,
        bytes32 dataHash
    ) public view virtual returns (IVoterUpgradeable.issueStruct memory status) {
        bytes32 proposalHash = keccak256(abi.encodePacked(originChainID, depositNonce, dataHash));
        return _voter.fetchIssueMap(_proposals[proposalHash]);
    }

    /**
        @notice When called, {msg.sender} will be marked as voting in favor of proposal.
        @notice Only callable by relayers when Bridge is not paused.
        @param chainID ID of chain deposit originated from.
        @param depositNonce ID of deposited generated by origin Bridge contract.
        @param dataHash Hash of data provided when deposit was made.
        @notice Proposal must not have already been passed or executed.
        @notice {msg.sender} must not have already voted on proposal.
        @notice Emits {ProposalEvent} event with status indicating the proposal status.
        @notice Emits {ProposalVote} event.
     */
    function voteProposal(
        uint8 chainID,
        uint64 depositNonce,
        bytes32 resourceID,
        bytes32 dataHash
    ) public virtual isResourceID(resourceID) onlyRole(RELAYER_ROLE) whenNotPaused {
        bytes32 proposalHash = keccak256(abi.encodePacked(chainID, depositNonce, dataHash));
        if (_proposals[proposalHash] == 0) {
            uint256 id = _voter.createProposal(block.number + _expiry, _quorum);
            _proposals[proposalHash] = id;
            _proposalDetails[id] = proposalStruct(chainID, depositNonce, resourceID, dataHash);
            emit ProposalEvent(chainID, depositNonce, IVoterUpgradeable.ProposalStatus.Active, dataHash);
        } else if (_voter.fetchIsExpired(_proposals[proposalHash])) {
            _voter.setStatus(_proposals[proposalHash]);
            emit ProposalEvent(chainID, depositNonce, _voter.getStatus(_proposals[proposalHash]), dataHash);
            return;
        }
        if (_voter.getStatus(_proposals[proposalHash]) != IVoterUpgradeable.ProposalStatus.Cancelled) {
            _voter.vote(_proposals[proposalHash], 1, msg.sender);

            emit ProposalVote(chainID, depositNonce, _voter.getStatus(_proposals[proposalHash]), dataHash);
            if (_voter.getStatus(_proposals[proposalHash]) == IVoterUpgradeable.ProposalStatus.Passed) {
                emit ProposalEvent(chainID, depositNonce, _voter.getStatus(_proposals[proposalHash]), dataHash);
            }
        }
    }

    /**
        @notice Cancels a deposit proposal that has not been executed yet.
        @notice Only callable by relayers when Bridge is not paused.
        @param chainID ID of chain deposit originated from.
        @param depositNonce ID of deposited generated by origin Bridge contract.
        @param dataHash Hash of data originally provided when deposit was made.
        @notice Proposal must be past expiry threshold.
        @notice Emits {ProposalEvent} event with status {Cancelled}.
     */
    function cancelProposal(
        uint8 chainID,
        uint64 depositNonce,
        bytes32 dataHash
    ) public onlyAdminOrRelayer {
        bytes32 proposalHash = keccak256(abi.encodePacked(chainID, depositNonce, dataHash));
        IVoterUpgradeable.ProposalStatus currentStatus = _voter.getStatus(_proposals[proposalHash]);
        require(
            currentStatus == IVoterUpgradeable.ProposalStatus.Active ||
                currentStatus == IVoterUpgradeable.ProposalStatus.Passed,
            "Proposal cannot be cancelled"
        );

        _voter.setStatus(_proposals[proposalHash]);

        emit ProposalEvent(chainID, depositNonce, IVoterUpgradeable.ProposalStatus.Cancelled, dataHash);
    }

    /**
        @notice Executes a deposit proposal that is considered passed using a specified handler contract.
        @notice Only callable by relayers when Bridge is not paused.
        @param chainID ID of chain deposit originated from.
        @param resourceID ResourceID to be used when making deposits.
        @param depositNonce ID of deposited generated by origin Bridge contract.
        @param data Data originally provided when deposit was made.
        @notice Proposal must have Passed status.
        @notice Hash of {data} must equal proposal's {dataHash}.
        @notice Emits {ProposalEvent} event with status {Executed}.
     */
    function executeProposal(
        uint8 chainID,
        uint64 depositNonce,
        bytes calldata data,
        bytes32 resourceID,
        uint256[] memory distribution,
        uint256[] memory flags,
        address[] memory path
    ) public virtual onlyRole(RELAYER_ROLE) whenNotPaused {
        address settlementToken;
        IDepositExecute.SwapInfo memory swapDetails = unpackDepositData(data);
        swapDetails.distribution = distribution;
        swapDetails.flags = flags;
        swapDetails.path = path;

        bytes32 dataHash = keccak256(abi.encodePacked(_resourceIDToHandlerAddress[resourceID], data));
        bytes32 proposalHash = keccak256(abi.encodePacked(chainID, depositNonce, dataHash));
        IVoterUpgradeable.ProposalStatus currentStatus = _voter.getStatus(_proposals[proposalHash]);
        require(currentStatus == IVoterUpgradeable.ProposalStatus.Passed, "Proposal must have Passed status");

        _voter.executeProposal(_proposals[proposalHash]);

        IDepositExecute depositHandler = IDepositExecute(_resourceIDToHandlerAddress[resourceID]);

        (settlementToken, swapDetails.returnAmount) = depositHandler.executeProposal(swapDetails, resourceID);
        emit Settlement(
            chainID,
            depositNonce,
            settlementToken,
            swapDetails.returnAmount,
            IVoterUpgradeable.ProposalStatus.Executed
        );

        emit ProposalEvent(chainID, depositNonce, IVoterUpgradeable.ProposalStatus.Executed, dataHash);
    }

    // Voting Function ends
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

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
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
    function __AccessControl_init() internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
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
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
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
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
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
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
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
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
        __ERC1967Upgrade_init_unchained();
        __UUPSUpgradeable_init_unchained();
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

/**
    @title Interface to be used with handlers that support ERC20s and ERC721s.
    @author Router Protocol.
 */
interface IVoterUpgradeable {

    enum ProposalStatus { Inactive, Active, Passed, Executed, Cancelled }

    struct issueStruct {
        ProposalStatus status;
        uint256 startBlock;
        uint256 endBlock;
        uint64 quorum;
        uint256 maxVotes;
        uint8 resultOption;
    }

    function Voted(uint256, address) external view returns (bool);

    function mint(address) external;

    function burn(address account) external;
    
    function balanceOf(address) external view returns (uint256);

    function fetchIssueMap(uint256 _issue) external view returns (issueStruct memory issue);

    function fetchIsExpired(uint256 _issue) external view returns (bool status);

    function createProposal(uint256 endBlock, uint64 quorum)
        external
        returns (uint256 id);

    function setStatus(uint256 issueId) external  returns (bool success);
    function getStatus(uint256 issueId) external view returns (ProposalStatus status);
     function vote(
        uint256 issueId,
        uint8 option,
        address relayer
    )
        external
        returns (bool success);
    
    function executeProposal(uint256 issueId) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

/**
    @title Interface to be used with handlers that support ERC20s and ERC721s.
    @author Router Protocol.
 */
interface IERC20Upgradeable {

    function transfer( address, uint256) external;
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

/**
    @title Interface for handler contracts that support deposits and deposit executions.
    @author Router Protocol.
 */
interface IDepositExecute {
    struct SwapInfo {
        address feeTokenAddress;
        uint64 depositNonce;
        uint256 index;
        uint256 returnAmount;
        address recipient;
        address stableTokenAddress;
        address handler;
        uint256 srcTokenAmount;
        uint256 srcStableTokenAmount;
        uint256 destStableTokenAmount;
        uint256 destTokenAmount;
        uint256 lenRecipientAddress;
        uint256 lenSrcTokenAddress;
        uint256 lenDestTokenAddress;
        bytes20 srcTokenAddress;
        address srcStableTokenAddress;
        bytes20 destTokenAddress;
        address destStableTokenAddress;
        uint256[] distribution;
        uint256[] flags;
        address[] path;
        address depositer;
        bool isDestNative;
    }

    /**
        @notice It is intended that deposit are made using the Bridge contract.
        @param destinationChainID Chain ID deposit is expected to be bridged to.
        @param depositNonce This value is generated as an ID by the Bridge contract.
        @param swapDetails Swap details

     */
    function deposit(
        bytes32 resourceID,
        uint8 destinationChainID,
        uint64 depositNonce,
        SwapInfo calldata swapDetails
    ) external;

    /**
        @notice It is intended that proposals are executed by the Bridge contract.
     */
    function executeProposal(SwapInfo calldata swapDetails, bytes32 resourceID) external returns (address, uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2;

/**
    @title Interface for handler contracts that support deposits and deposit executions.
    @author Router Protocol.
 */
interface ILiquidityPool {
    /**
        @notice Staking should be done by using bridge contract.
        @param depositor stakes liquidity in the pool .
        @param tokenAddress staking token for which liquidity needs to be added.
        @param amount Amount that needs to be staked.
     */
    function stake(
        address depositor,
        address tokenAddress,
        uint256 amount
    ) external;

    /**
        @notice Staking should be done by using bridge contract.
        @param depositor stakes liquidity in the pool .
        @param tokenAddress staking token for which liquidity needs to be added.
        @param amount Amount that needs to be staked.
     */
    function stakeETH(
        address depositor,
        address tokenAddress,
        uint256 amount
    ) external;

    /**
        @notice Staking should be done by using bridge contract.
        @param unstaker removes liquidity from the pool.
        @param tokenAddress staking token of which liquidity needs to be removed.
        @param amount Amount that needs to be unstaked.
     */
    function unstake(
        address unstaker,
        address tokenAddress,
        uint256 amount
    ) external;

    /**
        @notice Staking should be done by using bridge contract.
        @param unstaker removes liquidity from the pool.
        @param tokenAddress staking token of which liquidity needs to be removed.
        @param amount Amount that needs to be unstaked.
     */
    function unstakeETH(
        address unstaker,
        address tokenAddress,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

/**
    @title Interface to be used with handlers that support ERC20s and ERC721s.
    @author Router Protocol.
 */
interface IERCHandler {

    function withdrawFees(
        address tokenAddress,
        address recipient,
        uint256 amount
    ) external;

    function getBridgeFee(uint8 destinationChainID, address feeTokenAddress) external view returns (uint256, uint256);

    function setBridgeFee(
        uint8 destinationChainID,
        address feeTokenAddress,
        uint256 transferFee,
        uint256 exchangeFee,
        bool accepted
    ) external;

    function toggleFeeStatus(bool status) external;

    function getFeeStatus() external view returns (bool);

    function _ETH() external view returns (address);

    function _WETH() external view returns (address);

    function resourceIDToTokenContractAddress(bytes32 resourceID) external view returns (address);

    /**
        @notice Correlates {resourceID} with {contractAddress}.
        @param resourceID ResourceID to be used when making deposits.
        @param contractAddress Address of contract to be called when a deposit is made and a deposited is executed.
     */
    function setResource(bytes32 resourceID, address contractAddress) external;


    // function setTokenDecimals(address tokenAddress, uint8 destinationChainID, uint8 decimals) external;

    /**
        @notice Sets oneSplitAddress for the handler
        @param contractAddress Address of oneSplit contract
     */
    function setOneSplitAddress(address contractAddress) external;

    /**
        @notice Correlates {resourceID} with {contractAddress}.
        @param contractAddress Address of contract for qhich liquidity pool needs to be created.
     */
    function setLiquidityPool(
        string memory name,
        string memory symbol,
        uint8 decimals,
        address contractAddress,
        address lpAddress
    ) external;

    function setLiquidityPoolOwner(
        address newOwner,
        address tokenAddress,
        address lpAddress
    ) external;

    /**
        @notice Marks {contractAddress} as mintable/burnable.
        @param contractAddress Address of contract to be used when making or executing deposits.
        @param status Boolean flag for burnanble status.
     */
    function setBurnable(address contractAddress, bool status) external;

    /**
        @notice Used to manually release funds from ERC safes.
        @param tokenAddress Address of token contract to release.
        @param recipient Address to release tokens to.
        @param amountOrTokenID Either the amount of ERC20 tokens or the ERC721 token ID to release.
     */
    function withdraw(
        address tokenAddress,
        address recipient,
        uint256 amountOrTokenID
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

/**
    @title Interface to be used with handlers that support ERC20s and ERC721s.
    @author Router Protocol.
 */
interface IERCHandlerDecimals {
    
    function setTokenDecimals(address tokenAddress, uint8 destinationChainID, uint8 decimals) external;

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

/**
    @title Interface for handler that handles generic deposits and deposit executions.
    @author Router Protocol.
 */
interface IGenericHandler {
    /**
        @notice Correlates {resourceID} with {contractAddress}, {depositFunctionSig}, and {executeFunctionSig}.
        @param resourceID ResourceID to be used when making deposits.
        @param contractAddress Address of contract to be called when a deposit is made and a deposited is executed.
        @param depositFunctionSig Function signature of method to be called in {contractAddress} when a deposit is made.
        @param depositFunctionDepositerOffset Depositer address position offset in the metadata, in bytes.
        @param executeFunctionSig Function signature of method to be called in {contractAddress} when a deposit is executed.
     */
    function setResource(
        bytes32 resourceID,
        address contractAddress,
        bytes4 depositFunctionSig,
        uint256 depositFunctionDepositerOffset,
        bytes4 executeFunctionSig
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) external returns (bool);

    function approve(address guy, uint256 wad) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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
     * bearer except when using {AccessControl-_setupRole}.
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
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

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
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

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
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

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
    function __ERC165_init() internal onlyInitializing {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal onlyInitializing {
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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
// OpenZeppelin Contracts v4.4.1 (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
        __ERC1967Upgrade_init_unchained();
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallSecure(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlotUpgradeable.BooleanSlot storage rollbackTesting = StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            _functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature("upgradeTo(address)", oldImplementation)
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _upgradeTo(newImplementation);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}