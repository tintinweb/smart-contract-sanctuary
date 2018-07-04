// File: contracts\Authorized.sol

//pragma solidity ^0.4.11;
pragma solidity ^0.4.24;

/**
 * @title Authorized
 * @dev The Authorized contract has an Authorized address, and provides basic authorization control
 *  it can be multiple authority.

 */


contract Authorized {
  mapping (address => bool) public AuthorizedUser;
  event AuthorizedUserChanged(address indexed addr, bool state );

/**
 * @dev Authorized constructors grant default authorizations to contract authors.
 */
  constructor() public{
    AuthorizedUser[msg.sender] = true;
  }

  modifier onlyAuthorized() {
    require(AuthorizedUser[msg.sender]);
    _;
  }

  /**
   * register and change authorized user
   */
  function setAuthorizedUser(address addr, bool state) onlyAuthorized public {
    AuthorizedUser[addr] = state;
    emit AuthorizedUserChanged(addr, state);
  }

}

// File: contracts\HBRIdentification.sol

//pragma solidity ^0.4.11;
pragma solidity ^0.4.24;


/**
 * @title IntegrityService
 * @dev The identification contract confirms the identity of the investor for the purpose of kyc / aml.
 *
 * todo authority level
 * step 1 approve system
 * step 2 approve 3rd party
 * step 3 approve self 
 * step 4 approve self and system (3rd party)
 */
 
contract HBRIdentification is Authorized {

  mapping (address => bool)  IdentificationDb;

  event proven(address addr,bool isConfirm);


  //Identification check for KYC/AML
  function verify(address _addr) public view returns(bool) {
   return IdentificationDb[_addr];
  }

  //Register members whose identity information has been verified on the website by batch system, for KYC/AML
  function provenAddress(address _addr, bool _isConfirm) public onlyAuthorized {
    IdentificationDb[_addr] = _isConfirm;
    emit proven(_addr,_isConfirm);
  }


  function provenAddresseList(address[] _addrs, bool _isConfirm) public onlyAuthorized{
    for (uint256 i = 0; i < _addrs.length; i++) {
      provenAddress(_addrs[i],_isConfirm);
    }
  }
}