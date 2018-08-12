pragma solidity ^0.4.17;

interface BlacklistInterface {

    event Blacklisted(bytes32 indexed node);
    event Unblacklisted(bytes32 indexed node);
    
    function blacklist(bytes32 node) public;
    function unblacklist(bytes32 node) public;
    function isPermitted(bytes32 node) public view returns (bool);

}

contract Ownable {

    address public owner;

    modifier onlyOwner {
        require(isOwner(msg.sender));
        _;
    }

    function Ownable() public {
        owner = msg.sender;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }

    function isOwner(address addr) public view returns (bool) {
        return owner == addr;
    }
}

contract Blacklist is BlacklistInterface, Ownable {

    mapping (bytes32 => bool) blacklisted;
    
    /**
     * @dev Add a node to the blacklist.
     * @param node The node to add to the blacklist.
     */
    function blacklist(bytes32 node) public onlyOwner {
        blacklisted[node] = true;
        Blacklisted(node);
    }
    
    /** 
     * @dev Remove a node from the blacklist.
     * @param node The node to remove from the blacklist.
     */
    function unblacklist(bytes32 node) public onlyOwner {
        blacklisted[node] = false;
        Unblacklisted(node);
    }
    
    /**
     *  @dev Return true if the node is permitted, false otherwise. Every nodes, except the blacklisted ones, are permitted.
     *  @param node The node.
     */
    function isPermitted(bytes32 node) public view returns (bool) {
        return !blacklisted[node];
    }
}