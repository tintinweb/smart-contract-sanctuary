pragma solidity ^0.4.24;

library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns(uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns(uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns(uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns(uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

}

contract LotteryStorage {
    using SafeMath for uint256;
    
    mapping (uint => uint) public dateDraws;
    mapping (uint => uint) public dateWinners;
    mapping (uint => uint) public dateTickets;
    mapping (uint => uint) public listJackpotDraws;
    mapping (uint => uint) public listTicketsDraws;
    mapping (uint => uint) public listWinnersDraws;
    mapping (uint => uint) public listUsersRewards;
    mapping (uint => uint) public ticketDraws;
    mapping (uint => address) public ticketAccount;
    mapping (uint => address) public winnerAccount;

    function createLottery(uint _countOfDraws, uint _jackpot) external {
        listJackpotDraws[_countOfDraws] = _jackpot;
        dateDraws[_countOfDraws] = block.number;
    }

    function addTicketsToDraw(uint _countOfDraws, uint8 _numberOfTickets, uint8 _numDraws) external {
        // for statistic: total tickets for each draws
        for (uint8 j = 0; j < _numDraws; j ++) {
            listTicketsDraws[_countOfDraws+j] = listTicketsDraws[_countOfDraws+j].add(uint(_numberOfTickets));
        }
    }

    function addWinTickets(uint _countOfDraws, uint _winTickets) external {
        listWinnersDraws[_countOfDraws] = listWinnersDraws[_countOfDraws].add(_winTickets);
    }

    function addUserRewards(uint _totalWinners, uint _reward, address _player) external {
        listUsersRewards[_totalWinners] = _reward;
        dateWinners[_totalWinners] = block.number;
        winnerAccount[_totalWinners] = _player;
    }

    function buyTicketToDraw(uint _countOfDraws, uint _idTicket, address _player) external {
        dateTickets[_idTicket] = block.number;
        ticketDraws[_idTicket] = _countOfDraws;
        ticketAccount[_idTicket] = _player;
    }
}