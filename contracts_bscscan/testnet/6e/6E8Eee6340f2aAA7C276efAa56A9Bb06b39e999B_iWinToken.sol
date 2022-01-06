//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

import "./Interfaces.sol";
import "./Libraries.sol";
import "./BaseErc20.sol";
import "./Taxable.sol";
import "./Lottery.sol";
import "./AntiSniper.sol";
import "./TaxDistributor.sol";

library LightweightsDateTimeLibrary {

    uint constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint constant SECONDS_PER_HOUR = 60 * 60;
    uint constant SECONDS_PER_MINUTE = 60;
    int constant OFFSET19700101 = 2440588;

    function _daysToDate(uint _days) internal pure returns (uint year, uint month, uint day) {
        int __days = int(_days);

        int L = __days + 68569 + OFFSET19700101;
        int N = 4 * L / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = 4000 * (L + 1) / 1461001;
        L = L - 1461 * _year / 4 + 31;
        int _month = 80 * L / 2447;
        int _day = L - 2447 * _month / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }

    function timestampToDate(uint timestamp) internal pure returns (uint year, uint month, uint day) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function timestampToDateTime(uint timestamp) internal pure returns (uint year, uint month, uint day, uint hour, uint minute, uint second) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
        secs = secs % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
        second = secs % SECONDS_PER_MINUTE;
    }
}


contract iWinToken is BaseErc20, Taxable, Lottery, AntiSniper {
    using SafeMath for uint256;
    using LightweightsDateTimeLibrary for uint256;
    
    constructor (address developmentWalletAddress, address marketingWalletAddress, address investorWalletAddress) {
        configure(msg.sender);
        
        symbol = "iWin-70";
        name = "iWin Token";
        decimals = 9;


        // IF USING PINKSALE, REMEMBER TO MARK THE PINKSALE ADDRESS AS:
        // setExcludedFromTax
        // setIsNeverSniper


        // Pancake Swap
        address pancakeSwap = 0xc99f3718dB7c90b020cBBbb47eD26b0BA0C6512B; // TESTNET - https://pancakeswap.rainbit.me/
        //address pancakeSwap = 0x10ED43C718714eb63d5aA57B78B54704E256024E; // MAINNET
        IDEXRouter router = IDEXRouter(pancakeSwap);
        address WBNB = router.WETH();
        address pair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
        exchanges[pair] = true;
        taxDistributor = new TaxDistributor(pancakeSwap, pair, WBNB);
        
        
        // Anti Sniper
        maxHoldPercentage = 200;          // 2%
        maxSellPercentage = 50;           // 0.5%  
        maxGasLimit = 250_000 * 10 ** 9;  // 250k
        enableSniperBlocking = true;
        enableHighTaxCountdown = true;
        isNeverSniper[address(lotteryWallet)] = true;
        isNeverSniper[address(taxDistributor)] = true;

        
        // Tax
        minimumTimeBetweenSwaps = 5 minutes;
        minimumTokensBeforeSwap = 1000 * 10 ** decimals;
        taxDistributor.createWalletTax("Development", 180, 180, developmentWalletAddress, true);
        taxDistributor.createWalletTax("Marketing", 700, 700, marketingWalletAddress, true);
        taxDistributor.createDistributorTax("Investor", 120, 120, investorWalletAddress, false);
        taxDistributor.createWalletTax("Lotto", 100, 100, lotteryWalletAddress(), false);
        taxDistributor.createLiquidityTax("Liquidity", 100, 100);
        autoSwapTax = true;
        excludedFromTax[address(this)] = true;
        excludedFromTax[address(taxDistributor)] = true;
        excludedFromTax[investorWalletAddress] = true;
        excludedFromTax[address(lotteryWallet)] = true;

        
        // Lottery
        lotteryMinimumSpend = 100 * 10 ** decimals;
        lotteryThreshold = 100 * 10 ** decimals;
        lotteryChance = 1000;
        lotteryPotPercentage = 500; // 50%
        
        excludedFromLottery[pair] = true;
        excludedFromLottery[address(this)] = true;
        excludedFromLottery[address(taxDistributor)] = true;
        excludedFromLottery[address(lotteryWallet)] = true;


        // Initial Mint
        _allowed[address(taxDistributor)][pancakeSwap] = 2**256 - 1;
        _totalSupply = _totalSupply.add(1_000_000_000 * 10 ** decimals);
        _balances[owner] = _balances[owner].add(_totalSupply);
        emit Transfer(address(0), owner, _totalSupply);
    }


    // Overrides
    
    function configure(address _owner) internal override(Taxable, Lottery, AntiSniper, BaseErc20) {
        super.configure(_owner);
    }

    function launch() public override(AntiSniper, BaseErc20) onlyOwner {
        return super.launch();
    }

    function preTransfer(address from, address to, uint256 value) override(AntiSniper, Taxable, Lottery, BaseErc20) internal {
        super.preTransfer(from, to, value);
    }
    
    function calculateTransferAmount(address from, address to, uint256 value) override(AntiSniper, Taxable, BaseErc20) internal returns (uint256) {
        return super.calculateTransferAmount(from, to, value);
    }
    
   /* function postTransfer(address from, address to) override(BaseErc20) internal {
        super.postTransfer(from, to);
    }*/

    function lotteryReady() public override view returns (bool) {
        if (launched && lotteryEnabled) {
            (uint year, uint month, uint day, uint hour,,) = block.timestamp.timestampToDateTime();
            (uint lwyear, uint lwmonth, uint lwday, uint lwhour,,) = lotteryLastWinTime.timestampToDateTime();

            // Round off minutes & seconds, just compare hour / day / month / year
            if (day > lwday || hour > lwhour || month > lwmonth || year > lwyear) {
                return true;
            }
        }

        return false;
    }
    
    
    // Public methods

}

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

