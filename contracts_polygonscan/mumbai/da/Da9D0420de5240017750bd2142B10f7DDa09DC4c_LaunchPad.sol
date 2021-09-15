/**
 *Submitted for verification at polygonscan.com on 2021-09-14
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;


/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

interface IKommunitasStaking {
  function mint(address to, uint amount) external;
  function getAmount(address owner) external returns(uint);
} 


contract LaunchPad {
  using SafeMath for uint;
        
  event SubmitProject(
    address indexed tokenAddress, 
    uint tokenAmount, 
    uint lockPeriod, 
    uint vestingPeriod, 
    uint presaleRate, 
    uint presaleStart, 
    uint presaleEnd, 
    uint softCap, 
    uint hardCap, 
    bytes data
  );

  event BurnToken(address indexed tokenAddress, uint amount, uint timestamp );
  event UpdatePhase(address indexed tokenAddress, uint presaleRate, uint presaleStart, uint presaleEnd, uint timestamp);
  event TopUpAmount(address indexed tokenAddress, uint totalAmount, uint timestamp);
  event BuyToken(address indexed tokenAddress, address buyerAddress, uint amount, uint timestamp);
  event DeleteProject(address indexed tokenAddress, uint timestamp);
  event Debug(uint param1, uint param2);

  address payable public isOwner; // address of the owner of contract
  bool internal locked;
  uint private maxNumOfPresale = 3;
  address constant KOMToken = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
  address constant kommunitasStakingAddress = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
  IKommunitasStaking public kommunitasStaking;

  struct TokenInfo {
    bool burned;
    uint tokenAmount;
    uint lockPeriod;
    uint vestingPeriod;
    uint softCap;
    uint hardCap;
  }

  struct ProjectInfo {
    bool isActivated;
    uint numOfPresale;
    uint presaleRate;
    uint presaleStart;
    uint presaleEnd;
    bytes data;
  }

  ProjectInfo[] public projectInfo; // array of projects

  mapping(address => TokenInfo) public tokenInfo;

  mapping(address => uint) public projectIndex; // return the index of the project from the struct

  mapping(address => bool) public isRegistered; // return the index of the project from the struct
  


  modifier _onlyOwner() {
    require(isOwner == msg.sender, "not owner");
    _;
  }

  modifier _isRegistered(address _tokenAddress) {
    require(isRegistered[_tokenAddress], "Project is not registered");
    _;
  }


  modifier _noReentrant() { // prevent re-entrancy
    require(!locked, "No re-entrancy");
    locked = true;
    _;
    locked = false;
  }

  constructor()  {
    isOwner = payable(msg.sender);
    // kommunitasStaking = IKommunitasStaking(_kommunitasStakingAddress);
  }

  function submitProject(address _tokenAddress, uint _tokenAmount, uint _lockPeriod, uint _vestingPeriod, uint _presaleRate, uint _presaleStart, uint _presaleEnd, uint _softCap, uint _hardCap, bytes memory _data)
    public
  {
    require(_tokenAddress != address(0), "Invalid token address");
    require(projectIndex[_tokenAddress] == 0, "Project already exist");

    require(_presaleStart >= block.timestamp, "Presale starting period is in the past"); // checks the presale starting time
    
    require(_presaleStart <= _presaleEnd, "Presale starting time must be equal or less than the ending time"); // checks if the presale starting period is less than or equal to the ending time

    IERC20 token = IERC20(_tokenAddress);
    
    token.transferFrom(msg.sender, address(this), _tokenAmount);

    uint _projectIndex = projectInfo.length;

    projectInfo.push(ProjectInfo({
      isActivated: false,
      numOfPresale: 0,
      presaleRate: _presaleRate,
      presaleStart: _presaleStart,
      presaleEnd: _presaleEnd,
      data: _data
    }));

    // emit Debug(_projectIndex, block.timestamp);

    setTokenInfo(_tokenAddress, _tokenAmount, _lockPeriod, _vestingPeriod, _softCap, _hardCap, _projectIndex); 

    emit SubmitProject(_tokenAddress, _tokenAmount, _lockPeriod, _vestingPeriod, _presaleRate, _presaleStart, _presaleEnd, _softCap, _hardCap, _data);

  }

  function setTokenInfo(address _tokenAddress, uint _tokenAmount, uint _lockPeriod, uint _vestingPeriod, uint _softCap, uint _hardCap, uint _projectIndex) 
    internal
  {
    TokenInfo storage _tokenInfo = tokenInfo[_tokenAddress];

    _tokenInfo.burned = false;
    _tokenInfo.tokenAmount = _tokenAmount;
    _tokenInfo.lockPeriod = _lockPeriod;
    _tokenInfo.vestingPeriod = _vestingPeriod;
    _tokenInfo.softCap = _softCap;
    _tokenInfo.hardCap = _hardCap;

    projectIndex[_tokenAddress] = _projectIndex;
    isRegistered[_tokenAddress] = true;

  }

  function getProjectsCount() public view returns (uint) {
    return projectInfo.length;
  }

  function getProjectInfo(uint _index) public view returns(ProjectInfo memory){
    return projectInfo[_index];
  }

  function topUpAmount(address _tokenAddress, uint _tokenAmount)
    public
    _isRegistered(_tokenAddress)
  {
    require(!tokenInfo[_tokenAddress].burned, "Project have been burned");

    IERC20 token = IERC20(_tokenAddress);
    
    token.transferFrom(msg.sender, address(this), _tokenAmount);

    tokenInfo[_tokenAddress].tokenAmount = tokenInfo[_tokenAddress].tokenAmount.add(_tokenAmount);

    emit TopUpAmount(_tokenAddress, tokenInfo[_tokenAddress].tokenAmount, block.timestamp);
      
  }

  function activateProject(address _tokenAddress) 
    public 
    view
    _isRegistered(_tokenAddress)
  {
    require(!tokenInfo[_tokenAddress].burned, "Project have been burned");

    uint _index = projectIndex[_tokenAddress];
    ProjectInfo storage project = projectInfo[_index];

    require(!project.isActivated, "Project have already been activated");

  }

  function burnToken(address _tokenAddress) 
    public 
    _isRegistered(_tokenAddress)
  {
    require(!tokenInfo[_tokenAddress].burned, "Project have been burned");

    uint _index = projectIndex[_tokenAddress];
    ProjectInfo storage project = projectInfo[_index];

    require(project.isActivated, "Project have not been activated");
    require(project.numOfPresale == maxNumOfPresale, "Project have not reached the maximum number of presale");

    project.isActivated = false; // deactive project
    tokenInfo[_tokenAddress].burned = true;

    IERC20 token = IERC20(_tokenAddress);

    uint tokenBalance = token.balanceOf(address(this));
    
    require(token.transfer(address(0), tokenBalance), "Unable to transfer token to this smart contract"); // Transferring token to zero address

    emit BurnToken(_tokenAddress, tokenBalance, block.timestamp);
  }

  

  

  

}