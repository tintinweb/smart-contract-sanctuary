contract LifeSet_004 {
    
// part.I_fixe.../.../.../.../.../

  uint256 public FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;
  uint256 public lifeCoin;
  uint256 public A;
  uint256 public B;
  
// part.II_variable.../.../.../.../.../  
  
  uint256 public C;
  uint256 public D;
  uint256 public E;
  uint256 public F;
  
// part.I_fixe.../.../.../.../.../  

  function LifeSet_004() public {
    A = (block.number-1);
	B = uint256(block.blockhash(block.number-1));    
	lifeCoin = (B / FACTOR);
  }	
	
    function	getA	()	public	constant	returns	(	uint256	)	{
        return	A ;						
	}	    
	
    function	getB	()	public	constant	returns	(	uint256	)	{
        return	B ;						
	}

    function	getLifeCoin	()	public	constant	returns	(	uint256	)	{
        return	lifeCoin ;						
    }
    
// part.II_variable.../.../.../.../.../     

    function	getC	()	public	constant	returns	(	uint256	)	{
        return	(block.number) ;						
	}	    
	
    function	getD	()	public	constant	returns	(	uint256	)	{
        return	(block.number-1) ;                                              // (A variable)						
	}

    function	getE	()	public	constant	returns	(	uint256	)	{
        return	uint256(block.blockhash(block.number-1)) ;                      // (B variable)						
    }    
    
    function	getF	()	public	constant	returns	(	uint256	)	{
        return	uint256(block.blockhash(block.number-1)) / FACTOR ;             // (lifeCoin variable)					
    }        

}