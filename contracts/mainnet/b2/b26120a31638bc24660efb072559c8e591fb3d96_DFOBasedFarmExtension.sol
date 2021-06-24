/**
 *Submitted for verification at Etherscan.io on 2021-06-23
*/

// File: contracts\farming\FarmData.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

struct FarmingPositionRequest {
    uint256 setupIndex; // index of the chosen setup.
    uint256 amount0; // amount of main token or liquidity pool token.
    uint256 amount1; // amount of other token or liquidity pool token. Needed for gen2
    address positionOwner; // position extension or address(0) [msg.sender].
}

struct FarmingSetupConfiguration {
    bool add; // true if we're adding a new setup, false we're updating it.
    bool disable;
    uint256 index; // index of the setup we're updating.
    FarmingSetupInfo info; // data of the new or updated setup
}

struct FarmingSetupInfo {
    uint256 blockDuration; // duration of setup
    uint256 startBlock; // optional start block used for the delayed activation of the first setup
    uint256 originalRewardPerBlock;
    uint256 minStakeable; // minimum amount of staking tokens.
    uint256 renewTimes; // if the setup is renewable or if it's one time.
    address liquidityPoolTokenAddress; // address of the liquidity pool token
    address mainTokenAddress; // eg. buidl address.
    bool involvingETH; // if the setup involves ETH or not.
    uint256 setupsCount; // number of setups created by this info.
    uint256 lastSetupIndex; // index of last setup;
    int24 tickLower; // Gen2 Only - tickLower of the UniswapV3 pool
    int24 tickUpper; // Gen 2 Only - tickUpper of the UniswapV3 pool
}

struct FarmingSetup {
    uint256 infoIndex; // setup info
    bool active; // if the setup is active or not.
    uint256 startBlock; // farming setup start block.
    uint256 endBlock; // farming setup end block.
    uint256 lastUpdateBlock; // number of the block where an update was triggered.
    uint256 objectId; // need for gen2. uniswapV3 NFT position Id
    uint256 rewardPerBlock; // farming setup reward per single block.
    uint128 totalSupply; // Total LP token liquidity of all the positions of this setup
}

struct FarmingPosition {
    address uniqueOwner; // address representing the owner of the position.
    uint256 setupIndex; // the setup index related to this position.
    uint256 creationBlock; // block when this position was created.
    uint128 liquidityPoolTokenAmount; // amount of liquidity pool token in the position.
    uint256 reward; // position reward.
}

// File: contracts\farming\IFarmExtension.sol

//SPDX_License_Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;


interface IFarmExtension {

    function init(bool byMint, address host, address treasury) external;

    function setHost(address host) external;
    function setTreasury(address treasury) external;

    function data() external view returns(address farmMainContract, bool byMint, address host, address treasury, address rewardTokenAddress);

    function transferTo(uint256 amount) external;
    function backToYou(uint256 amount) external payable;

