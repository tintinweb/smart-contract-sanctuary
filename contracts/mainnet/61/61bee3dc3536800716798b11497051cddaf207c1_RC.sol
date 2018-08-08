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
    emit OwnershipTransferred(owner, newOwner);
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

contract ICOEngineInterface {

    // false if the ico is not started, true if the ico is started and running, true if the ico is completed
    function started() public view returns(bool);

    // false if the ico is not started, false if the ico is started and running, true if the ico is completed
    function ended() public view returns(bool);

    // time stamp of the starting time of the ico, must return 0 if it depends on the block number
    function startTime() public view returns(uint);

    // time stamp of the ending time of the ico, must retrun 0 if it depends on the block number
    function endTime() public view returns(uint);

    // Optional function, can be implemented in place of startTime
    // Returns the starting block number of the ico, must return 0 if it depends on the time stamp
    // function startBlock() public view returns(uint);

    // Optional function, can be implemented in place of endTime
    // Returns theending block number of the ico, must retrun 0 if it depends on the time stamp
    // function endBlock() public view returns(uint);

    // returns the total number of the tokens available for the sale, must not change when the ico is started
    function totalTokens() public view returns(uint);

    // returns the number of the tokens available for the ico. At the moment that the ico starts it must be equal to totalTokens(),
    // then it will decrease. It is used to calculate the percentage of sold tokens as remainingTokens() / totalTokens()
    function remainingTokens() public view returns(uint);

    // return the price as number of tokens released for each ether
    function price() public view returns(uint);
}

contract KYCBase {
    using SafeMath for uint256;

    mapping (address => bool) public isKycSigner;
    mapping (uint64 => uint256) public alreadyPayed;

    event KycVerified(address indexed signer, address buyerAddress, uint64 buyerId, uint maxAmount);

    function KYCBase(address [] kycSigners) internal {
        for (uint i = 0; i < kycSigners.length; i++) {
            isKycSigner[kycSigners[i]] = true;
        }
    }

    // Must be implemented in descending contract to assign tokens to the buyers. Called after the KYC verification is passed
    function releaseTokensTo(address buyer) internal returns(bool);

    // This method can be overridden to enable some sender to buy token for a different address
    function senderAllowedFor(address buyer)
        internal view returns(bool)
    {
        return buyer == msg.sender;
    }

    function buyTokensFor(address buyerAddress, uint64 buyerId, uint maxAmount, uint8 v, bytes32 r, bytes32 s)
        public payable returns (bool)
    {
        require(senderAllowedFor(buyerAddress));
        return buyImplementation(buyerAddress, buyerId, maxAmount, v, r, s);
    }

    function buyTokens(uint64 buyerId, uint maxAmount, uint8 v, bytes32 r, bytes32 s)
        public payable returns (bool)
    {
        return buyImplementation(msg.sender, buyerId, maxAmount, v, r, s);
    }

    function buyImplementation(address buyerAddress, uint64 buyerId, uint maxAmount, uint8 v, bytes32 r, bytes32 s)
        private returns (bool)
    {
        // check the signature
        bytes32 hash = sha256("Eidoo icoengine authorization", this, buyerAddress, buyerId, maxAmount);
        address signer = ecrecover(hash, v, r, s);
        if (!isKycSigner[signer]) {
            emit KycVerified(signer, buyerAddress, buyerId, maxAmount);
        } else {
            uint256 totalPayed = alreadyPayed[buyerId].add(msg.value);
            require(totalPayed <= maxAmount);
            alreadyPayed[buyerId] = totalPayed;
            emit KycVerified(signer, buyerAddress, buyerId, maxAmount);
            return releaseTokensTo(buyerAddress);
        }
    }
}

