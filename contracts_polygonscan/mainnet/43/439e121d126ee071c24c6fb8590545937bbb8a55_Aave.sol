// SPDX-License-Identifier: MIT
pragma solidity >=0.8;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./ProofToken.sol";
import "./ICurve_Aave_Swap.sol";
import "./ICurve_Aave_Gauge.sol";
import "./IUniswapV2Router02.sol";
import { HLS_aave } from "./HLS_aave.sol";

/// @title Polygon_Curve aave pool
/// @author Johnny Chang
contract Aave is ProofToken {

    struct User {
        uint256 depositPtokenAmount;
        uint256 depositToken0Amount; //DAI
        uint256 depositToken1Amount; //USDC
        uint256 depositToken2Amount; //USDT
        uint256 depositTokenValue;
        uint256 depositBlockTimestamp;
    }

    HLS_aave.HLSConfig private HLSConfig;
    HLS_aave.Position private position;
    HLS_aave.Oracle private oracle;
    
    using SafeMath for uint256;
    uint256 constant private MAX_INT_EXPONENTIATION = 2**256 - 1;

    uint256[3] public total_deposit_limit;
    uint256[3] public deposit_limit;
    uint256[3] private temp_free_funds;
    bool public TAG = false;
    address private dofin = address(0x9b1621198C2E60B3138a8D97119b20191a7b4bAf);
    address private factory = address(0x9b1621198C2E60B3138a8D97119b20191a7b4bAf);

    mapping (address => User) private users;

    function checkCaller() public view returns (bool) {
        if (msg.sender == factory || msg.sender == dofin) {
            return true;
        }
        return false;
    }

    function initialize(uint256 _percentage, address[3] memory _addrs, string memory _name, string memory _symbol, uint8 _decimals) external {
        if (dofin!=address(0) && factory!=address(0)) {
            require(checkCaller() == true, "Only factory or dofin can call this function");
        }
        position = HLS_aave.Position({
            token0: _addrs[0], // DAI  
            token1: _addrs[1], // USDC 
            token2: _addrs[2], // USDT

            enterPercentage: _percentage, // percentage of freeFunds to enter Curve's swap_addr
            
            enteredAmount0: 0, // DAI amount that has been added liquidity into Curve's swap_addr
            enteredAmount1: 0,
            enteredAmount2: 0
        });
        initializeToken(_name, _symbol, _decimals);
        factory = msg.sender;
    }
    
    function setConfig(address[6] memory _hlsConfig, address[4] memory _oracleConfig, address _dofin, uint256[3] memory _deposit_limit, uint256[3] memory _total_deposit_limit) external {
        if (dofin!=address(0) && factory!=address(0)) {
            require(checkCaller() == true, "Only factory or dofin can call this function");
        }

        HLSConfig.swap_addr = _hlsConfig[0];
        HLSConfig.gauge_addr = _hlsConfig[1];
        HLSConfig.LP_token = _hlsConfig[2];
        HLSConfig.CRV_token = _hlsConfig[3];
        HLSConfig.WMATIC_token = _hlsConfig[4];
        HLSConfig.sushiV2Router02_addr = _hlsConfig[5];

        oracle.token0_USD = _oracleConfig[0];
        oracle.token2_USD = _oracleConfig[1];
        oracle.CRV_USD    = _oracleConfig[2];
        oracle.WMATIC_USD = _oracleConfig[3];

        dofin = _dofin;
        deposit_limit = _deposit_limit;
        total_deposit_limit = _total_deposit_limit;

        // Approve for Curve swap_addr addliquidity
        IERC20(position.token0).approve(HLSConfig.swap_addr, MAX_INT_EXPONENTIATION);
        IERC20(position.token1).approve(HLSConfig.swap_addr, MAX_INT_EXPONENTIATION);
        IERC20(position.token2).approve(HLSConfig.swap_addr, MAX_INT_EXPONENTIATION);
        // Approve for Curve gauge_addr stake
        IERC20(HLSConfig.LP_token).approve(HLSConfig.gauge_addr, MAX_INT_EXPONENTIATION);
        // Approve for Curve swap_addr removeliquidity
        IERC20(HLSConfig.LP_token).approve(HLSConfig.swap_addr, MAX_INT_EXPONENTIATION);
        // Approve for withdraw?
        IERC20(position.token0).approve(address(this), MAX_INT_EXPONENTIATION);
        IERC20(position.token1).approve(address(this), MAX_INT_EXPONENTIATION);
        IERC20(position.token2).approve(address(this), MAX_INT_EXPONENTIATION);

        // Set Tag
        setTag(true);
    }

    function setTag(bool _tag) public {
        require(checkCaller() == true, "Only factory or dofin can call this function");
        TAG = _tag;
    }
    
    // getter function for script
    function getOverallPosition() public view returns(HLS_aave.Position memory, uint256, uint256) {
        uint256 unstakedLPAmount = IERC20(HLSConfig.LP_token).balanceOf(address(this));
        uint256 stakedLPAmount = IERC20(HLSConfig.gauge_addr).balanceOf(address(this));
        return (position, unstakedLPAmount, stakedLPAmount);
    }

    // getter function for script
    function getUser(address _account) external view returns (User memory) {
        
        return users[_account];
    }

    // getter function for script
    // get temp_free_funds value v.s current free funds in this contract
    function getFreeFunds() public view returns (uint256[3] memory, uint256[3] memory){
        uint256[3] memory balanceOf = HLS_aave.getFreeFundsOriginal(position, true) ;
        return (temp_free_funds, balanceOf) ;
    }

    /// @dev returns in decimals == 18, USDC value
    function getTotalAssets() public view returns (uint256) {

        uint256[3] memory FreeFunds = HLS_aave.getFreeFundsOriginal(position,true);
        uint256[3] memory separateFreeFundValue = HLS_aave.getTokenSeparateValue(oracle, FreeFunds);
        uint256 totalFreeFundValue = separateFreeFundValue[0].add(separateFreeFundValue[1]).add(separateFreeFundValue[2]);

        uint256 unstakedLPAmount = IERC20(HLSConfig.LP_token).balanceOf(address(this));
        uint256 stakedLPAmount = IERC20(HLSConfig.gauge_addr).balanceOf(address(this));
        uint256 totalLPAmount = unstakedLPAmount.add(stakedLPAmount);

        uint256 totalLPValue ;
        uint256 USDCequiAmount ;
        
        // caculate LP equivalence in USDC , in normalized decimals, USDC value
        if(totalLPAmount == 0) { totalLPValue = 0 ; }
        else{
            USDCequiAmount = ICurve_Aave_Swap(HLSConfig.swap_addr).calc_withdraw_one_coin(totalLPAmount,1);
            totalLPValue = USDCequiAmount.mul(10**12);
        } 

        // caculate reward equivalence in USDC , in normalized decimals, USDC value
        (uint256 pendingCRV_value, uint256 pendingWMATIC_value) = HLS_aave.getPendingRewardValue(HLSConfig.gauge_addr, HLSConfig.CRV_token, HLSConfig.WMATIC_token, oracle.CRV_USD, oracle.WMATIC_USD);
                
        return totalFreeFundValue.add(totalLPValue).add(pendingCRV_value).add(pendingWMATIC_value);
    }

    /// @dev returns ( user's withdraw total value , [DAI value, USDC value, ... etc.] )
    function getWithdrawAmount() external view returns (uint256[3] memory ) {

        uint256 withdraw_amount = balanceOf(msg.sender); // (proof Token) "withdraw_amount" is in decimals==18 
        uint256 totalAssets = getTotalAssets(); // "totalAssets" is in normalized decimals, USDC value
        uint256 value = withdraw_amount.mul(totalAssets).div(totalSupply_); // (proof Token) "totalSupply_" is in decimals==18

        User memory user = users[msg.sender];
        if (withdraw_amount > user.depositPtokenAmount) {
            return [uint256(0),uint256(0),uint256(0)];
        }       

        uint256 dofin_value;
        uint256 user_value;
        uint256[3] memory userSplitValue;
        //uint256[5] memory dofinSplitValue;
        
        // we charge 20% of user's profit, if user's profit > 0
        if (value > user.depositTokenValue) {
            dofin_value = value.sub(user.depositTokenValue).mul(20).div(100);
            user_value = value.sub(dofin_value);
            //dofinSplitValue = getSplitValue(dofin_value, user);
        } else {
            user_value = value;
        }
        
        userSplitValue = getSplitValue(user_value, user);
        uint256[3] memory userSplitAmount = HLS_aave.getAmountFromValue(oracle, userSplitValue);
        return userSplitAmount;

    }

    /// @dev refer to HLS_aave.exitPosition and HLS_aave.enterosition
    function rebalance(uint256 _typeout, uint256 _typein, int128 _i) external {
        require(checkCaller() == true, "Only factory or dofin can call this function");
        require(TAG == true, 'TAG ERROR.');

        position = HLS_aave.exitPosition(position, HLSConfig, _typeout, _i);

        position = HLS_aave.enterPosition(position, HLSConfig, _typein);

        temp_free_funds = HLS_aave.getFreeFundsOriginal(position, true);
    }

    function checkAddNewFunds() external view returns (uint256) {
        uint256[3] memory FreeFunds = HLS_aave.getFreeFundsOriginal( position, true );
        for(uint8 i=0; i<3;i++){
            if( FreeFunds[i] > temp_free_funds[i] ){
                if(IERC20(HLSConfig.LP_token).balanceOf(address(this)).add(IERC20(HLSConfig.gauge_addr).balanceOf(address(this))) == 0 ){
                    // Need to enter
                    return 1;
                }
                else{
                    // Need to rebalance
                    return 2;
                }
            }
        }
        return 0;
    }

    // only when calling this function will we claim pending reward CRV(and WMATIC)
    // returns how many CRV,WMATIC has been swapped to token and transferred back to contract
    // token is in the form of _CRV_path[_CRV_path.length-1], _WMATIC_path[_WMATIC_path.length-1]
    function autoCompound(address[] memory _CRV_path, address[] memory _WMATIC_path) external returns (uint256,uint256){

        require(checkCaller() == true, "Only factory or dofin can call this function");
        require(TAG == true, 'TAG ERROR.');

        ICurve_Aave_Gauge(HLSConfig.gauge_addr).claim_rewards();
        uint256 CRV_balance = IERC20(HLSConfig.CRV_token).balanceOf(address(this));
        uint256 WMATIC_balance = IERC20(HLSConfig.WMATIC_token).balanceOf(address(this));
        uint256[] memory amounts1 ;
        uint256[] memory amounts2 ;

        if( CRV_balance != 0 ){
            uint256 amountInSlippage1 = CRV_balance.mul(98).div(100);
            uint256[] memory amountOutMinAArray1 = IUniswapV2Router02(HLSConfig.sushiV2Router02_addr).getAmountsOut(amountInSlippage1, _CRV_path);
            uint256 amountOutMin1 = amountOutMinAArray1[amountOutMinAArray1.length - 1];
            amounts1 = IUniswapV2Router02(HLSConfig.sushiV2Router02_addr).swapExactTokensForTokens(
                CRV_balance,
                amountOutMin1,
                _CRV_path,
                address(this),
                block.timestamp
            );
        }

        if( WMATIC_balance != 0 ){
            uint256 amountInSlippage2 = WMATIC_balance.mul(98).div(100);
            uint256[] memory amountOutMinAArray2 = IUniswapV2Router02(HLSConfig.sushiV2Router02_addr).getAmountsOut(amountInSlippage2, _WMATIC_path);
            uint256 amountOutMin2 = amountOutMinAArray2[amountOutMinAArray2.length - 1];
            amounts2 = IUniswapV2Router02(HLSConfig.sushiV2Router02_addr).swapExactTokensForTokens(
                WMATIC_balance,
                amountOutMin2,
                _WMATIC_path,
                address(this),
                block.timestamp
            );
        }

        return (amounts1[amounts1.length-1] , amounts2[amounts2.length-1]);
    }
    
    function enter(uint256 _type ) external {
        require(checkCaller() == true, "Only factory or dofin can call this function");
        require(TAG == true, 'TAG ERROR.');
        position = HLS_aave.enterPosition(position, HLSConfig, _type) ;
        temp_free_funds = HLS_aave.getFreeFundsOriginal(position, true);
    }

    // will NOT claim pending reward when calling exit(and HLS_aave.exitPosition)
    // if we want to remove liquidity all only in one coin, than i=0~4 correspond to DAI,USDC,USDT,WBTC,WETH
    function exit(uint256 _type, int128 _i) external {

        require(checkCaller() == true, "Only factory or dofin can call this function");
        require(TAG == true, 'TAG ERROR.');
        position = HLS_aave.exitPosition(position, HLSConfig, _type , _i) ;
    }

    /// @dev returns "token_value_sum" is in decimals == 18 , USDC value
    /// @dev returns "shares"          is in decimals == 18 , no unit
    function getDepositAmountOut(uint256[3] memory _amounts) public view returns (uint256, uint256) {

        uint256[3] memory separateTokenValue = HLS_aave.getTokenSeparateValue(oracle, _amounts);

        uint256 token_value_sum = separateTokenValue[0].add(separateTokenValue[1]).add(separateTokenValue[2]) ;
        uint256 totalAssets = getTotalAssets();
        uint256 shares ;

        require(_amounts[0] <= deposit_limit[0].mul(10**IERC20(position.token0).decimals()), "Deposit too much DAI!");
        require(_amounts[1] <= deposit_limit[1].mul(10**IERC20(position.token1).decimals()), "Deposit too much USDC!");
        require(_amounts[2] <= deposit_limit[2].mul(10**IERC20(position.token2).decimals()), "Deposit too much USDT!");

        if (totalSupply_ > 0) {
            shares = token_value_sum.mul(totalSupply_).div(totalAssets);
        } else {
            shares = token_value_sum;
        }
        return (token_value_sum, shares);
    }
    
    // TODO 修改user.depositTokenValue，處理第一次depost跟第二次deposit不同token的匯率變動時user.depositTokenValue的計算？要嗎？
    // assume _amounts is in wei, refer to struct Position comments
    function deposit(uint256[3] memory _amounts) external returns (bool) {
        require(TAG == true, 'TAG ERROR.');
        // Calculation of pToken amount need to mint

        // token_value_sum : should be in "deciamls == 18"
        // shares : will be in "decimals = 18" , as set in proofToken's decimals().
        (uint256 token_value_sum, uint256 shares) = getDepositAmountOut(_amounts);

        // Record user deposit amount
        User memory user = users[msg.sender];
        user.depositPtokenAmount = user.depositPtokenAmount.add(shares) ;
        user.depositToken0Amount = user.depositToken0Amount.add(_amounts[0]) ;
        user.depositToken1Amount = user.depositToken1Amount.add(_amounts[1]) ;
        user.depositToken2Amount = user.depositToken2Amount.add(_amounts[2]) ;
        user.depositTokenValue = user.depositTokenValue.add(token_value_sum) ;
        user.depositBlockTimestamp = block.timestamp ;
        users[msg.sender] = user;

        // Mint pToken and transfer Token to cashbox
        mint(msg.sender, shares);
        IERC20(position.token0).transferFrom(msg.sender, address(this), _amounts[0]);
        IERC20(position.token1).transferFrom(msg.sender, address(this), _amounts[1]);
        IERC20(position.token2).transferFrom(msg.sender, address(this), _amounts[2]);

        return true;
    }

    /// @param _value is in normalized decimals , USD(C) value
    /// return "splitValue" is in normalized decimals , USD(C) value
    function getSplitValue(uint256 _value, User memory _user) public view returns (uint256[3] memory ) {

        uint256[3] memory splitValue;
        uint256[3] memory tokenSeparateValue = HLS_aave.getTokenSeparateValue(
            oracle,
            [_user.depositToken0Amount,
            _user.depositToken1Amount,
            _user.depositToken2Amount]
        );
        uint256 tokenTotalValue = tokenSeparateValue[0].add(tokenSeparateValue[1]).add(tokenSeparateValue[2]);

        // tokenTotalValue==0 => splitValue[i=0~5]==0
        if(tokenTotalValue==0){return splitValue;}

        for( uint8 i=0 ; i<3 ; i++ ){
            if(tokenSeparateValue[i]!=0){
                splitValue[i] = _value.mul(tokenSeparateValue[i]).div(tokenTotalValue);
            }
        }

        return splitValue;
    }


    // TODO 檢查withdraw()的邏輯有沒有錯？
    function withdraw() external returns (bool) {
        require(TAG == true, 'TAG ERROR.');
        uint256 withdraw_amount = balanceOf(msg.sender); // (proof Token) "withdraw_amount" is in decimals==18 
        uint256 totalAssets = getTotalAssets(); // "totalAssets" is in normalized decimals, USDC value
        uint256 value = withdraw_amount.mul(totalAssets).div(totalSupply_); // (proof Token) "totalSupply_" is in decimals==18
        // 1.0011565*10^18=1001156500000000000
        // "value" is in "decimals == 18" , USDC value

        User memory user = users[msg.sender];
        
        uint256[3] memory splitValue = getSplitValue(value, user);

        bool need_Exit = HLS_aave.checkNeedExit(position, oracle, splitValue);

        require(withdraw_amount <= user.depositPtokenAmount, "Proof token amount incorrect");
        require(block.timestamp > user.depositBlockTimestamp, "Deposit and withdraw in same block");
        
        // If no enough amount of free funds can transfer will trigger exit position
        if ( need_Exit == true) {
            
            position = HLS_aave.exitPosition(position, HLSConfig, 1 , 5);
        
            // get updated, accurate totalAssets after exitPosition
            uint256[3] memory FreeFunds = HLS_aave.getFreeFundsOriginal(position,true);
            
            uint256[3] memory separateFreeFundValue = HLS_aave.getTokenSeparateValue(oracle, FreeFunds);
            
            totalAssets = separateFreeFundValue[0].add(separateFreeFundValue[1]).add(separateFreeFundValue[2]);
            // get updated, accurate value to withdraw
            //totalAssets = getTotalAssets();
            value = withdraw_amount.mul(totalAssets).div(totalSupply_);
        }

        //Will charge 20% fees
        burn(msg.sender, withdraw_amount);
        uint256 dofin_value;
        uint256 user_value;
        uint256[3] memory userSplitValue;
        uint256[3] memory dofinSplitValue;
        
        // we charge 20% of user's profit, if user's profit > 0
        if (value > user.depositTokenValue) {
            dofin_value = value.sub(user.depositTokenValue).mul(20).div(100);
            user_value = value.sub(dofin_value);
            dofinSplitValue = getSplitValue(dofin_value, user);
        } else {
            user_value = value;
        }
        
        userSplitValue = getSplitValue(user_value, user);

        // Modify user state data
        user.depositPtokenAmount = 0;
        user.depositToken0Amount = 0;
        user.depositToken1Amount = 0;
        user.depositToken2Amount = 0;
        user.depositTokenValue = 0;
        user.depositBlockTimestamp = 0;
        users[msg.sender] = user;

        // 從value轉換回amount
        uint256[3] memory userAmount = HLS_aave.getAmountFromValue(oracle, userSplitValue);
        uint256[3] memory dofinAmount = HLS_aave.getAmountFromValue(oracle, dofinSplitValue);

        if( userAmount[0] != 0 ){
            IERC20(position.token0).transferFrom(address(this), msg.sender, userAmount[0]);
        }
        if( userAmount[1] != 0 ){
            IERC20(position.token1).transferFrom(address(this), msg.sender, userAmount[1]);
        }
        if( userAmount[2] != 0 ){
            IERC20(position.token2).transferFrom(address(this), msg.sender, userAmount[2]);
        }


        if (dofinAmount[0] > IERC20(position.token0).balanceOf(address(this))) {
            dofinAmount[0] = IERC20(position.token0).balanceOf(address(this));
            need_Exit = false;
        }
        if (dofinAmount[1] > IERC20(position.token1).balanceOf(address(this))) {
            dofinAmount[1] = IERC20(position.token1).balanceOf(address(this));
            need_Exit = false;
        }        
        if (dofinAmount[2] > IERC20(position.token2).balanceOf(address(this))) {
            dofinAmount[2] = IERC20(position.token2).balanceOf(address(this));
            need_Exit = false;
        }


        if( dofinAmount[0] != 0 ){
            IERC20(position.token0).transferFrom(address(this), msg.sender, dofinAmount[0]);
        }
        if( dofinAmount[1] != 0 ){
            IERC20(position.token1).transferFrom(address(this), msg.sender, dofinAmount[1]);
        }
        if( dofinAmount[2] != 0 ){
            IERC20(position.token2).transferFrom(address(this), msg.sender, dofinAmount[2]);
        }

        
        //Enter position again
        if (need_Exit == true) {
            position = HLS_aave.enterPosition(position, HLSConfig, 1);
            temp_free_funds = HLS_aave.getFreeFundsOriginal(position, true);
        }
        
        return true;
    }

    function emergencyWithdrawal() external returns (bool) {
        require(TAG == false, 'NOT EMERGENCY');
        uint256 pTokenBalance = balanceOf(msg.sender);
        User memory user = users[msg.sender];
        require(pTokenBalance > 0,  "Incorrect quantity of Proof Token");
        require(user.depositPtokenAmount > 0,"Not depositor");

        IERC20(position.token0).transferFrom(address(this), msg.sender, user.depositToken0Amount);
        IERC20(position.token1).transferFrom(address(this), msg.sender, user.depositToken1Amount);
        IERC20(position.token2).transferFrom(address(this), msg.sender, user.depositToken2Amount);

        return true;
    }


}