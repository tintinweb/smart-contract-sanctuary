pragma solidity ^0.4.24;

library SafeMath {
    function add(uint256 a, uint256 b)
        internal
        pure
        returns (uint256 c) 
    {
        c = a + b;
        require(c >= a, "SafeMath add failed");
        return c;
    }
}

contract RandomNumber {
	using SafeMath for *;

	address _owner;
	uint24 private _number;
	uint256 private _time;
	uint256 private _timespan;
    event onNewNumber
    (
        uint24 number,
        uint256 time
    );
	
	constructor(uint256 timespan) 
		public 
	{
		_owner = msg.sender;
		_time = 0;
		_number = 0;
		_timespan = timespan;
	}

	function number() 
		public 
		view 
		returns (uint24) 
	{
		return _number;
	}

	function time() 
		public 
		view 
		returns (uint256) 
	{
		return _time;
	}

	function timespan() 
		public 
		view 
		returns (uint256) 
	{
		return _timespan;
	}

	function genNumber() 
		public 
	{
		require(block.timestamp > _time + _timespan);
		_time = block.timestamp;
		_number = random();
		emit RandomNumber.onNewNumber (
			_number,
			_time
		);
	}

    function random() 
    	private 
    	view 
    	returns (uint24)
    {
        uint256 randnum = uint256(keccak256(abi.encodePacked(
            
            (block.timestamp).add
            (block.difficulty).add
            ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (now)).add
            (block.gaslimit).add
            ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (now)).add
            (block.number)
            
        )));
        return uint24(randnum%1000000);
    }
}