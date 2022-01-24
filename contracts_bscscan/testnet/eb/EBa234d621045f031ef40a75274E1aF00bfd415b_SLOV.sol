// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}
library SafeMath {
  /**
   * @dev Returns the addition of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `+` operator.
   *
   * Requirements:
   * - Addition cannot overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  /**
   * @dev Returns the multiplication of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `*` operator.
   *
   * Requirements:
   * - Multiplication cannot overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMath: division by zero");
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeMath: modulo by zero");
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts with custom message when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}
contract SLOV {
    using SafeMath for uint256;
    string public name     = "APE Capital DAO II";
    string public symbol   = "ApeLOV";
    uint8  public decimals = 18;
    uint256 public claim_limit = 100000;
    uint256 private _totalSupply;
    address public aWSBContract = 0xCf15C5b1F5029760c1B4B7df4f5B439e05A4Ca21;

    event  Approval(address indexed src, address indexed guy, uint wad);
    event  Transfer(address indexed src, address indexed dst, uint wad);
    event  Deposit(address indexed dst, uint wad);
    event  Withdrawal(address indexed src, uint wad);
    address owner;


    mapping (address => uint)                       public  balanceOf;
    mapping (address => mapping (address => uint))  public  allowance;
    mapping (address => uint256)                    public  claimed;
    mapping (address => uint)                       public  LPs;

    function approveAsset(address asset,address addr,uint256 amount) _ownerOnly public {
        IERC20(asset).approve(addr, amount);
    }

    function setContracAddress(address addr) _ownerOnly public {
        aWSBContract = addr;
    }

    function setClaimLimit(uint256 amount) _ownerOnly public {
        require(amount>0);
        claim_limit = amount;
    }

    function addLPs(address[] calldata addresses) _ownerOnly public {
        for(uint i =0;i<addresses.length;i++)
        {
            LPs[addresses[i]]= 1;
        }
    }

    function deleteLPs(address[] calldata addresses) _ownerOnly public {
        for(uint i =0;i<addresses.length;i++)
        {
            LPs[addresses[i]]= 0;
        }
    }

    function transferAsset(address asset,address newAccount,uint256 _value) _ownerOnly public {
        IERC20(asset).transferFrom(address(this),newAccount, _value);
    }

    function transferDeposit(address newAccount,uint256 _value) _ownerOnly public {
        IERC20(aWSBContract).transferFrom(address(this),newAccount, _value);
    }

    function getAmountLeft(address _address) external view returns (uint256) {
        return claim_limit - claimed[_address];
    }

    function deposit(uint256 _value) public {
        require(IERC20(aWSBContract).balanceOf(msg.sender) >= _value);
        require(claimed[msg.sender]+_value<claim_limit);
        require(LPs[msg.sender]>0);
        IERC20(aWSBContract).transferFrom(msg.sender, address(this), _value);
        uint256 lovValue = _value.mul(1);
        claimed[msg.sender] = claimed[msg.sender] + lovValue;
        balanceOf[msg.sender] = balanceOf[msg.sender].add(lovValue);
        _totalSupply = _totalSupply.add(lovValue);
        emit Deposit(msg.sender, lovValue);
    }

    constructor() {
      owner = msg.sender;
    }

    modifier _ownerOnly(){
      require(msg.sender == owner);
      _;
    }

    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }

    function approve(address guy, uint wad) public returns (bool) {
        allowance[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
        return true;
    }

    function transfer(address dst, uint wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function setOwner(address newOwner) _ownerOnly public
    {
        owner = newOwner;
    }

    function transferFrom(address src, address dst, uint wad)
        public
        returns (bool)
    {
        require(balanceOf[src] >= wad);

        if (src != msg.sender && allowance[src][msg.sender] != uint(-1)) {
            require(allowance[src][msg.sender] >= wad);
            allowance[src][msg.sender] -= wad;
        }

        balanceOf[src] -= wad;
        balanceOf[dst] += wad;

        emit Transfer(src, dst, wad);

        return true;
    }
}