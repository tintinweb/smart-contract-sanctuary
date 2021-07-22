/**
 *Submitted for verification at BscScan.com on 2021-07-22
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

pragma solidity ^0.8.0;
contract CoinFlip {
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    address public owner = msg.sender;
    address public dev = owner;
    uint public fee = 25; // 25 = 2.5%
    address public betToken;
    address public rewardToken;
    uint256 public rewardPercent = 800; // 800 = 80%
    uint256 public totalGameFlip = 0;
    
     
    /* ================== */
    // 1.Storage Data setting
    mapping(address => uint256) public gameResult;
    mapping(address => uint256) public playerReward;
    mapping(address => uint256) public totalRoundsBet;
    
    struct RoundsBetStorages{
        uint256 roundsBet; // round of betted;
        address playerAddress;
        uint256 playerAmountBet;
        uint256 playerBet;
        uint256 resultFlip;
        uint256 resultBet; // 0 = loss, 1 = win
    }
    RoundsBetStorages[] private _RoundsBetStorages;
    mapping(uint256 => RoundsBetStorages) public viewRoundsBetStorages;
   
    
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    
    function GameSetting (address _dev, uint _fee, address _betToken, address _rewardToken, uint256 _rewardPercent) public onlyOwner {
        dev = _dev;
        fee = _fee;
        betToken = _betToken;
        rewardToken = _rewardToken;
        rewardPercent = _rewardPercent;
    }
    
    
    /* ================== */
    // betting function
    uint256 privSeed;
    uint private result;
    
    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }

    function betting(uint _coinSide, uint _amount) public { 
        
        IERC20(betToken).transferFrom(msg.sender, address(this), _amount);
        
    	// Seeds
    	privSeed = (privSeed*3 + 1) / 2;
    	privSeed = privSeed % 10**9;
        
    	uint number = block.number; // ~ 10**5 ; 60000
    	uint diff = block.difficulty; // ~ 2 Tera = 2*10**12; 1731430114620
    	uint time = block.timestamp; // ~ 2 Giga = 2*10**9; 1439147273
    	uint gas = block.gaslimit; // ~ 3 Mega = 3*10**6
    	// Rand Number in Percent
    	uint total = privSeed + number + diff + time + gas;
    	result = total %2;
    	
    	gameResult[msg.sender] = result;
    	
    	uint256 _resultBet = 0;
    	
    	if(gameResult[msg.sender] == _coinSide)
    	  {
    	    playerReward[msg.sender] += _amount + ((_amount*rewardPercent)/1000);
    	    _resultBet = 1;
    	  }
    	totalGameFlip++;
    	totalRoundsBet[msg.sender]++;
    	
    	
    	// set addRoundsBetStorages is RoundsBetStorages struct
    	// add data in addRoundsBetStorages
    	RoundsBetStorages memory addRoundsBetStorages = RoundsBetStorages(totalGameFlip, msg.sender, _amount, _coinSide, result, _resultBet);
    	
    	// push data to array struct
    	_RoundsBetStorages.push(addRoundsBetStorages);
    	
    	// push 
    	viewRoundsBetStorages[totalGameFlip] = addRoundsBetStorages;
    }

    
    /* ================== */
    // withdraw reward function
    function withdrawReward(uint256 _amount) public {
        require(_amount <= playerReward[msg.sender], "Amount to withdraw too high");
        uint256 feeToDev = (playerReward[msg.sender] * fee) / 1000;
        uint256 playerReceived = playerReward[msg.sender] - feeToDev;
        
        
        playerReward[msg.sender] -= _amount;
        IERC20(rewardToken).transfer(dev, feeToDev);
        IERC20(rewardToken).transfer(msg.sender, playerReceived);
    }
    
    // Admin withdraw function
    function withdrawHouse(uint256 _amount) public onlyOwner{
        IERC20(rewardToken).transfer(owner, _amount); // withdraw token to owner
    }

}