contract RC is ICOEngineInterface, KYCBase {
    using SafeMath for uint256;
    TokenSale tokenSaleContract;
    uint256 public startTime;
    uint256 public endTime;
    
    uint256 public soldTokens;
    uint256 public remainingTokens;
    
    uint256 public oneTokenInUsdWei;
	
	mapping(address => uint256) public balanceUser; // address => token amount
	uint256[] public tokenThreshold; // array of token threshold reached in wei of token
    uint256[] public bonusThreshold; // array of bonus of each tokenThreshold reached - 20% = 20

    function RC(address _tokenSaleContract, uint256 _oneTokenInUsdWei, uint256 _remainingTokens,  uint256 _startTime , uint256 _endTime, address [] kycSigner, uint256[] _tokenThreshold, uint256[] _bonusThreshold ) public KYCBase(kycSigner) {
        require ( _tokenSaleContract != 0 );
        require ( _oneTokenInUsdWei != 0 );
        require( _remainingTokens != 0 );
        require ( _tokenThreshold.length != 0 );
        require ( _tokenThreshold.length == _bonusThreshold.length );
        bonusThreshold = _bonusThreshold;
        tokenThreshold = _tokenThreshold;
        
        
        tokenSaleContract = TokenSale(_tokenSaleContract);
        
        tokenSaleContract.addMeByRC();
        
        soldTokens = 0;
        remainingTokens = _remainingTokens;
        oneTokenInUsdWei = _oneTokenInUsdWei;
        
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
    
    event BuyRC(address indexed buyer, bytes trackID, uint256 value, uint256 soldToken, uint256 valueTokenInUsdWei );
    
    function releaseTokensTo(address buyer) internal returns(bool) {
        require( now > startTime );
        require( now < endTime );
        //require( msg.value >= 1*10**18); //1 Ether
        require( remainingTokens > 0 );
        
        uint256 tokenAmount = tokenSaleContract.buyFromRC.value(msg.value)(buyer, oneTokenInUsdWei, remainingTokens);
        
		balanceUser[msg.sender] = balanceUser[msg.sender].add(tokenAmount);		
        remainingTokens = remainingTokens.sub(tokenAmount);
        soldTokens = soldTokens.add(tokenAmount);
        
        emit BuyRC( msg.sender, msg.data, msg.value, tokenAmount, oneTokenInUsdWei );
        return true;
    }
    
    function started() public view returns(bool) {
        return now > startTime || remainingTokens == 0;
    }
    
    function ended() public view returns(bool) {
        return now > endTime || remainingTokens == 0;
    }
    
    function startTime() public view returns(uint) {
        return startTime;
    }
    
    function endTime() public view returns(uint) {
        return endTime;
    }
    
    function totalTokens() public view returns(uint) {
        return remainingTokens.add(soldTokens);
    }
    
    function remainingTokens() public view returns(uint) {
        return remainingTokens;
    }
    
    function price() public view returns(uint) {
        uint256 oneEther = 10**18;
        return oneEther.mul(10**18).div( tokenSaleContract.tokenValueInEther(oneTokenInUsdWei) );
    }
	
	function () public {
        require( now > endTime );
        require( balanceUser[msg.sender] > 0 );
        uint256 bonusApplied = 0;
        for (uint i = 0; i < tokenThreshold.length; i++) {
            if ( soldTokens > tokenThreshold[i] ) {
                bonusApplied = bonusThreshold[i];
			}
		}    
		require( bonusApplied > 0 );
		
		uint256 addTokenAmount = balanceUser[msg.sender].mul( bonusApplied ).div(10**2);
		balanceUser[msg.sender] = 0; 
		
		tokenSaleContract.claim(msg.sender, addTokenAmount);
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
    
    function tokenValueInEther(uint256 _oneTokenInUsdWei) public view returns(uint256 tknValue) {
        uint256 oneEtherInUsd = rateContract.readRate("usd");
        tknValue = _oneTokenInUsdWei.mul(10 ** uint256(decimals)).div(oneEtherInUsd);
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
        emit Buy(_buyer, tokenAmount, _ambassador);
		
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
        
        emit NewRC(msg.sender);
    }
    
    function setTime(uint256 _newStart, uint256 _newEnd) public onlyOwner {
        if ( _newStart != 0 ) startTime = _newStart;
        if ( _newEnd != 0 ) endTime = _newEnd;
    }

    function withdraw(address to, uint256 value) public onlyOwner {
        to.transfer(value);
    }
    
    function withdrawTokens(address to, uint256 value) public onlyOwner returns (bool) {
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
	
	function claim(address _buyer, uint256 _amount) onlyRC public returns(bool) {
        return tokenContract.transfer(_buyer, _amount);
    }

    function () public payable {
        revert();
    }
}