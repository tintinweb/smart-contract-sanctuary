pragma solidity ^0.4.24;

// File: ../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

// File: contracts/ETHReceiver.sol

contract ETHReceiver {
    using SafeMath for *;

    uint public balance_;
    address public owner_;

    event ReceivedValue(address indexed from, uint value);
    event Withdraw(address indexed from, uint amount);
    event ChangeOwner(address indexed from, address indexed to);

    constructor ()
        public
    {
        balance_ = 0;
        owner_ = msg.sender;
    }

    modifier onlyOwner
    {
        require(msg.sender == owner_, "msg sender is not contract owner");
        _;
    }

    function ()
        public
        payable
    {
        balance_ = (balance_).add(msg.value);
        emit ReceivedValue(msg.sender, msg.value);
    }

    function transferTo (address _to, uint _amount)
        public
        onlyOwner()
    {
        _to.transfer(_amount);
        balance_ = (balance_).sub(_amount);
        emit Withdraw(_to, _amount);
    }

    function changeOwner (address _to)
        public
        onlyOwner()
    {
        assert(_to != address(0));
        owner_ = _to;
        emit ChangeOwner(msg.sender, _to);
    }
}