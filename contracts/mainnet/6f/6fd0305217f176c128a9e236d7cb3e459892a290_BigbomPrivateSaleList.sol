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

contract BigbomPrivateSaleList is Ownable {
    mapping(address=>uint) public addressCap;

    function BigbomPrivateSaleList() public  {}

    event ListAddress( address _user, uint _amount, uint _time );

    // Owner can delist by setting amount = 0.
    // Onwer can also change it at any time
    function listAddress( address _user, uint _amount ) public onlyOwner {
        require(_user != address(0x0));

        addressCap[_user] = _amount;
        ListAddress( _user, _amount, now );
    }

    // an optimization in case of network congestion
    function listAddresses( address[] _users, uint[] _amount ) public onlyOwner {
        require(_users.length == _amount.length );
        for( uint i = 0 ; i < _users.length ; i++ ) {
            listAddress( _users[i], _amount[i] );
        }
    }

    function getCap( address _user ) public constant returns(uint) {
        return addressCap[_user];
    }

}