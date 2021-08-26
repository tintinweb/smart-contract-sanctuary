/**
 *Submitted for verification at Etherscan.io on 2021-08-26
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity 0.6.12;


 
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


// File contracts/resources/Context.sol

pragma solidity 0.6.12;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}


// File contracts/resources/IERC20.sol

pragma solidity 0.6.12;

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


// File contracts/resources/IUniswapV2Router01.sol

pragma solidity 0.6.12;

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


// File contracts/resources/IUniswapV2Router02.sol

pragma solidity 0.6.12;

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


// File contracts/resources/IUniswapV2Factory.sol

pragma solidity 0.6.12;


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


// File contracts/resources/IToken.sol

pragma solidity ^0.6.12;

interface IToken {
    function mint(address _to, uint256 _amount) external;
    function mintAvailable() external view returns(bool);
    function pctPair() external view returns(address);
    function isMinter(address _addr) external view returns(bool);
    function addPresaleUser(address _account) external;
    function maxTxAmount() external view returns(uint256);
    function isExcludedFromFee(address _account) external view returns(bool);
    function isPresaleUser(address _account) external view returns(bool);
}

interface ITokenCallee {
    function transferCallee(address from, address to) external;
}


// File contracts/BabyDogeV3.sol

pragma solidity ^0.6.12;






contract SuperBabyDoge is Context, IERC20 {
    using SafeMath for uint256;

    address public vaultWallet;
    address public babyDogePair;
    IUniswapV2Router02 public router;

    uint256 public buyFee = 500; // 5%
    uint256 public transferFee = 1000; // 10%;
    uint256 public sellFee = 1000; // 10%

    uint256 public tokenHoldersPart = 5000; // 50%
    uint256 public lpPart = 4900; // 49%
    uint256 public burnPart = 0; // 0%
    uint256 public vaultPart = 100; // 1%

    uint256 public totalHoldersFee;
    uint256 public totalLpFee;
    uint256 public totalBurnFee;
    uint256 public totalVaultFee;

    uint256 public tokensSellToAddToLiquidityPercent = 10; //0.1%
    bool public swapAndLiquifyEnabled = true;

    address[] public callees;
    mapping(address => bool) private mapCallees;

    address[] public pairs;
    mapping(address => bool) private mapPairs;

    address private _owner;
    address private _burner;
    address private _minter;
    uint256 private constant FEEMAX = 10000;
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;
    address[] private _excluded;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 10**9 * 10**18;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _totalSupply;

    string private _name = "BabyDoge";
    string private _symbol = "BabyDoge";
    uint8 private _decimals = 9;

    bool private _inSwapAndLiquify;

    address private constant DEAD = 0x000000000000000000000000000000000000dEaD;

    mapping(address => bool) private _excludedFromAntiWhale;

    struct OneBlockTxInfo {
        uint256 blockNumber;
        uint256 accTxAmt;
    }

    mapping(address => OneBlockTxInfo) private _userOneBlockTxInfo; //anti flashloan

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    event TxFee(
        uint256 tFee,
        address from,
        address to
    );

    modifier onlyOwner()
    {
        require(msg.sender == _owner, "!owner");
        _;
    }

    modifier lockTheSwap {
        _inSwapAndLiquify = true;
        _;
        _inSwapAndLiquify = false;
    }

    constructor(address payable _routerAddr) public {
        _rOwned[address(0)] = _rTotal;
        _owner = msg.sender;
        vaultWallet = msg.sender;

        IUniswapV2Router02 _router = IUniswapV2Router02(_routerAddr);
        router = _router;
        IUniswapV2Factory _factory = IUniswapV2Factory(_router.factory());
        babyDogePair = _factory.createPair(address(this), _router.WETH());
        require(babyDogePair != address(0), "create baby doge pair false!");
        addPair(babyDogePair);
        excludeFromReward(DEAD);
        excludeFromReward(address(this));
        _isExcludedFromFee[_owner] = true;
        _isExcludedFromFee[address(this)] = true;
        _approve(address(this), address(_router), uint256(~0));

        _excludedFromAntiWhale[msg.sender] = true;
        _excludedFromAntiWhale[address(0)] = true;
        _excludedFromAntiWhale[address(this)] = true;
        _excludedFromAntiWhale[DEAD] = true;
    }


    modifier onlyBurner() {
        require((msg.sender == _burner || msg.sender == _owner), "Bridge: caller does not have the Burner role.");
        _;
    }

    modifier onlyMinter() {
        require((msg.sender == _minter || msg.sender == _owner), "Bridge: caller does not have the Minter role.");
        _;
    }

    function setRouterAddress(address routerAddress) public onlyOwner {
        IUniswapV2Router02 _router = IUniswapV2Router02(routerAddress);
        babyDogePair = IUniswapV2Factory(_router.factory())
            .createPair(address(this), _router.WETH());

        router = _router;
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
        return _totalSupply;
    }

    function maxSupply() public view returns(uint256) {
        return _tTotal;
    }

    function setOwner(address newOwner) public onlyOwner {
        require(newOwner != address(0), "newOwner is zero-address");
        require(newOwner != _owner, "newOwner is the same");
        _owner = newOwner;
    }

    function owner() public view returns(address) {
        return _owner;
    }

    function setVaultWallet(address account) external onlyOwner {
        require(account != address(0), "Vault wallet is zero-address");
        require(account != vaultWallet, "Vault wallet is the same");
        vaultWallet = account;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address from, address spender) public view override returns (uint256) {
        return _allowances[from][spender];
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

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function reflectionFromToken(uint256 tAmount, uint256 tType) public view returns(uint256) {
        require(tAmount <= maxSupply(), "Amount must be less than max supply");
        uint256 txFee = 0;
        if (tType == 0) {
            txFee = buyFee;
        } else if (tType == 1) {
            txFee = transferFee;
        } else if (tType == 2) {
            txFee = sellFee;
        }
        (,uint256 rTransferAmount,,,) = _getValues(tAmount, txFee);
        return rTransferAmount;
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner {
        require(_isExcluded[account], "Account is already included");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function setTxFee(uint256 _buyFee, uint256 _transferFee, uint256 _sellFee) external onlyOwner {
        require(_buyFee < FEEMAX, "buy fee must less than FEEMAX");
        require(_transferFee < FEEMAX, "transfer fee must less than FEEMAX");
        require(_sellFee < FEEMAX, "sell fee must less than FEEMAX");
        buyFee = _buyFee;
        transferFee = _transferFee;
        sellFee = _sellFee;
    }

    function setFeeParts(uint256 _tokenHoldersPart, uint256 _lpPart, uint256 _burnPart, uint256 _vaultPart) external onlyOwner {
      tokenHoldersPart = _tokenHoldersPart; // 40%
      lpPart = _lpPart; // 40%
      burnPart = _burnPart; // 10%
      vaultPart = _vaultPart; // 10%
    }

    function setTokensSellToAddToLiquidityPercent(uint256 percent) external onlyOwner {
        require(percent < FEEMAX, "percent must be less than FEEMAX");
        tokensSellToAddToLiquidityPercent = percent;
    }

    function setSwapAndLiquifyEnabled(bool enabled) public onlyOwner {
        swapAndLiquifyEnabled = enabled;
    }

    function numTokensSellToAddToLiquidity() public view returns(uint256) {
        return _totalSupply.mul(tokensSellToAddToLiquidityPercent).div(FEEMAX);
    }

    function isExcludedFromAntiWhale(address _account) public view returns (bool) {
        return _excludedFromAntiWhale[_account];
    }

    function setExcludedFromAntiWhale(address _account, bool _exclude) public onlyOwner {
        _excludedFromAntiWhale[_account] = _exclude;
    }

    function addMinter(address _account) public onlyOwner {
        _minter = _account;
    }

    function setBurner(address _account) public onlyOwner {
        _burner = _account;
    }

    function addPair(address pair) public onlyOwner {
        require(!isPair(pair), "Pair exist");
        require(pairs.length < 25, "Maximum 25 LP Pairs reached");
        mapPairs[pair] = true;
        pairs.push(pair);
        excludeFromReward(pair);
    }

    function isPair(address pair) public view returns (bool) {
        return mapPairs[pair];
    }

    function pairsLength() public view returns (uint256) {
        return pairs.length;
    }

    function addCallee(address callee) public onlyOwner {
        require(!isCallee(callee), "Callee exist");
        require(callees.length < 10, "Maximum 10 callees reached");
        mapCallees[callee] = true;
        callees.push(callee);
    }

    function removeCallee(address callee) public onlyOwner {
        require(isCallee(callee), "Callee not exist");
        mapCallees[callee] = false;
        for (uint256 i = 0; i < callees.length; i++) {
            if (callees[i] == callee) {
                callees[i] = callees[callees.length - 1];
                callees.pop();
                break;
            }
        }
    }

    function isCallee(address callee) public view returns (bool) {
        return mapCallees[callee];
    }

    function calleesLength() public view returns(uint256) {
        return callees.length;
    }

  function burn(address account, uint256 amount) public onlyBurner returns (bool){
        _totalSupply = _totalSupply.sub(amount);
        _transfer(account, DEAD, amount);
        return true;
    }

    function mint(address to, uint256 amount) public onlyMinter returns (bool){
        if (amount == 0) {
            return false;
        }

        uint256 supply = totalSupply();
        uint256 _maxSupply = maxSupply();
        if (supply >= _maxSupply) {
            return false;
        }

        uint256 temp = supply.add(amount);
        if (temp > _maxSupply) {
            amount = _maxSupply.sub(supply);
        }
        return _mint(to, amount);
    }

    function _mint(address account, uint256 amount) private returns (bool){
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply = _totalSupply.add(amount);

        (uint256 rAmount,,,,) = _getValues(amount, 0);
        _rOwned[address(0)] = _rOwned[address(0)].sub(rAmount);
        _rOwned[account] = _rOwned[account].add(rAmount);
        _tOwned[account] = _tOwned[account].add(amount);

        emit Transfer(address(0), account, amount);
        _transferCallee(address(0), account);
        return true;
    }

    function mintAvailable() public view returns(bool) {
        if (totalSupply() >= maxSupply()) {
            return false;
        }
        return true;
    }

    receive() external payable {}

    /**
     * @dev No timelock functions
     */
    function withdrawBNB() public payable onlyOwner {
        msg.sender.transfer(address(this).balance);
    }

    function withdrawBEP20(address _tokenAddress) public payable onlyOwner {
        uint256 tokenBal = IERC20(_tokenAddress).balanceOf(address(this));
        IERC20(_tokenAddress).transfer(msg.sender, tokenBal);
    }

    function _transferCallee(address from, address to) private {
        for (uint256 i = 0; i < callees.length; ++i) {
            address callee = callees[i];
            ITokenCallee(callee).transferCallee(from, to);
        }
    }

    function _calculateTxFee(uint256 amount, uint256 tFee) private pure returns (uint256) {
        return amount.mul(tFee).div(FEEMAX);
    }

    function _approve(address from, address spender, uint256 amount) private {
        require(from != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[from][spender] = amount;
        emit Approval(from, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        uint256 bal = balanceOf(from);
        if (amount > bal) {
            amount = bal;
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        if (isExcludedFromAntiWhale(from) == false && isExcludedFromAntiWhale(to) == false) {
            OneBlockTxInfo storage info = _userOneBlockTxInfo[from];
            if (info.blockNumber != block.number) {
                info.blockNumber = block.number;
                info.accTxAmt = amount;
            } else {
                info.accTxAmt = info.accTxAmt.add(amount);
            }
        }

        uint256 _numTokensSellToAddToLiquidity = numTokensSellToAddToLiquidity();
        bool overMinTokenBalance = contractTokenBalance >= _numTokensSellToAddToLiquidity;
        if (
            overMinTokenBalance &&
            !_inSwapAndLiquify &&
            from != babyDogePair &&
            swapAndLiquifyEnabled
        ) {
            contractTokenBalance = _numTokensSellToAddToLiquidity;
            _swapAndLiquify(contractTokenBalance);
        }

        uint256 tFee = transferFee;
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            tFee = 0;
        } else {
            if (from == msg.sender && isPair(from)) {// buying
                tFee = buyFee;
            } else if (isPair(to)) {// selling
                tFee = sellFee;
            }
        }
        emit TxFee(tFee, from, to);
        _tokenTransfer(from,to,amount,tFee);
    }

    function _swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        uint256 initialBalance = address(this).balance;

        _swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        uint256 newBalance = address(this).balance.sub(initialBalance);

        _addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function _swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    function _getValues(uint256 tAmount, uint256 tFee) private view returns (uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFeeAmount) = _getTValues(tAmount, tFee);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount) = _getRValues(tAmount, tFeeAmount, currentRate);
        return (rAmount, rTransferAmount, tTransferAmount, tFeeAmount, currentRate);
    }

    function _getTValues(uint256 tAmount, uint256 tFee) private pure returns (uint256, uint256) {
        uint256 tFeeAmount = _calculateTxFee(tAmount, tFee);
        uint256 tTransferAmount = tAmount.sub(tFeeAmount);
        return (tTransferAmount, tFeeAmount);
    }

    function _getRValues(uint256 tAmount, uint256 tFeeAmount, uint256 currentRate) private pure returns (uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFeeAmount = tFeeAmount.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFeeAmount);
        return (rAmount, rTransferAmount);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount, uint256 tFee) private {
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount, tFee);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount, tFee);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount, tFee);
        } else {
            _transferStandard(sender, recipient, amount, tFee);
        }
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount, uint256 tFee) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 tTransferAmount, uint256 tFeeAmount, uint256 currentRate) = _getValues(tAmount, tFee);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeTxFee(currentRate, tFeeAmount);
        emit Transfer(sender, recipient, tTransferAmount);
        _transferCallee(sender, recipient);
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount, uint256 tFee) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 tTransferAmount, uint256 tFeeAmount, uint256 currentRate) = _getValues(tAmount, tFee);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeTxFee(currentRate, tFeeAmount);
        emit Transfer(sender, recipient, tTransferAmount);
        _transferCallee(sender, recipient);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount, uint256 tFee) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 tTransferAmount, uint256 tFeeAmount, uint256 currentRate) = _getValues(tAmount, tFee);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeTxFee(currentRate, tFeeAmount);
        emit Transfer(sender, recipient, tTransferAmount);
        _transferCallee(sender, recipient);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount, uint256 tFee) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 tTransferAmount, uint256 tFeeAmount, uint256 currentRate) = _getValues(tAmount, tFee);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeTxFee(currentRate, tFeeAmount);
        emit Transfer(sender, recipient, tTransferAmount);
        _transferCallee(sender, recipient);
    }

    function _takeTxFee(uint256 currentRate, uint256 tFeeAmount) private {
        if (tFeeAmount == 0) return;

        uint256 holdersFee = tFeeAmount.mul(tokenHoldersPart).div(FEEMAX);
        uint256 rHolderFee = holdersFee.mul(currentRate);
        totalHoldersFee = totalHoldersFee.add(holdersFee);
        _rTotal = _rTotal.sub(rHolderFee);

        uint256 lpFee = tFeeAmount.mul(lpPart).div(FEEMAX);
        uint256 rLpFee = lpFee.mul(currentRate);
        totalLpFee = totalLpFee.add(lpFee);
        _transferFeeTo(address(this), rLpFee, lpFee);
        _transferCallee(address(0), address(this));

        uint256 burnFee = tFeeAmount.mul(burnPart).div(FEEMAX);
        uint256 rBurnFee = burnFee.mul(currentRate);
        totalBurnFee = totalBurnFee.add(burnFee);
        _transferFeeTo(DEAD, rBurnFee, burnFee);
        _transferCallee(address(0), DEAD);

        uint256 vaultFee = tFeeAmount.sub(holdersFee).sub(lpFee).sub(burnFee);
        uint256 rVaultFee = vaultFee.mul(currentRate);
        totalVaultFee = totalVaultFee.add(vaultFee);
        _transferFeeTo(vaultWallet, rVaultFee, vaultFee);
    }

    function _transferFeeTo(address to, uint256 rAmount, uint256 tAmount) private {
        _rOwned[to] = _rOwned[to].add(rAmount);
        if(_isExcluded[to])
            _tOwned[to] = _tOwned[to].add(tAmount);
    }
}