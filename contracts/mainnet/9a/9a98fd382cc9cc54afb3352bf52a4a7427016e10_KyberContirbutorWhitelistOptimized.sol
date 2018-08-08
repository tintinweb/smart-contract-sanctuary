pragma solidity ^0.4.11;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
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
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}


contract KyberContirbutorWhitelist is Ownable {
    mapping(address=>uint) addressCap;
    
    function KyberContirbutorWhitelist() {}
    
    event ListAddress( address _user, uint _cap, uint _time );
    
    // Owner can delist by setting cap = 0.
    // Onwer can also change it at any time
    function listAddress( address _user, uint _cap ) onlyOwner {
        addressCap[_user] = _cap;
        ListAddress( _user, _cap, now );
    }
    
    function getCap( address _user ) constant returns(uint) {
        return addressCap[_user];
    }
}

contract KyberContirbutorWhitelistOptimized is KyberContirbutorWhitelist {
    uint public slackUsersCap = 7;
    
    function KyberContirbutorWhitelistOptimized() {}
    
    function listAddresses( address[] _users, uint[] _cap ) onlyOwner {
        require(_users.length == _cap.length );
        for( uint i = 0 ; i < _users.length ; i++ ) {
            listAddress( _users[i], _cap[i] );   
        }
    }
    
    function setSlackUsersCap( uint _cap ) onlyOwner {
        slackUsersCap = _cap;        
    }
    
    function getCap( address _user ) constant returns(uint) {
        uint cap = super.getCap(_user);
        
        if( cap == 1 ) return slackUsersCap;
        else return cap;
    }
}