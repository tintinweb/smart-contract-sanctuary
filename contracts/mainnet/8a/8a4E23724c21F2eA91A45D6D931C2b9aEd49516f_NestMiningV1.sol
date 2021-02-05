// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./libminingv1/MiningV1Data.sol";
import "./libminingv1/MiningV1Calc.sol";
import "./libminingv1/MiningV1Op.sol";

import "./lib/SafeMath.sol";
import "./lib/SafeERC20.sol";
import './lib/TransferHelper.sol';
import "./lib/ABDKMath64x64.sol";

import "./iface/INestPool.sol";
import "./iface/INestStaking.sol";
import "./iface/INTokenLegacy.sol";
import "./iface/INestMining.sol";
import "./iface/INestDAO.sol";
// import "hardhat/console.sol";

/// @title  NestMiningV1
/// @author Inf Loop - <[email protected]>
/// @author Paradox  - <[email protected]>
contract NestMiningV1 {

    using SafeMath for uint256;

    using MiningV1Calc for MiningV1Data.State;
    using MiningV1Op for MiningV1Data.State;

    /* ========== STATE VARIABLES ============== */

    uint8       public  flag;  // 0:  | 1:  | 2:  | 3:
    uint64      public  version; 
    uint8       private _entrant_state; 
    uint176     private _reserved;

    MiningV1Data.State state;
    
    // NOTE: _NOT_ENTERED is set to ZERO such that it needn't constructor
    uint8 private constant _NOT_ENTERED = 0;
    uint8 private constant _ENTERED = 1;

    uint8 constant MINING_FLAG_UNINITIALIZED    = 0;
    uint8 constant MINING_FLAG_SETUP_NEEDED     = 1;
    uint8 constant MINING_FLAG_UPGRADE_NEEDED   = 2;
    uint8 constant MINING_FLAG_ACTIVE           = 3;

    /* ========== ADDRESSES ============== */

    address public  governance;
    address private C_NestPool;

    /* ========== STRUCTURES ============== */

    struct Params {
        uint8    miningEthUnit;     
        uint32   nestStakedNum1k;   
        uint8    biteFeeRate;     
        uint8    miningFeeRate;     
        uint8    priceDurationBlock; 
        uint8    maxBiteNestedLevel; 
        uint8    biteInflateFactor;
        uint8    biteNestInflateFactor;
    }

    /* ========== CONSTRUCTOR ========== */

    constructor() public { }

    function initialize(address NestPool) external 
    {
        // check flag
        require(flag == MINING_FLAG_UNINITIALIZED, "Nest:Mine:!flag");

        uint256 amount = MiningV1Data.MINING_NEST_YIELD_PER_BLOCK_BASE;
        for (uint i =0; i < 10; i++) {
            state._mining_nest_yield_per_block_amount[i] = amount;
            amount = amount.mul(MiningV1Data.MINING_NEST_YIELD_CUTBACK_RATE).div(100);
        }

        amount = MiningV1Data.MINING_NTOKEN_YIELD_PER_BLOCK_BASE;
        for (uint i =0; i < 10; i++) {
            state._mining_ntoken_yield_per_block_amount[i] = amount;
            amount = amount.mul(MiningV1Data.MINING_NTOKEN_YIELD_CUTBACK_RATE).div(100);
        }
        
        // set a temporary governance
        governance = msg.sender;

        // increase version number
        version = uint64(block.number);

        // set the address of NestPool 
        C_NestPool = NestPool;

        // set flag
        flag = MINING_FLAG_SETUP_NEEDED;
    }

    /// @dev This function can only be called once immediately right after deployment
    function setup(
            uint32   genesisBlockNumber, 
            uint128  latestMiningHeight,
            uint128  minedNestTotalAmount,
            Params calldata initParams
        ) external onlyGovernance
    {
        // check flag
        require(flag == MINING_FLAG_SETUP_NEEDED, "Nest:Mine:!flag");
        
        // set system-wide parameters
        state.miningEthUnit = initParams.miningEthUnit;
        state.nestStakedNum1k = initParams.nestStakedNum1k;
        state.biteFeeRate = initParams.biteFeeRate;    // 0.1%
        state.miningFeeRate = initParams.miningFeeRate;  // 0.1% on testnet
        state.priceDurationBlock = initParams.priceDurationBlock;  // 5 on testnet
        state.maxBiteNestedLevel = initParams.maxBiteNestedLevel;  
        state.biteInflateFactor = initParams.biteInflateFactor;   // 1 on testnet
        state.biteNestInflateFactor = initParams.biteNestInflateFactor; // 1 on testnet
        state.latestMiningHeight = latestMiningHeight;
        state.minedNestAmount = minedNestTotalAmount;
        
        // genesisBlock = 6236588 on mainnet
        state.genesisBlock = genesisBlockNumber;

        // increase version number
        version = uint64(block.number);
        
        // set flag
        flag = MINING_FLAG_UPGRADE_NEEDED;
    }

    /// @dev The function will be kicking off Nest Protocol v3.5.
    ///    After upgrading, `post/post2()` are ready to be invoked.
    ///    Before that, `post2Only4Upgrade()` is used to do posting.
    ///    The purpose is to limit post2Only4Upgrade() to run 
    function upgrade() external onlyGovernance
    {
        require(flag == MINING_FLAG_UPGRADE_NEEDED, "Nest:Mine:!flag");

        flag = MINING_FLAG_ACTIVE;
    }

    /// @notice Write the block number as a version number
    /// @dev It shall be invoked *manually* whenever the contract is upgraded(behind proxy)
    function incVersion() external onlyGovernance
    {
        version = uint64(block.number);
    }

    receive() external payable { }

    /* ========== MODIFIERS ========== */

    function _onlyGovernance() private view 
    {
        require(msg.sender == governance, "Nest:Mine:!GOV");
    }

    modifier onlyGovernance() 
    {
        _onlyGovernance();
        _;
    }

    function _noContract() private view {
        require(address(msg.sender) == address(tx.origin), "Nest:Mine:contract!");
    }

    modifier noContract() 
    {
        _noContract();
        _;
    }

    modifier noContractExcept(address _contract) 
    {
        require(address(msg.sender) == address(tx.origin) || address(msg.sender) == _contract, "Nest:Mine:contract!");
        _;
    }

    modifier onlyGovOrBy(address _contract) 
    {
        require(msg.sender == governance || msg.sender == _contract, "Nest:Mine:!sender");
        _;
    }

    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_entrant_state != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _entrant_state = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _entrant_state = _NOT_ENTERED;
    }

    modifier onlyByNestOrNoContract()
    {
        require(address(msg.sender) == address(tx.origin)
            || msg.sender == state.C_NestDAO 
            || msg.sender == state.C_NestStaking 
            || msg.sender == state.C_NNRewardPool 
            || msg.sender == state.C_NestQuery, "Nest:Mine:!Auth");
        _;
    }

    /* ========== GOVERNANCE ========== */

    /// @dev Load real governance from NestPool, invalidate the temporary 
    function loadGovernance() external
    {
        governance = INestPool(C_NestPool).governance();
    }

    function loadContracts() external onlyGovOrBy(C_NestPool)
    {
        state.C_NestPool = C_NestPool;
        state.C_NestToken = INestPool(state.C_NestPool).addrOfNestToken();
        state.C_NestStaking = INestPool(state.C_NestPool).addrOfNestStaking();
        state.C_NestQuery = INestPool(state.C_NestPool).addrOfNestQuery();
        state.C_NNRewardPool = INestPool(state.C_NestPool).addrOfNNRewardPool();
        state.C_NestDAO = INestPool(state.C_NestPool).addrOfNestDAO();
    }

    function setParams(Params calldata newParams) external 
        onlyGovernance
    {
        state.miningEthUnit = newParams.miningEthUnit;
        state.nestStakedNum1k = newParams.nestStakedNum1k;
        state.biteFeeRate = newParams.biteFeeRate;
        state.miningFeeRate = newParams.miningFeeRate;

        state.priceDurationBlock = newParams.priceDurationBlock;
        state.maxBiteNestedLevel = newParams.maxBiteNestedLevel;
        state.biteInflateFactor = newParams.biteInflateFactor;
        state.biteNestInflateFactor = newParams.biteNestInflateFactor;

        emit MiningV1Data.SetParams(state.miningEthUnit, state.nestStakedNum1k, state.biteFeeRate,
                                    state.miningFeeRate, state.priceDurationBlock, state.maxBiteNestedLevel,
                                    state.biteInflateFactor, state.biteNestInflateFactor);
    }

    /// @dev only be used when upgrading 3.0 to 3.5
    /// @dev when the upgrade is complete, this function is disabled
    function setParams1(
            uint128  latestMiningHeight,
            uint128  minedNestTotalAmount
        ) external onlyGovernance
    {
        require(flag == MINING_FLAG_UPGRADE_NEEDED, "Nest:Mine:!flag");
        state.latestMiningHeight = latestMiningHeight;
        state.minedNestAmount = minedNestTotalAmount;
    }

    /* ========== HELPERS ========== */

    function addrOfGovernance() view external
        returns (address) 
    {   
        return governance;
    }

    function parameters() view external 
        returns (Params memory params)
    {
        params.miningEthUnit = state.miningEthUnit;
        params.nestStakedNum1k = state.nestStakedNum1k;
        params.biteFeeRate = state.biteFeeRate;
        params.miningFeeRate = state.miningFeeRate;
        params.priceDurationBlock = state.priceDurationBlock;
        params.maxBiteNestedLevel = state.maxBiteNestedLevel;
        params.biteInflateFactor = state.biteInflateFactor;
        params.biteNestInflateFactor = state.biteNestInflateFactor;
    }

    /* ========== POST/CLOSE Price Sheets ========== */

    /// @notice Post a price sheet for TOKEN
    /// @dev  It is for TOKEN (except USDT and NTOKENs) whose NTOKEN has a total supply below a threshold (e.g. 5,000,000 * 1e18)
    /// @param token The address of TOKEN contract
    /// @param ethNum The numbers of ethers to post sheets
    /// @param tokenAmountPerEth The price of TOKEN
    function post(
            address token, 
            uint256 ethNum, 
            uint256 tokenAmountPerEth
        )
        external 
        payable 
        noContract
    {
        // check parameters
        require(ethNum == state.miningEthUnit, "Nest:Mine:!(ethNum)");
        require(tokenAmountPerEth > 0, "Nest:Mine:!(price)");

        INestPool _C_NestPool = INestPool(state.C_NestPool);
        address _ntoken = _C_NestPool.getNTokenFromToken(token);
        require(_ntoken != address(0) &&  _ntoken != address(state.C_NestToken) && token != _ntoken, "Nest:Mine:!(ntoken)");

        // check if the totalsupply of ntoken is less than MINING_NTOKEN_NON_DUAL_POST_THRESHOLD, otherwise use post2()
        require(INToken(_ntoken).totalSupply() < MiningV1Data.MINING_NTOKEN_NON_DUAL_POST_THRESHOLD, "Nest:Mine:!ntoken");

        // calculate eth fee
        // NOTE: fee = ethAmount * (feeRate * 1/10k)
        uint256 _ethFee = ethNum.mul(state.miningFeeRate).mul(1e18).div(10_000);

        { // settle ethers and tokens

            // save the changes into miner's virtual account
            if (msg.value.sub(_ethFee) > 0) {
                _C_NestPool.depositEth{value:msg.value.sub(_ethFee)}(address(msg.sender));
            }

            // load addresses
            INestStaking _C_NestStaking = INestStaking(state.C_NestStaking);
            INestDAO _C_NestDAO = INestDAO(state.C_NestDAO);

            // 60% fee => NestStaking
            _C_NestStaking.addETHReward{value:_ethFee.mul(MiningV1Data.MINING_NTOKEN_FEE_DIVIDEND_RATE).div(100)}(_ntoken);       
            // 20% fee => NestDAO[NTOKEN]
            _C_NestDAO.addETHReward{value:_ethFee.mul(MiningV1Data.MINING_NTOKEN_FEE_DAO_RATE).div(100)}(_ntoken);       
            // 20% fee => NestDAO[NEST]
            _C_NestDAO.addETHReward{value:_ethFee.mul(MiningV1Data.MINING_NTOKEN_FEE_NEST_DAO_RATE).div(100)}(address(state.C_NestToken));  

            // freeze eths and tokens inside NestPool
            _C_NestPool.freezeEthAndToken(msg.sender, ethNum.mul(1 ether), 
                token, tokenAmountPerEth.mul(ethNum));
            _C_NestPool.freezeNest(msg.sender, uint256(state.nestStakedNum1k).mul(1000 * 1e18));
        }

        {
            MiningV1Data.PriceSheet[] storage _sheetToken = state.priceSheetList[token];
            // append a new price sheet
            _sheetToken.push(MiningV1Data.PriceSheet(
                uint160(msg.sender),            // miner 
                uint32(block.number),           // atHeight
                uint32(ethNum),                 // ethNum
                uint32(ethNum),                 // remainNum
                uint8(0),                       // level
                uint8(MiningV1Data.PRICESHEET_TYPE_TOKEN),   // typ
                uint8(MiningV1Data.PRICESHEET_STATE_POSTED), // state 
                uint8(0),                       // _reserved
                uint32(ethNum),                 // ethNumBal
                uint32(ethNum),                 // tokenNumBal
                uint32(state.nestStakedNum1k),    // nestNum1k
                uint128(tokenAmountPerEth)      // tokenAmountPerEth
            ));
            emit MiningV1Data.PricePosted(msg.sender, token, (_sheetToken.length - 1), ethNum.mul(1 ether), tokenAmountPerEth.mul(ethNum)); 

        }

        { // mining; NTOKEN branch only
            // load mining record from `minedAtHeight`
            uint256 _minedH = state.minedAtHeight[token][block.number];
            // decode `_ntokenH` & `_ethH`
            uint256 _ntokenH = uint256(_minedH >> 128);
            uint256 _ethH = uint256(_minedH % (1 << 128));
            if (_ntokenH == 0) {  // the sheet is the first in the block
                // calculate the amount the NTOKEN to be mined
                uint256 _ntokenAmount = mineNToken(_ntoken);  
                // load `Bidder` from NTOKEN contract
                address _bidder = INToken(_ntoken).checkBidder();
                if (_bidder == state.C_NestPool) { // for new NTokens, 100% to miners
                    _ntokenH = _ntokenAmount;
                    INToken(_ntoken).mint(_ntokenAmount, address(state.C_NestPool));
                } else { // for old NTokens, 95% to miners, 5% to the bidder
                    _ntokenH = _ntokenAmount.mul(MiningV1Data.MINING_LEGACY_NTOKEN_MINER_REWARD_PERCENTAGE).div(100);
                    INTokenLegacy(_ntoken).increaseTotal(_ntokenAmount);
                    INTokenLegacy(_ntoken).transfer(state.C_NestPool, _ntokenAmount);
                    INestPool(state.C_NestPool).addNToken(_bidder, _ntoken, _ntokenAmount.sub(_ntokenH));
                }
            }
            
            // add up `_ethH`
            _ethH = _ethH.add(ethNum);
            // store `_ntokenH` & `_ethH` into `minedAtHeight`
            state.minedAtHeight[token][block.number] = (_ntokenH * (1<< 128) + _ethH);
        }

        // calculate averge and volatility
        state._stat(token);
        return; 
    }

    /// @notice Post two price sheets for a token and its ntoken simultaneously 
    /// @dev  Support dual-posts for TOKEN/NTOKEN, (ETH, TOKEN) + (ETH, NTOKEN)
    /// @param token The address of TOKEN contract
    /// @param ethNum The numbers of ethers to post sheets
    /// @param tokenAmountPerEth The price of TOKEN
    /// @param ntokenAmountPerEth The price of NTOKEN
    function post2(
            address token, 
            uint256 ethNum, 
            uint256 tokenAmountPerEth, 
            uint256 ntokenAmountPerEth
        )
        external 
        payable 
        noContract
    {
        // check parameters 
        require(ethNum == state.miningEthUnit, "Nest:Mine:!(ethNum)");
        require(tokenAmountPerEth > 0 && ntokenAmountPerEth > 0, "Nest:Mine:!(price)");
        address _ntoken = INestPool(state.C_NestPool).getNTokenFromToken(token);

        require(_ntoken != token && _ntoken != address(0), "Nest:Mine:!(ntoken)");

        // calculate eth fee
        uint256 _ethFee = ethNum.mul(state.miningFeeRate).mul(1e18).div(10_000);

        { // settle ethers and tokens
            INestPool _C_NestPool = INestPool(state.C_NestPool);

            // save the changes into miner's virtual account
            if (msg.value.sub(_ethFee) > 0) {
                _C_NestPool.depositEth{value:msg.value.sub(_ethFee)}(address(msg.sender));
            }

            // load addresses
            INestStaking _C_NestStaking = INestStaking(state.C_NestStaking);
            INestDAO _C_NestDAO = INestDAO(state.C_NestDAO);

            if (_ntoken == address(state.C_NestToken)) {
                // %80 => NestStaking
                _C_NestStaking.addETHReward{value:_ethFee.mul(MiningV1Data.MINING_NEST_FEE_DIVIDEND_RATE).div(100)}(_ntoken);       
                // %20 => NestDAO
                _C_NestDAO.addETHReward{value:_ethFee.mul(MiningV1Data.MINING_NEST_FEE_DAO_RATE).div(100)}(_ntoken);       
            } else {
                // 60% => NestStaking
                _C_NestStaking.addETHReward{value:_ethFee.mul(MiningV1Data.MINING_NTOKEN_FEE_DIVIDEND_RATE).div(100)}(_ntoken);       
                // 20% => NestDAO[NTOKEN]
                _C_NestDAO.addETHReward{value:_ethFee.mul(MiningV1Data.MINING_NTOKEN_FEE_DAO_RATE).div(100)}(_ntoken);       
                // 20% => NestDAO[NEST]
                _C_NestDAO.addETHReward{value:_ethFee.mul(MiningV1Data.MINING_NTOKEN_FEE_NEST_DAO_RATE).div(100)}(address(state.C_NestToken));  
            }

            // freeze assets inside NestPool
            _C_NestPool.freezeEthAndToken(msg.sender, ethNum.mul(1 ether), 
                token, tokenAmountPerEth.mul(ethNum));
            _C_NestPool.freezeEthAndToken(msg.sender, ethNum.mul(1 ether), 
                _ntoken, ntokenAmountPerEth.mul(ethNum));
            _C_NestPool.freezeNest(msg.sender, uint256(state.nestStakedNum1k).mul(2).mul(1000 * 1e18));
        }

        {
            uint8 typ1;
            uint8 typ2; 
            if (_ntoken == address(state.C_NestToken)) {
                typ1 = MiningV1Data.PRICESHEET_TYPE_USD;
                typ2 = MiningV1Data.PRICESHEET_TYPE_NEST;
            } else {
                typ1 = MiningV1Data.PRICESHEET_TYPE_TOKEN;
                typ2 = MiningV1Data.PRICESHEET_TYPE_NTOKEN;
            }
            MiningV1Data.PriceSheet[] storage _sheetToken = state.priceSheetList[token];
            // append a new price sheet
            _sheetToken.push(MiningV1Data.PriceSheet(
                uint160(msg.sender),            // miner 
                uint32(block.number),           // atHeight
                uint32(ethNum),                 // ethNum
                uint32(ethNum),                 // remainNum
                uint8(0),                       // level
                uint8(typ1),                    // typ
                uint8(MiningV1Data.PRICESHEET_STATE_POSTED), // state 
                uint8(0),                       // _reserved
                uint32(ethNum),                 // ethNumBal
                uint32(ethNum),                 // tokenNumBal
                uint32(state.nestStakedNum1k),        // nestNum1k
                uint128(tokenAmountPerEth)      // tokenAmountPerEth
            ));

            MiningV1Data.PriceSheet[] storage _sheetNToken = state.priceSheetList[_ntoken];
            // append a new price sheet for ntoken
            _sheetNToken.push(MiningV1Data.PriceSheet(
                uint160(msg.sender),            // miner 
                uint32(block.number),           // atHeight
                uint32(ethNum),                 // ethNum
                uint32(ethNum),                 // remainNum
                uint8(0),                       // level
                uint8(typ2),                    // typ
                uint8(MiningV1Data.PRICESHEET_STATE_POSTED), // state 
                uint8(0),                       // _reserved
                uint32(ethNum),                 // ethNumBal
                uint32(ethNum),                 // tokenNumBal
                uint32(state.nestStakedNum1k),  // nestNum1k
                uint128(ntokenAmountPerEth)     // tokenAmountPerEth
            ));
            emit MiningV1Data.PricePosted(msg.sender, token, (_sheetToken.length - 1), ethNum.mul(1 ether), tokenAmountPerEth.mul(ethNum)); 
            emit MiningV1Data.PricePosted(msg.sender, _ntoken, (_sheetNToken.length - 1), ethNum.mul(1 ether), ntokenAmountPerEth.mul(ethNum)); 
        }

        { // mining; NEST branch & NTOKEN branch
            if (_ntoken == address(state.C_NestToken)) {
                // load mining records `minedAtHeight` in the same block 
                uint256 _minedH = state.minedAtHeight[token][block.number];
                // decode `_nestH` and `_ethH` from `minedAtHeight`
                uint256 _nestH = uint256(_minedH >> 128);
                uint256 _ethH = uint256(_minedH % (1 << 128));

                if (_nestH == 0) { // the sheet is the first in the block

                    // calculate the amount of NEST to be mined
                    uint256 _nestAmount = mineNest(); 

                    // update `latestMiningHeight`, the lastest NEST-mining block 
                    state.latestMiningHeight = uint32(block.number); 

                    // accumulate the amount of NEST
                    state.minedNestAmount += uint128(_nestAmount);

                    // 
                    _nestH = _nestAmount.mul(MiningV1Data.MINER_NEST_REWARD_PERCENTAGE).div(100); 

                    // 15% of NEST to NNRewardPool
                    INestPool(state.C_NestPool).addNest(state.C_NNRewardPool, _nestAmount.mul(MiningV1Data.NN_NEST_REWARD_PERCENTAGE).div(100));
                    INNRewardPool(state.C_NNRewardPool).addNNReward(_nestAmount.mul(MiningV1Data.NN_NEST_REWARD_PERCENTAGE).div(100));

                    // 5% of NEST to NestDAO
                    INestPool(state.C_NestPool).addNest(state.C_NestDAO, _nestAmount.mul(MiningV1Data.DAO_NEST_REWARD_PERCENTAGE).div(100));
                    INestDAO(state.C_NestDAO).addNestReward(_nestAmount.mul(MiningV1Data.DAO_NEST_REWARD_PERCENTAGE).div(100));
                }

                // add up `ethNum` into `minedAtHeight`
                _ethH = _ethH.add(ethNum);
                // encode `_nestH` and `_ethH` into `minedAtHeight`
                state.minedAtHeight[token][block.number] = (_nestH * (1<< 128) + _ethH);
            } else {
                // load mining records `minedAtHeight` in the same block 
                uint256 _minedH = state.minedAtHeight[token][block.number];
                // decode `_ntokenH` and `_ethH` from `minedAtHeight`
                uint256 _ntokenH = uint256(_minedH >> 128);
                uint256 _ethH = uint256(_minedH % (1 << 128));

                if (_ntokenH == 0) { // the sheet is the first in the block

                    // calculate the amount of NEST to be mined
                    uint256 _ntokenAmount = mineNToken(_ntoken);

                    // load `Bidder` from NTOKEN contract
                    address _bidder = INToken(_ntoken).checkBidder();

                    if (_bidder == state.C_NestPool) { // for new NTokens, 100% to miners
                        
                        // save the amount of NTOKEN to be mined
                        _ntokenH = _ntokenAmount;
                        // mint NTOKEN(new, v3.5) to NestPool
                        INToken(_ntoken).mint(_ntokenAmount, address(state.C_NestPool));

                    } else {                           // for old NTokens, 95% to miners, 5% to the bidder
                        
                        // mint NTOKEN(old, v3.0)
                        INTokenLegacy(_ntoken).increaseTotal(_ntokenAmount);
                        // transfer NTOKEN(old) to NestPool
                        INTokenLegacy(_ntoken).transfer(state.C_NestPool, _ntokenAmount);
                        // calculate the amount of NTOKEN, 95% => miner
                        _ntokenH = _ntokenAmount.mul(MiningV1Data.MINING_LEGACY_NTOKEN_MINER_REWARD_PERCENTAGE).div(100);
                        // 5% NTOKEN =>  `Bidder`
                        INestPool(state.C_NestPool).addNToken(_bidder, _ntoken, _ntokenAmount.sub(_ntokenH));
                    }
                }
                // add up `ethNum` into `minedAtHeight`
                _ethH = _ethH.add(ethNum);
                // encode `_nestH` and `_ethH` into `minedAtHeight`
                state.minedAtHeight[token][block.number] = (_ntokenH * (1<< 128) + _ethH);
            }
        }

        // calculate the average-prices and volatilities for (TOKEN. NTOKEN)

        state._stat(token);
        state._stat(_ntoken);
        return; 
    }

    /// @notice Close a price sheet of (ETH, USDx) | (ETH, NEST) | (ETH, TOKEN) | (ETH, NTOKEN)
    /// @dev Here we allow an empty price sheet (still in VERIFICATION-PERIOD) to be closed 
    /// @param token The address of TOKEN contract
    /// @param index The index of the price sheet w.r.t. `token`
    function close(address token, uint256 index) 
        public 
        noContract 
    {
        // call library
        state._close(token, index);

        // calculate average-price and volatility (forward)
        state._stat(token);

    }

 
    /// @notice Close a price sheet and withdraw assets for WEB users.  
    /// @dev Contracts aren't allowed to call it.
    /// @param token The address of TOKEN contract
    /// @param index The index of the price sheet w.r.t. `token`
    function closeAndWithdraw(address token, uint256 index) 
        external 
        noContract
    {
        // call library
        state._closeAndWithdraw(token, index);
        // calculate average-price and volatility (forward)
        state._stat(token);
    }

    /// @notice Close a batch of price sheets passed VERIFICATION-PHASE
    /// @dev Empty sheets but in VERIFICATION-PHASE aren't allowed
    /// @param token The address of TOKEN contract
    /// @param indices A list of indices of sheets w.r.t. `token`
    function closeList(address token, uint32[] memory indices) 
        external 
        noContract
    {
        // call library
        state._closeList(token, indices);

        // calculate average-price and volatility (forward)
        state._stat(token);

    }


    /// @notice Call the function to buy TOKEN/NTOKEN from a posted price sheet
    /// @dev bite TOKEN(NTOKEN) by ETH,  (+ethNumBal, -tokenNumBal)
    /// @param token The address of token(ntoken)
    /// @param index The position of the sheet in priceSheetList[token]
    /// @param biteNum The amount of bitting (in the unit of ETH), realAmount = biteNum * newTokenAmountPerEth
    /// @param newTokenAmountPerEth The new price of token (1 ETH : some TOKEN), here some means newTokenAmountPerEth
    function biteToken(address token, uint256 index, uint256 biteNum, uint256 newTokenAmountPerEth) 
        external 
        payable 
        noContract
    {
        // call library
        state._biteToken(token, index, biteNum, newTokenAmountPerEth);

        // calculate average-price and volatility (forward)
        state._stat(token);
    }

    /// @notice Call the function to buy TOKEN/NTOKEN from a posted price sheet
    /// @dev bite TOKEN(NTOKEN) by ETH,  (+ethNumBal, -tokenNumBal)
    /// @param token The address of token(ntoken)
    /// @param index The position of the sheet in priceSheetList[token]
    /// @param biteNum The amount of bitting (in the unit of ETH), realAmount = biteNum * newTokenAmountPerEth
    /// @param newTokenAmountPerEth The new price of token (1 ETH : some TOKEN), here some means newTokenAmountPerEth
    function biteEth(address token, uint256 index, uint256 biteNum, uint256 newTokenAmountPerEth)
        external
        payable
        noContract
    {
        // call library
        state._biteEth(token, index, biteNum, newTokenAmountPerEth);

        // calculate average-price and volatility (forward)
        state._stat(token);
    }


    /* ========== CALCULATION ========== */

    function stat(address _token) public 
    {
        // call library
        return state._stat(_token);
    }
    
    /* ========== PRICE QUERIES ========== */

    /// @notice Get the latest effective price for a token
    /// @dev It shouldn't be read from any contracts other than NestQuery
    function latestPriceOf(address token) 
        public
        view
        onlyByNestOrNoContract
        returns(uint256 ethAmount, uint256 tokenAmount, uint256 blockNum) 
    {
        MiningV1Data.PriceSheet[] storage _plist = state.priceSheetList[token];
        uint256 len = _plist.length;
        uint256 _ethNum;
        MiningV1Data.PriceSheet memory _sheet;

        if (len == 0) {
            revert("Nest:Mine:no(price)");
        }

        uint256 _first = 0;
        for (uint i = 1; i <= len; i++) {
            _sheet = _plist[len-i];
            if (_first == 0 && uint256(_sheet.height) + state.priceDurationBlock < block.number) {
                _ethNum = uint256(_sheet.remainNum);
                if (_ethNum == 0) {
                    continue;  // jump over a bitten sheet
                }
                _first = uint256(_sheet.height);
                tokenAmount = _ethNum.mul(uint256(_sheet.tokenAmountPerEth));
                ethAmount = _ethNum.mul(1 ether);
                blockNum = _first;
            } else if (_first == uint256(_sheet.height)) {
                _ethNum = uint256(_sheet.remainNum);
                tokenAmount = tokenAmount.add(_ethNum.mul(uint256(_sheet.tokenAmountPerEth)));
                ethAmount = ethAmount.add(_ethNum.mul(1 ether));
            } else if (_first > uint256(_sheet.height)) {
                break;
            }
        }
        blockNum = blockNum + uint256(state.priceDurationBlock); // safe math
        require(ethAmount > 0 && tokenAmount > 0, "Nest:Mine:no(price)");
    }

    /// @dev It shouldn't be read from any contracts other than NestQuery
    function priceOf(address token)
        public
        view
        noContractExcept(state.C_NestQuery)
        returns(uint256 ethAmount, uint256 tokenAmount, uint256 blockNum) 
    {
        MiningV1Data.PriceInfo memory pi = state.priceInfo[token];
        require(pi.height > 0, "Nest:Mine:NO(price)");
        ethAmount = uint256(pi.ethNum).mul(1 ether);
        tokenAmount = uint256(pi.tokenAmount);
        blockNum = uint256(pi.height + state.priceDurationBlock);
        require(ethAmount > 0 && tokenAmount > 0, "Nest:Mine:no(price)");
    }

    /// @dev It shouldn't be read from any contracts other than NestQuery
    function priceAvgAndSigmaOf(address token) 
        public 
        view 
        onlyByNestOrNoContract
        returns (uint128 price, uint128 avgPrice, int128 vola, uint32 bn) 
    {
        MiningV1Data.PriceInfo memory pi = state.priceInfo[token];
        require(pi.height > 0, "Nest:Mine:NO(price)");
        vola = ABDKMath64x64.sqrt(ABDKMath64x64.abs(pi.volatility_sigma_sq));
        price = uint128(uint256(pi.tokenAmount).div(uint256(pi.ethNum)));
        avgPrice = pi.avgTokenAmount;
        bn = pi.height + uint32(state.priceDurationBlock);
        require(price > 0 && avgPrice > 0, "Nest:Mine:no(price)");
    }

    function priceOfTokenAtHeight(address token, uint64 atHeight)
        public 
        view 
        noContractExcept(state.C_NestQuery)
        returns(uint256 ethAmount, uint256 tokenAmount, uint256 bn) 
    {
        (ethAmount, tokenAmount, bn) = state._priceOfTokenAtHeight(token, atHeight);
        require(ethAmount > 0 && tokenAmount > 0, "Nest:Mine:no(price)");
    }

    /// @notice Return a consecutive price list for a token 
    /// @dev 
    /// @param token The address of token contract
    /// @param num   The length of price list
    function priceListOfToken(address token, uint8 num) 
        external view 
        noContractExcept(state.C_NestQuery)
        returns (uint128[] memory data, uint256 bn) 
    {
        return state._priceListOfToken(token, num);
    }

    /* ========== MINING ========== */
    
    function mineNest() public view returns (uint256) 
    {
        uint256 _period = block.number.sub(state.genesisBlock).div(MiningV1Data.MINING_NEST_YIELD_CUTBACK_PERIOD);
        uint256 _nestPerBlock;
        if (_period > 9) {
            _nestPerBlock = MiningV1Data.MINING_NEST_YIELD_OFF_PERIOD_AMOUNT;
            if (block.number > MiningV1Data.MINING_FINAL_BLOCK_NUMBER) {
                return 0;  // NEST is empty
            }
        } else {
            _nestPerBlock = state._mining_nest_yield_per_block_amount[_period];
        }
        
        return _nestPerBlock.mul(block.number.sub(state.latestMiningHeight));
    }

    function minedNestAmount() external view returns (uint256) 
    {
       return uint256(state.minedNestAmount);
    }

    function latestMinedHeight() external view returns (uint64) 
    {
       return uint64(state.latestMiningHeight);
    }

    function mineNToken(address ntoken) public view returns (uint256) 
    {
        (uint256 _genesis, uint256 _last) = INToken(ntoken).checkBlockInfo();

        uint256 _period = block.number.sub(_genesis).div(MiningV1Data.MINING_NEST_YIELD_CUTBACK_PERIOD);
        uint256 _ntokenPerBlock;
        if (_period > 9) {
            _ntokenPerBlock = MiningV1Data.MINING_NTOKEN_YIELD_OFF_PERIOD_AMOUNT;
        } else {
            _ntokenPerBlock = state._mining_ntoken_yield_per_block_amount[_period];
        }
        uint256 _interval = block.number.sub(_last);
        if (_interval > MiningV1Data.MINING_NTOKEN_YIELD_BLOCK_LIMIT) {
            _interval = MiningV1Data.MINING_NTOKEN_YIELD_BLOCK_LIMIT;
        }

        // NOTE: no NTOKEN rewards if the mining interval is greater than a pre-defined number
        uint256 yieldAmount = _ntokenPerBlock.mul(_interval);
        return yieldAmount;
    }

    /* ========== WITHDRAW ========== */

    function withdrawEth(uint256 ethAmount) 
        external nonReentrant
    {
        INestPool(state.C_NestPool).withdrawEth(address(msg.sender), ethAmount); 
    }

    function withdrawEthAndToken(uint256 ethAmount, address token, uint256 tokenAmount) 
        external nonReentrant
    {
        INestPool(state.C_NestPool).withdrawEthAndToken(address(msg.sender), ethAmount, token, tokenAmount); 
    }

    function withdrawNest(uint256 nestAmount) 
        external nonReentrant
    {
        INestPool(state.C_NestPool).withdrawNest(address(msg.sender), nestAmount); 
    }

    function withdrawEthAndTokenAndNest(uint256 ethAmount, address token, uint256 tokenAmount, uint256 nestAmount) 
        external nonReentrant
    {
        INestPool(state.C_NestPool).withdrawEthAndToken(address(msg.sender), ethAmount, token, tokenAmount); 
        INestPool(state.C_NestPool).withdrawNest(address(msg.sender), nestAmount);
    }

    /* ========== VIEWS ========== */

    function lengthOfPriceSheets(address token) 
        view 
        external 
        returns (uint256)
    {
        return state.priceSheetList[token].length;
    }

    function priceSheet(address token, uint256 index) 
        view external 
        returns (MiningV1Data.PriceSheetPub memory sheet) 
    {
        return state._priceSheet(token, index); 
    }

    function fullPriceSheet(address token, uint256 index) 
        view 
        public
        noContract
        returns (MiningV1Data.PriceSheet memory sheet) 
    {
        uint256 len = state.priceSheetList[token].length;
        require (index < len, "Nest:Mine:>(len)");
        return state.priceSheetList[token][index];
    }

    function unVerifiedSheetList(address token)
        view 
        public
        noContract
        returns (MiningV1Data.PriceSheetPub2[] memory sheets) 
    {
        return state.unVerifiedSheetList(token);
    }

    function unClosedSheetListOf(address miner, address token, uint256 fromIndex, uint256 num) 
        view 
        public
        noContract
        returns (MiningV1Data.PriceSheetPub2[] memory sheets) 
    {
        return state.unClosedSheetListOf(miner, token, fromIndex, num);
    }

    function sheetListOf(address miner, address token, uint256 fromIndex, uint256 num) 
        view 
        public
        noContract
        returns (MiningV1Data.PriceSheetPub2[] memory sheets) 
    {
        return state.sheetListOf(miner, token, fromIndex, num);
    }

    /*
     /// @dev The function will be disabled when the upgrading is completed
    /// TODO: (TBD) auth needed? 
    function post2Only4Upgrade(
            address token,
            uint256 ethNum,
            uint256 tokenAmountPerEth,
            uint256 ntokenAmountPerEth
        )
        external 
        noContract
    {
       // only avialble in upgrade phase
        require (flag == MINING_FLAG_UPGRADE_NEEDED, "Nest:Mine:!flag");
        state._post2Only4Upgrade(token, ethNum, tokenAmountPerEth, ntokenAmountPerEth);
        address _ntoken = INestPool(state.C_NestPool).getNTokenFromToken(token);

        // calculate average price and volatility
        state._stat(token);
        state._stat(_ntoken);
    }
    */
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.12;


