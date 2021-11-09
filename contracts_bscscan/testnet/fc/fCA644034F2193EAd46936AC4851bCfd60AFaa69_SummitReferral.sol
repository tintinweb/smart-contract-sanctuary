pragma solidity =0.6.6;
pragma experimental ABIEncoderV2;

import 'summitswapcore/contracts/interfaces/ISummitswapFactory.sol';
import './libraries/SafeMath.sol';
import './interfaces/IERC20.sol';
import './interfaces/ISummitswapRouter02.sol';

contract Ownable {
    address private _owner;

    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function isOwner(address account) public view returns (bool) {
        return account == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }


    modifier onlyOwner() {
        require(isOwner(msg.sender), "Ownable: caller is not the owner");
        _;
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}

contract SummitReferral is Ownable {
    using SafeMath for uint256;
    
    struct FeeInfo {
        uint256 refFee;
        uint256 devFee;
    }
    mapping(address => FeeInfo) public pairFeeList;  // pair address => fee info
    
    struct SwapInfo {
        uint256 timestamp;
        address tokenA;
        address tokenB;
        uint256 amountA;
        uint256 amountB;
        uint256 amountR;
    }
    mapping(address => SwapInfo[]) public refList;  // refer address => swap info

    address public router; // dex router
    
    IERC20 public koda; // The KODA token for reward.
    
    address devAddr; // dev address
    
    mapping(address => uint256) private _balances;  // refer balance
    
    mapping(address => address) public referrers; // user address => referrer address
    mapping(address => uint256) public referralsCount; // referrer address => referrals count

    event ReferralRecorded(address indexed user, address indexed referrer);

    modifier onlyRouter {
        require(msg.sender == router, "caller is not the router");
        _;
    }

    constructor(IERC20 _koda) public {
        koda = _koda;
    }

    function recordReferral(address _user, address _referrer) public onlyOwner {
        if (_user != address(0)
            && _referrer != address(0)
            && _user != _referrer
            && referrers[_user] == address(0)
        ) {
            referrers[_user] = _referrer;
            referralsCount[_referrer] += 1;
            emit ReferralRecorded(_user, _referrer);
        }
    }

    // Get the referrer address that referred the user
    function getReferrer(address _user) public view returns (address) {
        return referrers[_user];
    }
    
    function setDevAddress(address _devAddr) public onlyOwner {
        devAddr = _devAddr;
    }

    function setKoda(IERC20 _koda) public onlyOwner {
        koda = _koda;
    }

    function setRouter(address _router) public onlyOwner {
        router = _router;
    }
    
    function setFeeInfo(address _pair, uint256 _refFee, uint256 _devFee) public onlyOwner {
        pairFeeList[_pair].refFee = _refFee;
        pairFeeList[_pair].devFee = _devFee;
    }
    
    function rewardBalance(address account) public view returns (uint256) {
        return _balances[account];
    }
    
    function claim() public {
        uint256 balance = _balances[msg.sender];
        if (balance > 0) {
            koda.transfer(msg.sender, balance);
        }
    }
    
    function swap(address user, address _tokenA, address _tokenB, uint256 _amountA, uint256 _amountB) public {
        address referrer = referrers[user];
        if (referrer == address(0)) {
            return;
        }

        address factory = ISummitswapRouter02(router).factory();
        address wbnb = ISummitswapRouter02(router).WETH();
        address pair = ISummitswapFactory(factory).getPair(_tokenA, _tokenB);

        uint256 amountKoda;

        if (_tokenA == address(koda)) {
            amountKoda = _amountA;
        } else if (_tokenA == wbnb) {
            address[] memory path = new address[](2);
            path[0] = wbnb;
            path[1] = address(koda);
            uint256[] memory amountsOut = ISummitswapRouter02(router).getAmountsOut(_amountA, path);
            amountKoda = amountsOut[1];
        } else {
            address[] memory path = new address[](3);
            path[0] = _tokenA;
            path[1] = wbnb;
            path[2] = address(koda);
            uint[] memory amountsOut = ISummitswapRouter02(router).getAmountsOut(_amountA, path);
            amountKoda = amountsOut[2];
        }


        uint256 refFee = 2;
        uint256 devFee = 1;
        
        if (pairFeeList[pair].devFee != 0) {
            devFee = pairFeeList[pair].devFee;
        }
        if (pairFeeList[pair].refFee != 0) {
            refFee = pairFeeList[pair].refFee;
        }
        
        uint256 amountR = amountKoda.mul(refFee).div(100);
        uint256 amountDev = amountKoda.mul(devFee).div(100);
        
        refList[referrer].push(SwapInfo({
            timestamp: block.timestamp,
            tokenA: _tokenA,
            tokenB: _tokenB,
            amountA: _amountA,
            amountB: _amountB,
            amountR: amountR
        }));
        
        _balances[referrer] += amountR;
        if (devAddr != address(0)) {
            _balances[devAddr] += amountDev;
        }
    }

    function swapInfo(address _referrer) public view returns (SwapInfo[] memory result) {
        result = refList[_referrer];
    }
}

pragma solidity >=0.5.0;

interface ISummitswapFactory {
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

pragma solidity =0.6.6;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

pragma solidity >=0.6.2;

import './ISummitswapRouter01.sol';

interface ISummitswapRouter02 is ISummitswapRouter01 {
    function summitReferral() external pure returns (address);

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

pragma solidity >=0.6.2;

interface ISummitswapRouter01 {
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

pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}