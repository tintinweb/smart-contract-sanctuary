/**
 *Submitted for verification at polygonscan.com on 2021-09-10
*/

pragma solidity 0.8.7;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

contract MegaDoge{
    
    mapping (address => uint) private balance;
    mapping (address => mapping (address => uint)) private allowed;
	
	mapping (address => bool) private isAUser;
    
    address private DEV_ADDRESS;
    address[20] private aboveAverageTX;
    uint private aboveAverageTXOldestIndex;
    address[] private allUsers;
    uint private totalTransactions;
    uint private sumValueTX;
    uint private averageTX;
    
    uint private airDropIndex;
    uint private _totalSupply;
    
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor(string memory _name_, string memory _symbol_, uint8 _decimals_){
        DEV_ADDRESS = msg.sender;
        _name = _name_;
        _symbol = _symbol_;
        _decimals = _decimals_;
        mint();
    }
    
    receive() external payable {
        //Limited to 2300 gas
    }
    
    fallback() external payable { 
       //2300 gas is insufficient to do anything useful
    }
    
    //One time minting of 1 Billion Tokens (18 decimals)
    function mint() private{
        _totalSupply = (10**9)*(10**_decimals);
        balance[address(this)] = _totalSupply;//Airdrops will come from contract balance
    }
  
  function approve(address spender, uint value) external returns (bool){
      allowed[msg.sender][spender] = value;
      emit Approval(msg.sender, spender, value);
      return true;
  }
  
    function name() external view returns (string memory){
        return _name;
    }
    
    function symbol() external view returns (string memory){
        return _symbol;
    }
    
    function decimals() external view returns (uint8){
        return _decimals;
    }
    
    function totalSupply() external view returns (uint){
        return _totalSupply;
    }
    
    function balanceOf(address owner) external view returns (uint){
        return balance[owner];
    }
    
    function allowance(address owner, address spender) external view returns (uint){
        return allowed[owner][spender];
    }
    
  function transferFrom(address from, address to, uint256 value) external returns (bool){
    require(value <= balance[from], 'Insufficient balance');
    require(value <= allowed[from][msg.sender], 'Not enough allowance granted to spender to spend this much.');
    require(to != address(0), 'Not allowed to send to 0 address.');
    
    if(from == to){
        return true;
    }
    
    uint fee = value/50;
    uint amount = value - fee;

    balance[from] -= amount;
    balance[to] += amount;
    allowed[from][msg.sender] -= value;
    emit Transfer(from, to, value);
    
    payTopUsers(from, fee/2);
    updateTopUsers(from, value);
    
    bool isAboveAVG = (value > averageTX);
    payNext(msg.sender, fee/2, isAboveAVG);
    
    return true;
  }
    
    function transfer(address to, uint value) external returns(bool){
        require(balance[msg.sender] >= value, 'Insufficient balance');
        if(to == msg.sender){
            return true;
        }
        uint fee = value/50;
        uint amount = value - fee;
        balance[msg.sender] -= amount;
        balance[to] += amount;
        emit Transfer(msg.sender, to, value);
        
        payTopUsers(msg.sender, fee/2);
        updateTopUsers(msg.sender, value);
        
        bool isAboveAVG = (value > averageTX);
        payNext(msg.sender, fee/2, isAboveAVG);
        
        return true;
    }
    
    function updateTopUsers(address from, uint value) private{
        totalTransactions++;
        sumValueTX += value;
        averageTX = (sumValueTX / totalTransactions);
        bool aboveAVG = (value > averageTX) || (totalTransactions == 1);
        if(totalTransactions >= 20 && aboveAVG){
            aboveAverageTX[aboveAverageTXOldestIndex] = from;
            aboveAverageTXOldestIndex++;
            if(aboveAverageTXOldestIndex >= 20){
                aboveAverageTXOldestIndex = 0;
            }
        }else if(aboveAVG){
            for(uint i = 0; i < 20; i++){
                if(aboveAverageTX[i] == address(0)){
                    aboveAverageTX[i] = from;
                    i = 20;
                }
            }
        }
        
        if((!isAUser[from]) && aboveAVG){
            allUsers.push(from);
			isAUser[from] = true;
        }
    }
    
    function getAVG() external view returns(uint){
       return averageTX;
    }
    
    function getAllUsers() external view returns(address[] memory){
        return allUsers;
    }
    
    function getIndex() external view returns(uint){
        return aboveAverageTXOldestIndex;
    }
    
    function getTopRecentUsers() external view returns(address[20] memory){
        return aboveAverageTX;
    }
    
    function nextAirDrop() external view returns(address){
        return allUsers[aboveAverageTXOldestIndex];
    }
    
    function airDrop1(address drop, uint amount) public{
        assert(msg.sender == DEV_ADDRESS);
        require(balance[address(this)] >= amount, 'No more tokens left to air drop.');
        balance[address(this)] -= amount;
        balance[drop] += amount;
        emit Transfer(address(this), drop, amount);
    }
	
	function airDropBulk(address[] memory drops) public{
        assert(msg.sender == DEV_ADDRESS);
        uint amount = 1000*10**_decimals;
        for(uint i = 0; i < drops.length; i++){
            require(balance[address(this)] < amount, 'No more tokens left to air drop.');
            if(drops[i] != address(0)){
                airDrop1(drops[i], amount);
            }else{
                return;
            }
        }
    }
    
    //Should be used to deposit liquidity into trading pools
    function withdraw(uint amount) public{
        assert(msg.sender == DEV_ADDRESS);
		require(balance[address(this)] >= amount, 'Insufficient contract balance');
        balance[address(this)] -= amount;
        balance[DEV_ADDRESS] += amount;
    }
    
    function payNext(address from, uint amount, bool isAboveAVG) private{
        if(allUsers.length == 0){
            return;
        }
        if(airDropIndex >= allUsers.length){
            airDropIndex = 0;
        }
        address nextUser = allUsers[airDropIndex];//Check out of bounds behavior
        if(isAboveAVG){
            airDropIndex += 1;
        }
        if(nextUser != address(0)){
            balance[from] -= amount;
            balance[nextUser] += amount;
            emit Transfer(from, nextUser, amount);
        }
    }
    
    function payTopUsers(address from, uint amount) private{
        uint commission = amount / 20;
        uint spent = payTop(from, aboveAverageTX, commission);
		uint leftOver = (amount - spent);
		if(leftOver > 0){
			address user = aboveAverageTX[aboveAverageTXOldestIndex];
			balance[from] -= leftOver;
            balance[user] += leftOver;
			emit Transfer(from, user, leftOver);
		}
    }
    
    function payTop(address from, address[20] memory users, uint commission) private returns(uint){
		uint spent;
        for(uint i = 0; i < 20; i++){
            address nextTopUser = users[i];
            if(nextTopUser != address(0)){
                balance[from] -= commission;
                balance[nextTopUser] += commission;
                emit Transfer(from, nextTopUser, commission);
				spent += commission;
            }
        }
		return(spent);
    }
	
	//In case anyone sends eth / matic to contract
	function extract() public {
		uint bal = address(this).balance;
        DEV_ADDRESS.call{value:bal}("");
    }
    
	//In case anyone sends tokens to contract
    function extractToken(address _token) public{
        IERC20 token = IERC20(_token);
        uint bal = token.balanceOf(address(this));
        token.transfer(DEV_ADDRESS, bal);
    }
}