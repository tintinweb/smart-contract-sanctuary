/**
 *Submitted for verification at polygonscan.com on 2021-12-06
*/

pragma solidity ^0.5.16;

interface IBEP20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8);

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory);

  /**
  * @dev Returns the token name.
  */
  function name() external view returns (string memory);

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view returns (address);

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
  function allowance(address _owner, address spender) external view returns (uint256);

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
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
  // Empty internal constructor, to prevent people from mistakenly deploying
  // an instance of this contract, which should be used via inheritance.
  constructor () internal { }

  function _msgSender() internal view returns (address payable) {
    return msg.sender;
  }

  function _msgData() internal view returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
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

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor () internal {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

contract Astronaut is Context, IBEP20, Ownable {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowances;

  uint256 private _totalSupply;
  uint8 private _decimals;
  string private _symbol;
  string private _name;

  constructor(string memory tokenName,string memory tokenSymbol,uint8 decimals,uint256 initSupply) public {
    _name = tokenName;
    _symbol = tokenSymbol;
    _decimals = decimals;
    _totalSupply = initSupply;
    _balances[msg.sender] = _totalSupply;

    emit Transfer(address(0), msg.sender, _totalSupply);
  }

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view returns (address) {
    return owner();
  }

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8) {
    return _decimals;
  }

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory) {
    return _symbol;
  }

  /**
  * @dev Returns the token name.
  */
  function name() external view returns (string memory) {
    return _name;
  }

  /**
   * @dev See {BEP20-totalSupply}.
   */
  function totalSupply() external view returns (uint256) {
    return _totalSupply;
  }

  /**
   * @dev See {BEP20-balanceOf}.
   */
  function balanceOf(address account) external view returns (uint256) {
    return _balances[account];
  }

  /**
   * @dev See {BEP20-transfer}.
   *
   * Requirements:
   *
   * - `recipient` cannot be the zero address.
   * - the caller must have a balance of at least `amount`.
   */
  function transfer(address recipient, uint256 amount) external returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  /**
   * @dev See {BEP20-allowance}.
   */
  function allowance(address owner, address spender) external view returns (uint256) {
    return _allowances[owner][spender];
  }

  /**
   * @dev See {BEP20-approve}.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function approve(address spender, uint256 amount) external returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  /**
   * @dev See {BEP20-transferFrom}.
   *
   * Emits an {Approval} event indicating the updated allowance. This is not
   * required by the EIP. See the note at the beginning of {BEP20};
   *
   * Requirements:
   * - `sender` and `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   * - the caller must have allowance for `sender`'s tokens of at least
   * `amount`.
   */
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
    return true;
  }

  /**
   * @dev Atomically increases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {BEP20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }

  /**
   * @dev Atomically decreases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {BEP20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   * - `spender` must have allowance for the caller of at least
   * `subtractedValue`.
   */
  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
    return true;
  }

  

  /**
   * @dev Moves tokens `amount` from `sender` to `recipient`.
   *
   * This is internal function is equivalent to {transfer}, and can be used to
   * e.g. implement automatic token fees, slashing mechanisms, etc.
   *
   * Emits a {Transfer} event.
   *
   * Requirements:
   *
   * - `sender` cannot be the zero address.
   * - `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   */
  function _transfer(address sender, address recipient, uint256 amount) internal {
    require(sender != address(0), "BEP20: transfer from the zero address");
    require(recipient != address(0), "BEP20: transfer to the zero address");

    _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
  }

 
  

  /**
   * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
   *
   * This is internal function is equivalent to `approve`, and can be used to
   * e.g. set automatic allowances for certain subsystems, etc.
   *
   * Emits an {Approval} event.
   *
   * Requirements:
   *
   * - `owner` cannot be the zero address.
   * - `spender` cannot be the zero address.
   */
  function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0), "BEP20: approve from the zero address");
    require(spender != address(0), "BEP20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

 
}

