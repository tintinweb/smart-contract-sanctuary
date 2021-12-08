// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./LinkPolygonOracle.sol";
import "./ICurve_Aave_Gauge.sol";
import "./ICurve_Aave_Swap.sol";
import "./IUniswapV2Router02.sol";



library HLS_aave {    

    using SafeMath for uint256;

    // HighLevelSystem config
    struct HLSConfig {
        address swap_addr ; // where we add liquidity , address : 0x445FE580eF8d70FF569aB36e80c647af338db351
        address gauge_addr ; // where we stake, address : 0x19793B454D3AfC7b454F206Ffe95aDE26cA6912c

        address LP_token ; 
        // after adding liquidity, crvUSDBTCETH token, address : 0xE7a24EF0C5e95Ffb0f6684b813A78F2a3AD7D171 , decimals == 18
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

        address CRV_USD;    //  CRV/USD oracle contract,        address: 0x336584C8E6Dc19637A5b36206B1c79923111b405
        address WMATIC_USD; //  "MATIC"/USD oracle contract,    address: 0xAB594600376Ec9fD91F8e885dADF0CE036862dE0

    }

    // atricrypto3 pool tokens address , token entered amount
    struct Position {
        address token0; // DAI  , token decimals == 18 , address: 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063
        address token1; // USDC , token decimals == 6  , address: 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174
        address token2; // USDT , token decimals == 6  , address: 0xc2132D05D31c914a87C6611C10748AEb04B58e8F

        uint256 enterPercentage; // percentage of freeFunds to enter Curve's swap_addr
        
        uint256 enteredAmount0; // DAI amount that has been added liquidity into Curve's swap_addr
        uint256 enteredAmount1; // USDC amount that has been added liquidity into Curve's swap_addr
        uint256 enteredAmount2; // USDT amount that has been added liquidity into Curve's swap_addr

    }

    function checkNeedExit(Position memory _position, Oracle memory _oracle, uint256[3] memory _splitValue) public view returns (bool){
        bool flag = false ;
        uint256[3] memory FreeFunds = getFreeFundsOriginal(_position, true);
        uint256[3] memory separateFreeFundValue = getTokenSeparateValue(_oracle, FreeFunds);
        for(uint256 i=0;i<3;i++){
            if( _splitValue[i] > separateFreeFundValue[i]){
                flag = true ;
                return flag ;
            }
        }
        return flag;
    }

    // in "decimals==18,6,6"
    function getFreeFundsOriginal(Position memory _position, bool _getAll) public view returns(uint256[3] memory){

        if( _getAll == true ){
            // return all FreeFunds in cashbox
            return[
                IERC20(_position.token0).balanceOf(address(this)),
                IERC20(_position.token1).balanceOf(address(this)),
                IERC20(_position.token2).balanceOf(address(this))
            ];
        }

        else {
            // return enter_amounts needed to add liquidity
            return[
                (IERC20(_position.token0).balanceOf(address(this))).mul(_position.enterPercentage).div(100),
                (IERC20(_position.token1).balanceOf(address(this))).mul(_position.enterPercentage).div(100),
                (IERC20(_position.token2).balanceOf(address(this))).mul(_position.enterPercentage).div(100)
            ];
        }

    }

    /// @param _amounts : in original("decimals==18,6,6") , separate token value
    /// @dev   returns  : in normalized("decimals==18,18,18") , USDC value  
    // get the equivalent value of each token with respect to USDC in "decimals == 18"
    function getTokenSeparateValue(Oracle memory _oracle, uint256[3] memory _amounts) public view returns (uint256[3] memory) {

        // all price get from chainlink is in "decimals = 8"
        uint256 token_0_price = uint256(LinkPolygonOracle(_oracle.token0_USD).latestAnswer());
        uint256 token_2_price = uint256(LinkPolygonOracle(_oracle.token2_USD).latestAnswer());

        uint256 token_0_value ;
        uint256 token_1_value ;
        uint256 token_2_value ;

        // convert all token into equivalent USDC(i.e. USD) value , in "decimals = 18"
        if(_amounts[0]==0){ token_0_value = 0 ; }
        else { token_0_value = token_0_price.mul(_amounts[0]).div(10**8); }
        // .mul(10**(8+18-18)) = .div(10**8)

        token_1_value = _amounts[1].mul(10**12) ;
        // 18-6 = 12

        if(_amounts[2]==0){ token_2_value = 0 ; }
        else { token_2_value = token_2_price.mul(_amounts[2]).mul(10**4) ; }
        // 18-(8+6)  = 4

        return [token_0_value, token_1_value, token_2_value];
    }

    /// @param _values : in normalized decimals
    /// @dev   returns  : in original decimals , separate token value
    function getAmountFromValue(Oracle memory _oracle, uint256[3] memory _values) public view returns (uint256[3] memory) {
        uint256 token_0_price = uint256(LinkPolygonOracle(_oracle.token0_USD).latestAnswer());
        uint256 token_2_price = uint256(LinkPolygonOracle(_oracle.token2_USD).latestAnswer());

        uint256 token_0_amount ;
        uint256 token_1_amount ;
        uint256 token_2_amount ;

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

        return [token_0_amount, token_1_amount, token_2_amount ];
    }

    
    /// @dev   returns  : in normalized decimals("decimals==18,18,18") , USDC value  
    function getPendingRewardValue(address _gauge, address _crv, address _matic, address _crv_usd, address wmatic_usd) public view returns (uint256,uint256) {

        // ? ICurve_Aave_Gauge(_gauge).claimable_reward_write(address(this), _crv);
        // TODO check if we need to send both write transaction ? 
        // ICurve_Aave_Gauge(_gauge).claimable_reward_write(address(this), _matic);
        // TODO check if we can chang ABI to view manually, and discard claimable_reward_write() ?

        // both decimals = 18
        uint256 pendingCRV_amount = ICurve_Aave_Gauge(_gauge).claimable_reward(address(this), _crv);
        uint256 pendingWMATIC_amount = ICurve_Aave_Gauge(_gauge).claimable_reward(address(this), _matic);

        // both decimals = 8
        uint256 CRV_price = uint256(LinkPolygonOracle(_crv_usd).latestAnswer());
        uint256 WMATIC_price = uint256(LinkPolygonOracle(wmatic_usd).latestAnswer());

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

    /// @param _type==3 => unstake
    /// @param _type==2 => unstake + withdraw in one coin
    /// @param _type==1 => unstake + withdraw in all coins
    function exitPosition(Position memory _position, HLSConfig memory self, uint256 _type, int128 _i) external returns(Position memory) {

        uint256 stakedLPAmount = IERC20(self.gauge_addr).balanceOf(address(this));

        if (_type == 1 || _type ==2 ||  _type == 3) {
            // unstake all
            ICurve_Aave_Gauge(self.gauge_addr).withdraw(stakedLPAmount);
        }

        if (_type == 2) {
            // withdraw in one coin
            // _i == 0 => user withdraw in DAI
            // _i == 1 => user withdraw in USDC
            // ...etc
            // _i == 5 => _type != 2
            uint256 unstakedLPAmount2 = IERC20(self.LP_token).balanceOf(address(this));
            uint256 _min_amounts2;
            ICurve_Aave_Swap(self.swap_addr).remove_liquidity_one_coin(unstakedLPAmount2, _i, _min_amounts2, true);
            if(_i==0){_position.enteredAmount0=0;}
            else if(_i==1){_position.enteredAmount1=0;}
            else if(_i==2){_position.enteredAmount2=0;}

        }

        if (_type == 1) {
            // withdraw in all coins
            uint256 unstakedLPAmount1 = IERC20(self.LP_token).balanceOf(address(this));
            uint256[3] memory _min_amounts1;
            ICurve_Aave_Swap(self.swap_addr).remove_liquidity(unstakedLPAmount1, _min_amounts1, true );
            _position.enteredAmount0 = 0;
            _position.enteredAmount1 = 0;
            _position.enteredAmount2 = 0;

        }

        return _position ;
        
    }

    /// @param _type==1 => addliquidity + stake
    /// @param _type==2 => stake
    function enterPosition(Position memory _position, HLSConfig memory self, uint256 _type) external returns (Position memory) {

        if( _type == 1 ){

            uint256[3] memory entering_amounts = getFreeFundsOriginal(_position, false);
            ICurve_Aave_Swap(self.swap_addr).add_liquidity(entering_amounts, 1, true);
            _position.enteredAmount0 = _position.enteredAmount0 + entering_amounts[0] ;
            _position.enteredAmount1 = _position.enteredAmount1 + entering_amounts[1] ;
            _position.enteredAmount2 = _position.enteredAmount2 + entering_amounts[2] ;

        }

        if ( _type == 1 || _type == 2 ) {
            
            uint256 unstakedLPAmount = IERC20(self.LP_token).balanceOf(address(this));
            ICurve_Aave_Gauge(self.gauge_addr).deposit(unstakedLPAmount);

        }

        return _position ;

    }


}