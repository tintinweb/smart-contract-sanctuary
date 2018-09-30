pragma solidity ^0.4.24;

contract Ownable {
    address public owner;

    constructor() public{
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

contract ERC20RewardToken {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  function decimals() public returns (uint8);
}

contract Reward is Ownable {
    
    ERC20RewardToken public token;
    address public presaleAddress;
    uint64 public doubleRewardEndTime = 1538006400;
    
    constructor(address _tokenAddr, address _presaleAddr) public {
        token = ERC20RewardToken(_tokenAddr);
        presaleAddress = _presaleAddr;
    }
    
    function get(address _receiver, uint256 _ethValue) external {

        require(msg.sender == presaleAddress);
        
        uint256 tokensValue = calculateValue(_ethValue, token.decimals());

        if(token.balanceOf(address(this)) > tokensValue) {
            token.transfer(_receiver, tokensValue);
        }
    }
    
	function setDoubleRewardEndTime(uint64 _time) onlyOwner external {
		doubleRewardEndTime = _time;
	}
	
    function calculateValue(uint256 _ethValue, uint8 decimals) view public returns (uint256 tokensValue) {
        
        uint8 TokensPerEthereum = 10;
        uint8 additionalBonusPercent = 10;
        
        if(_ethValue > 3 * 10**17)
            additionalBonusPercent = 25;
        if(_ethValue > 10**18)
            additionalBonusPercent = 30;
        if(_ethValue > 5 * 10**18)
            additionalBonusPercent = 60;
        
        tokensValue = _ethValue * TokensPerEthereum;
        
        tokensValue+= (tokensValue * additionalBonusPercent ) / 100;
        
        if(decimals < 18)
        {
            uint256 difference = 18 - uint256(decimals);
            tokensValue = tokensValue / 10**difference;
        }
        else if(decimals > 18)
        {
            difference = uint256(decimals) - 18;
            tokensValue = tokensValue * 10**difference;
        }
		
		// an additional small bonus to compensate for the difference in calculating the recommended price of the egg
		if(_ethValue > 10**18)
			tokensValue+= 3 * 10**(uint256(decimals) - 2);
        
        if(now <= doubleRewardEndTime)
            tokensValue*=2;
    }
    
    function () public payable {
        revert();
    }
    
    function withdraw() onlyOwner external {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }
}