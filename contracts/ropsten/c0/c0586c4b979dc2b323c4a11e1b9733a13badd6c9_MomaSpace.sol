pragma solidity ^0.4.11;

interface ICampaign {
  function claimReward(address _owner, string _reason) public returns (bool);
}
/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract Pauseable {
  bool public paused = false;

  /// @dev Modifier to allow actions only when the contract IS NOT paused
  modifier whenNotPaused() {
      require(!paused);
      _;
  }

  /// @dev Modifier to allow actions only when the contract IS paused
  modifier whenPaused {
      require(paused);
      _;
  }

  function pause() public whenNotPaused {
      paused = true;
  }

  function unpause() public whenPaused {
      // can&#39;t unpause if contract was upgraded
      paused = false;
  }
}

contract MomaSpace is Ownable, Pauseable {

  mapping (uint256 => address) registeredIDToCampaign;

  function MomaSpace() public {

  }

  function isCampaignRegistered(uint256 _cid) public returns (bool) {
    return registeredIDToCampaign[_cid] != 0x0;
  }

  function registerCampaign(uint256 _cid, address _campaignAddress) public onlyOwner {
    require(_campaignAddress != 0x0);
    registeredIDToCampaign[_cid] = _campaignAddress;
  }

  function unRegisterCampaign(uint256 _cid) public onlyOwner {
    require(isCampaignRegistered(_cid));
    delete registeredIDToCampaign[_cid];
  }

  function claimRewardBy(address _owner, uint256 _cid, string reason) public onlyOwner {
    require(isCampaignRegistered(_cid));
    require(_owner != address(0));

    address contractAddress = registeredIDToCampaign[_cid];
    ICampaign campaign = ICampaign(contractAddress);
    campaign.claimReward(_owner, reason);
  }
}