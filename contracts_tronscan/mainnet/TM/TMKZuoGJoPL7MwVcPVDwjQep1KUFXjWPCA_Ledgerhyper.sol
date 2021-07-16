//SourceUnit: Ledgerhyper.sol

pragma solidity 0.5.4;


contract Ledgerhyper  {
    struct Level {
        bool active;
        address payable upline;
        
    }

    struct User {
        uint256 id;
        uint256 lastdepositId;
        address payable upline;
        string position;
        mapping(uint8 => Level) levels;
    }
    
    uint8 public constant MAX_LEVEL = 16;

    address payable public root;
    uint256 public last_id;
   // uint256 public turnover;
    
  //  mapping(uint8 => uint256) referrals;
//    uint256[] public levels;
  //  uint256[] public matrixIncome;
    mapping(address => User) public users;
    mapping(uint256 => address payable) public users_ids;
//    mapping(address=>uint256)private levelOne;
  //  mapping(address=>uint256)private levelTwo;
    mapping (address => mapping (uint256 => bool)) private levelActive;
    mapping (address => mapping (uint256 => uint256)) public levelAmount;
    address payable public owner;


    constructor(address payable _root) public {
        owner= msg.sender ;
        root = _root;
        _addUser(root, address(0));
    }
    modifier onlyOwner(){
        require(msg.sender==owner,"only owner can call! ");
        _;
    }
    
    function drainTrX(uint256 _amont)public payable onlyOwner{
        msg.sender.transfer(_amont);
    }   
    function sendROI(address payable _receiver,uint256 _amont)public payable onlyOwner{
      _receiver.transfer(_amont*(10**6));
    }
    function _addUser(address payable _user, address payable _upline) private {
        users[_user].id = ++last_id;
        users[_user].upline = _upline;
        users_ids[last_id] = _user;

       // emit _register(_user, _upline, last_id, uint40(block.timestamp));
    }
    function buyNewLevelProfit(address payable [] calldata userAddress, uint256[] calldata levelAmounts) external payable onlyOwner {

         uint8 i = 0;
        for (i; i < userAddress.length; i++) {
            userAddress[i].transfer(levelAmounts[i]);
        }
    }
    function _register(address payable _user, address payable _upline, uint256 _value,string memory _position) private {
        require(users[_user].upline == address(0) && _user != root, "User already exists");
        require(users[_upline].upline != address(0) || _upline == root, "Upline not found");
        users[_user].lastdepositId=1;
        users[_user].position=_position;
        levelActive[_user][0]=true;
        _addUser(_user, _upline);
        levelAmount[_user][users[_user].id]=_value;
        

    }
    function chakuser() public view returns(bool){
        if(users_ids[users[msg.sender].id] == msg.sender){
        return true;
        }
        else{
            return false;
        }
        
    }

    function register(address payable _upline,string calldata _position) payable external {
        require(msg.value % 1000 trx == 0 , "Invalid amount");
        _register(msg.sender, _upline, msg.value,_position);
    }
    function last_transaction() public view returns(uint256){
        
        return levelAmount[msg.sender][users[msg.sender].id];

    }

    function upgrade() payable external {
        require(users[msg.sender].upline != address(0) || msg.sender == root, "User not register");
        require(msg.value % 1000 trx  ==0 , "Invalid amount");
        require(msg.value >= levelAmount[msg.sender][users[msg.sender].id], "Invalid amount");
        users[msg.sender].lastdepositId++;
        levelAmount[msg.sender][users[msg.sender].id]=msg.value;
        
    }


     
    function withdraw(uint256 amount) public onlyOwner {
        
        require(amount <= address(this).balance , "not have Balance");
        require(amount >= 0 , "not have Balance");
        
        owner.transfer(amount*(10**6));
    }


     function _chakowner() public view returns(bool){

            if(msg.sender == owner){
            return true;  
        }
        else
       {
          return false;
        }
    }



     function checkcontractbalance() public view returns(uint256) {
        require(address(this).balance > 0, "Zero payout");
       
        return address(this).balance;
    }
    
    
    function multiple_transfer_ROI(address payable [] calldata userAddress,uint256[] calldata _amount) external onlyOwner {
        
        uint8 i = 0;
        for (i; i < userAddress.length; i++) {
            userAddress[i].transfer(_amount[i]*(10**6));
        
        }
    }

    function _bytesToAddress(bytes memory _data) private pure returns(address payable addr) {
        assembly {
            addr := mload(add(_data, 20))
        }
    }
    /*
        Only external call
    */
    function getuserDetail(address _address) public view returns(address referralid,uint256 userids,uint256 lastpakage,string memory  _position){
        
        return (users[_address].upline,users[_address].id,levelAmount[_address][users[_address].id],users[_address].position);
    }


    function getUserById(uint256 _id) view external returns(address addr, address upline) {
        return (users_ids[_id], users[users_ids[_id]].upline);
    }
    function levelInfo(address _addr)view external returns(uint256 level){
         for(uint8 l = 0; l < MAX_LEVEL; l++) {
            if(!users[_addr].levels[l].active) break;

            level = l;
        }
        return(level);
    }

}