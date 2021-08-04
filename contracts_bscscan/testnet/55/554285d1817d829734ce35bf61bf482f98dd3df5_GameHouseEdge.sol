/**
 *Submitted for verification at BscScan.com on 2021-08-04
*/

/**
 *Submitted for verification at BscScan.com on 2021-08-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;


library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}
interface IBiswapRouter02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapFeeReward() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut, uint swapFee) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut, uint swapFee) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
interface IBiswapPair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);
    function swapFee() external view returns (uint32);
    function devFee() external view returns (uint32);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external returns(uint amount0In,uint amount1In);
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
    function setSwapFee(uint32) external;
    function setDevFee(uint32) external;
}

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
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}
interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}


interface ISwapFeeReward {
    function swap(address account, address input, address output, uint256 amount) external returns (bool);
}




contract GameHouseEdge {
    using SafeMath for uint256;

    // Tokens declaration
 
    IERC20 public BUST;
    IERC20 public BUSD;
    IERC20 public WBNB;
    IERC20 public MFRM;
    IERC20 public APE;

    uint public snum=990;
    uint public sden =1000;
    uint public anum=992;
    uint public aden=1000;
 
    
    // percent declaration
    uint256 public rewardPercent=2500;
    uint256 public LockLPPercent=2500;
    uint256 public BurnTokenPercent=2500;
    uint256 public DaoTreasuryBankRollPercent=2500;

    uint256 public burnBustPercent=6000;
    uint256 public burnApePercent=2000;
    uint256 public burnMfrmPercent=2000;
    
    uint256 percentHelper=10000;

    address public lock;

  // dao treasury  bankroll
    address payable public dtbr;

    address public reward;


    // owner's address 
    address public owner;

      // LP Tokens
    IBiswapPair BUSD_BUST;

    IBiswapPair BUST_BNB ;
    
    IBiswapPair MFRM_BNB ;
        
    IBiswapPair APE_BNB ;

    // Router Address
    IBiswapRouter02 router;
    
        // Write function
    // constructor
    
      constructor(address _bust, address _busd, address _ape, address _mfrm, address _wbnb,address busd_bust_lp,address _bnbAPElp,address _bnbMFRMlp,address bust_bnb_lp, address _router, address _reward,address _lock,address payable _dao) public {
        owner = msg.sender;
        reward = _reward;
         router = IBiswapRouter02(_router);
         BUST  = IERC20(_bust);
         BUSD  = IERC20(_busd);
         WBNB  = IERC20(_wbnb);
         MFRM  = IERC20(_mfrm);
         APE=IERC20(_ape);
         BUSD_BUST =
        IBiswapPair(busd_bust_lp);

     BUST_BNB =
        IBiswapPair(bust_bnb_lp);
        MFRM_BNB= IBiswapPair(_bnbMFRMlp);
        APE_BNB=IBiswapPair(_bnbAPElp);
        lock = _lock;
        dtbr = _dao;
        
    }


     function setTokenAddress(uint256 _bust, uint256 _busd, address _wbnb, uint256 _ape, address _mfrm) public restricted(){
         BUST  = IERC20(_bust);
         BUSD  = IERC20(_busd);
         WBNB  = IERC20(_wbnb);
         MFRM   =IERC20(_mfrm);
         APE    =IERC20(_ape);
    }
    function setBurnPercent(uint256 _bust, uint256 _ape, uint256 _mfrm) public restricted(){
        require(_bust+_ape+_mfrm == percentHelper , "should be equal to 10000");
        burnBustPercent=_bust;
        burnApePercent=_ape;
        burnMfrmPercent=_mfrm;
    }

    function setLPAddress(address busd_bust, address bust_bnb,address _apeBNB,address _mfrmBNB) public restricted(){
          BUSD_BUST =
        IBiswapPair(busd_bust);

     BUST_BNB =
        IBiswapPair(bust_bnb);

       MFRM_BNB = 
         IBiswapPair(_mfrmBNB);
    APE_BNB=
        IBiswapPair(_apeBNB);
    }


        // set percentage
    
    function setPercent(uint _rewardPercent,uint _LockLPPercent, uint _BurnTokenPercent, uint _DaoTreasuryBankRollPercent) public restricted(){
        require(_rewardPercent+_LockLPPercent+_BurnTokenPercent+_DaoTreasuryBankRollPercent == percentHelper, "sum of percent should be eqqual to 10000");
        
        rewardPercent=_rewardPercent;
        LockLPPercent=_LockLPPercent;
        BurnTokenPercent=_BurnTokenPercent;
        DaoTreasuryBankRollPercent=_DaoTreasuryBankRollPercent;
    }
    
    // transfer ownership
    
    function transferOwnership(address _newOwner) public restricted(){
        require(_newOwner != address(0));
        owner = _newOwner;
    }
    
    //setter 
    function setFraction(uint _snum, uint _sden, uint _rnum, uint _rden) public restricted(){
        snum= _snum;
        sden = _sden;
        anum = _rnum;
        aden = _rden;
    }

    function setRewardAddress(address _reward) public restricted(){
        reward = _reward;
    }

    function setRouterAddress(address _routerAddress) public restricted(){
        router=IBiswapRouter02(_routerAddress);
    }

    function _setDaoAddress(address payable _dtbrAddress) public restricted(){
        dtbr=_dtbrAddress;
    } 

    function setLockAddress(address _lock) public restricted(){
        lock = _lock;
    }
    
    function BUST_Bal() public view returns (uint256) {
        return BUST.balanceOf(address(this));
    }

    function BUSD_Bal() public view returns (uint256) {
        return BUSD.balanceOf(address(this));
    }

    function BNB_Bal() public view returns (uint256) {
        return address(this).balance;
    }
    
    function APE_Bal() public view returns (uint256) {
        return APE.balanceOf(address(this));
    }
    
    function MFRM_Bal() public view returns (uint256) {
        return MFRM.balanceOf(address(this));
    }
     
    modifier restricted() {
        require(msg.sender==owner);
        _;
    }

    // paths

    address[] BUST_BUSD_path = [0x6e03884333a30eE91AFda92E429fF4FD95Dc2850,0x637F61C18Cd7259f7c5EA50591C7Befe6A2E0BfE];
    address[] BUSD_BUST_path=[0x637F61C18Cd7259f7c5EA50591C7Befe6A2E0BfE,0x6e03884333a30eE91AFda92E429fF4FD95Dc2850];
    address[] WBNB_BUST_path = [0x44Bc761E0B58Aa6727202eBd2B636DC924dA9f1a, 0x6e03884333a30eE91AFda92E429fF4FD95Dc2850];
    address[] WBNB_APE_path = [0x44Bc761E0B58Aa6727202eBd2B636DC924dA9f1a, 0xe0c2a41a988E1bec6945deE4236bfF0e2e78e448];
    address[] WBNB_MFRM_path= [0x44Bc761E0B58Aa6727202eBd2B636DC924dA9f1a, 0xeFc55FfA42D02dc3fC14B5a64cf0D174cdBA3324];
    
   
   
    
    function distribution() public restricted() {
        
                    /**
      * @dev Consider InitialBNBBal as 400. This is split into 4 parts each part having 100 BNB in DistributedBNBBal.
      * In SubDistributedBNBBal we have taken out 75 BNB and converted it into bustBal
      * Provide them Liquidity(BNB-BUST)
      * Lock it in their respective LP 
      * In _daoTreasuryBankRoll we have transferred BNB to dao address
      */
        uint256 InitialBNBBal = address(this).balance;   //Let's say we have initially have 400 BNB in total
        uint256 DistributedReward=InitialBNBBal.mul(rewardPercent).div(percentHelper); 
        uint256 DistributedBNBToLockLP=InitialBNBBal.mul(LockLPPercent).div(percentHelper); 

        uint256 DistributedBNBToBurnToken=InitialBNBBal.mul(BurnTokenPercent).div(percentHelper);

        uint256 DistributedBNBToDaoTreasury=InitialBNBBal.mul(DaoTreasuryBankRollPercent).div(percentHelper);

         _getBUSTforBNBReward(DistributedReward, reward);

        uint256 SubDistributedBNBBal=DistributedBNBToLockLP.mul(75).div(100);
        uint256 BNBaddliquidityAmount=DistributedBNBToLockLP.sub(SubDistributedBNBBal);
        _getBUSTforBNB(SubDistributedBNBBal);//convert 75 BNB into BUST
        addLiquidityBNBBUST(BNBaddliquidityAmount);//Provide them Liquidity
        
        uint256 bustBal = BUST.balanceOf(address(this));
        uint256 p2BUST = bustBal.mul(5000).div(percentHelper);
        _getBUSDforBUST(p2BUST);
         (uint256 _reserve0, uint256 _reserve1, ) =BUSD_BUST.getReserves();
         uint bustAmount=_reserve1.mul(BUSD.balanceOf(address(this))).div(_reserve0);
        //uint bustAmount=router.getAmountsOut(BUSD.balanceOf(address(this)),BUSD_BUST_path)[1];
        
        if(bustAmount<=BUST.balanceOf(address(this))){
            addLiquidityBUSTBUSD(BUSD.balanceOf(address(this)),true);
        }
        else{
            addLiquidityBUSTBUSD(BUST.balanceOf(address(this)),false);
        }
       
    

        uint256 p3BUST= DistributedBNBToBurnToken.mul(burnBustPercent).div(percentHelper);
        uint256 p3APE = DistributedBNBToBurnToken.mul(burnApePercent).div(percentHelper);
        uint256 p3MFRM = DistributedBNBToBurnToken.mul(burnMfrmPercent).div(percentHelper);
        
                   
        _getBUSTforBNB(p3BUST);
        _getAPEforBNB(p3APE);
        _getMFRMforBNB(p3MFRM);
        
            
        _burnBUST(BUST.balanceOf(address(this)));
        _burnAPE(APE.balanceOf(address(this)));
        _burnMFRM(MFRM.balanceOf(address(this)));
        
         _daoTreasuryBankRoll(DistributedBNBToDaoTreasury);
        
    }
    
    function _getBUSTforBNB(uint256 _amount) internal  {
        uint256 bust = router.getAmountsOut(_amount,WBNB_BUST_path)[1];
        uint256 bustmin = bust.mul(snum).div(sden);
        uint256 time = block.timestamp + 1120;


        router.swapExactETHForTokens.value(_amount)(
            bustmin,
            WBNB_BUST_path,
            address(this), 
            time
        );
         
    }
    
    function _getBUSTforBNBReward(uint256 _amount, address addr) internal {
        uint256 bust = router.getAmountsOut(_amount,WBNB_BUST_path)[1];
        uint256 bustmin = bust.mul(snum).div(sden);
        uint256 time = block.timestamp + 1120;
         

        router.swapExactETHForTokens.value(_amount)(
            bustmin,
            WBNB_BUST_path,
            address(this), 
            time
        );
        

               
        // send the received amount to referal contract
        TransferHelper.safeTransfer(
            address(BUST),
            addr,
            BUST.balanceOf(address(this))
        );
    }
    
    function _getBUSDforBUST(uint256 _amount) internal {
        uint256 busd = router.getAmountsOut(_amount,BUST_BUSD_path)[1];
        uint256 busdmin = busd.mul(snum).div(sden);
        
        BUST.approve(address(router), _amount);

        uint256 time = block.timestamp + 1120;

        router.swapExactTokensForTokens(
            _amount,
            busdmin,
            BUST_BUSD_path,
            address(this),
            time
        );
    }
    
    function addLiquidityBNBBUST(uint256 value) internal{
        (uint256 _reserve0, uint256 _reserve1,) =BUST_BNB.getReserves();
        uint256 bust = _reserve1.mul(value).div(_reserve0);
        uint256 minbust = bust.mul(anum).div(aden);
        uint256 minbnb = _reserve0.mul(bust).div(_reserve1);
        minbnb=minbnb.mul(anum).div(aden);
        uint256 time = block.timestamp + 1220;

        BUST.approve(address(router),bust);

        router.addLiquidityETH.value(value)(
            address(BUST),
            bust,
            minbust,
            minbnb,
            address(this),
            time
        );
        lockBUST_BNBLP(BUST_BNB.balanceOf(address(this)));
    }
    
   
    
    
    function lockBUST_BNBLP(uint _amount) internal{
        TransferHelper.safeTransfer(address(BUST_BNB),lock,_amount);
    }
     
     function _daoTreasuryBankRoll(uint256 _bnb) internal {
       dtbr.transfer(_bnb); 
         
    }
      
       
    function addLiquidityBUSTBUSD(uint256 value,bool _bool) internal{
        (uint256 _reserve0, uint256 _reserve1, ) =BUSD_BUST.getReserves();
        
        uint bust;
        uint busd;
        uint minbust;
        uint minbusd;
        uint time;
        if(_bool){
            busd=value;
            bust = _reserve1.mul(value).div(_reserve0);
            minbusd=_reserve0.mul(bust).div(_reserve1);
            minbust=_reserve1.mul(busd).div(_reserve0);
            minbusd=minbusd.mul(anum).div(aden);
            minbust=minbust.mul(anum).div(aden);
            time = block.timestamp + 1220;
        }else{
            bust=value;
            busd = _reserve0.mul(value).div(_reserve1);
            minbusd=_reserve0.mul(bust).div(_reserve1);
            minbust=_reserve1.mul(busd).div(_reserve0);
            minbusd=minbusd.mul(anum).div(aden);
            minbust=minbust.mul(anum).div(aden);
            time = block.timestamp + 1220;
            
        }
        
        BUST.approve(address(router),BUST.balanceOf(address(this)));
        BUSD.approve(address(router),BUSD.balanceOf(address(this)));
        router.addLiquidity(
            address(BUSD),
            address(BUST),
            busd,
            bust,
            minbusd,
            minbust,
            address(this),
            time
        );
        
        lockBUST_BUSDLP(BUSD_BUST.balanceOf(address(this)));
    }
    

    function lockBUST_BUSDLP(uint _amount) internal{
        TransferHelper.safeTransfer(address(BUSD_BUST),lock,_amount);
    }
    
    
    function _getMFRMforBNB(uint256 _amount) internal {
        uint256 mfrm = router.getAmountsOut(_amount,WBNB_MFRM_path)[1];
        uint256 MFRMmin = mfrm.mul(snum).div(sden);
        uint256 time = block.timestamp + 1120;
        

        router.swapExactETHForTokens.value(_amount)(
            MFRMmin,
            WBNB_MFRM_path,
            address(this), 
            time
        );
    }
    
    function _getAPEforBNB(uint256 _amount) internal {
        uint256 ape = router.getAmountsOut(_amount,WBNB_APE_path)[1];
        uint256 apemin = ape.mul(snum).div(sden);
        uint256 time = block.timestamp + 1120;

        router.swapExactETHForTokens.value(_amount)(
            apemin,
            WBNB_APE_path,
            address(this), 
            time
        );
    }
    
    
    function _burnBUST(uint256 _amount) internal {
        TransferHelper.safeTransfer(
            address(BUST),
            0x000000000000000000000000000000000000dEaD,
            _amount
        );
    }

    
    function _burnAPE(uint256 _amount) internal {
        TransferHelper.safeTransfer(
            address(APE),
            0x000000000000000000000000000000000000dEaD,
            _amount
        );
    }
    
    function _burnMFRM(uint256 _amount) internal {
        TransferHelper.safeTransfer(
            address(MFRM),
            0x000000000000000000000000000000000000dEaD,
            _amount
        );

         
    }
    
    function recovertoken(address _token) external restricted(){
        TransferHelper.safeTransfer(address(_token),owner , IERC20(_token).balanceOf(address(this)));
    }
    
    function recoverBNB()external restricted(){
        payable(owner).transfer(address(this).balance); 
    }


    fallback() external payable {}

  
}