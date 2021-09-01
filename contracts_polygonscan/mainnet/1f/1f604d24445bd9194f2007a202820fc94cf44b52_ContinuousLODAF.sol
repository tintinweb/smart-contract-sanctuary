/**
 *Submitted for verification at polygonscan.com on 2021-09-01
*/

pragma solidity ^0.6.7;

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

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev give an account access to this role
     */
    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));

        role.bearer[account] = true;
    }

    /**
     * @dev remove an account's access to this role
     */
    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        role.bearer[account] = false;
    }

    /**
     * @dev check if an account has this role
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}

contract MinterRole {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(msg.sender);
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender));
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(msg.sender);
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
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
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

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
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

/*
 * Ownable
 *
 * Base contract with an owner.
 * Provides onlyOwner modifier, which prevents function from running if it is called by anyone other than the owner.
 */
contract Ownable {
  address public owner;

  constructor () public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    if (msg.sender == owner)
      _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    if (newOwner != address(0)) owner = newOwner;
  }

}

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://eips.ethereum.org/EIPS/eip-20
 * Originally based on code by FirstBlood:
 * https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 *
 * This implementation emits additional Approval events, allowing applications to reconstruct the allowance status for
 * all accounts just by listening to said events. Note that this isn't required by the specification, and other
 * compliant implementations may not do it.
 */
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;

    /**
     * @dev Total number of tokens in existence
     */
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param owner The address to query the balance of.
     * @return An uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address owner) public override view returns (uint256) {
        return _balances[owner];
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowed[owner][spender];
    }

    /**
     * @dev Transfer token to a specified address
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function transfer(address to, uint256 value) public override returns (bool) {
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
    function approve(address spender, uint256 value) public override returns (bool) {
        _approve(msg.sender, spender, value);
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
    function transferFrom(address from, address to, uint256 value) public override returns (bool) {
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when _allowed[msg.sender][spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when _allowed[msg.sender][spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    /**
     * @dev Transfer token for a specified addresses
     * @param from The address to transfer from.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

    /**
     * @dev Internal function that mints an amount of the token and assigns it to
     * an account. This encapsulates the modification of balances such that the
     * proper events are emitted.
     * @param account The account that will receive the created tokens.
     * @param value The amount that will be created.
     */
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account.
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    /**
     * @dev Approve an address to spend another addresses' tokens.
     * @param owner The address that owns the tokens.
     * @param spender The address that will spend the tokens.
     * @param value The number of tokens that can be spent.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        require(spender != address(0));
        require(owner != address(0));

        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account, deducting from the sender's allowance for said account. Uses the
     * internal burn function.
     * Emits an Approval event (reflecting the reduced allowance).
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burnFrom(address account, uint256 value) internal {
        _burn(account, value);
        _approve(account, msg.sender, _allowed[account][msg.sender].sub(value));
    }
}

/**
 * @title ERC20Mintable
 * @dev ERC20 minting logic
 */
