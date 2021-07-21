/**
 *Submitted for verification at BscScan.com on 2021-07-21
*/

pragma solidity >0.4.0 <= 0.8.0;

contract CoinFlip {

    function () external payable {}
    
    address public owner = msg.sender;
    address public dev = owner;
    uint public fee = 5; // 5%
    address public betToken;
    address public rewardToken;
    uint private rounds = 0;
    
    constructor (address _dev, uint _fee, address payable _betToken, address _rewardToken) public {
        dev = _dev;
        fee = _fee;
        betToken = _betToken;
        rewardToken = _rewardToken;

    }
    /* ================== */
    event Deposit(address sender, uint256 amount, uint256 balance);
    event Withdraw(uint256 amount, uint256 balance);
    event Transfer(address indexed from, address indexed to, uint256 value);

     // 1.Storage Data setting
    mapping(address => uint256) public playerResult;
    mapping(address => uint256) public playerReward;
    
     modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    
    
    
    //uint256 public betAmount;
    uint256 privSeed;
    uint private result;

    function betting(uint _coinSide, uint _amount) external { 
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
	
	playerResult[msg.sender] = result;
	
	if(playerResult[msg.sender] == _coinSide)
	  {
	    playerReward[msg.sender] += (_amount+(_amount*80)/100);
	  }
	  
	  
    }

    function deposit(uint256 _amount) public payable {
        require(_amount > 0, 'balance not eougth.');

        emit Deposit(msg.sender, _amount, address(this).balance);
    }
    function withdraw(uint256 _amount) public payable {
        require(playerReward[msg.sender] >= _amount, "Amount to withdraw too high");

        if (playerReward[msg.sender] <= _amount) {
            emit Transfer(address(rewardToken), msg.sender, _amount);
        }
    }

}