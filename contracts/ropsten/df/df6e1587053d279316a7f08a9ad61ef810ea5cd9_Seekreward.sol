/**
 *Submitted for verification at Etherscan.io on 2021-02-15
*/

pragma solidity 0.5.16;
interface IERC777 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function burnBalance(address _addr,uint _amount) external;
    function mint(address _tokenHolder,uint256 _amount,bytes calldata _data,bytes calldata _operatorData) external;
    function defaultOperators() external view returns (address[] memory);

    // solhint-disable-next-line no-simple-event-func-name
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}

library SafeMath {

    function add(uint a, uint b) internal pure returns (uint) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
    
    function mod(uint a, uint b) internal pure returns (uint) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

contract Seekreward {
    using SafeMath for uint256;
    struct user {
        uint256 cycle;
        address upline;
        uint256 referrals;
        uint256 payouts;
        uint256 referalBonus;
        uint256 matchBonus;
        uint256 depositAmount;
        uint256 depositPayouts;
        uint40 depositTime;
        uint256 totalDeposits; 
        uint256 totalStructure;
    }
   
    mapping(address => user)public users;
    bool public lockStatus;
    IERC777 private _token; 
    address payable public admin1;
    address payable public admin2;
    uint[]public Levels;
    uint public refBonuses = 5e18;
    uint256 public totalUsers = 1;
    uint256 public totalDeposited;
    uint256 public totalWithdraw;
    
    event Referalamount(address indexed from,address indexed to,uint value,uint time);
    event Matchbonus(address indexed from,address indexed to,uint value,uint time);
    event Withdraw(address indexed from,uint value,uint time);
    event Adminshare(address indexed from,address indexed to,uint value,uint time);
    event Deposit(address indexed from,address indexed refer,uint value,uint time);
    event Admin(address indexed user,uint value,uint time);
    
    
     constructor(address payable _own1,address payable _own2,address token)public{
         admin1 = _own1;
         admin2 = _own2;
         _token = IERC777(token);
         
         //Levels maximum amount
         Levels.push(150e18);
         Levels.push(450e18);
         Levels.push(1350e18);
         Levels.push(3000e18);
    }
     
     modifier onlyOwner() {
         require(msg.sender == admin1, "Only Owner");
        _;
    } 
        
    modifier isLock() {
         require(lockStatus == false, "Contract Locked");
        _;
    } 
    
    modifier isContractcheck(address _user) {
        require(!isContract(_user),"Invalid address");
        _;
    }
     
    function() payable external {
        _deposit(msg.sender, msg.value);
    }

    function _setUpline(address _addr, address _upline) private {
        if(users[_addr].upline == address(0) && _upline != _addr && _addr != admin1 && (users[_upline].depositTime > 0 || _upline == admin1)) {
        users[_addr].upline = _upline;
        users[_upline].referrals =  users[_upline].referrals.add(1);
        totalUsers++;
        for(uint8 i = 0; i < 21; i++) {
            if(_upline == address(0)) break;
        users[_upline].totalStructure++;
       _upline = users[_upline].upline;
        }
        }
    }
    
    function _refAmount(address _addr,address _upline,uint _amount)private{
        address up = users[_upline].upline;
        for(uint8 i = 0; i < 20; i++) {
          if(up == address(0))
            up = admin1;
        users[up].referalBonus = users[up].referalBonus.add(_amount.mul(refBonuses).div(100e18)); 
        emit Referalamount(_addr,up,_amount.mul(refBonuses).div(100e18),block.timestamp);
        up = users[up].upline;
        }
    }
    
    function _deposit(address _addr, uint256 _amount) private {
        require(users[_addr].upline != address(0) || _addr == admin1, "No upline");
        if(users[_addr].depositTime > 0) {
        users[_addr].cycle++;
        require(users[_addr].payouts >= this.maxPayoutOf(users[_addr].depositAmount), "Deposit already exists");
        require(_amount >= users[_addr].depositAmount && _amount <= Levels[users[_addr].cycle > Levels.length - 1 ? Levels.length - 1 : users[_addr].cycle], "Bad amount");
        }
        else {
        require(_amount >= 1e18 && _amount <= Levels[0], "Bad amount");
        }
        users[_addr].payouts = 0;
        users[_addr].depositAmount = _amount;
        users[_addr].depositPayouts = 0;
        users[_addr].depositTime = uint40(block.timestamp);
        users[_addr].totalDeposits = users[_addr].totalDeposits.add(_amount);
        totalDeposited =  totalDeposited.add(_amount);
        _token.transferFrom(msg.sender,address(this),_amount);

        if(users[_addr].upline != address(0)) {
        users[users[_addr].upline].referalBonus = users[users[_addr].upline].referalBonus.add(_amount.mul(10e18).div(100e18));
        emit Referalamount(_addr,users[_addr].upline,_amount.mul(10e18).div(100e18),block.timestamp);
    }
        emit Deposit(_addr,users[_addr].upline,_amount,block.timestamp);
        uint adminFee = _amount.mul(5e18).div(100e18);
        admin1.transfer(adminFee.div(2));
        emit Adminshare(_addr,admin1,adminFee.div(2),block.timestamp);
        admin2.transfer(adminFee.div(2));
        emit Adminshare(_addr,admin2,adminFee.div(2),block.timestamp);
        adminFee = 0;
        _refAmount(_addr,users[_addr].upline,_amount);
    }
    
    function deposit(address _upline) payable isLock isContractcheck(msg.sender) external {
        _setUpline(msg.sender, _upline);
        _deposit(msg.sender, msg.value);
    }
    
    function _matchBonus(address _user,uint _amount)private{
        address up = users[_user].upline;
        for(uint i = 1;i <= 21;i++){
        if(up == address(0))break;
        if(i<=3){
        users[up].matchBonus = users[up].matchBonus.add(_amount);
        emit Matchbonus(_user,up,_amount,block.timestamp);
        }
        else if(i <= 6){
        if(users[up].referrals >= 2){
        users[up].matchBonus = users[up].matchBonus.add(_amount);
        emit Matchbonus(_user,up,_amount,block.timestamp);
        }
    }
        else if(i<=10){
        if(users[up].referrals >= 4){
        users[up].matchBonus = users[up].matchBonus.add(_amount);
        emit Matchbonus(_user,up,_amount,block.timestamp);
        }
    }
        else if(i<=14){
        if(users[up].referrals >= 8){
        users[up].matchBonus = users[up].matchBonus.add(_amount);
        emit Matchbonus(_user,up,_amount,block.timestamp);
        }
    }
        else if(i<=21){
        if(users[up].referrals >= 16){
        users[up].matchBonus = users[up].matchBonus.add(_amount);
        emit Matchbonus(_user,up,_amount,block.timestamp);
        }
    }
        up = users[up].upline;
        
    }
        
    }
    
    function withdraw() isLock external {
        (uint256 to_payout, uint256 max_payout) = this.payoutOf(msg.sender);
        require(msg.sender != admin1,"only for users");
        require(users[msg.sender].payouts < max_payout , "Full payouts");
        // Deposit payout
        if(to_payout > 0) {
        if(users[msg.sender].payouts.add(to_payout) > max_payout) {
        to_payout = max_payout.sub(users[msg.sender].payouts);
        }
        users[msg.sender].depositPayouts = users[msg.sender].depositPayouts.add(to_payout);
        users[msg.sender].payouts = users[msg.sender].payouts.add(to_payout);
       _matchBonus(msg.sender, to_payout.mul(3e18).div(100e18));
    }
        // referal earn
        if(users[msg.sender].payouts < max_payout && users[msg.sender].referalBonus > 0 ){
        if(users[msg.sender].payouts.add(users[msg.sender].referalBonus) > max_payout){
        users[msg.sender].referalBonus = max_payout.sub(users[msg.sender].payouts);
        }
        users[msg.sender].payouts = users[msg.sender].payouts.add(users[msg.sender].referalBonus);
        to_payout = to_payout.add(users[msg.sender].referalBonus);
        users[msg.sender].referalBonus = users[msg.sender].referalBonus.sub(users[msg.sender].referalBonus);
    }
        // matching bonus
        if(users[msg.sender].payouts < max_payout && users[msg.sender].matchBonus > 0){
        if(users[msg.sender].payouts.add(users[msg.sender].matchBonus) > max_payout){
        users[msg.sender].matchBonus = max_payout.sub(users[msg.sender].payouts);
        }
        users[msg.sender].payouts = users[msg.sender].payouts.add(users[msg.sender].matchBonus);
        to_payout = to_payout.add(users[msg.sender].matchBonus);
        users[msg.sender].matchBonus = users[msg.sender].matchBonus.sub(users[msg.sender].matchBonus);
    }
        totalWithdraw = totalWithdraw.add(to_payout);
        msg.sender.transfer(to_payout);
        emit Withdraw(msg.sender,to_payout,block.timestamp);
    }
    
    function adminWithdraw()public onlyOwner{
        uint amount;
        if(users[admin1].referalBonus > 0){
        amount = amount.add(users[admin1].referalBonus);
        users[admin1].referalBonus = 0;
        }
        if(users[admin1].matchBonus > 0){
        amount = amount.add(users[admin1].matchBonus);
        users[admin1].matchBonus = 0;
        }
        require(address(uint160(admin1)).send(amount),"admin transaction failed");
        emit Admin(admin1,amount,block.timestamp);
    }
    
    function maxPayoutOf(uint256 _amount) pure external returns(uint256) {
        return _amount.mul(210).div(100);
    }

    function payoutOf(address _addr) view external returns(uint256 payout, uint256 max_payout) {
        max_payout = this.maxPayoutOf(users[_addr].depositAmount);
        if(users[_addr].depositPayouts < max_payout) {
        payout =  ((users[_addr].depositAmount.mul(1e18).div(100e18)).mul((block.timestamp.sub(users[_addr].depositTime)).div(1 days))).sub(users[_addr].depositPayouts);
        if(users[_addr].depositPayouts.add(payout) > max_payout) {
        payout = max_payout.sub(users[_addr].depositPayouts);
        }
        }
    }
    
    function userInfo(address _addr) view external returns(address upline, uint40 deposit_time, uint256 deposit_amount, uint256 payouts, uint256 match_bonus) {
        return (users[_addr].upline, users[_addr].depositTime, users[_addr].depositAmount, users[_addr].payouts,  users[_addr].matchBonus);
    }

    function userInfoTotals(address _addr) view external returns(uint256 referrals, uint256 total_deposits,  uint256 total_structure) {
        return (users[_addr].referrals, users[_addr].totalDeposits,  users[_addr].totalStructure);
    }

    function contractInfo() view external returns(uint256 _total_users, uint256 _total_deposited, uint256 _total_withdraw) {
        return (totalUsers, totalDeposited, totalWithdraw);
    }
    
    function contractLock(bool _lockStatus) public onlyOwner returns(bool) {
        lockStatus = _lockStatus;
        return true;
    }
        
    function failSafe(address payable _toUser, uint _amount) public onlyOwner returns (bool) {
        require(_toUser != address(0), "Invalid Address");
        require(address(this).balance >= _amount, "Insufficient balance");
      (_toUser).transfer(_amount);
        return true;
    }
    
    function isContract(address _account) public view returns (bool) {
        uint32 size;
        assembly {
                size := extcodesize(_account)
        }
        if(size != 0)
         return true;
        return false;
   }
}