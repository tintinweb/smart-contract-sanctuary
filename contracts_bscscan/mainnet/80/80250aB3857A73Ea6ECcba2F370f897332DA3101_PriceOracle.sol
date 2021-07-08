/**
 *Submitted for verification at BscScan.com on 2021-07-08
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.12;

interface IChainlink {
  function latestAnswer() external view returns (int256);
}

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

    // for lp
   
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);    
}

interface IFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);
}
 

contract PriceOracle {
    uint256 constant F = 1e18;
    address owner;
 
    /////////////////////////  change for release  //////////////////////// 
    address constant public SWAP_FACTORY = 0x70eab9FAfEE9BFA372EbEe7B2B6CFF78b996f6df;  //change for release
    address constant public STAKING_POOL = 0x45fEfF877C7dB0BBa2EA4947017F5DdD48DFcd14;   //change for release

    address constant public WFC  =  0x7164712F2136a03d25859408eb15AAf36640B71A ;  //change for release
    address constant public DOP  =  0xEcF32d9c60a75880B4E28A09da059dDa8BB114F9 ;  //change for release

 
    ///////////////////////////////////////////////////////////////////////// 

    //https://docs.chain.link/docs/binance-smart-chain-addresses/
    // bsc main chainlink oracle
    address constant CL_USDT = 0xB97Ad0E74fa7d920791E90258A6E2085088b4320;
    address constant CL_BNB = 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE;
    address constant CL_BTC = 	0x264990fbd0A4796A3E3d8E37C4d5F87a3aCa5Ebf;
    address constant CL_ETH =  0x9ef1B8c0E4F7dc8bF5719Ea496883DC6401d5b2e;
    address constant CL_FIL = 0xE5dbFD9003bFf9dF5feB2f4F445Ca00fb121fb83;
    
    //bsc main
    address constant USDT =  0x55d398326f99059fF775485246999027B3197955 ;   
    address constant BNB =   0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c ;   
    address constant BTC =   0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c ;   
    address constant ETH  =  0x2170Ed0880ac9A755fd29B2688956BD959F933F8 ;   
    address constant FIL  =  0x0D8Ce2A99Bb6e3B7Db580eD848240e4a0F9aE153 ; 
 
    address public DOP_USDT ;
    address public WFC_USDT ;
    address public BTC_WFC ;
    address public FIL_WFC ;
    address public ETH_WFC ;
    address public BNB_WFC ;
  
    function tvl() public view returns (uint256){
     return IERC20(USDT).balanceOf(STAKING_POOL) * oracle_price(CL_USDT) * 1e10 + 
             IERC20(BNB).balanceOf(STAKING_POOL) * oracle_price(CL_BNB) * 1e10 + 
             IERC20(BTC).balanceOf(STAKING_POOL) * oracle_price(CL_BTC) * 1e10+ 
             IERC20(ETH).balanceOf(STAKING_POOL) * oracle_price(CL_ETH) * 1e10 + 
             IERC20(FIL).balanceOf(STAKING_POOL) * oracle_price(CL_FIL) * 1e10 + 
             IERC20(DOP).balanceOf(STAKING_POOL) * dop_price() +
             usdt_balance(DOP_USDT) *oracle_price(CL_USDT) * 1e10 * 2 +
             usdt_balance(WFC_USDT) *oracle_price(CL_USDT) * 1e10 * 2 +
             wfc_balance(BTC_WFC) * wfc_price()  * 2 +
             wfc_balance(FIL_WFC) * wfc_price()  * 2 +
             wfc_balance(ETH_WFC) * wfc_price()  * 2 +
             wfc_balance(BNB_WFC) * wfc_price()  * 2 ;
    }

    constructor() public {
        owner = msg.sender;
    } 

    function update() public {
        IFactory factory = IFactory(SWAP_FACTORY);
        DOP_USDT = factory.getPair(DOP, USDT);
        WFC_USDT = factory.getPair(WFC, USDT);
        BTC_WFC  = factory.getPair(BTC, WFC );
        FIL_WFC  = factory.getPair(FIL, WFC );
        ETH_WFC  = factory.getPair(ETH, WFC );
        BNB_WFC  = factory.getPair(BNB, WFC );     
     }
    

    function usdt_balance( address _lptoken) public view returns (uint256){
        uint token_balance;
        uint256 usd_balance;

        IERC20 pair = IERC20(_lptoken);
        if (pair.token0() == USDT) 
            (usd_balance, token_balance, ) = pair.getReserves();     
        else
            (token_balance, usd_balance , ) = pair.getReserves();           

        return usd_balance;
    }  

    function wfc_balance( address _lptoken) public view returns (uint256){
        uint token_balance;
        uint256 wfc_balance;

        IERC20 pair = IERC20(_lptoken);
        if (pair.token0() == WFC) 
            (wfc_balance, token_balance, ) = pair.getReserves();     
        else
            (token_balance, wfc_balance , ) = pair.getReserves();           
            
        return wfc_balance;
    } 

    // X-USDT OR USDT-X  , return x price
    function amm_price( address _lptoken) public view returns (uint256){
        uint token_balance;
        uint256 usd_balance;

        IERC20 pair = IERC20(_lptoken);
        if (pair.token0() == USDT) 
            (usd_balance, token_balance, ) = pair.getReserves();     
        else
            (token_balance, usd_balance , ) = pair.getReserves();           

        uint256 price = usd_balance * F / token_balance;
        return price;
    }    
   
 
    function dop_price() public  view returns (uint256){
        return amm_price(DOP_USDT);
    }

    function wfc_price() public  view returns (uint256){
        return amm_price(WFC_USDT);
    }

    // return 26 78993591 = 26u
    function oracle_price(address _oracle_address) public view returns (uint256) {
        return uint256(IChainlink(_oracle_address).latestAnswer());
    }

/*
    // reward_pre_day  不需要加 18个0
    // lp 的token1 是usdt  , 即 X-USDT  
     function apy_usdt_pair_lp( address _lptoken, address _staking_pool, uint256 _reward_pre_day ) public  view returns (uint256) {          
        uint112 token_balance;
        uint112 usd_balance;

        IERC20 pair = IERC20(_lptoken);
        if (pair.token0() == USDT) 
            (usd_balance, token_balance, ) = pair.getReserves();     
        else
            (token_balance, usd_balance , ) = pair.getReserves();           

        uint256 token_price = usd_balance * F / token_balance;
        //lp token 价格
        uint256 lp_price = ((token_balance * token_price) + (usd_balance * F) ) / pair.totalSupply();
        //质押的lp token 的usdt 价值
        uint256 staking_lp_value = pair.balanceOf(_staking_pool) * lp_price / F;          
        uint256 apy =  _reward_pre_day * F  *  wfc_price() * 365 * 100 / staking_lp_value;   
      
        return apy;
    } 

    // reward_pre_day  不需要加 18个0
    // 不是usdt , 先转成usd 价值
     function apy_wfc_pair_lp( address _lptoken,  address _staking_pool, uint256 _reward_pre_day) public  view returns (uint256) {          
        uint112 token_balance;
        uint112 wfc_balance;

        IERC20 pair = IERC20(_lptoken);
        if (pair.token0() == WFC) 
            (wfc_balance, token_balance, ) = pair.getReserves();     
        else
            (token_balance, wfc_balance , ) = pair.getReserves();  

        //token 价格
        uint256 usd_balance = wfc_balance * wfc_price() / 1e18;
        uint256 token_price = usd_balance * F / token_balance;
        //lp token 价格
        uint256 lp_price = ((token_balance * token_price) + (usd_balance * F) ) / pair.totalSupply();
        //质押的lp token 的usdt 价值
        uint256 staking_lp_value = pair.balanceOf(_staking_pool) * lp_price / F;          
        uint256 apy =  _reward_pre_day * F  *  wfc_price() * 365 * 100 / staking_lp_value;   
      
        return apy;
    } 
 

 
    function token_pool_apy(uint256 _reward_pre_day, address _base_token, address _oracle_address) public  view returns (uint256){
          uint256 token_price = oracle_price(_oracle_address) * 1e10;
          uint256 staking_lp_value = IERC20(_base_token).balanceOf(STAKING_POOL) * token_price / F;          
          return _reward_pre_day * F  *  wfc_price() * 365 * 100 / staking_lp_value;  
    } 

    function btc_pool_apy(uint256 _reward_pre_day) public  view returns (uint256){       
          return token_pool_apy(_reward_pre_day, BTC, CL_BTC);  
    }    
    
    function fil_pool_apy(uint256 _reward_pre_day) public  view returns (uint256){       
          return token_pool_apy(_reward_pre_day, FIL, CL_FIL);  
    }    

    function usdt_pool_apy(uint256 _reward_pre_day) public  view returns (uint256){       
          return token_pool_apy(_reward_pre_day, USDT, CL_USDT);  
    }    
    
    function bnb_pool_apy(uint256 _reward_pre_day) public  view returns (uint256){       
          return token_pool_apy(_reward_pre_day, BNB, CL_BNB);  
    }    

    function eth_pool_apy(uint256 _reward_pre_day) public  view returns (uint256){       
          return token_pool_apy(_reward_pre_day, ETH, CL_ETH);  
    }    

    function dop_pool_apy(uint256 _reward_pre_day) public  view returns (uint256){       
          uint256 token_price = dop_price();
          uint256 staking_lp_value = IERC20(DOP).balanceOf(STAKING_POOL) * token_price / F;          
          return _reward_pre_day * F  *  wfc_price() * 365 * 100 / staking_lp_value;  
    }   

    function wfc_dao_pool_apy(uint256 _reward_pre_day, address _staking_pool ) public  view returns (uint256){       
          uint256 token_price = wfc_price();
          uint256 staking_lp_value = IERC20(WFC).balanceOf(_staking_pool) * token_price / F;          
          return _reward_pre_day * F  *  token_price * 365 * 100 / staking_lp_value;  
    }   


    function dop_usdt_lp_apy(uint256 _reward_pre_day) public  view returns (uint256){
        return apy_usdt_pair_lp(DOP_USDT, STAKING_POOL, _reward_pre_day  ) ; 
    }    

     function wfc_usdt_lp_apy(uint256 _reward_pre_day) public  view returns (uint256){
        return apy_usdt_pair_lp(WFC_USDT, STAKING_POOL, _reward_pre_day ) ; 
    }    

    function btc_wfc_lp_apy(uint256 _reward_pre_day) public  view returns (uint256){
        return apy_wfc_pair_lp(BTC_WFC,  STAKING_POOL, _reward_pre_day ) ; 
    }    
 
    function fil_wfc_lp_apy(uint256 _reward_pre_day) public  view returns (uint256){
        return apy_wfc_pair_lp(FIL_WFC, STAKING_POOL, _reward_pre_day ) ; 
    }    
 
    function eth_wfc_lp_apy(uint256 _reward_pre_day) public  view returns (uint256){
        return apy_wfc_pair_lp(ETH_WFC,  STAKING_POOL, _reward_pre_day ) ; 
    }   

    function bnb_wfc_lp_apy(uint256 _reward_pre_day) public  view returns (uint256){
        return apy_wfc_pair_lp(BNB_WFC, STAKING_POOL, _reward_pre_day ) ; 
    }   
 */


}