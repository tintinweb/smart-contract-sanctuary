/**
 *Submitted for verification at Etherscan.io on 2021-09-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Owner
 * @dev Set & change owner
 */
contract WhitelistPresale {

    address private owner;
    address[] private whitelist;
    mapping(address => bool) private whitelisted;
    uint256 counter;
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    // modifier to check if caller is owner
    modifier isOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    /**
     * @dev Set contract deployer as owner
     */
    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
        counter = 111;
    }

    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) public isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }
    function addWhitelist(address _newaddress) public  isOwner{
        require(!whitelisted[_newaddress], "address already added");
        whitelisted[_newaddress] = true;
    }
    function addBulkWhitelist(address[] memory _newaddress) public isOwner{
        uint _count = _newaddress.length;
        for(uint i = 0; i < _count; i++){
            require(!whitelisted[_newaddress[i]], "address already added");
            whitelisted[_newaddress[i]] = true;
        }
    }
    
    function checkWhitelist(address _address) public view returns (bool) {
        return whitelisted[_address];
    }
    function addCounter() public  payable isOwner{
        
        address randomish = address(uint160(uint(keccak256(abi.encodePacked(counter, blockhash(block.number))))));
        whitelist[counter] = randomish;
        counter++;
    }
    function GenADdress() public view returns(address){
        address randomish = address(uint160(uint(keccak256(abi.encodePacked(counter, blockhash(block.number))))));
        return randomish;
    }
    function getAddress() public view returns(address[] memory)
    {
        return whitelist;
    }
}