/*
    Tomato Private-Sale
    
    Rate: <1eth 1eth=10000   tomato
          <3eth 1eth=10000*2 tomato
	      <5eth 1eth=10000*3 tomato
	      >=5eth 1eth=10000*5 tomato

    Website: https://tomatoswap.xyz
    
*/

pragma solidity ^0.4.26;

interface token{
    
    function mint(address _to,uint amount) external;
    function transfer(address recipient, uint amount) external returns (bool);

}

contract SafeMath {
    function safeAdd(uint256 x, uint256 y) internal pure returns(uint256) {
        uint256 z = x + y;
        assert((z >= x) && (z >= y));
        return z;
    }

    function safeSubtract(uint256 x, uint256 y) internal pure returns(uint256) {
        assert(x >= y);
        uint256 z = x - y;
        return z;
    }

    function safeMult(uint256 x, uint256 y) internal pure returns(uint256) {
        uint256 z = x * y;
        assert((x == 0)||(z/x == y));
        return z;
    }

}

contract PreSale is SafeMath{
    
    uint public tokenExchangeRate; 
    
    address public beneficiary;

    bool public isFunding; 

    token public tokenReward;

    uint tokenAmount;

    event tokenMint(address backer,uint amount);     

    constructor() public {
        
        isFunding = true;  
                     
        beneficiary = msg.sender; 
        
         tokenExchangeRate = 10000;
	
	tokenReward = token(0xA42Cf329478e15E337CBE0025d19295B72b4bb16);
    }

    modifier isOwner()  { require(msg.sender == beneficiary); _; }

    function stopFunding() isOwner external {
        require(isFunding);
        isFunding = false;
    }

    function startFunding() isOwner external {
        require(!isFunding);
        isFunding = true;
    }
    
    function () public payable {
        buytoken();
    }
    
    function buytoken() public payable {
        
        require(isFunding);

        require(msg.value > 0);

	if (msg.value < 1 ether) {

	tokenAmount = safeMult(msg.value, tokenExchangeRate); 
	
	} else if (msg.value >= 1 ether && msg.value < 3 ether ) {

	tokenAmount = safeMult(msg.value, tokenExchangeRate*2); 

	} else if (msg.value >= 3 ether && msg.value < 5 ether ) {

	tokenAmount = safeMult(msg.value, tokenExchangeRate*3); 
	
	} else {

        tokenAmount = safeMult(msg.value, tokenExchangeRate*5); 
	
	}

        tokenReward.mint(msg.sender,tokenAmount);

        emit tokenMint(msg.sender, tokenAmount);  
        
    }
    
    function withdraw() isOwner external {  

    require(msg.sender == beneficiary);

    beneficiary.transfer(address(this).balance);

    }

}