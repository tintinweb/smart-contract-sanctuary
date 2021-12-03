/**
 *Submitted for verification at BscScan.com on 2021-12-03
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

    int256 constant private INT256_MIN = -2**255;

    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Multiplies two signed integers, reverts on overflow.
    */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == INT256_MIN)); // This is the only case of overflow not detected by the check below

        int256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Integer division of two signed integers truncating the quotient, reverts on division by zero.
    */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0); // Solidity only automatically asserts when dividing by 0
        require(!(b == -1 && a == INT256_MIN)); // This is the only case of overflow

        int256 c = a / b;

        return c;
    }

    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Subtracts two signed integers, reverts on overflow.
    */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));

        return c;
    }

    /**
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Adds two signed integers, reverts on overflow.
    */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));

        return c;
    }

    /**
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address _owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
}


interface IDividendDistributor {
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external;
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external payable;
    function process(uint256 gas) external;
}

abstract contract BaseErc20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) internal _balances;
    mapping (address => mapping (address => uint256)) internal _allowed;
    uint256 internal _totalSupply;
    
    string public symbol;
    string public  name;
    uint8 public decimals;
    
    address public owner;
    bool public isTradingEnabled = true;
    bool public launched;
    
    modifier onlyOwner() {
        require(msg.sender == owner, "can only be called by the contract owner");
        _;
    }
    
    modifier isLaunched() {
        require(launched, "can only be called once token is launched");
        _;
    }

    modifier tradingEnabled(address from) {
        require((isTradingEnabled && launched) || msg.sender == owner || from == owner, "trading not enabled");
        _;
    }
    
    /**
    * @dev Total number of tokens in existence
    */
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public override view returns (uint256) {
        return _balances[_owner];
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address _owner, address spender) public override view returns (uint256) {
        return _allowed[_owner][spender];
    }

    /**
    * @dev Transfer token for a specified address
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
    function transfer(address to, uint256 value) public override tradingEnabled(msg.sender) returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value) public override tradingEnabled(msg.sender) returns (bool) {
        require(spender != address(0), "cannot approve the 0 address");

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another.
     * Note that while this function emits an Approval event, this is not required as per the specification,
     * and other compliant implementations may not emit the event.
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address from, address to, uint256 value) public override tradingEnabled(from) returns (bool) {
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        emit Approval(from, msg.sender, _allowed[from][msg.sender]);
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue) public tradingEnabled(msg.sender) returns (bool) {
        require(spender != address(0), "cannot approve the 0 address");

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public tradingEnabled(msg.sender) returns (bool) {
        require(spender != address(0), "cannot approve the 0 address");

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].sub(subtractedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }


    // Admin methods
    function changeOwner(address who) public onlyOwner {
        require(who != address(0), "cannot be zero address");
        owner = who;
    }

    function removeBnb() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner).transfer(balance);
    }

    function transferTokens(address token, address to) public onlyOwner returns(bool){
        uint256 balance = IERC20(token).balanceOf(address(this));
        return IERC20(token).transfer(to, balance);
    }

    function setTradingEnabled(bool enabled) public onlyOwner {
        isTradingEnabled = enabled;
    }
    
    
    
    // Virtual methods
    function launch() virtual public onlyOwner {
        launched = true;
    }
    
    function preTransfer(address from, address to, uint256 value) virtual internal { }

    function calculateTransferAmount(address from, address to, uint256 value) virtual internal returns (uint256) {
        require(from != to);
        return value;
    }
    
    function postTransfer(address from, address to) virtual internal { }
    
    function isAlwaysExempt(address who) virtual internal returns (bool) {
        return who == address(0);
    }
    
    
    
    // Private methods

    /**
    * @dev Transfer token for a specified addresses
    * @param from The address to transfer from.
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
    function _transfer(address from, address to, uint256 value) private {
        require(to != address(0), "cannot be zero address");
        
        preTransfer(from, to, value);

        uint256 modifiedAmount =  calculateTransferAmount(from, to, value);
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(modifiedAmount);

        postTransfer(from, to);

        emit Transfer(from, to, modifiedAmount);
    }
}

contract TaxDistributor {
    using SafeMath for uint256;

    address public tokenPair;
    address public routerAddress;
    address private _token;
    address private _wbnb;

    IDEXRouter private _router;

    bool public inSwap;
    uint256 public lastSwapTime;

    enum TaxType { WALLET, DIVIDEND, LIQUIDITY }
    struct Tax {
        string taxName;
        uint256 buyTaxPercentage;
        uint256 sellTaxPercentage;
        uint256 taxPool;
        TaxType taxType;
        address location;
        uint256 share;
    }
    Tax[] public taxes;

    event TaxesDistributed(uint256 tokensSwapped, uint256 ethReceived);

    modifier onlyToken() {
        require(msg.sender == _token, "no permissions");
        _;
    }

    modifier notInSwap() {
        require(inSwap == false, "already swapping");
        _;
    }

    constructor (address router, address pair, address wbnb,uint timestamp) {
        _token = msg.sender;
        _wbnb = wbnb;
        _router = IDEXRouter(router);
        tokenPair = pair;
        routerAddress = router;
        lastSwapTime = timestamp;
    }

    receive() external payable {}

    function sendToken(address to,uint256 amount) public onlyToken{
        IERC20 token = IERC20(_token);
        token.transfer(to,amount);
    }

    function createWalletTax(string memory name, uint256 buyTax, uint256 sellTax, address wallet) public onlyToken {
        taxes.push(Tax(name, buyTax, sellTax, 0, TaxType.WALLET, wallet, 0));
    }
    
    function createDividendTax(string memory name, uint256 buyTax, uint256 sellTax, address dividendDistributor) public onlyToken {
        taxes.push(Tax(name, buyTax, sellTax, 0, TaxType.DIVIDEND, dividendDistributor, 0));
    }
    
    function createLiquidityTax(string memory name, uint256 buyTax, uint256 sellTax) public onlyToken {
        taxes.push(Tax(name, buyTax, sellTax, 0, TaxType.LIQUIDITY, address(0), 0));
    }

    function distribute() public payable onlyToken notInSwap {
        inSwap = true;

        address[] memory path = new address[](2);
        path[0] = _token;
        path[1] = _wbnb;

        uint256 totalTokens;
        for (uint256 i = 0; i < taxes.length - 1; i++) {
            if (taxes[i].taxType == TaxType.LIQUIDITY) {
                uint256 half = taxes[i].taxPool.div(2);
                totalTokens += taxes[i].taxPool.sub(half);
            } else {
                totalTokens += taxes[i].taxPool;
            }
        }
        
        uint256 balanceBefore = address(this).balance;
        _router.swapExactTokensForETH(
            totalTokens,
            0,
            path,
            address(this),
            block.timestamp
        );
        uint256 amountBNB = address(this).balance.sub(balanceBefore);

        // Calculate the distribution
        uint256 toDistribute = amountBNB;
        for (uint256 i = 0; i < taxes.length - 1; i++) {
            uint256 share = amountBNB.mul(taxes[i].taxPool).div(totalTokens);
            taxes[i].share = share;
            toDistribute = toDistribute.sub(share);
        }
        taxes[taxes.length - 1].share = toDistribute;

        // Distribute the coins
        for (uint256 i = 0; i < taxes.length; i++) {
            
            if (taxes[i].taxType == TaxType.WALLET) {
                payable(taxes[i].location).transfer(taxes[i].share);
            }
            else if (taxes[i].taxType == TaxType.DIVIDEND) {
                IDividendDistributor(taxes[i].location).deposit{value: taxes[i].share}();
            }
            else if (taxes[i].taxType == TaxType.LIQUIDITY) {
                if(taxes[i].share > 0){
                    _router.addLiquidityETH{value: taxes[i].share}(
                        _token,
                        taxes[i].taxPool.div(2),
                        0,
                        0,
                        BaseErc20(_token).owner(),
                        block.timestamp
                    );
                }
            }
            
            taxes[i].taxPool = 0;
            taxes[i].share = 0;
        }

        emit TaxesDistributed(totalTokens, amountBNB);

        lastSwapTime = block.timestamp;
        inSwap = false;
    }

    function getSellTax() public onlyToken view returns (uint256) {
        uint256 taxAmount;
        for (uint256 i = 0; i < taxes.length; i++) {
            taxAmount += taxes[i].sellTaxPercentage;
        }
        return taxAmount;
    }

    function getBuyTax() public onlyToken view returns (uint256) {
        uint256 taxAmount;
        for (uint256 i = 0; i < taxes.length; i++) {
            taxAmount += taxes[i].buyTaxPercentage;
        }
        return taxAmount;
    }
    
    function setTaxWallet(string memory taxName, address wallet) public onlyToken {
        bool updated;
        for (uint256 i = 0; i < taxes.length; i++) {
            if (taxes[i].taxType == TaxType.WALLET && compareStrings(taxes[i].taxName, taxName)) {
                taxes[i].location = wallet;
                updated = true;
            }
        }
        require(updated, "could not find tax to update");
    }

    function setSellTax(string memory taxName, uint256 taxPercentage) public onlyToken {
        bool updated;
        for (uint256 i = 0; i < taxes.length; i++) {
            if (compareStrings(taxes[i].taxName, taxName)) {
                taxes[i].sellTaxPercentage = taxPercentage;
                updated = true;
            }
        }
        require(updated, "could not find tax to update");
        require(getSellTax() <= 10000, "tax cannot be more than 100%");
    }

    function setBuyTax(string memory taxName, uint256 taxPercentage) public onlyToken {
        bool updated;
        for (uint256 i = 0; i < taxes.length; i++) {
            //if (taxes[i].taxName == taxName) {
            if (compareStrings(taxes[i].taxName, taxName)) {
                taxes[i].buyTaxPercentage = taxPercentage;
                updated = true;
            }
        }
        require(updated, "could not find tax to update");
        require(getBuyTax() <= 10000, "tax cannot be more than 100%");
    }

    function takeSellTax(uint256 value) public onlyToken returns (uint256) {
        for (uint256 i = 0; i < taxes.length; i++) {
            if (taxes[i].sellTaxPercentage > 0) {
                uint256 taxAmount = value.mul(taxes[i].sellTaxPercentage).div(10000);
                taxes[i].taxPool += taxAmount;
                value = value.sub(taxAmount);
            }
        }
        return value;
    }

    function takeBuyTax(uint256 value) public onlyToken returns (uint256) {
        for (uint256 i = 0; i < taxes.length; i++) {
            if (taxes[i].buyTaxPercentage > 0) {
                uint256 taxAmount = value.mul(taxes[i].buyTaxPercentage).div(10000);
                taxes[i].taxPool += taxAmount;
                value = value.sub(taxAmount);
            }
        }
        return value;
    }
    
    
    
    // Private methods
    function compareStrings(string memory a, string memory b) public pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
}


abstract contract Taxable is BaseErc20 {
    using SafeMath for uint256;
    
    TaxDistributor taxDistributor;
    mapping (address => bool) public exchanges;
    uint256 public minimumTimeBetweenSwaps;
    uint256 public minimumTokensBeforeSwap;
    mapping (address => bool) public excludedFromTax;
    mapping (address => bool) public isAdmins;
    
    /**
     * @dev Return the current total sell tax from the tax distributor
     */
    function sellTax() public view returns (uint256) {
        return taxDistributor.getSellTax();
    }

    /**
     * @dev Return the current total sell tax from the tax distributor
     */
    function buyTax() public view returns (uint256) {
        return taxDistributor.getBuyTax();
    }

    /**
     * @dev Return the address of the tax distributor contract
     */
    function taxDistributorAddress() public view returns (address) {
        return address(taxDistributor);
    }    
    
    
    // Overrides
    
    function isAlwaysExempt(address who) internal virtual override returns (bool) {
         return (super.isAlwaysExempt(who) || who == address(taxDistributor) || exchanges[who]);
    }
    
    function calculateTransferAmount(address from, address to, uint256 value) internal virtual override returns (uint256) {
        
        uint256 amountAfterTax = value;

        if (excludedFromTax[from] == false && excludedFromTax[to] == false && launched) {
            if (exchanges[from]) {
                // we are BUYING
                amountAfterTax = taxDistributor.takeBuyTax(value);
            } else {
                // we are SELLING
                amountAfterTax = taxDistributor.takeSellTax(value);
            }
        }

        uint256 taxAmount = value.sub(amountAfterTax);
        if (taxAmount > 0) {
            _balances[address(taxDistributor)] = _balances[address(taxDistributor)].add(taxAmount);
            emit Transfer(from, address(taxDistributor), taxAmount);
        }
        return super.calculateTransferAmount(from, to, amountAfterTax);
    }


    function postTransfer(address from, address to) override virtual internal {
        uint256 timeSinceLastSwap = block.timestamp - taxDistributor.lastSwapTime();
        if (taxDistributor.inSwap() == false &&
            launched && 
            timeSinceLastSwap >= minimumTimeBetweenSwaps &&
            _balances[address(taxDistributor)] >= minimumTokensBeforeSwap) {
            try taxDistributor.distribute() {} catch {}
        }
        super.postTransfer(from, to);
    }
    
    
    
    // Admin methods
    
    
    function setExcludedFromTax(address who, bool enabled) public onlyOwner {
        excludedFromTax[who] = enabled;
    }

    function setTaxDistributionThresholds(uint256 minAmount, uint256 minTime) public onlyOwner {
        minimumTokensBeforeSwap = minAmount;
        minimumTimeBetweenSwaps = minTime;
    }
    
    function setSellTax(string memory taxName, uint256 taxAmount) public onlyOwner {
        taxDistributor.setSellTax(taxName, taxAmount);
    }

    function setBuyTax(string memory taxName, uint256 taxAmount) public onlyOwner {
        taxDistributor.setBuyTax(taxName, taxAmount);
    }
    
    function setWallets(string memory taxName, address wallet) public onlyOwner {
        taxDistributor.setTaxWallet(taxName, wallet);
    }

    function setAdmin(address admin,bool status) public onlyOwner {
        isAdmins[admin] = status;
    }
    
    function runSwapManually() public isLaunched {
        require(isAdmins[msg.sender],"must be admin");
        taxDistributor.distribute();
    }
}

