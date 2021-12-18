/**
 *Submitted for verification at polygonscan.com on 2021-12-17
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

interface IOwnable {
  function owner() external view returns (address);

  function renounceOwnership() external;
  
  function transferOwnership( address newOwner_ ) external;
}

contract Ownable is IOwnable {
    
  address internal _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor () {
    _owner = msg.sender;
    emit OwnershipTransferred( address(0), _owner );
  }

  function owner() public view override returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    require( _owner == msg.sender, "Ownable: caller is not the owner" );
    _;
  }

  function renounceOwnership() public virtual override onlyOwner() {
    emit OwnershipTransferred( _owner, address(0) );
    _owner = address(0);
  }

  function transferOwnership( address newOwner_ ) public virtual override onlyOwner() {
    require( newOwner_ != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred( _owner, newOwner_ );
    _owner = newOwner_;
  }
}

contract MockAggregatorBase is Ownable {
    int256 private _latestAnswer;
    uint256 private _roundId;
    uint8 private _decimals;

    event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 timestamp);

    constructor (int256 _initialAnswer, uint8 _initialDecimals) {
        _latestAnswer = _initialAnswer;
        _roundId = 0;
        _decimals = _initialDecimals;
        emit AnswerUpdated(_initialAnswer, _roundId, block.timestamp);
    }

    function updateLatestAnswer(int256 newAnswer) external onlyOwner() {
      _latestAnswer = newAnswer;
      _roundId = _roundId + 1;
      emit AnswerUpdated(newAnswer, _roundId, block.timestamp);
    }

    function latestAnswer() external view returns (int256) {
        return _latestAnswer;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

contract MockAggregatorXAU is MockAggregatorBase {
    constructor (int256 _initialAnswer, uint8 _decimals) MockAggregatorBase(_initialAnswer, _decimals) {}
}