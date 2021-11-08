/**
 *Submitted for verification at BscScan.com on 2021-11-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;


interface IBEP20 {
	function totalSupply() external view returns (uint256);
	
	function balanceOf(address account) external view returns (uint256);

	function transfer(address recipient, uint256 amount) external returns (bool);
	
	function allowance(address owner, address spender) external view returns (uint256);
	
	function approve(address spender, uint256 amount) external returns (bool);
	
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
	
	event Transfer(address indexed from, address indexed to, uint256 value);

	event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {
	function _msgSender() internal view virtual returns (address payable){
		return payable(msg.sender);
	}

	function _msgData() internal view virtual returns (bytes memory){
		this;
		return msg.data;
	}
}

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () public {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    } 
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library Address{//Creates a new library with on-deploy functions
	function isContract(address account) internal view returns (bool){
		/*
		Instead of checking for tx > 0 Use EIP-1052 0x0 value for non yet created accounts
		0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 value for accounts
		with no code
		*/
		bytes32 codehash;
		bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
		assembly {codehash := extcodehash(account)}
		return(codehash != accountHash && codehash !=0x0);
	}
	function sendValue(address payable recipient, uint256 amount) internal {
		require(address(this).balance >= amount, "Address: insufficient balance");

		// solhint-disable-next-line avoid-low-level-calls, avoid-call-value
		(bool success, ) = recipient.call{ value: amount }("");
		require(success, "Address: unable to send value, recipient may have reverted");
	}

	function functionCall(address target, bytes memory data) internal returns (bytes memory) {
		return functionCall(target, data, "Address: low-level call failed");
	}

	function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
		return _functionCallWithValue(target, data, 0, errorMessage);
	}


	function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
		return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
	}


	function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
		require(address(this).balance >= value, "Address: insufficient balance for call");
		return _functionCallWithValue(target, data, value, errorMessage);
	}
	function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
		require(isContract(target), "Address: call to non-contract");

		// solhint-disable-next-line avoid-low-level-calls
		(bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
		if (success) {
				return returndata;
		} else {
			// Look for revert reason and bubble it up if present
			if (returndata.length > 0) {
				// The easiest way to bubble the revert reason is using memory via assembly

				// solhint-disable-next-line no-inline-assembly
				assembly {
						let returndata_size := mload(returndata)
						revert(add(32, returndata), returndata_size)
				}
			} else {
				revert(errorMessage);
			}
		}
	}
} 



