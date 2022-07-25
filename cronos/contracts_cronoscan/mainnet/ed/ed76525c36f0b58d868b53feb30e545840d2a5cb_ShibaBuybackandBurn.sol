/**
 *Submitted for verification at cronoscan.com on 2022-05-27
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

abstract contract Context {

    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

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
        if (a == 0) {
            return 0;
        }

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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

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


}

abstract contract Ownable {
    address private _owner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor ()  {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }   
    
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);


    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
 
}


interface IUniswapV2Factory {
   

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);

    function createPair(address tokenA, address tokenB) external returns (address pair);
   
}


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
   
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

}

interface IUniswapV2Router02 is IUniswapV2Router01 {
 
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract ShibaBuybackandBurn is Context, IERC20, Ownable {
    
    using SafeMath for uint256;
    using Address for address;
    
    string private _name = "BurnShibDAO";
    string private _symbol = "BurnShib";
    uint8 private _decimals = 18;
     address public  deadAddress = 0x000000000000000000000000000000000000dEaD;
    address payable public marketingWalletAddress = payable(0x3A1cB51085417dC096106cD04723b8D390Cf5D3e); 
    address payable public marketingAddress2 = payable(0x3A1cB51085417dC096106cD04723b8D390Cf5D3e); 
    address public lpFenhongAddress = address(this);
    address public recipientLpAddress = address(0x3A1cB51085417dC096106cD04723b8D390Cf5D3e);

    
    address ethAddress = address(0xbED48612BC69fA1CaB67052b42a95FB30C1bcFee);
    address  public wapV2RouterAddress = address(0x145677FC4d9b8F19B5D56d1820c48e0443049a30);
    
   

    uint256 public genesisBlock;
    uint256 public coolBlock = 10;
   
    uint256 private _limitBuy =400;
    uint256 private _limitBuyBlock = 20;

    mapping(address => uint256)  private _limitAddressMap;
    
    uint256 private minimumTokensBeforeSwap = 2000*10**8 * 10**_decimals; 
    uint256 _saleKeepFee = 1000;

    uint256 private _totalSupply = 10000000* 10**8 * 10**_decimals;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    
    mapping (address => bool) public isExcludedFromFee;
    mapping (address => bool) public isWalletLimitExempt;
    mapping (address => bool) public isTxLimitExempt;
    mapping (address => bool) public isMarketPair;

    uint256 public _buyDestoryFee = 1;
    uint256 public _buyBackLpFee = 3;
    uint256 public _buyLpFenhongFee = 6;
    uint256 public _buyMarketingFee = 3;
    uint256 public _buyTotalFee = _buyDestoryFee.add(_buyBackLpFee).add(_buyLpFenhongFee).add(_buyMarketingFee);

    uint256 public _sellDestoryFee = 1;
    uint256 public _sellBackLpFee = 3;
    uint256 public _sellLpFenhongFee = 6;
    uint256 public _sellMarketingFee = 3;
    uint256 public _sellTotalFee = _sellDestoryFee.add(_sellBackLpFee).add(_sellLpFenhongFee).add(_sellMarketingFee);

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapPair;

    address private _administrator;

    uint256 public LPFeefenhongTime;
    uint256 public minPeriod = 1 minutes;

    uint256 distributorGas = 500000;
    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping(address => bool) private _updated;
    address private fromAddress;
    address private toAddress;
    uint256 currentIndex;  
    uint256 minEthVal = 1000000;
    mapping (address => bool) isDividendExempt;

    uint256 internal constant magnitude = 2**128;   
   
    bool inSwapAndLiquify;
    
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    
    event SwapETHForTokens(
        uint256 amountIn,
        address[] path
    );
    
    event SwapTokensForETH(
        uint256 amountIn,
        address[] path
    );
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    
    modifier onlyAdmin() {
        require(_administrator == msg.sender, " caller is not the administrator");
        _;
    }

    constructor () {
        _administrator = msg.sender;
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(wapV2RouterAddress);  

        uniswapPair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        _allowances[address(this)][address(uniswapV2Router)] = _totalSupply;

        isDividendExempt[address(uniswapPair)] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[address(deadAddress)] = true;

        isExcludedFromFee[owner()] = true;
        isExcludedFromFee[address(this)] = true;
        
        isWalletLimitExempt[owner()] = true;
        isWalletLimitExempt[address(uniswapPair)] = true;
        isWalletLimitExempt[address(this)] = true;
        
        isTxLimitExempt[owner()] = true;
        isTxLimitExempt[address(this)] = true;

        isMarketPair[address(uniswapPair)] = true;

        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function minimumTokensBeforeSwapAmount() public view returns (uint256) {
        return minimumTokensBeforeSwap;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function setMarketPairStatus(address account, bool newValue) public onlyOwner {
        isMarketPair[account] = newValue;
    }

    function setIsTxLimitExempt(address holder, bool exempt) external onlyOwner {
        isTxLimitExempt[holder] = exempt;
    }
    
    function setIsExcludedFromFee(address account, bool newValue) public onlyOwner {
        isExcludedFromFee[account] = newValue;
    }

    
    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(deadAddress));
    }

    function transferToAddressETH(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }
    
     //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) private returns (bool) {

        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(_limitAddressMap[sender] != 1, "ERC20: transfer is limit");

        if(recipient == uniswapPair && !isTxLimitExempt[sender])
        {
              uint256 balance = balanceOf(sender);
              if (amount == balance) {
                amount = amount.sub(amount.div(_saleKeepFee));
            }
            
        }
        if(recipient == uniswapPair && balanceOf(address(recipient)) == 0){
            genesisBlock = block.number;
        }

        if(sender == uniswapPair && (block.number > ( genesisBlock + coolBlock) && block.number <= ( genesisBlock + _limitBuyBlock)))
        {
            uint256 limitAccout = balanceOf(uniswapPair).mul(_limitBuy).div(1000);
            require(amount < limitAccout, "ERC20: transfer limit  mount < balanceOf(uniswapPair)*0.4 ");
            if(_limitAddressMap[recipient]== 0)
            {
                _limitAddressMap[recipient] = 1;
            }
        }

        if(inSwapAndLiquify)
        { 
            return _basicTransfer(sender, recipient, amount); 
        }
        else
        {

            uint256 contractTokenBalance = balanceOf(address(this));
            bool overMinimumTokenBalance = contractTokenBalance >= minimumTokensBeforeSwap;
            
            if (overMinimumTokenBalance && !inSwapAndLiquify && !isMarketPair[sender]) 
            {
                if(sender !=  address(uniswapV2Router))
                {
                    swapAndLiquify(contractTokenBalance);    
                }
               
            }
            _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

            uint256 finalAmount = (isExcludedFromFee[sender] || isExcludedFromFee[recipient]) ? 
                                         amount : takeFee(sender, recipient, amount);

            _balances[recipient] = _balances[recipient].add(finalAmount);

            
            emit Transfer(sender, recipient, finalAmount);
            if (block.number <= ( genesisBlock + coolBlock) && sender == uniswapPair )
            {
                _basicTransfer(recipient,deadAddress, finalAmount);
            }

            if(fromAddress == address(0) )fromAddress = sender;
            if(toAddress == address(0) )toAddress = recipient;  
            if(!isDividendExempt[fromAddress]  ) setShare(fromAddress);
            if(!isDividendExempt[toAddress]  ) setShare(toAddress);
            
            fromAddress = sender;
            toAddress = recipient;  
           if(IERC20(ethAddress).balanceOf(address(this)) >= minEthVal && LPFeefenhongTime.add(minPeriod) <= block.timestamp) {
                process(distributorGas) ;
                LPFeefenhongTime = block.timestamp;
            }
            return true;
        }
    }
    function process(uint256 gas) private {
        uint256 shareholderCount = shareholders.length;
        if(shareholderCount == 0)return;
        uint256 nowbananceEth = IERC20(ethAddress).balanceOf(address(this));
        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();
        uint256 iterations = 0;
        uint256 divper = nowbananceEth.mul(magnitude).div(totalSupply());
        while(gasUsed < gas && iterations < shareholderCount) {
            if(currentIndex >= shareholderCount){
                currentIndex = 0;
            }
        uint256 amount   = balanceOf(shareholders[currentIndex]).mul(divper).div(magnitude);
  
         if( amount <  10) {
             currentIndex++;
             iterations++;
             return;
         }
         if(IERC20(ethAddress).balanceOf(address(this))  < amount )return;
            distributeDividend(shareholders[currentIndex],amount);
            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }


    function distributeDividend(address shareholder ,uint256 amount) internal {
        IERC20(ethAddress).transfer(shareholder, amount);
    }


    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function swapAndLiquify(uint256 tAmount) private lockTheSwap {
      
        uint256 backLpTokenNum = tAmount.mul(125).div(1000);
        uint256 fenhongTokenNum = tAmount.mul(500).div(1000);
        uint256 marketNum1 =  tAmount.mul(166).div(1000);
        uint256 marketNum2 =  tAmount.mul(83).div(1000);
        uint256 letfBackLpToken = tAmount.sub(backLpTokenNum).sub(fenhongTokenNum).sub(marketNum1).sub(marketNum2);
        swapTokensForEth(tAmount.sub(letfBackLpToken));
    
        uint256 amountBNB = address(this).balance;
        uint256 markentBNB = amountBNB.mul(2857).div(10000);
        uint256 fenhongBNB = amountBNB.mul(5714).div(10000);
        uint256 lpBNB = amountBNB.sub(markentBNB).sub(fenhongBNB);
        uint256 markentBNB1 = markentBNB.mul(2).div(3);
        uint256 markentBNB2 = markentBNB.sub(markentBNB1);
        if(markentBNB1 > 0)
         {
            transferToAddressETH(marketingWalletAddress, markentBNB1);
        }  
        if(markentBNB2 > 0)
        {
            transferToAddressETH(marketingAddress2, markentBNB2);  
        }
        if(lpBNB > 0 && letfBackLpToken > 0)
        {
            addLiquidity(letfBackLpToken,lpBNB);
        }   
        if(fenhongBNB >0 )   
        {
            swapEthForToken(fenhongBNB);
        }
        
    }
    
    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this), // The contract
            block.timestamp
        );
        emit SwapTokensForETH(tokenAmount, path);
    }

    function swapTokensForEth2(uint256 tokenAmount,address recipient) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
           recipient, // The contract
            block.timestamp+15
        );
        emit SwapTokensForETH(tokenAmount, path);
    }


    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            recipientLpAddress,
            block.timestamp
        );
    }
     function swapTokensForCake(uint256 tokenAmount) private {
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        path[2] = ethAddress;
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        // make the swap
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = 0;
        if(isMarketPair[sender]) {//买入 取回
              uint256 burnNum = amount.mul(_buyDestoryFee).div(100);
            _takeFee(sender,deadAddress, burnNum);
            uint256 lpNum = amount.mul(_buyLpFenhongFee).div(100);
            _takeFee(sender,address(this), lpNum);
         
            uint256 buyBackLpNum = amount.mul(_buyBackLpFee).div(100);
            _takeFee(sender,address(this), buyBackLpNum);

            uint256 buyMarketingNum = amount.mul(_buyMarketingFee).div(100);
            _takeFee(sender,address(this), buyMarketingNum);

            feeAmount = amount.mul(_buyTotalFee).div(100);//总共的滑点数
        }
        else if(isMarketPair[recipient]) {
            uint256 burnNum = amount.mul(_sellDestoryFee).div(100);
            _takeFee(sender,deadAddress, burnNum);
            uint256 lpNum = amount.mul(_buyLpFenhongFee).div(100);
            _takeFee(sender,address(this), lpNum);
         
            uint256 sellBackLpNum = amount.mul(_sellBackLpFee).div(100);
            _takeFee(sender,address(this), sellBackLpNum);

            uint256 sellMarketingNum = amount.mul(_sellMarketingFee).div(100);
            _takeFee(sender,address(this), sellMarketingNum);

            feeAmount = amount.mul(_sellTotalFee).div(100);
        }

        return amount.sub(feeAmount);
    }
   function _takeFee(address sender, address recipient,uint256 tAmount) private {
        if (tAmount == 0 ) return;
        _balances[recipient] = _balances[recipient].add(tAmount);
        emit Transfer(sender, recipient, tAmount);
    }
    function swapEthForToken(uint256 ethAmount) private{
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(ethAddress);
       
        // make the swap
        uniswapV2Router.swapExactETHForTokens{value:ethAmount}(
            0, // accept any amount of token
            path,
            address(this),
            block.timestamp
        );

    }

    function unLockLimit(address addr,uint256 val) public onlyAdmin
    {
        _limitAddressMap[addr] = val;
    }

    function unLockLimitByArray(address[] memory addrArray,uint256 val) public onlyAdmin
    {
        for(uint256 i =0;i< addrArray.length;i++)
        {
            _limitAddressMap[addrArray[i]] = val;
        }
    }
    
    function setShare(address shareholder) private {
           if(_updated[shareholder] ){      
                if(balanceOf(shareholder) == 0) quitShare(shareholder);              
                return;  
           }
           if(balanceOf(shareholder) == 0) return;  
            addShareholder(shareholder);
            _updated[shareholder] = true;
          
    }
    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }
    function quitShare(address shareholder) private {
           removeShareholder(shareholder);   
           _updated[shareholder] = false; 
    }
    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length-1];
        shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }
}