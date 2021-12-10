/**
 *Submitted for verification at BscScan.com on 2021-12-09
*/

/**
 *Submitted for verification at BscScan.com on 2021-12-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal virtual view returns (address payable) {
        return payable(msg.sender);
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
    
    function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
    uint256 c = add(a,m);
    uint256 d = sub(c,1);
    return mul(div(d,m),m);
  }
}

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor()  {
     //   address msgSender = _msgSender();
        _owner = 0xe307F969bE971EC2e94d8AfacD6f942F8f208c68;
        emit OwnershipTransferred(address(0), _owner);
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

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
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

contract BSCMETA is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    string private _name = "BMETA";
    string private _symbol = "BMT";
    uint8 private _decimals = 9;

    mapping(address => uint256) internal _reflectionBalance;
    mapping(address => uint256) internal _balanceLimit;
    mapping(address => uint256) internal _tokenBalance;
    
    mapping (address => bool) public _blackList;
    mapping (address=> bool) public _maxAmount;
    mapping (address => bool) public _maxWallet;
    mapping(address => mapping(address => uint256)) internal _allowances;
    

    uint256 private constant MAX = ~uint256(0);
    uint256 internal _tokenTotal = 10_000_000_000e9;
    uint256 internal _reflectionTotal = (MAX - (MAX % _tokenTotal));

    mapping(address => bool) isTaxless;
    mapping(address => bool) internal _isExcluded;
    address[] internal _excluded;
    
    uint256 public _feeDecimal = 2;

    //Buy fee

    uint256 public _buyTaxFee = 100; 
    uint256 public _buyRandDFee= 200;
    uint256 public _buyBuybackFee= 200;
    uint256 public _buyLiquidityFee = 100;
    uint256 public _buyAridropFee = 100;

    //Sell fee
    uint256 public _sellTaxFee = 200; 
    uint256 public _sellRandDFee= 300;
    uint256 public _sellBuybackFee= 300;
    uint256 public _sellLiquidityFee = 200;
    uint256 public _sellAridropFee = 200;

    //transfer fee
    
    uint256 public _transferBuybackFee= 200;
    uint256 public _transferLiquidityFee = 200;
    uint256 public _transferAridropFee = 200;

    

    address arghWallet=0xA9569205446753430e63aA1f66DC23a6AcC7313D;
    address buyBackWallet=0x49178033BcEA78AF34224992F8048bC6dEeDeb57;
    address lpWallet=0x21bb980aa1F179A8E5646494189e24b8207b5A94;
    address airDropWallet=0xeE1325d9eec32C04d1964987964EC21111e899a7;
    
    
    uint256 public _taxFeeTotal;

    bool public isFeeActive = true; // should be true
    bool private inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    bool private tradingEnable = true;
    
    uint256 public maxTxAmount = _tokenTotal; // 
    uint256 public _maxWalletToken =_tokenTotal;
    uint256 public minTokensBeforeSwap = 100_000e9;
  
    IUniswapV2Router02 public  uniswapV2Router;
    address public  uniswapV2Pair;

    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(uint256 tokensSwapped,uint256 ethReceived, uint256 tokensIntoLiqudity);



    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    

    constructor()  {

        //0x10ED43C718714eb63d5aA57B78B54704E256024E pancake v2 router address
        //0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D uniswap v2 router address
        //0xD99D1c33F9fC3444f8101754aBC46c52416550D1 pancake v2 router testnet address
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;


        //Exempt Tax From ONwer and contract
        isTaxless[owner()] = true;
        isTaxless[address(this)] = true;
        

        //Exempt maxTxAmount from Onwer and Contract
        _maxAmount[owner()] = true;
        _maxAmount[address(this)] = true;

        //Exempt maxWallet 
        _maxWallet[owner()] = true;
        _maxWallet[address(this)] = true;


        // exlcude pair address from tax rewards
        _isExcluded[address(uniswapV2Pair)] = true;
        _excluded.push(address(uniswapV2Pair));
        _isExcluded[address(0)]=true;
        _excluded.push(address(0));

        _reflectionBalance[owner()] = _reflectionTotal;

        emit Transfer(address(0),owner(), _tokenTotal);
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
                tokenAmount.sub(tokenAmount.mul(_buyTaxFee).div(10** _feeDecimal + 2)).mul(
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
            account != address(uniswapV2Router),
            "ERC20: We can not exclude Uniswap router."
        );
        require(!_isExcluded[account], "ERC20: Account is already excluded");
        if (_reflectionBalance[account] > 0) {
            _tokenBalance[account] = tokenFromReflection(
                _reflectionBalance[account]
            );
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeAccount(address account) external onlyOwner() {
        require(_isExcluded[account], "ERC20: Account is already included");
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
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!_blackList[sender] ,"Address is blackListed");
        require(amount <= maxTxAmount || _maxAmount[sender],"MaxTxAmount is disabled or Transfer Limit Exceeds");
        require(tradingEnable,"trading is disable");
        
            
        uint256 transferAmount = amount;
        uint256 rate = _getReflectionRate();
        
       if(sender != uniswapV2Pair && recipient != uniswapV2Pair){

        if(!isTaxless[sender] && !isTaxless[recipient] && !inSwapAndLiquify){
            transferAmount = _TransferCollectFee(sender,amount,rate);
        }
        //transfer reflection
        _reflectionBalance[sender] = _reflectionBalance[sender].sub(amount.mul(rate));
        _reflectionBalance[recipient] = _reflectionBalance[recipient].add(transferAmount.mul(rate));

        //if any account belongs to the excludedAccount transfer token
        if (_isExcluded[sender]) {
            _tokenBalance[sender] = _tokenBalance[sender].sub(amount);
        }
        if (_isExcluded[recipient]) {
            _tokenBalance[recipient] = _tokenBalance[recipient].add(transferAmount);
        }
        emit Transfer(sender, recipient, transferAmount);

        return;
        }

        if(sender == uniswapV2Pair) {
            
         if(!_maxWallet[recipient] && recipient != address(this)  && recipient != address(0) && recipient != owner()){
            uint256 heldTokens = balanceOf(recipient);
            require((heldTokens + amount) <= _maxWalletToken,"Total Holding is currently limited, you can not buy that much.");
            }

            
         if(!isTaxless[sender] && !isTaxless[recipient] && !inSwapAndLiquify){
            transferAmount = _buyCollectFee(sender,amount,rate);
         }
        
        //transfer reflection
        _reflectionBalance[sender] = _reflectionBalance[sender].sub(amount.mul(rate));
        _reflectionBalance[recipient] = _reflectionBalance[recipient].add(transferAmount.mul(rate));

        //if any account belongs to the excludedAccount transfer token
         if (_isExcluded[sender]) {
            _tokenBalance[sender] = _tokenBalance[sender].sub(amount);
         }
        if (_isExcluded[recipient]) {
            _tokenBalance[recipient] = _tokenBalance[recipient].add(transferAmount);
         }

        emit Transfer(sender, recipient, transferAmount);
        
        return;
       }
       
       //Sell side
       if(recipient == uniswapV2Pair){

        uint256 constractBal=balanceOf(buyBackWallet);
        bool overMinTokenBalance = constractBal >= minTokensBeforeSwap;
        
        if(!inSwapAndLiquify && overMinTokenBalance && swapAndLiquifyEnabled) {
            
            _reflectionBalance[buyBackWallet] = _reflectionBalance[buyBackWallet].sub(constractBal.mul(rate));
            _reflectionBalance[address(this)] = _reflectionBalance[address(this)].add(constractBal.mul(rate));

            swapAndLiquify(constractBal);
        }

         if(!isTaxless[sender] && !isTaxless[recipient] && !inSwapAndLiquify){
            transferAmount = _SellCollectFee(sender,amount,rate);
         }
        
        //transfer reflection
        _reflectionBalance[sender] = _reflectionBalance[sender].sub(amount.mul(rate));
        _reflectionBalance[recipient] = _reflectionBalance[recipient].add(transferAmount.mul(rate));

        //if any account belongs to the excludedAccount transfer token
        if (_isExcluded[sender]) {
            _tokenBalance[sender] = _tokenBalance[sender].sub(amount);
        }
        if (_isExcluded[recipient]) {
            _tokenBalance[recipient] = _tokenBalance[recipient].add(transferAmount);
        }

        emit Transfer(sender, recipient, transferAmount);
        
        return;

       }
       
        
    }
    
    function _buyCollectFee(address account, uint256 amount, uint256 rate) private returns (uint256) {
        uint256 transferAmount = amount;
        
        if(_buyTaxFee != 0){
            uint256 taxFee = amount.mul(_buyTaxFee).div(10**(_feeDecimal + 2));
            transferAmount = transferAmount.sub(taxFee);
            _reflectionTotal = _reflectionTotal.sub(taxFee.mul(rate));
            _taxFeeTotal = _taxFeeTotal.add(taxFee);
        }
        
        if(_buyBuybackFee != 0){
            uint256 marketingFee = amount.mul(_buyBuybackFee).div(10**(_feeDecimal + 2));
            transferAmount = transferAmount.sub(marketingFee);
            _reflectionBalance[buyBackWallet] = _reflectionBalance[buyBackWallet].add(marketingFee.mul(rate));
            if(_isExcluded[buyBackWallet]){
                _tokenBalance[buyBackWallet] = _tokenBalance[buyBackWallet].add(marketingFee);
            }
            emit Transfer(account,buyBackWallet,marketingFee);
        }
        
        if(_buyAridropFee != 0){
            uint256 devFee = amount.mul(_buyAridropFee).div(10**(_feeDecimal + 2));
            transferAmount = transferAmount.sub(devFee);
            _reflectionBalance[airDropWallet] = _reflectionBalance[airDropWallet].add(devFee.mul(rate));
            if(_isExcluded[airDropWallet]){
                _tokenBalance[airDropWallet] = _tokenBalance[airDropWallet].add(devFee);
            }
            emit Transfer(account,airDropWallet,devFee);
        }

        if(_buyLiquidityFee != 0){
            uint256 devFee = amount.mul(_buyLiquidityFee).div(10**(_feeDecimal + 2));
            transferAmount = transferAmount.sub(devFee);
            _reflectionBalance[lpWallet] = _reflectionBalance[lpWallet].add(devFee.mul(rate));
            if(_isExcluded[lpWallet]){
                _tokenBalance[lpWallet] = _tokenBalance[lpWallet].add(devFee);
            }
            emit Transfer(account,lpWallet,devFee);
        }

        if(_buyRandDFee != 0){
            uint256 devFee = amount.mul(_buyRandDFee).div(10**(_feeDecimal + 2));
            transferAmount = transferAmount.sub(devFee);
            _reflectionBalance[arghWallet] = _reflectionBalance[arghWallet].add(devFee.mul(rate));
            if(_isExcluded[arghWallet]){
                _tokenBalance[arghWallet] = _tokenBalance[arghWallet].add(devFee);
            }
            emit Transfer(account,arghWallet,devFee);
        }
        
    
        return transferAmount;
    }


    function _SellCollectFee(address account, uint256 amount, uint256 rate) private returns (uint256) {
        uint256 transferAmount = amount;
        
        if(_sellTaxFee != 0){
            uint256 taxFee = amount.mul(_sellTaxFee).div(10**(_feeDecimal + 2));
            transferAmount = transferAmount.sub(taxFee);
            _reflectionTotal = _reflectionTotal.sub(taxFee.mul(rate));
            _taxFeeTotal = _taxFeeTotal.add(taxFee);
        }
        
        if(_sellBuybackFee != 0){
            uint256 marketingFee = amount.mul(_sellBuybackFee).div(10**(_feeDecimal + 2));
            transferAmount = transferAmount.sub(marketingFee);
            _reflectionBalance[buyBackWallet] = _reflectionBalance[buyBackWallet].add(marketingFee.mul(rate));
            if(_isExcluded[buyBackWallet]){
                _tokenBalance[buyBackWallet] = _tokenBalance[buyBackWallet].add(marketingFee);
            }
            emit Transfer(account,buyBackWallet,marketingFee);
        }
        
        if(_sellAridropFee != 0){
            uint256 devFee = amount.mul(_sellAridropFee).div(10**(_feeDecimal + 2));
            transferAmount = transferAmount.sub(devFee);
            _reflectionBalance[airDropWallet] = _reflectionBalance[airDropWallet].add(devFee.mul(rate));
            if(_isExcluded[airDropWallet]){
                _tokenBalance[airDropWallet] = _tokenBalance[airDropWallet].add(devFee);
            }
            emit Transfer(account,airDropWallet,devFee);
        }

        if(_sellLiquidityFee != 0){
            uint256 devFee = amount.mul(_sellLiquidityFee).div(10**(_feeDecimal + 2));
            transferAmount = transferAmount.sub(devFee);
            _reflectionBalance[lpWallet] = _reflectionBalance[lpWallet].add(devFee.mul(rate));
            if(_isExcluded[lpWallet]){
                _tokenBalance[lpWallet] = _tokenBalance[lpWallet].add(devFee);
            }
            emit Transfer(account,lpWallet,devFee);
        }

        if(_sellRandDFee != 0){
            uint256 devFee = amount.mul(_sellRandDFee).div(10**(_feeDecimal + 2));
            transferAmount = transferAmount.sub(devFee);
            _reflectionBalance[arghWallet] = _reflectionBalance[arghWallet].add(devFee.mul(rate));
            if(_isExcluded[arghWallet]){
                _tokenBalance[arghWallet] = _tokenBalance[arghWallet].add(devFee);
            }
            emit Transfer(account,arghWallet,devFee);
        }
        
    
        return transferAmount;
    }

     function _TransferCollectFee(address account, uint256 amount, uint256 rate) private returns (uint256) {
        uint256 transferAmount = amount;
      
           
        if(_transferAridropFee != 0){
            uint256 devFee = amount.mul(_transferAridropFee).div(10**(_feeDecimal + 2));
            transferAmount = transferAmount.sub(devFee);
            _reflectionBalance[airDropWallet] = _reflectionBalance[airDropWallet].add(devFee.mul(rate));
            if(_isExcluded[airDropWallet]){
                _tokenBalance[airDropWallet] = _tokenBalance[airDropWallet].add(devFee);
            }
            emit Transfer(account,airDropWallet,devFee);
        }

        if(_transferLiquidityFee != 0){
            uint256 devFee = amount.mul(_transferLiquidityFee).div(10**(_feeDecimal + 2));
            transferAmount = transferAmount.sub(devFee);
            _reflectionBalance[lpWallet] = _reflectionBalance[lpWallet].add(devFee.mul(rate));
            if(_isExcluded[lpWallet]){
                _tokenBalance[lpWallet] = _tokenBalance[lpWallet].add(devFee);
            }
            emit Transfer(account,lpWallet,devFee);
        }

        if(_transferBuybackFee != 0){
            uint256 devFee = amount.mul(_transferBuybackFee).div(10**(_feeDecimal + 2));
            transferAmount = transferAmount.sub(devFee);
            _reflectionBalance[buyBackWallet] = _reflectionBalance[buyBackWallet].add(devFee.mul(rate));
            if(_isExcluded[buyBackWallet]){
                _tokenBalance[buyBackWallet] = _tokenBalance[buyBackWallet].add(devFee);
            }
            emit Transfer(account,buyBackWallet,devFee);
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
    
    
    
    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
      
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(contractTokenBalance); 
        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);
         
        payable(buyBackWallet).transfer(newBalance);
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
            address(this),
            block.timestamp
        );
    }

    function setTransferFee(uint256 buybackFee,uint256 airDropFee,uint256 liquidityFee) external onlyOwner {
        _transferLiquidityFee=liquidityFee;
        _transferAridropFee=airDropFee;
        _transferBuybackFee=buybackFee;
    }

    function setSellFee(uint256 buybackFee,uint256 airDropFee,uint256 liquidityFee,uint256 RandDFee,uint256 taxFee) external onlyOwner {
        _sellLiquidityFee=liquidityFee;
        _sellAridropFee=airDropFee;
        _sellBuybackFee=buybackFee;
        _sellTaxFee=taxFee;
        _sellRandDFee=RandDFee;
    }

    function setBuyFee(uint256 buybackFee,uint256 airDropFee,uint256 liquidityFee,uint256 RandDFee,uint256 taxFee) external onlyOwner {
        _buyLiquidityFee=liquidityFee;
        _buyAridropFee=airDropFee;
        _buyBuybackFee=buybackFee;
        _buyTaxFee=taxFee;
        _buyRandDFee=RandDFee;
    }

    function setAddresses(address _arghWallet,address _buyBackWallet,address _airDropWallet,address _lpWallet) external onlyOwner {
        arghWallet = _arghWallet;
        buyBackWallet = _buyBackWallet;
        airDropWallet = _airDropWallet;
        lpWallet = _lpWallet;
    }
    
    function setPair(address pair) external onlyOwner {
        uniswapV2Pair = pair;
    }

    function setTaxless(address account, bool value) external onlyOwner {
        isTaxless[account] = value;
    }
    
    function setFeeActive(bool value) external onlyOwner {
        isFeeActive = value;
    }
    
    function setBlackList (address _address,bool value) external onlyOwner {
        _blackList[_address]=value;
    }
    
    function exemptMaxTxAmountAddress(address _address,bool value) external onlyOwner {
        _maxAmount[_address] = value;
    }

    function exemptMaxWalletAmountAddress(address _address,bool value) external onlyOwner {
        _maxWallet[_address] =value;
    }
    
    function setTrading(bool value) external onlyOwner {
        tradingEnable= value;
    }
    
    function setMaxTxAmount(uint256 amount) external  onlyOwner {
        maxTxAmount = amount;
    }

    function setMaxWalletAmount(uint256 amount) external onlyOwner {
        _maxWalletToken = amount;
    }
 
    
    function setSwapAndLiquifyEnabled(bool enabled) external onlyOwner {
        swapAndLiquifyEnabled = enabled;
        emit SwapAndLiquifyEnabledUpdated(enabled);
    }
    
    function setMinTokensBeforeSwap(uint256 amount) external  onlyOwner {
        minTokensBeforeSwap = amount;
    }

    receive() external payable {}
}