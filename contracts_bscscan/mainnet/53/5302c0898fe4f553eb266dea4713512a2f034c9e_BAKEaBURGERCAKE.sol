/**
 *Submitted for verification at BscScan.com on 2021-10-12
*/

// SPDX-License-Identifier: MIT

// $BAKEaBURGERCAKE proposes an innovative feature in its contract.

// Hold BAKEaBURGERCAKE and get rewarded in BAKE, BURGER and CAKE on every transaction!

// Transfer Fee:    21%
// Buy / Sell Fee:  21%

// Fees and Reflection:
//      5% BakeryToken
//      5% BurgerSwap
//      5% PancakeSwap
//      2% Liquidity
//      2% Buyback
//      2% Marketing
// 📱 Telegram: https://t.me/BAKEaBUGERCAKE
// 🌎 Website: https://www.bakeaburgercake.com
// 🌐 Twitter: https://twitter.com/BAKEaBURGERCAKE

pragma solidity ^0.8.7;

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
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

interface IBAKEDistributor {
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution, uint256 _bnbToBAKEThreshold) external;
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external;
    function process(uint256 gas) external;
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
    // BAKE Contract Address
    address BAKE = 0xE02dF9e3e622DeBdD69fb838bB799E3F168902c5;
    
    // BNB Address
    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    
    // Pancakeswap Router
    IUniswapV2Router02 router;
    
    // Shareholder Fields
    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;
    mapping (address => Share) public shares;
    
    // Shares Math and Fields
    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;
    
    // Once the Minimum Distribution Limit is hit after "minPeriod" it awards the Rewards
    uint256 public minPeriod = 60 minutes;
    uint256 public minDistribution = 0.1 * 10**18; // 0.1 BAKE minimum auto send
    
    // BNB Needed to Swap to BAKE
    uint256 public swapToBAKEThreshold = 1 * 10**18;
    
    // Current Index in Shareholder array 
    uint256 currentIndex;

    modifier onlyToken() {
        require(msg.sender == _token); _;
    }
    // Testnet: 0xD99D1c33F9fC3444f8101754aBC46c52416550D1
    // Mainet: 0x10ED43C718714eb63d5aA57B78B54704E256024E
    constructor (address _router) {
        router = _router != address(0)
        ? IUniswapV2Router02(_router)
        : IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
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
        
        uint256 bnbBalance = address(this).balance;
        if (bnbBalance >= swapToBAKEThreshold) {
            
            uint256 balanceBefore = IERC20(BAKE).balanceOf(address(this));
            
            address[] memory path = new address[](2);
            path[0] = WBNB;
            path[1] = BAKE;

            router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: swapToBAKEThreshold}(
                0,
                path,
                address(this),
                block.timestamp
            );
            uint256 amount = IERC20(BAKE).balanceOf(address(this)).sub(balanceBefore);

            totalDividends = totalDividends.add(amount);
            dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
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
    function claimDividend() external {
        require(shouldDistribute(msg.sender), 'Must wait 24 hours to claim dividend!');
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
    function setBAKEAddress(address nBAKE) external onlyToken {
        BAKE = nBAKE;
    }
    receive() external payable { }
}

interface IBURGERDistributor {
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution, uint256 _bnbToBURGERThreshold) external;
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external;
    function process(uint256 gas) external;
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
    // BURGER Contract Address
    address BURGER = 0xAe9269f27437f0fcBC232d39Ec814844a51d6b8f;
    
    // BNB Address
    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    
    // Pancakeswap Router
    IUniswapV2Router02 router;
    
    // Shareholder Fields
    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;
    mapping (address => Share) public shares;
    
    // Shares Math and Fields
    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;
    
    // Once the Minimum Distribution Limit is hit after "minPeriod" it awards the Rewards
    uint256 public minPeriod = 60 minutes;
    uint256 public minDistribution = 0.2 * 10**18; // 0.1 BURGER minimum auto send
    
    // BNB Needed to Swap to BAKE
    uint256 public swapToBURGERThreshold = 1 * 10**18;
    
    // Current Index in Shareholder array 
    uint256 currentIndex;

    modifier onlyToken() {
        require(msg.sender == _token); _;
    }
    // Testnet: 0xD99D1c33F9fC3444f8101754aBC46c52416550D1
    // Mainet: 0x10ED43C718714eb63d5aA57B78B54704E256024E
    constructor (address _router) {
        router = _router != address(0)
        ? IUniswapV2Router02(_router)
        : IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
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
        
        uint256 bnbBalance = address(this).balance;
        if (bnbBalance >= swapToBURGERThreshold) {
            
            uint256 balanceBefore = IERC20(BURGER).balanceOf(address(this));
            
            address[] memory path = new address[](2);
            path[0] = WBNB;
            path[1] = BURGER;

            router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: swapToBURGERThreshold}(
                0,
                path,
                address(this),
                block.timestamp
            );
            uint256 amount = IERC20(BURGER).balanceOf(address(this)).sub(balanceBefore);

            totalDividends = totalDividends.add(amount);
            dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
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
    function claimDividend() external {
        require(shouldDistribute(msg.sender), 'Must wait 24 hours to claim dividend!');
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
    function setBURGERAddress(address nBURGER) external onlyToken {
        BURGER = nBURGER;
    }
    receive() external payable { }
}

interface ICAKEDistributor {
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution, uint256 _bnbToCAKEThreshold) external;
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external;
    function process(uint256 gas) external;
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
    // CAKE Contract Address
    address CAKE = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;
    
    // BNB Address
    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    
    // Pancakeswap Router
    IUniswapV2Router02 router;
    
    // Shareholder Fields
    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;
    mapping (address => Share) public shares;
    
    // Shares Math and Fields
    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;
    
    // Once the Minimum Distribution Limit is hit after "minPeriod" it awards the Rewards
    uint256 public minPeriod = 60 minutes;
    uint256 public minDistribution = 0.3 * 10**18; // 0.1 CAKE minimum auto send
    
    // BNB Needed to Swap to CAKE
    uint256 public swapToCAKEThreshold = 1 * 10**18;
    
    // Current Index in Shareholder array 
    uint256 currentIndex;

    modifier onlyToken() {
        require(msg.sender == _token); _;
    }
    // Testnet: 0xD99D1c33F9fC3444f8101754aBC46c52416550D1
    // Mainet: 0x10ED43C718714eb63d5aA57B78B54704E256024E
    constructor (address _router) {
        router = _router != address(0)
        ? IUniswapV2Router02(_router)
        : IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
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
        
        uint256 bnbBalance = address(this).balance;
        if (bnbBalance >= swapToCAKEThreshold) {
            
            uint256 balanceBefore = IERC20(CAKE).balanceOf(address(this));
            
            address[] memory path = new address[](2);
            path[0] = WBNB;
            path[1] = CAKE;

            router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: swapToCAKEThreshold}(
                0,
                path,
                address(this),
                block.timestamp
            );
            uint256 amount = IERC20(CAKE).balanceOf(address(this)).sub(balanceBefore);

            totalDividends = totalDividends.add(amount);
            dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
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
    function claimDividend() external {
        require(shouldDistribute(msg.sender), 'Must wait 24 hours to claim dividend!');
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
    function setCAKEAddress(address nCAKE) external onlyToken {
        CAKE = nCAKE;
    }
    receive() external payable { }

}

// Official BAKEaBURGERCAKE Contract
contract BAKEaBURGERCAKE is IERC20, Context, Ownable {
    using SafeMath for uint256;
    using SafeMath for uint8;
    using Address for address;
    
    // Our BakeryToken, BurgerSwap, PancakeSwap Distributor 
    BAKEDistributor public bakeDistributor;
    BURGERDistributor public burgerDistributor;
    CAKEDistributor public cakeDistributor;
    
    // General Info
    string constant _name = "BAKEaBURGERCAKE";
    string constant _symbol = "BABUCA";
    uint8 constant _decimals = 9;
    
    // Total Supply
    uint256 _totalSupply = 23 * 10**6 * (10 ** _decimals); // 23 Million Max Supply
    uint256 public _maxTxAmount = _totalSupply.div(200); // 0.5%
    
    // Addresses
    address BAKE        = address(0xE02dF9e3e622DeBdD69fb838bB799E3F168902c5); //BakeryToken
    address BURGER      = address(0xAe9269f27437f0fcBC232d39Ec814844a51d6b8f); //BurgerSwap
    address CAKE        = address(0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82); //PancakeSwap
    address ZERO        = 0x0000000000000000000000000000000000000000;
    address public BURN = 0x000000000000000000000000000000000000dEaD;
    address public WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    // Balances
    mapping (address => uint256) _balances; 
    mapping (address => mapping (address => uint256)) _allowances;
    
    // Exemptions
    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isDividendExempt;
    
    // Token Fees Settings
    uint256 public liquidityFee     =   2;
    uint256 public buybackFee       =   2;
    uint256 public marketingFee     =   2;
    uint256 public reflectionFee    =  15;
    uint256 public totalFee         =  21;
    uint256 feeDenominator          = 100;
    
    // Receiving Addresses
    address public autoLiquidityReceiver;
    address public marketingFeeReceiver;

    // Target Liquidity is 20%
    uint256 targetLiquidity = 20;
    uint256 targetLiquidityDenominator = 100;
    
    IUniswapV2Router02 public router;
    address public pair;
    
    // Buy Back Data
    bool public autoBuybackEnabled = false;
    uint256 autoBuybackAccumulator = 0;
    uint256 autoBuybackAmount = 1 * 10**18;
    uint256 autoBuybackBlockPeriod = 3600; // 3 hours
    uint256 autoBuybackBlockLast = block.number;

    // Gas for Distributor
    uint256 distributorGas = 500000;
    
    // In charge of swapping
    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply.div(1000); // 0.1%
    
    // True if our Threshold decreases with circulating Supply
    bool public canChangeSwapThreshold = false;
    uint256 public swapThresholdPercentOfCirculatingSupply = 10;
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }
    
    // Pancakeswap V2 Router
    // Testnet: 0xD99D1c33F9fC3444f8101754aBC46c52416550D1
    // Mainet: 0x10ED43C718714eb63d5aA57B78B54704E256024E
    address private _dexRouter = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    
    // False if we should disable Auto Liquidity pairing or Marketing for any reason
    bool public shouldPairLiquidity = true;
    bool public allowTransferToMarketing = true;
    
    // Because Transparency is important
    uint256 public totalBNBMarketing            = 0;
    uint256 public totalBNB_BAKE_Reflections    = 0;
    uint256 public totalBNB_BURGER_Reflections  = 0;
    uint256 public totalBNB_CAKE_Reflections    = 0;
    
    // Initialize some Stuff
    constructor () {
        // Pancakeswap V2 Router
        router = IUniswapV2Router02(_dexRouter);
        
        // Liquidity Pool Address for BNB -> BABUCA
        pair = IUniswapV2Factory(router.factory()).createPair(WBNB, address(this));
        _allowances[address(this)][address(router)] = _totalSupply;
        
        // Wrapped BNB Address used for trading on PCS
        WBNB = router.WETH();
        
        // Our BAKE, BURGER, CAKE Distributor
        bakeDistributor = new BAKEDistributor(_dexRouter);
        burgerDistributor = new BURGERDistributor(_dexRouter);
        cakeDistributor = new CAKEDistributor(_dexRouter);
        
        // Receiving Addresses
        autoLiquidityReceiver = msg.sender;
        marketingFeeReceiver = 0x142F7Dbf573a800ec8B3a287bEf7695B4D804dA1; // Marketing address used to pay for marketing
        
        // Exempt Deployer from Fees
        isFeeExempt[msg.sender] = true;
        
        // Exempt Deployer from Token Limit
        isTxLimitExempt[msg.sender] = true;
        isTxLimitExempt[marketingFeeReceiver] = true;
        
        // Exempt this Contract, the LP, and OUR Burn Wallet from receiving Rewards
        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[BURN] = true;
        
        // Approve Router of Total Supply
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
    // Internal Transfer
    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        // make standard checks
        require(recipient != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        // check if we have reached the transaction limit
        require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
        
        // if we're in swap perform a basic transfer
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }
        
        uint256 amountReceived;
        // limit gas consumption by splitting up operations
        if(shouldSwapBack()) { 
            swapBack();
            amountReceived = handleTransferBody(sender, recipient, amount);
        } else if(shouldAutoBuyback()) { 
            triggerAutoBuyback(); 
            amountReceived = handleTransferBody(sender, recipient, amount);
        } else {
            amountReceived = handleTransferBody(sender, recipient, amount);
            uint256 gasToUse = distributorGas > gasleft() ? gasleft().mul(3).div(4) : distributorGas;
            try bakeDistributor.process(gasToUse) {} catch {}
            try burgerDistributor.process(gasToUse) {} catch {}
            try cakeDistributor.process(gasToUse) {} catch {}  
        }
        
        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    // Takes Associated Fees and sets Holders' new Share for the Distributor
    function handleTransferBody(address sender, address recipient, uint256 amount) internal returns (uint256) {
        // Subtract balance from Sender
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        
        // Amount Receiver should receive
        uint256 amountReceived = shouldTakeFee(sender) ? takeFee(recipient, amount) : amount;
        
        // Add Amount to Recipient
        _balances[recipient] = _balances[recipient].add(amountReceived);
        
        // Set shares for Distributors
        if(!isDividendExempt[sender]){
             bakeDistributor.setShare(sender, _balances[sender]); 
             burgerDistributor.setShare(sender, _balances[sender]);
             cakeDistributor.setShare(sender, _balances[sender]);
        }
        if(!isDividendExempt[recipient]){
             bakeDistributor.setShare(recipient, _balances[recipient]);
             burgerDistributor.setShare(recipient, _balances[recipient]); 
             cakeDistributor.setShare(sender, _balances[recipient]);
        }
        // Return the Amount received by Receiver
        return amountReceived;
    }
    // Basic Transfer with no swaps for BNB -> Vault or Vault -> BNB
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        handleTransferBody(sender, recipient, amount);
        return true;
    }
    // False if sender is Fee Exempt, True if not
    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }
    // Takes Proper Fee (10% buys / transfers, 20% on sells) and stores in Contract
    function takeFee(address receiver, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount.mul(getTotalFee(receiver == pair)).div(feeDenominator);
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        return amount.sub(feeAmount);
    }
    // True if we should swap from BABUCA => BNB
    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }
    // Swaps BAKEaBURGERCAKE for BNB if Threshold is reached and the swap is enabled
    //  Uses BNB retrieved to:
    //  fuel the Contract for buy/burns
    //  provide Distributor with BNB for BAKE, BURGER and CAKE
    //  send to Marketing Wallet
    //  add liquidity if liquidity is low
     function swapBack() internal swapping {
        
        // check if we need to add liquidity 
        uint256 dynamicLiquidityFee = (isOverLiquified(targetLiquidity, targetLiquidityDenominator) || !shouldPairLiquidity)? 0 : liquidityFee;
        uint256 amountToLiquify = swapThreshold.mul(dynamicLiquidityFee).div(totalFee).div(2);
        uint256 amountToSwap = swapThreshold.sub(amountToLiquify);
        
        // path from token -> BNB
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WBNB;
        uint256 balanceBefore = address(this).balance;
        // swap tokens for BNB
        try router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        ) {} catch{}
        // how much BNB did we swap?
        uint256 amountBNB = address(this).balance.sub(balanceBefore);
        
        // total amount of BNB to allocate
        uint256 totalBNBFee = totalFee.sub(dynamicLiquidityFee.div(2));
        
        // how much bnb is sent to liquidity, reflections, and marketing
        uint256 amountBNBLiquidity = amountBNB.mul(dynamicLiquidityFee).div(totalBNBFee).div(2);
        uint256 amountBNBReflection = amountBNB.mul(reflectionFee).div(totalBNBFee);
        uint256 amountBNBMarketing = amountBNB.mul(marketingFee).div(totalBNBFee);
        // deposit BNB for reflections and marketing
        transferToDistributorAndMarketing(amountBNBReflection, amountBNBMarketing);
        
        // add liquidity if we need to
        if(amountToLiquify > 0 && shouldPairLiquidity ){
            try router.addLiquidityETH{value: amountBNBLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                autoLiquidityReceiver,
                block.timestamp
        ) {} catch {}
            emit AutoLiquify(amountBNBLiquidity, amountToLiquify);
        }
    }
    // Transfers BNB to Safemoon Distributor and Marketing Wallet
    function transferToDistributorAndMarketing(uint256 distributorBNB, uint256 marketingBNB) internal {
        (bool successOne,) = payable(address(bakeDistributor)).call{value: distributorBNB, gas: 30000}("");
        if (successOne) {
            try bakeDistributor.deposit() {totalBNB_BAKE_Reflections = totalBNB_BAKE_Reflections.add(marketingBNB);} catch {}
        }
        (bool successTwo,) = payable(address(burgerDistributor)).call{value: distributorBNB, gas: 30000}("");
        if (successTwo) {
            try burgerDistributor.deposit() {totalBNB_BURGER_Reflections = totalBNB_BURGER_Reflections.add(marketingBNB);} catch {}
        }
        (bool successThree,) = payable(address(cakeDistributor)).call{value: distributorBNB, gas: 30000}("");
        if (successThree) {
            try cakeDistributor.deposit() {totalBNB_CAKE_Reflections = totalBNB_CAKE_Reflections.add(marketingBNB);} catch {}
        }
        if (allowTransferToMarketing) {
            (bool successful,) = payable(marketingFeeReceiver).call{value: marketingBNB, gas: 30000}("");
            if (successful) {
                totalBNBMarketing = totalBNBMarketing.add(marketingBNB);
            }
        }
    }
    // Should BABUCA buy/burn right now?
    function shouldAutoBuyback() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && autoBuybackEnabled
        && autoBuybackBlockLast + autoBuybackBlockPeriod <= block.number // After N blocks from last buyback
        && address(this).balance >= autoBuybackAmount;
    }
    // Buy back tokens to make up for buy fee
    function triggerAutoBuyback() internal {
        buyTokens(autoBuybackAmount, BURN);
        autoBuybackBlockLast = block.number;
        autoBuybackAccumulator = autoBuybackAccumulator.add(autoBuybackAmount);
    }
    // Buys BAKEaBURGERCAKE with BNB in the Contract, sending to target Address
    function buyTokens(uint256 amount, address to) internal swapping {
        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(this);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0,
            path,
            to,
            block.timestamp.add(30)
        );
        if (to == BURN && canChangeSwapThreshold) {
            swapThreshold = getCirculatingSupply().div(swapThresholdPercentOfCirculatingSupply);
        }
    }
    // Sets Various Fees
    function setFees(uint256 _liquidityFee, uint256 _buybackFee, uint256 _reflectionFee, uint256 _marketingFee, uint256 _feeDenominator) external onlyOwner {
        liquidityFee = _liquidityFee;
        buybackFee = _buybackFee;
        reflectionFee = _reflectionFee;
        marketingFee = _marketingFee;
        totalFee = _liquidityFee.add(_buybackFee).add(_reflectionFee).add(_marketingFee);
        feeDenominator = _feeDenominator;
        require(totalFee < feeDenominator/4);
    }
    // Is Holder Exempt From Fees
    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }
    // Is Holder Exempt From Transaction Limit
    function setIsTxLimitExempt(address holder, bool exempt) external onlyOwner {
        isTxLimitExempt[holder] = exempt;
    }
    // Set Holder To Be Exempt From Dividends
    function setIsDividendExempt(address holder, bool exempt) external onlyOwner {
        require(holder != address(this) && holder != pair);
        isDividendExempt[holder] = exempt;
        if(exempt) {
            bakeDistributor.setShare(holder, 0);
            burgerDistributor.setShare(holder, 0);
            cakeDistributor.setShare(holder, 0);
            
        } else {
            bakeDistributor.setShare(holder, _balances[holder]);
            burgerDistributor.setShare(holder, _balances[holder]);
            cakeDistributor.setShare(holder, _balances[holder]);
        }
    }
    // Is Holder Exempt From Fees
    function getIsFeeExempt(address holder) external view returns (bool) {
        return isFeeExempt[holder];
    }
        // Is Holder Exempt From Transaction Limit
    function getIsTxLimitExempt(address holder) external view returns (bool) {
        return isTxLimitExempt[holder];
    }
    // Is Holder Exempt From Dividends
    function getIsDividendExempt(address holder) external view returns (bool) {
        return isDividendExempt[holder];
    }
    function setFeeReceivers(address _autoLiquidityReceiver, address _marketingFeeReceiver) external onlyOwner {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        marketingFeeReceiver = _marketingFeeReceiver;
    }
    function setAutoBuybackSettings(bool _enabled, uint256 _amount, uint256 _period) external onlyOwner {
        autoBuybackEnabled = _enabled;
        autoBuybackAccumulator = 0;
        autoBuybackAmount = _amount;
        autoBuybackBlockPeriod = _period;
        autoBuybackBlockLast = block.number;
    }
    function setSwapBackSettings(bool _enabled, uint256 _amount, bool changeSwapThreshold, bool shouldAutomateLiquidity, uint256 percentOfCirculatingSupply) external onlyOwner {
        swapEnabled = _enabled;
        swapThreshold = _amount;
        canChangeSwapThreshold = changeSwapThreshold;
        swapThresholdPercentOfCirculatingSupply = percentOfCirculatingSupply;
        shouldPairLiquidity = shouldAutomateLiquidity;
    }
    function setTargetLiquidity(uint256 _target, uint256 _denominator) external onlyOwner {
        targetLiquidity = _target;
        targetLiquidityDenominator = _denominator;
    }
    // Set Criteria For BAKE Distributor
    function setBAKEDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution, uint256 _bnbToBAKEThreshold) external onlyOwner {
        bakeDistributor.setDistributionCriteria(_minPeriod, _minDistribution, _bnbToBAKEThreshold);
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
    function setDistributorGas(uint256 gas) external onlyOwner {
        require(gas < 1000000);
        distributorGas = gas;
    }
    function setTxLimit(uint256 amount) external onlyOwner {
        require(amount >= _totalSupply / 2500);
        _maxTxAmount = amount;
    }
    // Buy and Burn BABUCA with BNB stored in Contract
    function triggerBABUCABuyback(uint256 amount) public onlyOwner {
        buyTokens(amount, BURN);
        emit BABUCABuyBackAndBurn(amount);
    }
    function setDexRouter(address nRouter) public onlyOwner{
        _dexRouter = nRouter;
        router = IUniswapV2Router02(nRouter);
    }
    function setAutoBuyBack(bool enable) public onlyOwner {
        autoBuybackEnabled = enable;
    }
    // Swaps BAKE, BURGER and CAKE Addresses in case of migration
    function setTokenAddresses(address nBAKE, address nBURGER, address nCAKE) external onlyOwner {
        bakeDistributor.setBAKEAddress(nBAKE);
        burgerDistributor.setBURGERAddress(nBURGER);
        cakeDistributor.setCAKEAddress(nCAKE);
        emit SwappedTokenAddresses(nBAKE, nBURGER, nCAKE);
    }
    function getBNBQuantityInContract() public view returns(uint256){
        return address(this).balance;
    }
    function getTotalFee(bool selling) public view returns (uint256) {
        if(selling){ return totalFee; }
        return totalFee;
    }
    // Returns the Circulating Supply of BABUCA ( supply not owned by Burn Wallet )
    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(BURN));
    }
    function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) {
        return accuracy.mul(balanceOf(pair).mul(2)).div(getCirculatingSupply()) > target;
    }
    function getBAKEDistributorAddress() external view returns (address) {
        return address(bakeDistributor);
    }
    function getBURGERDistributorAddress() external view returns (address) {
        return address(burgerDistributor);
    }
    function getCAKEDistributorAddress() external view returns (address) {
        return address(cakeDistributor);
    }
    event SwappedTokenAddresses(address newBAKE, address newBURGER, address newCAKE);
    event AutoLiquify(uint256 amountBNB, uint256 amountBOG);
    event BABUCABuyBackAndBurn(uint256 amountBNB);
}