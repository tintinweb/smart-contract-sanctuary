/**
 *Submitted for verification at Etherscan.io on 2020-05-05
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
	address public owner = 0x0000000000000000000000000000000000000000;	
	uint public maxNumber = 10000001;
	uint public systemNumber = 0;	
	uint public currentTickets = 0;
	uint public closedBlock = 0;
	
	bool public ticketsOpen = true;
	//winners from past contracts
	uint public winnersCount = 4;
	uint public winnersEthCount = 4000000000000000000;
	
	address[] public players;
	uint[] public tickets;
		
	uint[] public pastGameNr;
	uint[] public pastGameSystemNumber;
	uint[] public pastGameTickets;
	uint[] public pastGamePlayers;
	address[] public winners;
	uint[] public winnerTickets;
	uint[] public winnerETHAmount;
	uint[] public pastGameTimestamp;
	
	address[] public winnersOnly;
	uint[] public winnersOnlyTickets;
	uint[] public winnersOnlyETH;
	uint[] public winnersOnlyTimestamp;
	
	event Numbers(address indexed from, uint n, string m);
	
	address public _closerAddress;
	
	constructor() public
	{
		mne = Minereum(0x7eE48259C4A894065d4a5282f230D00908Fd6D96);
		_closerAddress = 0xF8094e15c897518B5Ac5287d7070cA5850eFc6ff;
		owner = payable(msg.sender);	
		pastGameNr.push(0);
		pastGameSystemNumber.push(0);
		pastGamePlayers.push(0);
		pastGameTickets.push(0);
		winners.push(0x0000000000000000000000000000000000000000);
		winnerTickets.push(0);
		winnerETHAmount.push(0);
		pastGameTimestamp.push(0);
	}
	
	receive() external payable { }
	
	function VerifyWinners(uint min, uint max) public
    {
        require(msg.sender == tx.origin);
		if ((!ticketsOpen) && (block.number > closedBlock + 3))
		{
			uint i = 0;
			uint m = players.length;
			
			if (msg.sender == _closerAddress && min > 0 && max > 0)
			{
				i = min;
				m = max;
			}
			
			systemNumber = uint256(uint256(keccak256(abi.encodePacked(blockhash(block.number - 1))))%maxNumber);
			address _winner;
			uint _winnerTickets;
			
			bool win = false;
			
			while (i < m)
			{
				if (win)
					break;
				
				uint j = 0;
				while (j < tickets[i])
				{						
					if (uint256(uint256(keccak256(abi.encodePacked(players[i], j)))%maxNumber) == systemNumber)
					{
						win = true;
						_winner = players[i];
						_winnerTickets = tickets[i];
						break;
					}
					j++;
				}
				i++;
			}
			
			if (win)
			{
				address payable add = payable(_winner);
				uint contractBalance = address(this).balance;
				uint winAmount = contractBalance * percentWin / 100;
				uint totalToPay = winAmount;
				if (!add.send(totalToPay)) revert('Error While Executing Payment.');
				totalPaidOut += totalToPay;	
				
				
				winnersOnly.push(_winner);
				winnersOnlyTickets.push(_winnerTickets);
				winnersOnlyETH.push(totalToPay);
				winnersOnlyTimestamp.push(block.timestamp);
				
				pastGameNr.push(pastGameNr[pastGameNr.length - 1] + 1);
				pastGameSystemNumber.push(systemNumber);
				pastGamePlayers.push(players.length);
				pastGameTickets.push(currentTickets);
				winners.push(_winner);
				winnerTickets.push(_winnerTickets);
				winnerETHAmount.push(totalToPay);
				pastGameTimestamp.push(block.timestamp);
				winnersCount++;
				winnersEthCount += totalToPay;
				emit Numbers(_winner, systemNumber, "WINNER!");
			}
			else
			{	
				pastGameNr.push(pastGameNr[pastGameNr.length - 1] + 1);
				pastGameSystemNumber.push(systemNumber);
				pastGamePlayers.push(players.length);
				pastGameTickets.push(currentTickets);
				winners.push(0x0000000000000000000000000000000000000000);
				winnerTickets.push(0);
				winnerETHAmount.push(0);
				pastGameTimestamp.push(block.timestamp);
				emit Numbers(msg.sender, systemNumber, "No winners! Try Again.");
			}
			
			currentTickets = 0;		
			delete players;
			delete tickets;
			ticketsOpen = true;
			closedBlock = 0;
		}
		else
		{
			revert('Tickets must be closed and block number must be + 10');
		}
    }
	
	function CloseTickets() public
	{
		require(msg.sender == _closerAddress);
		ticketsOpen = false;
		closedBlock = block.number;
	}
	
	function OpenTickets() public
	{
		require(msg.sender == _closerAddress);
		ticketsOpen = true;
		closedBlock = 0;
	}
	
    function BuyTickets(address _sender, uint256[] memory _max) public payable returns (uint256)
    {
		require(msg.sender == address(mne));
		require(_sender == tx.origin);
		
		if (ticketsOpen)
		{
			players.push(_sender);
			tickets.push(_max[0]);			
			uint valueStakeHolder = msg.value * stakeHoldersfee / 100;					
			currentTickets += _max[0];
			ticketsSold += _max[0];			
			uint totalEthfee = ethfee * _max[0];
			uint totalMneFee = mnefee * _max[0];
			if (msg.value < totalEthfee) revert('Not enough ETH.');
			mne.Payment.value(valueStakeHolder)();
			totalSentToStakeHolders += valueStakeHolder;
			return totalMneFee;
		}
		else 
		{
			revert('tickets closed until draw is done.');
		}
		
		return 0;
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
	
	function updateFees(uint _stakeHoldersfee, uint _mnefee, uint _ethfee) public
	{
		if (msg.sender == owner)
		{
			stakeHoldersfee = _stakeHoldersfee;
			mnefee = _mnefee;
			ethfee = _ethfee;
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
	
	function updateCloserAddress(address _address) public
	{
		if (msg.sender == owner)
		{
			_closerAddress = _address;
		}
		else
		{
			revert();
		}
	}
	
	function pastGameNrLength() public view returns (uint256) { return pastGameNr.length; }
	function winnersOnlyLength() public view returns (uint256) { return winnersOnly.length; }
	function playersLength() public view returns (uint256) { return players.length; }
	function ticketsLength() public view returns (uint256) { return tickets.length; }
}