// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "./SafeMath.sol";
import "./Ownable.sol";

interface UniContract{
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint value);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function approve(address spender, uint value) external returns (bool);
}
interface KbkcContract{
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint value);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function approve(address spender, uint value) external returns (bool);
}
contract Finan  is Ownable{
    using SafeMath for uint256;

    struct DepositRecord {
      uint id;
      address Depositer;
      uint amount;
      uint createTime;
      uint sendTime;
      uint share;
      uint cycleId;
    }
    struct WithdrawRecord {
      uint id;
      address Withdrawer;
      uint amount;
      uint withdrawTime;
      bool result;
    }
    struct SendRecord {
      uint id;
      address receive;
      uint capital;
      uint profit;
      uint sendTime;
      bool result;
      uint cycleId;
    }

    struct Cycle {
      uint id;
      string name;
      uint timeLen;
      uint share;
      bool statu;
    }
    string[] cycleType = ["KBKC","ETH/KBKC"];
    mapping(address => uint) public depositCount;
    mapping(address => uint) public withdrawCount;
    mapping(address => uint) public sendCount;

    mapping(address => uint) public depositAmount;
    mapping(address => uint) public withdrawAmount;
    mapping(address => uint) public sendAmount;

    mapping(uint => DepositRecord) public signDeposit;
    mapping(uint => WithdrawRecord) public signWithdraw;
    mapping(uint => SendRecord) public signSend;
    mapping(uint => Cycle) public signCycle;
    

    uint depositId = 0;
    uint withdrawId = 0;
    uint sendId = 0;
    uint cycleId = 0;
    uint decimals = 10 ** 18;
    
    DepositRecord[] private DepositList;
    WithdrawRecord[] private WithdrawList;
    SendRecord[] private SendList;
    Cycle[] private CycleList;

    uint[] public tmpID;

    UniContract uniPlay;
    KbkcContract kbkcPlay;

    address private uniAddress;
    address private kbkcAddress;

    modifier existCycle (uint _cycleId) {
        bool exist = false;
        for(uint i = 0; i < CycleList.length; i++){
          if(CycleList[i].id == _cycleId && CycleList[i].statu){
            exist = true;
          }
        }
        require(exist,"不存在该存款周期");
        _;
    }
    modifier unZero (address _address) {
      require(_address != address(0),"地址不为0");
      _;
    }
    modifier checkSend (uint _depositId) {
      require(block.timestamp >= signDeposit[_depositId].sendTime,"锁定中");
      require(msg.sender == signDeposit[_depositId].Depositer,"拒绝发放");
      _;
    }
    modifier checkType (string _name) {
      bool exist = false;
      for(uint i = 0; i < cycleType.length; i++){
        if(keccak256(abi.encodePacked(cycleType[i])) == keccak256(abi.encodePacked(_name))){
          exist = true;
        }
      }
      require(exist,"不存在当前类型");
      _;
    }

    constructor (address kbkcCoin,address uniCoin) public {
        kbkcAddress = kbkcCoin;
        kbkcPlay = KbkcContract(kbkcAddress);
        uniAddress = uniCoin;
        uniPlay = UniContract(uniAddress);
    }

    function setUniAddress(address _address) public onlyOwner{
        uniAddress = _address;
        uniPlay = UniContract(uniAddress);
    }
    function setKbkcAddress(address _address) public onlyOwner{
        kbkcAddress = _address;
        kbkcPlay = KbkcContract(kbkcAddress);
    }
    function uniCount() public view returns (uint) {
      return uniPlay.balanceOf(address(this));
    }
    function kbkcCount() public view returns (uint) {
      return kbkcPlay.balanceOf(address(this));
    }
    /* 新增周期 */
    function addCycle (string _name,uint _timeLen,uint _share) external checkType(_name) onlyOwner {
        Cycle memory cycleItem = Cycle({
          id:cycleId,
          name:_name,
          timeLen:_timeLen,
          share:_share,
          statu:true
        });
        CycleList.push(cycleItem);
        signCycle[cycleId] = cycleItem;
        cycleId = cycleId.add(1);
    }
    /* 是否开启对应ID周期设置 */
    function cycleOnOff (uint _id,bool _onOff) external onlyOwner {
      CycleList[_id].statu = _onOff;
      signCycle[_id].statu = _onOff;
    }
    /* 获取展示列表的ids */
    function showCycleList () external returns(uint[]){
      uint[] storage ids = tmpID;
      for(uint i = 0; i < CycleList.length;i++){
        if(CycleList[i].statu){
          ids.push(CycleList[i].id);
        }
      }
      return ids;
    }
    /* 根据记录ID查询详情 */
    function showCycleDetail (uint _id) external view returns(uint,uint,uint){
       return (signCycle[_id].id,signCycle[_id].timeLen,signCycle[_id].share);
    }
    /* 存款KBKC */
    function deposit (address _depositer,uint _amount,uint _cycleId) external existCycle(_cycleId) unZero(_depositer) returns (uint){
        if(keccak256(abi.encodePacked(signCycle[_cycleId].name)) == keccak256(abi.encodePacked("KBKC"))){
            kbkcPlay.transferFrom(_depositer,address(this), _amount*decimals);
        }
        if(keccak256(abi.encodePacked(signCycle[_cycleId].name)) == keccak256(abi.encodePacked("ETH/KBKC"))){
            uniPlay.transferFrom(_depositer,address(this), _amount*decimals);
        }
        DepositRecord memory Record = DepositRecord({
          id:depositId,
          Depositer:_depositer,
          amount:_amount*decimals,
          createTime:block.timestamp,
          sendTime:block.timestamp + signCycle[_cycleId].timeLen,
          share:signCycle[_cycleId].share,
          cycleId:_cycleId
        });
        DepositList.push(Record);
        signDeposit[depositId] = Record;
        depositId = depositId.add(1);
        depositCount[_depositer] = depositCount[_depositer].add(1);
        depositAmount[_depositer] = depositAmount[_depositer].add(_amount*decimals);
        return depositId.sub(1);
    }
    /* 提现KBKC */
    function withdraw (address _withdrawer,uint _amount) external unZero(_withdrawer) returns (uint){
        WithdrawRecord memory Record = WithdrawRecord({
          id:withdrawId,
          Withdrawer:_withdrawer,
          amount:_amount,
          withdrawTime:block.timestamp,
          result:true
        });
        WithdrawList.push(Record);
        signWithdraw[withdrawId] = Record;
        withdrawId = withdrawId.add(1);
        withdrawCount[_withdrawer] = withdrawCount[_withdrawer].add(1);
        withdrawAmount[_withdrawer] = withdrawAmount[_withdrawer].add(_amount);
        return withdrawId.sub(1);
    }
    /* 发放KBKC */
    function send (uint _depositerId) external checkSend(_depositerId) returns (uint){
        /* 收益+本金 */
        uint sum = signDeposit[_depositerId].amount.add(signDeposit[_depositerId].amount*(signDeposit[_depositerId].share/decimals));
        if(keccak256(abi.encodePacked(signCycle[signDeposit[_depositerId].cycleId].name)) == keccak256(abi.encodePacked("KBKC"))){
            kbkcPlay.transfer(signDeposit[_depositerId].Depositer, sum);
        }
        if(keccak256(abi.encodePacked(signCycle[signDeposit[_depositerId].cycleId].name)) == keccak256(abi.encodePacked("ETH/KBKC"))){
            uniPlay.transfer(signDeposit[_depositerId].Depositer, sum);
        }
        SendRecord memory Record = SendRecord({
          id:sendId,
          receive:signDeposit[_depositerId].Depositer,
          capital:signDeposit[_depositerId].amount,
          profit:signDeposit[_depositerId].amount*(signDeposit[_depositerId].share/decimals),
          sendTime:block.timestamp,
          result:true,
          cycleId:signDeposit[_depositerId].cycleId
        });
        SendList.push(Record);
        signSend[sendId] = Record;
        sendId = sendId.add(1);
        sendCount[signDeposit[_depositerId].Depositer] = sendCount[signDeposit[_depositerId].Depositer].add(1);
        sendAmount[signDeposit[_depositerId].Depositer] = sendAmount[signDeposit[_depositerId].Depositer].add(signDeposit[_depositerId].amount*decimals);
        sendAmount[signDeposit[_depositerId].Depositer] = sendAmount[signDeposit[_depositerId].Depositer].add(signDeposit[_depositerId].amount*(signDeposit[_depositerId].share/decimals)*decimals);
        return sendId.sub(1);
    }
    function getDepositDetail(uint _id) public view returns (address,uint,uint,uint){
      return (signDeposit[_id].Depositer,signDeposit[_id].amount,signDeposit[_id].createTime,signDeposit[_id].cycleId);
    }
    function getWithdrawDetail(uint _id) public view returns (uint,address,uint,uint,bool){
      return (signWithdraw[_id].id,signWithdraw[_id].Withdrawer,signWithdraw[_id].amount,signWithdraw[_id].withdrawTime,signWithdraw[_id].result);
    }
    function getSendDetail(uint _id) public view returns (address,uint,uint,uint,uint){
      return (signSend[_id].receive,signSend[_id].capital,signSend[_id].profit,signSend[_id].sendTime,signSend[_id].cycleId);
    }
    function getDepositRecord(address _owner) external returns (uint[]){
        uint[] storage ids = tmpID;
        for(uint i = 0; i < DepositList.length; i++){
          if(_owner == DepositList[i].Depositer){
            ids.push(DepositList[i].id);
          }
        }
        return ids;
    }
    function getWithdrawRecord(address _owner) external returns (uint[]){
        uint[] storage ids = tmpID;
        for(uint i = 0; i < WithdrawList.length; i++){
          if(_owner == WithdrawList[i].Withdrawer){
            ids.push(WithdrawList[i].id);
          }
        }
        return ids;
    }
    function getSendRecord(address _owner) external returns (uint[]){
        uint[] storage ids = tmpID;
        for(uint i = 0; i < SendList.length; i++){
          if(_owner == SendList[i].receive){
            ids.push(SendList[i].id);
          }
        }
        return ids;
    }

}