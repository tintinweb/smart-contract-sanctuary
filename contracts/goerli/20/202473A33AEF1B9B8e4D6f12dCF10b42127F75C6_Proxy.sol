pragma solidity ^0.5.1;
import "./blockset.sol";
import "./owner.sol";
contract Proxy is Ownable{
    address blockset;
    BlockSet hpbBlockSet;

    constructor () payable public {
        owner = msg.sender;
        addAdmin(owner);
    }

    function setcontract(address payable addr) onlyAdmin public{
        blockset = addr;
        hpbBlockSet = BlockSet(addr);
    }

    function getcontract() public view returns(address){
        return blockset;
    }

    function getValue(string calldata key) external view returns (uint256) {
        return hpbBlockSet.getValue(key);
    }
}