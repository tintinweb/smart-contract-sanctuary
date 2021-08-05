/**
 *Submitted for verification at Etherscan.io on 2020-05-12
*/

pragma solidity ^0.6.0;

interface Minereum {
  function Payment (  ) payable external;  
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
	uint public maxBlock = 60;
	
	//winners from past contracts
	uint public winnersCount = 0;
	uint public winnersEthCount = 0;
	
	address[] public winners;
	uint[] public winnersTickets;
	uint[] public winnersETH;
	uint[] public winnersTimestamp;
	
	mapping (address => uint256) public playerBlock;
	mapping (address => uint256) public playerTickets;
	
	event Numbers(address indexed from, uint[] n, string m);
	
	address public _closerAddress;
	
	constructor() public
	{
		mne = Minereum(0x426CA1eA2406c07d75Db9585F22781c096e3d0E0);
		owner = msg.sender;			
	}
	
	receive() external payable { }
	
	function LuckyDraw() public
    {
        require(msg.sender == tx.origin);
		
		if (block.number >= playerBlock[msg.sender] + 256)
		{
			uint[] memory empty = new uint[](0);	
			emit Numbers(address(this), empty, "Your tickets expired or are invalid. Try Again.");
		}		
		else if (block.number > playerBlock[msg.sender] + blockInterval)
		{
			bool win = false;

			uint[] memory numbers = new uint[](playerTickets[msg.sender]);		
			
			uint i = 0;
			while (i < playerTickets[msg.sender])
			{
				numbers[i] = uint256(uint256(keccak256(abi.encodePacked(blockhash(playerBlock[msg.sender] + 2), i)))%maxNumber);
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
	
	function BuyTickets(address _sender, uint256[] memory _max) public payable returns (uint256)
    {
		require(msg.sender == address(mne));
		require(_sender == tx.origin);
		
		if (_max[0] == 0) revert('value is 0');
		
		if (playerBlock[_sender] == 0)
		{	
			uint valueStakeHolder = msg.value * stakeHoldersfee / 100;					
			ticketsSold += _max[0];			
			uint totalEthfee = ethfee * _max[0];
			uint totalMneFee = mnefee * _max[0];
			
			playerBlock[_sender] = block.number;
			playerTickets[_sender] = _max[0];			
			
			if (msg.value < totalEthfee) revert('Not enough ETH.');
			mne.Payment.value(valueStakeHolder)();
			totalSentToStakeHolders += valueStakeHolder;
			return totalMneFee;
		}
		else 
		{
			revert('You must play the tickets first');
		}
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
	
	function updateFees(uint _stakeHoldersfee, uint _mnefee, uint _ethfee, uint _blockInterval) public
	{
		if (msg.sender == owner)
		{
			stakeHoldersfee = _stakeHoldersfee;
			mnefee = _mnefee;
			ethfee = _ethfee;
			blockInterval = _blockInterval;
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
	
	function WinnersLength() public view returns (uint256) { return winners.length; }	
	function GetPlayerBlock(address _address) public view returns (uint256) { return playerBlock[_address]; }
	function GetPlayerTickets(address _address) public view returns (uint256) { return playerTickets[_address]; }
}