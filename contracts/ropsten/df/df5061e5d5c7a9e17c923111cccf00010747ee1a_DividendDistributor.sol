/**
 *Submitted for verification at BscScan.com on 2021-09-16
*/

/**
 *Submitted for verification at BscScan.com on 2021-09-16
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;



/**
 * SAFEMATH LIBRARY
 */
library SafeMath {
    
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

interface IERC20 {
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
    function setSportToken(address _address) external;
    function process(uint256 gas) external;
}

contract DividendDistributor is IDividendDistributor {
    using SafeMath for uint256;

    address public _token;
    address public _sportTokenAddr;
    IERC20 public _sportToken;

    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderEsgBalance;
    mapping (address => uint256) holdingTime;
    mapping (address => uint256) amountToDistribute;
    mapping (address => bool) isshareholder;
    mapping (address => uint256) shareholderClaims;

    uint256 public minPeriod = 1 minutes;

    uint256 currentIndex;

    modifier onlyToken() {
        require(msg.sender == address(_token)); _;
    }

    constructor () {
        _token = msg.sender;
    }
    function setSportToken(address _address) external override onlyToken {
        _sportTokenAddr = _address;
        _sportToken = IERC20(_sportTokenAddr);
    }
    function setShare(address shareholder, uint256 amount) external override onlyToken {
        shareholderEsgBalance[shareholder] = amount;
        if(amount==0){removeShareholder(shareholder); return;} 
        if(isshareholder[shareholder] == false) addShareholder(shareholder); 
    }

    function getDiffDays(address holder) internal returns(uint256) {
        uint256 retVal = (block.timestamp - holdingTime[holder]).div(60).div(60).div(24);
        return retVal + 1;
    }

    function getDenominator() internal returns(uint256) {
        uint256 retVal = 0;
        for(uint256 i=0;i<shareholders.length;i++) {
            retVal = retVal.add(shareholderEsgBalance[shareholders[i]].mul(getDiffDays(shareholders[i])));
        }
        return retVal;
    }

    function process(uint256 gas) external override onlyToken {
        if(_sportToken.balanceOf(address(this))<=0) return;
        uint256 sportBalance = _sportToken.balanceOf(address(this));
        uint256 shareholderCount = shareholders.length;
        if(shareholderCount == 0) { return; }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        uint256 iterations = 0;
        uint256 denominator = getDenominator();
        while(gasUsed < gas && iterations < shareholderCount) {
            if(currentIndex >= shareholderCount){
                currentIndex = 0;
            }
            
            if(shouldDistribute(shareholders[currentIndex])){
                distributeDividend(shareholders[currentIndex], sportBalance.mul(shareholderEsgBalance[shareholders[currentIndex]].mul(getDiffDays(shareholders[currentIndex]))).div(denominator));
            }

            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }

    function shouldDistribute(address shareholder) internal view returns (bool) {
        return shareholderClaims[shareholder] + minPeriod < block.timestamp;
    }

    function distributeDividend(address shareholder, uint256 amount) internal {
        if(shareholderEsgBalance[shareholder] == 0){ return; }

        if(amount > 0){
            _sportToken.transfer(shareholder, amount);
            shareholderClaims[shareholder] = block.timestamp;
        }
    }

    function addShareholder(address shareholder) internal {
        holdingTime[shareholder] = block.timestamp;
        isshareholder[shareholder] = true;
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        isshareholder[shareholder] = false;
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length-1];
        shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }
}
contract ESG is IERC20, Auth {
    using SafeMath for uint256;

    address public MATIC = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    string constant _name = "eSkillz Game";
    string constant _symbol = "ESG";
    uint8 constant _decimals = 9;
    
    uint256 _totalSupply = 100000000 * (10 ** _decimals);

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    DividendDistributor distributor;
    address public distributorAddress;
    mapping (address => bool) isShareExempt;

    uint256 taxFee = 800;
    uint256 feeDenominator = 10000;
    uint256 distributorGas = 500000;

    address public taxFeeReceiver;

    IDEXRouter public router;
    address public pair;

    constructor (
        address _dexRouter
    ) Auth(msg.sender) {
        router = IDEXRouter(_dexRouter);
        pair = IDEXFactory(router.factory()).createPair(MATIC, address(this));

        isShareExempt[address(router)] = true;
        isShareExempt[address(pair)] = true;
        isShareExempt[msg.sender] = true;

        _allowances[address(this)][address(router)] = _totalSupply;
        MATIC = router.WETH();

        taxFeeReceiver = 0x18461667028745Cd20138059E57d8d882b7b3B3B;
        
        distributor = new DividendDistributor();
        distributorAddress = address(distributor);

        approve(_dexRouter, _totalSupply);
        approve(address(pair), _totalSupply);
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, _totalSupply);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != _totalSupply){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(sender==address(pair)) {
            _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
            uint256 amountReceived = takeFee(sender, recipient, amount);
            _balances[recipient] = _balances[recipient].add(amountReceived);

            if(!isShareExempt[recipient]) {
                try distributor.setShare(recipient, _balances[recipient]) {} catch {}
            }
            if (!isShareExempt[recipient] || !isShareExempt[recipient]) {
                try distributor.process(distributorGas) {} catch {}
            }
            
            emit Transfer(sender, recipient, amountReceived);
            return true;
        } else {
            return _basicTransfer(sender, recipient, amount);
        }
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        if(!isShareExempt[sender]) {
            try distributor.setShare(sender, _balances[sender]) {} catch {}
        }
        if(!isShareExempt[recipient]) {
            try distributor.setShare(recipient, _balances[recipient]) {} catch {}
        }
        if (!isShareExempt[recipient] || !isShareExempt[recipient]) {
            try distributor.process(distributorGas) {} catch {}
        }
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function setShareExempt(address _address, bool _exempt) external onlyOwner {
        isShareExempt[_address] = _exempt;
    }

    function takeFee(address sender, address receiver, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount.mul(taxFee).div(feeDenominator);
        _balances[taxFeeReceiver] = _balances[taxFeeReceiver].add(feeAmount);
        emit Transfer(sender, taxFeeReceiver, feeAmount);
        return amount.sub(feeAmount);
    }

    function setFees(uint256 _taxFee, uint256 _feeDenominator) external authorized {
        taxFee = _taxFee;
        feeDenominator = _feeDenominator;
        require(taxFee < feeDenominator/4);
    }
    
    function setSportToken(address _address) external authorized {
        distributor.setSportToken(_address);
    }

    function setFeeReceivers(address _taxFeeReceiver) external authorized {
        taxFeeReceiver = _taxFeeReceiver;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }
}