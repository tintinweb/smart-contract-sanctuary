//SourceUnit: GT300.sol

pragma solidity 0.5.14;

library SafeMath {
   
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract GT300{
    
    using SafeMath for uint256;
    
    struct Level {
        uint256 price;
        uint256 profit;
    }
    
    struct user{
        uint256 id;
        address inviter;
        uint256 currentMatrix;
        address upline;
        address secondupline;
        uint256 totalEarns;
        mapping (uint256 => address[]) firstPartners;
        mapping (uint256 => address[]) secondPartners;
        mapping (uint256 => uint256) profitData;
        mapping (uint256 => uint256) holdData;
    } 
    
    Level[4] public levels;
    mapping(address => user) public users;
    mapping(uint256 => address) public users_ids;
    mapping(address => uint256) public rootBalance;
    uint256 public LastId;
    uint256 public RegFees = 300 * 1e6;
    uint8 totalMatrix = 4;
    uint256 public findFreeID = 1;
    address public root1;
    address public root2;
    uint8 contractLockStatus = 2; // 1 - unlock, 2 - lock
    
    address public admin1;
    address public admin2;

    event _SendFun(address indexed _from,address indexed receiver,uint256 receiverId,uint256 _amount,uint256 matrix,string _receiver);
    event Register(address indexed addr, address indexed upline, uint256 id);
    event Profit(address indexed addr, address indexed ProfitAdd,uint256 matrix, uint256 value);
    event Hold(address indexed addr, address indexed HolderAdd,uint256 matrix, uint256 value);    
 
    constructor(address _admin1,address _admin2,address _root1,address _root2) public{    
       admin1 = _admin1;
       admin2 = _admin2;
       root1 = _root1;
       root2 = _root2;
       
       LastId++;
       users[admin1].id = LastId;
       users_ids[LastId] = admin1;
       users[admin1].currentMatrix = 0;
       users[admin1].upline = root2;
       users[admin1].secondupline = root1;
       
       
       levels[0] = (Level(300 * 1e6 , 300 * 1e6));
       levels[1] = (Level(900 * 1e6 , 900 * 1e6));

       levels[2] = (Level(2700 * 1e6 , 2700 * 1e6));
       levels[3] = (Level(8100 * 1e6 , 32100 * 1e6));

    }
    
    modifier contractLockCheck(){
        require(contractLockStatus == 1, "inject is locked");
        _;
    }
     
    modifier OwnerOnly(){
        require(msg.sender == admin1, "Owner only accessible");
        _;
    }
    
    modifier isContractcheck(address _user) {
         require(!isContract(_user),"Invalid address");
        _;
    }
    
    function isContract(address account) public view returns (bool) {
        uint32 size;
        assembly {
                size := extcodesize(account)
            }
        if(size != 0)
            return true;
            
        return false;
    }
    
    function changeContractLockStatus( uint8 _status) public OwnerOnly returns(bool){
        require((_status == 1) || (_status == 2), "Number should be 1 or 2");
        
        contractLockStatus = _status;
        return true;
    }
    
    function _injectUserReg(address _user,address _inviter) public isContractcheck(msg.sender) OwnerOnly{
        require(users[_user].id == 0, "User arleady register");
        require(users[_inviter].id != 0, "Upline not register");
        
        regUser(_user,_inviter,RegFees,2);
    }

    function Registration(uint256 _refId) public contractLockCheck isContractcheck(msg.sender) payable {
        regUser(msg.sender,users_ids[_refId],msg.value,1);
    }
    
    function regUser(address userAdd,address Ref,uint256 amount,uint256 flag) private{
        require(amount == RegFees, "Amount is invalid");
        require(users[userAdd].id == 0, "User already exist");
        require(users[Ref].id != 0, "Referrer Id is invalid");
        
        LastId++;
        users[userAdd].id = LastId;
        users[userAdd].inviter = Ref;
        users[userAdd].currentMatrix = 0;
        
        users_ids[LastId] = userAdd;
        
        address findFreeAddress;
        
        for(uint256 i = findFreeID; i <= LastId; i++) {
            if(users[users_ids[i]].firstPartners[0].length < 2) {
                findFreeAddress = users_ids[i]; 
                break;
            }
            else if(users[users_ids[i]].firstPartners[0].length == 2) {
                findFreeID = i.add(1);
                continue;
            }
        }
        
        users[userAdd].upline = findFreeAddress;
        users[userAdd].secondupline = users[findFreeAddress].upline;
        
       emit Register(userAdd,findFreeAddress, LastId);
        
        
        levelUpdate(userAdd,users[userAdd].upline,users[userAdd].secondupline,0);
        
        if(users[userAdd].id > 3){
            uplineUpdate(users[userAdd].secondupline,0,userAdd,amount,flag);
        }else
           sendtrx(userAdd,users[userAdd].secondupline,amount,0,flag);
    }
    
    function levelUpdate(address _addr, address _upline,address _secondupline, uint256 matrix) private {
        if((_upline != root1) && (_upline != root2)) {
            users[_upline].firstPartners[matrix].push(_addr);
        }
        
        if((_secondupline != root1) && (_secondupline != root2)) {
            users[_secondupline].secondPartners[matrix].push(_addr);
        }
    }
    
    function uplineUpdate(address _upline,uint256 _matrix,address _from,uint256 _amount,uint256 flag) private{
        if((_upline == root1) || (_upline == root2)){
             return sendtrx(_from,_upline,_amount,_matrix,flag);
        }
        
        if(users[_upline].profitData[_matrix] < levels[users[_upline].currentMatrix % totalMatrix].profit){
            users[_upline].profitData[_matrix] =  users[_upline].profitData[_matrix].add(_amount);
           
            sendtrx(_from,_upline,_amount,_matrix,flag);
            
           emit Profit(_from, _upline ,_matrix, _amount);
        }
        
        else {
            users[_upline].holdData[_matrix] = users[_upline].holdData[_matrix].add(_amount);
            
           emit Hold(_from,_upline,_matrix,_amount);
            
            uint256 next_matrix = users[_upline].currentMatrix.add(1);
            
            if(users[_upline].holdData[_matrix] >= levels[next_matrix % totalMatrix].price ){
                users[_upline].currentMatrix = users[_upline].currentMatrix.add(1);
                
                levelUpdate(_upline,users[_upline].upline,users[_upline].secondupline,next_matrix);
                
            }
            
            uplineUpdate(users[_upline].secondupline,next_matrix,_from,_amount,flag);
               
        }
    }

    function sendtrx(address _user,address rec,uint256 amount,uint256 matrix,uint256 flag) private{
        if(flag == 1){
            
          if(rec != root1 && rec != root2 && rec != admin1){
              
             users[rec].totalEarns = users[rec].totalEarns.add(amount);
             
             require(address(uint160(rec)).send(amount), "transaction failed");
             
             emit _SendFun(_user,rec,users[rec].id,amount,matrix,"User");
          }else if(rec == admin1){
              users[admin1].totalEarns = users[admin1].totalEarns.add(amount);
              uint256 _amount = amount / 2;
              
              require(address(uint160(admin1)).send(_amount), "transaction failed");
              require(address(uint160(admin2)).send(_amount), "transaction failed");
             
              emit _SendFun(_user,root2,users[rec].id,_amount,matrix,"Root");
              
           }else{
              rootBalance[rec] = rootBalance[rec].add(amount);
             
              require(address(uint160(rec)).send(amount), "transaction failed");
             
              emit _SendFun(_user,root2,users[rec].id,amount,matrix,"Root");
           }
        }else users[rec].totalEarns = users[rec].totalEarns.add(amount);
    }
    
    function userMatrixDetails(uint256 id,uint256 matrix) public view returns(address[] memory firstPartners,address[] memory secondPartners,uint256 profit,uint256 hold){
        return (users[users_ids[id]].firstPartners[matrix],users[users_ids[id]].secondPartners[matrix],users[users_ids[id]].profitData[matrix],users[users_ids[id]].holdData[matrix]);
    }

}