/**
 *Submitted for verification at Etherscan.io on 2021-02-11
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

contract Seekreward{
    using SafeMath for uint256;
    struct User {
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
    
   
    
    
    mapping(address => User)public Users;
    
    bool public lockStatus;
    IERC777 private _token; 
    address payable public admin1;
    address payable public admin2;
    uint[]public Levels;
    uint[]public refBonuses;
    
    uint256 public totalUsers = 1;
    uint256 public totalDeposited;
    uint256 public totalWithdraw;
    
    event Referalamount(address indexed from,address indexed to,uint value,uint time);
    event Matchbonus(address indexed from,address indexed to,uint value,uint time);
    event Withdraw(address indexed from,uint value,uint time);
    event Adminshare(address indexed from,address indexed to,uint value,uint time);
    event Deposit(address indexed from,address indexed refer,uint value,uint time);
    
    
     constructor(address payable own1,address payable own2,address token)public{
         admin1 = own1;
         admin2 = own2;
         _token = IERC777(token);
         
         
         Levels.push(150e18);
         Levels.push(450e18);
         Levels.push(1350e18);
         Levels.push(3000e18);
         
         refBonuses.push(5e18);
         refBonuses.push(5e18);
         refBonuses.push(5e18);
         refBonuses.push(5e18);
         refBonuses.push(5e18);
         refBonuses.push(5e18);
         refBonuses.push(5e18);
         refBonuses.push(5e18);
         refBonuses.push(5e18);
         refBonuses.push(5e18);
         refBonuses.push(5e18);
         refBonuses.push(5e18);
         refBonuses.push(5e18);
         refBonuses.push(5e18);
         refBonuses.push(5e18);
         refBonuses.push(5e18);
         refBonuses.push(5e18);
         refBonuses.push(5e18);
         refBonuses.push(5e18);
         refBonuses.push(5e18);
         
     }
     
     modifier onlyOwner() {
            require(msg.sender == admin1, "Only Owner");
            _;
        } 
        
    modifier isLock() {
            require(lockStatus == false, "Contract Locked");
        _;
    } 
     
    function() payable external {
        _deposit(msg.sender, msg.value);
    }

    function _setUpline(address _addr, address _upline) private {
        if(Users[_addr].upline == address(0) && _upline != _addr && _addr != admin1 && (Users[_upline].depositTime > 0 || _upline == admin1)) {
        Users[_addr].upline = _upline;
        Users[_upline].referrals.add(1);
        
        // emit Upline(_addr, _upline);
        
        totalUsers++;
        
        for(uint8 i = 0; i < 21; i++) {
        if(_upline == address(0)) break;
        
        Users[_upline].totalStructure++;
        
        _upline = Users[_upline].upline;
        }
        }
    }
    
    function _refAmount(address _addr,address _upline,uint amount)private{
        address up = Users[_upline].upline;
        for(uint8 i = 0; i < refBonuses.length; i++) {
            if(up == address(0))
               up = admin1;
            
            Users[up].referalBonus = Users[up].referalBonus.add(amount.mul(refBonuses[i]).div(100e18)); 
             emit Referalamount(_addr,up,amount.mul(refBonuses[i]).div(100e18),block.timestamp);

            up = Users[up].upline;
        }
    }
    
    function _deposit(address _addr, uint256 _amount) private {
        require(Users[_addr].upline != address(0) || _addr == admin1, "No upline");

        if(Users[_addr].depositTime > 0) {
            Users[_addr].cycle++;
            
        require(Users[_addr].payouts >= this.maxPayoutOf(Users[_addr].depositAmount), "Deposit already exists");
        require(_amount >= Users[_addr].depositAmount && _amount <= Levels[Users[_addr].cycle > Levels.length - 1 ? Levels.length - 1 : Users[_addr].cycle], "Bad amount");
        }
        else require(_amount >= 1e18 && _amount <= Levels[0], "Bad amount");
        
        Users[_addr].payouts = 0;
        Users[_addr].depositAmount = _amount;
        Users[_addr].depositPayouts = 0;
        Users[_addr].depositTime = uint40(block.timestamp);
        Users[_addr].totalDeposits = Users[_addr].totalDeposits.add(_amount);

        totalDeposited =  totalDeposited.add(_amount);
        
        _token.transferFrom(msg.sender,address(this),_amount);

        if(Users[_addr].upline != address(0)) {
         Users[Users[_addr].upline].referalBonus = Users[Users[_addr].upline].referalBonus.add(_amount.mul(10e18).div(100e18));
         emit Referalamount(_addr,Users[_addr].upline,_amount.mul(10e18).div(100e18),block.timestamp);

           
        }
        emit Deposit(_addr,Users[_addr].upline,_amount,block.timestamp);

        uint adminFee = _amount.mul(5e18).div(100e18);
        admin1.transfer(adminFee.mul(2.5e18).div(100e18));
        emit Adminshare(_addr,admin1,adminFee.mul(2.5e18).div(100e18),block.timestamp);
        admin2.transfer(adminFee.mul(2.5e18).div(100e18));
        emit Adminshare(_addr,admin2,adminFee.mul(2.5e18).div(100e18),block.timestamp);
        adminFee = 0;
        _refAmount(_addr,Users[_addr].upline,_amount);
    }
    
    function deposit(address _upline) payable isLock external {
        _setUpline(msg.sender, _upline);
        _deposit(msg.sender, msg.value);
    }
    
    function _matchBonus(address user,uint amount)private{
        address up = Users[user].upline;
        for(uint i = 1;i <= 21;i++){
        if(up == address(0))break;
           if(i<=3){
               Users[up].matchBonus = Users[up].matchBonus.add(amount.mul(3e18).div(100e18));
                emit Matchbonus(user,up,amount.mul(3e18).div(100e18),block.timestamp);
           }
           else if(i <= 6){
               if(Users[up].referrals >= 2){
               Users[up].matchBonus = Users[up].matchBonus.add(amount.mul(3e18).div(100e18));
                emit Matchbonus(user,up,amount.mul(3e18).div(100e18),block.timestamp);
               }
           }
           else if(i<=10){
               if(Users[up].referrals >= 4){
               Users[up].matchBonus = Users[up].matchBonus.add(amount.mul(3e18).div(100e18));
                emit Matchbonus(user,up,amount.mul(3e18).div(100e18),block.timestamp);
               }
           }
           else if(i<=14){
               if(Users[up].referrals >= 8){
               Users[up].matchBonus = Users[up].matchBonus.add(amount.mul(3e18).div(100e18));
                emit Matchbonus(user,up,amount.mul(3e18).div(100e18),block.timestamp);
               }
           }
           else if(i<=21){
               if(Users[up].referrals >= 16){
               Users[up].matchBonus = Users[up].matchBonus.add(amount.mul(3e18).div(100e18));
                emit Matchbonus(user,up,amount.mul(3e18).div(100e18),block.timestamp);
               }
           }
           up = Users[up].upline;
          
        }
        
    }
    
    function withdraw() isLock external {
        (uint256 to_payout, uint256 max_payout) = this.payoutOf(msg.sender);
        
        require(Users[msg.sender].payouts < max_payout, "Full payouts");

        // Deposit payout
        if(to_payout > 0) {
            if(Users[msg.sender].payouts.add(to_payout) > max_payout) {
                to_payout = max_payout.sub(Users[msg.sender].payouts);
             }

            Users[msg.sender].depositPayouts = Users[msg.sender].depositPayouts.add(to_payout);
            Users[msg.sender].payouts = Users[msg.sender].payouts.add(to_payout);

            _matchBonus(msg.sender, to_payout);
        }
        
        // referal earn
         if(Users[msg.sender].payouts < max_payout && Users[msg.sender].referalBonus > 0 ){
             if(Users[msg.sender].payouts.add(Users[msg.sender].referalBonus) > max_payout){
                 Users[msg.sender].referalBonus = max_payout.sub(Users[msg.sender].payouts);
             }
            
             
             Users[msg.sender].payouts = Users[msg.sender].payouts.add(Users[msg.sender].referalBonus);
             to_payout = to_payout.add(Users[msg.sender].referalBonus);
             Users[msg.sender].referalBonus = Users[msg.sender].referalBonus.sub(Users[msg.sender].referalBonus);
         }
         
          // matching bonus
        if(Users[msg.sender].payouts < max_payout && Users[msg.sender].matchBonus > 0){
             if(Users[msg.sender].payouts.add(Users[msg.sender].matchBonus) > max_payout){
                 Users[msg.sender].matchBonus = max_payout.sub(Users[msg.sender].payouts);
             }
            Users[msg.sender].payouts = Users[msg.sender].payouts.add(Users[msg.sender].matchBonus);
            to_payout = to_payout.add(Users[msg.sender].matchBonus);
            Users[msg.sender].matchBonus = Users[msg.sender].matchBonus.sub(Users[msg.sender].matchBonus);
             
            
        }
        totalWithdraw = totalWithdraw.add(to_payout);
        
         msg.sender.transfer(to_payout);
         emit Withdraw(msg.sender,to_payout,block.timestamp);
    }
    
    function maxPayoutOf(uint256 _amount) pure external returns(uint256) {
        return _amount.mul(5).div(100);
    }

    function payoutOf(address _addr) view external returns(uint256 payout, uint256 max_payout) {
        max_payout = this.maxPayoutOf(Users[_addr].depositAmount);

        if(Users[_addr].depositPayouts < max_payout) {
            payout =  ((Users[_addr].depositAmount.mul(1e18).div(100e18)) * ((block.timestamp.sub(Users[_addr].depositTime)).div(60))) - Users[_addr].depositPayouts;
            
            if(Users[_addr].depositPayouts.add(payout) > max_payout) {
                payout = max_payout.sub(Users[_addr].depositPayouts);
            }
        }
    }
    
    function userInfo(address _addr) view external returns(address upline, uint40 deposit_time, uint256 deposit_amount, uint256 payouts, uint256 match_bonus) {
        return (Users[_addr].upline, Users[_addr].depositTime, Users[_addr].depositAmount, Users[_addr].payouts,  Users[_addr].matchBonus);
    }

    function userInfoTotals(address _addr) view external returns(uint256 referrals, uint256 total_deposits,  uint256 total_structure) {
        return (Users[_addr].referrals, Users[_addr].totalDeposits,  Users[_addr].totalStructure);
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
}