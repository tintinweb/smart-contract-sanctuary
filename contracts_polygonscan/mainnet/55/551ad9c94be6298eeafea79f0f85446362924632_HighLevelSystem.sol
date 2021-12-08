// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./LinkPolygonOracle.sol";
import "./ICurve_Gauge.sol";
import "./ICurve_Deposit.sol";
import "./IUniswapV2Router02.sol";



library HighLevelSystem {    

    using SafeMath for uint256;

    // HighLevelSystem config
    struct HLSConfig {
        address deposit_addr ; // where we add liquidity , address : 0x1d8b86e3D88cDb2d34688e87E72F388Cb541B7C8
        address gauge_addr ; // where we stake, address : 0x3B6B158A76fd8ccc297538F454ce7B4787778c7C

        address LP_token ; 
        // after adding liquidity, crvUSDBTCETH token, address : 0xdAD97F7713Ae9437fa9249920eC8507e5FbB23d3 , decimals == 18
        address CRV_token ; // staking reward CRV token, address : 0x172370d5Cd63279eFa6d502DAB29171933a610AF , decimals == 18
        address WMATIC_token ; // staking reward WMATIC token, address : 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270 , decimals == 18

        address sushiV2Router02_addr ; // address to swap CRV,WMATIC to buncker token , address : 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506

    }
    
    // ChainLink datafeed address
    struct Oracle{

        // all price below got from chainlink is in "decimals == 8"

        address token0_USD; //  DAI/USD  oracle contract,      address: 0x4746DeC9e833A82EC7C2C1356372CcF2cfcD2F3D
        // address token1_USD; 1USDC == 1USD
        address token2_USD; //  USDT/USD oracle contract.      address: 0x0A6513e40db6EB1b165753AD52E80663aeA50545
        address token3_USD; //  WBTC/USD oracle contract,      address: 0xDE31F8bFBD8c84b5360CFACCa3539B938dd78ae6
        address token4_USD; //  "ETH"/USD oracle contract,     address: 0xF9680D99D6C9589e2a93a78A04A279e509205945

        address CRV_USD;    //  CRV/USD oracle contract,        address: 0x336584C8E6Dc19637A5b36206B1c79923111b405
        address WMATIC_USD; //  "MATIC"/USD oracle contract,    address: 0xAB594600376Ec9fD91F8e885dADF0CE036862dE0

    }

    // atricrypto3 pool tokens address , token entered amount
    struct Position {
        address token0; // DAI  , token decimals == 18 , address: 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063
        address token1; // USDC , token decimals == 6  , address: 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174
        address token2; // USDT , token decimals == 6  , address: 0xc2132D05D31c914a87C6611C10748AEb04B58e8F
        address token3; // WBTC , token decimals == 8  , address: 0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6
        address token4; // WETH , token decimals == 18 , address: 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619

        uint256 enterPercentage; // percentage of freeFunds to enter Curve's deposit_addr
        
        uint256 enteredAmount0; // DAI amount that has been added liquidity into Curve's deposit_addr
        uint256 enteredAmount1; // USDC amount that has been added liquidity into Curve's deposit_addr
        uint256 enteredAmount2; // USDT amount that has been added liquidity into Curve's deposit_addr
        uint256 enteredAmount3; // WBTC amount that has been added liquidity into Curve's deposit_addr
        uint256 enteredAmount4; // WETH amount that has been added liquidity into Curve's deposit_addr

    }

    function checkNeedExit(Position memory _position, Oracle memory _oracle, uint256[5] memory _splitValue) public view returns (bool){
        bool flag = false ;
        uint256[5] memory FreeFunds = getFreeFundsOriginal(_position, true);
        uint256[5] memory separateFreeFundValue = getTokenSeparateValue(_oracle, FreeFunds);
        for(uint256 i=0;i<5;i++){
            if( _splitValue[i] > separateFreeFundValue[i]){
                flag = true ;
                return flag ;
            }
        }
        return flag;
    }

    function checkAddNewFunds(HLSConfig memory self, Position memory position , uint256[5] memory temp_free_funds) external view returns (uint256) {
        uint256[5] memory FreeFunds = getFreeFundsOriginal( position, true );
        for(uint8 i=0; i<5;i++){
            if( FreeFunds[i] > temp_free_funds[i] ){
                if(IERC20(self.LP_token).balanceOf(address(this)).add(IERC20(self.gauge_addr).balanceOf(address(this))) == 0 ){
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

    // in "decimals==18,6,6,8,18"
    function getFreeFundsOriginal(Position memory _position, bool _getAll) public view returns(uint256[5] memory){

        if( _getAll == true ){
            // return all FreeFunds in cashbox
            return[
                IERC20(_position.token0).balanceOf(address(this)),
                IERC20(_position.token1).balanceOf(address(this)),
                IERC20(_position.token2).balanceOf(address(this)),
                IERC20(_position.token3).balanceOf(address(this)),
                IERC20(_position.token4).balanceOf(address(this))
            ];
        }

        else {
            // return enter_amounts needed to add liquidity
            return[
                (IERC20(_position.token0).balanceOf(address(this))).mul(_position.enterPercentage).div(100),
                (IERC20(_position.token1).balanceOf(address(this))).mul(_position.enterPercentage).div(100),
                (IERC20(_position.token2).balanceOf(address(this))).mul(_position.enterPercentage).div(100),
                (IERC20(_position.token3).balanceOf(address(this))).mul(_position.enterPercentage).div(100),
                (IERC20(_position.token4).balanceOf(address(this))).mul(_position.enterPercentage).div(100)
            ];
        }

    }

    /// @param _amounts : in original("decimals==18,6,6,8,18") , separate token value
    /// @dev   returns  : in normalized("decimals==18,18,18,18,18") , USDC value  
    // get the equivalent value of each token with respect to USDC in "decimals == 18"
    function getTokenSeparateValue(Oracle memory _oracle, uint256[5] memory _amounts) public view returns (uint256[5] memory) {

        // all price get from chainlink is in "decimals = 8"
        uint256 token_0_price = uint256(LinkPolygonOracle(_oracle.token0_USD).latestAnswer());
        uint256 token_2_price = uint256(LinkPolygonOracle(_oracle.token2_USD).latestAnswer());
        uint256 token_3_price = uint256(LinkPolygonOracle(_oracle.token3_USD).latestAnswer());
        uint256 token_4_price = uint256(LinkPolygonOracle(_oracle.token4_USD).latestAnswer());

        uint256 token_0_value ;
        uint256 token_1_value ;
        uint256 token_2_value ;
        uint256 token_3_value ;
        uint256 token_4_value ;

        // convert all token into equivalent USDC(i.e. USD) value , in "decimals = 18"
        if(_amounts[0]==0){ token_0_value = 0 ; }
        else { token_0_value = token_0_price.mul(_amounts[0]).div(10**8); }
        // .mul(10**(8+18-18)) = .div(10**8)

        token_1_value = _amounts[1].mul(10**12) ;
        // 18-6 = 12

        if(_amounts[2]==0){ token_2_value = 0 ; }
        else { token_2_value = token_2_price.mul(_amounts[2]).mul(10**4) ; }
        // 18-(8+6)  = 4
        
        if(_amounts[3]==0){ token_3_value = 0 ; }
        else { token_3_value = token_3_price.mul(_amounts[3]).mul(10**2); }
        // 18-(8+8)  = 2

        if(_amounts[4]==0){ token_4_value = 0 ; }
        else { token_4_value = token_4_price.mul(_amounts[4]).div(10**8); }
        // 8+18-18 = 8

        return [token_0_value, token_1_value, token_2_value, token_3_value, token_4_value ];
    }

    /// @param _values : in normalized decimals
    /// @dev   returns  : in original decimals , separate token value
    function getAmountFromValue(Oracle memory _oracle, uint256[5] memory _values) public view returns (uint256[5] memory) {
        uint256 token_0_price = uint256(LinkPolygonOracle(_oracle.token0_USD).latestAnswer());
        uint256 token_2_price = uint256(LinkPolygonOracle(_oracle.token2_USD).latestAnswer());
        uint256 token_3_price = uint256(LinkPolygonOracle(_oracle.token3_USD).latestAnswer());
        uint256 token_4_price = uint256(LinkPolygonOracle(_oracle.token4_USD).latestAnswer());

        uint256 token_0_amount ;
        uint256 token_1_amount ;
        uint256 token_2_amount ;
        uint256 token_3_amount ;
        uint256 token_4_amount ;

        if(_values[0]==0){ token_0_amount = 0 ; }
        else { token_0_amount = _values[0].div(token_0_price).mul(10**8); }
        // convert back to "decimals == 18"
        // 18- (18-8) = 8

        token_1_amount = _values[1].div(10**12) ;
        // convert back to "decimals == 6"
        // 6 - 18 = -12

        if(_values[2]==0){ token_2_amount = 0 ; }
        else { token_2_amount = _values[2].div(token_2_price).div(10**4) ; }
        // convert back to "decimals == 6"
        // 6 - (18-8) = -4
        
        if(_values[3]==0){ token_3_amount = 0 ; }
        else { token_3_amount = _values[3].div(token_3_price).div(10**2); }
        // convert back to "decimals == 8"
        // 8 - (18-8) = -2

        if(_values[4]==0){ token_4_amount = 0 ; }
        else { token_4_amount = _values[4].div(token_4_price).mul(10**8); }
        // convert back to "decimals == 18"
        // 18 - (18-8) = 8

        return [token_0_amount, token_1_amount, token_2_amount, token_3_amount, token_4_amount ];
    }

    
    /// @dev   returns  : in normalized decimals("decimals==18,18,18,18,18") , USDC value  
    function getPendingRewardValue(HLSConfig memory self, Oracle memory oracle) public view returns (uint256,uint256) {

        // ? ICurve_Gauge(_gauge).claimable_reward_write(address(this), _crv);
        // TODO check if we need to send both write transaction ? 
        // ICurve_Gauge(_gauge).claimable_reward_write(address(this), _matic);
        // TODO check if we can chang ABI to view manually, and discard claimable_reward_write() ?

        // both decimals = 18
        uint256 pendingCRV_amount = ICurve_Gauge(self.gauge_addr).claimable_reward(address(this), self.CRV_token);
        uint256 pendingWMATIC_amount = ICurve_Gauge(self.gauge_addr).claimable_reward(address(this), self.WMATIC_token);

        // both decimals = 8
        uint256 CRV_price = uint256(LinkPolygonOracle(oracle.CRV_USD).latestAnswer());
        uint256 WMATIC_price = uint256(LinkPolygonOracle(oracle.WMATIC_USD).latestAnswer());

        // transfrom into USDC value in normalized decimals 
        uint256 pendingCRV_value ;
        uint256 pendingWMATIC_value ;
        if(pendingCRV_amount == 0 ) { pendingCRV_value = 0 ; }
        else{ pendingCRV_value = pendingCRV_amount.mul(CRV_price).div(10**8); }
        // 18+8-18=8

        if(pendingWMATIC_amount == 0) { pendingWMATIC_value = 0 ; }
        else{ pendingWMATIC_value = pendingWMATIC_amount.mul(WMATIC_price).div(10**8); }
        // 18+8-18=18

        return (pendingCRV_value, pendingWMATIC_value) ;
    }

    /// @dev returns in decimals == 18, USDC value
    function getTotalAssets(Position memory position, Oracle memory oracle, HLSConfig memory self) public view returns (uint256) {

        uint256[5] memory FreeFunds = getFreeFundsOriginal(position,true);
        uint256[5] memory separateFreeFundValue = getTokenSeparateValue(oracle, FreeFunds);
        uint256 totalFreeFundValue = separateFreeFundValue[0].add(separateFreeFundValue[1]).add(separateFreeFundValue[2]).add(separateFreeFundValue[3]).add(separateFreeFundValue[4]) ;

        uint256 unstakedLPAmount = IERC20(self.LP_token).balanceOf(address(this));
        uint256 stakedLPAmount = IERC20(self.gauge_addr).balanceOf(address(this));
        uint256 totalLPAmount = unstakedLPAmount.add(stakedLPAmount);

        uint256 totalLPValue ;
        uint256 USDCequiAmount ;
        
        // caculate LP equivalence in USDC , in normalized decimals, USDC value
        if(totalLPAmount == 0) { totalLPValue = 0 ; }
        else{
            USDCequiAmount = ICurve_Deposit(self.deposit_addr).calc_withdraw_one_coin(totalLPAmount,1);
            totalLPValue = USDCequiAmount.mul(10**12);
        } 

        // caculate reward equivalence in USDC , in normalized decimals, USDC value
        (uint256 pendingCRV_value, uint256 pendingWMATIC_value) = getPendingRewardValue(self, oracle);
                
        return totalFreeFundValue.add(totalLPValue).add(pendingCRV_value).add(pendingWMATIC_value);
    }

    /// @dev returns "token_value_sum" is in decimals == 18 , USDC value
    /// @dev returns "shares"          is in decimals == 18 , no unit
    function getDepositAmountOut(HLSConfig memory self, Position memory position, Oracle memory oracle, uint256[5] memory _amounts, uint256[5] memory _deposit_limit, uint256 _totalSupply) public view returns (uint256, uint256) {
        uint256[5] memory separateTokenValue = getTokenSeparateValue(oracle, _amounts);
        uint256 token_value_sum = separateTokenValue[0].add(separateTokenValue[1]).add(separateTokenValue[2]).add(separateTokenValue[3]).add(separateTokenValue[4]) ;
        uint256 totalAssets = getTotalAssets(position, oracle, self); // "totalAssets" is in normalized decimals, USDC value
        uint256 shares ;
        require(_amounts[0] <= _deposit_limit[0].mul(10**IERC20(position.token0).decimals()), "Deposit too much DAI!");
        require(_amounts[1] <= _deposit_limit[1].mul(10**IERC20(position.token1).decimals()), "Deposit too much USDC!");
        require(_amounts[2] <= _deposit_limit[2].mul(10**IERC20(position.token2).decimals()), "Deposit too much USDT!");
        require(_amounts[3] <= _deposit_limit[3].mul(10**IERC20(position.token3).decimals()), "Deposit too much WBTC!");
        require(_amounts[4] <= _deposit_limit[4].mul(10**IERC20(position.token4).decimals()), "Deposit too much WETH!");
        if (_totalSupply > 0) {
            shares = token_value_sum.mul(_totalSupply).div(totalAssets);
        } else {
            shares = token_value_sum;
        }
        return (token_value_sum, shares);
    }

    /// @param _type==3 => unstake
    /// @param _type==2 => unstake + withdraw in one coin
    /// @param _type==1 => unstake + withdraw in all coins
    function exitPosition(Position memory _position, HLSConfig memory self, uint256 _type, uint256 _i) external returns(Position memory) {

        uint256 stakedLPAmount = IERC20(self.gauge_addr).balanceOf(address(this));

        if (_type == 1 || _type ==2 ||  _type == 3) {
            // unstake all
            ICurve_Gauge(self.gauge_addr).withdraw(stakedLPAmount);
        }

        if (_type == 2) {
            // withdraw in one coin
            // _i == 0 => user withdraw in DAI
            // _i == 1 => user withdraw in USDC
            // ...etc
            // _i == 5 => _type != 2
            uint256 unstakedLPAmount2 = IERC20(self.LP_token).balanceOf(address(this));
            ICurve_Deposit(self.deposit_addr).remove_liquidity_one_coin(unstakedLPAmount2, _i , 0);
            if(_i==0){_position.enteredAmount0=0;}
            else if(_i==1){_position.enteredAmount1=0;}
            else if(_i==2){_position.enteredAmount2=0;}
            else if(_i==3){_position.enteredAmount3=0;}
            else if(_i==4){_position.enteredAmount4=0;}

        }

        if (_type == 1) {
            // withdraw in all coins
            uint256[5] memory _min_amounts;
            uint256 unstakedLPAmount1 = IERC20(self.LP_token).balanceOf(address(this));
            ICurve_Deposit(self.deposit_addr).remove_liquidity(unstakedLPAmount1, _min_amounts );
            _position.enteredAmount0 = 0;
            _position.enteredAmount1 = 0;
            _position.enteredAmount2 = 0;
            _position.enteredAmount3 = 0;
            _position.enteredAmount4 = 0;

        }

        return _position ;
        
    }

    /// @param _type==1 => addliquidity + stake
    /// @param _type==2 => stake
    function enterPosition(Position memory _position, HLSConfig memory self, uint256 _type) external returns (Position memory) {

        if( _type == 1 ){

            uint256[5] memory entering_amounts = getFreeFundsOriginal(_position,false);
            ICurve_Deposit(self.deposit_addr).add_liquidity(entering_amounts , 1);
            _position.enteredAmount0 = _position.enteredAmount0 + entering_amounts[0] ;
            _position.enteredAmount1 = _position.enteredAmount1 + entering_amounts[1] ;
            _position.enteredAmount2 = _position.enteredAmount2 + entering_amounts[2] ;
            _position.enteredAmount3 = _position.enteredAmount3 + entering_amounts[3] ;
            _position.enteredAmount4 = _position.enteredAmount4 + entering_amounts[4] ;

        }

        if ( _type == 1 || _type == 2 ) {
            
            uint256 unstakedLPAmount = IERC20(self.LP_token).balanceOf(address(this));
            ICurve_Gauge(self.gauge_addr).deposit(unstakedLPAmount);

        }

        return _position ;

    }

    // only when calling this function will we claim pending reward CRV(and WMATIC)
    // returns how many CRV,WMATIC has been swapped to token and transferred back to contract
    // token is in the form of _CRV_path[_CRV_path.length-1], _WMATIC_path[_WMATIC_path.length-1]
    function autoCompound(HLSConfig memory self, address[] memory _CRV_path, address[] memory _WMATIC_path) external returns (uint256,uint256){
        ICurve_Gauge(self.gauge_addr).claim_rewards();
        uint256 CRV_balance = IERC20(self.CRV_token).balanceOf(address(this));
        uint256 WMATIC_balance = IERC20(self.WMATIC_token).balanceOf(address(this));
        uint256[] memory amounts1 ;
        uint256[] memory amounts2 ;
        if( CRV_balance != 0 ){
            uint256 amountInSlippage1 = CRV_balance.mul(98).div(100);
            uint256[] memory amountOutMinAArray1 = IUniswapV2Router02(self.sushiV2Router02_addr).getAmountsOut(amountInSlippage1, _CRV_path);
            uint256 amountOutMin1 = amountOutMinAArray1[amountOutMinAArray1.length - 1];
            amounts1 = IUniswapV2Router02(self.sushiV2Router02_addr).swapExactTokensForTokens(
                CRV_balance,
                amountOutMin1,
                _CRV_path,
                address(this),
                block.timestamp
            );
        }
        if( WMATIC_balance != 0 ){
            uint256 amountInSlippage2 = WMATIC_balance.mul(98).div(100);
            uint256[] memory amountOutMinAArray2 = IUniswapV2Router02(self.sushiV2Router02_addr).getAmountsOut(amountInSlippage2, _WMATIC_path);
            uint256 amountOutMin2 = amountOutMinAArray2[amountOutMinAArray2.length - 1];
            amounts2 = IUniswapV2Router02(self.sushiV2Router02_addr).swapExactTokensForTokens(
                WMATIC_balance,
                amountOutMin2,
                _WMATIC_path,
                address(this),
                block.timestamp
            );
        }
        return (amounts1[amounts1.length-1] , amounts2[amounts2.length-1]);
    }


}