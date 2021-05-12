/**
  Not This is not the complete code it will pushed soon.
*/
pragma solidity ^0.5.0;

import "./token.sol";
import "./1inch.sol";
// import "./itoken.sol";

interface Iitokendeployer{
	function createnewitoken(string calldata _name, string calldata _symbol) external returns(address);
}

interface IOracle{
	function getiTokenDetails(uint _poolIndex) external returns(string memory, string memory);
     function getTokenDetails(uint _poolIndex) external returns(address[] memory,uint[] memory,uint ,uint);
}

contract PoolConfiguration is ERC20 {
    
    using SafeMath for uint;

    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
   	address public EXCHANGE_CONTRACT = 0x5e676a2Ed7CBe15119EBe7E96e1BB0f3d157206F;
	address public WETH_ADDRESS = 0x7816fBBEd2C321c24bdB2e2477AF965Efafb7aC0;
	address public DAI_ADDRESS = 0xc6196e00Fd2970BD91777AADd387E08574cDf92a;
        
	address public ASTRTokenAddress;
	
	address public managerAddresses;
	address public ChefAddress;
	address public Oraclecontract;

	uint256[] public holders;
	
	uint256 public managmentfees = 2;
	
	uint256 public performancefees = 20;
	uint256 public slippagerate = 10;
	
	uint256 public WethBalance;
	
	address public distributor;

    address public OracleAddress;

    struct PoolInfo {
        address[] tokens;    
        uint256[]  weights;        
        uint256 totalWeight;      
        bool active;          
        uint256 rebaltime;
        uint256 threshold;
        uint256 currentRebalance;
        uint256 lastrebalance;
		string name;
		string symbol;
		address itokenaddr;
    }
    
    struct PoolUser 
    { 
        uint256 currentBalance; 
        uint256 currentPool; 
        uint256 pendingBalance; 
        bool active;
        bool isenabled;
    } 
    
    mapping ( uint256 =>mapping(address => PoolUser)) public poolUserInfo; 
    PoolInfo[] public poolInfo;
    
    uint256[] buf; 
    
    address[] _Tokens;
    uint256[] _Values;
    
    address[] _TokensDAI;
    uint256[] _ValuesDAI;
    
	mapping(uint256 => mapping(address => uint256)) public tokenBalances;
	
	mapping(uint256 => mapping(address => uint256)) public daatokenBalances;
	
	mapping(address => bool) public enabledDAO;
	
	mapping(uint256 => uint256) public totalPoolbalance;
	
	mapping(uint256 => uint256) public poolPendingbalance;
	
	bool public active = true; 

	mapping(address => bool) public systemAddresses;
	
	modifier systemOnly {
	    require(systemAddresses[msg.sender], "system only");
	    _;
	}
	
	modifier DaoOnly{
	    require(enabledDAO[msg.sender], "dao only");
	    _;
	}
	
	modifier whitelistManager {
	    require(managerAddresses == msg.sender, "Manager only");
	    _;
	}

	modifier OracleOnly {
		require(Oraclecontract == msg.sender, "Only Oracle contract");
		_;
	}
	
	event Transfer(address indexed src, address indexed dst, uint wad);
	event Withdrawn(address indexed from, uint value);
	event WithdrawnToken(address indexed from, address indexed token, uint amount);
	
	function addSystemAddress(address newSystemAddress) public systemOnly { 
	    systemAddresses[newSystemAddress] = true;
	}
	
	constructor(string memory name, string memory symbol, address _ASTRTokenAddress) public ERC20(name, symbol) {
		systemAddresses[msg.sender] = true;
		ASTRTokenAddress = _ASTRTokenAddress;
		managerAddresses = msg.sender;
		// distributor = 0x3C0579211A530ac1839CC672847973182bd2da31;
	}
	
	function whitelistDAOaddress(address _address) public whitelistManager {
	    require(!enabledDAO[_address],"whitelistDAOaddress: Already whitelisted");
	    enabledDAO[_address] = true;
	  
	}

	function setOracleaddress(address _address) public whitelistManager {
		require(_address != Oraclecontract, "setOracleaddress: Already set");
		Oraclecontract = _address;
	}

	function setdistributor(address _address) public whitelistManager {
		require(_address != distributor, "setdistributor: Already set");
		distributor = _address;
	}
	
	function removeDAOaddress(address _address) public whitelistManager {
	    require(enabledDAO[_address],"removeDAOaddress: Not whitelisted");
	    enabledDAO[_address] = false;
	  
	}
	
	function removefromwhitelist(address _address, uint _poolIndex) public whitelistManager{
	    require(poolUserInfo[_poolIndex][_address].active,"removefromwhitelist: Not whitelisted");
	    poolUserInfo[_poolIndex][_address].isenabled = false;
	}
	
	function updatewhitelistmanager(address _address) public whitelistManager{
	    require(_address != managerAddresses,"updatewhitelistmanager: Already Manager");
	    managerAddresses = _address;
	}
    
    function updatemanagfees (uint256 _feesper)public DaoOnly{
        require(_feesper<100,"updatemanagfees: Only less than 100");
        managmentfees = _feesper;
    }    

     function updatePerfees (uint256 _feesper) public DaoOnly{
        require(_feesper<100,"updatePerfees: Only less than 100");
        performancefees = _feesper;
    }
	function updateSlippagerate (uint256 _slippagerate) public DaoOnly{
        require(_slippagerate<100,"updateSlippagerate: Only less than 100");
        slippagerate = _slippagerate;
    }

	function getmanagmentfees() external view returns(uint256){
		return managmentfees;
	}

	function getperformancefees() external view returns(uint256){
		return performancefees;
	 }    

	  function checkDao(address daoAddress) external view returns(bool){
		  return enabledDAO[daoAddress];
	  }

	  function getoracleaddress() external view returns(address){
		  return Oraclecontract;
	  }

	  function getdistributor() external view returns(address){
		  return distributor;
	  }

	 function getslippagerate() external view returns(uint256){
		 return slippagerate;
	 }  
}