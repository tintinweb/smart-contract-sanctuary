//SourceUnit: USDT.sol

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


interface IACBToken{
    function mint(uint acb_amount, address ownerAddress) external;
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

interface ICoinBossReward{
    function acbRate() external view returns (uint); 
    function usdtRate() external view returns (uint);
}

//USDT => ACB
contract ACBSwapUSDT is Ownable{

    using SafeMath for uint256;
    address public ACBToken;
    address public USDTToken;
    address public CoinBossRewardAddress;
    address Keeper;
    IERC20 public ERC20Interface;
    IERC20 public ERC20ACInterface;
    uint public USDTRate;
    address public Fee;

    constructor(address acb_token_address, address usdt_token_address, address coin_boss_reward_address, address _fee) public{
        owner = msg.sender;
        ACBToken = acb_token_address;
        ERC20ACInterface = IERC20(ACBToken);
        USDTToken = usdt_token_address;
        ERC20Interface = IERC20(USDTToken);
        CoinBossRewardAddress = coin_boss_reward_address;
        Fee = _fee;
    }
    
    function SwapACBToUSDT(
        uint tradeTokenAmount
    )  public returns (bool success){

        address from_ = msg.sender;

        //Calculation with ratio 100,000 ** 18 = 100,000 ** 6
        uint USDTAmount = GetSwapUSDTAmount(tradeTokenAmount);
        
        ERC20ACInterface.transferFrom(from_, Fee ,tradeTokenAmount);
        emit TransferSuccessful(from_, Fee, tradeTokenAmount);
        
        ERC20Interface.transferFrom(Fee, from_ ,USDTAmount);
        
        return true;
    }
    
    function SwapUSDTToACB(
        uint tradeTokenAmount
    )  public returns (bool success){

        address from_ = msg.sender;

        //Calculation with ratio 100,000 ** 18 = 100,000 ** 6
        uint token_received_amount = GetSwapACBAmount(tradeTokenAmount);
        
        // Validate transfer amount
        // if (tradeTokenAmount > ERC20Interface.allowance(from_, Fee)) {
        //     emit TransferFailed(from_, Keeper, tradeTokenAmount);
        //     revert();
        // }
        ERC20Interface.transferFrom(from_, Fee, tradeTokenAmount);
        emit TransferSuccessful(from_, Fee, tradeTokenAmount);
        
        //Mint ACBToken and transfer
        ERC20ACInterface.transferFrom(Fee, from_ ,token_received_amount);
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
    
    function GetSwapUSDTAmount(uint ACBAmount)
        public
        view
        returns (uint)
    {
        //Calculation with ratio 100,000 ** 18 = 100,000 ** 6
        uint acbToUsdt = ICoinBossReward(CoinBossRewardAddress).usdtRate() * 10 ** 6 / ICoinBossReward(CoinBossRewardAddress).acbRate() ;
        uint usdt_amount = ACBAmount * acbToUsdt / 10 ** 6;
        return usdt_amount;
    }
    
    function GetSwapACBAmount(uint USDTAmount)
        public
        view
        returns (uint)
    {
        //Calculation with ratio 100,000 ** 18 = 100,000 ** 6
        uint USDTToACB = ICoinBossReward(CoinBossRewardAddress).acbRate() * 10 ** 7 / ICoinBossReward(CoinBossRewardAddress).usdtRate() ;
        USDTToACB = (USDTToACB + 5) / 10;
        uint usdt_amount = USDTAmount * USDTToACB / 10 ** 6;
        return usdt_amount;
    }
    
    
    function SetACBToken(address _acbTokenAddress)
        public
        onlyOwner
        returns (bool)
    {
        require(_acbTokenAddress != address(0));
        ACBToken = _acbTokenAddress;
        return true;
    }
    
    function SetFee(address _fee)
        public
        onlyOwner
        returns (bool)
    {
        require(_fee != address(0));
        Fee = _fee;
        return true;
    }
    
    function SetCoinBossRewardAddress(address _coinbossrewardaddress)
        public
        onlyOwner
        returns (bool)
    {
        require(_coinbossrewardaddress != address(0));
        CoinBossRewardAddress = _coinbossrewardaddress;
        return true;
    }
    
}