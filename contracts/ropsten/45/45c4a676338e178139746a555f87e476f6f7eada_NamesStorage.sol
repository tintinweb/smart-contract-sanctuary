// solhint-disable max-line-length
// @title A contract to store only messages sent by owner

/* Deployment:
Owner: 0x4460f4c8edbca96f9db17ef95aaf329eddaeac29
Address: 0x45c4a676338e178139746a555f87e476f6f7eada
ABI: [{"constant":false,"inputs":[{"name":"_dataInfo","type":"string"}],"name":"addMapping","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[],"name":"kill","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[{"name":"","type":"address"}],"name":"names","outputs":[{"name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"owner","outputs":[{"name":"","type":"address"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"contentCount","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"_dataInfo","type":"string"},{"name":"_version","type":"uint256"}],"name":"addEvent","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"inputs":[],"payable":false,"stateMutability":"nonpayable","type":"constructor"},{"payable":false,"stateMutability":"nonpayable","type":"fallback"},{"anonymous":false,"inputs":[{"indexed":true,"name":"version","type":"uint256"},{"indexed":false,"name":"dataInfo","type":"string"}],"name":"LogMessage","type":"event"}]
Optimized: yes
Solidity version: v0.4.24
*/

// solhint-enable max-line-length

pragma solidity 0.4.24;


contract NamesStorage {

    address public owner;

    uint public contentCount = 0;
    mapping (address => string) public names;
    
    event LogMessage(uint indexed version, string dataInfo);

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    constructor() public {
        owner = msg.sender;
    }

    // @notice fallback function, don&#39;t allow call to it
    function () public {
        revert();
    }
    
    function kill() public onlyOwner {
        selfdestruct(owner);
    }

    function addEvent(string _dataInfo, uint _version) public {
        contentCount++;
        emit LogMessage(_version, _dataInfo);
    }
    
    function addMapping(string _dataInfo) public {
        names[msg.sender] = _dataInfo;
    }
}