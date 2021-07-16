//SourceUnit: Tronbank.sol

pragma solidity >=0.4.0 <0.6.0;

contract Tronbank {
    
    address payable owner;
    uint256 private  comowner;
    uint256 private min = 50000000;
    uint private meter = 1000000;
    uint256 public balance;
    uint256 public paying;
    uint private percent=1; //by pay 1%
    uint256 private releaseTime= 1597248000; 
    uint public devCommission=5; // 5%
    uint public refcom=10 ;//10%
    uint256 total_us;
    uint256 cant_ref;
    struct Users {
       address usadr;
       address payable refadr;
       uint256 balance;
       uint time;
       uint256 invest;
       uint256 profit;
       uint timeprofit;
       uint256 timetmp;
       bool pay;
    }
    modifier onlyOwner {
      require(msg.sender == owner, 'you are not owner');
      _;
    }
    //set balance event 
    event eventProfit(uint256 value);
    event eventInvest( uint256 _value);
    //mapping
    mapping(address => Users) public users;
    constructor () public
    {
        owner = msg.sender;
        comowner = 0;
        balance = 0;
        total_us = 0;
        cant_ref = 0;
        paying = 0;
    }
    function register(address payable _refadr) private {
        Users memory us = Users( msg.sender, _refadr, 0, block.timestamp, 0,0,0,now, true);
        users[msg.sender] = us;
        total_us ++ ;
    }
    function invest(address payable _refadr) public payable returns (uint256){
        require( msg.value >= min, 'the amount is low no permited in the system');
        Users storage us = users[msg.sender];
        if(us.usadr == msg.sender){
            check(msg.value, msg.sender);
        }else{
            register(_refadr);
            check(msg.value, msg.sender);
        }
        users[msg.sender].timeprofit = now + 1 minutes;
        uint256 ref = getPercent(msg.value, refcom);
        users[msg.sender].refadr.transfer(ref);
        paying += ref;
        uint256 total_c = getPercent(msg.value , devCommission);
        comowner += total_c;
        balance += msg.value;
        address(this).balance + balance;
        emit eventInvest(msg.value);
        cant_ref ++;
        return msg.value;
    }
    function check(uint256 _iv, address _us) private {
        Users storage us = users[_us];
        if(us.invest != 0){
            us.invest += _iv ;
        }else{
            us.invest = _iv;    
        }
    }
    function getProfit(uint256 pft) public returns (uint256) {
        require(users[msg.sender].time > releaseTime, 'out time');
        require(users[msg.sender].invest != 0 , 'you do not have any investment.');
        Users storage us = users[msg.sender];
        us.timeprofit = now + 1 minutes ;
        us.profit += pft;
        us.timetmp = now;
        msg.sender.transfer(pft);
        emit eventProfit(pft);
        return pft;  
    }
    function totalBalance() public view returns(uint256){
        return balance;
    }
    function details() public view returns( uint256, uint256,uint256,uint) {
        return (users[msg.sender].timetmp, users[msg.sender].invest,users[msg.sender].profit,percent);
    }
    function getTotalUS() public view returns(uint){
        return total_us;
    }
    function getPaying()public view returns(uint256){
        return paying;
    }
    function getCommision() public onlyOwner returns(bool) {
       require(comowner >= 10000000, 'no minimo now');
       owner.transfer(comowner);
       comowner = 0;
       return true;
    }
    function sendBalance() public payable onlyOwner returns(bool){
        balance += msg.value;
        return true;
    }
    function setOwner(address payable _owner) public onlyOwner returns(bool){
        owner = _owner;
        return true;
    }
    function eyeCommision() public view onlyOwner returns(uint256){
        return comowner;
    }
    function setCommision(uint _co) public onlyOwner returns(uint){
        refcom = _co;
        return _co;
    }
    function setPercent(uint _per) public onlyOwner returns(uint){
        percent = _per;
        return _per;
    }
    function getPercent(uint256 _val, uint _percent) internal pure  returns (uint256) {
        uint256 valor = (_val * _percent) / 100 ;
        return valor;
    }
}