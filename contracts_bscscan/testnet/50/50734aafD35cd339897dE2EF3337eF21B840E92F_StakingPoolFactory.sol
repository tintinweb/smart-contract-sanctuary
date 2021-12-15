//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../pools/BlockRewardStakingPool.sol";
import "../../pools/FixedAPRStakingPool.sol";
import "../../libraries/Dictionary.sol";

contract StakingPoolFactory is Ownable {
  BlockRewardStakingPool[] private childrenBlockRewardStakingPool;
  FixedAPRStakingPool[] private childrenFixedAPRStakingPool;

  Dictionary private config;

  event FixedAPRStakingPoolDeployed(address owner, address sc);
  event BlockRewardStakingPoolDeployed(address owner, address sc);

  constructor(address configFee) {
    config = Dictionary(configFee);
  }

  function createFixedAPRStakingPool(
    address stakingToken,
    address rewardToken,
    uint256 minInvestment,
    uint256 maxInvestment,
    uint256 lockDuration,
    uint256 startDate,
    uint256 duration,
    uint8 apr
  ) external payable {
    require(
      msg.value >= config.getFee("staking"),
      "PoolFactory:Not enough value"
    );

    FixedAPRStakingPool child = new FixedAPRStakingPool(
      msg.sender,
      stakingToken,
      rewardToken,
      minInvestment,
      maxInvestment,
      lockDuration,
      startDate,
      duration,
      apr
    );
    childrenFixedAPRStakingPool.push(child);
    emit FixedAPRStakingPoolDeployed(msg.sender, address(child));
  }

  function createBlockRewardStakingPool(
    address stakingToken,
    address rewardToken,
    uint256 minInvestment,
    uint256 maxInvestment,
    uint256 lockDuration,
    uint256 startDate,
    uint256 duration,
    uint256 rewardPerBlock
  ) external payable {
    require(
      msg.value >= config.getFee("staking"),
      "PoolFactory:Not enough value"
    );

    BlockRewardStakingPool child = new BlockRewardStakingPool(
      msg.sender,
      stakingToken,
      rewardToken,
      minInvestment,
      maxInvestment,
      lockDuration,
      startDate,
      duration,
      rewardPerBlock
    );
    childrenBlockRewardStakingPool.push(child);
    emit BlockRewardStakingPoolDeployed(msg.sender, address(child));
  }

  function withdraw(uint256 amount, address to) public onlyOwner {
    payable(address(to)).transfer(amount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../access/Owner.sol";
import "../token/ERC20/interfaces/IERC20.sol";
import "../libraries/SafeMath.sol";


contract BlockRewardStakingPool is Ownable {
    using SafeMath for uint256;

    uint256 constant SECOND_IN_YEAR = 60*60*24*365;
    uint256 constant AVERAGE_BLOCK_DURATION = 3;

    IERC20 public STAKING_TOKEN;
    IERC20 public REWARD_TOKEN;
    uint256 public REWARD_PER_BLOCK;
    uint256 public MIN_INVESTMENT;
    uint256 public MAX_INVESTMENT;
    uint256 public LOCK_DURATION;
    uint256 public START_DATE;
    uint256 public DURATION;

    uint256 public totalBalance;
    uint256 public rewardPerTokenStored;
    uint256 public lastUpdateBlock;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address=>uint256) public balances;
    mapping(address=>uint256) public rewards;
    mapping(address=>uint256) public lastTimeUpdateReward;
    mapping(address=>uint256) public depositedAt;

    constructor(
        address sender,
        address stakingToken,
        address rewardToken,
        uint256 minInvestment,
        uint256 maxInvestment,
        uint256 lockDuration,
        uint256 startDate,
        uint256 duration,
        uint256 rewardPerBlock
    ) {
        STAKING_TOKEN = IERC20(stakingToken);
        REWARD_TOKEN = IERC20(rewardToken);
        MIN_INVESTMENT = minInvestment;
        MAX_INVESTMENT = maxInvestment;
        LOCK_DURATION = lockDuration;
        START_DATE = startDate;
        DURATION = duration;
        REWARD_PER_BLOCK = rewardPerBlock;
        transferOwnership(sender);
    }

    function apr() public view returns (uint256) {
        return REWARD_PER_BLOCK
            .mul(SECOND_IN_YEAR)
            .div(totalBalance)
            .div(AVERAGE_BLOCK_DURATION);
    }

    function earned(address user) public view returns (uint256) {
        uint256 generatedReward = balances[user].mul(
            _rewardPerToken()
            .sub(userRewardPerTokenPaid[user])
        ).div(1e18);
        return rewards[user].add(generatedReward);
    }

    function _updateReward(address user) internal {
        rewardPerTokenStored = _rewardPerToken();
        lastUpdateBlock = block.number;
        if (user != address(0)) {
            rewards[user] = earned(user);
            userRewardPerTokenPaid[user] = rewardPerTokenStored;
        }
    }

    function _rewardPerToken() public view returns (uint256) {
        if (totalBalance == 0) {
            return rewardPerTokenStored;
        }
        return rewardPerTokenStored.add(
            block.number
            .sub(lastUpdateBlock)
            .mul(REWARD_PER_BLOCK)
            .mul(1e18)
            .div(totalBalance)
        );
    }

    function deposit(uint256 amount) external {
        _updateReward(msg.sender);
        _deposit(msg.sender, amount);
    }

    function withdraw(uint256 amount) external {
        _updateReward(msg.sender);
        _withdraw(msg.sender, amount);
    }

    function withdrawAll() external {
        _updateReward(msg.sender);
        uint256 reward = rewards[msg.sender];
        rewards[msg.sender] = 0;
        REWARD_TOKEN.transfer(msg.sender, reward);
        
        uint256 userBalance = balances[msg.sender];
        _withdraw(msg.sender, userBalance);
        
        lastTimeUpdateReward[msg.sender] = 0;
    }

    function claim() external {
        _updateReward(msg.sender);
        uint256 reward = rewards[msg.sender];
        rewards[msg.sender] = 0;
        REWARD_TOKEN.transfer(msg.sender, reward);
    }

    function _withdraw(address user, uint256 amount) private {
        require(amount < balances[user], "NCSCStakingPool:Withdraw exceed balance");
        require(block.timestamp > depositedAt[user].add(LOCK_DURATION), "NCSCStakingPool:Withdraw still locked");
        STAKING_TOKEN.transfer(user, amount);
        balances[user] = balances[user].sub(amount);
        totalBalance = totalBalance.sub(amount);
    }

    function _deposit(address user, uint256 amount) private {
        require(amount > MIN_INVESTMENT, "NCSCStakingPool:Deposit less than min investment");
        if (MAX_INVESTMENT > 0) {
            require(amount < MAX_INVESTMENT, "NCSCStakingPool:Deposit exceed max investment");
        }
        if (START_DATE > 0) {
            require(block.timestamp > START_DATE, "NCSCStakingPool:Not start yet");
            if (DURATION > 0) {
                require(block.timestamp < START_DATE.add(DURATION), "NCSCStakingPool:Pool is over");
            }
        }
        STAKING_TOKEN.transferFrom(user, address(this), amount);
        balances[user] = balances[user].add(amount);
        totalBalance = totalBalance.add(amount);
        depositedAt[user] = block.timestamp;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../access/Owner.sol";
import "../token/ERC20/interfaces/IERC20.sol";
import "../libraries/SafeMath.sol";


contract FixedAPRStakingPool is Ownable {
    using SafeMath for uint256;

    uint256 constant SECOND_IN_YEAR = 60*60*24*365;

    IERC20 public STAKING_TOKEN;
    IERC20 public REWARD_TOKEN;
    uint8 public APR;
    uint256 public MIN_INVESTMENT;
    uint256 public MAX_INVESTMENT;
    uint256 public LOCK_DURATION;
    uint256 public START_DATE;
    uint256 public DURATION;

    uint256 public totalBalance;

    mapping(address=>uint256) public balances;
    mapping(address=>uint256) public rewards;
    mapping(address=>uint256) public lastTimeUpdateReward;
    mapping(address=>uint256) public depositedAt;

    constructor(
        address sender,
        address stakingToken,
        address rewardToken,
        uint256 minInvestment,
        uint256 maxInvestment,
        uint256 lockDuration,
        uint256 startDate,
        uint256 duration,
        uint8 apr
    ) {
        STAKING_TOKEN = IERC20(stakingToken);
        REWARD_TOKEN = IERC20(rewardToken);
        APR = apr;
        MIN_INVESTMENT = minInvestment;
        MAX_INVESTMENT = maxInvestment;
        LOCK_DURATION = lockDuration;
        START_DATE = startDate;
        DURATION = duration;
        transferOwnership(sender);
    }

    function earned(address user) public view returns (uint256) {
        if (lastTimeUpdateReward[user] == 0)
            return 0;
        uint256 duration = block.timestamp.sub(lastTimeUpdateReward[user]);
        uint256 generatedReward = balances[user].mul(APR).mul(duration).div(10000).div(SECOND_IN_YEAR);
        return rewards[user].add(generatedReward);
    }

    function _updateReward(address user) internal {
        rewards[user] = earned(user);
        lastTimeUpdateReward[user] = block.timestamp;
    }

    function deposit(uint256 amount) external {
        _updateReward(msg.sender);
        _deposit(msg.sender, amount);
    }

    function withdraw(uint256 amount) external {
        _updateReward(msg.sender);
        _withdraw(msg.sender, amount);
    }

    function withdrawAll() external {
        _updateReward(msg.sender);
        uint256 reward = rewards[msg.sender];
        rewards[msg.sender] = 0;
        REWARD_TOKEN.transfer(msg.sender, reward);
        
        uint256 userBalance = balances[msg.sender];
        _withdraw(msg.sender, userBalance);
        
        lastTimeUpdateReward[msg.sender] = 0;
    }

    function claim() external {
        _updateReward(msg.sender);
        uint256 reward = rewards[msg.sender];
        rewards[msg.sender] = 0;
        REWARD_TOKEN.transfer(msg.sender, reward);
    }

    function _withdraw(address user, uint256 amount) private {
        require(amount < balances[user], "NCSCStakingPool:Withdraw exceed balance");
        require(block.timestamp > depositedAt[user].add(LOCK_DURATION), "NCSCStakingPool:Withdraw still locked");
        STAKING_TOKEN.transfer(user, amount);
        balances[user] = balances[user].sub(amount);
        totalBalance = totalBalance.sub(amount);
    }

    function _deposit(address user, uint256 amount) private {
        require(amount > MIN_INVESTMENT, "NCSCStakingPool:Deposit less than min investment");
        if (MAX_INVESTMENT > 0) {
            require(amount < MAX_INVESTMENT, "NCSCStakingPool:Deposit exceed max investment");
        }
        if (START_DATE > 0) {
            require(block.timestamp > START_DATE, "NCSCStakingPool:Not start yet");
            if (DURATION > 0) {
                require(block.timestamp < START_DATE.add(DURATION), "NCSCStakingPool:Pool is over");
            }
        }
        STAKING_TOKEN.transferFrom(user, address(this), amount);
        balances[user] = balances[user].add(amount);
        totalBalance = totalBalance.add(amount);
        depositedAt[user] = block.timestamp;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../access/GroupOwner.sol';
import './interfaces/IDictionary.sol';


contract Dictionary is IDictionary, GroupOwnable {
    mapping(bytes32 => uint256) private fees;

    function getFee(string memory key) override public view returns (uint256) {
        bytes32 encodedKey = keccak256(abi.encodePacked(key));
        return fees[encodedKey];
    }

    function getFees(string[] memory keys) override public view returns (uint256) {
        uint256 fee;
        for (uint256 index = 0; index < keys.length; index++) {
            bytes32 encodedKey = keccak256(abi.encodePacked(keys[index]));
            fee += fees[encodedKey];
        }
        return fee;
    }

    function setFee(string memory key, uint256 value ) override public groupOwner {
        bytes32 encodedKey = keccak256(abi.encodePacked(key));
        fees[encodedKey] = value;
    }

    function getEncodedKey(string memory key) override public pure returns (bytes32) {
        return keccak256(abi.encodePacked(key));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../libraries/Context.sol";

abstract contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor() {
    _setOwner(_msgSender());
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view virtual returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(owner() == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() public virtual onlyOwner {
    _setOwner(address(0));
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    _setOwner(newOwner);
  }

  function _setOwner(address newOwner) private {
    address oldOwner = _owner;
    _owner = newOwner;
    emit OwnershipTransferred(oldOwner, newOwner);
  }

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
  //erc2917 and erc20
  function totalSupply() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SafeMath {
  function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require((z = x + y) >= x, "ds-math-add-overflow");
  }

  function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require((z = x - y) <= x, "ds-math-sub-underflow");
  }

  function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMath: division by zero");
  }

  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Context {
  function _msgSender() internal view virtual returns (address) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes calldata) {
    return msg.data;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./Owner.sol";

abstract contract GroupOwnable is Ownable {
  address private addressContract;
  address[] public owners;
  mapping(address => bool) public ownerByAddress;

  event SetOwners(address[] owners);
  event RemoveOwners(address[] owners);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor() {
    ownerByAddress[_msgSender()] == true;
  }

  /**
   * @dev groupOwner.
   */
  modifier groupOwner() {
    require(
      checkOwner(_msgSender()) || owner() == _msgSender(),
      "GroupOwner: caller is not the owner"
    );
    _;
  }

  /**
   * @dev Function to set owners addresses
   */
  function setGroupOwners(address[] memory _owners) public virtual groupOwner {
    _setOwners(_owners);
  }

  function _setOwners(address[] memory _owners) private {
    for (uint256 index = 0; index < _owners.length; index++) {
      if (!ownerByAddress[_owners[index]]) {
        ownerByAddress[_owners[index]] = true;
        owners.push(_owners[index]);
      }
    }
    emit SetOwners(owners);
  }

  /**
   * @dev Function to remove owners addresses
   */
  function removeOwner(address _oldowner) public virtual groupOwner {
    _removeOwner(_oldowner);
  }

  function _removeOwner(address _oldowner) private {
    ownerByAddress[_oldowner] = true;

    emit RemoveOwners(owners);
  }

  function checkOwner(address newOwner) public view virtual returns (bool) {
    return ownerByAddress[newOwner];
  }

  function getOwners() public view virtual returns (address[] memory) {
    return owners;
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../../access/Owner.sol';

interface IDictionary {
    function getFee(string memory key) external view returns (uint256);
    function setFee(string memory key, uint256 value) external;
    function getEncodedKey(string memory key) external pure returns (bytes32);
    function getFees(string[] memory keys) external view returns (uint256);
}