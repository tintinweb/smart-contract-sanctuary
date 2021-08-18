/**
 *Submitted for verification at BscScan.com on 2021-08-17
*/

// SPDX-License-Identifier: MIT

pragma solidity =0.6.6;

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
interface IBustRouter02 {
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
interface IBustPair {
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
    function feeTo() external view returns(address);
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
    function setFeeTo(address) external;
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

contract pool {
    using SafeMath for uint256;

    // Tokens declaration
    
    IERC20 public BUST ;
    IERC20 public BUSD ;
    IERC20 public WBNB ;
    IERC20 public APE ;
    IERC20 public MFRM ;
    
    // to set the slipage value
    
    uint public snum=990;
    uint public sden =1000;
    uint public rnum=992;
    uint public rden=1000;
    
    
    // set the percent needed in each case
    
    uint public a;
    uint public b;
    uint public c;
    uint public d;
    
    // bankroll distribution percent
    
    uint public bust_ratio;
    uint public ape_ratio;
    uint public mfarm_ratio;
    
    // address where funds will be send
    address payable public dao ;
    address public reward;
    address public lock;
    
    // owner's address
    address public owner;
    
    // LP Tokens
    IBustPair public BUSD_BUST ;
    IBustPair public BUST_BNB ;

    
    // Router Address
    IBustRouter02 public router ;
    
    // paths
    
    // change while deployment ??
    address[] public p20 = [0x637F61C18Cd7259f7c5EA50591C7Befe6A2E0BfE, 0x6e03884333a30eE91AFda92E429fF4FD95Dc2850]; // 1st busd 2nd bust
    address[] public pETH = [0x44Bc761E0B58Aa6727202eBd2B636DC924dA9f1a, 0x6e03884333a30eE91AFda92E429fF4FD95Dc2850]; // 1st bnb 2nd bust
    
    // ["0x6e03884333a30eE91AFda92E429fF4FD95Dc2850","0x44Bc761E0B58Aa6727202eBd2B636DC924dA9f1a", "0xe0c2a41a988E1bec6945deE4236bfF0e2e78e448"]
    address[] public pApe = [0x6e03884333a30eE91AFda92E429fF4FD95Dc2850,0x44Bc761E0B58Aa6727202eBd2B636DC924dA9f1a, 0xe0c2a41a988E1bec6945deE4236bfF0e2e78e448]; //1st bust 2nd wbnb 3rd ape 
    address[] public pMfrm = [0x6e03884333a30eE91AFda92E429fF4FD95Dc2850,0x44Bc761E0B58Aa6727202eBd2B636DC924dA9f1a, 0xeFc55FfA42D02dc3fC14B5a64cf0D174cdBA3324]; //1st bust 2nd wbnb 3rd mfrm 
    address[] public pBust_Eth = [0x6e03884333a30eE91AFda92E429fF4FD95Dc2850, 0x44Bc761E0B58Aa6727202eBd2B636DC924dA9f1a]; // 1st bust and 2nd bnb
    
    function setBUSD_BUST_Path(address[] memory _busd_bust) public restricted(){
        p20 = _busd_bust;
        
    }
    
    function setBNB_BUST_Path(address[] memory _bnb_bust) public restricted(){
        pETH = _bnb_bust;
    }
    
    function setBNB_APE_Path(address[] memory _bnb_ape) public restricted(){
        pApe = _bnb_ape;
    }
    
    function setBNB_MFRM_Path(address[] memory _bnb_mfrm) public restricted(){
        pMfrm = _bnb_mfrm;
    }
    function setBUST_BNB_Path(address[] memory _bust_bnb) public restricted(){
        pBust_Eth = _bust_bnb;
    }
    
    



    // Read function
    
    function BUST_Bal() public view returns (uint256) {
        return BUST.balanceOf(address(this));
    }
    
    function BUSD_Bal() public view returns (uint256) {
        return BUSD.balanceOf(address(this));
    }
    
    function BNB_Bal() public view returns (uint256) {
        return address(this).balance;
    }
    
    function BUST_BUSD_Bal() public view returns (uint256) {
        return BUSD_BUST.balanceOf(address(this));
    }
    
    function BUST_BNB_Bal() public view returns (uint256) {
        return BUST_BNB.balanceOf(address(this));
    }
    // modifier
    
    modifier restricted() {
        require(msg.sender==owner);
        _;
    }
    
    // Write function
    // constructor
    constructor(address _bust, address _busd, address _wbnb,address _ape, address _mfrm, address _busd_lp, address _bnb_lp, address _router, address _reward,address _lock,address payable _dao) public {
        owner = msg.sender;
        reward = _reward;
        router = IBustRouter02(_router);
        BUST = IERC20(_bust);
        BUSD = IERC20(_busd);
        WBNB = IERC20(_wbnb);
        APE = IERC20(_ape);
        MFRM = IERC20(_mfrm);
        BUSD_BUST =
        IBustPair(_busd_lp);
        
        BUST_BNB =
        IBustPair(_bnb_lp);
        
        lock = _lock;
        dao = _dao;
    
    }

    // set percentage
    
    function setPercent(uint _a,uint _b, uint _c, uint _d) public restricted(){
        require(_a+_b+_c+_d == 10000, "sum of percent should be equal to 10000");
    
        a=_a;
        b=_b;
        c=_c;
        d=_d;
    }
    
    // set buyback and burn ratio
    
    function setBurnRatio(uint _bust_ratio,uint _ape_ration, uint _mfarm_ratio) public restricted(){
        require(_mfarm_ratio + _ape_ration + _bust_ratio == 10000, "sum of percent should be equal to 10000");
    
        bust_ratio = _bust_ratio;
        ape_ratio = _ape_ration;
        mfarm_ratio = _mfarm_ratio;
    
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
        rnum = _rnum;
        rden = _rden;
    }
    
    function setRewardAddress(address _reward) public restricted(){
        reward = _reward;
    }
    
    function setRouterAddress(address _router) public restricted(){
        router = IBustRouter02(_router);
    }
    
    function setTokenAddress(address _bust, address _busd, address _wbnb, address _ape, address _mfrm) public restricted(){
        BUST = IERC20(_bust);
        BUSD = IERC20(_busd);
        WBNB = IERC20(_wbnb);
        APE = IERC20(_ape);
        MFRM = IERC20(_mfrm);
    }
    
    function setLPAddress(address _busd, address _bnb, address _ape_lp, address _mfrm_lp) public restricted(){
        BUSD_BUST =IBustPair(_busd);
    
        BUST_BNB =IBustPair(_bnb);
        
    }
    
    function setLockAddress(address _lock) public restricted(){
        lock = _lock;
    }
    
    function setDAO(address payable _dao) public restricted(){
        dao = _dao;
    }




    function distribution() public payable restricted(){
        
        uint256 BUSD_LP_Bal = BUSD_BUST.balanceOf(address(this));
        
        uint c1 = BUSD_LP_Bal.mul(a).div(10000);
        uint c2 = BUSD_LP_Bal.mul(b).div(10000);
        uint c3 = BUSD_LP_Bal.mul(c).div(10000);
        uint c4 = BUSD_LP_Bal.mul(d).div(10000);
        
        
        BUSD_BUST.approve(address(router), BUSD_LP_Bal);
        BUST_BNB.approve(address(router), BUST_BNB.balanceOf(address(this)));
        
        getBUST_BUSDLP(c1, reward, 0);
        lock_BUSD_LP(c2);
        getBUST_BUSDLP(c3, 0x000000000000000000000000000000000000dEaD,1);
         _buyback_burn_helper(0x000000000000000000000000000000000000dEaD);
        BUSD_DAO(c4, dao);
        
        
        
        uint256 BNB_LP_Bal = BUST_BNB.balanceOf(address(this));
        
        
        c1 = BNB_LP_Bal.mul(a).div(10000);
        c2 = BNB_LP_Bal.mul(b).div(10000);
        c3 = BNB_LP_Bal.mul(c).div(10000);
        c4 = BNB_LP_Bal.mul(d).div(10000);
        
        
        getBUST_BNBLP(c1, reward,0);
        lock_BNB_LP(c2);
        getBUST_BNBLP(c3, 0x000000000000000000000000000000000000dEaD,1);
        _buyback_burn_helper(0x000000000000000000000000000000000000dEaD);
        BNB_DAO(c4, dao);
        
        
        
    }
        
        // case 1 and case 3 part 1
        
    function getBUST_BUSDLP(uint _amount, address addr,uint opt) internal {
        (uint256 _reserve0, uint256 _reserve1, uint256 _blockTimestampLast) = BUSD_BUST.getReserves();
        uint tSupply = BUSD_BUST.totalSupply();
        
        // change while deployment ??
        
        uint tok0min = _reserve0.mul(_amount).mul(rnum).div(rden).div(tSupply);
        uint tok1min = _reserve1.mul(_amount).mul(rnum).div(rden).div(tSupply);
        uint256 time = block.timestamp + 1120;
        
        router.removeLiquidity(
            address(BUSD),
            address(BUST),
            _amount,
            tok0min,
            tok1min,
            address(this),
            time
        );
        
        // convert the BUSD to BUST
        (uint256 _rev0, uint256 _rev1, uint256 _bts) = BUSD_BUST.getReserves();

        
        
        uint256 bust_rec = router.getAmountsOut(BUSD.balanceOf(address(this)),p20)[1];
        uint256 bust_rec_min = bust_rec.mul(rnum).div(rden);
        
        BUSD.approve(address(router), BUSD.balanceOf(address(this)));
        
        router.swapExactTokensForTokens(
            BUSD.balanceOf(address(this)),
            bust_rec_min,
            p20,
            address(this),
            time
        );
        
        // send the received amount to referal contract
        if(opt == 0){
            TransferHelper.safeTransfer(
                address(BUST),
                addr,
                BUST.balanceOf(address(this))
            );
        }
        
        
    }
        
        
        // -------------------------------------------------------------------------------------------------------------------------------
        
        
        
    function _buyback_burn_helper(address addr) internal {
        
        uint256 Bust_Bal = BUST.balanceOf(address(this));
        
        
        uint bust_burn = Bust_Bal.mul(bust_ratio).div(10000);
        uint ape_burn = Bust_Bal.mul(ape_ratio).div(10000);
        uint mfrm_burn = Bust_Bal.mul(mfarm_ratio).div(10000);
        uint256 time = block.timestamp + 1120;
        BUST.approve(address(router), Bust_Bal);
        
        if(ape_burn > 0){
        
        
        
            uint256 ape = router.getAmountsOut(ape_burn,pApe)[pApe.length - 1];
            uint256 apemin = ape.mul(snum).div(sden);
        
            router.swapExactTokensForTokens(
                ape_burn,
                apemin,
                pApe,
                addr,
                time
            );
        
        
        }
        
        
        if(mfrm_burn > 0){
    
            uint256 mfrm = router.getAmountsOut(mfrm_burn,pMfrm)[pMfrm.length - 1];
            uint256 mfrmmin = mfrm.mul(snum).div(sden);
        
        
            router.swapExactTokensForTokens(
                mfrm_burn,
                mfrmmin,
                pMfrm,
                addr,
                time
            );
        
            // convert bnb to mfrm
            
        }
            
        TransferHelper.safeTransfer(
            address(BUST),
            addr,
            BUST.balanceOf(address(this))
        );
        
    }
        
        
        
        // --------------------------------------------------------------------------------------------
        
        // case 2 part 1
    function lock_BUSD_LP(uint _amount) internal{
        TransferHelper.safeTransfer(
          address(BUSD_BUST),
          lock,
          _amount
          );
    }
        // case 4 part 1
        
    function BUSD_DAO(uint _amount, address addr) internal{
        (uint256 _reserve0, uint256 _reserve1, uint256 _blockTimestampLast) = BUSD_BUST.getReserves();
        uint tSupply = BUSD_BUST.totalSupply();
        
        // change while deployment ??
        
        uint tok0min = _reserve0.div(tSupply).mul(_amount).mul(rnum).div(rden);
        uint tok1min = _reserve1.div(tSupply).mul(_amount).mul(rnum).div(rden);
        uint256 time = block.timestamp + 1120;
        
        router.removeLiquidity(
            address(BUSD),
            address(BUST),
            _amount,
            tok0min,
            tok1min,
            address(this),
            time
        );
        
        TransferHelper.safeTransfer(
            address(BUST),
            addr,
            BUST.balanceOf(address(this))
        );
        TransferHelper.safeTransfer(
            address(BUSD),
            addr,
            BUSD.balanceOf(address(this))
        );
        
    }
        
        
        // BNB LP function
        // case 1 and case 3 part 2
        
    function getBUST_BNBLP(uint _amount, address addr, uint opt) internal{
        (uint256 _reserve0, uint256 _reserve1, uint256 _blockTimestampLast) =
        BUST_BNB.getReserves();
        uint tSupply = BUST_BNB.totalSupply();
        uint rmAmount = _amount;
        
        // change while deployment ??
        
        uint tok0min = _reserve0.mul(rmAmount).mul(rnum).div(rden).div(tSupply);
        uint tok1min = _reserve1.mul(rmAmount).mul(rnum).div(rden).div(tSupply);
        uint256 time = block.timestamp + 1120;
        
        router.removeLiquidityETH(address(BUST),
            rmAmount,
            tok1min,
            tok0min,
            address(this),
            time
        );
        
        
        
        // convert the BNB to BUST
        ( _reserve0, _reserve1, _blockTimestampLast) = BUST_BNB.getReserves();
        
        //uint256 bust = _reserve1.mul(address(this).balance).div(_reserve0);
        uint256 bust = router.getAmountsOut(address(this).balance,pETH)[1];
        uint256 bustmin = bust.mul(snum).div(sden);
        
        
        router.swapExactETHForTokens.value(address(this).balance)(
            bustmin,
            pETH,
            address(this),
            time
        );
        
        
        
        // send the received amount to referal contract
        if(opt == 0){
            TransferHelper.safeTransfer(
                address(BUST),
                addr,
                BUST.balanceOf(address(this))
        
            );
            
        }
        
        
    }
        
        
        // case 2 part 1
    function lock_BNB_LP(uint _amount) internal{
        TransferHelper.safeTransfer(
            address(BUST_BNB),
            lock,
            _amount
        );
    }
        
        
        // case 4 part 1
        
    function BNB_DAO(uint _amount, address payable addr) internal{
        
        
        (uint256 _reserve0, uint256 _reserve1, uint256 _blockTimestampLast) =BUST_BNB.getReserves();
        
        uint tSupply = BUST_BNB.totalSupply();
        uint rmAmount = _amount;
        
        // change while deployment ??
        
        uint tok0min = _reserve0.mul(rmAmount).mul(rnum).div(rden).div(tSupply);
        uint tok1min = _reserve1.mul(rmAmount).mul(rnum).div(rden).div(tSupply);
        uint256 time = block.timestamp + 1120;
        
        router.removeLiquidityETH(address(BUST),
            rmAmount,
            tok1min,
            tok0min,
            address(this),
            time
        );
        
        
        
        TransferHelper.safeTransfer(
            address(BUST),
            addr,
            BUST.balanceOf(address(this))
        );
        
        addr.transfer(address(this).balance);
        
        
    }
        
        
    // fallback function
        
    fallback() external payable {}
        
    // emergency withdraw
        
    function emergencyWithdraw(address payable _recepient) public restricted(){
        TransferHelper.safeTransfer(address(BUST_BNB), _recepient, BUST_BNB.balanceOf(address(this)));
        TransferHelper.safeTransfer(address(BUSD_BUST), _recepient, BUSD_BUST.balanceOf(address(this)));
    }

}

// 3 address paths in swap and get min 
// len-1
// minamount