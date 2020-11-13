pragma solidity 0.6.8;

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
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
  * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two unsigned integers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

interface ERC20 {
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external  view returns (uint256);
  function transfer(address to, uint value) external  returns (bool success);
  function transferFrom(address from, address to, uint256 value) external returns (bool success);
  function approve(address spender, uint value) external returns (bool success);
}

contract yRiseTokenSale {
  using SafeMath for uint256;

  uint256 public totalSold;
  ERC20 public yRiseToken;
  address payable public owner;
  uint256 public collectedETH;
  uint256 public startDate;
  bool public softCapMet;
  bool private presaleClosed = false;
  uint256 private ethWithdrawals = 0;
  uint256 private lastWithdrawal;

  // tracks all contributors.
  mapping(address => uint256) internal _contributions;
  // adjusts for different conversion rates.
  mapping(address => uint256) internal _averagePurchaseRate;
  // total contributions from wallet.
  mapping(address => uint256) internal _numberOfContributions;

  constructor(address _wallet) public {
    owner = msg.sender;
    yRiseToken = ERC20(_wallet);
  }

  uint256 amount;
  uint256 rateDay1 = 20;
  uint256 rateDay2 = 16;
  uint256 rateDay3 = 13;
  uint256 rateDay4 = 10;
  uint256 rateDay5 = 8;
 
  // Converts ETH to yRise and sends new yRise to the sender
  receive () external payable {
    require(startDate > 0 && now.sub(startDate) <= 7 days);
    require(yRiseToken.balanceOf(address(this)) > 0);
    require(msg.value >= 0.1 ether && msg.value <= 3 ether);
    require(!presaleClosed);
     
    if (now.sub(startDate) <= 1 days) {
       amount = msg.value.mul(20);
       _averagePurchaseRate[msg.sender] = _averagePurchaseRate[msg.sender].add(rateDay1.mul(10));
    } else if(now.sub(startDate) > 1 days && now.sub(startDate) <= 2 days) {
       amount = msg.value.mul(16);
       _averagePurchaseRate[msg.sender] = _averagePurchaseRate[msg.sender].add(rateDay2.mul(10));
    } else if(now.sub(startDate) > 2 days && now.sub(startDate) <= 3 days) {
       amount = msg.value.mul(13);
       _averagePurchaseRate[msg.sender] = _averagePurchaseRate[msg.sender].add(rateDay3.mul(10));
    } else if(now.sub(startDate) > 3 days && now.sub(startDate) <= 4 days) {
       amount = msg.value.mul(10);
       _averagePurchaseRate[msg.sender] = _averagePurchaseRate[msg.sender].add(rateDay4.mul(10));
    } else if(now.sub(startDate) > 4 days) {
       amount = msg.value.mul(8);
       _averagePurchaseRate[msg.sender] = _averagePurchaseRate[msg.sender].add(rateDay5.mul(10));
    }
    
    require(amount <= yRiseToken.balanceOf(address(this)));
    // update constants.
    totalSold = totalSold.add(amount);
    collectedETH = collectedETH.add(msg.value);
    // update address contribution + total contributions.
    _contributions[msg.sender] = _contributions[msg.sender].add(amount);
    _numberOfContributions[msg.sender] = _numberOfContributions[msg.sender].add(1);
    // transfer the tokens.
    yRiseToken.transfer(msg.sender, amount);
    // check if soft cap is met.
    if (!softCapMet && collectedETH >= 100 ether) {
      softCapMet = true;
    }
  }

  // Converts ETH to yRise and sends new yRise to the sender
  function contribute() external payable {
    require(startDate > 0 && now.sub(startDate) <= 7 days);
    require(yRiseToken.balanceOf(address(this)) > 0);
    require(msg.value >= 0.1 ether && msg.value <= 3 ether);
    require(!presaleClosed);

    if (now.sub(startDate) <= 1 days) {
       amount = msg.value.mul(20);
       _averagePurchaseRate[msg.sender] = _averagePurchaseRate[msg.sender].add(rateDay1.mul(10));
    } else if(now.sub(startDate) > 1 days && now.sub(startDate) <= 2 days) {
       amount = msg.value.mul(16);
       _averagePurchaseRate[msg.sender] = _averagePurchaseRate[msg.sender].add(rateDay2.mul(10));
    } else if(now.sub(startDate) > 2 days && now.sub(startDate) <= 3 days) {
       amount = msg.value.mul(13);
       _averagePurchaseRate[msg.sender] = _averagePurchaseRate[msg.sender].add(rateDay3.mul(10));
    } else if(now.sub(startDate) > 3 days && now.sub(startDate) <= 4 days) {
       amount = msg.value.mul(10);
       _averagePurchaseRate[msg.sender] = _averagePurchaseRate[msg.sender].add(rateDay4.mul(10));
    } else if(now.sub(startDate) > 4 days) {
       amount = msg.value.mul(8);
       _averagePurchaseRate[msg.sender] = _averagePurchaseRate[msg.sender].add(rateDay5.mul(10));
    }
        
    require(amount <= yRiseToken.balanceOf(address(this)));
    // update constants.
    totalSold = totalSold.add(amount);
    collectedETH = collectedETH.add(msg.value);
    // update address contribution + total contributions.
    _contributions[msg.sender] = _contributions[msg.sender].add(amount);
    _numberOfContributions[msg.sender] = _numberOfContributions[msg.sender].add(1);
    // transfer the tokens.
    yRiseToken.transfer(msg.sender, amount);
    // check if soft cap is met.
    if (!softCapMet && collectedETH >= 100 ether) {
      softCapMet = true;
    }
  }

  function numberOfContributions(address from) public view returns(uint256) {
    return _numberOfContributions[address(from)]; 
  }

  function contributions(address from) public view returns(uint256) {
    return _contributions[address(from)];
  }

  function averagePurchaseRate(address from) public view returns(uint256) {
    return _averagePurchaseRate[address(from)];
  }

  // if the soft cap isn't met and the presale period ends (7 days) enable
  // users to buy back their ether.
  function buyBackETH(address payable from) public {
    require(now.sub(startDate) > 7 days && !softCapMet);
    require(_contributions[from] > 0);
    uint256 exchangeRate = _averagePurchaseRate[from].div(10).div(_numberOfContributions[from]);
    uint256 contribution = _contributions[from];
    // remove funds from users contributions.
    _contributions[from] = 0;
    // transfer funds back to user.
    from.transfer(contribution.div(exchangeRate));
  }

  // Function to withdraw raised ETH (staggered withdrawals)
  // Only the contract owner can call this function
  function withdrawETH() public {
    require(msg.sender == owner && address(this).balance > 0);
    require(softCapMet == true && presaleClosed == true);
    uint256 withdrawAmount;
    // first ether withdrawal (max 150 ETH)
    if (ethWithdrawals == 0) {
      if (collectedETH <= 150 ether) {
        withdrawAmount = collectedETH;
      } else {
        withdrawAmount = 150 ether;
      }
    } else {
      // remaining ether withdrawal (max 150 ETH per withdrawal)
      // staggered in 7 day periods.
      uint256 currDate = now;
      // ensure that it has been at least 7 days.
      require(currDate.sub(lastWithdrawal) >= 7 days);
      if (collectedETH <= 150 ether) {
        withdrawAmount = collectedETH;
      } else {
        withdrawAmount = 150 ether;
      }
    }
    lastWithdrawal = now;
    ethWithdrawals = ethWithdrawals.add(1);
    collectedETH = collectedETH.sub(withdrawAmount);
    owner.transfer(withdrawAmount);
  }

  function endPresale() public {
    require(msg.sender == owner);
    presaleClosed = true;
  }

  // Function to burn remaining yRise (sale must be over to call)
  // Only the contract owner can call this function
  function burnyRise() public {
    require(msg.sender == owner && yRiseToken.balanceOf(address(this)) > 0 && now.sub(startDate) > 7 days);
    // burn the left over.
    yRiseToken.transfer(address(0), yRiseToken.balanceOf(address(this)));
  }
  
  //Starts the sale
  //Only the contract owner can call this function
  function startSale() public {
    require(msg.sender == owner && startDate==0);
    startDate=now;
  }
  
  //Function to query the supply of yRise in the contract
  function availableyRise() public view returns(uint256) {
    return yRiseToken.balanceOf(address(this));
  }
}