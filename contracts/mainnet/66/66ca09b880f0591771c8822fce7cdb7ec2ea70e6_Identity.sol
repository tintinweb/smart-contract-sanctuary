/**
 *Submitted for verification at Etherscan.io on 2020-05-11
*/

pragma solidity >=0.4.0 <0.7.0;

contract Identity {

     // ************ Modifier *********** //
    modifier onlyManager() {
        require(msg.sender == owner, "Not allowed");
        _;
    }

    modifier onlyAddressAllowed() {
        require(addressAllowed[msg.sender] == true, "Not allowed");
        _;
    }


    // ************** Events ************ //
    event addressAllowedAdded(string, address);
    event addressAllowedRemoved(string, address);
    event memberAdded(string, string);
    event memeberRemoved(string, string);
    event updated(string, string);


    address private owner;
    mapping (address => bool) private addressAllowed;
    mapping (string => bool) private member_exist;
    mapping (string => address) private members;

    constructor() public {
        owner = msg.sender;
    }

    function addAddressAllowed(address _address_allowed) external onlyManager {
        addressAllowed[_address_allowed] = true;
        emit addressAllowedAdded("Added new address allowed: ", _address_allowed);
    }

    function removeAddressAllowed(address _address_allowed) external onlyManager {
        addressAllowed[_address_allowed] = false;
        emit addressAllowedRemoved("Removed address allowed: ", _address_allowed);
    }

    function addMember(string calldata hash, address _address) external onlyAddressAllowed {
        require(member_exist[hash] == false, "Member already exist");

        members[hash] = _address;
        member_exist[hash] = true;

        emit memberAdded("Added new member with hash: ", hash);
    }

    function removeMember(string calldata hash) external onlyAddressAllowed {
        require(member_exist[hash] == true, "Member does not exist");

        members[hash] = address(0x0);
        member_exist[hash] = false;

        emit memeberRemoved("Removed member with hash: ", hash);
    }

    function updateMember(string calldata hash, address _address) external onlyAddressAllowed {
        require(member_exist[hash] == true, "Member does not exist");

        members[hash] = _address;

        emit updated("Updated member with hash: ", hash);
    }

    function isTrusted(string calldata hash, address _address) external view onlyAddressAllowed returns (bool)  {
        require(bytes(hash).length > 0, "Hash is required");
        require(_address != address(0), "address is required");

        address tmp_address = members[hash];

        if (tmp_address == _address) {
            return true;
        } else {
            return false;
        }

    }

}