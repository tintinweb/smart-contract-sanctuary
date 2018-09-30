pragma solidity ^0.4.25;

/// @title A very simple contract that can store one link (a string) for each Eth address.
/// @author random tree
contract StoreLink {
    
    /// @notice The mapping that goes from addresses to links (strings). 
    mapping(address => string) private linkOf;
    
    /// @notice An event that fires when a link is changed.
    /// @param owner The address whose link changed. Indexable.
    /// @param newLink The new value of the link (there may or may not have been an old one.)
    event LinkChanged(address indexed owner, string newLink);
    
    /// @notice A function that allows a user to set the link associated with their address.
    /// @param _link The new value of the link. Must be <= 32 characters.
    function setLink(string _link) public {
        
        // Enforce byte-length limit.
        require(bytes(_link).length <= 32);
        
        // Save the link.
        linkOf[msg.sender] = _link;
        
        // Notify any watchers.
        emit LinkChanged(msg.sender, _link);
    }
    
    /// @notice A function that allows anyone to look up the link for any address.
    /// @param _owner The address to look up.
    /// @return The link (a string), or false/0 if it was never set.
    function getLink(address _owner) public view returns (string) {
        return linkOf[_owner];
    }
}