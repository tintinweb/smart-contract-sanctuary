/**
 *Submitted for verification at BscScan.com on 2021-10-27
*/

// SPDX-License-Identifier: MIT
/**
  $CNEKO is the token associated to the https://calineko.social website.

  Tokenomics:
  - 7 000 000 000 total supply.
  - 50% burnt at launch.
  - 2% Buyback
  - 2% Impact
  - 2% Market Maker protocol
  - 4% Marketing

  Website: https://calineko.com
  Telegram: https://t.me/calineko
  Twitter: https://twitter.com/calineko
 */

pragma solidity ^0.6.12;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
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
    event TakeFee(address indexed from, bool value);
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

library Address {
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
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

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

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
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    function getTime() public view returns (uint256) {
        return now;
    }

    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = now + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    function unlock() public virtual {
        require(
            _previousOwner == msg.sender,
            "You don't have permission to unlock"
        );
        require(now > _lockTime, "Contract still locked");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

// pragma solidity >=0.5.0;

interface INetworkV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

// pragma solidity >=0.5.0;
// Calineko
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

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

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

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// pragma solidity >=0.6.2;

interface INetworkV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// pragma solidity >=0.6.2;

interface INetworkV2Router02 is INetworkV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract Calineko is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcludedFromFee;

    mapping(address => bool) private _isExcluded;
    address[] private _excluded;

    uint256 private constant MAX = ~uint256(0);
    //uint256 private _tTotal = 7000000000 * 10**9;
    uint256 private _tTotal = 100000 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    uint256 private _tImpactTotal;
    uint256 private _tMarketMakerProtocolTotal;
    uint256 private _tBuybackTotal;
    uint256 private _tMarketingTotal;

    string private _name = "CALINEKO";
    string private _symbol = "CNEKO";
    uint8 private _decimals = 9;

    // Impact
    uint256 public _impactFee = 2;
    uint256 private _previousImpactFee = _impactFee;

    // Market maker
    uint256 public _marketMakerProtocolFee = 2;
    uint256 private _previousMarketMakerProtocolFee = _marketMakerProtocolFee;

    // Buyback
    uint256 public _buybackFee = 2;
    uint256 private _previousBuybackFee = _buybackFee;

    // Marketing
    uint256 public _marketingFee = 4;
    uint256 private _previousMarketingFee = _marketingFee;

    // Max transaction amount
    //uint256 public _maxTxAmount = 7000000000 * 10**9;
    uint256 public _maxTxAmount = 100000 * 10**9;
    uint256 private minimumTokensBeforeSwap = 5 * 10**5 * 10**9;

    // Impact wallet address
    address payable public _impactAddress;

    // Market maker protocol wallet address
    address payable public _marketMakerProtocolAddress;

    // Buyback wallet address
    address payable public _buybackAddress;

    // Marketing wallet address
    address payable public _marketingAddress;

    // Router
    INetworkV2Router02 public immutable networkV2Router;
    address public immutable networkV2Pair;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = false; // true;

    event RewardLiquidityProviders(uint256 tokenAmount);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    /*constructor(
        address networkV2Router02,
        address payable marketMakerProtocolAddress,
        address payable buybackAddress,
        address payable impactAddress,
        address payable marketingAddress
    ) public {
        _rOwned[_msgSender()] = _rTotal;

        _marketMakerProtocolAddress = marketMakerProtocolAddress;
        _buybackAddress = buybackAddress;
        _impactAddress = impactAddress;
        _marketingAddress = marketingAddress;

        INetworkV2Router02 _networkV2Router = INetworkV2Router02(
            networkV2Router02
        );

        networkV2Pair = INetworkV2Factory(_networkV2Router.factory())
            .createPair(address(this), _networkV2Router.WETH());
        networkV2Router = _networkV2Router;

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_marketMakerProtocolAddress] = true;
        _isExcludedFromFee[_buybackAddress] = true;
        _isExcludedFromFee[_impactAddress] = true;
        _isExcludedFromFee[_marketingAddress] = true;

        emit Transfer(address(0), _msgSender(), _tTotal);
    }*/

    constructor() public {
        _rOwned[_msgSender()] = _rTotal;

        _marketMakerProtocolAddress = 0x4de9534B9cE28c9adC2C6Ef90f8e76c9BEFaC1e7;
        _buybackAddress = 0x2Fcc51a3ED2403a1f33732dB0b2d4257351ba61c;
        _impactAddress = 0x3aC64874a4AE8F2711F06960DFa2Ed4A02007462;
        _marketingAddress = 0x993429Bd53e66b041A57213126cce844aF1515E7;

        INetworkV2Router02 _networkV2Router = INetworkV2Router02(
            0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
        );

        networkV2Pair = INetworkV2Factory(_networkV2Router.factory())
            .createPair(address(this), _networkV2Router.WETH());
        networkV2Router = _networkV2Router;

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_marketMakerProtocolAddress] = true;
        _isExcludedFromFee[_buybackAddress] = true;
        _isExcludedFromFee[_impactAddress] = true;
        _isExcludedFromFee[_marketingAddress] = true;

        emit Transfer(address(0), _msgSender(), _tTotal);
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

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
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
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
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

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function totalImpactBNB() public view returns (uint256) {
        // BNB has  18 decimals!
        return _tImpactTotal;
    }

    function totalMarketMakerProtocolBNB() public view returns (uint256) {
        return _tMarketMakerProtocolTotal;
    }

    function totalBuybackBNB() public view returns (uint256) {
        return _tBuybackTotal;
    }

    function totalMarketingBNB() public view returns (uint256) {
        return _tMarketingTotal;
    }

    function minimumTokensBeforeSwapAmount() public view returns (uint256) {
        return minimumTokensBeforeSwap;
    }

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(
            !_isExcluded[sender],
            "Excluded addresses cannot call this function"
        );
        (uint256 rAmount, , , , , , ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function tokenFromReflection(uint256 rAmount)
        public
        view
        returns (uint256)
    {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner {
        require(!_isExcluded[account], "Account is already excluded");
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner {
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
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if (from != owner() && to != owner())
            require(
                amount <= _maxTxAmount,
                "Transfer amount exceeds the maxTxAmount."
            );

        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinimumTokenBalance = contractTokenBalance >=
            minimumTokensBeforeSwap;

        if (
            overMinimumTokenBalance &&
            !inSwapAndLiquify &&
            from != networkV2Pair &&
            swapAndLiquifyEnabled
        ) {
            contractTokenBalance = minimumTokensBeforeSwap;
            swapAndLiquify(contractTokenBalance);
        }

        bool takeFee = true;

        if (
            _isExcludedFromFee[from] ||
            _isExcludedFromFee[to] ||
            from == networkV2Pair
        ) {
            takeFee = false;
        }

        _tokenTransfer(from, to, amount, takeFee);
    }

    function swapAndLiquify(uint256 contractTokenBalance) public lockTheSwap {
        uint256 totalFee = _impactFee
            .add(_buybackFee)
            .add(_marketMakerProtocolFee)
            .add(_marketingFee);

        uint256 tokenAmountToSell = contractTokenBalance.div(totalFee);

        uint256 tokenAmountForLiquidity = contractTokenBalance.sub(
            tokenAmountToSell
        );

        swapTokensForEth(tokenAmountToSell);

        _impactTranfers(address(this));

        addLiquidity(tokenAmountForLiquidity, address(this).balance);
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(networkV2Router), tokenAmount);

        // add the liquidity
        networkV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = networkV2Router.WETH();

        _approve(address(this), address(networkV2Router), tokenAmount);

        // make the swap
        networkV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this), // The contract
            block.timestamp
        );
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (!takeFee) removeAllFee();

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

        if (!takeFee) restoreAllFee();
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 tTransferAmount,
            uint256 tImpact,
            uint256 tMarketMakerProtocol,
            uint256 tBuyback,
            uint256 tMarketing
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        uint256 rImpact = _takeFee(sender, _impactAddress, tImpact);
        uint256 rMarketMakerProtocol = _takeFee(
            sender,
            _marketMakerProtocolAddress,
            tMarketMakerProtocol
        );
        uint256 rBuyback = _takeFee(sender, _buybackAddress, tBuyback);
        uint256 rMarketing = _takeFee(sender, _marketingAddress, tMarketing);
        _reflectFee(
            rImpact,
            tImpact,
            rMarketMakerProtocol,
            tMarketMakerProtocol,
            rBuyback,
            tBuyback,
            rMarketing,
            tMarketing
        );
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 tTransferAmount,
            uint256 tImpact,
            uint256 tMarketMakerProtocol,
            uint256 tBuyback,
            uint256 tMarketing
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        uint256 rImpact = _takeFee(sender, _impactAddress, tImpact);
        uint256 rMarketMakerProtocol = _takeFee(
            sender,
            _marketMakerProtocolAddress,
            tMarketMakerProtocol
        );
        uint256 rBuyback = _takeFee(sender, _buybackAddress, tBuyback);
        uint256 rMarketing = _takeFee(sender, _marketingAddress, tMarketing);
        _reflectFee(
            rImpact,
            tImpact,
            rMarketMakerProtocol,
            tMarketMakerProtocol,
            rBuyback,
            tBuyback,
            rMarketing,
            tMarketing
        );
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 tTransferAmount,
            uint256 tImpact,
            uint256 tMarketMakerProtocol,
            uint256 tBuyback,
            uint256 tMarketing
        ) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        uint256 rImpact = _takeFee(sender, _impactAddress, tImpact);
        uint256 rMarketMakerProtocol = _takeFee(
            sender,
            _marketMakerProtocolAddress,
            tMarketMakerProtocol
        );
        uint256 rBuyback = _takeFee(sender, _buybackAddress, tBuyback);
        uint256 rMarketing = _takeFee(sender, _marketingAddress, tMarketing);
        _reflectFee(
            rImpact,
            tImpact,
            rMarketMakerProtocol,
            tMarketMakerProtocol,
            rBuyback,
            tBuyback,
            rMarketing,
            tMarketing
        );
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 tTransferAmount,
            uint256 tImpact,
            uint256 tMarketMakerProtocol,
            uint256 tBuyback,
            uint256 tMarketing
        ) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        uint256 rImpact = _takeFee(sender, _impactAddress, tImpact);
        uint256 rMarketMakerProtocol = _takeFee(
            sender,
            _marketMakerProtocolAddress,
            tMarketMakerProtocol
        );
        uint256 rBuyback = _takeFee(sender, _buybackAddress, tBuyback);
        uint256 rMarketing = _takeFee(sender, _marketingAddress, tMarketing);
        _reflectFee(
            rImpact,
            tImpact,
            rMarketMakerProtocol,
            tMarketMakerProtocol,
            rBuyback,
            tBuyback,
            rMarketing,
            tMarketing
        );
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _takeFee(
        address sender,
        address recipient,
        uint256 tFee
    ) private returns (uint256) {
        if (tFee > 0) {
            uint256 currentRate = _getRate();
            uint256 rFee = tFee.mul(currentRate);
            _rOwned[recipient] = _rOwned[recipient].add(rFee);

            if (_isExcluded[recipient])
                _tOwned[recipient] = _tOwned[recipient].add(tFee);

            emit Transfer(sender, recipient, tFee);

            return rFee;
        }

        return 0;
    }

    function _reflectFee(
        uint256 rImpact,
        uint256 tImpact,
        uint256 rMarketMakerProtocol,
        uint256 tMarketMakerProtocol,
        uint256 rBuyback,
        uint256 tBuyback,
        uint256 rMarketing,
        uint256 tMarketing
    ) private {
        _rTotal = _rTotal
            .sub(rImpact)
            .sub(rMarketMakerProtocol)
            .sub(rBuyback)
            .sub(rMarketing);
        _tFeeTotal = _tFeeTotal
            .add(tImpact)
            .add(tMarketMakerProtocol)
            .add(tBuyback)
            .add(tMarketing);
        _tTotal = _tTotal
            .sub(tImpact)
            .sub(tMarketMakerProtocol)
            .sub(tBuyback)
            .sub(tMarketing);
        _tImpactTotal = _tImpactTotal.add(tImpact);
        _tMarketMakerProtocolTotal = _tMarketMakerProtocolTotal.add(
            tMarketMakerProtocol
        );
        _tBuybackTotal = _tBuybackTotal.add(tBuyback);
        _tMarketingTotal = _tMarketingTotal.add(tMarketing);
    }

    function _getValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (
            uint256 tTransferAmount,
            uint256 tImpact,
            uint256 tMarketMakerProtocol,
            uint256 tBuyback,
            uint256 tMarketing
        ) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount) = _getRValues(
            tAmount,
            tImpact,
            tMarketMakerProtocol,
            tBuyback,
            tMarketing,
            _getRate()
        );
        return (
            rAmount,
            rTransferAmount,
            tTransferAmount,
            tImpact,
            tMarketMakerProtocol,
            tBuyback,
            tMarketing
        );
    }

    function _getTValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 tImpact = calculateFee(tAmount, _impactFee);
        uint256 tMarketMakerProtocol = calculateFee(
            tAmount,
            _marketMakerProtocolFee
        );
        uint256 tBuyback = calculateFee(tAmount, _buybackFee);
        uint256 tMarketing = calculateFee(tAmount, _marketingFee);
        return (
            _calculateTransferAmount(
                tAmount,
                tImpact,
                tMarketMakerProtocol,
                tBuyback,
                tMarketing
            ),
            tImpact,
            tMarketMakerProtocol,
            tBuyback,
            tMarketing
        );
    }

    function _getRValues(
        uint256 tAmount,
        uint256 tImpact,
        uint256 tMarketMakerProtocol,
        uint256 tBuyback,
        uint256 tMarketing,
        uint256 currentRate
    ) private pure returns (uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rImpactFee = tImpact.mul(currentRate);
        uint256 rMarketMakerProtocolFee = tMarketMakerProtocol.mul(currentRate);
        uint256 rBuybackFee = tBuyback.mul(currentRate);
        uint256 rMarketingFee = tMarketing.mul(currentRate);
        return (
            rAmount,
            _calculateTransferAmount(
                rAmount,
                rImpactFee,
                rMarketMakerProtocolFee,
                rBuybackFee,
                rMarketingFee
            )
        );
    }

    function _calculateTransferAmount(
        uint256 amount,
        uint256 impact,
        uint256 marketMakerProtocol,
        uint256 buyback,
        uint256 marketing
    ) private pure returns (uint256) {
        return
            amount.sub(impact).sub(marketMakerProtocol).sub(buyback).sub(
                marketing
            );
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (
                _rOwned[_excluded[i]] > rSupply ||
                _tOwned[_excluded[i]] > tSupply
            ) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function calculateFee(uint256 _amount, uint256 _fee)
        private
        pure
        returns (uint256)
    {
        return _amount.mul(_fee).div(10**2);
    }

    function _impactTranfers(address payable sender) private {
        uint256 totalFee = _impactFee
            .add(_buybackFee)
            .add(_marketMakerProtocolFee)
            .add(_marketingFee);

        _tImpactTotal = _tImpactTotal.add(
            _transferETH(sender, totalFee, _impactFee, _impactAddress)
        );

        _tMarketMakerProtocolTotal = _tMarketMakerProtocolTotal.add(
            _transferETH(
                sender,
                totalFee,
                _marketMakerProtocolFee,
                _marketMakerProtocolAddress
            )
        );

        _tBuybackTotal = _tBuybackTotal.add(
            _transferETH(sender, totalFee, _buybackFee, _buybackAddress)
        );

        _tMarketingTotal = _tMarketingTotal.add(
            _transferETH(sender, totalFee, _marketingFee, _marketingAddress)
        );
    }

    function _transferETH(
        address payable sender,
        uint256 totalFee,
        uint256 _fee,
        address payable _address
    ) private returns (uint256) {
        uint256 contribution = sender.balance.div(totalFee).mul(_fee);
        TransferETH(sender, _address, contribution);
        return contribution;
    }

    function removeAllFee() private {
        if (
            _impactFee == 0 &&
            _marketingFee == 0 &&
            _marketMakerProtocolFee == 0 &&
            _buybackFee == 0
        ) return;

        _previousImpactFee = _impactFee;
        _previousMarketingFee = _marketingFee;
        _previousMarketMakerProtocolFee = _marketMakerProtocolFee;
        _previousBuybackFee = _buybackFee;

        _impactFee = 0;
        _marketingFee = 0;
        _marketMakerProtocolFee = 0;
        _buybackFee = 0;
    }

    function restoreAllFee() private {
        _impactFee = _previousImpactFee;
        _marketingFee = _previousMarketingFee;
        _marketMakerProtocolFee = _previousMarketMakerProtocolFee;
        _buybackFee = _previousBuybackFee;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function setMaxTxPercent(uint256 maxTxPercent, uint256 maxTxDecimals)
        external
        onlyOwner
    {
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(
            10**(uint256(maxTxDecimals) + 2)
        );
    }

    function setNumTokensSellToAddToLiquidity(uint256 _minimumTokensBeforeSwap)
        external
        onlyOwner
    {
        minimumTokensBeforeSwap = _minimumTokensBeforeSwap;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function TransferETH(
        address payable sender,
        address payable recipient,
        uint256 amount
    ) private {
        recipient.transfer(amount);
        emit Transfer(sender, recipient, amount);
    }

    //to recieve ETH from networkV2Router when swaping
    receive() external payable {}
}