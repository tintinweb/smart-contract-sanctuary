/**
 *Submitted for verification at BscScan.com on 2021-09-14
*/

// SPDX-License-Identifier: MIT

// Transfer Fee:  9%
// Buy Fee:       9%
// Sell Fee:     27%

// Fees Go Toward:
//    21% BakeryToken, BurgerSwap, PancakeSwap Distribution
//     3% Marketing
//     2% Burn

pragma solidity ^0.8.7;

// IERC20 interface taken from: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol)
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// Context abstract contract taken from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SafeMath library taken from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol
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

// Address library taken from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol
library Address {
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // the easiest way to bubble the revert reason is using memory via assembly

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

// Ownable abstract contract taken from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }
    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// IUniswapV2Factory interface taken from: https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/interfaces/IUniswapV2Factory.sol
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

// IUniswapV2Pair interface taken from: https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/interfaces/IUniswapV2Pair.sol
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

// IUniswapV2Router01 interface taken from: https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router01.sol
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

// IUniswapV2Router02 interface taken from: https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router02.sol 
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

interface IBAKEDistributor {
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution, uint256 _bnbToBAKEThreshold) external;
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external;
    function process(uint256 gas) external;
    function processManually() external returns(bool);
    function claimBAKEDividend(address sender) external;
    function setBAKEGAS(uint256 gas) external;
    function setBAKEAddress(address nBAKE) external;
}

contract BAKEDistributor is IBAKEDistributor {
    using SafeMath for uint256;
    using Address for address;
    // BAKE Contract
    address _token;
    // Share of the BAKE Pie
    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }
    // BakeryToken contract address
    address BAKE = 0xE02dF9e3e622DeBdD69fb838bB799E3F168902c5;
    // Pancakeswap Router
    IUniswapV2Router02 router;
    // shareholder fields
    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;
    
    mapping (address => Share) public shares;
    
    // shares math and fields
    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;
   
    // once the minimum distribution limit is hit after "minPeriod" it awards the reward
    uint256 public minPeriod = 30 minutes;
    uint256 public minDistribution = 0.1 * 10**18; // 0.1 CAKE minimum auto send
    uint256 public swapToBAKEThreshold = 100 * 10**9 * 10**9; // 100 Billion BAKEaBURGERCAKE Needed to Swap to BAKE
    // gas limit for purchasing BAKE
    uint256 BAKEGAS = 500000;
   
    uint256 currentIndex;
    
    modifier onlyToken() {
        require(msg.sender == _token); _;
    }
    // Testnet: 0xD99D1c33F9fC3444f8101754aBC46c52416550D1
    // Mainet: 0x10ED43C718714eb63d5aA57B78B54704E256024E
    constructor (address _router) {
        router = _router != address(0)
        ? IUniswapV2Router02 (_router)
        : IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
        _token = msg.sender;
    }
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution, uint256 _bnbToBAKEThreshold) external override onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
        swapToBAKEThreshold = _bnbToBAKEThreshold;
    }
    function setShare(address shareholder, uint256 amount) external override onlyToken {
        if(shares[shareholder].amount > 0){
            distributeDividend(shareholder);
        }
        if(amount > 0 && shares[shareholder].amount == 0){
            addShareholder(shareholder);
        }else if(amount == 0 && shares[shareholder].amount > 0){
            removeShareholder(shareholder);
        }
        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }
    function deposit() external override onlyToken {
        depositInternally();
    }
    function depositInternally() private {
        
        if (address(this).balance >= swapToBAKEThreshold) {
            
            uint256 balanceBefore = IERC20(BAKE).balanceOf(address(this));
            
            (bool successful,) = payable(BAKE).call{value: swapToBAKEThreshold, gas: BAKEGAS}("");
            if (successful) {
                uint256 amount = IERC20(BAKE).balanceOf(address(this)).sub(balanceBefore);

                totalDividends = totalDividends.add(amount);
                dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
            }
        }
    }
    function process(uint256 gas) external override onlyToken {
        uint256 shareholderCount = shareholders.length;

        if(shareholderCount == 0) { return; }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        uint256 iterations = 0;

        while(gasUsed < gas && iterations < shareholderCount) {
            if(currentIndex >= shareholderCount){
                currentIndex = 0;
            }
            if(shouldDistribute(shareholders[currentIndex])){
                distributeDividend(shareholders[currentIndex]);
            }
            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }
    function processManually() external override returns(bool) {
        uint256 shareholderCount = shareholders.length;
        
        if(shareholderCount == 0) { return false; }

        uint256 iterations = 0;
        uint256 index = 0;

        while(iterations < shareholderCount) {
            if(index >= shareholderCount){
                index = 0;
            }
            if(shouldDistribute(shareholders[index])){
                distributeDividend(shareholders[index]);
            }
            index++;
            iterations++;
        }
        return true;
    }
    function shouldDistribute(address shareholder) internal view returns (bool) {
        return shareholderClaims[shareholder] + minPeriod < block.timestamp
        && getUnpaidEarnings(shareholder) > minDistribution;
    }
    function distributeDividend(address shareholder) internal {
        if(shares[shareholder].amount == 0){ return; }
        uint256 amount = getUnpaidEarnings(shareholder);
        if(amount > 0){
            totalDistributed = totalDistributed.add(amount);
            IERC20(BAKE).transfer(shareholder, amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
        }
    }
    function claimBAKEDividend(address claimer) external override onlyToken {
        require(shareholderClaims[claimer] + minPeriod < block.timestamp, 'must wait at least the minimum auto withdraw period');
        distributeDividend(claimer);
    }
    function claimDividend() external {
        require(shouldDistribute(msg.sender), 'Must wait to claim dividend!');
        distributeDividend(msg.sender);
    }
    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if(shares[shareholder].amount == 0){ return 0; }

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }

        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }
    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
    }
    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }
    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length-1];
        shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }
    // Sets the Gas of the Purchase BAKE Function
    function setBAKEGAS(uint256 gas) external override onlyToken {
        BAKEGAS = gas;
    }
    // New BAKE Address
    function setBAKEAddress(address newBAKE) external override onlyToken {
        BAKE = newBAKE;
    }
    receive() external payable { 
        depositInternally();
    }
}

