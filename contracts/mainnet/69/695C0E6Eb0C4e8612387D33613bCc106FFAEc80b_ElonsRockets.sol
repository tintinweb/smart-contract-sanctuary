/**
 *Submitted for verification at Etherscan.io on 2021-06-28
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.6;

import "./VRFConsumerBase.sol";

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
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

    constructor () {
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


    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }


    function getTime() public view returns (uint256) {
        return block.timestamp;
    }

}

// pragma solidity >=0.5.0;

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


// pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

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

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// pragma solidity >=0.6.2;

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



// pragma solidity >=0.6.2;

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

contract ElonsRockets is Context, IERC20, Ownable, VRFConsumerBase {
    using SafeMath for uint256;
    using Address for address;

    event launchFailed();
    event launchTerminated(uint256 amountBoughtBack);
    event rocketLaunched(uint256 maxBuybackAmount);
    event burnSuccessful(uint256 amount);
    event newLaunchSet(uint256 nextLaunchTime);

    address public immutable deadAddress = 0x000000000000000000000000000000000000dEaD;
    mapping (address => uint256) private m_Balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => User) private cooldown;

    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _Blacklisted;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 1000000000000 * 10**9;
    uint256 private _tFeeTotal;

    string private _name = "Elon's Rockets";
    string private _symbol = "ELON'S ROCKETS";
    uint8 private _decimals = 9;

    address payable private teamDevAddress;

    uint256 public launchTime;
    uint256 private buyLimitEnd;

    // Elon's Rockets constants
    uint256 constant INITIAL_LAUNCH_DELAY = 24 hours;
    uint256 constant MIN_LAUNCH_DELAY = 2 hours;
    uint256 constant MAX_LAUNCH_DELAY = 12 hours;
    uint256 constant LAUNCH_SUCCESS_CHANCE = 33;
    uint256 constant BURN_SUCCESS_CHANCE = 75;
    // As a percentage of session total
    uint256 constant MIN_BURN_AMOUNT = 10;
    uint256 constant MAX_BURN_AMOUNT = 25;

    // random number generation
    uint256 public randomNumber; // for debugging
    bytes32 public lastRequestId;
    uint256 public lastRequestAt;

    uint256 public launchCount = 0;
    uint256 private maxBuybackAmount;
    uint256 private buybackAmount;
    uint256 private remainingSessionEth;
    bool public rocketFueled;
    bool private buybackInProgress;

    bytes32 internal keyHash;
    uint256 internal linkFee;
    // how many multiples of the linkFee should the contract aim to hold
    uint256 internal MIN_LINK_FEES_TO_HOLD = 2;
    uint256 internal MAX_LINK_FEES_TO_HOLD = 5;

    uint private _maxBuyAmount;
    bool private _cooldownEnabled=true;

    bool public tradingOpen = false; //once switched on, can never be switched off.

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = false;

    struct User {
        uint256 buy;
        uint256 sell;
        bool exists;
    }

    event SwapETHForTokens(
        uint256 amountIn,
        address[] path
    );

    event SwapTokensForETH(
        uint256 amountIn,
        address[] path
    );

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    modifier processBuyback {
        buybackInProgress = true;
        _;
        buybackInProgress = false;
    }


    constructor ()
        VRFConsumerBase(
            0xf0d54349aDdcf704F77AE15b96510dEA15cb7952, // VRF Coordinator
            0x514910771AF9Ca656af840dff83E8264EcF986CA  // LINK Token
        )
    {
        m_Balances[_msgSender()] = _tTotal;
        emit Transfer(address(0), _msgSender(), _tTotal);

        /**
         * Constructor inherits VRFConsumerBase
         *
         * Network: Mainnet
         * Chainlink VRF Coordinator address: 0xf0d54349aDdcf704F77AE15b96510dEA15cb7952
         * LINK token address:                0x514910771AF9Ca656af840dff83E8264EcF986CA
         * Key Hash: 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445
         */
        //VRF variables
        keyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;
        linkFee = 2 * 10 ** 18;
    }

    function iLoveInari() external onlyOwner() {
        _maxBuyAmount = 3000000000 * 10**9;
        swapAndLiquifyEnabled = true;
        tradingOpen = true;
        buyLimitEnd = block.timestamp + 3 minutes;

        launchTime = block.timestamp.add(INITIAL_LAUNCH_DELAY);
    }

    function initContract() external onlyOwner() {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[address(0xf0d54349aDdcf704F77AE15b96510dEA15cb7952)] = true; //chainlink VRFCoordinator

        teamDevAddress = payable(0x3F4B61e6c5A24aA1BE655B9E336eA5b89AEDD7aF);
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

    function balanceOf(address _account) public view override returns (uint256) {
        return m_Balances[_account];
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

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }


    function _approve(address owner, address spender, uint256 amount) private {
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
        // Early return if this is a buyback
        if (buybackInProgress) {
            _updateBalances(sender, recipient, amount, 0);

            return;
        }

        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!_Blacklisted[sender] && !_Blacklisted[recipient] && !_Blacklisted[tx.origin]);


        uint256 _taxes = 0;

        if (!inSwapAndLiquify && swapAndLiquifyEnabled && LINK.balanceOf(address(this)) < linkFee * MIN_LINK_FEES_TO_HOLD) {
            swapEthForLink();
        }

        if (!_isExcludedFromFee[sender]) {
            if (launchTime == 0) {
                // Sets a new launch time
                uint256 launchTimeWindowSeed = uint256(keccak256(abi.encodePacked(blockhash(block.number))));
                uint256 newLaunchTime = (launchTimeWindowSeed % (MAX_LAUNCH_DELAY - MIN_LAUNCH_DELAY));

                launchTime = block.timestamp.add(MIN_LAUNCH_DELAY).add(newLaunchTime);

                emit newLaunchSet(launchTime);
            } if (block.timestamp >= launchTime) {
                if (rocketFueled == false) {
                    fuelTheRocket();
                }

                requestBuybackRandomNumber();
            }
        }

        if(sender != owner() && recipient != owner()) {

            if (!tradingOpen) {
                if (!(sender == address(this) || recipient == address(this)
                || sender == address(owner()) || recipient == address(owner()))) {
                    require(tradingOpen, "Trading is not enabled");
                }
            }

            if(_cooldownEnabled) {
                if(!cooldown[msg.sender].exists) {
                    cooldown[msg.sender] = User(0,0,true);
                }
            }
        }

        //buy

        if(sender == uniswapV2Pair && recipient != address(uniswapV2Router) && !_isExcludedFromFee[recipient]) {
                require(tradingOpen, "Trading not yet enabled.");


                if(_cooldownEnabled) {
                    if(buyLimitEnd > block.timestamp) {
                        require(amount <= _maxBuyAmount);
                        require(cooldown[recipient].buy < block.timestamp, "Your buy cooldown has not expired.");
                        cooldown[recipient].buy = block.timestamp + (45 seconds);
                    }
                }
                if(_cooldownEnabled) {
                    cooldown[recipient].sell = block.timestamp + (15 seconds);
                }

                _taxes = _getTaxes(sender, recipient, amount);
        }

        //sell
        if (!inSwapAndLiquify && swapAndLiquifyEnabled && recipient == uniswapV2Pair) {
            //swap contract's tokens for ETH
            uint256 contractTokenBalance = balanceOf(address(this));
             if(contractTokenBalance > 0) {
                swapTokens(contractTokenBalance);
            }

            _taxes = _getTaxes(sender, recipient, amount);
        }

        //execute transfer
        _updateBalances(sender, recipient, amount, _taxes);
    }

	function _getTaxes(address sender, address recipient, uint256 amount) private view returns (uint256) {
        uint256 _netTaxes = 0;
        //if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]) {
            return _netTaxes;
        }
        _netTaxes = amount.mul(16).div(100);
        return _netTaxes;
    }

    function _updateBalances(address _sender, address _recipient, uint256 _amount, uint256 _taxes) private {
        uint256 _netAmount = _amount.sub(_taxes);
        m_Balances[_sender] = m_Balances[_sender].sub(_amount);
        m_Balances[_recipient] = m_Balances[_recipient].add(_netAmount);
        m_Balances[address(this)] = m_Balances[address(this)].add(_taxes);
        emit Transfer(_sender, _recipient, _netAmount);
    }

    function swapTokens(uint256 contractTokenBalance) private lockTheSwap {
        uint256 initialBalance = address(this).balance;

        swapTokensForEth(contractTokenBalance);

        uint256 transferredBalance = address(this).balance.sub(initialBalance);

        transferToAddressETH(teamDevAddress, transferredBalance.mul(3).div(8));
    }

    function buybackTokens(uint256 amount) private lockTheSwap {
        if (amount > 0) {
            swapETHForTokens(amount);

            remainingSessionEth -= amount;

            emit burnSuccessful(amount);

            if (remainingSessionEth <= 0) {
                terminateLaunch();
            }
        }

    }

    function swapEthForLink() private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(0x514910771AF9Ca656af840dff83E8264EcF986CA);

        uint256 ethAmount = uniswapV2Router.getAmountsIn(MAX_LINK_FEES_TO_HOLD * linkFee - LINK.balanceOf(address(this)), path)[0];

        if (address(this).balance > ethAmount) {
            uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: ethAmount}(
                0, // accept any amount of Tokens
                path,
                address(this), // Burn address
                block.timestamp.add(300)
            );

            emit SwapETHForTokens(ethAmount, path);
        }
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
            address(this), // The contract
            block.timestamp
        );

        emit SwapTokensForETH(tokenAmount, path);
    }

    function swapETHForTokens(uint256 amount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);

        // make the swap
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0, // accept any amount of Tokens
            path,
            deadAddress, // Burn address
            block.timestamp.add(300)
        );

        emit SwapETHForTokens(amount, path);
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function setTeamDevAddress(address _teamDevAddress) external onlyOwner() {
        teamDevAddress = payable(_teamDevAddress);
    }

    function transferToAddressETH(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        randomNumber = uint256(keccak256(abi.encode(randomness, requestId)));

        attemptBuyback(randomNumber);

        lastRequestId = 0;
    }

    function requestBuybackRandomNumber()  private  {

        if (lastRequestId != 0 && block.timestamp < lastRequestAt + 15 minutes) return;



        if (LINK.balanceOf(address(this)) > linkFee) {
            lastRequestId = requestRandomness(keyHash, linkFee);
            lastRequestAt = block.timestamp;
        }
    }

    function terminateLaunch() private {
        launchCount++;
        launchTime = 0;
        rocketFueled = false;
    }

    function attemptBuyback(uint256 randomResult) private processBuyback {
        // 1-100
        uint256 buybackRoll = randomResult % 100 + 1;

        // 1-9
        uint256 buybackAmountSeed = uint256(keccak256(abi.encodePacked(randomResult)));
        buybackAmount = maxBuybackAmount.
            mul(buybackAmountSeed % (MAX_BURN_AMOUNT - MIN_BURN_AMOUNT) + MIN_BURN_AMOUNT).
            div(100);

        // Debug RNG
        randomNumber = buybackRoll;

        if (remainingSessionEth == maxBuybackAmount && buybackRoll <= LAUNCH_SUCCESS_CHANCE) {
            buybackTokens(buybackAmount);

            emit rocketLaunched(maxBuybackAmount);
        } else {
            if (remainingSessionEth != maxBuybackAmount) {
                if (buybackRoll <= BURN_SUCCESS_CHANCE) {
                    buybackTokens(remainingSessionEth > buybackAmount ? buybackAmount : remainingSessionEth);
                } else {
                    terminateLaunch();

                    emit launchTerminated(maxBuybackAmount - remainingSessionEth);
                }
            } else {
                terminateLaunch();

                emit launchFailed();
            }
        }
    }

    function fuelTheRocket() private {
        // The launch can potentially use half of the BB wallet's balance as of setting the launch time
        maxBuybackAmount = address(this).balance.div(2);
        remainingSessionEth = maxBuybackAmount;

        rocketFueled = true;
    }

    function addTaxWhiteList(address _address) external onlyOwner(){
        _isExcludedFromFee[_address] = true;
    }
    function remTaxWhiteList(address _address) external onlyOwner(){
        _isExcludedFromFee[_address] = false;
    }

    function checkIfBlacklist(address _address) external view returns (bool) {
        return _Blacklisted[_address];
    }
    function blacklist(address _a) external onlyOwner() {
        _Blacklisted[_a] = true;
    }
    function rmBlacklist(address _a) external onlyOwner() {
        _Blacklisted[_a] = false;
    }

    //to recieve ETH from uniswapV2Router when swapping
    receive() external payable {}
}