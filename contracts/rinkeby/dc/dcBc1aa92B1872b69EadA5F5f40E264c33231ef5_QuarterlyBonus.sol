pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

//     _ \                           |                   |         
//    |   |   |   |    _` |    __|   __|    _ \    __|   |   |   | 
//    |   |   |   |   (   |   |      |      __/   |      |   |   | 
//   \__\_\  \__,_|  \__,_|  _|     \__|  \___|  _|     _|  \__, | 
//                                                          ____/  
//            __ )                              |                  
//            __ \     _ \    __ \    |   |    __)                 
//            |   |   (   |   |   |   |   |  \__ \                 
//           ____/   \___/   _|  _|  \__,_|  (   /                 
//                                             _|                  

//import "hardhat/console.sol";
// import "@openzeppelin/contracts/access/Ownable.sol"; 
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol

contract QuarterlyBonus {

  address private owner;
  address private burnWallet =  0xDeaDbeefdEAdbeefdEadbEEFdeadbeEFdEaDbeeF;
  mapping (address => bool) private Employees;  
  
  address[] public aEmployees;
  uint256 public lastReset;
  uint256 public lastQtrPayout;
  uint256 private oneWeek;
  uint256 public quarterlyBonus;
  uint256 public thePot;
  uint256 private aDay;
  uint256 private round;
  uint256 private aQuarter;
  uint256 private approxGas;
  uint256 public payout;
   
  bool locked = false;


  mapping(address => uint256) public magicEarnyPoints;
  mapping(address => uint256) private earningsPerSecond;
  mapping(address => uint256) private redeemable;

 constructor() payable {
        owner = 0xeD43465A959Ba3842A345a68632Aa048D2A3083c; // Deployment scripts make this more of a pain than I like..oh well.
        lastReset = block.timestamp;
        lastQtrPayout = block.timestamp;
        thePot = msg.value;
        quarterlyBonus = 0;
        oneWeek = 604800;
        aDay = 86400;
        round = 0;
        aQuarter = 7890000;
        approxGas = 69651;
  }



function hireEmployee(address _employee) private{
    Employees[_employee]=true;
    aEmployees.push(_employee);

}

function contains(address _employee) private view returns (bool){
    return Employees[_employee];
}



    function buyin() payable external{
      require(!locked, "Reentrant call detected!");
         locked = true;

         
      if(magicEarnyPoints[msg.sender] + msg.value >= 5 ether && !contains(msg.sender)){
          hireEmployee(msg.sender);
    }
    	if(block.timestamp - lastReset > oneWeek && address(this).balance < 1 ether)
    	{
    		
        
          magicEarnyPoints[msg.sender] = 0;
          earningsPerSecond[msg.sender] = 0;
          redeemable[msg.sender] = 0;

    		//resetGame();
          round += 1;
    		
    	}

      if(block.timestamp - lastQtrPayout > aQuarter)
      {

        //uint gasNeed = aEmployees.length * approxGas;

        payout = quarterlyBonus /*- gasNeed*/ / aEmployees.length;


        for(uint i = 0; i < aEmployees.length; i++)
        {
        aEmployees[i].call{value:payout}("");
        //require(paysuccess[i], "Payout failed.");
        }

        lastQtrPayout = block.timestamp;

      }

    	

      magicEarnyPoints[msg.sender] += msg.value;
      // Deposits
      uint256 left = msg.value;
      uint256 devFee = msg.value / 13 ;

        (bool devsuccess, ) = owner.call{value:devFee}("");
        require(devsuccess, "Transfer failed.");
        left -= devFee;
        quarterlyBonus += msg.value / 40;
        left -= msg.value / 40;
        (bool burnsuccess, ) = burnWallet.call{value:msg.value / 256}("");
        require(burnsuccess, "Burn failed.");
        left -= msg.value / 256;
        
        thePot += left;
        
      //dev wallet
      //thepot         7.5 / 100
      //qtrbonus

        /////////doing something here
        locked = false;
        calcRedeemable();
    }



  function calcRedeemable() private {
    require(!locked, "Reentrant call detected!");
    locked = true;
      uint256 timeElapsedThisRound = block.timestamp - lastReset;
    	
        
      earningsPerSecond[msg.sender] = magicEarnyPoints[msg.sender] / 10 / aDay;
      redeemable[msg.sender] = earningsPerSecond[msg.sender] * timeElapsedThisRound;
    locked = false;
  }

  function getRedeemable() public returns(uint){
    calcRedeemable();
    return redeemable[msg.sender];
  }


  function redeem() public{
        uint256 amount = getRedeemable();
        require(!locked, "Reentrant call detected!");
         locked = true;
        // Deposits
        uint256 pay = amount;
        uint256 devFee = amount / 13 ;

        (bool devsuccess, ) = owner.call{value:devFee}("");
        require(devsuccess, "Transfer failed.");
        pay -= devFee;
        quarterlyBonus += amount / 40;
        pay -= amount / 40;
        (bool burnsuccess, ) = burnWallet.call{value:amount / 256}("");
        require(burnsuccess, "Burn failed.");
        pay -= amount / 256;
        
        (bool success, ) = msg.sender.call{value:pay}("");
        require(success, "Transfer failed.");
    
        thePot -= amount;
        redeemable[msg.sender] = 0;
        locked = false;
  }

  
  function compound() public{
         calcRedeemable();
         require(!locked, "Reentrant call detected!");
         locked = true;
        
        
        magicEarnyPoints[msg.sender] += redeemable[msg.sender];
        redeemable[msg.sender] = 0;
        
        
        locked = false;
  }

  receive() external payable {
    this.buyin(); 
  }

}