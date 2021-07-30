/**
 *Submitted for verification at BscScan.com on 2021-07-29
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;

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

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

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
    
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }
    
    function getTime() public view returns (uint256) {
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
        require(block.timestamp > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

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


interface IReferral {
    function addReferrer(address) external;
    function updateReferralStatus(address) external;
    function isActiveAccount(address) external view returns (bool);
    function calculateBonus(address, uint256) external view returns (uint256);
}


interface IDividendDistributor {
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external;
    function setShare(address shareholder, uint256 amount) external;
    function addDividend(uint256 amount) external;
    function process(uint256 gas) external;
}


contract DogeDividendDistributor is IDividendDistributor, Ownable {
    using SafeMath for uint256;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    // SETMEUP
    // DOGE MAINNET: 0xba2ae424d960c26247dd6c32edc70b295c744c43
    // BUSD TESTNET: 0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7
    IBEP20 DOGE = IBEP20(0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7);
    
    // TODO: update to DOGE

    // BNB MAINNET: 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c
    // BNB TESTNET: 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd
    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    IDEXRouter router;

    address _token;
    address _referral;

    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;

    mapping (address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    // uint256 public dividendsPerShare;
    uint256 public totalDividendsClaimable;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;
    uint256 public minPeriod = 12 hours;
    uint256 public minDistribution = 1 * (10 ** 18);
    address public tokenContract;

    uint256 MIN_TOKEN_THRESHOLD = 100 *  10**6 * 10**9; // 100 million TODO: add setter
    uint256 currentIndex;

    bool initialized;

    // mainnet router: 0x10ED43C718714eb63d5aA57B78B54704E256024E
    constructor (address _router, address token) {
        router = _router != address(0)
            ? IDEXRouter(_router)
            : IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        _token = token;
        tokenContract = token;
    }

    modifier onlyToken() {
        require(msg.sender == _token);
        _;
    }

    function setReferralContractAddress(address ref) external onlyOwner {
        _referral = ref;
    }

    function setTokenContractAddress(address ref) public onlyOwner {
        tokenContract = ref;
        _token = ref;
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external override onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
    }

    /**
     * @dev trigger this function whenever a shareholder's share has been updated
     * @param shareholder address of the shareholder
     * @param amount the new amount of shares
     */
    function setShare(address shareholder, uint256 amount) external override onlyToken {
        // if(shares[shareholder].amount > 0){
        //     distributeDividend(shareholder);
        // }

        uint256 previousAmount = shares[shareholder].amount;

        if (amount >= MIN_TOKEN_THRESHOLD && previousAmount == 0) {
            // Add new shareholder
            addShareholder(shareholder);
            totalShares = totalShares.sub(previousAmount).add(amount);
            shares[shareholder].amount = amount;
        } else if (amount < MIN_TOKEN_THRESHOLD && previousAmount > 0) {
            // Remove existing shareholder
            removeShareholder(shareholder);
            totalShares = totalShares.sub(previousAmount);
            shares[shareholder].amount = 0;
        } else if (amount > MIN_TOKEN_THRESHOLD) {
            // Update existing shareholder
            totalShares = totalShares.sub(previousAmount).add(amount);
            shares[shareholder].amount = amount;
        } else {
            // Don't register address that does not have minimum token holding
        }
        
        // shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }

    /**
     * @dev record the amount of dividend.
     */
    function addDividend(uint256 amount) external override onlyToken {
        totalDividends = totalDividends.add(amount);
        totalDividendsClaimable = totalDividends.sub(totalDistributed);
    }

    /**
     * @dev main function to distribute dividends to all shareholders
     * @param gas the total amount of gas spendable
     */
    function process(uint256 gas) external override onlyToken {
        uint256 shareholderCount = shareholders.length;

        if (shareholderCount == 0) {
            return;
        }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        uint256 iterations = 0;

        while(gasUsed < gas && iterations < shareholderCount) {
            if (currentIndex >= shareholderCount) {
                currentIndex = 0;
            }

            // if(shouldDistribute(shareholders[currentIndex])){
                distributeDividend(shareholders[currentIndex]);
            // }

            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }
    
    function claimDividend() external {
        distributeDividend(msg.sender);
    }

    /**
     * @dev get shareholder last claim timestamp in epoch
     * @param shareholder address of the shareholder
     * @return shareholder last claim timestamp in epoch
     */
    function getShareholderClaim(address shareholder) external view returns (uint256) {
        return shareholderClaims[shareholder];
    }

    /**
     * @dev calculate amount of DOGE for each share. 50% of doge will be reserved for next block
     * @return amount of DOGE for each share
     */
    function dividendsPerShare() public view returns (uint256) {
        return totalDividendsClaimable.mul(dividendsPerShareAccuracyFactor).div(totalShares).div(2);
    }
    
    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if (shares[shareholder].amount == 0) {
            return 0;
        }

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if (shareholderTotalDividends <= shareholderTotalExcluded) {
            return 0;
        }

        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    /**
     * @dev distribute unclaimed dividend to a shareholder. TODO: Ensure that _token has called DOGE.approved
     */
    function distributeDividend(address shareholder) internal {
        require(shouldDistribute(shareholder), "Distribution criteria not met.");
        // if(shares[shareholder].amount == 0){ return; }

        uint256 amount = getUnpaidEarnings(shareholder);
        if (amount > 0) {
            totalDistributed = totalDistributed.add(amount);
            totalDividendsClaimable = totalDividends.sub(totalDistributed);
            
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);

            DOGE.transfer(shareholder, amount);
        }
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

    function shouldDistribute(address shareholder) internal view returns (bool) {
        // TODO: implement this part
        // require(claimStarted, "Claim has not started yet");
        require(
            shareholderClaims[shareholder] + minPeriod < block.timestamp,
            "minPeriod has not been reached since last claim"
        );
        require(getUnpaidEarnings(shareholder) > minDistribution, ""); // TODO: check if we need this
        
        return true;
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        // TODO: apply DogeReferral.calculateBonus here
        return share.mul(dividendsPerShare()).div(dividendsPerShareAccuracyFactor);
    }
}