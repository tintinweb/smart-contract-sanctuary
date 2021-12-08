// SPDX-License-Identifier: MIT
pragma solidity >=0.8;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./ProofToken.sol";
import "./ICurve_Deposit.sol";
import "./ICurve_Gauge.sol";
import "./IUniswapV2Router02.sol";
import { HighLevelSystem } from "./HighLevelSystem.sol";

/// @title Polygon_Curve atricrypto3 pool
contract Atricrypto3 is ProofToken {

    struct User {
        uint256 depositPtokenAmount;
        uint256 depositToken0Amount;//DAI
        uint256 depositToken1Amount;//USDC
        uint256 depositToken2Amount;//USDT
        uint256 depositToken3Amount;//WBTC
        uint256 depositToken4Amount;//WETH
        uint256 depositTokenValue;
        uint256 depositBlockTimestamp;
    }

    HighLevelSystem.HLSConfig private HLSConfig;
    HighLevelSystem.Position private position;
    HighLevelSystem.Oracle private oracle;
    
    using SafeMath for uint256;
    uint256 constant private MAX_INT_EXPONENTIATION = 2**256 - 1;

    uint256[5] public total_deposit_limit;
    uint256[5] public deposit_limit;
    uint256[5] private temp_free_funds;
    bool public TAG = false;
    address private dofin = address(0);
    address private factory = address(0);

    mapping (address => User) private users;

    function checkCaller() public view returns (bool) {
        if (msg.sender == factory || msg.sender == dofin) {
            return true;
        }
        return false;
    }

    function initialize(uint256 _percentage, address[5] memory _addrs, string memory _name, string memory _symbol, uint8 _decimals) external {
        if (dofin!=address(0) && factory!=address(0)) {
            require(checkCaller() == true, "Only factory or dofin can call this function");
        }
        position = HighLevelSystem.Position({
            token0: _addrs[0], // DAI  
            token1: _addrs[1], // USDC 
            token2: _addrs[2], // USDT
            token3: _addrs[3], // WBTC
            token4: _addrs[4], // WETH

            enterPercentage: _percentage, // percentage of freeFunds to enter Curve's deposit_addr
            
            enteredAmount0: 0, // DAI amount that has been added liquidity into Curve's deposit_addr
            enteredAmount1: 0,
            enteredAmount2: 0,
            enteredAmount3: 0,
            enteredAmount4: 0
        });
        initializeToken(_name, _symbol, _decimals);
        factory = msg.sender;
    }
    
    function setConfig(address[6] memory _hlsConfig, address[6] memory _oracleConfig, address _dofin, uint256[5] memory _deposit_limit, uint256[5] memory _total_deposit_limit) external {
        if (dofin!=address(0) && factory!=address(0)) {
            require(checkCaller() == true, "Only factory or dofin can call this function");
        }

        HLSConfig.deposit_addr = _hlsConfig[0];
        HLSConfig.gauge_addr = _hlsConfig[1];
        HLSConfig.LP_token = _hlsConfig[2];
        HLSConfig.CRV_token = _hlsConfig[3];
        HLSConfig.WMATIC_token = _hlsConfig[4];
        HLSConfig.sushiV2Router02_addr = _hlsConfig[5];

        oracle.token0_USD = _oracleConfig[0];
        oracle.token2_USD = _oracleConfig[1];
        oracle.token3_USD = _oracleConfig[2];
        oracle.token4_USD = _oracleConfig[3];
        oracle.CRV_USD    = _oracleConfig[4];
        oracle.WMATIC_USD = _oracleConfig[5];

        dofin = _dofin;
        deposit_limit = _deposit_limit;
        total_deposit_limit = _total_deposit_limit;

        IERC20(position.token0).approve(HLSConfig.deposit_addr, MAX_INT_EXPONENTIATION);
        IERC20(position.token1).approve(HLSConfig.deposit_addr, MAX_INT_EXPONENTIATION);
        IERC20(position.token2).approve(HLSConfig.deposit_addr, MAX_INT_EXPONENTIATION);
        IERC20(position.token3).approve(HLSConfig.deposit_addr, MAX_INT_EXPONENTIATION);
        IERC20(position.token4).approve(HLSConfig.deposit_addr, MAX_INT_EXPONENTIATION);
        IERC20(HLSConfig.LP_token).approve(HLSConfig.gauge_addr, MAX_INT_EXPONENTIATION);
        IERC20(HLSConfig.LP_token).approve(HLSConfig.deposit_addr, MAX_INT_EXPONENTIATION);
        IERC20(position.token0).approve(address(this), MAX_INT_EXPONENTIATION);
        IERC20(position.token1).approve(address(this), MAX_INT_EXPONENTIATION);
        IERC20(position.token2).approve(address(this), MAX_INT_EXPONENTIATION);
        IERC20(position.token3).approve(address(this), MAX_INT_EXPONENTIATION);
        IERC20(position.token4).approve(address(this), MAX_INT_EXPONENTIATION);
        setTag(true);
    }

    function setTag(bool _tag) public {
        require(checkCaller() == true, "Only factory or dofin can call this function");
        TAG = _tag;
    }
    
    function getOverallPosition() public view returns(HighLevelSystem.Position memory, uint256, uint256) {
        uint256 unstakedLPAmount = IERC20(HLSConfig.LP_token).balanceOf(address(this));
        uint256 stakedLPAmount = IERC20(HLSConfig.gauge_addr).balanceOf(address(this));
        return (position, unstakedLPAmount, stakedLPAmount);
    }

    function getUser(address _account) external view returns (User memory) {
        
        return users[_account];
    }

    function getFreeFunds() public view returns (uint256[5] memory, uint256[5] memory){
        uint256[5] memory balanceOf = HighLevelSystem.getFreeFundsOriginal(position, true) ;
        return (temp_free_funds, balanceOf) ;
    }

    /// @dev returns user's withdraw separate amount , [DAI amount, USDC amount, ... etc.] , in separate decimals
    function getWithdrawAmount() external view returns (uint256[5] memory) {

        uint256 withdraw_amount = balanceOf(msg.sender);
        uint256 totalAssets = HighLevelSystem.getTotalAssets(position, oracle, HLSConfig); 
        uint256 value = withdraw_amount.mul(totalAssets).div(totalSupply_);

        User memory user = users[msg.sender];
        if (withdraw_amount > user.depositPtokenAmount) {
            return ([uint256(0),uint256(0),uint256(0),uint256(0),uint256(0)] );
        }       

        uint256 user_value;
        uint256[5] memory userSplitValue;

        if (value > user.depositTokenValue) {
            user_value = value.sub(value.sub(user.depositTokenValue).mul(20).div(100));
        } else {
            user_value = value;
        }
        
        userSplitValue = getSplitValue(user_value, user);
        uint256[5] memory userSplitAmount = HighLevelSystem.getAmountFromValue(oracle, userSplitValue);

        return userSplitAmount;

    }

    function getTotalAssets() public view returns(uint256) {
        return HighLevelSystem.getTotalAssets(position, oracle, HLSConfig);
    }

    function getDepositAmountOut(uint256[5] memory _amounts) public view returns(uint256,uint256){
        return HighLevelSystem.getDepositAmountOut(HLSConfig, position, oracle, _amounts, deposit_limit, totalSupply_);
    }

    function rebalance(uint256 _typeout, uint256 _typein, uint256 _i) external {
        require(checkCaller() == true, "Only factory or dofin can call this function");
        require(TAG == true, 'TAG ERROR.');
        position = HighLevelSystem.exitPosition(position, HLSConfig, _typeout, _i);
        position = HighLevelSystem.enterPosition(position, HLSConfig, _typein);
        temp_free_funds = HighLevelSystem.getFreeFundsOriginal(position, true);
    }

    function checkAddNewFunds() public view returns(uint256){
        return HighLevelSystem.checkAddNewFunds(HLSConfig, position, temp_free_funds);
    }

    function autoCompound(address[] memory _CRV_path, address[] memory _WMATIC_path) public returns (uint256, uint256) {
        require(checkCaller() == true, "Only factory or dofin can call this function");
        require(TAG == true, 'TAG ERROR.');
        (uint256 CRV_amount, uint256 WMATIC_amount) = HighLevelSystem.autoCompound(HLSConfig, _CRV_path, _WMATIC_path);
        return (CRV_amount,WMATIC_amount);
    }
    
    function enter(uint256 _type ) external {
        require(checkCaller() == true, "Only factory or dofin can call this function");
        require(TAG == true, 'TAG ERROR.');
        position = HighLevelSystem.enterPosition(position, HLSConfig, _type) ;
        temp_free_funds = HighLevelSystem.getFreeFundsOriginal(position, true);
    }

    // will NOT claim pending reward when calling exit(and HighLevelSystem.exitPosition)
    // if we want to remove liquidity all only in one coin, than i=0~4 correspond to DAI,USDC,USDT,WBTC,WETH
    function exit(uint256 _type, uint256 _i) external {
        require(checkCaller() == true, "Only factory or dofin can call this function");
        require(TAG == true, 'TAG ERROR.');
        position = HighLevelSystem.exitPosition(position, HLSConfig, _type , _i) ;
    }
    
    // assume _amounts is in wei, refer to struct Position comments
    function deposit(uint256[5] memory _amounts) external returns (bool) {
        require(TAG == true, 'TAG ERROR.');
        (uint256 token_value_sum, uint256 shares) = getDepositAmountOut(_amounts);
        User memory user = users[msg.sender];
        user.depositPtokenAmount = user.depositPtokenAmount.add(shares) ;
        user.depositToken0Amount = user.depositToken0Amount.add(_amounts[0]) ;
        user.depositToken1Amount = user.depositToken1Amount.add(_amounts[1]) ;
        user.depositToken2Amount = user.depositToken2Amount.add(_amounts[2]) ;
        user.depositToken3Amount = user.depositToken3Amount.add(_amounts[3]) ;
        user.depositToken4Amount = user.depositToken4Amount.add(_amounts[4]) ;
        user.depositTokenValue = user.depositTokenValue.add(token_value_sum) ;
        user.depositBlockTimestamp = block.timestamp ;
        users[msg.sender] = user;
        mint(msg.sender, shares);
        IERC20(position.token0).transferFrom(msg.sender, address(this), _amounts[0]);
        IERC20(position.token1).transferFrom(msg.sender, address(this), _amounts[1]);
        IERC20(position.token2).transferFrom(msg.sender, address(this), _amounts[2]);
        IERC20(position.token3).transferFrom(msg.sender, address(this), _amounts[3]);
        IERC20(position.token4).transferFrom(msg.sender, address(this), _amounts[4]);
        return true;
    }

    /// @param _value is in normalized decimals , USD(C) value
    /// return "splitValue" is in normalized decimals , USD(C) value
    function getSplitValue(uint256 _value, User memory _user) public view returns (uint256[5] memory ) {
        uint256[5] memory splitValue;
        uint256[5] memory tokenSeparateValue = HighLevelSystem.getTokenSeparateValue(
            oracle,
            [_user.depositToken0Amount,
            _user.depositToken1Amount,
            _user.depositToken2Amount,
            _user.depositToken3Amount,
            _user.depositToken4Amount]
        );
        uint256 tokenTotalValue = tokenSeparateValue[0].add(tokenSeparateValue[1]).add(tokenSeparateValue[2]).add(tokenSeparateValue[3]).add(tokenSeparateValue[4]);
        // tokenTotalValue==0 => splitValue[i=0~5]==0
        if(tokenTotalValue==0){return splitValue;}
        for( uint8 i=0 ; i<5 ; i++ ){
            if(tokenSeparateValue[i]!=0){
                splitValue[i] = _value.mul(tokenSeparateValue[i]).div(tokenTotalValue);
            }
        }
        return splitValue;
    }

    function withdraw() external returns (bool) {
        require(TAG == true, 'TAG ERROR.');
        uint256 withdraw_amount = balanceOf(msg.sender);
        uint256 totalAssets = HighLevelSystem.getTotalAssets(position, oracle, HLSConfig); // "totalAssets" is in normalized decimals, USDC value
        uint256 value = withdraw_amount.mul(totalAssets).div(totalSupply_);

        User memory user = users[msg.sender];
        uint256[5] memory splitValue = getSplitValue(value, user);
        bool need_Exit = HighLevelSystem.checkNeedExit(position, oracle, splitValue);

        require(withdraw_amount <= user.depositPtokenAmount, "Proof token amount incorrect");
        require(block.timestamp > user.depositBlockTimestamp, "Deposit and withdraw in same block");
        
        // If no enough amount of free funds can transfer will trigger exit position
        if ( need_Exit == true) {
            position = HighLevelSystem.exitPosition(position, HLSConfig, 1 , 5);
            uint256[5] memory FreeFunds = HighLevelSystem.getFreeFundsOriginal(position,true);
            uint256[5] memory separateFreeFundValue = HighLevelSystem.getTokenSeparateValue(oracle, FreeFunds);
            totalAssets = separateFreeFundValue[0].add(separateFreeFundValue[1]).add(separateFreeFundValue[2]).add(separateFreeFundValue[3]).add(separateFreeFundValue[4]) ;
            // get updated, accurate value to withdraw
            value = withdraw_amount.mul(totalAssets).div(totalSupply_);
        }
        burn(msg.sender, withdraw_amount);
        uint256 dofin_value;
        uint256 user_value;
        uint256[5] memory userSplitValue;
        uint256[5] memory dofinSplitValue;
        
        if (value > user.depositTokenValue) {
            dofin_value = value.sub(user.depositTokenValue).mul(20).div(100);
            user_value = value.sub(dofin_value);
            dofinSplitValue = getSplitValue(dofin_value, user);
        } else {
            user_value = value;
        }
        
        userSplitValue = getSplitValue(user_value, user);
        user.depositPtokenAmount = 0;
        user.depositToken0Amount = 0;
        user.depositToken1Amount = 0;
        user.depositToken2Amount = 0;
        user.depositToken3Amount = 0;
        user.depositToken4Amount = 0;
        user.depositTokenValue = 0;
        user.depositBlockTimestamp = 0;
        users[msg.sender] = user;

        // 從value轉換回amount
        uint256[5] memory userAmount = HighLevelSystem.getAmountFromValue(oracle, userSplitValue);
        uint256[5] memory dofinAmount = HighLevelSystem.getAmountFromValue(oracle, dofinSplitValue);

        if( userAmount[0] != 0 ){
            IERC20(position.token0).transferFrom(address(this), msg.sender, userAmount[0]);
        }
        if( userAmount[1] != 0 ){
            IERC20(position.token1).transferFrom(address(this), msg.sender, userAmount[1]);
        }
        if( userAmount[2] != 0 ){
            IERC20(position.token2).transferFrom(address(this), msg.sender, userAmount[2]);
        }
        if( userAmount[3] != 0 ){
            IERC20(position.token3).transferFrom(address(this), msg.sender, userAmount[3]);
        }
        if( userAmount[4] != 0 ){
            IERC20(position.token4).transferFrom(address(this), msg.sender, userAmount[4]);
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
        if (dofinAmount[3] > IERC20(position.token3).balanceOf(address(this))) {
            dofinAmount[3] = IERC20(position.token3).balanceOf(address(this));
            need_Exit = false;
        }
        if (dofinAmount[4] > IERC20(position.token4).balanceOf(address(this))) {
            dofinAmount[4] = IERC20(position.token4).balanceOf(address(this));
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
        if( dofinAmount[3] != 0 ){
            IERC20(position.token3).transferFrom(address(this), msg.sender, dofinAmount[3]);
        }
        if( dofinAmount[4] != 0 ){
            IERC20(position.token4).transferFrom(address(this), msg.sender, dofinAmount[4]);
        }
        
        //Enter position again
        if (need_Exit == true) {
            position = HighLevelSystem.enterPosition(position, HLSConfig, 1);
            temp_free_funds = HighLevelSystem.getFreeFundsOriginal(position, true);
        }
        
        return true;
    }

    function emergencyWithdrawal() external returns (bool) {
        require(TAG == false, 'NOT EMERGENCY');
        uint256 pTokenBalance = balanceOf(msg.sender);
        User memory user = users[msg.sender];
        require(pTokenBalance > 0,  "Incorrect quantity of Proof Token");
        require(user.depositPtokenAmount > 0, "Not depositor");

        IERC20(position.token0).transferFrom(address(this), msg.sender, user.depositToken0Amount);
        IERC20(position.token1).transferFrom(address(this), msg.sender, user.depositToken1Amount);
        IERC20(position.token2).transferFrom(address(this), msg.sender, user.depositToken2Amount);
        IERC20(position.token3).transferFrom(address(this), msg.sender, user.depositToken3Amount);
        IERC20(position.token4).transferFrom(address(this), msg.sender, user.depositToken4Amount);

        return true;
    }

}