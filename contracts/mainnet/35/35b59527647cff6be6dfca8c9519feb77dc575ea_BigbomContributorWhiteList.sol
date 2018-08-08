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
  function Ownable() public {
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

contract BigbomContributorWhiteList is Ownable {
    mapping(address=>uint) public addressMinCap;
    mapping(address=>uint) public addressMaxCap;

    function BigbomContributorWhiteList() public  {}

    event ListAddress( address _user, uint _mincap, uint _maxcap, uint _time );

    // Owner can delist by setting cap = 0.
    // Onwer can also change it at any time
    function listAddress( address _user, uint _mincap, uint _maxcap ) public onlyOwner {
        require(_mincap <= _maxcap);
        require(_user != address(0x0));

        addressMinCap[_user] = _mincap;
        addressMaxCap[_user] = _maxcap;
        ListAddress( _user, _mincap, _maxcap, now );
    }

    // an optimization in case of network congestion
    function listAddresses( address[] _users, uint[] _mincap, uint[] _maxcap ) public  onlyOwner {
        require(_users.length == _mincap.length );
        require(_users.length == _maxcap.length );
        for( uint i = 0 ; i < _users.length ; i++ ) {
            listAddress( _users[i], _mincap[i], _maxcap[i] );
        }
    }

    function getMinCap( address _user ) public constant returns(uint) {
        return addressMinCap[_user];
    }
    function getMaxCap( address _user ) public constant returns(uint) {
        return addressMaxCap[_user];
    }

}