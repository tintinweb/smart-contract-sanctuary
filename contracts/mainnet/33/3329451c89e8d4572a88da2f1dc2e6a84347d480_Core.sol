pragma solidity >=0.6.0 <0.7.0;
import "./safeMath.sol";
contract Core {
    using SafeMath for uint256;
    USDT usdt;
    Db db;
    Token token;
    Tool tool;
    address[] public developer;
    uint minInvestValue = 100e6;
    uint minInvestParticle = 1e6;
    uint lastMinBalance = 100e6;
    address own = msg.sender;
    mapping(address => uint) surplusTokenNum;
    modifier isOwn(){
        require(msg.sender == own);
        _;
    }
    function init(address usdtAddress,address dbAddress,address tokenAddress,address toolAddress) public isOwn {
        usdt = USDT(usdtAddress);
        db = Db(dbAddress);
        token = Token(tokenAddress);
        tool = Tool(toolAddress);
    }
    function setDevAddress(address _devAddress) public isOwn{
        for(uint i = 0;i < developer.length;i++){
            if(developer[i] == _devAddress){
                developer[i] = developer[(developer.length-1)];
                developer.pop();
                return;
            }
        }
        developer.push(_devAddress);
    }
    function _setDevReward(uint _balance) internal {
        uint _ratio = developer.length;
        uint _giveBalance = _balance.div(_ratio);
        for (uint i = 0; i < _ratio; i++) {
            if(developer[i] == address(0x00)){
                continue;
            }
            _sendUsdtToAddress(developer[i],_giveBalance);
        }
    }
    function _sendUsdtToAddress(address _own,uint _balance) internal{
        require(usdt.balanceOf(address(this)) > _balance);
        usdt.transfer(_own,_balance);
    }
    function getAllowBalance(address _own) public view returns (uint){
        return  usdt.allowance(_own,address(this));
    }
    function _fromUsdtToAddress(uint _balance) internal{
        address _own = msg.sender;
        uint _allowBalance =  getAllowBalance(_own);
        require(_allowBalance >= _balance,"allow balance < balance");
        usdt.transferFrom(_own,address(this),_balance);
    }
    function bindParentAndBuyTicket(address _parent,uint _balance) public {
        address _own = msg.sender;
        (,,bool _isParent) = db.getPlayerInfo(_own);
        if(false == _isParent){
            if(db.systemPlayerNum() == 0){
                _parent = address(0x0);
            }else{
                (,bool _parentIsExits,) = db.getPlayerInfo(_parent);
                require(_parentIsExits == true,"parent not exist");
            }
            db.setPlayerParentAddress(_own,_parent);
        }
        _fromUsdtToAddress(_balance.mul(1e6));
        uint _price = token.price();
        uint _tokenNum = _balance.mul(_price);
        token.sendTokenToAddress(_own,_tokenNum);
    }
    function _useTicket(uint _value) internal returns (bool) {
        address _own = address(this);
        return token.sendTokenToGame(_own, _value);
    }
    function getNow() public view returns(uint){
        return now;
    }
    function _setLastTime(uint _balance) internal {
        uint _ratio = _balance / lastMinBalance;
        uint _t = 2 * 3600;
        uint _maxTime = 36 * 3600;
        uint _lastTime = db.lastTime();
        if(_lastTime < getNow()){
            _lastTime = getNow();
        }
        uint _nowLastTime = _lastTime;
        uint _newLastTime = _nowLastTime.add(_t.mul(_ratio));
        if (_newLastTime > _maxTime.add(getNow())) {
            _newLastTime = _maxTime.add(getNow());
        }
        db.setLastTime(_newLastTime);
    }
    receive() payable external {
        withdraw();
    }
    function openLastReward() public{
        if(db.lastTime() >= now){
            return;
        }
        db.openLastPoolReward();
    }
    function openReward() public{
        db.openReward();
    }
    function _setforceLuckCode(address _own,uint _balance) internal{
        if(_balance <= 0){
            return;
        }
        uint _tokenPrice = token.getTokenPrice();
        uint _scale = _tokenPrice;
        uint _tokenNum = _balance.mul(_tokenPrice).div(1e6);
        _balance = _balance.div(1e6);
        uint _lastTokenNum = surplusTokenNum[_own];
        uint _allTokenNum = _tokenNum.add(_lastTokenNum);
        uint _surplusNum = _allTokenNum.mod(_scale);
        surplusTokenNum[_own] = _surplusNum;
        uint _codeNum = _allTokenNum.sub(_surplusNum).div(_scale);
        db.addCodeToPlayer(_own,_codeNum);
    }
    function getParent(address _own) view public returns (address,bool,bool){
        (address _parent,bool _isExist, bool _isParent) = db.getPlayerInfo(_own);
        return (_parent,_isExist,_isParent);
    }
    function getAddressInfo(address _own) public view returns(uint _teamCount,uint _sonCount,uint _investBalance,uint _lev, uint _incomeBalance,uint _withdrawBalance){
        return db.getAddressSomeInfo(_own);
    }
    function getAreaPerformance(address _own) public view returns(uint _maxPerformance, uint _minPerformance){
        return db.getAreaPerformance(_own);
    }
    function getLastTime() public view returns(uint){
        return db.lastTime();
    }
    function getLastPool() public view returns(uint){
        return db.lastPool();
    }
    function getEstimateReward(address _own) public view returns(uint,uint){
        return db.getEstimateReward(_own);
    }
    function getIncomeList(address _own) public view  returns (uint[50] memory , uint[50] memory , uint[50] memory, address[50] memory ){
        return db.getIncomeList(_own);
    }
    function getMyReward(address _own) public view returns (uint[9] memory){
        return db.getMyReward(_own);
    }
    function getLuckNum() public view returns(uint){
        return db.luckCodeNum();
    }
    function getLuckCodePool() public view returns(uint,uint,uint,uint){
        uint _luckNum = getLuckNum();
        return (
            db.luckPool(_luckNum,1,0),
            db.luckPool(_luckNum,1,1),
            db.luckPool(_luckNum,1,2),
            db.luckPool(_luckNum,1,3)
        );
    }
    function getIncomePool() public view returns(uint,uint,uint,uint){
        uint _luckNum = getLuckNum();
        return (
            db.luckPool(_luckNum,0,0),
            db.luckPool(_luckNum,0,1),
            db.luckPool(_luckNum,0,2),
            db.luckPool(_luckNum,0,3)
        );
    }
    function playLuckCode(uint _num) public{
        address _own = msg.sender;
        uint _tokenPrice = token.price();
        uint _needTokenNum = _tokenPrice.mul(_num).mul(1e18);
        uint _ownBalance = token.getToken(_own);
        require(_ownBalance >= _needTokenNum,"token < need");
        token.sendTokenToGame(_own,_needTokenNum);
        db.addCodeToPlayer(_own,_num);
    }
    function getPlayerLuckCode(address _own) public view returns(uint[100] memory){
        return db.getLuckCode(_own);
    } 
    function getLastOpenLuckCodeList() public view returns(uint[] memory){
        return db.getLastOpenLuckCodeList();
    }
    function getLastInvestAddress() public view returns(address[50] memory ,uint[50] memory ){
        uint _length = db.getSystemInvestLength();
        uint j = 0;
        address[50] memory _address;
        uint[50] memory _balance;
        for(uint i = _length; i> 0;i--){
            if(j >= 50){
                break;
            }
            (address _tempAddress,uint _tempBalance) = db.getSystemInvestInfo(i.sub(1));
            _address[j] = _tempAddress;
            _balance[j] = _tempBalance;
            j++;
        }
        return (_address,_balance);
    }
    function getInvestList(bool _flag) public view returns(address[21] memory){
        return db.getInvestList(_flag);
    }
    
    function getSystemLevNum(uint _num) public view returns (uint){
        return db.systemLevNum(_num);
    }
    function invest(uint _balance) public {
        _balance = _balance.mul(1e6);
        require(_balance >= minInvestValue, "insufficient investment amount");
        require(_balance.mod(minInvestParticle) == 0, "wrong investment amount");
        _fromUsdtToAddress(_balance);
        address _selfAddress = msg.sender;
        (,,bool _isParent) = db.getPlayerInfo(_selfAddress);
        require(_isParent == true, "parent does not exist");
        uint _myTicketNum = token.getToken(_selfAddress);
        uint _needTicketNum = tool._getNeedTicketNum(_balance);
        _needTicketNum = _needTicketNum.mul(1e18);
        require(_myTicketNum >= _needTicketNum, "Insufficient tickets");
        _useTicket(_needTicketNum);
        db.addInvestBurnNum(_balance.div(10));
        db.addInvest(_selfAddress,_balance);
        db.setAssignment(_balance);
        db.giveShare(_selfAddress, _balance);
        db.setParentLev(_selfAddress);
        db.setTeamLevReward(_selfAddress, _balance);
        _setDevReward(_balance.mul(3).div(100));
        db.setTopLevReward(_balance.mul(3).div(100));
        _setLastTime(_balance);
    }
    function withdraw() public{
        openLastReward();
        openReward();
        address payable _own = tx.origin;
        db.setAllStaticReward(_own);
        uint _giveAmount = db.getFreeWithdrawBalance(_own);
        uint _tokenGiveAmount = _giveAmount.mul(5).div(100);
        uint _newGiveAmount = _giveAmount.sub(_tokenGiveAmount);
        _setforceLuckCode(_own,_tokenGiveAmount);
        db.setPlayerWithdraw(_own);
        _sendUsdtToAddress(_own,_newGiveAmount);
    }
}
abstract contract USDT {
    function transfer(address to, uint value) public virtual;
    function allowance(address owner, address spender) public view virtual returns (uint);
    function transferFrom(address from, address to, uint value) public virtual;
    function approve(address spender, uint value) public virtual;
    function balanceOf(address spender) public virtual view returns (uint);
}
abstract contract Token {
    function getToken(address _own) public virtual returns (uint);
    function sendTokenToGame(address _to, uint _value) public virtual returns (bool);
    function sendTokenToAddress(address _own,uint _balance) public virtual;
    function getTokenPrice() public virtual view returns (uint);
    function price() public view virtual returns (uint);
}
abstract contract Db {
    function setPlayerParentAddress(address _own,address _parent) public virtual;
    function systemPlayerNum() public virtual returns (uint);
    function getPlayerInfo(address _own) public view virtual returns(address _parent,bool _isExist,bool _isParent);
    function addInvest(address _own,uint _balance) public virtual;
    function setAssignment(uint _balance) public virtual;
    function giveShare(address _own, uint _balance) public virtual;
    function setParentLev(address _own) public virtual;
    function setTeamLevReward(address _own, uint _balance) public virtual;
    function setTopLevReward(uint _balance) public virtual;
    function lastTime() public view virtual returns (uint);
    function lastPool() public view virtual returns (uint);
    function setLastTime(uint _lastTime) public virtual;
    function setAllStaticReward(address _own) public virtual;
    function getFreeWithdrawBalance(address _own) public virtual returns (uint);
    function addCodeToPlayer(address _own,uint _count) public virtual;
    function setPlayerWithdraw(address _own) public virtual;
    function getAreaPerformance(address _own) public view virtual returns (uint _maxPerformance, uint _minPerformance);
    function getAddressSomeInfo(address _own) public view virtual returns(uint _teamCount,uint _sonCount,uint _investBalance,uint _lev,uint _incomeBalance,uint _withdrawBalance);
    function luckPool(uint _num,uint _type,uint _index) public view virtual returns (uint _balance);
    function getEstimateReward(address _own) public view virtual returns(uint,uint);
    function getMyReward(address _own) public view virtual  returns (uint[9] memory);
    function getIncomeList(address _own) public view virtual returns (uint[50] memory , uint[50] memory , uint[50] memory, address[50] memory);
    function luckCodeNum() public view virtual returns (uint);
    function getSystemInvestLength() public view virtual returns (uint);
    function getSystemInvestInfo(uint _index) public view virtual returns (address,uint);
    function getLastOpenLuckCodeList() public view virtual returns(uint[] memory);
    function getLuckCode(address _own) public view virtual returns(uint[100] memory);
    function getInvestList(bool _flag) public view virtual returns (address[21] memory);
    function openLastPoolReward() public virtual;
    function openReward() public virtual;
    function systemLevNum(uint _lev) public view virtual returns(uint);
    function addInvestBurnNum(uint _num) public virtual;
}
abstract contract Tool {
    function _getNeedTicketNum(uint _balance) view public virtual returns (uint);
    function _getRatio(uint _balance) pure public virtual returns (uint);
    function _createRandomNum(uint _min, uint _max, uint _randNonce) public virtual view returns (uint);
    function _crateLuckCodeList(uint _max) public view virtual returns (uint[25] memory);
}

