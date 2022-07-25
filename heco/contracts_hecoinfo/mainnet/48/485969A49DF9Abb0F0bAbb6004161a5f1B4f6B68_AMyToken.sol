/**
 *Submitted for verification at hecoinfo.com on 2022-05-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0 <0.9.0;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "add err");
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "sub err");
    return a - b;
  }

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    require(a == 0 || c / a == b, "mul err");
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0, "div 0 err");
    uint256 c = a / b;
    require(a == b * c + a % b, "div err"); // There is no case in which this doesn't hold
    return c;
  }

}


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
interface ERC20Basic {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  function allowance(address owner, address spender) external view returns (uint256);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract Ownable {
    address private _owner;

    // event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        _owner = msg.sender;
        // emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    // function renounceOwnership() public onlyOwner {
    //     emit OwnershipTransferred(_owner, address(0));
    //     _owner = address(0);
    // }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        // emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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
    function WHT() external pure returns (address);

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



// pragma solidity >=0.6.2;

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

contract TxRule is Ownable{
    using SafeMath for uint256;

    address public _systemAddress;
    address public _fomoDappAddress;

    mapping(address => bool) public txWhiteList;
    address[] public noNeedRedUsers;
    mapping(address => bool) public noNeedRedUsersDic;
    bool public needGas = true; 
    bool public needSendRed = true;
    bool public needApproveTx = true; 
    bool public antiBotEnabled = false;
    bool public swapStartOn = false; 
    mapping(address => bool) public swapWhiteList;
    uint256 public allTotalGas = 0;
    uint256 public lastAllTotalGas = 0;
    uint256 public transferValidAmount = (10**17);
    // uint256 public sendGasMin = 1000 * (10**18); // token
    // uint256 public haveRedMin = 50 * (10**16); // bnb
    // uint256 public swapMaxAmount = 15 * (10**16); // bnb 0.15 
    uint256 public sendGasMin = 100 * (10**18); // token
    uint256 public haveRedMin = 50 * (10**10); // bnb
    uint256 public swapMaxAmount = 15 * (10**10); // bnb 0.15 
    uint256[] public gasRedRatioList = [100,600,90,100,50,50]; // 990/10000  
    uint256 oneToken = (10**18);
    
    SwapHelp swapHelp;
    address public swapHelpAddress;
    
    function setSwapHelp(address _address) external onlyOwner {
        swapHelpAddress = _address;
        swapHelp = SwapHelp(_address);
        txWhiteList[_address] = true;
        noNeedRedUsers.push(_address);
        noNeedRedUsersDic[_address] = true;
    }
    function setEnableAntiBot(bool _enable) external onlyOwner {
        antiBotEnabled = _enable;
    }
    function needApproveTxOnOff(bool _bo) external onlyOwner {
        needApproveTx = _bo;
    }
    function updateSendGasMin(uint256 _value) external onlyOwner {
        require(_value>0, "_value is 0");
        sendGasMin = _value;
    }
    function updateTransferValidAmount(uint256 _value) external onlyOwner {
        require(_value>0, "_value is 0");
        transferValidAmount = _value;
    }
    function updateHaveRedMin(uint256 _value) external onlyOwner {
        require(_value>0, "_value is 0");
        haveRedMin = _value;
    }
    function needGasOnOff(bool _bo) external onlyOwner {
        needGas = _bo;
    }
    function needSendRedOnOff(bool _bo) external onlyOwner {
        needSendRed = _bo;
    } 
    function addTxWhiteLists(address[] memory _addressList) external onlyOwner {
        for (uint256 i=0; i < _addressList.length; i++) {
            txWhiteList[_addressList[i]] = true;
        } 
    }
    function subTxWhiteList(address _address) external onlyOwner {
        delete txWhiteList[_address];
    }
    function addNoNeedRedUsers(address _address) external onlyOwner {
        noNeedRedUsers.push(_address);
        noNeedRedUsersDic[_address] = true;
    }
    function subNoNeedRedUsers(uint256 _index) external onlyOwner {
        delete noNeedRedUsersDic[noNeedRedUsers[_index]];
        delete noNeedRedUsers[_index];
    }
    function updateSystemAddress(address _address) external onlyOwner {
        _systemAddress = _address;
    }
    function updateFomoDappAddress(address _address) external onlyOwner {
        _fomoDappAddress = _address;
    }
    function updateGasRatioList(uint256[] memory _values) external onlyOwner {
        require(_values.length == 6, "_values len is 6");
        uint256 gasRedRatioAll = 0;
        for (uint i=0; i<_values.length; i++) {
            gasRedRatioAll += _values[i];
        }
        require(gasRedRatioAll > 0 && gasRedRatioAll <= 10000, "_values sum error");
        gasRedRatioList= _values;
    }
    function offSwapStartOn() external onlyOwner {
        swapStartOn = false;
    }
    function updateSwapStartOn(bool _on) external onlyOwner { // 需删除
        swapStartOn = _on;
    }
  
    /**
     * 分红 
    */ 
    uint256 public allTotalReward = 0;  
    uint256 public lastTotalReward = 0;
    uint256 public totalAccSushi = 0;
    struct UserStruct {
        uint256 curReward;
        uint256 accSushi;
        uint256 exUpdateAccSushi;
        bool notCanSuperior;
        address superAddress;
    }
    mapping(address => UserStruct) public users;
    
    /**
     * swap 
    */ 
    address usdt = 0x5545153CCFcA01fbd7Dd11C0b23ba694D9509A6F;
    address swap = 0xED7d5F38C79115ca12fe6C0041abb22F0A06C300; // heco
    // address usdt = 0x55d398326f99059fF775485246999027B3197955; // bnb
    // address swap = 0x10ED43C718714eb63d5aA57B78B54704E256024E; // bsc
    // address public usdt = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; // bnb
    // address public swap = 0x7529740ECa172707D8edBCcdD2Cba3d140ACBd85; // pls2e

    ERC20Basic usdtToken = ERC20Basic(usdt);
    address public bTokenAddress;  
    address public exToken;
    address public exBase = usdt; // bnb
    ERC20Basic bToken;
    ERC20Basic cakeToken;
    uint256 public exUpdateAccSushi = 0;
    address[] public swapPath;
    
    // address uniswapV2Pair = address(0x0);
    IUniswapV2Router02 public immutable uniswapV2Router;
    address public uniswapV2Pair;
    address public uniswapV2PairTokenB;
    ERC20Basic public lpTokenContract;
    constructor () { 
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(swap); 
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), usdt); //getPair, createPair
        uniswapV2Router = _uniswapV2Router;
        lpTokenContract = ERC20Basic(uniswapV2Pair);

        swapPath = new address[](3);
        swapPath[0] = address(this);
        swapPath[1] = usdt;
        swapPath[2] = exToken;
    }
    function initBTokenAddress(address _address) external onlyOwner {
        bTokenAddress = _address;
        exToken = bTokenAddress;
        cakeToken = ERC20Basic(exToken);
        bToken = ERC20Basic(bTokenAddress);
        uniswapV2PairTokenB = IUniswapV2Factory(IUniswapV2Router02(swap).factory()).getPair(bTokenAddress, usdt); //getPair, createPair
        txWhiteList[uniswapV2PairTokenB] = true;
    }
    function updateExAndBaseToken(address _exToken, address _exBase) external onlyOwner {
        exToken = _exToken;
        exBase = _exBase;
        exUpdateAccSushi = totalAccSushi;
        lastTotalReward = allTotalReward;
        cakeToken.transfer(_systemAddress, cakeToken.balanceOf(address(this)));
        cakeToken = ERC20Basic(exToken);

        if (_exBase == usdt) {
        swapPath = new address[](3);
        swapPath[0] = address(this);
        swapPath[1] = usdt;
        swapPath[2] = exToken;
        } else {
        swapPath = new address[](4);
        swapPath[0] = address(this);
        swapPath[1] = usdt;
        swapPath[2] = exBase;
        swapPath[3] = exToken;
        }
    }
}

