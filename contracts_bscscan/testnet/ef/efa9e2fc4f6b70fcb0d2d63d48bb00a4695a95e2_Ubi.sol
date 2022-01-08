// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../lib/IERC20.sol";
import "../lib/Initializable.sol";

contract Ubi is Initializable {

    event Set_Ajax_Prime(address oldAjaxPrime, address newAjaxPrime);
    event Set_Reward_Token(address rewardToken);
    event Set_User_Info(address user, string idHash, Status newStatus);
    event Harvest(address user, uint amount);
    event Deposit_Reward(uint amount);
    event Set_Minimum_Reward_Per_Person(uint amount);

    address public ajaxPrime;
    address public rewardToken;

    enum Status { Init, Pending, Approved, Rejected }

    struct UserInfo {
        uint harvestedReward;
        string idHash;
        Status status;
    }

    uint public totalRewardPerPerson;
    uint public userCount;
    uint public minimumRewardPerPerson;

    mapping(address => UserInfo) public userInfo;

    modifier onlyAjaxPrime() {
        require(msg.sender == ajaxPrime, "Only Admin");
        _;
    }

    function set_reward_token(address _rewardToken) external onlyAjaxPrime {
        rewardToken = _rewardToken;
        emit Set_Reward_Token(_rewardToken);
    }

    function set_minimum_reward_per_person(uint amount) external onlyAjaxPrime {
        minimumRewardPerPerson = amount;
        emit Set_Minimum_Reward_Per_Person(amount);
    }

    function deposit_reward(uint amount) external {
        uint rewardPerPerson = amount / userCount;
        require(rewardPerPerson >= minimumRewardPerPerson, "Reward is too small");
        IERC20(rewardToken).transferFrom(msg.sender, address(this), amount);
        totalRewardPerPerson += rewardPerPerson;
        emit Deposit_Reward(amount);
    }

    function collect_ubi() external {
        UserInfo storage info = userInfo[msg.sender];
        require(info.status == Status.Approved, "You are not approved");
        uint reward = totalRewardPerPerson - info.harvestedReward;
        require(reward > 0, "Nothing to harvest");
        IERC20(rewardToken).transfer(msg.sender, reward);
        info.harvestedReward = totalRewardPerPerson;
        emit Harvest(msg.sender, reward);
    }

    function setUserInfo(address user, string calldata idHash, Status newStatus) external onlyAjaxPrime {
        UserInfo storage info = userInfo[user];
        require(info.status != Status.Init, "User is not registered");
        if(newStatus == Status.Approved) {
            if(info.status != Status.Approved) {
                userCount += 1;
                info.harvestedReward = totalRewardPerPerson;
            }
        }
        if(newStatus == Status.Rejected) {
            if(info.status == Status.Approved) {
                userCount -= 1;
            }
        }
        info.idHash = idHash;
        info.status = newStatus;
        emit Set_User_Info(user, idHash, newStatus);
    }

    function register() external {
        UserInfo storage info = userInfo[msg.sender];
        require(info.status == Status.Init, "You already registered");
        userInfo[msg.sender].status = Status.Pending;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(address _ajaxPrime, address _rewardToken) external initializer {
        ajaxPrime = _ajaxPrime;
        rewardToken = _rewardToken;
    }

    function set_ajax_prime(address newAjaxPrime) external onlyAjaxPrime {
        address oldAjaxPrime = ajaxPrime;
        ajaxPrime = newAjaxPrime;
        emit Set_Ajax_Prime(oldAjaxPrime, newAjaxPrime);
    }

    function withdrawByAdmin(address token, uint amount) external onlyAjaxPrime {
        IERC20(token).transfer(msg.sender, amount);
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