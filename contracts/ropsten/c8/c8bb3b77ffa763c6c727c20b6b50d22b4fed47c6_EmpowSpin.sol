/**
 *Submitted for verification at Etherscan.io on 2019-07-11
*/

pragma solidity ^0.5.10;

contract EmpowSpin {
    
    event Spin(address indexed _address, uint256 _time, uint32 _number);
    
    struct SpinHistory {
        uint256 time;
        uint32 number;
    }
    
    mapping (address => uint256) public countSpin;
    mapping (address => mapping (uint256 => SpinHistory)) public spinHistories;
    
    uint32 NEXT_SPIN_WAIT_TIME = 24 * 60 * 60; // 1 day
    uint32 MIN_SPIN_NUMBER = 10;
    uint32 MAX_SPIN_NUMBER = 200;
    
    address owner;
    
    modifier onlyOwner () {
        require(msg.sender == owner, "owner require");
        _;
    }
    
    constructor ()
        public
    {
        owner = msg.sender;
    }
    
    function changeWaitTime(uint32 _waitTime) 
        public
        onlyOwner
        returns(bool)
    {
        NEXT_SPIN_WAIT_TIME = _waitTime;
        return true;
    }
    
    function spin ()
        public
        returns(uint32)
    {
        if(countSpin[msg.sender] > 0) {
            uint256 lastSpinTime = spinHistories[msg.sender][countSpin[msg.sender]].time;
            require(block.timestamp > lastSpinTime + NEXT_SPIN_WAIT_TIME, "You need wait more time");
        }
        
        uint256 spinTime = block.timestamp;
        uint32 number = randomNumber();
        
        emit Spin(msg.sender, spinTime, number);
        saveHistory(msg.sender, spinTime, number);
        
        return number;
    }
    
    function saveHistory (address _address, uint256 _time, uint32 _number)
        private
        returns(bool)
    {
        spinHistories[msg.sender][countSpin[_address]].time = _time;
        spinHistories[msg.sender][countSpin[_address]].number = _number;
        
        countSpin[_address]++;
        return true;
    }
    
    function randomNumber()
        private
        view
        returns(uint32)
    {
        uint32 random = uint32(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % (MAX_SPIN_NUMBER - MIN_SPIN_NUMBER + 1));
        random += MIN_SPIN_NUMBER;
        return random;
    }
    
}