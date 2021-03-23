/**
 *Submitted for verification at Etherscan.io on 2021-03-22
*/

pragma solidity ^0.7.5;

interface Minereum {
  function Payment (  ) payable external;  
}

interface BazarSwap {
  function getWeiPriceUnitTokenList (address seller, address tokenAddress) external view returns (uint);  
}

contract MinereumLuckyDraw
{
	Minereum public mne;
	uint public stakeHoldersfee = 50;
	uint public percentWin = 80;
	uint public mnefee = 0;
	uint public ethfee = 15000000000000000;
	uint public totalSentToStakeHolders = 0;
	uint public totalPaidOut = 0;
	uint public ticketsSold = 0;
	uint public ticketsPlayed = 0;
	address public owner = 0x0000000000000000000000000000000000000000;	
	uint public maxNumber = 10001;
	uint public systemNumber = 3223;
	
	uint public blockInterval = 3;
	uint public midBlock = 2;
	uint public maxBlock = 256;
	
	//winners from past contracts
	uint public winnersCount = 0;
	uint public winnersEthCount = 0;
	
	address[] public winners;
	uint[] public winnersTickets;
	uint[] public winnersETH;
	uint[] public winnersTimestamp;
	
	uint public bazarSwapCount = 0;
	bool public bazarSwapActive = true;
	BazarSwap public bazar;
	
	mapping (address => mapping (address => bool)) public bazarSwapClaimed;

	mapping (address => uint256) public playerBlock;
	mapping (address => uint256) public playerTickets;
	
	event Numbers(address indexed from, uint[] n, string m);
	
	constructor() public
	{
		mne = Minereum(0x426CA1eA2406c07d75Db9585F22781c096e3d0E0);
		bazar = BazarSwap(0xb3cD2Bf2DC3D92E5647953314561d10a9B7CF473);
		owner = msg.sender;
		//data from old contract
		ticketsPlayed = 405;
		ticketsSold = 510;
		totalSentToStakeHolders = 3727500000000000000;
	}
	
	receive() external payable { }
	
	function LuckyDraw() public
    {
        require(msg.sender == tx.origin);
		
		if (block.number >= playerBlock[msg.sender] + maxBlock) //256
		{
			uint[] memory empty = new uint[](0);	
			emit Numbers(address(this), empty, "Your tickets expired or are invalid. Try Again.");
			playerBlock[msg.sender] = 0;
			playerTickets[msg.sender] = 0;			
		}		
		else if (block.number > playerBlock[msg.sender] + blockInterval)
		{
			bool win = false;

			uint[] memory numbers = new uint[](playerTickets[msg.sender]);		
			
			uint i = 0;
			while (i < playerTickets[msg.sender])
			{
				numbers[i] = uint256(uint256(keccak256(abi.encodePacked(blockhash(playerBlock[msg.sender] + midBlock), i)))%maxNumber);
				if (numbers[i] == systemNumber)
					win = true;
				i++;				
			}
			
			ticketsPlayed += playerTickets[msg.sender];
			
			
			if (win)
			{
				address payable add = payable(msg.sender);
				uint contractBalance = address(this).balance;
				uint winAmount = contractBalance * percentWin / 100;
				uint totalToPay = winAmount;
				if (!add.send(totalToPay)) revert('Error While Executing Payment.');
				totalPaidOut += totalToPay;
				
				winnersCount++;
				winnersEthCount += totalToPay;
				emit Numbers(address(this), numbers, "YOU WON!");
				
				winners.push(msg.sender);
				winnersTickets.push(playerTickets[msg.sender]);
				winnersETH.push(totalToPay);
				winnersTimestamp.push(block.timestamp);
			}
			else
			{
				emit Numbers(address(this), numbers, "Your numbers don't match the System Number! Try Again.");
			}
			
			playerBlock[msg.sender] = 0;
			playerTickets[msg.sender] = 0;			
		}
		else
		{
			revert('Players must wait 3 blocks');
		}
    }
	
	function BuyTickets(uint256 _max) public payable
    {
		require(msg.sender == tx.origin);
		
		if (_max == 0) revert('value is 0');
		
		if (playerBlock[msg.sender] == 0)
		{	
			ticketsSold += _max;			
			uint totalEthfee = ethfee * _max;
			
			playerBlock[msg.sender] = block.number;
			playerTickets[msg.sender] = _max;			
			
			if (msg.value < totalEthfee) revert('Not enough ETH.');
			mne.Payment{value:msg.value}();
			totalSentToStakeHolders += msg.value;			
		}
		else 
		{
			revert('You must play the tickets first');
		}
    }
	
	function ClaimBazarSwapTickets(address tokenAddress) public
    {
		require(msg.sender == tx.origin);
		
		if (playerBlock[msg.sender] > 0) revert('You must play the tickets you have first');
		
		if (bazarSwapClaimed[msg.sender][tokenAddress]) revert('Ticket already claimed');
		
		if (bazar.getWeiPriceUnitTokenList(msg.sender, tokenAddress) == 0) revert('Token not set for sale');
		
		playerBlock[msg.sender] = block.number;
		playerTickets[msg.sender] = 1;	
		bazarSwapClaimed[msg.sender][tokenAddress] = true;		
    }	
	
	function GetBazarSwapClaimed(address _address, address _token) public view returns (bool)
	{
		return bazarSwapClaimed[_address][_token];
	}
	
	function transferFundsOut() public
	{
		if (msg.sender == owner)
		{
			address payable add = payable(msg.sender);
			uint contractBalance = address(this).balance;
			if (!add.send(contractBalance)) revert('Error While Executing Payment.');			
		}
		else
		{
			revert();
		}
	}
	
	function updateFees(uint _stakeHoldersfee, uint _mnefee, uint _ethfee, uint _blockInterval, bool _bazarSwapActive, uint _maxBlock, uint _midBlock) public
	{
		if (msg.sender == owner)
		{
			stakeHoldersfee = _stakeHoldersfee;
			mnefee = _mnefee;
			ethfee = _ethfee;
			blockInterval = _blockInterval;
			bazarSwapActive = _bazarSwapActive;
			maxBlock = _maxBlock;
			midBlock = _midBlock;
		}
		else
		{
			revert();
		}
	}
	
	function updateSystemNumber(uint _systemNumber) public
	{
		if (msg.sender == owner)
		{
			systemNumber = _systemNumber;
		}
		else
		{
			revert();
		}
	}
	
	function updateMaxNumber(uint _maxNumber) public
	{
		if (msg.sender == owner)
		{
			maxNumber = _maxNumber;
		}
		else
		{
			revert();
		}
	}
	
	function updatePercentWin(uint _percentWin) public
	{
		if (msg.sender == owner)
		{
			percentWin = _percentWin;
		}
		else
		{
			revert();
		}
	}	
	
	function updateMNEContract(address _mneAddress) public
	{
		if (msg.sender == owner)
		{
			mne = Minereum(_mneAddress);
		}
		else
		{
			revert();
		}
	}
	
	function updateBazarContract(address _address) public
	{
		if (msg.sender == owner)
		{
			bazar = BazarSwap(_address);
		}
		else
		{
			revert();
		}
	}	
	
	function WinnersLength() public view returns (uint256) { return winners.length; }	
	function GetPlayerBlock(address _address) public view returns (uint256) { return playerBlock[_address]; }
	function GetPlayerTickets(address _address) public view returns (uint256) { return playerTickets[_address]; }
}