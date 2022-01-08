// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../IJaxAdmin.sol";
import "../lib/Initializable.sol";
import "./IERC20.sol";
import "../JaxOwnable.sol";

interface IVRP {
    enum Action { Mint, Burn }
    enum Status { InActive, Active }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    event Set_Jax_Admin(address jaxAdmin);
    event Set_Jax_Swap(address jaxSwap);
    event Vote_Governor(address voter, address candidate);
    event Init_Average_Balance();
    event Update_Vote_Share(address voter, address candidate, uint voteShare);
    event Set_Reward_Token(address rewardToken);
    event Harvest(address account, uint amount);
    event Deposit_Reward(uint amount);
}

/**
 * @title WJAX
 * @dev Implementation of the WJAX
 */
//, Initializable
contract VRP is IVRP, Initializable, JaxOwnable {
    
    address public jaxAdmin;
    address public jaxSwap;

    address public rewardToken;

    mapping (address => uint256) private _balances;
    
    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    
    // blacklisted addressed can not send, receive tokens and tokens cannot be minted to this address.

    struct EpochInfo {
        uint blockCount;
        uint rewardPerShare;
        uint totalRewardPerBalance;
    }

    EpochInfo[] public epochInfo;

    uint currentEpoch;
    uint lastEpochBlock;
    
    uint epochSharePlus;
    uint epochShareMinus;

    struct UserInfo {
        uint currentEpoch;
        uint sharePlus;
        uint shareMinus;
        uint rewardPaid;
        uint totalReward;
    }

    mapping(address => UserInfo) userInfo;

    // Voting States
    mapping (address => uint)  public voteShare;
    mapping (address => address) public vote;
    uint public voterCount;

    function initialize (address _jaxAdmin) public initializer {
        _name = "Volatility Reserves Pool";
        _symbol = "VRP";
        _decimals = 18;
        jaxAdmin = _jaxAdmin;
        EpochInfo memory firstEpoch;
        epochInfo.push(firstEpoch);
        currentEpoch = 1;
        lastEpochBlock = block.number;
        owner = msg.sender;
    }

    modifier onlyAdmin() {
        require(IJaxAdmin(jaxAdmin).userIsAdmin(msg.sender) || msg.sender == owner, "Only Admin can perform this operation.");
        _;
    }

    modifier onlyGovernor() {
        require(IJaxAdmin(jaxAdmin).userIsGovernor(msg.sender), "Only Governor can perform this operation.");
        _;
    }

    modifier onlyJaxSwap() {
        require(msg.sender == jaxSwap, "Only JaxSwap can perform this operation.");
        _;
    }

    function setJaxAdmin(address _jaxAdmin) public onlyAdmin {
        jaxAdmin = _jaxAdmin;    
        IJaxAdmin(jaxAdmin).system_status();    
        emit Set_Jax_Admin(_jaxAdmin);
    }

    function setJaxSwap(address _jaxSwap) public onlyAdmin {
        jaxSwap = _jaxSwap;
        emit Set_Jax_Swap(_jaxSwap);
    }

    function mint(address account, uint256 amount) public onlyJaxSwap {
        updateReward(account);
        UserInfo storage info = userInfo[account];
        info.shareMinus += amount * (block.number - lastEpochBlock);
        epochShareMinus += amount * (block.number - lastEpochBlock);
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) public onlyJaxSwap {
        updateReward(account);
        UserInfo storage info = userInfo[account];
        info.sharePlus += amount * (block.number - lastEpochBlock);
        epochSharePlus += amount * (block.number - lastEpochBlock);
        _burn(account, amount);
    }

    function burnFrom(address account, uint256 amount) public {
      uint256 currentAllowance = allowance(account, msg.sender);
      require(currentAllowance >= amount, "BEP20: burn amount exceeds allowance");
      _approve(account, msg.sender, currentAllowance - amount);
      burn(account, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        revert("transfer is not allowed");
        return false;
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        revert("transfer is not allowed");
        return false;
    }

    function deposit_reward(uint amount) public {
        require(IJaxAdmin(jaxAdmin).userIsGovernor(tx.origin), "tx.origin should be governor");
        uint epochShare = (block.number - lastEpochBlock) * totalSupply() + epochSharePlus - epochShareMinus;
        
        uint rewardPerShare;
        if(epochShare > 0) {
            rewardPerShare = amount * 1e36 / epochShare; // multiplied by 1e36
            IERC20(rewardToken).transferFrom(msg.sender, address(this), amount);
        }
        EpochInfo memory newEpoch;
        newEpoch.blockCount = block.number - lastEpochBlock;
        newEpoch.rewardPerShare = rewardPerShare;
        newEpoch.totalRewardPerBalance = epochInfo[currentEpoch-1].totalRewardPerBalance + rewardPerShare * (block.number - lastEpochBlock);
        epochInfo.push(newEpoch);
        lastEpochBlock = block.number;
        epochShare = 0;
        epochSharePlus = 0;
        epochShareMinus = 0;
        currentEpoch += 1;
        emit Deposit_Reward(amount);
    }

    function updateReward(address account) internal {
        UserInfo storage user = userInfo[account];
        if(user.currentEpoch == currentEpoch) return;
        if(user.currentEpoch == 0) {
            user.currentEpoch = currentEpoch;
            return;
        }
        uint balance = balanceOf(account);
        EpochInfo storage epoch = epochInfo[user.currentEpoch];
        uint newReward = (balance * epoch.blockCount + user.sharePlus - user.shareMinus) * epoch.rewardPerShare;
        newReward += balance * (epochInfo[currentEpoch-1].totalRewardPerBalance - 
                            epochInfo[user.currentEpoch].totalRewardPerBalance);
        user.totalReward += newReward;
        user.sharePlus = 0;
        user.shareMinus = 0;
        user.currentEpoch = currentEpoch;
    }

    function harvest() external {
        updateReward(msg.sender);
        UserInfo storage user = userInfo[msg.sender];
        uint reward = (user.totalReward - user.rewardPaid)/1e36;
        require(reward > 0, "Nothing to harvest");
        IERC20(rewardToken).transfer(msg.sender, reward);
        user.rewardPaid = user.totalReward;
        emit Harvest(msg.sender, reward);
    }

    function set_reward_token(address _rewardToken) public onlyAdmin {
        rewardToken = _rewardToken;
        emit Set_Reward_Token(_rewardToken);
    }

    // vote functions
    function vote_governor(address candidate) public {
        require(balanceOf(msg.sender) > 0, "Only VRP holders can participate voting.");
        require(vote[msg.sender] != candidate, "Already Voted");
        if(vote[msg.sender] != address(0x0)) {
        voteShare[vote[msg.sender]] -= balanceOf(msg.sender);
        }
        vote[msg.sender] = candidate;
        voteShare[candidate] += balanceOf(msg.sender);
        emit Vote_Governor(msg.sender, candidate);
        check_candidate(candidate);
    }

    function check_candidate(address candidate) internal {
        if(candidate == address(0x0)) return;
        if(voteShare[candidate] >= totalSupply() * 51 / 100) {
            IJaxAdmin(jaxAdmin).electGovernor(candidate);
        }
    }

    function updateVoteShare(address voter, uint amount, Action action) internal {
        address candidate = vote[voter];
        if(action == Action.Mint)
            voteShare[candidate] += amount;
        else
            voteShare[candidate] -= amount;
        emit Update_Vote_Share(voter, candidate, voteShare[candidate]);
        check_candidate(candidate);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "BEP20: decreased allowance below zero");
        _approve(msg.sender, spender, currentAllowance - subtractedValue);

        return true;
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "BEP20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "BEP20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "BEP20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IJaxAdmin {

  function userIsAdmin (address _user) external view returns (bool);
  function userIsGovernor (address _user) external view returns (bool);
  function userIsAjaxPrime (address _user) external view returns (bool);
  function system_status () external view returns (uint);
  function electGovernor (address _governor) external;  
  function blacklist(address _user) external view returns (bool);
  function fee_blacklist(address _user) external view returns (bool);
  function priceImpactLimit() external view returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

/**
 * @dev Interface of the BEP standard.
 */
interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function getOwner() external view returns (address);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function mint(address account, uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract JaxOwnable {

  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  modifier onlyOwner() {
      require(owner == msg.sender, "JaxOwnable: caller is not the owner");
      _;
  }

  function transferOwnership(address newOwner) external onlyOwner {
    require(newOwner != address(0), "new owner is the zero address");
    _transferOwnership(newOwner);
  }

  function renounceOwnership() external onlyOwner {
    _transferOwnership(address(0));
  }

  /**
  * @dev Transfers ownership of the contract to a new account (`newOwner`).
  * Internal function without access restriction.
  */
  function _transferOwnership(address newOwner) internal virtual {
    address oldOwner = owner;
    owner = newOwner;
    emit OwnershipTransferred(oldOwner, newOwner);
  }
}