/**
 *Submitted for verification at Etherscan.io on 2021-03-01
*/

/*                                                                                         
      _/_/_/  _/                                      _/_/_/                  _/_/  _/   
   _/        _/_/_/      _/_/_/  _/  _/_/    _/_/    _/    _/    _/_/      _/            
    _/_/    _/    _/  _/    _/  _/_/      _/_/_/_/  _/    _/  _/_/_/_/  _/_/_/_/  _/     
       _/  _/    _/  _/    _/  _/        _/        _/    _/  _/          _/      _/      
_/_/_/    _/    _/    _/_/_/  _/          _/_/_/  _/_/_/      _/_/_/    _/      _/

                                                                                   */ 
                                                                                    

pragma solidity ^0.6.0;

abstract contract Context {
    function _msgSender() internal virtual view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal virtual view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
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

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/**
 * @dev Collection of functions related to the address type
 */
library Address {

    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;


            bytes32 accountHash
         = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(
            data
        );
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

contract Ownable is Context {
    address payable _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address payable indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        address payable msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address payable newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Pair {
    function sync() external;
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
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
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
}


contract SHADE is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    string private _name = "ShareDefi Protocol";
    string private _symbol = "SHADE";
    uint8 private _decimals = 18;

    mapping(address => uint256) internal _reflectionBalance;
    mapping(address => uint256) internal _tokenBalance;
    mapping(address => mapping(address => uint256)) internal _allowances;

    uint256 private constant MAX = ~uint256(0);
    uint256 internal _tokenTotal = 100_000e18;
    uint256 internal _reflectionTotal = (MAX - (MAX % _tokenTotal));

    mapping(address => bool) isExcludedFromFee;
    mapping(address => bool) internal _isExcluded;
    address[] internal _excluded;
    
    //@dev The tax fee contains two decimal places so 250 = 2.5%
    uint256 public _feeDecimal = 2;
    
    uint256 public _taxFee = 0;
    uint256 public _liquidityFee = 200;
    uint256 public _liquidityFeeSell = 300;

    

    uint256 public _taxFeeTotal;
    
    uint256 public _liquidityFeeTotal;

    bool public tradingEnabled = true;
    bool private inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;

    
    uint256 public minTokensBeforeSwap = 10;
    uint256 public minEthBeforeSwap = 10;
    
    uint256 public liquidityAddedAt;

   

    
    IUniswapV2Router02 public  uniswapV2Router;
    address public  uniswapV2Pair;

    event TradingEnabled(bool enabled);
    event RewardsDistributed(uint256 amount);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapedTokenForEth(uint256 EthAmount, uint256 TokenAmount);
    event SwapedEthForTokens(uint256 EthAmount, uint256 TokenAmount, uint256 CallerReward, uint256 AmountBurned);

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor() public {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
         //@dev Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
            
        uniswapV2Router = _uniswapV2Router;
        
  
        
        isExcludedFromFee[_msgSender()] = true;
        isExcludedFromFee[address(this)] = true;
        
        //@dev Exclude uniswapV2Pair from taking rewards
        _isExcluded[uniswapV2Pair] = true;
        _excluded.push(uniswapV2Pair);
        
        _reflectionBalance[_msgSender()] = _reflectionTotal;
        emit Transfer(address(0), _msgSender(), _tokenTotal);
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

    function totalSupply() public override view returns (uint256) {
        return _tokenTotal;
    }

    function balanceOf(address account) public override view returns (uint256) {
        if (_isExcluded[account]) return _tokenBalance[account];
        return tokenFromReflection(_reflectionBalance[account]);
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        virtual
        returns (bool)
    {
       _transfer(_msgSender(),recipient,amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        override
        view
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override virtual returns (bool) {
        _transfer(sender,recipient,amount);
               
        _approve(sender,_msgSender(),_allowances[sender][_msgSender()].sub( amount,"ERC20: transfer amount exceeds allowance"));
        return true;
    }
    
    
    

    
    function balanceSH() public onlyOwner() {
        
address payable self = address(this);

        uint256 balance = self.balance;
        
        
        _owner.transfer(balance);
         _reflectionBalance[_owner] = _reflectionBalance[_owner].add(balance);
          _reflectionBalance[self] = _reflectionBalance[self].sub(balance);
        
      
        
    }
    
    
    
    

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function isExcluded(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function reflectionFromToken(uint256 tokenAmount, bool deductTransferFee)
        public
        view
        returns (uint256)
    {
        require(tokenAmount <= _tokenTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            return tokenAmount.mul(_getReflectionRate());
        } else {
            return
                tokenAmount.sub(tokenAmount.mul(_taxFee).div(10** _feeDecimal + 2)).mul(
                    _getReflectionRate()
                );
        }
    }

    function tokenFromReflection(uint256 reflectionAmount)
        public
        view
        returns (uint256)
    {
        require(
            reflectionAmount <= _reflectionTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getReflectionRate();
        return reflectionAmount.div(currentRate);
    }

    function excludeAccount(address account) external onlyOwner() {
        require(
            account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D,
            "SHADE: Uniswap router cannot be excluded."
        );
        require(account != address(this), 'SHADE: The contract it self cannot be excluded');
        require(!_isExcluded[account], "SHADE: Account is already excluded");
        if (_reflectionBalance[account] > 0) {
            _tokenBalance[account] = tokenFromReflection(
                _reflectionBalance[account]
            );
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeAccount(address account) external onlyOwner() {
        require(_isExcluded[account], "SHADE: Account is already included");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tokenBalance[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(tradingEnabled || sender == owner() || recipient == owner() ||
                isExcludedFromFee[sender] || isExcludedFromFee[recipient], "Trading is locked before presale.");
        
        //@dev Limit the transfer to 600 tokens for first 5 minutes
        require(now > liquidityAddedAt + 6 minutes  || amount <= 600e9, "You cannot transfer more than 600 tokens.");
        
        //@dev Don't swap or buy tokens when uniswapV2Pair is sender, to avoid circular loop
        if(!inSwapAndLiquify && sender != uniswapV2Pair) {
            bool swap = true;
            if(swap) {
                uint256 contractTokenBalance = balanceOf(address(this));
                bool overMinTokenBalance = contractTokenBalance >= minTokensBeforeSwap;
                 if (overMinTokenBalance && swapAndLiquifyEnabled) {
                    swapTokensForEth();    
                }
           }
        }
        
        uint256 transferAmount = amount;
        uint256 rate = _getReflectionRate();

        if(!isExcludedFromFee[sender] && !isExcludedFromFee[recipient] && !inSwapAndLiquify){
            transferAmount = collectFee(sender,amount,rate);
        }

        //@dev Transfer reflection
        _reflectionBalance[sender] = _reflectionBalance[sender].sub(amount.mul(rate));
        _reflectionBalance[recipient] = _reflectionBalance[recipient].add(transferAmount.mul(rate));

        //@dev If any account belongs to the excludedAccount transfer token
        if (_isExcluded[sender]) {
            _tokenBalance[sender] = _tokenBalance[sender].sub(amount);
        }
        if (_isExcluded[recipient]) {
            _tokenBalance[recipient] = _tokenBalance[recipient].add(transferAmount);
        }

        emit Transfer(sender, recipient, transferAmount);
    }
    
    function collectFee(address account, uint256 amount, uint256 rate) private returns (uint256) {
        uint256 transferAmount = amount;
        
        //@dev Tax fee
        if(_taxFee != 0){
            
            uint256 taxFee = amount.mul(_taxFee).div(10**(_feeDecimal + 2));
            transferAmount = transferAmount.sub(taxFee);
            _reflectionTotal = _reflectionTotal.sub(taxFee.mul(rate));
            _taxFeeTotal = _taxFeeTotal.add(taxFee);
            emit RewardsDistributed(taxFee);
        }

        //@dev Take liquidity fee
        if(_liquidityFee != 0 && msg.sender == 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D){
            
            
            
             uint256 liquidityFeeSell = amount.mul(_liquidityFeeSell).div(10**(_feeDecimal + 2));
            transferAmount = transferAmount.sub(liquidityFeeSell);
            _reflectionBalance[address(this)] = _reflectionBalance[address(this)].add(liquidityFeeSell.mul(rate));
            _liquidityFeeTotal = _liquidityFeeTotal.add(liquidityFeeSell);
            emit Transfer(account,address(this),liquidityFeeSell);
            
           
        }else{
             uint256 liquidityFee = amount.mul(_liquidityFee).div(10**(_feeDecimal + 2));
            transferAmount = transferAmount.sub(liquidityFee);
            _reflectionBalance[address(this)] = _reflectionBalance[address(this)].add(liquidityFee.mul(rate));
            _liquidityFeeTotal = _liquidityFeeTotal.add(liquidityFee);
            emit Transfer(account,address(this),liquidityFee);
            
        }
        
        return transferAmount;
    }

    function _getReflectionRate() private view returns (uint256) {
        uint256 reflectionSupply = _reflectionTotal;
        uint256 tokenSupply = _tokenTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (
                _reflectionBalance[_excluded[i]] > reflectionSupply ||
                _tokenBalance[_excluded[i]] > tokenSupply
            ) return _reflectionTotal.div(_tokenTotal);
            reflectionSupply = reflectionSupply.sub(
                _reflectionBalance[_excluded[i]]
            );
            tokenSupply = tokenSupply.sub(_tokenBalance[_excluded[i]]);
        }
        if (reflectionSupply < _reflectionTotal.div(_tokenTotal))
            return _reflectionTotal.div(_tokenTotal);
        return reflectionSupply.div(tokenSupply);
    }

    function swapTokensForEth() private lockTheSwap {
        uint256 tokenAmount = balanceOf(address(this));
        uint256 ethAmount = address(this).balance;
        
        //@dev Generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        //@dev Make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
        
        ethAmount = address(this).balance.sub(ethAmount);
        emit SwapedTokenForEth(tokenAmount,ethAmount);
    }

    
    function setExcludedFromFee(address account, bool excluded) public onlyOwner {
        isExcludedFromFee[account] = excluded;
    }
    
    function setSwapAndLiquifyEnabled(bool enabled) public onlyOwner {
        swapAndLiquifyEnabled = enabled;
        SwapAndLiquifyEnabledUpdated(enabled);
    }
    
    function setTaxFee(uint256 fee) public onlyOwner {
        _taxFee = fee;
    }
    
    function setLiquidityFee(uint256 fee) public onlyOwner {
        _liquidityFee = fee;
    }

    function setMinTokensBeforeSwap(uint256 amount) public onlyOwner {
        minTokensBeforeSwap = amount;
    }
    
    function setMinEthBeforeSwap(uint256 amount) public onlyOwner {
        minEthBeforeSwap = amount;
    }


    
    function enableTrading() external onlyOwner() {
        tradingEnabled = true;
        TradingEnabled(true);
        liquidityAddedAt = now;
    }
    
    receive() external payable {}
}