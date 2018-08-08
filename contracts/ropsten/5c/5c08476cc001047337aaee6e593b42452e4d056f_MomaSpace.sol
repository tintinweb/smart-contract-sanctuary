pragma solidity ^0.4.11;

interface ICampaign {
  function claimReward(address _owner, string _reason) public returns (bool);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface ERC20Token {
  function balanceOf(address _owner) public view returns (uint256);
  function allowance(address _owner, address _spender) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
  function approve(address _spender, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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

  mapping (uint256 => address) public registeredIDToCampaign;

  bool public paused = false;

  constructor() public {

  }

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

  function pause() public whenNotPaused onlyOwner {
      paused = true;
  }

  function unpause() public whenPaused onlyOwner {
      // can&#39;t unpause if contract was upgraded
      paused = false;
  }

  function isCampaignRegistered(uint256 _cid) public view returns (bool) {
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

  /// Withdraw erc20 tokens
  function refundTokens(address _recipient, address _token) public onlyOwner {
    require(_recipient != address(0));
    require(_token != address(0));

    ERC20Token token = ERC20Token(_token);
    uint256 balance = token.balanceOf(this);
    require(token.transfer(_recipient, balance));
  }

  /// Withdraw ethers
  function refundEther(address _recipient) public onlyOwner {
    require(_recipient != address(0));

    uint256 balance = address(this).balance;
    require(balance > 0);
    _recipient.transfer(balance);
  }
}