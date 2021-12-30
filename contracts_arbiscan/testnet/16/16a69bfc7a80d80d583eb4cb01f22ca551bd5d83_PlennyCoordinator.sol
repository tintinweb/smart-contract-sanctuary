// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "./PlennyBaseUpgradableV2.sol";
import "./storage/PlennyCoordinatorStorage.sol";
import "./libraries/RewardLib.sol";

import "./interfaces/ArbSys.sol";

/// @title  PlennyCoordinator
/// @notice Coordinator contract between the Lightning Network and the Ethereum blockchain. Coordination and storing of
///         the data from the LN on-chain. Allows the users to provide info about their lightning nodes/channels,
///         and manages the channel rewards (i.e. NCCR) due for some actions.
contract PlennyCoordinator is PlennyBaseUpgradableV2, PlennyCoordinatorStorage {

    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address payable;
    using SafeERC20Upgradeable for IPlennyERC20;
    using RewardLib for uint256;

    /// An event emitted when a lightning node is added, but not yet verified.
    event LightningNodePending(address indexed by, uint256 verificationCapacity, string publicKey, address validatorAddress, uint256 indexed nodeIndex);
    /// An event emitted when a lightning node is verified.
    event LightningNodeVerified(address indexed to, string publicKey, uint256 indexed nodeIndex);
    /// An event emitted when a lightning channel is added, but not yet confirmed.
    event LightningChannelOpeningPending(address indexed by, string channelPoint, uint256 indexed channelIndex);
    /// An event emitted when a lightning channel is confirmed.
    event LightningChannelOpeningConfirmed(address to, uint256 amount, string node1, string node2, uint256 indexed channelIndex, uint256 blockNumber);
    /// An event emitted when a lightning channel is closed.
    event LightningChannelClosed(uint256 channelIndex);
    /// An event emitted when a reward is collected.
    event RewardReleased(address to, uint256 amount);
    /// An event emitted when logging function calls.
    event LogCall(bytes4  indexed sig, address indexed caller, bytes data) anonymous;

    /// @notice Initializes the smart contract instead of a constructor.
    /// @dev    Can be called only once during deploy.
    /// @param  _registry PlennyContractRegistry
    function initialize(address _registry) external initializer {
        channelRewardThreshold = uint256(500000);
        PlennyBaseUpgradableV2.__plennyBaseInit(_registry);
    }

    /// @notice Allows the user to add provisional information about their own lightning node.
    /// @dev    The lightning node is considered as "pending" in the system until the user verifies it by opening a channel
    ///         with a given capacity on the lightning network and submitting info (channel point) about that channel
    ///         in this contract.
    /// @param  nodePublicKey Public key of the lightning node.
    /// @param  validatorAddress An oracle validator address is responsible for validating the lightning node.
    /// @return uint256 The capacity of the channel that the user needs to open on the lightning network.
    function addLightningNode(string calldata nodePublicKey, address validatorAddress) external returns (uint256) {
        uint256 nodeIndex = nodeIndexPerPubKey[nodePublicKey][msg.sender];

        LightningNode storage node = nodes[nodeIndex];

        require(node.validatorAddress != validatorAddress, "ERR_DUPLICATE");
        if (nodeIndex > 0) {
            node.status = 2;
        }

        IPlennyDappFactory factory = contractRegistry.factoryContract();
        require(factory.isOracleValidator(validatorAddress), "ERR_NOT_ORACLE");

        uint256 verificationCapacity = factory.random();

        nodesCount++;
        nodes[nodesCount] = LightningNode(verificationCapacity, _blockNumber(), nodePublicKey, validatorAddress,
            0, 0, msg.sender);

        nodeIndexPerPubKey[nodePublicKey][msg.sender] = nodesCount;
        nodeOwnerCount[msg.sender]++;
        nodesPerAddress[msg.sender].push(nodesCount);

        emit LightningNodePending(msg.sender, verificationCapacity, nodePublicKey, validatorAddress, nodesCount);

        return (verificationCapacity);
    }

    /// @notice Submits a claim/info that a certain channel has been opened on the lightning network.
    /// @dev    The information can be submitted either by the end-user directly or by the maker that has opened
    ///         the channel via the lightning ocean/marketplace.
    /// @param  _channelPoint Channel point of the lightning channel.
    /// @param  _oracleAddress an address of the lightning oracle that is the counter-party of the lightning channel.
    /// @param  capacityRequest if this channel is opened via the lightning ocean/marketplace.
    function openChannel(string memory _channelPoint, address payable _oracleAddress, bool capacityRequest) external override {

        require(_oracleAddress != msg.sender, "ERR_SELF");

        require(contractRegistry.factoryContract().isOracleValidator(_oracleAddress)
            || contractRegistry.oceanContract().makerIndexPerAddress(_oracleAddress) > 0, "ERR_NOT_ORACLE");

        address payable nodeOwner;
        if (capacityRequest) {
            nodeOwner = _oracleAddress;
        } else {
            nodeOwner = msg.sender;
        }

        // check if the user has at least one verified node
        uint256 ownedNodes = nodeOwnerCount[nodeOwner];
        require(ownedNodes > 0, "ERR_NOT_FOUND");

        // check if this channel was already added
        uint256 channelIndex = channelIndexPerId[_channelPoint][nodeOwner];
        require(channelIndex == 0, "ERR_DUPLICATE");
        require(confirmedChannelIndexPerId[_channelPoint] == 0, "ERR_DUPLICATE");

        channelsCount++;
        channels[channelsCount] = LightningChannel(0, _blockNumber(), 0, 0, 0, nodeOwner,
            _oracleAddress, 0, 0, _channelPoint, 0, _altBlockNumber());

        channelsPerAddress[nodeOwner].push(channelsCount);
        channelIndexPerId[_channelPoint][nodeOwner] = channelsCount;
        channelStatusCount[0]++;

        emit LightningChannelOpeningPending(nodeOwner, _channelPoint, channelsCount);
    }

    /// @notice Instant verification of the initial(ZERO) lightning node. Managed by the contract owner.
    /// @param  publicKey The public key of the initial lightning node.
    /// @param  account address of the initial lightning oracle.
    /// @return uint256 node index
    function verifyDefaultNode(string calldata publicKey, address payable account) external override returns (uint256){
        _onlyFactory();

        nodesCount++;
        nodes[nodesCount] = LightningNode(0, _blockNumber(), publicKey, account, 1, _blockNumber(), account);
        nodeIndexPerPubKey[publicKey][account] = nodesCount;
        nodesPerAddress[account].push(nodesCount);
        uint256 newNodeIndex = nodeIndexPerPubKey[publicKey][account];

        nodeOwnerCount[account]++;
        return newNodeIndex;
    }

    /// @notice Confirms that a lightning channel with the provided information was indeed opened on the lightning network.
    ///         Once a channel is confirmed, the submitter of the channel info becomes eligible for collecting rewards as long
    ///         as the channel is kept open on the lightning network. In case this channel is opened as a result of
    ///         verification of a lightning node, the node gets also marked as "verified".
    /// @dev    This is only called by the validation mechanism once the validators have reached the consensus on the
    ///         information provided below.
    /// @param  channelIndex index/id of the channel submission as registered in this contract.
    /// @param  _channelCapacitySat The capacity of the channel expressed in satoshi.
    /// @param  channelId Id of the channel as registered on the lightning network.
    /// @param  node1PublicKey The public key of the first node in the channel.
    /// @param  node2PublicKey The public key of the second node in the channel.
    function confirmChannelOpening(uint256 channelIndex, uint256 _channelCapacitySat,
        uint256 channelId, string memory node1PublicKey, string memory node2PublicKey) external override nonReentrant {
        _onlyAggregator();
        require(channelIndex > 0, "ERR_CHANNEL_NOT_FOUND");
        require(_channelCapacitySat > 0, "ERR_EMPTY");

        LightningChannel storage channel = channels[channelIndex];
        require(channel.status == 0, "ERR_WRONG_STATE");
        require(confirmedChannelIndexPerId[channel.channelPoint] == 0, "ERR_DUPLICATE");

        NodeInfo memory nodeInfo = NodeInfo(0, "0", "0");
        if (nodeIndexPerPubKey[node1PublicKey][channel.to] > 0) {
            nodeInfo.nodeIndex = nodeIndexPerPubKey[node1PublicKey][channel.to];
            nodeInfo.ownerPublicKey = node1PublicKey;
            nodeInfo.validatorPublicKey = node2PublicKey;
        } else {
            if (nodeIndexPerPubKey[node2PublicKey][channel.to] > 0) {
                nodeInfo.nodeIndex = nodeIndexPerPubKey[node2PublicKey][channel.to];
                nodeInfo.ownerPublicKey = node2PublicKey;
                nodeInfo.validatorPublicKey = node1PublicKey;
            }
        }

        // check if the channel matches data in smart contracts
        require(nodeInfo.nodeIndex > 0, "ERR_NODE_NOT_FOUND");
        LightningNode storage node = nodes[nodeInfo.nodeIndex];
        require(stringsEqual(node.publicKey, nodeInfo.ownerPublicKey), "ERR_WRONG_STATE");
        require(node.to == channel.to, "ERR_NODE_CHANNEL_MATCH");

        if (node.status == 0) {
            // verify the node
            if (node.capacity == _channelCapacitySat) {
                node.status = 1;
                node.verifiedDate = _blockNumber();
                emit LightningNodeVerified(node.to, node.publicKey, nodeInfo.nodeIndex);
            }
        }

        require(node.status == 1, "ERR_WRONG_STATE");

        // reserve the amount in the escrow
        channel.id = channelId;
        channel.status = 1;
        channel.capacity = _channelCapacitySat;
        channel.confirmedDate = _blockNumber();
        channel.blockNumber = contractRegistry.validatorElectionContract().latestElectionBlock();
        channelRewardStart[channel.id] = _blockNumber();
        confirmedChannelIndexPerId[channel.channelPoint] = channelIndex;

        channelStatusCount[0]--;
        channelStatusCount[1]++;

        uint256 potentialTreasuryRewardAmount = 0;

        IPlennyOcean plennyOcean = contractRegistry.oceanContract();
        uint256 capacityRequestIndex = plennyOcean.capacityRequestPerChannel(channel.channelPoint);
        if (capacityRequestIndex > 0) {
            (uint256 capacity,,,,,, string memory channelPoint,) = plennyOcean.capacityRequests(capacityRequestIndex);
            if (stringsEqual(channelPoint, channel.channelPoint)) {
                potentialTreasuryRewardAmount = _calculatePotentialReward(_channelCapacitySat, true);
                channel.rewardAmount = potentialTreasuryRewardAmount;
                //increment total inbound capacity
                totalInboundCapacity += capacity;
                // process the request
                plennyOcean.processCapacityRequest(capacityRequestIndex);
            }
        } else {
            potentialTreasuryRewardAmount = _calculatePotentialReward(_channelCapacitySat, false);
            channel.rewardAmount = potentialTreasuryRewardAmount;

            IPlennyDappFactory factory = contractRegistry.factoryContract();
            (,uint256 validatorNodeIndex,,,,,,) = factory.validators(factory.validatorIndexPerAddress(channel.oracleAddress));
            require(stringsEqual(nodeInfo.validatorPublicKey, nodes[validatorNodeIndex].publicKey), "ERR_WRONG_STATE");
            totalOutboundCapacity += channel.capacity;
        }

        emit LightningChannelOpeningConfirmed(channel.to, potentialTreasuryRewardAmount, nodeInfo.ownerPublicKey, nodeInfo.validatorPublicKey, channelIndex, _blockNumber());
    }

    /// @notice Marks that a previously opened channel on the lightning network has been closed.
    /// @dev    This is only called by the validation mechanism once the validators have reached the consensus that
    ///         the channel has been indeed closed on the lightning network.
    /// @param  channelIndex index/id of the channel submission as registered in this contract.
    function closeChannel(uint256 channelIndex) external override nonReentrant {
        _onlyAggregator();
        require(channelIndex > 0, "ERR_EMPTY");

        LightningChannel storage channel = channels[channelIndex];
        require(channel.status == 1, "ERR_WRONG_STATE");

        channel.status = 2;
        channel.closureDate = _blockNumber();
        channelStatusCount[1]--;

        IPlennyOcean ocean = contractRegistry.oceanContract();
        uint256 capacityRequestIndex = ocean.capacityRequestPerChannel(channel.channelPoint);
        if (ocean.capacityRequestsCount() > 0) {
            totalInboundCapacity -= channel.capacity;
            (,,,,,, string memory channelPoint,) = ocean.capacityRequests(capacityRequestIndex);
            if (stringsEqual(channelPoint, channel.channelPoint)) {
                ocean.closeCapacityRequest(capacityRequestIndex, channel.id, channel.confirmedDate);
            }
        } else {
            totalOutboundCapacity -= channel.capacity;
        }

        _collectChannelRewardInternal(channel);

        emit LightningChannelClosed(channelIndex);
    }

    /// @notice Batch collect of all pending rewards for all the channels opened by the sender.
    /// @param  channelIndex indexes/ids of the channel submissions as registered in this contract.
    function claimAllChannelsReward(uint256 [] calldata channelIndex) external nonReentrant {
        for (uint256 i = 0; i < channelIndex.length; i++) {
            _collectChannelReward(channelIndex[i]);
        }
    }

    /// @notice Collects pending rewards only for the provided channel opened by the sender.
    /// @param  channelIndex index/id of the channel submission as registered in this contract.
    function collectChannelReward(uint256 channelIndex) external nonReentrant {
        _collectChannelReward(channelIndex);
    }

    /// @notice Set the channel threshold (in satoshi) for which a reward is given.
    /// @dev    Only the owner of the contract can set this.
    /// @param  threshold channel threshold (in satoshi)
    function setChannelRewardThreshold(uint256 threshold) external onlyOwner {
        require(threshold > 20000 && threshold < 16000000, "ERR_INVALID_VALUE");
        channelRewardThreshold = threshold;
    }

    /// @notice Gets the number of opened channels as registered in this contract.
    /// @return uint256 opened channels count
    function getChannelsCount() external view returns (uint256){
        return channelStatusCount[1];
    }

    /// @notice Gets all the submitted nodes for the given address.
    /// @param  addr Address to check for
    /// @return array indexes of all the nodes that belong to the address
    function getNodesPerAddress(address addr) external view returns (uint256[] memory){
        return nodesPerAddress[addr];
    }

    /// @notice Gets all the submitted channels for the given address.
    /// @param  addr Address to check for
    /// @return array indexes of all the channels that belong to the address
    function getChannelsPerAddress(address addr) external view returns (uint256[] memory){
        return channelsPerAddress[addr];
    }

    /// @notice Calculates the potential reward for the given channel capacity. If the channel is opened through the
    ///         ocean/marketplace the reward is increased.
    /// @param  capacity capacity of the channel
    /// @param  marketplace if the reward comes as a result of marketplace action.
    /// @return potentialReward channel reward
    function _calculatePotentialReward(uint256 capacity, bool marketplace) public view returns (uint256 potentialReward){
        uint256 treasuryBalance = contractRegistry.plennyTokenContract().balanceOf(contractRegistry.getAddress("PlennyTreasury"));

        IPlennyDappFactory factory = contractRegistry.factoryContract();

        return capacity.calculateReward(
            marketplace,
            channelRewardThreshold,
            factory.makersFixedRewardAmount(),
            factory.makersRewardPercentage(),
            factory.capacityFixedRewardAmount(),
            factory.capacityRewardPercentage(),
            treasuryBalance);
    }


    /// @notice Check string equality
    /// @param  a first string
    /// @param  b second string
    /// @return bool true/false
    function stringsEqual(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b)));
    }

    /// @notice Only oracle consensus validators
    function _onlyAggregator() internal view {
        require(contractRegistry.getAddress("PlennyOracleValidator") == msg.sender, "ERR_NON_AGGR");
    }

    /// @notice Only plenny oracle factory
    function _onlyFactory() internal view {
        require(contractRegistry.getAddress("PlennyDappFactory") == msg.sender, "ERR_NOT_FACTORY");
    }

    /// @notice In case the contract is deployed on Arbitrum, get the Arbitrum block number.
    /// @return uint256 L1 block number or L2 block number
    function _altBlockNumber() internal view returns (uint256){
        uint chainId = getChainId();
        if (chainId == 42161 || chainId == 421611) {
            return ArbSys(address(100)).arbBlockNumber();
        } else {
            return block.number;
        }
    }

    /// @notice id of the network the contract is deployed to.
    /// @return chainId Network id
    function getChainId() internal pure returns (uint256 chainId) {
        assembly {
            chainId := chainid()
        }
    }

    /// @notice Collects a reward for a given channel
    /// @param  channel opened/active channel
    function _collectChannelRewardInternal(LightningChannel storage channel) private {
        address payable _to = channel.to;

        IPlennyDappFactory factory = contractRegistry.factoryContract();
        uint256 _reward = _blockNumber() - channel.confirmedDate > factory.userChannelRewardPeriod()
        ? channel.rewardAmount.mul(factory.userChannelReward()).mul(_blockNumber() - channelRewardStart[channel.id])
            .div(factory.userChannelRewardPeriod()).div(10000) : 0;
        if (_reward > channel.rewardAmount) {
            _reward = channel.rewardAmount;
        }

        uint256 rewardFee = _reward.mul(factory.userChannelRewardFee()).div(100).div(100);

        totalTimeReward += _reward;
        channel.rewardAmount -= _reward;
        channelRewardStart[channel.id] = _blockNumber();
        emit RewardReleased(_to, _reward);

        IPlennyTreasury treasury = contractRegistry.treasuryContract();

        require(treasury.approve(address(this), rewardFee), "failed");
        contractRegistry.plennyTokenContract().safeTransferFrom(address(treasury),
            contractRegistry.getAddress("PlennyRePLENishment"), rewardFee);

        require(treasury.approve(contractRegistry.getAddress("PlennyCoordinator"), _reward - rewardFee), "failed");
        contractRegistry.plennyTokenContract().safeTransferFrom(address(treasury), _to, _reward - rewardFee);
    }

    /// @notice Collects a reward for a given index/id of a channel
    /// @param  channelIndex channel index/id
    function _collectChannelReward(uint256 channelIndex) private {
        require(channelIndex > 0, "ERR_EMPTY");

        LightningChannel storage channel = channels[channelIndex];
        require(channel.status == 1, "ERR_WRONG_STATE");

        IPlennyOcean ocean = contractRegistry.oceanContract();

        uint256 capacityRequestIndex = ocean.capacityRequestPerChannel(channel.channelPoint);
        if (ocean.capacityRequestsCount() > 0) {
            (,,,,,, string memory channelPoint,) = ocean.capacityRequests(capacityRequestIndex);
            if (stringsEqual(channelPoint, channel.channelPoint)) {
                ocean.collectCapacityRequestReward(capacityRequestIndex, channel.id, channel.confirmedDate);
            }
        }

        _collectChannelRewardInternal(channel);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/* solhint-disable */
interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external payable returns (uint[] memory amounts);

    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external returns (uint[] memory amounts);

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external returns (uint[] memory amounts);

    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external payable returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./ContextUpgradeable.sol";
import "../proxy/Initializable.sol";

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
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
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
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
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
library SafeMathUpgradeable {
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

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/EnumerableSetUpgradeable.sol";
import "../utils/AddressUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using AddressUpgradeable for address;

    struct RoleData {
        EnumerableSetUpgradeable.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

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
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
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
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

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
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

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
    function renounceRole(bytes32 role, address account) public virtual {
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
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../interfaces/IPlennyCoordinator.sol";

/// @title  PlennyCoordinatorStorage
/// @notice Storage contract for the PlennyCoordinator
abstract contract PlennyCoordinatorStorage is IPlennyCoordinator {

    /// @notice total rewards
    uint256 public totalTimeReward;
    /// @notice number of channels
    uint256 public channelsCount;
    /// @notice number of nodes
    uint256 public nodesCount;
    /// @notice channel threshold, in satoshi
    uint256 public override channelRewardThreshold;
    /// @notice total outbound channel capacity, in satoshi
    uint256 public totalOutboundCapacity;
    /// @notice total inbound channel capacity, in satoshi
    uint256 public totalInboundCapacity;

    /// @notice maps index/id with a channel info
    mapping(uint256 => LightningChannel) public channels;
    /// @notice maps index/id with a node info
    mapping(uint256 => LightningNode) public override nodes;

    /// @dev maps the index for a channel point and the user
    mapping(string => mapping(address => uint256)) internal channelIndexPerId;
    /// @dev confirmed channel points per user
    mapping(string => uint256) internal confirmedChannelIndexPerId;
    /// @notice counter per channel status
    mapping(uint => uint256) public channelStatusCount;
    /// @notice tracks when the reward starts for a given channel
    mapping(uint256 => uint256) public override channelRewardStart;

    /// @dev maps node public key per user and index/id
    mapping(string => mapping(address => uint256)) internal nodeIndexPerPubKey;
    /// @dev node counter per user
    mapping(address => uint256) internal nodeOwnerCount;

    /// @notice nodes per user
    mapping(address => uint256[]) public nodesPerAddress;
    /// @notice channels per user
    mapping(address => uint256[]) public channelsPerAddress;

    struct LightningNode {
        uint256 capacity;
        uint256 addedDate;
        string publicKey;
        address validatorAddress;

        uint256 status;

        uint256 verifiedDate;
        address payable to;
    }

    struct LightningChannel {
        uint256 capacity;
        uint256 appliedDate;
        uint256 confirmedDate;

        uint256 status;

        uint256 closureDate;
        address payable to;
        address payable oracleAddress;
        uint256 rewardAmount;

        uint256 id;
        string channelPoint;
        uint256 blockNumber;
        uint256 blockNumberAlt;
    }

    struct NodeInfo {
        uint256 nodeIndex;
        string ownerPublicKey;
        string validatorPublicKey;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "./ExtendedMathLib.sol";

/// @title  RewardLib
/// @notice Library for calculating the reward

library RewardLib {

	using SafeMathUpgradeable for uint256;

	/// @notice Calculate reward for channel capacity
	/// @param  capacity channel capacity
	/// @param  marketplace if reward from marketplace
	/// @param  penaltyValue minimum channel capacity for which a reward is given
	/// @param  makersFixedRewardAmount maker's fixed reward
	/// @param  makersRewardPercentage maker's percentage reward
	/// @param  capacityFixedRewardAmount capacity fixed reward
	/// @param  capacityRewardPercentage capacity percentage reward
	/// @param  treasuryBalance balance of the PlennyTreasury
	/// @return multiplier reward multiplier
	function calculateReward(
		uint256 capacity,
		bool marketplace,
		uint256 penaltyValue,
		uint256 makersFixedRewardAmount,
		uint256 makersRewardPercentage,
		uint256 capacityFixedRewardAmount,
		uint256 capacityRewardPercentage,
		uint256 treasuryBalance
	) internal pure returns (uint multiplier){
		uint256 rewardAmount;

		if (marketplace) {
			if (makersFixedRewardAmount < makersRewardPercentage.mul(treasuryBalance).div(100).div(100000)) {
				rewardAmount = makersFixedRewardAmount;
			} else {
				rewardAmount = makersRewardPercentage.mul(treasuryBalance).div(100).div(100000);
			}
		} else {
			if (capacityFixedRewardAmount < capacityRewardPercentage.mul(treasuryBalance).div(100).div(100000)) {
				rewardAmount = capacityFixedRewardAmount;
			} else {
				rewardAmount = capacityRewardPercentage.mul(treasuryBalance).div(100).div(100000);
			}
		}
		if (capacity >= penaltyValue) {

			uint256 cS = capacity.sub(penaltyValue.sub(uint256(1)));
			uint256 cMax = uint256(15500000);
			uint256 sqrtCS = ExtendedMathLib.sqrt(cS);
			uint256 sqrtCMax = ExtendedMathLib.sqrt(cMax);

			return rewardAmount.mul(cS).mul(sqrtCS).div(cMax).div(sqrtCMax);
		} else {
			return 0;
		}
	}
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";


/// @title  ExtendedMathLib
/// @notice Library for calculating the square root

library ExtendedMathLib {

	using SafeMathUpgradeable for uint256;

	/// @notice Calculates root
	/// @param  y number
	/// @return z calculated number
	function sqrt(uint y) internal pure returns (uint z) {
		if (y > 3) {
			z = y;
			uint x = y / 2 + 1;
			while (x < z) {
				z = x;
				x = (y / x + x) / 2;
			}
		} else if (y != 0) {
			z = 1;
		}
		return z;
	}
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
    function approve(address guy, uint wad) external returns (bool);
    function transferFrom(address src, address dst, uint wad) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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

pragma solidity >=0.6.0 <0.8.0;

interface IPlennyValidatorElection {

    function validators(uint256 electionBlock, address addr) external view returns (bool);

    function latestElectionBlock() external view returns (uint256);

    function getElectedValidatorsCount(uint256 electionBlock) external view returns (uint256);

    function reserveReward(address validator, uint256 amount) external;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

interface IPlennyTreasury {

    function approve(address addr, uint256 amount) external returns (bool);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

interface IPlennyStaking {

    function plennyBalance(address addr) external view returns (uint256);

    function decreasePlennyBalance(address dapp, uint256 amount, address to) external;

    function increasePlennyBalance(address dapp, uint256 amount, address from) external;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

interface IPlennyReward {

    function transfer(address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

interface IPlennyOracleValidator {

    function oracleValidations(uint256, address) external view returns (uint256);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

interface IPlennyOcean {

    function processCapacityRequest(uint256 index) external;

    function closeCapacityRequest(uint256 index, uint256 id, uint256 date) external;

    function collectCapacityRequestReward(uint256 index, uint256 id, uint256 date) external;

    function capacityRequests(uint256 index) external view returns (uint256, uint256, string memory, address payable,
        uint256, uint256, string memory, address payable);

    function capacityRequestPerChannel(string calldata channelPoint) external view returns (uint256 index);

    function makerIndexPerAddress(address addr) external view returns (uint256 index);

    function capacityRequestsCount() external view returns (uint256);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

interface IPlennyLocking {

    function totalVotesLocked() external view returns (uint256);

    function govLockReward() external view returns (uint256);

    function getUserVoteCountAtBlock(address account, uint blockNumber) external view returns (uint256);

    function getTotalVoteCountAtBlock(uint256 blockNumber) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

interface IPlennyLiqMining {

    function totalWeightLocked() external view returns (uint256);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IBasePlennyERC20.sol";

interface IPlennyERC20 is IBasePlennyERC20 {

    function registerTokenOnL2(address l2CustomTokenAddress, uint256 maxSubmissionCost, uint256 maxGas, uint256 gasPriceBid) external;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

interface IPlennyDappFactory {

    function isOracleValidator(address validatorAddress) external view returns (bool);

    // to be removed from factory
    function random() external view returns (uint256);

    function decreaseDelegatedBalance(address dapp, uint256 amount) external;

    function increaseDelegatedBalance(address dapp, uint256 amount) external;

    function updateReputation(address validator, uint256 electionBlock) external;

    function getValidatorsScore() external view returns (uint256[] memory scores, uint256 sum);

    function getDelegatedBalance(address) external view returns (uint256);

    function getDelegators(address) external view returns (address[] memory);

    function pureRandom() external view returns (uint256);

    function validators(uint256 index) external view returns (string memory name, uint256 nodeIndex, string memory nodeIP,
        string memory nodePort, string memory validatorServiceUrl, uint256 revenueShareGlobal, address owner, uint256 reputation);

    function validatorIndexPerAddress(address addr) external view returns (uint256 index);

    function userChannelRewardPeriod() external view returns (uint256);

    function userChannelReward() external view returns (uint256);

    function userChannelRewardFee() external view returns (uint256);

    function makersFixedRewardAmount() external view returns (uint256);

    function makersRewardPercentage() external view returns (uint256);

    function capacityFixedRewardAmount() external view returns (uint256);

    function capacityRewardPercentage() external view returns (uint256);

    function defaultLockingAmount() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

interface IPlennyCoordinator {

    function nodes(uint256 index) external view returns (uint256, uint256, string memory, address, uint256, uint256, address payable);

    function openChannel(string memory _channelPoint, address payable _oracleAddress, bool capacityRequest) external;

    function confirmChannelOpening(uint256 channelIndex, uint256 _channelCapacitySat,
        uint256 channelId, string memory node1PublicKey, string memory node2PublicKey) external;

    function verifyDefaultNode(string calldata publicKey, address payable account) external returns (uint256);

    function closeChannel(uint256 channelIndex) external;

    function channelRewardStart(uint256 index) external view returns (uint256);

    function channelRewardThreshold() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "../interfaces/IWETH.sol";
import "./IPlennyERC20.sol";
import "./IPlennyCoordinator.sol";
import "./IPlennyTreasury.sol";
import "./IPlennyOcean.sol";
import "./IPlennyStaking.sol";
import "./IPlennyValidatorElection.sol";
import "./IPlennyOracleValidator.sol";
import "./IPlennyDappFactory.sol";
import "./IPlennyReward.sol";
import "./IPlennyLiqMining.sol";
import "./IPlennyLocking.sol";
import "../interfaces/IUniswapV2Router02.sol";

interface IContractRegistry {

    function getAddress(bytes32 name) external view returns (address);

    function requireAndGetAddress(bytes32 name) external view returns (address);

    function plennyTokenContract() external view returns (IPlennyERC20);

    function factoryContract() external view returns (IPlennyDappFactory);

    function oceanContract() external view returns (IPlennyOcean);

    function lpContract() external view returns (IUniswapV2Pair);

    function uniswapRouterV2() external view returns (IUniswapV2Router02);

    function treasuryContract() external view returns (IPlennyTreasury);

    function stakingContract() external view returns (IPlennyStaking);

    function coordinatorContract() external view returns (IPlennyCoordinator);

    function validatorElectionContract() external view returns (IPlennyValidatorElection);

    function oracleValidatorContract() external view returns (IPlennyOracleValidator);

    function wrappedETHContract() external view returns (IWETH);

    function rewardContract() external view returns (IPlennyReward);

    function liquidityMiningContract() external view returns (IPlennyLiqMining);

    function lockingContract() external view returns (IPlennyLocking);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IBasePlennyERC20 is IERC20Upgradeable {

    function initialize(address owner, bytes memory _data) external;

    function mint(address addr, uint256 amount) external;

}

/**
* @title Precompiled contract that exists in every Arbitrum chain at address(100), 0x0000000000000000000000000000000000000064. Exposes a variety of system-level functionality.
 */
interface ArbSys {
    /**
    * @notice Get internal version number identifying an ArbOS build
    * @return version number as int
     */
    function arbOSVersion() external pure returns (uint);

    /**
    * @notice Get Arbitrum block number (distinct from L1 block number; Arbitrum genesis block has block number 0)
    * @return block number as int
     */
    function arbBlockNumber() external view returns (uint);

    /**
    * @notice Send given amount of Eth to dest from sender.
    * This is a convenience function, which is equivalent to calling sendTxToL1 with empty calldataForL1.
    * @param destination recipient address on L1
    * @return unique identifier for this L2-to-L1 transaction.
    */
    function withdrawEth(address destination) external payable returns(uint);

    /**
    * @notice Send a transaction to L1
    * @param destination recipient address on L1
    * @param calldataForL1 (optional) calldata for L1 contract call
    * @return a unique identifier for this L2-to-L1 transaction.
    */
    function sendTxToL1(address destination, bytes calldata calldataForL1) external payable returns(uint);



    /**
    * @notice get the number of transactions issued by the given external account or the account sequence number of the given contract
    * @param account target account
    * @return the number of transactions issued by the given external account or the account sequence number of the given contract
    */
    function getTransactionCount(address account) external view returns(uint256);

    /**
    * @notice get the value of target L2 storage slot
    * This function is only callable from address 0 to prevent contracts from being able to call it
    * @param account target account
    * @param index target index of storage slot
    * @return stotage value for the given account at the given index
    */
    function getStorageAt(address account, uint256 index) external view returns (uint256);

    /**
    * @notice check if current call is coming from l1
    * @return true if the caller of this was called directly from L1
    */
    function isTopLevelCall() external view returns (bool);

    event EthWithdrawal(address indexed destAddr, uint amount);

    event L2ToL1Transaction(address caller, address indexed destination, uint indexed uniqueId,
        uint indexed batchNumber, uint indexInBatch,
        uint arbBlockNum, uint ethBlockNum, uint timestamp,
        uint callvalue, bytes data);
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./interfaces/IContractRegistry.sol";

/// @title  Base Plenny upgradeable contract.
/// @notice Used by all Plenny contracts, except PlennyERC20, to allow upgradeable contracts.
abstract contract PlennyBaseUpgradableV2 is AccessControlUpgradeable, ReentrancyGuardUpgradeable, OwnableUpgradeable {

    /// @notice Plenny contract addresses registry
    IContractRegistry public contractRegistry;

    /// @notice Initializes the contract. Can be called only once.
    /// @dev    Upgradable contracts does not have a constructor, so this method is its replacement.
    /// @param  _registry Plenny contracts registry
    function __plennyBaseInit(address _registry) internal initializer {
        require(_registry != address(0x0), "ERR_REG_EMPTY");
        contractRegistry = IContractRegistry(_registry);

        AccessControlUpgradeable.__AccessControl_init();
        OwnableUpgradeable.__Ownable_init();
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @notice Returns current block number
    /// @return uint256 block number
    function _blockNumber() internal view returns (uint256) {
        return block.number;
    }
}