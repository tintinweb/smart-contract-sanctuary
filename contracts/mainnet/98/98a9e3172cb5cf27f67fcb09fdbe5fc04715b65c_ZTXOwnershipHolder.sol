pragma solidity 0.4.24;

// File: contracts/ZTXInterface.sol

contract ZTXInterface {
    function transferOwnership(address _newOwner) public;
    function mint(address _to, uint256 amount) public returns (bool);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function unpause() public;
}

// File: zeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
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
  constructor() public {
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

// File: contracts/ZTXOwnershipHolder.sol

/**
 * @title ZTXOwnershipHolder - Sole responsibility is to hold and transfer ZTX ownership
 * @author Gustavo Guimaraes - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="a2c5d7d1d6c3d4cde2d8d7ced7d0c7d2d7c0cecbc18ccbcd">[email&#160;protected]</a>>
 * @author Timo Hedke - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="e5918c888aa59f9089909780959087898c86cb8c8a">[email&#160;protected]</a>>
 */
contract ZTXOwnershipHolder is Ownable {

      /**
     * @dev Constructor for the airdrop contract
     * @param _ztx ZTX contract address
     * @param newZuluOwner New ZTX owner address
     */
    function transferZTXOwnership(address _ztx, address newZuluOwner) external onlyOwner{
        ZTXInterface(_ztx).transferOwnership(newZuluOwner);
    }
}