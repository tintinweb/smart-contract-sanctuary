/**
 *Submitted for verification at Etherscan.io on 2021-04-05
*/

pragma solidity 0.8.1;


/** @title Repeater
 *  This contract repeats calls on the owner request.
 */
contract Repeater {
    address owner = msg.sender;
    
/** @dev Call `_target` with `_data`
 *  @param _target The contract to call.
 *  @param _data The data to send to the contract.
 */    
    function repeat(address _target, bytes calldata _data) external {
        require(msg.sender == owner);
        _target.call(_data);
    }

/** @dev Call `_target` with `_data` sending `_value` wei.
 *  @param _target The contract to call.
 *  @param _data The data to send to the contract.
 *  @param _value The amount of wei to send.
 */
    function repeatWithValue(address _target, bytes calldata _data, uint _value) external {
        require(msg.sender == owner);
        _target.call{value: _value}(_data);
    }
    
    receive() external payable {}
}

/** @title Master
 *  This contract creates repeaters and make them perform some actions.
 */
contract Master {
    address public owner = msg.sender;
    Repeater[] public repeaters;
    
    function changeOwner(address _newOwner) external {
        require(msg.sender == owner);
        owner = _newOwner;
    }
    
    /** @dev Create `_amount` repeaters.
     *  @param _amount The amount of repeaters to create.
     */
    function addRepeaters(uint _amount) external {
        require(msg.sender == owner);
        for (uint i; i<_amount; ++i) {
            repeaters.push(new Repeater());
        }
    }
    
    /** @dev Make repeaters from `_start` to `_end` (included) call `_target` with `_data`.
     *  @param _start The first repeater ID.
     *  @param _end The last repeater ID.
     *  @param _target The contract to be called by the repeaters.
     *  @param _data The data the repeaters will send to the contract.
     */
    function say(uint _start, uint _end, address _target, bytes calldata _data) external {
        require(msg.sender == owner);
        for (uint i=_start; i<=_end; ++i) {
            repeaters[i].repeat(_target, _data);
        }
    }

    /** @dev Make repeaters from `_start` to `_end` (included) call `_target` with `_data` sending `_value` wei.
     *  @param _start The first repeater ID.
     *  @param _end The last repeater ID.
     *  @param _target The contract to be called by the repeaters.
     *  @param _data The data the repeaters will send to the contract.
     *  @param _value The amount of wei to send.
     */
    function sayWithValue(uint _start, uint _end, address _target, bytes calldata _data, uint _value) external {
        require(msg.sender == owner);
        for (uint i=_start; i<=_end; ++i) {
            repeaters[i].repeatWithValue(_target, _data, _value);
        }
    }    
    
    /** @dev Return the list of repeaters.
     *  @return The list of repeaters.
     */
    function getRepeatersAddresses() external view returns(Repeater[] memory)  {
        return repeaters;
    }
    
    
}