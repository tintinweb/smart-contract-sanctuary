pragma solidity ^0.4.24;

// File: contracts/OracleRequest.sol

/*
Interface for requests to the rate oracle (for EUR/ETH)
Copy this to projects that need to access the oracle.
See rate-oracle project for implementation.
*/
pragma solidity ^0.4.24;


contract OracleRequest {

    uint256 public EUR_WEI; //number of wei per EUR

    uint256 public lastUpdate; //timestamp of when the last update occurred

    function ETH_EUR() public view returns (uint256); //number of EUR per ETH (rounded down!)

    function ETH_EURCENT() public view returns (uint256); //number of EUR cent per ETH (rounded down!)

}

// File: zeppelin-solidity/contracts/math/SafeMath.sol

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

// File: zeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: contracts/Oracle.sol

/*
Implements a rate oracle (for EUR/ETH)
*/
pragma solidity ^0.4.24;




contract Oracle is OracleRequest {
    using SafeMath for uint256;

    address public rateControl;

    address public tokenAssignmentControl;

    constructor(address _rateControl, address _tokenAssignmentControl)
    public
    {
        lastUpdate = 0;
        rateControl = _rateControl;
        tokenAssignmentControl = _tokenAssignmentControl;
    }

    modifier onlyRateControl()
    {
        require(msg.sender == rateControl, "rateControl key required for this function.");
        _;
    }

    modifier onlyTokenAssignmentControl() {
        require(msg.sender == tokenAssignmentControl, "tokenAssignmentControl key required for this function.");
        _;
    }

    function setRate(uint256 _new_EUR_WEI)
    public
    onlyRateControl
    {
        lastUpdate = now;
        require(_new_EUR_WEI > 0, "Please assign a valid rate.");
        EUR_WEI = _new_EUR_WEI;
    }

    function ETH_EUR()
    public view
    returns (uint256)
    {
        return uint256(1 ether).div(EUR_WEI);
    }

    function ETH_EURCENT()
    public view
    returns (uint256)
    {
        return uint256(100 ether).div(EUR_WEI);
    }

    /*** Make sure currency doesn&#39;t get stranded in this contract ***/

    // If this contract gets a balance in some ERC20 contract after it&#39;s finished, then we can rescue it.
    function rescueToken(ERC20Basic _foreignToken, address _to)
    public
    onlyTokenAssignmentControl
    {
        _foreignToken.transfer(_to, _foreignToken.balanceOf(this));
    }

    // Make sure this contract cannot receive ETH.
    function()
    public payable
    {
        revert("The contract cannot receive ETH payments.");
    }
}