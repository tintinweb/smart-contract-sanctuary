library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c>= a);
        return c;
    }
    function compare(uint256 a, uint256 b) internal pure returns (bool) {
        if ( a > b ) return true;
        return false;
    }
    function random(uint256 _limitN) internal view returns (uint8) {
        return uint8(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, now)))%_limitN);
    }
    function minOfArray(uint256[] _arr) internal pure returns (uint256) {
        uint256 _min = 0;
        if (_arr.length==0) return _min;
        _min = _arr[0];
        for(uint8 i=1;i<_arr.length;i++) {
            if ( _min > _arr[i] ) _min = _arr[i];
        }
        return _min;
    }
    function maxOfArray(uint256[] _arr) internal pure returns (uint256) {
        uint256 _max = 0;
        if (_arr.length==0) return _max;
        _max = _arr[0];
        for(uint8 i=1;i<_arr.length;i++) {
            if ( _max < _arr[i] ) _max = _arr[i];
        }
        return _max;
    }
}
contract Mooncases {
    address private admin;
    uint256 private rate;
    uint256 minFunds = 0.001 ether;
    struct Battle {
        uint8 playerNumber;
        uint256[] caseList;
        address[] joinedPlayers;
        uint256[] gameCaseList;
        uint256 gamePrice;
        address battleCreator;
    }
    
    mapping( string => Battle ) private battleList;
    
    /**
        Event Handler List
    **/
    event onCreateBattle(string battleCode, string resultMsg);
    event onCancelBattle(string battleCode, string resultMsg);
    event onJoinNewPlayerInBattle(string battleCode, address playerAddr);
    event onJoinOutPlayInBattle(string battleCode, string result );
    event onGenerateCase(string _battleCode, uint8 caseIndex, address[] players, uint256[] cases);
    event onFinishBattle(string _battleCode, string result);
    
    constructor() public {
        admin = msg.sender;
        rate = 2;
    }
    modifier onlyAdmin() {
        require( msg.sender==admin );
        _;
    }
    /***
    * public function list
    ***/
    function changeAdmin( address _newAdmin ) public onlyAdmin {
        admin = _newAdmin;
    }
    function changeRate( uint256 _rate ) public onlyAdmin {
        rate = _rate;
    }
    function changeMinFunds( uint256 _minFunds ) public onlyAdmin {
        minFunds = _minFunds;
    }
    function getBattle(string _battleCode) public view returns(uint8, uint256[], address[], uint256[], uint256, address) {
        require(isExistingBattle(_battleCode));
        Battle memory _battle = battleList[_battleCode];
        return (_battle.playerNumber, _battle.caseList, _battle.joinedPlayers, _battle.gameCaseList, _battle.gamePrice, _battle.battleCreator);
    }
    function createNewGame(string _battleCode, uint8 _playerNumber, uint256[] _caseList, uint256[] _gameCaseList) public payable {
        require( msg.sender == address(0) || msg.sender == admin );
        require( moreMinFunds((uint256(msg.value))) );
        require(isNewBattle(_battleCode));
        address[] memory _joinedPlayers = new address[](0);
        _joinedPlayers[0] = msg.sender;
        Battle memory _battle = Battle({playerNumber: _playerNumber, caseList: _caseList, joinedPlayers: _joinedPlayers, 
        gameCaseList: _gameCaseList, gamePrice: msg.value, battleCreator: msg.sender });
        battleList[_battleCode] = _battle;
        admin.transfer(msg.value);
        emit onCreateBattle(_battleCode, &#39;Started&#39;);
    }
    function joinBattle( string _battleCode ) public payable {
        require(isExistingBattle(_battleCode));
        require(isNewPlayerInBattle(_battleCode, msg.sender));
        require( moreMinFunds((uint256(msg.value))) );
        Battle memory _battle = battleList[_battleCode];
        _battle.joinedPlayers[_battle.joinedPlayers.length] = msg.sender;
        emit onJoinNewPlayerInBattle(_battleCode, msg.sender);
        admin.transfer(msg.value);
    }
    function cancelGame( string _battleCode ) public {
        require(isBattleCreator(_battleCode, msg.sender));
        Battle memory _battle = battleList[_battleCode];
        for( uint8 i = 0; i < uint8(_battle.joinedPlayers.length); i++ ) {
            _battle.joinedPlayers[i].transfer(_battle.gamePrice);  // Refunds to all players
        }
        // delete battle item from battle list
        delete _battle;
        delete battleList[_battleCode];
        emit onCancelBattle(_battleCode, &#39;Canceled&#39;);
    }
    function joinOutBattle( string _battleCode ) public {
        require(isExistingBattle(_battleCode));
        require(isExistingPlayerInBattle(_battleCode, msg.sender));
        Battle memory _battle = battleList[_battleCode];
        
        for( uint8 i = 0; i < uint8(_battle.joinedPlayers.length); i++ ) {
            if ( _battle.joinedPlayers[i] == msg.sender ) {
                msg.sender.transfer(_battle.gamePrice);
                delete _battle.joinedPlayers[i];
                emit onJoinOutPlayInBattle(_battleCode, &#39;success&#39;);
            }
        }
        emit onJoinOutPlayInBattle(_battleCode, &#39;failed&#39;);
    }
    function startBattle(string _battleCode) public returns(bool){
        require(isExistingBattle(_battleCode));
        require(enableStartBattle(_battleCode));
        Battle memory _battle = battleList[_battleCode];
        uint256[] memory totalBattlePrice = new uint256[](_battle.caseList.length);
        uint8 i;
        uint8 j;
        for( i = 0; i < uint8(_battle.joinedPlayers.length); i++ ) {
            totalBattlePrice[i] = 0;
        }
        for( i = 0; i < uint8(_battle.caseList.length); i++ ) {
            uint256[] memory _cases = new uint256[](_battle.caseList.length);
            for( j = 0; j < _battle.joinedPlayers.length; j++ ) {
                uint256 _randCase = getRandomCase(_battle.caseList[i], _battle.gameCaseList);
                totalBattlePrice[j] = SafeMath.add(totalBattlePrice[j], _randCase);
                _cases[j] = _randCase;
            }
            emit onGenerateCase(_battleCode, i, _battle.joinedPlayers, _cases );
        }
        // refunds to Winner
        address winnerPlayer = _battle.joinedPlayers[getWinner(totalBattlePrice)];
        uint256 winnerFunds = getWinnerFunds(totalBattlePrice);
        winnerPlayer.transfer(winnerFunds);
        delete battleList[_battleCode];  // Delete Battle from battle list.
        emit onFinishBattle(_battleCode, &#39;Finished&#39;);
        return true;
    }
    /***
    * private function list
    ***/
    function moreMinFunds(uint256 _funds) private view returns(bool) {
        if ( _funds >= minFunds ) return true;
        return false;
    }
    function isNewBattle(string _battleCode) private view returns(bool) {
        if ( battleList[_battleCode].battleCreator == address(0) ) return true;
        return false;
    }
    function isExistingBattle( string _battleCode) private view returns(bool) {
        if ( battleList[_battleCode].battleCreator == address(0) ) return false;
        return true;
    }
    function isBattleCreator(string _battleCode, address _addr) private view returns(bool) {
        if ( battleList[_battleCode].battleCreator == _addr ) return true;
        return false;
    }
    function isExistingPlayerInBattle(string _battleCode, address _addr) private view returns(bool) {
        for( uint8 i = 0; i < uint8(battleList[_battleCode].joinedPlayers.length); i++ ) {
            if ( battleList[_battleCode].joinedPlayers[i] == _addr ) return true;
        }
        return false;
    }
    function isNewPlayerInBattle(string _battleCode, address _addr) private view returns(bool) {
        for( uint8 i = 0; i < uint8(battleList[_battleCode].joinedPlayers.length); i++ ) {
            if ( battleList[_battleCode].joinedPlayers[i] == _addr ) return false;
        }
        return true;
    }
    function enableStartBattle(string _battleCode) private view returns (bool) {
        if (battleList[_battleCode].joinedPlayers.length>1) return true;
        return false;
    }
    function getRandomCase(uint256 _baseCaseItem, uint256[] _gameCaseList) private view returns(uint256) {
        uint8 n = 0;
        uint256 randomCase = SafeMath.minOfArray(_gameCaseList);
        for(n = 0; n < _gameCaseList.length; n++) {
            randomCase = _gameCaseList[SafeMath.random(uint8(_gameCaseList.length))];
            if ( SafeMath.compare(randomCase, SafeMath.mul(_baseCaseItem, rate) ) ) {
                continue;
            }
            else {
                return randomCase;
            }
        }
        return randomCase;
    }
    function getWinner(uint256[] _totalBattlePriceArray) private pure returns(uint8) {
        uint256 winnerPrice = SafeMath.maxOfArray(_totalBattlePriceArray);
        for(uint8 i=0;i<(uint8(_totalBattlePriceArray.length));i++) {
            if ( _totalBattlePriceArray[i] == winnerPrice ) return i;
        }
    }
    function getWinnerFunds(uint256[] _totalBattlePriceArray) private pure returns(uint256) {
        uint256 winnerFunds = 0;
        for(uint8 i=0;i<(uint8(_totalBattlePriceArray.length));i++) {
            winnerFunds = SafeMath.add(winnerFunds, _totalBattlePriceArray[i]);
        }
        return winnerFunds;
    }
}