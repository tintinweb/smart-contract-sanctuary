pragma solidity ^0.4.23;

/**
 * CoinCrowd Multi Send Contract. More info www.coincrowd.me
 */
 
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
 
contract tokenInterface {
    function transfer(address _to, uint256 _value) public returns (bool);
}

contract MultiSendCoinCrowd is Ownable {
	tokenInterface public tokenContract;
	
	function updateTokenContract(address _tokenAddress) public onlyOwner {
        tokenContract = tokenInterface(_tokenAddress);
    }
	
    function multisend(address[] _dests, uint256[] _values) public onlyOwner returns(uint256) {
        require(_dests.length == _values.length, "_dests.length == _values.length");
        uint256 i = 0;
        while (i < _dests.length) {
           tokenContract.transfer(_dests[i], _values[i]);
           i += 1;
        }
        return(i);
    }
	
	function airdrop( uint256 _value, address[] _dests ) public onlyOwner returns(uint256) {
        uint256 i = 0;
        while (i < _dests.length) {
            tokenContract.transfer(_dests[i], _value);
           i += 1;
        }
        return(i);
    }
	
	function withdrawTokens(address to, uint256 value) public onlyOwner returns (bool) {
        return tokenContract.transfer(to, value);
    }
}