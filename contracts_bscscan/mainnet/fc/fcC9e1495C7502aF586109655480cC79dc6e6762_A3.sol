/**
 *Submitted for verification at BscScan.com on 2021-09-30
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;

/*

    Name = A3
    Symbol = A3
    Total Supply = 100_000_000_000
    Decimal = 9
        - Tokenomics
        6% Project
        4% Community
        2% Liquidity Pool
        
        - Project Wallet Breakdown
        2% Wallet
        2 1/2% Wallet 
        1% Wallet 
        1/2% Wallet
        
*/

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


/* 
    Interface to implement BEP20 compliant tokens. 
    This will be utilized in primary token contract with full implementations.
*/
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

 
/*
    Basic solidity library for performing safe math functions internal to the contract.
*/
library SafeMath {

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


/**
 * Allows for contract ownership along with multi-address authorization
 */
abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }
    
    /**
     * Function modifier to only allow either contract owner or current dividend wallet owner to change dividend wallet 
     */
     modifier dividendOwner(address _wallet) {
         require(msg.sender == _wallet || isOwner(msg.sender), "!NOT YOUR WALLET"); _;
     }
     
    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    /**
     * Authorize address. Owner only
     */
    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    /**
     * Remove address' authorization. Owner only
     */
    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    /**
     * Return address' authorization status
     */
    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    /**
     * Transfer ownership to new address. Caller must be owner. Leaves old owner authorized
     */
    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}


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

    event Mint(address indexed sender, uint amount0, uint amount1);
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

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
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

/*

    Name = A3
    Symbol = A3
    Total Supply = 100_000_000_000
    Decimal = 9
        - Tokenomics
        6% Project
        4% Community
        2% Liquidity Pool
        
        - Project Wallet Breakdown
        2% Wallet
        2 1/2% Wallet 
        1% Wallet 
        1/2% Wallet
        
*/