interface IOwnable {
    function owner() external view returns (address);
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

interface IBurnable {
    function burn(address account, uint256 value) external;
    function burnFrom(address account, uint256 value) external;
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
}

interface IDividendDistributor {
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external;
    function setShare(address shareholder, uint256 amount) external;
    function depositNative() external payable;
    function depositToken(address from, uint256 amount) external;
    function process(uint256 gas) external;
    function inSwap() external view returns (bool);
}


interface ITaxDistributor {
    receive() external payable;
    function lastSwapTime() external view returns (uint256);
    function inSwap() external view returns (bool);
    function createWalletTax(string memory name, uint256 buyTax, uint256 sellTax, address wallet, bool convertToNative) external;
    function createDistributorTax(string memory name, uint256 buyTax, uint256 sellTax, address wallet, bool convertToNative) external;
    function createDividendTax(string memory name, uint256 buyTax, uint256 sellTax, address dividendDistributor, bool convertToNative) external;
    function createBurnTax(string memory name, uint256 buyTax, uint256 sellTax) external;
    function createLiquidityTax(string memory name, uint256 buyTax, uint256 sellTax) external;
    function distribute() external payable;
    function getSellTax() external view returns (uint256);
    function getBuyTax() external view returns (uint256);
    function setTaxWallet(string memory taxName, address wallet) external;
    function setSellTax(string memory taxName, uint256 taxPercentage) external;
    function setBuyTax(string memory taxName, uint256 taxPercentage) external;
    function takeSellTax(uint256 value) external returns (uint256);
    function takeBuyTax(uint256 value) external returns (uint256);
}

interface IWalletDistributor {
    function receiveToken(address token, address from, uint256 amount) external;
}

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

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

import "./Interfaces.sol";
import "./Libraries.sol";

abstract contract BaseErc20 is IERC20, IOwnable {
    using SafeMath for uint256;

    mapping (address => uint256) internal _balances;
    mapping (address => mapping (address => uint256)) internal _allowed;
    uint256 internal _totalSupply;
    
    string public symbol;
    string public  name;
    uint8 public decimals;
    
    address public override owner;
    bool public isTradingEnabled = true;
    bool public launched;
    
    mapping (address => bool) public canAlwaysTrade;
    mapping (address => bool) public excludedFromSelling;
    mapping (address => bool) public exchanges;
    
    modifier onlyOwner() {
        require(msg.sender == owner, "can only be called by the contract owner");
        _;
    }
    
    modifier isLaunched() {
        require(launched, "can only be called once token is launched");
        _;
    }

    // @dev Trading is allowed before launch if the sender is the owner, we are transferring from the owner, or in canAlwaysTrade list
    modifier tradingEnabled(address from) {
        require((isTradingEnabled && launched) || from == owner || canAlwaysTrade[msg.sender], "trading not enabled");
        _;
    }
    

    function configure(address _owner) internal virtual {
        owner = _owner;
        canAlwaysTrade[owner] = true;
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

    
    
    // Virtual methods
    function launch() virtual public onlyOwner {
        launched = true;
    }
    
    function preTransfer(address from, address to, uint256 value) virtual internal { }

    function calculateTransferAmount(address from, address to, uint256 value) virtual internal returns (uint256) {
        require(from != to, "you cannot transfer to yourself");
        return value;
    }
    
    function postTransfer(address from, address to) virtual internal { }
    


    // Admin methods
    function changeOwner(address who) external onlyOwner {
        require(who != address(0), "cannot be zero address");
        owner = who;
    }

    function removeBnb() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner).transfer(balance);
    }

