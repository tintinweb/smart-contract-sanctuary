//SourceUnit: TronPlus.sol

pragma solidity ^0.5.10;
library SafeMath{

   function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
}
interface CodeAddresspool {

     function setrelation(uint64 code, address _add) external;
     function superior(address account) external view returns (address);

     function addressToCode(address account) external view returns (uint64 );
     function codeToAddress(uint64 code) external view returns (address );
}
contract TronPlusStorage {
    using SafeMath for uint256;
    modifier isOwner() {
        require(msg.sender == _owner || msg.sender == _owner2 || msg.sender == _owner3, "not owner of show");
        _;
    }
    struct User{
        address userAddress;
        uint investAmount;   //投资的数量
 //       uint invitedAmount;   //本日直推的ETH金额,参与竞赛
        uint totalInvitedE0; //直推业绩
        // uint stashedDynamic;        //已存的动态
//         uint achieveTime;               //邀请排名达成时间
         uint staticTime;          //静态计算时间
         uint lastInvestTime;  //最后投资时间
         uint freezeAmount;    //重启后冻结的金额

    }
    address _owner;
    address _owner2;
    address _owner3;
    mapping (address => User) public addressToUser;
    mapping (address => uint256) _gottenStaticProfit;
    mapping (address => uint256) _gottenDynamicProfit;
    mapping (address => uint256) _gottenExcitation;
    mapping (address => uint256) _stashedExcitation;
    mapping (address => uint256) _stashedDynamicProfit;
    mapping (address => uint256) _stashedStaticProfit;
    //最小投资eth数量
    uint256 minInvest;
    //全球节点
    uint256 public globalNodeNumber = 0;
    //合约总量
    uint256 public totalInvestAmount;  //总流水

    uint public racePool;  //奖金池,用于发放竞赛的资金   充值的10%
    address feePool;     //5%提现手续费
    address foundingPool;     //2%用于生态建设
    address techPool;         //3%会用于技术开发
    uint256 public rebootTime;
    uint256 raceBirthDay;
    bool public opened = true;
    // address[] public topUsers;
      address[] public levelUsers;
      address[] public allUsers;
      CodeAddresspool public tree;
    constructor() public{
        _owner =  address(0x41B7E9D56F114A96C499D5B12CC16F878B528C55C3);
        _owner2 = msg.sender;
        _owner3 = address(0x419E211C9E4E004D37765393CEF79BDB0B5259CD20);
        minInvest = 100 trx;
        User memory creation = User(msg.sender, minInvest, 0, now,now,0);
        // topUsers = new address[](10);
        allUsers = new address[](0);
    addressToUser[msg.sender] = creation;
    foundingPool = address(0x414F7AB133A5234D56BB24059D0EBE807295035D1B);
    feePool = msg.sender;
    techPool = address(0x4120969B80700185979D4B5FC6B9AE58258B73EC23);
    }

}

