/**
 *Submitted for verification at Etherscan.io on 2021-02-02
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

// File: contracts\liquidity-mining\ILiquidityMining.sol

//SPDX_License_Identifier: MIT
pragma solidity ^0.7.6;
//pragma abicoder v2;


interface ILiquidityMining {

    function _rewardTokenAddress() external view returns(address);
    function setups() external view returns (LiquidityMiningSetup[] memory);
    function setLiquidityMiningSetups(LiquidityMiningSetupConfiguration[] memory liquidityMiningSetups, bool clearPinned, bool setPinned, uint256 pinnedIndex) external;
    
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

// File: contracts\liquidity-mining\util\IERC20Mintable.sol

// SPDX_License_Identifier: MIT

pragma solidity ^0.7.6;

interface IERC20Mintable {
    function mint(address wallet, uint256 amount) external returns (bool);
    function burn(address wallet, uint256 amount) external returns (bool);
}

// File: contracts\liquidity-mining\LiquidityMiningExtension.sol

//SPDX_License_Identifier: MIT
pragma solidity ^0.7.6;
//pragma abicoder v2;






contract LiquidityMiningExtension is ILiquidityMiningExtension {

    // wallet who has control on the extension
    address internal _host;

    // mapping that contains all the liquidity mining contract linked to this extension
    address internal _liquidityMiningContract;

    // the reward token address linked to this liquidity mining contract
    address internal _rewardTokenAddress;

    // whether the token is by mint or by reserve
    bool internal _byMint;

    /** MODIFIERS */

    /** @dev liquidityMiningOnly modifier used to check for unauthorized transfers. */
    modifier liquidityMiningOnly() {
        require(msg.sender == _liquidityMiningContract, "Unauthorized");
        _;
    }

    /** @dev hostOnly modifier used to check for unauthorized edits. */
    modifier hostOnly() {
        require(msg.sender == _host, "Unauthorized");
        _;
    }

    /** PUBLIC METHODS */

    receive() external payable {
        require(_liquidityMiningContract != address(0) && _rewardTokenAddress == address(0), "ETH not allowed");
    }

    function init(bool byMint, address host) public virtual override {
        require(_liquidityMiningContract == address(0), "Already init");
        _rewardTokenAddress = ILiquidityMining(_liquidityMiningContract = msg.sender)._rewardTokenAddress();
        _byMint = byMint;
        _host = host;
    }

    function setHost(address host) public virtual override hostOnly {
        _host = host;
    }

    function data() view public virtual override returns(address liquidityMiningContract, bool byMint, address host, address rewardTokenAddress) {
        return (_liquidityMiningContract, _byMint, _host, _rewardTokenAddress);
    }

    /** @dev transfers the input amount to the caller liquidity mining contract.
      * @param amount amount of erc20 to transfer or mint.
     */
    function transferTo(uint256 amount, address recipient) public virtual override liquidityMiningOnly {
        if(_rewardTokenAddress != address(0)) {
            return _byMint ? _mintAndTransfer(_rewardTokenAddress, recipient, amount) : _safeTransfer(_rewardTokenAddress, recipient, amount);
        }
        payable(recipient).transfer(amount);
    }

    /** @dev transfers the input amount from the caller liquidity mining contract to the extension.
      * @param amount amount of erc20 to transfer back or burn.
     */
    function backToYou(uint256 amount) payable public virtual override liquidityMiningOnly {
        if(_rewardTokenAddress != address(0)) {
            _safeTransferFrom(_rewardTokenAddress, msg.sender, address(this), amount);
            if(_byMint) {
                _burn(_rewardTokenAddress, amount);
            }
        } else {
            require(msg.value == amount, "invalid sent amount");
        }
    }

    /** @dev this function calls the liquidity mining contract with the given address and sets the given liquidity mining setups.
      * @param liquidityMiningSetups array containing all the liquidity mining setups.
      * @param setPinned if we're updating the pinned setup or not.
      * @param pinnedIndex new pinned setup index.
     */
    function setLiquidityMiningSetups(LiquidityMiningSetupConfiguration[] memory liquidityMiningSetups, bool clearPinned, bool setPinned, uint256 pinnedIndex) public virtual override hostOnly {
        ILiquidityMining(_liquidityMiningContract).setLiquidityMiningSetups(liquidityMiningSetups, clearPinned, setPinned, pinnedIndex);
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