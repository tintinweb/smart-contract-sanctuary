/*
The ChefICO Smart Contract has the following features implemented:
- ETH can only be deposited before the 1st of July, 2018., and only in amounts greater to or equal to 0.2 ETH.
- A address(person) can not deposit ETH to the smart contract after they have already deposited 250 ETH.
- It is not possible to deposit ETH to the smart contract once the hard cap has been reached.
- If a address(person) deposits an ETH amount which makes the total funds deposited to the smart contract exceed the hard cap, 
  exceeded amount is returned to the address.
- If a address(person) deposits an amount which is greater than 250 ETH, or which makes their total deposits through the ICO 
  exceed 250 ETH, exceeded amount is returned to the address.

- If a address(person) deposits an amount that is less than 10 ETH, they achieve certain bonuses based on the time of the transaction.
  The time-based bonuses for deposits that are less than 10 ETH are defined as follows:
    1. Deposits made within the first ten days of the ICO achieve a 20% bonus in CHEF tokens.
    2. Deposits made within the second ten days of the ICO achieve a 15% bonus in CHEF tokens.
    3. Deposits made within the third ten days of the ICO achieve a 10% bonus in CHEF tokens.
    4. Deposits made within the fourth ten days of the ICO achieve a 5% bonus in CHEF tokens.

- If a address(person) deposits an amount that is equal to or greater than 10 ETH, they achieve certain bonuses based on the 
  amount transfered. The volume-based bonuses for deposits that are greater than or equal to 10 ETH are defined as follows:
    1. Deposits greater than or equal to 150 ETH achieve a 35% bonus in CHEF tokens.
    2. Deposits smaller than 150 ETH, but greater than or equal to 70 ETH achieve a 30% bonus in CHEF tokens.
    3. Deposits smaller than 70 ETH, but greater than or equal to 25 ETH achieve a 25% bonus in CHEF tokens.
    4. Deposits smaller than 25 ETH, but greater than or equal to 10 ETH achieve a 20% bonus in CHEF tokens.

Short overview of significant functions:
- safeWithdrawal:
    This function enables users to withdraw the funds they have deposited to the ICO in case the ICO does not reach the soft cap. 
    It will be possible to withdraw the deposited ETH only after the 1st of July, 2018.
- chefOwnerWithdrawal: 
    This function enables the ICO smart contract owner to withdraw the funds in case the ICO reaches the soft or hard cap 
    (ie. the ICO is successful). The CHEF tokens will be released to investors manually, after we check the KYC status of each 
    person that has contributed 10 or more ETH, as well as we confirm that each person has not contributed more than 10 ETH 
    from several addresses.
*/
  
  pragma solidity 0.4.23;
  library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract ChefICO {
    
    using SafeMath for uint256;
    
    uint256 public softCap;
    uint256 public hardCap;
    uint256 public totalAmount;
    uint256 public chefPrice;
    uint256 public minimumInvestment;
    uint256 public maximumInvestment;
    uint256 public finalBonus;
    
    uint256 public icoStart;
    uint256 public icoEnd;
    address public chefOwner;

    bool public softCapReached = false;
    bool public hardCapReached = false;

    mapping(address => uint256) public balanceOf;
    mapping(address => uint256) public chefBalanceOf;

    event ChefICOSucceed(address indexed recipient, uint totalAmount);
    event ChefICOTransfer(address indexed tokenHolder, uint value, bool isContribution);


    function ChefICO() public {
        softCap = 7000 * 1 ether;
        hardCap = 22500 * 1 ether;
        totalAmount = 1100 * 1 ether; //Private presale funds with 35% bonus
        chefPrice = 0.0001 * 1 ether;
        minimumInvestment = 1 ether / 5;
        maximumInvestment = 250 * 1 ether;
       
        icoStart = 1525471200;
        icoEnd = 1530396000;
        chefOwner = msg.sender;
    }
    
    
    function balanceOf(address _contributor) public view returns (uint256 balance) {
        return balanceOf[_contributor];
    }
    
    
    function chefBalanceOf(address _contributor) public view returns (uint256 balance) {
        return chefBalanceOf[_contributor];
    }


    modifier onlyOwner() {
        require(msg.sender == chefOwner);
        _;
    }
    
    
    modifier afterICOdeadline() { 
        require(now >= icoEnd );
            _; 
        }
        
        
    modifier beforeICOdeadline() { 
        require(now <= icoEnd );
            _; 
        }
    
   
    function () public payable beforeICOdeadline {
        uint256 amount = msg.value;
        require(!hardCapReached);
        require(amount >= minimumInvestment && balanceOf[msg.sender] < maximumInvestment);
        
        if(hardCap <= totalAmount.add(amount)) {
            hardCapReached = true;
            emit ChefICOSucceed(chefOwner, hardCap);
            
             if(hardCap < totalAmount.add(amount)) {
                uint256 returnAmount = totalAmount.add(amount).sub(hardCap);
                msg.sender.transfer(returnAmount);
                emit ChefICOTransfer(msg.sender, returnAmount, false);
                amount = amount.sub(returnAmount);    
             }
        }
        
        if(maximumInvestment < balanceOf[msg.sender].add(amount)) {
          uint overMaxAmount = balanceOf[msg.sender].add(amount).sub(maximumInvestment);
          msg.sender.transfer(overMaxAmount);
          emit ChefICOTransfer(msg.sender, overMaxAmount, false);
          amount = amount.sub(overMaxAmount);
        }

        totalAmount = totalAmount.add(amount);
        balanceOf[msg.sender] = balanceOf[msg.sender].add(amount);
               
        if (amount >= 10 ether) {
            if (amount >= 150 ether) {
                chefBalanceOf[msg.sender] = chefBalanceOf[msg.sender].add(amount.div(chefPrice).mul(135).div(100));
            }
            else if (amount >= 70 ether) {
                chefBalanceOf[msg.sender] = chefBalanceOf[msg.sender].add(amount.div(chefPrice).mul(130).div(100));
            }
            else if (amount >= 25 ether) {
                chefBalanceOf[msg.sender] = chefBalanceOf[msg.sender].add(amount.div(chefPrice).mul(125).div(100));
            }
            else {
                chefBalanceOf[msg.sender] = chefBalanceOf[msg.sender].add(amount.div(chefPrice).mul(120).div(100));
            }
        }
        else if (now <= icoStart.add(10 days)) {
            chefBalanceOf[msg.sender] = chefBalanceOf[msg.sender].add(amount.div(chefPrice).mul(120).div(100));
        }
        else if (now <= icoStart.add(20 days)) {
            chefBalanceOf[msg.sender] = chefBalanceOf[msg.sender].add(amount.div(chefPrice).mul(115).div(100));
        }
        else if (now <= icoStart.add(30 days)) {
            chefBalanceOf[msg.sender] = chefBalanceOf[msg.sender].add(amount.div(chefPrice).mul(110).div(100));
        }
        else if (now <= icoStart.add(40 days)) {
            chefBalanceOf[msg.sender] = chefBalanceOf[msg.sender].add(amount.div(chefPrice).mul(105).div(100));
        }
        else {
            chefBalanceOf[msg.sender] = chefBalanceOf[msg.sender].add(amount.div(chefPrice));
        }
        
        emit ChefICOTransfer(msg.sender, amount, true);
        
        if (totalAmount >= softCap && softCapReached == false ){
        softCapReached = true;
        emit ChefICOSucceed(chefOwner, totalAmount);
        }
    }

    
   function safeWithdrawal() public afterICOdeadline {
        if (!softCapReached) {
	    uint256 amount = balanceOf[msg.sender];
            balanceOf[msg.sender] = 0;
            if (amount > 0) {
                msg.sender.transfer(amount);
                emit ChefICOTransfer(msg.sender, amount, false);
            }
        }
    }
        
    
    function chefOwnerWithdrawal() public onlyOwner {    
        if ((now >= icoEnd && softCapReached) || hardCapReached) {
            chefOwner.transfer(totalAmount);
            emit ChefICOTransfer(chefOwner, totalAmount, false);
        }
    }
}