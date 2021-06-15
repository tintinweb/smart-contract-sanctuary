/**
 *Submitted for verification at Etherscan.io on 2021-06-15
*/

pragma solidity 0.5.9;

contract TRC20 {
  uint256 public decimals;
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address _from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
}
contract LynkPadIDO {
    address payable public owner;
    address public admin;
    uint256 public startBlock;
    uint256 public endBlock;
    uint256 public totalTokenForSales;
    uint256 public currentlyCompletedSales = 0;
    uint256 public totalethEarned;
    uint256 public TokensPereth;
    uint256 public minPurchase;
    uint256 public maxPurchase;
    address creater;
    TRC20 token;
    event buyevent(address buyer, uint256 amounteth,uint256 amountToken);
    constructor() public {
    creater = msg.sender;
  }
    function initialize(address payable _owner,address _admin,address tokenAddress,uint256 _startBlock,uint256 _endBlock,uint256 _minprice,uint256 _maxprice,uint256 _totalTokenForSales,uint256 _tokenPereth) external {
        require(msg.sender == creater, 'Permission Denied'); // sufficient check
        owner = _owner;
        admin = _admin;
        token = TRC20(tokenAddress);
        totalTokenForSales = _totalTokenForSales;
        TokensPereth = _tokenPereth;
        startBlock = _startBlock;
        endBlock = _endBlock;
        minPurchase = _minprice;
        maxPurchase = _maxprice;
    }

    function purchaseTokens() public payable {
        require(msg.value >= minPurchase && msg.value <= maxPurchase,"Invalid Purchase");
        require(now >= startBlock && now <= endBlock,"Sales ended or not yet started");
        require(currentlyCompletedSales<totalTokenForSales,"Sales Completed");
        uint256 decimal = token.decimals();
        uint256 tokens = msg.value * TokensPereth / 1000000000000000000;
        uint256 tokentosale = tokens * 10 ** decimal;
        require(tokentosale + currentlyCompletedSales < totalTokenForSales,"Token Exceed The Limit");
        token.transfer(msg.sender,tokentosale);
        owner.transfer(msg.value);
        currentlyCompletedSales += tokentosale;
        totalethEarned += msg.value;
        emit buyevent(msg.sender, msg.value,tokentosale);
    }
   
    function changeMinMaxPurchase(uint256 mineth,uint256 maxeth) external{
        require(msg.sender == owner || msg.sender == admin,"Permission Denied");
        minPurchase = mineth;
        maxPurchase = maxeth;
    }
    function changeStartAndEndSales(uint256 startblock,uint256 endblock) external{
        require(msg.sender == owner || msg.sender == admin,"Permission Denied");
        startBlock = startblock;
        endBlock = endblock;
    }
    function increaseTokenForSales(uint256 numoftokensToIncrease) external{
        require(msg.sender == owner || msg.sender == admin,"Permission Denied");
        totalTokenForSales += numoftokensToIncrease;
    }
    function safeWithdraw() public {
        require(msg.sender == owner,"Permission Denied");
        owner.transfer(address(this).balance);
    }
    function changePrice(uint256 _tokensPereth) external{
        require(msg.sender == owner || msg.sender == admin,"Permission Denied");
        TokensPereth = _tokensPereth;
    }
    function safeWithdrawToken(address tokenAddress) public {
        require(msg.sender == owner,"Permission Denied");
        TRC20 receivedToken = TRC20(tokenAddress);
        receivedToken.transfer(owner,receivedToken.balanceOf(address(this)));
    }
}