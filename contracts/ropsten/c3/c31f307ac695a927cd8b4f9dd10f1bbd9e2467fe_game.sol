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
contract game is owned{

    using SafeMath for uint256;
    using Math for uint256;

    //3艘飞船
    Spaceship[] spaceships;
    //玩家集合
    Player[] players;
    //玩家地址映射
    mapping(address => uint256) addressMPid;
    mapping(uint256 => address) pidXAddress;
    mapping(string => uint256) nameXPid;
    //总玩家数
    uint256 playerCount;
    //总船票数
    uint256 totalTicketCount;
    //空投奖池 满1 ether 自动发放
    uint256 airdropPrizePool;
    //月球奖池 累计
    uint256 moonPrizePool;
    //开奖剩余时间
    uint256 lotteryTime;
    //修改name需要消耗的费用
    uint256 editPlayerNamePrice = 0.01 ether;
    //船票价格
    uint256 spaceshipPrice = 0.01 ether;
    //船票每次增加价格
    uint256 addSpaceshipPrice = 0.00000001 ether;
    //距上次空投开奖之后，单次购买船票最多的账户
    address maxAirDropAddress;
    //空投 => 计数
    uint256 maxTotalTicket;
    //游戏轮次
    uint256 round;
    //平台总分红
    uint256 totalDividendEarnings;
    //平台总流水
    uint256 totalEarnings;






    //飞船
    struct Spaceship {
        //飞船id
        uint256 id;
        //飞船名字
        string name;
        //速度
        uint256 speed;
        //舰长
        address captain;
        //船票数
        uint256 ticketCount;
        //分红比例
        uint256 dividendRatio;
        //舰长价格
        uint256 spaceshipPrice;
        //速度每次增加
        uint256 addSpeed;
    }
    //玩家
    struct Player {
        //玩家地址
        address addr;
        //玩家名称
        string name;
        //总收益
        uint256 earnings;
        //船票数
        uint256 ticketCount;
        //玩家分红权力比
        uint256 dividendRatio;
        //分销收益
        uint256 distributionEarnings;
        //分红收益
        uint256 dividendEarnings;
        //已提现金额
        uint256 withdrawalAmount;
        //分销上级账户id
        uint256 parentId;
        //购买各大飞船船票数
        uint256 dlTicketCount;
        uint256 xzTicketCount;
        uint256 jcTicketCount;
    }

    constructor() public {
        //初始化游戏合约
        //初始化开奖时间
        lotteryTime = now + 12 hours;
        round = 1;

        //初始化大佬飞船
        spaceships.push(Spaceship(0,"dalao",100000,msg.sender,0,20,10 ether,2));
        //初始化小庄飞船
        spaceships.push(Spaceship(1,"xiaozhuang",100000,msg.sender,0,50,10 ether,5));
        //初始化韭菜飞船
        spaceships.push(Spaceship(2,"jiucai",100000,msg.sender,0,80,10 ether,8));

        //初始化第一位玩家
        uint256 playerArrayIndex = players.push(Player(msg.sender,"system",0,0,3,0,0,0,0,0,0,0));
        addressMPid[msg.sender] = playerArrayIndex;
        pidXAddress[playerArrayIndex] = msg.sender;
        playerCount = players.length;
        nameXPid["system"] = playerArrayIndex;
    }

    /**
      * 获取飞船详情（飞船id）
      * id 飞船id
      * name 飞船名字
      * speed 速度
      * captain 船长
      * ticketCount 船票
      * dividendRatio 分红比例
      *
      */
    function getSpaceship(uint256 _spaceshipId) public view returns(
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
    /**
      * 获取以太坊当前时间戳
      */
    function getNowTime() public view returns(uint256){
        return now;
    }

    /**
      * 检测用户名是否存在
      */
    function checkName(string _name) public view returns(bool){
        if(nameXPid[_name] == 0 ){
            return false;
        }
        return true;
    }

    //设置用户名称
    function setName(string _name) external payable {
        require(msg.value >= editPlayerNamePrice);
        //查询玩家是不是新玩家
        if(addressMPid[msg.sender] == 0){
            //新玩家
            uint256 playerArrayIndex = players.push(Player(msg.sender,_name,0,0,0,0,0,0,0,0,0,0));
            addressMPid[msg.sender] = playerArrayIndex;
            pidXAddress[playerArrayIndex] = msg.sender;
            playerCount = players.length;
            nameXPid[_name] = playerArrayIndex;
        }else{
            uint256 _pid = addressMPid[msg.sender];
            Player storage _p = players[_pid.sub(1)];
            _p.name = _name;
            nameXPid[_name] = _pid;

        }
    }
    /**
      * 校验金额是否足以支付
      */
    function checkTicket(uint256 _ticketCount,uint256 _money) private view returns(bool){
        uint256 _tmpMoney = spaceshipPrice.mul(_ticketCount);
        uint256 _tmpMoney2 = addSpaceshipPrice.mul(_ticketCount.sub(1));
        if(_money >= _tmpMoney.add(_tmpMoney2)){
            return true;
        }
        return false;

    }

    //如果不是老玩家，添加玩家数据
    function checkNewPlayer(address _player) private {
        //校验玩家是否是new玩家
        if(addressMPid[_player] == 0){//新玩家
            //新增一位玩家
            uint256 playerArrayIndex = players.push(Player(_player,"",0,0,0,0,0,0,0,0,0,0));
            addressMPid[_player] = playerArrayIndex;
            pidXAddress[playerArrayIndex] = _player;
            playerCount = players.length;
        }
    }


    /*
     *  购买船票
     *  _ticketCount 船票数量
     *  _spaceshipNo 飞船编号
     */
    function buyTicket(uint256 _ticketCount,uint256 _spaceshipNo,string _name) external payable{
        require(_spaceshipNo ==0 || _spaceshipNo ==1 || _spaceshipNo == 2);
        //计算需要消耗多少 ether
        require(checkTicket(_ticketCount,msg.value));//正常支付
        checkNewPlayer(msg.sender);
        //计入总流水
        totalEarnings = totalEarnings.add(msg.value);

        Player storage _p = players[addressMPid[msg.sender].sub(1)];
        //分销进来的用户
        if(_p.parentId == 0 && nameXPid[_name] != 0 ){
            //绑定分销关系
            _p.parentId = nameXPid[_name];
        }
        //统计玩家船票
        _p.ticketCount = _p.ticketCount.add(_ticketCount);
        if(_spaceshipNo == 0){//大佬
            _p.dlTicketCount = _p.dlTicketCount.add(_ticketCount);
        }
        if(_spaceshipNo == 1){//小庄
            _p.xzTicketCount = _p.xzTicketCount.add(_ticketCount);
        }
        if(_spaceshipNo == 2){//韭菜
            _p.jcTicketCount = _p.jcTicketCount.add(_ticketCount);
        }

        //船长分红 每位船长 1%
        addSpaceshipMoney(msg.value.div(100).mul(1),_spaceshipNo,_ticketCount);

        //平台分红 5%
        Player storage _player = players[0];
        uint256 _SysMoney = msg.value.div(100).mul(5);
        _player.earnings = _player.earnings.add(_SysMoney);//增加总收入
        _player.dividendEarnings = _player.dividendEarnings.add(_SysMoney);//增加分红收入


        //查询是否有上级分销
        //分销奖励 10%
        uint256 _distributionMoney = msg.value.div(100).mul(10);
        if(_p.parentId == 0 ){
            //将分销奖励划入系统账户
            _player.earnings = _player.earnings.add(_distributionMoney);//增加总收入
            _player.distributionEarnings = _player.distributionEarnings.add(_distributionMoney);
        }else{
            //如果有上级分销
            Player storage _player_ = players[_p.parentId.sub(1)];
            _player_.earnings = _player_.earnings.add(_distributionMoney);//增加总收入
            _player_.distributionEarnings = _player_.distributionEarnings.add(_distributionMoney);
        }
        //这次购买是否是这段期间内购买船票最多的用户
        if(_ticketCount > maxTotalTicket){
            maxTotalTicket = _ticketCount;
            maxAirDropAddress = msg.sender;
        }

        //将2% 放入空投
        uint256 _airDropMoney = msg.value.div(100).mul(2);
        airdropPrizePool = airdropPrizePool.add(_airDropMoney);
        if(airdropPrizePool >= 1 ether){
            //空投开奖
            //赠送给这期间单次购买最多船票的用户
            Player storage _playerAirdrop = players[addressMPid[maxAirDropAddress].sub(1)];
            _playerAirdrop.earnings = _playerAirdrop.earnings.add(airdropPrizePool);//增加总收入
            _playerAirdrop.dividendEarnings = _playerAirdrop.dividendEarnings.add(airdropPrizePool);//增加分红收入
        }

        uint256 _remainderMoney = msg.value.sub((msg.value.div(100).mul(1)).mul(3)).sub(_SysMoney).
            sub(_distributionMoney).sub(_airDropMoney);

        //将剩余的钱用于分红和头奖
        updateGameMoney(_remainderMoney,_spaceshipNo,_ticketCount,addressMPid[msg.sender].sub(1));




    }

    //计算对应飞船每张船票分红
    function getFhMoney(uint256 _spaceshipNo,uint256 _money,uint256 _ticketCount,uint256 _targetNo) private view returns(uint256){
        Spaceship memory _fc =  spaceships[_spaceshipNo];
        //飞船总票数
        if(_spaceshipNo == _targetNo){
            uint256 _Ticket = _fc.ticketCount.sub(_ticketCount);
            return _money.div(_Ticket);
        }else{
            return _money.div(_fc.ticketCount);
        }
    }

    //消费剩余的
    function updateGameMoney(uint256 _money,uint256 _spaceshipNo,uint256 _ticketCount,uint256 arrayPid) private {
        uint256 _lastMoney = addMoonPrizePool(_money,_spaceshipNo);
        uint256 _dlMoney = _lastMoney.div(100).mul(53);
        uint256 _xzMoney = _lastMoney.div(100).mul(33);
        uint256 _jcMoney = _lastMoney.sub(_dlMoney).sub(_xzMoney);
        //大佬每张船票分红
        uint256 _dlFMoney = getFhMoney(0,_dlMoney,_ticketCount,_spaceshipNo);
        //小庄每张船票分红
        uint256 _xzFMoney = getFhMoney(1,_xzMoney,_ticketCount,_spaceshipNo);
        //韭菜每张船票分红
        uint256 _jcFMoney = getFhMoney(2,_jcMoney,_ticketCount,_spaceshipNo);
        for(uint i = 0; i<players.length; i++){
            if(arrayPid != i){
                //分红
                Player storage _tmpP = players[i];
                //大佬分红
                _tmpP.earnings =  _tmpP.earnings.add(_tmpP.dlTicketCount.mul(_dlFMoney));
                _tmpP.dividendEarnings = _tmpP.dividendEarnings.add(_tmpP.dlTicketCount.mul(_dlFMoney));
                //小庄分红
                _tmpP.earnings =  _tmpP.earnings.add(_tmpP.xzTicketCount.mul(_xzFMoney));
                _tmpP.dividendEarnings = _tmpP.dividendEarnings.add(_tmpP.dlTicketCount.mul(_dlFMoney));
                //韭菜分红
                _tmpP.earnings =  _tmpP.earnings.add(_tmpP.jcTicketCount.mul(_jcFMoney));
                _tmpP.dividendEarnings = _tmpP.dividendEarnings.add(_tmpP.dlTicketCount.mul(_dlFMoney));
            }
        }

    }
    //增加奖池
    function addMoonPrizePool(uint256 _money,uint256 _spaceshipNo) private returns(uint){
        uint256 _tmpMoney;
        if(_spaceshipNo == 0 ){ //大佬
            //将80%放入奖池
            _tmpMoney = _money.div(100).mul(80);
            totalDividendEarnings = totalDividendEarnings.add((_money.sub(_tmpMoney)));
        }
        if(_spaceshipNo == 1 ){ //小庄
            //将50%放入奖池
            _tmpMoney = _money.div(100).mul(50);
            totalDividendEarnings = totalDividendEarnings.add((_money.sub(_tmpMoney)));
        }
        if(_spaceshipNo == 2 ){ //韭菜
            //将20%放入奖池
            _tmpMoney = _money.div(100).mul(20);
            totalDividendEarnings = totalDividendEarnings.add((_money.sub(_tmpMoney)));
        }
        moonPrizePool = moonPrizePool.add(_tmpMoney);
        return _money.sub(_tmpMoney);
    }



     /**
       *  增加船长收入
       */
     function addSpaceshipMoney(uint256 _money,uint256 _spaceshipNo,uint256 _ticketCount) internal {
        //增加大佬船长收入
        Spaceship storage _spaceship0 = spaceships[0];
        uint256 _pid0 = addressMPid[_spaceship0.captain];
        Player storage _player0 = players[_pid0.sub(1)];
        _player0.earnings = _player0.earnings.add(_money);//增加总收入
        _player0.dividendEarnings = _player0.dividendEarnings.add(_money);//增加分红收入


         //增加小庄船长收入
         Spaceship storage _spaceship1 = spaceships[1];
         uint256 _pid1 = addressMPid[_spaceship1.captain];
         Player storage _player1 = players[_pid1.sub(1)];
         _player1.earnings = _player1.earnings.add(_money);//增加总收入
         _player1.dividendEarnings = _player1.dividendEarnings.add(_money);//增加分红收入



         //增加韭菜船长收入
         Spaceship storage _spaceship2 = spaceships[2];
         uint256 _pid2 = addressMPid[_spaceship2.captain];
         Player storage _player2 = players[_pid2.sub(1)];
         _player2.earnings = _player2.earnings.add(_money);//增加总收入
         _player2.dividendEarnings = _player2.dividendEarnings.add(_money);//增加分红收入



        //增加对应飞船数据
         Spaceship storage _spaceship_ = spaceships[_spaceshipNo];
         _spaceship_.speed = _spaceship_.speed.add(_spaceship_.addSpeed);//增加速度
         _spaceship_.ticketCount = _spaceship_.ticketCount.add(_ticketCount);//增加船票数量


    }

    /**
      * 获取玩家详情
      *
      */
    function getPlayerInfo(address _playerAddress) public view returns(
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

    /**
      * 增加系统账户收益
      */
    function addSystemUserEarnings(uint256 _money) private {
        Player storage _player =  players[0];
        _player.earnings = _player.earnings.add(_money);
    }

    /**
      * 提现
      */
    function withdraw(uint256 _money) public {
        require(addressMPid[msg.sender] != 0);
        Player storage _player = players[addressMPid[msg.sender].sub(1)];
        require(_player.earnings >= _money);
        _player.addr.transfer(_money);
        _player.earnings = _player.earnings.sub(_money);
    }

    /**
      * 获取游戏详情
      *
      */
    function getGameInfo()public view returns(
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

    //舰长价格每次递增上一次价格30%
    function _updateSpaceshipPrice(uint256 _spaceshipId) internal {
        spaceships[_spaceshipId].spaceshipPrice = spaceships[_spaceshipId].spaceshipPrice.add(
        spaceships[_spaceshipId].spaceshipPrice.mul(3).div(10));
    }

    //当选舰长
    function campaignCaptain(uint _spaceshipId) external payable {
        require(msg.value == spaceships[_spaceshipId].spaceshipPrice);
        //校验玩家是否是new玩家
        if(addressMPid[msg.sender] == 0){//新玩家
            //新增一位玩家
            uint256 playerArrayIndex = players.push(Player(msg.sender,"",0,0,0,0,0,0,0,0,0,0));
            addressMPid[msg.sender] = playerArrayIndex;
            pidXAddress[playerArrayIndex] = msg.sender;
            playerCount = players.length;
        }
        //将eth打入卖家账户
        spaceships[_spaceshipId].captain.transfer(msg.value);
        spaceships[_spaceshipId].captain = msg.sender;
        //刷新当选舰长价格
        _updateSpaceshipPrice(_spaceshipId);
    }
}





/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (_a == 0) {
            return 0;
        }

        c = _a * _b;
        assert(c / _a == _b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        // assert(_b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = _a / _b;
        // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold
        return _a / _b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        assert(_b <= _a);
        return _a - _b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
        c = _a + _b;
        assert(c >= _a);
        return c;
    }
}


/**
 * @title Math
 * @dev Assorted math operations
 */
library Math {
    function max(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return _a >= _b ? _a : _b;
    }

    function min(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return _a < _b ? _a : _b;
    }
}