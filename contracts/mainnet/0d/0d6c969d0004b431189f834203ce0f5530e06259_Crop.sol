pragma solidity ^0.4.23;

interface P3D {
  function() payable external;
  function buy(address _playerAddress) payable external returns(uint256);
  function sell(uint256 _amountOfTokens) external;
  function reinvest() external;
  function withdraw() external;
  function exit() external;
  function dividendsOf(address _playerAddress) external view returns(uint256);
  function balanceOf(address _playerAddress) external view returns(uint256);
  function transfer(address _toAddress, uint256 _amountOfTokens) external returns(bool);
  function stakingRequirement() external view returns(uint256);
  function myDividends(bool _includeReferralBonus) external view returns(uint256);
}

contract Crop {
  address public owner;
  bool public disabled;

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function() public payable {}
  
  /**
   * @dev Turn reinvest on / off
   * @param _disabled bool to determine state of reinvest.
   */
  function disable(bool _disabled) external onlyOwner() {
    // toggle disabled
    disabled = _disabled;
  }

  /**
   * @dev Enables anyone with a masternode to earn referral fees on P3D reinvestments.
   */
  function reinvest() external {
    // reinvest must be enabled
    require(disabled == false);
    
    // setup p3d
    P3D p3d = P3D(0xB3775fB83F7D12A36E0475aBdD1FCA35c091efBe);

    // withdraw dividends
    p3d.withdraw();

    // reinvest with a referral fee for sender
    p3d.buy.value(address(this).balance)(msg.sender);
  }

  /**
   * @dev Buy P3D tokens
   * @param _playerAddress referral address.
   */
  function buy(address _playerAddress) external payable onlyOwner() {
    P3D(0xB3775fB83F7D12A36E0475aBdD1FCA35c091efBe).buy.value(msg.value)(_playerAddress);
  }

  /**
   * @dev Sell P3D tokens and send balance to owner
   * @param _amountOfTokens amount of tokens to sell.
   */
  function sell(uint256 _amountOfTokens) external onlyOwner() {
    // sell tokens
    P3D(0xB3775fB83F7D12A36E0475aBdD1FCA35c091efBe).sell(_amountOfTokens);

    // transfer to owner
    owner.transfer(address(this).balance);
  }

  /**
   * @dev Withdraw P3D dividends and send balance to owner
   */
  function withdraw() external onlyOwner() {
    // withdraw dividends
    P3D(0xB3775fB83F7D12A36E0475aBdD1FCA35c091efBe).withdraw();

    // transfer to owner
    owner.transfer(address(this).balance);
  }

  /**
   * @dev Sell P3D tokens, withdraw dividends, and send balance to owner
   */
  function exit() external onlyOwner() {
    // sell all tokens and withdraw
    P3D(0xB3775fB83F7D12A36E0475aBdD1FCA35c091efBe).exit();

    // transfer to owner
    owner.transfer(address(this).balance);
  }
  
  /**
   * @dev Transfer P3D tokens
   * @param _toAddress address to send tokens to.
   * @param _amountOfTokens amount of tokens to send.
   */
  function transfer(address _toAddress, uint256 _amountOfTokens) external onlyOwner() returns (bool) {
    return P3D(0xB3775fB83F7D12A36E0475aBdD1FCA35c091efBe).transfer(_toAddress, _amountOfTokens);
  }

  /**
   * @dev Get dividends for this contract
   * @param _includeReferralBonus for including referrals in dividends.
   */
  function dividends(bool _includeReferralBonus) external view returns (uint256) {
    return P3D(0xB3775fB83F7D12A36E0475aBdD1FCA35c091efBe).myDividends(_includeReferralBonus);
  }
}