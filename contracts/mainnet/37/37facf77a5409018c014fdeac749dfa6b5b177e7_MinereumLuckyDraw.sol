/**
 *Submitted for verification at Etherscan.io on 2020-05-04
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
	uint public maxNumber = 10001;
	uint public systemNumber = 3232;	
	
	address[] public winner;
	uint[] public winnerTickets;
	uint[] public winnerETHAmount;
	uint[] public winnerTimestamp;
	
	address[] public lost;
	uint[] public lostTickets;
	uint[] public lostTimestamp;
	
	event Numbers(address indexed from, uint[] n, string m);
	
	constructor() public
	{
		mne = Minereum(0x7eE48259C4A894065d4a5282f230D00908Fd6D96);
		owner = payable(msg.sender);	
	}
	
	receive() external payable { }
    
	
    function BuyTickets(address _sender, uint256[] memory _max) public payable returns (uint256)
    {
		require(msg.sender == address(mne));
		require(tx.origin == _sender);
		
		bool win = false;
		
		uint[] memory numbers = new uint[](_max[0]);
        uint i = 0;
        		
		while (i < _max[0])
        {	
            //Random number generation
			numbers[i] = uint256(uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), i)))%maxNumber);
            if (numbers[i] == systemNumber)
                win = true;
            i++;
        }
		
		uint valueStakeHolder = msg.value * stakeHoldersfee / 100;
		
        if (win)
		{
			address payable add = payable(_sender);
			uint contractBalance = address(this).balance;
			emit Numbers(msg.sender, numbers, "You WON!");
			uint winAmount = contractBalance * percentWin / 100;
			uint totalToPay = winAmount - stakeHoldersfee;
			if (!add.send(totalToPay)) revert('Error While Executing Payment.');
			totalPaidOut += totalToPay;
			winner.push(_sender);
			winnerTickets.push(_max[0]);
			winnerETHAmount.push(totalToPay);
			winnerTimestamp.push(block.timestamp);
		}
        else
		{	
			lost.push(_sender);
			lostTickets.push(_max[0]);
			lostTimestamp.push(block.timestamp);
            emit Numbers(msg.sender, numbers, "Your numbers don't match the System Number! Try Again.");
		}
		ticketsSold += _max[0];
		
		uint totalEthfee = ethfee * _max[0];
		uint totalMneFee = mnefee * _max[0];
		if (msg.value < totalEthfee) revert('Not enough ETH.');
		mne.Payment.value(valueStakeHolder)();
		totalSentToStakeHolders += valueStakeHolder;
		
		return totalMneFee;
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
	
	function winnerLength() public view returns (uint256) { return winner.length; }
	function lossesLength() public view returns (uint256) { return lost.length; }
}