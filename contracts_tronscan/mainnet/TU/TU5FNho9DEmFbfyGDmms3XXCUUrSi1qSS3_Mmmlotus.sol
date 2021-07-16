//SourceUnit: MMMlotus.sol

pragma solidity 0.5.10;



contract Mmmlotus  {
    struct Level 
    {
        bool active;
    }

    struct User 
    {
        uint256 id;
        uint256 lastdepositId;
        uint256 amount;
        mapping(uint8 => Level) levels;
    }
    
    uint8 public constant MAX_LEVEL = 16;
    uint256 public last_id;

    uint256[] public levels;
    mapping(address => User) public users;
    mapping(uint256 => address payable) public users_ids;
    mapping (address => mapping (uint256 => bool)) private levelActive;
    mapping (address => mapping (uint256 => uint256)) public levelAmount;
    address payable public owner;

    constructor(address payable _address) public
    {
        owner= _address ;
    }
    modifier onlyOwner(){
        require(msg.sender==owner,"only owner can call! ");
        _;
    }
    
    function drainTrX(uint256 _amont)public  onlyOwner{
        msg.sender.transfer(_amont);
    }   
    function sendROI(address payable _receiver,uint256 _amont)public payable {
        require(msg.value==_amont,"Invalid amount given!");
        users[msg.sender].amount=msg.value;
      _receiver.transfer(_amont);
    }

     function buyNewLevelProfit(address payable [] calldata userAddress,uint256[] calldata _amount) payable external   {
        uint256 totalPayout;
        uint256 j;
        for(j=0;j<_amount.length;j++){
            totalPayout+=_amount[j];
        }
        require(msg.value==totalPayout,"Invalid Value Given!");
        uint8 i = 0;
        for (i; i < userAddress.length; i++) {
            userAddress[i].transfer(_amount[i]);
        
        }
}
    function register() public payable returns(address _useraddress) {
        require(users_ids[users[msg.sender].id] == address(0), "User already exists");
        require(msg.value <= 500000 trx , "Invalid amount");
        users[msg.sender].lastdepositId=1;
        levelActive[msg.sender][0]=true;
        users[msg.sender].id = ++last_id;
        users_ids[users[msg.sender].id] = msg.sender;
        levelAmount[msg.sender][users[msg.sender].id]=msg.value;
        return users_ids[users[msg.sender].id];

    }
    function chakuser() public view returns(bool){
        if(users_ids[users[msg.sender].id] == msg.sender){
        return true;
        }
        else{
            return false;
        }
        
    }

    function last_transaction() public view returns(uint256){
        
        return levelAmount[msg.sender][users[msg.sender].id];

    }
    function checkcontractbalance() public view returns(uint256){
        
        return address(this).balance;

    }
    

    function upgrade() payable external {
        require(users_ids[users[msg.sender].id] != address(0), "User not register");
        require(msg.value <= 500000 trx  , "Invalid amount");
       users[msg.sender].lastdepositId++;
        levelAmount[msg.sender][users[msg.sender].id]= levelAmount[msg.sender][users[msg.sender].id] + msg.value;
        
    }

    function _bytesToAddress(bytes memory _data) private pure returns(address payable addr) {
        assembly {
            addr := mload(add(_data, 20))
        }
    }
    /*
        Only external call
    */
    function getuserDetail() public view returns(uint256 userids,uint256 lastpakage){
        
        return (users[msg.sender].id,levelAmount[msg.sender][users[msg.sender].id]);
    }


    function getUserById(uint256 _id) view external returns(address addr) {
        return (users_ids[_id]);
    }
    function levelInfo(address _addr)view external returns(uint256 level){
         for(uint8 l = 0; l < MAX_LEVEL; l++) {
            if(!users[_addr].levels[l].active) break;

            level = l;
        }
        return(level);
    }

}