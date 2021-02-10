// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

import './IERC20Interface.sol';
import './CurveInterface.sol';
import './UniswapInterface.sol';
import './SafeMath.sol';

contract CurveStrategy {

    using SafeMath for uint256;

    address royaleAddress;
    IERC20 poolToken;
    IERC20[3] Coins;  // DAI / USDC / USDT
    IERC20[3] uCoins; // yDAI / yUSDC / yUSDT
    CurvePool public pool;
    DepositY public depositY;
    PoolGauge public gauge;
    Minter public minter;
    VoteEscrow public voteEscrow;
    FeeDistributor public feeDistributor;

    uint256 public constant DENOMINATOR = 10000;

    uint256 public DepositSlip = 100;

    uint256 public withdrawSlip = 200;

    address public wallet;
    
    uint256 totalProfit;
    
    uint256 public crvBreak=10000;
    
    uint256[4] public depositBal;

    uint256 public totalDeposited;

    uint256 public virtualPrice;
 
    bool public TEST = true; // For testing uniswap , should be removed on deployment to the mainnet

    address public uniAddr  = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public crvAddr  = address(0x5dDBDBB1D1e691d2994d4A44470EB07dFCbd57C3);
    address public wethAddr = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);


    modifier onlyWallet(){
      require(wallet == msg.sender|| msg.sender==royaleAddress, "Not authorized");
      _;
    }

    modifier onlyRoyaleLP() {
        require(msg.sender == royaleAddress || true, "Not authorized");
        _;
    }

    constructor(
         address _wallet,
         IERC20[3] memory coins, 
         IERC20[3] memory ucoins,
         address _royaleaddress,
         address _crvpool,
         address _depositY,
         address _poolToken,
         address _gauge,
         address _minter
         ) public {

        wallet=_wallet;
        Coins = coins;
        uCoins=ucoins;
        royaleAddress =_royaleaddress;
        depositY=DepositY(_depositY);
        pool = CurvePool(_crvpool);
        poolToken = IERC20(_poolToken);
        gauge = PoolGauge(_gauge);
        minter=Minter(_minter);
        
    }


    function setCRVBreak(uint256 _percentage)external onlyWallet(){
        crvBreak=_percentage;
    }

    function transferOwnership(address _wallet) external onlyWallet(){
        wallet=_wallet;
    }


