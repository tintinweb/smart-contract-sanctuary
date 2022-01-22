//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

interface IStakingToken is IERC20Upgradeable{
    function gonsForBalance(uint _amount) external view returns (uint);
    function balanceForGons(uint _amount) external view returns (uint);
    function circulatingSupply() external view returns (uint);
    function index() external view returns (uint);

    function rebase(uint _profit, uint _epoch) external ;
}

interface IStakingWarmUp {
    function retrieve( address _receiver, uint _amount ) external ;
}

interface IDistributor {
    function distribute() external returns (bool);
}

interface IgCESTA {
    function mint(address _to, uint256 _amount) external;
    function burn(address _from, uint256 _amount) external;
    function balanceFrom(uint256 _amount) external view returns (uint256);
    function balanceTo(uint256 _amount) external view returns (uint256);
}
contract Staking is Initializable, OwnableUpgradeable {

    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeERC20Upgradeable for IStakingToken;

    IERC20Upgradeable public CESTA;
    IStakingToken public stakingToken;
    IStakingWarmUp public stakingWarmUp;
    IgCESTA public gCESTA;
    address public distributor;    
    uint public warmupPeriod;
    uint public slashedRewards; // stakingToken collected from 

    bool isLockup;

    struct Claim {
        uint deposit;
        uint gons;
        uint expiry;
        bool lock; // prevents malicious delays
    }
    
    struct Epoch {
        uint length; //epoch length in seconds
        uint number;
        uint timestamp;
        uint distribute;
    }

    struct UserInfo  {
        uint deposit;
        uint gons;
    }

    Epoch public epoch;

    struct Penalty {
        uint interval; //time remaining
        uint perc; //penlty percentage //5000 for 50%
    }
    mapping(uint => Penalty) public penaltyInfo;

    // mapping( address => Claim ) public warmupInfo;
    // mapping(uint => address) public ids;
    
    mapping(address => Claim[]) public ids;
    mapping (address => UserInfo) public userInfo;
    mapping(address => uint) public lastWithdrawnSlot;

    address public DAO;

    function initialize(address owner_) external initializer {
        __Ownable_init();
        transferOwnership(owner_); //transfer ownership from proxyAdmin contract to deployer
    }

    function initialzeStaking(IERC20Upgradeable _CESTA, IStakingToken _sCESTA, address distributor_, address _stakingWarmUp, 
        uint _epochLength, uint _firstEpochNumber,
        uint _firstEpochTimestamp, uint warmUpPeriod_, bool _isLockup, address _DAO, address _gCESTA) external onlyOwner {

        require(address(CESTA) == address(0), "Already initalized");

        CESTA = _CESTA;
        stakingToken = _sCESTA;
        distributor = distributor_;
        warmupPeriod = warmUpPeriod_;
        DAO = _DAO;
        gCESTA = IgCESTA(_gCESTA);

        epoch = Epoch({
            length: _epochLength,
            number: _firstEpochNumber,
            timestamp: _firstEpochTimestamp + _epochLength,
            distribute: 0
        });

        isLockup = _isLockup;

        stakingWarmUp = IStakingWarmUp(_stakingWarmUp);
        
    }
    ///@notice Function to  deposit CESTA. stakingToken will not be trensferred in this function.
    function stake(uint _amount, address _receiver) external returns (bool) {
        rebase();
        CESTA.safeTransferFrom(msg.sender, address(this), _amount);

        UserInfo memory info = userInfo[ _receiver ];
        // require( !info.lock, "Deposits for account are locked" );

        ids[_receiver].push(Claim({
            deposit:  _amount ,
            gons: stakingToken.gonsForBalance( _amount ),
            expiry: epoch.timestamp +  warmupPeriod,
            lock: false
        }));

        userInfo[ _receiver ] = UserInfo ({
            deposit: info.deposit +  _amount ,
            gons: info.gons + stakingToken.gonsForBalance( _amount )
        });

        stakingToken.transfer(address(stakingWarmUp), _amount);
        return true;

    }

    ///@notice Claims only the expired deposits
    function safeClaim() public {
        uint totalDeposits = ids[msg.sender].length;
        require(totalDeposits > 0, "No previous deposits");

        uint _lastWithdrawnSlot = lastWithdrawnSlot[msg.sender];

        uint _currentSlot;
        //totalDeposits is length of array, so greater than 1 == more than 1 deposit (else block)
        //set current slot to 0 if there is only one deposit
        //else set current slot to next available slot 
        if(totalDeposits == 1) {
            Claim memory info = ids[msg.sender][_currentSlot];
            require(info.deposit > 0, "No New deposits"); //slot 0 is already withdrawn if info.deposit is 0
            //currentSlot is 0
        } else {
            require(_lastWithdrawnSlot < totalDeposits - 1, "No New Deposits");
            _currentSlot = _lastWithdrawnSlot +1;
        }

        uint _amount;
        uint _depositedAmt; //for easy querying
        
        uint targetSlot = totalDeposits > _lastWithdrawnSlot + 10 //if more than 10 deposits after last withdrawl
        ? _lastWithdrawnSlot + 10 //check only next 10 slots
        : totalDeposits; //if less than 10 new deposits, check upto totalDeposits(i.e totalDeposits -1 th slot)
        
        for(; _currentSlot < targetSlot; _currentSlot++) {
            Claim memory info = ids[msg.sender][_currentSlot];
            
            if(epoch.timestamp >= info.expiry && info.expiry != 0) {
                _amount += stakingToken.balanceForGons(info.gons);
                _depositedAmt += info.deposit;
                delete ids[msg.sender][_currentSlot]; //gas refund
            } else {
                //withdrawn upto previous loop's slot
                //This block is reached only once

                //if no deposits _currentSlot is 0, set lastWithdrawnSlot = 0 else set previous slot
                lastWithdrawnSlot[msg.sender] = _currentSlot == 0 ? 0 : _currentSlot -1;
                _currentSlot = targetSlot; //exit loop
            }

        }

        if(_amount > 0) {
            UserInfo memory _userInfo = userInfo[ msg.sender ];
            
            userInfo[ msg.sender ] = UserInfo ({
                deposit: _userInfo.deposit - _depositedAmt ,
                gons: _userInfo.gons - stakingToken.gonsForBalance( _userInfo.deposit - _depositedAmt )
            });
            
            stakingWarmUp.retrieve(address(this), _amount);
            _wrap(_amount, msg.sender);

        }
    }

    function forceClaim() public {
        require(isLockup == false, "Cannot withdraw during lockup period"); //true for lockedStaking

        uint totalDeposits = ids[msg.sender].length;
        require(totalDeposits > 0, "No previous deposits");

        uint _lastWithdrawnSlot = lastWithdrawnSlot[msg.sender];
        uint _currentSlot;
        //totalDeposits is length of array, so greater than 1 == more than 1 deposit (else block)
        //set current slot to 0 if there is only one deposit
        //else set current slot to next available slot 
        if(totalDeposits == 1) {
            Claim memory info = ids[msg.sender][_currentSlot];
            require(info.deposit > 0, "No New deposits"); //slot 0 is already withdrawn if info.deposit is 0
            //currentSlot is 0
        } else {
            require(_lastWithdrawnSlot < totalDeposits - 1, "No New Deposits");

            if(_lastWithdrawnSlot == 0 && ids[msg.sender][0].deposit > 0) {
                //slot 0 is not withdrawn yet
                _currentSlot = 0;
            } else {
                _currentSlot = _lastWithdrawnSlot +1;
            }
        }

        uint _amount;
        uint _reward;
        uint _depositedAmt;
        uint _penalty;

        uint targetSlot = totalDeposits > _lastWithdrawnSlot + 10 //if more than 10 deposits after last withdrawl
            ? _lastWithdrawnSlot + 10 //check only next 10 slots
            : totalDeposits; //if less than 10 new deposits, check upto totalDeposits(i.e totalDeposits -1 th slot)
                
        for(; _currentSlot < targetSlot; _currentSlot++) {
            Claim memory info = ids[msg.sender][_currentSlot];


            uint _amtCurrSlot = stakingToken.balanceForGons(info.gons);
            uint _rewardCurrSlot = _amtCurrSlot - info.deposit;
            _reward += _rewardCurrSlot;
            _amount += _amtCurrSlot;
            _depositedAmt += info.deposit;
            
            if(info.expiry > epoch.timestamp) {
                _penalty += _calculatePenalty(_rewardCurrSlot, info.expiry);
            }
            
            delete ids[msg.sender][_currentSlot]; //gas refund
        }

        lastWithdrawnSlot[msg.sender] = targetSlot -1; //targetSlot is length so subtracting 1

        uint amtToWithdraw;
        
        stakingWarmUp.retrieve(address(this), _amount);

        if(_penalty > 0) {
            amtToWithdraw = _amount - _penalty;
            _wrap(_penalty, DAO);
        } else {
            amtToWithdraw = _amount;
        }

        UserInfo memory _userInfo = userInfo[ msg.sender ];
            
        userInfo[ msg.sender ] = UserInfo ({
            deposit: _userInfo.deposit - _depositedAmt ,
            gons: _userInfo.gons - stakingToken.gonsForBalance( _userInfo.deposit - _depositedAmt )
        });

        _wrap(amtToWithdraw, msg.sender);
    }

    function unStake(uint _amount, bool _trigger) external {
        if(_trigger == true) {
            rebase();
        }
        
        uint _amt = _unWrap(_amount);
        CESTA.safeTransfer( msg.sender, _amt );
    }

    ///@return gBalance_ _amount equivalent gCESTA 
    function _wrap(uint _amount, address _to) internal returns (uint gBalance_) {
        //should transfer sCESTA to this contract before calling this function
        gBalance_ = gCESTA.balanceTo(_amount);
        gCESTA.mint(_to, gBalance_);
    }

    ///@param _amount number of gCESTA to upwrap to sCESTA
    ///@return sBalance _amount equivalent sCESTA 
    function _unWrap(uint _amount) internal returns(uint sBalance) {
        gCESTA.burn(msg.sender, _amount);
        sBalance = gCESTA.balanceFrom(_amount);

        //transfer out sCESTA or CESTA after this function
    }

    function _calculatePenalty(uint _reward, uint _expiry) public view returns (uint) {
        uint diff = _expiry - epoch.timestamp; //lock time remaining

        if(diff >= penaltyInfo[0].interval) { //max Interval (max fee).
            return _reward * penaltyInfo[0].perc / 100_00;

        } else if(diff >= penaltyInfo[1].interval) {
            return _reward * penaltyInfo[1].perc / 100_00;

        } else if(diff >= penaltyInfo[2].interval) {
            return _reward * penaltyInfo[2].perc / 100_00;

        } else if(diff >= penaltyInfo[3].interval) { //least interval (least fee). Interval 
            return _reward * penaltyInfo[3].perc / 100_00;
        } else {
            return _reward * penaltyInfo[4].perc / 100_00;

        }
    }

    ///@return rewards_ Total rewards without penalty deductions (in CESTA terms)
    ///@return penalty_ Penalty amount (in CESTA terms)
    ///@return withdrawn_ gCESTA that will be withdrawn (in gCESTA)
    function forceClaimInfo(address _user) external view returns (uint rewards_, uint penalty_, uint withdrawn_){
        uint totalDeposits = ids[_user].length;

        if(totalDeposits > 0) {
            uint _lastWithdrawnSlot = lastWithdrawnSlot[_user];
            uint _currentSlot;

            if(_lastWithdrawnSlot == 0 && ids[_user][0].deposit > 0) {
                //slot 0 is not withdrawn yet
                _currentSlot = 0;
            } else {
                _currentSlot = _lastWithdrawnSlot +1;
            }

            uint targetSlot = totalDeposits > _lastWithdrawnSlot + 10 //if more than 10 deposits after last withdrawl
            ? _lastWithdrawnSlot + 10 //check only next 10 slots
            : totalDeposits; //if less than 10 new deposits, check upto totalDeposits(i.e totalDeposits -1 th slot)
                
            uint _amount;
            for(; _currentSlot < targetSlot; _currentSlot++) {
                Claim memory info = ids[_user][_currentSlot];


                uint _amtCurrSlot = stakingToken.balanceForGons(info.gons);
                uint _rewardCurrSlot = _amtCurrSlot - info.deposit;
                rewards_ += _rewardCurrSlot;
                _amount += _amtCurrSlot;
            
                if(info.expiry > epoch.timestamp) {
                    penalty_ += _calculatePenalty(_rewardCurrSlot, info.expiry);
                }
            
            }

            withdrawn_ = gCESTA.balanceTo(_amount - penalty_);

        }
        
    }

    function safeClaimInfo(address _user) external view returns (uint rewards_, uint withdrawn_) {
        uint totalDeposits = ids[_user].length;

        if(totalDeposits > 0) {
            uint _lastWithdrawnSlot = lastWithdrawnSlot[_user];
            uint _currentSlot;

            if(_lastWithdrawnSlot == 0 && ids[_user][0].deposit > 0) {
                //slot 0 is not withdrawn yet
                _currentSlot = 0;
            } else {
                _currentSlot = _lastWithdrawnSlot +1;
            }

            uint targetSlot = totalDeposits > _lastWithdrawnSlot + 10 //if more than 10 deposits after last withdrawl
            ? _lastWithdrawnSlot + 10 //check only next 10 slots
            : totalDeposits; //if less than 10 new deposits, check upto totalDeposits(i.e totalDeposits -1 th slot)
                
            uint _amount;
            for(; _currentSlot < targetSlot; _currentSlot++) {
                Claim memory info = ids[_user][_currentSlot];

                if(epoch.timestamp >= info.expiry && info.expiry != 0) {
                    uint _amtCurrSlot = stakingToken.balanceForGons(info.gons);
                    _amount += _amtCurrSlot;
                    uint _rewardCurrSlot = _amtCurrSlot - info.deposit;
                    rewards_ += _rewardCurrSlot;
                } else {
                    //This block is reached only once

                    _currentSlot = targetSlot; //exit loop
                }
            
            }

            withdrawn_ = gCESTA.balanceTo(_amount);

        }
    }

    function idInfo(address _user) external view returns (uint first_, uint end_) {
        uint _lastWithdrawnSlot  = lastWithdrawnSlot[_user];
        
        first_ = _lastWithdrawnSlot == 0 && ids[_user][0].deposit > 0 
        ? 0  
        : _lastWithdrawnSlot +1;

        end_ = ids[_user].length > 0 ? ids[_user].length -1 : 0;
    }

    ///@return deposited amount
    ///@return principle + rewards from this deposit
    ///@return Lockup end time
    function depositInfo(address _user, uint _id) external view returns (uint, uint, uint) {
        if(ids[_user].length > 0) {
            Claim memory info = ids[_user][_id];
            return (
                info.deposit, 
                stakingToken.balanceForGons( info.gons ),
                info.expiry
            );
        }
    }

    function setPenaltyInfo(uint _id, uint _interval, uint _feePerc) external onlyOwner{
        penaltyInfo[_id] = Penalty({
            interval: _interval,
            perc: _feePerc
        });
    }

    function rebase() public {
        if(epoch.timestamp <= block.timestamp) {
            stakingToken.rebase(epoch.distribute, epoch.number);

            // epoch.endBlock = epoch.endBlock + epoch.length;
            epoch.timestamp = epoch.timestamp + epoch.length;

            epoch.number++;

            if ( distributor != address(0) ) {
                IDistributor( distributor ).distribute();
            }

            uint balance = CESTA.balanceOf(address(this));
            uint staked = stakingToken.circulatingSupply();

            if( balance <= staked ) {
                epoch.distribute = 0;
            } else {
                epoch.distribute = balance -  staked;
            }
        }
    }

    // function toggleDepositLock() external {
    //     warmupInfo[ msg.sender ].lock = !warmupInfo[ msg.sender ].lock;
    // }


    function index() public view returns ( uint ) {
        return stakingToken.index();
    }


}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

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
 * /// @custom:oz-upgrades-unsafe-allow constructor
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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}