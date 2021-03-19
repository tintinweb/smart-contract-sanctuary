/**
 *Submitted for verification at Etherscan.io on 2021-03-19
*/

pragma solidity ^0.4.24;
// ----------------------------------------------------------------------------

contract SafeMath {

    function safeAdd(uint256 a, uint256 b) public pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
    }

    function safeSub(uint256 a, uint b) public pure returns (uint256 c) {
        require(b <= a);
        c = a - b;
    }

    function safeMul(uint256 a, uint256 b) public pure returns (uint256 c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function safeDiv(uint256 a, uint256 b) public pure returns (uint256 c) {
        require(b > 0);
        c = a / b;
    }
}
library SafeERC20 {
  function safeTransfer(IERC20 token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }
  function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }
  function safeApprove(IERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}
library Math {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     * @notice Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
ERC Token Standard #20 Interface
https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
*/
contract IERC20 {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Buy(uint indexed);
    event Burn(address indexed from, uint256 value);
    

}



/**
Contract function to receive approval and execute function in one call

Borrowed from MiniMeToken
*/
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}


/**
ERC20 Token, with the addition of symbol, name and decimals and assisted token transfers
*/
    
 contract MultiBeneficiary is Ownable {
  using Math for uint256;
  using SafeERC20 for IERC20;

  event Released(address beneficiary, uint256 amount);

  IERC20 public token;
  uint256 public cliff;
  uint256 public start;
  uint256 public duration;

  mapping (address => uint256) public shares;

  uint256 released = 0;

  address[] public beneficiaries;

  modifier onlyBeneficiaries {
    require(isOwner()  || shares[msg.sender] > 0, "You cannot release tokens!");
    _;
  }

  constructor(
    IERC20 _token,
    uint256 _start,
    uint256 _cliff,
    uint256 _duration
  )
  public
  {
    require(_cliff <= _duration, "Cliff has to be lower or equal to duration");
    token = _token;
    duration = _duration;
    cliff = _start.add(_cliff);
    start = _start;
  }

  function addBeneficiary(address _beneficiary, uint256 _sharesAmount) onlyOwner public {
    require(_beneficiary != address(0), "The beneficiary's address cannot be 0");
    require(_sharesAmount > 0, "Shares amount has to be greater than 0");

    releaseAllTokens();

    if (shares[_beneficiary] == 0) {
      beneficiaries.push(_beneficiary);
    }

    shares[_beneficiary] = shares[_beneficiary].add(_sharesAmount);
  }

  function releaseAllTokens() onlyBeneficiaries public {
    uint256 unreleased = releasableAmount();

    if (unreleased > 0) {
      uint beneficiariesCount = beneficiaries.length;

      released = released.add(unreleased);

      for (uint i = 0; i < beneficiariesCount; i++) {
        release(beneficiaries[i], calculateShares(unreleased, beneficiaries[i]));
      }
    }
  }

  function releasableAmount() public view returns (uint256) {
    return vestedAmount().sub(released);
  }

  function calculateShares(uint256 _amount, address _beneficiary) public view returns (uint256) {
    return _amount.mul(shares[_beneficiary]).div(totalShares());
  }

  function totalShares() public view returns (uint256) {
    uint sum = 0;
    uint beneficiariesCount = beneficiaries.length;

    for (uint i = 0; i < beneficiariesCount; i++) {
      sum = sum.add(shares[beneficiaries[i]]);
    }

    return sum;
  }

  function vestedAmount() public view returns (uint256) {
    uint256 currentBalance = token.balanceOf(this);
    uint256 totalBalance = currentBalance.add(released);

    
    if (block.timestamp < cliff) {
      return 0;
    } else if (block.timestamp >= start.add(duration)) {
      return totalBalance;
    } else {
      return totalBalance.mul(block.timestamp.sub(start)).div(duration);
    }
    
  }

  function release(address _beneficiary, uint256 _amount) private {
    token.safeTransfer(_beneficiary, _amount);
    emit Released(_beneficiary, _amount);
  }
}