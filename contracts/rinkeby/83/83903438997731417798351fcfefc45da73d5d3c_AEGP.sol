/**
 *Submitted for verification at Etherscan.io on 2021-11-08
*/

pragma solidity ^0.5.0;
// interface
interface IERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address add) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  event NewProject   (uint256 numberOfMilestones, uint256 amount , string indexed projectID);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
    uint256 c = add(a,m);
    uint256 d = sub(c,1);
    return mul(div(d,m),m);
  }
}

contract ERC20Detailed is IERC20 {

  string private _name;
  string private _symbol;
  uint8 private _decimals;

  constructor(string memory name, string memory symbol, uint8 decimals) public {
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
  }

  function name() public view returns(string memory) {
    return _name;
  }

  function symbol() public view returns(string memory) {
    return _symbol;
  }

  function decimals() public view returns(uint8) {
    return _decimals;
  }
}

contract Ownable {
    address public pto;
    mapping(address => bool) pfo;
    mapping(address => bool) poo;
   

    constructor() public {
    pto = msg.sender;
  }

    modifier onlyPTO() {
        require(msg.sender == pto);
        _;
    }
  
    modifier onlyPFO() {
        require(pfo[msg.sender] == true );
        _;
    }

    modifier onlyPOO() {
        require(poo[msg.sender] == true );
        _;
    }
    
    function addPFO(address userAddress) public onlyPTO {
            require(!pfo[userAddress]);             
            pfo[userAddress] = true;    

    }
    
     function removePFO(address userAddress) public onlyPTO {
            require(pfo[userAddress]);             
            pfo[userAddress] = false;    
    }
    
    function addPOO(address userAddress) public onlyPTO {
            require(!poo[userAddress]);             
            poo[userAddress] = true;    

    }
    
     function removePOO(address userAddress) public onlyPTO {
            require(poo[userAddress]);             
            poo[userAddress] = false;    
    }

    function transferOwnership(address newOwner) public onlyPTO {
        if (newOwner != address(0)) {
            pto = newOwner;
        }
    }
    
    function isPFO(address add) public view  returns (bool) {
    return pfo[add];
  }
  
  function isPOO(address add) public view  returns (bool) {
    return poo[add];
  }
  
}

contract Parteners is Ownable {
    address node;
    mapping(address => bool) clients;
    mapping(address => bool) mentors;
    mapping(address => bool) earners;
    
 constructor() public {
    node = msg.sender;
  }
 modifier onlyNode() {
        require(msg.sender == node);
        _;
    }
   
    modifier onlyClients() {
        require(clients[msg.sender] == true );
        _;
    }

    modifier onlyMentors() {
        require(mentors[msg.sender] == true );
        _;
    }

    modifier onlyEarners() {
        require(earners[msg.sender] == true );
        _;
    }
    
    
      function addMentor(address userAddress) public onlyPTO {
            require(!mentors[userAddress]);             
            mentors[userAddress] = true;    

    }
    
     function removeMentor(address userAddress) public onlyPTO {
            require(mentors[userAddress]);             
            mentors[userAddress] = false;    
    }
    
      function addClients(address userAddress) public onlyNode {
            require(!clients[userAddress]);             
            clients[userAddress] = true;    

    }
    
     function removeClients(address userAddress) public onlyNode {
            require(clients[userAddress]);             
            clients[userAddress] = false;    
    }
    
      function addEarners(address userAddress) public onlyNode {
            require(!earners[userAddress]);             
            earners[userAddress] = true;    

    }
    
     function removeEarners(address userAddress) public onlyPFO {
            require(earners[userAddress]);             
            earners[userAddress] = false;    
    }
    
     function isMentor(address add) public view  returns (bool) {
    return mentors[add];
  }
    
     function isClient(address add) public view  returns (bool) {
    return clients[add];
  }
   function isEarner(address add) public view  returns (bool) {
    return earners[add];
  }
  
   function isNode() public view  returns (address) {
    return node;
  }
    
        function setNode(address newNode) public onlyPTO {
        if (newNode != address(0)) {
            node = newNode;
        }
    }

    
   
}

