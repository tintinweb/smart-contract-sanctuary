/**
 *Submitted for verification at Etherscan.io on 2021-04-09
*/

pragma solidity 0.8.3;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
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

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);
  
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

contract ChainlinkETHUSDPriceConsumer {

    AggregatorV3Interface internal priceFeed;


    constructor() {
        priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice() public view returns (int) {
        (
            , 
            int price,
            ,
            ,
            
        ) = priceFeed.latestRoundData();
        return price;
    }
    
    function getDecimals() public view returns (uint8) {
        return priceFeed.decimals();
    }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
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
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
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

contract Crowdsale is Ownable {
    address public eth_usd_consumer_address;
    ChainlinkETHUSDPriceConsumer private eth_usd_pricer;
    uint8 private eth_usd_pricer_decimals;
    IERC20 public token;
    
    mapping (address => uint256) public vestedAmount;
    mapping (address => uint256) public ethDeposited;
    
    uint256 public totalVested;
    uint256 public balanceLeft;
    
    uint256 private ethStepOne = 10e18;
    uint256 private ethStepTwo = 50e18;
    uint256 private tokenDecimals = 18;
    uint256 private fine = 30;
    
    // 1e6 precision
    uint256 private ethStepOnePrice = 250000;
    uint256 private ethStepTwoPrice = 150000;
    uint256 private ethStepThreePrice = 100000;
    
    uint256 public startDate;
    
    uint256 public oneMonth = 5 minutes;
    uint256 public twoMonths = 10 minutes;
    uint256 public sixMonths = 30 minutes;
    
    uint256 private constant PRICE_PRECISION = 1e6;
    
    constructor (uint256 _startDate, address _token, address _eth_usd_consumer_address) public {
        require(block.timestamp < _startDate);
        startDate = _startDate;
        token = IERC20(_token);
        setETHUSDOracle(_eth_usd_consumer_address);
    }
    
    fallback() external payable {
        buyTokens();
    }
    
    receive() external payable {
        buyTokens();
    }
    
    function buyTokens() public payable {
        // Get the ETH / USD price first, and cut it down to 1e6 precision
        uint256 eth_usd_price = uint256(eth_usd_pricer.getLatestPrice()) * (PRICE_PRECISION) / (uint256(10) ** eth_usd_pricer_decimals);
        uint256 usdDeposited = msg.value * eth_usd_price / 1e18;
        ethDeposited[msg.sender] = msg.value;
        uint256 vested;
        
        if(msg.value <= ethStepOne) {
            token.transfer(msg.sender, usdDeposited / ethStepOnePrice * (uint256(10) ** (tokenDecimals)));
        } else if(msg.value <= ethStepTwo) {
            vested = usdDeposited / ethStepTwoPrice * (uint256(10) ** (tokenDecimals));
            vestedAmount[msg.sender] += vested;
        } else if(msg.value > ethStepTwo) {
            vested = usdDeposited / ethStepThreePrice * (uint256(10) ** (tokenDecimals));
            vestedAmount[msg.sender] += vested;
        } 
        
        require(vested <= token.balanceOf(address(this)) - totalVested, "Not enough tokens in contract");
        totalVested += vested;
    }
    
    function claim() public {
        require(block.timestamp >= startDate + sixMonths);
        uint256 tokensToSend = unlockedTokens(msg.sender);
        vestedAmount[msg.sender] -= tokensToSend;
        
        token.transfer(msg.sender, vestedAmount[msg.sender]);
    }
    
    function unlockedTokens(address _address) public view returns(uint256) {
        uint256 monthsPassed = ((block.timestamp - (startDate + sixMonths)) / oneMonth) + 1;
        monthsPassed = monthsPassed > 10 ? 10 : monthsPassed;
        
        if(block.timestamp < (startDate + sixMonths)) {
            monthsPassed = 0;
        }
        
        return vestedAmount[_address] * 10 * monthsPassed / 100;
    }
    
    function setETHUSDOracle(address _eth_usd_consumer_address) public onlyOwner {
        eth_usd_consumer_address = _eth_usd_consumer_address;
        eth_usd_pricer = ChainlinkETHUSDPriceConsumer(_eth_usd_consumer_address);
        eth_usd_pricer_decimals = eth_usd_pricer.getDecimals();
    }
    
    function withdrawETH() public {
        require(block.timestamp <= startDate + twoMonths);
    
        uint256 amountToSend = ethDeposited[msg.sender] - ethDeposited[msg.sender] * fine / 100;
        
        ethDeposited[msg.sender] = 0;
        vestedAmount[msg.sender] = 0;
        
        payable(address(msg.sender)).transfer(amountToSend);
    }
    
    function claimEth() public onlyOwner {
        if(block.timestamp > startDate + twoMonths) {
            payable(address(msg.sender)).transfer(address(this).balance);
        } else {
            payable(address(msg.sender)).transfer(address(this).balance * fine / 100);
        }
    }
}