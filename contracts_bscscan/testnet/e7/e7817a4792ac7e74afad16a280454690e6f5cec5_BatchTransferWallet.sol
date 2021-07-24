/**
 *Submitted for verification at BscScan.com on 2021-07-24
*/

pragma solidity ^0.4.23;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
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
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
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
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold
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

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}


contract BatchTransferWallet is Ownable {
    using SafeMath for uint256;

    event Withdraw(address indexed receiver, address indexed token, uint amount);
    event TransferEther(address indexed sender, address indexed receiver, uint256 amount);

    modifier checkArrayArgument(address[] _receivers, uint256[] _amounts) {
        require(_receivers.length == _amounts.length && _receivers.length != 0);
        _;
    }

    function batchTransferToken(address _token, address[] _receivers, uint256[] _tokenAmounts) public checkArrayArgument(_receivers, _tokenAmounts) {
        require(_token != address(0));

        ERC20 token = ERC20(_token);
        require(allowanceForContract(_token) >= getTotalSendingAmount(_tokenAmounts));

	uint decimalsForCalc = 10 ** uint256(18);

        for (uint i = 0; i < _receivers.length; i++) {
            require(_receivers[i] != address(0));
            require(token.transferFrom(msg.sender, _receivers[i], _tokenAmounts[i].mul(decimalsForCalc)));
        }
    }

    function batchTransferEther(address[] _receivers, uint[] _amounts) public payable checkArrayArgument(_receivers, _amounts) {
        require(msg.value != 0 && msg.value == getTotalSendingAmount(_amounts));

        for (uint i = 0; i < _receivers.length; i++) {
            require(_receivers[i] != address(0));
            _receivers[i].transfer(_amounts[i]);
            emit TransferEther(msg.sender, _receivers[i], _amounts[i]);
        }
    }

    function withdraw(address _receiver, address _token) public onlyOwner {
        ERC20 token = ERC20(_token);
        uint tokenBalanceOfContract = token.balanceOf(this);
        require(_receiver != address(0) && tokenBalanceOfContract > 0);
        require(token.transfer(_receiver, tokenBalanceOfContract));
        emit Withdraw(_receiver, _token, tokenBalanceOfContract);
    }

    function balanceOfContract(address _token) public view returns (uint) {
        ERC20 token = ERC20(_token);
        return token.balanceOf(this);
    }

    function allowanceForContract(address _token) public view returns (uint) {
        ERC20 token = ERC20(_token);
        return token.allowance(msg.sender, this);
    }

    function getTotalSendingAmount(uint256[] _amounts) private pure returns (uint totalSendingAmount) {
        for (uint i = 0; i < _amounts.length; i++) {
            require(_amounts[i] > 0);
            totalSendingAmount = totalSendingAmount.add(_amounts[i]);
        }
    }
}