/**
 *Submitted for verification at Etherscan.io on 2021-12-08
*/

pragma solidity >=0.4.21 <0.9.0;

// SPDX-License-Identifier: MIT

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
// SPDX-License-Identifier: MIT

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the {SafeMath}
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library Counters {
    using SafeMath for uint256;

    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

contract Device {

    using Counters for Counters.Counter;
    Counters.Counter private id;

    event onDeviceAdded(address indexed ownerOfDevice, uint date, string name);
    event onDeviceUpdated(address indexed ownerOfDevice, string name, string typeDevice, uint date, uint id);
    event onDeviceTransferOwnership(address oldOwner, address indexed newOwner, uint id);
    event onDeviceRemoved(address indexed owner, uint id, uint date);
    event onEnergyRecorded(address indexed owner, uint id, uint energy, uint date);

    struct device {
        address owner;
        string typeOfDevice;
        string name;
        uint energy;
        uint uuID;
        uint date;
    }

    mapping(uint => uint) deviceMap;
    device[] devices;

    function createDevice(string memory _typeOfDevice, string memory _name) public {

        ///@notice must added a valid way to check the validity of device input

        address _owner = msg.sender;
        uint currentTime = block.timestamp;
        id.increment();
        uint currentID = id.current();
        uint idx = devices.length;
        deviceMap[currentID] = idx;
        devices.push(device({
            owner: _owner,
            typeOfDevice: _typeOfDevice,
            name: _name,
            energy: 0,
            uuID: currentID,
            date: currentTime
        }));
        emit onDeviceAdded(_owner, currentTime, _name);
    }

    function removeDevice(uint _id) public {
        address _owner = msg.sender;
        for(uint i = 0; i<devices.length; i++){
            if(devices[i].uuID == _id && devices[i].owner == _owner){
                emit onDeviceRemoved(_owner, _id, block.timestamp);
                if (devices.length > 1) {
                    devices[i] = devices[devices.length-1];
                }
                devices.length--;
            }
        }
    }

    function updateDevice(uint _id, string memory _name, string memory _typeOfDevice) public {
        address _owner = msg.sender;
        for(uint i = 0; i<devices.length; i++){
            if(devices[i].uuID == _id && devices[i].owner == _owner){
                devices[i].name = _name;
                devices[i].typeOfDevice = _typeOfDevice;
                emit onDeviceUpdated(_owner, _name, _typeOfDevice, block.timestamp, _id);
            }
        }
    }

    function transferOwnershipOfDevice(uint _id, address _to) public {
        address _from = msg.sender;
        require(_from != _to, "You can not use the same address");
        for(uint i = 0; i<devices.length; i++){
            if(devices[i].uuID == _id && devices[i].owner == _from){
                devices[i].owner = _to;
                emit onDeviceTransferOwnership(_from, _to, _id);
            }
        }
    }

    function recordEnergyPerDevice(uint _id, uint _energy) public {
        address _owner = msg.sender;
        for(uint i = 0; i<devices.length; i++){
            if(devices[i].uuID == _id && devices[i].owner == _owner){
                devices[i].energy = devices[i].energy + _energy;
                emit onEnergyRecorded(_owner, _id, _energy, block.timestamp);
            }
        }
    }

    function getCountOfDevices() public view returns(uint){
        address currentAddr = msg.sender;
        uint count = 0;
        for(uint i = 0; i<devices.length; i++){
            if(devices[i].owner == currentAddr){
                count++;
            }
        }
        return count;
    }

    ///@notice In order to iterate with the devices of a given address we need this extra function with the current legth of device array
    ///@notice So in the Front end we would need to get the length and iterate for each device that we want to list in our platform 
    ///@notice and get the index for that device
    function getMyDevices(uint _id) public view returns(uint, string memory, string memory, uint){
        uint index = deviceMap[_id];
        require(devices.length > index, "Wrong index");
        require(devices[index].uuID == _id, "Wrong ID");
        return(devices[index].uuID, devices[index].typeOfDevice, devices[index].name, devices[index].date);
    }

    function getTotalEnergy() public view returns(uint) {
        address currentAddr = msg.sender;
        uint res = 0;
        for(uint i = 0; i<devices.length; i++){
            if(devices[i].owner == currentAddr){
                res = res + devices[i].energy;
            }
        }
        return res;
    }

    ///@notice Solidity generally can not return dynamic string arrays
    ///@notice so, you can use this function to show the available energy per device
    ///@notice and name, type of device as well, when someone click on it.
    function getEnergyPerDevice(uint _id) public view returns(uint) {
        uint index = deviceMap[_id];
        require(devices.length > index, "Wrong index");
        require(devices[index].uuID == _id, "Wrong ID");
        return(devices[index].energy);
    }
}