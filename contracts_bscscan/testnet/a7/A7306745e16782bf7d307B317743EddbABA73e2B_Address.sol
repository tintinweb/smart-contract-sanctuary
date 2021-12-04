/**
 *Submitted for verification at BscScan.com on 2021-12-03
*/

//=============================[X-BIT&Coin]=============================//

pragma solidity ^0.6.12;
// SPDX-License-Identifier: MIT

abstract contract Context {
    function _msgSender() internal virtual view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal virtual view returns (bytes memory) {
        this;
        return msg.data;
    }
}

//=============================[X-BIT&Coin]=============================//

interface IERC20  {
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

//=============================[X-BIT&Coin]=============================//

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

//=============================[X-BIT&Coin]=============================//

library Address {

    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;

            bytes32 accountHash
         = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470; // Hash padrao de biblioteca
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

        (bool success, bytes memory returndata) = target.call{value: weiValue}(
            data
        );
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {

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

//=============================[X-BIT&Coin]=============================//

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
        
    );

    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
        
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

//=============================[X-BIT&Coin]=============================//

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

//=============================[X-BIT&Coin]=============================//

contract XBIT is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    string private _name = "X-Bit & Coin"; // Nome da moeda
    string private _symbol = "XBIT"; // Simbolo da moeda
    
    uint8 private _decimals = 18; // Casas decimais para 1 bloco

    mapping(address => uint256) internal _reflectionBalance;
    mapping(address => uint256) internal _tokenBalance;
    mapping(address => mapping(address => uint256)) internal _allowances;

    uint256 private constant MAX = ~uint256(0);
    uint256 internal _tokenTotal = 600000000e18; // 600 Milhões e18 decimais.
    uint256 internal _reflectionTotal = (MAX - (MAX % _tokenTotal));

    mapping(address => bool) isTaxless; 
    mapping(address => bool) internal _isExcluded; 
    address[] internal _excluded;

//=============================[X-BIT&Coin]=============================//
    
    // Definição de taxas por casa decimal sendo 1%=100 /2%=200/3%=300 /4%=400/ 5%=500
    uint256 public _taxaDecimal = 2;
    
    // holders %
    uint256 public _holderFee = 0;
    uint256 public _holderFeeTotal;
    
    // liquidez %
    uint256 public _liquidityFee = 600;
    uint256 public _liquidityFeeTotal;

    // queima %
    uint256 public _burnFee = 0;
    uint256 public _burnFeeTotal;
    
    // devWallet %
    uint256 public _devFee = 200;
    uint256 public _devFeeTotal;

    // marketWallet %
    uint256 public _marketFee = 200;
    uint256 public _marketFeeTotal;
    
    // identificação de carteiras publicas
    address public devWallet;
    address public marketWallet;
    address public burnAccount;
    
    bool public isTaxActive = true;
    bool private inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    
    uint256 public maxTxAmount = _tokenTotal; // Limita compra e venda da moeda "sistema anti-despejo".
    uint256 public minTokensBeforeSwap = 7500000e18; // Reserva o montante para adicionar a liquidez.
    
    IUniswapV2Router02 public  uniswapV2Router;
    address public  uniswapV2Pair;

    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    
//=============================[X-BIT&Coin]=============================//

    constructor() public {
        
        // Endereço de roteamento padrão da PancakeSwap
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F);
        //IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x6725F303b657a9451d8BA641348b6761A6CC7a17);

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        
        // Carteira publica dos desenvolvedores.
        devWallet = 0x16f080E983998d88B39EA2Ac14dB77B3dDC14a12;
        
        // Carteira publica comercial.
        marketWallet = 0xDbCf76B9B76904969226Ff59641E29a1E43ca79F;
        
        // Conta de queima padrão ou endereço de gravação.
        burnAccount = 0x000000000000000000000000000000000000dEaD;
        
        isTaxless[_msgSender()] = true;
        isTaxless[address(this)] = true;

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
               
        _approve(sender,_msgSender(),_allowances[sender][_msgSender()].sub( amount,"X-Bit&Coin: transfer amount exceeds allowance"));
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
                "X-Bit&Coin: decreased allowance below zero"
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
                tokenAmount.sub(tokenAmount.mul(_holderFee).div(10** _taxaDecimal + 2)).mul(
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
            "X-Bit&Coin: We can not exclude Uniswap router."
        );
        require(!_isExcluded[account], "X-Bit&Coin: Account is already excluded");
        if (_reflectionBalance[account] > 0) {
            _tokenBalance[account] = tokenFromReflection(
                _reflectionBalance[account]
            );
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeAccount(address account) external onlyOwner() {
        require(_isExcluded[account], "X-Bit&Coin: Account is already included");
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
        require(owner != address(0), "X-Bit&Coin: approve from the zero address");
        require(spender != address(0), "X-Bit&Coin: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(sender != address(0), "X-Bit&Coin: transfer from the zero address");
        require(recipient != address(0), "X-Bit&Coin: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        
        require(amount <= maxTxAmount, "Transfer Limit exceeded!");
        
        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinTokenBalance = contractTokenBalance >= minTokensBeforeSwap;
        if (!inSwapAndLiquify && overMinTokenBalance && sender != uniswapV2Pair && swapAndLiquifyEnabled) {
            swapAndLiquify(contractTokenBalance);
        }

        uint256 transferAmount = amount;
        uint256 rate = _getReflectionRate();

        if(isTaxActive && !isTaxless[_msgSender()] && !isTaxless[recipient] && !inSwapAndLiquify){
            transferAmount = collectFee(sender,amount,rate);
        }

        _reflectionBalance[sender] = _reflectionBalance[sender].sub(amount.mul(rate));
        _reflectionBalance[recipient] = _reflectionBalance[recipient].add(transferAmount.mul(rate));

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
        
        if(_holderFee != 0){
            uint256 holderFee = amount.mul(_holderFee).div(10**(_taxaDecimal + 2));
            transferAmount = transferAmount.sub(holderFee);
            _reflectionTotal = _reflectionTotal.sub(holderFee.mul(rate));
            _holderFeeTotal = _holderFeeTotal.add(holderFee);
        }
    
        if(_liquidityFee != 0){
            uint256 liquidityFee = amount.mul(_liquidityFee).div(10**(_taxaDecimal + 2));
            transferAmount = transferAmount.sub(liquidityFee);
            _reflectionBalance[address(this)] = _reflectionBalance[address(this)].add(liquidityFee.mul(rate));
            if(_isExcluded[address(this)]){
                _tokenBalance[address(this)] = _tokenBalance[address(this)].add(liquidityFee);
            }
            _liquidityFeeTotal = _liquidityFeeTotal.add(liquidityFee);
            emit Transfer(account,address(this),liquidityFee);
        }
    
        if(_burnFee != 0){
            uint256 burnFee = amount.mul(_burnFee).div(10**(_taxaDecimal + 2));
            transferAmount = transferAmount.sub(burnFee);
            _reflectionBalance[burnAccount] = _reflectionBalance[burnAccount].add(burnFee.mul(rate));
            if (_isExcluded[burnAccount]) {
                _tokenBalance[burnAccount] = _tokenBalance[burnAccount].add(burnFee);
            }
            _burnFeeTotal = _burnFeeTotal.add(burnFee);
            emit Transfer(account,burnAccount,burnFee);
        }
        
        if(_marketFee != 0){
            uint256 marketFee = amount.mul(_marketFee).div(10**(_taxaDecimal + 2));
            transferAmount = transferAmount.sub(marketFee);
            _reflectionBalance[marketWallet] = _reflectionBalance[marketWallet].add(marketFee.mul(rate));
            if (_isExcluded[marketWallet]) {
                _tokenBalance[marketWallet] = _tokenBalance[marketWallet].add(marketFee);
            }
            _marketFeeTotal = _marketFeeTotal.add(marketFee);
            emit Transfer(account,marketWallet,marketFee);
        }
    
        if(_devFee != 0){
            uint256 devFee = amount.mul(_devFee).div(10**(_taxaDecimal + 2));
            transferAmount = transferAmount.sub(devFee);
            _reflectionBalance[devWallet] = _reflectionBalance[devWallet].add(devFee.mul(rate));
            if (_isExcluded[devWallet]) {
                _tokenBalance[devWallet] = _tokenBalance[devWallet].add(devFee);
            }
            _devFeeTotal = _devFeeTotal.add(devFee);
            emit Transfer(account,devWallet,devFee);
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
         if(contractTokenBalance > maxTxAmount)
            contractTokenBalance = maxTxAmount;
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);


        uint256 initialBalance = address(this).balance;

        swapTokensForEth(half); 

        uint256 newBalance = address(this).balance.sub(initialBalance);

        addLiquidity(otherHalf, newBalance);
        
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, 
            path,
            address(this),
            block.timestamp
        );
    }
    
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, 
            0, 
            address(this),
            block.timestamp
        );
    }

    function setPair(address pair) external onlyOwner {
        uniswapV2Pair = pair;
    }
    
    function setdevWallet(address account) external onlyOwner {
        devWallet = account;
    }
    function setmarketWalet(address account) external onlyOwner {
        marketWallet = account;
    }
    function setTaxless(address account, bool value) external onlyOwner {
        isTaxless[account] = value;
    }
    
    function setSwapAndLiquifyEnabled(bool enabled) external onlyOwner {
        swapAndLiquifyEnabled = enabled;
        emit SwapAndLiquifyEnabledUpdated(enabled);
    }
    
    function setTaxActive(bool value) external onlyOwner {
        isTaxActive = value;
    }
    
    function setholderFee(uint256 fee) external onlyOwner {
        _holderFee = fee;
    }
    
    function setBurnFee(uint256 fee) external onlyOwner {
        _burnFee = fee;
    }
    
    function setLiquidityFee(uint256 fee) external onlyOwner {
        _liquidityFee = fee;
    }
 
    function setdevFee(uint256 fee) external onlyOwner {
        _devFee = fee;
    }
    function setmarketFee(uint256 fee) external onlyOwner {
        _marketFee = fee;
    }
    function setMaxTxAmount(uint256 amount) external onlyOwner {
        maxTxAmount = amount;
    }

    function setMinTokensBeforeSwap(uint256 amount) external onlyOwner {
        minTokensBeforeSwap = amount;
    }
    function destroyTokens (uint256 amount) external onlyOwner {
        _tokenTotal -= amount;
    }
    receive() external payable {}
}