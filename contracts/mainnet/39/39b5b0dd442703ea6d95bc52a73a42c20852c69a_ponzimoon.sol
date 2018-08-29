pragma solidity ^0.4.24;

contract owned {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    constructor() public {
        owner = msg.sender;
    }


    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

/// @title PONZIMOON
contract ponzimoon is owned {

    using SafeMath for uint256;


    Spaceship[] spaceships;
    Player[] players;
    mapping(address => uint256) addressMPid;
    mapping(uint256 => address) pidXAddress;
    mapping(string => uint256) nameXPid;
    uint256 playerCount;
    uint256 totalTicketCount;
    uint256 airdropPrizePool;
    uint256 moonPrizePool;
    uint256 lotteryTime;
    uint256 editPlayerNamePrice = 0.01 ether;
    uint256 spaceshipPrice = 0.01 ether;
    uint256 addSpaceshipPrice = 0.00000001 ether;
    address maxAirDropAddress;
    uint256 maxTotalTicket;
    uint256 round;
    uint256 totalDividendEarnings;
    uint256 totalEarnings;
    uint256 luckyPayerId;


    struct Spaceship {
        uint256 id;
        string name;
        uint256 speed;
        address captain;
        uint256 ticketCount;
        uint256 dividendRatio;
        uint256 spaceshipPrice;
        uint256 addSpeed;
    }
    struct Player {
        address addr;
        string name;
        uint256 earnings;
        uint256 ticketCount;
        uint256 dividendRatio;
        uint256 distributionEarnings;
        uint256 dividendEarnings;
        uint256 withdrawalAmount;
        uint256 parentId;
        uint256 dlTicketCount;
        uint256 xzTicketCount;
        uint256 jcTicketCount;
    }

    constructor() public {
        lotteryTime = now + 12 hours;
        round = 1;

        spaceships.push(Spaceship(0, "dalao", 100000, msg.sender, 0, 20, 15 ether, 2));
        spaceships.push(Spaceship(1, "xiaozhuang", 100000, msg.sender, 0, 50, 15 ether, 5));
        spaceships.push(Spaceship(2, "jiucai", 100000, msg.sender, 0, 80, 15 ether, 8));

        uint256 playerArrayIndex = players.push(Player(msg.sender, "system", 0, 0, 3, 0, 0, 0, 0, 0, 0, 0));
        addressMPid[msg.sender] = playerArrayIndex;
        pidXAddress[playerArrayIndex] = msg.sender;
        playerCount = players.length;
        nameXPid["system"] = playerArrayIndex;
    }

    function getSpaceship(uint256 _spaceshipId) public view returns (
        uint256 _id,
        string _name,
        uint256 _speed,
        address _captain,
        uint256 _ticketCount,
        uint256 _dividendRatio,
        uint256 _spaceshipPrice
    ){
        _id = spaceships[_spaceshipId].id;
        _name = spaceships[_spaceshipId].name;
        _speed = spaceships[_spaceshipId].speed;
        _captain = spaceships[_spaceshipId].captain;
        _ticketCount = spaceships[_spaceshipId].ticketCount;
        _dividendRatio = spaceships[_spaceshipId].dividendRatio;
        _spaceshipPrice = spaceships[_spaceshipId].spaceshipPrice;
    }
    function getNowTime() public view returns (uint256){
        return now;
    }

    function checkName(string _name) public view returns (bool){
        if (nameXPid[_name] == 0) {
            return false;
        }
        return true;
    }

    function setYxName(address _address, string _name) external onlyOwner {
        if (addressMPid[_address] == 0) {
            uint256 playerArrayIndex = players.push(Player(_address, _name, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0));
            addressMPid[_address] = playerArrayIndex;
            pidXAddress[playerArrayIndex] = _address;
            playerCount = players.length;
            nameXPid[_name] = playerArrayIndex;
        } else {
            uint256 _pid = addressMPid[_address];
            Player storage _p = players[_pid.sub(1)];
            _p.name = _name;
            nameXPid[_name] = _pid;
        }
    }

    function setName(string _name) external payable {
        require(msg.value >= editPlayerNamePrice);
        if (addressMPid[msg.sender] == 0) {
            uint256 playerArrayIndex = players.push(Player(msg.sender, _name, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0));
            addressMPid[msg.sender] = playerArrayIndex;
            pidXAddress[playerArrayIndex] = msg.sender;
            playerCount = players.length;
            nameXPid[_name] = playerArrayIndex;
        } else {
            uint256 _pid = addressMPid[msg.sender];
            Player storage _p = players[_pid.sub(1)];
            _p.name = _name;
            nameXPid[_name] = _pid;

        }
        Player storage _sysP = players[0];
        _sysP.earnings = _sysP.earnings.add(msg.value);
        _sysP.distributionEarnings = _sysP.distributionEarnings.add(msg.value);
    }

    function _computePayMoney(uint256 _ticketCount, address _addr) private view returns (bool){
        uint256 _initMoney = 0.01 ether;
        uint256 _eachMoney = 0.0001 ether;
        uint256 _payMoney = (spaceshipPrice.mul(_ticketCount)).add(addSpaceshipPrice.mul((_ticketCount.sub(1))));
        _payMoney = _payMoney.sub((_eachMoney.mul(_ticketCount)));
        uint256 _tmpPid = addressMPid[_addr];
        Player memory _p = players[_tmpPid.sub(1)];
        if (_p.earnings >= (_initMoney.mul(_ticketCount)) && _p.earnings >= _payMoney) {
            return true;
        }
        return false;
    }

    function checkTicket(uint256 _ticketCount, uint256 _money) private view returns (bool){
        uint256 _initMoney = 0.01 ether;
        uint256 _eachMoney = 0.0001 ether;
        uint256 _payMoney = (spaceshipPrice.mul(_ticketCount)).add(addSpaceshipPrice.mul((_ticketCount.sub(1))));
        _payMoney = _payMoney.sub((_eachMoney.mul(_ticketCount)));
        if (_money >= (_initMoney.mul(_ticketCount)) && _money >= _payMoney) {
            return true;
        }
        return false;


    }

    function checkNewPlayer(address _player) private {
        if (addressMPid[_player] == 0) {
            uint256 playerArrayIndex = players.push(Player(_player, "", 0, 0, 0, 0, 0, 0, 0, 0, 0, 0));
            addressMPid[_player] = playerArrayIndex;
            pidXAddress[playerArrayIndex] = _player;
            playerCount = players.length;
        }
    }

    function addTicket(uint256 _ticketCount, uint256 _spaceshipNo, uint256 _pid) private {
        spaceshipPrice = spaceshipPrice.add(addSpaceshipPrice.mul(_ticketCount));

        totalTicketCount = totalTicketCount.add(_ticketCount);
        Player storage _p = players[_pid.sub(1)];
        _p.ticketCount = _p.ticketCount.add(_ticketCount);
        if (_spaceshipNo == 0) {
            _p.dlTicketCount = _p.dlTicketCount.add(_ticketCount);
            Spaceship storage _s = spaceships[0];
            _s.ticketCount = _s.ticketCount.add(_ticketCount);
            _s.speed = _s.speed.add(_ticketCount.mul(_s.addSpeed));

        }
        if (_spaceshipNo == 1) {
            _p.xzTicketCount = _p.xzTicketCount.add(_ticketCount);
            Spaceship storage _s1 = spaceships[1];
            _s1.ticketCount = _s1.ticketCount.add(_ticketCount);
            _s1.speed = _s1.speed.add(_ticketCount.mul(_s1.addSpeed));
        }
        if (_spaceshipNo == 2) {
            _p.jcTicketCount = _p.jcTicketCount.add(_ticketCount);
            Spaceship storage _s2 = spaceships[2];
            _s2.ticketCount = _s2.ticketCount.add(_ticketCount);
            _s2.speed = _s2.speed.add(_ticketCount.mul(_s2.addSpeed));
        }
    }


    function _payTicketByEarnings(uint256 _ticketCount, address _addr) private returns (uint256){
        uint256 _tmpPid = addressMPid[_addr];
        Player storage _p = players[_tmpPid.sub(1)];
        uint256 _tmpMoney = spaceshipPrice.mul(_ticketCount);
        uint256 _tmpMoney2 = addSpaceshipPrice.mul(_ticketCount.sub(1));
        uint256 _returnMoney = _tmpMoney.add(_tmpMoney2);
        _p.earnings = _p.earnings.sub(_returnMoney);
        return _returnMoney;
    }


    function buyTicketByEarnings(uint256 _ticketCount, uint256 _spaceshipNo, string _name) external {
        require(now < lotteryTime);
        require(_spaceshipNo == 0 || _spaceshipNo == 1 || _spaceshipNo == 2);
        require(addressMPid[msg.sender] != 0);
        require(_computePayMoney(_ticketCount, msg.sender));
        updateTime();
        uint256 _money = _payTicketByEarnings(_ticketCount, msg.sender);


        totalEarnings = totalEarnings.add(_money);

        Player storage _p = players[addressMPid[msg.sender].sub(1)];
        if (_p.parentId == 0 && nameXPid[_name] != 0) {
            _p.parentId = nameXPid[_name];
        }
        luckyPayerId = addressMPid[msg.sender];

        addTicket(_ticketCount, _spaceshipNo, addressMPid[msg.sender]);


        addSpaceshipMoney(_money.div(100).mul(1));

        Player storage _player = players[0];
        uint256 _SysMoney = _money.div(100).mul(5);
        _player.earnings = _player.earnings.add(_SysMoney);
        _player.dividendEarnings = _player.dividendEarnings.add(_SysMoney);


        uint256 _distributionMoney = _money.div(100).mul(10);
        if (_p.parentId == 0) {
            _player.earnings = _player.earnings.add(_distributionMoney);
            _player.distributionEarnings = _player.distributionEarnings.add(_distributionMoney);
        } else {
            Player storage _player_ = players[_p.parentId.sub(1)];
            _player_.earnings = _player_.earnings.add(_distributionMoney);
            _player_.distributionEarnings = _player_.distributionEarnings.add(_distributionMoney);
        }
        if (_ticketCount > maxTotalTicket) {
            maxTotalTicket = _ticketCount;
            maxAirDropAddress = msg.sender;
        }

        uint256 _airDropMoney = _money.div(100).mul(2);
        airdropPrizePool = airdropPrizePool.add(_airDropMoney);
        if (airdropPrizePool >= 1 ether) {
            Player storage _playerAirdrop = players[addressMPid[maxAirDropAddress].sub(1)];
            _playerAirdrop.earnings = _playerAirdrop.earnings.add(airdropPrizePool);
            _playerAirdrop.dividendEarnings = _playerAirdrop.dividendEarnings.add(airdropPrizePool);
            airdropPrizePool = 0;
        }

        uint256 _remainderMoney = _cMoney(_money, _SysMoney, _distributionMoney, _airDropMoney);

        updateGameMoney(_remainderMoney, _spaceshipNo, _ticketCount, addressMPid[msg.sender].sub(1));
    }

    function _cMoney(uint256 _money, uint256 _SysMoney, uint256 _distributionMoney, uint256 _airDropMoney)
    private pure returns (uint256){
        uint256 _czSpaceshipMoney = _money.div(100).mul(1).mul(3);
        return _money.sub(_czSpaceshipMoney).sub(_SysMoney).
        sub(_distributionMoney).sub(_airDropMoney);
    }

    function updateTime() private {
        if (totalTicketCount < 50000) {
            lotteryTime = now + 12 hours;

        } else {
            lotteryTime = now + 1 hours;
        }
    }


    function buyTicket(uint256 _ticketCount, uint256 _spaceshipNo, string _name) external payable {
        require(now < lotteryTime);
        require(_spaceshipNo == 0 || _spaceshipNo == 1 || _spaceshipNo == 2);
        require(checkTicket(_ticketCount, msg.value));
        checkNewPlayer(msg.sender);
        updateTime();
        totalEarnings = totalEarnings.add(msg.value);

        Player storage _p = players[addressMPid[msg.sender].sub(1)];
        if (_p.parentId == 0 && nameXPid[_name] != 0) {
            _p.parentId = nameXPid[_name];
        }
        luckyPayerId = addressMPid[msg.sender];
        addTicket(_ticketCount, _spaceshipNo, addressMPid[msg.sender]);


        addSpaceshipMoney(msg.value.div(100).mul(1));

        Player storage _player = players[0];
        uint256 _SysMoney = msg.value.div(100).mul(5);
        _player.earnings = _player.earnings.add(_SysMoney);
        _player.dividendEarnings = _player.dividendEarnings.add(_SysMoney);


        uint256 _distributionMoney = msg.value.div(100).mul(10);
        if (_p.parentId == 0) {
            _player.earnings = _player.earnings.add(_distributionMoney);
            _player.distributionEarnings = _player.distributionEarnings.add(_distributionMoney);
        } else {
            Player storage _player_ = players[_p.parentId.sub(1)];
            _player_.earnings = _player_.earnings.add(_distributionMoney);
            _player_.distributionEarnings = _player_.distributionEarnings.add(_distributionMoney);
        }
        if (_ticketCount > maxTotalTicket) {
            maxTotalTicket = _ticketCount;
            maxAirDropAddress = msg.sender;
        }

        uint256 _airDropMoney = msg.value.div(100).mul(2);
        airdropPrizePool = airdropPrizePool.add(_airDropMoney);
        if (airdropPrizePool >= 1 ether) {
            Player storage _playerAirdrop = players[addressMPid[maxAirDropAddress].sub(1)];
            _playerAirdrop.earnings = _playerAirdrop.earnings.add(airdropPrizePool);
            _playerAirdrop.dividendEarnings = _playerAirdrop.dividendEarnings.add(airdropPrizePool);
            airdropPrizePool = 0;
        }

        uint256 _remainderMoney = msg.value.sub((msg.value.div(100).mul(1)).mul(3)).sub(_SysMoney).
        sub(_distributionMoney).sub(_airDropMoney);

        updateGameMoney(_remainderMoney, _spaceshipNo, _ticketCount, addressMPid[msg.sender].sub(1));


    }

    function getFhMoney(uint256 _spaceshipNo, uint256 _money, uint256 _ticketCount, uint256 _targetNo) private view returns (uint256){
        Spaceship memory _fc = spaceships[_spaceshipNo];
        if (_spaceshipNo == _targetNo) {
            uint256 _Ticket = _fc.ticketCount.sub(_ticketCount);
            if (_Ticket == 0) {
                return 0;
            }
            return _money.div(_Ticket);
        } else {
            if (_fc.ticketCount == 0) {
                return 0;
            }
            return _money.div(_fc.ticketCount);
        }
    }

    function updateGameMoney(uint256 _money, uint256 _spaceshipNo, uint256 _ticketCount, uint256 _arrayPid) private {
        uint256 _lastMoney = addMoonPrizePool(_money, _spaceshipNo);
        uint256 _dlMoney = _lastMoney.div(100).mul(53);
        uint256 _xzMoney = _lastMoney.div(100).mul(33);
        uint256 _jcMoney = _lastMoney.sub(_dlMoney).sub(_xzMoney);
        uint256 _dlFMoney = getFhMoney(0, _dlMoney, _ticketCount, _spaceshipNo);
        uint256 _xzFMoney = getFhMoney(1, _xzMoney, _ticketCount, _spaceshipNo);
        uint256 _jcFMoney = getFhMoney(2, _jcMoney, _ticketCount, _spaceshipNo);
        _fhMoney(_dlFMoney, _xzFMoney, _jcFMoney, _arrayPid, _spaceshipNo, _ticketCount);

    }

    function _fhMoney(uint256 _dlFMoney, uint256 _xzFMoney, uint256 _jcFMoney, uint256 arrayPid, uint256 _spaceshipNo, uint256 _ticketCount) private {
        for (uint i = 0; i < players.length; i++) {
            Player storage _tmpP = players[i];
            uint256 _totalMoney = 0;
            if (arrayPid != i) {
                _totalMoney = _totalMoney.add(_tmpP.dlTicketCount.mul(_dlFMoney));
                _totalMoney = _totalMoney.add(_tmpP.xzTicketCount.mul(_xzFMoney));
                _totalMoney = _totalMoney.add(_tmpP.jcTicketCount.mul(_jcFMoney));
            } else {
                if (_spaceshipNo == 0) {
                    _totalMoney = _totalMoney.add((_tmpP.dlTicketCount.sub(_ticketCount)).mul(_dlFMoney));
                } else {
                    _totalMoney = _totalMoney.add(_tmpP.dlTicketCount.mul(_dlFMoney));
                }
                if (_spaceshipNo == 1) {
                    _totalMoney = _totalMoney.add((_tmpP.xzTicketCount.sub(_ticketCount)).mul(_xzFMoney));
                } else {
                    _totalMoney = _totalMoney.add(_tmpP.xzTicketCount.mul(_xzFMoney));
                }
                if (_spaceshipNo == 2) {
                    _totalMoney = _totalMoney.add((_tmpP.jcTicketCount.sub(_ticketCount)).mul(_jcFMoney));
                } else {
                    _totalMoney = _totalMoney.add(_tmpP.jcTicketCount.mul(_jcFMoney));
                }
            }
            _tmpP.earnings = _tmpP.earnings.add(_totalMoney);
            _tmpP.dividendEarnings = _tmpP.dividendEarnings.add(_totalMoney);
        }
    }

    function addMoonPrizePool(uint256 _money, uint256 _spaceshipNo) private returns (uint){
        uint256 _tmpMoney;
        if (_spaceshipNo == 0) {
            _tmpMoney = _money.div(100).mul(80);
            totalDividendEarnings = totalDividendEarnings.add((_money.sub(_tmpMoney)));
        }
        if (_spaceshipNo == 1) {
            _tmpMoney = _money.div(100).mul(50);
            totalDividendEarnings = totalDividendEarnings.add((_money.sub(_tmpMoney)));
        }
        if (_spaceshipNo == 2) {
            _tmpMoney = _money.div(100).mul(20);
            totalDividendEarnings = totalDividendEarnings.add((_money.sub(_tmpMoney)));
        }
        moonPrizePool = moonPrizePool.add(_tmpMoney);
        return _money.sub(_tmpMoney);
    }



    function addSpaceshipMoney(uint256 _money) internal {
        Spaceship storage _spaceship0 = spaceships[0];
        uint256 _pid0 = addressMPid[_spaceship0.captain];
        Player storage _player0 = players[_pid0.sub(1)];
        _player0.earnings = _player0.earnings.add(_money);
        _player0.dividendEarnings = _player0.dividendEarnings.add(_money);


        Spaceship storage _spaceship1 = spaceships[1];
        uint256 _pid1 = addressMPid[_spaceship1.captain];
        Player storage _player1 = players[_pid1.sub(1)];
        _player1.earnings = _player1.earnings.add(_money);
        _player1.dividendEarnings = _player1.dividendEarnings.add(_money);



        Spaceship storage _spaceship2 = spaceships[2];
        uint256 _pid2 = addressMPid[_spaceship2.captain];
        Player storage _player2 = players[_pid2.sub(1)];
        _player2.earnings = _player2.earnings.add(_money);
        _player2.dividendEarnings = _player2.dividendEarnings.add(_money);


    }

    function getPlayerInfo(address _playerAddress) public view returns (
        address _addr,
        string _name,
        uint256 _earnings,
        uint256 _ticketCount,
        uint256 _dividendEarnings,
        uint256 _distributionEarnings,
        uint256 _dlTicketCount,
        uint256 _xzTicketCount,
        uint256 _jcTicketCount
    ){
        uint256 _pid = addressMPid[_playerAddress];
        Player storage _player = players[_pid.sub(1)];
        _addr = _player.addr;
        _name = _player.name;
        _earnings = _player.earnings;
        _ticketCount = _player.ticketCount;
        _dividendEarnings = _player.dividendEarnings;
        _distributionEarnings = _player.distributionEarnings;
        _dlTicketCount = _player.dlTicketCount;
        _xzTicketCount = _player.xzTicketCount;
        _jcTicketCount = _player.jcTicketCount;
    }

    function addSystemUserEarnings(uint256 _money) private {
        Player storage _player = players[0];
        _player.earnings = _player.earnings.add(_money);
    }

    function withdraw() public {
        require(addressMPid[msg.sender] != 0);
        Player storage _player = players[addressMPid[msg.sender].sub(1)];
        _player.addr.transfer(_player.earnings);
        _player.withdrawalAmount = _player.withdrawalAmount.add(_player.earnings);
        _player.earnings = 0;
        _player.distributionEarnings = 0;
        _player.dividendEarnings = 0;
    }

    function makeMoney() public {
        require(now > lotteryTime);
        uint256 _pMoney = moonPrizePool.div(2);
        Player storage _luckyPayer = players[luckyPayerId.sub(1)];
        _luckyPayer.earnings = _luckyPayer.earnings.add(_pMoney);
        uint256 _nextMoonPrizePool = moonPrizePool.div(100).mul(2);
        uint256 _luckyCaptainMoney = moonPrizePool.div(100).mul(5);
        uint256 _luckyCrewMoney = moonPrizePool.sub(_nextMoonPrizePool).sub(_luckyCaptainMoney).sub(_pMoney);
        uint256 _no1Spaceship = getFastestSpaceship();
        Spaceship storage _s = spaceships[_no1Spaceship];
        uint256 _pid = addressMPid[_s.captain];
        Player storage _pPayer = players[_pid.sub(1)];
        _pPayer.earnings = _pPayer.earnings.add(_luckyCaptainMoney);

        uint256 _eachMoney = _getLuckySpaceshipMoney(_no1Spaceship, _luckyCrewMoney);
        for (uint i = 0; i < players.length; i++) {
            Player storage _tmpP = players[i];
            if (_no1Spaceship == 0) {
                _tmpP.earnings = _tmpP.earnings.add(_tmpP.dlTicketCount.mul(_eachMoney));
                _tmpP.dividendEarnings = _tmpP.dividendEarnings.add(_tmpP.dlTicketCount.mul(_eachMoney));
            }
            if (_no1Spaceship == 1) {
                _tmpP.earnings = _tmpP.earnings.add(_tmpP.xzTicketCount.mul(_eachMoney));
                _tmpP.dividendEarnings = _tmpP.dividendEarnings.add(_tmpP.xzTicketCount.mul(_eachMoney));
            }
            if (_no1Spaceship == 2) {
                _tmpP.earnings = _tmpP.earnings.add(_tmpP.jcTicketCount.mul(_eachMoney));
                _tmpP.dividendEarnings = _tmpP.dividendEarnings.add(_tmpP.jcTicketCount.mul(_eachMoney));
            }
            _tmpP.dlTicketCount = 0;
            _tmpP.xzTicketCount = 0;
            _tmpP.jcTicketCount = 0;
            _tmpP.ticketCount = 0;
        }
        _initSpaceship();
        totalTicketCount = 0;
        airdropPrizePool = 0;
        moonPrizePool = _nextMoonPrizePool;
        lotteryTime = now + 12 hours;
        spaceshipPrice = 0.01 ether;
        maxAirDropAddress = pidXAddress[1];
        maxTotalTicket = 0;
        round = round.add(1);
        luckyPayerId = 1;
    }

    function _initSpaceship() private {
        for (uint i = 0; i < spaceships.length; i++) {
            Spaceship storage _s = spaceships[i];
            _s.captain = pidXAddress[1];
            _s.ticketCount = 0;
            _s.spaceshipPrice = 15 ether;
            _s.speed = 100000;
        }

    }

    function _getLuckySpaceshipMoney(uint256 _spaceshipId, uint256 _luckyMoney) private view returns (uint256){
        Spaceship memory _s = spaceships[_spaceshipId];
        uint256 _eachLuckyMoney = _luckyMoney.div(_s.ticketCount);
        return _eachLuckyMoney;

    }

    function getFastestSpaceship() private view returns (uint256){
        Spaceship memory _dlSpaceship = spaceships[0];
        Spaceship memory _xzSpaceship = spaceships[1];
        Spaceship memory _jcSpaceship = spaceships[2];

        uint256 _maxSpeed;
        if (_jcSpaceship.speed >= _xzSpaceship.speed) {
            if (_jcSpaceship.speed >= _dlSpaceship.speed) {
                _maxSpeed = 2;
            } else {
                _maxSpeed = 0;
            }
        } else {
            if (_xzSpaceship.speed >= _dlSpaceship.speed) {
                _maxSpeed = 1;
            } else {
                _maxSpeed = 0;
            }
        }
        return _maxSpeed;

    }

    function getGameInfo() public view returns (
        uint256 _totalTicketCount,
        uint256 _airdropPrizePool,
        uint256 _moonPrizePool,
        uint256 _lotteryTime,
        uint256 _nowTime,
        uint256 _spaceshipPrice,
        uint256 _round,
        uint256 _totalEarnings,
        uint256 _totalDividendEarnings
    ){
        _totalTicketCount = totalTicketCount;
        _airdropPrizePool = airdropPrizePool;
        _moonPrizePool = moonPrizePool;
        _lotteryTime = lotteryTime;
        _nowTime = now;
        _spaceshipPrice = spaceshipPrice;
        _round = round;
        _totalEarnings = totalEarnings;
        _totalDividendEarnings = totalDividendEarnings;
    }

    function _updateSpaceshipPrice(uint256 _spaceshipId) internal {
        spaceships[_spaceshipId].spaceshipPrice = spaceships[_spaceshipId].spaceshipPrice.add(
            spaceships[_spaceshipId].spaceshipPrice.mul(3).div(10));
    }

    function campaignCaptain(uint _spaceshipId) external payable {
        require(now < lotteryTime);
        require(msg.value == spaceships[_spaceshipId].spaceshipPrice);
        if (addressMPid[msg.sender] == 0) {
            uint256 playerArrayIndex = players.push(Player(msg.sender, "", 0, 0, 0, 0, 0, 0, 0, 0, 0, 0));
            addressMPid[msg.sender] = playerArrayIndex;
            pidXAddress[playerArrayIndex] = msg.sender;
            playerCount = players.length;
        }
        spaceships[_spaceshipId].captain.transfer(msg.value);
        spaceships[_spaceshipId].captain = msg.sender;
        _updateSpaceshipPrice(_spaceshipId);
    }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (_a == 0) {
            return 0;
        }

        uint256 c = _a * _b;
        require(c / _a == _b);

        return c;
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b > 0);
        // Solidity only automatically asserts when dividing by 0
        uint256 c = _a / _b;
        // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b <= _a);
        uint256 c = _a - _b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a + _b;
        require(c >= _a);

        return c;
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}