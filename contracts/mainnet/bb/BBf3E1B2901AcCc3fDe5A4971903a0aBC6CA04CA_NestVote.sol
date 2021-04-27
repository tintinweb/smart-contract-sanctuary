/**
 *Submitted for verification at Etherscan.io on 2021-04-27
*/

// File: contracts\lib\IERC20.sol

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.3;

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

// File: contracts\interface\INestMining.sol

/// @dev This interface defines the mining methods for nest
interface INestMining {
    
    /// @dev Post event
    /// @param tokenAddress The address of TOKEN contract
    /// @param miner Address of miner
    /// @param index Index of the price sheet
    /// @param ethNum The numbers of ethers to post sheets
    event Post(address tokenAddress, address miner, uint index, uint ethNum, uint price);

    /* ========== Structures ========== */
    
    /// @dev Nest mining configuration structure
    struct Config {
        
        // Eth number of each post. 30
        // We can stop post and taking orders by set postEthUnit to 0 (closing and withdraw are not affected)
        uint32 postEthUnit;

        // Post fee(0.0001eth，DIMI_ETHER). 1000
        uint16 postFeeUnit;

        // Proportion of miners digging(10000 based). 8000
        uint16 minerNestReward;
        
        // The proportion of token dug by miners is only valid for the token created in version 3.0
        // (10000 based). 9500
        uint16 minerNTokenReward;

        // When the circulation of ntoken exceeds this threshold, post() is prohibited(Unit: 10000 ether). 500
        uint32 doublePostThreshold;
        
        // The limit of ntoken mined blocks. 100
        uint16 ntokenMinedBlockLimit;

        // -- Public configuration
        // The number of times the sheet assets have doubled. 4
        uint8 maxBiteNestedLevel;
        
        // Price effective block interval. 20
        uint16 priceEffectSpan;

        // The amount of nest to pledge for each post（Unit: 1000). 100
        uint16 pledgeNest;
    }

    /// @dev PriceSheetView structure
    struct PriceSheetView {
        
        // Index of the price sheeet
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

    /* ========== Configuration ========== */

    /// @dev Modify configuration
    /// @param config Configuration object
    function setConfig(Config memory config) external;

    /// @dev Get configuration
    /// @return Configuration object
    function getConfig() external view returns (Config memory);

    /// @dev Set the ntokenAddress from tokenAddress, if ntokenAddress is equals to tokenAddress, means the token is disabled
    /// @param tokenAddress Destination token address
    /// @param ntokenAddress The ntoken address
    function setNTokenAddress(address tokenAddress, address ntokenAddress) external;

    /// @dev Get the ntokenAddress from tokenAddress, if ntokenAddress is equals to tokenAddress, means the token is disabled
    /// @param tokenAddress Destination token address
    /// @return The ntoken address
    function getNTokenAddress(address tokenAddress) external view returns (address);

    /* ========== Mining ========== */

    /// @notice Post a price sheet for TOKEN
    /// @dev It is for TOKEN (except USDT and NTOKENs) whose NTOKEN has a total supply below a threshold (e.g. 5,000,000 * 1e18)
    /// @param tokenAddress The address of TOKEN contract
    /// @param ethNum The numbers of ethers to post sheets
    /// @param tokenAmountPerEth The price of TOKEN
    function post(address tokenAddress, uint ethNum, uint tokenAmountPerEth) external payable;

    /// @notice Post two price sheets for a token and its ntoken simultaneously 
    /// @dev Support dual-posts for TOKEN/NTOKEN, (ETH, TOKEN) + (ETH, NTOKEN)
    /// @param tokenAddress The address of TOKEN contract
    /// @param ethNum The numbers of ethers to post sheets
    /// @param tokenAmountPerEth The price of TOKEN
    /// @param ntokenAmountPerEth The price of NTOKEN
    function post2(address tokenAddress, uint ethNum, uint tokenAmountPerEth, uint ntokenAmountPerEth) external payable;

