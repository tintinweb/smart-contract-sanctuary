/**
 *Submitted for verification at BscScan.com on 2021-12-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IBEP20 {
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
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
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

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor (address initialOwner) {
        _owner = initialOwner;
        emit OwnershipTransferred(address(0), initialOwner);
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is still locked");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

interface IPancakeFactory {
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


interface IPancakeRouter01 {
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

interface IPancakeRouter02 is IPancakeRouter01 {
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


contract GekkoLLC is Context, IBEP20, Ownable {
    using SafeMath for uint256;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;

    mapping (address => bool) private _isExcludedFromReward;

    mapping (address => bool) private _isBlacklisted;

    mapping (address => bool) private _isExchange;

    mapping (address => bool) private _systemWallet;

    mapping (address => mapping (address => uint256)) private _allowances;

    address[] private _excluded;

    uint private saleStartBlock;

    string private     _name = "Gekko LLC";
    string private   _symbol = "Gekko";
    uint8 private  _decimals = 18;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 1000000000000 * 10 ** _decimals;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    uint256[3] private _sellFees = [5,4,6];
    uint256[3] private _buyFees = [2,1,3];

    bool public _sellFeesActive;
    bool public _buyFeesActive;

    uint256 public _taxFee;
    uint256 public _liqFee;
    uint256 public _teamFee;

    address private _burnWallet = 0x000000000000000000000000000000000000dEaD;

    address private _teamWallet = 0xC2f0938B13132002dF773Fe742cb867cc64EcD8D;

    address private _reserveWallet = 0xFE491075e832d571498d6170dA1EF33E656C8abf;

    uint256 private numTokensSellToAddToLiquidity = 1000000 * 10 **_decimals;

    bool public saleStarted;


    // auto liquidity

    IPancakeRouter02 public pancakeRouter;
    address            public pancakePair;
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
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

    constructor (address cOwner) Ownable(cOwner) {
        // initial token distribution
        _rOwned[_teamWallet] = _rTotal.div(20);
        _tOwned[_teamWallet] = tokenFromReflection(_rOwned[_teamWallet]);
        _rOwned[_reserveWallet] = _rTotal.div(10);
        _tOwned[_reserveWallet] = tokenFromReflection(_rOwned[_reserveWallet]);
        _rOwned[cOwner] = _rTotal.sub(_rOwned[_teamWallet]).sub(_rOwned[_reserveWallet]);
        _tOwned[cOwner] = tokenFromReflection(_rOwned[cOwner]);

        emit Transfer(address(0), _teamWallet, _tOwned[_teamWallet]);
        emit Transfer(address(0), _reserveWallet, _tOwned[_reserveWallet]);
        emit Transfer(address(0), cOwner, _tOwned[cOwner]);

        // uniswap

        //testnet
        //address routerAddress = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
        //mainnet
        address routerAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E;


        pancakeRouter = IPancakeRouter02(routerAddress);

        pancakePair = IPancakeFactory(pancakeRouter.factory()).createPair(
            address(this),
            pancakeRouter.WETH()
        );

        _isExchange[routerAddress] = true;
        _isExchange[pancakePair] = true;


        // exclude system contracts
        _systemWallet[address(this)] = true;
        _systemWallet[cOwner] = true;
        _systemWallet[_burnWallet] = true;
        _systemWallet[_teamWallet] = true;
        _systemWallet[_reserveWallet] = true;


        _isExcludedFromReward[address(this)] = true;
        _excluded.push(address(this));
        _isExcludedFromReward[_burnWallet] = true;
        _excluded.push(_burnWallet);
        _isExcludedFromReward[cOwner] = true;
        _excluded.push(cOwner);
        _isExcludedFromReward[pancakePair] = true;
        _excluded.push(pancakePair);

        _approve(address(this), routerAddress, _tTotal);
        _approve(cOwner, routerAddress, _tTotal);

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
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcludedFromReward[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }


    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcludedFromReward[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }


    function setSystemWallet(address account, bool _status) public onlyOwner {
        _systemWallet[account] = _status;

    }


    function excludeFromReward(address account) public onlyOwner {
        require(!_isExcludedFromReward[account], "Account is already excluded");

        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcludedFromReward[account] = true;
        _excluded.push(account);
    }


    function includeInReward(address account) external onlyOwner {
        require(_isExcludedFromReward[account], "Account is already excluded");

        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcludedFromReward[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    receive() external payable {}


    function addToExchanges(address account) external onlyOwner {
        require(!_isExchange[account], "Address already in list of exchanges");
        require(!_systemWallet[account], "System wallets cannot be added to exchange list.");
        _isExchange[account] = true;
        _isExcludedFromReward[account] = true;
        _excluded.push(account);
    }


    function removeFromExchanges(address account) external onlyOwner {
        require(_isExchange[account], "Address is not in a list of exchanges");
        require(!_systemWallet[account], "System wallets cannot be in exchange list.");
        _isExchange[account] = false;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcludedFromReward[account] = false;
                _excluded.pop();
                break;
            }
        }


    }


    function setMarketSellFee(uint256 _fee) external onlyOwner {
        _sellFees[2] = _fee;

    }


    function disableSellFees() external onlyOwner {
        _sellFeesActive = false;
    }

    function enableSellFees() external onlyOwner {
        _sellFeesActive = true;
    }

    function disableBuyFees() external onlyOwner {
        _buyFeesActive = false;
    }

    function enableBuyFees() external onlyOwner {
        _buyFeesActive = true;
    }

    function disableAllFees() external onlyOwner {
        _sellFeesActive = false;
        _buyFeesActive = false;

    }

    function enableAllFees() external onlyOwner {
        _sellFeesActive = true;
        _buyFeesActive = true;

    }


    function setMinAutoLiquidityAmount(uint256 _amount) external onlyOwner {
        require(_amount <= _tTotal, "Amount cannot exceed total token circulation.");
        require(_amount > 0, "Amount cannot have zero value");
        numTokensSellToAddToLiquidity = _amount;

    }

    function startSale() external onlyOwner {
        saleStarted = true;
        saleStartBlock = block.number;
        _sellFeesActive = true;
        _buyFeesActive = true;
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


    function calculateFee(uint256 _amount, uint256 _fee) private pure returns (uint256) {
        return _amount.mul(_fee).div(100);
    }


    function _getValues(uint256 tAmount) private view returns
        (uint256, uint256, uint256, uint256, uint256, uint256, uint256)
    {
        uint256 currentRate = _getRate();

        uint256[4] memory tvalues;
        uint256[5] memory rvalues;

        tvalues[0] = calculateFee(tAmount, _taxFee);
        tvalues[1] = calculateFee(tAmount, _liqFee);
        tvalues[2] = calculateFee(tAmount, _teamFee);
        tvalues[3] = tAmount.sub(tvalues[0].add(tvalues[1]).add(tvalues[2]));
        rvalues[0] = tvalues[0].mul(currentRate);
        rvalues[1] = tvalues[1].mul(currentRate);
        rvalues[2] = tvalues[2].mul(currentRate);
        rvalues[3] = tAmount.mul(currentRate);
        rvalues[4] = rvalues[3].sub(rvalues[0]).sub(rvalues[1]).sub(rvalues[2]);

        return (rvalues[3], rvalues[4], rvalues[0], tvalues[3], tvalues[0], tvalues[2], tvalues[1]);
    }


    function _takeLiquidity(uint256 tLiquidity, address account) private {
        uint256 currentRate =  _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);

        // liquidity to contract
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if (_isExcludedFromReward[address(this)]) {
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
        }
        emit Transfer(account, address(this), tLiquidity);

    }


    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal    = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }


    function _reflectTeam(uint256 tTeam, address account) private {
        uint256 currentRate =  _getRate();
        uint256 rTeam = tTeam.mul(currentRate);

        // liquidity to contract
        _rOwned[_teamWallet] = _rOwned[_teamWallet].add(rTeam);
        if (_isExcludedFromReward[_teamWallet]) {
            _tOwned[_teamWallet] = _tOwned[_teamWallet].add(tTeam);
        }

        emit Transfer(account, _teamWallet, tTeam);
    }


    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");

        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }


    function burn(uint256 amount) public onlyOwner returns (bool) {
        _transfer(owner(), _burnWallet, amount);
        return true;
    }


    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if (_isExchange[from] || _isExchange[to]) {
            if (_isExchange[from]) {
                require(saleStarted, "Sale is not started yet.");
                if (block.number <= saleStartBlock + 1 && !_systemWallet[to]) {
                    _isBlacklisted[to] = true;
                }
                if (_buyFeesActive) {
                    _taxFee = _buyFees[0];
                    _liqFee = _buyFees[1];
                    _teamFee = _buyFees[2];
                } else {
                    _taxFee = 0;
                    _liqFee = 0;
                    _teamFee = 0;

                }
            } else {
                require(!_isBlacklisted[from], "This address was blacklisted as a snipe bot");
                if (_sellFeesActive) {
                    _taxFee = _sellFees[0];
                    _liqFee = _sellFees[1];
                    _teamFee = _sellFees[2];
                } else {
                    _taxFee = 0;
                    _liqFee = 0;
                    _teamFee = 0;

                }

            }

            uint256 contractTokenBalance = balanceOf(address(this));

            bool isOverMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
            if (
                isOverMinTokenBalance &&
                !inSwapAndLiquify &&
                swapAndLiquifyEnabled
            ) {
                contractTokenBalance = numTokensSellToAddToLiquidity;
                swapAndLiquify(contractTokenBalance);
            }

        }  else {
            _taxFee = 0;
            _liqFee = 0;
            _teamFee = 0;
        }

        if (_systemWallet[from] || _systemWallet[to]) {
            _taxFee = 0;
            _liqFee = 0;
            _teamFee = 0;
        }

        if (_isExcludedFromReward[from] && !_isExcludedFromReward[to]) {
            _transferFromExcluded(from, to, amount);

        } else if (!_isExcludedFromReward[from] && _isExcludedFromReward[to]) {
            _transferToExcluded(from, to, amount);

        } else if (!_isExcludedFromReward[from] && !_isExcludedFromReward[to]) {
            _transferStandard(from, to, amount);

        } else if (_isExcludedFromReward[from] && _isExcludedFromReward[to]) {
            _transferBothExcluded(from, to, amount);

        } else {
            _transferStandard(from, to, amount);
        }

    }


    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee,
         uint256 tTransferAmount, uint256 tFee, uint256 tTeam, uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender]    = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        if (tLiquidity > 0) {
            _takeLiquidity(tLiquidity, sender);
        }

        if (tTeam > 0) {
            _reflectTeam(tTeam, sender);
        }

        if (tFee > 0) {
            _reflectFee(rFee, tFee);
        }

        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee,
         uint256 tTransferAmount, uint256 tFee, uint256 tTeam, uint256 tLiquidity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        if (tLiquidity > 0) {
            _takeLiquidity(tLiquidity, sender);
        }

        if (tTeam > 0) {
            _reflectTeam(tTeam, sender);
        }

        if (tFee > 0) {
            _reflectFee(rFee, tFee);
        }


        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee,
         uint256 tTransferAmount, uint256 tFee, uint256 tTeam, uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        if (tLiquidity > 0) {
            _takeLiquidity(tLiquidity, sender);
        }

        if (tTeam > 0) {
            _reflectTeam(tTeam, sender);
        }

        if (tFee > 0) {
            _reflectFee(rFee, tFee);
        }

        emit Transfer(sender, recipient, tTransferAmount);
    }


    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee,
         uint256 tTransferAmount, uint256 tFee, uint256 tTeam, uint256 tLiquidity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        if (tLiquidity > 0) {
            _takeLiquidity(tLiquidity, sender);
        }

        if (tTeam > 0) {
            _reflectTeam(tTeam, sender);
        }

        if (tFee > 0) {
            _reflectFee(rFee, tFee);
        }


        emit Transfer(sender, recipient, tTransferAmount);
    }


    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // split contract balance into halves
        uint256 half      = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        /*
            capture the contract's current BNB balance.
            this is so that we can capture exactly the amount of BNB that
            the swap creates, and not make the liquidity event include any BNB
            that has been manually sent to the contract.
        */
        uint256 initialBalance = address(this).balance;

        // swap tokens for BNB
        swapTokensForBnb(half);

        // this is the amount of BNB that we just swapped into
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForBnb(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeRouter.WETH();

        _approve(address(this), address(pancakeRouter), tokenAmount);

        // make the swap
        pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of BNB
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(pancakeRouter), tokenAmount);

        // add the liquidity
        pancakeRouter.addLiquidityETH{value: bnbAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }


}