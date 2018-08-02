pragma solidity ^0.4.21;

contract Grounder {
    
    address public parent;
    enum State { startGround, endGround }
    State public state;
    uint public startGroundTimeStamp;
    uint public endGroundTimeStamp;
    uint[] public moveTimeStamp; 
    uint[] public callTimeStamp; 
    
    event groundStarted();
    event groundEnded();
    event moved();
    event calledforhelp();
    
    modifier onlyParent(){
        require(msg.sender == parent);
        _;
    }
    
    modifier inState(State _state) {
        require(state == _state);
        _;
    }
    
    constructor(uint _timeGround) 
        public
    {
        startGroundTimeStamp = _timeGround;
        state = State.startGround;
        parent = msg.sender;
        emit groundStarted();
    }
    
    function move(uint _timeMove)
        public
        onlyParent
        inState(State.startGround)
    {
        moveTimeStamp.push(_timeMove);
        emit moved();
    }
    
    function callforhelp(uint _timeCall)
        public
        onlyParent
        inState(State.startGround)
    {
        callTimeStamp.push(_timeCall);
        emit calledforhelp();
    }
    
    function endGround(uint _timeEnd)
        public
        onlyParent
        inState(State.startGround)
    {
        endGroundTimeStamp = _timeEnd;
        state = State.endGround;
        emit groundEnded();
    }
    
    function reGround(uint _timeGround)
        public
        onlyParent
        inState(State.endGround)
    {
        startGroundTimeStamp = _timeGround;
        endGroundTimeStamp = 0;
        delete moveTimeStamp;
        delete callTimeStamp;
        state = State.startGround;
        emit groundStarted();
    }
    
    function getMoveCount()
		public
		constant
		returns(uint moveCount)
	{
		return moveTimeStamp.length;
	}
	
    function getCallCount()
		public
		constant
		returns(uint callCount)
	{
		return callTimeStamp.length;
	}
}