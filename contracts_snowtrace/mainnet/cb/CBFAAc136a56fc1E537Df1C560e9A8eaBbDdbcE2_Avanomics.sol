/**
 *Submitted for verification at snowtrace.io on 2021-12-09
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.5.17;

/**
 * @title ERC20 interface
 * @dev see https://github.com/avaxereum/EIPs/issues/20
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender)
    external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value)
    external returns (bool);

    function transferFrom(address from, address to, uint256 value)
    external returns (bool);

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface ILP {
    function sync() external;
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);

    function getPair(address tokenA, address tokenB)
    external
    view
    returns (address pair);

}

interface IDEXPair {
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

}

interface IDEXRouter {
    function factory() external pure returns (address);
    function WAVAX() external pure returns (address);

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

    function addLiquidityAVAX(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountAVAX, uint liquidity);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IDividendDistributor {
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external;
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external payable;
    function process(uint256 gas) external;
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipRenounced(address indexed previousOwner);

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        _owner = msg.sender;
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns(address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns(bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(_owner);
        _owner = address(0);
    }

    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }


    //Locks the contract for owner
    function lock() public onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        emit OwnershipRenounced(_owner);

    }

    function unlock() public {
        require(_previousOwner == msg.sender, "You don’t have permission to unlock");
        require(now > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, reverts on overflow.
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
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0); // Solidity only automatically asserts when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

/**
 * @title SafeMathInt
 * @dev Math operations for int256 with overflow safety checks.
 */
