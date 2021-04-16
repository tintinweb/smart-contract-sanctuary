/**
 *Submitted for verification at Etherscan.io on 2021-04-15
*/

// File: contracts\farming\FarmData.sol

//SPDX-License-Identifier: MIT
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
    uint256 startBlock; // optional start block used for the delayed activation of the first setup
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

// File: contracts\farming\util\IERC20Mintable.sol

// SPDX_License_Identifier: MIT

pragma solidity ^0.7.6;

interface IERC20Mintable {
    function mint(address wallet, uint256 amount) external returns (bool);
    function burn(address wallet, uint256 amount) external returns (bool);
}

// File: contracts\farming\FarmExtension.sol

//SPDX_License_Identifier: MIT
pragma solidity ^0.7.6;
//pragma abicoder v2;





contract FarmExtension is IFarmExtension {

    // wallet who has control on the extension and treasury
    address internal _host;
    address internal _treasury;
    // address of the farm main contract linked to this extension
    address internal _farmMainContract;
    // the reward token address linked to this extension
    address internal _rewardTokenAddress;
    // whether the token is by mint or by reserve
    bool internal _byMint;

    /** MODIFIERS */

    /** @dev farmMainOnly modifier used to check for unauthorized transfers. */
    modifier farmMainOnly() {
        require(msg.sender == _farmMainContract, "Unauthorized");
        _;
    }

    /** @dev hostOnly modifier used to check for unauthorized edits. */
    modifier hostOnly() {
        require(msg.sender == _host, "Unauthorized");
        _;
    }

    /** PUBLIC METHODS */

    receive() external payable {
        require(_farmMainContract != address(0) && _rewardTokenAddress == address(0), "ETH not allowed");
    }

    function init(bool byMint, address host, address treasury) public virtual override {
        require(_farmMainContract == address(0), "Already init");
        require((_host = host) != address(0), "blank host");
        _rewardTokenAddress = IFarmMain(_farmMainContract = msg.sender)._rewardTokenAddress();
        _byMint = byMint;
        _treasury = treasury != address(0) ? treasury : host;
    }

    function data() view public virtual override returns(address farmMainContract, bool byMint, address host, address treasury, address rewardTokenAddress) {
        return (_farmMainContract, _byMint, _host, _treasury, _rewardTokenAddress);
    }

    /** @dev method used to update the extension host.
      * @param host new host address.
     */
    function setHost(address host) public virtual override hostOnly {
        _host = host;
    }

    /** @dev method used to update the extension treasury.
      * @param treasury new treasury address.
     */
    function setTreasury(address treasury) public virtual override hostOnly {
        _treasury = treasury;
    }

    /** @dev this function calls the farm main contract with the given address and sets the given farming setups.
      * @param farmingSetups array containing all the farming setups.
     */
    function setFarmingSetups(FarmingSetupConfiguration[] memory farmingSetups) public virtual override hostOnly {
        IFarmMain(_farmMainContract).setFarmingSetups(farmingSetups);
    }

    /** @dev transfers the input amount to the caller farming contract.
      * @param amount amount of erc20 to transfer or mint.
     */
    function transferTo(uint256 amount) public virtual override farmMainOnly {
        if(_rewardTokenAddress != address(0)) {
            return _byMint ? _mintAndTransfer(_rewardTokenAddress, _farmMainContract, amount) : _safeTransfer(_rewardTokenAddress, _farmMainContract, amount);
        }
        (bool result, ) = _farmMainContract.call{value:amount}("");
        require(result, "ETH transfer failed.");
    }

    /** @dev transfers the input amount from the caller farming contract to the extension.
      * @param amount amount of erc20 to transfer back or burn.
     */
    function backToYou(uint256 amount) payable public virtual override farmMainOnly {
        if(_rewardTokenAddress != address(0)) {
            _safeTransferFrom(_rewardTokenAddress, msg.sender, _byMint ? address(this) : _treasury, amount);
            if(_byMint) {
                _burn(_rewardTokenAddress, amount);
            }
        } else {
            require(msg.value == amount, "invalid sent amount");
            if(_treasury != address(this)) {
                (bool result, ) = _treasury.call{value:amount}("");
                require(result, "ETH transfer failed.");
            }
        }
    }

    /** INTERNAL METHODS */

    function _mintAndTransfer(address erc20TokenAddress, address recipient, uint256 value) internal virtual {
        IERC20Mintable(erc20TokenAddress).mint(recipient, value);
    }

    function _burn(address erc20TokenAddress, uint256 value) internal virtual {
        IERC20Mintable(erc20TokenAddress).burn(msg.sender, value);
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
    function _safeTransferFrom(address erc20TokenAddress, address from, address to, uint256 value) internal virtual {
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
}