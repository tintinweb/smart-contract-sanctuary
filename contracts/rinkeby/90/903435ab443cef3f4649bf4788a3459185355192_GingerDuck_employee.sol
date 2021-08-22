/**
 *Submitted for verification at Etherscan.io on 2021-08-22
*/

pragma solidity ^0.4.25;
contract GingerDuck_employee {
    address public owner; //老闆
    uint public PayTime; // 上次發薪時間，初始化時定為部屬時間點
    uint public DistributeTime; // 上次分紅時間，初始化時定為部屬時間點
    uint public ReliefTime; // 上次申請紓困時間，初始化時定為部屬時間點
    address[] public MemberList; //會員清單
    mapping(address => bool) active; //會員是否在職
    mapping(address => uint) public ReliefList; //紓困清單，單位為 wei
    event LogMsg(address _MsgSender, string);
    event LogTx(address _from, address _to, uint _value);

    constructor() public {
        owner = msg.sender;
        PayTime = now;
        ReliefTime = now;
        DistributeTime = now;
    }

    // 判斷是否是老闆？
    modifier isBoss() {
        require(msg.sender == owner, "權限不足");
        _;
    }    
    
    // 判斷是否是會員？
    modifier isMember(address id) {
        require(active[id], "不是會員");
        _;
    }
    
    // 判斷 address 餘額是否足夠？
    modifier haveMoney(address id, uint value) {
        require(id.balance > value, "合約餘額不足");
        _;
    }
    
    // 判斷是否已經過預設時間？ t1為上次時間，t2為設定時間
    modifier isTime(uint t1, uint t2) {
        uint a = t1 + t2;
        require(a >= t1); //檢查 overflow
        require(t1 + t2 < now, "時間未到");
        _;
    }
        
    // 取得合約餘額
    function get_ContractBalance() public view returns(uint) {
        return address(this).balance;
    }
    
    // 取得 id 餘額
    function get_MemberBalance(address id) public view isMember(id) returns(uint)  {
        return address(id).balance;
    }
    
    function clean() public isBoss() {
        for(uint i = 0; i < MemberList.length; i ++) {
            if(active[MemberList[i]]) {
                active[MemberList[i]] = false;
            }
        }
        delete MemberList;
    }
    
    // 加值() => 是否是老闆？ => 合約餘額加值 msg.value  (ok)
    function add() public payable isBoss() {
        emit LogTx(msg.sender, address(this), msg.value);
    }
    
    // 發薪() => 是否是老闆？ => 合約餘額是否足夠? => 距上次發薪時間超過30天？ => 發薪成功  (ok)
    function pay() public isBoss() haveMoney(address(this), (50 ether) * MemberList.length) isTime(PayTime, 30 seconds) {
        for(uint i = 0; i < MemberList.length; i++) {
            if(active[MemberList[i]]){
                MemberList[i].transfer(50 ether);
                emit LogTx(address(this), MemberList[i], 50 ether);  
            }
        }
        PayTime = now;
    }
    
    // 分红() => 是否是老闆？ => 合約餘額是否足夠? => 距上次分紅時間超過一年？ => 分红成功  (ok)
    function distribute() public isBoss() haveMoney(address(this), (50 ether) * MemberList.length) isTime(DistributeTime, 30 seconds) {
        for(uint i = 0; i < MemberList.length; i++) {
            if(active[MemberList[i]]){
                MemberList[i].transfer(50 ether);
                emit LogTx(address(this), MemberList[i], 50 ether);  
            }
        }
        DistributeTime = now;
    }
    
    //加入() => 是否是會員？ => 否，則加入成功 (ok)
    function register() public {
        require(active[msg.sender] != true, "你已是會員");
        MemberList.push(msg.sender);
        active[msg.sender] = true;
        emit LogMsg(msg.sender, "歡迎加入!");
    }
    
    //退休() => 是否是會員？ => 合約餘額是否足夠? => 獲得退休金，退出成功 (ok)
    function retire() public isMember(msg.sender) haveMoney(address(this), 50 ether) {
        msg.sender.transfer(50 ether);
        active[msg.sender] = false;
        for(uint i ; i < MemberList.length; i ++){
            if(MemberList[i] == msg.sender){
                delete MemberList[i];
            }
        }
        emit LogTx(address(this), msg.sender, 50 ether);
        emit LogMsg(msg.sender, "辛苦了!好好享受退休生活吧!");
    }
    
    // 紓困() => 是否是會員？ => 合約餘額是否足夠? => 帳戶餘額是否達申請標準？ => 是否超過申請額度？ => 申請成功 (ok)
    function relief(uint value) public isMember(msg.sender) haveMoney(address(this), value * (1 ether)) {
        require(address(msg.sender).balance < 200 ether, "未達申請標準");
        require(value <= 300, "超過申請額度");
        msg.sender.transfer(value * (1 ether));
        ReliefList[msg.sender] = value;
        ReliefTime = now;
        emit LogTx(address(this), msg.sender, value * (1 ether));
        emit LogMsg(msg.sender, "申請成功");
    }
    
    // 確認還款金額() => 是否是會員？ => return 應還款金額  (ok)
    function ReturnCheck() public isMember(msg.sender) view returns(uint) {
        uint PassTime = (now - ReliefTime) / 60; // 1 month = 2628000 seconds
        uint Interest = (1002 wei)**PassTime * 10**(18-3*PassTime);
        require(Interest / 10**(18-3*PassTime) == (1002 wei)**PassTime, "overflow"); // 檢查是否 overflow？
        uint ReturnMoney = ReliefList[msg.sender] * Interest;
        return ReturnMoney;
    }
    
    // 還款() => 是否是會員？ => 確認輸入金額與還款金額是否相同？ => 還款金額歸零 (ok)
    function Return() public isMember(msg.sender) payable {
        require(msg.value == ReturnCheck(), "金額不對");
        ReliefList[msg.sender] = 0;
        emit LogMsg(msg.sender, "已還款");
        emit LogTx(msg.sender, address(this), msg.value);
    }
    
    // 删除 contract => 歸還 owner 合約剩餘金額 (ok)
    function kill() public isBoss() {
        selfdestruct(owner);
    }
}