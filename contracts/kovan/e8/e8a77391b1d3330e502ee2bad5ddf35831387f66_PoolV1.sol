/**
  Not This is not the complete code it will pushed soon.
*/
pragma solidity ^0.5.0;

import "./token.sol";
import "./1inch.sol";
// import "./itoken.sol";


interface IOracle{
	function getiTokenDetails(uint _poolIndex) external returns(string memory, string memory);
     function getTokenDetails(uint _poolIndex) external returns(address[] memory,uint[] memory,uint ,uint);
}

interface Iitokendeployer{
	function createnewitoken(string calldata _name, string calldata _symbol) external returns(address);
}

interface Iitoken{
	function mint(address account, uint256 amount) external returns (bool);
	function burn(address account, uint256 amount) external returns (bool);
	function balanceOf(address account) external view returns (uint256);
}

interface IPoolConfiguration{
	 function checkDao(address daoAddress) external returns(bool);
	 function getmanagmentfees() external view returns(uint256);
	 function getperformancefees() external view returns(uint256);
	 function getslippagerate() external view returns(uint256);
	 function getoracleaddress() external view returns(address);
}

contract PoolV1 is ERC20 {
    
    using SafeMath for uint;

	

    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
   	address public EXCHANGE_CONTRACT = 0x5e676a2Ed7CBe15119EBe7E96e1BB0f3d157206F;
	address public WETH_ADDRESS = 0x7816fBBEd2C321c24bdB2e2477AF965Efafb7aC0;
	address public DAI_ADDRESS = 0xc6196e00Fd2970BD91777AADd387E08574cDf92a;

	address public distributor;

	address public ASTRTokenAddress;
	
	address public managerAddresses;
	address public ChefAddress;
	address public _poolConf;

	uint256[] public holders;
	
	uint256 public WethBalance;

    address public itokendeployer;
	
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
		address owner;
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
	
	mapping(uint256 => uint256) public totalPoolbalance;
	
	mapping(uint256 => uint256) public poolPendingbalance;
	
	bool public active = true; 

	mapping(address => bool) public systemAddresses;
	
	modifier systemOnly {
	    require(systemAddresses[msg.sender], "system only");
	    _;
	}
	
	modifier DaoOnly{
	    require(IPoolConfiguration(_poolConf).checkDao(msg.sender), "dao only");
	    _;
	}
	
	modifier whitelistManager {
	    require(managerAddresses == msg.sender, "Manager only");
	    _;
	}

	modifier OracleOnly {
		require(IPoolConfiguration(_poolConf).getoracleaddress() == msg.sender, "Only Oracle contract");
		_;
	}
	
	event Transfer(address indexed src, address indexed dst, uint wad);
	event Withdrawn(address indexed from, uint value);
	event WithdrawnToken(address indexed from, address indexed token, uint amount);
	
	
	constructor(string memory name, string memory symbol, address _ASTRTokenAddress, address poolConfiguration,address _itokendeployer) public ERC20(name, symbol) {
		systemAddresses[msg.sender] = true;
		ASTRTokenAddress = _ASTRTokenAddress;
		managerAddresses = msg.sender;
		_poolConf = poolConfiguration;
		itokendeployer = _itokendeployer;
		distributor = 0x3C0579211A530ac1839CC672847973182bd2da31;
	}
	
	

	/**
     * @dev Update the Exhchange/Weth/DAI address this is only for testing phase in live version it will be removed.
     */
     
	function configurePoolContracts(address _exchange, address _weth, address _dai) public systemOnly{
		   	EXCHANGE_CONTRACT = _exchange;
	        WETH_ADDRESS = _exchange;
	        DAI_ADDRESS = _dai;		
	}
	
	/**
     * @dev Whitelist users for deposit on pool.
     * @param _address Account that needs to be whitelisted.
	 * @param _poolIndex Pool Index in which user wants to invest.
     */
     

    function whitelistaddress(address _address, uint _poolIndex) public whitelistManager {
		require(_poolIndex<poolInfo.length, "whitelistaddress: Invalid Pool Index");
	    require(!poolUserInfo[_poolIndex][_address].active,"whitelistaddress: Already whitelisted");
	    PoolUser memory newPoolUser = PoolUser(0, poolInfo[_poolIndex].currentRebalance,0,true,true);
        poolUserInfo[_poolIndex][_address] = newPoolUser;
	}

	/**
     * @dev Add new public pool by any users.
     * @param _tokens tokens to purchase in pool.
     * @param _weights Weight of new tokens.
	 * @param _threshold Threshold amount to purchase token.
	 * @param _rebalanceTime Next Rebalance time.
	 * @param _name itoken name.
	 * @param _symbol itoken symbol.
     */
	function addPublicPool(address[] memory _tokens, uint[] memory _weights,uint _threshold,uint _rebalanceTime,string memory _name,string memory _symbol) public{
        require (_tokens.length == _weights.length, "addNewList: Invalid config length");
        uint _totalWeight;
		address _itokenaddr;
		for(uint i = 0; i < _tokens.length; i++) {
			_totalWeight += _weights[i];
		}
        _itokenaddr = Iitokendeployer(itokendeployer).createnewitoken(_name, _symbol);
		poolInfo.push(PoolInfo({
            tokens : _tokens,   
            weights : _weights,        
            totalWeight : _totalWeight,      
            active : true,          
            rebaltime : _rebalanceTime,
            currentRebalance : 0,
            threshold: _threshold,
            lastrebalance: block.timestamp,
			name: _name,
			symbol: _symbol,
		    itokenaddr: _itokenaddr,
			owner: msg.sender
        }));
    }

	/**
     * @dev Add new public pool by any Astra its details will came from Oracle contract addresses
     */

    function addNewList() public systemOnly{
        uint _poolIndex = poolInfo.length;
        address[] memory _tokens; 
        uint[] memory _weights;
		uint _threshold;
		uint _rebalanceTime;
		string memory _name;
		string memory _symbol;
		address _itokenaddr;
		(_tokens, _weights,_threshold,_rebalanceTime) = IOracle(IPoolConfiguration(_poolConf).getoracleaddress()).getTokenDetails(_poolIndex);
        (_name,_symbol) = IOracle(IPoolConfiguration(_poolConf).getoracleaddress()).getiTokenDetails(_poolIndex);
	    require (_tokens.length == _weights.length, "addNewList: Invalid config length");
        uint _totalWeight;
		for(uint i = 0; i < _tokens.length; i++) {
			_totalWeight += _weights[i];
		}
        _itokenaddr = Iitokendeployer(itokendeployer).createnewitoken(_name, _symbol);

		poolInfo.push(PoolInfo({
            tokens : _tokens,   
            weights : _weights,        
            totalWeight : _totalWeight,      
            active : true,          
            rebaltime : _rebalanceTime,
            currentRebalance : 0,
            threshold: _threshold,
            lastrebalance: block.timestamp,
			name: _name,
			symbol: _symbol,
			itokenaddr: _itokenaddr,
			owner: address(this)
        }));
    }
	
	
	/**
     * @dev Buy token initially once threshold is reached this can only be called by poolIn function
     */
    function buytokens(uint _poolIndex) internal {
     require(_poolIndex<poolInfo.length, "Invalid Pool Index");
     address[] memory returnedTokens;
	 uint[] memory returnedAmounts;
     uint ethValue = poolPendingbalance[_poolIndex]; 
     uint[] memory buf3;
	 buf = buf3;
     
     (returnedTokens, returnedAmounts) = swap2(DAI_ADDRESS, ethValue, poolInfo[_poolIndex].tokens, poolInfo[_poolIndex].weights, poolInfo[_poolIndex].totalWeight,buf);
     
      for (uint i = 0; i < returnedTokens.length; i++) {
			tokenBalances[_poolIndex][returnedTokens[i]] += returnedAmounts[i];
	  }
	  
	  totalPoolbalance[_poolIndex] = totalPoolbalance[_poolIndex].add(ethValue);
	  poolPendingbalance[_poolIndex] = 0;
	  if (poolInfo[_poolIndex].currentRebalance == 0){
	      poolInfo[_poolIndex].currentRebalance = poolInfo[_poolIndex].currentRebalance.add(1);
	  }
		
    }
    
    function updateuserinfo(uint _amount,uint _poolIndex) internal { 
        
        if(poolUserInfo[_poolIndex][msg.sender].active){
            if(poolUserInfo[_poolIndex][msg.sender].currentPool < poolInfo[_poolIndex].currentRebalance){
                poolUserInfo[_poolIndex][msg.sender].currentBalance = poolUserInfo[_poolIndex][msg.sender].currentBalance.add(poolUserInfo[_poolIndex][msg.sender].pendingBalance);
                poolUserInfo[_poolIndex][msg.sender].currentPool = poolInfo[_poolIndex].currentRebalance;
                poolUserInfo[_poolIndex][msg.sender].pendingBalance = _amount;
            }
            else{
               poolUserInfo[_poolIndex][msg.sender].pendingBalance = poolUserInfo[_poolIndex][msg.sender].pendingBalance.add(_amount); 
            }
        }
       
    } 
    
    function getuserbalance(uint _poolIndex) public view returns(uint){
        return poolUserInfo[_poolIndex][msg.sender].currentBalance;
    }
    
    function chargepmanagmenfees(uint _amount) internal view returns (uint){
		uint manFees = IPoolConfiguration(_poolConf).getmanagmentfees();
        uint fees = _amount.mul(manFees).div(100);
        return fees;  
    }
    
    function chargePerformancefees(uint _amount) internal view returns (uint){
		uint perFees = IPoolConfiguration(_poolConf).getperformancefees();
        uint fees = _amount.mul(perFees).div(100);
        return fees;
        
    }

	function calculateMinimumRetrun(uint _amount) internal view returns (uint){
		uint256 sliprate= IPoolConfiguration(_poolConf).getslippagerate();
        uint rate = _amount.mul(sliprate).div(100);
        return _amount.sub(rate);
        
    }
    function claimRewards(uint _poolIndex) public {
        require(_poolIndex<poolInfo.length, "Invalid Pool Index");
    }  
    
    function check(address[] memory _tokens)public view returns(address,address,bool){
        bool checkaddress = (address(_tokens[0]) == address(DAI_ADDRESS));
        return (_tokens[0],DAI_ADDRESS,checkaddress);
    }
    /**
     * @dev Deposit in Indices pool either public pool or pool created by Astra.
     * @param _tokens Token in which user want to give the amount. Currenly ony DAI stable coin is used.
     * @param _values Amount to spend.
	 * @param _poolIndex Pool Index in which user wants to invest.
     */
	function poolIn(address[] memory _tokens, uint[] memory _values, uint _poolIndex) public payable  {
		require(poolUserInfo[_poolIndex][msg.sender].isenabled, "poolIn: Only whitelisted user");
		require(_poolIndex<poolInfo.length, "poolIn: Invalid Pool Index");
		require(_tokens.length <2 && _values.length<2, "poolIn: Only one token allowed");
		uint ethValue;
		uint fees;
		uint DAIValue;
		address[] memory returnedTokens;
	    uint[] memory returnedAmounts;
	    
	    _TokensDAI = returnedTokens;
	    _ValuesDAI = returnedAmounts;
		if(_tokens.length == 0) {
			require (msg.value > 0.001 ether, "0.001 ether min pool in");
			ethValue = msg.value;
			_TokensDAI.push(DAI_ADDRESS);
			_ValuesDAI.push(1);
    	    (returnedTokens, returnedAmounts) = swap(ETH_ADDRESS, ethValue, _TokensDAI, _ValuesDAI, 1);
    	    DAIValue = returnedAmounts[0];
     
		} else {
		    bool checkaddress = (address(_tokens[0]) == address(DAI_ADDRESS));
		    require(checkaddress,"poolIn: Can only submit Stable coin");
			require(msg.value == 0, "poolIn: Submit one token at a time");
			require(IERC20(DAI_ADDRESS).balanceOf(msg.sender) >= _values[0], "poolIn: Not enough Dai tokens");
			DAIValue = _values[0];
			require(DAIValue > 0.001 ether,"poolIn: Can only submit Stable coin");
			IERC20(DAI_ADDRESS).transferFrom(msg.sender,address(this),DAIValue);
		}
		 fees = chargepmanagmenfees(DAIValue);
         IERC20(DAI_ADDRESS).transfer(distributor, fees);
		 DAIValue = DAIValue.sub(fees);
		 poolPendingbalance[_poolIndex] = poolPendingbalance[_poolIndex].add(DAIValue);
		 uint checkbalance = totalPoolbalance[_poolIndex].add(poolPendingbalance[_poolIndex]);
		 updateuserinfo(DAIValue,_poolIndex);
		  if (poolInfo[_poolIndex].currentRebalance == 0){
		     if(poolInfo[_poolIndex].threshold <= checkbalance){
		        buytokens( _poolIndex);
		     }     
		  }
		 
		updateuserinfo(0,_poolIndex);
		Iitoken(poolInfo[_poolIndex].itokenaddr).mint(msg.sender, DAIValue);
	}

	 /**
     * @dev Withdraw from Pool using itoken.
	 * @param _poolIndex Pool Index to withdraw funds from.
     */
	function withdraw(uint _poolIndex) public {
	    require(_poolIndex<poolInfo.length, "Invalid Pool Index");
	    updateuserinfo(0,_poolIndex);
		uint _balance = poolUserInfo[_poolIndex][msg.sender].currentBalance;
		uint localWeight;
		if(totalPoolbalance[_poolIndex]>0){
			localWeight = _balance.mul(1 ether).div(totalPoolbalance[_poolIndex]);
		} 
		uint _amount;
		uint _totalAmount;
		uint fees;
		uint[] memory _distribution;
		Iitoken(poolInfo[_poolIndex].itokenaddr).burn(msg.sender, _balance);
		for (uint i = 0; i < poolInfo[_poolIndex].tokens.length; i++) {
		    uint withdrawBalance = tokenBalances[_poolIndex][poolInfo[_poolIndex].tokens[i]].mul(localWeight).div(1 ether);
		    if (withdrawBalance == 0) {
		        continue;
		    }
		    if (poolInfo[_poolIndex].tokens[i] == DAI_ADDRESS) {
		        _totalAmount += withdrawBalance;
		        continue;
		    }
		    IERC20(poolInfo[_poolIndex].tokens[i]).approve(EXCHANGE_CONTRACT, withdrawBalance);
		    
			(_amount, _distribution) = IOneSplit(EXCHANGE_CONTRACT).getExpectedReturn(IERC20(poolInfo[_poolIndex].tokens[i]), IERC20(DAI_ADDRESS), withdrawBalance, 2, 0);
			if (_amount == 0) {
		        continue;
		    }
		    _totalAmount += _amount;
			IOneSplit(EXCHANGE_CONTRACT).swap(IERC20(poolInfo[_poolIndex].tokens[i]), IERC20(DAI_ADDRESS), withdrawBalance, _amount, _distribution, 0);
		}
		if(_totalAmount>_balance){
			fees = chargePerformancefees(_totalAmount.sub(_balance));
			IERC20(DAI_ADDRESS).transfer(distributor, fees);
			IERC20(DAI_ADDRESS).transfer(msg.sender, _totalAmount.sub(fees));
		}
		else{
			IERC20(DAI_ADDRESS).transfer(msg.sender, _totalAmount);
		}
		if(poolUserInfo[_poolIndex][msg.sender].pendingBalance>0){
		 IERC20(DAI_ADDRESS).transfer(msg.sender, poolUserInfo[_poolIndex][msg.sender].pendingBalance);
		}
		Iitoken(poolInfo[_poolIndex].itokenaddr).burn(msg.sender, poolUserInfo[_poolIndex][msg.sender].pendingBalance);

        poolPendingbalance[_poolIndex] = poolPendingbalance[_poolIndex].sub( poolUserInfo[_poolIndex][msg.sender].pendingBalance);
        poolUserInfo[_poolIndex][msg.sender].pendingBalance = 0;
        totalPoolbalance[_poolIndex] = totalPoolbalance[_poolIndex].sub(_balance);
		poolUserInfo[_poolIndex][msg.sender].currentBalance = poolUserInfo[_poolIndex][msg.sender].currentBalance.sub(_balance);
		emit Withdrawn(msg.sender, _balance);
	}

	 /**
     * @dev Update pool function to do the rebalaning.
     * @param _tokens New tokens to purchase after rebalance.
     * @param _weights Weight of new tokens.
	 * @param _threshold Threshold amount to purchase token.
	 * @param _rebalanceTime Next Rebalance time.
	 * @param _poolIndex Pool Index to do rebalance.
     */
	function updatePool(address[] memory _tokens,uint[] memory _weights,uint _threshold,uint _rebalanceTime,uint _poolIndex) public {	    
	    require(block.timestamp >= poolInfo[_poolIndex].rebaltime," Rebalnce time not reached");
		// require(poolUserInfo[_poolIndex][msg.sender].currentBalance>poolInfo[_poolIndex].threshold,"Threshold not reached");
		if(poolInfo[_poolIndex].owner != address(this)){
		    require(_tokens.length == _weights.length, "invalid config length");
			require(poolInfo[_poolIndex].owner == msg.sender, "Only owner can update the punlic pool");
		}else{
			(_tokens, _weights,_threshold,_rebalanceTime) = IOracle(IPoolConfiguration(_poolConf).getoracleaddress()).getTokenDetails(_poolIndex);
		}

	    address[] memory newTokens;
	    uint[] memory newWeights;
	    uint newTotalWeight;
		
		uint _newTotalWeight;

		for(uint i = 0; i < _tokens.length; i++) {
			require (_tokens[i] != ETH_ADDRESS && _tokens[i] != WETH_ADDRESS);			
			_newTotalWeight += _weights[i];
		}
		
		newTokens = _tokens;
		newWeights = _weights;
		newTotalWeight = _newTotalWeight;

		rebalance(newTokens, newWeights,newTotalWeight,_poolIndex);
		poolInfo[_poolIndex].threshold = _threshold;
		poolInfo[_poolIndex].rebaltime = _rebalanceTime;
		if(poolPendingbalance[_poolIndex]>0){
		 buytokens(_poolIndex);   
		}
		
	}
	function setPoolStatus(bool _active,uint _poolIndex) public systemOnly {
		poolInfo[_poolIndex].active = _active;
	}	
	/*
	 * @dev sell array of tokens for ether
	 */
	function sellTokensForEther(address[] memory _tokens, uint[] memory _amounts) internal returns(uint) {
		uint _amount;
		uint _totalAmount;
		uint[] memory _distribution;
		for(uint i = 0; i < _tokens.length; i++) {
		    if (_amounts[i] == 0) {
		        continue;
		    }
		    
		    if (_tokens[i] == WETH_ADDRESS) {
		        _totalAmount += _amounts[i];
		        continue;
		    }
		    IERC20(_tokens[i]).approve(EXCHANGE_CONTRACT, _amounts[i]);
		    
			(_amount, _distribution) = IOneSplit(EXCHANGE_CONTRACT).getExpectedReturn(IERC20(_tokens[i]), IERC20(WETH_ADDRESS), _amounts[i], 2, 0);
			if (_amount == 0) {
		        continue;
		    }
		    uint256 minReturn = calculateMinimumRetrun(_amount);
			_amount = IOneSplit(EXCHANGE_CONTRACT).swap(IERC20(_tokens[i]), IERC20(WETH_ADDRESS), _amounts[i], minReturn, _distribution, 0);

			_totalAmount += _amount;
		}

		return _totalAmount;
	}
	
	function sellTokensForDAI(address[] memory _tokens, uint[] memory _amounts) internal returns(uint) {
		uint _amount;
		uint _totalAmount;
		uint[] memory _distribution;
		for(uint i = 0; i < _tokens.length; i++) {
		    if (_amounts[i] == 0) {
		        continue;
		    }
		    
		    if (_tokens[i] == DAI_ADDRESS) {
		        _totalAmount += _amounts[i];
		        continue;
		    }
		    IERC20(_tokens[i]).approve(EXCHANGE_CONTRACT, _amounts[i]);
		    
			(_amount, _distribution) = IOneSplit(EXCHANGE_CONTRACT).getExpectedReturn(IERC20(_tokens[i]), IERC20(DAI_ADDRESS), _amounts[i], 2, 0);
			if (_amount == 0) {
		        continue;
		    }
		    uint256 minReturn = calculateMinimumRetrun(_amount);
		    _totalAmount += _amount;
			_amount = IOneSplit(EXCHANGE_CONTRACT).swap(IERC20(_tokens[i]), IERC20(DAI_ADDRESS), _amounts[i], minReturn, _distribution, 0);

			
		}

		return _totalAmount;
	}


	function rebalance(address[] memory newTokens, uint[] memory newWeights,uint newTotalWeight, uint _poolIndex) internal {
	    require(poolInfo[_poolIndex].currentRebalance >0, "No balance in Pool");
		uint[] memory buf2;
		buf = buf2;
		uint ethValue;
		address[] memory returnedTokens;
	    uint[] memory returnedAmounts;

		for (uint i = 0; i < poolInfo[_poolIndex].tokens.length; i++) {
			buf.push(tokenBalances[_poolIndex][poolInfo[_poolIndex].tokens[i]]);
			tokenBalances[_poolIndex][poolInfo[_poolIndex].tokens[i]] = 0;
		}
		
		if(totalPoolbalance[_poolIndex]>0){
		 ethValue = sellTokensForDAI(poolInfo[_poolIndex].tokens, buf);   
		}

		poolInfo[_poolIndex].tokens = newTokens;
		poolInfo[_poolIndex].weights = newWeights;
		poolInfo[_poolIndex].totalWeight = newTotalWeight;
		poolInfo[_poolIndex].currentRebalance = poolInfo[_poolIndex].currentRebalance.add(1);
		poolInfo[_poolIndex].lastrebalance = block.timestamp;
		
		if (ethValue == 0) {
		    return;
		}
		
		uint[] memory buf3;
		buf = buf3;
		
		if(totalPoolbalance[_poolIndex]>0){
		 (returnedTokens, returnedAmounts) = swap2(DAI_ADDRESS, ethValue, newTokens, newWeights,newTotalWeight,buf);
		
		for(uint i = 0; i < poolInfo[_poolIndex].tokens.length; i++) {
			tokenBalances[_poolIndex][poolInfo[_poolIndex].tokens[i]] = buf[i];
	    	
		}  
		}
		
	}

	function swap(address _token, uint _value, address[] memory _tokens, uint[] memory _weights, uint _totalWeight) internal returns(address[] memory, uint[] memory) {
		uint _tokenPart;
		uint _amount;
		uint[] memory _distribution;
        
		for(uint i = 0; i < _tokens.length; i++) { 
		    
		    _tokenPart = _value.mul(_weights[i]).div(_totalWeight);

			(_amount, _distribution) = IOneSplit(EXCHANGE_CONTRACT).getExpectedReturn(IERC20(_token), IERC20(_tokens[i]), _tokenPart, 2, 0);
		    uint256 minReturn = calculateMinimumRetrun(_amount);
		    _weights[i] = _amount;
			if (_token == ETH_ADDRESS) {
				_amount = IOneSplit(EXCHANGE_CONTRACT).swap.value(_tokenPart)(IERC20(_token), IERC20(_tokens[i]), _tokenPart, minReturn, _distribution, 0);
			} else {
			    IERC20(_tokens[i]).approve(EXCHANGE_CONTRACT, _tokenPart);
				_amount = IOneSplit(EXCHANGE_CONTRACT).swap(IERC20(_token), IERC20(_tokens[i]), _tokenPart, minReturn, _distribution, 0);
			}
			
		}
		
		return (_tokens, _weights);
	}
	
	function swap2(address _token, uint _value, address[] memory newTokens, uint[] memory newWeights,uint newTotalWeight, uint[] memory _buf) internal returns(address[] memory, uint[] memory) {
		uint _tokenPart;
		uint _amount;
		buf = _buf;
		
		uint[] memory _distribution;
		
		IERC20(_token).approve(EXCHANGE_CONTRACT, _value);
		
		for(uint i = 0; i < newTokens.length; i++) {
            
			_tokenPart = _value.mul(newWeights[i]).div(newTotalWeight);
			
			if(_tokenPart == 0) {
			    buf.push(0);
			    continue;
			}
			
			(_amount, _distribution) = IOneSplit(EXCHANGE_CONTRACT).getExpectedReturn(IERC20(_token), IERC20(newTokens[i]), _tokenPart, 2, 0);
			uint256 minReturn = calculateMinimumRetrun(_amount);
			buf.push(_amount);
            newWeights[i] = _amount;
			_amount= IOneSplit(EXCHANGE_CONTRACT).swap(IERC20(_token), IERC20(newTokens[i]), _tokenPart, minReturn, _distribution, 0);
		}
		return (newTokens, newWeights);
	}
}