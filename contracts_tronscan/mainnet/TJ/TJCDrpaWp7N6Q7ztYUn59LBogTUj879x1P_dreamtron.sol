//SourceUnit: matrix.sol

pragma solidity 0.5.10;

contract dreamtron{
    string name;
    address owner;
    struct Userdata
    {
        
         uint256 id;
         uint256 sponsorid;
         address trxaddress;
         uint8 x4id;
         uint8 x3id;
         uint256 myteam;
         
 
    }
    mapping(uint8 => uint) public pakages;
    event Deposit(address spender,uint256 amount,uint256 balance);
    event Transfer(address to,uint256 amount,uint256 balance);
    uint256 registableid =1;
    mapping(address => Userdata) public users;
    constructor (string memory _name)public {
        owner=msg.sender;
        name=_name;
         Userdata memory user=Userdata({
                id:1,
                sponsorid:0,
                trxaddress:msg.sender,
                x3id:10,
                x4id:10,
                myteam:0
  
            });
        users[msg.sender]= user;
         pakages[1]=1000000;
        pakages[2]=2000000;
        pakages[3]=3000000;
        pakages[4]=4000000;pakages[5]=5000000;pakages[6]=6000000;pakages[7]=7000000;pakages[8]=8000000;pakages[9]=9000000;pakages[10]=10000000;
        
    }
    
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }
     function getsponsorid(address user) public view returns (uint256) {
        return (users[user].id);
    }
    function getpackages(address useraddress) private returns(uint8)
    {
        return ((users[useraddress].x3id)+1);
    }
    
    function nextpack(uint8 pack) private returns(uint256)
    {
        return (pakages[pack]);
    }
     function registrationex(address referraladdress) public payable  returns(bool){
        
        
        require(!isUserExists(msg.sender),"user exists");
        require(isUserExists(referraladdress), "referrer not exists");
        registableid++;
        Userdata memory user=Userdata({
                id:registableid,
                sponsorid:getsponsorid(referraladdress),
                trxaddress:msg.sender,
                x3id:0,
                x4id:0,
                myteam:0
                

            });
            users[msg.sender] = user;
           
        require(nextpack(getpackages(msg.sender)) <=10000000,"wrong pack");
        require(msg.value>=nextpack(getpackages(msg.sender)),"insufficient balance");
        emit Deposit(msg.sender,msg.value,address(this).balance);
        
        transfer(owner,msg.value);
        return   true;
        
        
    }
    
  function buynextpack(address referraladdress) public payable  returns(bool){
        
        
        require(isUserExists(msg.sender),"user not exists");
        require(isUserExists(referraladdress), "referrer not exists");
        require(nextpack(getpackages(msg.sender)) <=10000000,"wrong pack");
        require(msg.value>=nextpack(getpackages(msg.sender)),"insufficient balance");
        emit Deposit(msg.sender,msg.value,address(this).balance);
        
        transfer(owner,msg.value);
        return   true;
        
        
    }
    
    function transfer(address  _to, uint256 _amount) private  {
        
         address(uint256(_to)).transfer(_amount);
        emit Transfer(_to,_amount,address(this).balance);
    }
}