contract Nautstaking {
    using SafeMath for uint256;

    Astronaut public nautToken;
    address public owner;
    
    bool ido=false;

    mapping(address => bool) public isStaking;
    address[] public whitelistedUsers;
    
    struct StakeUsersInfo {
        uint256 amount;
        uint8 tier;
    }

    uint256 public Tier1 = 100 * 10**18;
    uint256 public Tier2 = 250 * 10**18;
    uint256 public Tier3 = 600 * 10**18;
    uint256 public Tier4 = 1500 * 10**18;

    uint256 private Tier1Users = 0;
    uint256 private Tier2Users = 0;
    uint256 private Tier3Users = 0;
    uint256 private Tier4Users = 0;

    mapping(address => StakeUsersInfo) staker;

    bool public isstakingLive = false;
    bool public ICOover = false;

    address[] public stakers;

    constructor(Astronaut _address) public {
        nautToken = Astronaut(_address);
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function changeOwnership(address _newowner) external onlyOwner {
        require(msg.sender != _newowner);
        owner = _newowner;
    }

    modifier stoppedInEmergency() {
        require(isstakingLive);
        _;
    }

    modifier onlyWhenStopped() {
        require(!isstakingLive);
        _;
    }

    /** @dev Stop Staking
     */
    function stopStaking() public onlyOwner stoppedInEmergency {
        isstakingLive = false;
    }

    /** @dev Start Staking
     */
    function startStaking() public onlyOwner onlyWhenStopped {
        require(ido==false, "IDO over");
        isstakingLive = true;
    }

    /** @dev Start UnStaking
     */
    function StartUnstaking() public onlyOwner {
        require(isstakingLive == false , "Staking is live");
        ICOover = true;
        ido = true;
    }

    /** @dev Stop UnStaking
     */
    function StopUnstaking() public onlyOwner onlyWhenICOover {
        ICOover = false;
    }

    modifier onlyWhenICOover() {
        require(ICOover);
        _;
    }


    // invest function
    function stakeTokens(uint256 _amount) public stoppedInEmergency {

        // staking amount must be equal to below packages
        require(
            _amount == Tier1 ||
                _amount == Tier2 ||
                _amount == Tier3 ||
                _amount == Tier4,
            "Select Appropriate Tier"
        );

        require(isStaking[msg.sender] == false, "Already Staked");

        // Transfer staking tokens to staking Contract
        nautToken.transferFrom(msg.sender, address(this), _amount);

        // Add user To staking Data structure
        StakeUsersInfo storage stakeStorage = staker[msg.sender];

        if (_amount == Tier1) {
            stakeStorage.tier = 1;
            stakeStorage.amount = _amount;
            Tier1Users = Tier1Users + 1;
        } else if (_amount == Tier2) {
            stakeStorage.tier = 2;
            stakeStorage.amount = _amount;
            Tier2Users = Tier2Users + 1;
        } else if (_amount == Tier3) {
            stakeStorage.tier = 3;
            stakeStorage.amount = _amount;
            Tier3Users = Tier3Users + 1;
        } else {
            stakeStorage.tier = 4;
            stakeStorage.amount = _amount;
            Tier4Users = Tier4Users + 1;
        }

        stakers.push(msg.sender);
        isStaking[msg.sender] = true;
    }

    // allow user to withdraw their token
    function unStakeTokens() public onlyWhenICOover {
        require(isStaking[msg.sender] == true, "No previous deposit");

        uint256 balance = staker[msg.sender].amount;

        nautToken.transfer(msg.sender, balance);

        uint256 tier = staker[msg.sender].tier;

        if (tier == 1) {
            Tier1Users = Tier1Users - 1;
        } else if (tier == 2) {
            Tier2Users = Tier2Users - 1;
        } else if (tier == 3) {
            Tier3Users = Tier3Users - 1;
        } else if (tier == 4) {
            Tier4Users = Tier4Users - 1;
        }

        isStaking[msg.sender] = false;
        staker[msg.sender].amount = 0;
        staker[msg.sender].tier = 0;
        // stakers.pop(msg.sender);
    }

    function whitelist(address[] calldata _users, uint8[] calldata _tiers) external onlyOwner {
        
        uint userlength = _users.length;
        uint tierlength = _tiers.length;
        require(userlength == tierlength, "Incorrect params");
        
        for (uint i =0; i < userlength; i++) {
            
        StakeUsersInfo storage stakeStorage = staker[_users[i]];

        require(staker[_users[i]].tier == 0, "Already whitelisted");
        stakeStorage.tier = _tiers[i];
        whitelistedUsers.push(_users[i]);
    
        if (_tiers[i] == 1) {
            Tier1Users = Tier1Users + 1;
        } else if (_tiers[i] == 2) {
            Tier2Users = Tier2Users + 1;
        } else if (_tiers[i] == 3) {
            Tier3Users = Tier3Users + 1;
        } else if (_tiers[i] == 4) {
            Tier4Users = Tier4Users + 1;
        }
        else {
            revert();
        }
      }
    }

    // function blacklist(address _user) public onlyOwner {
    //     StakeUsersInfo storage stakeStorage = staker[_user];

    //     require(staker[_user].tier != 0, "Already blacklisted");

    //     uint8 tier = stakeStorage.tier;

    //     stakeStorage.tier = 0;

    //     if (tier == 1) {
    //         Tier1Users = Tier1Users - 1;
    //     } else if (tier == 2) {
    //         Tier2Users = Tier2Users - 1;
    //     } else if (tier == 3) {
    //         Tier3Users = Tier3Users - 1;
    //     } else if (tier == 4) {
    //         Tier4Users = Tier4Users - 1;
    //     }
    // }

    // Total no of Stakers
    function countStakers() public view returns (uint256) {
        return stakers.length;
    }
    
    
    // Total no of whitelistedUsers
    function countWhitelistedUsers() public view returns (uint256) {
        return whitelistedUsers.length;
    }
    
    // get Staker info
    function getStaker(address _address)
        public
        view
        returns (uint256 amount, uint8 tier)
    {
        return (staker[_address].amount, staker[_address].tier);
    }

    // check Balance
    function checkBalance(address _owner)
        public
        view
        returns (uint256 balance)
    {
        return nautToken.balanceOf(_owner);
    }

    // get Tier
    function getStakerTier(address _address) public view returns (uint8 tier) {
        return (staker[_address].tier);
    }

    // Total naut tokens in Contract Wallet
    function checkContractBalance() public view returns (uint256 balance) {
        return nautToken.balanceOf(address(this));
    }

    function tier1user() public view returns (uint256) {
        return Tier1Users;
    }

    function tier2user() public view returns (uint256) {
        return Tier2Users;
    }

    function tier3user() public view returns (uint256) {
        return Tier3Users;
    }

    function tier4user() public view returns (uint256) {
        return Tier4Users;
    }

    // allow Owner to Withdraw Dead Tokens from Smart Contract Wallet when Unstaking is complete
    function withdrawlAdmin(uint256 _amount, address _admin) public onlyOwner {
        uint256 withdrawlAmmount = _amount;
        nautToken.transfer(_admin, withdrawlAmmount);
    }


    function resetContract() public onlyOwner {
        
        require(checkContractBalance() ==0, "Contract not empty");
        
        address[] memory totalstakers = stakers;
        
        for (uint256 i = 0; i < totalstakers.length; i++) {
            if (isStaking[totalstakers[i]] == true) {
                 isStaking[totalstakers[i]] = false;
                 staker[totalstakers[i]].amount = 0;
                 staker[totalstakers[i]].tier = 0;
            }
        }
        
        address[] memory totalwhitelistedUsers = whitelistedUsers;
        
         for (uint256 i = 0; i < totalwhitelistedUsers.length; i++) {
                 staker[totalwhitelistedUsers[i]].tier = 0;
            }

        // stakingStart = 0;
        // stakingStop = 0;
        ICOover = false;
        ido=false;
        Tier1Users = 0;
        Tier2Users = 0;
        Tier3Users = 0;
        Tier4Users = 0;
        isstakingLive = false;

        delete stakers;
        delete whitelistedUsers;
    }


    function setTier(uint8 _tier, uint256 _value) public onlyOwner {
        require(
            _tier == 1 || _tier == 2 || _tier == 3 || _tier == 4,
            "Select Appropriate Tier"
        );

        if (_tier == 1) {
            Tier1 = _value * (10**18);
        } else if (_tier == 2) {
            Tier2 = _value * (10**18);
        } else if (_tier == 3) {
            Tier3 = _value * (10**18);
        } else {
            Tier4 = _value * (10**18);
        }
    }

}



contract NAUTIDO 
   
   {
       using SafeMath for uint256;
           
      address public owner;
      Nautstaking public nts;
      
      address public inputtoken;
      address public outputtoken;
      
     // total Supply for ICO
      uint256 public totalsupply;
     
      struct ICOUsersInfo {
        uint256 investedamount;
        uint256 maxallocation;
        uint256 remainingallocation;
        uint256 remainingClaim;
        uint256 claimround;
      }
   
     mapping (address => ICOUsersInfo)public ico;
     address[] public investors;
     mapping (address => bool) public existinguser;
     
     
     // Tier Max limit
     uint256 private tier1Max;
     uint256 private tier2Max;
     uint256 private tier3Max;
     uint256 private tier4Max;
     
     // pool weight   
     uint256 public poolweightTier1 = 0;          //  100
     uint256 public poolweightTier2 = 0;          //  250 
     uint256 public poolweightTier3 = 0;          //  375
     uint256 public poolweightTier4 = 0;          //  625
     
     bool poolweightinitialize = false;
 
     //set price of token  
      uint public tokenPrice;                   
 
     //hardcap 
      uint public icoTarget;
 
      //define a state variable to track the funded amount
      uint public receivedFund=0;
      
      
      uint public vestingTime;
      uint public vestingperc;
 
 
        bool public claimenabled = false;
        bool public icoStatus = false;
        bool claim = false;
 
        modifier onlyOwner() {
                require(msg.sender == owner);
                _;
        }   
    
        function transferOwnership(address _newowner) public onlyOwner {
            owner = _newowner;
        } 
 
        constructor (Nautstaking _nts) public  {
         nts = Nautstaking(_nts);
         owner = msg.sender;
         }
 

    /** @dev Stop IDO
     */
    function stopIDO() public onlyOwner {
        icoStatus = false;
    }

    /** @dev Start IDO
     */
    function startIDO() public onlyOwner {
        require(claimenabled == false , "claim enabled");
        require(claim == false , "claim already start");
        icoStatus = true;
    }

    /** @dev Start Claim
     */
    function StartClaim() public onlyOwner {
        require(icoStatus == false , "IDO is live");
        require(vestingTime != 0, "Initialze  Vesting Params");
        claimenabled = true;
        claim = true;
    }
    
    /** @dev Stop Claim
     */
    function StopClaim() public onlyOwner {
        claimenabled = false;
    }
    
 
    function getTotalWeightedUsers() internal view returns (uint256 _t) {
        
        uint256 t1 =  nts.tier1user();     //1
        uint256 t2 =  nts.tier2user();     //1
        uint256 t3 =  nts.tier3user();     //1
        uint256 t4 =  nts.tier4user();     //2
        
        uint256 tw = (t1 * poolweightTier1) + (t2 * poolweightTier2) + (t3 * poolweightTier3) + (t4 * poolweightTier4);
        
        return tw;                         //395
    }
 
    
    function TokenPerperson() internal view returns (uint256) {
        
        uint256 totalweight = getTotalWeightedUsers();
    
       if (totalweight != 0) 
        {
        uint256 tpp = (totalsupply) / totalweight;
        return tpp;                       // 253.164
        }
        return 0;
    }
     
     
    function getTier1Maxlimit() public view returns (uint256 _tier1limit) {    //34782
        
        return TokenPerperson() * poolweightTier1;         
    }
     
    
    function getTier2Maxlimit() public view returns (uint256 _tier2limit) {    // 86956
        
        return (TokenPerperson() * poolweightTier2);
    }
 
 
     function getTier3Maxlimit() public view returns (uint256 _tier2limit) {   // 130434 
        
        return (TokenPerperson() * poolweightTier3);
    }
 
 
     function getTier4Maxlimit() public view returns (uint256 _tier2limit) {   // 217391
        
        return (TokenPerperson() * poolweightTier4);
    }



    
     function getTier1MaxContribution() public view returns (uint256 _tier1limit) {
        
        if (getTier1Maxlimit() > 0 ) 
        {
        return getTier1Maxlimit() * 1000  / tokenPrice / 1000000000000;
        }
        return 0 ;
         
     }
     
     
      function getTier2MaxContribution() public view returns (uint256 _tier1limit) {
        
       if (getTier2Maxlimit() > 0 ) 
        {
        return getTier2Maxlimit() * 1000 / tokenPrice / 1000000000000;
        }
        return 0 ;
         
     }
     
     
      function getTier3MaxContribution() public view returns (uint256 _tier1limit) {
        
        if (getTier3Maxlimit() > 0 ) 
        {
        return getTier3Maxlimit() * 1000 / tokenPrice / 1000000000000;
        }
        return 0 ;
         
     }
    
    
     function getTier4MaxContribution() public view returns (uint256 _tier1limit) {
        
         if (getTier4Maxlimit() > 0 ) 
        {
        return getTier4Maxlimit() * 1000 / tokenPrice / 1000000000000;
        }
        return 0 ;
         
     }
     
     
 
     function Investing(uint256 _amount) public {
    
     require(icoStatus == true, "ICO in not active");
    
     //check for hard cap
     require(icoTarget >= receivedFund + _amount, "Target Achieved. Investment not accepted");
     
     ICOUsersInfo storage icoStorage = ico[msg.sender];  
     uint useralloc = _amount*tokenPrice*1000000000000 / 1000;
     
     // check for existinguser
     if (existinguser[msg.sender]==false) {
         
         (,uint8 b)  =  nts.getStaker(msg.sender);
         
         require(b==1 || b==2 || b==3 || b==4, "Not whitelisted ");
         
         if (b == 1) 
         {
          require (useralloc <= tier1Max, "Not allowed" );     
          icoStorage.investedamount = _amount;                            //100 => 200    
          icoStorage.maxallocation = tier1Max;                            //1000 
          icoStorage.remainingallocation = tier1Max - (useralloc);                                 
         }   
         
        else if (b == 2) 
         {
          require (useralloc <= tier2Max, "Not allowed" );     
          icoStorage.investedamount = _amount;                            //100 => 200    
          icoStorage.maxallocation = tier2Max;                            //1000 
          icoStorage.remainingallocation = tier2Max - (useralloc);                                 
         }   
         
        else if (b == 3) 
         {
          require (useralloc <= tier3Max, "Not allowed" );     
          icoStorage.investedamount = _amount;                            //100 => 200    
          icoStorage.maxallocation = tier3Max;                            //1000 
          icoStorage.remainingallocation = tier3Max - (useralloc);                                 
         }
         
         else 
         {
          require (useralloc <= tier4Max, "Not allowed" );     
          icoStorage.investedamount = _amount;                            //100 => 200    
          icoStorage.maxallocation = tier4Max;                            //1000 
          icoStorage.remainingallocation = tier4Max - (useralloc);                                   
         }
         
        existinguser[msg.sender] = true;
        investors.push(msg.sender);
     }
     
     
       else {
         require ( ((_amount+icoStorage.investedamount)*tokenPrice*1000000000000) / 1000  <= icoStorage.maxallocation, "Not allowed" );
         icoStorage.investedamount += _amount;
         icoStorage.remainingallocation = icoStorage.remainingallocation - (useralloc);
       }
       
        icoStorage.remainingClaim = (icoStorage.investedamount * tokenPrice * 1000000000000) /1000;
        receivedFund = receivedFund + _amount;
        IBEP20(inputtoken).transferFrom(msg.sender,address(this), _amount);
     }
     
     
     function claimTokens() public {
    
     // check claim Status
     require(claimenabled == true, "Claim not start");
     
     require(existinguser[msg.sender] == true, "Already claim"); 
      
     ICOUsersInfo storage icoStorage = ico[msg.sender];
     
     uint256 redeemtokens = icoStorage.remainingClaim;
     
     require(redeemtokens>0, "No tokens to redeem");
     
       if (block.timestamp < vestingTime) {
                require(icoStorage.claimround == 0, "Already claim tokens of Round1");
                uint userclaim = (redeemtokens * vestingperc) / 100;
                icoStorage.remainingClaim -= userclaim; 
                icoStorage.claimround = 1; 
                IBEP20(outputtoken).transfer(msg.sender, userclaim);
        }
        else {
            
                IBEP20(outputtoken).transfer(msg.sender,  icoStorage.remainingClaim);
                existinguser[msg.sender] = false;   
                icoStorage.investedamount = 0;
                icoStorage.maxallocation = 0;
                icoStorage.remainingallocation = 0;
                icoStorage.remainingClaim = 0;
                icoStorage.claimround = 0;
        }
    }

    
    function checkyourTier(address _owner)public view returns (uint8 _tier) {
        
        (,uint8 b)  =  nts.getStaker(_owner);
        return b;
    }
    
    function maxBuyIDOToken(address _owner) public view returns (uint256 _max) {
        
        (,uint8 b)  =  nts.getStaker(_owner);
        
        if (b == 1) {
            return tier1Max;
        }
        
        else if (b == 2) {
            return tier2Max;
        }
        
        else if (b == 3) {
            return tier3Max;
        }
        else if (b == 4){
            return tier4Max;
        }
        else {
            return 0;
        }
    }
    
    
    function maximumContribution(address _owner) public view returns (uint256 _max) {
        
        (,uint8 b)  =  nts.getStaker(_owner);
        
        if (b == 1) {
            
            return ((tier1Max * 1000) /tokenPrice) / 1000000000000;
        }
        
        else if (b == 2) {
            return ((tier2Max * 1000) /tokenPrice) / 1000000000000;
        }
        
        else if (b == 3) {
            return ((tier3Max * 1000) /tokenPrice) / 1000000000000;
        }
        else if (b == 4){
            return ((tier4Max * 1000) /tokenPrice) / 1000000000000;
        }
        else {
            return 0;
        }
    }
    
    
    function remainigContribution(address _owner) public view returns (uint256) {
        
        ICOUsersInfo memory icoStorage = ico[_owner];
        
        uint256 remaining = maximumContribution(_owner) - icoStorage.investedamount;
        
        return remaining;
    }
    
    
    
    
    //  _token = 1 (outputtoken)        and         _token = 2 (inputtoken) 
    function checkICObalance(uint8 _token) public view returns(uint256 _balance) {
        
      if (_token == 1) {
          
        return IBEP20(outputtoken).balanceOf(address(this));
      }
      else if (_token == 2) {
          
        return IBEP20(inputtoken).balanceOf(address(this));  
      }
      
      else {
          return 0;
      }
    }
    
   

    function withdarwInputToken(address _admin, uint256 _amount) public onlyOwner{
        
    //   icoStatus = getIcoStatus();
    //   require(icoStatus == Status.completed, "ICO in not complete yet");
      
       uint256 raisedamount = IBEP20(inputtoken).balanceOf(address(this));
       
       require(raisedamount >= _amount, "Not enough token to withdraw");
       
       IBEP20(inputtoken).transfer(_admin, _amount);
        
    }
    
  
     function withdrawOutputToken(address _admin, uint256 _amount) public onlyOwner{
        
    //   icoStatus = getIcoStatus();
    //   require(icoStatus == Status.completed, "ICO in not complete yet");
       
       uint256 remainingamount = IBEP20(outputtoken).balanceOf(address(this));
       
       require(remainingamount >= _amount, "Not enough token to withdraw");
       
       IBEP20(outputtoken).transfer(_admin, _amount);
    }
    
    
    
    function resetICO() public onlyOwner {
        
         for (uint256 i = 0; i < investors.length; i++) {
             
            if (existinguser[investors[i]]==true)
            {
                  existinguser[investors[i]]=false;
                  ico[investors[i]].investedamount = 0;
                  ico[investors[i]].maxallocation = 0;
                  ico[investors[i]].remainingallocation = 0;
                  ico[investors[i]].remainingClaim = 0;
                  ico[investors[i]].claimround = 0;
            }
        }
        
        require(IBEP20(outputtoken).balanceOf(address(this)) <= 0, "Ico is not empty");
        require(IBEP20(inputtoken).balanceOf(address(this)) <= 0, "Ico is not empty");
        
        totalsupply = 0;
        icoTarget = 0;
        icoStatus = false;
        tier1Max =  0;
        tier2Max =  0;
        tier3Max =  0;
        tier4Max =  0;
        receivedFund = 0;
        poolweightTier1 = 0;
        poolweightTier2 = 0;
        poolweightTier3 = 0;
        poolweightTier4 = 0;
        poolweightinitialize = false;
        claimenabled = false;
        claim=false;
        icoTarget = 0;
        vestingTime = 0;
        vestingperc = 0;
        
        inputtoken  =  0x0000000000000000000000000000000000000000;
        outputtoken =  0x0000000000000000000000000000000000000000;
        tokenPrice = 0;
        
        delete investors;
        
    }
    
     

    function initializeIDOPoolweight(uint256 pw1, uint256 pw2, uint256 pw3, uint256 pw4) external onlyOwner {
        
        require (poolweightinitialize == false, "Pool weight already initialize");
        
        poolweightTier1 = pw1;
        poolweightTier2 = pw2;
        poolweightTier3 = pw3;
        poolweightTier4 = pw4;
        
        poolweightinitialize = true;
    }
 
    
    function initializeIDO(address _inputtoken, address _outputtoken, uint256 _tokenprice) public onlyOwner {
        
        require (_tokenprice>0, "Token price must be greater than 0");
        require (poolweightinitialize == true, "First initialize pool weight");
        
        inputtoken = _inputtoken;
        outputtoken = _outputtoken;
        tokenPrice = _tokenprice;
        
        require(IBEP20(outputtoken).balanceOf(address(this))>0,"Please first give Tokens to IDO");
        require(IBEP20(inputtoken).decimals()==6, "Only six decimal input token allowed");
        
        totalsupply = IBEP20(outputtoken).balanceOf(address(this));
        icoTarget = ((totalsupply / _tokenprice) * 1000 ) / 1000000000000;
        tier1Max =  getTier1Maxlimit();
        tier2Max =  getTier2Maxlimit();
        tier3Max =  getTier3Maxlimit();
        tier4Max =  getTier4Maxlimit();
    }
    
    function InitialzeVesting(uint256 _vestingtime, uint256 _vestingperc) external onlyOwner {
            
        require(vestingTime ==0 && vestingperc==0, "Vesting already initialzed");
        require(_vestingperc < 100, "Incorrect vestingpercentage");
            
        vestingTime = block.timestamp + _vestingtime;
        vestingperc = _vestingperc;
    }
}