interface IBURGERDistributor {
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution, uint256 _bnbToBURGERThreshold) external;
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external;
    function process(uint256 gas) external;
    function processManually() external returns(bool);
    function claimBURGERDividend(address sender) external;
    function setBURGERGAS(uint256 gas) external;
    function setBURGERAddress(address nBURGER) external;
}

contract BURGERDistributor is IBURGERDistributor {
    using SafeMath for uint256;
    using Address for address;
    // BURGER Contract
    address _token;
    // Share of the BURGER Pie
    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }
    // BurgerSwap contract address
    address BURGER = 0xAe9269f27437f0fcBC232d39Ec814844a51d6b8f;
    // Pancakeswap Router
    IUniswapV2Router02 router;
    // shareholder fields
    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;
    
    mapping (address => Share) public shares;
    
    // shares math and fields
    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;
   
    // once the minimum distribution limit is hit after "minPeriod" it awards the reward
    uint256 public minPeriod = 30 minutes;
    uint256 public minDistribution = 0.1 * 10**18; // 0.1 CAKE minimum auto send
    uint256 public swapToBURGERThreshold = 100 * 10**9 * 10**9; // 100 Billion BAKEaBURGERCAKE Needed to Swap to BURGER
    // gas limit for purchasing BURGER
    uint256 BURGERGAS = 500000;
   
    uint256 currentIndex;
    
    modifier onlyToken() {
        require(msg.sender == _token); _;
    }
    // Testnet: 0xD99D1c33F9fC3444f8101754aBC46c52416550D1
    // Mainet: 0x10ED43C718714eb63d5aA57B78B54704E256024E
    constructor (address _router) {
        router = _router != address(0)
        ? IUniswapV2Router02 (_router)
        : IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
        _token = msg.sender;
    }
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution, uint256 _bnbToBURGERThreshold) external override onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
        swapToBURGERThreshold = _bnbToBURGERThreshold;
    }
    function setShare(address shareholder, uint256 amount) external override onlyToken {
        if(shares[shareholder].amount > 0){
            distributeDividend(shareholder);
        }
        if(amount > 0 && shares[shareholder].amount == 0){
            addShareholder(shareholder);
        }else if(amount == 0 && shares[shareholder].amount > 0){
            removeShareholder(shareholder);
        }
        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }
    function deposit() external override onlyToken {
        depositInternally();
    }
    function depositInternally() private {
        
        if (address(this).balance >= swapToBURGERThreshold) {
            
            uint256 balanceBefore = IERC20(BURGER).balanceOf(address(this));
            
            (bool successful,) = payable(BURGER).call{value: swapToBURGERThreshold, gas: BURGERGAS}("");
            if (successful) {
                uint256 amount = IERC20(BURGER).balanceOf(address(this)).sub(balanceBefore);

                totalDividends = totalDividends.add(amount);
                dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
            }
        }
    }
    function process(uint256 gas) external override onlyToken {
        uint256 shareholderCount = shareholders.length;

        if(shareholderCount == 0) { return; }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        uint256 iterations = 0;

        while(gasUsed < gas && iterations < shareholderCount) {
            if(currentIndex >= shareholderCount){
                currentIndex = 0;
            }
            if(shouldDistribute(shareholders[currentIndex])){
                distributeDividend(shareholders[currentIndex]);
            }
            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }
    function processManually() external override returns(bool) {
        uint256 shareholderCount = shareholders.length;
        
        if(shareholderCount == 0) { return false; }

        uint256 iterations = 0;
        uint256 index = 0;

        while(iterations < shareholderCount) {
            if(index >= shareholderCount){
                index = 0;
            }
            if(shouldDistribute(shareholders[index])){
                distributeDividend(shareholders[index]);
            }
            index++;
            iterations++;
        }
        return true;
    }
    function shouldDistribute(address shareholder) internal view returns (bool) {
        return shareholderClaims[shareholder] + minPeriod < block.timestamp
        && getUnpaidEarnings(shareholder) > minDistribution;
    }
    function distributeDividend(address shareholder) internal {
        if(shares[shareholder].amount == 0){ return; }
        uint256 amount = getUnpaidEarnings(shareholder);
        if(amount > 0){
            totalDistributed = totalDistributed.add(amount);
            IERC20(BURGER).transfer(shareholder, amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
        }
    }
    function claimBURGERDividend(address claimer) external override onlyToken {
        require(shareholderClaims[claimer] + minPeriod < block.timestamp, 'must wait at least the minimum auto withdraw period');
        distributeDividend(claimer);
    }
    function claimDividend() external {
        require(shouldDistribute(msg.sender), 'Must wait to claim dividend!');
        distributeDividend(msg.sender);
    }
    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if(shares[shareholder].amount == 0){ return 0; }

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }

        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }
    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
    }
    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }
    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length-1];
        shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }
    // Sets the Gas of the Purchase BURGER Function
    function setBURGERGAS(uint256 gas) external override onlyToken {
        BURGERGAS = gas;
    }
    // New BURGER Address
    function setBURGERAddress(address newBURGER) external override onlyToken {
        BURGER = newBURGER;
    }
    receive() external payable { 
        depositInternally();
    }
}

