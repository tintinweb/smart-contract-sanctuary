/**
 *Submitted for verification at polygonscan.com on 2022-01-21
*/

// Sources flattened with hardhat v2.6.5 https://hardhat.org

// File contracts/libs/TransferHelper.sol

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value, gas: 5000}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}


// File contracts/interfaces/INestBatchPriceView.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev This contract implemented the mining logic of nest
interface INestBatchPriceView {
    
    /// @dev Get the latest trigger price
    /// @param channelId 报价通道编号
    /// @param pairIndex 报价对编号
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    function triggeredPrice(uint channelId, uint pairIndex) external view returns (uint blockNumber, uint price);

    /// @dev Get the full information of latest trigger price
    /// @param channelId 报价通道编号
    /// @param pairIndex 报价对编号
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    /// @return avgPrice Average price
    /// @return sigmaSQ The square of the volatility (18 decimal places). The current implementation assumes that 
    ///         the volatility cannot exceed 1. Correspondingly, when the return value is equal to 999999999999996447,
    ///         it means that the volatility has exceeded the range that can be expressed
    function triggeredPriceInfo(uint channelId, uint pairIndex) external view returns (
        uint blockNumber,
        uint price,
        uint avgPrice,
        uint sigmaSQ
    );

    /// @dev Find the price at block number
    /// @param channelId 报价通道编号
    /// @param pairIndex 报价对编号
    /// @param height Destination block number
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    function findPrice(
        uint channelId, 
        uint pairIndex,
        uint height
    ) external view returns (uint blockNumber, uint price);

    /// @dev Get the last (num) effective price
    /// @param channelId 报价通道编号
    /// @param pairIndex 报价对编号
    /// @param count The number of prices that want to return
    /// @return An array which length is num * 2, each two element expresses one price like blockNumber｜price
    function lastPriceList(uint channelId, uint pairIndex, uint count) external view returns (uint[] memory);

    /// @dev Returns lastPriceList and triggered price info
    /// @param channelId 报价通道编号
    /// @param pairIndex 报价对编号
    /// @param count The number of prices that want to return
    /// @return prices An array which length is num * 2, each two element expresses one price like blockNumber｜price
    /// @return triggeredPriceBlockNumber The block number of triggered price
    /// @return triggeredPriceValue The token triggered price. (1eth equivalent to (price) token)
    /// @return triggeredAvgPrice Average price
    /// @return triggeredSigmaSQ The square of the volatility (18 decimal places). The current implementation 
    /// assumes that the volatility cannot exceed 1. Correspondingly, when the return value is equal to 
    /// 999999999999996447, it means that the volatility has exceeded the range that can be expressed
    function lastPriceListAndTriggeredPriceInfo(uint channelId, uint pairIndex, uint count) external view 
    returns (
        uint[] memory prices,
        uint triggeredPriceBlockNumber,
        uint triggeredPriceValue,
        uint triggeredAvgPrice,
        uint triggeredSigmaSQ
    );
}


// File contracts/interfaces/INestBatchPrice2.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev This contract implemented the mining logic of nest
interface INestBatchPrice2 {

    /// @dev Get the latest trigger price
    /// @param channelId 报价通道编号
    /// @param pairIndices 报价对编号
    /// @param payback 如果费用有多余的，则退回到此地址
    /// @return prices 价格数组, i * 2 为第i个价格所在区块, i * 2 + 1 为第i个价格
    function triggeredPrice(
        uint channelId,
        uint[] calldata pairIndices, 
        address payback
    ) external payable returns (uint[] memory prices);

    /// @dev Get the full information of latest trigger price
    /// @param channelId 报价通道编号
    /// @param pairIndices 报价对编号
    /// @param payback 如果费用有多余的，则退回到此地址
    /// @return prices 价格数组, i * 4 为第i个价格所在区块, i * 4 + 1 为第i个价格, 
    ///         i * 4 + 2 为第i个平均价格, i * 4 + 3 为第i个波动率
    function triggeredPriceInfo(
        uint channelId, 
        uint[] calldata pairIndices,
        address payback
    ) external payable returns (uint[] memory prices);

    /// @dev Find the price at block number
    /// @param channelId 报价通道编号
    /// @param pairIndices 报价对编号
    /// @param height Destination block number
    /// @param payback 如果费用有多余的，则退回到此地址
    /// @return prices 价格数组, i * 2 为第i个价格所在区块, i * 2 + 1 为第i个价格
    function findPrice(
        uint channelId,
        uint[] calldata pairIndices, 
        uint height, 
        address payback
    ) external payable returns (uint[] memory prices);

    /// @dev Get the last (num) effective price
    /// @param channelId 报价通道编号
    /// @param pairIndices 报价对编号
    /// @param count The number of prices that want to return
    /// @param payback 如果费用有多余的，则退回到此地址
    /// @return prices 结果数组，第 i * count * 2 到 (i + 1) * count * 2 - 1为第i组报价对的价格结果
    function lastPriceList(
        uint channelId, 
        uint[] calldata pairIndices, 
        uint count, 
        address payback
    ) external payable returns (uint[] memory prices);

    /// @dev Returns lastPriceList and triggered price info
    /// @param channelId 报价通道编号
    /// @param pairIndices 报价对编号
    /// @param count The number of prices that want to return
    /// @param payback 如果费用有多余的，则退回到此地址
    /// @return prices 结果数组，第 i * (count * 2 + 4)到 (i + 1) * (count * 2 + 4)- 1为第i组报价对的价格结果
    ///         其中前count * 2个为最新价格，后4个依次为：触发价格区块号，触发价格，平均价格，波动率
    function lastPriceListAndTriggeredPriceInfo(
        uint channelId, 
        uint[] calldata pairIndices,
        uint count, 
        address payback
    ) external payable returns (uint[] memory prices);
}


// File contracts/libs/IERC20.sol

// MIT

pragma solidity ^0.8.6;

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


// File contracts/interfaces/INestBatchMining.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev This interface defines the mining methods for nest
interface INestBatchMining {
    
    /// @dev 开通报价通道
    /// @param channelId 报价通道编号
    /// @param token0 计价代币地址。0表示eth
    /// @param unit token0的单位
    /// @param reward 挖矿代币地址。0表示不挖矿
    event Open(uint channelId, address token0, uint unit, address reward);

    /// @dev Post event
    /// @param channelId 报价通道编号
    /// @param pairIndex 报价对编号
    /// @param miner Address of miner
    /// @param index Index of the price sheet
    /// @param scale 报价规模
    event Post(uint channelId, uint pairIndex, address miner, uint index, uint scale, uint price);

    /* ========== Structures ========== */
    
    /// @dev Nest mining configuration structure
    struct Config {
        
        // -- Public configuration
        // The number of times the sheet assets have doubled. 4
        uint8 maxBiteNestedLevel;
        
        // Price effective block interval. 20
        uint16 priceEffectSpan;

        // The amount of nest to pledge for each post (Unit: 1000). 100
        uint16 pledgeNest;
    }

    /// @dev PriceSheetView structure
    struct PriceSheetView {
        
        // Index of the price sheet
        uint32 index;

        // Address of miner
        address miner;

        // The block number of this price sheet packaged
        uint32 height;

        // The remain number of this price sheet
        uint32 remainNum;

        // The eth number which miner will got
        uint32 ethNumBal;

        // The eth number which equivalent to token's value which miner will got
        uint32 tokenNumBal;

        // The pledged number of nest in this sheet. (Unit: 1000nest)
        uint24 nestNum1k;

        // The level of this sheet. 0 expresses initial price sheet, a value greater than 0 expresses bite price sheet
        uint8 level;

        // Post fee shares, if there are many sheets in one block, this value is used to divide up mining value
        uint8 shares;

        // The token price. (1eth equivalent to (price) token)
        uint152 price;
    }

    // 报价通道配置
    struct ChannelConfig {
        // // 计价代币地址, 0表示eth
        // address token0;
        // // 计价代币单位
        // uint96 unit;

        // // 矿币地址如果和token0或者token1是一种币，可能导致挖矿资产被当成矿币挖走
        // // 出矿代币地址
        // address reward;
        // 每个区块的标准出矿量
        uint96 rewardPerBlock;

        // 矿币总量
        //uint96 vault;

        // 管理地址
        //address governance;
        // 创世区块
        //uint32 genesisBlock;
        // Post fee(0.0001eth，DIMI_ETHER). 1000
        uint16 postFeeUnit;
        // Single query fee (0.0001 ether, DIMI_ETHER). 100
        uint16 singleFee;
        // 衰减系数，万分制。8000
        uint16 reductionRate;

        //address[] tokens;
    }

    /// @dev 报价对视图
    struct PairView {
        // 报价代币地址
        address target;
        // 报价单数量
        uint96 sheetCount;
    }

    /// @dev Price channel view
    struct PriceChannelView {
        
        uint channelId;

        // 计价代币地址, 0表示eth
        address token0;
        // 计价代币单位
        uint96 unit;

        // 矿币地址如果和token0或者token1是一种币，可能导致挖矿资产被当成矿币挖走
        // 出矿代币地址
        address reward;
        // 每个区块的标准出矿量
        uint96 rewardPerBlock;

        // 矿币总量
        uint128 vault;
        // The information of mining fee
        uint96 rewards;
        // Post fee(0.0001eth，DIMI_ETHER). 1000
        uint16 postFeeUnit;
        // 报价对数量
        uint16 count;

        // 开通者地址
        address opener;
        // 创世区块
        uint32 genesisBlock;
        // Single query fee (0.0001 ether, DIMI_ETHER). 100
        uint16 singleFee;
        // 衰减系数，万分制。8000
        uint16 reductionRate;
        
        // 报价对信息
        PairView[] pairs;
    }

    /* ========== Configuration ========== */

    /// @dev Modify configuration
    /// @param config Configuration object
    function setConfig(Config calldata config) external;

    /// @dev Get configuration
    /// @return Configuration object
    function getConfig() external view returns (Config memory);

    /// @dev 开通报价通道
    /// @param token0 计价代币地址, 0表示eth
    /// @param unit 计价代币单位
    /// @param reward 出矿代币地址
    /// @param tokens 报价代币数组
    /// @param config 报价通道配置
    function open(
        address token0, 
        uint96 unit, 
        address reward, 
        address[] calldata tokens,
        ChannelConfig calldata config
    ) external;

    /// @dev 修改通道配置
    /// @param channelId 报价通道
    /// @param config 报价通道配置
    function modify(uint channelId, ChannelConfig calldata config) external;

    /// @dev 向报价通道注入矿币
    /// @param channelId 报价通道
    /// @param vault 注入矿币数量
    function increase(uint channelId, uint128 vault) external payable;

