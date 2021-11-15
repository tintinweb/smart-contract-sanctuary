//SPDX-License-Identifier: UNLICENSED

/**
 * ████████████████▀█████████████████████████████████████████████
 * █▄─▄▄▀█─▄▄─█─▄▄▄▄█▄─▄▄─███─▄─▄─█▄─█─▄█─▄▄▄─█─▄▄─█─▄▄─█▄─▀█▄─▄█
 * ██─██─█─██─█─██▄─██─▄█▀█████─████▄─▄██─███▀█─██─█─██─██─█▄▀─██
 * ▀▄▄▄▄▀▀▄▄▄▄▀▄▄▄▄▄▀▄▄▄▄▄▀▀▀▀▄▄▄▀▀▀▄▄▄▀▀▄▄▄▄▄▀▄▄▄▄▀▄▄▄▄▀▄▄▄▀▀▄▄▀
 * 
 * NFT Super-Powered Hyperdeflationary Token
 * Hold more than .1% of circ supply to gain unique NFT's.
 * NFT's change buy/sell and NFT drop rates.
 *
 * + Holders get BUSD rewards
 * + Intelligent Buyback system
 * + Dynamic sell ratios
 *
 * for more info: https://dogetycoon.io
 * 
 */

pragma solidity ^0.8.2;
import './IDividentDistributor.sol';
import './SafeMath.sol';
import './IBEP20.sol';
import './IDEXRouter.sol';

