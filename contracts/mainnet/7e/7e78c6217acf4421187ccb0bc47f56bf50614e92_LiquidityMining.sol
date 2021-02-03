/**
 *Submitted for verification at Etherscan.io on 2021-02-02
*/

// File: contracts\liquidity-mining\ILiquidityMiningFactory.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface ILiquidityMiningFactory {

    event ExtensionCloned(address indexed);

    function feePercentageInfo() external view returns (uint256, address);
    function liquidityMiningDefaultExtension() external view returns(address);
    function cloneLiquidityMiningDefaultExtension() external returns(address);
    function getLiquidityFarmTokenCollectionURI() external view returns (string memory);
    function getLiquidityFarmTokenURI() external view returns (string memory);
}

// File: contracts\amm-aggregator\common\AMMData.sol

//SPDX_License_Identifier: MIT
pragma solidity ^0.7.6;

struct LiquidityPoolData {
    address liquidityPoolAddress;
    uint256 amount;
    address tokenAddress;
    bool amountIsLiquidityPool;
    bool involvingETH;
    address receiver;
}

struct SwapData {
    bool enterInETH;
    bool exitInETH;
    address[] liquidityPoolAddresses;
    address[] path;
    address inputToken;
    uint256 amount;
    address receiver;
}

// File: contracts\liquidity-mining\LiquidityMiningData.sol

//SPDX_License_Identifier: MIT
pragma solidity ^0.7.6;


struct LiquidityMiningSetupConfiguration {
    bool add;
    uint256 index;
    LiquidityMiningSetup data;
}

// liquidity mining setup struct
struct LiquidityMiningSetup {
    address ammPlugin; // amm plugin address used for this setup (eg. uniswap amm plugin address).
    uint256 objectId; // items object id for the liquidity pool token.
    address liquidityPoolTokenAddress; // address of the liquidity pool token
    address mainTokenAddress; // eg. buidl address.
    uint256 startBlock; // liquidity mining setup start block (used only if free is false).
    uint256 endBlock; // liquidity mining setup end block (used only if free is false).
    uint256 rewardPerBlock; // liquidity mining setup reward per single block.
    uint256 currentRewardPerBlock; // liquidity mining setup current reward per single block.
    uint256 totalSupply; // current liquidity added in this setup (used only if free is true).
    uint256 lastBlockUpdate; // number of the block where an update was triggered.
    uint256 maximumLiquidity; // maximum liquidity stakeable in the contract (used only if free is false).
    uint256 currentStakedLiquidity; // currently staked liquidity (used only if free is false).
    bool free; // if the setup is a free liquidity mining setup or a locked one.
    uint256 renewTimes; // if the locked setup is renewable or if it's one time (used only if free is false).
    uint256 penaltyFee; // fee paid when the user exits a still active locked liquidity mining setup (used only if free is false).
    bool involvingETH; // if the setup involves ETH or not.
}

// position struct
struct LiquidityMiningPosition {
    address uniqueOwner; // address representing the extension address, address(0) if objectId is populated.
    uint256 setupIndex; // the setup index.
    uint256 setupStartBlock; // liquidity mining setup start block (used only if free is false).
    uint256 setupEndBlock; // liquidity mining setup end block (used only if free is false).
    bool free; // if the setup is a free liquidity mining setup or a locked one.
    // LiquidityPoolData liquidityPoolData; // amm liquidity pool data.
    uint256 liquidityPoolTokenAmount;
    uint256 reward; // position reward.
    uint256 lockedRewardPerBlock; // position locked reward per block.
    uint256 creationBlock; // block when this position was created.
}

// stake data struct
struct LiquidityMiningPositionRequest {
    uint256 setupIndex; // index of the chosen setup.
    uint256 amount; // amount of main token.
    bool amountIsLiquidityPool; //true if user wants to directly share the liquidity pool token amount, false to add liquidity to AMM
    address positionOwner; // position extension or address(0) [msg.sender].
}

// File: contracts\liquidity-mining\ILiquidityMiningExtension.sol

//SPDX_License_Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;


interface ILiquidityMiningExtension {

    function init(bool byMint, address host) external;

    function setHost(address host) external;

    function data() external view returns(address liquidityMiningContract, bool byMint, address host, address rewardTokenAddress);

    function transferTo(uint256 amount, address recipient) external;
    function backToYou(uint256 amount) external payable;

    function setLiquidityMiningSetups(LiquidityMiningSetupConfiguration[] memory liquidityMiningSetups, bool clearPinned, bool setPinned, uint256 pinnedIndex) external;
}

// File: contracts\amm-aggregator\common\IAMM.sol

//SPDX_License_Identifier: MIT
pragma solidity ^0.7.6;
//pragma abicoder v2;


interface IAMM {

    event NewLiquidityPoolAddress(address indexed);

    function info() external view returns(string memory name, uint256 version);

    function data() external view returns(address ethereumAddress, uint256 maxTokensPerLiquidityPool, bool hasUniqueLiquidityPools);

    function balanceOf(address liquidityPoolAddress, address owner) external view returns(uint256, uint256[] memory, address[] memory);

    function byLiquidityPool(address liquidityPoolAddress) external view returns(uint256, uint256[] memory, address[] memory);

    function byTokens(address[] calldata liquidityPoolTokens) external view returns(uint256, uint256[] memory, address, address[] memory);

    function byPercentage(address liquidityPoolAddress, uint256 numerator, uint256 denominator) external view returns (uint256, uint256[] memory, address[] memory);

    function byLiquidityPoolAmount(address liquidityPoolAddress, uint256 liquidityPoolAmount) external view returns(uint256[] memory, address[] memory);

    function byTokenAmount(address liquidityPoolAddress, address tokenAddress, uint256 tokenAmount) external view returns(uint256, uint256[] memory, address[] memory);

    function createLiquidityPoolAndAddLiquidity(address[] calldata tokenAddresses, uint256[] calldata amounts, bool involvingETH, address receiver) external payable returns(uint256, uint256[] memory, address, address[] memory);

    function addLiquidity(LiquidityPoolData calldata data) external payable returns(uint256, uint256[] memory, address[] memory);
    function addLiquidityBatch(LiquidityPoolData[] calldata data) external payable returns(uint256[] memory, uint256[][] memory, address[][] memory);

    function removeLiquidity(LiquidityPoolData calldata data) external returns(uint256, uint256[] memory, address[] memory);
    function removeLiquidityBatch(LiquidityPoolData[] calldata data) external returns(uint256[] memory, uint256[][] memory, address[][] memory);

    function getSwapOutput(address tokenAddress, uint256 tokenAmount, address[] calldata, address[] calldata path) view external returns(uint256[] memory);

    function swapLiquidity(SwapData calldata data) external payable returns(uint256);
    function swapLiquidityBatch(SwapData[] calldata data) external payable returns(uint256[] memory);
}

// File: contracts\liquidity-mining\util\IERC20.sol

// SPDX_License_Identifier: MIT

pragma solidity ^0.7.6;

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function safeApprove(address spender, uint256 amount) external;

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function decimals() external view returns (uint8);
}

// File: contracts\liquidity-mining\util\IEthItemOrchestrator.sol

//SPDX_License_Identifier: MIT

pragma solidity ^0.7.6;

