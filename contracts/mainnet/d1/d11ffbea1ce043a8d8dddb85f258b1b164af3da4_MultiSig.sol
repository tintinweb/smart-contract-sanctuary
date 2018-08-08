// basic multisig wallet with spending limits, token types and other controls built in
// wondering if I should build in a master lock which enables free spend after a certain time?
pragma solidity ^0.4.24;

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic
{
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract MultiSig
{
  address constant internal CONTRACT_SIGNATURE1 = 0xa5a5f62BfA22b1E42A98Ce00131eA658D5E29B37; // SB
  address constant internal CONTRACT_SIGNATURE2 = 0x9115a6162D6bC3663dC7f4Ea46ad87db6B9CB926; // SM
  
  mapping(address => uint256) internal mSignatures;
  mapping(address => uint256) internal mLastSpend;
  
  // gas limit
  uint256 public GAS_PRICE_LIMIT = 200 * 10**9;                       // Gas limit 200 gwei
  
  // live parameters
  uint256 public constant WHOLE_ETHER = 10**18;
  uint256 public constant FRACTION_ETHER = 10**14;
  uint256 public constant COSIGN_MAX_TIME= 900; // maximum delay between signatures
  uint256 public constant DAY_LENGTH  = 300; // length of day in seconds
  
  // ether spending
  uint256 public constant MAX_DAILY_SOLO_SPEND = (5*WHOLE_ETHER); // amount which can be withdrawn without co-signing
  uint256 public constant MAX_DAILY_COSIGN_SEND = (500*WHOLE_ETHER);
  
  // token spending
  uint256 public constant MAX_DAILY_TOKEN_SOLO_SPEND = 2500000*WHOLE_ETHER; // ~5 eth
  uint256 public constant MAX_DAILY_TOKEN_COSIGN_SPEND = 250000000*WHOLE_ETHER; // ~500 eth
  
  uint256 internal mAmount1=0;
  uint256 internal mAmount2=0;

  // set the time of a signature
  function sendsignature() internal
  {
       // check if these signatures are authorised
        require((msg.sender == CONTRACT_SIGNATURE1 || msg.sender == CONTRACT_SIGNATURE2));//, "Only signatories can sign");
        
        // assign signature
        uint256 timestamp = block.timestamp;
        mSignatures[msg.sender] = timestamp;
  }
  
  // inserted for paranoia but may need to change gas prices in future
  function SetGasLimit(uint256 newGasLimit) public
  {
      require((msg.sender == CONTRACT_SIGNATURE1 || msg.sender == CONTRACT_SIGNATURE2));//, "Only signatories can call");
      GAS_PRICE_LIMIT = newGasLimit;                       // Gas limit default 200 gwei
  }
    
  // implicitly calls spend - if both signatures have signed we then spend
  function spendlarge(uint256 _to, uint256 _main, uint256 _fraction) public returns (bool valid)
  {
        require( _to != 0x0);//, "Must send to valid address");
        require( _main<= MAX_DAILY_COSIGN_SEND);//, "Cannot spend more than 500 eth");
        require( _fraction< (WHOLE_ETHER/FRACTION_ETHER));//, "Fraction must be less than 10000");
        require (tx.gasprice <= GAS_PRICE_LIMIT);//, "tx.gasprice exceeds limit");
        // usually called after sign but will work if top level function is called by both parties
        sendsignature();
        
        uint256 currentTime = block.timestamp;
        uint256 valid1=0;
        uint256 valid2=0;
        
        // check both signatures have been logged within the time frame
        // one of these times will obviously be zero
        if (block.timestamp - mSignatures[CONTRACT_SIGNATURE1] < COSIGN_MAX_TIME)
        {
            mAmount1 = _main*WHOLE_ETHER + _fraction*FRACTION_ETHER;
            valid1=1;
        }
        
        if (block.timestamp - mSignatures[CONTRACT_SIGNATURE2] < COSIGN_MAX_TIME)
        {
            mAmount2 = _main*WHOLE_ETHER + _fraction*FRACTION_ETHER;
            valid2=1;
        }
        
        if (valid1==1 && valid2==1) //"Both signatures must sign");
        {
            // if this was called in less than 24 hours then don&#39;t allow spend
            require( (currentTime - mLastSpend[msg.sender]) > DAY_LENGTH);//, "You can&#39;t call this more than once per day per signature");
        
            if (mAmount1 == mAmount2)
            {
                // transfer eth to the destination
                address(_to).transfer(mAmount1);
                
                // clear the state
                valid1=0;
                valid2=0;
                mAmount1=0;
                mAmount2=0;
                
                // clear the signature timestamps
                endsigning();
                
                return true;
            }
        }
        
        // out of time or need another signature
        return false;
  }
  
  // used for individual wallet holders to take a small amount of ether
  function takedaily(address _to) public returns (bool valid)
  {
    require( _to != 0x0);//, "Must send to valid address");
    require (tx.gasprice <= GAS_PRICE_LIMIT);//, "tx.gasprice exceeds limit");
    
    // check if these signatures are authorised
    require((msg.sender == CONTRACT_SIGNATURE1 || msg.sender == CONTRACT_SIGNATURE2));//, "Only signatories can sign");
        
    uint256 currentTime = block.timestamp;
        
    // if this was called in less than 24 hours then don&#39;t allow spend
    require(currentTime - mLastSpend[msg.sender] > DAY_LENGTH);//, "You can&#39;t call this more than once per day per signature");
    
    // transfer eth to the destination
    _to.transfer(MAX_DAILY_SOLO_SPEND);
                
    mLastSpend[msg.sender] = currentTime;
                
    return true;
  }
  
  // implicitly calls spend - if both signatures have signed we then spend
  function spendtokens(ERC20Basic contractaddress, uint256 _to, uint256 _main, uint256 _fraction) public returns (bool valid)
  {
        require( _to != 0x0);//, "Must send to valid address");
        require(_main <= MAX_DAILY_TOKEN_COSIGN_SPEND);// , "Cannot spend more than 150000000 per day");
        require(_fraction< (WHOLE_ETHER/FRACTION_ETHER));//, "Fraction must be less than 10000");
        
        // usually called after sign but will work if top level function is called by both parties
        sendsignature();
        
        uint256 currentTime = block.timestamp;
        uint256 valid1=0;
        uint256 valid2=0;
        
        // check both signatures have been logged within the time frame
        // one of these times will obviously be zero
        if (block.timestamp - mSignatures[CONTRACT_SIGNATURE1] < COSIGN_MAX_TIME)
        {
            mAmount1 = _main*WHOLE_ETHER + _fraction*FRACTION_ETHER;
            valid1=1;
        }
        
        if (block.timestamp - mSignatures[CONTRACT_SIGNATURE2] < COSIGN_MAX_TIME)
        {
            mAmount2 = _main*WHOLE_ETHER + _fraction*FRACTION_ETHER;
            valid2=1;
        }
        
        if (valid1==1 && valid2==1) //"Both signatures must sign");
        {
            // if this was called in less than 24 hours then don&#39;t allow spend
            require(currentTime - mLastSpend[msg.sender] > DAY_LENGTH);//, "You can&#39;t call this more than once per day per signature");
        
            if (mAmount1 == mAmount2)
            {
                uint256 valuetosend = _main*WHOLE_ETHER + _fraction*FRACTION_ETHER;
                // transfer eth to the destination
                contractaddress.transfer(address(_to), valuetosend);
                
                // clear the state
                valid1=0;
                valid2=0;
                mAmount1=0;
                mAmount2=0;
                
                // clear the signature timestamps
                endsigning();
                
                return true;
            }
        }
        
        // out of time or need another signature
        return false;
  }
        

  // used to take a small amount of daily tokens
  function taketokendaily(ERC20Basic contractaddress, uint256 _to) public returns (bool valid)
  {
    require( _to != 0x0);//, "Must send to valid address");
    
    // check if these signatures are authorised
    require((msg.sender == CONTRACT_SIGNATURE1 || msg.sender == CONTRACT_SIGNATURE2));//, "Only signatories can sign");
        
    uint256 currentTime = block.timestamp;
        
    // if this was called in less than 24 hours then don&#39;t allow spend
    require(currentTime - mLastSpend[msg.sender] > DAY_LENGTH);//, "You can&#39;t call this more than once per day per signature");
    
    // transfer eth to the destination
    contractaddress.transfer(address(_to), MAX_DAILY_TOKEN_SOLO_SPEND);
                
    mLastSpend[msg.sender] = currentTime;
                
    return true;
  }
    
  function endsigning() internal
  {
      // only called when spending was successful - sets the timestamp of last call
      mLastSpend[CONTRACT_SIGNATURE1]=block.timestamp;
      mLastSpend[CONTRACT_SIGNATURE2]=block.timestamp;
      mSignatures[CONTRACT_SIGNATURE1]=0;
      mSignatures[CONTRACT_SIGNATURE2]=0;
  }
  
  function () public payable 
    {
       
    }
    
}