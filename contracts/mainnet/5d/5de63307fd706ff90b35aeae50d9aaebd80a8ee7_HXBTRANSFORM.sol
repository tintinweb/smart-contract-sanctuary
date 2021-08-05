//HXB_EXCHANGE.sol

pragma solidity 0.6.4;

import "./SafeMath.sol";
import "./IERC20.sol";

interface HXB {
    function mintHXB (uint256 value, address receiver)
        external
    returns (bool);
    
    function mintRatio() external pure returns (uint256);//hxb
    function mintBlock() external pure returns (bool);//hxy/hxb
   // uint256 mintRatio;
   // bool mintBlock;
}

//Uniswap v2 interface
interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

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
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
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

interface IUniswapV2Pair {
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

  function mint(address to) external returns (uint liquidity);
  function burn(address to) external returns (uint amount0, uint amount1);
  function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
  function skim(address to) external;
  function sync() external;
}


////////////////////////////////////////////////
////////////////////EVENTS/////////////////////
//////////////////////////////////////////////

contract Events {

    //when a user transforms HEX to HXB
    event HexTransform (
        uint hexAmt,
        uint hxyAmt,
        address indexed transformer
    );
    
    //when a user transforms ETH to HXB
    event EthTransform (
        uint ethAmt,
        uint hxyAmt,
        address indexed transformer
    );
    
    //when a user transforms HXY to HXB
    event HxyTransform (
        uint ethAmt,
        uint hxyAmt,
        address indexed transformer
    );
    
    //when a users ref bonus gets locked
    event RefLock(
        address indexed user,
        uint256 amount
    );
    
    event RefUnlock(
        address indexed user,
        uint256 amount
    );

    //when transformed tokens get locked
    event TransformLock(
        address indexed user,
        uint256 amount
    );
    
    event TransformUnlock(
        address indexed user,
        uint256 amount
    );
    
    event MultisigSet(
        address indexed wallet
    );

}

