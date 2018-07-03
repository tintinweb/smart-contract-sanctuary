pragma solidity ^0.4.21;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

contract WorldCupWinner {
    using SafeMath for uint256;

    /*****------ EVENTS -----*****/
  event BuyWinner(address indexed buyer, uint256 indexed traddingTime, uint256 first, uint256 second, uint256 three, uint256 gameid, uint256 buyType, uint buyTotal,uint256 buyPrice);
  event BuyWinnerList(uint256 indexed first, uint256 indexed second, uint256  indexed third,address  buyer, uint256  traddingTime, uint256 gameid, uint256 buyType, uint buyTotal,uint256 buyPrice);
  event BuyWinnerTwo(address indexed buyer, uint256 indexed first, uint256 indexed gameid,uint256 traddingTime, uint256 buyType,uint256 buyPrice,uint buyTotal);
  event ShareBonus(address indexed buyer, uint256 indexed traddingTime, uint256 indexed buyerType, uint256 gameID, uint256 remainingAmount);

  address public owner;

	uint[] _teamIDs;

    struct Game{
      uint256 _bouns;
	    uint[] _teams;
	    uint256[] _teamPrice;
	    uint _playType;
	    bool _stop;
		  uint256 _beginTime;
    }
    Game[] public games;

    constructor() public {
	    owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function createGame(uint[] _teams, uint256[] _tPrice, uint _gameType,uint256 _beginTime) public onlyOwner {
		Game memory _game = Game({
        _bouns: 0,
		    _teams: _teams,
		    _teamPrice: _tPrice,
        _playType: _gameType,
		    _stop: true,
			_beginTime:_beginTime
        });
        games.push(_game);
    }

    function setTeamPrice(uint[] _teams, uint256[] _tPrice, uint gameID) public onlyOwner {
        games[gameID]._teams = _teams;
		    games[gameID]._teamPrice = _tPrice;
    }

	  function setTeamStatus(bool bstop, uint gameID) public onlyOwner {
        games[gameID]._stop = bstop;
    }

    function destroy() public onlyOwner {
	    selfdestruct(owner);
    }

    function shareAmount(address winner, uint256 amount, uint256 _buyerType, uint _gameID) public onlyOwner {
	    require(address(this).balance>=amount);
	    winner.transfer(amount);
	    emit ShareBonus(winner, uint256(now), _buyerType, _gameID, amount);
    }
    function batchShareAmount(address[] winner, uint256[] amount, uint256 _gameID,uint256 _buyerType,uint256 amount_total) public onlyOwner {
     require(address(this).balance>=amount_total);
     for(uint i=0; i<winner.length; i++){
      winner[i].transfer(amount[i]);
         emit ShareBonus(winner[i], uint256(now), _buyerType, _gameID, amount[i]);
         }
    }

	function getListTeamByPlayType(uint _gameType) public view returns (uint[] teamIDss){
		_teamIDs = [0];
		for(uint i=0; i<games.length; i++)
	    {
		    if(games[i]._playType == _gameType){
		        _teamIDs.push(i);
		    }
	    }
		teamIDss = _teamIDs;
    }

    function getListTeam(uint _gameID) public view returns (uint256 _bouns,
	    uint[] _teams,
	    uint256[] _teamPrice,

	    uint _playType,
	    bool _stop,
		uint256 _beginTime){
		_bouns = games[_gameID]._bouns;
		_teams = games[_gameID]._teams;
		_teamPrice = games[_gameID]._teamPrice;
		_playType = games[_gameID]._playType;
		_stop = games[_gameID]._stop;
		_beginTime = games[_gameID]._beginTime;
    }

	function getPool(uint _gameID) public view returns (uint256 bounsp){
	    return games[_gameID]._bouns;
    }

    function buy(uint256 _gameID, uint256 _one, uint256 _two, uint256 _three, uint256 _buyCount,uint256 buyPrice) payable public{
	    //require(games[_gameID]._stop);
      uint256 totalPrice = (games[_gameID]._teamPrice[_one.sub(100)].add(games[_gameID]._teamPrice[_two.sub(100)]).add(games[_gameID]._teamPrice[_three.sub(100)])).mul(_buyCount);
      totalPrice = totalPrice.add(totalPrice.div(20)) ;
	    require(msg.value >= totalPrice);

	    emit BuyWinner(msg.sender, uint256(now),_one, _two, _three, _gameID, games[_gameID]._playType, _buyCount, buyPrice);
      emit BuyWinnerList(_one, _two, _three,msg.sender, uint256(now), _gameID, games[_gameID]._playType, _buyCount, buyPrice);
	    owner.transfer(msg.value.div(20));
	    games[_gameID]._bouns = games[_gameID]._bouns.add(msg.value);
    }

	function buyTwo(uint256 _one, uint256 _gameID, uint256 _buyCount,uint256 _buyPrice) payable public{
	    //require(games[_gameID]._stop);
	    require(msg.value >= ((games[_gameID]._teamPrice[_one].mul(_buyCount)).add(games[_gameID]._teamPrice[_one]).mul(_buyCount).div(20)));
      owner.transfer(msg.value.div(20));
		  emit BuyWinnerTwo(msg.sender, games[_gameID]._teams[_one], _gameID,uint256(now), games[_gameID]._playType,_buyPrice, _buyCount);
	    games[_gameID]._bouns = games[_gameID]._bouns.add(msg.value);
    }

    function getBonusPoolTotal() public view returns (uint256) {
        return this.balance;
 }
}