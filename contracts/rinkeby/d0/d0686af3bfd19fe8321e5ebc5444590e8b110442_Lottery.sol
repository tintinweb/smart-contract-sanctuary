/**
 *Submitted for verification at Etherscan.io on 2021-12-14
*/

pragma solidity ^0.4.17;

contract Ownable {
    address public _owner = msg.sender;

    modifier isOwner {
        require(_owner == msg.sender);
        _;
    }

    function changeOwner(address newOwner) public isOwner {
        _owner = newOwner;
    }
}

contract Lottery is Ownable {
    uint256 public _balance;
    uint256 public _ownerBalance;

    uint256 public constant _ticketPrice = 0.01 ether;
    uint256 public constant _targetRoundBalance = 1 ether;

    address[] public players;

    event WinnerPicked(address winner, uint256 amount);

    modifier whenRoundLimitReached {
        require(_balance >= _targetRoundBalance && players.length > 1);
        _;
    }

    function buyTicket() public payable {
        require(msg.value >= _ticketPrice);
        players.push(msg.sender);
        _balance += msg.value;
    }

    function claimWinner() public payable whenRoundLimitReached {
        bytes32 ticketHash = keccak256(block.difficulty, block.timestamp);
        uint ticketNumber = uint(ticketHash);
        uint index = ticketNumber % players.length;
        uint256 winAmount = _balance/2;
        address winner = players[index];
        WinnerPicked(winner, winAmount);
        winner.transfer(winAmount);
        uint256 fundBalance = _balance - winAmount;
        _balance = fundBalance/2;
        _ownerBalance += fundBalance - _balance;
        players = new address[](0);
    }

    function getPlayers() public view returns(address[]) {
      return players;
    }

    function claimFunds() public isOwner {
        require(_ownerBalance > 0);
        _owner.transfer(_ownerBalance);
        _ownerBalance = 0;
    }

    function() public payable {
        buyTicket();
    }
}