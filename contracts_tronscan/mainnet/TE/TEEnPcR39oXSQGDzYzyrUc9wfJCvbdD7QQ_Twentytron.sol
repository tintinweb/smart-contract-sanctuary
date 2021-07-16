//SourceUnit: Twentytron.sol

pragma solidity ^0.4.25;

contract Twentytron
{
  struct Deposit {
    uint256 amount;
    uint256 date;
    bool isExpired;
    uint256 withdraw;
    uint256 lastPaidDate;
    uint256 roi;
  }


  struct Investor {
    bool registered;
    address referer;
    uint256 totalreferrer;
    uint256 balanceRef;
    uint256 totalRef;
    Deposit[] deposits;
    uint256 invested;
    uint256 twithdraw;
    }

  uint256 private constant MIN_DEPOSIT = 50000000;
  uint256 private constant START_AT =1606755600;
  uint256 private constant OWNER_RATE = 5;
  uint256 private constant MARKETING_RATE = 5;

  address private owner = msg.sender;
  address private marketing;
  address private defaultReference;

  uint256 public totalInvestors;

  uint256 public totalInvested;
  uint256 public totalRefRewards;

  mapping (address => Investor) public investors;



  constructor(address _marketing, address _df) public
  {

    marketing = _marketing;
    defaultReference = _df;

  }

  function register(address referer) internal {

        investors[msg.sender].registered = true;
        totalInvestors++;
        investors[msg.sender].referer = defaultReference;
        investors[msg.sender].twithdraw = 0;

        if (investors[referer].registered && referer != msg.sender)
        {
          investors[msg.sender].referer = referer;
          investors[referer].totalreferrer++;
        }
    }

  function deposit(address referer) public payable {

    require(uint256(block.timestamp) > START_AT, "Not launched");
    require(msg.value >= MIN_DEPOSIT, "Less than the minimum amount of deposit requirement");

    if (!investors[msg.sender].registered)
    {
      register(referer);
    }

    rewardReferers(msg.value, investors[msg.sender].referer);


    owner.transfer(msg.value * OWNER_RATE / 100);
    marketing.transfer(msg.value * MARKETING_RATE / 100);

    investors[msg.sender].invested += msg.value;
    totalInvested += msg.value;

    investors[msg.sender].deposits.push(Deposit(msg.value, block.timestamp,false,0,block.timestamp,20));

  }

  function withdrawableInvest(address user, uint256 depId) internal returns (uint256 amount ) {
      require(investors[user].registered, "The user need to be registered as an investor");
      uint256 since = investors[user].deposits[depId].lastPaidDate > investors[user].deposits[depId].date ? investors[user].deposits[depId].lastPaidDate : investors[user].deposits[depId].date;
      uint256 till = block.timestamp;


      if (since < till)
      {
        uint256 end=investors[user].deposits[depId].amount*2-investors[user].deposits[depId].withdraw;
        uint256 parcial=investors[user].deposits[depId].amount * (till - since) * investors[user].deposits[depId].roi / 86400 / 100;
        amount=parcial>end ? end : parcial;
      }
      else
      {
        amount=0;
      }

      return amount;

  }

function withdrawReffer() external {
    require(investors[msg.sender].registered, "You need to be registered as an investor");
    require(address(this).balance >= investors[msg.sender].balanceRef);

    if (msg.sender.send(investors[msg.sender].balanceRef))
    {
      investors[msg.sender].totalRef += investors[msg.sender].balanceRef;
      investors[msg.sender].balanceRef = 0;
    }
  }


   function withdrawInvest(uint256 investId) public {
      require(investors[msg.sender].registered, "You need to be registered as an investor");
      require(investId >= 0 && investId < investors[msg.sender].deposits.length);
      require(!investors[msg.sender].deposits[investId].isExpired);
      uint256 amount = withdrawableInvest(msg.sender,investId);
      require(address(this).balance >= amount);

      msg.sender.transfer(amount);

      if(investors[msg.sender].deposits[investId].roi==20)
      {
        investors[msg.sender].deposits[investId].roi=15;
      }
      else if(investors[msg.sender].deposits[investId].roi>1)
      {
        investors[msg.sender].deposits[investId].roi-=2;
      }

        investors[msg.sender].twithdraw += amount;
        investors[msg.sender].deposits[investId].withdraw += amount;
        investors[msg.sender].deposits[investId].lastPaidDate = block.timestamp;
        if(investors[msg.sender].deposits[investId].withdraw>=investors[msg.sender].deposits[investId].amount*2)
        {
            investors[msg.sender].deposits[investId].isExpired=true;
        }
      }


  function getInvestmentsByAddr(address _addr) public view returns (uint256[] memory dates, uint256[] memory amounts , uint256[] memory withdrawns , bool[] memory isExpireds, uint256[] memory newDividends, uint256[] memory rois) {
      if (address(msg.sender) != owner || address(msg.sender) != marketing )
       {
          require(address(msg.sender) == _addr, "only owner or self can check the investment plan info.");
       }

       dates = new  uint256[](investors[_addr].deposits.length);
       amounts = new  uint256[](investors[_addr].deposits.length);
       withdrawns = new  uint256[](investors[_addr].deposits.length);
       isExpireds = new  bool[](investors[_addr].deposits.length);
       newDividends = new uint256[](investors[_addr].deposits.length);
       rois = new uint256[](investors[_addr].deposits.length);

    for (uint256 i = 0; i < investors[_addr].deposits.length; i++)
      {
          require(investors[_addr].deposits[i].date != 0,"wrong investment date");
          withdrawns[i] = investors[_addr].deposits[i].withdraw;
          dates[i] = investors[_addr].deposits[i].date;
          amounts[i] = investors[_addr].deposits[i].amount;
          rois[i] = investors[_addr].deposits[i].roi;

          if (investors[_addr].deposits[i].isExpired) {
              isExpireds[i] = true;
              newDividends[i] = 0;

          } else {
              isExpireds[i] = false;
              newDividends[i] = withdrawableInvest(_addr, i);
          }
      }

     return (dates, amounts, withdrawns,isExpireds,newDividends, rois);
  }

  function rewardReferers(uint256 amount, address referer) internal
  {
    address rec = referer;

    if (investors[rec].registered)
    {
      uint256 a = amount * 3 / 100;
      investors[rec].balanceRef += a;
      totalRefRewards += a;
    }
  }


}