contract TronPlusLogic is TronPlusStorage  {
    using SafeMath for uint256;
    event CollectProfit(address indexed from, uint256 staticAmount, uint256 dynamicAmount);
     event Invest(address indexed from, uint256 amount, uint64 referCode);
     event Reinvest(address indexed from, uint256 amount);
     event UserWithdraw(address indexed from, uint amount);
    function() payable external{
        
    }
    function transferOwnership(address newOwner) public isOwner {
		require(newOwner != address(0x0), "Ownable: new owner is the zero address");
		_owner = newOwner;
	}
	    function transferOwner2(address newOwner) public isOwner {
		require(newOwner != address(0x0), "Ownable: new owner is the zero address");
		_owner2 = newOwner;
	}
	function transferOwner3(address newOwner) public isOwner {
		require(newOwner != address(0x0), "Ownable: new owner is the zero address");
		_owner3 = newOwner;
	}
	function withdrawForOwner (uint256 _amt) public isOwner{
	    msg.sender.transfer(_amt);
	}
    /**
     * 投资eth
     * referrNO:6位邀请码
     * 转入ETH到合约储存池
     */
    function invest(uint64 referrNO)public payable{
        require(opened, "rebooting");
        require(msg.value >= minInvest, "less than min");
        User storage o_user = addressToUser[msg.sender];
        if (tree.superior(msg.sender) == address(0x0) && tree.addressToCode(msg.sender) == 0){
        address r_address =  tree.codeToAddress(referrNO);
        require (r_address != address(0x0), "invalid referrNO");
        tree.setrelation(referrNO, msg.sender);

            allUsers.push(msg.sender);
            o_user.userAddress = msg.sender;
            globalNodeNumber = globalNodeNumber + 1;
            o_user.investAmount = msg.value;
        }else {

            if(isOut(msg.sender)){
             o_user.investAmount = msg.value;  
             _resetUsersProfit(msg.sender);
             o_user.totalInvitedE0 = 0;
            }else {
                if (o_user.lastInvestTime < rebootTime) {
                     o_user.investAmount = msg.value;  
                    _resetUsersProfit(msg.sender);
                    o_user.totalInvitedE0 = 0;
                }else {
                _stashDynamic(msg.sender);
                o_user.investAmount = o_user.investAmount.add(msg.value);
                }
                
            }
            if (msg.value >= o_user.freezeAmount && o_user.freezeAmount > 0) {
                o_user.investAmount = o_user.investAmount.add(o_user.freezeAmount);
                o_user.freezeAmount = 0;
            }
        }

            emit Invest(msg.sender, msg.value, referrNO);

        o_user.staticTime = now;
        o_user.lastInvestTime = now;

    totalInvestAmount = totalInvestAmount + msg.value;
    address payable payFoundingPool = address(uint160(foundingPool));
    payFoundingPool.transfer(SafeMath.mul(SafeMath.div( msg.value, 100), 2));
    //     address payable payFeePool = address(uint160(feePool));
    // payFeePool.transfer(SafeMath.mul(SafeMath.div( msg.value, 100), 1));
        address payable payTechPool = address(uint160(techPool));
    payTechPool.transfer(SafeMath.mul(SafeMath.div( msg.value, 100), 1));
    racePool = SafeMath.add(racePool, SafeMath.mul(SafeMath.div(msg.value, 100), 2));
    }
    function _resetUsersProfit(address _add)private {
            _stashedStaticProfit[_add] = 0;
            _stashedDynamicProfit[_add] = 0;
            _stashedExcitation[_add] = 0;
            _gottenStaticProfit[_add] = 0;
            _gottenDynamicProfit[_add] = 0;
             _gottenExcitation[_add] = 0;
    }


     function happy() public{
         //领取静态
        User storage _user = addressToUser[msg.sender];
        uint payAmount = getLiveStaticProfit(msg.sender);
        require(payAmount > 0, "no amount");
      _outToAddress(msg.sender, payAmount, 1);
      _user.staticTime = now;
      _stashedStaticProfit[msg.sender] = 0;
        emit UserWithdraw(msg.sender, payAmount);
        if (stashedDynamicProfit(msg.sender) > 0) {
            _outToAddress(msg.sender, stashedDynamicProfit(msg.sender), 4);
            _stashedDynamicProfit[msg.sender] = 0;
        }
        if (stashedExcitation(msg.sender) > 0) {
            _outToAddress(msg.sender, stashedExcitation(msg.sender), 2);
            _stashedExcitation[msg.sender] = 0;
        }
    }

    function _stashDynamic(address _add) private {
        User storage _user = addressToUser[_add];
        _stashedStaticProfit[_add] = stashedStaticProfit(_add).add(getLiveStaticProfit(_add));
        _user.staticTime = now;
    }
function sendReboot(address payable _add, uint _amount) public isOwner {
    _outToAddress(_add, _amount, 3);
}
function sendInvite(address payable _add, uint _amount) public isOwner {

    _stashedDynamicProfit[_add] = stashedDynamicProfit(_add).add(_amount);
}
//1:每日分红  2:竞赛激励  3:重启发奖  4:邀请奖励
    function _outToAddress(address payable _add, uint _amount, uint8 rewardType) private {
        User storage _user = addressToUser[_add];
        if (rewardType == 3) {
            if (_amount > _user.investAmount) {
                _add.transfer(_user.investAmount);
                _user.freezeAmount = _amount.sub(_user.investAmount);
            }else {
                _add.transfer(_amount);
            }
        }else {
        uint256 totaled = _gottenStaticProfit[_add] + _gottenDynamicProfit[_add] + _gottenExcitation[_add];
        uint payAmount = _amount;
        if (totaled + _amount > getOutgame(_user.investAmount)){
            payAmount = getOutgame(_user.investAmount).sub(totaled);
        }
        if (rewardType == 1) {
            _add.transfer(payAmount);
            _gottenStaticProfit[_add] = gottenStaticProfit(_add).add(payAmount);
        }else if (rewardType == 4){
            _add.transfer(payAmount);
            _gottenDynamicProfit[_add] = gottenDynamicProfit(_add).add(payAmount);
        }else if (rewardType == 2) {
            _add.transfer(payAmount);
            _gottenExcitation[_add] = gottenExcitation(_add).add(payAmount);
        }
        }
    }
    
    function getOneDayStatic(address _address) public view returns(uint){
        User memory _user = addressToUser[_address];
        return SafeMath.mul(SafeMath.div(_user.investAmount, 1000),getStaticRateByAmount(_user.investAmount)); 
    }



    function getLiveStaticProfit(address _address) public view returns(uint){
        User memory _user = addressToUser[_address];
        if (_user.investAmount == 0) {
            return 0;
        }
        if (_user.lastInvestTime < rebootTime) {
            return 0;
        }
        if (isOut(_address)) {
            return 0;
        }
        uint times = now - _user.staticTime;
        uint minu = SafeMath.div(times, 60);
        uint profit =  SafeMath.div(SafeMath.mul(getOneDayStatic(_address), minu), 1440);
        return profit;
        
    }
    function isOut(address _address) public view returns (bool) {
        User memory _user = addressToUser[_address];
        bool isOuts = ((_gottenStaticProfit[_address] + _gottenDynamicProfit[_address] + _gottenExcitation[_address]) >= getOutgame(_user.investAmount));
        return isOuts;
    }


    function getAlllUsers1(uint _formIndex, uint _length)public view returns(address[] memory , address[] memory , uint[] memory , uint[] memory) {
        address[] memory adds = new address[](_length);
        address[] memory pars = new address[](_length);
        uint[] memory lastItimes = new uint[](_length);
        uint[] memory amounts = new uint[](_length);

        require(_length + _formIndex <= allUsers.length);
        for (uint i = 0; i < _length; i ++) {
            address _ad = allUsers[i + _formIndex];
            User memory _user = addressToUser[_ad];
            adds[i] = _ad;
            pars[i] = tree.superior(_ad);
            amounts[i] = getUserInvestAmount(_ad);
            lastItimes[i] = _user.lastInvestTime;
        }
        return (adds, pars, lastItimes, amounts);
        
    }
        function getAlllUsers2(uint _formIndex, uint _length)public view returns(address[] memory ,uint[] memory,uint[] memory,uint[] memory, bool[] memory ) {
        address[] memory adds = new address[](_length);
        uint[] memory statics = new uint[](_length);
        uint[] memory invites = new uint[](_length);
        uint[] memory excitations = new uint[](_length);
        bool[] memory isOuts = new bool[](_length);
        require(_length + _formIndex <= allUsers.length);
        for (uint i = 0; i < _length; i ++) {
            address _ad = allUsers[i + _formIndex];
            adds[i] = _ad;
            statics[i] = gottenStaticProfit(_ad);
            invites[i] = gottenDynamicProfit(_ad);
            excitations[i] = gottenExcitation(_ad);
            isOuts[i] = isOut(_ad);
        }
        return (adds, statics,invites,excitations,isOuts);
        
    }
    function getStaticRateByAmount(uint _amt)public pure returns (uint){
        if (_amt > 30000 trx){
            return 20;
        }else if (_amt > 20000 trx) {
            return 18;
        }else if (_amt > 10000 trx) {
            return 15;
        }else if (_amt > 5000 trx) {
            return 12;
        }else if (_amt > 2000 trx) {
            return 11;
        }else {
            return 10;
        }
    }
    function getDynamicRateByLevel(uint _generation)public pure returns (uint){

        if (_generation == 1){
            return 30;
        }else if (_generation == 2){
            return 20;
        }else if (_generation >=3 && _generation <= 10){
             return 10;
        }else {
            return 0;
        }

    }

    function getOutgame(uint _amt) public pure returns(uint){
        return _amt * 21 / 10;
    }

        function sendRace(address ad0, address ad1, address ad2, address ad3, address ad4, address ad5, address ad6, address ad7, address ad8, address ad9) public isOwner{
        //发放竞赛奖励,每天一次
    uint currentPool = racePool.mul(30).div(100);
        address[10] memory top10 = [ad0,ad1,ad2,ad3,ad4,ad5,ad6,ad7,ad8,ad9];
        uint256[10] memory rate = [uint256(40),22,13,8,6,4,3,2,1, 1];
        uint256 sendedAmount = 0;
        for (uint i = 0; i < 10; i ++){
            
            address _add = top10[i];
            if (_add != address(0x0)){
                    // _outToAddress(needPay, SafeMath.mul(SafeMath.div(currentPool, 100), rate[i]), 2);
                    _stashedExcitation[_add] = stashedExcitation(_add).add(SafeMath.mul(SafeMath.div(currentPool, 100), rate[i]));
                    sendedAmount = sendedAmount + SafeMath.mul(SafeMath.div(currentPool, 100), rate[i]);
            }
        }
        racePool = SafeMath.sub(racePool, sendedAmount);
        raceBirthDay = now;
    }
    function reboot()public isOwner {
        rebootTime = now;
        racePool = 0;
        totalInvestAmount = 0;
        opened = false;
    }
    function trunOn()public isOwner {
        opened = true;
    }
    function setMin(uint _amt)public isOwner {
        minInvest = _amt;
    }
    function setFoundings(address _add0, address _add1, address _add2)public isOwner {
        feePool = _add0;
        techPool = _add1;
        foundingPool = _add2;
    }
    function setTree(address _add) public isOwner {
        tree = CodeAddresspool(_add);
    }
    function getUserInvestAmount(address _add)public view returns (uint) {
        User memory _user = addressToUser[_add];
        if (_user.lastInvestTime <= rebootTime) {
            return 0;
        }else {
            return _user.investAmount;
        }
    }
    function isUserBeforeReboot(address _add)public view returns (bool) {
        User memory _user = addressToUser[_add];
        return _user.lastInvestTime <= rebootTime;
    }
    function gottenExcitation(address _add)public view returns (uint) {
      if (isUserBeforeReboot(_add)){
          return 0;
      }else {
          return _gottenExcitation[_add];
      }
    }
        function gottenStaticProfit(address _add)public view returns (uint) {
      if (isUserBeforeReboot(_add)){
          return 0;
      }else {
          return _gottenStaticProfit[_add];
      }
    }
        function gottenDynamicProfit(address _add)public view returns (uint) {
      if (isUserBeforeReboot(_add)){
          return 0;
      }else {
          return _gottenDynamicProfit[_add];
      }
    }
        function stashedExcitation(address _add)public view returns (uint) {
      if (isUserBeforeReboot(_add) || isOut(_add)){
          return 0;
      }else {
          return _stashedExcitation[_add];
      }
    }
        function stashedDynamicProfit(address _add)public view returns (uint) {
      if (isUserBeforeReboot(_add) || isOut(_add)){
          return 0;
      }else {
          return _stashedDynamicProfit[_add];
      }
    }
        function stashedStaticProfit(address _add)public view returns (uint) {
      if (isUserBeforeReboot(_add) || isOut(_add)){
          return 0;
      }else {
          return _stashedStaticProfit[_add];
      }
    }
    
}