contract A3 is Context, IERC20, Auth {
    using SafeMath for uint256;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public _isExcludedFromAutoLiquidity;

    address[] private _excluded;
    address[] public _whitelist;
    address[] public _blacklist;
    address public _communityFeeReceiver;
    address public _p1Receiver;
    address public _p2Receiver;
    address public _p3Receiver;
    address public _p4Receiver;
   
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 100000000000 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private _name     = "A3";
    string private _symbol   = "A3";
    uint8 private  _decimals = 9;
    
    uint256 public _liquidityFee  = 12; 
    uint256 public _taxFee = 0;
    // community fee
    uint256 public _percentageOfLiquidityForCommunityFee = 34; // 4.08% of 12%
    // community total = 34% of total or 4.08% of 12% fee
    uint256 public _percentageOfLiquidityForP1 = 21; // 2.52% of 12%
    uint256 public _percentageOfLiquidityForP2 = 17; // 2.04% of 12%
    uint256 public _percentageOfLiquidityForP3 = 9; // 1.08% of 12% 
    uint256 public _percentageOfLiquidityForP4 = 4; // .6% of 12% 
    // project total = 51% of total or 6.24% of 12% fee
    // remainder left to go towards the auto-liquidity = 15% of total or 1.8% of 12% fee
    
    uint256 public  _maxTxAmount     = 100000000000 * 10**9; // 100 billion
    uint256 private _minTokenBalance = 100000 * 10**9;
    
    // auto liquidity
    bool public _swapAndLiquifyEnabled = true;
    bool public _isPrelaunchEnabled = true;
    bool public _launched = false;
    bool _inSwapAndLiquify;
    IUniswapV2Router02 public _uniswapV2Router;
    address            public _uniswapV2Pair;
    // Events 
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 bnbReceived, uint256 tokensIntoLiqudity);
    event CommunityFeeSent(address to, uint256 bnbSent);
    event P1FeeSent(address to, uint256 bnbSent);
    event P2FeeSent(address to, uint256 bnbSent);
    event P3FeeSent(address to, uint256 bnbSent);
    event P4FeeSent(address to, uint256 bnbSent);
    
    modifier lockTheSwap {
        _inSwapAndLiquify = true;
        _;
        _inSwapAndLiquify = false;
    }
    
    constructor (
                address cOwner, // deployer will be transferred after launch
                address communityFeeReceiver, // community wallet at 4%
                address p1Receiver, // project wallet 1 at 2.5%
                address p2Receiver, // project wallet 2 at 2%
                address p3Receiver, // project wallet 3 at 1%
                address p4Receiver // project wallet 4 at .5%
                ) Auth(cOwner) {

        // set wallet addresses
        _communityFeeReceiver = communityFeeReceiver;
        _p1Receiver = p1Receiver;
        _p2Receiver = p2Receiver;
        _p3Receiver = p3Receiver;
        _p4Receiver = p4Receiver;
        _rOwned[cOwner] = _rTotal;
        
        // PancakeRouterV2
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E); // Pancakeswap MAINNET BSC
        _uniswapV2Router = uniswapV2Router;
        _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WETH());
        
        // exclude system contracts
        _isExcludedFromFee[cOwner]                = true;
        _isExcludedFromFee[address(this)]         = true;
        _isExcludedFromFee[_communityFeeReceiver] = true;
        _isExcludedFromFee[_p1Receiver]           = true;
        _isExcludedFromFee[_p2Receiver]           = true;
        _isExcludedFromFee[_p3Receiver]           = true;
        _isExcludedFromFee[_p4Receiver]           = true;
        
        // whitelist
        _whitelist.push(cOwner);
        _whitelist.push(_p1Receiver);
        _whitelist.push(_p2Receiver);
        _whitelist.push(_p3Receiver);
        _whitelist.push(_p4Receiver);
        _whitelist.push(_communityFeeReceiver);

        _isExcludedFromAutoLiquidity[_uniswapV2Pair]            = true;
        _isExcludedFromAutoLiquidity[address(_uniswapV2Router)] = true;
        
        emit Transfer(address(0), cOwner, _tTotal);
    }

    /**
     * returns the name of the token 
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /*
     * returns the symbol for the token 
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /*
     * returns the decimal count for the token 
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /*
     * returns the total supply of the token
     */
    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    /*
     * returns the balance of tokens held by the account requested
     */
    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    /*
     * returns boolean
     * transfer amount to recipient
     */
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /*
     * return allowance of spender for owner
     */
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    /*
     * returns bool
     * approve spender to spend amount on _msgSender
     */
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /*
     * returns bool
     * transfer amount from sender to rrecipient
     */
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }

    /*
     * returns bool
     * increase allowance of spender by addedValue
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /*
     * returns bool
     * decrease allowance of spender by addedValue
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
        return true;
    }

    /*
     * returns boolean of whether account is excluded from reward
     */
    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    /*
     * returns total fees 
     */
    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        (, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount);
        uint256 currentRate = _getRate();

        if (!deductTransferFee) {
            (uint256 rAmount,,) = _getRValues(tAmount, tFee, tLiquidity, currentRate);
            return rAmount;

        } else {
            (, uint256 rTransferAmount,) = _getRValues(tAmount, tFee, tLiquidity, currentRate);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");

        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    /*
     * exclude account from reward
     */
    function excludeFromReward(address account) public authorized {
        require(!_isExcluded[account], "Account is already excluded");

        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    /*
     * include account in reward
     */
    function includeInReward(address account) external authorized {
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
    
    /*
     * add to the naughty list
     */
    function addToBlacklist(address addressToBlacklist) external authorized returns(bool) {
        if(_blacklist.length == 0) {
            _blacklist.push(addressToBlacklist);
            return true;
        }
        uint counter = 0;
        for(uint i = 0; i < _blacklist.length; i++) {
            address addr = _blacklist[i];
            if(addr == addressToBlacklist) {
                // found addressToBlacklist already on list return false and don't finish
                return false;
            }
            // this index is not the addressToBlacklist set counter to index
            counter = i;
        }
        // if counter is the number of the last index we didn't find the addressToBlacklist
        // in the list already to add to the _blacklist and return true
        // else return false
        if(counter == _blacklist.length.sub(1)) {
            _blacklist.push(addressToBlacklist);
            return true;
        } else {
            return false;
        }
    }
    
    /*
     * remove from the naughty list
     */
    function removeFromBlacklist(address addressToRemove) external authorized returns(bool) {
        for(uint i = 0; i < _blacklist.length; i++) {
            address addr = _blacklist[i];
            // check if this index equals the addressToRemove
            if(addr == addressToRemove) {
                // starting from index i replace with next one in array.
                // this effectively removes the addressToRemove
                for (uint j = i; j < _blacklist.length.sub(1); j++){
                    _blacklist[j] = _blacklist[j+1];
                }
                // pop off the last empty slot and return true
                _blacklist.pop();
                return true;
            }
        }
        // if we haven't returned true we will return out false here
        return false;
    } 
    
    /*
     * checks if address IS/IS NOT on blacklist
     * returns true if not on blacklist
     */
    function notBlacklisted(address addressToCheck) public view returns(bool) {
        for(uint i = 0; i < _blacklist.length; i++) {
            address addr = _blacklist[i];
            if(addr == addressToCheck) {
                return false; // false means addressToCheck IS on blacklist
            }
        }
        return true; // true means addressToCheck IS NOT on blacklist
    }
    
    /*
     * add to whitelist
     */
    function addToWhitelist(address addressToWhitelist) external authorized returns(bool) {
        uint counter = 0;
        for(uint i = 0; i < _whitelist.length; i++) {
            address addr = _whitelist[i];
            // if addressToWhitelist matches addr it is already on whitelist
            // return false and don't add
            if(addr == addressToWhitelist) {
                return false;
            }
            // set counter to index
            counter = i;
        }
        // check counter to be equal to number for last index in array
        if(counter == _whitelist.length.sub(1)) {
            // push addressToWhitelist to _whitelist
            // return true since it was added
            _whitelist.push(addressToWhitelist);
            return true;
        } else {
            // else return false
            return false;
        }
    }
    
    /*
     * remove from whitelist
     */
    function removeFromWhitelist(address addressToRemove) external authorized returns(bool) {
        for(uint i = 0; i < _whitelist.length; i++) {
            address addr = _whitelist[i];
            // check if addressToRemove matches addr at index
            if(addr == addressToRemove) {
                // starting from current index move each next index back one
                for (uint j = i; j < _whitelist.length.sub(1); j++){
                    _whitelist[j] = _whitelist[j+1];
                }
                // pop off last empty index and return true
                _whitelist.pop();
                return true;
            }
        }
        // if hasn't returned true return false
        return false;
    }    
    
    /*
     * checks if addressToCheck is whitelisted
     * returns TRUE if addressToCheck IS on the whitelist and FALSE if addressToCheck IS NOT
     */
    function isWhitelisted(address addressToCheck) public view returns(bool) {
        for(uint i = 0; i < _whitelist.length; i++) {
            address addr = _whitelist[i];
            if(addr == addressToCheck) {
                return true; // true means addressToCheck IS on _whitelist
            }
        }
        return false; // false means addressToCheck IS NOT on _whitelist
    }
    
    /*
     * Set Prelaunch enabled
     */
     function setPrelaunchEnabled(bool enabled) external authorized returns(bool) {
         _isPrelaunchEnabled = enabled;
         return _isPrelaunchEnabled;
     }

    /*
     * set Community fee wallet
     */
    function setCommunityFeeWallet(address communityFeeReceiver) external authorized {
        _communityFeeReceiver = communityFeeReceiver;
    }

    /*
     * set P1 wallet 
     */
    function setP1Wallet(address p1Receiver) external dividendOwner(_p1Receiver) {
        _p1Receiver = p1Receiver;
    }

    /*
     * set P2 wallet 
     */
    function setP2Wallet(address p2Receiver) external dividendOwner(_p2Receiver) {
        _p2Receiver = p2Receiver;
    }

    /*
     * set P3 wallet 
     */
    function setP3Wallet(address p3Receiver) external dividendOwner(_p3Receiver) {
        _p3Receiver = p3Receiver;
    }

    /*
     * set P4 wallet 
     */
    function setP4Wallet(address p4Receiver) external dividendOwner(_p4Receiver) {
        _p4Receiver = p4Receiver;
    }

    /*
     * set account to either be excluded or not excluded from fee dependant on bool(e) passed in
     */
    function setExcludedFromFee(address account, bool e) external authorized {
        _isExcludedFromFee[account] = e;
    }

    /*
     * set liquidity fee percent i.e. the percentage being split between the sub fees
     */
    function setLiquidityFeePercent(uint256 liquidityFee) external authorized {
        _liquidityFee = liquidityFee;
    }

    /*
     * set percentage of liquidity fee for community fee wallet 
     */
    function setPercentageOfLiquidityForCommunityFee(uint256 communityFee) external authorized {
        _percentageOfLiquidityForCommunityFee = communityFee;
    }

    /*
     * set percentage of liquidity fee for P1 wallet 
     */
    function setPercentageOfLiquidityForP1(uint256 p1Fee) external authorized {
        _percentageOfLiquidityForP1 = p1Fee;
    }
    
    /*
     * set percentage of liquidity fee for P2 wallet 
     */
    function setPercentageOfLiquidityForP2(uint256 p2Fee) external authorized {
        _percentageOfLiquidityForP2 = p2Fee;
    }
    
    /*
     * set percentage of liquidity fee for P3 wallet 
     */
    function setPercentageOfLiquidityForP3(uint256 p3Fee) external authorized {
        _percentageOfLiquidityForP3 = p3Fee;
    }
    
    /*
     * set percentage of liquidity fee for P4 wallet 
     */
    function setPercentageOfLiquidityForP4(uint256 p4Fee) external authorized {
        _percentageOfLiquidityForP4 = p4Fee;
    }

    /*
     * set max transaction amount
     */
    function setMaxTxAmount(uint256 maxTxAmount) external authorized {
        _maxTxAmount = maxTxAmount;
    }

    /*
     * set swap and liquify to either enabled or disabled dependant on the bool(e) passed in
     */
    function setSwapAndLiquifyEnabled(bool e) public authorized {
        _swapAndLiquifyEnabled = e;
        emit SwapAndLiquifyEnabledUpdated(e);
    }
    
    /*
     * allows the contract to recieve payments 
     */
    receive() external payable {}

    /*
     * set uniswapV2Router address
     */
    function setUniswapRouter(address r) external authorized {
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(r);
        _uniswapV2Router = uniswapV2Router;
    }

    /*
     * set uniswapV2Pair address 
     */
    function setUniswapPair(address p) external authorized {
        _uniswapV2Pair = p;
    }

    /*
     * set address(a) to be either excluded or included in auto liquidity based on bool(b) passed in
     */
    function setExcludedFromAutoLiquidity(address a, bool b) external authorized {
        _isExcludedFromAutoLiquidity[a] = b;
    }

    /*
     * calculate reflection fee and update totals
     */
    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal    = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    /*
     * get tValues
     */
    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 tFee       = calculateFee(tAmount, _taxFee);
        uint256 tLiquidity = calculateFee(tAmount, _liquidityFee);
        uint256 tTransferAmount = tAmount.sub(tFee);
        tTransferAmount = tTransferAmount.sub(tLiquidity);
        return (tTransferAmount, tFee, tLiquidity);
    }

    /*
     * get rValues
     */
    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount    = tAmount.mul(currentRate);
        uint256 rFee       = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee);
        rTransferAmount = rTransferAmount.sub(rLiquidity);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    /*
     * get the current supply
     */
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

    /*
     * calcs and takes the transaction fee
     */
    function takeTransactionFee(address to, uint256 tAmount, uint256 currentRate) private {
        if (tAmount <= 0) { return; }

        uint256 rAmount = tAmount.mul(currentRate);
        _rOwned[to] = _rOwned[to].add(rAmount);
        if (_isExcluded[to]) {
            _tOwned[to] = _tOwned[to].add(tAmount);
        }
    }
    
    /*
     * calcs fee into .00 format
     */
    function calculateFee(uint256 amount, uint256 fee) private pure returns (uint256) {
        return amount.mul(fee).div(100);
    }
    
    /*
     * returns bool
     * see if account is excluded from fee 
     */
    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    /*
     * appove spender for amount on owner 
     * used internal
     */
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /*
     * transfer FROM TO for AMOUNT
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(notBlacklisted(from), "You have been flagged as a bot. Please contact the team to be unrestricted.");           
        
        // check for prelaunch condition
        if(_isPrelaunchEnabled == true) {
            // ensure from is whitelisted to transfer during prelaunch
            require(isWhitelisted(from), "Account not on prelaunch whitelist.");
        }
        
        // check for maxTxAmount outside deployer wallet 
        if (isOwner(from) && isOwner(to)) {
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        }

        /*
            - swapAndLiquify will be initiated when token balance of this contract
            has accumulated enough over the minimum number of tokens required.
            - don't get caught in a circular liquidity event.
            - don't swapAndLiquify if sender is uniswap pair.
        */
        uint256 contractTokenBalance = balanceOf(address(this));
        
        // check that there are more or equal tokens in contract than max transaction amount 
        // if true set to max transaction amount
        if (contractTokenBalance >= _maxTxAmount) {
            contractTokenBalance = _maxTxAmount;
        }
        
        // boolean condition for SaL to occur
        // must meet below + not be in SaL + not from address not be excluded from SaL + SaL must be enabled
        bool isOverMinTokenBalance = contractTokenBalance >= _minTokenBalance;
        if (
            isOverMinTokenBalance &&
            !_inSwapAndLiquify &&
            !_isExcludedFromAutoLiquidity[from] &&
            _swapAndLiquifyEnabled
        ) {
            swapAndLiquify(contractTokenBalance);
        }

        // dont take fee if from or to is excluded 
        bool takeFee = true;
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }
        _tokenTransfer(from, to, amount, takeFee);
    }

    /*
     * locktheswap modifier 
     * read the comments for explanation
     */
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
        
        // take community fee
        uint256 communityFee = newBalance.mul(_percentageOfLiquidityForCommunityFee).div(100);

        // take P1 fee
        uint256 p1Fee = newBalance.mul(_percentageOfLiquidityForP1).div(100);

        // take P2 fee
        uint256 p2Fee = newBalance.mul(_percentageOfLiquidityForP2).div(100);

        // take P3 fee
        uint256 p3Fee = newBalance.mul(_percentageOfLiquidityForP3).div(100);

        // take P4 fee
        uint256 p4Fee = newBalance.mul(_percentageOfLiquidityForP4).div(100);
        
        // add fees together to get total fees to sub
        uint256 txFees = communityFee.add(p1Fee).add(p2Fee).add(p3Fee).add(p4Fee);
        
        // sub fees to get bnbForLiquidity
        uint256 bnbForLiquidity     = newBalance.sub(txFees);
        
        // pay community fee wallet and emit event
        if (communityFee > 0) {
            payable(_communityFeeReceiver).transfer(communityFee);
            emit CommunityFeeSent(_communityFeeReceiver, communityFee);
        }

        // pay P1 wallet and emit event
        if (p1Fee > 0) {
            payable(_p1Receiver).transfer(p1Fee);
            emit P1FeeSent(_p1Receiver, p1Fee);
        }

        // pay P2 wallet and emit event
        if (p2Fee > 0) {
            payable(_p2Receiver).transfer(p2Fee);
            emit P2FeeSent(_p2Receiver, p2Fee);
        }

        // pay P3 wallet and emit event
        if (p3Fee > 0) {
            payable(_p3Receiver).transfer(p3Fee);
            emit P3FeeSent(_p3Receiver, p3Fee);
        }

        // pay P4 wallet and emit event
        if (p4Fee > 0) {
            payable(_p4Receiver).transfer(p4Fee);
            emit P4FeeSent(_p4Receiver, p4Fee);
        }

        // add liquidity to uniswap
        addLiquidity(otherHalf, bnbForLiquidity);
        
        emit SwapAndLiquify(half, bnbForLiquidity, otherHalf);
    }
    
    /*
     * swap tokenAmount for bnb
     * used internally in SwapAndLiquify
     */
    function swapTokensForBnb(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();

        _approve(address(this), address(_uniswapV2Router), tokenAmount);

        // make the swap
        _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of BNB
            path,
            address(this),
            block.timestamp
        );
    }

    /*
     * add liquidity in amounts passed in using uniswapV2Router addLiquidityETH function
     * used internally in SwapAndLiquify
     */
    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(_uniswapV2Router), tokenAmount);

        // add the liquidity
        _uniswapV2Router.addLiquidityETH{value: bnbAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );
    }

    /*
     * internal token transfer function used in _transfer
     */
    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        uint256 previousTaxFee       = _taxFee;
        uint256 previousLiquidityFee = _liquidityFee;
        // if takeFee is false set fees to 0
        if (!takeFee) {
            _taxFee       = 0;
            _liquidityFee = 0;
        }
        
        // sender is excluded 
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        // recipient is excluded
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        // neither are excluded 
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        // both are excluded
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        // default
        } else {
            _transferStandard(sender, recipient, amount);
        }
        // reset fees if bool was met above
        if (!takeFee) {
            _taxFee       = previousTaxFee;
            _liquidityFee = previousLiquidityFee;
        }
    }

    /*
     * standard transfer function called internally when neither sender nor recipient is excluded from fee
     */
    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, currentRate);

        _rOwned[sender]    = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        takeTransactionFee(address(this), tLiquidity, currentRate);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    /*
     * transfer function called internally when both sender and recipient is excluded from fee
     */
    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, currentRate);

        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        takeTransactionFee(address(this), tLiquidity, currentRate);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    /*
     * transfer function called internally when only recipient is excluded from fee
     */
    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, currentRate);

        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        takeTransactionFee(address(this), tLiquidity, currentRate);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    /*
     * transfer function called internally when only sender is excluded from fee
     */
    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, currentRate);

        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        
        takeTransactionFee(address(this), tLiquidity, currentRate);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

}