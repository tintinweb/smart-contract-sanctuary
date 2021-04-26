/**
 *Submitted for verification at Etherscan.io on 2021-04-26
*/

pragma solidity ^0.5.1;

interface Token{
    function transfer(address _to, uint256 amount) external returns (bool);
    function transferFrom(address _from, address _to, uint256 amount) external returns(bool);
    function balanceOf(address owner) external returns (uint256);
    function approve(address _spender, uint256 amount) external returns(bool);
}

interface AggregatorV3Interface {
  
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



contract TokenSale{


    AggregatorV3Interface internal priceFeed;

    constructor(address _token) public {
        priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
        tokenContract=Token(_token);
    }

    
    function latestRoundData() public view returns (int) {
        (,int price,,, ) = priceFeed.latestRoundData();
        return price;
    }

    using SafeMath for uint;
    address payable admin;
    Token public tokenContract;
    uint256 public tokenPrice=1 ether;
    uint256 public tokenSold;
    struct User{
        uint256 totalinvested;
        uint256 investedtime;
        uint256 totalwithdrawreward;
    }
    mapping(address=>User)public users;
    event Sell(address _buyer, uint256 _amount);
    
    
    function buyToken(uint256 _numberOfTokens) public payable{
        require(msg.value >=( _numberOfTokens*tokenPrice));
        require(tokenContract.balanceOf(address(this)) >= _numberOfTokens); //aghy b karen
        require(tokenContract.transfer(msg.sender, _numberOfTokens));
        tokenSold = tokenSold.add(_numberOfTokens);
        emit Sell (msg.sender, _numberOfTokens);
        
    }
    function sellToken(uint256 _numberOfTokens ) public returns (bool){
        require(tokenContract.balanceOf(msg.sender) >= _numberOfTokens, "insuffient balance");
        require(address(this).balance>= _numberOfTokens.mul(tokenPrice),"Contract has insuffient");
        tokenContract.transferFrom(msg.sender, address(this), _numberOfTokens);
        msg.sender.transfer(_numberOfTokens.mul(tokenPrice));
        return true;
        
    }
    
    function invest( uint256 _numberOfTokens) public returns (bool){
        require(tokenContract.balanceOf(msg.sender)>= _numberOfTokens, "insuffient balance");
         tokenContract.transferFrom(msg.sender, address(this), _numberOfTokens);
         users[msg.sender].totalinvested=users[msg.sender].totalinvested.add(_numberOfTokens);  //users[msg.sender].totalinvested.add(_numberOfTokens);  //total investment yahan jama hn gi..
         users[msg.sender].investedtime= now;   // block.timestamp;  ///aur ya btaye ga unsny kis din ki investement...
         return true;
        
    }
    
    function withdraw()public returns(bool){
        require(users[msg.sender].investedtime.add(5 days)<=block.timestamp,"you are withdrawing the money befre time");
        require(users[msg.sender].totalinvested>0, "you have not invested anything");
        tokenContract.transfer(msg.sender,users[msg.sender].totalinvested.mul(2));
        users[msg.sender].totalinvested = 0;
        users[msg.sender].investedtime = 0;
        }
    
    function destruct()public{
        require(msg.sender==admin, "access denied");
        require(tokenContract.transfer(admin, tokenContract.balanceOf(address(this))));
        selfdestruct( admin);
    }
    
}




library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
}