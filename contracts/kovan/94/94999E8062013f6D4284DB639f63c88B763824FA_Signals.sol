pragma solidity ^0.5.0;

import "./IERC20.sol";

import "./ERC721EnumerableCustom.sol";
import "./ERC721MetadataCustom.sol";

/**
 * @title ERC-721 Non-Fungible Token with optional enumeration extension logic
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
contract Signals is ERC721Enumerable, ERC721Metadata {
  using SafeMath for uint256;

  struct Signal {
    address issuer;
    bytes32 instrument;
    string info;
    bytes32 hash;
    string changeableInfo;
    bytes32 hashOfChangeableInfo;
    string closingInfo;
  }

  mapping(address => bool) public operators;
  mapping(uint256 => Signal) public signals; // starts at 1

  event SignalCreated(
    uint256 signalID,
    bytes32 indexed hash,
    bytes32 hashOfChangeableInfo,
    string signature
  );

  event SignalClosed(
    uint256 signalID,
    address indexed issuer,
    bytes32 indexed instrument,
    string info,
    string changeableInfo,
    string closingInfo,
    string signature
  );

  event SignalChanged(
    uint256 signalID,
    bytes32 hashOfChangeableInfo,
    string signature
  );

  event SetOperator(address indexed operator, bool indexed authorized);

  modifier onlyOperator() {
    require(operators[msg.sender], "Ownable: caller is not the operator");
    _;
  }


  /**
   * @dev Constructor function.
   */
  constructor(
    string memory name,
    string memory symbol,
    string memory uri
  )
  ERC721Metadata(name, symbol, uri)
  public {}


  function newSignal(
    bytes32 hash,
    bytes32 hashOfChangeableInfo,
    string calldata signature
  )
  onlyOperator
  external returns (uint256) {
    super._mint();

    signals[totalSupply] = Signal(address(0), 0, '', hash, '', hashOfChangeableInfo, '');

    emit SignalCreated(totalSupply, hash, hashOfChangeableInfo, signature);

    return totalSupply;
  }

  function closeSignal(
    uint256 signalID,
    address issuer,
    bytes32 instrument,
    string calldata info,
    string calldata changeableInfo,
    string calldata closingInfo,
    string calldata signature
  )
  onlyOperator
  external returns (uint256) {// todo may be add check hash
    signals[signalID].issuer = issuer;
    signals[signalID].instrument = instrument;
    signals[signalID].info = info;
    signals[signalID].changeableInfo = changeableInfo;
    signals[signalID].closingInfo = closingInfo;

    emit SignalClosed(
      signalID,
      issuer,
      instrument,
      info,
      changeableInfo,
      closingInfo,
      signature
    );

    return totalSupply;
  }


  function changeSignal(
    uint256 signalID,
    bytes32 hashOfChangeableInfo,
    string calldata signature
  )
  onlyOperator
  external returns (uint256) {
    require(signals[signalID].instrument == 0, "Signals: signal is closed");

    signals[signalID].hashOfChangeableInfo = hashOfChangeableInfo;

    emit SignalChanged(
      signalID,
      signals[signalID].hashOfChangeableInfo,
      signature
    );

    return totalSupply;
  }

  function setOperator(address operator, bool authorized) public onlyOwner {
    require(operator != address(0));
    // Action Blocked - Not a valid address
    operators[operator] = authorized;
    emit SetOperator(operator, authorized);
  }
}