import "../iface/INestPool.sol";
import "../iface/INestStaking.sol";
import "../iface/INToken.sol";
import "../iface/INNRewardPool.sol";

import "../lib/SafeERC20.sol";


/// @author Inf Loop - <[email protected]>
/// @author 0x00  - <[email protected]>
library MiningV1Data {

    /* ========== CONSTANTS ========== */

    uint256 constant MINING_NEST_YIELD_CUTBACK_PERIOD = 2400000; // ~ 1 years 
    uint256 constant MINING_NEST_YIELD_CUTBACK_RATE = 80;     // percentage = 80%

    // yield amount (per block) after the first ten years
    uint256 constant MINING_NEST_YIELD_OFF_PERIOD_AMOUNT = 40 ether;
    // yield amount (per block) in the first year, it drops to 80% in the following nine years
    uint256 constant MINING_NEST_YIELD_PER_BLOCK_BASE = 400 ether;

    uint256 constant MINING_NTOKEN_YIELD_CUTBACK_RATE = 80;
    uint256 constant MINING_NTOKEN_YIELD_OFF_PERIOD_AMOUNT = 0.4 ether;
    uint256 constant MINING_NTOKEN_YIELD_PER_BLOCK_BASE = 4 ether;

    uint256 constant MINING_FINAL_BLOCK_NUMBER = 173121488;


    uint256 constant MINING_NEST_FEE_DIVIDEND_RATE = 80;    // percentage = 80%
    uint256 constant MINING_NEST_FEE_DAO_RATE = 20;         // percentage = 20%

    uint256 constant MINING_NTOKEN_FEE_DIVIDEND_RATE        = 60;     // percentage = 60%
    uint256 constant MINING_NTOKEN_FEE_DAO_RATE             = 20;     // percentage = 20%
    uint256 constant MINING_NTOKEN_FEE_NEST_DAO_RATE        = 20;     // percentage = 20%

    uint256 constant MINING_NTOKEN_YIELD_BLOCK_LIMIT = 100;

    uint256 constant NN_NEST_REWARD_PERCENTAGE = 15;
    uint256 constant DAO_NEST_REWARD_PERCENTAGE = 5;
    uint256 constant MINER_NEST_REWARD_PERCENTAGE = 80;

    uint256 constant MINING_LEGACY_NTOKEN_MINER_REWARD_PERCENTAGE = 95;
    uint256 constant MINING_LEGACY_NTOKEN_BIDDER_REWARD_PERCENTAGE = 5;

    uint8 constant PRICESHEET_STATE_CLOSED = 0;
    uint8 constant PRICESHEET_STATE_POSTED = 1;
    uint8 constant PRICESHEET_STATE_BITTEN = 2;

    uint8 constant PRICESHEET_TYPE_USD     = 1;
    uint8 constant PRICESHEET_TYPE_NEST    = 2;
    uint8 constant PRICESHEET_TYPE_TOKEN   = 3;
    uint8 constant PRICESHEET_TYPE_NTOKEN  = 4;
    uint8 constant PRICESHEET_TYPE_BITTING = 8;


    uint8 constant STATE_FLAG_UNINITIALIZED    = 0;
    uint8 constant STATE_FLAG_SETUP_NEEDED     = 1;
    uint8 constant STATE_FLAG_ACTIVE           = 3;
    uint8 constant STATE_FLAG_MINING_STOPPED   = 4;
    uint8 constant STATE_FLAG_CLOSING_STOPPED  = 5;
    uint8 constant STATE_FLAG_WITHDRAW_STOPPED = 6;
    uint8 constant STATE_FLAG_PRICE_STOPPED    = 7;
    uint8 constant STATE_FLAG_SHUTDOWN         = 127;

    uint256 constant MINING_NTOKEN_NON_DUAL_POST_THRESHOLD = 5_000_000 ether;


    /// @dev size: (2 x 256 bit)
    struct PriceSheet {    
        uint160 miner;       //  miner who posted the price (most significant bits, or left-most)
        uint32  height;      //
        uint32  ethNum;   
        uint32  remainNum;    

        uint8   level;           // the level of bitting, 1-4: eth-doubling | 5 - 127: nest-doubling
        uint8   typ;             // 1: USD | 2: NEST | 3: TOKEN | 4: NTOKEN
        uint8   state;           // 0: closed | 1: posted | 2: bitten
        uint8   _reserved;       // for padding
        uint32  ethNumBal;
        uint32  tokenNumBal;
        uint32  nestNum1k;
        uint128 tokenAmountPerEth;
    }
    
    /// @dev size: (3 x 256 bit)
    struct PriceInfo {
        uint32  index;
        uint32  height;         // NOTE: the height of being posted
        uint32  ethNum;         //  the balance of eth
        uint32  _reserved;
        uint128 tokenAmount;    //  the balance of token 
        int128  volatility_sigma_sq;
        int128  volatility_ut_sq;
        uint128  avgTokenAmount;  // avg = (tokenAmount : perEth)
        uint128 _reserved2;     
    }


    /// @dev The struct is for public data in a price sheet, so as to protect prices from being read
    struct PriceSheetPub {
        uint160 miner;       //  miner who posted the price (most significant bits, or left-most)
        uint32  height;
        uint32  ethNum;   

        uint8   typ;             // 1: USD | 2: NEST | 3: TOKEN | 4: NTOKEN(Not Available)
        uint8   state;           // 0: closed | 1: posted | 2: bitten
        uint32  ethNumBal;
        uint32  tokenNumBal;
    }


    struct PriceSheetPub2 {
        uint160 miner;       //  miner who posted the price (most significant bits, or left-most)
        uint32  height;
        uint32  ethNum;   
        uint32  remainNum; 

        uint8   level;           // the level of bitting, 1-4: eth-doubling | 5 - 127: nest-doubling
        uint8   typ;             // 1: USD | 2: NEST | 3: TOKEN | 4: NTOKEN(Not Available)
        uint8   state;           // 0: closed | 1: posted | 2: bitten
        uint256 index;           // return to the quotation of index
        uint32  nestNum1k;
        uint128 tokenAmountPerEth;   
    }

    /* ========== EVENTS ========== */

    event PricePosted(address miner, address token, uint256 index, uint256 ethAmount, uint256 tokenAmount);
    event PriceClosed(address miner, address token, uint256 index);
    event Deposit(address miner, address token, uint256 amount);
    event Withdraw(address miner, address token, uint256 amount);
    event TokenBought(address miner, address token, uint256 index, uint256 biteEthAmount, uint256 biteTokenAmount);
    event TokenSold(address miner, address token, uint256 index, uint256 biteEthAmount, uint256 biteTokenAmount);

    event VolaComputed(uint32 h, uint32 pos, uint32 ethA, uint128 tokenA, int128 sigma_sq, int128 ut_sq);

    event SetParams(uint8 miningEthUnit, uint32 nestStakedNum1k, uint8 biteFeeRate,
                    uint8 miningFeeRate, uint8 priceDurationBlock, uint8 maxBiteNestedLevel,
                    uint8 biteInflateFactor, uint8 biteNestInflateFactor);

    // event GovSet(address oldGov, address newGov);

    /* ========== GIANT STATE VARIABLE ========== */

    struct State {
        // TODO: more comments

        uint8   miningEthUnit;      // = 30 on mainnet;
        uint32  nestStakedNum1k;    // = 100;
        uint8   biteFeeRate;        // 
        uint8   miningFeeRate;      // = 10;  
        uint8   priceDurationBlock; // = 25;
        uint8   maxBiteNestedLevel; // = 3;
        uint8   biteInflateFactor;  // = 2;
        uint8   biteNestInflateFactor; // = 2;

        uint32  genesisBlock;       // = 6236588;

        uint128  latestMiningHeight;  // latest block number of NEST mining
        uint128  minedNestAmount;     // the total amount of mined NEST
        
        address  _developer_address;  // WARNING: DO NOT delete this unused variable
        address  _NN_address;         // WARNING: DO NOT delete this unused variable

        address  C_NestPool;
        address  C_NestToken;
        address  C_NestStaking;
        address  C_NNRewardPool;
        address  C_NestQuery;
        address  C_NestDAO;

        uint256[10] _mining_nest_yield_per_block_amount;
        uint256[10] _mining_ntoken_yield_per_block_amount;

        // A mapping (from token(address) to an array of PriceSheet)
        mapping(address => PriceSheet[]) priceSheetList;

        // from token(address) to Price
        mapping(address => PriceInfo) priceInfo;

        // (token-address, block-number) => (ethFee-total, nest/ntoken-mined-total)
        mapping(address => mapping(uint256 => uint256)) minedAtHeight;

        // WARNING: DO NOT delete these variables, reserved for future use
        uint256  _reserved1;
        uint256  _reserved2;
        uint256  _reserved3;
        uint256  _reserved4;
    }

}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../lib/SafeMath.sol";
import "../lib/SafeERC20.sol";
import '../lib/TransferHelper.sol';
import "../lib/ABDKMath64x64.sol";

