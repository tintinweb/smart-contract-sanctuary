pragma solidity ^0.4.24;

contract Ownable {
	event OwnershipRenounced(address indexed previousOwner); 
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}

	modifier notOwner(address _addr) {
		require(_addr != owner);
		_;
	}

	address public owner;

	constructor() 
		public 
	{
		owner = msg.sender;
	}

	function renounceOwnership()
		external
		onlyOwner 
	{
		emit OwnershipRenounced(owner);
		owner = address(0);
	}

	function transferOwnership(address _newOwner) 
		external
		onlyOwner
		notOwner(_newOwner)
	{
		require(_newOwner != address(0));
		emit OwnershipTransferred(owner, _newOwner);
		owner = _newOwner;
	}
}

contract ETHPublish is Ownable {
	event Publication(bytes32 indexed hash, string content);

	mapping(bytes32 => string) public publications;
	mapping(bytes32 => bool) published;

	function()
		public
		payable
	{
		revert();
	}

	function publish(string content)
		public
		onlyOwner
		returns (bytes32)
	{
		bytes32 hash = keccak256(bytes(content));
		
		require(!published[hash]);

		publications[hash] = content;
		published[hash] = true;
		emit Publication(hash, content);

		return hash;
	}
}