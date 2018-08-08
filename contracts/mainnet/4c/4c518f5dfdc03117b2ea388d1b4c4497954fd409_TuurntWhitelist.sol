pragma solidity ^0.4.23;

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

contract TuurntWhitelist is Ownable{

    mapping(address => bool) public whitelist;
    address public airdrop;
    
    /**
    * @dev Set the airdrop contract address.
    @param _airdrop Airdrop contract address
    */
    function setAirdropAddress(address _airdrop) public onlyOwner{
        airdrop = _airdrop;
    }
  /**
   * @dev Adds single address to whitelist.
   * @param _beneficiary Address to be added to the whitelist
   */
    function addToWhitelist(address _beneficiary) external onlyOwner {
        whitelist[_beneficiary] = true;
    }

  /**
   * @dev Adds list of addresses to whitelist. Not overloaded due to limitations with truffle testing.
   * @param _beneficiaries Addresses to be added to the whitelist
   */
    function addManyToWhitelist(address[] _beneficiaries) external onlyOwner {
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            whitelist[_beneficiaries[i]] = true;
        }
    }

  /**
   * @dev Removes single address from whitelist.
   * @param _beneficiary Address to be removed to the whitelist
   */
    function removeFromWhitelist(address _beneficiary) external onlyOwner {
        whitelist[_beneficiary] = false;
    }

    /**
    * @dev Check whether the address is in the whitelist.
    * @param _whiteListAddress Whitelisted user address 
    */
    function checkWhitelist(address _whiteListAddress) public view returns(bool){
        if(whitelist[_whiteListAddress])
            return true;
        else
            return false;
    }

}