interface ICAKEDistributor {
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution, uint256 _bnbToCAKEThreshold) external;
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external;
    function process(uint256 gas) external;
    function processManually() external returns(bool);
    function claimCAKEDividend(address sender) external;
    function setCAKEGAS(uint256 gas) external;
    function setCAKEAddress(address nCAKE) external;
}

contract CAKEDistributor is ICAKEDistributor {
    using SafeMath for uint256;
    using Address for address;
    // CAKE Contract
    address _token;
    // Share of the CAKE Pie
    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }
    // PancakeSwap contract address
    address CAKE = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;
    // Pancakeswap Router
    IUniswapV2Router02 router;
    // shareholder fields
    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;
    
    mapping (address => Share) public shares;
    
    // shares math and fields
    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;
   
    // once the minimum distribution limit is hit after "minPeriod" it awards the reward
    uint256 public minPeriod = 30 minutes;
    uint256 public minDistribution = 0.1 * 10**18; // 0.1 CAKE minimum auto send
    uint256 public swapToCAKEThreshold = 100 * 10**9 * 10**9; // 100 Billion BAKEaBURGERCAKE Needed to Swap to CAKE
    // gas limit for purchasing CAKE
    uint256 CAKEGAS = 500000;
   
    uint256 currentIndex;
    
    modifier onlyToken() {
        require(msg.sender == _token); _;
    }
    // Testnet: 0xD99D1c33F9fC3444f8101754aBC46c52416550D1
    // Mainet: 0x10ED43C718714eb63d5aA57B78B54704E256024E
    constructor (address _router) {
        router = _router != address(0)
        ? IUniswapV2Router02 (_router)
        : IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
        _token = msg.sender;
    }
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution, uint256 _bnbToCAKEThreshold) external override onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
        swapToCAKEThreshold = _bnbToCAKEThreshold;
    }
    function setShare(address shareholder, uint256 amount) external override onlyToken {
        if(shares[shareholder].amount > 0){
            distributeDividend(shareholder);
        }
        if(amount > 0 && shares[shareholder].amount == 0){
            addShareholder(shareholder);
        }else if(amount == 0 && shares[shareholder].amount > 0){
            removeShareholder(shareholder);
        }
        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }
    function deposit() external override onlyToken {
        depositInternally();
    }
    function depositInternally() private {
        
        if (address(this).balance >= swapToCAKEThreshold) {
            
            uint256 balanceBefore = IERC20(CAKE).balanceOf(address(this));
            
            (bool successful,) = payable(CAKE).call{value: swapToCAKEThreshold, gas: CAKEGAS}("");
            if (successful) {
                uint256 amount = IERC20(CAKE).balanceOf(address(this)).sub(balanceBefore);

                totalDividends = totalDividends.add(amount);
                dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
            }
        }
    }
    function process(uint256 gas) external override onlyToken {
        uint256 shareholderCount = shareholders.length;

        if(shareholderCount == 0) { return; }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        uint256 iterations = 0;

        while(gasUsed < gas && iterations < shareholderCount) {
            if(currentIndex >= shareholderCount){
                currentIndex = 0;
            }
            if(shouldDistribute(shareholders[currentIndex])){
                distributeDividend(shareholders[currentIndex]);
            }
            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }
    function processManually() external override returns(bool) {
        uint256 shareholderCount = shareholders.length;
        
        if(shareholderCount == 0) { return false; }

        uint256 iterations = 0;
        uint256 index = 0;

        while(iterations < shareholderCount) {
            if(index >= shareholderCount){
                index = 0;
            }
            if(shouldDistribute(shareholders[index])){
                distributeDividend(shareholders[index]);
            }
            index++;
            iterations++;
        }
        return true;
    }
    function shouldDistribute(address shareholder) internal view returns (bool) {
        return shareholderClaims[shareholder] + minPeriod < block.timestamp
        && getUnpaidEarnings(shareholder) > minDistribution;
    }
    function distributeDividend(address shareholder) internal {
        if(shares[shareholder].amount == 0){ return; }
        uint256 amount = getUnpaidEarnings(shareholder);
        if(amount > 0){
            totalDistributed = totalDistributed.add(amount);
            IERC20(CAKE).transfer(shareholder, amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
        }
    }
    function claimCAKEDividend(address claimer) external override onlyToken {
        require(shareholderClaims[claimer] + minPeriod < block.timestamp, 'must wait at least the minimum auto withdraw period');
        distributeDividend(claimer);
    }
    function claimDividend() external {
        require(shouldDistribute(msg.sender), 'Must wait to claim dividend!');
        distributeDividend(msg.sender);
    }
    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if(shares[shareholder].amount == 0){ return 0; }

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }

        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }
    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
    }
    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }
    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length-1];
        shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }
    // Sets the Gas of the Purchase CAKE Function
    function setCAKEGAS(uint256 gas) external override onlyToken {
        CAKEGAS = gas;
    }
    // New CAKE Address
    function setCAKEAddress(address newCAKE) external override onlyToken {
        CAKE = newCAKE;
    }
    receive() external payable { 
        depositInternally();
    }
}