contract DividendDistributor is IDividendDistributor {
    using SafeMath for uint256;

    address _token;
    address _owner;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    IBEP20 BUSD;
    address WBNB;
    IDEXRouter router;

    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;

    mapping (address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;

    uint256 public minPeriod = 1 hours; // min 1 hour delay
    uint256 public minDistribution = 1 * (10 ** 18); // 1 BUSD minimum auto send

    uint256 currentIndex;

    bool initialized;
    modifier initialization() {
        require(!initialized);
        _;
        initialized = true;
    }

    modifier onlyToken() {
        require(msg.sender == _token); _;
    }

    modifier onlyOwner() {
        require(msg.sender == _token); _;
    }

    constructor (address _router, address _wbnb, address _busd) {
        router = IDEXRouter(_router);
        WBNB = _wbnb;
        BUSD = IBEP20(_busd);
        _token = msg.sender;
        _owner = msg.sender;
    }

    function setToken(address _tokenAddress) external onlyOwner {
        _token = _tokenAddress;
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external override onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
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

    function deposit() external payable override onlyToken {
        uint256 balanceBefore = BUSD.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(BUSD);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amount = BUSD.balanceOf(address(this)).sub(balanceBefore);

        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
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
            BUSD.transfer(shareholder, amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
        }
    }
    
    function claimDividend() external override {
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
}

//SPDX-License-Identifier: UNLICENSED

/**
 * ████████████████▀█████████████████████████████████████████████
 * █▄─▄▄▀█─▄▄─█─▄▄▄▄█▄─▄▄─███─▄─▄─█▄─█─▄█─▄▄▄─█─▄▄─█─▄▄─█▄─▀█▄─▄█
 * ██─██─█─██─█─██▄─██─▄█▀█████─████▄─▄██─███▀█─██─█─██─██─█▄▀─██
 * ▀▄▄▄▄▀▀▄▄▄▄▀▄▄▄▄▄▀▄▄▄▄▄▀▀▀▀▄▄▄▀▀▀▄▄▄▀▀▄▄▄▄▄▀▄▄▄▄▀▄▄▄▄▀▄▄▄▀▀▄▄▀
 * 
 * NFT Super-Powered Hyperdeflationary Token
 * Hold more than .1% of circ supply to gain unique NFT's.
 * NFT's change buy/sell and NFT drop rates.
 *
 * + Holders get BUSD rewards
 * + Intelligent Buyback system
 * + Dynamic sell ratios
 *
 * for more info: https://dogetycoon.io
 * 
 */
 
pragma solidity ^0.8.2;
/**
 * BEP20 standard interface.
 */
interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

//SPDX-License-Identifier: UNLICENSED

/**
 * ████████████████▀█████████████████████████████████████████████
 * █▄─▄▄▀█─▄▄─█─▄▄▄▄█▄─▄▄─███─▄─▄─█▄─█─▄█─▄▄▄─█─▄▄─█─▄▄─█▄─▀█▄─▄█
 * ██─██─█─██─█─██▄─██─▄█▀█████─████▄─▄██─███▀█─██─█─██─██─█▄▀─██
 * ▀▄▄▄▄▀▀▄▄▄▄▀▄▄▄▄▄▀▄▄▄▄▄▀▀▀▀▄▄▄▀▀▀▄▄▄▀▀▄▄▄▄▄▀▄▄▄▄▀▄▄▄▄▀▄▄▄▀▀▄▄▀
 * 
 * NFT Super-Powered Hyperdeflationary Token
 * Hold more than .1% of circ supply to gain unique NFT's.
 * NFT's change buy/sell and NFT drop rates.
 *
 * + Holders get BUSD rewards
 * + Intelligent Buyback system
 * + Dynamic sell ratios
 *
 * for more info: https://dogetycoon.io
 * 
 */
 
pragma solidity ^0.8.2;

interface IDEXRouter {
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

//SPDX-License-Identifier: UNLICENSED

/**
 * ████████████████▀█████████████████████████████████████████████
 * █▄─▄▄▀█─▄▄─█─▄▄▄▄█▄─▄▄─███─▄─▄─█▄─█─▄█─▄▄▄─█─▄▄─█─▄▄─█▄─▀█▄─▄█
 * ██─██─█─██─█─██▄─██─▄█▀█████─████▄─▄██─███▀█─██─█─██─██─█▄▀─██
 * ▀▄▄▄▄▀▀▄▄▄▄▀▄▄▄▄▄▀▄▄▄▄▄▀▀▀▀▄▄▄▀▀▀▄▄▄▀▀▄▄▄▄▄▀▄▄▄▄▀▄▄▄▄▀▄▄▄▀▀▄▄▀
 * 
 * NFT Super-Powered Hyperdeflationary Token
 * Hold more than .1% of circ supply to gain unique NFT's.
 * NFT's change buy/sell and NFT drop rates.
 *
 * + Holders get BUSD rewards
 * + Intelligent Buyback system
 * + Dynamic sell ratios
 *
 * for more info: https://dogetycoon.io
 * 
 */
 
pragma solidity ^0.8.2;

interface IDividendDistributor {
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external;
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external payable;
    function process(uint256 gas) external;
    function claimDividend() external;
}

//SPDX-License-Identifier: UNLICENSED

/**
 * ████████████████▀█████████████████████████████████████████████
 * █▄─▄▄▀█─▄▄─█─▄▄▄▄█▄─▄▄─███─▄─▄─█▄─█─▄█─▄▄▄─█─▄▄─█─▄▄─█▄─▀█▄─▄█
 * ██─██─█─██─█─██▄─██─▄█▀█████─████▄─▄██─███▀█─██─█─██─██─█▄▀─██
 * ▀▄▄▄▄▀▀▄▄▄▄▀▄▄▄▄▄▀▄▄▄▄▄▀▀▀▀▄▄▄▀▀▀▄▄▄▀▀▄▄▄▄▄▀▄▄▄▄▀▄▄▄▄▀▄▄▄▀▀▄▄▀
 * 
 * NFT Super-Powered Hyperdeflationary Token
 * Hold more than .1% of circ supply to gain unique NFT's.
 * NFT's change buy/sell and NFT drop rates.
 *
 * + Holders get BUSD rewards
 * + Intelligent Buyback system
 * + Dynamic sell ratios
 *
 * for more info: https://dogetycoon.io
 * 
 */

 
pragma solidity ^0.8.2;
/**
 * Standard SafeMath, stripped down to just add/sub/mul/div
 */
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

