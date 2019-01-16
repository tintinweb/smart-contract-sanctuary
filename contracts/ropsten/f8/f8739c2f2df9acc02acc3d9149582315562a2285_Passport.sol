/**
 * @title Passport interface
 */
interface PassportInterface {

  function hasPass(address owner) external view returns (bool);

  function getPassOwner(bytes32 pass) external view returns (address);

  function isPassOwner(bytes32 pass, address owner) external view returns (bool);

  function getPass(address owner) external view returns (bytes32);

  function issuePass(address owner, bytes32 pass, uint8 zone) external returns (bool);

  function deactivatePass(bytes32 pass) external returns (bool);

  function activatePass(bytes32 pass) external returns (bool);

  function delegatePass(bytes32 pass, address to) external returns (bool);

  function burnPass(bytes32 pass, address from) external returns (bool);

  function transferPass(bytes32 pass, address newOwner) external returns (bool);

  event Issue(
    bytes32 indexed pass,
    address indexed owner,
    uint256 zone
  );

  event Delegate(
    bytes32 indexed pass,
    address indexed to
  );

  event Burn(
    bytes32 indexed pass,
    address indexed from
  );

  event Transfer(
    bytes32 indexed pass,
    address indexed from,
    address to
  );

  event Activate(
    bytes32 indexed pass
  );

  event Deactivate(
    bytes32 indexed pass
  );


}


contract PassportIssuer {
  address public superissuer;
  mapping (address => bool) public issuers;

  constructor() internal {
    superissuer = msg.sender;
    issuers[msg.sender] = true;
  }

  modifier onlySuperissuer() {
    require(msg.sender == superissuer);
    _;
  }

  modifier onlyIssuer() {
    require(isIssuer(msg.sender));
    _;
  }

  // Check if address is issuer
  function isIssuer(address issuer) public view returns (bool) {
    return issuers[issuer] == true ? true : false;
  }

  // Add new issuer
  function addIssuer(address newIssuer) public onlySuperissuer returns (bool) {
    issuers[newIssuer] = true;
    return true;
  }

  // Delete issuer
  function deleteIssuer(address issuer) public onlySuperissuer returns (bool) {
    issuers[issuer] = false;
    return true;
  }

  function transferOwnership(address newOwner) public onlySuperissuer {
    if (newOwner != address(0)) {
      superissuer = newOwner;
    }
  }

}

// File: contracts/Passport.sol

contract Passport is PassportInterface, PassportIssuer {

    struct Pass {
      bool active;
      address owner;
      uint8 zone;
    }

    mapping (address => bytes32) balance;
    mapping (bytes32 => Pass) passport;

    // Check if address have an passport
    function hasPass(address owner) public view returns(bool) {
      return passport[balance[owner]].active == true ? true : false;
    }

    // Get pass owner
    function getPassOwner(bytes32 pass) public view returns(address) {
      return passport[pass].owner;
    }

    // Check if address is pass owner
    function isPassOwner(bytes32 pass, address owner) public view returns(bool) {
      if (passport[pass].owner == owner){
        return true;
      } else {
        return false;
      }
    }

    // Get pass by address
    function getPass(address owner) public view returns(bytes32) {
       return balance[owner];
    }

    // Issue passport
    function issuePass(address owner, bytes32 pass, uint8 zone) public onlyIssuer returns(bool){
      passport[pass].active = true;
      passport[pass].owner = owner;
      passport[pass].zone = zone;
      balance[owner] = pass;
      emit Issue(pass, owner, zone);
      emit Delegate(pass, owner);
      return true;
    }

    // Deactivate pass
    function deactivatePass(bytes32 pass) public onlySuperissuer returns(bool){
      passport[pass].active = false;
      emit Deactivate(pass);
      return true;
    }

    // Activate pass
    function activatePass(bytes32 pass) public onlyIssuer returns(bool){
      passport[pass].active = true;
      emit Activate(pass);
      return true;
    }


    // Delegate pass to address
    function delegatePass(bytes32 pass, address to) public returns(bool) {
      require(isPassOwner(pass, msg.sender));
      balance[to] = pass;
      emit Delegate(pass, to);
      return true;
    }

    // Burn pass from address
    function burnPass(bytes32 pass, address from) public returns(bool) {
      require(isPassOwner(pass, msg.sender));
      balance[from] = 0x0;
      emit Burn(pass, from);
      return true;
    }

    // Transfer pass ownership to another address
    function transferPass(bytes32 pass, address newOwner) public returns (bool) {
      require(isPassOwner(pass, msg.sender));
      if (newOwner != address(0)) {
         passport[pass].owner = newOwner;
         emit Transfer(pass, msg.sender, newOwner);
         return true;
      }
    }

}