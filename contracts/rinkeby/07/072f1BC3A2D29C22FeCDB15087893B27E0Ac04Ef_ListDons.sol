/**
 *Submitted for verification at Etherscan.io on 2021-09-05
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

contract ListDons {
    mapping (uint => address) public list; // Default: public -- Check address for listing
    mapping (address => uint) private list1; // Default: private -- Internal
    mapping (address => mapping(uint => string)) public textList; // Default: public -- Check address for donations
    mapping (address => uint) public amountList; // Default: public -- Check amount of donations
    mapping (address => uint) private addressTextCount; // Default: private -- Internal
    uint private countAddresses = 1; // Default: private -- Number of addresses

    address public owner; // Owner address
    address public daoContract; // DAO contract address

    string public status = "0: Success";
    uint timeOut = 12 hours;
    uint private time;

    constructor() {
        owner = msg.sender; // Owner initialization
    }

    // Modifier to protect against calls is not a contract creator
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }

    // Modifier to protect against calls not by DAO
    modifier onlyDAO(){
        require(msg.sender == daoContract);
        _;
    }

    // Function for installation / replacement contract DAO
    function setDAOContract(address _newDAO) onlyOwner public {
        daoContract = _newDAO;
    }

    // Function for viewing the owner from the outside
    function viewOwner() public onlyDAO view returns (address _owner) {
        return owner;
    }

    // Function for interacting with mapping from the outside
    function changeTextList(string memory _func, string memory _string, address _address, uint _num) onlyDAO public {
            if (strToBytes32(_func) == strToBytes32("change")) {
                textList[_address][_num] = _string;
            }
            if (strToBytes32(_func) == strToBytes32("delete")) {
                delete textList[_address][_num];
            }
            if (strToBytes32(_func) == strToBytes32("full-delete")) {
                for(uint i = 0 ; i<addressTextCount[_address]; i++){
                    delete textList[_address][i];
                }
            }
    }

    // 1/4 Converting address to str
    function toString(address _account) internal pure returns(string memory) {
        return toString(abi.encodePacked(_account));
    }

    // 2/4 Converting address to str
    function toString(uint256 _value) internal pure returns(string memory) {
        return toString(abi.encodePacked(_value));
    }

    // 3/4 Converting address to str
    function toString(bytes32 _value) internal pure returns(string memory) {
        return toString(abi.encodePacked(_value));
    }

    // 4/4 Converting address to str
    function toString(bytes memory _data) internal pure returns(string memory) {
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(2 + _data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint i = 0; i < _data.length; i++) {
            str[2+i*2] = alphabet[uint(uint8(_data[i] >> 4))];
            str[3+i*2] = alphabet[uint(uint8(_data[i] & 0x0f))];
        }
        return string(str);
    }

    // Convert string to bytes32
    function strToBytes32(string memory _string) internal pure returns(bytes32) {
        return keccak256(abi.encodePacked(_string));
    }

    // (Deprecate?) Listing of all addresses
    function allDonatorsList() public view returns(string memory) {
        bytes memory b;
        b = abi.encodePacked("");
        for(uint i = 1 ; i<countAddresses; i++){
            b = abi.encodePacked(b, toString(list[i]));
            b = abi.encodePacked(b, " ");
        }
        string memory str = string(b);
        return str;
    }

    // Listing of all addresses + texts
    function allDonatorsText() public view returns(string memory) {
        bytes memory b;
        bytes memory d;

        b = abi.encodePacked("");
        for(uint i = 1 ; i<countAddresses; i++){
            b = abi.encodePacked(b, toString(list[i]));
            b = abi.encodePacked(b, " ");
            for(uint x = 0 ; x<addressTextCount[list[i]]; x++){
                d = abi.encodePacked(b, textList[list[i]][x]);
                b = abi.encodePacked(d, ", ");
            }
            b = abi.encodePacked(d, "\n");
        }
        string memory str = string(b);
        return str;
    }

    // Send text
    function donateWithText(string memory _text) public{
        require(amountList[msg.sender] >= 0.0005 ether);
        require(strToBytes32(_text) != strToBytes32("")
            &&  strToBytes32(_text) != strToBytes32(" "));
        textList[msg.sender][addressTextCount[msg.sender]] = _text;
        addressTextCount[msg.sender]++;
        amountList[msg.sender] -= 0.0005 ether;
    }

    // Record of all donaters and donations to the list
    receive() external payable {
        if(list1[msg.sender] == 0){
            list[countAddresses] = msg.sender;
            list1[msg.sender] = countAddresses;
            countAddresses++;
        }
        amountList[msg.sender] += msg.value;
    }

    // Show contract balance
    function contractBalance() public view returns(uint256){
        return address(this).balance;
    }

    // Show address balance
    function addressBalance(address _address) public view returns(uint256) {
        return amountList[_address];
    }

    // Preparation for destruct
    function switch_admin(string memory _string) onlyOwner public {
        if (keccak256(abi.encodePacked(_string)) == keccak256(abi.encodePacked("/destruct"))) {
            setTime();
            status = "1: Alert. Contract may be destroyed after 12 hours";
        }
        if (keccak256(abi.encodePacked(_string)) == keccak256(abi.encodePacked("/recover"))) {
            require(time != 0);
            require(time + timeOut < block.timestamp);
            time = 0;
            status = "0: Success";
        }
    }

    // Destruct contract
    function destruct_admin() onlyOwner public {
        require(time != 0);
        require(time + timeOut < block.timestamp);
        selfdestruct(payable(owner));
    }

    // Set time
    function setTime() internal {
        time = block.timestamp;
    }
}