/**
 *Submitted for verification at Etherscan.io on 2021-03-19
*/

// File: contracts\amm-aggregator\common\AMMData.sol

//SPDX-License-Identifier: MIT
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

// File: contracts\amm-aggregator\common\IAMM.sol

//SPDX_License_Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;


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

// File: contracts\farming\FarmData.sol

//SPDX_License_Identifier: MIT
pragma solidity ^0.7.6;

struct FarmingPositionRequest {
    uint256 setupIndex; // index of the chosen setup.
    uint256 amount; // amount of main token or liquidity pool token.
    bool amountIsLiquidityPool; //true if user wants to directly share the liquidity pool token amount, false to add liquidity to AMM
    address positionOwner; // position extension or address(0) [msg.sender].
}

struct FarmingSetupConfiguration {
    bool add; // true if we're adding a new setup, false we're updating it.
    bool disable;
    uint256 index; // index of the setup we're updating.
    FarmingSetupInfo info; // data of the new or updated setup
}

struct FarmingSetupInfo {
    bool free; // if the setup is a free farming setup or a locked one.
    uint256 blockDuration; // duration of setup
    uint256 originalRewardPerBlock;
    uint256 minStakeable; // minimum amount of staking tokens.
    uint256 maxStakeable; // maximum amount stakeable in the setup (used only if free is false).
    uint256 renewTimes; // if the setup is renewable or if it's one time.
    address ammPlugin; // amm plugin address used for this setup (eg. uniswap amm plugin address).
    address liquidityPoolTokenAddress; // address of the liquidity pool token
    address mainTokenAddress; // eg. buidl address.
    address ethereumAddress;
    bool involvingETH; // if the setup involves ETH or not.
    uint256 penaltyFee; // fee paid when the user exits a still active locked farming setup (used only if free is false).
    uint256 setupsCount; // number of setups created by this info.
    uint256 lastSetupIndex; // index of last setup;
}

struct FarmingSetup {
    uint256 infoIndex; // setup info
    bool active; // if the setup is active or not.
    uint256 startBlock; // farming setup start block.
    uint256 endBlock; // farming setup end block.
    uint256 lastUpdateBlock; // number of the block where an update was triggered.
    uint256 objectId; // items object id for the liquidity pool token (used only if free is false).
    uint256 rewardPerBlock; // farming setup reward per single block.
    uint256 totalSupply; // If free it's the LP amount, if locked is currentlyStaked.
}

struct FarmingPosition {
    address uniqueOwner; // address representing the owner of the position.
    uint256 setupIndex; // the setup index related to this position.
    uint256 creationBlock; // block when this position was created.
    uint256 liquidityPoolTokenAmount; // amount of liquidity pool token in the position.
    uint256 mainTokenAmount; // amount of main token in the position (used only if free is false).
    uint256 reward; // position reward (used only if free is false).
    uint256 lockedRewardPerBlock; // position locked reward per block (used only if free is false).
}

// File: contracts\farming\IFarmMain.sol

//SPDX_License_Identifier: MIT
pragma solidity ^0.7.6;
//pragma abicoder v2;


interface IFarmMain {

    function ONE_HUNDRED() external view returns(uint256);
    function _rewardTokenAddress() external view returns(address);
    function position(uint256 positionId) external view returns (FarmingPosition memory);
    function setups() external view returns (FarmingSetup[] memory);
    function setup(uint256 setupIndex) external view returns (FarmingSetup memory, FarmingSetupInfo memory);
    function setFarmingSetups(FarmingSetupConfiguration[] memory farmingSetups) external;
    function openPosition(FarmingPositionRequest calldata request) external payable returns(uint256 positionId);
    function addLiquidity(uint256 positionId, FarmingPositionRequest calldata request) external payable;
}

// File: contracts\farming\IFarmExtension.sol

//SPDX_License_Identifier: MIT
pragma solidity ^0.7.6;
//pragma abicoder v2;


interface IFarmExtension {

    function init(bool byMint, address host, address treasury) external;

    function setHost(address host) external;
    function setTreasury(address treasury) external;

    function data() external view returns(address farmMainContract, bool byMint, address host, address treasury, address rewardTokenAddress);

    function transferTo(uint256 amount) external;
    function backToYou(uint256 amount) external payable;

    function setFarmingSetups(FarmingSetupConfiguration[] memory farmingSetups) external;

}

// File: contracts\farming\IFarmFactory.sol

//SPDX_License_Identifier: MIT
pragma solidity ^0.7.6;

interface IFarmFactory {

    event ExtensionCloned(address indexed);

    function feePercentageInfo() external view returns (uint256, address);
    function farmDefaultExtension() external view returns(address);
    function cloneFarmDefaultExtension() external returns(address);
    function getFarmTokenCollectionURI() external view returns (string memory);
    function getFarmTokenURI() external view returns (string memory);
}

// File: contracts\farming\util\ERC1155Receiver.sol

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

// File: contracts\farming\util\IERC20.sol

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

// File: contracts\farming\util\IEthItemOrchestrator.sol

//SPDX_License_Identifier: MIT

pragma solidity ^0.7.6;

interface IEthItemOrchestrator {
    function createNative(bytes calldata modelInitPayload, string calldata ens)
        external
        returns (address newNativeAddress, bytes memory modelInitCallResponse);
}

// File: contracts\farming\util\IERC1155.sol

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

// File: contracts\farming\util\IEthItemInteroperableInterface.sol

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

// File: contracts\farming\util\IEthItem.sol

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

// File: contracts\farming\util\INativeV1.sol

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

