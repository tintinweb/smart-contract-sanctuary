// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;


import './SafeMath.sol';
import './IERC20Interface.sol';
import './CurveInterface.sol';
import './UniswapInterface.sol';


contract CurveStrategy {

    using SafeMath for uint256;

    address royaleAddress;
    IERC20 poolToken;
    IERC20[3] Coins;  // DAI / USDC / USDT
    CurvePool public pool;
    PoolGauge public gauge;
    Minter public minter;
    VoteEscrow public voteEscrow;
    FeeDistributor public feeDistributor;
    UniswapI  public uniAddr;
    IERC20 public crvAddr;
    address public wethAddr;
    
    
    uint256 public constant DENOMINATOR = 10000;

    uint256 public DepositSlip = 100;

    uint256 public withdrawSlip = 200;

    address public wallet;
    
    uint256 public totalProfit;
    
    uint256 public crvBreak=10000;

    uint256 public virtualPrice;
 
    bool public TEST = true; // For testing uniswap , should be removed on deployment to the mainnet

    modifier onlyAuthorized(){
      require(wallet == msg.sender|| msg.sender==royaleAddress, "Not authorized");
      _;
    }

    modifier onlyWallet(){
        require((wallet==msg.sender),"Not Authorized");
        _;
    }

    modifier onlyRoyaleLP() {
        require(msg.sender == royaleAddress || true, "Not authorized");
        _;
    }

    constructor(
         address _wallet,
         IERC20[3] memory coins, 
         address _royaleaddress,
         address _crvpool,
         address _poolToken,
         address _gauge,
         address _minter,
         address _uniAddress,
         address _crvAddress,
         address _wethAddress
         ) public {

        wallet=_wallet;
        Coins = coins;
        royaleAddress =_royaleaddress;
        pool = CurvePool(_crvpool);
        poolToken = IERC20(_poolToken);
        gauge = PoolGauge(_gauge);
        minter=Minter(_minter);
        uniAddr=UniswapI(_uniAddress);
        crvAddr=IERC20(_crvAddress);
        wethAddr=_wethAddress;
        
    }


    function setCRVBreak(uint256 _percentage)external onlyWallet(){
        crvBreak=_percentage;
    }

    function transferOwnership(address _wallet) external onlyWallet(){
        wallet=_wallet;
    }

    function changeRoyaleLP(address _address)external onlyWallet(){
        royaleAddress=_address;
    }


    // Functions to deposit and withdraw stable coins in the y pool and recieve LP tokens (Ycrv)

    function deposit(uint[3] memory amounts) external onlyRoyaleLP(){
        uint currentTotal;
        for(uint8 i=0; i<3; i++) {
            if(amounts[i] > 0) {
               uint decimal;
               decimal=Coins[i].decimals();
               Coins[i].approve(address(pool), amounts[i]); 
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
        uint256 max_burn = pool.calc_token_amount(amounts,false);
        max_burn=max_burn.mul(DENOMINATOR.add(withdrawSlip)).div(DENOMINATOR);
        unstakeLP(max_burn);
        pool.remove_liquidity_imbalance(amounts, max_burn);
        for(uint8 i=0;i<3;i++){
            if(amounts[i]!=0){
               Coins[i].transfer(royaleAddress, Coins[i].balanceOf(address(this)));
            }
        } 
        stakeLP();
    }

    function withdrawAll() external onlyRoyaleLP() returns(uint256[3] memory){
        unstakeLP(gauge.balanceOf(address(this)));
        uint256[3] memory withdrawAmt;
        pool.remove_liquidity(poolToken.balanceOf(address(this)),withdrawAmt);
        for(uint8 i=0;i<3;i++){
            if(Coins[i].balanceOf(address(this))!=0){
                withdrawAmt[i]=Coins[i].balanceOf(address(this));
                Coins[i].transfer(royaleAddress,withdrawAmt[i]); 
            }
        }
        return withdrawAmt; 
    } 



    // Functions to stake and unstake LPTokens(Ycrv) and claim CRV

    function stakeLP() public onlyAuthorized() {
        uint depositAmt = poolToken.balanceOf(address(this)) ;
        poolToken.approve(address(gauge), depositAmt);
        gauge.deposit(depositAmt);  
    }

    function unstakeLP(uint _amount) public  onlyAuthorized(){
        require(gauge.balanceOf(address(this)) >= _amount,"You have not staked that much amount");
        gauge.withdraw(_amount);
    }


    function checkClaimableToken()public view  returns(uint256){
        return gauge.claimable_tokens(address(this));
    }

    function claimCRV() public onlyAuthorized(){
        minter.mint(address(gauge));
    }

    // Functions to lock and unlock CRV and recieve VeCRV

    function createLock(uint256 _value,uint256 _unlockTime) external onlyAuthorized(){
        IERC20(crvAddr).approve(address(voteEscrow), _value);
        voteEscrow.create_lock(_value, _unlockTime);
    }

    function increaseLockAmount(uint256 _value) external onlyAuthorized(){
        IERC20(crvAddr).approve(address(voteEscrow), _value);
        voteEscrow.increase_amount(_value);
    }

    function releaseLock() external onlyAuthorized(){
        voteEscrow.withdraw();  
    }

    function claim3CRV()public onlyAuthorized(){
        feeDistributor.claim();
    }

    // Function to sell CRV

    function sellCRV(uint8 _index) public onlyWallet() returns(uint256) {  //here index=0 means convert crv into DAI , index=1 means crv into USDC , index=2 means crv into USDT
        uint256 crvAmt = IERC20(crvAddr).balanceOf(address(this));
        uint256 prevCoin = Coins[_index].balanceOf(address(this));
        require(crvAmt > 0, "insufficient CRV");
        crvAmt=crvAmt.mul(crvBreak).div(DENOMINATOR);
        crvAddr.approve(address(uniAddr), crvAmt);
        address[] memory path; 
        if(TEST) {
            path = new address[](2);
            path[0] = address(crvAddr);
            path[1] = address(Coins[_index]);

        } else {    
            path = new address[](3);
            path[0] = address(crvAddr);
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

    function calculateProfit()public view returns(uint256,bool){
        if(pool.get_virtual_price() >= virtualPrice){
            return (gauge.balanceOf(address(this)).mul(pool.get_virtual_price().sub(virtualPrice)).div(10**18),true);
        }    
        else{
            return (gauge.balanceOf(address(this)).mul(virtualPrice.sub(pool.get_virtual_price())).div(10**18),false);
        }
        
    }

    function gaugeBoostCalculator() public view returns(uint256){
          uint minimumVeCRV ;
          minimumVeCRV =(gauge.balanceOf(address(this)).mul(100)).sub((gauge.balanceOf(address(this)).mul(40))).mul(voteEscrow.totalSupply()).div(gauge.totalSupply().mul(60));
          return minimumVeCRV;
    }
}