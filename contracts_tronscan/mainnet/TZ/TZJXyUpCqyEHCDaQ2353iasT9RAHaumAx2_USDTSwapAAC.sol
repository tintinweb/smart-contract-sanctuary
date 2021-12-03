//SourceUnit: AACToUSDT.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);
    function mint(address account, uint amount) external;

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IAACBToken{
    function mint(uint AACB_amount, address ownerAddress) external;
    function burn(address from, uint value) external;
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
        require(c / a == b, "SafeMath#mul: OVERFLOW");

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath#div: DIVISION_BY_ZERO");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath#sub: UNDERFLOW");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath#add: OVERFLOW");

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath#mod: DIVISION_BY_ZERO");
        return a % b;
    }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


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
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

  function GetOwner() public view returns (address){
      return owner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
  
    /**
     * @dev Event to notify if transfer successful or failed * after account approval verified */
    event TransferSuccessful(
        address indexed from_,
        address indexed to_,
        uint256 amount_
    );

    event TransferFailed(
        address indexed from_,
        address indexed to_,
        uint256 amount_
    );
    
    /**
     * @dev a list of all transfers successful or unsuccessful */
    //Transfer public transaction;
}

//AAC => AACB
contract USDTSwapAAC is Ownable{

    using SafeMath for uint256;
    address public AACBToken;
    address public USDTToken;
    uint public SwapTokenAmountIn;
    address Keeper;
    IERC20 public ERC20Interface;
    IERC20 public ERC20AACInterface;
    uint public decimals;
    uint public tradeTokenDecimals;
    uint public TotalSwapAmount = 100000000000;
    uint public CurrentSwapAmount;
    address public PlatformAccount;

    constructor(address AAC_token_address, address USDT_token_address, address _platform) public{
        owner = msg.sender;
        AACBToken = AAC_token_address;
        ERC20AACInterface = IERC20(AACBToken);
        USDTToken = USDT_token_address;
        ERC20Interface = IERC20(USDTToken);
        SwapTokenAmountIn = 200000000000000000;
        tradeTokenDecimals = 6;
        decimals = 6;
        PlatformAccount = _platform;
    }
    
    function Swap(
        uint tradeTokenAmount
    )  public returns (bool success){
        //require(tradeTokenAmount >= SwapTokenAmountIn, "Trade token amount must be larger than swap in amount");

        address from_ = msg.sender;

        //Calculation with ratio 100,000 ** 18, swap in USDT for ACC
        uint token_received_amount = tradeTokenAmount * SwapTokenAmountIn / (10 ** uint256(tradeTokenDecimals));
        
        //Validate transfer amount
        if (tradeTokenAmount > ERC20Interface.allowance(from_, address(this))) {
            emit TransferFailed(from_, Keeper, tradeTokenAmount);
            revert();
        }
        ERC20Interface.transferFrom(from_, PlatformAccount, tradeTokenAmount);
        emit TransferSuccessful(from_, PlatformAccount, tradeTokenAmount);
        
        //Mint AACBToken and transfer
        // require(CurrentSwapAmount + token_received_amount <= TotalSwapAmount, "Mint Amount Exceeded Total Swap Amount");
        // CurrentSwapAmount = CurrentSwapAmount.add(token_received_amount);
        ERC20AACInterface.transfer(from_, token_received_amount);
        return true;
    }
    
    
    function SetSwapToken(address address_)
        public
        onlyOwner
        returns (bool)
    {
        require(address_ != address(0));
        USDTToken = address_;
        ERC20Interface = IERC20(USDTToken);
        return true;
    }
    
    function SetSwapTokenIn(uint token_swap_amount_in)
        public
        onlyOwner
        returns (bool)
    {
        require(token_swap_amount_in > 0);
        SwapTokenAmountIn = token_swap_amount_in;
        return true;
    }
    
    function SetDecimal(uint _decimals)
        public
        onlyOwner
        returns (bool)
    {
        require(_decimals > 0);
        decimals = _decimals;
        return true;
    }
    
    function SetSwapDecimal(uint _decimals)
        public
        onlyOwner
        returns (bool)
    {
        require(_decimals > 0);
        tradeTokenDecimals = _decimals;
        return true;
    }
    
    function SetAACBToken(address _AACBTokenAddress)
        public
        onlyOwner
        returns (bool)
    {
        require(_AACBTokenAddress != address(0));
        AACBToken = _AACBTokenAddress;
        return true;
    }
    
    function GetCurrentSwapAmount() public view returns(uint){
        return CurrentSwapAmount;
    }
    
    function Emergency(address _address) external onlyOwner{
        IERC20(_address).transfer(msg.sender, IERC20(_address).balanceOf(address(this)));
    }
    
}