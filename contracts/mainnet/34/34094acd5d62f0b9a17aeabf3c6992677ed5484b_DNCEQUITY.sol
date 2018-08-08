pragma solidity ^0.4.4;

contract DNCAsset {
    uint256 public totalSupply = 0;
    //function balanceOf(address who) constant returns (uint);
    //function transfer(address _to, uint _value) returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
}

 
contract DNCReceivingContract {
    function tokenFallback(address _from, uint _value, bytes _data);
}

/* SafeMath for checking eror*/
library SafeMath {
    
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
  function div(uint a, uint b) internal returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }
  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }
  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }
  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }
  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }
  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }
  function assert(bool assertion) internal {
    if (!assertion) {
      throw;
    }
  }


}

contract ERC223BasicToken is DNCAsset{
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    function transfer(address _to, uint _value) returns (bool success) {
        uint codeLength;
        bytes memory empty;

        assembly {
            // Retrieve the size of the code on target address, this needs assembly .
            codeLength := extcodesize(_to)
        }
        
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        if(codeLength>0) {
            DNCReceivingContract receiver = DNCReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, empty);
        }
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function balanceOf(address _owner) constant returns (uint balance) {
        return balances[_owner];
    }
}

contract DNCEQUITY is ERC223BasicToken{
	address admin;
	string public name = "DinarCoin";
    string public symbol = "DNC";
    uint public decimals = 18;
	mapping (address => bool) public mintable;

	event Minted(address indexed recipient, uint256 value);
	event Burned(address indexed user, uint256 value);

	function DNCEQUITY() {
		admin = msg.sender;
	}

	modifier onlyadmin { if (msg.sender == admin) _; }

	function changeAdmin(address _newAdminAddr) onlyadmin {
		admin = _newAdminAddr;
	}

	function createNewMintableUser (address newAddr) onlyadmin {
		if(balances[newAddr] == 0)  
    		mintable[newAddr] = true;
	}
	
	function deleteMintable (address addr) onlyadmin {
	    mintable[addr] = false;
	}
	
	function adminTransfer(address from, address to, uint256 value) onlyadmin {
        if(mintable[from] == true) {
    	    balances[from] = balances[from].sub(value);
    	    balances[to] = balances[to].add(value);
    	    Transfer(from, to, value);
        }
	}
	
	function mintNewDNC(address user, uint256 quantity) onlyadmin {
	    uint256 correctedQuantity = quantity * (10**(decimals-1));
        if(mintable[user] == true) {
            totalSupply = totalSupply.add(correctedQuantity);
            balances[user] = balances[user].add(correctedQuantity);
            Transfer(0, user, correctedQuantity);
            Minted(user, correctedQuantity);
        }   
	}
	
	function burnDNC(address user, uint256 quantity) onlyadmin {
	    uint256 correctedQuantity = quantity * (10**(decimals-1));
	    if(mintable[user] == true) {
            balances[user] = balances[user].sub(correctedQuantity);
            totalSupply = totalSupply.sub(correctedQuantity);
            Transfer(user, 0, correctedQuantity);
            Burned(user, correctedQuantity);
	    }
	}
}