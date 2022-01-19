/**
 *Submitted for verification at Etherscan.io on 2022-01-19
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.6.12;

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = now + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(now > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function WETH() external pure returns (address);
    function factory() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

contract ThreeOh is Ownable {
    using SafeMath for uint256;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => uint256) public _firstBuyTime;
    mapping (address => uint256) public _presaleBalance;
    mapping (address => uint256) public _presaleLiquidated;
    mapping (address => bool) private _isSniper;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;

    address[] private _excluded;

    address payable public dev;
    address payable public advocacy;
    address public _burnPool = 0x0000000000000000000000000000000000000000;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 21 * 10**11 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private _name = "ThreeOh DAO";
    string private _symbol = "3OH";
    uint8 private _decimals = 9;

    uint256 public _taxFee = 100;
    uint256 public _advocacyFee = 800;
    uint256 public _developmentFee = 100;
    uint256 public _dayTraderMultiplicator = 25;
    bool public transfersEnabled; //once enabled, transfers cannot be disabled

    uint256 private launchBlock;
    uint256 private launchTime;
    uint256 private blocksLimit;

    uint256 public _pendingDevelopmentFees;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public uniswapV2Pair;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;

    uint256 public _maxWalletHolding = 34 * 10**9 * 10**9;
    uint256 private numTokensSellToAddToLiquidity = 2 * 10**9 * 10**9;

    uint256 public _marketingDevAllocation = 50 * 10**9 * 10**9;
    uint256 public _burnAllocation = 400 * 10**9 * 10**9;
    uint256 public _exchangeAllocation = 850 * 10**9 * 10**9;

    uint256 public _periodLiquidationLength = 7 days;

    event SwapAndLiquifyEnabledUpdated(bool enabled);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor (address payable _devWallet, address payable _advocacyWallet, address _marketingDevWallet, address _exchangeWallet) public {
      dev = _devWallet;
      advocacy = _advocacyWallet;

      IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
      uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
      uniswapV2Router = _uniswapV2Router;

      _isExcludedFromFee[owner()] = true;
      _isExcludedFromFee[address(this)] = true;
      _isExcludedFromFee[_burnPool] = true;
      _isExcludedFromFee[_advocacyWallet] = true;
      _isExcludedFromFee[_marketingDevWallet] = true;
      _isExcludedFromFee[_exchangeWallet] = true;

      _isExcluded[_burnPool] = true;
      _excluded.push(_burnPool);

      _isExcluded[uniswapV2Pair] = true;
      _excluded.push(uniswapV2Pair);

      _isExcluded[address(this)] = true;
      _excluded.push(address(this));

      uint256 currentRate =  _getRate();
      _rOwned[_burnPool] = _burnAllocation.mul(currentRate);
      _tOwned[_burnPool] = _burnAllocation;

      currentRate = _getRate();
      _rOwned[_marketingDevWallet] = _marketingDevAllocation.mul(currentRate);
      _rOwned[_exchangeWallet] = _exchangeAllocation.mul(currentRate);

      _rOwned[_msgSender()] = _rTotal - _rOwned[_marketingDevWallet] - _rOwned[_exchangeWallet] - _rOwned[_burnPool];

      emit Transfer(address(0), _msgSender(), _tTotal);
      emit Transfer(_msgSender(), _marketingDevWallet, _marketingDevAllocation);
      emit Transfer(_msgSender(), _exchangeWallet, _exchangeAllocation);
      emit Transfer(_msgSender(), _burnPool, _burnAllocation);
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

    function totalSupply() public view returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        else return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
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
        return _tFeeTotal;
    }

    function airdrop(address payable [] memory holders, uint256 [] memory balances) public onlyOwner() {
      require(holders.length == balances.length, "Incorrect input");
      uint256 deployer_balance = _rOwned[_msgSender()];
      uint256 currentRate =  _getRate();

      for (uint8 i = 0; i < holders.length; i++) {
        uint256 balance = balances[i] * 10 ** 15;
        uint256 new_r_owned = currentRate.mul(balance);
        _rOwned[holders[i]] = _rOwned[holders[i]] + new_r_owned;
        _presaleBalance[holders[i]] = _presaleBalance[holders[i]] + balance;
        emit Transfer(_msgSender(), holders[i], balance);
        deployer_balance = deployer_balance.sub(new_r_owned);
      }
      _rOwned[_msgSender()] = deployer_balance;
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function manualSwapAndLiquify() public onlyOwner() {
        uint256 contractTokenBalance = balanceOf(address(this));
        swapAndLiquify(contractTokenBalance);
    }

    function excludeFromReward(address account) public onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is not excluded");
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

    function setTax(uint256 _taxType, uint _taxSize) external onlyOwner() {
      if (_taxType == 1) {
        _taxFee = _taxSize;
        require(_taxFee <= 100);
      }
      else if (_taxType == 2) {
        _developmentFee = _taxSize;
        require(_developmentFee <= 200);
      }
      else if (_taxType == 3) {
        _advocacyFee = _taxSize;
        require(_advocacyFee <= 900);
      }
      else if (_taxType == 4) {
        _dayTraderMultiplicator = _taxSize;
      }
    }

    function setSwapAndLiquifyEnabled(bool _enabled, uint256 _numTokensMin) public onlyOwner() {
        swapAndLiquifyEnabled = _enabled;
        numTokensSellToAddToLiquidity = _numTokensMin;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function enableTransfers(uint256 _blocksLimit) public onlyOwner() {
        transfersEnabled = true;
        launchBlock = block.number;
        launchTime = block.timestamp;
        blocksLimit = _blocksLimit;
    }

    function setSniperEnabled(bool _enabled, address sniper) public onlyOwner() {
        _isSniper[sniper] = _enabled;
    }

    receive() external payable {}

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
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

    function _takeOperations(uint256 tAmount, uint256 feeType) private returns (uint256) {
        uint256 currentRate =  _getRate();
        uint256 tTransferAmount = tAmount;
        uint256 taxMultiplicator = 10;

        if (feeType == 2) taxMultiplicator = _dayTraderMultiplicator;

        uint256 tFee = calculateFee(tAmount, _taxFee, taxMultiplicator);
        uint256 tAdvocacy = calculateFee(tAmount, _advocacyFee, taxMultiplicator);
        uint256 tDevelopment = calculateFee(tAmount, _developmentFee, taxMultiplicator);

        _pendingDevelopmentFees = _pendingDevelopmentFees.add(tDevelopment);

        tTransferAmount = tAmount - tFee - tAdvocacy - tDevelopment;
        uint256 tTaxes = tAdvocacy.add(tDevelopment);

        _reflectFee(tFee.mul(currentRate), tFee);

        _rOwned[address(this)] = _rOwned[address(this)].add(tTaxes.mul(currentRate));
        _tOwned[address(this)] = _tOwned[address(this)].add(tTaxes);

        return tTransferAmount;
    }

    function calculateFee(uint256 _amount, uint256 _taxRate, uint256 _taxMultiplicator) private pure returns (uint256) {
        return _amount.mul(_taxRate).div(10**4).mul(_taxMultiplicator).div(10);
    }

    function isExcludedFromFee(address account) public view returns (bool) {
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

        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;

        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            from != uniswapV2Pair &&
            swapAndLiquifyEnabled
        ) {
            swapAndLiquify(contractTokenBalance);
        }

        if (_firstBuyTime[to] == 0) _firstBuyTime[to] = block.timestamp;

        //indicates if fee should be deducted from transfer
        uint256 feeType = 1;

        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            feeType = 0;
        }
        else {
          require(transfersEnabled, "Transfers are not enabled now");
          if (to == uniswapV2Pair || (to != uniswapV2Pair && from != uniswapV2Pair)) {
            require(!_isSniper[from], "SNIPER!");
            if (to != uniswapV2Pair && from != uniswapV2Pair) {
              feeType = 0;
            }
            if (_presaleBalance[from] > 0) {
              uint256 maxLiquidation = (block.timestamp - launchTime).div(_periodLiquidationLength) + 1;
              if (maxLiquidation <= 4) {
                maxLiquidation = maxLiquidation.mul(_presaleBalance[from]).div(4);
                require((_presaleLiquidated[from] + amount) < maxLiquidation, "Presale vesting exceeded");
              }
              _presaleLiquidated[from] = _presaleLiquidated[from] + amount;
              if (_firstBuyTime[from] == 0) _firstBuyTime[from] = launchTime;
            }
            if (_firstBuyTime[from] != 0 && (_firstBuyTime[from] + (24 hours) > block.timestamp) ) {
              feeType = 2;
            }
          }
          if (from == uniswapV2Pair) {
            if (block.number <= (launchBlock + blocksLimit)) _isSniper[to] = true;
          }
        }

        _tokenTransfer(from, to, amount, feeType);

        if (!_isExcludedFromFee[to] && (to != uniswapV2Pair)) require(balanceOf(to) < _maxWalletHolding, "Max Wallet holding limit exceeded");
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(contractTokenBalance);
        uint256 newBalance = address(this).balance.sub(initialBalance);
        uint256 payDevelopment = _pendingDevelopmentFees.mul(newBalance).div(contractTokenBalance);
        if (payDevelopment <= address(this).balance) dev.call{ value: payDevelopment }("");
        if (address(this).balance > 0) advocacy.call{ value: address(this).balance }("");
        _pendingDevelopmentFees = 0;
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

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount, uint256 feeType) private {
        uint256 currentRate =  _getRate();
        uint256 tTransferAmount = amount;
        if (feeType != 0) {
          tTransferAmount = _takeOperations(amount, feeType);
        }
        uint256 rTransferAmount = tTransferAmount.mul(currentRate);
        uint256 rAmount = amount.mul(currentRate);
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, rAmount, amount, tTransferAmount, rTransferAmount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, rAmount, amount, tTransferAmount, rTransferAmount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, rAmount, amount, tTransferAmount, rTransferAmount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, rAmount, amount, tTransferAmount, rTransferAmount);
        } else {
            _transferStandard(sender, recipient, rAmount, amount, tTransferAmount, rTransferAmount);
        }
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferStandard(address sender, address recipient, uint256 rAmount, uint256 tAmount, uint256 tTransferAmount, uint256 rTransferAmount) private {
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 rAmount, uint256 tAmount, uint256 tTransferAmount, uint256 rTransferAmount) private {
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 rAmount, uint256 tAmount, uint256 tTransferAmount, uint256 rTransferAmount) private {
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 rAmount, uint256 tAmount, uint256 tTransferAmount, uint256 rTransferAmount) private {
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
    }

}