/**
 *Submitted for verification at polygonscan.com on 2021-09-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library SafeMath {
  /**
   * @dev Returns the addition of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `+` operator.
   *
   * Requirements:
   * - Addition cannot overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, 'SafeMath: addition overflow');

    return c;
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, 'SafeMath: subtraction overflow');
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  /**
   * @dev Returns the multiplication of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `*` operator.
   *
   * Requirements:
   * - Multiplication cannot overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, 'SafeMath: multiplication overflow');

    return c;
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, 'SafeMath: division by zero');
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, 'SafeMath: modulo by zero');
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts with custom message when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function mod(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}


abstract contract Context {
  function _msgSender() internal view virtual returns (address) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes calldata) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

abstract contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor() {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(_owner == _msgSender(), 'Ownable: caller is not the owner');
    _;
  }

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), 'Ownable: new owner is the zero address');
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}



interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
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

contract PriceConsumerV3 {

    AggregatorV3Interface internal priceFeed;

    constructor(address token) public {
        priceFeed = AggregatorV3Interface(token);
    }

    function getDecimals() public view returns (uint8) {
        return priceFeed.decimals();
    }
    
    function getDescription() public view returns (string memory) {
        return priceFeed.description();
    }
    
    function getLatestPrice() public view returns (int) {
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return price;
    }
}


interface IERC20 {
    // function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    // function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    // function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

contract MultiTokenExchange is Ownable {

    using SafeMath for uint256;

    bool public paused;
    address public exchangeToken;
    address public walletAddress;
    
    // margin percentage
    uint private margin_int = 0;
    uint private margin_decimals = 1;
    // list of token addresses
    address[] private tokenAddresses;
    // map token address to bool
    mapping(address => bool) public baseTokens;
    // map data feed contract address to bool
    mapping(address => bool) public isInstantiation;
    // map token address to data feed contract address
    mapping(address => address) public dataFeedContractAddress;

    // events
    event ContractInstantiation(address instantiation, address token);
    event Deposit(address indexed from, address indexed to, uint256 value, address token);
    event Withdraw(address indexed from, address indexed to, uint256 value, address token);
    event Exchange(address indexed from, address indexed to, uint256 value_from, address token_from, uint256 value_to, address token_to);
    
    constructor (address _exchangeToken) {

        // set token to be exchanged for (BITE POINT)
        exchangeToken = _exchangeToken;
        
        // the wallet for withdraw money
        walletAddress = msg.sender;
    }
    
    // power function
    function pow(uint256 base, uint256 exponent) private pure returns (uint256) {
        if (exponent == 0) {
            return 1;
        }
        else if (exponent == 1) {
            return base;
        }
        else if (base == 0 && exponent != 0) {
            return 0;
        }
        else {
            uint256 z = base;
            for (uint256 i = 1; i < exponent; i++)
                z = SafeMath.mul(z, base);
            return z;
        }
    }
    
    // set the percentage markup
    function setMargin(uint margin, uint decimals) public onlyOwner {
        require(decimals > 0, "DECIMAL CANNOT BE 0");
        require( margin < SafeMath.mul(3, pow(10, SafeMath.sub(decimals, 1))), " Margin CANNOT BE HIGHER THAN 30%" );
        margin_int = margin;
        margin_decimals = decimals;
    }
    
    // get the percentage markup
    function getMargin() public view onlyOwner returns (uint, uint) {
        return (margin_int, margin_decimals);
    }
    
    // get the tokens that we supports
    function getSupportedTokenAddresses() public view returns (address[] memory){
        address[] memory supportedTokenAddresses = new address[](tokenAddresses.length);
        for ( uint256 i = 0 ; i < tokenAddresses.length ; i ++ ){
            supportedTokenAddresses[i] = tokenAddresses[i];
        }
        return supportedTokenAddresses;
    }

    function getDataFeedContractAddress(address token_address) public view returns (address) {
        return dataFeedContractAddress[token_address];
    }
    
    function checkTokenAddressExists(address token_address) internal view returns (bool) {
        bool exists = false;
        for (uint i = 0 ; i < tokenAddresses.length ; i ++ ) {
            if (tokenAddresses[i] == token_address ) {
                exists = true;
            }
        }
        return exists;
    }
  
    // for registering data feed contracts
    function register(address instantiation, address token) internal {
        isInstantiation[instantiation] = true;
        dataFeedContractAddress[token] = instantiation;
        emit ContractInstantiation(instantiation, token);
    }
    
    function setDataFeedContractAddress(address[] memory _baseTokens, address[] memory _dataFeedLinkPairAddress) public onlyOwner {
        
        // length check
        require(_baseTokens.length == _dataFeedLinkPairAddress.length, "Length of Input Does Not Match");
        
        // A list of acceptable token addresses
        for (uint i = 0 ; i < _baseTokens.length ; i++){
            
            address token_address = _baseTokens[uint(i)];
            address dataFeedLinkPairAddress = _dataFeedLinkPairAddress[uint(i)];
            // store token address // check if exist first
            if ( ! checkTokenAddressExists(token_address) ) {
                tokenAddresses.push(token_address);
            }
            // enable token to be exchanged
            baseTokens[token_address] = true;
            
            // create data feed contracts for monitoring price
            address contractAddress = address(new PriceConsumerV3(dataFeedLinkPairAddress));
            
            // register data feed contracts creation
            register(contractAddress, token_address);
            
            // enable base token for exchangeForToken
            baseTokens[token_address] = true;
        }
    }

    function getDataFeedDescription(address contractAddress) public view onlyOwner returns (string memory) {
        string memory description = PriceConsumerV3(contractAddress).getDescription();
        return description;
    }

    function enableBaseToken(address token_address) public onlyOwner {
        require(baseTokens[token_address] == false, "TOKEN ADDRESS IS NOT DISABLED");
        baseTokens[token_address] = true;
    }
    
    function disableBaseToken(address token_address) public onlyOwner{
        require(baseTokens[token_address] = true, "TOKEN ALREADY DISABLED");
        baseTokens[token_address] = false;
    }
    
    function updateWalletAddress(address addr) public onlyOwner {
        walletAddress = addr;
    }

    function abs(int x) private pure returns (int) {
        return x >= 0 ? x : -x;
    }
    
    function pos(int x) private pure returns (bool) {
        return x > 0 ? true : false;
    }
    
    // struct that stores the in memory variables for the exchangeForToken function
    struct ExchangeInfo{
        uint256 exchangeAmount;
        uint256 fee;
        address dataFeedContract;
        uint256 exchangeRate;
        int256 decimalsBaseTokens;
        int256 decimalsExchangeTokens;
        int256 decimalsPair;
        int256 decimalConversionValue;
        uint256 exp;
        bool isPositive;
        uint256 userBalance;
        uint256 exchangeTokenBalance;
    }
    
    function getExchangeRateInfo(address baseToken) public view returns (uint256, int256) {
        ExchangeInfo memory eInfo;
        eInfo.dataFeedContract = dataFeedContractAddress[baseToken];
        eInfo.exchangeRate = uint256(PriceConsumerV3(eInfo.dataFeedContract).getLatestPrice());
        eInfo.decimalsPair = int8(PriceConsumerV3(eInfo.dataFeedContract).getDecimals());
        return (eInfo.exchangeRate, eInfo.decimalsPair);
    }
    
    
    function computeExchangeAmount(ExchangeInfo memory eInfo, address baseToken, uint256 amount) internal view {

        // get decimals for exchangeToken
        eInfo.decimalsExchangeTokens = int8(IERC20(exchangeToken).decimals());
        
        // check chainlink for conversion rate
        eInfo.dataFeedContract = dataFeedContractAddress[baseToken];
        eInfo.exchangeRate = uint256(PriceConsumerV3(eInfo.dataFeedContract).getLatestPrice());
        eInfo.decimalsPair = int8(PriceConsumerV3(eInfo.dataFeedContract).getDecimals());
        
        // conversion
        eInfo.decimalConversionValue = eInfo.decimalsBaseTokens - eInfo.decimalsExchangeTokens + eInfo.decimalsPair; // safemath cannot be applied to int
        assert(eInfo.decimalConversionValue < 50); // assert the outcome is not weird
        eInfo.exp = uint256(abs(eInfo.decimalConversionValue));
        eInfo.isPositive = pos(eInfo.decimalConversionValue);
      
        // compute exchange amount based on exchange rate and adjust for the difference in decimals
        if ( eInfo.isPositive ) {
            eInfo.exchangeAmount = amount.mul(eInfo.exchangeRate).div(pow(10, eInfo.exp));
        } else {
            eInfo.exchangeAmount = amount.mul(eInfo.exchangeRate).mul(pow(10, eInfo.exp));
        }
        
        // compute transation fee and subtract from exchangeAmount
        eInfo.fee = eInfo.exchangeAmount.mul(margin_int).div(pow(10, margin_decimals));
        eInfo.exchangeAmount = eInfo.exchangeAmount.sub(eInfo.fee);
        
        // conversion
        eInfo.exchangeTokenBalance = balanceOfExchangeToken();
        require(eInfo.exchangeTokenBalance >= eInfo.exchangeAmount, "CONTRACT_HAS_INSUFFICIENT_TOKEN_IN_POOL");
        
    }
    
    function exchangeForNativeToken() public payable {
        require(paused == false, "Contract Paused");
        
        // Create A Struct to Store Data in Memory
        ExchangeInfo memory eInfo;
        require( baseTokens[address(0)] == true, "TOKEN NOT SUPPORTED FOR EXCHANGE" );
        
        uint256 amount = msg.value; // overwrite amount with value for native token
        eInfo.decimalsBaseTokens = 18;
        
        // compute exchange rate
        computeExchangeAmount(eInfo, address(0), amount);
        
        IERC20(exchangeToken).transfer(msg.sender, eInfo.exchangeAmount);
        
        emit Exchange(msg.sender, address(this), amount, address(0), eInfo.exchangeAmount, exchangeToken);        
        
    }
    
    function exchangeForToken(uint256 amount, address baseToken) public {
        require(paused == false, "Contract Paused");
        
        // Create A Struct to Store Data in Memory
        ExchangeInfo memory eInfo;

        require( baseTokens[baseToken] == true, "TOKEN NOT SUPPORTED FOR EXCHANGE" );

        // check balance
        eInfo.userBalance = IERC20(baseToken).balanceOf(address(msg.sender));
        eInfo.decimalsBaseTokens = int8(IERC20(baseToken).decimals());
        require(eInfo.userBalance >= amount, "INSUFFICIENT_FUND"); // only need to check balance if user is using ERC20 token
        
        // check Allowance if ERC20 Token
        uint allowance = IERC20(baseToken).allowance(msg.sender, address(this));
        require(allowance >= amount, "INSUFFICIENT_ALLOWANCE");

        // compute exchange amount
        computeExchangeAmount(eInfo, baseToken, amount);
        
        // transfer tokens
        IERC20(baseToken).transferFrom(msg.sender, address(this), amount);
        IERC20(exchangeToken).transfer(msg.sender, eInfo.exchangeAmount);
         
        emit Exchange(msg.sender, address(this), amount, baseToken, eInfo.exchangeAmount, exchangeToken);
    }

    function depositExchangeToken(uint256 amount) public onlyOwner {
        uint256 balance = IERC20(exchangeToken).balanceOf(address(msg.sender));
        require(balance >= amount, "INSUFFICIENT_INPUT_AMOUNT");
        IERC20(exchangeToken).transferFrom(msg.sender, address(this), amount);

        emit Deposit(msg.sender, address(this), amount, exchangeToken);
    }
    
    function withdrawExchangeToken() public onlyOwner {
        uint256 balance = IERC20(exchangeToken).balanceOf(address(this));   
        IERC20(exchangeToken).transfer(walletAddress, balance);

        emit Withdraw(address(this), walletAddress, balance, exchangeToken);
    }
    
    // withdraw a particular baseToken, i.e. Ethereum
    function withdrawBaseToken(address baseToken) public payable onlyOwner {
        uint256 balance = 0;
        if (baseToken == address(0)){
            balance = address(this).balance;
            payable(walletAddress).transfer(balance);
        } else {
            balance = IERC20(baseToken).balanceOf(address(this));
            IERC20(baseToken).transfer(walletAddress, balance);   
        }
        emit Withdraw(address(this), walletAddress, balance, baseToken);
    }
    
    function balanceOfExchangeToken() public view returns (uint256) {
        uint256 balance = IERC20(exchangeToken).balanceOf(address(this));
        return balance;
    }

    function balanceOfBaseToken(address baseToken) public view returns (uint256 amount) {
        if ( baseToken == address(0) ) {
            return address(this).balance;
        }
        uint256 balance = IERC20(baseToken).balanceOf(address(this));
        return balance;
    }
    
    function setPaused(bool _paused) public onlyOwner {
        paused = _paused;
    }
    
}