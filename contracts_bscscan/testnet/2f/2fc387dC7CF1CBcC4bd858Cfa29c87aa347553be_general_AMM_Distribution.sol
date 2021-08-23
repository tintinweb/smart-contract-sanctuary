/**
 *Submitted for verification at BscScan.com on 2021-08-23
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

contract general_AMM_Distribution{
     using SafeMath for uint256;
     
      // Tokens declaration
    
    IERC20 public partnerToken ;
    IERC20 public BUSD ;
    IERC20 public WBNB ;
    
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
    
    // address where funds will be send
    address payable public dao ;
    address public reward;
    address public lock;
    // owner's address
    address public owner;
    
    // LP Tokens
    IBustPair public BUSD_Partner ;
    IBustPair public BNB_Partner ;
    
     // Router Address
    IBustRouter02 public router ;
    
    address[] public busd_partner_path = [0x637F61C18Cd7259f7c5EA50591C7Befe6A2E0BfE, 0x6e03884333a30eE91AFda92E429fF4FD95Dc2850]; // 1st busd 2nd bust
    address[] public bnb_partner_path = [0x44Bc761E0B58Aa6727202eBd2B636DC924dA9f1a, 0x6e03884333a30eE91AFda92E429fF4FD95Dc2850]; // 1st bnb 2nd bust
    
    
    
    //setter
    
     function setBusd_Partner_Path(address[] memory _busd_partner_path) public restricted(){
        busd_partner_path = _busd_partner_path;
    }
    
    function setBnb_Partner_Path(address[] memory _bnb_partner_path) public restricted(){
        bnb_partner_path = _bnb_partner_path;
    }
    
    function setPercent(uint _a,uint _b, uint _c, uint _d) public restricted(){
        require(_a+_b+_c+_d == 10000, "sum of percent should be equal to 10000");
    
        a=_a;
        b=_b;
        c=_c;
        d=_d;
    }
    
    function setFraction(uint _snum, uint _sden, uint _rnum, uint _rden) public restricted(){
        snum= _snum;
        sden = _sden;
        rnum = _rnum;
        rden = _rden;
    }
    
     function setRewardAddress(address _reward) public restricted(){
        reward = _reward;
    }
    
     function setLockAddress(address _lock) public restricted(){
        lock = _lock;
    }
    
    function setDAO(address payable _dao) public restricted(){
        dao = _dao;
    }
    
    function setRouterAddress(address _router) public restricted(){
        router = IBustRouter02(_router);
    }
    
    function setTokenAddress(address _partnerToken, address _busd, address _wbnb) public restricted(){
        
        partnerToken = IERC20(_partnerToken);
        BUSD = IERC20(_busd);
        WBNB = IERC20(_wbnb);
    }
    
    function setLPAddress(address _busd_lp, address _bnb_lp) public restricted(){
        
        BUSD_Partner =IBustPair(_busd_lp);
        BNB_Partner =IBustPair(_bnb_lp);
        
    }
    
    
    
    //getter
    
    function Partner_BUSD_Bal() public view returns (uint256) {
        return BUSD_Partner.balanceOf(address(this));
    }
    
    function Partner_BNB_Bal() public view returns (uint256) {
        return BNB_Partner.balanceOf(address(this));
    }
    
    function Partner_Bal() public view returns (uint256) {
        return partnerToken.balanceOf(address(this));
    }
    
    function BUSD_Bal() public view returns (uint256) {
        return BUSD.balanceOf(address(this));
    }
    
    function BNB_Bal() public view returns (uint256) {
        return address(this).balance;
    }
    
    //modifier
    
    modifier restricted() {
      //  require(msg.sender==owner,"You are not the owner");
        _;
    }
    
     // constructor
    constructor(address _partner, address _busd, address _wbnb, address _busd_lp, address _bnb_lp, address _router, address _reward,address _lock,address payable _dao) public {
        owner = msg.sender;
        reward = _reward;
        router = IBustRouter02(_router);
        partnerToken = IERC20(_partner);
        BUSD = IERC20(_busd);
        WBNB = IERC20(_wbnb);
        
        BUSD_Partner =IBustPair(_busd_lp);
        
        BNB_Partner = IBustPair(_bnb_lp);
        
        lock = _lock;
        dao = _dao;
    
    }

    
    // functionality 
    
    function BUSD_LP_Distribution() public payable restricted(){
        
        uint256 BUSD_LP_Bal = BUSD_Partner.balanceOf(address(this));
        
        uint c1 = BUSD_LP_Bal.mul(a).div(10000);
        uint c2 = BUSD_LP_Bal.mul(b).div(10000);
        uint c3 = BUSD_LP_Bal.mul(c).div(10000);
        uint c4 = BUSD_LP_Bal.mul(d).div(10000);
        
        
        BUSD_Partner.approve(address(router), BUSD_LP_Bal);
       
       if(c1>0){
            // burn 
             BUSD_to_Partner(c1, 0x000000000000000000000000000000000000dEaD);
        }
        
        if(c2>0){
            // lock 
            lock_LP(c2,0);
        }
        
        if(c3>0){
            // treasury
            BUSD_to_Partner(c3,dao);
        }
        
        if(c4>0){
            // reward 
            BUSD_to_Partner(c4, reward);
        }
        
        
    }
    
    function BNB_LP_Distribution() public payable restricted(){
        
        uint256 BNB_LP_Bal = BNB_Partner.balanceOf(address(this));
        
        uint c1 = BNB_LP_Bal.mul(a).div(10000);
        uint c2 = BNB_LP_Bal.mul(b).div(10000);
        uint c3 = BNB_LP_Bal.mul(c).div(10000);
        uint c4 = BNB_LP_Bal.mul(d).div(10000);
        
        
        BNB_Partner.approve(address(router), BNB_LP_Bal);
       
      if(c1>0){
            // burn 
             BNB_to_Partner(c1, 0x000000000000000000000000000000000000dEaD);
        }
        
        if(c2>0){
            // lock 
            lock_LP(c2,1);
        }
        
        if(c3>0){
            // treasury
            BNB_to_Partner(c3,dao);
        }
        
        if(c4>0){
            // reward 
            BNB_to_Partner(c4, reward);
        }
        
        
    }
    
    
    // internal functions 
    
    function BUSD_to_Partner(uint _amount, address addr) internal {
        
        (uint256 _reserve0, uint256 _reserve1, uint256 _blockTimestampLast) = BUSD_Partner.getReserves();
        uint tSupply = BUSD_Partner.totalSupply();
        
        // remove liquidity
        
        uint tok0min = _reserve0.mul(_amount).mul(rnum).div(rden).div(tSupply);
        uint tok1min = _reserve1.mul(_amount).mul(rnum).div(rden).div(tSupply);
        uint256 time = block.timestamp + 1120;
        
        router.removeLiquidity(
            BUSD_Partner.token0(),
            BUSD_Partner.token1(),
            _amount,
            tok0min,
            tok1min,
            address(this),
            time
        );
        
        // convert BUSD to Partner token
        
        uint256 partner_rec = router.getAmountsOut(BUSD.balanceOf(address(this)),busd_partner_path)[busd_partner_path.length - 1];
        uint256 partner_rec_min = partner_rec.mul(snum).div(sden);
        
        BUSD.approve(address(router), BUSD.balanceOf(address(this)));
        
        router.swapExactTokensForTokens(
            BUSD.balanceOf(address(this)),
            partner_rec_min,
            busd_partner_path,
            address(this),
            time
        );
        
        TransferHelper.safeTransfer(
                address(partnerToken),
                addr,
                partnerToken.balanceOf(address(this))
            );
        
    }
    
    function lock_LP(uint _amount, uint opt) internal{
        
        if(opt == 0){
        TransferHelper.safeTransfer(
          address(BUSD_Partner),
          lock,
          _amount
          );
        }
        
        if(opt == 1){
        TransferHelper.safeTransfer(
          address(BNB_Partner),
          lock,
          _amount
          );
        }
    }
    
    function BNB_to_Partner(uint _amount, address addr) internal {
        (uint256 _reserve0, uint256 _reserve1, uint256 _blockTimestampLast) = BNB_Partner.getReserves();
        uint tSupply = BNB_Partner.totalSupply();
        uint256 time = block.timestamp + 1120;
        
        uint pTokMin;
        uint ethMin;
    
        // remove liquidity 
        if(BNB_Partner.token0() == address(WBNB)){
            ethMin = _reserve0.mul(_amount).mul(rnum).div(rden).div(tSupply);
            pTokMin = _reserve1.mul(_amount).mul(rnum).div(rden).div(tSupply);
        }
        if(BNB_Partner.token1() == address(WBNB)){
            ethMin = _reserve1.mul(_amount).mul(rnum).div(rden).div(tSupply);
            pTokMin = _reserve0.mul(_amount).mul(rnum).div(rden).div(tSupply);
        }
        
        router.removeLiquidityETH(address(partnerToken),
            _amount,
            pTokMin,
            ethMin,
            address(this),
            time
        );
    
        // convert BNB to Partner token 
        
        
        uint256 pT = router.getAmountsOut(address(this).balance,bnb_partner_path)[bnb_partner_path.length - 1];
        uint256 pTM = pT.mul(snum).div(sden);
        
        router.swapExactETHForTokens.value(address(this).balance)(
            pTM,
            bnb_partner_path,
            address(this),
            time
        );
        
        // transfer Partner token
        
         TransferHelper.safeTransfer(
                address(partnerToken),
                addr,
                partnerToken.balanceOf(address(this))
            );
        
        
    }
    
    // utility functions 
    function transferOwnership(address _newOwner) public restricted(){
        require(_newOwner != address(0));
        owner = _newOwner;
    }
    
    //fallback function 
        
    fallback() external payable {}
    
    // emergency withdraw
        
    function emergencyWithdraw(address payable _recepient) public restricted(){
        TransferHelper.safeTransfer(address(BUSD_Partner), _recepient, BUSD_Partner.balanceOf(address(this)));
        TransferHelper.safeTransfer(address(BNB_Partner), _recepient, BNB_Partner.balanceOf(address(this)));
    }
  
}