import "../iface/INestPool.sol";
import "../iface/INestStaking.sol";
import "../iface/INToken.sol";
import "../iface/INNRewardPool.sol";
import "../libminingv1/MiningV1Data.sol";
//import "hardhat/console.sol";


/// @title  NestMiningV1/MiningV1Calc
/// @author Inf Loop - <[email protected]>
/// @author Paradox  - <[email protected]>
library MiningV1Calc {

    using SafeMath for uint256;
    
    /// @dev Average block mining interval, ~ 14s
    uint256 constant ETHEREUM_BLOCK_TIMESPAN = 14;

    function _calcVola(
            // uint256 ethA0, 
            uint256 tokenA0, 
            // uint256 ethA1, 
            uint256 tokenA1, 
            int128 _sigma_sq, 
            int128 _ut_sq,
            uint256 _interval
        )
        private
        pure
        // pure 
        returns (int128, int128)
    {
        int128 _ut_sq_2 = ABDKMath64x64.div(_ut_sq, 
            ABDKMath64x64.fromUInt(_interval.mul(ETHEREUM_BLOCK_TIMESPAN)));

        int128 _new_sigma_sq = ABDKMath64x64.add(
            ABDKMath64x64.mul(ABDKMath64x64.divu(95, 100), _sigma_sq),
            ABDKMath64x64.mul(ABDKMath64x64.divu(5,100), _ut_sq_2));

        int128 _new_ut_sq;
        _new_ut_sq = ABDKMath64x64.pow(ABDKMath64x64.sub(
                    ABDKMath64x64.divu(tokenA1, tokenA0), 
                    ABDKMath64x64.fromUInt(1)), 
                2);
        
        return (_new_sigma_sq, _new_ut_sq);
    }

    function _calcAvg(uint256 ethA, uint256 tokenA, uint256 _avg)
        private 
        pure
        returns(uint256)
    {
        uint256 _newP = tokenA.div(ethA);
        uint256 _newAvg;

        if (_avg == 0) {
            _newAvg = _newP;
        } else {
            _newAvg = (_avg.mul(95).div(100)).add(_newP.mul(5).div(100));
            // _newAvg = ABDKMath64x64.add(
            //     ABDKMath64x64.mul(ABDKMath64x64.divu(95, 100), _avg),
            //     ABDKMath64x64.mul(ABDKMath64x64.divu(5,100), _newP));
        }

        return _newAvg;
    }

    function _moveAndCalc(
            MiningV1Data.PriceInfo memory p0,
            MiningV1Data.PriceSheet[] storage pL,
            uint256 priceDurationBlock
        )
        private
        view
        returns (MiningV1Data.PriceInfo memory)
    {
        uint256 i = p0.index + 1;
        if (i >= pL.length) {
            return (MiningV1Data.PriceInfo(0,0,0,0,0,int128(0),int128(0), uint128(0), 0));
        }

        uint256 h = uint256(pL[i].height);
        if (h + priceDurationBlock >= block.number) {
            return (MiningV1Data.PriceInfo(0,0,0,0,0,int128(0),int128(0), uint128(0), 0));
        }

        uint256 ethA1 = 0;
        uint256 tokenA1 = 0;
        while (i < pL.length && pL[i].height == h) {
            uint256 _remain = uint256(pL[i].remainNum);
            if (_remain == 0) {
                i = i + 1;
                continue;  // jump over a bitten sheet
            }
            ethA1 = ethA1 + _remain;
            tokenA1 = tokenA1 + _remain.mul(pL[i].tokenAmountPerEth);
            i = i + 1;
        }
        i = i - 1;

        if (ethA1 == 0 || tokenA1 == 0) {
            return (MiningV1Data.PriceInfo(
                    uint32(i),  // index
                    uint32(0),  // height
                    uint32(0),  // ethNum
                    uint32(0),  // _reserved
                    uint32(0),  // tokenAmount
                    int128(0),  // volatility_sigma_sq
                    int128(0),  // volatility_ut_sq
                    uint128(0),  // avgTokenAmount
                    0           // _reserved2
            ));
        }
        int128 new_sigma_sq;
        int128 new_ut_sq;
        {
            if (uint256(p0.ethNum) != 0) {
                (new_sigma_sq, new_ut_sq) = _calcVola(
                    uint256(p0.tokenAmount).div(uint256(p0.ethNum)), 
                    uint256(tokenA1).div(uint256(ethA1)),
                p0.volatility_sigma_sq, p0.volatility_ut_sq,
                h - p0.height);
            }
        }
        uint256 _newAvg = _calcAvg(ethA1, tokenA1, p0.avgTokenAmount); 

        return(MiningV1Data.PriceInfo(
                uint32(i),          // index
                uint32(h),          // height
                uint32(ethA1),      // ethNum
                uint32(0),          // _reserved
                uint128(tokenA1),   // tokenAmount
                new_sigma_sq,       // volatility_sigma_sq
                new_ut_sq,          // volatility_ut_sq
                uint128(_newAvg),   // avgTokenAmount
                uint128(0)          // _reserved2
        ));
    }

    /// @dev The function updates the statistics of price sheets
    ///     It calculates from priceInfo to the newest that is effective.
    ///     Different from `_statOneBlock()`, it may cross multiple blocks.
    function _stat(MiningV1Data.State storage state, address token)
        external 
    {
        MiningV1Data.PriceInfo memory p0 = state.priceInfo[token];
        MiningV1Data.PriceSheet[] storage pL = state.priceSheetList[token];

        if (pL.length < 2) {
            return;
        }

        if (p0.height == 0) {

            MiningV1Data.PriceSheet memory _sheet = pL[0];
            p0.ethNum = _sheet.ethNum;
            p0.tokenAmount = uint128(uint256(_sheet.tokenAmountPerEth).mul(_sheet.ethNum));
            p0.height = _sheet.height;
            p0.volatility_sigma_sq = 0;
            p0.volatility_ut_sq = 0;
            p0.avgTokenAmount = uint128(_sheet.tokenAmountPerEth);
            // write back
            state.priceInfo[token] = p0;
        }

        MiningV1Data.PriceInfo memory p1;

        // record the gas usage
        uint256 startGas = gasleft();
        uint256 gasUsed;

        while (uint256(p0.index) < pL.length && uint256(p0.height) + state.priceDurationBlock < block.number){
            gasUsed = startGas - gasleft();
            // NOTE: check gas usage to prevent DOS attacks
            if (gasUsed > 1_000_000) {
                break; 
            }
            p1 = _moveAndCalc(p0, pL, state.priceDurationBlock);
            if (p1.index <= p0.index) {    // bootstraping
                break;
            } else if (p1.ethNum == 0) {   // jump cross a block with bitten prices
                p0.index = p1.index;
                continue;
            } else {                       // calculate one more block
                p0 = p1;
            }
        }

        if (p0.index > state.priceInfo[token].index) {
            state.priceInfo[token] = p0;
        }

        return;
    }

    /// @dev The function updates the statistics of price sheets across only one block.
    function _statOneBlock(MiningV1Data.State storage state, address token) 
        external 
    {
        MiningV1Data.PriceInfo memory p0 = state.priceInfo[token];
        MiningV1Data.PriceSheet[] storage pL = state.priceSheetList[token];
        if (pL.length < 2) {
            return;
        }
        (MiningV1Data.PriceInfo memory p1) = _moveAndCalc(p0, state.priceSheetList[token], state.priceDurationBlock);
        if (p1.index > p0.index && p1.ethNum != 0) {
            state.priceInfo[token] = p1;
        } else if (p1.index > p0.index && p1.ethNum == 0) {
            p0.index = p1.index;
            state.priceInfo[token] = p1;
        }
        return;
    }

    /// @notice Return a consecutive price list for a token 
    /// @dev 
    /// @param token The address of token contract
    /// @param num   The length of price list
    function _priceListOfToken(
            MiningV1Data.State storage state, 
            address token, 
            uint8 num
        )
        external 
        view
        returns (uint128[] memory data, uint256 bn) 
    {
        MiningV1Data.PriceSheet[] storage _list = state.priceSheetList[token];
        uint256 len = _list.length;
        uint256 _index = 0;
        data = new uint128[](num * 3);
        MiningV1Data.PriceSheet memory _sheet;
        uint256 _ethNum;

        // loop
        uint256 _curr = 0;
        uint256 _prev = 0;
        for (uint i = 1; i <= len; i++) {
            _sheet = _list[len - i];
            _curr = uint256(_sheet.height);
            if (_prev == 0) {
                if (_curr + state.priceDurationBlock < block.number) {
                    _ethNum = uint256(_sheet.remainNum);
                    if(_ethNum > 0) {
                        data[_index] = uint128(_curr + state.priceDurationBlock); // safe math
                        data[_index + 1] = uint128(_ethNum.mul(1 ether));
                        data[_index + 2] = uint128(_ethNum.mul(_sheet.tokenAmountPerEth));
                        bn = _curr + state.priceDurationBlock;  // safe math
                        _prev = _curr;
                    }
                }
            } else if (_prev == _curr) {
                _ethNum = uint256(_sheet.remainNum);
                data[_index + 1] += uint128(_ethNum.mul(1 ether));
                data[_index + 2] += uint128(_ethNum.mul(_sheet.tokenAmountPerEth));
            } else if (_prev > _curr) {
                _ethNum = uint256(_sheet.remainNum);
                if(_ethNum > 0){
                    _index += 3;
                    if (_index >= uint256(num * 3)) {
                        break;
                    }
                    data[_index] = uint128(_curr + state.priceDurationBlock); // safe math
                    data[_index + 1] = uint128(_ethNum.mul(1 ether));
                    data[_index + 2] = uint128(_ethNum.mul(_sheet.tokenAmountPerEth));
                    _prev = _curr;
                }
            }
        } 
        // require (data.length == uint256(num * 3), "Incorrect price list length");
    }

    function _priceOfTokenAtHeight(
            MiningV1Data.State storage state, 
            address token, 
            uint64 atHeight
        )
        external 
        view 
        returns(uint256 ethAmount, uint256 tokenAmount, uint256 blockNum) 
    {
        require(atHeight <= block.number, "Nest:Mine:!height");

        MiningV1Data.PriceSheet[] storage _list = state.priceSheetList[token];
        uint256 len = state.priceSheetList[token].length;
        MiningV1Data.PriceSheet memory _sheet;
        uint256 _ethNum;

        if (len == 0) {
            return (0, 0, 0);
        }

        uint256 _first = 0;
        uint256 _prev = 0;
        for (uint i = 1; i <= len; i++) {
            _sheet = _list[len - i];
            _first = uint256(_sheet.height);
            if (_prev == 0) {
                if (_first + state.priceDurationBlock < uint256(atHeight)) {
                    _ethNum = uint256(_sheet.remainNum);
                    if (_ethNum == 0) {
                        continue; // jump over a bitten sheet
                    }
                    ethAmount = _ethNum.mul(1 ether);
                    tokenAmount = _ethNum.mul(_sheet.tokenAmountPerEth);
                    blockNum = _first + state.priceDurationBlock;
                    _prev = _first;
                }
            } else if (_first == _prev) {
                _ethNum = uint256(_sheet.remainNum);
                ethAmount = ethAmount.add(_ethNum.mul(1 ether));
                tokenAmount = tokenAmount.add(_ethNum.mul(_sheet.tokenAmountPerEth));
            } else if (_prev > _first) {
                break;
            }
        }
    }

    function _priceSheet(
            MiningV1Data.State storage state, 
            address token, 
            uint256 index
        ) 
        view external 
        returns (MiningV1Data.PriceSheetPub memory sheet) 
    {
        uint256 len = state.priceSheetList[token].length;
        require (index < len, "Nest:Mine:!index");
        MiningV1Data.PriceSheet memory _sheet = state.priceSheetList[token][index];
        sheet.miner = _sheet.miner;
        sheet.height = _sheet.height;
        sheet.ethNum = _sheet.ethNum;
        sheet.typ = _sheet.typ;
        sheet.state = _sheet.state;
        sheet.ethNumBal = _sheet.ethNumBal;
        sheet.tokenNumBal = _sheet.tokenNumBal;
    }

    
    function unVerifiedSheetList(
            MiningV1Data.State storage state, 
            address token
        ) 
        view 
        public
        returns (MiningV1Data.PriceSheetPub2[] memory sheets) 
    {
        MiningV1Data.PriceSheet[] storage _list = state.priceSheetList[token]; 
        uint256 len = _list.length;
        uint256 num;
        for (uint i = 0; i < len; i++) {
            if (_list[len - 1 - i].height + state.priceDurationBlock < block.number) {
                break;
            }
            num += 1;
        }

        sheets = new MiningV1Data.PriceSheetPub2[](num);
        for (uint i = 0; i < num; i++) {
            MiningV1Data.PriceSheet memory _sheet = _list[len - 1 - i];
            if (uint256(_sheet.height) + state.priceDurationBlock < block.number) {
                break;
            }
            //sheets[i] = _sheet;
            sheets[i].miner = _sheet.miner;
            sheets[i].height = _sheet.height;
            sheets[i].ethNum = _sheet.ethNum;
            sheets[i].remainNum = _sheet.remainNum;
            sheets[i].level = _sheet.level;
            sheets[i].typ = _sheet.typ;
            sheets[i].state = _sheet.state;

            sheets[i].index = len - 1 - i;

            sheets[i].nestNum1k = _sheet.nestNum1k;
            sheets[i].tokenAmountPerEth = _sheet.tokenAmountPerEth;
        }
    }

    function unClosedSheetListOf(
            MiningV1Data.State storage state, 
            address miner, 
            address token, 
            uint256 fromIndex, 
            uint256 num) 
        view 
        external
        returns (MiningV1Data.PriceSheetPub2[] memory sheets) 
    {
        sheets = new MiningV1Data.PriceSheetPub2[](num);
        MiningV1Data.PriceSheet[] storage _list = state.priceSheetList[token]; 
        uint256 len = _list.length;
        require(fromIndex < len, "Nest:Mine:!from");

        for (uint i = 0; i < num; i++) {
            if (fromIndex < i) {
                break;
            }

            MiningV1Data.PriceSheet memory _sheet = _list[fromIndex - i];
            if (uint256(_sheet.miner) == uint256(miner)
                && (_sheet.state == MiningV1Data.PRICESHEET_STATE_POSTED 
                    || _sheet.state == MiningV1Data.PRICESHEET_STATE_BITTEN)) {
            
                sheets[i].miner = _sheet.miner;
                sheets[i].height = _sheet.height;
                sheets[i].ethNum = _sheet.ethNum;
                sheets[i].remainNum = _sheet.remainNum;
                sheets[i].level = _sheet.level;
                sheets[i].typ = _sheet.typ;
                sheets[i].state = _sheet.state;

                sheets[i].index = fromIndex - i;

                sheets[i].nestNum1k = _sheet.nestNum1k;
                sheets[i].tokenAmountPerEth = _sheet.tokenAmountPerEth;

            }
        }
    }

    function sheetListOf(
           MiningV1Data.State storage state, 
           address miner, 
           address token, 
           uint256 fromIndex, 
           uint256 num
        ) 
        view 
        external
        returns (MiningV1Data.PriceSheetPub2[] memory sheets) 
    {
        sheets = new MiningV1Data.PriceSheetPub2[](num);
        MiningV1Data.PriceSheet[] storage _list = state.priceSheetList[token]; 
        uint256 len = _list.length;
        require(fromIndex < len, "Nest:Mine:!from");

        for (uint i = 0; i < num; i++) {
            if (fromIndex < i) {
                break;
            }
            MiningV1Data.PriceSheet memory _sheet = _list[fromIndex - i];
            if (uint256(_sheet.miner) == uint256(miner)) {
            
                sheets[i].miner = _sheet.miner;
                sheets[i].height = _sheet.height;
                sheets[i].ethNum = _sheet.ethNum;
                sheets[i].remainNum = _sheet.remainNum;
                sheets[i].level = _sheet.level;
                sheets[i].typ = _sheet.typ;
                sheets[i].state = _sheet.state;

                sheets[i].index = fromIndex - i;
                sheets[i].nestNum1k = _sheet.nestNum1k;
                sheets[i].tokenAmountPerEth = _sheet.tokenAmountPerEth;

            }
        }
    }

}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../lib/SafeMath.sol";
import "../lib/SafeERC20.sol";
import '../lib/TransferHelper.sol';
import "../lib/ABDKMath64x64.sol";

