pragma solidity ^0.4.24;
/**
 * The MultiSig contract does this and that...
 */
contract MultiSig {
	address public Owner;
	address[] public  Members;
	
	mapping (address => uint256) public Map_monto;
	mapping (address => address) public Map_target;

	function donate() public  payable{
		
	}

	constructor () public{
		Owner = msg.sender;
	}	
	function addMember(address _address)public {
		require(msg.sender == Owner);
	    bool _check = true;
	    for (uint i = 0; i < Members.length ; i++) {
	        if (Members[i] == _address){
	            _check = false;
	            break;
	        }
	    }
		if(_check){
			Members.push(_address);
		}
	}

	function aval(uint256 _monto, address _to ) public
	{
		require(address(this).balance >= _monto, "fondos insuficientes");
		Map_monto[msg.sender] =_monto;
		Map_target[msg.sender] =_to;

		bool _check = true;
		
		for (uint i = 0; i < Members.length ; i++) {
			if(_check){
				if((Map_monto[Members[i]] != _monto) 
					|| (Map_target[Members[i]] != _to) ){
					_check = false;
					break;
				}	
			}
		}
		if (_check){
			_to.transfer(_monto);
		}
	}
	function MembersLength() public view returns(uint256){
	    return(Members.length);
	}
}