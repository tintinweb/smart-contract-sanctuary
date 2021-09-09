/**
 *Submitted for verification at Etherscan.io on 2021-09-09
*/

// File: contracts/YCoin.sol

/**
 *Submitted for verification at Etherscan.io on 2021-01-02
*/

pragma solidity ^0.6.12;

interface IERC20 {
    
    function totalSupply() external view returns (uint256);

   
    function balanceOf(address account) external view returns (uint256);

   
    function transfer(address recipient, uint256 amount) external returns (bool);

   
    function allowance(address owner, address spender) external view returns (uint256);

   
    function approve(address spender, uint256 amount) external returns (bool);

    
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    
    event Transfer(address indexed from, address indexed to, uint256 value);

    
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

   
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

   
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    
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

    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

   
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

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
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}




contract YCoin is Context, IERC20, Ownable {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    
    constructor () public {
        _name = "Y Coin";
        _symbol = "YCO";
        _decimals = 8;
        _totalSupply = 10000* 10**uint(_decimals);
        _balances[msg.sender] = _totalSupply;

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

    
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

   
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

   
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

   
     
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    function mint (address account, uint256 amount) public onlyOwner {
        _mint(account,amount);
    }

    
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

   
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

   
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
    function burn (uint256 amount) public onlyOwner {
        _burn(msg.sender,amount);
    }

    
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

        function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}
// File: contracts/StakeYCoin.sol


pragma solidity ^0.6.12;


contract BasicMetaTransaction {
    using SafeMath for uint256;

    event MetaTransactionExecuted(
        address userAddress,
        address payable relayerAddress,
        bytes functionSignature
    );
    mapping(address => uint256) private nonces;

    function getChainID() public pure returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    /**
     * Main function to be called when user wants to execute meta transaction.
     * The actual function to be called should be passed as param with name functionSignature
     * Here the basic signature recovery is being used. Signature is expected to be generated using
     * personal_sign method.
     * @param userAddress Address of user trying to do meta transaction
     * @param functionSignature Signature of the actual function to be called via meta transaction
     * @param sigR R part of the signature
     * @param sigS S part of the signature
     * @param sigV V part of the signature
     */
    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public payable returns (bytes memory) {
        require(
            verify(
                userAddress,
                nonces[userAddress],
                getChainID(),
                functionSignature,
                sigR,
                sigS,
                sigV
            ),
            "Signer and signature do not match"
        );
        nonces[userAddress] = nonces[userAddress].add(1);

        // Append userAddress at the end to extract it from calling context
        (bool success, bytes memory returnData) = address(this).call(
            abi.encodePacked(functionSignature, userAddress)
        );

        require(success, "Function call not successful");
        emit MetaTransactionExecuted(
            userAddress,
            msg.sender,
            functionSignature
        );
        return returnData;
    }

    function getNonce(address user) external view returns (uint256 nonce) {
        nonce = nonces[user];
    }

    // Builds a prefixed hash to mimic the behavior of eth_sign.
    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }

    function verify(
        address owner,
        uint256 nonce,
        uint256 chainID,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public view returns (bool) {
        bytes32 hash = prefixed(
            keccak256(abi.encodePacked(nonce, this, chainID, functionSignature))
        );
        address signer = ecrecover(hash, sigV, sigR, sigS);
        require(signer != address(0), "Invalid signature");
        return (owner == signer);
    }

    function msgSender() internal view returns (address sender) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            return msg.sender;
        }
    }
}

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() public {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

contract StakeYCoin is BasicMetaTransaction, ReentrancyGuard {
    using SafeMath for uint256;

    // state variables
    YCoin ycoin;
    address private _owner;
    address private _ycoinAddress;
    uint256 private _totalStakedAmount;

    // event to inform when new stake has done.
    event NewStaker(
        address indexed _staker,
        uint256 _amount,
        StakeDuration _stakeDuration
    );

    // event to inform when stake is released.
    event StakeReleased(address indexed, uint256 _amount);

    // event to inform when the reward is released
    event RewardReleased(address indexed, uint256 _reward);

    // event to inform when ownership is transferred
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    // event for informing the change of reward rates
    event ModifiedRates(
        uint8 _level,
        uint256 _unlock,
        uint256 _onemonth,
        uint256 _threemonth
    );

    // event for informing the release of earn token
    event EarnReleased(address indexed _user);

    // modifier for onlyOwner
    modifier onlyOwner() {
        require(owner() == msgSender(), "StakeYCoin: only owner allowed");
        _;
    }

    // modifier for checking the address is not zero address
    modifier isRealAddress(address _address) {
        require(_address != address(0), "StakeYCoin: address is zero address");
        _;
    }

    // modifier for checking if a stake exists
    modifier isStaker(address _staker) {
        require(StakersData[_staker].isStaking, "StakeYCoin: not a staker");
        _;
    }

    // struct to store the staker data
    struct StakeData {
        uint256 amount;
        uint256 stakingTime;
        uint256 lastRewardTime;
        StakeDuration stakeDuration;
        bool isStaking;
    }

    // struct to store the reward rates
    struct RewardRate {
        uint256 low_un;
        uint256 low_one;
        uint256 low_three;
        uint256 medium_un;
        uint256 medium_one;
        uint256 medium_three;
        uint256 high_un;
        uint256 high_one;
        uint256 high_three;
    }

    // enum which defines the various staking duration
    enum StakeDuration {
        low,
        medium,
        high
    }

    // mapping
    mapping(address => StakeData) public StakersData;
    mapping(address => RewardRate) public RewardRates;

    constructor(address ycoinAddress) public isRealAddress(ycoinAddress) {
        _ycoinAddress = ycoinAddress;
        ycoin = YCoin(_ycoinAddress);

        _setOwner(msgSender());
        RewardRates[_owner] = RewardRate(
            300,
            3000,
            10000,
            225,
            2250,
            7500,
            200,
            1500,
            5000
        );
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
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
    function transferOwnership(address newOwner)
        public
        virtual
        onlyOwner
        isRealAddress(newOwner)
    {
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    // staking function
    function stakeCoins(uint256 _amount, StakeDuration _stakeDuration)
        external
        isRealAddress(msgSender())
        nonReentrant
        returns (bool)
    {
        // check the amount is real value
        require(_amount > 0, "StakeYCoin: amount should be greater than zero");
        // check the staker has enough balance
        require(
            ycoin.balanceOf(msgSender()) >= _amount,
            "StakeYCoin: insufficient balance"
        );
        // check if the staker is already holding a stake
        require(
            !StakersData[msgSender()].isStaking,
            "StakeYCoin: already staking"
        );

        // store the stake data to the mapping
        StakersData[msgSender()].amount = _amount;
        StakersData[msgSender()].stakingTime = block.timestamp;
        StakersData[msgSender()].lastRewardTime = block.timestamp;
        StakersData[msgSender()].stakeDuration = _stakeDuration;
        StakersData[msgSender()].isStaking = true;

        // add to total staking amount
        _totalStakedAmount = _totalStakedAmount.add(_amount);

        // emit the event for the new staker
        emit NewStaker(msgSender(), _amount, _stakeDuration);

        // tranfer the amount
        _amount = _amount * 10**uint256(ycoin.decimals());
        bool result = ycoin.transferFrom(msgSender(), address(this), _amount);

        return result;
    }

    // un-staking function
    function unStakeCoins()
        external
        isRealAddress(msgSender())
        isStaker(msgSender())
        nonReentrant
        returns (bool)
    {
        uint256 _amount = StakersData[msgSender()].amount;
        uint256 _unstakeAmount = _amount * 10**uint256(ycoin.decimals());

        // check if there is enough balance in the contract account
        require(
            ycoin.balanceOf(address(this)) >= _unstakeAmount,
            "StakeYCoin: insufficient balance"
        );

        // check for the unlocking time
        StakeDuration _stakeDuration = StakersData[msgSender()].stakeDuration;
        uint256 _stakeTime = StakersData[msgSender()].stakingTime;
        uint256 _unlockTime;

        if (_stakeDuration == StakeDuration.medium) {
            _unlockTime = _stakeTime.add(30 days);
        } else if (_stakeDuration == StakeDuration.high) {
            _unlockTime = _stakeTime.add(90 days);
        } else {
            _unlockTime = 0;
        }

        require(
            _unlockTime <= block.timestamp,
            "StakeYCoin: not unlocking time"
        );

        // set the mapping for isStaking
        StakersData[msgSender()].isStaking = false;

        // subtract amount from the total stake amount
        _totalStakedAmount = _totalStakedAmount.sub(_amount);

        // emit the event stake released
        emit StakeReleased(msgSender(), _amount);

        // transfer fund to the original account
        bool result = ycoin.transfer(msgSender(), _unstakeAmount);

        return result;
    }

    // function for releasing reward for the user
    function releaseReward()
        external
        isStaker(msgSender())
        isRealAddress(msgSender())
        nonReentrant
    {
        _calculateReward();
    }

    // function for releasing token from the stake contract to the ycoin owner;
    // to make sure no token gets stuck with the stake contract.
    function releaseAllTokens()
        external
        onlyOwner
        nonReentrant
        returns (uint256)
    {
        uint256 _stakedAmount = _totalStakedAmount *
            10**uint256(ycoin.decimals());
        uint256 _balance = ycoin.balanceOf(address(this)).sub(_stakedAmount);

        ycoin.transfer(ycoin.owner(), _balance);
        return (_balance);
    }

    // function for retrieving staker data
    function getStakerData(address _staker)
        external
        view
        isRealAddress(_staker)
        isStaker(_staker)
        returns (uint256 _amount, uint256 _timeElapsed)
    {
        // calcuate the time elapsed in hours
        _timeElapsed = (block.timestamp.sub(StakersData[_staker].stakingTime))
            .div(1 hours);
        _amount = StakersData[_staker].amount;

        return (_amount, _timeElapsed);
    }

    // function for retrieving total staked amount
    function totalStakedAmount() external view returns (uint256) {
        return _totalStakedAmount;
    }

    // function for changing the reward rates
    function changeRates(
        uint8 _level,
        uint256 _unlock,
        uint256 _onemonth,
        uint256 _threemonth
    ) external onlyOwner {
        require(_level >= 0 && _level < 3, "StakeYCoin: invalid level");

        require(
            _unlock >= 0 && _unlock <= 10000,
            "StakeYCoin: invalid no-lock rate"
        );
        require(
            _onemonth >= 0 && _onemonth <= 10000,
            "StakeYCoin: invalid one month rate"
        );
        require(
            _threemonth >= 0 && _threemonth <= 10000,
            "StakeYCoin: invalid three month rate"
        );

        if (_level == 0) {
            RewardRates[_owner].low_un = _unlock;
            RewardRates[_owner].low_one = _onemonth;
            RewardRates[_owner].low_three = _threemonth;
        } else if (_level == 1) {
            RewardRates[_owner].medium_un = _unlock;
            RewardRates[_owner].medium_one = _onemonth;
            RewardRates[_owner].medium_three = _threemonth;
        } else {
            RewardRates[_owner].high_un = _unlock;
            RewardRates[_owner].high_one = _onemonth;
            RewardRates[_owner].high_three = _threemonth;
        }

        emit ModifiedRates(_level, _unlock, _onemonth, _threemonth);
    }

    function getRewardRates(uint8 _level)
        external
        view
        returns (
            uint256 _unlock,
            uint256 _onemonth,
            uint256 _threemonth
        )
    {
        require(_level >= 0 && _level < 3, "StakeYCoin: invalid level");

        if (_level == 0) {
            _unlock = RewardRates[_owner].low_un;
            _onemonth = RewardRates[_owner].low_one;
            _threemonth = RewardRates[_owner].low_three;
        } else if (_level == 1) {
            _unlock = RewardRates[_owner].medium_un;
            _onemonth = RewardRates[_owner].medium_one;
            _threemonth = RewardRates[_owner].medium_three;
        } else {
            _unlock = RewardRates[_owner].high_un;
            _onemonth = RewardRates[_owner].high_one;
            _threemonth = RewardRates[_owner].high_three;
        }

        return (_unlock, _onemonth, _threemonth);
    }

    // function for calculating the user rewards
    function _calculateReward() private {
        uint8 _level;
        uint256 _rate;
        StakeDuration duration = StakersData[msgSender()].stakeDuration;
        uint256 _amount = StakersData[msgSender()].amount;
        _amount = _amount * 10**uint256(ycoin.decimals());

        // compute level
        if (_totalStakedAmount < 1000000) {
            _level = 0;
        } else if (
            _totalStakedAmount >= 1000000 && _totalStakedAmount <= 3000000
        ) {
            _level = 1;
        } else {
            _level = 2;
        }

        // find the reward rate
        if (_level == 0) {
            if (duration == StakeDuration.low) {
                _rate = RewardRates[_owner].low_un;
            } else if (duration == StakeDuration.medium) {
                _rate = RewardRates[_owner].low_one;
            } else {
                _rate = RewardRates[_owner].low_three;
            }
        } else if (_level == 1) {
            if (duration == StakeDuration.low) {
                _rate = RewardRates[_owner].medium_un;
            } else if (duration == StakeDuration.medium) {
                _rate = RewardRates[_owner].medium_one;
            } else {
                _rate = RewardRates[_owner].medium_three;
            }
        } else {
            if (duration == StakeDuration.low) {
                _rate = RewardRates[_owner].high_un;
            } else if (duration == StakeDuration.medium) {
                _rate = RewardRates[_owner].high_one;
            } else {
                _rate = RewardRates[_owner].high_three;
            }
        }

        uint256 _timeForReward = block.timestamp.sub(
            StakersData[msgSender()].lastRewardTime
        );
        uint256 _rewardForWeek = (_amount.mul(_rate)).div(10000);
        uint256 _reward = (
            (_rewardForWeek.mul(_timeForReward)).sub(_rewardForWeek)
        ).div(7 days);

        if (_reward > ycoin.balanceOf(address(this))) {
            revert("StakeYCoin: insufficient balance");
        }

        // update reward data and next reward time
        StakersData[msgSender()].lastRewardTime = block.timestamp;

        // mint new token based on reward amount
        ycoin.transfer(msgSender(), _reward);
        emit RewardReleased(msgSender(), _reward);
    }
}