contract ScratchCard is Context, Ownable{
	uint256 public randoNum;
    uint256 private cardsSold = 0;
	uint256 private FactorySold=0;
    uint256 private maxPrize;
    IBEP20 public factoryContract = IBEP20(0x311bcb6C91aea7a21cf5A1932aEEfc38bF20aaac);
    uint256 public pricePerTicket = 1000*10**18; //1000 FACTORY 0.30 cents
    uint256 public lastResult=0;
    uint256 maxCards;
    uint256 lastPurchase;
	mapping (address=>bool) public isPlaying;
	mapping(address=>uint) public isPrize;
	mapping(address=>bool) public wonLast;
	mapping(address=>uint) public winTier;
	bool GameOn = true;
	uint256 totalWins=0;
	event noPrize(address payable player,bool win);
	event prizePaid(address player,bool win, uint256 amount);
	event ticketBought(address player,uint256 timeBought);
	uint8 randNonce=0;
	//uint256 private _currentplayers=0;
	mapping (address=>uint256) public playsnumber;

    constructor() {
        maxCards=10000;

    }
    //User calls - 
    receive() external payable{}


    function BuyTicket() public{
       
		//uint256 prizeAmount=0;
        
        require(factoryContract.balanceOf(msg.sender)>pricePerTicket && isPlaying[msg.sender]==false); //prevents botting of the game
		require(cardsSold<=maxCards && GameOn==true,"Conditions for game start not met: Game hasnt started or it has finished");//Checks if machine has sold out	
		 factoryContract.transferFrom(msg.sender, address(this), pricePerTicket);//transfers tokens from msg sender to contract
	     isPlaying[_msgSender()]=true;
	     cardsSold+=1;
	     uint256 currentRandomNumber = randomNumber(500);
	     
	     if(currentRandomNumber<175 && currentRandomNumber !=69){
	         isPlaying[_msgSender()]=false;
	          winTier[_msgSender()]=0;
	         emit noPrize(_msgSender(),false);
	        
	     }
	     else if(currentRandomNumber>=175 && currentRandomNumber<=215){
	         isPrize[_msgSender()]=1000*10**18;
	         winTier[_msgSender()]=1;
	     }
		 else if(currentRandomNumber == 496){
			 isPrize[_msgSender()]=100000*10**18;
			 winTier[_msgSender()]=9;

		 }
		 else if(currentRandomNumber >= 235 && currentRandomNumber<=330){
			 isPlaying[_msgSender()]=false;
			 winTier[_msgSender()]=0;
	         emit noPrize(_msgSender(),false);
	         

		 }
		  else if(currentRandomNumber > 331 && currentRandomNumber<=390){
			isPrize[_msgSender()]=1000*10**18;
			 winTier[_msgSender()]=1;

		 }
		   else if(currentRandomNumber > 430 && currentRandomNumber<=460){
			isPrize[_msgSender()]=2500*10**18;
			 winTier[_msgSender()]=2;

		 }
		   else if(currentRandomNumber > 480 && currentRandomNumber<=490){
			isPrize[_msgSender()]=5000*10**18;
			 winTier[_msgSender()]=3;

		 }
		   else if(currentRandomNumber > 490 && currentRandomNumber<=495){
			isPrize[_msgSender()]=10000*10**18;
			 winTier[_msgSender()]=4;

		 }
		   else if(currentRandomNumber > 498 && currentRandomNumber<=500 || currentRandomNumber == 69){
			isPrize[_msgSender()]=25000*10**18;
			 winTier[_msgSender()]=5;
		 }
		 else{
			 isPlaying[_msgSender()]=false;
	         emit noPrize(_msgSender(),false);
	          winTier[_msgSender()]=0;
		 }
		
	     
		
	}


		
	


	function claimPrize() public {
		require(isPrize[msg.sender]>0);
		uint256 amountToClaim = returnLastWonPrize(msg.sender);
		factoryContract.transfer(msg.sender,amountToClaim);
		FactorySold+=amountToClaim;
		emit prizePaid(msg.sender, true, amountToClaim);
		isPrize[msg.sender]=0;
		isPlaying[msg.sender]=false;
		winTier[msg.sender]=0;
		//_currentplayers-=1;


	}
	function randomNumber(uint _modulus) internal returns(uint256){
		randNonce++;
		randoNum= uint(keccak256(abi.encodePacked(block.timestamp,msg.sender,randNonce)))%_modulus;
		return randoNum;
	}

	function returnLastWonPrize(address playerAddress) public view returns(uint256){
		return isPrize[playerAddress];
	}
	function totalCardsSold() public view returns(uint256){
		return cardsSold;
	}

	function clearStats() public onlyOwner{
		require(GameOn==false,"cant clear stats while game is on");
		
		cardsSold=0;
		//_currentplayers=0;

	}
	function startGame() public onlyOwner{
		GameOn=true;

	}
	 function updateTokenAddress (IBEP20 newTokenAddress) public onlyOwner{
		 factoryContract = newTokenAddress;

	 }

	 function contractBalance() public view returns(uint256){
		 return factoryContract.balanceOf(address(this));
	 }
	 
	 function numberOfPlays(address playerAddress) public view returns(uint256){
	     return playsnumber[playerAddress];
	 }
	 
	 function isActive(address playerAddress) public view returns (bool){
	     return isPlaying[playerAddress];
	 }
	 function returnLastWinTier(address playerAddress) public view returns(uint){
	     return winTier[playerAddress];
	 }

	 function stopGame() public onlyOwner{
		 GameOn=false;

	 }
	 function restartGame() public onlyOwner{
		 require(GameOn==false,"Cant restart game in progress");
		 cardsSold=0;

	 }
	 function cleanFactory(IBEP20 tokenAddress) public onlyOwner{
		 uint256 TokenscontractBalance = tokenAddress.balanceOf(address(this));
		 tokenAddress.transfer(owner(), TokenscontractBalance);
	 }
	 function totalFactorySold() public view returns(uint256){
		 return FactorySold;
	 }


	
}