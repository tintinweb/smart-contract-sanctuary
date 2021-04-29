// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

import './SafeERC20.sol';
import './CurveInterface.sol';
import './UniswapInterface.sol';

contract CurveStrategy {

    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address public royaleAddress;
    address public yieldDistributor;
    IERC20 public poolToken;
    IERC20[3] public tokens;  // DAI / USDC / USDT
    CurvePool public pool;
    PoolGauge public gauge;
    Minter public minter;
    VoteEscrow public voteEscrow;
    FeeDistributor public feeDistributor;
    UniswapI  public uniAddr;
    IERC20 public crvAddr;
    address public wethAddr;
    
    
    uint256 public constant DENOMINATOR = 10000;

    uint256 public depositSlip = 100;

    uint256 public withdrawSlip = 200;
    
    uint256 public uniswapSlippage=50;

    address public wallet;
    address public nominatedWallet;
    
   // uint256 public totalProfit;
    
    uint256 public crvBreak=10000;

   // uint256 public virtualPrice;
 
    bool public TEST = false; // For testing uniswap , should be removed on deployment to the mainnet

    modifier onlyAuthorized(){
      require(wallet == msg.sender|| msg.sender==royaleAddress, "Not authorized");
      _;
    }

    modifier onlyWallet(){
        require((wallet==msg.sender),"Not Authorized");
        _;
    }

    modifier onlyRoyaleLP() {
        require(msg.sender == royaleAddress, "Not authorized");
        _;
    }

    constructor(
         address _wallet,
         IERC20[3] memory _tokens, 
         address _royaleaddress,
         address _yieldDistributor,
         address _crvpool,
         address _poolToken,
         address _gauge,
         address _minter,
         address _uniAddress,
         address _crvAddress,
         address _wethAddress,
         address _voteEscrow,
         address _feeDistributor
         ) public {

        wallet=_wallet;
        tokens = _tokens;
        royaleAddress =_royaleaddress;
        yieldDistributor=_yieldDistributor;
        pool = CurvePool(_crvpool);
        poolToken = IERC20(_poolToken);
        gauge = PoolGauge(_gauge);
        minter=Minter(_minter);
        uniAddr=UniswapI(_uniAddress);
        crvAddr=IERC20(_crvAddress);
        wethAddr=_wethAddress;  
        feeDistributor = FeeDistributor(_feeDistributor);
        voteEscrow = VoteEscrow(_voteEscrow);
    }

    function setCRVBreak(uint256 _percentage)external onlyWallet(){
        crvBreak=_percentage;
    }

    function nominateNewOwner(address _wallet) external onlyWallet {
        nominatedWallet = _wallet;
        emit walletNominated(_wallet);
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedWallet, "You must be nominated before you can accept ownership");
        emit walletChanged(wallet, nominatedWallet);
        wallet = nominatedWallet;
        nominatedWallet = address(0);
    }

    function changeRoyaleLP(address _address)external onlyWallet(){
        royaleAddress=_address;
    }

    function changeYieldDistributor(address _address)external onlyWallet(){
        yieldDistributor=_address;
    }
    
    function changeDepositSlip(uint _value)external onlyWallet(){
        depositSlip=_value;
    }
    
    function changeWithdrawSlip(uint _value)external onlyWallet(){
        withdrawSlip=_value;
    }
    
    function changeUniswapSlippage(uint _value) external onlyWallet(){
        uniswapSlippage=_value;
    }

