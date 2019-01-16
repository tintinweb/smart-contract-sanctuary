pragma solidity ^0.5.0;

// File: contracts/PassportInterface.sol

/**
 * @title Passport interface
 */
interface PassportInterface {

  function hasActivePass(address owner) external view returns(bool);

  function getPassOwner(bytes32 pass) external view returns (address);

  function isPassOwner(bytes32 pass, address owner) external view returns (bool);

  function isOwner(address account) external view returns(bool);

  function isIssuer(address account) external view returns(bool);

  function isProvider(address account) external view returns(bool);

  function isClient(address account) external view returns(bool);

  // function getPass(address owner) external view returns (bytes32);
  //
  // function issuePass(address owner, bytes32 pass, uint8 zone) external returns (bool);
  //
  // function deactivatePass(bytes32 pass) external returns (bool);
  //
  // function activatePass(bytes32 pass) external returns (bool);
  //
  // function delegatePass(bytes32 pass, address to) externalreturns (bool);
  //
  // function removePass(bytes32 pass, address from) externalreturns (bool);
  //
  // function transferPass(bytes32 pass, address newOwner) external returns (bool);
  //
  event Passport(
    bytes32 indexed pass,
    address indexed owner,
    uint256 typePass
  );
  //
  // event Delegate(
  //   bytes32 indexed pass,
  //   address indexed to
  // );
  //
  // event Remove(
  //   bytes32 indexed pass,
  //   address indexed from
  // );
  //
  // event Transfer(
  //   bytes32 indexed pass,
  //   address indexed from,
  //   address to
  // );
  //
  // event Activate(
  //   bytes32 indexed pass
  // );
  //
  // event Deactivate(
  //   bytes32 indexed pass
  // );


}

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner,address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner`of the contract to the sender
     * account.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control ofthe contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the`onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/Passport.sol

// import "./PassportProvider.sol";



contract Passport is PassportInterface, Ownable {

    struct Pass {
      // CORE
      uint8 typePass; // Passport type { 1 - business, 2 - personal}
      address ownerPass; // Passport owner account, can delegate and remove pass to other accounts
      bool isActive;
      // ROLES
      bool isOwner; // @ROLE OWNER / Passport has owner role
      bool isProvider; // @ROLE PROVIDER / Passport has provider role
      bool isIssuer; // @ROLE ISSUER / Passport has issuer role
      bool isClient;  // @ROLE ACCOUNT / Passport has accountrole
    }

    mapping (address => bytes32) attachment;
    mapping (bytes32 => Pass) passport;

    // Check if address have an passport
    function hasActivePass(address account) public view returns(bool) {
      return passport[attachment[account]].isActive == true ?true : false;
    }

    // Get passport owner
    function getPassOwner(bytes32 pass) public view returns(address) {
      return passport[pass].ownerPass;
    }

    // Get passport by address
    function getPass(address account) public view returns(bytes32) {
       return attachment[account];
    }

    // Check if address is pass owner
    function isPassOwner(bytes32 pass, address owner) public view returns(bool) {
      if (passport[pass].ownerPass == owner){
        return true;
      } else {
        return false;
      }
    }

    // ROLES checks functions

    // OWNER / Check if address has OWNER role
    function isOwner(address account) public view returns(bool) {
      require(hasActivePass(account));
      return passport[attachment[account]].isOwner == true ? true : false;
    }

    // PROVIDER / Check if address has PROVIDER role
    function isProvider(address account) public view returns(bool) {
      require(hasActivePass(account));
      return passport[attachment[account]].isProvider == true? true : false;
    }

    // CLIENT / Check if address has CLIENT role
    function isClient(address account) public view returns(bool) {
      require(hasActivePass(account));
      return passport[attachment[account]].isClient == true ?true : false;
    }

    // ISSUER / Check if address has ISSUER role
    function isIssuer(address account) public view returns(bool) {
      require(hasActivePass(account));
      return passport[attachment[account]].isIssuer == true ?true : false;
    }

    // PROVIDER / Grant account PROVIDER role
    function grantProvider(address account) public onlyOwner returns(bool) {
      require(hasActivePass(account));
      passport[attachment[account]].isProvider = true;
      return true;
    }

    // ISSUER / Grant account ISSUER role
    function grantIssuer(address account) public onlyOwner returns(bool) {
      require(hasActivePass(account));
      passport[attachment[account]].isIssuer = true;
      return true;
    }


    function issuePass(address account, bytes32 pass, uint8 typePass) public returns(bool){


      if (typePass == 3){
          require(isOwner());
          passport[pass].typePass = typePass;
          passport[pass].isActive = true;
          passport[pass].ownerPass = account;
      }
      else if (typePass == 1 || typePass == 2) {
        require(isProvider(msg.sender));
        passport[pass].typePass = typePass;
        passport[pass].isClient = true;
        passport[pass].isActive = true;
        passport[pass].ownerPass = account;
      }
      attachment[account] = pass;
      emit Passport(pass, account, typePass);
      // emit Delegate(pass, owner);
      return true;
    }
    //
    // // Deactivate pass
    // function deactivatePass(bytes32 pass) public onlyContractOwner returns(bool){
    //   passport[pass].active = false;
    //   emit Deactivate(pass);
    //   return true;
    // }
    //
    // // Activate pass
    // function activatePass(bytes32 pass) public onlyProvider returns(bool){
    //   passport[pass].active = true;
    //   emit Activate(pass);
    //   return true;
    // }
    //
    //
    // // Delegate pass to address
    // function delegatePass(bytes32 pass, address to) publicreturns(bool) {
    //   require(isPassOwner(pass, msg.sender));
    //   balance[to] = pass;
    //   emit Delegate(pass, to);
    //   return true;
    // }
    //
    // // Remove pass from address - only pass owner
    // function removePass(bytes32 pass, address from) publicreturns(bool) {
    //   require(isPassOwner(pass, msg.sender));
    //   balance[from] = 0x0;
    //   emit Remove(pass, from);
    //   return true;
    // }
    //
    // // Transfer pass ownership to another address
    // function transferPass(bytes32 pass, address newOwner) public returns (bool) {
    //   require(isPassOwner(pass, msg.sender));
    //   if (newOwner != address(0)) {
    //      passport[pass].owner = newOwner;
    //      emit Transfer(pass, msg.sender, newOwner);
    //      return true;
    //   }
    // }

}