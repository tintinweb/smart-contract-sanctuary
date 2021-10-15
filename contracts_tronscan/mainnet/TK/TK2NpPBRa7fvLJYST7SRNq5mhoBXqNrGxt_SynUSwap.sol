//SourceUnit: SynUSwap.sol

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

interface ISynUToken{
    function mintToken(uint synu_amount, address ownerAddress) external;
    function burnFrom(address from, uint value) external;
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
  
//   struct Transfer {
//         address contract_;
//         address to_;
//         uint256 amount_;
//         bool failed_;
//     }
    
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

contract SynUSwap is Ownable{

    using SafeMath for uint256;
    address public SynUToken;
    address public Fees;
    uint public SwapTokenAmountOut;
    address public SwapToken;
    uint public SwapTokenAmountIn;
    mapping(uint => address) Investors;
    uint public InvestorsCounter = 0;
    address Keeper;
    IERC20 public ERC20Interface;
    IERC20 public ERC20SynUInterface;
    ISynUToken public SynUTokenInterface;
    uint public decimals;
    uint public tradeTokenDecimals;

    constructor(address synu_token_address, address swap_token_address, uint token_swap_amount_in, uint trade_token_decimal ,address fees, uint token_swap_amount_out) public{
        owner = msg.sender;
        SynUToken = synu_token_address;
        SynUTokenInterface = ISynUToken(SynUToken);
        ERC20SynUInterface = IERC20(SynUToken);
        ERC20Interface = IERC20(swap_token_address);
        SwapToken = swap_token_address;
        SwapTokenAmountIn = token_swap_amount_in;
        tradeTokenDecimals = trade_token_decimal;
        Fees = fees;
        SwapTokenAmountOut = token_swap_amount_out;
        decimals = 6;
    }
    
    function Buy(
        uint tradeTokenAmount,
        bool useReceiverAddress,
        address receiverAddress
    )  public returns (bool success){
        require(InvestorsCounter > 0, "No investors in the contract");
        require(tradeTokenAmount >= SwapTokenAmountIn, "Trade token amount must be larger than swap in amount");

        address from_ = msg.sender;

        //Calculation with ratio
        uint token_received_amount = tradeTokenAmount * SwapTokenAmountIn / (10 ** uint256(tradeTokenDecimals + 1));
        token_received_amount = ((token_received_amount) + 5) / 10;
        token_received_amount = token_received_amount * 100;
        
        //Validate transfer amount
        if (tradeTokenAmount > ERC20Interface.allowance(from_, address(this))) {
            emit TransferFailed(from_, Keeper, tradeTokenAmount);
            revert();
        }
        ERC20Interface.transferFrom(from_, address(this), tradeTokenAmount);
        emit TransferSuccessful(from_, address(this), tradeTokenAmount);
        
        //Transfer to multiple Investor
        uint investor_receive_amount = tradeTokenAmount / InvestorsCounter;
        for(uint i = 1; i <= InvestorsCounter; i++){
            ERC20Interface.transfer(Investors[i], investor_receive_amount);
        }
        
        //Mint SynUToken and transfer
        if(useReceiverAddress){
            SynUTokenInterface.mintToken(token_received_amount, receiverAddress);
        }
        else{
            SynUTokenInterface.mintToken(token_received_amount, from_);
        }
        return true;
    }
    
    //Change to swap out
    function Sell(uint synu_amount) public{
        
        address from_ = msg.sender;
        
        require(ERC20SynUInterface.balanceOf(from_) >= synu_amount, "Insufficient SynUToken to trade.");
        //Calculation with ratio
        uint token_trade_amount = synu_amount * SwapTokenAmountOut / (10 ** uint256(tradeTokenDecimals + 1));
        token_trade_amount = ((token_trade_amount) + 5) / 10;
        token_trade_amount = token_trade_amount * 100;
        
        require(token_trade_amount > 0, "Trade amount too small");
        
        //Validate transfer amount
        if (token_trade_amount > ERC20Interface.allowance(Fees, address(this))) {
            emit TransferFailed(from_, Keeper, token_trade_amount);
            revert();
        }
        
        ERC20Interface.transferFrom(Fees, address(this), token_trade_amount);
        emit TransferSuccessful(Fees, address(this), token_trade_amount);
        
        //Transfer to multiple Investor
        ERC20Interface.transfer(from_, token_trade_amount);
        
        SynUTokenInterface.burnFrom(from_, synu_amount);
    }
    
    function AddInvestor(address address_)
        public
        onlyOwner
        returns (bool)
    {
        require(address_ != address(0));
        InvestorsCounter = InvestorsCounter + 1;
        Investors[InvestorsCounter] = address_;
        return true;
    }
    
    function RemoveInvestor(address address_)
        public
        onlyOwner
        returns (bool)
    {
        require(address_ != address(0));
        for(uint i = 0; i < InvestorsCounter; i++){
            if(Investors[i] == address_){
                Investors[i] = Investors[InvestorsCounter];
                Investors[InvestorsCounter] = address(0);
                InvestorsCounter = InvestorsCounter - 1;
                return true;
            }
        }
        return true;
    }
    
    function GetInvestor(uint InvestorNo) public view returns(address){
        return Investors[InvestorNo];
    }
    
    function SetSwapToken(address address_)
        public
        onlyOwner
        returns (bool)
    {
        require(address_ != address(0));
        SwapToken = address_;
        ERC20Interface = IERC20(SwapToken);
        return true;
    }
    
    function SetFeesAddress(address address_)
        public
        onlyOwner
        returns (bool)
    {
        require(address_ != address(0));
        Fees = address_;
        return true;
    }
    
    function SetSwapTokenIn(uint token_swap_amount_in)
        public
        onlyOwner
        returns (bool)
    {
        require(token_swap_amount_in > 0);
        SwapTokenAmountIn = token_swap_amount_in;
        ERC20Interface = IERC20(SwapToken);
        return true;
    }
    
    function SetSwapTokenOut(uint token_swap_amount_out)
        public
        onlyOwner
        returns (bool)
    {
        require(token_swap_amount_out > 0);
        SwapTokenAmountOut = token_swap_amount_out;
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
    
     function SetSynUToken(address _synUTokenAddress)
        public
        onlyOwner
        returns (bool)
    {
        require(_synUTokenAddress != address(0));
        SynUToken = _synUTokenAddress;
        return true;
    }
    
}