    /// @dev 从报价通道取出矿币
    /// @param channelId 报价通道
    /// @param vault 注入矿币数量
    function decrease(uint channelId, uint128 vault) external;

    /// @dev 获取报价通道信息
    /// @param channelId 报价通道
    /// @return 报价通道信息
    function getChannelInfo(uint channelId) external view returns (PriceChannelView memory);

    /// @dev 报价
    /// @param channelId 报价通道id
    /// @param scale 报价规模（token0，单位unit）
    /// @param equivalents 价格数组，索引和报价对一一对应
    function post(uint channelId, uint scale, uint[] calldata equivalents) external payable;

    /// @notice Call the function to buy TOKEN/NTOKEN from a posted price sheet
    /// @dev bite TOKEN(NTOKEN) by ETH,  (+ethNumBal, -tokenNumBal)
    /// @param channelId 报价通道编号
    /// @param pairIndex 报价对编号。吃单方向为拿走计价代币时，直接传报价对编号，吃单方向为拿走报价代币时，报价对编号加65536
    /// @param index The position of the sheet in priceSheetList[token]
    /// @param takeNum The amount of biting (in the unit of ETH), realAmount = takeNum * newTokenAmountPerEth
    /// @param newEquivalent The new price of token (1 ETH : some TOKEN), here some means newTokenAmountPerEth
    function take(uint channelId, uint pairIndex, uint index, uint takeNum, uint newEquivalent) external payable;

    /// @dev List sheets by page
    /// @param channelId 报价通道编号
    /// @param pairIndex 报价对编号
    /// @param offset Skip previous (offset) records
    /// @param count Return (count) records
    /// @param order Order. 0 reverse order, non-0 positive order
    /// @return List of price sheets
    function list(
        uint channelId, 
        uint pairIndex, 
        uint offset, 
        uint count, 
        uint order
    ) external view returns (PriceSheetView[] memory);

    /// @notice Close a batch of price sheets passed VERIFICATION-PHASE
    /// @dev Empty sheets but in VERIFICATION-PHASE aren't allowed
    /// @param channelId 报价通道编号
    /// @param indices 报价单二维数组，外层对应通道号，内层对应报价单号，如果仅关闭后面的报价对，则前面的报价对数组传空数组
    function close(uint channelId, uint[][] calldata indices) external;

    /// @dev View the number of assets specified by the user
    /// @param tokenAddress Destination token address
    /// @param addr Destination address
    /// @return Number of assets
    function balanceOf(address tokenAddress, address addr) external view returns (uint);

    /// @dev Withdraw assets
    /// @param tokenAddress Destination token address
    /// @param value The value to withdraw
    function withdraw(address tokenAddress, uint value) external;

    /// @dev Estimated mining amount
    /// @param channelId 报价通道编号
    /// @return Estimated mining amount
    function estimate(uint channelId) external view returns (uint);

    /// @dev Query the quantity of the target quotation
    /// @param channelId 报价通道编号
    /// @param index The index of the sheet
    /// @return minedBlocks Mined block period from previous block
    /// @return totalShares Total shares of sheets in the block
    function getMinedBlocks(
        uint channelId,
        uint index
    ) external view returns (uint minedBlocks, uint totalShares);

    /// @dev The function returns eth rewards of specified ntoken
    /// @param channelId 报价通道编号
    function totalETHRewards(uint channelId) external view returns (uint);

    /// @dev Pay
    /// @param channelId 报价通道编号
    /// @param to Address to receive
    /// @param value Amount to receive
    function pay(uint channelId, address to, uint value) external;

    /// @dev 向DAO捐赠
    /// @param channelId 报价通道
    /// @param value Amount to receive
    function donate(uint channelId, uint value) external;
}


// File contracts/interfaces/INestLedger.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev This interface defines the nest ledger methods
interface INestLedger {

    /// @dev Application Flag Changed event
    /// @param addr DAO application contract address
    /// @param flag Authorization flag, 1 means authorization, 0 means cancel authorization
    event ApplicationChanged(address addr, uint flag);
    
    /// @dev Set DAO application
    /// @param addr DAO application contract address
    /// @param flag Authorization flag, 1 means authorization, 0 means cancel authorization
    function setApplication(address addr, uint flag) external;

    /// @dev Check DAO application flag
    /// @param addr DAO application contract address
    /// @return Authorization flag, 1 means authorization, 0 means cancel authorization
    function checkApplication(address addr) external view returns (uint);

    /// @dev Add reward
    /// @param channelId 报价通道
    function addETHReward(uint channelId) external payable;

    /// @dev The function returns eth rewards of specified ntoken
    /// @param channelId 报价通道
    function totalETHRewards(uint channelId) external view returns (uint);

    /// @dev Pay
    /// @param channelId 报价通道
    /// @param tokenAddress Token address of receiving funds (0 means ETH)
    /// @param to Address to receive
    /// @param value Amount to receive
    function pay(uint channelId, address tokenAddress, address to, uint value) external;
}


// File contracts/interfaces/INToken.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev ntoken interface
interface INToken {
        
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @dev Mint 
    /// @param value The amount of NToken to add
    function increaseTotal(uint256 value) external;

    /// @notice The view of variables about minting 
    /// @dev The naming follows nest v3.0
    /// @return createBlock The block number where the contract was created
    /// @return recentlyUsedBlock The block number where the last minting went
    function checkBlockInfo() external view returns(uint256 createBlock, uint256 recentlyUsedBlock);

    /// @dev The ABI keeps unchanged with old NTokens, so as to support token-and-ntoken-mining
    /// @return The address of bidder
    function checkBidder() external view returns(address);
    
    /// @notice The view of totalSupply
    /// @return The total supply of ntoken
    function totalSupply() external view returns (uint256);

    /// @dev The view of balances
    /// @param owner The address of an account
    /// @return The balance of the account
    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256); 

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);
}


// File contracts/custom/ChainConfig.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev Base contract of nest
contract ChainConfig {

    // ******** 以太坊 ******** //

    // // Ethereum average block time interval, 14000 milliseconds
    // uint constant ETHEREUM_BLOCK_TIMESPAN = 14000;

    // // Nest ore drawing attenuation interval. 2400000 blocks, about one year
    // uint constant NEST_REDUCTION_SPAN = 2400000;
    // // The decay limit of nest ore drawing becomes stable after exceeding this interval. 
    // // 24 million blocks, about 10 years
    // uint constant NEST_REDUCTION_LIMIT = 24000000; //NEST_REDUCTION_SPAN * 10;
    // // Attenuation gradient array, each attenuation step value occupies 16 bits. The attenuation value is an integer
    // uint constant NEST_REDUCTION_STEPS = 0x280035004300530068008300A300CC010001400190;
    //     // 0
    //     // | (uint(400 / uint(1)) << (16 * 0))
    //     // | (uint(400 * 8 / uint(10)) << (16 * 1))
    //     // | (uint(400 * 8 * 8 / uint(10 * 10)) << (16 * 2))
    //     // | (uint(400 * 8 * 8 * 8 / uint(10 * 10 * 10)) << (16 * 3))
    //     // | (uint(400 * 8 * 8 * 8 * 8 / uint(10 * 10 * 10 * 10)) << (16 * 4))
    //     // | (uint(400 * 8 * 8 * 8 * 8 * 8 / uint(10 * 10 * 10 * 10 * 10)) << (16 * 5))
    //     // | (uint(400 * 8 * 8 * 8 * 8 * 8 * 8 / uint(10 * 10 * 10 * 10 * 10 * 10)) << (16 * 6))
    //     // | (uint(400 * 8 * 8 * 8 * 8 * 8 * 8 * 8 / uint(10 * 10 * 10 * 10 * 10 * 10 * 10)) << (16 * 7))
    //     // | (uint(400 * 8 * 8 * 8 * 8 * 8 * 8 * 8 * 8 / uint(10 * 10 * 10 * 10 * 10 * 10 * 10 * 10)) << (16 * 8))
    //     // | (uint(400 * 8 * 8 * 8 * 8 * 8 * 8 * 8 * 8 * 8 / uint(10 * 10 * 10 * 10 * 10 * 10 * 10 * 10 * 10)) << (16 * 9))
    //     // //| (uint(400 * 8 * 8 * 8 * 8 * 8 * 8 * 8 * 8 * 8 * 8 / uint(10 * 10 * 10 * 10 * 10 * 10 * 10 * 10 * 10 * 10)) << (16 * 10));
    //     // | (uint(40) << (16 * 10));

    // ******** BSC ******** //
    
    // // Ethereum average block time interval, 3000 milliseconds
    // uint constant ETHEREUM_BLOCK_TIMESPAN = 3000;

    // // Nest ore drawing attenuation interval. 2400000 blocks, about one year
    // uint constant NEST_REDUCTION_SPAN = 10000000;
    // // The decay limit of nest ore drawing becomes stable after exceeding this interval. 
    // // 24 million blocks, about 10 years
    // uint constant NEST_REDUCTION_LIMIT = 100000000; //NEST_REDUCTION_SPAN * 10;
    // // Attenuation gradient array, each attenuation step value occupies 16 bits. The attenuation value is an integer
    // uint constant NEST_REDUCTION_STEPS = 0x280035004300530068008300A300CC010001400190;
    //     // 0
    //     // | (uint(400 / uint(1)) << (16 * 0))
    //     // | (uint(400 * 8 / uint(10)) << (16 * 1))
    //     // | (uint(400 * 8 * 8 / uint(10 * 10)) << (16 * 2))
    //     // | (uint(400 * 8 * 8 * 8 / uint(10 * 10 * 10)) << (16 * 3))
    //     // | (uint(400 * 8 * 8 * 8 * 8 / uint(10 * 10 * 10 * 10)) << (16 * 4))
    //     // | (uint(400 * 8 * 8 * 8 * 8 * 8 / uint(10 * 10 * 10 * 10 * 10)) << (16 * 5))
    //     // | (uint(400 * 8 * 8 * 8 * 8 * 8 * 8 / uint(10 * 10 * 10 * 10 * 10 * 10)) << (16 * 6))
    //     // | (uint(400 * 8 * 8 * 8 * 8 * 8 * 8 * 8 / uint(10 * 10 * 10 * 10 * 10 * 10 * 10)) << (16 * 7))
    //     // | (uint(400 * 8 * 8 * 8 * 8 * 8 * 8 * 8 * 8 / uint(10 * 10 * 10 * 10 * 10 * 10 * 10 * 10)) << (16 * 8))
    //     // | (uint(400 * 8 * 8 * 8 * 8 * 8 * 8 * 8 * 8 * 8 / uint(10 * 10 * 10 * 10 * 10 * 10 * 10 * 10 * 10)) << (16 * 9))
    //     // //| (uint(400 * 8 * 8 * 8 * 8 * 8 * 8 * 8 * 8 * 8 * 8 / uint(10 * 10 * 10 * 10 * 10 * 10 * 10 * 10 * 10 * 10)) << (16 * 10));
    //     // | (uint(40) << (16 * 10));

    // ******** Ploygon ******** //

    // Ethereum average block time interval, 2200 milliseconds
    uint constant ETHEREUM_BLOCK_TIMESPAN = 2200;

    // Nest ore drawing attenuation interval. 2400000 blocks, about one year
    uint constant NEST_REDUCTION_SPAN = 15000000;
    // The decay limit of nest ore drawing becomes stable after exceeding this interval. 
    // 24 million blocks, about 10 years
    uint constant NEST_REDUCTION_LIMIT = 150000000; //NEST_REDUCTION_SPAN * 10;
    // Attenuation gradient array, each attenuation step value occupies 16 bits. The attenuation value is an integer
    uint constant NEST_REDUCTION_STEPS = 0x280035004300530068008300A300CC010001400190;
        // 0
        // | (uint(400 / uint(1)) << (16 * 0))
        // | (uint(400 * 8 / uint(10)) << (16 * 1))
        // | (uint(400 * 8 * 8 / uint(10 * 10)) << (16 * 2))
        // | (uint(400 * 8 * 8 * 8 / uint(10 * 10 * 10)) << (16 * 3))
        // | (uint(400 * 8 * 8 * 8 * 8 / uint(10 * 10 * 10 * 10)) << (16 * 4))
        // | (uint(400 * 8 * 8 * 8 * 8 * 8 / uint(10 * 10 * 10 * 10 * 10)) << (16 * 5))
        // | (uint(400 * 8 * 8 * 8 * 8 * 8 * 8 / uint(10 * 10 * 10 * 10 * 10 * 10)) << (16 * 6))
        // | (uint(400 * 8 * 8 * 8 * 8 * 8 * 8 * 8 / uint(10 * 10 * 10 * 10 * 10 * 10 * 10)) << (16 * 7))
        // | (uint(400 * 8 * 8 * 8 * 8 * 8 * 8 * 8 * 8 / uint(10 * 10 * 10 * 10 * 10 * 10 * 10 * 10)) << (16 * 8))
        // | (uint(400 * 8 * 8 * 8 * 8 * 8 * 8 * 8 * 8 * 8 / uint(10 * 10 * 10 * 10 * 10 * 10 * 10 * 10 * 10)) << (16 * 9))
        // //| (uint(400 * 8 * 8 * 8 * 8 * 8 * 8 * 8 * 8 * 8 * 8 / uint(10 * 10 * 10 * 10 * 10 * 10 * 10 * 10 * 10 * 10)) << (16 * 10));
        // | (uint(40) << (16 * 10));
}


