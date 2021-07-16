//SourceUnit: Tronfractal.sol

pragma solidity >=0.5.9 ;

contract Tronfractal{
    
    address payable owner;
    uint256 public comowner;
    uint256 private min = 50000000;
    uint256 private max = 50000000000;
    uint private meter = 1000000;
    uint256 private balance;
    uint256 public paying;
    uint private percent; //by pay 5%
    uint256 private releaseTime=1596484800; 
    uint public devCommission; // 5%
    uint public refcom ;//3%
    uint256 public total_us;
    struct Users {
       address usadr;
       address payable refadr;
       uint256 balance;
       uint time;
       uint256 invest;
       uint256 profit;
       uint timeprofit;
       uint timetmp;
       bool pay;
    }
    modifier onlyOwner {
      require(msg.sender == owner, 'you are not owner');
      _;
    }
    //set balance event 
    event eventRegister(address _adr, string _name);
    event eventInvest(address _adr, uint256 _value);
    //mapping
    mapping(address => Users) public users;
    constructor () public
    {
       owner = msg.sender;
       comowner = 0;
       balance = 0;
       devCommission = 5;
       percent = 5;
       refcom = 3 ;
       total_us = 0;
        paying = 0;
    }
    function register(address payable _refadr) public returns (bool){
        require(msg.sender != users[msg.sender].usadr, 'you are registered here..');
        Users memory us = Users( msg.sender, _refadr, 0, block.timestamp, 0,0,0,0, true);
        users[msg.sender] = us;
        total_us ++ ;
        return true ;
    }
    function invest() public payable returns (uint256){
        require( msg.value >= min, 'the amount is low no permited in the system');
        require(msg.value <= max, 'the amount is hight in the system');
        require(msg.sender == users[msg.sender].usadr, 'register first please...');
        require (users[msg.sender].pay , 'you are disabled.');
        if(users[msg.sender].invest != 0){
           return 1;
        }
        users[msg.sender].timeprofit = now + 21 hours;
        users[msg.sender].invest = msg.value;
        uint256 ref = getPercent(msg.value, refcom);
        users[msg.sender].refadr.transfer(ref);
        paying += ref;
        uint256 total_c = getPercent(msg.value , devCommission);
        comowner += total_c;
        balance += msg.value;
        address(this).balance + msg.value;
        emit eventInvest(msg.sender , msg.value);
        return msg.value;
    }
    function getProfit() public returns (uint256) {
        require(users[msg.sender].time > releaseTime, 'out time');
        require(address(this).balance > 0, 'not balance in the system');
        require(users[msg.sender].invest != 0 , 'you already won the percentage of the contract.');
        if( users[msg.sender].timeprofit <= now ){
            Users storage us = users[msg.sender];
            uint256 total = getPercent(us.invest, percent);
            uint256 se = us.invest + total;
            us.timetmp = 0;
            us.timeprofit = 0;
            us.profit = 0;
            us.invest = 0;
            msg.sender.transfer(se);
            return se;  
        }else{
           return 0;
        }
    }
    
    function totalBalance() public view returns(uint256){
        return balance;
    }
    function details() public view returns( uint256, uint256) {
        return (users[msg.sender].timeprofit, users[msg.sender].invest);
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
    function setMax(uint256 _max) public onlyOwner returns(uint256){
        max = _max;
        return max;
    }
    function getPercent(uint256 _val, uint _percent) internal pure  returns (uint256) {
        uint256 valor = (_val * _percent)/100 ;
        return valor;
    }
    
}