// Official BAKEaBURGERCAKE Contract
contract BAKEaBURGERCAKE is IERC20, Context, Ownable {
    using SafeMath for uint256;
    using SafeMath for uint8;
    using Address for address;
    
    // our BakeryToken, BurgerSwap, PancakeSwap Distributor 
    BAKEDistributor public distributor;
    BURGERDistributor public burgerDistributor;
    CAKEDistributor public cakeDistributor;

    // General Info
    string constant _name = "BAKEaBURGERCAKE";
    string constant _symbol = "BABUCA";
    uint8 constant _decimals = 9;

    // Total Supply
    uint256 _totalSupply = 1 * 10**15 * 10**9; // 1 quadrillion

    // Address
    address public BAKE     = address(0xE02dF9e3e622DeBdD69fb838bB799E3F168902c5); //BakeryToken
    address public BURGER   = address(0xAe9269f27437f0fcBC232d39Ec814844a51d6b8f); //BurgerSwap
    address public CAKE     = address(0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82); //PancakeSwap
    address        ZERO     = 0x0000000000000000000000000000000000000000;
    address public DEAD     = 0x000000000000000000000000000000000000dEaD;
    address public marketingFeeReceiver = 0x142F7Dbf573a800ec8B3a287bEf7695B4D804dA1; // Marketing address used to pay for marketing
 
    // Balances
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;
    
    // Exemptions
    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isDividendExempt;
    
    // Token Limits
    uint256 public _maxTxAmount        = 1 * 10**15 * 10**9;  // 1 quadrillion
    uint256 public _tokenSwapThreshold = 100 * 10**9 * 10**9; // 100 billion
    
    // Token Tax Settings
    uint256 public burnFee              =   3;
    uint256 public BAKE_reflectionFee   =   7;
    uint256 public BURGER_reflectionFee =   7;
    uint256 public CAKE_reflectionFee   =   7;
    uint256 public marketingFee         =   3;

    uint256 public totalFeeSells   =  27;
    uint256 public totalFeeBuys    =   9;
    uint256 feeDenominator         = 100;
    
    // Gas Limit
    uint256 public BakeGAS = 500000;
    uint256 public BurgerGAS = 500000;
    uint256 public CakeGAS = 500000;
    uint256 public minimumToDistribute = 0.1 * 10**18;
    
    IUniswapV2Router02 public router;
    address public pair;
    
    bool public allowTransferToMarketing = true;
    
    uint256 public launchedAt;
    uint256 public launchedAtTimestamp;

    uint256 distributorGas = 500000;
    
    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply.div(1000); // 0.1% = 1 Trillion
    // true if our threshold decreases with circulating supply
    bool public canChangeSwapThreshold = false;
    uint256 public swapThresholdPercentOfCirculatingSupply = 1000;
    bool inSwap;
    bool isDistributing;
    // false to stop the burn
    bool burnEnabled = true;
    modifier swapping() { inSwap = true; _; inSwap = false; }
    modifier distributing() { isDistributing = true; _; isDistributing = false; }
 
    // PancakeSwap Router V2
    // Testnet: 0xD99D1c33F9fC3444f8101754aBC46c52416550D1
    // Mainet: 0x10ED43C718714eb63d5aA57B78B54704E256024E
    address private _dexRouter = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1;
    
    // initialize some stuff
    constructor () {
        // Pancakeswap V2 Router
        router = IUniswapV2Router02(_dexRouter);
        pair = IUniswapV2Factory(router.factory()).createPair(router.WETH(), address(this));
        _allowances[address(this)][address(router)] = _totalSupply;
        // our BAKE Distributor
        distributor = new BAKEDistributor(_dexRouter);
        // our BURGER distributor
        burgerDistributor = new BURGERDistributor(_dexRouter);
        // our CAKE distributor
        cakeDistributor = new CAKEDistributor(_dexRouter);
        
        // exempt deployer and contract from fees
        isFeeExempt[msg.sender] = true;
        isFeeExempt[address(this)] = true;
        // exempt important addresses from TX limit
        isTxLimitExempt[msg.sender] = true;
        isTxLimitExempt[marketingFeeReceiver] = true;
        isTxLimitExempt[address(distributor)] = true;
        isTxLimitExempt[address(burgerDistributor)] = true;
        isTxLimitExempt[address(cakeDistributor)] = true;
        isTxLimitExempt[address(this)] = true;
        // exempt this important addresses from receiving Rewards
        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;
        // approve router of total supply
        approve(_dexRouter, _totalSupply);
        approve(address(pair), _totalSupply);
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }
    function name() public pure returns (string memory) {
        return _name;
    }
    function symbol() public pure returns (string memory) {
        return _symbol;
    }
    function decimals() public pure returns (uint8) {
        return _decimals;
    }
    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    function internalApprove(address spender, uint256 amount) internal returns (bool) {
        _allowances[msg.sender][spender] = amount;
        return true;
    }
    // Approve Total Supply
    function approveMax(address spender) external returns (bool) {
        return approve(spender, _totalSupply);
    }
    // Transfer Function
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }
    // Transfer Function
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != _totalSupply){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }
        return _transferFrom(sender, recipient, amount);
    }
    //Internal Transfer
    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        // make standard checks
        require(recipient != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        // check if we have reached the transaction limit
        require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
        // whether transfer succeeded
        bool success;
        // if we're in swap perform a basic transfer
        if(inSwap || isDistributing){ 
            (, success) = handleTransferBody(sender, recipient, amount); 
            return success;
        }
        // amount of tokens received by recipient
        uint256 amountReceived;
        // limit gas consumption by splitting up operations
        if(shouldSwapBack()) { 
            swapBack();
            (amountReceived, success) = handleTransferBody(sender, recipient, amount);
        } else if (shouldReflectAndDistribute()) {
            reflectAndDistribute();
            (amountReceived, success) = handleTransferBody(sender, recipient, amount);
        } else {
            (amountReceived, success) = handleTransferBody(sender, recipient, amount);
            try distributor.process(distributorGas) {} catch {}
            try burgerDistributor.process(distributorGas) {} catch {}
            try cakeDistributor.process(distributorGas) {} catch {}  
        }
        
        emit Transfer(sender, recipient, amountReceived);
        return success;
    }
    // Takes Associated Fees and sets holders' new Share for the Distributor
    function handleTransferBody(address sender, address recipient, uint256 amount) internal returns (uint256, bool) {
        // subtract balance from sender
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        // amount receiver should receive
        uint256 amountReceived = shouldTakeFee(sender) ? takeFee(recipient, amount) : amount;
        // add amount to recipient
        _balances[recipient] = _balances[recipient].add(amountReceived);
        // set shares for distributors
        if(!isDividendExempt[sender]){ 
            distributor.setShare(sender, _balances[sender]);
            burgerDistributor.setShare(sender, _balances[sender]);
            cakeDistributor.setShare(sender, _balances[sender]);
        }
        if(!isDividendExempt[recipient]){ 
            distributor.setShare(recipient, _balances[recipient]);
            burgerDistributor.setShare(recipient, _balances[recipient]);
            cakeDistributor.setShare(sender, _balances[recipient]);
        }
        // return the amount received by receiver
        return (amountReceived, true);
    }
    // False if sender is Fee Exempt, True if not
    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }
    // Takes Proper Fee (9% buys / transfers, 27% on sells) and stores in contract
    function takeFee(address receiver, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount.mul(getTotalFee(receiver == pair)).div(feeDenominator);
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        return amount.sub(feeAmount);
    }
    // True if we should swap from BAKEaBURGERCAKE => BNB
    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }
    // Swaps BAKEaBURGERCAKE for BNB if threshold is reached and the swap is enabled
    // Burns 20% of BAKEaBURGERCAKE in Contract
    // Swaps The Rest For BNB
    function swapBack() private swapping {
        // path from token -> BNB
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        // tokens allocated to burning
        uint256 burnAmount = swapThreshold.mul(burnFee).div(totalFeeSells);
        // burn tokens
        burnTokens(burnAmount);
        // how many are left to swap with
        uint256 swapAmount = swapThreshold.sub(burnAmount);
        // swap tokens for BNB
        try router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            swapAmount,
            0,
            path,
            address(this),
            block.timestamp
        ) {} catch{return;}
        
        // Tell The Blockchain
        emit SwappedBack(swapAmount, burnAmount);
    }
    function shouldReflectAndDistribute() private view returns(bool) {
        return msg.sender != pair
        && !isDistributing
        && swapEnabled
        && address(this).balance >= minimumToDistribute;
    }
    function reflectAndDistribute() private distributing {
        bool successful;
        // how much bnb is sent to reflections, and marketing
        uint256 amountBNBMarketing = address(this).balance.mul(marketingFee).div(totalFeeSells);
        uint256 amountBNBReflection = address(this).balance.sub(amountBNBMarketing);
        // amount for BAKE
        uint256 BAKE_Amount = amountBNBReflection.div(BAKE_reflectionFee);
        // amount for BURGER
        uint256 BURGER_Amount = amountBNBReflection.div(BURGER_reflectionFee);
        // amount for CAKE
        uint256 CAKE_Amount = amountBNBReflection.div(CAKE_reflectionFee);
        if (allowTransferToMarketing) {
            (successful,) = payable(marketingFeeReceiver).call{value: amountBNBMarketing, gas: 30000}("");
        }
            emit FundDistributors(BAKE_Amount, BURGER_Amount, CAKE_Amount, amountBNBMarketing);
    }
    // Removes Tokens From Circulation
    function burnTokens(uint256 tokenAmount) private returns (bool) {
        if (!burnEnabled) {
            return false;
        }
        // update balance of contract
        _balances[address(this)] = _balances[address(this)].sub(tokenAmount, 'cannot burn this amount');
        // update Total Supply
        _totalSupply = _totalSupply.sub(tokenAmount, 'total supply cannot be negative');
        // approve PCS Router for total supply
        internalApprove(_dexRouter, _totalSupply);
        // approve initial liquidity pair for total supply
        internalApprove(address(pair), _totalSupply);
        // change Swap Threshold if we should
        if (canChangeSwapThreshold) {
            swapThreshold = _totalSupply.div(swapThresholdPercentOfCirculatingSupply);
        }
        // emit Transfer to Blockchain
        emit Transfer(address(this), address(0), tokenAmount);
        return true;
    }
    //Claim Your BAKE Rewards
    function claimBAKEDividend() external returns (bool) {
        distributor.claimBAKEDividend(msg.sender);
        return true;
    }
    // Claim Your BURGER Rewards
    function claimBURGERDividend() external returns (bool) {
        burgerDistributor.claimBURGERDividend(msg.sender);
        return true;
    }
     // Claim Your CAKE Rewards
    function claimCAKEDividend() external returns (bool) {
        cakeDistributor.claimCAKEDividend(msg.sender);
        return true;
    }
    // Claim Your BAKE Rewards Early
    function getUnpaidBAKEEarnings() public view returns (uint256) {
        return distributor.getUnpaidEarnings(msg.sender);
    }
    // Claim Your BURGER Rewards Early
    function getUnpaidBURGEREarnings() public view returns (uint256) {
        return burgerDistributor.getUnpaidEarnings(msg.sender);
    }
    // Claim Your CAKE Rewards Early
    function getUnpaidCAKEEarnings() public view returns (uint256) {
        return cakeDistributor.getUnpaidEarnings(msg.sender);
    }
    // Manually Depsoits To The Surge or Vault Contract
    function manuallyDeposit(bool depositBAKE) external returns (bool){
        if (depositBAKE) {
            distributor.deposit();
        } else {
            burgerDistributor.deposit();
            cakeDistributor.deposit();
        }
        return true;
    }
    
    // Is Holder Exempt From Fees
    function getIsFeeExempt(address holder) public view returns (bool) {
        return isFeeExempt[holder];
    }
    // Is Holder Exempt From Dividends
    function getIsDividendExempt(address holder) public view returns (bool) {
        return isDividendExempt[holder];
    }
    // Is Holder Exempt From Transaction Limit
    function getIsTxLimitExempt(address holder) public view returns (bool) {
        return isTxLimitExempt[holder];
    }
    // Get Fees for Buying or Selling
    function getTotalFee(bool selling) public view returns (uint256) {
        if(selling){ return totalFeeSells; }
        return totalFeeBuys;
    }
    // Sets Various Fees
    function setFees(uint256 _burnFee, uint256 _BAKE_reflectionFee, uint256 _BURGER_reflectionFee, uint256 _CAKE_reflectionFee, uint256 _marketingFee, uint256 _buyFee) external onlyOwner {
        burnFee = _burnFee;
        BAKE_reflectionFee = _BAKE_reflectionFee;
        BURGER_reflectionFee = _BURGER_reflectionFee;
        CAKE_reflectionFee = _CAKE_reflectionFee;
        marketingFee = _marketingFee;
        totalFeeSells = _burnFee.add(_BAKE_reflectionFee).add(_BURGER_reflectionFee).add(_CAKE_reflectionFee).add(_marketingFee);
        totalFeeBuys = _buyFee;
        require(_buyFee <= 1000);
        require(totalFeeSells < feeDenominator/2);

    }
    // Set Exemption For Holder
    function setIsFeeAndTXLimitExempt(address holder, bool feeExempt, bool txLimitExempt) external onlyOwner {
        require(holder != address(0));
        isFeeExempt[holder] = feeExempt;
        isTxLimitExempt[holder] = txLimitExempt;
    }
    // Set Holder To Be Exempt From Dividends
    function setIsDividendExempt(address holder, bool exempt) external onlyOwner {
        require(holder != address(this) && holder != pair);
        isDividendExempt[holder] = exempt;
        if(exempt) {
            distributor.setShare(holder, 0);
            burgerDistributor.setShare(holder, 0);
            cakeDistributor.setShare(holder, 0);
            
        } else {
            distributor.setShare(holder, _balances[holder]);
            burgerDistributor.setShare(holder, _balances[holder]);
            cakeDistributor.setShare(holder, _balances[holder]);
        }
    }
     /** Set Settings related to Swaps */
    function setSwapBackSettings(bool _swapEnabled, uint256 _swapThreshold, bool _canChangeSwapThreshold, uint256 _percentOfCirculatingSupply, bool _burnEnabled, uint256 _minimumBNBToDistribute) external onlyOwner {
        swapEnabled = _swapEnabled;
        swapThreshold = _swapThreshold;
        canChangeSwapThreshold = _canChangeSwapThreshold;
        swapThresholdPercentOfCirculatingSupply = _percentOfCirculatingSupply;
        burnEnabled = _burnEnabled;
        minimumToDistribute = _minimumBNBToDistribute;
    }
    // Set Criteria For BAKE Distributor
    function setBAKEDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution, uint256 _bnbToBAKEThreshold) external onlyOwner {
        distributor.setDistributionCriteria(_minPeriod, _minDistribution, _bnbToBAKEThreshold);
    }
    // Set Criteria For BURGER Distributor
    function setBURGERDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution, uint256 _bnbToBURGERThreshold) external onlyOwner {
        burgerDistributor.setDistributionCriteria(_minPeriod, _minDistribution, _bnbToBURGERThreshold);
    }
    // Set Criteria For CAKE Distributor
    function setCAKEDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution, uint256 _bnbToCAKEThreshold) external onlyOwner {
        cakeDistributor.setDistributionCriteria(_minPeriod, _minDistribution, _bnbToCAKEThreshold);
    }
    // Should We Transfer To Marketing
    function setAllowTransferToMarketing(bool _canSendToMarketing, address _marketingFeeReceiver) external onlyOwner {
        allowTransferToMarketing = _canSendToMarketing;
        marketingFeeReceiver = _marketingFeeReceiver;
    }
    // Set Address For Bake Distributor
    function setBAKEDistributor(address payable BAKEDispo) external onlyOwner {
        require(BAKEDispo != address(distributor));
        distributor = BAKEDistributor(BAKEDispo);
        emit SwappedDistributor(true, BAKEDispo);
    }
    // Set Address For Burger Distributor
    function setBurgerDistributor(address payable burgerDispo) external onlyOwner {
        require(burgerDispo != address(burgerDistributor));
        burgerDistributor = BURGERDistributor(burgerDispo);
        emit SwappedDistributor(false, burgerDispo);
    }
    // Set Address For Cake Distributor
    function setCakeDistributor(address payable cakeDispo) external onlyOwner {
        require(cakeDispo != address(cakeDistributor));
        cakeDistributor = CAKEDistributor(cakeDispo);
        emit SwappedDistributor(true, cakeDispo);
    }
    // Swaps BAKE, BURGER and CAKE Addresses in case of migration */
    function setTokenAddresses(address nBAKE, address nBURGER, address nCAKE) external onlyOwner {
        distributor.setBAKEAddress(nBAKE);
        burgerDistributor.setBURGERAddress(nBURGER);
        cakeDistributor.setCAKEAddress(nCAKE);
        emit SwappedTokenAddresses(nBAKE, nBURGER, nCAKE);
    }
    // Deletes the entire bag from sender
    function deleteBag(uint256 nTokens) external returns(bool){
        // make sure you are burning enough tokens
        require(nTokens > 0);
        // if the balance is greater than zero
        require(_balances[msg.sender] >= nTokens, 'user does not own enough tokens');
        // remove tokens from sender
        _balances[msg.sender] = _balances[msg.sender].sub(nTokens, 'cannot have negative tokens');
        // remove tokens from total supply
        _totalSupply = _totalSupply.sub(nTokens, 'total supply cannot be negative');
        // approve PCS Router for the new total supply
        internalApprove(_dexRouter, _totalSupply);
        // approve initial liquidity pair for total supply
        internalApprove(address(pair), _totalSupply);
        // tell blockchain
        emit Transfer(msg.sender, address(0), nTokens);
        return true;
    }
    // Events
    event SwappedDistributor(bool distributor, address newDistributor);
    event SwappedBack(uint256 tokensSwapped, uint256 amountBurned);
    event SwappedTokenAddresses(address newBAKE, address newBURGER, address newCAKE);
    event FundDistributors(uint256 BAKEAmount, uint256 BURGERAmount, uint256 CAKEAmount,uint256 marketingAmount);
}