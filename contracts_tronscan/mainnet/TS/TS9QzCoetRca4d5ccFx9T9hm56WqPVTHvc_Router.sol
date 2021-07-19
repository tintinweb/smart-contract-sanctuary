//SourceUnit: trxRouterFee.sol

pragma solidity 0.5.12;

library SafeMath {
    function mul(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function max64(uint64 a, uint64 b) internal  returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal  returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal  returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal  returns (uint256) {
        return a < b ? a : b;
    }
}

contract Owned {
    address public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}

contract Router is  Owned {
    event Transfer(address indexed _from, address indexed _to, uint256 value);

    using SafeMath for uint;

    mapping(address=>uint) _banlance;
    
    /*
        transfer tron to other address
    */
	function transfer(address tokenAddress, uint tokens) external  onlyOwner returns (uint){
	    address(uint160(tokenAddress)).transfer(tokens);
	    emit Transfer(owner,tokenAddress,tokens);
		return tokens;
	}

    /**
     * @dev Store value in variable
     */
    function store() public payable returns (uint){
        if(_banlance[msg.sender] <= 0)
        {
			
            _banlance[msg.sender] = msg.value;
        }
        else
        {
            _banlance[msg.sender] = _banlance[msg.sender].add(msg.value);
        }
		return msg.value;
    }
	
/**
     * @dev Store value in variable
	 
	     address(uint160(toAddress)).transfer(msg.value/2);
	 */
    function () external payable{
		
    }
	
	/* 
		query banlance
	 */
	
	function banlanceOf(address addr) public view returns (uint){
		return _banlance[addr];
	}
}