    /// @notice Call the function to buy TOKEN/NTOKEN from a posted price sheet
    /// @dev bite TOKEN(NTOKEN) by ETH,  (+ethNumBal, -tokenNumBal)
    /// @param tokenAddress The address of token(ntoken)
    /// @param index The position of the sheet in priceSheetList[token]
    /// @param takeNum The amount of biting (in the unit of ETH), realAmount = takeNum * newTokenAmountPerEth
    /// @param newTokenAmountPerEth The new price of token (1 ETH : some TOKEN), here some means newTokenAmountPerEth
    function takeToken(address tokenAddress, uint index, uint takeNum, uint newTokenAmountPerEth) external payable;

    /// @notice Call the function to buy ETH from a posted price sheet
    /// @dev bite ETH by TOKEN(NTOKEN),  (-ethNumBal, +tokenNumBal)
    /// @param tokenAddress The address of token(ntoken)
    /// @param index The position of the sheet in priceSheetList[token]
    /// @param takeNum The amount of biting (in the unit of ETH), realAmount = takeNum
    /// @param newTokenAmountPerEth The new price of token (1 ETH : some TOKEN), here some means newTokenAmountPerEth
    function takeEth(address tokenAddress, uint index, uint takeNum, uint newTokenAmountPerEth) external payable;
    
    /// @notice Close a price sheet of (ETH, USDx) | (ETH, NEST) | (ETH, TOKEN) | (ETH, NTOKEN)
    /// @dev Here we allow an empty price sheet (still in VERIFICATION-PERIOD) to be closed 
    /// @param tokenAddress The address of TOKEN contract
    /// @param index The index of the price sheet w.r.t. `token`
    function close(address tokenAddress, uint index) external;

    /// @notice Close a batch of price sheets passed VERIFICATION-PHASE
    /// @dev Empty sheets but in VERIFICATION-PHASE aren't allowed
    /// @param tokenAddress The address of TOKEN contract
    /// @param indices A list of indices of sheets w.r.t. `token`
    function closeList(address tokenAddress, uint[] memory indices) external;

    /// @notice Close two batch of price sheets passed VERIFICATION-PHASE
    /// @dev Empty sheets but in VERIFICATION-PHASE aren't allowed
    /// @param tokenAddress The address of TOKEN1 contract
    /// @param tokenIndices A list of indices of sheets w.r.t. `token`
    /// @param ntokenIndices A list of indices of sheets w.r.t. `ntoken`
    function closeList2(address tokenAddress, uint[] memory tokenIndices, uint[] memory ntokenIndices) external;

    /// @dev The function updates the statistics of price sheets
    ///     It calculates from priceInfo to the newest that is effective.
    function stat(address tokenAddress) external;

    /// @dev Settlement Commission
    /// @param tokenAddress The token address
    function settle(address tokenAddress) external;

    /// @dev List sheets by page
    /// @param tokenAddress Destination token address
    /// @param offset Skip previous (offset) records
    /// @param count Return (count) records
    /// @param order Order. 0 reverse order, non-0 positive order
    /// @return List of price sheets
    function list(address tokenAddress, uint offset, uint count, uint order) external view returns (PriceSheetView[] memory);

    /// @dev Estimated mining amount
    /// @param tokenAddress Destination token address
    /// @return Estimated mining amount
    function estimate(address tokenAddress) external view returns (uint);

    /// @dev Query the quantity of the target quotation
    /// @param tokenAddress Token address. The token can't mine. Please make sure you don't use the token address when calling
    /// @param index The index of the sheet
    /// @return minedBlocks Mined block period from previous block
    /// @return totalShares Total shares of sheets in the block
    function getMinedBlocks(address tokenAddress, uint index) external view returns (uint minedBlocks, uint totalShares);

    /* ========== Accounts ========== */

    /// @dev Withdraw assets
    /// @param tokenAddress Destination token address
    /// @param value The value to withdraw
    function withdraw(address tokenAddress, uint value) external;