// File contracts/interfaces/INestMapping.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev The interface defines methods for nest builtin contract address mapping
interface INestMapping {

    /// @dev Set the built-in contract address of the system
    /// @param nestTokenAddress Address of nest token contract
    /// @param nestNodeAddress Address of nest node contract
    /// @param nestLedgerAddress INestLedger implementation contract address
    /// @param nestMiningAddress INestMining implementation contract address for nest
    /// @param ntokenMiningAddress INestMining implementation contract address for ntoken
    /// @param nestPriceFacadeAddress INestPriceFacade implementation contract address
    /// @param nestVoteAddress INestVote implementation contract address
    /// @param nestQueryAddress INestQuery implementation contract address
    /// @param nnIncomeAddress NNIncome contract address
    /// @param nTokenControllerAddress INTokenController implementation contract address
    function setBuiltinAddress(
        address nestTokenAddress,
        address nestNodeAddress,
        address nestLedgerAddress,
        address nestMiningAddress,
        address ntokenMiningAddress,
        address nestPriceFacadeAddress,
        address nestVoteAddress,
        address nestQueryAddress,
        address nnIncomeAddress,
        address nTokenControllerAddress
    ) external;

    /// @dev Get the built-in contract address of the system
    /// @return nestTokenAddress Address of nest token contract
    /// @return nestNodeAddress Address of nest node contract
    /// @return nestLedgerAddress INestLedger implementation contract address
    /// @return nestMiningAddress INestMining implementation contract address for nest
    /// @return ntokenMiningAddress INestMining implementation contract address for ntoken
    /// @return nestPriceFacadeAddress INestPriceFacade implementation contract address
    /// @return nestVoteAddress INestVote implementation contract address
    /// @return nestQueryAddress INestQuery implementation contract address
    /// @return nnIncomeAddress NNIncome contract address
    /// @return nTokenControllerAddress INTokenController implementation contract address
    function getBuiltinAddress() external view returns (
        address nestTokenAddress,
        address nestNodeAddress,
        address nestLedgerAddress,
        address nestMiningAddress,
        address ntokenMiningAddress,
        address nestPriceFacadeAddress,
        address nestVoteAddress,
        address nestQueryAddress,
        address nnIncomeAddress,
        address nTokenControllerAddress
    );

    /// @dev Get address of nest token contract
    /// @return Address of nest token contract
    function getNestTokenAddress() external view returns (address);

    /// @dev Get address of nest node contract
    /// @return Address of nest node contract
    function getNestNodeAddress() external view returns (address);

    /// @dev Get INestLedger implementation contract address
    /// @return INestLedger implementation contract address
    function getNestLedgerAddress() external view returns (address);

    /// @dev Get INestMining implementation contract address for nest
    /// @return INestMining implementation contract address for nest
    function getNestMiningAddress() external view returns (address);

    /// @dev Get INestMining implementation contract address for ntoken
    /// @return INestMining implementation contract address for ntoken
    function getNTokenMiningAddress() external view returns (address);

    /// @dev Get INestPriceFacade implementation contract address
    /// @return INestPriceFacade implementation contract address
    function getNestPriceFacadeAddress() external view returns (address);

    /// @dev Get INestVote implementation contract address
    /// @return INestVote implementation contract address
    function getNestVoteAddress() external view returns (address);

    /// @dev Get INestQuery implementation contract address
    /// @return INestQuery implementation contract address
    function getNestQueryAddress() external view returns (address);

    /// @dev Get NNIncome contract address
    /// @return NNIncome contract address
    function getNnIncomeAddress() external view returns (address);

    /// @dev Get INTokenController implementation contract address
    /// @return INTokenController implementation contract address
    function getNTokenControllerAddress() external view returns (address);

    /// @dev Registered address. The address registered here is the address accepted by nest system
    /// @param key The key
    /// @param addr Destination address. 0 means to delete the registration information
    function registerAddress(string memory key, address addr) external;

    /// @dev Get registered address
    /// @param key The key
    /// @return Destination address. 0 means empty
    function checkAddress(string memory key) external view returns (address);
}


// File contracts/interfaces/INestGovernance.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;
/// @dev This interface defines the governance methods
interface INestGovernance is INestMapping {

    /// @dev Set governance authority
    /// @param addr Destination address
    /// @param flag Weight. 0 means to delete the governance permission of the target address. Weight is not 
    ///        implemented in the current system, only the difference between authorized and unauthorized. 
    ///        Here, a uint96 is used to represent the weight, which is only reserved for expansion
    function setGovernance(address addr, uint flag) external;

    /// @dev Get governance rights
    /// @param addr Destination address
    /// @return Weight. 0 means to delete the governance permission of the target address. Weight is not 
    ///        implemented in the current system, only the difference between authorized and unauthorized. 
    ///        Here, a uint96 is used to represent the weight, which is only reserved for expansion
    function getGovernance(address addr) external view returns (uint);

    /// @dev Check whether the target address has governance rights for the given target
    /// @param addr Destination address
    /// @param flag Permission weight. The permission of the target address must be greater than this weight 
    /// to pass the check
    /// @return True indicates permission
    function checkGovernance(address addr, uint flag) external view returns (bool);
}


// File contracts/NestBase.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;
/// @dev Base contract of nest
contract NestBase {

    /// @dev To support open-zeppelin/upgrades
    /// @param governance INestGovernance implementation contract address
    function initialize(address governance) public virtual {
        require(_governance == address(0), "NEST:!initialize");
        _governance = governance;
    }

    /// @dev INestGovernance implementation contract address
    address public _governance;

    /// @dev Rewritten in the implementation contract, for load other contract addresses. Call 
    ///      super.update(newGovernance) when overriding, and override method without onlyGovernance
    /// @param newGovernance INestGovernance implementation contract address
    function update(address newGovernance) public virtual {
        address governance = _governance;
        require(governance == msg.sender || INestGovernance(governance).checkGovernance(msg.sender, 0), "NEST:!gov");
        _governance = newGovernance;
    }

    // /// @dev Migrate funds from current contract to NestLedger
    // /// @param tokenAddress Destination token address.(0 means eth)
    // /// @param value Migrate amount
    // function migrate(address tokenAddress, uint value) external onlyGovernance {

    //     address to = INestGovernance(_governance).getNestLedgerAddress();
    //     if (tokenAddress == address(0)) {
    //         INestLedger(to).addETHReward { value: value } (0);
    //     } else {
    //         TransferHelper.safeTransfer(tokenAddress, to, value);
    //     }
    // }

    //---------modifier------------

    modifier onlyGovernance() {
        require(INestGovernance(_governance).checkGovernance(msg.sender, 0), "NEST:!gov");
        _;
    }

    modifier noContract() {
        require(msg.sender == tx.origin, "NEST:!contract");
        _;
    }
}


// File contracts/custom/NestFrequentlyUsed.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;
/// @dev Base contract of nest
contract NestFrequentlyUsed is NestBase {

    // Address of nest token contract
    address constant NEST_TOKEN_ADDRESS = 0x98f8669F6481EbB341B522fCD3663f79A3d1A6A7;

    // Genesis block number of nest
    // NEST token contract is created at block height 6913517. However, because the mining algorithm of nest1.0
    // is different from that at present, a new mining algorithm is adopted from nest2.0. The new algorithm
    // includes the attenuation logic according to the block. Therefore, it is necessary to trace the block
    // where the nest begins to decay. According to the circulation when nest2.0 is online, the new mining
    // algorithm is used to deduce and convert the nest, and the new algorithm is used to mine the nest2.0
    // on-line flow, the actual block is 5120000
    //uint constant NEST_GENESIS_BLOCK = 0;

}


