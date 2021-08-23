pragma solidity 0.4.24;

import "./SafeMath.sol";
import "./Whitelist.sol";
import "./ISelfServiceFrequencyControls.sol";

contract SelfServiceFrequencyControls is ISelfServiceFrequencyControls, Whitelist {
  using SafeMath for uint256;

  // frozen out for..
  uint256 public freezeWindow = 1 days;

  // When the current time period started
  mapping(address => uint256) public frozenTil;

  // Frequency override list for users - you can temporaily add in address which disables the 24hr check
  mapping(address => bool) public frequencyOverride;

  constructor() public {
    super.addAddressToWhitelist(msg.sender);
  }

  function canCreateNewEdition(address artist) external view returns (bool) {
    if (frequencyOverride[artist]) {
      return true;
    }
    return (block.timestamp >= frozenTil[artist]);
  }

  function recordSuccessfulMint(address artist, uint256 totalAvailable, uint256 priceInWei) external onlyIfWhitelisted(msg.sender) returns (bool) {
    frozenTil[artist] = block.timestamp.add(freezeWindow);
    return true;
  }

  function setFrequencyOverride(address artist, bool value) external onlyIfWhitelisted(msg.sender) {
    frequencyOverride[artist] = value;
  }

  /**
   * @dev Sets freeze window
   * @dev Only callable from owner
   */
  function setFreezeWindow(uint256 _freezeWindow) onlyIfWhitelisted(msg.sender) public {
    freezeWindow = _freezeWindow;
  }

  /**
   * @dev Allows for the ability to extract stuck ether
   * @dev Only callable from owner
   */
  function withdrawStuckEther(address _withdrawalAccount) onlyIfWhitelisted(msg.sender) public {
    require(_withdrawalAccount != address(0), "Invalid address provided");
    _withdrawalAccount.transfer(address(this).balance);
  }
}