    /// @dev View the number of assets specified by the user
    /// @param tokenAddress Destination token address
    /// @param addr Destination address
    /// @return Number of assets
    function balanceOf(address tokenAddress, address addr) external view returns (uint);

    /// @dev Gets the address corresponding to the given index number
    /// @param index The index number of the specified address
    /// @return The address corresponding to the given index number
    function indexAddress(uint index) external view returns (address);
    
    /// @dev Gets the registration index number of the specified address
    /// @param addr Destination address
    /// @return 0 means nonexistent, non-0 means index number
    function getAccountIndex(address addr) external view returns (uint);

    /// @dev Get the length of registered account array
    /// @return The length of registered account array
    function getAccountCount() external view returns (uint);
}

// File: contracts\interface\INestVote.sol

/// @dev This interface defines the methods for voting
interface INestVote {

    /// @dev Event of submitting a voting proposal
    /// @param proposer Proposer address
    /// @param contractAddress The contract address which will be executed when the proposal is approved. (Must implemented IVotePropose)
    /// @param index Index of proposal
    event NIPSubmitted(address proposer, address contractAddress, uint index);

    /// @dev Voting event
    /// @param voter Voter address
    /// @param index Index of proposal
    /// @param amount Amount of nest to vote
    event NIPVote(address voter, uint index, uint amount);

    /// @dev Proposal execute event
    /// @param executor Executor address
    /// @param index Index of proposal
    event NIPExecute(address executor, uint index);

    /// @dev Voting contract configuration structure
    struct Config {

        // Proportion of votes required (10000 based). 5100
        uint32 acceptance;

        // Voting time cycle (seconds). 5 * 86400
        uint64 voteDuration;

        // The number of nest votes need to be staked. 100000 nest
        uint96 proposalStaking;
    }

    // Proposal
    struct ProposalView {

        // Index of proposal
        uint index;
        
        // The immutable field and the variable field are stored separately
        /* ========== Immutable field ========== */

        // Brief of this proposal
        string brief;

        // The contract address which will be executed when the proposal is approved. (Must implemented IVotePropose)
        address contractAddress;

        // Voting start time
        uint48 startTime;

        // Voting stop time
        uint48 stopTime;

        // Proposer
        address proposer;

        // Staked nest amount
        uint96 staked;

        /* ========== Mutable field ========== */

        // Gained value
        // The maximum value of uint96 can be expressed as 79228162514264337593543950335, which is more than the total 
        // number of nest 10000000000 ether. Therefore, uint96 can be used to express the total number of votes
        uint96 gainValue;

        // The state of this proposal
        uint32 state;  // 0: proposed | 1: accepted | 2: cancelled

        // The executor of this proposal
        address executor;

        // The execution time (if any, such as block number or time stamp) is placed in the contract and is limited by the contract itself

        // Circulation of nest
        uint96 nestCirculation;
    }
    
    /// @dev Modify configuration
    /// @param config Configuration object
    function setConfig(Config memory config) external;

    /// @dev Get configuration
    /// @return Configuration object
    function getConfig() external view returns (Config memory);

    /* ========== VOTE ========== */
    
    /// @dev Initiate a voting proposal
    /// @param contractAddress The contract address which will be executed when the proposal is approved. (Must implemented IVotePropose)
    /// @param brief Brief of this propose
    function propose(address contractAddress, string memory brief) external;

    /// @dev vote
    /// @param index Index of proposal
    /// @param value Amount of nest to vote
    function vote(uint index, uint value) external;

    /// @dev Withdraw the nest of the vote. If the target vote is in the voting state, the corresponding number of votes will be cancelled
    /// @param index Index of the proposal
    function withdraw(uint index) external;

    /// @dev Execute the proposal
    /// @param index Index of the proposal
    function execute(uint index) external;

    /// @dev Cancel the proposal
    /// @param index Index of the proposal
    function cancel(uint index) external;

