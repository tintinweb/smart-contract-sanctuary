/**
 *Submitted for verification at Etherscan.io on 2021-02-06
*/

/**
 *Submitted for verification at Etherscan.io on 2021-01-31
*/

pragma solidity ^0.8.1;

contract Autem {
  address public owner;
  uint96  public lastPing;
  address public beneficiary;
  uint96  public window;

  string  public metadata;

  event Ping() anonymous;
  event SetOwner(address indexed _owner);
  event SetBeneficiary(address indexed _beneficiary);
  event SetWindow(uint96 _window);
  event Call(bool _success, bytes _result);

  constructor() {
    lastPing = uint96(1);
  }

  function setup(
    address _owner,
    address _beneficiary,
    uint96  _window,
    string calldata _metadata
  ) external returns (bool) {
    require(_owner != address(0), "E400");
    require(owner == address(0) && lastPing == 0, "E405");

    owner = _owner;
    lastPing = uint96(block.timestamp);
    beneficiary = _beneficiary;
    window = _window;

    emit Ping();
    emit SetOwner(_owner);
    emit SetBeneficiary(_beneficiary);
    emit SetWindow(_window);

    metadata = _metadata;

    return true;
  }

  modifier auth() {
    address m_owner = owner;

    if (msg.sender != m_owner) {
      if (msg.sender == beneficiary) {
        require(block.timestamp - lastPing >= window, "E425");
      } else {
        revert("E401");
      }
    }

    assert(msg.sender != address(0));

    _;

    if (m_owner == msg.sender) {
      lastPing = uint96(block.timestamp);
      emit Ping();
    }
  }

  function setMetadata(string calldata _metadata) external auth {
    metadata = _metadata;
  }

  function setOwner(address _owner) external auth {
    require(_owner != address(0), "E400");
    emit SetOwner(_owner);
    owner = _owner;
  }

  function setBeneficiary(address _beneficiary) external auth {
    emit SetBeneficiary(_beneficiary);
    beneficiary = _beneficiary;
  }

  function setWindow(uint96 _window) external auth {
    emit SetWindow(_window);
    window = _window;
  }

  function execute(address payable _to, uint256 _val, bytes calldata _data) external auth {
    if (_to == address(this)) return;

    (bool success, bytes memory result) = _to.call{ value: _val }(_data);
    emit Call(success, result);
  }

  fallback() external payable { }
  receive() external payable { }
}