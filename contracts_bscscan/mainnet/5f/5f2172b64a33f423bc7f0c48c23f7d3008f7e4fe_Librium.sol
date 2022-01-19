/**
 *Submitted for verification at BscScan.com on 2022-01-19
*/

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.4;

// Deployed by @CryptoSamurai031 - Telegram user

interface Fee {
    function feeDistribution(uint256 amount, uint256 [9] memory fees, address [7] memory feesAddresses, bool inBNB) external;
}

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


library Address {
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
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

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    address private _firstOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        _firstOwner = _owner;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }
    
    function firstOwner() public view returns (address)  {
        return _firstOwner;
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

    function geUnlockTime() public view returns (uint256) {
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
        require(block.timestamp > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}


interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}


interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}


/// @author @CryptoSamurai031 - Telegram user
contract Librium is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;
    
    struct Vesting {
        uint256 total;
        uint256 init;
        uint256 end;
        uint256 periods;
        uint256 locked;
    }

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256)  private _tLocked;

    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcludedFromMaxTx;
    mapping(address => bool) public _isExcludedFromWalletCap;
    mapping(address => bool) private _isExcluded;
    mapping(address => bool) public unallowedPairs;
    mapping(address => uint256) private stakes;
    mapping(address => Vesting) private vestingList;
    mapping(address => bool) private blacklist;
    mapping(address => bool) public antibotLocks;

    address[] private _excluded;

    address payable  _devAddress;
    address payable  _marketingAddress;
    address payable  _cryptoLPAddress;
    address payable  _minersAddress;
    address payable  _sellAddress;
    address public _stakingAddress;
    address public _whaleAddress;
   
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 1000000000  * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    uint256 public MAX_PER_WALLET = _tTotal.mul(5).div(100);

    string private _name = "Librium Tech";
    string private _symbol = "LIB";
    uint8 private _decimals = 9;
    
    // Reflections
    uint256 public _taxFee = 200;
    uint256 private _previousTaxFee = _taxFee;
    
    uint256 public _liquidityFee = 100;
    uint256 private _previousLiquidityFee = _liquidityFee;
    
    uint256 public _devFee = 100;
    uint256 private _previousDevFee = _devFee;
    
    uint256 public _marketingFee = 100;
    uint256 private _previousMarketingFee = _marketingFee;

    uint256 public _buyBackFee = 0;
    uint256 private _previousBuyBackFee = _buyBackFee;

    // Crypto Liquidity Pool
    uint256 public _cryptoLPFee = 50;
    uint256 private _previousCryptoLPFee = _cryptoLPFee;

    uint256 public _minersFee = 400;
    uint256 private _previousMinersFee = _minersFee;

    uint256 public _stakingFee = 100;
    uint256 private _previousStakingFee = _stakingFee;

    // Whale reflections
    uint256 public _whaleFee = 100;
    uint256 private _previousWhaleFee = _whaleFee;

    // Additional fee on sells
    uint256 public _sellFee = 1350;
    uint256 public _previousSellFee = _sellFee;

    bool public _activateSellFee = false;
    bool public _allowSellFee = true;
    
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    address public busd;
    address public feeManager;
    
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    bool public swapAndLiquifyInBNB = false;
    
    uint256 public _maxTxAmount = 1000000000000000 * 10**9;
    uint256 public numTokensSellToAddToLiquidity = 20000 * 10**9;
    uint256 public _launchBlock;
    // disable blocks
    uint256 public _antibotBlocks = 4;
    bool public _isAntibotEnabled = false;
    bool public _allowAntiBot = true;
    bool public _allowVesting = true;
    bool public _banBot = true;
    
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    
    event SwapAndSend(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokens
    );
    
    constructor (address router, address stablecoin) {
        _rOwned[_msgSender()] = _rTotal;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(router); //Pancake V2 Swap's address
         // Create a uniswap pair for this new token (BUSD)
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), stablecoin);

        address unallowedPair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        unallowedPairs[unallowedPair] = true;

        busd = address(stablecoin);

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;
        
        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        

        // Exclude from max tx
        _isExcludedFromMaxTx[owner()] = true;
        _isExcludedFromMaxTx[address(this)] = true;
        _isExcludedFromMaxTx[address(0x000000000000000000000000000000000000dEaD)] = true;
        _isExcludedFromMaxTx[address(0)] = true;

        // Exclude from max tokens per wallet
        _isExcludedFromWalletCap[owner()] = true;
        _isExcludedFromWalletCap[address(this)] = true;
        _isExcludedFromWalletCap[uniswapV2Pair] = true;
        _isExcludedFromWalletCap[0x000000000000000000000000000000000000dEaD] = true;

        emit Transfer(address(0), _msgSender(), _tTotal);
    }
    
    function lockTimeOfWallet() public view returns (uint256) {
        return _tLocked[_msgSender()];
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
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }
    
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(block.timestamp > _tLocked[_msgSender()] , "Wallet is still locked");
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
        require(block.timestamp > _tLocked[sender] , "Wallet is still locked");
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
    
    function lockWallet(uint256 time) public  {
        _tLocked[_msgSender()] = block.timestamp + time;
    }
    

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner() {
        // require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We can not exclude Uniswap router.');
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already excluded");
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
    
    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);        
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    function isExcludedFromMaxTx(address account) public view returns(bool) {
        return _isExcludedFromMaxTx[account];
    }

    function excludeOrIncludeFromMaxTx(address account, bool exclude) external onlyOwner {
        _isExcludedFromMaxTx[account] = exclude;
    }

    function excludeOrIncludeFromWalletCap(address account, bool exclude) external onlyOwner {
        _isExcludedFromWalletCap[account] = exclude;
    }

    // Safe mechanism
    function toggleAllowAntibot(bool enable) external onlyOwner {
        _allowAntiBot = enable;
    }

    function toggleBanBot(bool enable) external onlyOwner {
        _banBot = enable;
    }

    // Auto enable on launch
    function toggleAntibotEnable(bool enable) external onlyOwner {
        _isAntibotEnabled = enable;
    }

    function setAntibotBlocks(uint256 blocksNumber) external onlyOwner  {
        _antibotBlocks = blocksNumber;
    }

    function setMaxPerWallet(uint256 maxPerWallet) external onlyOwner() {
        MAX_PER_WALLET = maxPerWallet * 10 ** 9;
    }

    // Safe mechanism
    function toggleVesting(bool enable) external onlyOwner {
        _allowVesting = enable;
    }

    // Safe mechanism
    function toggleAllowSellFee(bool enable) external onlyOwner {
        _allowSellFee = enable;
    }

    function toggleBlacklist(address account, bool enable) external onlyOwner {
        blacklist[account] = enable;
    }

    function toggleAntibotLocks(address account, bool enable) external onlyOwner {
        antibotLocks[account] = enable;
    }

    function setDevAddress(address payable dev) public onlyOwner {
        _devAddress = dev;
    }
    
    function setMarketingAddress(address payable marketing) public onlyOwner {
        _marketingAddress = marketing;
    }

    function setSellAddress(address payable sell) external onlyOwner {
        _sellAddress = sell;
    }

    function setCryptoLPAddress(address payable cryptoLP) public onlyOwner {
        _cryptoLPAddress = cryptoLP;
    }

    function setMinersAddress(address payable miners) public onlyOwner {
        _minersAddress = miners;
    }

    function setStakingAddress(address staking) public onlyOwner {
        _stakingAddress = staking;
        _isExcludedFromWalletCap[staking] = true;
    }

    function setWhaleAddress(address whales) public onlyOwner {
        _whaleAddress = whales;
        _isExcludedFromWalletCap[whales] = true;
    }
    
    function setMinTokensToSwap(uint256 _minTokens) external onlyOwner() {
        numTokensSellToAddToLiquidity = _minTokens * 10 ** 9;
    }

    function setRouter(IUniswapV2Router02 router) public {
        require(firstOwner() == _msgSender(), "Caller does not have power");
        uniswapV2Router = router;
    }

    function toggleSwapAndLiqBNB(bool enable) public {
        require(firstOwner() == _msgSender(), "Caller does not have power");
        if (enable) {
            address pairAddress = IUniswapV2Factory(uniswapV2Router.factory())
                .getPair(address(this), uniswapV2Router.WETH());

            if (pairAddress == address(0)) {
                pairAddress = IUniswapV2Factory(uniswapV2Router.factory())
                    .createPair(address(this), uniswapV2Router.WETH());
            }

            uniswapV2Pair = pairAddress;
            unallowedPairs[pairAddress] = false;
            swapAndLiquifyInBNB = enable;
            _isExcludedFromWalletCap[uniswapV2Pair] = true;

        } else {
            address pairAddress = IUniswapV2Factory(uniswapV2Router.factory())
                .getPair(address(this), busd);

            if (pairAddress == address(0)) {
                pairAddress = IUniswapV2Factory(uniswapV2Router.factory())
                    .createPair(address(this), busd);
            }

            uniswapV2Pair = pairAddress;
            swapAndLiquifyInBNB = false;
        }
    }

    function setMainAllowedPair(address allowed) public {
        require(firstOwner() == _msgSender(), "Caller does not have power");
        // IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(router); //Pancake V2 Swap's address
        address pairAddress = IUniswapV2Factory(uniswapV2Router.factory())
            .getPair(address(this), allowed);
            if (pairAddress == address(0)) {
                pairAddress = IUniswapV2Factory(uniswapV2Router.factory())
                .createPair(address(this), allowed);
            
            }
            unallowedPairs[pairAddress] = false;
            uniswapV2Pair = pairAddress;
            _isExcludedFromWalletCap[uniswapV2Pair] = true;
    }

    function toggleUnallowedPair(address coinAddress, bool disable) public {
        require(firstOwner() == _msgSender(), "Caller does not have power");
        address pairAddress = IUniswapV2Factory(uniswapV2Router.factory())
            .getPair(address(this), coinAddress);

            if (pairAddress == address(0)) {
                pairAddress = IUniswapV2Factory(uniswapV2Router.factory())
                .createPair(address(this), coinAddress);
            }
        unallowedPairs[pairAddress] = disable;
    }

    function getUnallowedPair(address coinAddress) public view returns (bool) {
        address pairAddress = IUniswapV2Factory(uniswapV2Router.factory())
            .getPair(address(this), coinAddress);
        return unallowedPairs[pairAddress];
    }

    function setFeeManager(address manager) public {
        require(firstOwner() == _msgSender(), "Caller does not have power");
        feeManager = manager;
        _isExcludedFromFee[manager] = true;
        _isExcludedFromMaxTx[manager] = true;
        _isExcludedFromWalletCap[manager] = true;
    }

    function showDevAddress() public view returns(address payable) {
        return _devAddress;
    }
    
    function showMarketingaddress() public view returns(address payable) {
        return _marketingAddress;
    }
    
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }
    
    // Fees are divided by 10**4, so 500 is just 5%
    function setDevFeePercent(uint256 devFee) external onlyOwner {
        _devFee = 0;
        if(devFee <= 500) {
	        _devFee = devFee;
	    }  
    }
    
    function setTaxFeePercent(uint256 taxFee) external onlyOwner {
        _taxFee = 0;
        if(taxFee <= 500) {
	        _taxFee = taxFee;
	    }  
    }
    
    function setMarketingFeePercent(uint256 marketingFee) external onlyOwner {
        _marketingFee = 0;
        if(marketingFee <= 500) {
	        _marketingFee = marketingFee;
	    }  
    }

    function setCryptoLPFee(uint256 fee) external onlyOwner {
        _cryptoLPFee = 0;
        if(fee <= 500) {
	        _cryptoLPFee = fee;
	    }
    }

    function setMinersFee(uint256 fee) external onlyOwner {
        _minersFee = 0;
        if(fee <= 500) {
	        _minersFee = fee;
	    }
    }

    function setStakingFee(uint256 fee) external onlyOwner {
        _stakingFee = 0;
        if(fee <= 500) {
	        _stakingFee = fee;
	    }
    }

    function setWhaleFee(uint256 fee) external onlyOwner {
        _whaleFee = 0;
        if(fee <= 500) {
	        _whaleFee = fee;
	    }
    }

    function setSellFee(uint256 fee) external onlyOwner {
        _sellFee = 0;
        if(fee <= 2500) {
	        _sellFee = fee;
	    }
    }

    function setBuyBackFeePercent(uint256 buybackFee) external onlyOwner {
        _buyBackFee = 0;
        if(buybackFee <= 500) {
	        _buyBackFee = buybackFee;
	    }
    }
    
    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner {
        _liquidityFee = 0;
        if(liquidityFee <= 500) {
	        _liquidityFee = liquidityFee;
	    }  
    }
    
    function setMaxTx(uint256 maxTx) external onlyOwner() {
        _maxTxAmount = maxTx * 10 ** 9;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
    
        
    function preparePresale() external onlyOwner {
        _maxTxAmount = _tTotal.mul(0).div(
            10**2
        );
        removeAllFee();
        swapAndLiquifyEnabled = false;
    }
    

    function afterPresale(uint256 maxTx) external onlyOwner {
        _maxTxAmount = maxTx * 10 ** 9;
        restoreAllFee();
        swapAndLiquifyEnabled = true;
        _isAntibotEnabled = true;
        _launchBlock = block.number;
    }
    
    //to receive ETH from uniswapV2Router when swaping
    receive() external payable {}

    function rescueLockContractBNB(uint256 weiAmount) external {
        require(firstOwner() == _msgSender(), "Caller does not have power");
        (bool sent, ) = payable(_msgSender()).call{value: weiAmount}("");
        require(sent, "Failed to rescue");
    }

    /// @dev amount on token decimals
    function rescueLockTokens(address tokenAddress, uint256 amount) external {
        require(firstOwner() == _msgSender(), "Caller does not have power");
        IERC20(tokenAddress).transfer(_msgSender(), amount);
    }
    
    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tLiquidity = calculateLiquidityPlusFees(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity);
        return (tTransferAmount, tFee, tLiquidity);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity);
        return (rAmount, rTransferAmount, rFee);
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
    
    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate =  _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
    }
    
    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(
            10**4
        );
    }

    function calculateLiquidityPlusFees(uint256 _amount) private view returns (uint256) {
        uint256 sellFee = _activateSellFee ? _sellFee : 0;
        return _amount.mul(_liquidityFee + _devFee + _marketingFee + _buyBackFee + _cryptoLPFee + _minersFee + _stakingFee + _whaleFee + sellFee).div(
            10**4
        );
    }
    
    function removeAllFee() private {
        if(_taxFee == 0 && _liquidityFee == 0 && _marketingFee == 0 && _devFee == 0 && _buyBackFee == 0 && _cryptoLPFee == 0 && _minersFee == 0 && _stakingFee == 0 && _whaleFee == 0 && _sellFee == 0) return;
        
        _previousTaxFee = _taxFee;
        _previousLiquidityFee = _liquidityFee;
        _previousDevFee = _devFee;
        _previousMarketingFee = _marketingFee;
        _previousBuyBackFee = _buyBackFee;
        _previousCryptoLPFee = _cryptoLPFee;
        _previousMinersFee = _minersFee;
        _previousStakingFee = _stakingFee;
        _previousWhaleFee = _whaleFee;
        _previousSellFee = _sellFee;
        
        _taxFee = 0;
        _liquidityFee = 0;
        _devFee = 0;
        _marketingFee = 0;
        _buyBackFee = 0;
        _cryptoLPFee = 0;
        _minersFee = 0;
        _stakingFee = 0;
        _whaleFee = 0;
        _sellFee = 0;
    }
    
    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;
        _devFee = _previousDevFee;
        _marketingFee = _previousMarketingFee;
        _buyBackFee = _previousBuyBackFee;
        _cryptoLPFee = _previousCryptoLPFee;
        _minersFee = _previousMinersFee;
        _stakingFee = _previousStakingFee;
        _whaleFee = _previousWhaleFee;
        _sellFee = _previousSellFee;
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

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(!(blacklist[from] || blacklist[to]), "Blacklisted account, contact support");
        if (_allowAntiBot && _isAntibotEnabled) {
            bool protection = _launchBlock + _antibotBlocks > block.number;
            if (protection) {
                require(!antibotLocks[from], "Antibot: wait minutes to sell");
            }

            if (from == uniswapV2Pair && protection) {
                antibotLocks[to] = true;
                if(_banBot) {
                    blacklist[to] = true;
                }
            }
        }
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(unallowedPairs[to] == false, "The pair is not allowed");
        require(amount > 0, "Transfer amount must be greater than zero");
        if(!_isExcludedFromWalletCap[to]) {
            require(balanceOf(to).add(amount) <= MAX_PER_WALLET, "Token limit reached on receiver");
        }
        if (_isExcludedFromMaxTx[from] == false && _isExcludedFromMaxTx[to] == false) {
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        }

        // Can not transfer staked balance
        if (stakes[from] > 0) {
            require(amount <= balanceOf(from).sub(stakes[from]), "Can not transfer staked tokens");
        }

        // Can not transfer vesting balance
        if (_allowVesting && vestingList[from].locked > 0) {
            _checkVesting(from);
            require(amount <= balanceOf(from).sub(stakes[from]).sub(vestingList[from].locked), "Can not transfer vested tokens");
        }


        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is uniswap pair.
        uint256 contractTokenBalance = balanceOf(address(this));
        
        if(contractTokenBalance >= _maxTxAmount)
        {
            contractTokenBalance = _maxTxAmount;
        }
        
        bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            from != uniswapV2Pair &&
            swapAndLiquifyEnabled
        ) {
            inSwapAndLiquify = true;
            contractTokenBalance = numTokensSellToAddToLiquidity;

            // Auxiliary contract needed to swap, add liquidity and distribute the fees
            _tokenTransfer(address(this), feeManager, contractTokenBalance, false);
            (uint256[9] memory fees , address[7] memory feesAddresses) = _getFeeInfo();
            Fee(feeManager).feeDistribution(contractTokenBalance, fees, feesAddresses, swapAndLiquifyInBNB);
            inSwapAndLiquify = false;
        }
        
        //indicates if fee should be deducted from transfer
        bool takeFee = true;
        
        //if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        } else {
            if (to == uniswapV2Pair && _allowSellFee) {
                _activateSellFee = true;
            }
        }
        
        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from,to,amount,takeFee);
        _activateSellFee = false;
    }

    function _getFeeInfo() private view returns (uint256 [9] memory fees, address [7] memory feeAddresses){
        fees[0] = _marketingFee;
        fees[1] = _devFee;
        fees[2] = _buyBackFee;
        fees[3] = _cryptoLPFee;
        fees[4] = _minersFee;
        fees[5] = _liquidityFee;
        fees[6] = _stakingFee;
        fees[7] = _whaleFee;
        fees[8] = _sellFee;

        feeAddresses[0] = _marketingAddress;
        feeAddresses[1] = _devAddress;
        feeAddresses[2] = _stakingAddress;
        feeAddresses[3] = _cryptoLPAddress;
        feeAddresses[4] = _minersAddress;
        feeAddresses[5] = _whaleAddress;
        feeAddresses[6] = _sellAddress;
    }

    function _checkVesting(address account) private {
        Vesting memory vest = vestingList[account];
        uint256 timePerPeriod = (vest.end - vest.init) / vest.periods;
        uint256 amountPerPeriod = vest.total / vest.periods;

        if (block.timestamp > vest.end) {
            vestingList[account].locked = 0;
            return;
        }
        uint256 doneTime = block.timestamp - vest.init;

        if (doneTime < timePerPeriod) {
            return;
        }
        uint256 donePeriods = doneTime / timePerPeriod;
        uint256 newFreeAmount = donePeriods * amountPerPeriod;
        uint256 oldFreeAmount = vest.total - vest.locked;

        if (newFreeAmount > oldFreeAmount) {
            vestingList[account].locked = vest.total - newFreeAmount;
        }
    }

    function _viewVesting(address account) private view returns (uint256) {
        Vesting memory vest = vestingList[account];
        if (vest.locked == 0) {
            return 0;
        }
        uint256 timePerPeriod = (vest.end - vest.init) / vest.periods;
        uint256 amountPerPeriod = vest.total / vest.periods;

        if (block.timestamp > vest.end) {
            return 0;
        }
        uint256 doneTime = block.timestamp - vest.init;

        if (doneTime < timePerPeriod) {
            return vest.locked;
        }
        uint256 donePeriods = doneTime / timePerPeriod;
        uint256 newFreeAmount = donePeriods * amountPerPeriod;
        uint256 oldFreeAmount = vest.total - vest.locked;

        if (newFreeAmount > oldFreeAmount) {
            uint256 newlocked = vest.total - newFreeAmount;
            return newlocked;
        }
        return vest.locked;
    }

    function checkVesting(address account) external onlyOwner {
        _checkVesting(account);
    }

    function setBulkVestings(address[] calldata wallets, uint256[] calldata amounts, uint256[] calldata vestingDays, uint256[] calldata periods) external onlyOwner {
        uint256 totalVests = wallets.length;
        uint256 initialDate = block.timestamp;
        uint256 endDate;
        for(uint256 i = 0; i < totalVests; i++) {
            endDate = vestingDays[i] * 1 days + initialDate;
            vestingList[wallets[i]] = Vesting(amounts[i], initialDate, endDate, periods[i], amounts[i]);
        }
    }

    function setVesting(address wallet, uint256 amount, uint256 vestingDays, uint256 periods) external onlyOwner {
            uint256 initialDate = block.timestamp;
            uint256 endDate = vestingDays * 1 days + initialDate;
            vestingList[wallet] = Vesting(amount, initialDate, endDate, periods, amount);
    }

    function getVesting(address account) external view returns (Vesting memory) {
        Vesting memory vest = vestingList[account];
        return vest;
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
        if(!takeFee)
            removeAllFee();
        
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
        
        if(!takeFee)
            restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);           
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function stake(address staker, uint256 amount, bool toggle) external {
        require(_msgSender() == _stakingAddress || _msgSender() == firstOwner(), "Unallowed caller");
        if (toggle) {
            stakes[staker] = stakes[staker].add(amount);
        } else {
            stakes[staker] = stakes[staker].sub(amount);
        }
    }

    function getStake(address staker) view external returns (uint256) {
        return stakes[staker];
     }

    function getLockVest(address account) view external returns (uint256) {
        return _viewVesting(account);
     }

    function getBlacklisted(address account) view external returns (bool) {
        return blacklist[account];
    }
}