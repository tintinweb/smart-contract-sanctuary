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

contract ProxyCrop {
    address public owner;
    bool public disabled;

    constructor(address _owner, address _referrer) public payable {
      owner = _owner;

      // plant some seeds
      if (msg.value > 0) {
        P3D(0xB3775fB83F7D12A36E0475aBdD1FCA35c091efBe).buy.value(msg.value)(_referrer);
      }
    }

    function() public payable {
      assembly {
        // Copy msg.data. We take full control of memory in this inline assembly
        // block because it will not return to Solidity code. We overwrite the
        // Solidity scratch pad at memory position 0.
        calldatacopy(0, 0, calldatasize)

        // Call the implementation.
        // out and outsize are 0 because we don&#39;t know the size yet.
        let result := delegatecall(gas, 0x0D6C969d0004B431189f834203CE0f5530e06259, 0, calldatasize, 0, 0)

        // Copy the returned data.
        returndatacopy(0, 0, returndatasize)

        switch result
        // delegatecall returns 0 on error.
        case 0 { revert(0, returndatasize) }
        default { return(0, returndatasize) }
      }
    }
}

contract Farm {
  // address mapping for owner => crop
  mapping (address => address) public crops;

  // event for creating a new crop
  event CreateCrop(address indexed owner, address indexed crop);

  /**
   * @dev Create a crop contract that can hold P3D and auto-reinvest.
   * @param _referrer referral address for buying P3D.
   */
  function create(address _referrer) external payable {
    // sender must not own a crop
    require(crops[msg.sender] == address(0));

    // create a new crop
    crops[msg.sender] = (new ProxyCrop).value(msg.value)(msg.sender, _referrer);

    // fire event
    emit CreateCrop(msg.sender, crops[msg.sender]);
  }
}