import "../iface/INestPool.sol";
import "../iface/INestStaking.sol";
import "../iface/INToken.sol";
import "../iface/INNRewardPool.sol";
import "../libminingv1/MiningV1Data.sol";

//import "hardhat/console.sol";

/// @title  NestMiningV1/MiningV1Calc
/// @author Inf Loop - <[email protected]>
/// @author Paradox  - <[email protected]>
library MiningV1Op {

    using SafeMath for uint256;

    /// @notice Call the function to buy TOKEN/NTOKEN from a posted price sheet
    /// @dev bite TOKEN(NTOKEN) by ETH,  (+ethNumBal, -tokenNumBal)
    /// @param token The address of token(ntoken)
    /// @param index The position of the sheet in priceSheetList[token]
    /// @param biteNum The amount of bitting (in the unit of ETH), realAmount = biteNum * newTokenAmountPerEth
    /// @param newTokenAmountPerEth The new price of token (1 ETH : some TOKEN), here some means newTokenAmountPerEth
    function _biteToken(
            MiningV1Data.State storage state, 
            address token, 
            uint256 index, 
            uint256 biteNum, 
            uint256 newTokenAmountPerEth
        )
        external
    {
        // check parameters
        require(token != address(0x0), "Nest:Mine:(token)=0"); 
        require(newTokenAmountPerEth > 0, "Nest:Mine:(price)=0");
        require(biteNum >= state.miningEthUnit && biteNum % state.miningEthUnit == 0, "Nest:Mine:!(bite)");

        // check sheet
        MiningV1Data.PriceSheet memory _sheet = state.priceSheetList[token][index]; 
        require(uint256(_sheet.height) + state.priceDurationBlock >= block.number, "Nest:Mine:!EFF(sheet)");
        require(uint256(_sheet.remainNum) >= biteNum, "Nest:Mine:!(remain)");

        // load address of NestPool 
        INestPool _C_NestPool = INestPool(state.C_NestPool);

        // check sheet sate
        uint256 _state = uint256(_sheet.state);
        require(_state == MiningV1Data.PRICESHEET_STATE_POSTED 
             || _state == MiningV1Data.PRICESHEET_STATE_BITTEN,  "Nest:Mine:!(state)");

        {
            // load NTOKEN
            address _ntoken = _C_NestPool.getNTokenFromToken(token);
            // calculate fee
            uint256 _ethFee = biteNum.mul(1 ether).mul(state.biteFeeRate).div(1000);

            // save the changes into miner's virtual account
            if (msg.value.sub(_ethFee) > 0) {
                _C_NestPool.depositEth{value:msg.value.sub(_ethFee)}(address(msg.sender));
            }

            // pump fee into staking pool
            if (_ethFee > 0) {
                INestStaking(state.C_NestStaking).addETHReward{value:_ethFee}(_ntoken);
            }
        }
 
        // post a new price sheet
        { 
            // check bitting conditions
            uint256 _newEthNum;
            uint256 _newNestNum1k = uint256(_sheet.nestNum1k);
            {
                uint256 _level = uint256(_sheet.level);
                uint256 _newLevel;
                
                // calculate `(_newEthNum, _newNestNum1k, _newLevel)`
                if (_level > state.maxBiteNestedLevel && _level < 127) { // bitten sheet, nest doubling
                    _newEthNum = biteNum;
                    _newNestNum1k = _newNestNum1k.mul(biteNum.mul(state.biteNestInflateFactor)).div(_sheet.ethNum);
                    _newLevel = _level + 1;
                } else if (_level <= state.maxBiteNestedLevel) {  // bitten sheet, eth doubling 
                    _newEthNum = biteNum.mul(state.biteInflateFactor);
                    _newNestNum1k = _newNestNum1k.mul(biteNum.mul(state.biteNestInflateFactor)).div(_sheet.ethNum);
                    _newLevel = _level + 1;
                }

                // freeze NEST 
                _C_NestPool.freezeNest(address(msg.sender), _newNestNum1k.mul(1000 * 1e18));

                // freeze(TOKEN, ETH); or freeeze(ETH) but unfreeze(TOKEN)
                if (_newEthNum.mul(newTokenAmountPerEth) < biteNum * _sheet.tokenAmountPerEth) {
                    uint256 _unfreezetokenAmount;
                    _unfreezetokenAmount = uint256(_sheet.tokenAmountPerEth).mul(biteNum).sub((uint256(newTokenAmountPerEth)).mul(_newEthNum));               
                    _C_NestPool.unfreezeToken(msg.sender, token, _unfreezetokenAmount);
                    _C_NestPool.freezeEth(msg.sender, _newEthNum.add(biteNum).mul(1 ether));
                } else {
                    _C_NestPool.freezeEthAndToken(msg.sender, _newEthNum.add(biteNum).mul(1 ether), 
                        token, _newEthNum.mul(newTokenAmountPerEth)
                                         .sub(biteNum * _sheet.tokenAmountPerEth));
                }

                MiningV1Data.PriceSheet[] storage _sheetOfToken = state.priceSheetList[token];
                // append a new price sheet
                _sheetOfToken.push(MiningV1Data.PriceSheet(
                    uint160(msg.sender),                // miner 
                    uint32(block.number),               // atHeight
                    uint32(_newEthNum),                 // ethNum
                    uint32(_newEthNum),                 // remainNum
                    uint8(_newLevel),                   // level
                    uint8(_sheet.typ),                  // typ
                    uint8(MiningV1Data.PRICESHEET_STATE_POSTED),  // state 
                    uint8(0),                           // _reserved
                    uint32(_newEthNum),                 // ethNumBal
                    uint32(_newEthNum),                 // tokenNumBal
                    uint32(_newNestNum1k),              // nestNum1k
                    uint128(newTokenAmountPerEth)     // tokenAmountPerEth
                ));
              
            }

            // update the bitten sheet
            _sheet.state = MiningV1Data.PRICESHEET_STATE_BITTEN;
            _sheet.ethNumBal = uint32(uint256(_sheet.ethNumBal).add(biteNum));
            _sheet.tokenNumBal = uint32(uint256(_sheet.tokenNumBal).sub(biteNum));
            _sheet.remainNum = uint32(uint256(_sheet.remainNum).sub(biteNum));
            state.priceSheetList[token][index] = _sheet;
            
        }

        emit MiningV1Data.TokenBought(address(msg.sender), address(token), index, biteNum.mul(1 ether), biteNum.mul(_sheet.tokenAmountPerEth));
        return; 

    }

    /// @notice Call the function to buy TOKEN/NTOKEN from a posted price sheet
    /// @dev bite TOKEN(NTOKEN) by ETH,  (+ethNumBal, -tokenNumBal)
    /// @param token The address of token(ntoken)
    /// @param index The position of the sheet in priceSheetList[token]
    /// @param biteNum The amount of bitting (in the unit of ETH), realAmount = biteNum * newTokenAmountPerEth
    /// @param newTokenAmountPerEth The new price of token (1 ETH : some TOKEN), here some means newTokenAmountPerEth
    function _biteEth(
            MiningV1Data.State storage state, 
            address token, 
            uint256 index, 
            uint256 biteNum, 
            uint256 newTokenAmountPerEth
        )
        external
    {
        // check parameters
        require(token != address(0x0), "Nest:Mine:(token)=0"); 
        require(newTokenAmountPerEth > 0, "Nest:Mine:(price)=0");
        require(biteNum >= state.miningEthUnit && biteNum % state.miningEthUnit == 0, "Nest:Mine:!(bite)");

        MiningV1Data.PriceSheet memory _sheet = state.priceSheetList[token][index]; 
        require(uint256(_sheet.height) + state.priceDurationBlock >= block.number, "Nest:Mine:!EFF(sheet)");
        require(uint256(_sheet.remainNum) >= biteNum, "Nest:Mine:!(remain)");

        // load NestPool
        INestPool _C_NestPool = INestPool(state.C_NestPool);

        // check state
        uint256 _state = uint256(_sheet.state);
        require(_state == MiningV1Data.PRICESHEET_STATE_POSTED 
            || _state == MiningV1Data.PRICESHEET_STATE_BITTEN,  "Nest:Mine:!(state)");

        {
            // load NTOKEN
            address _ntoken = _C_NestPool.getNTokenFromToken(token);

            // calculate fee
            uint256 _ethFee = biteNum.mul(1 ether).mul(state.biteFeeRate).div(1000);

            // save the changes into miner's virtual account
            if (msg.value.sub(_ethFee) > 0) {
                _C_NestPool.depositEth{value:msg.value.sub(_ethFee)}(address(msg.sender));
            }

            // pump fee into NestStaking
            INestStaking(state.C_NestStaking).addETHReward{value:_ethFee}(_ntoken);
        }
        
        // post a new price sheet
        { 
            // check bitting conditions
            uint256 _newEthNum;
            uint256 _newNestNum1k = uint256(_sheet.nestNum1k);
            {
                uint256 _level = uint256(_sheet.level);
                uint256 _newLevel;

                if (_level > state.maxBiteNestedLevel && _level < 127) { // bitten sheet, nest doubling
                    _newEthNum = biteNum;
                    _newNestNum1k = _newNestNum1k.mul(biteNum.mul(state.biteNestInflateFactor)).div(_sheet.ethNum);
                    _newLevel = _level + 1;
                } else if (_level <= state.maxBiteNestedLevel) {  // bitten sheet, eth doubling 
                    _newEthNum = biteNum.mul(state.biteInflateFactor);
                    _newNestNum1k = _newNestNum1k.mul(biteNum.mul(state.biteNestInflateFactor)).div(_sheet.ethNum);
                    _newLevel = _level + 1;
                }

                MiningV1Data.PriceSheet[] storage _sheetOfToken = state.priceSheetList[token];
                // append a new price sheet
                _sheetOfToken.push(MiningV1Data.PriceSheet(
                    uint160(msg.sender),             // miner 
                    uint32(block.number),            // atHeight
                    uint32(_newEthNum),                 // ethNum
                    uint32(_newEthNum),                 // remainNum
                    uint8(_newLevel),                // level
                    uint8(_sheet.typ),               // typ
                    uint8(MiningV1Data.PRICESHEET_STATE_POSTED),  // state 
                    uint8(0),                        // _reserved
                    uint32(_newEthNum),                 // ethNumBal
                    uint32(_newEthNum),                 // tokenNumBal
                    uint32(_newNestNum1k),           // nestNum1k
                    uint128(newTokenAmountPerEth)    // tokenAmountPerEth
                ));
            }

            // freeze NEST 
            _C_NestPool.freezeNest(address(msg.sender), _newNestNum1k.mul(1000 * 1e18));

            // freeze(TOKEN, ETH)
            _C_NestPool.freezeEthAndToken(msg.sender, _newEthNum.sub(biteNum).mul(1 ether), 
                token, _newEthNum.mul(newTokenAmountPerEth)
                                    .add(biteNum.mul(_sheet.tokenAmountPerEth)));

            // update the bitten sheet
            _sheet.state = MiningV1Data.PRICESHEET_STATE_BITTEN;
            _sheet.ethNumBal = uint32(uint256(_sheet.ethNumBal).sub(biteNum));
            _sheet.tokenNumBal = uint32(uint256(_sheet.tokenNumBal).add(biteNum));
            _sheet.remainNum = uint32(uint256(_sheet.remainNum).sub(biteNum));
            state.priceSheetList[token][index] = _sheet;
        }

        emit MiningV1Data.TokenSold(address(msg.sender), address(token), index, biteNum.mul(1 ether), biteNum.mul(_sheet.tokenAmountPerEth));
        return; 
    }

    /// @notice Close a price sheet of (ETH, USDx) | (ETH, NEST) | (ETH, TOKEN) | (ETH, NTOKEN)
    /// @dev Here we allow an empty price sheet (still in VERIFICATION-PERIOD) to be closed 
    /// @param token The address of TOKEN contract
    /// @param index The index of the price sheet w.r.t. `token`
    function _close(
            MiningV1Data.State storage state, 
            address token, 
            uint256 index
        )
        external
    {
        // load sheet
        MiningV1Data.PriceSheet memory _sheet = state.priceSheetList[token][index];
        // check if the sheet is closable
        require(uint256(_sheet.height) + state.priceDurationBlock < block.number // safe_math
            || _sheet.remainNum == 0, "Nest:Mine:!(height)");

        // check owner
        require(address(_sheet.miner) == address(msg.sender), "Nest:Mine:!(miner)");
        // check state flag
        require(uint256(_sheet.state) != MiningV1Data.PRICESHEET_STATE_CLOSED, "Nest:Mine:!unclosed");

        // load ntoken
        INestPool _C_NestPool = INestPool(state.C_NestPool);
        address _ntoken = _C_NestPool.getNTokenFromToken(token);

        // distribute rewards (NEST or NTOKEN)
        {
            uint256 h = _sheet.height;
            if (_sheet.typ == MiningV1Data.PRICESHEET_TYPE_USD && _sheet.level == 0) {   // for (USDT, NEST)
                uint256 _nestH = uint256(state.minedAtHeight[token][h] / (1 << 128));
                uint256 _ethH = uint256(state.minedAtHeight[token][h] % (1 << 128));
                uint256 _reward = uint256(_sheet.ethNum).mul(_nestH).div(_ethH);
                _C_NestPool.addNest(address(msg.sender), _reward);
            } else if (_sheet.typ == MiningV1Data.PRICESHEET_TYPE_TOKEN && _sheet.level == 0) { // for (ERC20, NTOKEN)
                uint256 _ntokenH = uint256(state.minedAtHeight[token][h] / (1 << 128));
                uint256 _ethH = uint256(state.minedAtHeight[token][h] % (1 << 128));
                uint256 _reward = uint256(_sheet.ethNum).mul(_ntokenH).div(_ethH);
                _C_NestPool.addNToken(address(msg.sender), _ntoken, _reward);
            }
        }

        // unfreeze the assets withheld by the sheet
        {
            uint256 _ethAmount = uint256(_sheet.ethNumBal).mul(1 ether);
            uint256 _tokenAmount = uint256(_sheet.tokenNumBal).mul(_sheet.tokenAmountPerEth);
            uint256 _nestAmount = uint256(_sheet.nestNum1k).mul(1000 * 1e18);
            _sheet.ethNumBal = 0;
            _sheet.tokenNumBal = 0;
            _sheet.nestNum1k = 0;

            _C_NestPool.unfreezeEthAndToken(address(msg.sender), _ethAmount, token, _tokenAmount);
            _C_NestPool.unfreezeNest(address(msg.sender), _nestAmount); 
        }

        // update the state flag
        _sheet.state = MiningV1Data.PRICESHEET_STATE_CLOSED;

        // write back
        state.priceSheetList[token][index] = _sheet;

        // emit an event
        emit MiningV1Data.PriceClosed(address(msg.sender), token, index);
    }

    /// @notice Close a price sheet and withdraw assets for WEB users.  
    /// @dev Contracts aren't allowed to call it.
    /// @param token The address of TOKEN contract
    /// @param index The index of the price sheet w.r.t. `token`
    function _closeAndWithdraw(
            MiningV1Data.State storage state, 
            address token, 
            uint256 index
        ) 
        external 
    {
        // check sheet if passing verification
        MiningV1Data.PriceSheet memory _sheet = state.priceSheetList[token][index];
        require(uint256(_sheet.height) + state.priceDurationBlock < block.number // safe_math
            || _sheet.remainNum == 0, "Nest:Mine:!(height)");

        // check ownership and state
        require(address(_sheet.miner) == address(msg.sender), "Nest:Mine:!(miner)");
        require(uint256(_sheet.state) != MiningV1Data.PRICESHEET_STATE_CLOSED, "Nest:Mine:!unclosed");

        // get ntoken
        INestPool _C_NestPool = INestPool(state.C_NestPool);
        address _ntoken = _C_NestPool.getNTokenFromToken(token);

        {
            uint256 h = uint256(_sheet.height);
            if (_sheet.typ == MiningV1Data.PRICESHEET_TYPE_USD && _sheet.level == 0) {
                uint256 _nestH = uint256(state.minedAtHeight[token][h] / (1 << 128));
                uint256 _ethH = uint256(state.minedAtHeight[token][h] % (1 << 128));
                uint256 _reward = uint256(_sheet.ethNum).mul(_nestH).div(_ethH);
                _C_NestPool.addNest(address(msg.sender), _reward);
            } else if (_sheet.typ == MiningV1Data.PRICESHEET_TYPE_TOKEN && _sheet.level == 0) {
                uint256 _ntokenH = uint256(state.minedAtHeight[token][h] / (1 << 128));
                uint256 _ethH = uint256(state.minedAtHeight[token][h] % (1 << 128));
                uint256 _reward = uint256(_sheet.ethNum).mul(_ntokenH).div(_ethH);
                _C_NestPool.addNToken(address(msg.sender), _ntoken, _reward);
            }
        }

        {
            uint256 _ethAmount = uint256(_sheet.ethNumBal).mul(1 ether);
            uint256 _tokenAmount = uint256(_sheet.tokenNumBal).mul(_sheet.tokenAmountPerEth);
            uint256 _nestAmount = uint256(_sheet.nestNum1k).mul(1000 * 1e18);
            _sheet.ethNumBal = 0;
            _sheet.tokenNumBal = 0;
            _sheet.nestNum1k = 0;

            _C_NestPool.unfreezeEthAndToken(address(msg.sender), _ethAmount, token, _tokenAmount);
            _C_NestPool.unfreezeNest(address(msg.sender), _nestAmount); 
            _C_NestPool.withdrawEthAndToken(address(msg.sender), _ethAmount, token, _tokenAmount);
            _C_NestPool.withdrawNest(address(msg.sender), _nestAmount);
        }

        /*  
        - Issue #23: 
            Uncomment the following code to support withdrawing ethers cached 
        {
            uint256 _ethAmount = _C_NestPool.balanceOfEthInPool(address(msg.sender));
            if (_ethAmount > 0) {
                _C_NestPool.withdrawEth(address(msg.sender), _ethAmount);
            }
        }
        */

        _sheet.state = MiningV1Data.PRICESHEET_STATE_CLOSED;

        state.priceSheetList[token][index] = _sheet;

        emit MiningV1Data.PriceClosed(address(msg.sender), token, index);    
    }

    /// @notice Close a batch of price sheets passed VERIFICATION-PHASE
    /// @dev Empty sheets but in VERIFICATION-PHASE aren't allowed
    /// @param token The address of TOKEN contract
    /// @param indices A list of indices of sheets w.r.t. `token`
    function _closeList(
            MiningV1Data.State storage state, 
            address token, 
            uint32[] memory indices) 
        external 
    {
        uint256 _ethAmount;
        uint256 _tokenAmount;
        uint256 _nestAmount;
        uint256 _reward;

        // load storage point to the list of price sheets
        MiningV1Data.PriceSheet[] storage prices = state.priceSheetList[token];
        
        // loop
        for (uint i=0; i<indices.length; i++) {
            // load one sheet
            MiningV1Data.PriceSheet memory _sheet = prices[indices[i]];

            // check owner
            if (uint256(_sheet.miner) != uint256(msg.sender)) {
                continue;
            }

            // check state
            if(_sheet.state == MiningV1Data.PRICESHEET_STATE_CLOSED) {
                continue;
            }

            uint256 h = uint256(_sheet.height);
            // check if the sheet closable
            if (h + state.priceDurationBlock < block.number || _sheet.remainNum == 0) { // safe_math: untainted values

                // count up assets in the sheet
                _ethAmount = _ethAmount.add(uint256(_sheet.ethNumBal).mul(1 ether));
                _tokenAmount = _tokenAmount.add(uint256(_sheet.tokenNumBal).mul(_sheet.tokenAmountPerEth));
                _nestAmount = _nestAmount.add(uint256(_sheet.nestNum1k).mul(1000 * 1e18));

                // clear bits in the sheet
                _sheet.ethNumBal = 0;
                _sheet.tokenNumBal = 0;
                _sheet.nestNum1k = 0;
                
                // update state flag
                _sheet.state = MiningV1Data.PRICESHEET_STATE_CLOSED;
                
                // write back
                prices[indices[i]] = _sheet;

                // count up the reward
                if(_sheet.level == 0 && (_sheet.typ == MiningV1Data.PRICESHEET_TYPE_USD || _sheet.typ == MiningV1Data.PRICESHEET_TYPE_TOKEN)) {
                    uint256 _ntokenH = uint256(state.minedAtHeight[token][h] >> 128);
                    uint256 _ethH = uint256(state.minedAtHeight[token][h] << 128 >> 128);
                    _reward = _reward.add(uint256(_sheet.ethNum).mul(_ntokenH).div(_ethH));
                }
                emit MiningV1Data.PriceClosed(address(msg.sender), token, indices[i]);
            }
        }
        
        // load address of NestPool (for gas saving)
        INestPool _C_NestPool = INestPool(state.C_NestPool);

        // unfreeze assets
        if (_ethAmount > 0 || _tokenAmount > 0) {
            _C_NestPool.unfreezeEthAndToken(address(msg.sender), _ethAmount, token, _tokenAmount);
        }
        _C_NestPool.unfreezeNest(address(msg.sender), _nestAmount); 

        // distribute the rewards
        {
            uint256 _typ = prices[indices[0]].typ;
            if  (_typ == MiningV1Data.PRICESHEET_TYPE_USD) {
                _C_NestPool.addNest(address(msg.sender), _reward);
            } else if (_typ == MiningV1Data.PRICESHEET_TYPE_TOKEN) {
                address _ntoken = _C_NestPool.getNTokenFromToken(token);
                _C_NestPool.addNToken(address(msg.sender), _ntoken, _reward);
            }
        }
    }

    /*
    /// @dev This function is only for post dual-price-sheet before upgrading without assets
    function _post2Only4Upgrade(
            MiningV1Data.State storage state,
            address token,
            uint256 ethNum,
            uint256 tokenAmountPerEth,
            uint256 ntokenAmountPerEth
        )
        external 
    {
        // check parameters 
        require(ethNum == state.miningEthUnit, "Nest:Mine:!(ethNum)");
        require(tokenAmountPerEth > 0 && ntokenAmountPerEth > 0, "Nest:Mine:!(price)");
        address _ntoken = INestPool(state.C_NestPool).getNTokenFromToken(token);

        // no eth fee, no freezing

        // push sheets
        {
            uint8 typ1;
            uint8 typ2; 
            if (_ntoken == address(state.C_NestToken)) {
                typ1 = MiningV1Data.PRICESHEET_TYPE_USD;
                typ2 = MiningV1Data.PRICESHEET_TYPE_NEST;
            } else {
                typ1 = MiningV1Data.PRICESHEET_TYPE_TOKEN;
                typ2 = MiningV1Data.PRICESHEET_TYPE_NTOKEN;
            }
            MiningV1Data.PriceSheet[] storage _sheetToken = state.priceSheetList[token];
            // append a new price sheet
            _sheetToken.push(MiningV1Data.PriceSheet(
                uint160(msg.sender),            // miner 
                uint32(block.number),           // atHeight
                uint32(ethNum),                 // ethNum
                uint32(ethNum),                 // remainNum
                uint8(0),                       // level
                uint8(typ1),     // typ
                uint8(MiningV1Data.PRICESHEET_STATE_CLOSED), // state 
                uint8(0),                       // _reserved
                uint32(ethNum),                 // ethNumBal
                uint32(ethNum),                 // tokenNumBal
                uint32(state.nestStakedNum1k),        // nestNum1k
                uint128(tokenAmountPerEth)      // tokenAmountPerEth
            ));

            MiningV1Data.PriceSheet[] storage _sheetNToken = state.priceSheetList[_ntoken];
            // append a new price sheet for ntoken
            _sheetNToken.push(MiningV1Data.PriceSheet(
                uint160(msg.sender),            // miner 
                uint32(block.number),           // atHeight
                uint32(ethNum),                 // ethNum
                uint32(ethNum),                 // remainNum
                uint8(0),                       // level
                uint8(typ2),     // typ
                uint8(MiningV1Data.PRICESHEET_STATE_CLOSED), // state 
                uint8(0),                       // _reserved
                uint32(ethNum),                 // ethNumBal
                uint32(ethNum),                 // tokenNumBal
                uint32(state.nestStakedNum1k),        // nestNum1k
                uint128(ntokenAmountPerEth)      // tokenAmountPerEth
            ));
            emit MiningV1Data.PricePosted(msg.sender, token, (_sheetToken.length - 1), ethNum.mul(1 ether), tokenAmountPerEth.mul(ethNum)); 
            emit MiningV1Data.PricePosted(msg.sender, _ntoken, (_sheetNToken.length - 1), ethNum.mul(1 ether), ntokenAmountPerEth.mul(ethNum)); 
        }

        // no mining

        return; 
    }
    */

}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.12;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }

    function div(uint x, uint y) internal pure returns (uint z) {
        require(y > 0, "ds-math-div-zero");
        z = x / y;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.6.12;

import "./Address.sol";
import "./SafeMath.sol";

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(ERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(ERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(ERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(ERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function callOptionalReturn(ERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface ERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.12;

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

// SPDX-License-Identifier: Copyright © 2019 by ABDK Consulting

/*
 * ABDK Math 64.64 Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <[email protected]>
 */
pragma solidity 0.6.12;

/**
 * Smart contract library of mathematical functions operating with signed
 * 64.64-bit fixed point numbers.  Signed 64.64-bit fixed point number is
 * basically a simple fraction whose numerator is signed 128-bit integer and
 * denominator is 2^64.  As long as denominator is always the same, there is no
 * need to store it, thus in Solidity signed 64.64-bit fixed point numbers are
 * represented by int128 type holding only the numerator.
 */
library ABDKMath64x64 {
  /**
   * @dev Minimum value signed 64.64-bit fixed point number may have. 
   */
  int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;

  /**
   * @dev Maximum value signed 64.64-bit fixed point number may have. 
   */
  int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

  /**
   * Convert signed 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromInt (int256 x) internal pure returns (int128) {
    require (x >= -0x8000000000000000 && x <= 0x7FFFFFFFFFFFFFFF);
    return int128 (x << 64);
  }

  /**
   * Convert signed 64.64 fixed point number into signed 64-bit integer number
   * rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64-bit integer number
   */
  function toInt (int128 x) internal pure returns (int64) {
    return int64 (x >> 64);
  }

  /**
   * Convert unsigned 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromUInt (uint256 x) internal pure returns (int128) {
    require (x <= 0x7FFFFFFFFFFFFFFF);
    return int128 (x << 64);
  }

  /**
   * Convert signed 64.64 fixed point number into unsigned 64-bit integer
   * number rounding down.  Revert on underflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return unsigned 64-bit integer number
   */
  function toUInt (int128 x) internal pure returns (uint64) {
    require (x >= 0);
    return uint64 (x >> 64);
  }

  /**
   * Convert signed 128.128 fixed point number into signed 64.64-bit fixed point
   * number rounding down.  Revert on overflow.
   *
   * @param x signed 128.128-bin fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function from128x128 (int256 x) internal pure returns (int128) {
    int256 result = x >> 64;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Convert signed 64.64 fixed point number into signed 128.128 fixed point
   * number.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 128.128 fixed point number
   */
  function to128x128 (int128 x) internal pure returns (int256) {
    return int256 (x) << 64;
  }

  /**
   * Calculate x + y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function add (int128 x, int128 y) internal pure returns (int128) {
    int256 result = int256(x) + y;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Calculate x - y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sub (int128 x, int128 y) internal pure returns (int128) {
    int256 result = int256(x) - y;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Calculate x * y rounding down.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function mul (int128 x, int128 y) internal pure returns (int128) {
    int256 result = int256(x) * y >> 64;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Calculate x * y rounding towards zero, where x is signed 64.64 fixed point
   * number and y is signed 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y signed 256-bit integer number
   * @return signed 256-bit integer number
   */
  function muli (int128 x, int256 y) internal pure returns (int256) {
    if (x == MIN_64x64) {
      require (y >= -0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF &&
        y <= 0x1000000000000000000000000000000000000000000000000);
      return -y << 63;
    } else {
      bool negativeResult = false;
      if (x < 0) {
        x = -x;
        negativeResult = true;
      }
      if (y < 0) {
        y = -y; // We rely on overflow behavior here
        negativeResult = !negativeResult;
      }
      uint256 absoluteResult = mulu (x, uint256 (y));
      if (negativeResult) {
        require (absoluteResult <=
          0x8000000000000000000000000000000000000000000000000000000000000000);
        return -int256 (absoluteResult); // We rely on overflow behavior here
      } else {
        require (absoluteResult <=
          0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        return int256 (absoluteResult);
      }
    }
  }

  /**
   * Calculate x * y rounding down, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y unsigned 256-bit integer number
   * @return unsigned 256-bit integer number
   */
  function mulu (int128 x, uint256 y) internal pure returns (uint256) {
    if (y == 0) return 0;

    require (x >= 0);

    uint256 lo = (uint256 (x) * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) >> 64;
    uint256 hi = uint256 (x) * (y >> 128);

    require (hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
    hi <<= 64;

    require (hi <=
      0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - lo);
    return hi + lo;
  }

  /**
   * Calculate x / y rounding towards zero.  Revert on overflow or when y is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function div (int128 x, int128 y) internal pure returns (int128) {
    require (y != 0);
    int256 result = (int256 (x) << 64) / y;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are signed 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x signed 256-bit integer number
   * @param y signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divi (int256 x, int256 y) internal pure returns (int128) {
    require (y != 0);

    bool negativeResult = false;
    if (x < 0) {
      x = -x; // We rely on overflow behavior here
      negativeResult = true;
    }
    if (y < 0) {
      y = -y; // We rely on overflow behavior here
      negativeResult = !negativeResult;
    }
    uint128 absoluteResult = divuu (uint256 (x), uint256 (y));
    if (negativeResult) {
      require (absoluteResult <= 0x80000000000000000000000000000000);
      return -int128 (absoluteResult); // We rely on overflow behavior here
    } else {
      require (absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      return int128 (absoluteResult); // We rely on overflow behavior here
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divu (uint256 x, uint256 y) internal pure returns (int128) {
    require (y != 0);
    uint128 result = divuu (x, y);
    require (result <= uint128 (MAX_64x64));
    return int128 (result);
  }

  /**
   * Calculate -x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function neg (int128 x) internal pure returns (int128) {
    require (x != MIN_64x64);
    return -x;
  }

  /**
   * Calculate |x|.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function abs (int128 x) internal pure returns (int128) {
    require (x != MIN_64x64);
    return x < 0 ? -x : x;
  }

  /**
   * Calculate 1 / x rounding towards zero.  Revert on overflow or when x is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function inv (int128 x) internal pure returns (int128) {
    require (x != 0);
    int256 result = int256 (0x100000000000000000000000000000000) / x;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Calculate arithmetics average of x and y, i.e. (x + y) / 2 rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function avg (int128 x, int128 y) internal pure returns (int128) {
    return int128 ((int256 (x) + int256 (y)) >> 1);
  }

  /**
   * Calculate geometric average of x and y, i.e. sqrt (x * y) rounding down.
   * Revert on overflow or in case x * y is negative.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function gavg (int128 x, int128 y) internal pure returns (int128) {
    int256 m = int256 (x) * int256 (y);
    require (m >= 0);
    require (m <
        0x4000000000000000000000000000000000000000000000000000000000000000);
    return int128 (sqrtu (uint256 (m), uint256 (x) + uint256 (y) >> 1));
  }

  /**
   * Calculate x^y assuming 0^0 is 1, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y uint256 value
   * @return signed 64.64-bit fixed point number
   */
  function pow (int128 x, uint256 y) internal pure returns (int128) {
    uint256 absoluteResult;
    bool negativeResult = false;
    if (x >= 0) {
      absoluteResult = powu (uint256 (x) << 63, y);
    } else {
      // We rely on overflow behavior here
      absoluteResult = powu (uint256 (uint128 (-x)) << 63, y);
      negativeResult = y & 1 > 0;
    }

    absoluteResult >>= 63;

    if (negativeResult) {
      require (absoluteResult <= 0x80000000000000000000000000000000);
      return -int128 (absoluteResult); // We rely on overflow behavior here
    } else {
      require (absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      return int128 (absoluteResult); // We rely on overflow behavior here
    }
  }

  /**
   * Calculate sqrt (x) rounding down.  Revert if x < 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sqrt (int128 x) internal pure returns (int128) {
    require (x >= 0);
    return int128 (sqrtu (uint256 (x) << 64, 0x10000000000000000));
  }

  /**
   * Calculate binary logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function log_2 (int128 x) internal pure returns (int128) {
    require (x > 0);

    int256 msb = 0;
    int256 xc = x;
    if (xc >= 0x10000000000000000) { xc >>= 64; msb += 64; }
    if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
    if (xc >= 0x10000) { xc >>= 16; msb += 16; }
    if (xc >= 0x100) { xc >>= 8; msb += 8; }
    if (xc >= 0x10) { xc >>= 4; msb += 4; }
    if (xc >= 0x4) { xc >>= 2; msb += 2; }
    if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

    int256 result = msb - 64 << 64;
    uint256 ux = uint256 (x) << 127 - msb;
    for (int256 bit = 0x8000000000000000; bit > 0; bit >>= 1) {
      ux *= ux;
      uint256 b = ux >> 255;
      ux >>= 127 + b;
      result += bit * int256 (b);
    }

    return int128 (result);
  }

  /**
   * Calculate natural logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function ln (int128 x) internal pure returns (int128) {
    require (x > 0);

    return int128 (
        uint256 (log_2 (x)) * 0xB17217F7D1CF79ABC9E3B39803F2F6AF >> 128);
  }

  /**
   * Calculate binary exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp_2 (int128 x) internal pure returns (int128) {
    require (x < 0x400000000000000000); // Overflow

    if (x < -0x400000000000000000) return 0; // Underflow

    uint256 result = 0x80000000000000000000000000000000;

    if (x & 0x8000000000000000 > 0)
      result = result * 0x16A09E667F3BCC908B2FB1366EA957D3E >> 128;
    if (x & 0x4000000000000000 > 0)
      result = result * 0x1306FE0A31B7152DE8D5A46305C85EDEC >> 128;
    if (x & 0x2000000000000000 > 0)
      result = result * 0x1172B83C7D517ADCDF7C8C50EB14A791F >> 128;
    if (x & 0x1000000000000000 > 0)
      result = result * 0x10B5586CF9890F6298B92B71842A98363 >> 128;
    if (x & 0x800000000000000 > 0)
      result = result * 0x1059B0D31585743AE7C548EB68CA417FD >> 128;
    if (x & 0x400000000000000 > 0)
      result = result * 0x102C9A3E778060EE6F7CACA4F7A29BDE8 >> 128;
    if (x & 0x200000000000000 > 0)
      result = result * 0x10163DA9FB33356D84A66AE336DCDFA3F >> 128;
    if (x & 0x100000000000000 > 0)
      result = result * 0x100B1AFA5ABCBED6129AB13EC11DC9543 >> 128;
    if (x & 0x80000000000000 > 0)
      result = result * 0x10058C86DA1C09EA1FF19D294CF2F679B >> 128;
    if (x & 0x40000000000000 > 0)
      result = result * 0x1002C605E2E8CEC506D21BFC89A23A00F >> 128;
    if (x & 0x20000000000000 > 0)
      result = result * 0x100162F3904051FA128BCA9C55C31E5DF >> 128;
    if (x & 0x10000000000000 > 0)
      result = result * 0x1000B175EFFDC76BA38E31671CA939725 >> 128;
    if (x & 0x8000000000000 > 0)
      result = result * 0x100058BA01FB9F96D6CACD4B180917C3D >> 128;
    if (x & 0x4000000000000 > 0)
      result = result * 0x10002C5CC37DA9491D0985C348C68E7B3 >> 128;
    if (x & 0x2000000000000 > 0)
      result = result * 0x1000162E525EE054754457D5995292026 >> 128;
    if (x & 0x1000000000000 > 0)
      result = result * 0x10000B17255775C040618BF4A4ADE83FC >> 128;
    if (x & 0x800000000000 > 0)
      result = result * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB >> 128;
    if (x & 0x400000000000 > 0)
      result = result * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9 >> 128;
    if (x & 0x200000000000 > 0)
      result = result * 0x10000162E43F4F831060E02D839A9D16D >> 128;
    if (x & 0x100000000000 > 0)
      result = result * 0x100000B1721BCFC99D9F890EA06911763 >> 128;
    if (x & 0x80000000000 > 0)
      result = result * 0x10000058B90CF1E6D97F9CA14DBCC1628 >> 128;
    if (x & 0x40000000000 > 0)
      result = result * 0x1000002C5C863B73F016468F6BAC5CA2B >> 128;
    if (x & 0x20000000000 > 0)
      result = result * 0x100000162E430E5A18F6119E3C02282A5 >> 128;
    if (x & 0x10000000000 > 0)
      result = result * 0x1000000B1721835514B86E6D96EFD1BFE >> 128;
    if (x & 0x8000000000 > 0)
      result = result * 0x100000058B90C0B48C6BE5DF846C5B2EF >> 128;
    if (x & 0x4000000000 > 0)
      result = result * 0x10000002C5C8601CC6B9E94213C72737A >> 128;
    if (x & 0x2000000000 > 0)
      result = result * 0x1000000162E42FFF037DF38AA2B219F06 >> 128;
    if (x & 0x1000000000 > 0)
      result = result * 0x10000000B17217FBA9C739AA5819F44F9 >> 128;
    if (x & 0x800000000 > 0)
      result = result * 0x1000000058B90BFCDEE5ACD3C1CEDC823 >> 128;
    if (x & 0x400000000 > 0)
      result = result * 0x100000002C5C85FE31F35A6A30DA1BE50 >> 128;
    if (x & 0x200000000 > 0)
      result = result * 0x10000000162E42FF0999CE3541B9FFFCF >> 128;
    if (x & 0x100000000 > 0)
      result = result * 0x100000000B17217F80F4EF5AADDA45554 >> 128;
    if (x & 0x80000000 > 0)
      result = result * 0x10000000058B90BFBF8479BD5A81B51AD >> 128;
    if (x & 0x40000000 > 0)
      result = result * 0x1000000002C5C85FDF84BD62AE30A74CC >> 128;
    if (x & 0x20000000 > 0)
      result = result * 0x100000000162E42FEFB2FED257559BDAA >> 128;
    if (x & 0x10000000 > 0)
      result = result * 0x1000000000B17217F7D5A7716BBA4A9AE >> 128;
    if (x & 0x8000000 > 0)
      result = result * 0x100000000058B90BFBE9DDBAC5E109CCE >> 128;
    if (x & 0x4000000 > 0)
      result = result * 0x10000000002C5C85FDF4B15DE6F17EB0D >> 128;
    if (x & 0x2000000 > 0)
      result = result * 0x1000000000162E42FEFA494F1478FDE05 >> 128;
    if (x & 0x1000000 > 0)
      result = result * 0x10000000000B17217F7D20CF927C8E94C >> 128;
    if (x & 0x800000 > 0)
      result = result * 0x1000000000058B90BFBE8F71CB4E4B33D >> 128;
    if (x & 0x400000 > 0)
      result = result * 0x100000000002C5C85FDF477B662B26945 >> 128;
    if (x & 0x200000 > 0)
      result = result * 0x10000000000162E42FEFA3AE53369388C >> 128;
    if (x & 0x100000 > 0)
      result = result * 0x100000000000B17217F7D1D351A389D40 >> 128;
    if (x & 0x80000 > 0)
      result = result * 0x10000000000058B90BFBE8E8B2D3D4EDE >> 128;
    if (x & 0x40000 > 0)
      result = result * 0x1000000000002C5C85FDF4741BEA6E77E >> 128;
    if (x & 0x20000 > 0)
      result = result * 0x100000000000162E42FEFA39FE95583C2 >> 128;
    if (x & 0x10000 > 0)
      result = result * 0x1000000000000B17217F7D1CFB72B45E1 >> 128;
    if (x & 0x8000 > 0)
      result = result * 0x100000000000058B90BFBE8E7CC35C3F0 >> 128;
    if (x & 0x4000 > 0)
      result = result * 0x10000000000002C5C85FDF473E242EA38 >> 128;
    if (x & 0x2000 > 0)
      result = result * 0x1000000000000162E42FEFA39F02B772C >> 128;
    if (x & 0x1000 > 0)
      result = result * 0x10000000000000B17217F7D1CF7D83C1A >> 128;
    if (x & 0x800 > 0)
      result = result * 0x1000000000000058B90BFBE8E7BDCBE2E >> 128;
    if (x & 0x400 > 0)
      result = result * 0x100000000000002C5C85FDF473DEA871F >> 128;
    if (x & 0x200 > 0)
      result = result * 0x10000000000000162E42FEFA39EF44D91 >> 128;
    if (x & 0x100 > 0)
      result = result * 0x100000000000000B17217F7D1CF79E949 >> 128;
    if (x & 0x80 > 0)
      result = result * 0x10000000000000058B90BFBE8E7BCE544 >> 128;
    if (x & 0x40 > 0)
      result = result * 0x1000000000000002C5C85FDF473DE6ECA >> 128;
    if (x & 0x20 > 0)
      result = result * 0x100000000000000162E42FEFA39EF366F >> 128;
    if (x & 0x10 > 0)
      result = result * 0x1000000000000000B17217F7D1CF79AFA >> 128;
    if (x & 0x8 > 0)
      result = result * 0x100000000000000058B90BFBE8E7BCD6D >> 128;
    if (x & 0x4 > 0)
      result = result * 0x10000000000000002C5C85FDF473DE6B2 >> 128;
    if (x & 0x2 > 0)
      result = result * 0x1000000000000000162E42FEFA39EF358 >> 128;
    if (x & 0x1 > 0)
      result = result * 0x10000000000000000B17217F7D1CF79AB >> 128;

    result >>= 63 - (x >> 64);
    require (result <= uint256 (MAX_64x64));

    return int128 (result);
  }

  /**
   * Calculate natural exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp (int128 x) internal pure returns (int128) {
    require (x < 0x400000000000000000); // Overflow

    if (x < -0x400000000000000000) return 0; // Underflow

    return exp_2 (
        int128 (int256 (x) * 0x171547652B82FE1777D0FFDA0D23A7D12 >> 128));
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return unsigned 64.64-bit fixed point number
   */
  function divuu (uint256 x, uint256 y) private pure returns (uint128) {
    require (y != 0);

    uint256 result;

    if (x <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
      result = (x << 64) / y;
    else {
      uint256 msb = 192;
      uint256 xc = x >> 192;
      if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
      if (xc >= 0x10000) { xc >>= 16; msb += 16; }
      if (xc >= 0x100) { xc >>= 8; msb += 8; }
      if (xc >= 0x10) { xc >>= 4; msb += 4; }
      if (xc >= 0x4) { xc >>= 2; msb += 2; }
      if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

      result = (x << 255 - msb) / ((y - 1 >> msb - 191) + 1);
      require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

      uint256 hi = result * (y >> 128);
      uint256 lo = result * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

      uint256 xh = x >> 192;
      uint256 xl = x << 64;

      if (xl < lo) xh -= 1;
      xl -= lo; // We rely on overflow behavior here
      lo = hi << 128;
      if (xl < lo) xh -= 1;
      xl -= lo; // We rely on overflow behavior here

      assert (xh == hi >> 128);

      result += xl / y;
    }

    require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
    return uint128 (result);
  }

  /**
   * Calculate x^y assuming 0^0 is 1, where x is unsigned 129.127 fixed point
   * number and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x unsigned 129.127-bit fixed point number
   * @param y uint256 value
   * @return unsigned 129.127-bit fixed point number
   */
  function powu (uint256 x, uint256 y) private pure returns (uint256) {
    if (y == 0) return 0x80000000000000000000000000000000;
    else if (x == 0) return 0;
    else {
      int256 msb = 0;
      uint256 xc = x;
      if (xc >= 0x100000000000000000000000000000000) { xc >>= 128; msb += 128; }
      if (xc >= 0x10000000000000000) { xc >>= 64; msb += 64; }
      if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
      if (xc >= 0x10000) { xc >>= 16; msb += 16; }
      if (xc >= 0x100) { xc >>= 8; msb += 8; }
      if (xc >= 0x10) { xc >>= 4; msb += 4; }
      if (xc >= 0x4) { xc >>= 2; msb += 2; }
      if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

      int256 xe = msb - 127;
      if (xe > 0) x >>= xe;
      else x <<= -xe;

      uint256 result = 0x80000000000000000000000000000000;
      int256 re = 0;

      while (y > 0) {
        if (y & 1 > 0) {
          result = result * x;
          y -= 1;
          re += xe;
          if (result >=
            0x8000000000000000000000000000000000000000000000000000000000000000) {
            result >>= 128;
            re += 1;
          } else result >>= 127;
          if (re < -127) return 0; // Underflow
          require (re < 128); // Overflow
        } else {
          x = x * x;
          y >>= 1;
          xe <<= 1;
          if (x >=
            0x8000000000000000000000000000000000000000000000000000000000000000) {
            x >>= 128;
            xe += 1;
          } else x >>= 127;
          if (xe < -127) return 0; // Underflow
          require (xe < 128); // Overflow
        }
      }

      if (re > 0) result <<= re;
      else if (re < 0) result >>= -re;

      return result;
    }
  }

  /**
   * Calculate sqrt (x) rounding down, where x is unsigned 256-bit integer
   * number.
   *
   * @param x unsigned 256-bit integer number
   * @return unsigned 128-bit integer number
   */
  function sqrtu (uint256 x, uint256 r) private pure returns (uint128) {
    if (x == 0) return 0;
    else {
      require (r > 0);
      while (true) {
        uint256 rr = x / r;
        if (r == rr || r + 1 == rr) return uint128 (r);
        else if (r == rr + 1) return uint128 (rr);
        r = r + rr + 1 >> 1;
      }
    }
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.12;

import "../lib/SafeERC20.sol";

interface INestPool {

    // function getNTokenFromToken(address token) view external returns (address);
    // function setNTokenToToken(address token, address ntoken) external; 

    function addNest(address miner, uint256 amount) external;
    function addNToken(address contributor, address ntoken, uint256 amount) external;

    function depositEth(address miner) external payable;
    function depositNToken(address miner,  address from, address ntoken, uint256 amount) external;

    function freezeEth(address miner, uint256 ethAmount) external; 
    function unfreezeEth(address miner, uint256 ethAmount) external;

    function freezeNest(address miner, uint256 nestAmount) external;
    function unfreezeNest(address miner, uint256 nestAmount) external;

    function freezeToken(address miner, address token, uint256 tokenAmount) external; 
    function unfreezeToken(address miner, address token, uint256 tokenAmount) external;

    function freezeEthAndToken(address miner, uint256 ethAmount, address token, uint256 tokenAmount) external;
    function unfreezeEthAndToken(address miner, uint256 ethAmount, address token, uint256 tokenAmount) external;

    function getNTokenFromToken(address token) external view returns (address); 
    function setNTokenToToken(address token, address ntoken) external; 

    function withdrawEth(address miner, uint256 ethAmount) external;
    function withdrawToken(address miner, address token, uint256 tokenAmount) external;

    function withdrawNest(address miner, uint256 amount) external;
    function withdrawEthAndToken(address miner, uint256 ethAmount, address token, uint256 tokenAmount) external;
    // function withdrawNToken(address miner, address ntoken, uint256 amount) external;
    function withdrawNTokenAndTransfer(address miner, address ntoken, uint256 amount, address to) external;


    function balanceOfNestInPool(address miner) external view returns (uint256);
    function balanceOfEthInPool(address miner) external view returns (uint256);
    function balanceOfTokenInPool(address miner, address token)  external view returns (uint256);

    function addrOfNestToken() external view returns (address);
    function addrOfNestMining() external view returns (address);
    function addrOfNTokenController() external view returns (address);
    function addrOfNNRewardPool() external view returns (address);
    function addrOfNNToken() external view returns (address);
    function addrOfNestStaking() external view returns (address);
    function addrOfNestQuery() external view returns (address);
    function addrOfNestDAO() external view returns (address);

    function addressOfBurnedNest() external view returns (address);

    function setGovernance(address _gov) external; 
    function governance() external view returns(address);
    function initNestLedger(uint256 amount) external;
    function drainNest(address to, uint256 amount, address gov) external;

}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.12;


interface INestStaking {
    // Views

    /// @dev How many stakingToken (XToken) deposited into to this reward pool (staking pool)
    /// @param  ntoken The address of NToken
    /// @return The total amount of XTokens deposited in this staking pool
    function totalStaked(address ntoken) external view returns (uint256);

    /// @dev How many stakingToken (XToken) deposited by the target account
    /// @param  ntoken The address of NToken
    /// @param  account The target account
    /// @return The total amount of XToken deposited in this staking pool
    function stakedBalanceOf(address ntoken, address account) external view returns (uint256);


    // Mutative
    /// @dev Stake/Deposit into the reward pool (staking pool)
    /// @param  ntoken The address of NToken
    /// @param  amount The target amount
    function stake(address ntoken, uint256 amount) external;

    function stakeFromNestPool(address ntoken, uint256 amount) external;

    /// @dev Withdraw from the reward pool (staking pool), get the original tokens back
    /// @param  ntoken The address of NToken
    /// @param  amount The target amount
    function unstake(address ntoken, uint256 amount) external;

    /// @dev Claim the reward the user earned
    /// @param ntoken The address of NToken
    /// @return The amount of ethers as rewards
    function claim(address ntoken) external returns (uint256);

    /// @dev Add ETH reward to the staking pool
    /// @param ntoken The address of NToken
    function addETHReward(address ntoken) external payable;

    /// @dev Only for governance
    function loadContracts() external; 

    /// @dev Only for governance
    function loadGovernance() external; 

    function pause() external;

    function resume() external;

    //function setParams(uint8 dividendShareRate) external;

    /* ========== EVENTS ========== */

    // Events
    event RewardAdded(address ntoken, address sender, uint256 reward);
    event NTokenStaked(address ntoken, address indexed user, uint256 amount);
    event NTokenUnstaked(address ntoken, address indexed user, uint256 amount);
    event SavingWithdrawn(address ntoken, address indexed to, uint256 amount);
    event RewardClaimed(address ntoken, address indexed user, uint256 reward);

    event FlagSet(address gov, uint256 flag);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.12;

interface INTokenLegacy {
    function increaseTotal(uint256 value) external;

    // the block height where the ntoken was created
    function checkBlockInfo() external view returns(uint256 createBlock, uint256 recentlyUsedBlock);
    // the owner (auction winner) of the ntoken
    function checkBidder() external view returns(address);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../lib/SafeERC20.sol";


interface INestMining {
    
    struct Params {
        uint8    miningEthUnit;     // = 10;
        uint32   nestStakedNum1k;   // = 1;
        uint8    biteFeeRate;       // = 1; 
        uint8    miningFeeRate;     // = 10;
        uint8    priceDurationBlock; 
        uint8    maxBiteNestedLevel; // = 3;
        uint8    biteInflateFactor;
        uint8    biteNestInflateFactor;
    }

    function priceOf(address token) external view returns(uint256 ethAmount, uint256 tokenAmount, uint256 bn);
    
    function priceListOfToken(address token, uint8 num) external view returns(uint128[] memory data, uint256 bn);

    // function priceOfTokenAtHeight(address token, uint64 atHeight) external view returns(uint256 ethAmount, uint256 tokenAmount, uint64 bn);

    function latestPriceOf(address token) external view returns (uint256 ethAmount, uint256 tokenAmount, uint256 bn);

    function priceAvgAndSigmaOf(address token) 
        external view returns (uint128, uint128, int128, uint32);

    function minedNestAmount() external view returns (uint256);

    /// @dev Only for governance
    function loadContracts() external; 
    
    function loadGovernance() external;

    function upgrade() external;

    function setup(uint32   genesisBlockNumber, uint128  latestMiningHeight, uint128  minedNestTotalAmount, Params calldata initParams) external;

    function setParams1(uint128  latestMiningHeight, uint128  minedNestTotalAmount) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.12;

interface INestDAO {

    function addETHReward(address ntoken) external payable; 

    function addNestReward(uint256 amount) external;

    /// @dev Only for governance
    function loadContracts() external; 

    /// @dev Only for governance
    function loadGovernance() external;
    
    /// @dev Only for governance
    function start() external; 

    function initEthLedger(address ntoken, uint256 amount) external;

    event NTokenRedeemed(address ntoken, address user, uint256 amount);

    event AssetsCollected(address user, uint256 ethAmount, uint256 nestAmount);

    event ParamsSetup(address gov, uint256 oldParam, uint256 newParam);

    event FlagSet(address gov, uint256 flag);

}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.12;

interface INToken {
    // mint ntoken for value
    function mint(uint256 amount, address account) external;

    // the block height where the ntoken was created
    function checkBlockInfo() external view returns(uint256 createBlock, uint256 recentlyUsedBlock);
    // the owner (auction winner) of the ntoken
    function checkBidder() external view returns(address);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.12;

/// @title NNRewardPool
/// @author Inf Loop - <[email protected]>
/// @author Paradox  - <[email protected]>

interface INNRewardPool {
    
    /* [DEPRECATED]
        uint256 constant DEV_REWARD_PERCENTAGE   = 5;
        uint256 constant NN_REWARD_PERCENTAGE    = 15;
        uint256 constant MINER_REWARD_PERCENTAGE = 80;
    */

    /// @notice Add rewards for Nest-Nodes, only governance or NestMining (contract) are allowed
    /// @dev  The rewards need to pull from NestPool
    /// @param _amount The amount of Nest token as the rewards to each nest-node
    function addNNReward(uint256 _amount) external;

    /// @notice Claim rewards by Nest-Nodes
    /// @dev The rewards need to pull from NestPool
    function claimNNReward() external ;  

    /// @dev The callback function called by NNToken.transfer()
    /// @param fromAdd The address of 'from' to transfer
    /// @param toAdd The address of 'to' to transfer
    function nodeCount(address fromAdd, address toAdd) external;

    /// @notice Show the amount of rewards unclaimed
    /// @return reward The reward of a NN holder
    function unclaimedNNReward() external view returns (uint256 reward);

    /// @dev Only for governance
    function loadContracts() external; 

    /// @dev Only for governance
    function loadGovernance() external; 

    /* ========== EVENTS ============== */

    /// @notice When rewards are added to the pool
    /// @param reward The amount of Nest Token
    /// @param allRewards The snapshot of all rewards accumulated
    event NNRewardAdded(uint256 reward, uint256 allRewards);

    /// @notice When rewards are claimed by nodes 
    /// @param nnode The address of the nest node
    /// @param share The amount of Nest Token claimed by the nest node
    event NNRewardClaimed(address nnode, uint256 share);

    /// @notice When flag of state is set by governance 
    /// @param gov The address of the governance
    /// @param flag The value of the new flag
    event FlagSet(address gov, uint256 flag);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.6.12;

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{value:amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}