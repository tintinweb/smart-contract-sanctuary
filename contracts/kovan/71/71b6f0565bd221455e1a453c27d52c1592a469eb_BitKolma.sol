/**
 *Submitted for verification at Etherscan.io on 2021-06-14
*/

pragma solidity 0.5.9;

contract ERC20 {
  uint256 public decimals;
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address _from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
}
contract BitKolma {
    address payable public owner;
    address public admin;
    uint256 public startBlock = 1623671732;
    uint256 public endBlock = 1623930932;
    uint256 public totalTokenForSales;
    uint256 public currentlyCompletedSales = 0;
    uint256 public totalethEarned;
    uint256 public TokensPereth;
    uint256 public minPurchase = 0.001 ether;
    uint256 public maxPurchase = 1 ether;
    ERC20 token;
    event buyevent(address buyer, uint256 amounteth,uint256 amountToken);
    event buy(uint256 tokentosale, uint256 tokens,uint256 amountToken);
    constructor(address payable _owner,address tokenAddress,uint256 _totalTokenForSales,uint256 _tokenPereth) public {
        owner = _owner;
        admin = msg.sender;
        token = ERC20(tokenAddress);
        totalTokenForSales = _totalTokenForSales;
        TokensPereth = _tokenPereth;
    }

    function purchaseTokens() public payable {
        require(msg.value >= minPurchase && msg.value <= maxPurchase,"Invalid Purchase");
        require(now >= startBlock && now <= endBlock,"Sales ended or not yet started");
        require(currentlyCompletedSales<totalTokenForSales,"Sales Completed");
        uint256 decimal = token.decimals();
        uint256 tokens = msg.value / 1000000000000000000 * TokensPereth;
        uint256 tokentosale = tokens * 10 ** decimal;
        emit buy(tokentosale,tokens,msg.value / 1000000000000000000);
        // require(tokentosale + currentlyCompletedSales < totalTokenForSales,"Token Exceed The Limit");
        // require(token.transfer(msg.sender,tokentosale),"Token transfer failed");
        // owner.transfer(msg.value);
        // currentlyCompletedSales += tokentosale;
        // totalethEarned += msg.value;
        // emit buyevent(msg.sender, msg.value,tokentosale);
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
        ERC20 receivedToken = ERC20(tokenAddress);
        receivedToken.transfer(owner,receivedToken.balanceOf(address(this)));
    }
}