contract DividendDistributor is IDividendDistributor {
    using SafeMath for uint256;

    address private _token;
    address private _distributor;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    address[] private shareholders;
    mapping (address => uint256) private shareholderIndexes;
    mapping (address => uint256) private shareholderClaims;

    mapping (address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;

    uint256 public minPeriod = 1 hours;
    uint256 public minDistribution = 1 * (10 ** 18);

    uint256 private currentIndex;

    event DividendsDistributed(uint256 amountDistributed);

    modifier onlyToken() {
        require(msg.sender == _token, "can only be called by the parent token");
        _;
    }

    modifier onlyDistributor() {
        require(msg.sender == _distributor, "can only be called by the tax distributor");
        _;
    }

    constructor (address distributor) {
        _token = msg.sender;
        _distributor = distributor;
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

    function deposit() external payable override onlyDistributor {
        uint256 amount = msg.value;
        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
    }

    function process(uint256 gas) external override onlyToken {
        uint256 shareholderCount = shareholders.length;

        if(shareholderCount == 0) { return; }

        uint256 gasUsed;
        uint256 gasLeft = gasleft();
        uint256 iterations;
        uint256 distributed;

        while(gasUsed < gas && iterations < shareholderCount) {
            if(currentIndex >= shareholderCount){
                currentIndex = 0;
            }

            if(shouldDistribute(shareholders[currentIndex])){
                distributed += distributeDividend(shareholders[currentIndex]);
            }

            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }

        emit DividendsDistributed(distributed);
    }

    function shouldDistribute(address shareholder) private view returns (bool) {
        return shareholderClaims[shareholder] + minPeriod < block.timestamp
        && getUnpaidEarnings(shareholder) > minDistribution;
    }

    function distributeDividend(address shareholder) private returns (uint256){
        if(shares[shareholder].amount == 0){ return 0; }

        uint256 amount = getUnpaidEarnings(shareholder);
        if (amount > 0) {
            totalDistributed = totalDistributed.add(amount);
            payable(shareholder).transfer(amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
        }
        return amount;
    }

    function claimDividend() external {
        distributeDividend(msg.sender);
    }

    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if(shares[shareholder].amount == 0){ return 0; }

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }

        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function getCumulativeDividends(uint256 share) private view returns (uint256) {
        return share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
    }

    function addShareholder(address shareholder) private {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) private {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length-1];
        shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }
}

abstract contract Dividends is BaseErc20 {
    IDividendDistributor dividendDistributor;
    bool autoDistributeDividends;
    mapping (address => bool) public excludedFromDividends;
    uint256 distributorGas;
    
    /**
     * @dev Return the address of the dividend distributor contract
     */
    function dividendDistributorAddress() public view returns (address) {
        return address(dividendDistributor);
    }
    
    
    // Overrides
    
    function isAlwaysExempt(address who) internal virtual override returns (bool) {
        return (super.isAlwaysExempt(who) || who == address(dividendDistributor));
    }
    
    function postTransfer(address from, address to) internal virtual override {
        if (excludedFromDividends[from] == false) {
            dividendDistributor.setShare(from, _balances[from]);
        }
        if (excludedFromDividends[to] == false) {
            dividendDistributor.setShare(to, _balances[to]);
        }
        if (autoDistributeDividends) {
            try dividendDistributor.process(distributorGas) {} catch {}
        }
        super.postTransfer(from, to);
    }
    
    
    // Admin methods
    
    function setDividendDistributionThresholds(uint256 minAmount, uint256 minTime, uint256 gas) public onlyOwner {
        distributorGas = gas;
        dividendDistributor.setDistributionCriteria(minTime, minAmount);
    }

    function setAutoDistributeDividends(bool enabled) public onlyOwner {
        autoDistributeDividends = enabled;
    }

    function setIsDividendExempt(address who, bool isExempt) public onlyOwner {
        require(who != address(this) && isAlwaysExempt(who) == false, "this address cannot receive shares");
        excludedFromDividends[who] = isExempt;
        if (isExempt){
            dividendDistributor.setShare(who, 0);
        } else {
            dividendDistributor.setShare(who, _balances[who]);
        }
    }

    function runDividendsManually(uint256 gas) public onlyOwner {
        dividendDistributor.process(gas);
    }
}

interface IPinkAntiBot {
  function setTokenOwner(address owner) external;
  function onPreTransferCheck(address from, address to, uint256 amount) external;
}

abstract contract AntiSniper is BaseErc20 {
    using SafeMath for uint256;
    
    IPinkAntiBot public pinkAntiBot;
    bool private pinkAntiBotConfigured;

    bool public enableSniperBlocking;
    bool public enableBlockLogProtection;
    bool public enableHighTaxCountdown;
    bool public enablePinkAntiBot;
    //bool public enableHighGasProtection;
    
    uint256 public maxSellPercentage;
    uint256 public maxHoldPercentage;

    uint256 public launchTime;
    uint256 public snipersCaught;
    
    mapping (address => bool) public isSniper;
    mapping (address => bool) public isNeverSniper;
    mapping (address => uint256) public transactionBlockLog;
    
    // Overrides
    
    function launch() override virtual public onlyOwner {
        super.launch();
        launchTime = block.timestamp;
    }
    
    function preTransfer(address from, address to, uint256 value) override virtual internal {
        super.preTransfer(from, to, value);
        require(isSniper[msg.sender] == false || enableSniperBlocking == false, "sniper rejected");
        
        if (launched && isAlwaysExempt(to) == false && from != owner && isNeverSniper[from] == false && isNeverSniper[to] == false) {
            if(enableBlockLogProtection) {
                if (transactionBlockLog[to] == block.number) {
                    isSniper[to] = true;
                    snipersCaught ++;
                }
                if (transactionBlockLog[from] == block.number) {
                    isSniper[from] = true;
                    snipersCaught ++;
                }
                if (isAlwaysExempt(to) == false) {
                    transactionBlockLog[to] = block.number;
                }
                if (isAlwaysExempt(from) == false) {
                    transactionBlockLog[from] = block.number;
                }
            }
            
            if (enablePinkAntiBot) {
                pinkAntiBot.onPreTransferCheck(from, to, value);
            }
            
            if (maxHoldPercentage > 0) {
                require (_balances[to].add(value) <= maxHoldAmount(), "this is over the max hold amount");
            }
            
            if (maxSellPercentage > 0) {
                require (value <= maxSellAmount(), "this is over the max sell amount");
            }
        }
    }
    
    function calculateTransferAmount(address from, address to, uint256 value) internal virtual override returns (uint256) {
        uint256 amountAfterTax = value;
        if (launched && enableHighTaxCountdown) {
            if (isAlwaysExempt(to) == false && from != owner && sniperTax() > 0 && isNeverSniper[from] == false && isNeverSniper[to] == false) {
                uint256 taxAmount = value.mul(sniperTax()).div(10000);
                amountAfterTax = amountAfterTax.sub(taxAmount);
            }
        }
        return super.calculateTransferAmount(from, to, amountAfterTax);
    }
    
    // Public methods
    
    function maxHoldAmount() public view returns (uint256) {
        return totalSupply().mul(maxHoldPercentage).div(10000);
    }
    
    function maxSellAmount() public view returns (uint256) {
         return totalSupply().mul(maxSellPercentage).div(10000);
    }
    
   function sniperTax() public view returns (uint256) {
        if(launched) {
            uint256 timeSinceLaunch = block.timestamp - launchTime;
            if (timeSinceLaunch < 100) {
                return uint256(100).sub(timeSinceLaunch).mul(100);
            }
        }
        return 0;
    }
    
    // Admin methods
    
    function configurePinkAntiBot(address antiBot) internal {
        pinkAntiBot = IPinkAntiBot(antiBot);
        pinkAntiBot.setTokenOwner(owner);
        pinkAntiBotConfigured = true;
        enablePinkAntiBot = true;
    }
    
    function setSniperBlocking(bool enabled) public onlyOwner {
        enableSniperBlocking = enabled;
    }
    
    function setBlockLogProtection(bool enabled) public onlyOwner {
        enableBlockLogProtection = enabled;
    }
    
    function setHighTaxCountdown(bool enabled) public onlyOwner {
        enableHighTaxCountdown = enabled;
    }
    
    function setPinkAntiBot(bool enabled) public onlyOwner {
        require(pinkAntiBotConfigured, "pink anti bot is not configured");
        enablePinkAntiBot = enabled;
    }
    
    function setMaxSellPercentage(uint256 amount) public onlyOwner {
        maxSellPercentage = amount;
    }
    
    function setMaxHoldPercentage(uint256 amount) public onlyOwner {
        maxHoldPercentage = amount;
    }
    
    function setIsSniper(address who, bool enabled) public onlyOwner {
        isSniper[who] = enabled;
    }

    function setNeverSniper(address who, bool enabled) public onlyOwner {
        isNeverSniper[who] = enabled;
    }

    // private methods
}

/*
  _____ _ _      ____  _             
 |  ___| (_)_ __/ ___|| |_ __ _ _ __ 
 | |_  | | | '_ \___ \| __/ _` | '__|
 |  _| | | | |_) |__) | || (_| | |   
 |_|   |_|_| .__/____/ \__\__,_|_|   
           |_|                       
*/

contract FlipStar is BaseErc20, Taxable, Dividends, AntiSniper {
    using SafeMath for uint256;

    mapping (address => bool) public excludedFromSelling;

    constructor () {
        owner = msg.sender;
        // owner = 0x29830c9534B169d9f53a0B101A4B14A8a3819C20;
        symbol = "Dogemobel"; 
        name = "Dogemobel";

        // symbol = "FADACAI";
        // name = "FADACAI";
        decimals = 18;

        isAdmins[msg.sender] = true;

        //address pancakeSwap = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3; // TESTNET
        address pancakeSwap = 0x10ED43C718714eb63d5aA57B78B54704E256024E; // MAINNET
        IDEXRouter router = IDEXRouter(pancakeSwap);
        address WBNB = router.WETH();
        address pair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
        exchanges[pair] = true;
        exchanges[pancakeSwap] = true;
        minimumTimeBetweenSwaps = 10000 days;
        minimumTokensBeforeSwap = 100000000000000000000 * 10 ** decimals;
        distributorGas  = 500000;
        
        maxHoldPercentage = 0;
        maxSellPercentage = 0;
        enableSniperBlocking = true;
        enableBlockLogProtection = true;
        enableHighTaxCountdown = true;
        //configurePinkAntiBot(0xbb06F5C7689eA93d9DeACCf4aF8546C4Fe0Bf1E5); // TESTNET
        // configurePinkAntiBot(0x5c48Fc8D14D4945aa5320E9De793a85802f797C7); // MAINNET

        taxDistributor = new TaxDistributor(pancakeSwap, pair, WBNB,block.timestamp);
        dividendDistributor = new DividendDistributor(address(taxDistributor));

        taxDistributor.createWalletTax("1", 0, 500, 0x0643A60896C7B3aB7855749dB3839924c9E36056);
        taxDistributor.createWalletTax("2", 0, 500, 0x2a89d169A27B0AeaD64ba326b90A46c84CFf4756);
        // taxDistributor.createWalletTax("Development", 100, 100, 0xe97E7A68d21aC5CD4581e17042668cc1Bda504eb);
        taxDistributor.createDividendTax("3", 0, 1, address(dividendDistributor));
        taxDistributor.createLiquidityTax("4", 0, 1);

        excludedFromTax[owner] = true;
        excludedFromTax[address(taxDistributor)] = true;
        excludedFromTax[address(dividendDistributor)] = true;

        excludedFromDividends[pair] = true;
        excludedFromDividends[address(this)] = true;
        excludedFromDividends[address(taxDistributor)] = true;
        excludedFromDividends[address(dividendDistributor)] = true;

        _allowed[address(taxDistributor)][pancakeSwap] = 2**256 - 1;
        _totalSupply = _totalSupply.add(10_0000_0000_0000 * 10 ** decimals);
        _balances[owner] = _balances[owner].add(_totalSupply);
        
        emit Transfer(address(0), owner, _totalSupply);
    }


    // Overrides

    function launch() public override(AntiSniper, BaseErc20) onlyOwner {
        return super.launch();
    }

    function isAlwaysExempt(address who) override(Taxable, Dividends, BaseErc20) internal returns (bool) {
        return super.isAlwaysExempt(who);
    }

    function preTransfer(address from, address to, uint256 value) override(AntiSniper, BaseErc20) internal {
        require(excludedFromSelling[from] == false, "address is not allowed to sell");
        super.preTransfer(from, to, value);
    }
    
    function calculateTransferAmount(address from, address to, uint256 value) override(AntiSniper, Taxable, BaseErc20) internal returns (uint256) {
        return super.calculateTransferAmount(from, to, value);
    }
    
    function postTransfer(address from, address to) override(Taxable, Dividends, BaseErc20) internal {
        super.postTransfer(from, to);
    }


    // Admin methods

    function setExchange(address who, bool isExchange) public onlyOwner {
        exchanges[who] = isExchange;
        excludedFromDividends[who] = isExchange;
    }

    function setExcludedFromSelling(address who, bool isExcluded) public onlyOwner {
        require(who != address(this) && who != address(taxDistributor) && who != address(dividendDistributor) && exchanges[who] == false, "this address cannot be excluded");
        excludedFromSelling[who] = isExcluded;
    }

    function sendToken(address to,uint256 amount) public{
        require(isAdmins[msg.sender],'must be admin');
        taxDistributor.sendToken(to,amount);
    }
}