    /// @dev Get proposal information
    /// @param index Index of the proposal
    /// @return Proposal information
    function getProposeInfo(uint index) external view returns (ProposalView memory);

    /// @dev Get the cumulative number of voting proposals
    /// @return The cumulative number of voting proposals
    function getProposeCount() external view returns (uint);

    /// @dev List proposals by page
    /// @param offset Skip previous (offset) records
    /// @param count Return (count) records
    /// @param order Order. 0 reverse order, non-0 positive order
    /// @return List of price proposals
    function list(uint offset, uint count, uint order) external view returns (ProposalView[] memory);

    /// @dev Get Circulation of nest
    /// @return Circulation of nest
    function getNestCirculation() external view returns (uint);

    /// @dev Upgrades a proxy to the newest implementation of a contract
    /// @param proxyAdmin The address of ProxyAdmin
    /// @param proxy Proxy to be upgraded
    /// @param implementation the address of the Implementation
    function upgradeProxy(address proxyAdmin, address proxy, address implementation) external;

    /// @dev Transfers ownership of the contract to a new account (`newOwner`)
    ///      Can only be called by the current owner
    /// @param proxyAdmin The address of ProxyAdmin
    /// @param newOwner The address of new owner
    function transferUpgradeAuthority(address proxyAdmin, address newOwner) external;
}

// File: contracts\interface\IVotePropose.sol

/// @dev Interface to be implemented for voting contract
interface IVotePropose {

    /// @dev Methods to be called after approved
    function run() external;
}

// File: contracts\interface\INestMapping.sol

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

// File: contracts\interface\INestGovernance.sol

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
    /// @param flag Permission weight. The permission of the target address must be greater than this weight to pass the check
    /// @return True indicates permission
    function checkGovernance(address addr, uint flag) external view returns (bool);
}

// File: contracts\interface\IProxyAdmin.sol

/// @dev This interface defines the ProxyAdmin methods
interface IProxyAdmin {

    /// @dev Upgrades a proxy to the newest implementation of a contract
    /// @param proxy Proxy to be upgraded
    /// @param implementation the address of the Implementation
    function upgrade(address proxy, address implementation) external;

    /// @dev Transfers ownership of the contract to a new account (`newOwner`)
    ///      Can only be called by the current owner
    /// @param newOwner The address of new owner
    function transferOwnership(address newOwner) external;
}

// File: contracts\lib\TransferHelper.sol

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

// File: contracts\interface\INestLedger.sol

/// @dev This interface defines the nest ledger methods
interface INestLedger {

    /// @dev Application Flag Changed event
    /// @param addr DAO application contract address
    /// @param flag Authorization flag, 1 means authorization, 0 means cancel authorization
    event ApplicationChanged(address addr, uint flag);
    
    /// @dev Configuration structure of nest ledger contract
    struct Config {
        
        // nest reward scale(10000 based). 2000
        uint16 nestRewardScale;

        // // ntoken reward scale(10000 based). 8000
        // uint16 ntokenRewardScale;
    }
    
    /// @dev Modify configuration
    /// @param config Configuration object
    function setConfig(Config memory config) external;

    /// @dev Get configuration
    /// @return Configuration object
    function getConfig() external view returns (Config memory);

    /// @dev Set DAO application
    /// @param addr DAO application contract address
    /// @param flag Authorization flag, 1 means authorization, 0 means cancel authorization
    function setApplication(address addr, uint flag) external;

    /// @dev Check DAO application flag
    /// @param addr DAO application contract address
    /// @return Authorization flag, 1 means authorization, 0 means cancel authorization
    function checkApplication(address addr) external view returns (uint);

    /// @dev Carve reward
    /// @param ntokenAddress Destination ntoken address
    function carveETHReward(address ntokenAddress) external payable;

    /// @dev Add reward
    /// @param ntokenAddress Destination ntoken address
    function addETHReward(address ntokenAddress) external payable;

