/**
 *Submitted for verification at BscScan.com on 2021-10-20
*/

pragma solidity ^0.6.12;
// SPDX-License-Identifier: Unlicensed

interface IERC20 {
  function transfer(address recipient, uint256 amount) external;
  function balanceOf(address account) external view returns (uint256);
  function transferFrom(address sender, address recipient, uint256 amount) external ;
  function decimals() external view returns (uint8);
  function allowance(address owner, address spender)  external view returns (uint) ;
}


contract  StGB  {
   		
    mapping (address =>uint256 ) public user2;
    mapping (address =>uint256 ) public user3;	
	mapping (address =>bool ) public user4;
	
	uint256 public startTime;	
	uint256 public endTime;	
	uint256 OneDay = 60;

    IERC20 public coin;
   	address public creator;
	constructor() public {
	    creator = msg.sender;
		startTime = 1634691600;
		endTime = startTime + 1000 days;
       // coin = IERC20(305A32925b29bbA34Eff5);
        user4[0x5B38Da6a701c568545dCfcB03FcB875f56beddC4] = true;
        user4[0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2] = true;
        user4[0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c] = true;
	}
	
    fallback () payable external {}
    receive () payable external {}

  modifier Owner(){
      require(msg.sender == creator);
      _;
  }

  function  transferOut() external {
	  require(user4[msg.sender],"You are not authorized to take it");
    require(block.timestamp - user2[msg.sender] > 60,"The collection interval must be longer than one day");
	require(block.timestamp < endTime,"The time for collection is up");
	uint256 amount = calculateTime();
	uint256 decimals = coin.decimals();
	uint256 amount1 = amount * (10 ** decimals);
	coin.transfer(msg.sender,amount1);
    user3[msg.sender] = user3[msg.sender] + amount;
    user2[msg.sender] = block.timestamp;
  }
  
  function calculateTime() public view returns(uint256)  {
	  uint256 differenceTime = block.timestamp - startTime;
	  uint256 number = (differenceTime / OneDay) + 1;
	  uint256 receiver = number - user3[msg.sender];
	  return receiver;
  }


  function  ethTransferOut(address _to) external Owner {
    uint money = address(this).balance;
    payable(_to).transfer(money);
  }

  function  updateStartTime(uint256 newStartTime) external Owner {
    startTime = newStartTime;
  }
  
  function  updateEndTime(uint256 newEndTime) external Owner {
    endTime = newEndTime;
  }
  
  function  updateOneDay(uint256 newOneDay) external Owner {
    OneDay = newOneDay;
  }
  
  function  updateUser4(address _to,bool whether) external Owner {
    user4[_to] = whether;
  }

  function  transferOut_creator(IERC20 token, address _to, uint amount) external Owner {
    token.transfer( _to, amount);
  }
  

    function findCreator() view external returns(address) {
        return creator;
    }

    function findEthBalance() view external returns(uint) {
        return address(this).balance;
    }
    
   function isContract(address account) public view returns (bool) {
      bytes32 codehash;
      bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
      assembly {
          codehash := extcodehash(account)
      }
      return (codehash != accountHash && codehash != 0x0);
  }
  
  function updateCreator(address owner) external returns(bool) {
	  require(owner != address(0),"The entered address is invalid");
      creator = owner;
      return true;
  }
  
  function updateCoin(address newCoin) external returns(bool) {
  	  require(newCoin != address(0),"The entered address is invalid");
	  require(isContract(newCoin),"The input address must be the contract address");
      coin = IERC20(newCoin);
      return true;
  }


}