contract ERC20Mintable is ERC20, MinterRole {
    /**
     * @dev Function to mint tokens
     * @param to The address that will receive the minted tokens.
     * @param value The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address to, uint256 value) public onlyMinter returns (bool) {
        _mint(to, value);
        return true;
    }
}

contract ERC20Burnable is ERC20, MinterRole {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public onlyMinter returns (bool) {
        _burn(msg.sender, amount);
        return true;
    }
    
    function burnFrom(address account, uint256 amount)  public onlyMinter returns (bool) {
        uint256 currentAllowance = allowance(account, msg.sender);
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        _burn(account, amount);
        return true;
    }
}

/**
 * @title ERC20Detailed token
 * @dev The decimals are only for visualization purposes.
 * All the operations are done using the smallest and indivisible token unit,
 * just as on Ethereum all the operations are done in wei.
 */
abstract contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @return the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @return the symbol of the token.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @return the number of decimals of the token.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

contract NapDAFToken is ERC20Mintable, ERC20Burnable, ERC20Detailed {
    uint8 public constant DECIMALS = 6;
    uint256 public constant INITIAL_SUPPLY = 0;
    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */
    constructor () public ERC20Detailed("NapDAF", "DAF", DECIMALS) {
        _mint(msg.sender, INITIAL_SUPPLY);
    }
}

contract ContinuousLODAF is Ownable { 
    using SafeMath for uint256;
    // 18 decimals for wrapped ether
    address private _maticWEther = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;
    // 8 decimals for WBTC 
    address private _maticWBTC = 0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6;
    // 6 decimals for tether
    address private _maticTether = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
     /** Network: Matic Aggregator: ETH/USD */
    address private _maticEtherPriceFeed = 0xF9680D99D6C9589e2a93a78A04A279e509205945;
    AggregatorV3Interface internal _priceFeed;
    // Matic civic mainnet  quickswap v2 router
    address private constant QUICKSWAP_V2_ROUTER = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
    
    string private daf_ = "educk";
    
    uint _dafAssetAmount; 
    uint private _previousSig;
    
    uint _lastTimestamp;
    uint _mngtFeesDailyRateDenominator;
    uint _mngtFeesDailyRateNumerator;
    
    address _napDafAddress;
    NapDAFToken private _napDaf;
	mapping(address=>uint256) public contributions;
    uint256 private _usdtValo;
    
	event SubscriptionReceived(address contributor, uint256 value, uint256 timestamp);
	event PartAllocated(address contributor, uint256 value, uint256 timestamp);
	event PartUnAllocated(address contributor, uint256 value, uint256 timestamp);
	event RedemptionAccepted(address contributor, uint256 value, uint256 timestamp);
	event ContractBalance(uint256 amoutIn, uint256 tetherBalance, uint etherBalance);
	event PoolShare(uint ethPrice, uint etherBalance, uint assetValo, uint tetherBalance, uint poolshare);
	event EtherSwap(uint percentageDeltaEtherToSwap, uint deltaEtherToSwapInTether, uint deltaEtherToSwapInEther);
	event TetherSwap(uint percentageDeltaTetherToSwap, uint deltaTetherToSwapInTether);
	
	event EtherPrice(uint price);
	event DafMinted(address user, uint256 mintedAmount);
	event DafBurned(address user, uint256 buneddAmount);
	event SwapMade(address tokenIn, address tokenOut, uint256 tokenAmount, address swaper);
	
	constructor (address tokenAddress) public {
	    _napDafAddress=tokenAddress;
	    _napDaf = NapDAFToken(tokenAddress);
	    _priceFeed = AggregatorV3Interface(_maticEtherPriceFeed);
	    _previousSig = 0;
	    _dafAssetAmount = 0;
	    _lastTimestamp = block.timestamp;
	    _mngtFeesDailyRateDenominator = 1000;
	    _mngtFeesDailyRateNumerator = 5;
	}
    
    function setMngtFeesDailyRateDenominator(uint mngtFeesDailyRateDenominator) public onlyOwner {
        _mngtFeesDailyRateDenominator = mngtFeesDailyRateDenominator;
    }
    
    function setMngtFeesDailyRateNumerator(uint mngtFeesDailyRateNumerator) public onlyOwner {
        _mngtFeesDailyRateNumerator = mngtFeesDailyRateNumerator;
    }
    
    function getDafToken() external view returns(address) {
        return _napDafAddress;
    }

    /*
    function assessManagementFees() external view returns(uint) {
        uint oneDay = 1 days;
        uint _now = block.timestamp;
        uint nbDays = (_lastTimestamp - _now)/oneDay;
        
        if (_cashMode){
            uint256 tetherBalance = this.getUsdtBalance();
            uint256 tetherFeesToReap = (nbDays*tetherBalance*_mngtFeesDailyRateNumerator)/_mngtFeesDailyRateDenominator;
            return tetherFeesToReap;
        } else {
            uint256 etherBalance = this.getEtherBalance();
            uint256 etherFeesToReap = (nbDays*etherBalance*_mngtFeesDailyRateNumerator)/_mngtFeesDailyRateDenominator; 
            return etherFeesToReap;
        }
        return nbDays;
    } */
    /*
    function withdrawManagementFees() public onlyOwner {
        uint oneDay = 1 days;
        uint _now = block.timestamp;
        uint nbDays = (_lastTimestamp - _now)/oneDay;
        if (_cashMode){
            uint256 tetherBalance = this.getUsdtBalance();
            uint256 tetherFeesToReap = (nbDays*tetherBalance*_mngtFeesDailyRateNumerator)/_mngtFeesDailyRateDenominator;
            bool transferTetherMngtFeesSuccess = IERC20(_maticTether).transfer(msg.sender, tetherFeesToReap);
    	    require(transferTetherMngtFeesSuccess,"Failed to transfer management fees");
        } else {
            uint256 etherBalance = this.getEtherBalance();
            uint256 etherFeesToReap = (nbDays*etherBalance*_mngtFeesDailyRateNumerator)/_mngtFeesDailyRateDenominator; 
            this.swap(_maticWEther,_maticTether,etherFeesToReap,0,address(this));
	        emit SwapMade(_maticWEther,_maticTether,etherFeesToReap,address(this));
	        // the tether balance from the contract is now the result of the swap
	        uint256 tetherBalance = this.getUsdtBalance();
            bool transferTetherMngtFeesSuccess = IERC20(_maticTether).transfer(msg.sender, tetherBalance);
    	    require(transferTetherMngtFeesSuccess,"Failed to transfer management fees");
        }
        _lastTimestamp = block.timestamp;
    }
    */
    
    
    // the sender must have already approved an _amountIn allowance of tether for the smart contract
    // the smart contract will preempt them and make the move
	
	function usdtSubscription(uint256 _amountIn)  public {
	    uint256 oldTetherBalance = this.getUsdtBalance();
	    uint256 oldEtherBalance = this.getEtherBalance();
	    emit ContractBalance(_amountIn,oldTetherBalance,oldEtherBalance);
	    // important step for the user : he must allow the DAF contract to move Tether on his account (at least the subscription amount)
    	uint dafAllowanceContractOnBehalfUser =  IERC20(_maticTether).allowance(msg.sender,address(this));
    	require(dafAllowanceContractOnBehalfUser >= _amountIn, "contract not allowed to move tether for user s behalf");
    		
	    bool transferSuccess = IERC20(_maticTether).transferFrom(msg.sender, address(this), _amountIn);
	    require(transferSuccess,"Failed to transfer usdt to daf contract");
	    
	    uint256 nbTotalParts =_napDaf.totalSupply();
	    uint256 toAllocate;
	  
	    require(_amountIn>0,"usdt must be sent");
	    
	    if (nbTotalParts == 0){
	        require(oldTetherBalance == 0 && oldEtherBalance==0,"you cannot have money and no daf token allowed");
	        toAllocate = _amountIn;
	    } 

	    uint ethPrice = uint(getEtherLatestPrice());
        emit EtherPrice(ethPrice);
        
	    if (nbTotalParts > 0 && (oldTetherBalance > 0 || oldEtherBalance > 0)){
            uint assetValo = oldEtherBalance*ethPrice;
            uint poolPercentShare = assetValo*100 / (assetValo + oldTetherBalance);
            emit PoolShare(ethPrice, oldEtherBalance, assetValo, oldTetherBalance, poolPercentShare);
            toAllocate = _amountIn;
	    }
	    /*
	    bool _cashMode = true;
	    if (_cashMode){
	        // no part in the fund. matches with oldTetherBalance == 0
	        if (nbTotalParts == 0 || oldTetherBalance == 0){
    	        toAllocate = _amountIn;
	        } else {
	            toAllocate = (_amountIn*nbTotalParts)/oldTetherBalance ;
	        }
	    } else {
	        // no part in the fund. matches with oldEtherBalance == 0
	        if (nbTotalParts == 0 || oldEtherBalance == 0){
    	        toAllocate = _amountIn;
	        } else {
    	        // we immediately swap the sent USDT to Ether
    	        this.swap(_maticTether,_maticWEther,_amountIn,0,address(this));
    	        emit SwapMade(_maticTether,_maticWEther,_amountIn,address(this));
    	        uint256 newEtherBalance = this.getEtherBalance();
    	        uint256 _ethAmountIn = newEtherBalance - oldEtherBalance;
    	        require(_ethAmountIn > 0, "New ether balance not higher : investigate");
    	        toAllocate = (_ethAmountIn*nbTotalParts)/oldEtherBalance;
	        } 
	    }
	    */
	    require(toAllocate > 0, "You need to subscribe more than zero part");
        _napDaf.mint(msg.sender, toAllocate);
        emit DafMinted(msg.sender, toAllocate);
    	contributions[msg.sender] += _amountIn;
		SubscriptionReceived(msg.sender, _amountIn, now);
		PartAllocated(msg.sender,toAllocate,now);
	}
	
	
	function approveQuickswapForInfiniteTetherSwap(uint _amountIn) public onlyOwner {
    	IERC20(_maticTether).approve(QUICKSWAP_V2_ROUTER, _amountIn);   
	}
	
	function approveQuickswapForInfiniteEtherSwap(uint _amountIn) public onlyOwner {
    	IERC20(_maticWEther).approve(QUICKSWAP_V2_ROUTER, _amountIn);   
	}
	// uint is an integer between 0 and 100 highlighting the quantity of the pool in the asset
	function swapAsset(uint _signal) public onlyOwner {
	    uint256 oldTetherBalance = this.getUsdtBalance();
	    uint256 oldEtherBalance = this.getEtherBalance();
	    
	    emit ContractBalance(0,oldTetherBalance,oldEtherBalance);
	    
	    bool swapValid = (_signal != _previousSig);
	    
	    require(swapValid,"Nothing to swap here");
        
	    uint ethPrice = uint(getEtherLatestPrice());
        emit EtherPrice(ethPrice);

        bool isStoredValue = oldTetherBalance > 0 || oldEtherBalance > 0;
        require(isStoredValue, "no value in the DAF");

        uint assetValo = oldEtherBalance*ethPrice;
        uint poolAssetPercentShare = assetValo*100 / (assetValo + oldTetherBalance);
        emit PoolShare(ethPrice, oldEtherBalance, assetValo, oldTetherBalance, poolAssetPercentShare);
	
        // first step before = 0 : we swap _signal amount of the tether 
        
        if (poolAssetPercentShare > _signal){
            // the pool has too much asset compared to signal
            uint percentageDeltaToSwap = poolAssetPercentShare - _signal;
            uint deltaToSwapInTether = (percentageDeltaToSwap * (assetValo + oldTetherBalance)) / 100;
            uint deltaToSwapInEther = deltaToSwapInTether/ethPrice;
            // we swap ether to tether
            emit EtherSwap(percentageDeltaToSwap, deltaToSwapInTether, deltaToSwapInEther);
            this.swap(_maticWEther,_maticTether,deltaToSwapInEther,0,address(this));
        } else {
            // we swap ether to tether
            uint percentageDeltaToSwap = _signal - poolAssetPercentShare ;
            uint deltaToSwapInTether = (percentageDeltaToSwap * (assetValo + oldTetherBalance)) / 100;
            emit TetherSwap(percentageDeltaToSwap,deltaToSwapInTether);
            this.swap(_maticTether, _maticWEther,deltaToSwapInTether,0,address(this));
        }
	    
     /*   
	    if (swapValid){
	        if (_signal == 0){
	            // we go from 1 to 0 : we swap ether to tether
	            uint256 wholeEtherBalance = this.getEtherBalance();
	            this.swap(_maticWEther,_maticTether,wholeEtherBalance,0,address(this));
	            _cashMode = true;
	        } else {
	            // we go from 0 to 1 : we swap tether to ether
	            uint256 wholeTetherBalance = this.getUsdtBalance();
	            this.swap(_maticTether,_maticWEther,wholeTetherBalance,0,address(this));
	            _cashMode = false;
	        }
	    }
	    _previousSig = _signal;
	    
	    uint256 newTetherBalance = this.getUsdtBalance();
	    uint256 newEtherBalance = this.getEtherBalance();
	    emit ContractBalance(0,newTetherBalance,newEtherBalance);
	    */
	}
	
	function discreteSwapAsset(uint _signal) public onlyOwner {
	    uint256 tetherBalance = this.getUsdtBalance();
	    uint256 etherBalance = this.getEtherBalance();
	    
	    emit ContractBalance(0,tetherBalance,etherBalance);
	    bool swapValid = (_signal != _previousSig);
	    require(swapValid,"Nothing to swap here");

	    if (swapValid){
	        if (_signal == 0){
	            // we go from 1 to 0 : we swap ether to tether
	            uint256 wholeEtherBalance = this.getEtherBalance();
	            this.swap(_maticWEther,_maticTether,wholeEtherBalance,0,address(this));
	        } else {
	            // we go from 0 to 1 : we swap tether to ether
	            uint256 wholeTetherBalance = this.getUsdtBalance();
	            this.swap(_maticTether,_maticWEther,wholeTetherBalance,0,address(this));
	        }
	    }
	    _previousSig = _signal;
	    
	    uint256 newTetherBalance = this.getUsdtBalance();
	    uint256 newEtherBalance = this.getEtherBalance();
	    emit ContractBalance(0,newTetherBalance,newEtherBalance);
	}
	
	function getAssetAmount() external view returns (uint) {
	    return _dafAssetAmount;
	}
 
	function getPreviousSig() external view returns (uint256) {
	    return _previousSig;
	}

    function withdrawDAFAssets() public onlyOwner {
        uint256 tetherBalance = this.getUsdtBalance();
	    uint256 etherBalance = this.getEtherBalance();
	    if (tetherBalance > 0){
	        bool transferSuccess = IERC20(_maticTether).transfer(msg.sender, tetherBalance);
    		require(transferSuccess,"tether withdrawal transfer failed");
	    }
	    if (etherBalance > 0){
	        bool transferSuccess = IERC20(_maticWEther).transfer(msg.sender, etherBalance);
    		require(transferSuccess,"ether withdrawal transfer failed");
	    }
    }

    function getDafTokenOwnedAmount() external view returns (uint256) {
	    uint256 dafBalance = _napDaf.balanceOf(address(this));
	    return dafBalance;
	}

    function getDafTotalTokenSupply() external view returns (uint256) {
	    uint256 dafTotalSupply = _napDaf.totalSupply();
	    return dafTotalSupply;
	}
	/*
	function dafTokenRedemption(uint _amountIn)  public {
	    uint256 tetherBalance = this.getUsdtBalance();
	    uint256 etherBalance = this.getEtherBalance();
	    emit ContractBalance(_amountIn,tetherBalance,etherBalance);

	    uint256 nbParts =_napDaf.balanceOf(msg.sender);
	    uint256 nbTotalParts =_napDaf.totalSupply();
	    
	    require(nbParts >= _amountIn, "redemption size must be smaller than what you have");
//        bool trsSuc = _napDaf.transferFrom(msg.sender,address(this),_amountIn);
//		require(trsSuc,"daf transfer failed");:
//	    bool burned = _napDaf.burn(_amountIn);
        bool trsSuc = _napDaf.burnFrom(msg.sender,_amountIn);
	    require(trsSuc,"Fail to burn the DAF token");

	    emit DafBurned(msg.sender,_amountIn);
	    
	    if (_cashMode){
	        uint256 tetherToReimburse = (_amountIn*tetherBalance)/nbTotalParts ;
	        require(tetherToReimburse > 0, "nothing to reimburse");
	        require(tetherToReimburse <= tetherBalance, "nothing to reimburse");
    		bool transferSuccess = IERC20(_maticTether).transfer(msg.sender, tetherToReimburse);
    		require(transferSuccess,"tether transfer failed");
    		
    		uint dafAllowanceContractOnBehalfUser = _napDaf.allowance(msg.sender,address(this));
    		require(dafAllowanceContractOnBehalfUser >= _amountIn, "contract not allowed to move daf tokens");

    		RedemptionAccepted(msg.sender, _amountIn, now);
    		PartUnAllocated(msg.sender, _amountIn, now);
	    } else {
	        uint256 etherToReimburse = (_amountIn*etherBalance)/nbTotalParts ;
	        this.swap(_maticWEther,_maticTether,etherToReimburse,0,address(this));
	        emit SwapMade(_maticWEther,_maticTether,etherToReimburse,address(this));
	        // the whole tether balance from the contract comes from the swap
	        uint256 tetherToReimburse = this.getUsdtBalance();
    		bool transferSuccess = IERC20(_maticTether).transfer(msg.sender, tetherToReimburse);
    		require(transferSuccess, "tether transfer failed");
    		RedemptionAccepted(msg.sender, _amountIn, now);
    		PartUnAllocated(msg.sender, _amountIn, now);
	    }
	}
	*/
	
	function getUsdtBalance() external view returns (uint256) {
	    uint256 usdtBalance = IERC20(_maticTether).balanceOf(address(this));
	    return usdtBalance;
	}
	
	function getBTCBalance()  external view returns (uint256) {
	    uint256 btcBalance = IERC20(_maticWBTC).balanceOf(address(this));
	    return btcBalance;
	}
	
	function getEtherBalance() external view returns (uint256) {
	    uint256 etherBalance = IERC20(_maticWEther).balanceOf(address(this));
	    return etherBalance;
	}
	
    function getEtherLatestPrice() public view returns (int) {
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = _priceFeed.latestRoundData();
        return price;
    }
    
    function swap(address _tokenIn, address _tokenOut, uint256 _amountIn, uint256 _amountOutMin, address _to) external {
    //next we need to allow the uniswapv2 router to spend the token we just sent to this contract
    //by calling IERC20 approve you allow the uniswap contract to spend the tokens in this contract 

    // no need to do that if it has been done once for all 
    // IERC20(_tokenIn).approve(QUICKSWAP_V2_ROUTER, _amountIn);

    //path is an array of addresses.
    //this path array will have 3 addresses [tokenIn, WETH, tokenOut]
    //the if statement below takes into account if token in or token out is WETH.  then the path is only 2 addresses
    address[] memory path;
    path = new address[](2);
    path[0] = _tokenIn;
    path[1] = _tokenOut;
    
    //then we will call swapExactTokensForTokens
    //for the deadline we will pass in block.timestamp
    //the deadline is the latest time the trade is valid for
    IUniswapV2Router02(QUICKSWAP_V2_ROUTER).swapExactTokensForTokens(_amountIn, _amountOutMin, path, _to, block.timestamp);
    }
    
       //this function will return the minimum amount from a swap
       //input the 3 parameters below and it will return the minimum amount out
       //this is needed for the swap function above
    function getAmountOutMin(address _tokenIn, address _tokenOut, uint256 _amountIn) external view returns (uint256) {
       //path is an array of addresses.
       //this path array will have 3 addresses [tokenIn, WETH, tokenOut]
       //the if statement below takes into account if token in or token out is WETH.  then the path is only 2 addresses
        address[] memory path;
        path = new address[](2);
        path[0] = _tokenOut;
        path[1] = _tokenIn;
        uint256[] memory amountOutMins = IUniswapV2Router02(QUICKSWAP_V2_ROUTER).getAmountsIn(_amountIn, path);
        return amountOutMins[0];
    }
    
    function getEstimatedETHforTether(uint tetherAmount) public view returns (uint[] memory) {
        return  IUniswapV2Router02(QUICKSWAP_V2_ROUTER).getAmountsIn(tetherAmount, getPathForETHtoTether());
    }

    function getEstimatedTetherforETH(uint ethAmount) public view returns (uint[] memory) {
        return  IUniswapV2Router02(QUICKSWAP_V2_ROUTER).getAmountsIn(ethAmount, getPathForTethertoETH());
    }

    function getPathForETHtoTether() private view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = _maticWEther;
        path[1] = _maticTether;
        return path;
    }

    function getPathForTethertoETH() private view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = _maticTether;
        path[1] = _maticWEther;
        return path;
    }
}