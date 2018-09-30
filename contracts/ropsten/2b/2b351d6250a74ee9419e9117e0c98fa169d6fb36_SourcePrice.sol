pragma solidity ^0.4.24;

contract Ownable {
	address public owner;
	address public newOwner;

	event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

	constructor() public {
		owner = msg.sender;
		newOwner = address(0);
	}

	modifier onlyOwner() {
		require(msg.sender == owner, "msg.sender == owner");
		_;
	}

	function transferOwnership(address _newOwner) public onlyOwner {
		require(address(0) != _newOwner, "address(0) != _newOwner");
		newOwner = _newOwner;
	}

	function acceptOwnership() public {
		require(msg.sender == newOwner, "msg.sender == newOwner");
		emit OwnershipTransferred(owner, msg.sender);
		owner = msg.sender;
		newOwner = address(0);
	}
}

contract FeedPrice is Ownable {
    
    address public sourcePrice ;
    
    constructor ( address _sourcePrice ) public {
        setSourcePrice(_sourcePrice);
    }
    
    function setSourcePrice( address _sourcePrice ) public onlyOwner returns (bool) {
        require( _sourcePrice != address(0), "The address of source&#39;s price cannot be 0." );
        sourcePrice = _sourcePrice;
        return true;
    }
    
    function read(bytes32 _currency) view public returns (uint256 value) {
        value = SourcePrice(sourcePrice).read(_currency);
    }
    
}

contract SourcePrice {
    mapping (bytes32 => address) public sourceContract;

    constructor (address _sourceContract) public {
        sourceContract[ keccak256( abi.encodePacked( "usd" ) ) ] = _sourceContract;
    }
    
    function read(bytes32 _currency) view public returns (uint256 value) {
        address source = sourceContract[ _currency ];
        if( source != address(0) ) { 
            value = 250 ether;
        } else {
            revert("Not implemented source&#39;s price.");
        }
    }
}

contract EndPointInterface {
    function read() view public returns (bytes32);
}