// File contracts/NestBatchMining.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;
/// @dev This contract implemented the mining logic of nest
contract NestBatchMining is ChainConfig, NestFrequentlyUsed, INestBatchMining {

    /// @dev To support open-zeppelin/upgrades
    /// @param nestGovernanceAddress INestGovernance implementation contract address
    function initialize(address nestGovernanceAddress) public override {
        super.initialize(nestGovernanceAddress);
        // Placeholder in _accounts, the index of a real account must greater than 0
        _accounts.push();
    }

    /// @dev Definitions for the price sheet, include the full information. 
    /// (use 256-bits, a storage unit in ethereum evm)
    struct PriceSheet {
        
        // Index of miner account in _accounts. for this way, mapping an address(which need 160-bits) to a 32-bits 
        // integer, support 4 billion accounts
        uint32 miner;

        // The block number of this price sheet packaged
        uint32 height;

        // The remain number of this price sheet
        uint32 remainNum;

        // The eth number which miner will got
        uint32 ethNumBal;

        // The eth number which equivalent to token's value which miner will got
        uint32 tokenNumBal;

        // The pledged number of nest in this sheet. (Unit: 1000nest)
        uint24 nestNum1k;

        // The level of this sheet. 0 expresses initial price sheet, a value greater than 0 expresses bite price sheet
        uint8 level;

        // Post fee shares, if there are many sheets in one block, this value is used to divide up mining value
        uint8 shares;

        // Represent price as this way, may lose precision, the error less than 1/10^14
        // price = priceFraction * 16 ^ priceExponent
        uint56 priceFloat;
    }

    /// @dev Definitions for the price information
    struct PriceInfo {

        // Record the index of price sheet, for update price information from price sheet next time.
        uint32 index;

        // The block number of this price
        uint32 height;

        // The remain number of this price sheet
        uint32 remainNum;

        // Price, represent as float
        // Represent price as this way, may lose precision, the error less than 1/10^14
        uint56 priceFloat;

        // Avg Price, represent as float
        // Represent price as this way, may lose precision, the error less than 1/10^14
        uint56 avgFloat;

        // Square of price volatility, need divide by 2^48
        uint48 sigmaSQ;
    }

    // 报价对
    struct PricePair {
        address target;
        PriceInfo price;
        PriceSheet[] sheets;    
    }

    /// @dev Price channel
    struct PriceChannel {

        // 计价代币地址, 0表示eth
        address token0;
        // 计价代币单位
        uint96 unit;

        // 出矿代币地址
        address reward;        
        // 每个区块的标准出矿量
        uint96 rewardPerBlock;

        // 矿币总量
        uint128 vault;        
        // The information of mining fee
        uint96 rewards;
        // Post fee(0.0001eth，DIMI_ETHER). 1000
        uint16 postFeeUnit;
        // 报价对数量
        uint16 count;

        // 开通者地址
        address opener;
        // 创世区块
        uint32 genesisBlock;
        // Single query fee (0.0001 ether, DIMI_ETHER). 100
        uint16 singleFee;
        // 衰减系数，万分制。8000
        uint16 reductionRate;
        
        // 报价对数组
        PricePair[0xFFFF] pairs;
    }

    /// @dev Structure is used to represent a storage location. Storage variable can be used to avoid indexing 
    /// from mapping many times
    struct UINT {
        uint value;
    }

    /// @dev Account information
    struct Account {
        
        // Address of account
        address addr;

        // Balances of mining account
        // tokenAddress=>balance
        mapping(address=>UINT) balances;
    }

    // Configuration
    Config _config;

    // Registered account information
    Account[] _accounts;

    // Mapping from address to index of account. address=>accountIndex
    mapping(address=>uint) _accountMapping;

    // 报价通道映射，通过此映射避免重复添加报价通道
    //mapping(uint=>uint) _channelMapping;

    // 报价通道
    PriceChannel[] _channels;

    // Unit of post fee. 0.0001 ether
    uint constant DIMI_ETHER = 0.0001 ether;

    /* ========== Governance ========== */

    /// @dev Modify configuration
    /// @param config Configuration object
    function setConfig(Config calldata config) external override onlyGovernance {
        _config = config;
    }

    /// @dev Get configuration
    /// @return Configuration object
    function getConfig() external view override returns (Config memory) {
        return _config;
    }

    /// @dev 开通报价通道
    /// @param token0 计价代币地址, 0表示eth
    /// @param unit 计价代币单位
    /// @param reward 出矿代币地址
    /// @param tokens 报价代币数组
    /// @param config 报价通道配置
    function open(
        address token0, 
        uint96 unit, 
        address reward, 
        address[] calldata tokens,
        ChannelConfig calldata config
    ) external override {

        //// 计价代币
        //address token0 = config.token0;
        // 矿币
        //address reward = config.reward;

        // 触发开通事件
        emit Open(_channels.length, token0, unit, reward);
        
        PriceChannel storage channel = _channels.push();

        // 计价代币
        channel.token0 = token0;
        // 计价代币单位
        channel.unit = unit;

        // 矿币
        channel.reward = reward;

        channel.vault = uint128(0);
        channel.rewards = uint96(0);
        channel.count = uint16(tokens.length);
        
        // 开通者地址
        channel.opener = msg.sender;
        // 创世区块
        channel.genesisBlock = uint32(block.number);

        // 遍历创建报价对
        for (uint i = 0; i < tokens.length; ++i) {
            require(token0 != tokens[i], "NOM:token can't equal token0");
            for (uint j = 0; j < i; ++j) {
                require(tokens[i] != tokens[j], "NOM:token reiterated");
            }
            channel.pairs[i].target = tokens[i];
        }

        _modify(channel, config);
    }

    /// @dev 修改通道配置
    /// @param channelId 报价通道
    /// @param config 报价通道配置
    function modify(uint channelId, ChannelConfig calldata config) external override {
        PriceChannel storage channel = _channels[channelId];
        require(channel.opener == msg.sender, "NOM:not opener");
        _modify(channel, config);
    }

    /// @dev 修改通道配置
    /// @param channel 报价通道
    /// @param config 报价通道配置
    function _modify(PriceChannel storage channel, ChannelConfig calldata config) private {
        // 单位区块出矿币数量
        channel.rewardPerBlock = config.rewardPerBlock;

        // Post fee(0.0001eth，DIMI_ETHER). 1000
        channel.postFeeUnit = config.postFeeUnit;

        // Single query fee (0.0001 ether, DIMI_ETHER). 100
        channel.singleFee = config.singleFee;
        // 衰减系数，万分制。8000
        channel.reductionRate = config.reductionRate;
    }

    /// @dev 添加报价代币，与计价代币形成新的报价对（暂不支持删除，请谨慎添加）
    /// @param channelId 报价通道
    /// @param target 目标代币地址
    function addPair(uint channelId, address target) external {
        PriceChannel storage channel = _channels[channelId];
        require(channel.opener == msg.sender, "NOM:not opener");
        require(channel.token0 != target, "NOM:token can't equal token0");
        uint count = uint(channel.count);
        for (uint j = 0; j < count; ++j) {
            require(channel.pairs[j].target != target, "NOM:token reiterated");
        }
        channel.pairs[count].target = target;
        ++channel.count;
    }

    /// @dev 向报价通道注入矿币
    /// @param channelId 报价通道
    /// @param vault 注入矿币数量
    function increase(uint channelId, uint128 vault) external payable override {
        PriceChannel storage channel = _channels[channelId];
        address reward = channel.reward;
        if (reward == address(0)) {
            require(msg.value == uint(vault), "NOM:vault error");
        } else {
            TransferHelper.safeTransferFrom(reward, msg.sender, address(this), uint(vault));
        }
        channel.vault += vault;
    }

    /// @dev 从报价通道取出矿币
    /// @param channelId 报价通道
    /// @param vault 取出矿币数量
    function decrease(uint channelId, uint128 vault) external override {
        PriceChannel storage channel = _channels[channelId];
        require(channel.opener == msg.sender, "NOM:not opener");
        address reward = channel.reward;
        channel.vault -= vault;
        if (reward == address(0)) {
            payable(msg.sender).transfer(uint(vault));
        } else {
            TransferHelper.safeTransfer(reward, msg.sender, uint(vault));
        }
    }

    /// @dev 修改治理权限地址
    /// @param channelId 报价通道
    /// @param newOpener 新治理权限地址
    function changeOpener(uint channelId, address newOpener) external {
        PriceChannel storage channel = _channels[channelId];
        require(channel.opener == msg.sender, "NOM:not opener");
        channel.opener = newOpener;
    }

    /// @dev 获取报价通道信息
    /// @param channelId 报价通道
    /// @return 报价通道信息
    function getChannelInfo(uint channelId) external view override returns (PriceChannelView memory) {
        PriceChannel storage channel = _channels[channelId];

        uint count = uint(channel.count);
        PairView[] memory pairs = new PairView[](count);
        for (uint i = 0; i < count; ++i) {
            PricePair storage pair = channel.pairs[i];
            pairs[i] = PairView(pair.target, uint96(pair.sheets.length));
        }

        return PriceChannelView (
            channelId,

            // 计价代币地址, 0表示eth
            channel.token0,
            // 计价代币单位
            channel.unit,

            // 矿币地址如果和token0或者token1是一种币，可能导致挖矿资产被当成矿币挖走
            // 出矿代币地址
            channel.reward,
            // 每个区块的标准出矿量
            channel.rewardPerBlock,

            // 矿币总量
            channel.vault,
            // The information of mining fee
            channel.rewards,
            // Post fee(0.0001eth，DIMI_ETHER). 1000
            channel.postFeeUnit,
            // 报价对数量
            channel.count,

            // 开通者地址
            channel.opener,
            // 创世区块
            channel.genesisBlock,
            // Single query fee (0.0001 ether, DIMI_ETHER). 100
            channel.singleFee,
            // 衰减系数，万分制。8000
            channel.reductionRate,

            pairs
        );
    }

    /* ========== Mining ========== */

    /// @dev 报价
    /// @param channelId 报价通道id
    /// @param scale 报价规模（token0，单位unit）
    /// @param equivalents 价格数组，索引和报价对一一对应
    function post(uint channelId, uint scale, uint[] calldata equivalents) external payable override {

        // 0. 加载配置
        Config memory config = _config;

        // 1. Check arguments
        require(scale == 1, "NOM:!scale");

        // 2. Load price channel
        PriceChannel storage channel = _channels[channelId];

        // 3. Freeze assets
        uint accountIndex = _addressIndex(msg.sender);
        // Freeze token and nest
        // Because of the use of floating-point representation(fraction * 16 ^ exponent), it may bring some precision 
        // loss After assets are frozen according to tokenAmountPerEth * ethNum, the part with poor accuracy may be 
        // lost when the assets are returned, It should be frozen according to decodeFloat(fraction, exponent) * ethNum
        // However, considering that the loss is less than 1 / 10 ^ 14, the loss here is ignored, and the part of
        // precision loss can be transferred out as system income in the future
        mapping(address=>UINT) storage balances = _accounts[accountIndex].balances;

        uint cn = uint(channel.count);
        uint fee = msg.value;

        // 冻结nest
        fee = _freeze(balances, NEST_TOKEN_ADDRESS, cn * uint(config.pledgeNest) * 1000 ether, fee);
    
        // 冻结token0
        fee = _freeze(balances, channel.token0, cn * uint(channel.unit) * scale, fee);

        // 冻结token1
        while (cn > 0) {
            PricePair storage pair = channel.pairs[--cn];
            uint equivalent = equivalents[cn];
            require(equivalent > 0, "NOM:!equivalent");
            fee = _freeze(balances, pair.target, scale * equivalent, fee);

            // Calculate the price
            // According to the current mechanism, the newly added sheet cannot take effect, so the calculated price
            // is placed before the sheet is added, which can reduce unnecessary traversal
            _stat(config, pair);
            
            // 6. Create token price sheet
            emit Post(channelId, cn, msg.sender, pair.sheets.length, scale, equivalent);
            // 只有0号报价对挖矿
            _create(pair.sheets, accountIndex, uint32(scale), uint(config.pledgeNest), cn == 0 ? 1 : 0, equivalent);
        }

        // 4. Deposit fee
        // 只有配置了报价佣金时才检查fee
        uint postFeeUnit = uint(channel.postFeeUnit);
        if (postFeeUnit > 0) {
            require(fee >= postFeeUnit * DIMI_ETHER + tx.gasprice * 400000, "NM:!fee");
        }
        if (fee > 0) {
            channel.rewards += _toUInt96(fee);
        }
    }

    /// @notice Call the function to buy TOKEN/NTOKEN from a posted price sheet
    /// @dev bite TOKEN(NTOKEN) by ETH,  (+ethNumBal, -tokenNumBal)
    /// @param channelId 报价通道编号
    /// @param pairIndex 报价对编号。吃单方向为拿走计价代币时，直接传报价对编号，吃单方向为拿走报价代币时，报价对编号加65536
    /// @param index The position of the sheet in priceSheetList[token]
    /// @param takeNum The amount of biting (in the unit of ETH), realAmount = takeNum * newTokenAmountPerEth
    /// @param newEquivalent The new price of token (1 ETH : some TOKEN), here some means newTokenAmountPerEth
    function take(
        uint channelId, 
        uint pairIndex, 
        uint index, 
        uint takeNum, 
        uint newEquivalent
    ) external payable override {

        Config memory config = _config;

        // 1. Check arguments
        require(takeNum > 0, "NM:!takeNum");
        require(newEquivalent > 0, "NM:!price");

        // 2. Load price sheet
        PriceChannel storage channel = _channels[channelId];
        PricePair storage pair = channel.pairs[pairIndex < 0x10000 ? pairIndex : pairIndex - 0x10000];
        //PriceSheet[] storage sheets = pair.sheets;
        PriceSheet memory sheet = pair.sheets[index];

        // 3. Check state
        //require(uint(sheet.remainNum) >= takeNum, "NM:!remainNum");
        require(uint(sheet.height) + uint(config.priceEffectSpan) >= block.number, "NM:!state");
        sheet.remainNum = uint32(uint(sheet.remainNum) - takeNum);

        uint accountIndex = _addressIndex(msg.sender);
        // Number of nest to be pledged
        // sheet.ethNumBal + sheet.tokenNumBal is always two times to sheet.ethNum
        uint needNest1k = (takeNum << 2) * uint(sheet.nestNum1k) / (uint(sheet.ethNumBal) + uint(sheet.tokenNumBal));

        // 4. Calculate the number of eth, token and nest needed, and freeze them
        uint needEthNum = takeNum;
        uint level = uint(sheet.level);
        if (level < 255) {
            if (level < uint(config.maxBiteNestedLevel)) {
                // Double scale sheet
                needEthNum <<= 1;
            }
            ++level;
        }

        {
            // Freeze nest and token
            // 冻结资产：token0, token1, nest
            mapping(address=>UINT) storage balances = _accounts[accountIndex].balances;
            uint fee = msg.value;

            // 当吃单方向为拿走计价代币时，直接传报价对编号，当吃单方向为拿走报价代币时，传报价对编号减65536
            // pairIndex < 0x10000，吃单方向为拿走计价代币
            if (pairIndex < 0x10000) {
                // Update the bitten sheet
                sheet.ethNumBal = uint32(uint(sheet.ethNumBal) - takeNum);
                sheet.tokenNumBal = uint32(uint(sheet.tokenNumBal) + takeNum);
                pair.sheets[index] = sheet;

                // 冻结token0
                fee = _freeze(balances, channel.token0, (needEthNum - takeNum) * uint(channel.unit), fee);
                // 冻结token1
                fee = _freeze(
                    balances, 
                    pair.target, 
                    needEthNum * newEquivalent + _decodeFloat(sheet.priceFloat) * takeNum, 
                    fee
                );
            } 
            // pairIndex >= 0x10000，吃单方向为拿走报价代币
            else {
                pairIndex -= 0x10000;
                // Update the bitten sheet
                sheet.ethNumBal = uint32(uint(sheet.ethNumBal) + takeNum);
                sheet.tokenNumBal = uint32(uint(sheet.tokenNumBal) - takeNum);
                pair.sheets[index] = sheet;

                // 冻结token0
                fee = _freeze(balances, channel.token0, (needEthNum + takeNum) * uint(channel.unit), fee);
                // 冻结token1
                uint backTokenValue = _decodeFloat(sheet.priceFloat) * takeNum;
                if (needEthNum * newEquivalent > backTokenValue) {
                    fee = _freeze(balances, pair.target, needEthNum * newEquivalent - backTokenValue, fee);
                } else {
                    _unfreeze(balances, pair.target, backTokenValue - needEthNum * newEquivalent, msg.sender);
                }
            }
                
            // 冻结nest
            fee = _freeze(balances, NEST_TOKEN_ADDRESS, needNest1k * 1000 ether, fee);

            require(fee == 0, "NOM:!fee");
        }
            
        // 5. Calculate the price
        // According to the current mechanism, the newly added sheet cannot take effect, so the calculated price
        // is placed before the sheet is added, which can reduce unnecessary traversal
        _stat(config, pair);

        // 6. Create price sheet
        emit Post(channelId, pairIndex, msg.sender, pair.sheets.length, needEthNum, newEquivalent);
        _create(pair.sheets, accountIndex, uint32(needEthNum), needNest1k, level << 8, newEquivalent);
    }

    /// @dev List sheets by page
    /// @param channelId 报价通道编号
    /// @param pairIndex 报价对编号
    /// @param offset Skip previous (offset) records
    /// @param count Return (count) records
    /// @param order Order. 0 reverse order, non-0 positive order
    /// @return List of price sheets
    function list(
        uint channelId,
        uint pairIndex,
        uint offset,
        uint count,
        uint order
    ) external view override noContract returns (PriceSheetView[] memory) {

        PriceSheet[] storage sheets = _channels[channelId].pairs[pairIndex].sheets;
        PriceSheetView[] memory result = new PriceSheetView[](count);
        uint length = sheets.length;
        uint i = 0;

        // Reverse order
        if (order == 0) {

            uint index = length - offset;
            uint end = index > count ? index - count : 0;
            while (index > end) {
                --index;
                result[i++] = _toPriceSheetView(sheets[index], index);
            }
        } 
        // Positive order
        else {

            uint index = offset;
            uint end = index + count;
            if (end > length) {
                end = length;
            }
            while (index < end) {
                result[i++] = _toPriceSheetView(sheets[index], index);
                ++index;
            }
        }
        return result;
    }

    /// @notice Close a batch of price sheets passed VERIFICATION-PHASE
    /// @dev Empty sheets but in VERIFICATION-PHASE aren't allowed
    /// @param channelId 报价通道编号
    /// @param indices 报价单二维数组，外层对应通道号，内层对应报价单号，如果仅关闭后面的报价对，则前面的报价对数组传空数组
    function close(uint channelId, uint[][] calldata indices) external override {
        
        Config memory config = _config;
        PriceChannel storage channel = _channels[channelId];
        
        uint accountIndex = 0;
        uint reward = 0;
        uint nestNum1k = 0;
        uint ethNum = 0;

        // storage变量必须在定义时初始化，因此在此处赋值，但是由于accountIndex此时为0，此赋值没有意义
        mapping(address=>UINT) storage balances = _accounts[0/*accountIndex*/].balances;
        uint[3] memory vars = [
            uint(channel.rewardPerBlock), 
            uint(channel.genesisBlock), 
            uint(channel.reductionRate)
        ];

        for (uint j = indices.length; j > 0;) {
            PricePair storage pair = channel.pairs[--j];

            ///////////////////////////////////////////////////////////////////////////////////////
            //PriceSheet[] storage sheets = pair.sheets;

            uint tokenValue = 0;

            // 1. Traverse sheets
            for (uint i = indices[j].length; i > 0;) {

                // ---------------------------------------------------------------------------------
                uint index = indices[j][--i];
                PriceSheet memory sheet = pair.sheets[index];
                //uint height = uint(sheet.height);
                //uint minerIndex = uint(sheet.miner);
                
                // Batch closing quotation can only close sheet of the same user
                if (accountIndex == 0) {
                    // accountIndex == 0 means the first sheet, and the number of this sheet is taken
                    accountIndex = uint(sheet.miner);
                    balances = _accounts[accountIndex].balances;
                } else {
                    // accountIndex != 0 means that it is a follow-up sheet, and the miner number must be 
                    // consistent with the previous record
                    require(accountIndex == uint(sheet.miner), "NM:!miner");
                }

                // Check the status of the price sheet to see if it has reached the effective block interval 
                // or has been finished
                if (accountIndex > 0 && (uint(sheet.height) + uint(config.priceEffectSpan) < block.number)) {

                    // 后面的通道不出矿，不需要出矿逻辑
                    // 出矿按照第一个通道计算
                    if (j == 0) {
                        uint shares = uint(sheet.shares);
                        // Mining logic
                        // The price sheet which shares is zero doesn't mining
                        if (shares > 0) {

                            // Currently, mined represents the number of blocks has mined
                            (uint mined, uint totalShares) = _calcMinedBlocks(pair.sheets, index, sheet);
                            
                            // 当开通者指定的rewardPerBlock非常大时，计算出矿可能会被截断，导致实际能够得到的出矿大大减少
                            // 这种情况是不合理的，需要由开通者负责
                            reward += (
                                mined
                                * shares
                                * _reduction(uint(sheet.height) - vars[1], vars[2])
                                * vars[0]
                                / totalShares / 400
                            );
                        }
                    }

                    nestNum1k += uint(sheet.nestNum1k);
                    ethNum += uint(sheet.ethNumBal);
                    tokenValue += _decodeFloat(sheet.priceFloat) * uint(sheet.tokenNumBal);

                    // Set sheet.miner to 0, express the sheet is closed
                    sheet.miner = uint32(0);
                    sheet.ethNumBal = uint32(0);
                    sheet.tokenNumBal = uint32(0);
                    pair.sheets[index] = sheet;
                }

                // ---------------------------------------------------------------------------------
            }

            _stat(config, pair);
            ///////////////////////////////////////////////////////////////////////////////////////

            // 解冻token1
            _unfreeze(balances, pair.target, tokenValue, accountIndex);
        }

        // 解冻token0
        _unfreeze(balances, channel.token0, ethNum * uint(channel.unit), accountIndex);
        
        // 解冻nest
        _unfreeze(balances, NEST_TOKEN_ADDRESS, nestNum1k * 1000 ether, accountIndex);

        uint vault = uint(channel.vault);
        if (reward > vault) {
            reward = vault;
        }
        // 记录每个通道矿币的数量，防止开通者不打币，直接用资金池内的资金
        channel.vault = uint96(vault - reward);
        
        // 奖励矿币
        _unfreeze(balances, channel.reward, reward, accountIndex);
    }

    /// @dev View the number of assets specified by the user
    /// @param tokenAddress Destination token address
    /// @param addr Destination address
    /// @return Number of assets
    function balanceOf(address tokenAddress, address addr) external view override returns (uint) {
        return _accounts[_accountMapping[addr]].balances[tokenAddress].value;
    }

    /// @dev Withdraw assets
    /// @param tokenAddress Destination token address
    /// @param value The value to withdraw
    function withdraw(address tokenAddress, uint value) external override {

        // The user's locked nest and the mining pool's nest are stored together. When the nest is mined over,
        // the problem of taking the locked nest as the ore drawing will appear
        // As it will take a long time for nest to finish mining, this problem will not be considered for the time being
        UINT storage balance = _accounts[_accountMapping[msg.sender]].balances[tokenAddress];
        //uint balanceValue = balance.value;
        //require(balanceValue >= value, "NM:!balance");
        balance.value -= value;

        TransferHelper.safeTransfer(tokenAddress, msg.sender, value);
    }

    /// @dev Estimated mining amount
    /// @param channelId 报价通道编号
    /// @return Estimated mining amount
    function estimate(uint channelId) external view override returns (uint) {

        PriceChannel storage channel = _channels[channelId];
        PriceSheet[] storage sheets = channel.pairs[0].sheets;
        uint index = sheets.length;
        uint blocks = 10;
        while (index > 0) {

            PriceSheet memory sheet = sheets[--index];
            if (uint(sheet.shares) > 0) {
                blocks = block.number - uint(sheet.height);
                break;
            }
        }

        return 
            blocks
            * uint(channel.rewardPerBlock) 
            * _reduction(block.number - uint(channel.genesisBlock), uint(channel.reductionRate))
            / 400;
    }

    /// @dev Query the quantity of the target quotation
    /// @param channelId 报价通道编号
    /// @param index The index of the sheet
    /// @return minedBlocks Mined block period from previous block
    /// @return totalShares Total shares of sheets in the block
    function getMinedBlocks(
        uint channelId,
        uint index
    ) external view override returns (uint minedBlocks, uint totalShares) {

        // PriceSheet[] storage sheets = _channels[channelId].pairs[0].sheets;
        // PriceSheet memory sheet = sheets[index];

        // // The bite sheet or ntoken sheet doesn't mining
        // if (uint(sheet.shares) == 0) {
        //     return (0, 0);
        // }

        // return _calcMinedBlocks(sheets, index, sheet);

        PriceSheet[] storage sheets = _channels[channelId].pairs[0].sheets;
        return _calcMinedBlocks(sheets, index, sheets[index]);
    }

    /// @dev The function returns eth rewards of specified ntoken
    /// @param channelId 报价通道编号
    function totalETHRewards(uint channelId) external view override returns (uint) {
        return uint(_channels[channelId].rewards);
    }

    /// @dev Pay
    /// @param channelId 报价通道编号
    /// @param to Address to receive
    /// @param value Amount to receive
    function pay(uint channelId, address to, uint value) external override {

        PriceChannel storage channel = _channels[channelId];
        require(channel.opener == msg.sender, "NOM:!opener");
        channel.rewards -= _toUInt96(value);
        // pay
        payable(to).transfer(value);
    }

    /// @dev 向DAO捐赠
    /// @param channelId 报价通道
    /// @param value Amount to receive
    function donate(uint channelId, uint value) external override {

        PriceChannel storage channel = _channels[channelId];
        require(channel.opener == msg.sender, "NOM:!opener");
        channel.rewards -= _toUInt96(value);
        INestLedger(INestMapping(_governance).getNestLedgerAddress()).addETHReward { value: value } (channelId);
    }

    /// @dev Gets the address corresponding to the given index number
    /// @param index The index number of the specified address
    /// @return The address corresponding to the given index number
    function indexAddress(uint index) public view returns (address) {
        return _accounts[index].addr;
    }

    /// @dev Gets the registration index number of the specified address
    /// @param addr Destination address
    /// @return 0 means nonexistent, non-0 means index number
    function getAccountIndex(address addr) external view returns (uint) {
        return _accountMapping[addr];
    }

    /// @dev Get the length of registered account array
    /// @return The length of registered account array
    function getAccountCount() external view returns (uint) {
        return _accounts.length;
    }

    // Convert PriceSheet to PriceSheetView
    function _toPriceSheetView(PriceSheet memory sheet, uint index) private view returns (PriceSheetView memory) {

        return PriceSheetView(
            // Index number
            uint32(index),
            // Miner address
            indexAddress(sheet.miner),
            // The block number of this price sheet packaged
            sheet.height,
            // The remain number of this price sheet
            sheet.remainNum,
            // The eth number which miner will got
            sheet.ethNumBal,
            // The eth number which equivalent to token's value which miner will got
            sheet.tokenNumBal,
            // The pledged number of nest in this sheet. (Unit: 1000nest)
            sheet.nestNum1k,
            // The level of this sheet. 0 expresses initial price sheet, a value greater than 0 expresses 
            // bite price sheet
            sheet.level,
            // Post fee shares
            sheet.shares,
            // Price
            uint152(_decodeFloat(sheet.priceFloat))
        );
    }

    // Create price sheet
    function _create(
        PriceSheet[] storage sheets,
        uint accountIndex,
        uint32 ethNum,
        uint nestNum1k,
        uint level_shares,
        uint equivalent
    ) private {

        sheets.push(PriceSheet(
            uint32(accountIndex),                       // uint32 miner;
            uint32(block.number),                       // uint32 height;
            ethNum,                                     // uint32 remainNum;
            ethNum,                                     // uint32 ethNumBal;
            ethNum,                                     // uint32 tokenNumBal;
            uint24(nestNum1k),                          // uint32 nestNum1k;
            uint8(level_shares >> 8),                   // uint8 level;
            uint8(level_shares & 0xFF),
            _encodeFloat(equivalent)
        ));
    }

    // Calculate price, average price and volatility
    function _stat(Config memory config, PricePair storage pair) private {
        
        PriceSheet[] storage sheets = pair.sheets;
        // Load token price information
        PriceInfo memory p0 = pair.price;

        // Length of sheets
        uint length = sheets.length;
        // The index of the sheet to be processed in the sheet array
        uint index = uint(p0.index);
        // The latest block number for which the price has been calculated
        uint prev = uint(p0.height);
        // It's not necessary to load the price information in p0
        // Eth count variable used to calculate price
        uint totalEthNum = 0; 
        // Token count variable for price calculation
        uint totalTokenValue = 0; 
        // Block number of current sheet
        uint height = 0;

        // Traverse the sheets to find the effective price
        //uint effectBlock = block.number - uint(config.priceEffectSpan);
        PriceSheet memory sheet;
        for (; ; ++index) {

            // Gas attack analysis, each post transaction, calculated according to post, needs to write
            // at least one sheet and freeze two kinds of assets, which needs to consume at least 30000 gas,
            // In addition to the basic cost of the transaction, at least 50000 gas is required.
            // In addition, there are other reading and calculation operations. The gas consumed by each
            // transaction is impossible less than 70000 gas, The attacker can accumulate up to 20 blocks
            // of sheets to be generated. To ensure that the calculation can be completed in one block,
            // it is necessary to ensure that the consumption of each price does not exceed 70000 / 20 = 3500 gas,
            // According to the current logic, each calculation of a price needs to read a storage unit (800)
            // and calculate the consumption, which can not reach the dangerous value of 3500, so the gas attack
            // is not considered

            // Traverse the sheets that has reached the effective interval from the current position
            bool flag = index >= length
                || (height = uint((sheet = sheets[index]).height)) + uint(config.priceEffectSpan) >= block.number;

            // Not the same block (or flag is false), calculate the price and update it
            if (flag || prev != height) {

                // totalEthNum > 0 Can calculate the price
                if (totalEthNum > 0) {

                    // Calculate average price and Volatility
                    // Calculation method of volatility of follow-up price
                    uint tmp = _decodeFloat(p0.priceFloat);
                    // New price
                    uint price = totalTokenValue / totalEthNum;
                    // Update price
                    p0.remainNum = uint32(totalEthNum);
                    p0.priceFloat = _encodeFloat(price);
                    // Clear cumulative values
                    totalEthNum = 0;
                    totalTokenValue = 0;

                    if (tmp > 0) {
                        // Calculate average price
                        // avgPrice[i + 1] = avgPrice[i] * 90% + price[i] * 10%
                        p0.avgFloat = _encodeFloat((_decodeFloat(p0.avgFloat) * 9 + price) / 10);

                        // When the accuracy of the token is very high or the value of the token relative to
                        // eth is very low, the price may be very large, and there may be overflow problem,
                        // it is not considered for the moment
                        tmp = (price << 48) / tmp;
                        if (tmp > 0x1000000000000) {
                            tmp = tmp - 0x1000000000000;
                        } else {
                            tmp = 0x1000000000000 - tmp;
                        }

                        // earn = price[i] / price[i - 1] - 1;
                        // seconds = time[i] - time[i - 1];
                        // sigmaSQ[i + 1] = sigmaSQ[i] * 90% + (earn ^ 2 / seconds) * 10%
                        tmp = (
                            uint(p0.sigmaSQ) * 9 + 
                            // It is inevitable that prev greater than p0.height
                            ((tmp * tmp * 1000 / ETHEREUM_BLOCK_TIMESPAN / (prev - uint(p0.height))) >> 48)
                        ) / 10;

                        // The current implementation assumes that the volatility cannot exceed 1, and
                        // corresponding to this, when the calculated value exceeds 1, expressed as 0xFFFFFFFFFFFF
                        if (tmp > 0xFFFFFFFFFFFF) {
                            tmp = 0xFFFFFFFFFFFF;
                        }
                        p0.sigmaSQ = uint48(tmp);
                    }
                    // The calculation methods of average price and volatility are different for first price
                    else {
                        // The average price is equal to the price
                        //p0.avgTokenAmount = uint64(price);
                        p0.avgFloat = p0.priceFloat;

                        // The volatility is 0
                        p0.sigmaSQ = uint48(0);
                    }

                    // Update price block number
                    p0.height = uint32(prev);
                }

                // Move to new block number
                prev = height;
            }

            if (flag) {
                break;
            }

            // Cumulative price information
            totalEthNum += uint(sheet.remainNum);
            totalTokenValue += _decodeFloat(sheet.priceFloat) * uint(sheet.remainNum);
        }

        // Update price information
        if (index > uint(p0.index)) {
            p0.index = uint32(index);
            pair.price = p0;
        }
    }

    // Calculation number of blocks which mined
    function _calcMinedBlocks(
        PriceSheet[] storage sheets,
        uint index,
        PriceSheet memory sheet
    ) private view returns (uint minedBlocks, uint totalShares) {

        uint length = sheets.length;
        uint height = uint(sheet.height);
        totalShares = uint(sheet.shares);

        // Backward looking for sheets in the same block
        for (uint i = index; ++i < length && uint(sheets[i].height) == height;) {
            
            // Multiple sheets in the same block is a small probability event at present, so it can be ignored
            // to read more than once, if there are always multiple sheets in the same block, it means that the
            // sheets are very intensive, and the gas consumed here does not have a great impact
            totalShares += uint(sheets[i].shares);
        }

        //i = index;
        // Find sheets in the same block forward
        uint prev = height;
        while (index > 0 && uint(prev = sheets[--index].height) == height) {

            // Multiple sheets in the same block is a small probability event at present, so it can be ignored 
            // to read more than once, if there are always multiple sheets in the same block, it means that the
            // sheets are very intensive, and the gas consumed here does not have a great impact
            totalShares += uint(sheets[index].shares);
        }

        if (index > 0 || height > prev) {
            minedBlocks = height - prev;
        } else {
            minedBlocks = 10;
        }
    }

    /// @dev freeze token
    /// @param balances Balances ledger
    /// @param tokenAddress Destination token address
    /// @param tokenValue token amount
    /// @param value 剩余的eth数量
    function _freeze(
        mapping(address=>UINT) storage balances, 
        address tokenAddress, 
        uint tokenValue,
        uint value
    ) private returns (uint) {
        if (tokenAddress == address(0)) {
            return value - tokenValue;
        } else {
            // Unfreeze nest
            UINT storage balance = balances[tokenAddress];
            uint balanceValue = balance.value;
            if (balanceValue < tokenValue) {
                balance.value = 0;
                TransferHelper.safeTransferFrom(tokenAddress, msg.sender, address(this), tokenValue - balanceValue);
            } else {
                balance.value = balanceValue - tokenValue;
            }
            return value;
        }
    }

    function _unfreeze(
        mapping(address=>UINT) storage balances, 
        address tokenAddress, 
        uint tokenValue,
        uint accountIndex
    ) private {
        if (tokenValue > 0) {
            if (tokenAddress == address(0)) {
                payable(indexAddress(accountIndex)).transfer(tokenValue);
            } else {
                balances[tokenAddress].value += tokenValue;
            }
        }
    }

    function _unfreeze(
        mapping(address=>UINT) storage balances, 
        address tokenAddress, 
        uint tokenValue,
        address owner
    ) private {
        if (tokenValue > 0) {
            if (tokenAddress == address(0)) {
                payable(owner).transfer(tokenValue);
            } else {
                balances[tokenAddress].value += tokenValue;
            }
        }
    }

    /// @dev Gets the index number of the specified address. If it does not exist, register
    /// @param addr Destination address
    /// @return The index number of the specified address
    function _addressIndex(address addr) private returns (uint) {

        uint index = _accountMapping[addr];
        if (index == 0) {
            // If it exceeds the maximum number that 32 bits can store, you can't continue to register a new account.
            // If you need to support a new account, you need to update the contract
            require((_accountMapping[addr] = index = _accounts.length) < 0x100000000, "NM:!accounts");
            _accounts.push().addr = addr;
        }

        return index;
    }

    // // Calculation of attenuation gradient
    // function _reduction(uint delta) private pure returns (uint) {

    //     if (delta < NEST_REDUCTION_LIMIT) {
    //         return (NEST_REDUCTION_STEPS >> ((delta / NEST_REDUCTION_SPAN) << 4)) & 0xFFFF;
    //     }
    //     return (NEST_REDUCTION_STEPS >> 160) & 0xFFFF;
    // }

    function _reduction(uint delta, uint reductionRate) private pure returns (uint) {
        if (delta < NEST_REDUCTION_LIMIT) {
            uint n = delta / NEST_REDUCTION_SPAN;
            return 400 * reductionRate ** n / 10000 ** n;
        }
        return 400 * reductionRate ** 10 / 10000 ** 10;
    }

    /* ========== Tools and methods ========== */

    /// @dev Encode the uint value as a floating-point representation in the form of fraction * 16 ^ exponent
    /// @param value Destination uint value
    /// @return float format
    function _encodeFloat(uint value) private pure returns (uint56) {

        uint exponent = 0; 
        while (value > 0x3FFFFFFFFFFFF) {
            value >>= 4;
            ++exponent;
        }
        return uint56((value << 6) | exponent);
    }

    /// @dev Decode the floating-point representation of fraction * 16 ^ exponent to uint
    /// @param floatValue fraction value
    /// @return decode format
    function _decodeFloat(uint56 floatValue) private pure returns (uint) {
        return (uint(floatValue) >> 6) << ((uint(floatValue) & 0x3F) << 2);
    }

    // 将uint转为uint96
    function _toUInt96(uint value) internal pure returns (uint96) {
        require(value < 0x1000000000000000000000000);
        return uint96(value);
    }

    /* ========== 价格查询 ========== */
    
    /// @dev Get the latest trigger price
    /// @param pair 报价对
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    function _triggeredPrice(PricePair storage pair) internal view returns (uint blockNumber, uint price) {

        PriceInfo memory priceInfo = pair.price;

        if (uint(priceInfo.remainNum) > 0) {
            return (uint(priceInfo.height) + uint(_config.priceEffectSpan), _decodeFloat(priceInfo.priceFloat));
        }
        
        return (0, 0);
    }

    /// @dev Get the full information of latest trigger price
    /// @param pair 报价对
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    /// @return avgPrice Average price
    /// @return sigmaSQ The square of the volatility (18 decimal places). The current implementation assumes that 
    ///         the volatility cannot exceed 1. Correspondingly, when the return value is equal to 999999999999996447,
    ///         it means that the volatility has exceeded the range that can be expressed
    function _triggeredPriceInfo(PricePair storage pair) internal view returns (
        uint blockNumber,
        uint price,
        uint avgPrice,
        uint sigmaSQ
    ) {

        PriceInfo memory priceInfo = pair.price;

        if (uint(priceInfo.remainNum) > 0) {
            return (
                uint(priceInfo.height) + uint(_config.priceEffectSpan),
                _decodeFloat(priceInfo.priceFloat),
                _decodeFloat(priceInfo.avgFloat),
                (uint(priceInfo.sigmaSQ) * 1 ether) >> 48
            );
        }

        return (0, 0, 0, 0);
    }

    /// @dev Find the price at block number
    /// @param pair 报价对
    /// @param height Destination block number
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    function _findPrice(
        PricePair storage pair,
        uint height
    ) internal view returns (uint blockNumber, uint price) {

        PriceSheet[] storage sheets = pair.sheets;
        uint priceEffectSpan = uint(_config.priceEffectSpan);

        uint length = sheets.length;
        uint index = 0;
        uint sheetHeight;
        height -= priceEffectSpan;
        {
            // If there is no sheet in this channel, length is 0, length - 1 will overflow,
            uint right = length - 1;
            uint left = 0;
            // Find the index use Binary Search
            while (left < right) {

                index = (left + right) >> 1;
                sheetHeight = uint(sheets[index].height);
                if (height > sheetHeight) {
                    left = ++index;
                } else if (height < sheetHeight) {
                    // When index = 0, this statement will have an underflow exception, which usually 
                    // indicates that the effective block height passed during the call is lower than 
                    // the block height of the first quotation
                    right = --index;
                } else {
                    break;
                }
            }
        }

        // Calculate price
        uint totalEthNum = 0;
        uint totalTokenValue = 0;
        uint h = 0;
        uint remainNum;
        PriceSheet memory sheet;

        // Find sheets forward
        for (uint i = index; i < length;) {

            sheet = sheets[i++];
            sheetHeight = uint(sheet.height);
            if (height < sheetHeight) {
                break;
            }
            remainNum = uint(sheet.remainNum);
            if (remainNum > 0) {
                if (h == 0) {
                    h = sheetHeight;
                } else if (h != sheetHeight) {
                    break;
                }
                totalEthNum += remainNum;
                totalTokenValue += _decodeFloat(sheet.priceFloat) * remainNum;
            }
        }

        // Find sheets backward
        while (index > 0) {

            sheet = sheets[--index];
            remainNum = uint(sheet.remainNum);
            if (remainNum > 0) {
                sheetHeight = uint(sheet.height);
                if (h == 0) {
                    h = sheetHeight;
                } else if (h != sheetHeight) {
                    break;
                }
                totalEthNum += remainNum;
                totalTokenValue += _decodeFloat(sheet.priceFloat) * remainNum;
            }
        }

        if (totalEthNum > 0) {
            return (h + priceEffectSpan, totalTokenValue / totalEthNum);
        }
        return (0, 0);
    }

    /// @dev Get the last (num) effective price
    /// @param pair 报价对
    /// @param count The number of prices that want to return
    /// @return An array which length is num * 2, each two element expresses one price like blockNumber｜price
    function _lastPriceList(PricePair storage pair, uint count) internal view returns (uint[] memory) {

        PriceSheet[] storage sheets = pair.sheets;
        PriceSheet memory sheet;
        uint[] memory array = new uint[](count <<= 1);

        uint priceEffectSpan = uint(_config.priceEffectSpan);
        //uint h = block.number - priceEffectSpan;
        uint index = sheets.length;
        uint totalEthNum = 0;
        uint totalTokenValue = 0;
        uint height = 0;

        for (uint i = 0; i < count;) {

            bool flag = index == 0;
            if (flag || height != uint((sheet = sheets[--index]).height)) {
                if (totalEthNum > 0 && height + priceEffectSpan < block.number) {
                    array[i++] = height + priceEffectSpan;
                    array[i++] = totalTokenValue / totalEthNum;
                }
                if (flag) {
                    break;
                }
                totalEthNum = 0;
                totalTokenValue = 0;
                height = uint(sheet.height);
            }

            uint remainNum = uint(sheet.remainNum);
            totalEthNum += remainNum;
            totalTokenValue += _decodeFloat(sheet.priceFloat) * remainNum;
        }

        return array;
    }
}