    function setFarmingSetups(FarmingSetupConfiguration[] memory farmingSetups) external;
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

// File: contracts\farming\util\DFOHub.sol

// SPDX_License_Identifier: MIT

pragma solidity ^0.7.6;

interface IDoubleProxy {
    function proxy() external view returns (address);
}

interface IMVDProxy {
    function getMVDFunctionalitiesManagerAddress() external view returns(address);
    function getMVDWalletAddress() external view returns (address);
    function getStateHolderAddress() external view returns(address);
    function submit(string calldata codeName, bytes calldata data) external payable returns(bytes memory returnData);
}

interface IMVDFunctionalitiesManager {
    function getFunctionalityData(string calldata codeName) external view returns(address, uint256, string memory, address, uint256);
    function isAuthorizedFunctionality(address functionality) external view returns(bool);
}

interface IStateHolder {
    function getUint256(string calldata name) external view returns(uint256);
    function getAddress(string calldata name) external view returns(address);
    function clear(string calldata varName) external returns(string memory oldDataType, bytes memory oldVal);
}

// File: contracts\farming\dfo\DFOBasedFarmExtension.sol

//SPDX_License_Identifier: MIT
pragma solidity ^0.7.6;
//pragma abicoder v2;





contract DFOBasedFarmExtension is IFarmExtension {

    string private constant FUNCTIONALITY_NAME = "manageFarming";

    // wallet who has control on the extension
    address internal _doubleProxy;

    // mapping that contains all the farming contract linked to this extension
    address internal _farmingContract;

    // the reward token address linked to this farming contract
    address internal _rewardTokenAddress;

    // whether the token is by mint or by reserve
    bool internal _byMint;

    /** MODIFIERS */

    /** @dev farmingOnly modifier used to check for unauthorized transfers. */
    modifier farmingOnly() {
        require(msg.sender == _farmingContract, "Unauthorized");
        _;
    }

    /** @dev hostOnly modifier used to check for unauthorized edits. */
    modifier hostOnly() {
        require(_isFromDFO(msg.sender), "Unauthorized");
        _;
    }

    /** PUBLIC METHODS */

    function init(bool byMint, address host, address) public virtual override {
        require(_farmingContract == address(0), "Already init");
        require((_doubleProxy = host) != address(0), "blank host");
        _rewardTokenAddress = IFarmMain(_farmingContract = msg.sender)._rewardTokenAddress();
        _byMint = byMint;
    }

    /** @dev allows the DFO to update the double proxy address.
      * @param newDoubleProxy new double proxy address.
     */
    function setHost(address newDoubleProxy) public virtual override hostOnly {
        _doubleProxy = newDoubleProxy;
    }

    /** @dev method used to update the extension treasury.
     */
    function setTreasury(address) public virtual override hostOnly {
        revert("Impossibru!");
    }

    function data() view public virtual override returns(address farmingContract, bool byMint, address host, address treasury, address rewardTokenAddress) {
        return (_farmingContract, _byMint, _doubleProxy, IMVDProxy(IDoubleProxy(_doubleProxy).proxy()).getMVDWalletAddress(), _rewardTokenAddress);
    }

    /** @dev transfers the input amount to the caller farming contract.
      * @param amount amount of erc20 to transfer or mint.
     */
    function transferTo(uint256 amount) override public farmingOnly {
        IMVDProxy(IDoubleProxy(_doubleProxy).proxy()).submit(FUNCTIONALITY_NAME, abi.encode(address(0), 0, true, _rewardTokenAddress, _farmingContract, amount, _byMint));
    }

    /** @dev transfers the input amount from the caller farming contract to the extension.
      * @param amount amount of erc20 to transfer back or burn.
     */
    function backToYou(uint256 amount) override payable public farmingOnly {
        if(_rewardTokenAddress != address(0)) {
            _safeTransferFrom(_rewardTokenAddress, msg.sender, address(this), amount);
            _safeApprove(_rewardTokenAddress, _getFunctionalityAddress(), amount);
            IMVDProxy(IDoubleProxy(_doubleProxy).proxy()).submit(FUNCTIONALITY_NAME, abi.encode(address(0), 0, false, _rewardTokenAddress, msg.sender, amount, _byMint));
        } else {
            IMVDProxy(IDoubleProxy(_doubleProxy).proxy()).submit{value : amount}(FUNCTIONALITY_NAME, abi.encode(address(0), 0, false, _rewardTokenAddress, msg.sender, amount, _byMint));
        }
    }

    /** @dev this function calls the farming contract with the given address and sets the given farming setups.
      * @param farmingSetups array containing all the farming setups.
     */
    function setFarmingSetups(FarmingSetupConfiguration[] memory farmingSetups) public override hostOnly {
        IFarmMain(_farmingContract).setFarmingSetups(farmingSetups);
    }

    /** PRIVATE METHODS */

    /** @dev this function returns the address of the functionality with the FUNCTIONALITY_NAME.
      * @return functionalityAddress functionality FUNCTIONALITY_NAME address.
     */
    function _getFunctionalityAddress() private view returns(address functionalityAddress) {
        (functionalityAddress,,,,) = IMVDFunctionalitiesManager(IMVDProxy(IDoubleProxy(_doubleProxy).proxy()).getMVDFunctionalitiesManagerAddress()).getFunctionalityData(FUNCTIONALITY_NAME);
    }

    /** @dev this function returns the address of the wallet of the linked DFO.
      * @return linked DFO wallet address.
     */
    function _getDFOWallet() private view returns(address) {
        return IMVDProxy(IDoubleProxy(_doubleProxy).proxy()).getMVDWalletAddress();
    }

    /** @dev this function returns true if the sender is an authorized DFO functionality, false otherwise.
      * @param sender address of the caller.
      * @return true if the call is from a DFO, false otherwise.
     */
    function _isFromDFO(address sender) private view returns(bool) {
        return IMVDFunctionalitiesManager(IMVDProxy(IDoubleProxy(_doubleProxy).proxy()).getMVDFunctionalitiesManagerAddress()).isAuthorizedFunctionality(sender);
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
}