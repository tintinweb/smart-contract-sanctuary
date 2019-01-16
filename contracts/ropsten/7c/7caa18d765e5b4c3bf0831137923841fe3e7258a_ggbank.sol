//Welcome to LCTF
pragma solidity ^0.4.24;
library SafeMath {

	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		if (a == 0) {
			return 0;
		}

		uint256 c = a * b;
		require(c / a == b);

		return c;
	}

	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		require(b > 0); 
		uint256 c = a / b;

		return c;
	}

	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		require(b <= a);
		uint256 c = a - b;

		return c;
	}

	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		require(c >= a);

		return c;
	}
}


contract ERC20{
	using SafeMath for uint256;

	mapping (address => uint256) public balances;

	uint256 public _totalSupply;

	function totalSupply() public view returns (uint256) {
		return _totalSupply;
	}

	function balanceOf(address owner) public view returns (uint256) {
		return balances[owner];
	}

	function transfer(address _to, uint _value) public returns (bool success){
    	balances[msg.sender] = balances[msg.sender].sub(_value);
    	balances[_to] = balances[_to].add(_value);
    	
    	return true;
  	}
}

contract ggToken is ERC20 {

	string public constant name = "777";
	string public constant symbol = "666";
	uint8 public constant decimals = 18;
	uint256 public constant _airdropAmount = 1000;

	uint256 public constant INITIAL_SUPPLY = 20000000000 * (10 ** uint256(decimals));

	mapping(address => bool) initialized;

	constructor() public {
		initialized[msg.sender] = true;
		_totalSupply = INITIAL_SUPPLY;
		balances[msg.sender] = INITIAL_SUPPLY;
	}


}


contract ggbank is ggToken{
    address public owner;
    mapping(uint => bool) locknumber;

    event GetFlag(
			string b64email,
			string back
		);
    
    modifier authenticate {
        require(checkfriend(msg.sender));_;
    }
    constructor() public {
        owner=msg.sender;
    }
    function checkfriend(address _addr) internal pure returns (bool success) {
        bytes20 addr = bytes20(_addr);
        bytes20 id = hex"000000000000000000000000000000000007d7ec";
        bytes20 gg = hex"00000000000000000000000000000000000fffff";

        for (uint256 i = 0; i < 34; i++) {
            if (addr & gg == id) {
                return true;
            }
            gg <<= 4;
            id <<= 4;
        }

        return false;
    }
    function getAirdrop() public authenticate returns (bool success){
		 if (!initialized[msg.sender]) {
            initialized[msg.sender] = true;
            balances[msg.sender] = _airdropAmount;
            _totalSupply += _airdropAmount;
        }
        return true;
	}
    function goodluck()  public payable authenticate returns (bool success) {
        require(!locknumber[block.number]);
        require(balances[msg.sender]>=100);
        balances[msg.sender]-=100;
        uint random=uint(keccak256(abi.encodePacked(block.number))) % 100;
        if(uint(keccak256(abi.encodePacked(msg.sender))) % 100 == random){
            balances[msg.sender]+=20000;
            _totalSupply +=20000;
            locknumber[block.number] = true;
        }
        return true;
    }
    
 
    function PayForFlag(string b64email) public payable authenticate returns (bool success){
		
			require (balances[msg.sender] > 200000);
			emit GetFlag(b64email, "Get flag!");
		}
}