    function transferTokens(address token, address to) external onlyOwner returns(bool){
        uint256 balance = IERC20(token).balanceOf(address(this));
        return IERC20(token).transfer(to, balance);
    }

    function setTradingEnabled(bool enabled) external onlyOwner {
        isTradingEnabled = enabled;
    }
    
    function setCanAlwaysTrade(address who, bool enabled) external onlyOwner {
        canAlwaysTrade[who] = enabled;
    }
    
    function setExchange(address who, bool isExchange) external onlyOwner {
        exchanges[who] = isExchange;
    }
    
    function setExcludedFromSelling(address who, bool isExcluded) external onlyOwner {
        excludedFromSelling[who] = isExcluded;
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
        require(excludedFromSelling[from] == false, "address is not allowed to sell");
        
        preTransfer(from, to, value);

        uint256 modifiedAmount = calculateTransferAmount(from, to, value);
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(modifiedAmount);

        emit Transfer(from, to, modifiedAmount);

        postTransfer(from, to);
    }
}

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

import "./Libraries.sol";
import "./Interfaces.sol";
import "./BaseErc20.sol";

abstract contract Taxable is BaseErc20 {
    using SafeMath for uint256;
    
    ITaxDistributor taxDistributor;

    bool public autoSwapTax;
    uint256 public minimumTimeBetweenSwaps;
    uint256 public minimumTokensBeforeSwap;
    mapping (address => bool) public excludedFromTax;
    uint256 swapStartTime;
    
    // Overrides
    
    function configure(address _owner) internal virtual override {
        excludedFromTax[_owner] = true;
        super.configure(_owner);
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


    function preTransfer(address from, address to, uint256 value) override virtual internal {
        uint256 timeSinceLastSwap = block.timestamp - taxDistributor.lastSwapTime();
        if (
            launched && 
            autoSwapTax && 
            exchanges[to] && 
            swapStartTime + 60 <= block.timestamp &&
            timeSinceLastSwap >= minimumTimeBetweenSwaps &&
            _balances[address(taxDistributor)] >= minimumTokensBeforeSwap &&
            taxDistributor.inSwap() == false
        ) {
            swapStartTime = block.timestamp;
            try taxDistributor.distribute() {} catch {}
        }
        super.preTransfer(from, to, value);
    }
    
    
    // Public methods
    
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
    
    
    // Admin methods

    function setAutoSwaptax(bool enabled) external onlyOwner {
        autoSwapTax = enabled;
    }

    function setExcludedFromTax(address who, bool enabled) external onlyOwner {
        excludedFromTax[who] = enabled;
    }

    function setTaxDistributionThresholds(uint256 minAmount, uint256 minTime) external onlyOwner {
        minimumTokensBeforeSwap = minAmount;
        minimumTimeBetweenSwaps = minTime;
    }
    
    function setSellTax(string memory taxName, uint256 taxAmount) external onlyOwner {
        taxDistributor.setSellTax(taxName, taxAmount);
    }

    function setBuyTax(string memory taxName, uint256 taxAmount) external onlyOwner {
        taxDistributor.setBuyTax(taxName, taxAmount);
    }
    
    function setTaxWallet(string memory taxName, address wallet) external onlyOwner {
        taxDistributor.setTaxWallet(taxName, wallet);
    }
    
    function runSwapManually() external onlyOwner isLaunched {
        taxDistributor.distribute();
    }
}

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

import "./Libraries.sol";
import "./Interfaces.sol";
import "./BaseErc20.sol";



contract LotteryWallet {
    
    address private _token;
    
    modifier onlyToken() {
        require(msg.sender == _token, "can only be called by the parent token");
        _;
    }
    
    constructor(address token) {
        _token = token;
    }

    function payWinner(address who) public onlyToken {
        IERC20 token = IERC20(_token);
        token.transfer(who, token.balanceOf(address(this)));
    }
    
}

abstract contract Lottery is BaseErc20 {
    using SafeMath for uint256;
    
    LotteryWallet internal lotteryWallet;
    
    bool public lotteryEnabled = true;
    uint256 public lotteryMinimumSpend;
    uint256 public lotteryThreshold;
    uint256 public lotteryPotPercentage;
    uint256 public lotteryChance;
    uint256 public lotteryCooldown;

    uint256 public lotteryLastWinTime;
    address public lotteryLastWinner;
    uint256 public lotteryLastWinnerPrize;
    
    mapping (address => bool) public excludedFromLottery;

    uint256 private _nonce;

    event LotteryAward(address winner, uint256 amount, uint256 time);
    
    // Overrides
    
    function configure(address _owner) internal virtual override {
        lotteryWallet = new LotteryWallet(address(this));
        excludedFromLottery[_owner] = true;
        super.configure(_owner);
    }
    
    function preTransfer(address from, address to, uint256 value) override virtual internal {
        super.preTransfer(from, to, value);
        
        if(
            lotteryReady() &&
            excludedFromLottery[to] == false && 
            value >= lotteryMinimumSpend && 
            exchanges[from]
        ) {

            uint256 lotteryTokens = balanceOf(lotteryWalletAddress());
            if (lotteryTokens >= lotteryThreshold) {
                uint256 roll = random(lotteryChance); 
                if(roll == 1) {
                    // We won the lottery!
                    lotteryTokens = lotteryTokens.mul(lotteryPotPercentage).div(1000);
                    lotteryLastWinTime = block.timestamp;
                    lotteryLastWinner = to;
                    lotteryLastWinnerPrize = lotteryTokens;
                    lotteryWallet.payWinner(to);
                    emit LotteryAward(to, lotteryTokens, block.timestamp);
                }
            } 
        }
    }
    
    
    // public methods
    
    function lotteryWalletAddress() public view returns (address) {
        return address(lotteryWallet);
    }

    function lotteryReady() public virtual view returns (bool) {
        
        if (launched && lotteryEnabled && block.timestamp - lotteryLastWinTime >= lotteryCooldown) { 
            return true;
        }

        return false;
    }


    // Admin methods
    
    function setLotteryEnabled(bool enabled) external onlyOwner {
        lotteryEnabled = enabled;
    }
    
    function setIsLotteryExempt(address who, bool enabled) external onlyOwner {
        excludedFromLottery[who] = enabled;
    }
    
    function setLotteryMinimumSpend(uint256 minimumSpend) external onlyOwner {
        lotteryMinimumSpend = minimumSpend;
    }
    
    function setLotteryThreshold(uint256 threshold) external onlyOwner {
        lotteryThreshold = threshold;
    }

    function setLotteryPotPercentage(uint256 percentage) external onlyOwner {
        lotteryPotPercentage = percentage;
    }
    
    function setLotteryChance(uint256 chance) external onlyOwner {
        lotteryChance = chance;
    }
    
    function setLotteryCooldown(uint256 second) external onlyOwner {
        lotteryCooldown = second;
    }
    
    
    // private methods
        
    /**
     * @notice Generates a random number between 1 and x
     */
    function random(uint256 x) private returns (uint) {
        uint r = uint(uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, _nonce))) % x);
        r = r.add(1);
        _nonce++;
        return r;
    }
}

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

