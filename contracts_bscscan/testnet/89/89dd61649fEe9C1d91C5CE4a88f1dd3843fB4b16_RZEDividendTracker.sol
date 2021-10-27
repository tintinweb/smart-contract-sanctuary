/**
 *Submitted for verification at BscScan.com on 2021-10-26
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.6;

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(0x01e9611dF08548994C883e4Ca729B0128E73470F);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
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

interface IDividendDistributor {
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external payable;
    function process(uint256 gas) external returns (uint256, uint256, uint256);
}

contract RZEDividendTracker is IDividendDistributor, Ownable {
    using SafeMath for uint256;
    
    address _admin = msg.sender;
    address public adminAddress = _admin;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    IBEP20 DOGE = IBEP20(0xbA2aE424d960c26247Dd6c32edC70B295c744C43);
    IDEXRouter router;

    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;

    mapping (address => Share) public shares;
    
    mapping (address => bool) public excludedFromDividends;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDividendsDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;

    uint256 public claimWait = 1 hours;
    uint256 public minimumTokenBalanceForDividends = 20071  * (10**18);

    uint256 currentIndex;

    bool initialized;
    modifier initialization() {
        require(!initialized);
        _;
        initialized = true;
    }

    modifier onlyAdmin() {
        require(msg.sender == adminAddress, "admin only");
        _;
    }
    
     modifier onlyOwnerOrAdmin() {
        require(msg.sender == owner() || msg.sender == adminAddress, "Only Owner | Admin");
        _;
    }
    
    event ExcludeFromDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event Claim(address indexed account, uint256 amount, bool indexed automatic);

    constructor () {
        router =  IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    }
    
    receive() external payable { }

    function updateClaimWait(uint256 newClaimWait) external onlyAdmin {
        require(newClaimWait != claimWait, "Cannot update claimWait to same value");
        emit ClaimWaitUpdated(newClaimWait, claimWait);
        claimWait = newClaimWait;
    }
    
    function updateMinTokenBalForDividends(uint256 newMinTokenBalForDividends) external onlyAdmin {
        minimumTokenBalanceForDividends = newMinTokenBalForDividends;
    }
    
     function setAdmin(address _adminAddress) external onlyAdmin {
        require(_adminAddress != address(0), "Cannot be zero address");
        adminAddress = _adminAddress;
    }
    
    // called from main contract
     function setBalance(address payable account, uint256 newBalance) external onlyOwnerOrAdmin {
    	if(excludedFromDividends[account]) {
    		return;
    	}
    	setShare(account, newBalance);
    }
    
 
    function setShare(address shareholder, uint256 amount) public override onlyOwnerOrAdmin {
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

    function distributeDividends(uint256 amount) public onlyOwnerOrAdmin {
        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
    }
    
    function deposit() external payable override onlyAdmin {
        uint256 balanceBefore = DOGE.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(DOGE);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amount = DOGE.balanceOf(address(this)).sub(balanceBefore);

        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
    }

    function process(uint256 gas) public override onlyOwnerOrAdmin returns (uint256, uint256, uint256) {
        uint256 shareholderCount = shareholders.length;

        if(shareholderCount == 0) { return (0, 0, currentIndex); }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        uint256 iterations = 0;
        uint256 claims = 0;

        while(gasUsed < gas && iterations < shareholderCount) {
            if(currentIndex >= shareholderCount){
                currentIndex = 0;
            }

            if(shouldDistribute(shareholders[currentIndex])){
                if(distributeDividend(shareholders[currentIndex])){
                    claims++;
                }
            }

            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
        
        return (iterations, claims, currentIndex);
    }
    
    function shouldDistribute(address shareholder) internal view returns (bool) {
        return shareholderClaims[shareholder] + claimWait < block.timestamp
                && shares[shareholder].amount > minimumTokenBalanceForDividends;
    }

    function distributeDividend(address shareholder) internal returns (bool) {
        if(shares[shareholder].amount == 0){ return false; }

        uint256 amount = withdrawableDividendOf(shareholder);
        if(amount > 0){
            totalDividendsDistributed = totalDividendsDistributed.add(amount);
            DOGE.transfer(shareholder, amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
            return true;
        }
        
        return false;
    }
    
    // claim Dividend
    function processAccount(address shareholder, bool automatic) public onlyOwnerOrAdmin returns (bool) {
        uint256 amount = withdrawableDividendOf(shareholder);
        
        if(distributeDividend(shareholder)) {
            shareholderClaims[shareholder] = block.timestamp;
            emit Claim(shareholder, amount, automatic);
            return true;
        }
        return false;
    }
    
    // get Unpaid Earnings
    function withdrawableDividendOf(address shareholder) public view returns (uint256) {
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
    
    function excludeFromDividends(address account) external onlyOwnerOrAdmin {
    	require(!excludedFromDividends[account]);
    	excludedFromDividends[account] = true;
    	
        setShare(account, 0);

    	emit ExcludeFromDividends(account);
    }
    
    function TransferDOGE(address payable recipient, uint256 amount) external onlyAdmin {
        require(recipient != address(0), "Cannot withdraw the DOGE balance to the zero address");
        DOGE.transfer(recipient, amount);
    }
    
    function getAccount(address _account) public view returns (
            address account,
            int256 index,
            int256 iterationsUntilProcessed,
            uint256 withdrawableDividends,
            uint256 _totalDividends,
            uint256 lastClaimTime,
            uint256 nextClaimTime,
            uint256 secondsUntilAutoClaimAvailable) {
        account = _account;

        index = int256(shareholderIndexes[account]);

        iterationsUntilProcessed = -1;

        if(index >= 0) {
            if(uint256(index) > currentIndex) {
                iterationsUntilProcessed = index - int256(currentIndex);
            }
            else {
                uint256 processesUntilEndOfArray = shareholders.length > currentIndex ?
                                                        shareholders.length.sub(currentIndex) : 0;

                iterationsUntilProcessed = index + int256(processesUntilEndOfArray);
            }
        }


        withdrawableDividends = withdrawableDividendOf(account);
        _totalDividends = shares[account].totalExcluded;

        lastClaimTime = shareholderClaims[account];

        nextClaimTime = lastClaimTime > 0 ? lastClaimTime.add(claimWait) : 0;

        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ? nextClaimTime.sub(block.timestamp) : 0;
    }

    function getAccountAtIndex(uint256 index)
        public view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
    	if(index >= shareholders.length) {
            return (0x0000000000000000000000000000000000000000, -1, -1, 0, 0, 0, 0, 0);
        }

        address account = shareholders[index];

        return getAccount(account);
    }
    
    // withdrawalble dividend
    function balanceOf(address shareholder) public view returns (uint256) {
        return withdrawableDividendOf(shareholder);
    }
    
    // total shareholders
    function getNumberOfTokenHolders() external view returns(uint256) {
        return shareholders.length;
    }
    
    function getLastProcessedIndex() external view returns(uint256) {
    	return currentIndex;
    }
    
}