// File contracts/NestBatchPlatform2.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;
// 支持pairIndex数组，可以一次性查询多个价格
/// @dev This contract implemented the mining logic of nest
contract NestBatchPlatform2 is NestBatchMining, INestBatchPriceView, INestBatchPrice2 {

    /* ========== INestBatchPriceView ========== */

    /// @dev Get the latest trigger price
    /// @param channelId 报价通道编号
    /// @param pairIndex 报价对编号
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    function triggeredPrice(uint channelId, uint pairIndex) external view override noContract returns (uint blockNumber, uint price) {
        return _triggeredPrice(_channels[channelId].pairs[pairIndex]);
    }

    /// @dev Get the full information of latest trigger price
    /// @param channelId 报价通道编号
    /// @param pairIndex 报价对编号
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    /// @return avgPrice Average price
    /// @return sigmaSQ The square of the volatility (18 decimal places). The current implementation assumes that 
    ///         the volatility cannot exceed 1. Correspondingly, when the return value is equal to 999999999999996447,
    ///         it means that the volatility has exceeded the range that can be expressed
    function triggeredPriceInfo(uint channelId, uint pairIndex) external view override noContract returns (
        uint blockNumber,
        uint price,
        uint avgPrice,
        uint sigmaSQ
    ) {
        return _triggeredPriceInfo(_channels[channelId].pairs[pairIndex]);
    }

    /// @dev Find the price at block number
    /// @param channelId 报价通道编号
    /// @param pairIndex 报价对编号
    /// @param height Destination block number
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    function findPrice(
        uint channelId,
        uint pairIndex,
        uint height
    ) external view override noContract returns (uint blockNumber, uint price) {
        return _findPrice(_channels[channelId].pairs[pairIndex], height);
    }

    // /// @dev Get the latest effective price
    // /// @param channelId 报价通道编号
    // /// @param pairIndex 报价对编号
    // /// @return blockNumber The block number of price
    // /// @return price The token price. (1eth equivalent to (price) token)
    // function latestPrice(uint channelId, uint pairIndex) external view override noContract returns (uint blockNumber, uint price) {
    //     return _latestPrice(_channels[channelId].pairs[pairIndex]);
    // }

    /// @dev Get the last (num) effective price
    /// @param channelId 报价通道编号
    /// @param pairIndex 报价对编号
    /// @param count The number of prices that want to return
    /// @return An array which length is num * 2, each two element expresses one price like blockNumber｜price
    function lastPriceList(uint channelId, uint pairIndex, uint count) external view override noContract returns (uint[] memory) {
        return _lastPriceList(_channels[channelId].pairs[pairIndex], count);
    } 

    /// @dev Returns lastPriceList and triggered price info
    /// @param channelId 报价通道编号
    /// @param pairIndex 报价对编号
    /// @param count The number of prices that want to return
    /// @return prices An array which length is num * 2, each two element expresses one price like blockNumber｜price
    /// @return triggeredPriceBlockNumber The block number of triggered price
    /// @return triggeredPriceValue The token triggered price. (1eth equivalent to (price) token)
    /// @return triggeredAvgPrice Average price
    /// @return triggeredSigmaSQ The square of the volatility (18 decimal places). The current implementation 
    /// assumes that the volatility cannot exceed 1. Correspondingly, when the return value is equal to 
    /// 999999999999996447, it means that the volatility has exceeded the range that can be expressed
    function lastPriceListAndTriggeredPriceInfo(uint channelId, uint pairIndex, uint count) external view override noContract
    returns (
        uint[] memory prices,
        uint triggeredPriceBlockNumber,
        uint triggeredPriceValue,
        uint triggeredAvgPrice,
        uint triggeredSigmaSQ
    ) {
        //return _lastPriceListAndTriggeredPriceInfo(_channels[channelId].pairs[pairIndex], count);
        PricePair storage pair = _channels[channelId].pairs[pairIndex];
        prices = _lastPriceList(pair, count);
        (
            triggeredPriceBlockNumber, 
            triggeredPriceValue, 
            triggeredAvgPrice, 
            triggeredSigmaSQ
        ) = _triggeredPriceInfo(pair);
    }

    /* ========== INestBatchPrice ========== */

    /// @dev Get the latest trigger price
    /// @param channelId 报价通道编号
    /// @param pairIndices 报价对编号
    /// @param payback 如果费用有多余的，则退回到此地址
    /// @return prices 价格数组, i * 2 为第i个价格所在区块, i * 2 + 1 为第i个价格
    function triggeredPrice(
        uint channelId,
        uint[] calldata pairIndices, 
        address payback
    ) external payable override returns (uint[] memory prices) {
        PricePair[0xFFFF] storage pairs = _pay(channelId, payback).pairs;

        uint n = pairIndices.length << 1;
        prices = new uint[](n);
        while (n > 0) {
            n -= 2;
            (prices[n], prices[n + 1]) = _triggeredPrice(pairs[pairIndices[n >> 1]]);
        }
    }

    /// @dev Get the full information of latest trigger price
    /// @param channelId 报价通道编号
    /// @param pairIndices 报价对编号
    /// @param payback 如果费用有多余的，则退回到此地址
    /// @return prices 价格数组, i * 4 为第i个价格所在区块, i * 4 + 1 为第i个价格, i * 4 + 2 为第i个平均价格, i * 4 + 3 为第i个波动率
    function triggeredPriceInfo(
        uint channelId, 
        uint[] calldata pairIndices,
        address payback
    ) external payable override returns (uint[] memory prices) {
        PricePair[0xFFFF] storage pairs = _pay(channelId, payback).pairs;

        uint n = pairIndices.length << 2;
        prices = new uint[](n);
        while (n > 0) {
            n -= 4;
            (prices[n], prices[n + 1], prices[n + 2], prices[n + 3]) = _triggeredPriceInfo(pairs[pairIndices[n >> 2]]);
        }
    }

    /// @dev Find the price at block number
    /// @param channelId 报价通道编号
    /// @param pairIndices 报价对编号
    /// @param height Destination block number
    /// @param payback 如果费用有多余的，则退回到此地址
    /// @return prices 价格数组, i * 2 为第i个价格所在区块, i * 2 + 1 为第i个价格
    function findPrice(
        uint channelId,
        uint[] calldata pairIndices, 
        uint height, 
        address payback
    ) external payable override returns (uint[] memory prices) {
        PricePair[0xFFFF] storage pairs = _pay(channelId, payback).pairs;

        uint n = pairIndices.length << 1;
        prices = new uint[](n);
        while (n > 0) {
            n -= 2;
            (prices[n], prices[n + 1]) = _findPrice(pairs[pairIndices[n >> 1]], height);
        }
    }

    // /// @dev Get the latest effective price
    // /// @param channelId 报价通道编号
    // /// @param pairIndices 报价对编号
    // /// @param payback 如果费用有多余的，则退回到此地址
    // /// @return prices 价格数组, i * 2 为第i个价格所在区块, i * 2 + 1 为第i个价格
    // function latestPrice(
    //     uint channelId, 
    //     uint[] calldata pairIndices, 
    //     address payback
    // ) external payable override returns (uint[] memory prices) {
    //     PricePair[0xFFFF] storage pairs = _pay(channelId, payback).pairs;

    //     uint n = pairIndices.length << 1;
    //     prices = new uint[](n);
    //     while (n > 0) {
    //         n -= 2;
    //         (prices[n], prices[n + 1]) = _latestPrice(pairs[pairIndices[n >> 1]]);
    //     }
    // }

    /// @dev Get the last (num) effective price
    /// @param channelId 报价通道编号
    /// @param pairIndices 报价对编号
    /// @param count The number of prices that want to return
    /// @param payback 如果费用有多余的，则退回到此地址
    /// @return prices 结果数组，第 i * count * 2 到 (i + 1) * count * 2 - 1为第i组报价对的价格结果
    function lastPriceList(
        uint channelId, 
        uint[] calldata pairIndices, 
        uint count, 
        address payback
    ) external payable override returns (uint[] memory prices) {
        PricePair[0xFFFF] storage pairs = _pay(channelId, payback).pairs;

        uint row = count << 1;
        uint n = pairIndices.length * row;
        prices = new uint[](n);
        while (n > 0) {
            n -= row;
            uint[] memory pi = _lastPriceList(pairs[pairIndices[n / row]], count);
            for (uint i = 0; i < row; ++i) {
                prices[n + i] = pi[i];
            }
        }
    }

    /// @dev Returns lastPriceList and triggered price info
    /// @param channelId 报价通道编号
    /// @param pairIndices 报价对编号
    /// @param count The number of prices that want to return
    /// @param payback 如果费用有多余的，则退回到此地址
    /// @return prices 结果数组，第 i * (count * 2 + 4)到 (i + 1) * (count * 2 + 4)- 1为第i组报价对的价格结果
    ///         其中前count * 2个为最新价格，后4个依次为：触发价格区块号，触发价格，平均价格，波动率
    function lastPriceListAndTriggeredPriceInfo(
        uint channelId, 
        uint[] calldata pairIndices,
        uint count, 
        address payback
    ) external payable override returns (uint[] memory prices) {
        PricePair[0xFFFF] storage pairs = _pay(channelId, payback).pairs;

        uint row = (count << 1) + 4;
        uint n = pairIndices.length * row;
        prices = new uint[](n);
        while (n > 0) {
            n -= row;

            PricePair storage pair = pairs[pairIndices[n / row]];
            uint[] memory pi = _lastPriceList(pair, count);
            for (uint i = 0; i + 4 < row; ++i) {
                prices[n + i] = pi[i];
            }
            uint j = n + row - 4;
            (
                prices[j],
                prices[j + 1],
                prices[j + 2],
                prices[j + 3]
            ) = _triggeredPriceInfo(pair);
        }
    }

    // Payment of transfer fee
    function _pay(uint channelId, address payback) private returns (PriceChannel storage channel) {

        channel = _channels[channelId];
        uint fee = uint(channel.singleFee) * DIMI_ETHER;
        if (msg.value > fee) {
            payable(payback).transfer(msg.value - fee);
            // TODO: BSC上采用的是老的gas计算策略，直接转账可能导致代理合约gas超出，要改用下面的方式转账
            //TransferHelper.safeTransferETH(payback, msg.value - fee);
        } else {
            require(msg.value == fee, "NOP:!fee");
        }

        channel.rewards += _toUInt96(fee);
    }
}