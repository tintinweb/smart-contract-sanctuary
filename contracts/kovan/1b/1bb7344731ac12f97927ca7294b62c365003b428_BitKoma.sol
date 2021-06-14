/**
 *Submitted for verification at Etherscan.io on 2021-06-14
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
contract BitKoma {
    address payable public owner;
    address public admin;
    uint256 public startBlock = 1623671732;
    uint256 public endBlock = 1623930932;
    uint256 public totalTokenForSales;
    uint256 public currentlyCompletedSales = 0;
    uint256 public totalTrxEarned;
    uint256 public TokensPerTrx;
    uint256 public minPurchase = 0.001 ether;
    uint256 public maxPurchase = 1 ether;
    TRC20 token;
    event buyevent(address buyer, uint256 amountTrx,uint256 amountToken);
    constructor(address payable _owner,address tokenAddress,uint256 _totalTokenForSales,uint256 _tokenPerTrx) public {
        owner = _owner;
        admin = msg.sender;
        token = TRC20(tokenAddress);
        totalTokenForSales = _totalTokenForSales;
        TokensPerTrx = _tokenPerTrx;
    }

    function purchaseTokens() public payable {
        require(msg.value >= minPurchase && msg.value <= maxPurchase,"Invalid Purchase");
        require(now >= startBlock && now <= endBlock,"Sales ended or not yet started");
        require(currentlyCompletedSales<totalTokenForSales,"Sales Completed");
        uint256 decimal = token.decimals();
        uint256 tokens = msg.value / 1 ether * TokensPerTrx;
        uint256 tokentosale = tokens * 10 ** decimal;
        require(tokentosale + currentlyCompletedSales < totalTokenForSales,"Token Exceed The Limit");
        token.transfer(msg.sender,tokentosale);
        owner.transfer(msg.value);
        currentlyCompletedSales += tokentosale;
        totalTrxEarned += msg.value;
        emit buyevent(msg.sender, msg.value,tokentosale);
    }
   
    function changeMinMaxPurchase(uint256 mintrx,uint256 maxtrx) external{
        require(msg.sender == owner || msg.sender == admin,"Permission Denied");
        minPurchase = mintrx;
        maxPurchase = maxtrx;
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
    function changePrice(uint256 _tokensPerTrx) external{
        require(msg.sender == owner || msg.sender == admin,"Permission Denied");
        TokensPerTrx = _tokensPerTrx;
    }
    function safeWithdrawToken(address tokenAddress) public {
        require(msg.sender == owner,"Permission Denied");
        TRC20 receivedToken = TRC20(tokenAddress);
        receivedToken.transfer(owner,receivedToken.balanceOf(address(this)));
    }
}