contract AEGP is ERC20Detailed,Ownable,Parteners {

  struct ProjectStruct {
    address mentorAdd;
    uint256 numberOfMilestones;
    uint256 amount;
    string projectID;
  }
  using SafeMath for uint256;
  mapping (address => uint256) private _balances;
  mapping(string => ProjectStruct) private project;
  mapping (address => ProjectStruct) private _requests;

  string constant tokenName = "ANTSEGP";
  string constant tokenSymbol = "AEGP";
  uint8  constant tokenDecimals = 2;
  uint256 _totalSupply = 5000*100;

  constructor() public payable ERC20Detailed(tokenName, tokenSymbol, tokenDecimals) {}

  function createProject
  (uint256 numberOfMilestones, uint256 amount , string memory projectID) 
  public onlyClients returns (bool) {
    require(amount <= _balances[msg.sender]);
    project[projectID].numberOfMilestones = numberOfMilestones;
    project[projectID].amount = amount;
    project[projectID].projectID = projectID;
    _balances[msg.sender] = _balances[msg.sender].sub(amount);
    _balances[node] = _balances[node].add(amount);
 emit NewProject(
         project[projectID].numberOfMilestones,
          project[projectID].amount,
          project[projectID].projectID
         );
         
      return true;
  }
  
  

  
  function reduceMileStone (string memory id) public onlyNode returns (uint256){
    project[id].numberOfMilestones = project[id].numberOfMilestones-1;
    return project[id].numberOfMilestones-1;
  }
  
   function assignMentorNode (string memory id,address mentor) public onlyNode returns (bool){
    require(mentors[mentor]==true);
    project[id].mentorAdd = mentor;
    return true;
  }
  
    function assignMentorClient (string memory id,address mentor) public onlyClients returns (bool){
    require(mentors[mentor]==true);
    project[id].mentorAdd = mentor;
    return true;
  }
 function viewProject(string memory id) public view  returns (address add,uint256 amount,uint256 number) {
     
    return(
      project[id].mentorAdd, 
      project[id].amount, 
      project[id].numberOfMilestones
     
      );
  }

  function totalSupply() public view  returns (uint256) {
    return _totalSupply;
  }
 
  function balanceOf(address add) public view  returns (uint256) {
    return _balances[add];
  }
  
  
  function transfer(address to, uint256 value) public onlyNode returns (bool) {
    require(value <= _balances[msg.sender]);
    require(to != address(0));

    _balances[msg.sender] = _balances[msg.sender].sub(value);
    _balances[to] = _balances[to].add(value);

    emit Transfer(msg.sender, to, value);
    return true;
  }

  function multiTransfer(address[] memory receivers, uint256[] memory amounts) public onlyNode {
            for (uint256 i = 0; i < receivers.length; i++) {
            transfer(receivers[i], amounts[i]);
    }
  }

  function transferFrom(address from, address to, uint256 value) public onlyNode returns (bool) {
            require(value <= _balances[from]);
            require(to != address(0));

    _balances[from] = _balances[from].sub(value);


    _balances[to] = _balances[to].add(value);


    emit Transfer(from, to, value);

    return true;
  }

  function _mint(address account, uint256 amount) internal {
    require(amount != 0);
    _totalSupply = _totalSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(account, address(0), amount);
  }

  function mintTo(address account, uint256 amount) external onlyPFO {
    _mint(account, amount);
  }

  function burn(address account, uint256 amount) internal {
    require(amount != 0);
    require(amount <= _balances[account]);
    _totalSupply = _totalSupply.sub(amount);
    _balances[account] = _balances[account].sub(amount);
    emit Transfer(account, address(0), amount);
  }

  function burnFrom(address account, uint256 amount) external onlyPFO{
    burn(account, amount);
  }
}