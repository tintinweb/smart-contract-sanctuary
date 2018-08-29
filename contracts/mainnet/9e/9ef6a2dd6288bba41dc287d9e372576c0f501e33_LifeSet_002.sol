contract LifeSet_002 {
  uint256 public consecutiveDeaths;
  uint256 lastHash;
  uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;
  uint256 blockValue;
  uint256 lifeCoin;
  uint256 deathCoin;
  uint256 _hedge;
  

  function LifeSet_002() public {
    consecutiveDeaths = 0;
  }

  function ReinsureSeveralDeaths(bool _hedge) public returns (bool) {
    uint256 blockValue = uint256(block.blockhash(block.number-1));

    if (lastHash == blockValue) {
      revert();
    }

    lastHash = blockValue;
    uint256 lifeCoin = blockValue / FACTOR;
    bool deathCoin = lifeCoin == 1 ? true : false;

    if (deathCoin == _hedge) {
      consecutiveDeaths++;
      return true;
    } else {
      consecutiveDeaths = 0;
      return false;
    }
  }

  function	getConsecutiveDeaths	()	public	constant	returns	(	uint256	)	{
    return	consecutiveDeaths ;						
	}
	
  function	getLastHash	()	public	constant	returns	(	uint256	)	{
    return	lastHash ;						
	}  
  function	getFACTOR	()	public	constant	returns	(	uint256	)	{
    return	FACTOR ;						
	}	
  
  function	getBlockNumber	()	public	constant	returns	(	uint256	)	{
    return	(block.number) ;						
	}  
 
  function	getBlockNumberM1	()	public	constant	returns	(	uint256	)	{
    return	(block.number-1) ;						
	}  

  function	getBlockHash	()	public	constant	returns	(	uint256	)	{
    return	uint256(block.blockhash(block.number-1)) ;						
	}   
	
  function	getBlockValue	()	public	constant	returns	(	uint256	)	{
    return	blockValue ;						
	}     
	
  function	getLifeCoin	()	public	constant	returns	(	uint256	)	{
    return	lifeCoin ;						
	}     
	
  function	getDeathCoin	()	public	constant	returns	(	uint256	)	{
    return	deathCoin ;						
	}    
	
  function	get_hedge	()	public	constant	returns	(	uint256	)	{
    return	_hedge ;						
	}     
}