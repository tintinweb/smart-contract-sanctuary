/**
 *Submitted for verification at Etherscan.io on 2021-05-16
*/

pragma solidity =0.6.6;

contract Ownable {
    address public owner;

    /**
      * @dev The Ownable constructor sets the original `owner` of the contract to the sender
      * account.
      */
    constructor() public {
        owner = msg.sender;
    }

    /**
      * @dev Throws if called by any account other than the owner.
      */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

}
contract Config is Ownable{
    mapping(string => string) public strMap;
    mapping(string => uint) public numMap;
    mapping(string => address) public addrMap;

    function setStr( string memory key,  string memory value) public onlyOwner {
        strMap[key] = value;
    }

    function setInt( string memory key,  uint  value) public onlyOwner {
        numMap[key] = value;
    }

    function setAddr( string memory key,  address  value) public onlyOwner {
        addrMap[key] = value;
    }

}