// Functions to deposit and withdraw stable coins in the y pool and recieve LP tokens (Ycrv)


    function updateArray(uint[3] memory amount) internal pure returns(uint[4] memory){
        uint256[4] memory uamount;
        for(uint8 i=0;i<3;i++){
                uamount[i]=amount[i];
        }
        uamount[3]=0;
        return uamount;
    }

    function deposit(uint[3] memory amounts) external onlyRoyaleLP(){
        //uint256[4] memory amounts;
        //uint[4] memory damount;
        uint currentTotal;
        //amounts=updateArray(amount);
        for(uint8 i=0; i<3; i++) {
            if(amounts[i] > 0) {
               uint decimal;
               decimal=Coins[i].decimals();
               Coins[i].approve(address(pool), amounts[i]); 
               depositBal[i] =depositBal[i].add(amounts[i]);
               totalDeposited = totalDeposited.add(amounts[i].mul(1e18).div(10**decimal));
               //damount[i] = amounts[i].mul(1e18).div(uCoins[i].getPricePerFullShare());
               currentTotal =currentTotal.add(amounts[i].mul(1e18).div(10**decimal));
            }
        }
        uint256 returnedAmount;
        bool status;
        (returnedAmount,status)=calculateProfit();
        if(status){
            totalProfit =totalProfit.add(returnedAmount);
        }
        else{
            totalProfit =totalProfit.sub(returnedAmount);
        } 
        uint256 mintAmount = currentTotal.mul(1e18).div(pool.get_virtual_price());
        pool.add_liquidity(amounts,  mintAmount.mul(DENOMINATOR.sub(DepositSlip)).div(DENOMINATOR));
        virtualPrice=pool.get_virtual_price();
        stakeLP();   
    }

    function withdraw(uint[3] memory amounts) external onlyRoyaleLP() {
        //uint256[4] memory amounts;
        //uint[4] memory damount;
        uint decimal;
        uint currentTotal;
        //amounts=updateArray(amount);
        for(uint8 i=0;i<3;i++){
            if(amounts[i]>0){
                decimal = Coins[i].decimals();
                depositBal[i] =depositBal[i].sub(amounts[i]);
               // totalDeposited =totalDeposited.sub(amounts[i].mul(1e18).div(10**decimal));
                //damount[i] = amounts[i].mul(1e18).div(uCoins[i].getPricePerFullShare());
                currentTotal =currentTotal.add(amounts[i].mul(1e18).div(10**decimal));
            }  
        }
        uint256 max_burn = currentTotal.mul(1e18).div(pool.get_virtual_price());
        max_burn=max_burn.mul(DENOMINATOR.add(withdrawSlip)).div(DENOMINATOR);
        unstakeLP(max_burn);
        pool.remove_liquidity_imbalance(amounts, max_burn);
        for(uint8 i=0;i<3;i++){
            if(amounts[i]!=0){
               Coins[i].transfer(royaleAddress, Coins[i].balanceOf(address(this)));
            }
        } 
        totalDeposited=totalDeposited.sub(currentTotal);
        stakeLP();
    }

    function withdrawAll() external onlyRoyaleLP() returns(uint256[3] memory){
        unstakeAll();
        uint256 poolTokenBalance;
        uint256[3] memory withdrawAmt;
        uint totalBurnt;
        poolTokenBalance=poolToken.balanceOf(address(this));
        for(uint8 i=0;i<3;i++){
            uint decimal;
            uint poolTokenShare;
            decimal=Coins[i].decimals();
            if(i==2){
                poolTokenShare =poolTokenBalance.sub(totalBurnt);
            }
            else{
                poolTokenShare= poolTokenBalance.mul(10**(18-decimal)).mul(depositBal[i]).div(totalDeposited);
            }
            totalBurnt =totalBurnt.add(poolTokenShare);
            pool.remove_liquidity_one_coin(poolTokenShare, i, poolTokenShare.mul(10**decimal).mul(DENOMINATOR.sub(withdrawSlip)).div(DENOMINATOR).div(10**18));
        }
        for(uint8 i=0;i<3;i++){
            depositBal[i] =0;
            if(Coins[i].balanceOf(address(this))!=0){
                 withdrawAmt[i]= Coins[i].balanceOf(address(this));
                 Coins[i].transfer(royaleAddress,withdrawAmt[i]);
            }
        }
        totalDeposited=0;
        return withdrawAmt; 
    } 



    // Functions to stake and unstake LPTokens(Ycrv) and claim CRV

    function stakeLP() public onlyWallet {
        uint depositAmt = poolToken.balanceOf(address(this)) ;
        poolToken.approve(address(gauge), depositAmt);
        gauge.deposit(depositAmt);  
    }

    function unstakeLP(uint _amount) public  onlyWallet{
        require(gauge.balanceOf(address(this)) >= _amount,"You have not staked that much amount");
        gauge.withdraw(_amount);
    }

    function unstakeAll()public onlyWallet{
        gauge.withdraw(gauge.balanceOf(address(this)));  
    }

    function checkClaimableToken()public view  returns(uint256){
        return gauge.claimable_tokens(address(this));
    }

    function claimCRV() public onlyWallet{
        minter.mint(address(gauge));
    }

    // Functions to lock and unlock CRV and recieve VeCRV

    function createLock(uint256 _value,uint256 _unlockTime) external onlyWallet(){
        IERC20(crvAddr).approve(address(voteEscrow), _value);
        voteEscrow.create_lock(_value, _unlockTime);
    }

    function increaseLockAmount(uint256 _value) external onlyWallet(){
        IERC20(crvAddr).approve(address(voteEscrow), _value);
        voteEscrow.increase_amount(_value);
    }

    function releaseLock() external onlyWallet(){
        voteEscrow.withdraw();
    }

    function claim3CRV()public onlyWallet(){
        feeDistributor.claim();
    }

    // Function to sell CRV

    function sellCRV(uint8 _index) public onlyWallet() returns(uint256) {  //here index=0 means convert crv into DAI , index=1 means crv into USDC , index=2 means crv into USDT
        uint256 crvAmt = IERC20(crvAddr).balanceOf(address(this));
        uint256 prevCoin = Coins[_index].balanceOf(address(this));
        require(crvAmt > 0, "insufficient CRV");
        crvAmt=crvAmt.mul(crvBreak).div(DENOMINATOR);
        IERC20(crvAddr).approve(uniAddr, crvAmt);
        address[] memory path; 
        if(TEST) {
            path = new address[](2);
            path[0] = crvAddr;
            path[1] = address(Coins[_index]);

        } else {
            path = new address[](3);
            path[0] = crvAddr;
            path[1] = wethAddr;
            path[2] = address(Coins[_index]);
        }
        UniswapI(uniAddr).swapExactTokensForTokens(
            crvAmt, 
            uint256(0), 
            path, 
            address(this), 
            now + 1800
        );
        uint256 postCoin=Coins[_index].balanceOf(address(this));
        return (postCoin-prevCoin);
    }

    function calculateProfit()public view returns(uint256,bool) {
        if(pool.get_virtual_price() >= virtualPrice){
            return (gauge.balanceOf(address(this)).mul(pool.get_virtual_price().sub(virtualPrice)),true);
        }    
        else{
            return (gauge.balanceOf(address(this)).mul(virtualPrice.sub(pool.get_virtual_price())),false);
        }
        
    }


    function gaugeBoostCalculator() public view returns(uint256){
          uint minimumVeCRV ;
          minimumVeCRV =(gauge.balanceOf(address(this)).mul(100)).sub((gauge.balanceOf(address(this)).mul(40))).mul(voteEscrow.totalSupply()).div(gauge.totalSupply().mul(60));
          return minimumVeCRV;
    }
}