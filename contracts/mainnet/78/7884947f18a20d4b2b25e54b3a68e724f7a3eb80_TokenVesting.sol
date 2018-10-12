pragma solidity ^0.4.24;  


library SafeMath {
	function mul(uint a, uint b) internal pure returns(uint) {  
		uint c = a * b;
		assert(a == 0 || c / a == b);
		return c;
	}

	function div(uint a, uint b) internal pure returns(uint) { 
		uint c = a / b;
		return c; 
	}

	function sub(uint a, uint b) internal pure returns(uint) {  
		assert(b <= a);
		return a - b;
	}

	function add(uint a, uint b) internal pure returns(uint) {  
		uint c = a + b;
		assert(c >= a);
		return c;
	}
	function max64(uint64 a, uint64 b) internal pure  returns(uint64) { 
		return a >= b ? a : b;
	}

	function min64(uint64 a, uint64 b) internal pure  returns(uint64) { 
		return a < b ? a : b;
	}

	function max256(uint256 a, uint256 b) internal pure returns(uint256) { 
		return a >= b ? a : b;
	}

	function min256(uint256 a, uint256 b) internal pure returns(uint256) {  
		return a < b ? a : b;
	}
 
}

contract ERC20Basic {
	uint public totalSupply;
	function balanceOf(address who) public constant returns(uint);  
	function transfer(address to, uint value) public;  
	event Transfer(address indexed from, address indexed to, uint value);
}


contract ERC20 is ERC20Basic {
	function allowance(address owner, address spender) public constant returns(uint);  
	function transferFrom(address from, address to, uint value) public;  
	function approve(address spender, uint value) public;  
	event Approval(address indexed owner, address indexed spender, uint value);
}

/**
 * @title TokenVesting
 * @dev A contract can unlock token at designated time.
 */
contract TokenVesting  {
  using SafeMath for uint256;

  event Released(uint256 amounts);

  address[] private _beneficiary ;
  uint256[] private _unlocktime;  
  uint256[] private _amount;

  constructor() public
  {
   	 _beneficiary = [0x9138D3b9d45cd8901aD1C2e670428Bc51f85c350,
   	 0x2968d05dCF6e706F68ca8fC16F6e430fd822d742,
   	 0xCD2C7D18325B7E09DA08DBA6f58D0E6F0e6BDf68,
   	 0xA29459226F9aFa33b2b22093f5f9FCB9B16a9851,
   	 0xD20D3CaC06BfC68f1d0e84855c3395D2D10CDb14,
   	 0xd8B5C428E7F37e84d13a25C400a35fD97a2BfaBd,
   	 0x2e5f02cb099c2b6ddc71694cafa6801eb30b60ce,
   	 0x4e8b6b5b94ffc827b1ec2f6c172a93067248c4fa,
   	 0xbe4c612de6221f557799b7ed456572f0c0a14bd1,
   	 0xbe4c612de6221f557799b7ed456572f0c0a14bd1,
   	 0x9c0A93e70143611fD5107eb865963b1E4670C852,
   	 0x7A2D687BEDeb0B0C6e7Ef27db97Bcc5ab4d68c02,
   	 0xf5991c3be1677F62Ac7A631108D56300634CFAcF];
   	 
     _unlocktime = [1546272000,1572969600,1572969600,1572969600,1569859200,1546185600,1556640000,1559318400,1551369600,1569859200,1545321600,1557244800,1564416000];
     _amount=[227500000,773500000,136500000,91000000,1708182733,9614599,39173094,15054061,230700000,384500000,9000000,17500000,7500000];
     
  }

  /**
   * @return the beneficiary of the tokens.
   */
  function beneficiary() public view returns(address[]) {
    return _beneficiary;
  }

  /**
   * @return the unlocktime time of the token vesting.
   */
  function unlocktime() public view returns(uint256[]) {
    return _unlocktime;
  }
   /**
   * @return the amount of the tokens.
   */
  function amount() public view returns(uint256[]) {
    return _amount;
  }
 
 

  /**
   * @notice Transfers vested tokens to beneficiary.
   * @param token ERC20 token which is being vested
   */
  function release(ERC20 token) public {
       for(uint i = 0; i < _beneficiary.length; i++) {
            if(block.timestamp >= _unlocktime[i] ){
                   token.transfer(_beneficiary[i], _amount[i].mul(10**18));
                    emit Released( _amount[i]);
                    _amount[i]=0;
            }
       }
  }

  /**
   * @notice Release the unexpected token.
   * @param token ERC20 token which is being vested
   */
  
    function checkRelease(ERC20 token) public {
        
       uint num = 0;
        for(uint i = 0; i < _amount.length; i++) {
            num = num.add(_amount[i]); 
        }
        if(num==0){
             token.transfer(_beneficiary[0],token.balanceOf(this));
        }
        
  }

}