interface SwapHelp  {
    function buySwap() external;
}
/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract StandardToken is ERC20Basic,TxRule {
  using SafeMath for uint256;

  event AddRelate(address indexed user, address indexed superUser);

  mapping(address => uint256) balances;
  mapping (address => mapping (address => uint256)) internal allowed;

  uint256 _totalSupply;

  /**
   * @dev Fix for the ERC20 short address attack.
   */
  modifier onlyPayloadSize(uint size) {
    if(msg.data.length < size + 4) {
      revert();
    }
    _;
  }
    function swapTokensForCake(uint256 tokenAmount, address receiveAddress) private {
        // approve(address(uniswapV2Router), tokenAmount);
        allowed[address(this)][address(uniswapV2Router)] = tokenAmount;
        emit Approval(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            swapPath,
            receiveAddress,
            block.timestamp
        );
    }
    function swapTokensToUsdt(uint256 tokenAmount, address receiveAddress) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = usdt;

        // approve(address(uniswapV2Router), tokenAmount);
        allowed[address(this)][address(uniswapV2Router)] = tokenAmount;
        emit Approval(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            receiveAddress,
            block.timestamp
        );
    }
    /**
    公开
    */
    // true:in:eth->token false:out:token->eth
    function priceToToken(uint256 _amount, bool _in) public view returns(uint256) {
        require(_amount > 0, "Amount is 0");
        uint256 betBalance = balances[uniswapV2Pair];
        uint256 usdtBalance = usdtToken.balanceOf(uniswapV2Pair);
        if (betBalance == 0 || usdtBalance == 0) {
            return 0;
        }
        uint256 res = 0;
        if (_in) {
            res = uniswapV2Router.getAmountIn(_amount, betBalance, usdtBalance);
        } else {
            res = uniswapV2Router.getAmountOut(_amount, betBalance, usdtBalance);
        }
        return res.mul(oneToken).div(_amount);
    } 
    function priceToTokenB(uint256 _amount) public view returns(uint256) {
        require(_amount > 0, "Amount is 0");
        uint256 betBalance = bToken.balanceOf(uniswapV2PairTokenB);
        uint256 usdtBalance = usdtToken.balanceOf(uniswapV2PairTokenB);
        if (betBalance == 0 || usdtBalance == 0) {
            return 0;
        }
        uint256 res = uniswapV2Router.getAmountIn(_amount, betBalance, usdtBalance);
        return res.mul(oneToken).div(_amount);
    } 
    // A to B price
    function aTobPrice(uint256 _amount) public view returns (uint256){
        return priceToTokenB(priceToToken(_amount, false));
    }
    function totalValidBalanceLp() public view returns (uint256) {
        uint256 amount = lpTokenContract.totalSupply()+1;
        for (uint256 i=0; i < noNeedRedUsers.length; i++) {
            if (noNeedRedUsers[i] != address(0x0)) {
                uint256 balance = lpTokenContract.balanceOf(noNeedRedUsers[i]);
                amount = amount.sub(balance);
            }
        }  
        return amount.sub(lpTokenContract.balanceOf(address(0x0)));
    }
    function balanceRedOf(address _user) public view returns (uint256) {
        if (noNeedRedUsersDic[_user] || lpTokenContract.balanceOf(_user) < priceToToken(haveRedMin, true)) {return 0;}    
        UserStruct memory user = users[_user];
        
        uint256 accSushi = user.accSushi;
        if (user.exUpdateAccSushi < exUpdateAccSushi) {
            accSushi = exUpdateAccSushi;
        }       
    
        uint256 _nowSushi = totalAccSushi.add(allTotalReward.sub(lastTotalReward).mul(_totalSupply).div(totalValidBalanceLp()));
        return balanceOf(_user).mul(_nowSushi.sub(accSushi)).div(_totalSupply);
    }
    function countGasRedRatioAll() public view returns(uint256){
        uint256 gasRedRatioAll = 0;
        for (uint256 i=0; i < gasRedRatioList.length; i++) {
            gasRedRatioAll += gasRedRatioList[i];
        }
        return gasRedRatioAll;
    }
    

    /**
    私有
    */
    function handleSendRed(address _user) public{
        if (noNeedRedUsersDic[_user] || lpTokenContract.balanceOf(_user) < priceToToken(haveRedMin, true)) {return;}    
        
        UserStruct storage user = users[_user];
        if (user.exUpdateAccSushi < exUpdateAccSushi) {
            user.exUpdateAccSushi = exUpdateAccSushi;
            user.accSushi = exUpdateAccSushi;
        } 
        uint256 _nowSushi = totalAccSushi.add(allTotalReward.sub(lastTotalReward).mul(_totalSupply).div(totalValidBalanceLp()));
        uint256 _userRed = lpTokenContract.balanceOf(_user).mul(_nowSushi.sub(user.accSushi)).div(_totalSupply);
        if (_userRed > 0) {
            cakeToken.transfer(_user, _userRed);
            user.curReward = user.curReward.add(_userRed);
        }
        
        user.accSushi = _nowSushi;        
        totalAccSushi = _nowSushi;
        lastTotalReward = allTotalReward;
    }
    function handleTrasfer() public  { // private
        uint256 subAmount = allTotalGas.sub(lastAllTotalGas);
        if (subAmount > sendGasMin) {
            lastAllTotalGas = allTotalGas;
            uint256 gasRatioAll = gasRedRatioList[0]+gasRedRatioList[1];
            
            inTtransfer(address(this), swapHelpAddress, subAmount.mul(gasRedRatioList[1]).div(gasRatioAll));
            swapHelp.buySwap();
            
            uint256 tokenRedAmount = 0; 
            uint256 amount = subAmount.sub(subAmount.mul(gasRedRatioList[1]).div(gasRatioAll));
            if (exToken == bTokenAddress) {
                // bToken已经存在了合约里，不需要兑换
                swapTokensToUsdt(amount, _systemAddress);
                tokenRedAmount = amount.mul(aTobPrice(amount)).div(oneToken);
            } else {
                uint256 initBalance = cakeToken.balanceOf(address(this));
                swapTokensForCake(amount, address(this));
                tokenRedAmount = cakeToken.balanceOf(address(this)).sub(initBalance);
            }
            
            allTotalReward = allTotalReward.add(tokenRedAmount);
        }
    }

    function handleSubGasBalance(address _user, address _to, uint256 _value) public{
        uint256 _gas = _value.mul(countGasRedRatioAll()).div(10000);
        uint256 peerGas = _value.mul(1).div(10000);
        allTotalGas = allTotalGas.add((gasRedRatioList[0]+gasRedRatioList[1]).mul(peerGas));
        inTtransfer(_to, address(this), _gas);
        inTtransfer(address(this), _fomoDappAddress, gasRedRatioList[2].mul(peerGas));
        
        UserStruct memory baseUser = users[_user]; 
        address superAddress = baseUser.superAddress;
        uint256 index = 0;
        while (superAddress != address(0x0) && index < 3) {
            if (lpTokenContract.balanceOf(superAddress) >= priceToToken(haveRedMin, true)) {
                inTtransfer(address(this), superAddress, gasRedRatioList[3+index].mul(peerGas));
            }
            
            baseUser = users[superAddress];
            superAddress = baseUser.superAddress;
            index++;
        }
    }
    function inTtransfer(address _from, address _to, uint256 _value) private {
        // if (_value > 0) {
            balances[_from] = balances[_from].sub(_value);
            balances[_to] = balances[_to].add(_value);
            emit Transfer(_from, _to, _value);
        // }
    }
    function bindSuper(address _user, address _superUser) public {
        UserStruct storage baseUser = users[_user];
        if (!baseUser.notCanSuperior) {
            baseUser.notCanSuperior = true;
            if (_superUser != uniswapV2Pair && _user != _superUser) {
                baseUser.superAddress = _superUser;
                emit AddRelate(_user, _superUser);
            }
        }
    }
    function _transfer(address _from, address _to, uint256 _value) private {
        require(_value <= balances[_from], "_from balance low");
        if (_from == address(this) || _from == uniswapV2PairTokenB) {
            inTtransfer(_from, _to, _value);
            return;
        }
        address gasAddress = address(0x0);
        if (_from == uniswapV2Pair) {
            gasAddress = _to;
        } 
        if (_to == uniswapV2Pair) {
            gasAddress = _from;
        }

        if (swapStartOn && gasAddress != address(0x0)) {
            require(swapWhiteList[gasAddress], "user not swap");
            uint256 maxAmount = priceToToken(swapMaxAmount, true);
            require(balances[gasAddress] < maxAmount, "swap max amount");
            if (balances[gasAddress].add(_value) > maxAmount) {
                _value = maxAmount.sub(balances[gasAddress]);  
            }
        }
        if (needSendRed && totalValidBalanceLp() > 0) { 
            // handleSendRed(_from);
            handleSendRed(_to);
        }
        
        inTtransfer(_from, _to, _value);

        if (_value >= transferValidAmount) {
            bindSuper(_to, _from);
        }

        if (needGas) {
            if (gasAddress != address(0x0) && !txWhiteList[gasAddress]) {
                handleSubGasBalance(gasAddress, _to, _value);
            } else if (_to != uniswapV2Pair && _from != uniswapV2Pair) {
                handleTrasfer();
            }
        }
    }
    
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        allowed[owner][spender] = amount;
        emit Approval(owner, spender, amount);

        if (!txWhiteList[owner] && needApproveTx) { 
            handleTrasfer();
        }
    }
    
    
  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public onlyPayloadSize(2 * 32) override returns (bool) {
    // require(_to != address(0));
    _transfer(msg.sender, _to, _value);
    return true;
  }

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public override returns (bool) {
    require(_to != address(0), "to do not is 0x0");
    require(_value <= allowed[_from][msg.sender], "_from allowed low");
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    
    _transfer(_from, _to, _value);
    return true;
  }
  
  function balanceOf(address _owner) public view override returns (uint256 balance) {
    return balances[_owner];
  }
  
  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view override returns (uint256) {
    return _totalSupply;
  }
  
  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public onlyPayloadSize(2 * 32) override returns (bool) {
    _approve(msg.sender, _spender, _value);
    return true;
  }
    
  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public view override returns (uint256) {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(address _spender, uint _addedValue) public onlyPayloadSize(2 * 32) returns (bool) {
    require(_spender != address(0));
    // require(allowed[msg.sender][_spender].add(_addedValue) <= balances[msg.sender]);
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(address _spender, uint _subtractedValue) public onlyPayloadSize(2 * 32) returns (bool) {
    require(_spender != address(0));
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}


/**
 * @title SimpleToken
 * @dev ERC20 Token, where all tokens are pre-assigned to the creator.
 * Note they can later distribute these tokens as they wish using `transfer` and other
 * `StandardToken` functions.
 */
contract AMyToken is StandardToken {

    // string public constant symbol = "V2E";
    // string public constant name = "VoteP2E";
    string public constant symbol = "A2";
    string public constant name = "A2";
    uint8 public constant decimals = 18; 

    uint256 public constant INITIAL_SUPPLY = 10000 * (10 ** 8) * (10 ** uint256(decimals));    
    // uint256 public constant INITIAL_SUPPLY = 210 * (10 ** 4) * (10 ** uint256(decimals));

    /**
    * @dev Constructor that gives msg.sender all of existing tokens.
    */
    constructor() {
        _totalSupply = INITIAL_SUPPLY;
        
        // test
        address systemReceive = msg.sender;
        _systemAddress = 0x5c6B0f7Bf3E7ce046039Bd8FABdfD3f9F5021678;
        _fomoDappAddress = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
        
        noNeedRedUsers = [uniswapV2Pair, systemReceive];
        for (uint256 i=0; i < noNeedRedUsers.length; i++) {
            noNeedRedUsersDic[noNeedRedUsers[i]] = true;
            txWhiteList[noNeedRedUsers[i]] = true;
        }
        address[7] memory txWhiteUsers = [address(0x0), address(0x01), address(this),
            _systemAddress, _fomoDappAddress, msg.sender, systemReceive];
        for (uint256 i=0; i < txWhiteUsers.length; i++) {
            txWhiteList[txWhiteUsers[i]] = true;
        }

        address[] memory swapWhiteArr = noNeedRedUsers;
        for (uint256 i=0; i < swapWhiteArr.length; i++) {
            swapWhiteList[swapWhiteArr[i]] = true;
        }

        balances[systemReceive] = INITIAL_SUPPLY;
        emit Transfer(address(0x0), systemReceive, balances[systemReceive]);
    }
}