//////////////////////////////////////
//////////HXBTRANSFORM CONTRACT////////
////////////////////////////////////
contract HXBTRANSFORM is Events {

    using SafeMath for uint256;

    //uniswap setup
    address public factoryAddress = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address public routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    //address public uniHXBETH = 0xaDEA645907Dbe2b9BCB7B102695Ad0C321f6b40c;
    address public uniHEXHXY = 0x8081Daa61DC0fb980Ad6bB61f51461877EC8dc7A;
    address public uniHEXHXB = 0x938Af9DE4Fe7Fd683F9eDf29E12457181E01Ca46;
    //address public uniHXBHXY = 0x7a1Bb83A28203636F1cd75B6Fac54d4a8dff0F50;
    address public uniHEXETH = 0x55D5c232D921B9eAA6b37b5845E439aCD04b4DBa;
    
    IUniswapV2Pair internal uniHexHxyInterface = IUniswapV2Pair(uniHEXHXY);
    IUniswapV2Pair internal uniHexHxbInterface = IUniswapV2Pair(uniHEXHXB);
    //IUniswapV2Pair internal uniHxbHxyInterface = IUniswapV2Pair(uniHXBHXY);
    IUniswapV2Pair internal uniHexEthInterface = IUniswapV2Pair(uniHEXETH);
    
    IUniswapV2Router02 internal uniV2Router = IUniswapV2Router02(routerAddress);
    
    //hex contract setup
    address internal hexAddress = 0x2b591e99afE9f32eAA6214f7B7629768c40Eeb39;
    IERC20 internal hexInterface = IERC20(hexAddress);
    
    //hxy contract setup
    address internal hxyAddress = 0xf3A2ace8e48751c965eA0A1D064303AcA53842b9;
    IERC20 internal hxyInterface = IERC20(hxyAddress);
    
    //hxb contract setup
    address internal hxbAddress = 0x9BB6fd000109E24Eb38B0Deb806382fF9247E478;
    IERC20 internal hxbInterface = IERC20(hxbAddress);
    HXB internal hxbControl = HXB(hxbAddress);
    
    address payable public liquidityBuyback = 0xf72842821c58aDe72EDa5ec5399B959b499d4AA4;
    address public hexDividendContract = 0x7d68C0321cf6B3A12E6e5D5ABbAA8F2A13d77FDd;
    address public hxyDividendContract = 0x8530261684C0549D5E85A30934e30D60C46AA8a1;
    //transform room
    bool public roomActive;
    uint public totalHexTransformed = 0;
    uint public totalEthTransformed = 0;
    uint public totalHxyTransformed = 0;
    uint public totalHxbMinted = 0;
    uint private ethLiquidity = 0;
    uint private hexLiquidity = 0;
    uint private hxyLiquidity = 0;
    uint private ethDivs = 0;
    uint private hexDivs = 0;
    uint private hxyDivs = 0;
    
    //referral lock
    uint public totalRefLocked = 0;
    mapping (address => uint) public refLockedBalances; //balance of referral HXB locked till maxSupply
    uint public totalTransformLocked = 0;
    mapping (address => uint) public transformLockedBalances; // balance of 50% transformed HXB locked till maxSupply
    
    //admin
    address payable internal _p1 = 0xbf1984B12878c6A25f0921535c76C05a60bdEf39;
    address payable internal _p2 = 0xD64FF89558Cd0EA20Ae7aA032873d290801865f3;
    
    bool private multisigSet;
    
    bool private _sync;
    
    mapping(address => bool) admins;
    mapping (address => Transformed) public transformed;

    struct Transformed{
        uint256 hexTransformed;
        uint256 ethTransformed;
        uint256 usdcTransformed;
        uint256 hxyTransformed;
        uint256 hxbMinted;
        uint256 hxbRefMinted;
    }

    modifier onlyAdmins(){
        require(admins[msg.sender], "not an admin");
        _;
    }
    
    //protects against potential reentrancy
    modifier synchronized {
        require(!_sync, "Sync lock");
        _sync = true;
        _;
        _sync = false;
    }

    constructor() public {
        admins[_p1] = true;
        admins[_p2] = true;
        admins[msg.sender] = true;
    }
 
    receive() external payable{
        //
    }

    function pushEthLiquidity()
        public
        synchronized
    {
        //get price 
        (uint reserve0, uint reserve1,) = uniHexEthInterface.getReserves();
        uint _hex = uniV2Router.quote(ethLiquidity, reserve1, reserve0);
        //get price 
        (uint _reserve0, uint _reserve1,) = uniHexHxbInterface.getReserves();
        uint hxb = uniV2Router.quote(_hex, _reserve0, _reserve1);
        //mint
        require(hxbControl.mintHXB(hxb.mul(hxbControl.mintRatio()), address(this)), "could not mint HXB");
        //send
        liquidityBuyback.transfer(ethLiquidity);
        hxbInterface.transfer(liquidityBuyback, hxb);
        //reset
        ethLiquidity = 0;
    }
    
    function pushHexLiquidity()
        public
        synchronized
    {
        //get price 
        (uint reserve0, uint reserve1,) = uniHexHxbInterface.getReserves();
        uint hxb = uniV2Router.quote(hexLiquidity, reserve0, reserve1);
        //mint
        require(hxbControl.mintHXB(hxb.mul(hxbControl.mintRatio()), address(this)), "could not mint HXB");
        //send
        hexInterface.transfer(liquidityBuyback, hexLiquidity);
        hxbInterface.transfer(liquidityBuyback, hxb);
        //reset
        hexLiquidity = 0;
    }
    
    function pushHxyLiquidity()
        public
        synchronized
    {
        //get price 
        (uint reserve0, uint reserve1,) = uniHexHxyInterface.getReserves();
        uint _hex = uniV2Router.quote(hxyLiquidity, reserve1, reserve0);
        //gett price 
        (uint _reserve0, uint _reserve1,) = uniHexHxbInterface.getReserves();
        uint hxb = uniV2Router.quote(_hex, _reserve0, _reserve1);
        //mint
        require(hxbControl.mintHXB(hxb.mul(hxbControl.mintRatio()), address(this)), "could not mint HXB");
        //send
        hxyInterface.transfer(liquidityBuyback, hxyLiquidity);
        hxbInterface.transfer(liquidityBuyback, hxb);
        //reset
        hxyLiquidity = 0;
    }
    
    function pushAllLiquidity()
        public
    {
        if(ethLiquidity > 0){
            pushEthLiquidity();
        }
        if(hexLiquidity > 0){
            pushHexLiquidity();
        }   
        if(hxyLiquidity > 0){
            pushHxyLiquidity();
        }   
    }
    
    function pushDivs()
        public
    {
        if(ethDivs > 0){
            address[] memory path = new address[](2);
            path[0] = uniV2Router.WETH();
            path[1] = address(hexAddress);
            //buy hex with eth, recipient is div contract
            uniV2Router.swapExactETHForTokens{value:ethDivs}(0, path, hexDividendContract, now.add(800));
            ethDivs = 0;
        }
        if(hexDivs > 0){
            //send hex to div contract
            hexInterface.transfer(hexDividendContract, hexDivs);
            hexDivs = 0;
        }
        if(hxyDivs > 0){
            //send hxy to div contract
            hxyInterface.transfer(hxyDividendContract, hxyDivs);
            hxyDivs = 0;
        }
    }
    
    //transforms ETH to HXB @ uniswap rate
    function transformETH(address ref)//Approval needed
        public
        payable
        synchronized
    {
        require(roomActive, "transform room not active");
        require(msg.value >= 100, "value too low");
        //allocate funds
        ethLiquidity += msg.value.mul(60).div(100);//60%
        ethDivs += msg.value.mul(40).div(100);//40%
        //get HEX to ETH price
        (uint reserve0, uint reserve1,) = uniHexEthInterface.getReserves();
        uint _hex = uniV2Router.quote(msg.value, reserve1, reserve0);
        //get HEX to HXB price 
        (uint _reserve0, uint _reserve1,) = uniHexHxbInterface.getReserves();
        uint hxb = uniV2Router.quote(_hex, _reserve0, _reserve1);
        require(_hex <= _reserve0.div(10), "transform value too high");
        uint256 mintRatio = hxbControl.mintRatio();//adjust for changing dapp mintratio by multiplying first before division in HXB contract
        
        if(ref != address(0))//ref
        {
            uint refBonus = hxb.div(10);
            require(hxbControl.mintHXB(hxb.add(refBonus).mul(mintRatio), address(this)), "Mint failed");//mint hxb from contract to this contract
            //global
            totalHxbMinted += hxb.add(refBonus);
            //user
            transformed[ref].hxbRefMinted += refBonus;
            //lock +10% to referrer
            LockRefTokens(refBonus, ref);
        }
        else{//no ref
            require(hxbControl.mintHXB(hxb.mul(mintRatio), address(this)), "Mint failed");//mint hxb from contract to this contract
            totalHxbMinted += hxb;
        }
        
        totalEthTransformed += msg.value;
        transformed[msg.sender].ethTransformed += msg.value;
        transformed[msg.sender].hxbMinted += hxb;
        LockTransformTokens(hxb.div(2), msg.sender);//lock 50% HXB
        hxbInterface.transfer(msg.sender, hxb.div(2));//transfer 50% HXB
        emit EthTransform(msg.value, hxb, msg.sender);
    }
    
    //transforms HEX to HXB @ uniswap rate
    function transformHEX(uint hearts, address ref)//Approval needed
        public
        synchronized
    {
        require(roomActive, "transform room not active");
        require(hearts >= 100, "value too low");
        require(hexInterface.transferFrom(msg.sender, address(this), hearts), "Transfer failed");//send hex from user to contract
        //allocate funds
        hexLiquidity += hearts.mul(60).div(100);//60%
        hexDivs += hearts.mul(40).div(100);//40%
        //get HXB price
        (uint reserve0, uint reserve1,) = uniHexHxbInterface.getReserves();
        uint hxb = uniV2Router.quote(hearts, reserve0, reserve1);
        require(hearts <= reserve0.div(10), "transform value too high");
        uint256 mintRatio = hxbControl.mintRatio();//adjust for changing dapp mintratio by multiplying first before division in HXB contract
        
        if(ref != address(0))//ref
        {
            uint refBonus = hxb.div(10);
            require(hxbControl.mintHXB(hxb.add(refBonus).mul(mintRatio), address(this)), "Mint failed");//mint hxb from contract to this contract
            //global
            totalHxbMinted += hxb.add(refBonus);
            //user
            transformed[ref].hxbRefMinted += refBonus;
            //lock +10% to referrer
            LockRefTokens(refBonus, ref);
        }
        else{//no ref
            require(hxbControl.mintHXB(hxb.mul(mintRatio), address(this)), "Mint failed");//mint hxb from contract to this contract
            totalHxbMinted += hxb;
        }
        
        totalHexTransformed += hearts;
        transformed[msg.sender].hexTransformed += hearts;
        transformed[msg.sender].hxbMinted += hxb;
        LockTransformTokens(hxb.div(2), msg.sender);//lock 50% HXB
        hxbInterface.transfer(msg.sender, hxb.div(2));//transfer 50% HXB
        emit HexTransform(hearts, hxb, msg.sender);
    }
    
    //transforms HXY to HXB @ uniswap rate
    function transformHXY(uint value, address ref)//Approval needed
        public
        synchronized
    {
        require(roomActive, "transform room not active");
        require(value >= 100, "value too low");
        require(hxyInterface.transferFrom(msg.sender, address(this), value), "Transfer failed");//send hex from user to contract
        //allocate funds
        hxyLiquidity += value.mul(60).div(100);//60%
        hxyDivs += value.mul(40).div(100);//40%
        //get HEX price
        (uint reserve0, uint reserve1,) = uniHexHxyInterface.getReserves(); 
        uint _hex = uniV2Router.quote(value, reserve1, reserve0);
        //get HXB price
        (uint _reserve0, uint _reserve1,) = uniHexHxbInterface.getReserves(); 
        uint hxb = uniV2Router.quote(_hex, _reserve0, _reserve1);
        require(_hex <= _reserve0.div(10), "transform value too high");
        uint256 mintRatio = hxbControl.mintRatio();//adjust for changing dapp mintratio by multiplying first before division in HXB contract
        
        if(ref != address(0))//ref
        {
            uint refBonus = hxb.div(10);
            require(hxbControl.mintHXB(hxb.add(refBonus).mul(mintRatio), address(this)), "Mint failed");//mint hxb from contract to this contract
            //global
            totalHxbMinted += hxb.add(refBonus);
            //user
            transformed[ref].hxbRefMinted += refBonus;
            //lock +10% to referrer
            LockRefTokens(refBonus, ref);
        }
        else{//no ref
            require(hxbControl.mintHXB(hxb.mul(mintRatio), address(this)), "Mint failed");//mint hxb from contract to this contract
            totalHxbMinted += hxb;
        }
        
        totalHxyTransformed += value;
        transformed[msg.sender].hxyTransformed += value;
        transformed[msg.sender].hxbMinted += hxb;
        LockTransformTokens(hxb.div(2), msg.sender);//lock 50% HXB
        hxbInterface.transfer(msg.sender, hxb.div(2));//transfer 50% HXB
        emit HxyTransform(value, hxb, msg.sender);
    }

    //lock referral HXB tokens to contract
    function LockRefTokens(uint amt, address ref)
        internal
    {
        //update balances
        refLockedBalances[ref] = refLockedBalances[ref].add(amt);
        totalRefLocked = totalRefLocked.add(amt);
        emit RefLock(ref, amt);
    }

    //unlock referral HXB tokens from contract
    function UnlockRefTokens()
        public
        synchronized
    {
        require(refLockedBalances[msg.sender] > 0,"Error: unsufficient locked balance");//ensure user has enough locked funds
        require(isLockFinished(), "tokens cannot be unlocked yet. hxb maxsupply not yet reached");
        uint amt = refLockedBalances[msg.sender];
        refLockedBalances[msg.sender] = 0;
        totalRefLocked = totalRefLocked.sub(amt);
        hxbInterface.transfer(msg.sender, amt);//make transfer
        emit RefUnlock(msg.sender, amt);
    }
    
    //lock transformed HXB tokens to contract
    function LockTransformTokens(uint amt, address transformer)
        internal
    {
        //update balances
        transformLockedBalances[transformer] = transformLockedBalances[transformer].add(amt);
        totalTransformLocked = totalTransformLocked.add(amt);
        emit TransformLock(transformer, amt);
    }
    
    //unlock transformed HXB tokens from contract
    function UnlockTransformTokens()
        public
        synchronized
    {
        require(transformLockedBalances[msg.sender] > 0,"Error: unsufficient locked balance");//ensure user has enough locked funds
        require(isLockFinished(), "tokens cannot be unlocked yet. hxb maxsupply not yet reached");
        uint amt = transformLockedBalances[msg.sender];
        transformLockedBalances[msg.sender] = 0;
        totalTransformLocked = totalTransformLocked.sub(amt);
        hxbInterface.transfer(msg.sender, amt);//make transfer
        emit TransformUnlock(msg.sender, amt);
    }
    
    //
    function isLockFinished()
        public
        view
        returns(bool)
    {
        return hxbControl.mintBlock();
    }
    
    ///////////////////////////////
    ////////ADMIN ONLY//////////////
    ///////////////////////////////
    //toggle transform room on/off
    function toggleRoundActive(bool active)
        public
        onlyAdmins
    {
        if(active){
            roomActive = true;
        }
        else{
            roomActive = false;
        }
    }

    function setLiquidityBuyback(address payable _multiSig)
        public
        onlyAdmins
    {
        require(!multisigSet);
        liquidityBuyback = _multiSig;
        multisigSet = true;
        emit MultisigSet(_multiSig);
    }
    
    function setHexEthExchange(address exchange)
        public
        onlyAdmins
    {
        uniHEXETH = exchange;
        uniHexEthInterface = IUniswapV2Pair(uniHEXETH);
    }
    
    function setHexHxbExchange(address exchange)
        public
        onlyAdmins
    {
        uniHEXHXB = exchange;
        uniHexHxbInterface = IUniswapV2Pair(uniHEXHXB);
    }
    
    function setHexHxyExchange(address exchange)
        public
        onlyAdmins
    {
        uniHEXHXY = exchange;
        uniHexHxyInterface = IUniswapV2Pair(uniHEXHXY);
    }
    
}