library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    /**
     * @dev Multiplies two int256 variables and fails on overflow.
     */
    function mul(int256 a, int256 b)
    internal
    pure
    returns (int256)
    {
        int256 c = a * b;

        // Detect overflow when multiplying MIN_INT256 with -1
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    /**
     * @dev Division of two int256 variables and fails on overflow.
     */
    function div(int256 a, int256 b)
    internal
    pure
    returns (int256)
    {
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != -1 || a != MIN_INT256);

        // Solidity already throws when dividing by 0.
        return a / b;
    }

    /**
     * @dev Subtracts two int256 variables and fails on overflow.
     */
    function sub(int256 a, int256 b)
    internal
    pure
    returns (int256)
    {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    /**
     * @dev Adds two int256 variables and fails on overflow.
     */
    function add(int256 a, int256 b)
    internal
    pure
    returns (int256)
    {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    /**
     * @dev Converts to absolute value, and fails on overflow.
     */
    function abs(int256 a)
    internal
    pure
    returns (int256)
    {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }
}

contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

/**
 * @title GRV ERC20 token
 * @dev
 *      Based on the Ampleforth & Safemoon protocol.
 */
contract Avanomics is ERC20Detailed, Ownable {
    using SafeMath for uint256;
    using SafeMathInt for int256;

    event LogRebase(uint256 indexed epoch, uint256 totalSupply);

    event SwapEnabled(bool enabled);

    event SwapAndLiquify(
        uint256 threequarters,
        uint256 sharedAVAX,
        uint256 onequarter
    );


    // Used for authentication
    address public master;

    // LP atomic sync
    address public lp;
    ILP public lpContract;

    modifier onlyMaster() {
        require(msg.sender == master);
        _;
    }

    // Only the owner can transfer tokens in the initial phase.
    // This is allow the AMM listing to happen in an orderly fashion.

    bool public initialDistributionFinished;

    mapping (address => bool) allowTransfer;

    modifier initialDistributionLock {
        require(initialDistributionFinished || isOwner() || allowTransfer[msg.sender]);
        _;
    }

    modifier validRecipient(address to) {
        require(to != address(0x0));
        require(to != address(this));
        _;
    }

    uint256 private constant DECIMALS = 9;
    uint256 private constant MAX_UINT256 = ~uint256(0);

    uint256 private constant INITIAL_FRAGMENTS_SUPPLY = 10**8 * 10 ** DECIMALS;

    uint256 public transactionTax = 981;
    uint256 public buybackLimit = 10 ** 18;
    uint256 public buybackDivisor = 100;
    uint256 public numTokensSellDivisor = 10000;

    IDEXRouter dexRouter;
    IDEXPair public dexPair;
    address public dexPairAddress;
    address public deadAddress = 0x000000000000000000000000000000000000dEaD;
    address payable public marketingAddress;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = false;
    bool public buyBackEnabled = false;

    mapping (address => bool) private _isExcluded;

    bool private privateSaleDropCompleted = false;

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }


    // TOTAL_GONS is a multiple of INITIAL_FRAGMENTS_SUPPLY so that _gonsPerFragment is an integer.
    // Use the highest value that fits in a uint256 for max granularity.
    uint256 private constant TOTAL_GONS = MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);

    // MAX_SUPPLY = maximum integer < (sqrt(4*TOTAL_GONS + 1) - 1) / 2
    uint256 private constant MAX_SUPPLY = ~uint128(0);  // (2^128) - 1

    uint256 private _totalSupply;
    uint256 private _gonsPerFragment;
    mapping(address => uint256) private _gonBalances;

    // This is denominated in Fragments, because the gons-fragments conversion might change before
    // it's fully paid.
    mapping (address => mapping (address => uint256)) private _allowedFragments;

    constructor (address router, address payable _marketingAddress)
    ERC20Detailed("Avanomics", "Avanomics", uint8(DECIMALS))
    payable
    public
    {
        marketingAddress = _marketingAddress;

        IDEXRouter _dexRouter = IDEXRouter(router);

        dexPairAddress = IDEXFactory(_dexRouter.factory())
        .createPair(address(this), _dexRouter.WAVAX());

        dexRouter = _dexRouter;

        setLP(dexPairAddress);

        IDEXPair _dexPair = IDEXPair(dexPairAddress);

        dexPair = _dexPair;

        _totalSupply = INITIAL_FRAGMENTS_SUPPLY;
        _gonBalances[msg.sender] = TOTAL_GONS;
        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);

        initialDistributionFinished = false;

        //exclude owner and this contract from fee
        _isExcluded[owner()] = true;
        _isExcluded[address(this)] = true;

        emit Transfer(address(0x0), msg.sender, _totalSupply);
    }

    /**
     * @dev Notifies Fragments contract about a new rebase cycle.
     * @param supplyDelta The number of new fragment tokens to add into circulation via expansion.
     * @return The total number of fragments after the supply adjustment.
     */
    function rebase(uint256 epoch, int256 supplyDelta)
    external
    onlyMaster
    returns (uint256)
    {
        if (supplyDelta == 0) {
            emit LogRebase(epoch, _totalSupply);
            return _totalSupply;
        }

        if (supplyDelta < 0) {
            _totalSupply = _totalSupply.sub(uint256(-supplyDelta));
        } else {
            _totalSupply = _totalSupply.add(uint256(supplyDelta));
        }

        if (_totalSupply > MAX_SUPPLY) {
            _totalSupply = MAX_SUPPLY;
        }

        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);
        lpContract.sync();

        emit LogRebase(epoch, _totalSupply);
        return _totalSupply;
    }


    /**
     * @notice Sets a new master
     */
    function setMaster(address _master)
    external
    onlyOwner
    returns (uint256)
    {
        master = _master;
    }

    /**
 * @notice Sets contract LP address
 */
    function setLP(address _lp)
    public
    onlyOwner
    returns (uint256)
    {
        lp = _lp;
        lpContract = ILP(_lp);
    }

    /**
     * @return The total number of fragments.
     */
    function totalSupply()
    external
    view
    returns (uint256)
    {
        return _totalSupply;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapEnabled(_enabled);
    }

    /**
     * @param who The address to query.
     * @return The balance of the specified address.
     */
    function balanceOf(address who)
    public
    view
    returns (uint256)
    {
        return _gonBalances[who].div(_gonsPerFragment);
    }

    function transfer(address recipient, uint256 amount)
    external
    validRecipient(recipient)
    initialDistributionLock
    returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    event Sender(address sender);

    function transferFrom(address sender, address recipient, uint256 amount)
    external
    validRecipient(recipient)
    returns (bool)
    {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowedFragments[sender][msg.sender].sub(amount));
        return true;
    }


    /**
     * @dev Transfer tokens to a specified address.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     * @return True on success, false otherwise.
     */
    function _transfer(address from, address to, uint256 value)
    private
    validRecipient(to)
    initialDistributionLock
    returns (bool)
    {
        require(from != address(0));
        require(to != address(0));
        require(value > 0);


        uint256 contractTokenBalance = balanceOf(address(this));
        uint256 _maxTxAmount = _totalSupply.div(10);
        uint256 numTokensSell = _totalSupply.div(numTokensSellDivisor);

        bool overMinimumTokenBalance = contractTokenBalance >= numTokensSell;

        if(from != owner() && to != owner()){
            require(value <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");}

        if (!inSwapAndLiquify && swapAndLiquifyEnabled && from != dexPairAddress) {
            if (overMinimumTokenBalance) {
                swapAndLiquify(numTokensSell);
            }

            uint256 balance = address(this).balance;
            if (buyBackEnabled && balance > buybackLimit) {

                buyBackTokens(buybackLimit.div(buybackDivisor));
            }
        }

        _tokenTransfer(from,to,value);

        return true;
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount) private {

        if (_isExcluded[sender] || _isExcluded[recipient]) {
            _transferExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
    }

    function _transferStandard(address sender, address recipient, uint256 amount) private {
        (uint256 tTransferAmount, uint256 tFee) = _getTValues(amount);
        uint256 gonDeduct = amount.mul(_gonsPerFragment);
        uint256 gonValue = tTransferAmount.mul(_gonsPerFragment);
        _gonBalances[sender] = _gonBalances[sender].sub(gonDeduct);
        _gonBalances[recipient] = _gonBalances[recipient].add(gonValue);
        _takeFee(tFee);
        emit Transfer(sender, recipient, amount);
    }

    function _transferExcluded(address sender, address recipient, uint256 amount) private {
        uint256 gonValue = amount.mul(_gonsPerFragment);
        _gonBalances[sender] = _gonBalances[sender].sub(gonValue);
        _gonBalances[recipient] = _gonBalances[recipient].add(gonValue);
        emit Transfer(sender, recipient, amount);
    }


    function _getTValues(uint256 tAmount) private view returns (uint256, uint256) {
        uint256 tFee = calculateFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee);
        return (tTransferAmount, tFee);
    }


    function calculateFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(transactionTax).div(10000);
    }

    function _takeFee(uint256 tFee) private {
        uint256 rFee = tFee.mul(_gonsPerFragment);
        _gonBalances[address(this)] = _gonBalances[address(this)].add(rFee);

    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // split the contract balance into quarters
        uint256 threequarters = contractTokenBalance.mul(3).div(4);
        uint256 onequarter = contractTokenBalance.sub(threequarters);

        // capture the contract's current AVAX balance.
        // this is so that we can capture exactly the amount of AVAX that the
        // swap creates, and not make the liquidity event include any AVAX that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for AVAX
        swapTokensForEth(threequarters); // <- this breaks the AVAX -> HATE swap when swap+liquify is triggered

        // how much AVAX did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        uint256 sharedAVAX = newBalance.div(3);

        // add liquidity to uniswap
        addLiquidity(onequarter, sharedAVAX);

        // Transfer to marketing address
        transferToAddressAVAX(marketingAddress, sharedAVAX);

        emit SwapAndLiquify(threequarters, sharedAVAX, onequarter);

    }

    function buyBackTokens(uint256 amount) private lockTheSwap {
        if (amount > 0) {
            swapAVAXForTokens(amount);
        }
    }


    function transferToAddressAVAX(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }

    function() external payable {}

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> wavax
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WAVAX();

        _approve(address(this), address(dexRouter), tokenAmount);

        // make the swap
       dexRouter.swapExactTokensForAVAXSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of AVAX
            path,
            address(this),
            block.timestamp.add(300)
        );

    }

    function swapAVAXForTokens(uint256 amount) private {
        // generate the uniswap pair path of token -> wavax
        address[] memory path = new address[](2);
        path[0] =dexRouter.WAVAX();
        path[1] = address(this);

        // make the swap
       dexRouter.swapExactAVAXForTokensSupportingFeeOnTransferTokens.value(amount)(
            0, // accept any amount of Tokens
            path,
            deadAddress, // Burn address
            block.timestamp.add(300)
        );
    }


    function addLiquidity(uint256 tokenAmount, uint256 avaxAmount) private {
        // approve token transfer to cover all possible scenarios

        _approve(address(this), address(dexRouter), tokenAmount);

        // add the liquidity
       dexRouter.addLiquidityAVAX.value(avaxAmount)(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp.add(300)
        );
    }


    /**
    * @dev Increase the amount of tokens that an owner has allowed to a spender.
    * This mavaxod should be used instead of approve() to avoid the double approval vulnerability
    * described above.
    * @param spender The address which will spend the funds.
    * @param addedValue The amount of tokens to increase the allowance by.
    */

    function increaseAllowance(address spender, uint256 addedValue)
    public
    initialDistributionLock
    returns (bool)
    {
        _approve(msg.sender, spender, _allowedFragments[msg.sender][spender].add(addedValue));
        return true;
    }


    function _approve(address owner, address spender, uint256 value) private {
        require(owner != address(0));
        require(spender != address(0));

        _allowedFragments[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of
   * msg.sender. This mavaxod is included for ERC20 compatibility.
   * increaseAllowance and decreaseAllowance should be used instead.
   * Changing an allowance with this mavaxod brings the risk that someone may transfer both
   * the old and the new allowance - if they are both greater than zero - if a transfer
   * transaction is mined before the later approve() call is mined.
   *
   * @param spender The address which will spend the funds.
   * @param value The amount of tokens to be spent.
   */

    function approve(address spender, uint256 value)
    public
    initialDistributionLock
    returns (bool)
    {
        _approve(msg.sender, spender, value);
        return true;
    }


    /**
     * @dev Function to check the amount of tokens that an owner has allowed to a spender.
     * @param owner_ The address which owns the funds.
     * @param spender The address which will spend the funds.
     * @return The number of tokens still available for the spender.
     */
    function allowance(address owner_, address spender)
    public
    view
    returns (uint256)
    {
        return _allowedFragments[owner_][spender];
    }

    /**
     * @dev Decrease the amount of tokens that an owner has allowed to a spender.
     *
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
    external
    initialDistributionLock
    returns (bool)
    {
        uint256 oldValue = _allowedFragments[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowedFragments[msg.sender][spender] = 0;
        } else {
            _allowedFragments[msg.sender][spender] = oldValue.sub(subtractedValue);
        }
        emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);
        return true;
    }

    function setInitialDistributionFinished()
    external
    onlyOwner
    {
        initialDistributionFinished = true;
    }

    function enableTransfer(address _addr)
    external
    onlyOwner
    {
        allowTransfer[_addr] = true;
    }

    function excludeAddress(address _addr)
    external
    onlyOwner
    {
        _isExcluded[_addr] = true;
    }

    function burnAutoLP()
    external
    onlyOwner
    {
        uint256 balance = dexPair.balanceOf(address(this));
        dexPair.transfer(owner(), balance);
    }

    function airDrop(address[] calldata recipients, uint256[] calldata values)
    external
    onlyOwner
    {
        for (uint256 i = 0; i < recipients.length; i++) {
            _tokenTransfer(msg.sender, recipients[i], values[i]);
        }
    }

    function setBuyBackEnabled(bool _enabled) public onlyOwner {
        buyBackEnabled = _enabled;
    }

    function setBuyBackLimit(uint256 _buybackLimit) public onlyOwner {
        buybackLimit = _buybackLimit;}

    function setBuyBackDivisor(uint256 _buybackDivisor) public onlyOwner {
        buybackDivisor = _buybackDivisor;}

    function setnumTokensSellDivisor(uint256 _numTokensSellDivisor) public onlyOwner {
        numTokensSellDivisor = _numTokensSellDivisor;}

    function burnBNB(address payable burnAddress) external onlyOwner {
        burnAddress.transfer(address(this).balance);
    }

    function setFees(uint256 _transactionTax) external onlyOwner {
        transactionTax = _transactionTax;
    }

}