// deposits stable tokens into the 3pool and stake recived LPtoken(3CRV) in the curve 3pool gauge
    function deposit(uint[3] memory amounts) external onlyRoyaleLP(){
        uint currentTotal;
        for(uint8 i=0; i<3; i++) {
            if(amounts[i] > 0) {
               uint decimal;
               decimal=tokens[i].decimals();
               tokens[i].safeApprove(address(pool),0);
               tokens[i].safeApprove(address(pool), amounts[i]); 
               currentTotal =currentTotal.add(amounts[i].mul(1e18).div(10**decimal));
            }
        }
        uint256 mintAmount = currentTotal.mul(1e18).div(pool.get_virtual_price());
        pool.add_liquidity(amounts,  mintAmount.mul(DENOMINATOR.sub(depositSlip)).div(DENOMINATOR));
        stakeLP();   
    }

    //withdraws stable tokens from the 3pool.Unstake required LPtokens and stake LP tokens if not used.
    function withdraw(uint[3] memory amounts) external onlyRoyaleLP() {
        uint256 max_burn = pool.calc_token_amount(amounts,false);
        max_burn=max_burn.mul(DENOMINATOR.add(withdrawSlip)).div(DENOMINATOR);
        unstakeLP(max_burn);
        pool.remove_liquidity_imbalance(amounts, max_burn);
        for(uint8 i=0;i<3;i++){
            if(amounts[i]!=0){
               tokens[i].safeTransfer(royaleAddress, tokens[i].balanceOf(address(this)));
            }
        } 
        stakeLP();
    }

   //unstake all the LPtokens and withdraw all the Stable tokens from 3pool 
    function withdrawAll() external onlyRoyaleLP() returns(uint256[3] memory){
        unstakeLP(gauge.balanceOf(address(this)));
        uint256[3] memory withdrawAmt;
        pool.remove_liquidity(poolToken.balanceOf(address(this)),withdrawAmt);
        for(uint8 i=0;i<3;i++){
            if(tokens[i].balanceOf(address(this))!=0){
                withdrawAmt[i]=tokens[i].balanceOf(address(this));
                tokens[i].safeTransfer(royaleAddress,withdrawAmt[i]); 
            }
        }
        return withdrawAmt; 
    } 
    
    // Functions to stake and unstake LPTokens(Ycrv) and claim CRV


    //Stakes LP token(3CRV) into the curve 3pool gauage
    function stakeLP() public onlyAuthorized() {
        uint depositAmt = poolToken.balanceOf(address(this)) ;
        poolToken.safeApprove(address(gauge),0);
        poolToken.safeApprove(address(gauge), depositAmt);
        gauge.deposit(depositAmt);  
        emit staked(depositAmt);
    }

    //For unstaking LP tokens(3CRV)
    function unstakeLP(uint _amount) public  onlyAuthorized(){
        require(gauge.balanceOf(address(this)) >= _amount,"You have not staked that much amount");
        gauge.withdraw(_amount);
        emit unstaked(_amount);
    }
    
    //Checking claimable CRV tokens.
    function checkClaimableToken()public view  returns(uint256){
        return gauge.claimable_tokens(address(this));
    }

    //for claiming CRV tokens which accumalates on staking 3CRV.
    function claimCRV() public onlyAuthorized(){
        minter.mint(address(gauge));
        emit crvClaimed();
    }

    // Functions to lock and unlock CRV and recieve VeCRV


   //For locking CRV tokens in the curve lock
    function createLock(uint256 _value,uint256 _unlockTime) external onlyWallet(){
        crvAddr.safeApprove(address(voteEscrow), 0);
        crvAddr.safeApprove(address(voteEscrow), _value);
        voteEscrow.create_lock(_value, _unlockTime);
        emit locked(_value);
    }


    //Increasing lock CRV amount
    function increaseLockAmount(uint256 _value) external onlyWallet(){
        crvAddr.safeApprove(address(voteEscrow), 0);
        crvAddr.safeApprove(address(voteEscrow), _value);
        voteEscrow.increase_amount(_value);
        emit locked(_value);
    }

    //For unlocking CRV tokens
    function releaseLock() external onlyWallet(){
        voteEscrow.withdraw(); 
        emit unlocked();
    }

//For claiming recieved 3CRV tokens which are given for locking CRV and
   // withdrawing stable tokens from curve 3pool using those 3CRV and sending those stable tokens to an address
    function claim3CRV()public onlyWallet(){
        uint prevCoin=poolToken.balanceOf(address(this));
        feeDistributor.claim();
        uint postCoin=poolToken.balanceOf(address(this));
        uint[3] memory minimum;
        pool.remove_liquidity(postCoin-prevCoin,minimum);
        for(uint i=0;i<3;i++){
            tokens[i].safeTransfer(yieldDistributor,tokens[i].balanceOf(address(this)));
        }
        emit yieldTransfered();
    }
    
    // Function to sell CRV using uniswap to any stable token and send that token to an address
    function sellCRV(uint8 _index) public onlyWallet() returns(uint256) {  //here index=0 means convert crv into DAI , index=1 means crv into USDC , index=2 means crv into USDT
        uint256 crvAmt = IERC20(crvAddr).balanceOf(address(this));
        uint256 prevCoin = tokens[_index].balanceOf(address(this));
        require(crvAmt > 0, "insufficient CRV");
        crvAmt=crvAmt.mul(crvBreak).div(DENOMINATOR);
        crvAddr.safeApprove(address(uniAddr), 0);
        crvAddr.safeApprove(address(uniAddr), crvAmt);
        address[] memory path; 
        if(TEST) {
            path = new address[](2);
            path[0] = address(crvAddr);
            path[1] = address(tokens[_index]);

        } else {    
            path = new address[](3);
            path[0] = address(crvAddr);
            path[1] = wethAddr;
            path[2] = address(tokens[_index]);
        }
        uint[] memory amount=UniswapI(uniAddr).getAmountsOut(crvAmt,path);
        uint calulatedAmount=amount[amount.length.sub(1)];
        uint minimumAmount=calulatedAmount.sub(calulatedAmount.mul(uniswapSlippage).div(DENOMINATOR));
        UniswapI(uniAddr).swapExactTokensForTokens(
            crvAmt, 
            minimumAmount, 
            path, 
            address(this), 
            now + 1800
        );
        uint256 postCoin=tokens[_index].balanceOf(address(this));
        tokens[_index].safeTransfer(yieldDistributor,postCoin.sub(prevCoin));
        emit yieldTransfered(_index,postCoin.sub(prevCoin));
    }

    //calulates how much VeCRV is needed to get 2.5X boost.
    function gaugeVeCRVCalculator() public view returns(uint256){
          uint minimumVeCRV ;
          minimumVeCRV =(gauge.balanceOf(address(this)).mul(100)).sub((gauge.balanceOf(address(this)).mul(40))).mul(voteEscrow.totalSupply()).div(gauge.totalSupply().mul(60));
          return minimumVeCRV;
    }
    
    event yieldTransfered(uint index,uint coin);
    event yieldTransfered();
    event staked(uint amount);
    event unstaked(uint amount);
    event crvClaimed();
    event locked(uint amount);
    event unlocked();
    event walletNominated(address newOwner);
    event walletChanged(address oldOwner, address newOwner);

}