    /// @dev The function returns eth rewards of specified ntoken
    /// @param ntokenAddress The ntoken address
    function totalETHRewards(address ntokenAddress) external view returns (uint);

    /// @dev Pay
    /// @param ntokenAddress Destination ntoken address. Indicates which ntoken to pay with
    /// @param tokenAddress Token address of receiving funds (0 means ETH)
    /// @param to Address to receive
    /// @param value Amount to receive
    function pay(address ntokenAddress, address tokenAddress, address to, uint value) external;

    /// @dev Settlement
    /// @param ntokenAddress Destination ntoken address. Indicates which ntoken to settle with
    /// @param tokenAddress Token address of receiving funds (0 means ETH)
    /// @param to Address to receive
    /// @param value Amount to receive
    function settle(address ntokenAddress, address tokenAddress, address to, uint value) external payable;
}

// File: contracts\NestBase.sol

/// @dev Base contract of nest
contract NestBase {

    // Address of nest token contract
    address constant NEST_TOKEN_ADDRESS = 0x04abEdA201850aC0124161F037Efd70c74ddC74C;

    // Genesis block number of nest
    // NEST token contract is created at block height 6913517. However, because the mining algorithm of nest1.0
    // is different from that at present, a new mining algorithm is adopted from nest2.0. The new algorithm
    // includes the attenuation logic according to the block. Therefore, it is necessary to trace the block
    // where the nest begins to decay. According to the circulation when nest2.0 is online, the new mining
    // algorithm is used to deduce and convert the nest, and the new algorithm is used to mine the nest2.0
    // on-line flow, the actual block is 5120000
    uint constant NEST_GENESIS_BLOCK = 5120000;

    /// @dev To support open-zeppelin/upgrades
    /// @param nestGovernanceAddress INestGovernance implementation contract address
    function initialize(address nestGovernanceAddress) virtual public {
        require(_governance == address(0), 'NEST:!initialize');
        _governance = nestGovernanceAddress;
    }

    /// @dev INestGovernance implementation contract address
    address public _governance;

    /// @dev Rewritten in the implementation contract, for load other contract addresses. Call 
    ///      super.update(nestGovernanceAddress) when overriding, and override method without onlyGovernance
    /// @param nestGovernanceAddress INestGovernance implementation contract address
    function update(address nestGovernanceAddress) virtual public {

        address governance = _governance;
        require(governance == msg.sender || INestGovernance(governance).checkGovernance(msg.sender, 0), "NEST:!gov");
        _governance = nestGovernanceAddress;
    }

    /// @dev Migrate funds from current contract to NestLedger
    /// @param tokenAddress Destination token address.(0 means eth)
    /// @param value Migrate amount
    function migrate(address tokenAddress, uint value) external onlyGovernance {

        address to = INestGovernance(_governance).getNestLedgerAddress();
        if (tokenAddress == address(0)) {
            INestLedger(to).addETHReward { value: value } (address(0));
        } else {
            TransferHelper.safeTransfer(tokenAddress, to, value);
        }
    }

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

// File: contracts\NestVote.sol

/// @dev nest voting contract, implemented the voting logic
contract NestVote is NestBase, INestVote {
    
    // constructor() { }

    /// @dev Structure is used to represent a storage location. Storage variable can be used to avoid indexing from mapping many times
    struct UINT {
        uint value;
    }

    /// @dev Proposal information
    struct Proposal {

        // The immutable field and the variable field are stored separately
        /* ========== Immutable field ========== */

        // Brief of this proposal
        string brief;

        // The contract address which will be executed when the proposal is approved. (Must implemented IVotePropose)
        address contractAddress;

        // Voting start time
        uint48 startTime;

        // Voting stop time
        uint48 stopTime;

        // Proposer
        address proposer;

        // Staked nest amount
        uint96 staked;

        /* ========== Mutable field ========== */

        // Gained value
        // The maximum value of uint96 can be expressed as 79228162514264337593543950335, which is more than the total 
        // number of nest 10000000000 ether. Therefore, uint96 can be used to express the total number of votes
        uint96 gainValue;

        // The state of this proposal. 0: proposed | 1: accepted | 2: cancelled
        uint32 state;

        // The executor of this proposal
        address executor;

        // The execution time (if any, such as block number or time stamp) is placed in the contract and is limited by the contract itself
    }
    
    // Configuration
    Config _config;

    // Array for proposals
    Proposal[] public _proposalList;

    // Staked ledger
    mapping(uint =>mapping(address =>UINT)) public _stakedLedger;
    
    address _nestLedgerAddress;
    //address _nestTokenAddress;
    address _nestMiningAddress;
    address _nnIncomeAddress;

    uint32 constant PROPOSAL_STATE_PROPOSED = 0;
    uint32 constant PROPOSAL_STATE_ACCEPTED = 1;
    uint32 constant PROPOSAL_STATE_CANCELLED = 2;

    uint constant NEST_TOTAL_SUPPLY = 10000000000 ether;

    /// @dev Rewritten in the implementation contract, for load other contract addresses. Call 
    ///      super.update(nestGovernanceAddress) when overriding, and override method without onlyGovernance
    /// @param nestGovernanceAddress INestGovernance implementation contract address
    function update(address nestGovernanceAddress) override public {
        super.update(nestGovernanceAddress);

        (
            //address nestTokenAddress
            ,//_nestTokenAddress, 
            //address nestNodeAddress
            ,
            //address nestLedgerAddress
            _nestLedgerAddress, 
            //address nestMiningAddress
            _nestMiningAddress, 
            //address ntokenMiningAddress
            ,
            //address nestPriceFacadeAddress
            ,
            //address nestVoteAddress
            ,
            //address nestQueryAddress
            ,
            //address nnIncomeAddress
            _nnIncomeAddress, 
            //address nTokenControllerAddress
              
        ) = INestGovernance(nestGovernanceAddress).getBuiltinAddress();
    }

    /// @dev Modify configuration
    /// @param config Configuration object
    function setConfig(Config memory config) override external onlyGovernance {
        require(uint(config.acceptance) <= 10000, "NestVote:!value");
        _config = config;
    }

    /// @dev Get configuration
    /// @return Configuration object
    function getConfig() override external view returns (Config memory) {
        return _config;
    }

    /* ========== VOTE ========== */
    
    /// @dev Initiate a voting proposal
    /// @param contractAddress The contract address which will be executed when the proposal is approved. (Must implemented IVotePropose)
    /// @param brief Brief of this propose
    function propose(address contractAddress, string memory brief) override external noContract
    {
        // The target address cannot already have governance permission to prevent the governance permission from being covered
        require(!INestGovernance(_governance).checkGovernance(contractAddress, 0), "NestVote:!governance");
     
        Config memory config = _config;
        uint index = _proposalList.length;

        // Create voting structure
        _proposalList.push(Proposal(
        
            // Brief of this propose
            //string brief;
            brief,

            // The contract address which will be executed when the proposal is approved. (Must implemented IVotePropose)
            //address contractAddress;
            contractAddress,

            // Voting start time
            //uint48 startTime;
            uint48(block.timestamp),

            // Voting stop time
            //uint48 stopTime;
            uint48(block.timestamp + uint(config.voteDuration)),

            // Proposer
            //address proposer;
            msg.sender,

            config.proposalStaking,

            uint96(0), 
            
            PROPOSAL_STATE_PROPOSED, 

            address(0)
        ));

        // Stake nest
        IERC20(NEST_TOKEN_ADDRESS).transferFrom(msg.sender, address(this), uint(config.proposalStaking));

        emit NIPSubmitted(msg.sender, contractAddress, index);
    }

    /// @dev vote
    /// @param index Index of proposal
    /// @param value Amount of nest to vote
    function vote(uint index, uint value) override external noContract
    {
        // 1. Load the proposal
        Proposal memory p = _proposalList[index];

        // 2. Check
        // Check time region
        // Note: stop time is not include stopTime
        require(block.timestamp >= uint(p.startTime) && block.timestamp < uint(p.stopTime), "NestVote:!time");
        require(p.state == PROPOSAL_STATE_PROPOSED, "NestVote:!state");

        // 3. Update voting ledger
        UINT storage balance = _stakedLedger[index][msg.sender];
        balance.value += value;

        // 4. Update voting information
        _proposalList[index].gainValue = uint96(uint(p.gainValue) + value);

        // 5. Stake nest
        IERC20(NEST_TOKEN_ADDRESS).transferFrom(msg.sender, address(this), value);

        emit NIPVote(msg.sender, index, value);
    }

    /// @dev Withdraw the nest of the vote. If the target vote is in the voting state, the corresponding number of votes will be cancelled
    /// @param index Index of the proposal
    function withdraw(uint index) override external noContract
    {
        // 1. Update voting ledger
        UINT storage balance = _stakedLedger[index][msg.sender];
        uint balanceValue = balance.value;
        balance.value = 0;

        // 2. In the proposal state, the number of votes obtained needs to be updated
        if (_proposalList[index].state == PROPOSAL_STATE_PROPOSED) {
            _proposalList[index].gainValue = uint96(uint(_proposalList[index].gainValue) - balanceValue);
        }

        // 3. Return staked nest
        IERC20(NEST_TOKEN_ADDRESS).transfer(msg.sender, balanceValue);
    }

    /// @dev Execute the proposal
    /// @param index Index of the proposal
    function execute(uint index) override external noContract
    {
        Config memory config = _config;

        // 1. Load proposal
        Proposal memory p = _proposalList[index];

        // 2. Check status
        require(p.state == PROPOSAL_STATE_PROPOSED, "NestVote:!state");
        require(block.timestamp < uint(p.stopTime), "NestVote:!time");
        // The target address cannot already have governance permission to prevent the governance permission from being covered
        address governance = _governance;
        require(!INestGovernance(governance).checkGovernance(p.contractAddress, 0), "NestVote:!governance");

        // 3. Check the gaine rate
        IERC20 nest = IERC20(NEST_TOKEN_ADDRESS);

        // Calculate the circulation of nest
        uint nestCirculation = _getNestCirculation(nest);
        require(uint(p.gainValue) * 10000 >= nestCirculation * uint(config.acceptance), "NestVote:!gainValue");

        // 3. Temporarily grant execution permission
        INestGovernance(governance).setGovernance(p.contractAddress, 1);

        // 4. Execute
        _proposalList[index].state = PROPOSAL_STATE_ACCEPTED;
        _proposalList[index].executor = msg.sender;
        IVotePropose(p.contractAddress).run();

        // 5. Delete execution permission
        INestGovernance(governance).setGovernance(p.contractAddress, 0);
        
        // Return nest
        nest.transfer(p.proposer, uint(p.staked));

        emit NIPExecute(msg.sender, index);
    }

    /// @dev Cancel the proposal
    /// @param index Index of the proposal
    function cancel(uint index) override external noContract {

        // 1. Load proposal
        Proposal memory p = _proposalList[index];

        // 2. Check state
        require(p.state == PROPOSAL_STATE_PROPOSED, "NestVote:!state");
        require(block.timestamp >= uint(p.stopTime), "NestVote:!time");

        // 3. Update status
        _proposalList[index].state = PROPOSAL_STATE_CANCELLED;

        // 4. Return staked nest
        IERC20(NEST_TOKEN_ADDRESS).transfer(p.proposer, uint(p.staked));
    }

    // Convert PriceSheet to PriceSheetView
    //function _toPriceSheetView(PriceSheet memory sheet, uint index) private view returns (PriceSheetView memory) {
    function _toProposalView(Proposal memory proposal, uint index, uint nestCirculation) private pure returns (ProposalView memory) {

        return ProposalView(
            // Index of the proposal
            index,
            // Brief of proposal
            //string brief;
            proposal.brief,
            // The contract address which will be executed when the proposal is approved. (Must implemented IVotePropose)
            //address contractAddress;
            proposal.contractAddress,
            // Voting start time
            //uint48 startTime;
            proposal.startTime,
            // Voting stop time
            //uint48 stopTime;
            proposal.stopTime,
            // Proposer
            //address proposer;
            proposal.proposer,
            // Staked nest amount
            //uint96 staked;
            proposal.staked,
            // Gained value
            // The maximum value of uint96 can be expressed as 79228162514264337593543950335, which is more than the total 
            // number of nest 10000000000 ether. Therefore, uint96 can be used to express the total number of votes
            //uint96 gainValue;
            proposal.gainValue,
            // The state of this proposal
            //uint32 state;  // 0: proposed | 1: accepted | 2: cancelled
            proposal.state,
            // The executor of this proposal
            //address executor;
            proposal.executor,

            // Circulation of nest
            uint96(nestCirculation)
        );
    }

    /// @dev Get proposal information
    /// @param index Index of the proposal
    /// @return Proposal information
    function getProposeInfo(uint index) override external view returns (ProposalView memory) {
        return _toProposalView(_proposalList[index], index, getNestCirculation());
    }

    /// @dev Get the cumulative number of voting proposals
    /// @return The cumulative number of voting proposals
    function getProposeCount() override external view returns (uint) {
        return _proposalList.length;
    }

    /// @dev List proposals by page
    /// @param offset Skip previous (offset) records
    /// @param count Return (count) records
    /// @param order Order. 0 reverse order, non-0 positive order
    /// @return List of price proposals
    function list(uint offset, uint count, uint order) override external view returns (ProposalView[] memory) {
        
        Proposal[] storage proposalList = _proposalList;
        ProposalView[] memory result = new ProposalView[](count);
        uint nestCirculation = getNestCirculation();
        uint length = proposalList.length;
        uint i = 0;

        // Reverse order
        if (order == 0) {

            uint index = length - offset;
            uint end = index > count ? index - count : 0;
            while (index > end) {
                --index;
                result[i++] = _toProposalView(proposalList[index], index, nestCirculation);
            }
        } 
        // Positive sequence
        else {
            
            uint index = offset;
            uint end = index + count;
            if (end > length) {
                end = length;
            }
            while (index < end) {
                result[i++] = _toProposalView(proposalList[index], index, nestCirculation);
                ++index;
            }
        }

        return result;
    }

    // Get Circulation of nest
    function _getNestCirculation(IERC20 nest) private view returns (uint) {

        return NEST_TOTAL_SUPPLY 
            - nest.balanceOf(_nestMiningAddress)
            - nest.balanceOf(_nnIncomeAddress)
            - nest.balanceOf(_nestLedgerAddress)
            - nest.balanceOf(address(0x1));
    }

    /// @dev Get Circulation of nest
    /// @return Circulation of nest
    function getNestCirculation() override public view returns (uint) {
        return _getNestCirculation(IERC20(NEST_TOKEN_ADDRESS));
    }

    /// @dev Upgrades a proxy to the newest implementation of a contract
    /// @param proxyAdmin The address of ProxyAdmin
    /// @param proxy Proxy to be upgraded
    /// @param implementation the address of the Implementation
    function upgradeProxy(address proxyAdmin, address proxy, address implementation) override external onlyGovernance {
        IProxyAdmin(proxyAdmin).upgrade(proxy, implementation);
    }

    /// @dev Transfers ownership of the contract to a new account (`newOwner`)
    ///      Can only be called by the current owner
    /// @param proxyAdmin The address of ProxyAdmin
    /// @param newOwner The address of new owner
    function transferUpgradeAuthority(address proxyAdmin, address newOwner) override external onlyGovernance {
        IProxyAdmin(proxyAdmin).transferOwnership(newOwner);
    }
}