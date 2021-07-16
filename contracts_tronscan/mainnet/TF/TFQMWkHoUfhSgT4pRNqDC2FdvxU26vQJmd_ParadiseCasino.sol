//SourceUnit: ParadiseCasino_flat.sol

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


contract ParadiseCasino is Ownable{
    using SafeMath for uint;

    event LOG_Deposit(address walletAddr, uint amount);
    event LOG_Withdraw(address user, uint amount);

    event LOG_Bankroll(address sender, uint value);
    event LOG_OwnerWithdraw(address _to, uint _val);

    event LOG_ContractStopped();
    event LOG_ContractResumed();

    bool public isStopped;

    mapping (bytes32 => mapping(bytes32 => uint)) depositList;

    modifier onlyIfNotStopped {
        require(!isStopped);
        _;
    }

    modifier onlyIfStopped {
        require(isStopped);
        _;
    }

    constructor() public {
    }

    function () payable public {
        revert();
    }

    function bankroll() payable public onlyOwner {
        emit LOG_Bankroll(msg.sender, msg.value);
    }

    function userDeposit() payable public onlyIfNotStopped {
        emit LOG_Deposit(msg.sender, msg.value);
    }

    function userWithdraw(address _to, uint _amount) public onlyOwner onlyIfNotStopped{
        _to.transfer(_amount);
        emit LOG_Withdraw(_to, _amount);
    }

    function ownerWithdraw(address _to, uint _val) public onlyOwner{
        require(address(this).balance > _val);
        _to.transfer(_val);
        emit LOG_OwnerWithdraw(_to, _val);
    }

    function stopContract() public onlyOwner onlyIfNotStopped {
        isStopped = true;
        emit LOG_ContractStopped();
    }

    function resumeContract() public onlyOwner onlyIfStopped {
        isStopped = false;
        emit LOG_ContractResumed();
    }

    function postMessage(string message) public payable
    {

    }

}