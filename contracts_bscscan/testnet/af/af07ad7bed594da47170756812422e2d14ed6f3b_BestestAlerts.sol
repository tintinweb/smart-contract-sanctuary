/**
 *Submitted for verification at BscScan.com on 2022-01-04
*/

/*
__________             _____            _____     _____________           _____        
___  ____/_____ _________  /______________  /_    ___    |__  /_____________  /________
__  /_   _  __ `/_  ___/  __/  _ \_  ___/  __/    __  /| |_  /_  _ \_  ___/  __/_  ___/
_  __/   / /_/ /_(__  )/ /_ /  __/(__  )/ /_      _  ___ |  / /  __/  /   / /_ _(__  ) 
/_/      \__,_/ /____/ \__/ \___//____/ \__/      /_/  |_/_/  \___//_/    \__/ /____/

Fastest alerts is a utility token with a mission to provide powerful tools to stay ahead of the competition.

Website: https://besteralert.com
Twitter: https://twitter.com/Bester_alerts
Telegram: https://t.me/CMC_Bester_alerts

*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^ 0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns(address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns(bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


interface IERC20 {

    function totalSupply() external view returns(uint256);
    function balanceOf(address account) external view returns(uint256);
    function transfer(address recipient, uint256 amount) external returns(bool);
    function allowance(address owner, address spender) external view returns(uint256);
    function approve(address spender, uint256 amount) external returns(bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns(bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    

}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns(uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }


    function div(uint256 a, uint256 b) internal pure returns(uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns(uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns(uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns(uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {

    function isContract(address account) internal view returns(bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash:= extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount } ("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }


    function functionCall(address target, bytes memory data) internal returns(bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns(bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns(bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns(bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns(bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{ value: weiValue } (data);
        if (success) {
            return returndata;
        } else {

            if (returndata.length > 0) {
                assembly {
                    let returndata_size:= mload(returndata)
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
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns(address) {
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

    function getUnlockTime() public view returns(uint256) {
        return _lockTime;
    }

    function getTime() public view returns(uint256) {
        return block.timestamp;
    }

    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime, "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}


// pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

function feeTo() external view returns(address);
function feeToSetter() external view returns(address);

function getPair(address tokenA, address tokenB) external view returns(address pair);
function allPairs(uint) external view returns(address pair);
function allPairsLength() external view returns(uint);

function createPair(address tokenA, address tokenB) external returns(address pair);

function setFeeTo(address) external;
function setFeeToSetter(address) external;
}


// pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

function name() external pure returns(string memory);
function symbol() external pure returns(string memory);
function decimals() external pure returns(uint8);
function totalSupply() external view returns(uint);
function balanceOf(address owner) external view returns(uint);
function allowance(address owner, address spender) external view returns(uint);

function approve(address spender, uint value) external returns(bool);
function transfer(address to, uint value) external returns(bool);
function transferFrom(address from, address to, uint value) external returns(bool);

function DOMAIN_SEPARATOR() external view returns(bytes32);
function PERMIT_TYPEHASH() external pure returns(bytes32);
function nonces(address owner) external view returns(uint);

function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    
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

function MINIMUM_LIQUIDITY() external pure returns(uint);
function factory() external view returns(address);
function token0() external view returns(address);
function token1() external view returns(address);
function getReserves() external view returns(uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
function price0CumulativeLast() external view returns(uint);
function price1CumulativeLast() external view returns(uint);
function kLast() external view returns(uint);

function burn(address to) external returns(uint amount0, uint amount1);
function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
function skim(address to) external;
function sync() external;

function initialize(address, address) external;
}

// pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns(address);
function WETH() external pure returns(address);

function addLiquidity(
    address tokenA,
    address tokenB,
    uint amountADesired,
    uint amountBDesired,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
) external returns(uint amountA, uint amountB, uint liquidity);
function addLiquidityETH(
    address token,
    uint amountTokenDesired,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline
) external payable returns(uint amountToken, uint amountETH, uint liquidity);

function removeLiquidity(
    address tokenA,
    address tokenB,
    uint liquidity,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
) external returns(uint amountA, uint amountB);
function removeLiquidityETH(
    address token,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline
) external returns(uint amountToken, uint amountETH);
function removeLiquidityWithPermit(
    address tokenA,
    address tokenB,
    uint liquidity,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline,
    bool approveMax, uint8 v, bytes32 r, bytes32 s
) external returns(uint amountA, uint amountB);
function removeLiquidityETHWithPermit(
    address token,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline,
    bool approveMax, uint8 v, bytes32 r, bytes32 s
) external returns(uint amountToken, uint amountETH);
function swapExactTokensForTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
) external returns(uint[] memory amounts);
function swapTokensForExactTokens(
    uint amountOut,
    uint amountInMax,
    address[] calldata path,
    address to,
    uint deadline
) external returns(uint[] memory amounts);
function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
external
payable
returns(uint[] memory amounts);
function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
external
returns(uint[] memory amounts);
function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
external
returns(uint[] memory amounts);
function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
external
payable
returns(uint[] memory amounts);

function quote(uint amountA, uint reserveA, uint reserveB) external pure returns(uint amountB);
function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns(uint amountOut);
function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns(uint amountIn);
function getAmountsOut(uint amountIn, address[] calldata path) external view returns(uint[] memory amounts);
function getAmountsIn(uint amountOut, address[] calldata path) external view returns(uint[] memory amounts);
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
    ) external returns(uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns(uint amountETH);

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



contract BestestAlerts is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    address public immutable deadAddress = 0x000000000000000000000000000000000000dEaD;
    address public marketingAddress = 0xeBDFE75966740F392C24eb16798e4b0e9287592e;
    address public projectAddress = 0x6f594341073C9c4BB717e85771Aa028D41c2bDC0;
    address public protectionAddress = 0xdc720f96Be46305e1dfC8AA76E7e86f6302664C5;
    address public airdropAddressPublic = 0x0E7fA6592921980F08F9d97dbDF04ddf6997bc90;
    address public airdropAddressPrivate = 0x35DA2c1A64D74D90Ee52d22e96d5bc4e9205eebF;


    mapping(address => uint256) private _rOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcludedFromFee;

    struct BuyHistories {
        bool exist;
        uint256 time;
        uint256 tokenAmount;
    }
    // LookBack into historical buy data
    mapping (address => BuyHistories) public _buyHistories;
    address public _lastWalletInteraction;

    uint256 private _tTotal = 100000000 * 10**18;

    string private _name = "Bester Alert";
    string private _symbol = "BA";
    uint8 private _decimals = 18;

    struct SellHistories {
        uint256 time;
        uint256 bnbAmount;
    }


    uint256 public _taxFee = 2;
    uint256 private _previousTaxFee = _taxFee;
    uint256 public _buyTaxFee = 2;
    uint256 public _sellTaxFee = 8;

    bool private _presaleEnded = false;
    // LookBack into historical sale data
    SellHistories[] public _sellHistories;
    // Presale will end when liquidity is added from PinkSale
    uint256 private _liqAddTimestamp;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    constructor() {

        _rOwned[_msgSender()] = _tTotal;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[marketingAddress] = true;
        _isExcludedFromFee[projectAddress] = true;
        _isExcludedFromFee[protectionAddress] = true;
        _isExcludedFromFee[airdropAddressPrivate] = true;
        _isExcludedFromFee[airdropAddressPublic] = true;


        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public view returns(string memory) {
        return _name;
    }

    function symbol() public view returns(string memory) {
        return _symbol;
    }

    function decimals() public view returns(uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns(uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns(uint256) {
        return _rOwned[account];
    }

    function transfer(address recipient, uint256 amount) public override returns(bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns(uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns(bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns(bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns(bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns(bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
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
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        // Before the presale the trading is halted. After presale it can't be halted anymore.

        if (from == owner() || from == airdropAddressPublic || from == airdropAddressPrivate ) {}
        else {

            require(_presaleEnded, "Presale is not ended, wait for launch");

        }

        if (to == uniswapV2Pair && balanceOf(uniswapV2Pair) > 0) {
            SellHistories memory sellHistory;
            sellHistory.time = block.timestamp;
            sellHistory.bnbAmount = _getSellBnBAmount(amount);

            _sellHistories.push(sellHistory);
        }
        else if(from == uniswapV2Pair){
             if (!_buyHistories[to].exist) {
                _buyHistories[to].exist = true;
                _buyHistories[to].time = block.timestamp;
                _buyHistories[to].tokenAmount = amount;
             }
        }

        bool takeFee = true;

        // If any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
            if(_isExcludedFromFee[from]) {
                _lastWalletInteraction = from;
            }
            if(_isExcludedFromFee[to]) {
                _lastWalletInteraction = to;
            }
        }
        else {
            // Buy
            if (from == uniswapV2Pair) {
                removeAllFee();
                _taxFee = _buyTaxFee;
                _lastWalletInteraction = to;

            }
            // Sell
            else if (to == uniswapV2Pair) {
                removeAllFee();
                _taxFee = _sellTaxFee;
                if(_buyHistories[from].exist) {
                    if ( block.timestamp == _buyHistories[from].time ) {
                        if ( _lastWalletInteraction != from ){
                            //anti bot tech
                            _taxFee = 100;
                        }
                    }

                }
                _lastWalletInteraction = from;

            }
            else if (from != uniswapV2Pair && to != uniswapV2Pair) {
                takeFee = false;
            }


        }

        _tokenTransfer(from, to, amount, takeFee);
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {

        // Approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // Add the liquidity
        uniswapV2Router.addLiquidityETH{ value: ethAmount } (
            address(this),
            tokenAmount,
            0, // Slippage is unavoidable
            0, // Slippage is unavoidable
            owner(),
            block.timestamp
        );
    }


    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if (!takeFee)
            removeAllFee();

        _transferLogic(sender, recipient, amount);

        if (!takeFee)
            restoreAllFee();
    }

    function _transferLogic(address sender, address recipient, uint256 amount) private {

        uint256 tMarketing; uint256 tProject; uint256 tProtect; uint256 tBurn;

        if (_taxFee > 0) {
            uint256 takeFeeAmount = amount.mul(_taxFee * getGradientFees()).div(4).div(10 ** 2);
            tMarketing = takeFeeAmount;
            tProject = takeFeeAmount;
            tProtect = takeFeeAmount;
            tBurn = takeFeeAmount;
            _rOwned[marketingAddress] = _rOwned[marketingAddress].add(tMarketing);
            emit Transfer(sender, marketingAddress, tMarketing);

            _rOwned[projectAddress] = _rOwned[projectAddress].add(tProject);
            emit Transfer(sender, projectAddress, tProject);

            _rOwned[protectionAddress] = _rOwned[protectionAddress].add(tProtect);
            emit Transfer(sender, protectionAddress, tProtect);

            _rOwned[deadAddress] = _rOwned[deadAddress].add(tBurn);
            emit Transfer(sender, deadAddress, tBurn);

        }

        uint256 tTransferAmount = amount.sub(tMarketing).sub(tProject).sub(tProtect).sub(tBurn);
        _rOwned[sender] = _rOwned[sender].sub(amount);
        _rOwned[recipient] = _rOwned[recipient].add(tTransferAmount);
        emit Transfer(sender, recipient, tTransferAmount);

    }


    function removeAllFee() private {
        if (_taxFee == 0) return;

        _previousTaxFee = _taxFee;

        _taxFee = 0;
    }

    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }


    function _getSellBnBAmount(uint256 tokenAmount) private view returns(uint256) {
        address[] memory path = new address[](2);

        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        uint[] memory amounts = uniswapV2Router.getAmountsOut(tokenAmount, path);

        return amounts[1];
    }

    //Protection against high fee, max fee is 4%.
    function setTaxFeePercent(uint256 taxFee) external onlyOwner() {
        require(taxFee <= 4, "Can't set buy fee higher than 4%");
        _taxFee = taxFee;
    }

    //Protection against high buy fee, max sell fee is 4%.
    function setBuyFee(uint256 buyTaxFee) external onlyOwner {
        require(buyTaxFee <= 4, "Can't set buy fee higher than 4%");
        _buyTaxFee = buyTaxFee;
    }

    //Protection against high sell fee, max sell fee is 16%.
    function setSellFee(uint256 sellTaxFee) external onlyOwner {
        require(sellTaxFee <= 16, "Can't set sell fee higher than 16%");
        _sellTaxFee = sellTaxFee;
    }

    //This only enables to set the airdrop to true. Cannot be set back to false again.
    function presaleEnded() external onlyOwner {
        _presaleEnded = true;
        _liqAddTimestamp = block.timestamp;

    }

    function setMarketingWallet(address payable newWallet) external onlyOwner {
        require(marketingAddress != newWallet, "Wallet already set!");
        marketingAddress = newWallet;
    }
    
    function setProjectWallet(address payable newWallet) external onlyOwner {
        require(projectAddress != newWallet, "Wallet already set!");
        projectAddress = newWallet;
    }

    function setProtectionWallet(address payable newWallet) external onlyOwner {
        require(protectionAddress != newWallet, "Wallet already set!");
        protectionAddress = newWallet;
    }

    function changeRouterVersion(address _router) public onlyOwner returns(address _pair) {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_router);

        _pair = IUniswapV2Factory(_uniswapV2Router.factory()).getPair(address(this), _uniswapV2Router.WETH());
        if (_pair == address(0)) {
            // Pair doesn't exist
            _pair = IUniswapV2Factory(_uniswapV2Router.factory())
                .createPair(address(this), _uniswapV2Router.WETH());
        }
        uniswapV2Pair = _pair;

        // Set the router of the contract variables
        uniswapV2Router = _uniswapV2Router;
    }

    // To recieve ETH from uniswapV2Router when swapping
    receive() external payable { }


    function transferForeignToken(address _token, address _to) public onlyOwner returns(bool _sent){
        require(_token != address(this), "Can't let you take all native token");
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        _sent = IERC20(_token).transfer(_to, _contractBalance);
    }

    function Sweep() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    /**
     * Returns a fee multiplier. During the first 4 hours sell fees will be multiplied and buy fees will remain the same.
     * After 4 hours, normal sell fees will apply.
     */
    function getGradientFees() internal view returns (uint256) {
        uint256 time_since_start = block.timestamp - _liqAddTimestamp;
        uint256 hour = 60 * 60;
        if (_taxFee == _sellTaxFee) {
            if (time_since_start < 1 * hour) {
                return (4);
            } else if (time_since_start < 2 * hour) {
                return (3);
            } else if (time_since_start < 3 * hour) {
                return (2);
            } else {
                return (1);
            }
        } else {
            return (1);
        }
    }


}