interface IEthItemOrchestrator {
    function createNative(bytes calldata modelInitPayload, string calldata ens)
        external
        returns (address newNativeAddress, bytes memory modelInitCallResponse);
}

// File: contracts\liquidity-mining\util\IERC1155.sol

// SPDX_License_Identifier: MIT

pragma solidity ^0.7.6;

interface IERC1155 {

    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(address account, address operator) external view returns (bool);

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

// File: contracts\liquidity-mining\util\IEthItemInteroperableInterface.sol

// SPDX_License_Identifier: MIT

pragma solidity ^0.7.6;


interface IEthItemInteroperableInterface is IERC20 {

    function mainInterface() external view returns (address);

    function objectId() external view returns (uint256);

    function mint(address owner, uint256 amount) external;

    function burn(address owner, uint256 amount) external;

    function permitNonce(address sender) external view returns(uint256);

    function permit(address owner, address spender, uint value, uint8 v, bytes32 r, bytes32 s) external;

    function interoperableInterfaceVersion() external pure returns(uint256 ethItemInteroperableInterfaceVersion);
}

// File: contracts\liquidity-mining\util\IEthItem.sol

// SPDX_License_Identifier: MIT

pragma solidity ^0.7.6;



interface IEthItem is IERC1155 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function totalSupply(uint256 objectId) external view returns (uint256);

    function name(uint256 objectId) external view returns (string memory);

    function symbol(uint256 objectId) external view returns (string memory);

    function decimals(uint256 objectId) external view returns (uint256);

    function uri(uint256 objectId) external view returns (string memory);

    function mainInterfaceVersion() external pure returns(uint256 ethItemInteroperableVersion);

    function toInteroperableInterfaceAmount(uint256 objectId, uint256 ethItemAmount) external view returns (uint256 interoperableInterfaceAmount);

    function toMainInterfaceAmount(uint256 objectId, uint256 erc20WrapperAmount) external view returns (uint256 mainInterfaceAmount);

    function interoperableInterfaceModel() external view returns (address, uint256);

    function asInteroperable(uint256 objectId) external view returns (IEthItemInteroperableInterface);

    function emitTransferSingleEvent(address sender, address from, address to, uint256 objectId, uint256 amount) external;

    function mint(uint256 amount, string calldata partialUri)
        external
        returns (uint256, address);

    function burn(
        uint256 objectId,
        uint256 amount
    ) external;

    function burnBatch(
        uint256[] calldata objectIds,
        uint256[] calldata amounts
    ) external;
}

// File: contracts\liquidity-mining\util\INativeV1.sol

//SPDX_License_Identifier: MIT

pragma solidity ^0.7.6;


interface INativeV1 is IEthItem {

    function init(string calldata name, string calldata symbol, bool hasDecimals, string calldata collectionUri, address extensionAddress, bytes calldata extensionInitPayload) external returns(bytes memory extensionInitCallResponse);
    function extension() external view returns (address extensionAddress);
    function canMint(address operator) external view returns (bool result);
    function isEditable(uint256 objectId) external view returns (bool result);
    function releaseExtension() external;
    function uri() external view returns (string memory);
    function decimals() external view returns (uint256);
    function mint(uint256 amount, string calldata tokenName, string calldata tokenSymbol, string calldata objectUri, bool editable) external returns (uint256 objectId, address tokenAddress);
    function mint(uint256 amount, string calldata tokenName, string calldata tokenSymbol, string calldata objectUri) external returns (uint256 objectId, address tokenAddress);
    function mint(uint256 objectId, uint256 amount) external;
    function makeReadOnly(uint256 objectId) external;
    function setUri(string calldata newUri) external;
    function setUri(uint256 objectId, string calldata newUri) external;
}

// File: contracts\liquidity-mining\util\ERC1155Receiver.sol

// File: contracts/usd-v2/util/ERC1155Receiver.sol

// SPDX_License_Identifier: MIT

pragma solidity ^0.7.6;

abstract contract ERC1155Receiver {
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor() {
        _registerInterface(_INTERFACE_ID_ERC165);
        _registerInterface(
            ERC1155Receiver(0).onERC1155Received.selector ^
            ERC1155Receiver(0).onERC1155BatchReceived.selector
        );
    }

    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        virtual
        returns(bytes4);

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        virtual
        returns(bytes4);
}

// File: contracts\liquidity-mining\ILiquidityMining.sol

//SPDX_License_Identifier: MIT
pragma solidity ^0.7.6;
//pragma abicoder v2;


interface ILiquidityMining {

    function _rewardTokenAddress() external view returns(address);
    function setups() external view returns (LiquidityMiningSetup[] memory);
    function setLiquidityMiningSetups(LiquidityMiningSetupConfiguration[] memory liquidityMiningSetups, bool clearPinned, bool setPinned, uint256 pinnedIndex) external;
    
}

// File: contracts\liquidity-mining\LiquidityMining.sol

//SPDX_License_Identifier: MIT
pragma solidity ^0.7.6;
//pragma abicoder v2;










