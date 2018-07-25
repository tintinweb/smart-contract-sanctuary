pragma solidity ^0.4.21;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of &quot;user permissions&quot;.
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


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
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

contract Octopeth is Ownable {

  struct dApp {
    address owner;
    string title;
    string url;
    string logo;
    string desc;
    string contact;
    bytes32 hash;
    categories cat;
    bool approved;
  }

  enum categories {OTHER, GAMING, ENTERTAINMENT, FINANCE, SOCIAL, EXCHANGE, GAMBLING, TOKENS, SHARING, GOVERNANCE}

  event Publish(address owner, string title, string url, string contact, string logo, string desc, bytes32 hash, categories cat);
  event Approve(address owner, string title, string url, string contact, string logo, string desc, bytes32 hash, categories cat);
  event Remove(string indexed title);

  mapping (string => dApp) dApps;

  function publish(string title, string url, string contact, string logo, string desc, bytes32 hash, categories cat) public {
    require(dApps[title].owner == address(0) || dApps[title].owner == msg.sender);
    dApp memory newdApp = dApp(msg.sender, title, url, logo, desc, contact, hash, cat, false);
    dApps[title] = newdApp;
    emit Publish(msg.sender, title, url, contact, logo, desc, hash, cat);
  }

  function approve(string title) public onlyOwner {
    dApp storage thisdApp = dApps[title];
    dApps[title].approved = true;
    emit Approve(thisdApp.owner, thisdApp.title, thisdApp.url, thisdApp.contact, thisdApp.logo, thisdApp.desc, thisdApp.hash, thisdApp.cat);
  }

  function remove(string title) public onlyOwner {
    dApps[title].approved = false;
    emit Remove(title);
  }
}