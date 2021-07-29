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
      bool isSend;
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

    mapping(uint => DepositRecord) public signDeposit;
    mapping(uint => WithdrawRecord) public signWithdraw;
    mapping(uint => SendRecord) public signSend;
    mapping(uint => Cycle) public signCycle;
    
    uint stakingUniCount = 0;
    uint stakingKbkcCount = 0;
    mapping(address => uint) public ownerUniCount;
    mapping(address => uint) public ownerKbkcCount;

    uint depositId = 0;
    uint withdrawId = 0;
    uint sendId = 0;
    uint cycleId = 0;
    uint decimals = 10 ** 18;
    uint extractionShare = 9 * 10 ** 17;

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
    modifier checkSend (uint _depositId) {
      require(block.timestamp >= signDeposit[_depositId].sendTime,"锁定中");
      require(msg.sender == signDeposit[_depositId].Depositer,"拒绝发放");
      require(!signDeposit[_depositId].isSend,"已发放");
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
    modifier checkUser (uint _depositId) {
      require(msg.sender == signDeposit[_depositId].Depositer,"拒绝发放");
      require(!signDeposit[_depositId].isSend,"已发放");
      _;
    }

    modifier withdrawMax (uint _cycleId,uint _amount) {
      bool allow = false;
      if(keccak256(abi.encodePacked(signCycle[_cycleId].name)) == keccak256(abi.encodePacked("KBKC"))){
        if(uniPlay.balanceOf(address(this)).sub(stakingKbkcCount) > _amount){
          allow = true;
        }
      }
      if(keccak256(abi.encodePacked(signCycle[_cycleId].name)) == keccak256(abi.encodePacked("ETH/KBKC"))){
        if(kbkcPlay.balanceOf(address(this)).sub(stakingUniCount) > _amount){
          allow = true;
        }
      }
      require(allow,"超过最大提款额度");
      _;
    }
    constructor (address kbkcCoin,address uniCoin) public {
        kbkcAddress = kbkcCoin;
        kbkcPlay = KbkcContract(kbkcAddress);
        uniAddress = uniCoin;
        uniPlay = UniContract(uniAddress);
        
        CycleList.push(Cycle({
          id:0,
          name:"KBKC",
          timeLen:60*10,
          share:177 * 10 ** 14,
          statu:true
        }));
        signCycle[0] = Cycle({
          id:0,
          name:"KBKC",
          timeLen:60*10,
          share:177 * 10 ** 14,
          statu:true
        });
        CycleList.push(Cycle({
          id:1,
          name:"ETH/KBKC",
          timeLen:60*10,
          share:514 * 10 ** 14,
          statu:true
        }));
        signCycle[1] = Cycle({
          id:1,
          name:"ETH/KBKC",
          timeLen:60*10,
          share:514 * 10 ** 14,
          statu:true
        });
        cycleId = 2;
    }
    
    function setExtractionShare(uint _share) public onlyOwner{
        extractionShare = _share;
    }
    /* function setUniAddress(address _address) public onlyOwner{
        uniAddress = _address;
        uniPlay = UniContract(uniAddress);
    }
    function setKbkcAddress(address _address) public onlyOwner{
        kbkcAddress = _address;
        kbkcPlay = KbkcContract(kbkcAddress);
    } */
    /* function uniCount() public view returns (uint) {
      return uniPlay.balanceOf(address(this));
    }
    function kbkcCount() public view returns (uint) {
        return kbkcPlay.balanceOf(address(this));
    } */
    function uniOwnerCount(address _address) public view returns (uint) {
      return ownerUniCount[_address];
    }
    function kbkcOwnerCount(address _address) public view returns (uint) {
      return ownerKbkcCount[_address];
    }
    function stakingUniAmount() public view returns (uint) {
      return stakingUniCount;
    }
    function stakingKbkcAmount() public view returns (uint) {
      return stakingKbkcCount;
    }
    // /* 查询staking数量 */
    // function stakingCount(address _owner,uint _cycleId) public view returns (uint) {
    //     uint count = 0;
    //     if(_owner != address(0)){
    //         for(uint i = 0; i < DepositList.length;i++){
    //             if(DepositList[i].Depositer == _owner && !DepositList[i].isSend && block.timestamp > DepositList[i].sendTime && DepositList[s].cycleId == _cycleId){
    //                 count = count.add(DepositList[i].amount);
    //             }
    //         }
    //     }else{
    //         for(uint s = 0; s < DepositList.length;s++){
    //             if(!DepositList[s].isSend && block.timestamp > DepositList[s].sendTime && DepositList[s].cycleId == _cycleId){
    //                 count = count.add(DepositList[i].amount);
    //             }
    //         }
    //     }
    //     return count;
    // }
    /* 预计收益 */
    function profitComput(uint _amount,uint _cycleId) public view returns (uint) {
        if(keccak256(abi.encodePacked(signCycle[_cycleId].name)) == keccak256(abi.encodePacked("KBKC"))){
            return _amount*signCycle[_cycleId].share/decimals;
        }
        if(keccak256(abi.encodePacked(signCycle[_cycleId].name)) == keccak256(abi.encodePacked("ETH/KBKC"))){
            uint haveKbkcCount = kbkcPlay.balanceOf(uniAddress)*_amount/uniPlay.totalSupply();
            return haveKbkcCount*signCycle[_cycleId].share/decimals;
        }
    }
    /* 新增周期 */
    /* function addCycle (string _name,uint _timeLen,uint _share,uint _decimals) external checkType(_name) onlyOwner {
        Cycle memory cycleItem = Cycle({
          id:cycleId,
          name:_name,
          timeLen:_timeLen,
          share:_share * 10 ** _decimals,
          statu:true
        });
        CycleList.push(cycleItem);
        signCycle[cycleId] = cycleItem;
        cycleId = cycleId.add(1);
    } */
    /* 修改周期 */
    function editCycle (uint _cycleId,uint _timeLen,uint _share) external onlyOwner {
        CycleList[_cycleId].timeLen = _timeLen;
        signCycle[_cycleId].timeLen = _timeLen;
        CycleList[_cycleId].share = _share;
        signCycle[_cycleId].share = _share;
    }

    /* 是否开启对应ID周期设置 */
    /* function cycleOnOff (uint _id,bool _onOff) external onlyOwner {
      CycleList[_id].statu = _onOff;
      signCycle[_id].statu = _onOff;
    } */
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
    function showCycleDetail (uint _id) external view returns(string,uint,uint){
       return (signCycle[_id].name,signCycle[_id].timeLen,signCycle[_id].share);
    }
    /* 存款 */
    function deposit (address _depositer,uint _amount,uint _cycleId) external existCycle(_cycleId) returns (uint){
        if(keccak256(abi.encodePacked(signCycle[_cycleId].name)) == keccak256(abi.encodePacked("KBKC"))){
            stakingKbkcCount = stakingKbkcCount.add(_amount);
            ownerKbkcCount[_depositer] = ownerKbkcCount[_depositer].add(_amount);
            kbkcPlay.transferFrom(_depositer,address(this), _amount);
        }
        if(keccak256(abi.encodePacked(signCycle[_cycleId].name)) == keccak256(abi.encodePacked("ETH/KBKC"))){
            stakingUniCount = stakingUniCount.add(_amount);
            ownerUniCount[_depositer] = ownerUniCount[_depositer].add(_amount);
            uniPlay.transferFrom(_depositer,address(this), _amount);
        }
        DepositRecord memory Record = DepositRecord({
          id:depositId,
          Depositer:_depositer,
          amount:_amount,
          createTime:block.timestamp,
          sendTime:block.timestamp + signCycle[_cycleId].timeLen,
          share:signCycle[_cycleId].share,
          cycleId:_cycleId,
          isSend:false
        });
        DepositList.push(Record);
        signDeposit[depositId] = Record;
        depositId = depositId.add(1);
        depositCount[_depositer] = depositCount[_depositer].add(1);
        return depositId.sub(1);
    }
    /* 提现*/
    function withdraw (address _withdrawer,uint _amount,uint _cycleId) external onlyOwner existCycle(_cycleId) withdrawMax(_cycleId,_amount) returns (uint){
        if(keccak256(abi.encodePacked(signCycle[_cycleId].name)) == keccak256(abi.encodePacked("KBKC"))){
            kbkcPlay.transfer(_withdrawer, _amount);
        }
        if(keccak256(abi.encodePacked(signCycle[_cycleId].name)) == keccak256(abi.encodePacked("ETH/KBKC"))){
            uniPlay.transfer(_withdrawer,_amount);
        }
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
        return withdrawId.sub(1);
    }
    /* 发放 */
    function send (uint _depositerId) external checkSend(_depositerId) returns (uint){
        /* 收益+本金 */
        uint sum;
        if(keccak256(abi.encodePacked(signCycle[signDeposit[_depositerId].cycleId].name)) == keccak256(abi.encodePacked("KBKC"))){
            stakingKbkcCount = stakingKbkcCount.sub(signDeposit[_depositerId].amount);
            ownerKbkcCount[signDeposit[_depositerId].Depositer] = ownerKbkcCount[signDeposit[_depositerId].Depositer].add(signDeposit[_depositerId].amount);

            sum = signDeposit[_depositerId].amount*signDeposit[_depositerId].share/decimals;
            kbkcPlay.transfer(signDeposit[_depositerId].Depositer, signDeposit[_depositerId].amount.add(sum));
        }
        if(keccak256(abi.encodePacked(signCycle[signDeposit[_depositerId].cycleId].name)) == keccak256(abi.encodePacked("ETH/KBKC"))){
            stakingUniCount = stakingUniCount.sub(signDeposit[_depositerId].amount);
            ownerUniCount[signDeposit[_depositerId].Depositer] = ownerUniCount[signDeposit[_depositerId].Depositer].sub(signDeposit[_depositerId].amount);

            uint haveKbkcCount = kbkcPlay.balanceOf(uniAddress)*signDeposit[_depositerId].amount/uniPlay.totalSupply();
            sum = haveKbkcCount*signDeposit[_depositerId].share/decimals;
            kbkcPlay.transfer(signDeposit[_depositerId].Depositer, sum);
            uniPlay.transfer(signDeposit[_depositerId].Depositer,signDeposit[_depositerId].amount);
        }
        SendRecord memory Record = SendRecord({
          id:sendId,
          receive:signDeposit[_depositerId].Depositer,
          capital:signDeposit[_depositerId].amount,
          profit:sum,
          sendTime:block.timestamp,
          result:true,
          cycleId:signDeposit[_depositerId].cycleId
        });
        SendList.push(Record);
        signSend[sendId] = Record;
        sendId = sendId.add(1);
        sendCount[signDeposit[_depositerId].Depositer] = sendCount[signDeposit[_depositerId].Depositer].add(1);

        signDeposit[_depositerId].isSend = true;
        DepositList[_depositerId].isSend = true;
        return sendId.sub(1);
    }
    /* 提前提取 */
    function extraction(uint _depositerId) external checkUser(_depositerId) returns (uint){
        if(keccak256(abi.encodePacked(signCycle[signDeposit[_depositerId].cycleId].name)) == keccak256(abi.encodePacked("KBKC"))){
            stakingKbkcCount = stakingKbkcCount.sub(signDeposit[_depositerId].amount);
            ownerKbkcCount[signDeposit[_depositerId].Depositer] = ownerKbkcCount[signDeposit[_depositerId].Depositer].add(signDeposit[_depositerId].amount);

            kbkcPlay.transfer(signDeposit[_depositerId].Depositer, signDeposit[_depositerId].amount*extractionShare/decimals);
        }
        if(keccak256(abi.encodePacked(signCycle[signDeposit[_depositerId].cycleId].name)) == keccak256(abi.encodePacked("ETH/KBKC"))){
            stakingUniCount = stakingUniCount.sub(signDeposit[_depositerId].amount);
            ownerUniCount[signDeposit[_depositerId].Depositer] = ownerUniCount[signDeposit[_depositerId].Depositer].sub(signDeposit[_depositerId].amount);

            uniPlay.transfer(signDeposit[_depositerId].Depositer,signDeposit[_depositerId].amount*extractionShare/decimals);
        }

        SendRecord memory Record = SendRecord({
          id:sendId,
          receive:signDeposit[_depositerId].Depositer,
          capital:signDeposit[_depositerId].amount,
          profit:signDeposit[_depositerId].amount*(decimals-extractionShare)/decimals,
          sendTime:block.timestamp,
          result:false,
          cycleId:signDeposit[_depositerId].cycleId
        });
        SendList.push(Record);
        signSend[sendId] = Record;
        sendId = sendId.add(1);
        sendCount[signDeposit[_depositerId].Depositer] = sendCount[signDeposit[_depositerId].Depositer].add(1);
        signDeposit[_depositerId].isSend = true;
        DepositList[_depositerId].isSend = true;
        return sendId.sub(1);
    }
    function getDepositDetail(uint _id) public view returns (bool,uint,uint,uint,uint){
      return (signDeposit[_id].isSend,signDeposit[_id].amount,signDeposit[_id].createTime,signDeposit[_id].cycleId,signDeposit[_id].sendTime);
    }
    /* function getWithdrawDetail(uint _id) public view returns (uint,address,uint,uint,bool){
      return (signWithdraw[_id].id,signWithdraw[_id].Withdrawer,signWithdraw[_id].amount,signWithdraw[_id].withdrawTime,signWithdraw[_id].result);
    } */
    function getSendDetail(uint _id) public view returns (uint,uint,uint,uint,bool){
      return (signSend[_id].capital,signSend[_id].profit,signSend[_id].sendTime,signSend[_id].cycleId,signSend[_id].result);
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
    /* function getWithdrawRecord(address _owner) external returns (uint[]){
        uint[] storage ids = tmpID;
        for(uint i = 0; i < WithdrawList.length; i++){
          if(_owner == WithdrawList[i].Withdrawer){
            ids.push(WithdrawList[i].id);
          }
        }
        return ids;
    } */
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