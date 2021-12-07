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
        address tokenR;
        uint256 refFee;
        uint256 devFee;
    }
    mapping(address => FeeInfo) public pairInfo;  // pair address => fee info
    uint256 public feeDenominator = 10000;  // fee denominator
    
    struct SwapInfo {
        uint256 timestamp;
        address tokenA;
        address tokenB;
        address tokenR;     // reward token
        uint256 amountA;    // tokenA amount
        uint256 amountB;    // tokenB amount
        uint256 amountR;    // Ref amount
        uint256 amountD;    // Dev amount
    }
    mapping(address => SwapInfo[]) private swapList;  // refer address => swap info

    address public router; // dex router
    
    address devAddr; // dev address
    
    mapping(address => uint256) private _balances;  // refer balance
    
    mapping(address => address) public referrers; // user address => referrer address
    mapping(address => uint256) public referralsCount; // referrer address => referrals count

    event ReferralRecorded(address indexed user, address indexed referrer);

    modifier onlyRouter {
        require(msg.sender == router, "caller is not the router");
        _;
    }

    constructor() public {}

    function recordReferral(address _user, address _referrer) public {
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

    function setRouter(address _router) public onlyOwner {
        router = _router;
    }
    
    function setFeeInfo(address _pair, address _rewardToken, uint256 _refFee, uint256 _devFee) public onlyOwner {
        pairInfo[_pair].tokenR = _rewardToken;
        pairInfo[_pair].refFee = _refFee;
        pairInfo[_pair].devFee = _devFee;
    }
    
    function rewardBalance(address account) public view returns (uint256) {
        return _balances[account];
    }
    
    // function claim() public {
    //     uint256 balance = _balances[msg.sender];
    //     if (balance > 0) {
    //         koda.transfer(msg.sender, balance);
    //         _balances[msg.sender] = 0;
    //     }
    // }

    function claimReward(uint256 _id) public {
        SwapInfo memory info = swapList[msg.sender][_id];
        IERC20(info.tokenR).transfer(msg.sender, info.amountR);
        swapList[msg.sender][_id].amountR = 0;
    }
    
    function swap(address user, address _tokenA, address _tokenB, uint256 _amountA, uint256 _amountB) public onlyRouter {
        address referrer = referrers[user];
        if (referrer == address(0)) {
            return;
        }

        address factory = ISummitswapRouter02(router).factory();
        address wbnb = ISummitswapRouter02(router).WETH();
        address pair = ISummitswapFactory(factory).getPair(_tokenA, _tokenB);

        address rewardToken = pairInfo[pair].tokenR;
        if (rewardToken == address(0)) {
            return;
        }

        uint256 amountReward;

        if (_tokenA == rewardToken) {
            amountReward = _amountA;
        } else if (_tokenA == wbnb) {
            address[] memory path = new address[](2);
            path[0] = wbnb;
            path[1] = rewardToken;
            uint256[] memory amountsOut = ISummitswapRouter02(router).getAmountsOut(_amountA, path);
            amountReward = amountsOut[1];
        } else {
            address[] memory path = new address[](3);
            path[0] = _tokenA;
            path[1] = wbnb;
            path[2] = rewardToken;
            uint[] memory amountsOut = ISummitswapRouter02(router).getAmountsOut(_amountA, path);
            amountReward = amountsOut[2];
        }
        
        uint256 amountR = amountReward.mul(pairInfo[pair].refFee).div(feeDenominator);
        uint256 amountD = amountReward.mul(pairInfo[pair].devFee).div(feeDenominator);
        
        swapList[referrer].push(
            SwapInfo({
                timestamp: block.timestamp,
                tokenA: _tokenA,
                tokenB: _tokenB,
                tokenR: rewardToken,
                amountA: _amountA,
                amountB: _amountB,
                amountR: amountR,
                amountD: amountD
            })
        );
        
        _balances[referrer] += amountR;
        if (devAddr != address(0)) {
            _balances[devAddr] += amountD;
        }
    }

    function getSwapList(address _referrer) public view returns (SwapInfo[] memory result) {
        result = swapList[_referrer];
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