contract LiquidityMining is ILiquidityMining, ERC1155Receiver {

    uint256 public constant ONE_HUNDRED = 10000;

    // event that tracks liquidity mining contracts deployed
    event RewardToken(address indexed rewardTokenAddress);
    // new liquidity mining position event
    event Transfer(uint256 indexed positionId, address indexed from, address indexed to);
    // event that tracks involved tokens for this contract
    event SetupToken(address indexed mainToken, address indexed involvedToken);
    // event that tracks farm tokens
    event FarmToken(uint256 indexed objectId, address indexed liquidityPoolToken, uint256 setupIndex, uint256 endBlock);

    // factory address that will create clones of this contract
    address public _factory;
    // address of the extension of this contract
    address public _extension;
    // address of the reward token
    address public override _rewardTokenAddress;
    // liquidity farm token collection
    address public _liquidityFarmTokenCollection;
    // array containing all the currently available liquidity mining setups
    LiquidityMiningSetup[] private _setups;
    // mapping containing all the positions
    mapping(uint256 => LiquidityMiningPosition) public _positions;
    // mapping containing the reward per token per setup per block
    mapping(uint256 => mapping(uint256 => uint256)) public _rewardPerTokenPerSetupPerBlock;
    // mapping containing all the blocks where an update has been triggered
    mapping(uint256 => uint256[]) public _setupUpdateBlocks;
    // mapping containing whether a liquidity mining position has been redeemed or not
    mapping(uint256 => bool) public _positionRedeemed;
    // mapping containing whether a liquidity mining position has been partially reedemed or not
    mapping(uint256 => uint256) public _partiallyRedeemed;
    // mapping containing whether a locked setup has ended or not and has been used for the rebalance
    mapping(uint256 => bool) public _finishedLockedSetups;
    // mapping containing object id to setup index
    mapping(uint256 => uint256) private _objectIdSetup;
    // pinned setup index
    bool public _hasPinned;
    uint256 public _pinnedSetupIndex;

    /** Modifiers. */

    /** @dev byExtension modifier used to check for unauthorized changes. */
    modifier byExtension() {
        require(msg.sender == _extension, "Unauthorized");
        _;
    }

    /** @dev byPositionOwner modifier used to check for unauthorized accesses. */
    modifier byPositionOwner(uint256 positionId) {
        require(_positions[positionId].uniqueOwner == msg.sender, "Not owned");
        _;
    }

    /** Public extension methods. */

    /** @dev initializes the liquidity mining contract.
      * @param extension extension address.
      * @param extensionInitData lm extension init payload.
      * @param orchestrator address of the eth item orchestrator.
      * @param rewardTokenAddress address of the reward token.
      * @param liquidityMiningSetupsBytes array containing all the liquidity mining setups as bytes.
      * @param setPinned true if we're setting a pinned setup during initialization, false otherwise.
      * @param pinnedIndex index of the pinned setup.
      * @return extensionReturnCall result of the extension initialization function, if it was called.  
     */
    function init(address extension, bytes memory extensionInitData, address orchestrator, address rewardTokenAddress, bytes memory liquidityMiningSetupsBytes, bool setPinned, uint256 pinnedIndex) public returns(bytes memory extensionReturnCall) {
        require(_factory == address(0), "Already initialized");
        require((_extension = extension) != address(0), "extension");
        _factory = msg.sender;
        emit RewardToken(_rewardTokenAddress = rewardTokenAddress);
        if (keccak256(extensionInitData) != keccak256("")) {
            extensionReturnCall = _call(_extension, extensionInitData);
        }
        (_liquidityFarmTokenCollection,) = IEthItemOrchestrator(orchestrator).createNative(abi.encodeWithSignature("init(string,string,bool,string,address,bytes)", "Covenants Farming", "cFARM", false, ILiquidityMiningFactory(_factory).getLiquidityFarmTokenCollectionURI(), address(this), ""), "");
        _initLiquidityMiningSetups(liquidityMiningSetupsBytes, setPinned, pinnedIndex);
    }

    /** @dev allows this contract to receive eth. */
    receive() external payable { }

    /** @dev returns the liquidity mining setups.
      * @return array containing all the liquidity mining setups.
     */
    function setups() view public override returns (LiquidityMiningSetup[] memory) {
        return _setups;
    }

    /** @dev returns the liquidity mining position associated with the input id.
      * @param id liquidity mining position id.
      * @return liquidity mining position stored at the given id.
     */
    function position(uint256 id) public view returns(LiquidityMiningPosition memory) {
        return _positions[id];
    }

    /** @dev returns the reward per token for the setup index at the given block number.
      * @param setupIndex index of the setup.
      * @param blockNumber block that wants to be inspected.
      * @return reward per token.
     */
    function rewardPerToken(uint256 setupIndex, uint256 blockNumber) public view returns(uint256) {
        return _rewardPerTokenPerSetupPerBlock[setupIndex][blockNumber];
    }

    /** @dev allows the extension to set the liquidity mining setups.
      * @param liquidityMiningSetups liquidity mining setups to set.
      * @param setPinned if we're updating the pinned setup or not.
      * @param pinnedIndex new pinned setup index.
      */
    function setLiquidityMiningSetups(LiquidityMiningSetupConfiguration[] memory liquidityMiningSetups, bool clearPinned, bool setPinned, uint256 pinnedIndex) public override byExtension {
        for (uint256 i = 0; i < liquidityMiningSetups.length; i++) {
            _setOrAddLiquidityMiningSetup(liquidityMiningSetups[i].data, liquidityMiningSetups[i].add, liquidityMiningSetups[i].index);
        }
        _pinnedSetup(clearPinned, setPinned, pinnedIndex);
        // rebalance the pinned setup
        rebalancePinnedSetup();
    }

    /** Public methods. */

    /** @dev function called by external users to open a new liquidity mining position.
      * @param request Liquidity Mining input data.
    */
    function openPosition(LiquidityMiningPositionRequest memory request) public payable returns(uint256 positionId) {
        require(request.setupIndex < _setups.length, "Invalid setup index");
        // retrieve the setup
        LiquidityMiningSetup storage chosenSetup = _setups[request.setupIndex];
        require(chosenSetup.free || (block.number >= chosenSetup.startBlock && block.number <= chosenSetup.endBlock), "Setup not available");
        (IAMM amm, uint256 liquidityPoolAmount, uint256 mainTokenAmount, bool involvingETH) = _transferToMeAndCheckAllowance(chosenSetup, request);
        // retrieve the unique owner
        address uniqueOwner = (request.positionOwner != address(0)) ? request.positionOwner : msg.sender;
        LiquidityPoolData memory liquidityPoolData = LiquidityPoolData(
            chosenSetup.liquidityPoolTokenAddress,
            request.amountIsLiquidityPool ? liquidityPoolAmount : mainTokenAmount,
            chosenSetup.mainTokenAddress,
            request.amountIsLiquidityPool,
            involvingETH,
            address(this)
        );

        if (!liquidityPoolData.amountIsLiquidityPool) {
            // retrieve the poolTokenAmount from the amm
            if(liquidityPoolData.involvingETH) {
                (liquidityPoolData.amount,,) = amm.addLiquidity{value : msg.value}(liquidityPoolData);
            } else {
                (liquidityPoolData.amount,,) = amm.addLiquidity(liquidityPoolData);
            }
            liquidityPoolData.amountIsLiquidityPool = true;
        } else {
            require(msg.value == 0, "ETH not involved");
        }
        // create the position id
        positionId = uint256(keccak256(abi.encode(uniqueOwner, request.setupIndex, block.number)));
        // calculate the reward
        uint256 reward;
        uint256 lockedRewardPerBlock;
        if (!chosenSetup.free) {
            (reward, lockedRewardPerBlock) = calculateLockedLiquidityMiningSetupReward(request.setupIndex, mainTokenAmount, false, 0);
            require(reward > 0 && lockedRewardPerBlock > 0, "Insufficient staked amount");
            ILiquidityMiningExtension(_extension).transferTo(reward, address(this));
            chosenSetup.currentRewardPerBlock += lockedRewardPerBlock;
            chosenSetup.currentStakedLiquidity += mainTokenAmount;
            _mintLiquidity(uniqueOwner, liquidityPoolData.amount, request.setupIndex);
        }
        _positions[positionId] = LiquidityMiningPosition({
            uniqueOwner: uniqueOwner,
            setupIndex : request.setupIndex,
            setupStartBlock : chosenSetup.startBlock,
            setupEndBlock : chosenSetup.endBlock,
            free : chosenSetup.free,
            liquidityPoolTokenAmount: liquidityPoolData.amount,
            reward: reward,
            lockedRewardPerBlock: lockedRewardPerBlock,
            creationBlock: block.number
        });
        if (chosenSetup.free) {
            _rebalanceRewardPerToken(request.setupIndex, liquidityPoolData.amount, false);
        } else {
            if (_hasPinned && _setups[_pinnedSetupIndex].free) {
                _rebalanceRewardPerBlock(_pinnedSetupIndex, (chosenSetup.rewardPerBlock * (mainTokenAmount * 1e18 / chosenSetup.maximumLiquidity)) / 1e18, false);
            }
        }

        emit Transfer(positionId, address(0), uniqueOwner);
    }

    /** @dev adds liquidity to the liquidity mining position at the given positionId using the given lpData.
      * @param positionId id of the liquidity mining position.
      * @param request update position request.
      */
    function addLiquidity(uint256 positionId, LiquidityMiningPositionRequest memory request) public payable byPositionOwner(positionId) {
        // retrieve liquidity mining position
        LiquidityMiningPosition storage liquidityMiningPosition = _positions[positionId];
        // check if liquidity mining position is valid
        require(liquidityMiningPosition.free || liquidityMiningPosition.setupEndBlock >= block.number, "Invalid add liquidity");
        LiquidityMiningSetup memory chosenSetup = _setups[liquidityMiningPosition.setupIndex];
        (IAMM amm, uint256 liquidityPoolAmount, uint256 mainTokenAmount, bool involvingETH) = _transferToMeAndCheckAllowance(chosenSetup, request);

        LiquidityPoolData memory liquidityPoolData = LiquidityPoolData(
            chosenSetup.liquidityPoolTokenAddress,
            request.amountIsLiquidityPool ? liquidityPoolAmount : mainTokenAmount,
            chosenSetup.mainTokenAddress,
            request.amountIsLiquidityPool,
            involvingETH,
            address(this)
        );

        if (!liquidityPoolData.amountIsLiquidityPool) {
            // retrieve the poolTokenAmount from the amm
            if(liquidityPoolData.involvingETH) {
                (liquidityPoolData.amount,,) = amm.addLiquidity{value : msg.value}(liquidityPoolData);
            } else {
                (liquidityPoolData.amount,,) = amm.addLiquidity(liquidityPoolData);
            }
            liquidityPoolData.amountIsLiquidityPool = true;
        } else {
            require(msg.value == 0, "ETH not involved");
        }
        // if free we must rebalance and snapshot the state
        if (liquidityMiningPosition.free) {
            // rebalance the reward per token
            _rebalanceRewardPerToken(liquidityMiningPosition.setupIndex, 0, false);
        } else {
            // mint more item corresponding to the new liquidity
            _mintLiquidity(liquidityMiningPosition.uniqueOwner, liquidityPoolData.amount, liquidityMiningPosition.setupIndex);
        }
        // calculate reward before adding liquidity pool data to the position
        (uint256 newReward, uint256 newLockedRewardPerBlock) = liquidityMiningPosition.free ? (calculateFreeLiquidityMiningSetupReward(positionId, false), 0) : calculateLockedLiquidityMiningSetupReward(liquidityMiningPosition.setupIndex, mainTokenAmount, false, 0);
        // update the liquidity pool token amount
        liquidityMiningPosition.liquidityPoolTokenAmount += liquidityPoolData.amount;
        if (!liquidityMiningPosition.free) {
            // transfer the reward in advance to this contract
            ILiquidityMiningExtension(_extension).transferTo(newReward, address(this));
            // update the position reward, locked reward per block and the liquidity pool token amount
            liquidityMiningPosition.reward += newReward;
            liquidityMiningPosition.lockedRewardPerBlock += newLockedRewardPerBlock;
            _setups[liquidityMiningPosition.setupIndex].currentRewardPerBlock += newLockedRewardPerBlock;
            // rebalance the pinned reward per block
            if (_hasPinned && _setups[_pinnedSetupIndex].free) {
                _rebalanceRewardPerBlock(_pinnedSetupIndex, (chosenSetup.rewardPerBlock * (mainTokenAmount * 1e18 / chosenSetup.maximumLiquidity)) / 1e18, false);
            }
        } else {
            if (newReward > 0) {
                // transfer the reward
                ILiquidityMiningExtension(_extension).transferTo(newReward, msg.sender);
            }
            // update the creation block to avoid blocks before the new add liquidity
            liquidityMiningPosition.creationBlock = block.number;
            // rebalance the reward per token
            _rebalanceRewardPerToken(liquidityMiningPosition.setupIndex, liquidityPoolData.amount, false);
        }
    }

    /** @dev this function allows a wallet to update the extension of the given liquidity mining position.
      * @param to address of the new extension.
      * @param positionId id of the liquidity mining position.
     */
    function transfer(address to, uint256 positionId) public byPositionOwner(positionId) {
        // retrieve liquidity mining position
        LiquidityMiningPosition storage liquidityMiningPosition = _positions[positionId];
        require(
            to != address(0) &&
            liquidityMiningPosition.setupStartBlock == _setups[liquidityMiningPosition.setupIndex].startBlock &&
            liquidityMiningPosition.setupEndBlock == _setups[liquidityMiningPosition.setupIndex].endBlock,
            "Invalid position"
        );
        liquidityMiningPosition.uniqueOwner = to;
        emit Transfer(positionId, msg.sender, to);
    }

    /** @dev this function allows a extension to unlock its locked liquidity mining position receiving back its tokens or the lpt amount.
      * @param positionId liquidity mining position id.
      * @param unwrapPair if the caller wants to unwrap his pair from the liquidity pool token or not.
      */
    function unlock(uint256 positionId, bool unwrapPair) public payable byPositionOwner(positionId) {
        // retrieve liquidity mining position
        LiquidityMiningPosition storage liquidityMiningPosition = _positions[positionId];
        // require(liquidityMiningPosition.liquidityPoolData.liquidityPoolAddress != address(0), "Invalid position");
        require(!liquidityMiningPosition.free && liquidityMiningPosition.setupEndBlock >= block.number, "Invalid unlock");
        require(!_positionRedeemed[positionId], "Already redeemed");
        uint256 rewardToGiveBack = _partiallyRedeemed[positionId];
        // must pay a penalty fee
        rewardToGiveBack += _setups[liquidityMiningPosition.setupIndex].penaltyFee == 0 ? 0 : (liquidityMiningPosition.reward * ((_setups[liquidityMiningPosition.setupIndex].penaltyFee * 1e18) / ONE_HUNDRED) / 1e18);
        if (rewardToGiveBack > 0) {
            // has partially redeemed, must pay a penalty fee
            if(_rewardTokenAddress != address(0)) {
                _safeTransferFrom(_rewardTokenAddress, msg.sender, address(this), rewardToGiveBack);
                _safeApprove(_rewardTokenAddress, _extension, rewardToGiveBack);
                ILiquidityMiningExtension(_extension).backToYou(rewardToGiveBack);
            } else {
                require(msg.value == rewardToGiveBack, "Invalid sent amount");
                ILiquidityMiningExtension(_extension).backToYou{value : rewardToGiveBack}(rewardToGiveBack);
            }
        }
        _burnLiquidity(_setups[liquidityMiningPosition.setupIndex].objectId, liquidityMiningPosition.liquidityPoolTokenAmount);
        _removeLiquidity(positionId, _setups[liquidityMiningPosition.setupIndex].objectId, liquidityMiningPosition.setupIndex, unwrapPair, liquidityMiningPosition.liquidityPoolTokenAmount, true);
    }

    /** @dev this function allows a user to withdraw the reward.
      * @param positionId liquidity mining position id.
     */
    function withdrawReward(uint256 positionId) public byPositionOwner(positionId) {
        // retrieve liquidity mining position
        LiquidityMiningPosition storage liquidityMiningPosition = _positions[positionId];
        // check if liquidity mining position is valid
        // require(liquidityMiningPosition.liquidityPoolData.liquidityPoolAddress != address(0), "Invalid position");
        uint256 reward = liquidityMiningPosition.reward;
        if (!liquidityMiningPosition.free) {
            // check if reward is available
            require(liquidityMiningPosition.reward > 0, "No reward");
            // check if it's a partial reward or not
            if (liquidityMiningPosition.setupEndBlock >= block.number) {
            // calculate the reward from the liquidity mining position creation block to the current block multiplied by the reward per block
                (reward,) = calculateLockedLiquidityMiningSetupReward(0, 0, true, positionId);
            }
            require(reward <= liquidityMiningPosition.reward, "Reward is bigger than expected");
            // remove the partial reward from the liquidity mining position total reward
            liquidityMiningPosition.reward = liquidityMiningPosition.reward - reward;
        } else {
            // rebalance setup
            _rebalanceRewardPerToken(liquidityMiningPosition.setupIndex, 0, true);
            reward = calculateFreeLiquidityMiningSetupReward(positionId, false);
            require(reward > 0, "No reward?");
        }
        // transfer the reward
        if (reward > 0) {
            if(!liquidityMiningPosition.free) {
                _rewardTokenAddress != address(0) ? _safeTransfer(_rewardTokenAddress, liquidityMiningPosition.uniqueOwner, reward) : payable(liquidityMiningPosition.uniqueOwner).transfer(reward);
            } else {
                ILiquidityMiningExtension(_extension).transferTo(reward, liquidityMiningPosition.uniqueOwner);
            }
        }
        if (liquidityMiningPosition.free) {
            // update the creation block for the free position
            liquidityMiningPosition.creationBlock = block.number;
        } else {
            if (liquidityMiningPosition.reward == 0) {
                // close the locked position after withdrawing all the reward
                _positions[positionId] = _positions[0x0];
            } else {
                // set the partially redeemed amount
                _partiallyRedeemed[positionId] = reward;
            }
        }
    }

    /** @dev allows the withdrawal of the liquidity from a position or from the item tokens.
      * @param positionId id of the position.
      * @param objectId object id of the item token to burn.
      * @param unwrapPair if the liquidity pool tokens will be unwrapped or not.
      * @param removedLiquidity amount of liquidity to remove.
     */
    function withdrawLiquidity(uint256 positionId, uint256 objectId, bool unwrapPair, uint256 removedLiquidity) public {
        // retrieve liquidity mining position
        LiquidityMiningPosition storage liquidityMiningPosition = _positions[positionId];
        uint256 setupIndex = objectId != 0 ? getObjectIdSetupIndex(objectId) : liquidityMiningPosition.setupIndex;
        require(positionId != 0 || (_setups[setupIndex].objectId == objectId || _finishedLockedSetups[objectId]), "Invalid position");
        // current owned liquidity
        require(
            (
                liquidityMiningPosition.free && 
                removedLiquidity <= liquidityMiningPosition.liquidityPoolTokenAmount &&
                !_positionRedeemed[positionId]
                // && liquidityMiningPosition.liquidityPoolData.liquidityPoolAddress != address(0)
            ) || (positionId == 0 && INativeV1(_liquidityFarmTokenCollection).balanceOf(msg.sender, objectId) >= removedLiquidity), "Invalid withdraw");
        // check if liquidity mining position is valid
        require(liquidityMiningPosition.free || (_setups[setupIndex].endBlock <= block.number || _finishedLockedSetups[objectId]), "Invalid withdraw");
        // burn the liquidity in the locked setup
        if (positionId == 0) {
            _burnLiquidity(objectId, removedLiquidity);
        } else {
            _positionRedeemed[positionId] = removedLiquidity == liquidityMiningPosition.liquidityPoolTokenAmount;
            withdrawReward(positionId);
            _setups[liquidityMiningPosition.setupIndex].totalSupply -= removedLiquidity;
        }
        _removeLiquidity(positionId, objectId, setupIndex, unwrapPair, removedLiquidity, false);
    }

    /** @dev this function allows any user to rebalance the pinned setup. */
    function rebalancePinnedSetup() public {
        // if (!_hasPinned || !_setups[_pinnedSetupIndex].free) return;
        uint256 amount;
        for (uint256 i = 0; i < _setups.length; i++) {
            if (_setups[i].free) continue;
            // this is a locked setup that it's currently active or it's a new one
            if (block.number >= _setups[i].startBlock && block.number < _setups[i].endBlock) {
                // the amount to add to the pinned is given by the difference between the reward per block and currently locked one
                // in the case of a new setup, the currentRewardPerBlock is 0 so the difference is the whole rewardPerBlock
                amount += _setups[i].rewardPerBlock - ((_setups[i].rewardPerBlock * (_setups[i].currentStakedLiquidity * 1e18 / _setups[i].maximumLiquidity)) / 1e18);
            // this is a locked setup that has expired
            } else if (block.number >= _setups[i].endBlock) {
                _finishedLockedSetups[_setups[i].objectId] = true;
                // check if the setup is renewable
                if (_setups[i].renewTimes > 0) {
                    _setups[i].renewTimes -= 1;
                    // if it is, we renew it and add the reward per block
                    _renewSetup(i);
                    amount += _setups[i].rewardPerBlock;
                }
            }
        }
        if (_hasPinned && _setups[_pinnedSetupIndex].free) {
            _setups[_pinnedSetupIndex].rewardPerBlock = _setups[_pinnedSetupIndex].currentRewardPerBlock;
            _rebalanceRewardPerBlock(_pinnedSetupIndex, amount, true);
        }
    }

    /** @dev function used to calculate the reward in a locked liquidity mining setup.
      * @param setupIndex liquidity mining setup index.
      * @param mainTokenAmount amount of main token.
      * @param isPartial if we're calculating a partial reward.
      * @param positionId id of the position (used for the partial reward).
      * @return reward total reward for the liquidity mining position extension.
      * @return relativeRewardPerBlock returned for the pinned free setup balancing.
     */
    function calculateLockedLiquidityMiningSetupReward(uint256 setupIndex, uint256 mainTokenAmount, bool isPartial, uint256 positionId) public view returns(uint256 reward, uint256 relativeRewardPerBlock) {
        if (isPartial) {
            // retrieve the position
            LiquidityMiningPosition memory liquidityMiningPosition = _positions[positionId];
            // calculate the reward
            reward = (block.number >= liquidityMiningPosition.setupEndBlock) ? liquidityMiningPosition.reward : ((block.number - liquidityMiningPosition.creationBlock) * liquidityMiningPosition.lockedRewardPerBlock);
        } else {
            LiquidityMiningSetup memory setup = _setups[setupIndex];
            // check if main token amount is less than the stakeable liquidity
            require(mainTokenAmount <= setup.maximumLiquidity - setup.currentStakedLiquidity, "Invalid liquidity");
            uint256 remainingBlocks = block.number > setup.endBlock ? 0 : setup.endBlock - block.number;
            // get amount of remaining blocks
            require(remainingBlocks > 0, "Setup ended");
            // get total reward still available (= 0 if rewardPerBlock = 0)
            require(setup.rewardPerBlock * remainingBlocks > 0, "No rewards");
            // calculate relativeRewardPerBlock
            relativeRewardPerBlock = (setup.rewardPerBlock * ((mainTokenAmount * 1e18) / setup.maximumLiquidity)) / 1e18;
            // check if rewardPerBlock is greater than 0
            require(relativeRewardPerBlock > 0, "Invalid rpb");
            // calculate reward by multiplying relative reward per block and the remaining blocks
            reward = relativeRewardPerBlock * remainingBlocks;
            // check if the reward is still available
        }
    }

    /** @dev function used to calculate the reward in a free liquidity mining setup.
      * @param positionId liquidity mining position id.
      * @return reward total reward for the liquidity mining position extension.
     */
    function calculateFreeLiquidityMiningSetupReward(uint256 positionId, bool isExt) public view returns(uint256 reward) {
        LiquidityMiningPosition memory liquidityMiningPosition = _positions[positionId];
        for (uint256 i = 0; i < _setupUpdateBlocks[liquidityMiningPosition.setupIndex].length; i++) {
            if (liquidityMiningPosition.creationBlock < _setupUpdateBlocks[liquidityMiningPosition.setupIndex][i]) {
                reward += (_rewardPerTokenPerSetupPerBlock[liquidityMiningPosition.setupIndex][_setupUpdateBlocks[liquidityMiningPosition.setupIndex][i]] * liquidityMiningPosition.liquidityPoolTokenAmount) / 1e18;
            }
        }
        if (isExt) {
            uint256 rpt = (((block.number - _setups[liquidityMiningPosition.setupIndex].lastBlockUpdate + 1) * _setups[liquidityMiningPosition.setupIndex].rewardPerBlock) * 1e18) / _setups[liquidityMiningPosition.setupIndex].totalSupply;
            reward += (rpt * liquidityMiningPosition.liquidityPoolTokenAmount) / 1e18;
        }
    }

    /** @dev returns the setup index for the given objectId.
      * @param objectId farm token object id.
      * @return setupIndex index of the setup.
     */
    function getObjectIdSetupIndex(uint256 objectId) public view returns (uint256 setupIndex) {
        require(address(INativeV1(_liquidityFarmTokenCollection).asInteroperable(objectId)) != address(0), "Invalid objectId");
        setupIndex = _objectIdSetup[objectId];
    }

    /** Private methods. */

    /** @dev initializes the liquidity mining setups during the contract initialization.
      * @param liquidityMiningSetupsBytes array of liquidity mining setups as bytes.
      * @param setPinned if we are setting the pinned setup or not.
      * @param pinnedIndex the pinned setup index.
     */
    function _initLiquidityMiningSetups(bytes memory liquidityMiningSetupsBytes, bool setPinned, uint256 pinnedIndex) private {
        LiquidityMiningSetup[] memory liquidityMiningSetups = abi.decode(liquidityMiningSetupsBytes, (LiquidityMiningSetup[]));
        require(liquidityMiningSetups.length > 0, "Invalid length");
        for(uint256 i = 0; i < liquidityMiningSetups.length; i++) {
            _setOrAddLiquidityMiningSetup(liquidityMiningSetups[i], true, 0);
        }
        _pinnedSetup(false, setPinned, pinnedIndex);
        // rebalance the pinned setup
        rebalancePinnedSetup();
    }

    /** @dev helper method that given a liquidity mining setup adds it to the _setups array or updates it.
      * @param data new or updated liquidity mining setup.
      * @param add if we are adding the setup or updating it.
      * @param index liquidity mining setup index.
     */
    function _setOrAddLiquidityMiningSetup(LiquidityMiningSetup memory data, bool add, uint256 index) private {
        LiquidityMiningSetup memory liquidityMiningSetup = add ? data : _setups[index];
        require(
            data.ammPlugin != address(0) &&
            (
                (data.free && data.liquidityPoolTokenAddress != address(0)) ||
                (!data.free && data.liquidityPoolTokenAddress != address(0) && data.startBlock < data.endBlock)
            ),
            "Invalid setup configuration"
        );
        require(!add || liquidityMiningSetup.ammPlugin != address(0), "Invalid setup index");
        address mainTokenAddress = add ? data.mainTokenAddress : liquidityMiningSetup.mainTokenAddress;
        address ammPlugin = add ? data.ammPlugin : liquidityMiningSetup.ammPlugin;
        (,,address[] memory tokenAddresses) = IAMM(ammPlugin).byLiquidityPool(data.liquidityPoolTokenAddress);
        bool found = false;
        for(uint256 z = 0; z < tokenAddresses.length; z++) {
            if(tokenAddresses[z] == mainTokenAddress) {
                found = true;
            } else {
                emit SetupToken(mainTokenAddress, tokenAddresses[z]);
            }
        }
        require(found, "No main token");
        if (add) {
            data.totalSupply = 0;
            data.currentRewardPerBlock = data.free ? data.rewardPerBlock : 0;
            // adding new liquidity mining setup
            _setups.push(data);
        } else {
            if (liquidityMiningSetup.free) {
                // update free liquidity mining setup reward per block
                if (data.rewardPerBlock - liquidityMiningSetup.rewardPerBlock < 0) {
                    _rebalanceRewardPerBlock(index, liquidityMiningSetup.rewardPerBlock - data.rewardPerBlock, false);
                } else {
                    _rebalanceRewardPerBlock(index, data.rewardPerBlock - liquidityMiningSetup.rewardPerBlock, true);
                }
                _setups[index].rewardPerBlock = data.rewardPerBlock;
                _setups[index].currentRewardPerBlock = data.rewardPerBlock;
            } else {
                // update locked liquidity mining setup
                _setups[index].rewardPerBlock = data.rewardPerBlock > 0 ? data.rewardPerBlock : _setups[index].rewardPerBlock;
                _setups[index].renewTimes = data.renewTimes;
            }
        }
    }

    /** @dev helper function used to update or set the pinned free setup.
      * @param clearPinned if we're clearing the pinned setup or not.
      * @param setPinned if we're setting the pinned setup or not.
      * @param pinnedIndex new pinned setup index.
     */
    function _pinnedSetup(bool clearPinned, bool setPinned, uint256 pinnedIndex) private {
        // if we're clearing the pinned setup we must also remove the excess reward per block
        if (clearPinned && _hasPinned) {
            _hasPinned = false;
            _rebalanceRewardPerToken(_pinnedSetupIndex, 0, false);
            _setups[_pinnedSetupIndex].rewardPerBlock = _setups[_pinnedSetupIndex].currentRewardPerBlock;
        }
        // check if we're updating the pinned setup
        if (!clearPinned && setPinned) {
            require(_setups[pinnedIndex].free, "Invalid pinned free setup");
            uint256 oldBalancedRewardPerBlock;
            // check if we already have a free pinned setup
            if (_hasPinned && _setups[_pinnedSetupIndex].free) {
                // calculate the old balanced reward by subtracting from the current pinned reward per block the starting reward per block (aka currentRewardPerBlock)
                oldBalancedRewardPerBlock = _setups[_pinnedSetupIndex].rewardPerBlock - _setups[_pinnedSetupIndex].currentRewardPerBlock;
                // remove it from the current pinned setup
                _rebalanceRewardPerBlock(_pinnedSetupIndex, oldBalancedRewardPerBlock, false);
            }
            // update pinned setup index
            _hasPinned = true;
            _pinnedSetupIndex = pinnedIndex;
        }
    }

    /** @dev this function performs the transfer of the tokens that will be staked, interacting with the AMM plugin.
      * @param setup the chosen setup.
      * @param request new open position request.
      * @return amm AMM plugin interface.
      * @return liquidityPoolAmount amount of liquidity pool token.
      * @return mainTokenAmount amount of main token staked.
      * @return involvingETH if the inputed flag is consistent.
     */
    function _transferToMeAndCheckAllowance(LiquidityMiningSetup memory setup, LiquidityMiningPositionRequest memory request) private returns(IAMM amm, uint256 liquidityPoolAmount, uint256 mainTokenAmount, bool involvingETH) {
        require(request.amount > 0, "No amount");
        involvingETH = request.amountIsLiquidityPool && setup.involvingETH;
        // retrieve the values
        amm = IAMM(setup.ammPlugin);
        liquidityPoolAmount = request.amountIsLiquidityPool ? request.amount : 0;
        mainTokenAmount = request.amountIsLiquidityPool ? 0 : request.amount;
        address[] memory tokens;
        uint256[] memory tokenAmounts;
        // if liquidity pool token amount is provided, the position is opened by liquidity pool token amount
        if(request.amountIsLiquidityPool) {
            _safeTransferFrom(setup.liquidityPoolTokenAddress, msg.sender, address(this), liquidityPoolAmount);
            (tokenAmounts, tokens) = amm.byLiquidityPoolAmount(setup.liquidityPoolTokenAddress, liquidityPoolAmount);
        } else {
            // else it is opened by the tokens amounts
            (liquidityPoolAmount, tokenAmounts, tokens) = amm.byTokenAmount(setup.liquidityPoolTokenAddress, setup.mainTokenAddress, mainTokenAmount);
        }

        // check if the eth is involved in the request
        address ethAddress = address(0); 
        if(setup.involvingETH) {
            (ethAddress,,) = amm.data();
        }
        // iterate the tokens and perform the transferFrom and the approve
        for(uint256 i = 0; i < tokens.length; i++) {
            if(tokens[i] == setup.mainTokenAddress) {
                mainTokenAmount = tokenAmounts[i];
                if(request.amountIsLiquidityPool) {
                    break;
                }
            }
            if(request.amountIsLiquidityPool) {
                continue;
            }
            if(setup.involvingETH && ethAddress == tokens[i]) {
                involvingETH = true;
                require(msg.value == tokenAmounts[i], "Incorrect eth value");
            } else {
                _safeTransferFrom(tokens[i], msg.sender, address(this), tokenAmounts[i]);
                _safeApprove(tokens[i], setup.ammPlugin, tokenAmounts[i]);
            }
        }
    }

    /** @dev mints a new PositionToken inside the collection for the given wallet.
      * @param uniqueOwner liquidityMiningPosition token extension.
      * @param amount amount of to mint for a farm token.
      * @param setupIndex index of the setup.
      * @return objectId new liquidityMiningPosition token object id.
     */
    function _mintLiquidity(address uniqueOwner, uint256 amount, uint256 setupIndex) private returns(uint256 objectId) {
        if (_setups[setupIndex].objectId == 0) {
            (objectId,) = INativeV1(_liquidityFarmTokenCollection).mint(amount, string(abi.encodePacked("Farming LP ", _toString(_setups[setupIndex].liquidityPoolTokenAddress))), "fLP", ILiquidityMiningFactory(_factory).getLiquidityFarmTokenURI(), true);
            emit FarmToken(objectId, _setups[setupIndex].liquidityPoolTokenAddress, setupIndex, _setups[setupIndex].endBlock);
            _objectIdSetup[objectId] = setupIndex;
            _setups[setupIndex].objectId = objectId;
        } else {
            INativeV1(_liquidityFarmTokenCollection).mint(_setups[setupIndex].objectId, amount);
        }
        INativeV1(_liquidityFarmTokenCollection).safeTransferFrom(address(this), uniqueOwner, _setups[setupIndex].objectId, amount, "");
    }

    function _toString(address _addr) internal pure returns(string memory) {
        bytes32 value = bytes32(uint256(_addr));
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(42);
        str[0] = '0';
        str[1] = 'x';
        for (uint i = 0; i < 20; i++) {
            str[2+i*2] = alphabet[uint(uint8(value[i + 12] >> 4))];
            str[3+i*2] = alphabet[uint(uint8(value[i + 12] & 0x0f))];
        }
        return string(str);
    }

    /** @dev burns a farm token from the collection.
      * @param objectId object id where to burn liquidity.
      * @param amount amount of liquidity to burn.
      */
    function _burnLiquidity(uint256 objectId, uint256 amount) private {
        INativeV1 tokenCollection = INativeV1(_liquidityFarmTokenCollection);
        // transfer the liquidity mining farm token to this contract
        tokenCollection.safeTransferFrom(msg.sender, address(this), objectId, amount, "");
        // burn the liquidity mining farm token
        tokenCollection.burn(objectId, amount);
    }

    /** @dev helper function used to remove liquidity from a free position or to burn item liquidity tokens and retrieve their content.
      * @param positionId id of the position.
      * @param objectId object id related to the item liquidity tokens to burn.
      * @param setupIndex index of the setup related to the item liquidity tokens.
      * @param unwrapPair whether to unwrap the liquidity pool tokens or not.
      * @param isUnlock if we're removing liquidity from an unlock method or not.
     */
    function _removeLiquidity(uint256 positionId, uint256 objectId, uint256 setupIndex, bool unwrapPair, uint256 removedLiquidity, bool isUnlock) private {
        LiquidityMiningPosition storage liquidityMiningPosition = _positions[positionId];
        LiquidityPoolData memory lpData = LiquidityPoolData(
            _setups[setupIndex].liquidityPoolTokenAddress,
            removedLiquidity,
            _setups[setupIndex].mainTokenAddress,
            true,
            _setups[setupIndex].involvingETH,
            msg.sender
        );
        uint256 remainingLiquidity;
        // we are removing liquidity using the setup items
        if (positionId != 0) {
            // update the setup index
            setupIndex = liquidityMiningPosition.setupIndex;
            remainingLiquidity = liquidityMiningPosition.liquidityPoolTokenAmount - removedLiquidity;
        }
        // retrieve fee stuff
        (uint256 exitFeePercentage, address exitFeeWallet) = ILiquidityMiningFactory(_factory).feePercentageInfo();
        // pay the fees!
        if (exitFeePercentage > 0) {
            uint256 fee = (lpData.amount * ((exitFeePercentage * 1e18) / ONE_HUNDRED)) / 1e18;
            _safeTransfer(_setups[setupIndex].liquidityPoolTokenAddress, exitFeeWallet, fee);
            lpData.amount = lpData.amount - fee;
        }
        // check if the user wants to unwrap its pair or not
        if (unwrapPair) {
            // remove liquidity using AMM
            address ammPlugin = _setups[setupIndex].ammPlugin;
            _safeApprove(lpData.liquidityPoolAddress, ammPlugin, lpData.amount);
            (, uint256[] memory amounts,) = IAMM(ammPlugin).removeLiquidity(lpData);
            require(amounts[0] > 0 && amounts[1] > 0, "Insufficient amount");
            if (isUnlock) {
                _setups[setupIndex].currentStakedLiquidity -= amounts[0];
            }
        } else {
            // send back the liquidity pool token amount without the fee
            _safeTransfer(lpData.liquidityPoolAddress, lpData.receiver, lpData.amount);
        }
        // rebalance the setup if not free
        if (!_setups[setupIndex].free && !_finishedLockedSetups[objectId]) {
            // check if the setup has been updated or not
            if (objectId == _setups[setupIndex].objectId) {
                // check if it's finished (this is a withdraw) or not (a unlock)
                if (!isUnlock) {
                    // the locked setup must be considered finished only if it's not renewable
                    _finishedLockedSetups[objectId] = _setups[setupIndex].renewTimes == 0;
                    if (_hasPinned && _setups[_pinnedSetupIndex].free) {
                        _rebalanceRewardPerBlock(
                            _pinnedSetupIndex, 
                            _setups[setupIndex].rewardPerBlock - ((_setups[setupIndex].rewardPerBlock * (_setups[setupIndex].currentStakedLiquidity * 1e18 / _setups[setupIndex].maximumLiquidity)) / 1e18),
                            false
                        );
                    }
                    if (_setups[setupIndex].renewTimes > 0) {
                        _setups[setupIndex].renewTimes -= 1;
                        // renew the setup if renewable
                        _renewSetup(setupIndex);
                    }
                } else {
                    // this is an unlock, so we just need to provide back the reward per block
                    if (_hasPinned && _setups[_pinnedSetupIndex].free) {
                        _rebalanceRewardPerBlock(
                            _pinnedSetupIndex, 
                            _setups[setupIndex].rewardPerBlock * ((removedLiquidity * 1e18 / _setups[setupIndex].maximumLiquidity) / 1e18), 
                            true
                        );
                    }
                }
            }
        }
        if (positionId != 0) {
            // delete the liquidity mining position after the withdraw
            if (remainingLiquidity == 0) {
                _positions[positionId] = _positions[0x0];
            } else {
                // update the creation block and amount
                liquidityMiningPosition.creationBlock = block.number;
                liquidityMiningPosition.liquidityPoolTokenAmount = remainingLiquidity;
            }
        }
    }

    /** @dev Renews the setup with the given index.
      * @param setupIndex index of the setup to renew.
     */
    function _renewSetup(uint256 setupIndex) private {
        uint256 duration = _setups[setupIndex].endBlock - _setups[setupIndex].startBlock;
        _setups[setupIndex].startBlock = block.number + 1;
        _setups[setupIndex].endBlock = block.number + 1 + duration;
        _setups[setupIndex].currentRewardPerBlock = 0;
        _setups[setupIndex].currentStakedLiquidity = 0;
        _setups[setupIndex].objectId = 0;
    }

    /** @dev function used to rebalance the reward per block in the given free liquidity mining setup.
      * @param setupIndex setup to rebalance.
      * @param lockedRewardPerBlock new liquidity mining position locked reward per block that must be subtracted from the given free liquidity mining setup reward per block.
      * @param fromExit if the rebalance is caused by an exit from the locked liquidity mining position or not.
      */
    function _rebalanceRewardPerBlock(uint256 setupIndex, uint256 lockedRewardPerBlock, bool fromExit) private {
        LiquidityMiningSetup storage setup = _setups[setupIndex];
        _rebalanceRewardPerToken(setupIndex, 0, fromExit);
        fromExit ? setup.rewardPerBlock += lockedRewardPerBlock : setup.rewardPerBlock -= lockedRewardPerBlock;
    }

    /** @dev function used to rebalance the reward per token in a free liquidity mining setup.
      * @param setupIndex index of the setup to rebalance.
      * @param liquidityPoolTokenAmount amount of liquidity pool token being added.
      * @param fromExit if the rebalance is caused by an exit from the free liquidity mining position or not.
     */
    function _rebalanceRewardPerToken(uint256 setupIndex, uint256 liquidityPoolTokenAmount, bool fromExit) private {
        LiquidityMiningSetup storage setup = _setups[setupIndex];
        if(setup.lastBlockUpdate > 0 && setup.totalSupply > 0) {
            // add the block to the setup update blocks
            _setupUpdateBlocks[setupIndex].push(block.number);
            // update the reward token
            _rewardPerTokenPerSetupPerBlock[setupIndex][block.number] = (((block.number - setup.lastBlockUpdate) * setup.rewardPerBlock) * 1e18) / setup.totalSupply;
        }
        // update the last block update variable
        setup.lastBlockUpdate = block.number;
        // update total supply in the setup AFTER the reward calculation - to let previous liquidity mining position holders to calculate the correct value
        fromExit ? setup.totalSupply -= liquidityPoolTokenAmount : setup.totalSupply += liquidityPoolTokenAmount;
    }

    /** @dev function used to safely approve ERC20 transfers.
      * @param erc20TokenAddress address of the token to approve.
      * @param to receiver of the approval.
      * @param value amount to approve for.
     */
    function _safeApprove(address erc20TokenAddress, address to, uint256 value) internal virtual {
        bytes memory returnData = _call(erc20TokenAddress, abi.encodeWithSelector(IERC20(erc20TokenAddress).approve.selector, to, value));
        require(returnData.length == 0 || abi.decode(returnData, (bool)), 'APPROVE_FAILED');
    }

    /** @dev function used to safe transfer ERC20 tokens.
      * @param erc20TokenAddress address of the token to transfer.
      * @param to receiver of the tokens.
      * @param value amount of tokens to transfer.
     */
    function _safeTransfer(address erc20TokenAddress, address to, uint256 value) internal virtual {
        bytes memory returnData = _call(erc20TokenAddress, abi.encodeWithSelector(IERC20(erc20TokenAddress).transfer.selector, to, value));
        require(returnData.length == 0 || abi.decode(returnData, (bool)), 'TRANSFER_FAILED');
    }

    /** @dev this function safely transfers the given ERC20 value from an address to another.
      * @param erc20TokenAddress erc20 token address.
      * @param from address from.
      * @param to address to.
      * @param value amount to transfer.
     */
    function _safeTransferFrom(address erc20TokenAddress, address from, address to, uint256 value) private {
        bytes memory returnData = _call(erc20TokenAddress, abi.encodeWithSelector(IERC20(erc20TokenAddress).transferFrom.selector, from, to, value));
        require(returnData.length == 0 || abi.decode(returnData, (bool)), 'TRANSFERFROM_FAILED');
    }

    /** @dev calls the contract at the given location using the given payload and returns the returnData.
      * @param location location to call.
      * @param payload call payload.
      * @return returnData call return data.
     */
    function _call(address location, bytes memory payload) private returns(bytes memory returnData) {
        assembly {
            let result := call(gas(), location, 0, add(payload, 0x20), mload(payload), 0, 0)
            let size := returndatasize()
            returnData := mload(0x40)
            mstore(returnData, size)
            let returnDataPayloadStart := add(returnData, 0x20)
            returndatacopy(returnDataPayloadStart, 0, size)
            mstore(0x40, add(returnDataPayloadStart, size))
            switch result case 0 {revert(returnDataPayloadStart, size)}
        }
    }

    /** @dev function used to receive batch of erc1155 tokens. */
    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public view override returns(bytes4) {
        require(_liquidityFarmTokenCollection == msg.sender, "Invalid sender");
        return this.onERC1155BatchReceived.selector;
    }

    /** @dev function used to receive erc1155 tokens. */
    function onERC1155Received(address, address, uint256, uint256, bytes memory) public view override returns(bytes4) {
        require(_liquidityFarmTokenCollection == msg.sender, "Invalid sender");
        return this.onERC1155Received.selector;
    }

}