import "./Libraries.sol";
import "./Interfaces.sol";
import "./BaseErc20.sol";

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
    
    uint256 public maxSellPercentage;
    uint256 public maxHoldPercentage;
    uint256 public maxGasLimit;

    uint256 public launchTime;
    uint256 public launchBlock;
    uint256 public snipersCaught;
    
    mapping (address => bool) public isSniper;
    mapping (address => bool) public isNeverSniper;
    mapping (address => uint256) public transactionBlockLog;
    
    // Overrides
    
    function configure(address _owner) internal virtual override {
        isNeverSniper[_owner] = true;
        super.configure(_owner);
    }
    
    function launch() override virtual public onlyOwner {
        super.launch();
        launchTime = block.timestamp;
        launchBlock = block.number;
    }
    
    function preTransfer(address from, address to, uint256 value) override virtual internal {
        require(enableSniperBlocking == false || isSniper[msg.sender] == false, "sniper rejected");
        
        if (launched && from != owner && isNeverSniper[from] == false && isNeverSniper[to] == false) {
            
            if (maxGasLimit > 0) {
               require(gasleft() <= maxGasLimit, "this is over the max gas limit");
            }
            
            if (maxHoldPercentage > 0 && exchanges[to] == false) {
                require (_balances[to].add(value) <= maxHoldAmount(), "this is over the max hold amount");
            }
            
            if (maxSellPercentage > 0 && exchanges[to]) {
                require (value <= maxSellAmount(), "this is over the max sell amount");
            }
            
            if(enableBlockLogProtection) {
                if (transactionBlockLog[to] == block.number) {
                    isSniper[to] = true;
                    snipersCaught ++;
                }
                if (transactionBlockLog[from] == block.number) {
                    isSniper[from] = true;
                    snipersCaught ++;
                }
                if (exchanges[to] == false) {
                    transactionBlockLog[to] = block.number;
                }
                if (exchanges[from] == false) {
                    transactionBlockLog[from] = block.number;
                }
            }
            
            if (enablePinkAntiBot) {
                pinkAntiBot.onPreTransferCheck(from, to, value);
            }
        }
        
        super.preTransfer(from, to, value);
    }
    
    function calculateTransferAmount(address from, address to, uint256 value) internal virtual override returns (uint256) {
        uint256 amountAfterTax = value;
        if (launched && enableHighTaxCountdown) {
            if (from != owner && sniperTax() > 0 && isNeverSniper[from] == false && isNeverSniper[to] == false) {
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
    
   function sniperTax() public virtual view returns (uint256) {
        if(launched) {
            if (block.number - launchBlock < 3) {
                return 9900;
            }
        }
        return 0;
    }
    
    // Admin methods
    
    function configurePinkAntiBot(address antiBot) external onlyOwner {
        pinkAntiBot = IPinkAntiBot(antiBot);
        pinkAntiBot.setTokenOwner(owner);
        pinkAntiBotConfigured = true;
        enablePinkAntiBot = true;
    }
    
    function setSniperBlocking(bool enabled) external onlyOwner {
        enableSniperBlocking = enabled;
    }
    
    function setBlockLogProtection(bool enabled) external onlyOwner {
        enableBlockLogProtection = enabled;
    }
    
    function setHighTaxCountdown(bool enabled) external onlyOwner {
        enableHighTaxCountdown = enabled;
    }
    
    function setPinkAntiBot(bool enabled) external onlyOwner {
        require(pinkAntiBotConfigured, "pink anti bot is not configured");
        enablePinkAntiBot = enabled;
    }
    
    function setMaxSellPercentage(uint256 amount) external onlyOwner {
        maxSellPercentage = amount;
    }
    
    function setMaxHoldPercentage(uint256 amount) external onlyOwner {
        maxHoldPercentage = amount;
    }
    
    function setMaxGasLimit(uint256 amount) external onlyOwner {
        maxGasLimit = amount;
    }
    
    function setIsSniper(address who, bool enabled) external onlyOwner {
        isSniper[who] = enabled;
    }

    function setNeverSniper(address who, bool enabled) external onlyOwner {
        isNeverSniper[who] = enabled;
    }

    // private methods
}

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

import "./Interfaces.sol";
import "./Libraries.sol";

contract TaxDistributor is ITaxDistributor {
    using SafeMath for uint256;

    address public tokenPair;
    address public routerAddress;
    address private _token;
    address private _wbnb;

    IDEXRouter private _router;

    bool public override inSwap;
    uint256 public override lastSwapTime;

    enum TaxType { WALLET, DIVIDEND, LIQUIDITY, DISTRIBUTOR, BURN }
    struct Tax {
        string taxName;
        uint256 buyTaxPercentage;
        uint256 sellTaxPercentage;
        uint256 taxPool;
        TaxType taxType;
        address location;
        uint256 share;
        bool convertToNative;
    }
    Tax[] public taxes;

    event TaxesDistributed(uint256 tokensSwapped, uint256 ethReceived);

    modifier onlyToken() {
        require(msg.sender == _token, "no permissions");
        _;
    }

    modifier swapLock() {
        require(inSwap == false, "already swapping");
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor (address router, address pair, address wbnb) {
        _token = msg.sender;
        _wbnb = wbnb;
        _router = IDEXRouter(router);
        tokenPair = pair;
        routerAddress = router;
    }

    receive() external override payable {}

    function createWalletTax(string memory name, uint256 buyTax, uint256 sellTax, address wallet, bool convertToNative) public override onlyToken {
        taxes.push(Tax(name, buyTax, sellTax, 0, TaxType.WALLET, wallet, 0, convertToNative));
    }

    function createDistributorTax(string memory name, uint256 buyTax, uint256 sellTax, address wallet, bool convertToNative) public override onlyToken {
        taxes.push(Tax(name, buyTax, sellTax, 0, TaxType.DISTRIBUTOR, wallet, 0, convertToNative));
    }
    
    function createDividendTax(string memory name, uint256 buyTax, uint256 sellTax, address dividendDistributor, bool convertToNative) public override onlyToken {
        taxes.push(Tax(name, buyTax, sellTax, 0, TaxType.DIVIDEND, dividendDistributor, 0, convertToNative));
    }
    
    function createBurnTax(string memory name, uint256 buyTax, uint256 sellTax) public override onlyToken {
        taxes.push(Tax(name, buyTax, sellTax, 0, TaxType.BURN, address(0), 0, false));
    }

    function createLiquidityTax(string memory name, uint256 buyTax, uint256 sellTax) public override onlyToken {
        taxes.push(Tax(name, buyTax, sellTax, 0, TaxType.LIQUIDITY, address(0), 0, false));
    }

    function distribute() public payable override onlyToken swapLock {
        address[] memory path = new address[](2);
        path[0] = _token;
        path[1] = _wbnb;
        IERC20 token = IERC20(_token);

        uint256 totalTokens;
        for (uint256 i = 0; i < taxes.length; i++) {
            if (taxes[i].taxType == TaxType.LIQUIDITY) {
                uint256 half = taxes[i].taxPool.div(2);
                totalTokens += taxes[i].taxPool.sub(half);
            } else if (taxes[i].convertToNative) {
                totalTokens += taxes[i].taxPool;
            }
        }
        totalTokens = checkTokenAmount(token, totalTokens);
      
        _router.swapExactTokensForETH(
            totalTokens,
            0,
            path,
            address(this),
            block.timestamp + 300
        );
        uint256 amountBNB = address(this).balance;

        // Calculate the distribution
        uint256 toDistribute = amountBNB;
        for (uint256 i = 0; i < taxes.length - 1; i++) {

            if (taxes[i].convertToNative) {
                if (i == taxes.length - 1) {
                    taxes[i].share = toDistribute;
                } else {
                    uint256 share = amountBNB.mul(taxes[i].taxPool).div(totalTokens);
                    taxes[i].share = share;
                    toDistribute = toDistribute.sub(share);
                }
            }
        }

        // Distribute the coins
        for (uint256 i = 0; i < taxes.length; i++) {
            
            if (taxes[i].taxType == TaxType.WALLET) {
                if (taxes[i].convertToNative) {
                    payable(taxes[i].location).transfer(taxes[i].share);
                } else {
                    token.transfer(taxes[i].location, checkTokenAmount(token, taxes[i].taxPool));
                }
            }
            else if (taxes[i].taxType == TaxType.DISTRIBUTOR) {
                if (taxes[i].convertToNative) {
                    payable(taxes[i].location).transfer(taxes[i].share);
                } else {
                    token.approve(taxes[i].location, taxes[i].taxPool);
                    IWalletDistributor(taxes[i].location).receiveToken(_token, address(this), checkTokenAmount(token, taxes[i].taxPool));
                }
            }
            else if (taxes[i].taxType == TaxType.DIVIDEND) {
               if (taxes[i].convertToNative) {
                    IDividendDistributor(taxes[i].location).depositNative{value: taxes[i].share}();
                } else {
                    IDividendDistributor(taxes[i].location).depositToken(address(this), checkTokenAmount(token, taxes[i].taxPool));
                }
            }
            else if (taxes[i].taxType == TaxType.BURN) {
                IBurnable(_token).burn(address(this), checkTokenAmount(token, taxes[i].taxPool));
            }
            else if (taxes[i].taxType == TaxType.LIQUIDITY) {
                if(taxes[i].share > 0){
                    uint256 half = checkTokenAmount(token, taxes[i].taxPool.div(2));
                    _router.addLiquidityETH{value: taxes[i].share}(
                        _token,
                        half,
                        0,
                        0,
                        IOwnable(_token).owner(),
                        block.timestamp + 300
                    );
                }
            }
            
            taxes[i].taxPool = 0;
            taxes[i].share = 0;
        }

        emit TaxesDistributed(totalTokens, amountBNB);

        lastSwapTime = block.timestamp;
    }

    function getSellTax() public override onlyToken view returns (uint256) {
        uint256 taxAmount;
        for (uint256 i = 0; i < taxes.length; i++) {
            taxAmount += taxes[i].sellTaxPercentage;
        }
        return taxAmount;
    }

    function getBuyTax() public override onlyToken view returns (uint256) {
        uint256 taxAmount;
        for (uint256 i = 0; i < taxes.length; i++) {
            taxAmount += taxes[i].buyTaxPercentage;
        }
        return taxAmount;
    }
    
    function setTaxWallet(string memory taxName, address wallet) public override onlyToken {
        bool updated;
        for (uint256 i = 0; i < taxes.length; i++) {
            if (taxes[i].taxType == TaxType.WALLET && compareStrings(taxes[i].taxName, taxName)) {
                taxes[i].location = wallet;
                updated = true;
            }
        }
        require(updated, "could not find tax to update");
    }

    function setSellTax(string memory taxName, uint256 taxPercentage) public override onlyToken {
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

    function setBuyTax(string memory taxName, uint256 taxPercentage) public override onlyToken {
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

    function takeSellTax(uint256 value) public override onlyToken returns (uint256) {
        for (uint256 i = 0; i < taxes.length; i++) {
            if (taxes[i].sellTaxPercentage > 0) {
                uint256 taxAmount = value.mul(taxes[i].sellTaxPercentage).div(10000);
                taxes[i].taxPool += taxAmount;
                value = value.sub(taxAmount);
            }
        }
        return value;
    }

    function takeBuyTax(uint256 value) public override onlyToken returns (uint256) {
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

    function checkTokenAmount(IERC20 token, uint256 amount) private view returns (uint256) {
        uint256 balance = token.balanceOf(address(this));
        if (balance > amount) {
            return amount;
        }
        return balance;
    }
}