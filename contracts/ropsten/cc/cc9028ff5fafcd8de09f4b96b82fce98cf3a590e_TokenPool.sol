pragma solidity 0.4.24;
// produced by the Solididy File Flattener (c) David Appleton 2018
// contact : <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="a4c0c5d2c1e4c5cfcbc9c6c58ac7cbc9">[email&#160;protected]</a>
// released under Apache 2.0 licence
// input  /root/code/solidity/xixoio-contracts/flat/TokenPool.sol
// flattened :  Monday, 03-Dec-18 10:34:17 UTC
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

  /**
   * @return the address of the owner.
   */
  function owner() public view returns(address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  /**
   * @return true if `msg.sender` is the owner of the contract.
   */
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

interface ITokenPool {
    function balanceOf(uint128 id) public view returns (uint256);
    function allocate(uint128 id, uint256 value) public;
    function withdraw(uint128 id, address to, uint256 value) public;
    function complete() public;
}

contract TokenPool is ITokenPool, Ownable {
    using SafeMath for uint256;

    IERC20 public token;
    bool public completed = false;

    mapping(uint128 => uint256) private balances;
    uint256 public allocated = 0;

    event FundsAllocated(uint128 indexed account, uint256 value);
    event FundsWithdrawn(uint128 indexed account, address indexed to, uint256 value);

    constructor(address tokenAddress) public {
        token = IERC20(tokenAddress);
    }

    /**
     * @return The balance of the account in pool
     */
    function balanceOf(uint128 account) public view returns (uint256) {
        return balances[account];
    }

    /**
     * Token allocation function
     * @dev should be called after every token deposit to allocate these token to the account
     */
    function allocate(uint128 account, uint256 value) public onlyOwner {
        require(!completed, "Pool is already completed");
        assert(unallocated() >= value);
        allocated = allocated.add(value);
        balances[account] = balances[account].add(value);
        emit FundsAllocated(account, value);
    }

    /**
     * Allows withdrawal of tokens and dividends from temporal storage to the wallet
     * @dev transfers corresponding amount of dividend in ETH
     */
    function withdraw(uint128 account, address to, uint256 value) public onlyOwner {
        balances[account] = balances[account].sub(value);
        uint256 balance = address(this).balance;
        uint256 dividend = balance.mul(value).div(allocated);
        allocated = allocated.sub(value);
        token.transfer(to, value);
        if (dividend > 0) {
            to.transfer(dividend);
        }
        emit FundsWithdrawn(account, to, value);
    }

    /**
     * Concludes allocation of tokens and serves as a drain for unallocated tokens
     */
    function complete() public onlyOwner {
        completed = true;
        token.transfer(msg.sender, unallocated());
    }

    /**
     * Fallback function enabling deposit of dividends in ETH
     * @dev dividend has to be deposited only after pool completion, as additional token
     *      allocations after the deposit would skew shares
     */
    function () public payable {
        require(completed, "Has to be completed first");
    }

    /**
     * @return Amount of unallocated tokens in the pool
     */
    function unallocated() internal view returns (uint256) {
        return token.balanceOf(this).sub(allocated);
    }
}