// File: contracts\farming\FarmMain.sol

//SPDX_License_Identifier: MIT
pragma solidity ^0.7.6;
//pragma abicoder v2;









contract FarmMain is IFarmMain, ERC1155Receiver {

    // percentage
    uint256 public override constant ONE_HUNDRED = 1e18;
    // event that tracks contracts deployed for the given reward token
    event RewardToken(address indexed rewardTokenAddress);
    // new or transferred farming position event
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
     // farm token collection
    address public _farmTokenCollection;
    // mapping containing all the currently available farming setups info
    mapping(uint256 => FarmingSetupInfo) private _setupsInfo;
    // counter for the farming setup info
    uint256 public _farmingSetupsInfoCount;
    // mapping containing all the currently available farming setups
    mapping(uint256 => FarmingSetup) private _setups;
    // counter for the farming setups
    uint256 public _farmingSetupsCount;
    // mapping containing all the positions
    mapping(uint256 => FarmingPosition) private _positions;
    // mapping containing the reward per token per setup per block
    mapping(uint256 => uint256) private _rewardPerTokenPerSetup;
    // mapping containing the reward per token paid per position
    mapping(uint256 => uint256) private _rewardPerTokenPaid;
    // mapping containing whether a farming position has been partially reedemed or not
    mapping(uint256 => uint256) public _partiallyRedeemed;
    // mapping containing object id to setup index
    mapping(uint256 => uint256) private _objectIdSetup;
    // mapping containing all the number of opened positions for each setups
    mapping(uint256 => uint256) private _setupPositionsCount;
    // mapping containing all the reward received/paid per setup
    mapping(uint256 => uint256) public _rewardReceived;
    mapping(uint256 => uint256) public _rewardPaid;

    /** Modifiers. */

    /** @dev byExtension modifier used to check for unauthorized changes. */
    modifier byExtension() {
        require(msg.sender == _extension, "Unauthorized");
        _;
    }

    /** @dev byPositionOwner modifier used to check for unauthorized accesses. */
    modifier byPositionOwner(uint256 positionId) {
        require(_positions[positionId].uniqueOwner == msg.sender && _positions[positionId].creationBlock != 0, "Not owned");
        _;
    }

    /** @dev activeSetupOnly modifier used to check for function calls only if the setup is active. */
    modifier activeSetupOnly(uint256 setupIndex) {
        require(_setups[setupIndex].active, "Setup not active");
        require(_setups[setupIndex].startBlock <= block.number && _setups[setupIndex].endBlock > block.number, "Invalid setup");
        _;
    }

    receive() external payable {}

    /** Extension methods */

    /** @dev initializes the farming contract.
      * @param extension extension address.
      * @param extensionInitData lm extension init payload.
      * @param orchestrator address of the eth item orchestrator.
      * @param rewardTokenAddress address of the reward token.
      * @return extensionReturnCall result of the extension initialization function, if it was called.  
     */
    function init(address extension, bytes memory extensionInitData, address orchestrator, address rewardTokenAddress, bytes memory farmingSetupInfosBytes) public returns(bytes memory extensionReturnCall) {
        require(_factory == address(0), "Already initialized");
        require((_extension = extension) != address(0), "extension");
        _factory = msg.sender;
        emit RewardToken(_rewardTokenAddress = rewardTokenAddress);
        if (keccak256(extensionInitData) != keccak256("")) {
            extensionReturnCall = _call(_extension, extensionInitData);
        }
        (_farmTokenCollection,) = IEthItemOrchestrator(orchestrator).createNative(abi.encodeWithSignature("init(string,string,bool,string,address,bytes)", "Covenants Farming", "cFARM", true, IFarmFactory(_factory).getFarmTokenCollectionURI(), address(this), ""), "");
        if(farmingSetupInfosBytes.length > 0) {
            FarmingSetupInfo[] memory farmingSetupInfos = abi.decode(farmingSetupInfosBytes, (FarmingSetupInfo[]));
            for(uint256 i = 0; i < farmingSetupInfos.length; i++) {
                _setOrAddFarmingSetupInfo(farmingSetupInfos[i], true, false, 0);
            }
        }
    }

    function setFarmingSetups(FarmingSetupConfiguration[] memory farmingSetups) public override byExtension {
        for (uint256 i = 0; i < farmingSetups.length; i++) {
            _setOrAddFarmingSetupInfo(farmingSetups[i].info, farmingSetups[i].add, farmingSetups[i].disable, farmingSetups[i].index);
        }
    }

    /** Public methods */

    /** @dev returns the position with the given id.
      * @param positionId id of the position.
      * @return farming position with the given id.
     */
    function position(uint256 positionId) public override view returns (FarmingPosition memory) {
        return _positions[positionId];
    }

    function setup(uint256 setupIndex) public override view returns (FarmingSetup memory, FarmingSetupInfo memory) {
        return (_setups[setupIndex], _setupsInfo[_setups[setupIndex].infoIndex]);
    }

    function setups() public override view returns (FarmingSetup[] memory) {
        FarmingSetup[] memory farmingSetups = new FarmingSetup[](_farmingSetupsCount);
        for (uint256 i = 0; i < _farmingSetupsCount; i++) {
            farmingSetups[i] = _setups[i];
        }
        return farmingSetups;
    }

    function activateSetup(uint256 setupInfoIndex) public {
        require(_setupsInfo[setupInfoIndex].renewTimes > 0 && !_setups[_setupsInfo[setupInfoIndex].lastSetupIndex].active, "Invalid toggle.");
        _toggleSetup(_setupsInfo[setupInfoIndex].lastSetupIndex);
    }

    function transferPosition(address to, uint256 positionId) public byPositionOwner(positionId) {
        // retrieve liquidity mining position
        FarmingPosition memory pos = _positions[positionId];
        require(
            to != address(0) &&
            pos.creationBlock != 0,
            "Invalid position"
        );
        // pos.uniqueOwner = to;
        uint256 newPositionId = uint256(keccak256(abi.encode(to, _setupsInfo[_setups[pos.setupIndex].infoIndex].free ? 0 : block.number, pos.setupIndex)));
        require(_positions[newPositionId].creationBlock == 0, "Invalid transfer");
        _positions[newPositionId] = abi.decode(abi.encode(pos), (FarmingPosition));
        _positions[newPositionId].uniqueOwner = to;
        delete _positions[positionId];
        emit Transfer(newPositionId, msg.sender, to);
    }

    function openPosition(FarmingPositionRequest memory request) public override payable activeSetupOnly(request.setupIndex) returns(uint256 positionId) {
        // retrieve the setup
        FarmingSetup storage chosenSetup = _setups[request.setupIndex];
        // retrieve the unique owner
        address uniqueOwner = (request.positionOwner != address(0)) ? request.positionOwner : msg.sender;
        // create the position id
        positionId = uint256(keccak256(abi.encode(uniqueOwner, _setupsInfo[chosenSetup.infoIndex].free ? 0 : block.number, request.setupIndex)));
        require(_positions[positionId].creationBlock == 0, "Invalid open");
        // create the lp data for the amm
        (LiquidityPoolData memory liquidityPoolData, uint256 mainTokenAmount) = _addLiquidity(request.setupIndex, request);
        // calculate the reward
        uint256 reward;
        uint256 lockedRewardPerBlock;
        if (!_setupsInfo[chosenSetup.infoIndex].free) {
            (reward, lockedRewardPerBlock) = calculateLockedFarmingReward(request.setupIndex, mainTokenAmount, false, 0);
            require(reward > 0 && lockedRewardPerBlock > 0, "Insufficient staked amount");
            chosenSetup.totalSupply = chosenSetup.totalSupply + mainTokenAmount;
            chosenSetup.lastUpdateBlock = block.number;
            _mintFarmTokenAmount(uniqueOwner, liquidityPoolData.amount, request.setupIndex);
        } else {
            _updateFreeSetup(request.setupIndex, liquidityPoolData.amount, positionId, false);
        }
        _positions[positionId] = FarmingPosition({
            uniqueOwner: uniqueOwner,
            setupIndex : request.setupIndex,
            liquidityPoolTokenAmount: liquidityPoolData.amount,
            mainTokenAmount: mainTokenAmount,
            reward: reward,
            lockedRewardPerBlock: lockedRewardPerBlock,
            creationBlock: block.number
        });
        _setupPositionsCount[request.setupIndex] += (1 + (_setupsInfo[chosenSetup.infoIndex].free ? 0 : liquidityPoolData.amount));
        emit Transfer(positionId, address(0), uniqueOwner);
    }

    function addLiquidity(uint256 positionId, FarmingPositionRequest memory request) public override payable activeSetupOnly(request.setupIndex) byPositionOwner(positionId) {
        // retrieve farming position
        FarmingPosition storage farmingPosition = _positions[positionId];
        FarmingSetup storage chosenSetup = _setups[farmingPosition.setupIndex];
        // check if farmoing position is valid
        require(_setupsInfo[chosenSetup.infoIndex].free, "Invalid add liquidity");
        // create the lp data for the amm
        (LiquidityPoolData memory liquidityPoolData,) = _addLiquidity(farmingPosition.setupIndex, request);
        // rebalance the reward per token
        _rewardPerTokenPerSetup[farmingPosition.setupIndex] += (((block.number - chosenSetup.lastUpdateBlock) * chosenSetup.rewardPerBlock) * 1e18) / chosenSetup.totalSupply;
        farmingPosition.reward = calculateFreeFarmingReward(positionId, false);
        _rewardPerTokenPaid[positionId] = _rewardPerTokenPerSetup[farmingPosition.setupIndex];
        farmingPosition.liquidityPoolTokenAmount += liquidityPoolData.amount;
        // update the last block update variablex
        chosenSetup.lastUpdateBlock = block.number;
        chosenSetup.totalSupply += liquidityPoolData.amount;
    }


    /** @dev this function allows a user to withdraw the reward.
      * @param positionId farming position id.
     */
    function withdrawReward(uint256 positionId) public byPositionOwner(positionId) {
        // retrieve farming position
        FarmingPosition storage farmingPosition = _positions[positionId];
        uint256 reward = farmingPosition.reward;
        uint256 currentBlock = block.number;
        if (!_setupsInfo[_setups[farmingPosition.setupIndex].infoIndex].free) {
            // check if reward is available
            require(farmingPosition.reward > 0, "No reward");
            // check if it's a partial reward or not
            // if (_setups[farmingPosition.setupIndex].endBlock > block.number) {
            // calculate the reward from the farming position creation block to the current block multiplied by the reward per block
            (reward,) = calculateLockedFarmingReward(0, 0, true, positionId);
            //}
            require(reward <= farmingPosition.reward, "Reward is bigger than expected");
            // remove the partial reward from the liquidity mining position total reward
            farmingPosition.reward = currentBlock >= _setups[farmingPosition.setupIndex].endBlock ? 0 : farmingPosition.reward - reward;
            farmingPosition.creationBlock = block.number;
        } else {
            // rebalance setup
            currentBlock = currentBlock > _setups[farmingPosition.setupIndex].endBlock ? _setups[farmingPosition.setupIndex].endBlock : currentBlock;
            _rewardPerTokenPerSetup[farmingPosition.setupIndex] += (((currentBlock - _setups[farmingPosition.setupIndex].lastUpdateBlock) * _setups[farmingPosition.setupIndex].rewardPerBlock) * 1e18) / _setups[farmingPosition.setupIndex].totalSupply;
            reward = calculateFreeFarmingReward(positionId, false);
            _rewardPerTokenPaid[positionId] = _rewardPerTokenPerSetup[farmingPosition.setupIndex];
            farmingPosition.reward = 0;
            // update the last block update variable
            _setups[farmingPosition.setupIndex].lastUpdateBlock = currentBlock;
        }
        if (reward > 0) {
            // transfer the reward
            if (_rewardTokenAddress != address(0)) {
                _safeTransfer(_rewardTokenAddress, farmingPosition.uniqueOwner, reward);
            } else {
                (bool result,) = farmingPosition.uniqueOwner.call{value:reward}("");
                require(result, "Invalid ETH transfer.");
            }
            _rewardPaid[farmingPosition.setupIndex] += reward;
        }
        if (_setups[farmingPosition.setupIndex].endBlock <= block.number) {
            if (_setups[farmingPosition.setupIndex].active) {
                _toggleSetup(farmingPosition.setupIndex);
            }
            // close the locked position after withdrawing all the reward
            if (!_setupsInfo[_setups[farmingPosition.setupIndex].infoIndex].free) {
                _setupPositionsCount[farmingPosition.setupIndex] -= 1;
                if (_setupPositionsCount[farmingPosition.setupIndex] == 0 && !_setups[farmingPosition.setupIndex].active) {
                    _giveBack(_rewardReceived[farmingPosition.setupIndex] - _rewardPaid[farmingPosition.setupIndex]);
                    delete _setups[farmingPosition.setupIndex];
                }
                delete _positions[positionId];
            }
        } else if (!_setupsInfo[_setups[farmingPosition.setupIndex].infoIndex].free) {
            // set the partially redeemed amount
            _partiallyRedeemed[positionId] += reward;
        }
    }

    function withdrawLiquidity(uint256 positionId, uint256 objectId, bool unwrapPair, uint256 removedLiquidity) public {
        // retrieve farming position
        FarmingPosition memory farmingPosition = _positions[positionId];
        uint256 setupIndex = farmingPosition.setupIndex;
        if (objectId != 0 && address(INativeV1(_farmTokenCollection).asInteroperable(objectId)) != address(0)) {
            setupIndex = _objectIdSetup[objectId];
        }
        require((positionId != 0 && objectId == 0) || (objectId != 0 && positionId == 0 && _setups[setupIndex].objectId == objectId), "Invalid position");
        // current owned liquidity
        require(
            (
                _setupsInfo[_setups[farmingPosition.setupIndex].infoIndex].free && 
                farmingPosition.creationBlock != 0 &&
                removedLiquidity <= farmingPosition.liquidityPoolTokenAmount &&
                farmingPosition.uniqueOwner == msg.sender
            ) || (INativeV1(_farmTokenCollection).balanceOf(msg.sender, objectId) >= removedLiquidity && (_setups[setupIndex].endBlock <= block.number)), "Invalid withdraw");
        // burn the liquidity in the locked setup
        if (positionId == 0) {
            _burnFarmTokenAmount(objectId, removedLiquidity);
        } else {
            withdrawReward(positionId);
            _setups[farmingPosition.setupIndex].totalSupply -= removedLiquidity;
        }
        _removeLiquidity(positionId, setupIndex, unwrapPair, removedLiquidity, false);
        if (positionId == 0) {
            _setupPositionsCount[setupIndex] -= removedLiquidity;
            if (_setupPositionsCount[setupIndex] == 0 && !_setups[setupIndex].active) {
                _giveBack(_rewardReceived[setupIndex] - _rewardPaid[setupIndex]);
                delete _setups[setupIndex];
            }
        }
    }

    function unlock(uint256 positionId, bool unwrapPair) public payable byPositionOwner(positionId) {
        // retrieve liquidity mining position
        FarmingPosition storage farmingPosition = _positions[positionId];
        require(!_setupsInfo[_setups[farmingPosition.setupIndex].infoIndex].free && _setups[farmingPosition.setupIndex].endBlock > block.number, "Invalid unlock");
        uint256 rewardToGiveBack = _partiallyRedeemed[positionId];
        // must pay a penalty fee
        rewardToGiveBack += _setupsInfo[_setups[farmingPosition.setupIndex].infoIndex].penaltyFee == 0 ? 0 : (farmingPosition.reward * ((_setupsInfo[_setups[farmingPosition.setupIndex].infoIndex].penaltyFee * 1e18) / ONE_HUNDRED) / 1e18);
        // add all the unissued reward
        if (rewardToGiveBack > 0) {
            _safeTransferFrom(_rewardTokenAddress, msg.sender, address(this), rewardToGiveBack);
            _giveBack(rewardToGiveBack);
        } 
        _setups[farmingPosition.setupIndex].totalSupply -= farmingPosition.mainTokenAmount;
        _burnFarmTokenAmount(_setups[farmingPosition.setupIndex].objectId, farmingPosition.liquidityPoolTokenAmount);
        _removeLiquidity(positionId, farmingPosition.setupIndex, unwrapPair, farmingPosition.liquidityPoolTokenAmount, true);
        _setupPositionsCount[farmingPosition.setupIndex] -= 1 + farmingPosition.liquidityPoolTokenAmount;
        delete _positions[positionId];
    }

    function calculateLockedFarmingReward(uint256 setupIndex, uint256 mainTokenAmount, bool isPartial, uint256 positionId) public view returns(uint256 reward, uint256 relativeRewardPerBlock) {
        if (isPartial) {
            // retrieve the position
            FarmingPosition memory farmingPosition = _positions[positionId];
            // calculate the reward
            uint256 currentBlock = block.number >= _setups[farmingPosition.setupIndex].endBlock ? _setups[farmingPosition.setupIndex].endBlock : block.number;
            reward = ((currentBlock - farmingPosition.creationBlock) * farmingPosition.lockedRewardPerBlock);
        } else {
            FarmingSetup memory setup = _setups[setupIndex];
            // check if main token amount is less than the stakeable liquidity
            require(mainTokenAmount <= _setupsInfo[_setups[setupIndex].infoIndex].maxStakeable - setup.totalSupply, "Invalid liquidity");
            uint256 remainingBlocks = block.number >= setup.endBlock ? 0 : setup.endBlock - block.number;
            // get amount of remaining blocks
            require(remainingBlocks > 0, "FarmingSetup ended");
            // get total reward still available (= 0 if rewardPerBlock = 0)
            require(setup.rewardPerBlock * remainingBlocks > 0, "No rewards");
            // calculate relativeRewardPerBlock
            relativeRewardPerBlock = (setup.rewardPerBlock * ((mainTokenAmount * 1e18) / _setupsInfo[_setups[setupIndex].infoIndex].maxStakeable)) / 1e18;
            // check if rewardPerBlock is greater than 0
            require(relativeRewardPerBlock > 0, "Invalid rpb");
            // calculate reward by multiplying relative reward per block and the remaining blocks
            reward = relativeRewardPerBlock * remainingBlocks;
        }
    }

    function calculateFreeFarmingReward(uint256 positionId, bool isExt) public view returns(uint256 reward) {
        FarmingPosition memory farmingPosition = _positions[positionId];
        reward = ((_rewardPerTokenPerSetup[farmingPosition.setupIndex] - _rewardPerTokenPaid[positionId]) * farmingPosition.liquidityPoolTokenAmount) / 1e18;
        if (isExt) {
            uint256 currentBlock = block.number < _setups[farmingPosition.setupIndex].endBlock ? block.number : _setups[farmingPosition.setupIndex].endBlock;
            uint256 lastUpdateBlock = _setups[farmingPosition.setupIndex].lastUpdateBlock < _setups[farmingPosition.setupIndex].startBlock ? _setups[farmingPosition.setupIndex].startBlock : _setups[farmingPosition.setupIndex].lastUpdateBlock;
            uint256 rpt = (((currentBlock - lastUpdateBlock) * _setups[farmingPosition.setupIndex].rewardPerBlock) * 1e18) / _setups[farmingPosition.setupIndex].totalSupply;
            reward += (rpt * farmingPosition.liquidityPoolTokenAmount) / 1e18;
        }
        reward += farmingPosition.reward;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public view override returns(bytes4) {
        require(_farmTokenCollection == msg.sender, "Invalid sender");
        return this.onERC1155BatchReceived.selector;
    }

    function onERC1155Received(address, address, uint256, uint256, bytes memory) public view override returns(bytes4) {
        require(_farmTokenCollection == msg.sender, "Invalid sender");
        return this.onERC1155Received.selector;
    }

    /** Private methods */

    function _setOrAddFarmingSetupInfo(FarmingSetupInfo memory info, bool add, bool disable, uint256 setupIndex) private {
        FarmingSetupInfo memory farmingSetupInfo = info;

        if(add || !disable) {
            farmingSetupInfo.renewTimes = farmingSetupInfo.renewTimes + 1;
            if(farmingSetupInfo.renewTimes == 0) {
                farmingSetupInfo.renewTimes = farmingSetupInfo.renewTimes - 1;
            }
        }

        if (add) {
            require(
                farmingSetupInfo.ammPlugin != address(0) &&
                farmingSetupInfo.liquidityPoolTokenAddress != address(0) &&
                farmingSetupInfo.originalRewardPerBlock > 0 &&
                (farmingSetupInfo.free || farmingSetupInfo.maxStakeable > 0),
                "Invalid setup configuration"
            );

            (,,address[] memory tokenAddresses) = IAMM(farmingSetupInfo.ammPlugin).byLiquidityPool(farmingSetupInfo.liquidityPoolTokenAddress);
            farmingSetupInfo.ethereumAddress = address(0);
            if (farmingSetupInfo.involvingETH) {
                (farmingSetupInfo.ethereumAddress,,) = IAMM(farmingSetupInfo.ammPlugin).data();
            }
            bool mainTokenFound = false;
            bool ethTokenFound = false;
            for(uint256 z = 0; z < tokenAddresses.length; z++) {
                if(tokenAddresses[z] == farmingSetupInfo.mainTokenAddress) {
                    mainTokenFound = true;
                    if(tokenAddresses[z] == farmingSetupInfo.ethereumAddress) {
                        ethTokenFound = true;
                    }
                } else {
                    emit SetupToken(farmingSetupInfo.mainTokenAddress, tokenAddresses[z]);
                    if(tokenAddresses[z] == farmingSetupInfo.ethereumAddress) {
                        ethTokenFound = true;
                    }
                }
            }
            require(mainTokenFound, "No main token");
            require(!farmingSetupInfo.involvingETH || ethTokenFound, "No ETH token");
            farmingSetupInfo.setupsCount = 0;
            _setupsInfo[_farmingSetupsInfoCount] = farmingSetupInfo;
            _setups[_farmingSetupsCount] = FarmingSetup(_farmingSetupsInfoCount, false, 0, 0, 0, 0, farmingSetupInfo.originalRewardPerBlock, 0);
            _setupsInfo[_farmingSetupsInfoCount].lastSetupIndex = _farmingSetupsCount;
            _farmingSetupsInfoCount += 1;
            _farmingSetupsCount += 1;
            return;
        }

        FarmingSetup storage setup = _setups[setupIndex];
        farmingSetupInfo = _setupsInfo[_setups[setupIndex].infoIndex];

        if(disable) {
            require(setup.active, "Not possible");
            _toggleSetup(setupIndex);
            return;
        }

        info.renewTimes -= 1;

        if (setup.active && _setupsInfo[_setups[setupIndex].infoIndex].free) {
            setup = _setups[setupIndex];
            if(block.number < setup.endBlock) {
                uint256 difference = info.originalRewardPerBlock < farmingSetupInfo.originalRewardPerBlock ? farmingSetupInfo.originalRewardPerBlock - info.originalRewardPerBlock : info.originalRewardPerBlock - farmingSetupInfo.originalRewardPerBlock;
                uint256 duration = setup.endBlock - block.number;
                uint256 amount = difference * duration;
                if (amount > 0) {
                    if (info.originalRewardPerBlock > farmingSetupInfo.originalRewardPerBlock) {
                        require(_ensureTransfer(amount), "Insufficient reward in extension.");
                        _rewardReceived[setupIndex] += amount;
                    }
                    _updateFreeSetup(setupIndex, 0, 0, false);
                    setup.rewardPerBlock = info.originalRewardPerBlock;
                }
            }
            _setupsInfo[_setups[setupIndex].infoIndex].originalRewardPerBlock = info.originalRewardPerBlock;
        }
        if(_setupsInfo[_setups[setupIndex].infoIndex].renewTimes > 0) {
            _setupsInfo[_setups[setupIndex].infoIndex].renewTimes = info.renewTimes;
        }
    }

    function _transferToMeAndCheckAllowance(FarmingSetup memory setup, FarmingPositionRequest memory request) private returns(IAMM amm, uint256 liquidityPoolAmount, uint256 mainTokenAmount) {
        require(request.amount > 0, "No amount");
        // retrieve the values
        amm = IAMM(_setupsInfo[setup.infoIndex].ammPlugin);
        liquidityPoolAmount = request.amountIsLiquidityPool ? request.amount : 0;
        mainTokenAmount = request.amountIsLiquidityPool ? 0 : request.amount;
        address[] memory tokens;
        uint256[] memory tokenAmounts;
        // if liquidity pool token amount is provided, the position is opened by liquidity pool token amount
        if(request.amountIsLiquidityPool) {
            _safeTransferFrom(_setupsInfo[setup.infoIndex].liquidityPoolTokenAddress, msg.sender, address(this), liquidityPoolAmount);
            (tokenAmounts, tokens) = amm.byLiquidityPoolAmount(_setupsInfo[setup.infoIndex].liquidityPoolTokenAddress, liquidityPoolAmount);
        } else {
            // else it is opened by the tokens amounts
            (liquidityPoolAmount, tokenAmounts, tokens) = amm.byTokenAmount(_setupsInfo[setup.infoIndex].liquidityPoolTokenAddress, _setupsInfo[setup.infoIndex].mainTokenAddress, mainTokenAmount);
        }

        // iterate the tokens and perform the transferFrom and the approve
        for(uint256 i = 0; i < tokens.length; i++) {
            if(tokens[i] == _setupsInfo[setup.infoIndex].mainTokenAddress) {
                mainTokenAmount = tokenAmounts[i];
                require(mainTokenAmount >= _setupsInfo[setup.infoIndex].minStakeable, "Invalid liquidity.");
                if(request.amountIsLiquidityPool) {
                    break;
                }
            }
            if(request.amountIsLiquidityPool) {
                continue;
            }
            if(_setupsInfo[setup.infoIndex].involvingETH && _setupsInfo[setup.infoIndex].ethereumAddress == tokens[i]) {
                require(msg.value == tokenAmounts[i], "Incorrect eth value");
            } else {
                _safeTransferFrom(tokens[i], msg.sender, address(this), tokenAmounts[i]);
                _safeApprove(tokens[i], _setupsInfo[setup.infoIndex].ammPlugin, tokenAmounts[i]);
            }
        }
    }

    function _addLiquidity(uint256 setupIndex, FarmingPositionRequest memory request) private returns(LiquidityPoolData memory liquidityPoolData, uint256 tokenAmount) {
        (IAMM amm, uint256 liquidityPoolAmount, uint256 mainTokenAmount) = _transferToMeAndCheckAllowance(_setups[setupIndex], request);
        // liquidity pool data struct for the AMM
        liquidityPoolData = LiquidityPoolData(
            _setupsInfo[_setups[setupIndex].infoIndex].liquidityPoolTokenAddress,
            request.amountIsLiquidityPool ? liquidityPoolAmount : mainTokenAmount,
            _setupsInfo[_setups[setupIndex].infoIndex].mainTokenAddress,
            request.amountIsLiquidityPool,
            _setupsInfo[_setups[setupIndex].infoIndex].involvingETH,
            address(this)
        );
        tokenAmount = mainTokenAmount;
        // amount is lp check
        if (liquidityPoolData.amountIsLiquidityPool || !_setupsInfo[_setups[setupIndex].infoIndex].involvingETH) {
            require(msg.value == 0, "ETH not involved");
        }
        if (liquidityPoolData.amountIsLiquidityPool) {
            return(liquidityPoolData, tokenAmount);
        }
        // retrieve the poolTokenAmount from the amm
        if(liquidityPoolData.involvingETH) {
            (liquidityPoolData.amount,,) = amm.addLiquidity{value : msg.value}(liquidityPoolData);
        } else {
            (liquidityPoolData.amount,,) = amm.addLiquidity(liquidityPoolData);
        }
    }

    /** @dev helper function used to remove liquidity from a free position or to burn item farm tokens and retrieve their content.
      * @param positionId id of the position.
      * @param setupIndex index of the setup related to the item farm tokens.
      * @param unwrapPair whether to unwrap the liquidity pool tokens or not.
      * @param isUnlock if we're removing liquidity from an unlock method or not.
     */
    function _removeLiquidity(uint256 positionId, uint256 setupIndex, bool unwrapPair, uint256 removedLiquidity, bool isUnlock) private {
        FarmingSetupInfo memory setupInfo = _setupsInfo[_setups[setupIndex].infoIndex];
        // create liquidity pool data struct for the AMM
        LiquidityPoolData memory lpData = LiquidityPoolData(
            setupInfo.liquidityPoolTokenAddress,
            removedLiquidity,
            setupInfo.mainTokenAddress,
            true,
            setupInfo.involvingETH,
            msg.sender
        );
        // retrieve the position
        FarmingPosition storage farmingPosition = _positions[positionId];
        // remaining liquidity
        uint256 remainingLiquidity;
        // we are removing liquidity using the setup items
        if (setupInfo.free && farmingPosition.creationBlock != 0 && positionId != 0) {
            // update the remaining liquidity
            remainingLiquidity = farmingPosition.liquidityPoolTokenAmount - removedLiquidity;
        }
        // retrieve fee stuff
        (uint256 exitFeePercentage, address exitFeeWallet) = IFarmFactory(_factory).feePercentageInfo();
        // pay the fees!
        if (exitFeePercentage > 0) {
            uint256 fee = (lpData.amount * ((exitFeePercentage * 1e18) / ONE_HUNDRED)) / 1e18;
            _safeTransfer(setupInfo.liquidityPoolTokenAddress, exitFeeWallet, fee);
            lpData.amount = lpData.amount - fee;
        }
        // check if the user wants to unwrap its pair or not
        if (unwrapPair) {
            // remove liquidity using AMM
            _safeApprove(lpData.liquidityPoolAddress, setupInfo.ammPlugin, lpData.amount);
            IAMM(setupInfo.ammPlugin).removeLiquidity(lpData);
        } else {
            // send back the liquidity pool token amount without the fee
            _safeTransfer(lpData.liquidityPoolAddress, lpData.receiver, lpData.amount);
        }
        if (!setupInfo.free && _setups[setupIndex].active && !isUnlock) {
            _toggleSetup(setupIndex);
        } else if (setupInfo.free && positionId != 0) {
            if (_setups[farmingPosition.setupIndex].active && _setups[farmingPosition.setupIndex].endBlock <= block.number) {
                _toggleSetup(farmingPosition.setupIndex);
            }
            // delete the farming position after the withdraw
            if (remainingLiquidity == 0) {
                _setupPositionsCount[farmingPosition.setupIndex] -= 1;
                if (_setupPositionsCount[farmingPosition.setupIndex] == 0 && !_setups[farmingPosition.setupIndex].active) {
                    _giveBack(_rewardReceived[farmingPosition.setupIndex] - _rewardPaid[farmingPosition.setupIndex]);
                    delete _setups[farmingPosition.setupIndex];
                }
                delete _positions[positionId];
            } else {
                // update the creation block and amount
                farmingPosition.liquidityPoolTokenAmount = remainingLiquidity;
            }
        }
    }

    /** @dev updates the free setup with the given index.
      * @param setupIndex index of the setup that we're updating.
      * @param amount amount of liquidity that we're adding/removeing.
      * @param positionId position id.
      * @param fromExit if it's from an exit or not.
     */
    function _updateFreeSetup(uint256 setupIndex, uint256 amount, uint256 positionId, bool fromExit) private {
        uint256 currentBlock = block.number < _setups[setupIndex].endBlock ? block.number : _setups[setupIndex].endBlock;
        if (_setups[setupIndex].totalSupply != 0) {
            uint256 lastUpdateBlock = _setups[setupIndex].lastUpdateBlock < _setups[setupIndex].startBlock ? _setups[setupIndex].startBlock : _setups[setupIndex].lastUpdateBlock;
            _rewardPerTokenPerSetup[setupIndex] += (((currentBlock - lastUpdateBlock) * _setups[setupIndex].rewardPerBlock) * 1e18) / _setups[setupIndex].totalSupply;
        }
        // update the last block update variable
        _setups[setupIndex].lastUpdateBlock = currentBlock;
        if (positionId != 0) {
            _rewardPerTokenPaid[positionId] = _rewardPerTokenPerSetup[setupIndex];
        }
        if (amount > 0) {
            fromExit ? _setups[setupIndex].totalSupply -= amount : _setups[setupIndex].totalSupply += amount;
        }
    }

    function _toggleSetup(uint256 setupIndex) private {
        FarmingSetup storage setup = _setups[setupIndex];
        // require(!setup.active || block.number >= setup.endBlock, "Not valid activation");

        if (setup.active && block.number >= setup.endBlock && _setupsInfo[setup.infoIndex].renewTimes == 0) {
            setup.active = false;
            return;
        } else if (block.number >= setup.startBlock && block.number < setup.endBlock && setup.active) {
            setup.active = false;
            _setupsInfo[setup.infoIndex].renewTimes = 0;
            uint256 amount = (setup.endBlock - block.number) * setup.rewardPerBlock;
            setup.endBlock = block.number;
            if (_setupsInfo[setup.infoIndex].free) {
                _updateFreeSetup(setupIndex, 0, 0, false);
            }
            _rewardReceived[setupIndex] -= amount;
            _giveBack(amount);
            return;
        }

        bool wasActive = setup.active;
        setup.active = _ensureTransfer(setup.rewardPerBlock * _setupsInfo[setup.infoIndex].blockDuration);

        if (setup.active && wasActive) {
            _rewardReceived[_farmingSetupsCount] = setup.rewardPerBlock * _setupsInfo[setup.infoIndex].blockDuration;
            // set new setup
            _setups[_farmingSetupsCount] = abi.decode(abi.encode(setup), (FarmingSetup));
            // update old setup
            _setups[setupIndex].active = false;
            // update new setup
            _setupsInfo[setup.infoIndex].renewTimes -= 1;
            _setupsInfo[setup.infoIndex].setupsCount += 1;
            _setupsInfo[setup.infoIndex].lastSetupIndex = _farmingSetupsCount;
            _setups[_farmingSetupsCount].startBlock = block.number;
            _setups[_farmingSetupsCount].endBlock = block.number + _setupsInfo[_setups[_farmingSetupsCount].infoIndex].blockDuration;
            _setups[_farmingSetupsCount].objectId = 0;
            _setups[_farmingSetupsCount].totalSupply = 0;
            _farmingSetupsCount += 1;
        } else if (setup.active && !wasActive) {
            _rewardReceived[setupIndex] = setup.rewardPerBlock * _setupsInfo[_setups[setupIndex].infoIndex].blockDuration;
            // update new setup
            _setups[setupIndex].startBlock = block.number;
            _setups[setupIndex].endBlock = block.number + _setupsInfo[_setups[setupIndex].infoIndex].blockDuration;
            _setups[setupIndex].totalSupply = 0;
            _setupsInfo[_setups[setupIndex].infoIndex].renewTimes -= 1;
        } else {
            _setupsInfo[_setups[setupIndex].infoIndex].renewTimes = 0;
        }
    }

    /** @dev mints a new FarmToken inside the collection for the given position.
      * @param uniqueOwner farming position owner.
      * @param amount amount of to mint for a farm token.
      * @param setupIndex index of the setup.
      * @return objectId new farm token object id.
     */
    function _mintFarmTokenAmount(address uniqueOwner, uint256 amount, uint256 setupIndex) private returns(uint256 objectId) {
        if (_setups[setupIndex].objectId == 0) {
            (objectId,) = INativeV1(_farmTokenCollection).mint(amount, string(abi.encodePacked("Farming LP ", _toString(_setupsInfo[_setups[setupIndex].infoIndex].liquidityPoolTokenAddress))), "fLP", IFarmFactory(_factory).getFarmTokenURI(), true);
            emit FarmToken(objectId, _setupsInfo[_setups[setupIndex].infoIndex].liquidityPoolTokenAddress, setupIndex, _setups[setupIndex].endBlock);
            _objectIdSetup[objectId] = setupIndex;
            _setups[setupIndex].objectId = objectId;
        } else {
            INativeV1(_farmTokenCollection).mint(_setups[setupIndex].objectId, amount);
        }
        INativeV1(_farmTokenCollection).safeTransferFrom(address(this), uniqueOwner, _setups[setupIndex].objectId, amount, "");
    }

    /** @dev burns a farm token from the collection.
      * @param objectId object id where to burn liquidity.
      * @param amount amount of liquidity to burn.
      */
    function _burnFarmTokenAmount(uint256 objectId, uint256 amount) private {
        INativeV1 tokenCollection = INativeV1(_farmTokenCollection);
        // transfer the farm token to this contract
        tokenCollection.safeTransferFrom(msg.sender, address(this), objectId, amount, "");
        // burn the farm token
        tokenCollection.burn(objectId, amount);
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

    /** @dev returns the input address to string.
      * @param _addr address to convert as string.
      * @return address as string.
     */
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

    /** @dev gives back the reward to the extension.
      * @param amount to give back.
     */
    function _giveBack(uint256 amount) private {
        if(amount == 0) {
            return;
        }
        if (_rewardTokenAddress == address(0)) {
            IFarmExtension(_extension).backToYou{value : amount}(amount);
        } else {
            _safeApprove(_rewardTokenAddress, _extension, amount);
            IFarmExtension(_extension).backToYou(amount);
        }
    }

    /** @dev ensures the transfer from the contract to the extension.
      * @param amount amount to transfer.
     */
    function _ensureTransfer(uint256 amount) private returns(bool) {
        uint256 initialBalance = _rewardTokenAddress == address(0) ? address(this).balance : IERC20(_rewardTokenAddress).balanceOf(address(this));
        uint256 expectedBalance = initialBalance + amount;
        try IFarmExtension(_extension).transferTo(amount) {} catch {}
        uint256 actualBalance = _rewardTokenAddress == address(0) ? address(this).balance : IERC20(_rewardTokenAddress).balanceOf(address(this));
        if(actualBalance == expectedBalance) {
            return true;
        }
        _giveBack(actualBalance - initialBalance);
        return false;
    }
}