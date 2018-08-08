pragma solidity ^0.4.19;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;
  
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() internal {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

contract tokenInterface {
	function balanceOf(address _owner) public constant returns (uint256 balance);
	function transfer(address _to, uint256 _value) public returns (bool);
}

contract rateInterface {
    function readRate(string _currency) public view returns (uint256 oneEtherValue);
}

contract RC {
    using SafeMath for uint256;
    TokenSale tokenSaleContract;
    uint256 public startTime;
    uint256 public endTime;
    
    uint256 public soldTokens;
    uint256 public remainingTokens;
    
    uint256 public oneTokenInEurWei;

    function RC(address _tokenSaleContract, uint256 _oneTokenInEurWei, uint256 _remainingTokens,  uint256 _startTime , uint256 _endTime ) public {
        require ( _tokenSaleContract != 0 );
        require ( _oneTokenInEurWei != 0 );
        require( _remainingTokens != 0 );
        
        tokenSaleContract = TokenSale(_tokenSaleContract);
        
        tokenSaleContract.addMeByRC();
        
        soldTokens = 0;
        remainingTokens = _remainingTokens;
        oneTokenInEurWei = _oneTokenInEurWei;
        
        setTimeRC( _startTime, _endTime );
    }
    
    function setTimeRC(uint256 _startTime, uint256 _endTime ) internal {
        if( _startTime == 0 ) {
            startTime = tokenSaleContract.startTime();
        } else {
            startTime = _startTime;
        }
        if( _endTime == 0 ) {
            endTime = tokenSaleContract.endTime();
        } else {
            endTime = _endTime;
        }
    }
    
    modifier onlyTokenSaleOwner() {
        require(msg.sender == tokenSaleContract.owner() );
        _;
    }
    
    function setTime(uint256 _newStart, uint256 _newEnd) public onlyTokenSaleOwner {
        if ( _newStart != 0 ) startTime = _newStart;
        if ( _newEnd != 0 ) endTime = _newEnd;
    }
    
    event BuyRC(address indexed buyer, bytes trackID, uint256 value, uint256 soldToken, uint256 valueTokenInEurWei );
    
    function () public payable {
        require( now > startTime );
        require( now < endTime );
        //require( msg.value >= 1*10**18); //1 Ether
        require( remainingTokens > 0 );
        
        uint256 tokenAmount = tokenSaleContract.buyFromRC.value(msg.value)(msg.sender, oneTokenInEurWei, remainingTokens);
        
        remainingTokens = remainingTokens.sub(tokenAmount);
        soldTokens = soldTokens.add(tokenAmount);
        
        BuyRC( msg.sender, msg.data, msg.value, tokenAmount, oneTokenInEurWei );
    }
}

contract TokenSale is Ownable {
    using SafeMath for uint256;
    tokenInterface public tokenContract;
    rateInterface public rateContract;
    
    address public wallet;
    address public advisor;
    uint256 public advisorFee; // 1 = 0,1%
    
	uint256 public constant decimals = 18;
    
    uint256 public endTime;  // seconds from 1970-01-01T00:00:00Z
    uint256 public startTime;  // seconds from 1970-01-01T00:00:00Z

    mapping(address => bool) public rc;


    function TokenSale(address _tokenAddress, address _rateAddress, uint256 _startTime, uint256 _endTime) public {
        tokenContract = tokenInterface(_tokenAddress);
        rateContract = rateInterface(_rateAddress);
        setTime(_startTime, _endTime); 
        wallet = msg.sender;
        advisor = msg.sender;
        advisorFee = 0 * 10**3;
    }
    
    function tokenValueInEther(uint256 _oneTokenInEurWei) public view returns(uint256 tknValue) {
        uint256 oneEtherInEur = rateContract.readRate("eur");
        tknValue = _oneTokenInEurWei.mul(10 ** uint256(decimals)).div(oneEtherInEur);
        return tknValue;
    } 
    
    modifier isBuyable() {
        require( now > startTime ); // check if started
        require( now < endTime ); // check if ended
        require( msg.value > 0 );
		
		uint256 remainingTokens = tokenContract.balanceOf(this);
        require( remainingTokens > 0 ); // Check if there are any remaining tokens 
        _;
    }
    
    event Buy(address buyer, uint256 value, address indexed ambassador);
    
    modifier onlyRC() {
        require( rc[msg.sender] ); //check if is an authorized rcContract
        _;
    }
    
    function buyFromRC(address _buyer, uint256 _rcTokenValue, uint256 _remainingTokens) onlyRC isBuyable public payable returns(uint256) {
        uint256 oneToken = 10 ** uint256(decimals);
        uint256 tokenValue = tokenValueInEther(_rcTokenValue);
        uint256 tokenAmount = msg.value.mul(oneToken).div(tokenValue);
        address _ambassador = msg.sender;
        
        
        uint256 remainingTokens = tokenContract.balanceOf(this);
        if ( _remainingTokens < remainingTokens ) {
            remainingTokens = _remainingTokens;
        }
        
        if ( remainingTokens < tokenAmount ) {
            uint256 refund = (tokenAmount - remainingTokens).mul(tokenValue).div(oneToken);
            tokenAmount = remainingTokens;
            forward(msg.value-refund);
			remainingTokens = 0; // set remaining token to 0
             _buyer.transfer(refund);
        } else {
			remainingTokens = remainingTokens.sub(tokenAmount); // update remaining token without bonus
            forward(msg.value);
        }
        
        tokenContract.transfer(_buyer, tokenAmount);
        Buy(_buyer, tokenAmount, _ambassador);
		
        return tokenAmount; 
    }
    
    function forward(uint256 _amount) internal {
        uint256 advisorAmount = _amount.mul(advisorFee).div(10**3);
        uint256 walletAmount = _amount - advisorAmount;
        advisor.transfer(advisorAmount);
        wallet.transfer(walletAmount);
    }

    event NewRC(address contr);
    
    function addMeByRC() public {
        require(tx.origin == owner);
        
        rc[ msg.sender ]  = true;
        
        NewRC(msg.sender);
    }
    
    function setTime(uint256 _newStart, uint256 _newEnd) public onlyOwner {
        if ( _newStart != 0 ) startTime = _newStart;
        if ( _newEnd != 0 ) endTime = _newEnd;
    }
    
    modifier onlyOwnerOrRC() {
        require( rc[msg.sender] || msg.sender == owner );
        _;
    }

    function withdraw(address to, uint256 value) public onlyOwner {
        to.transfer(value);
    }
    
    function withdrawTokens(address to, uint256 value) public onlyOwnerOrRC returns (bool) {
        return tokenContract.transfer(to, value);
    }
    
    function setTokenContract(address _tokenContract) public onlyOwner {
        tokenContract = tokenInterface(_tokenContract);
    }

    function setWalletAddress(address _wallet) public onlyOwner {
        wallet = _wallet;
    }
    
    function setAdvisorAddress(address _advisor) public onlyOwner {
            advisor = _advisor;
    }
    
    function setAdvisorFee(uint256 _advisorFee) public onlyOwner {
            advisorFee = _advisorFee;
    }
    
    function setRateContract(address _rateAddress) public onlyOwner {
        rateContract = rateInterface(_rateAddress);
    }

    function () public payable {
        revert();
    }
    
    function newRC(uint256 _oneTokenInEurWei, uint256 _remainingTokens) onlyOwner public {
        new RC(this, _oneTokenInEurWei, _remainingTokens, 0, 0 );
    }
}

contract PrivateSale {
    using SafeMath for uint256;
    TokenSale tokenSaleContract;
    uint256 public startTime;
    uint256 internal constant weekInSeconds = 604800; // seconds in a week
    uint256 public endTime;
    
    uint256 public soldTokens;
    uint256 public remainingTokens;
    
    uint256 public oneTokenInEurWei;

    function PrivateSale(address _tokenSaleContract, uint256 _oneTokenInEurWei, uint256 _remainingTokens,  uint256 _startTime , uint256 _endTime ) public {
        require ( _tokenSaleContract != 0 );
        require ( _oneTokenInEurWei != 0 );
        require( _remainingTokens != 0 );
        
        tokenSaleContract = TokenSale(_tokenSaleContract);
        
        tokenSaleContract.addMeByRC();
        
        soldTokens = 0;
        remainingTokens = _remainingTokens;
        oneTokenInEurWei = _oneTokenInEurWei;
        
        setTimeRC( _startTime, _endTime );
    }
    
    function setTimeRC(uint256 _startTime, uint256 _endTime ) internal {
        if( _startTime == 0 ) {
            startTime = tokenSaleContract.startTime();
        } else {
            startTime = _startTime;
        }
        if( _endTime == 0 ) {
            endTime = tokenSaleContract.endTime();
        } else {
            endTime = _endTime;
        }
    }
    
    modifier onlyTokenSaleOwner() {
        require(msg.sender == tokenSaleContract.owner() );
        _;
    }
    
    function setTime(uint256 _newStart, uint256 _newEnd) public onlyTokenSaleOwner {
        if ( _newStart != 0 ) startTime = _newStart;
        if ( _newEnd != 0 ) endTime = _newEnd;
    }
    
    event BuyRC(address indexed buyer, bytes trackID, uint256 value, uint256 soldToken, uint256 valueTokenInEurWei );
    
    function () public payable {
        require( now > startTime );
        require( now < endTime );
        //require( msg.value >= 1*10**18); //1 Ether
        require( remainingTokens > 0 );
        
        uint256 tokenAmount = tokenSaleContract.buyFromRC.value(msg.value)(msg.sender, oneTokenInEurWei, remainingTokens);
        
        remainingTokens = remainingTokens.sub(tokenAmount);
        soldTokens = soldTokens.add(tokenAmount);
        
        uint256 bonusRate;
        if( now > startTime + weekInSeconds*0  ) { bonusRate = 1000; }
        if( now > startTime + weekInSeconds*1  ) { bonusRate = 800; }
        if( now > startTime + weekInSeconds*2  ) { bonusRate = 600; }
        if( now > startTime + weekInSeconds*3  ) { bonusRate = 400; }
        if( now > startTime + weekInSeconds*4  ) { bonusRate = 200; }
        if( now > startTime + weekInSeconds*5  ) { bonusRate = 0; }
        
        tokenSaleContract.withdrawTokens(msg.sender, tokenAmount.mul( bonusRate ).div(10**4) );
        
        BuyRC( msg.sender, msg.data, msg.value, tokenAmount, oneTokenInEurWei );
    }
}