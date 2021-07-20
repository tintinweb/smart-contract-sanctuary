/**
 *Submitted for verification at Etherscan.io on 2021-07-20
*/

pragma solidity >=0.5.0 <0.6.0;


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
    
    // 0x74825DbC8BF76CC4e9494d0ecB210f676Efa001D - DAI/ETH Testnet
    // 0x773616E4d11A78F511299002da57A0a94577F1f4 - DAI/ETH Mainnet
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


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


contract Ownable  {
    address payable public _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
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
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address payable newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


interface Token {
    function transfer(address to, uint256 value) external returns (bool);


    function balanceOf(address who) external view returns (uint256);

}


contract Buy_INH_Token is Ownable{
    
    using SafeMath for uint;

    address public tokenAddr;
    uint256 private ethAmount;
    uint256 public tokenPriceEth; 
    uint256 public tokenDecimal = 18;
    uint256 public ethDecimal = 18;
    
    AggregatorV3Interface internal priceFeed;


    event TokenTransfer(address beneficiary, uint amount);
    
    mapping (address => uint256) public balances;
    mapping(address => uint256) public tokenExchanged;

    constructor(address _tokenAddr) public {
        tokenAddr = _tokenAddr;
        priceFeed = AggregatorV3Interface(0x773616E4d11A78F511299002da57A0a94577F1f4);

    }
    
    
    
    function() payable external {
        ExchangeETHforToken(msg.sender, msg.value);
        balances[msg.sender] = balances[msg.sender].add(msg.value);
    }
    
    function getLatestPrice() public view returns (uint256) {
        (
            , 
            int price,
            ,
            ,
        ) = priceFeed.latestRoundData();
        return uint256(price);
    }
    
    function ExchangeETHforToken(address _addr, uint256 _amount) private {
        uint256 amount = _amount;
        address userAdd = _addr;
        
        tokenPriceEth = getLatestPrice();
        
        ethAmount = ((amount.mul(10 ** uint256(tokenDecimal)).div(tokenPriceEth)).mul(10 ** uint256(tokenDecimal))).div(10 ** uint256(tokenDecimal));
        require(Token(tokenAddr).balanceOf(address(this)) >= ethAmount, "There is low token balance in contract");
        
        require(Token(tokenAddr).transfer(userAdd, ethAmount));
        emit TokenTransfer(userAdd, ethAmount);
        tokenExchanged[msg.sender] = tokenExchanged[msg.sender].add(ethAmount);
        _owner.transfer(amount);
    }
    
    function ExchangeETHforTokenMannual() public payable {
        uint256 amount = msg.value;
        address userAdd = msg.sender;
        
        tokenPriceEth = getLatestPrice();
        
        ethAmount = ((amount.mul(10 ** uint256(tokenDecimal)).div(tokenPriceEth)).mul(10 ** uint256(tokenDecimal))).div(10 ** uint256(tokenDecimal));
        require(Token(tokenAddr).balanceOf(address(this)) >= ethAmount, "There is low token balance in contract");
        
        require(Token(tokenAddr).transfer(userAdd, ethAmount));
        balances[msg.sender] = balances[msg.sender].add(msg.value);
        emit TokenTransfer(userAdd, ethAmount);
        tokenExchanged[msg.sender] = tokenExchanged[msg.sender].add(ethAmount);
        _owner.transfer(amount);
        
    }
    

    function updateTokenDecimal(uint256 newDecimal) public onlyOwner {
        tokenDecimal = newDecimal;
    }
    
    function updateTokenAddress(address newTokenAddr) public onlyOwner {
        tokenAddr = newTokenAddr;
    }

    function withdrawTokens(address beneficiary) public onlyOwner {
        require(Token(tokenAddr).transfer(beneficiary, Token(tokenAddr).balanceOf(address(this))));
    }

    function withdrawCrypto(address payable beneficiary) public onlyOwner {
        beneficiary.transfer(address(this).balance);
    }
    function tokenBalance() public view returns (uint256){
        return Token(tokenAddr).balanceOf(address(this));
    }
    function ethBalance() public view returns (uint256){
        return address(this).balance;
    }
}