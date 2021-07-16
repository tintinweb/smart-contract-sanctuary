//SourceUnit: Context.sol

pragma solidity 0.5.12;

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
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/trxeum/solidity/issues/2691
        return msg.data;
    }
}


//SourceUnit: Ownable.sol

pragma solidity 0.5.12;

import './Context.sol';

// File: @openzeppelin/contracts/access/Ownable.sol

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
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
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
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
        require(
            newOwner != address(0),
            'Ownable: new owner is the zero address'
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


//SourceUnit: RET.sol

pragma solidity 0.5.12;

import './Ownable.sol';
import './SafeMath.sol';

contract RET is Ownable {
    using SafeMath for uint256;

    /// @notice EIP-20 token name for this token
    string public constant name = 'RET Token';

    /// @notice EIP-20 token symbol for this token 
    string public constant symbol = 'RET';

    /// @notice EIP-20 token decimals for this token
    uint8 public constant decimals = 12;

    /// @notice Total number of tokens in circulation
    uint256 private _totalSupply = 0;

    uint256 private _maxSupply = 269000 * 10 ** uint256(decimals); // 269k Token

    mapping(address => mapping(address => uint256)) internal allowances;

    mapping(address => uint256) internal balances;

    /// @notice A record of each accounts delegate
    mapping(address => address) public delegates;

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint256 fromBlock;
        uint256 votes;
    }

    /// @notice A record of votes checkpoints for each account, by index
    mapping(address => mapping(uint256 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping(address => uint256) public numCheckpoints;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256(
        'EIP712Domain(string name,address verifyingContract)'
    );

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH = keccak256(
        'Delegation(address delegatee,uint256 nonce,uint256 expiry)'
    );

    /// @notice A record of states for signing / validating signatures
    mapping(address => uint256) public nonces;

    /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(
        address indexed delegator,
        address indexed fromDelegate,
        address indexed toDelegate
    );

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(
        address indexed delegate,
        uint256 previousBalance,
        uint256 newBalance
    );

    /// @notice The standard EIP-20 transfer event
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /// @notice The standard EIP-20 approval event
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address _to, uint256 _amount) internal {
        require(_to != address(0), 'RET::_mint: mint to the zero address');

        _totalSupply = _totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(address(0), _to, _amount);

        _moveDelegates(address(0), delegates[_to], _amount);
    }

    function mint(address _to, uint256 amount) public onlyOwner returns (bool) {
        require(_totalSupply.add(amount, 'RET::mint: mint amount overflows') <= _maxSupply, 'RET::mint: max supply exceeded');
        _mint(_to, amount);
        return true;
    }

    /**
     * @notice Get the number of tokens `spender` is approved to spend on behalf of `account`
     * @param account The address of the account holding the funds
     * @param spender The address of the account spending the funds
     * @return The number of tokens approved
     */
    function allowance(address account, address spender)
        external
        view
        returns (uint256)
    {
        return allowances[account][spender];
    }

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.trxeum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param amount The number of tokens that are approved (2^256-1 means infinite)
     * @return Whtrx or not the approval succeeded
     */
    function approve(address spender, uint256 amount)
        external
        returns (bool)
    {
        allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /**
     * @notice Get the number of tokens held by the `account`
     * @param account The address of the account to get the balance of
     * @return The number of tokens held
     */
    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    /**
     * @notice Get total supply
     * @return Total supply
     */
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @notice Get maximum supply
     * @return Maximum supply
     */
    function maxSupply() external view returns (uint256) {
        return _maxSupply;
    }

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whtrx or not the transfer succeeded
     */
    function transfer(address dst, uint256 amount) external returns (bool) {
        _transferTokens(msg.sender, dst, amount);
        return true;
    }

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whtrx or not the transfer succeeded
     */
    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external returns (bool) {
        address spender = msg.sender;
        uint256 spenderAllowance = allowances[src][spender];

        if (spender != src && spenderAllowance != uint256(-1)) {
            uint256 newAllowance = spenderAllowance.sub(amount);
            allowances[src][spender] = newAllowance;

            emit Approval(src, spender, newAllowance);
        }

        _transferTokens(src, dst, amount);
        return true;
    }

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegatee The address to delegate votes to
     */
    function delegate(address delegatee) public {
        return _delegate(msg.sender, delegatee);
    }

    /**
     * @notice Delegates votes from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        bytes32 domainSeparator = keccak256(
            abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), address(this))
        );
        bytes32 structHash = keccak256(
            abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry)
        );
        bytes32 digest = keccak256(
            abi.encodePacked('\x19\x01', domainSeparator, structHash)
        );
        address signatory = ecrecover(digest, v, r, s);
        require(
            signatory != address(0),
            'RET::delegateBySig: invalid signature'
        );
        require(
            nonce == nonces[signatory]++,
            'RET::delegateBySig: invalid nonce'
        );
        require(block.timestamp <= expiry, 'RET::delegateBySig: signature expired');
        return _delegate(signatory, delegatee);
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account) external view returns (uint256) {
        uint256 nCheckpoints = numCheckpoints[account];
        return
            nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint256 blockNumber)
        public
        view
        returns (uint256)
    {
        require(
            blockNumber < block.number,
            'RET::getPriorVotes: not yet determined'
        );

        uint256 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint256 lower = 0;
        uint256 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint256 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function _delegate(address delegator, address delegatee) internal {
        address currentDelegate = delegates[delegator];
        uint256 delegatorBalance = balances[delegator];
        delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _transferTokens(
        address src,
        address dst,
        uint256 amount
    ) internal {
        require(
            src != address(0),
            'RET::_transferTokens: cannot transfer from the zero address'
        );
        require(
            dst != address(0),
            'RET::_transferTokens: cannot transfer to the zero address'
        );

        balances[src] = balances[src].sub(amount, 'RET::_transferTokens: transfer amount exceeds balance');
        balances[dst] = balances[dst].add(amount, 'RET::_transferTokens: transfer amount overflows');
        emit Transfer(src, dst, amount);

        _moveDelegates(delegates[src], delegates[dst], amount);
    }

    function _moveDelegates(
        address srcRep,
        address dstRep,
        uint256 amount
    ) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                uint256 srcRepNum = numCheckpoints[srcRep];
                uint256 srcRepOld = srcRepNum > 0
                    ? checkpoints[srcRep][srcRepNum - 1].votes
                    : 0;
                uint256 srcRepNew = srcRepOld.add(amount, 'RET::_moveVotes: vote amount underflows');
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                uint256 dstRepNum = numCheckpoints[dstRep];
                uint256 dstRepOld = dstRepNum > 0
                    ? checkpoints[dstRep][dstRepNum - 1].votes
                    : 0;
                uint256 dstRepNew = dstRepOld.add(amount, 'RET::_moveVotes: vote amount overflows');
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(
        address delegatee,
        uint256 nCheckpoints,
        uint256 oldVotes,
        uint256 newVotes
    ) internal {
        uint256 blockNumber = block.number;

        if (
            nCheckpoints > 0 &&
            checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber
        ) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(
                blockNumber,
                newVotes
            );
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }
}


//SourceUnit: RETStakingPlatform.sol

pragma solidity >=0.5.12;

import "./RET.sol";

contract RETStakingPlatform is Ownable {
    using SafeMath for uint256;

    RET public rewardToken;

    uint256 private _lastMintTime;
    uint256 private _totalStaked = 0;
    uint256 private _totalClaim = 0;
    uint256 private _platformFees = 0;
    uint256 private _DevFee = 0;
    uint256 private _mintedCurrentLevel = 0;

    uint256 constant REWARD_INTERVAL = 1 days;

    uint256 constant REF_REWARD_PERCENT = 10;

    uint256 constant UNSTAKE_FEE = 10;

    uint256[11] public levelChangeTime;

    uint256[] public LEVEL_LIMIT = [
        60000 * 10e12,
        40000 * 10e12,
        30000 * 10e12,
        25000 * 10e12,
        18000 * 10e12,
        10000 * 10e12,
        7000 * 10e12,
        0
    ];

    uint256[] public LEVEL_YIELD = [
       
        5571429,
        3466667,
        3120000,
        3095238,
        2925000,
        2600000,
        2275000,
        0
    ];

    // take fee from unstake fee. (div 10)
    uint256[] public DEV_FEE = [
        100,
        75,
        60,
        50,
        40,
        30,
        20,
        0
    ];
    
    
    uint256[] public MINING_DURATION = [
        7,
        10,
        10,
        10,
        10,
        10,
        10,
        0

];
    uint256 public _currentLevel = 0;

    address payable devadr = address(0x5b3c0F6A2Cd0F4853e3663D67621c46626c11fB2);
    address payable teamadr = address(0x266cb2678bd4Fa6d13AF7b06Ce46792f95067e2B);
    
    // Info of each user.
    struct User {
        uint256 investment;
        uint256 lastClaim;
        uint256 lastStake;
        address referrer;
        uint256 referralReward;
        uint256 totalReferrals;
        uint256 pendingToken;
        uint256 tokenClaimed;
        address addr;
        bool exists;
        
        Deposit[] deposits;
    }
    struct Deposit {
        uint256 amount;
        uint256 price;
        uint256 numOfToken;
        uint40 time;
        uint256 duration;
        bool enable;
        bool unstake;
        bool mint;
    }


    mapping(address => User) private _users;

    event Operation(
        string _type,
        address indexed _user,
        address indexed _referrer,
        uint256 _amount
    );

    event LevelChanged(uint256 _newLevel, uint256 _timestamp);
    event SendFees(address _from, address _team, uint256 _amount);
    event NewReferral(string _for, address indexed _user, address _referral);
    event ReferralReward(
        address indexed _referrer,
        address indexed _user,
        uint256 _amount
    );
    event ClaimStaked(
        address indexed _user,
        address indexed _referrer,
        uint256 _amount
    );
    event ClaimReferral( address indexed _user, uint256 _amount);

    constructor(RET _rewardToken) public {
        User storage user = _users[msg.sender];
        user.exists = true;
        user.addr = msg.sender;
        user.investment = 0;
        user.referrer = msg.sender;
        user.lastClaim = block.timestamp;

        _lastMintTime = block.timestamp;
        rewardToken = _rewardToken;
    }
    
    function toString(address account) internal pure returns(string memory) {
    return toString(abi.encodePacked(account));
    }
    
    function toString(uint256 value) internal pure returns(string memory) {
        return toString(abi.encodePacked(value));
    }
    
    function toString(bytes32 value) internal pure returns(string memory) {
        return toString(abi.encodePacked(value));
    }
    
    function toString(bytes memory data) internal pure returns(string memory) {
        bytes memory alphabet = "0123456789abcdef";
    
        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint i = 0; i < data.length; i++) {
            str[2+i*2] = alphabet[uint(uint8(data[i] >> 4))];
            str[3+i*2] = alphabet[uint(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }
    function stake() public payable {
        stake(msg.sender);
    }

    function stake(address _referrer) public payable {

        require(msg.sender!=owner(),"Owner can't stake");
        require(msg.value>=100e6,"Min 100 TRX");
        
        _stake( _referrer, msg.value);
        
    }


    function _stake(
        address _referrer,
        uint256 _amount
    ) private {
        
        

        address referrer = _referrer == address(0x0) ? owner() : _referrer;
        if (!_users[referrer].exists) {
            referrer = owner();
        }

        User storage user = _users[msg.sender];
        if (!user.exists) {
            user.exists = true;
            user.addr = msg.sender;
            user.referrer = referrer;
            user.investment = _amount;
            user.lastClaim = block.timestamp;
            user.lastStake = block.timestamp;

            _users[referrer].totalReferrals = _users[referrer]
                .totalReferrals
                .add(1);
            
            user.deposits.push(Deposit({
                amount: msg.value,
                price: LEVEL_YIELD[_currentLevel],
                numOfToken: msg.value.mul(LEVEL_YIELD[_currentLevel]).div(1000000),
                duration: MINING_DURATION[_currentLevel],
                time: uint40(block.timestamp),
                enable:true,
                mint:true,
                unstake:false
                
            }));

            emit NewReferral(toString(referrer),referrer, user.addr);
        } else {
            
            user.lastStake = block.timestamp;
            user.investment = user.investment.add(_amount);
            user.deposits.push(Deposit({
                amount: msg.value,
                price: LEVEL_YIELD[_currentLevel],
                numOfToken: msg.value.mul(LEVEL_YIELD[_currentLevel]).div(1000000),
                duration: MINING_DURATION[_currentLevel],
                time: uint40(block.timestamp),
                enable:true,
                mint:true,
                unstake:false
                
            }));
        }
        _totalStaked = _totalStaked.add(_amount);
        uint256 Fees = _amount.mul(UNSTAKE_FEE).div(100);
        uint256 DevFee = Fees.mul(DEV_FEE[_currentLevel]).div(1000);
        uint256 TeamFee = Fees.sub(DevFee);

        _DevFee = _DevFee.add(DevFee);

        _platformFees = _platformFees.add(TeamFee);
        _mintTokens();
        devadr.transfer(DevFee);
        teamadr.transfer(TeamFee);


        emit SendFees(msg.sender,devadr,DevFee);
        emit SendFees(msg.sender,teamadr,TeamFee);
        emit ReferralReward(user.referrer,msg.sender, msg.value.mul(LEVEL_YIELD[_currentLevel]).div(1000000).mul(REF_REWARD_PERCENT).div(100));
        emit Operation('stake', msg.sender, user.referrer, _amount);
    }

    function unstake() public {

        User storage user = _users[msg.sender];
        uint256 _amount = user.investment;

        require(user.exists, 'Invalid User');
        
        for(uint256 i = 0; i < user.deposits.length; i++) {
            Deposit storage dep = user.deposits[i];
            dep.enable = false;
            dep.unstake = true;
            
        }
        _claimStaked();
    
        user.investment = user.investment.sub(
            _amount,
            'RETStake::unstake: Insufficient funds'
        );

        safeSendValue(msg.sender, _amount.mul(uint256(100).sub(UNSTAKE_FEE)).div(100));

        emit Operation('unstake', user.addr, user.referrer, _amount);
    }



    function claimStaked() public {
        _claimStaked();
    }

    function claimReferralReward() public {
        
        User storage user = _users[msg.sender];
        uint256 refReward = user.referralReward;
        user.referralReward = 0;
        safeTokenTransfer(user.addr, refReward);
        emit ClaimReferral(msg.sender, refReward);
    }

    function _mintTokens() private {
       
       
        User storage user = _users[msg.sender];
        
        uint256 toMint = 0;
        for(uint256 i = 0; i < user.deposits.length; i++) {
            Deposit storage dep = user.deposits[i];
            if(dep.mint){
            toMint = toMint.add(dep.numOfToken).mul(dep.duration);
            toMint = toMint.add(dep.numOfToken.mul(dep.duration).mul(REF_REWARD_PERCENT).div(100));
            //add spare 1%
            toMint = toMint.add(dep.numOfToken.mul(dep.duration).mul(1).div(100));
            dep.mint = false;
            
            _users[user.referrer].referralReward = _users[user.referrer]
            .referralReward
            .add(dep.numOfToken.mul(dep.duration).mul(REF_REWARD_PERCENT).div(100));
            }
        }
        
            _mintedCurrentLevel = _mintedCurrentLevel.add(toMint);
            
            uint256 tokenTotalSupply = rewardToken.totalSupply();
            // If cap is reached mint as much as possible
            if (tokenTotalSupply.add(toMint) > rewardToken.maxSupply()) {
                toMint = rewardToken.maxSupply().sub(tokenTotalSupply);
            }
            rewardToken.mint(address(this), toMint);
            if (
                _mintedCurrentLevel >= LEVEL_LIMIT[_currentLevel] &&
                _currentLevel < (LEVEL_LIMIT.length - 1)
            ) {
                levelChangeTime[_currentLevel] = block.timestamp;
                _currentLevel++;
                _mintedCurrentLevel = 0;
                emit LevelChanged(_currentLevel, block.timestamp);
            }
        
        _lastMintTime = block.timestamp;
    }

    function _claimStaked() internal {
        User storage user = _users[msg.sender];

        require(user.exists, 'Invalid User');

        uint256 reward = pendingReward(msg.sender);

        user.lastClaim = block.timestamp;
        user.tokenClaimed = user.tokenClaimed.add(reward);
        
        safeTokenTransfer(user.addr, reward);

        emit ClaimStaked(user.addr, user.referrer, reward);
    }

    function pendingReward() public view returns (uint256) {
        return pendingReward(msg.sender);
    }

    function pendingReward(address _address)
        public
        view
        returns (uint256 reward)
    {
        User memory user = _users[_address];
        uint256 lastClaim = user.lastClaim;
        
        for(uint256 i = 0; i < user.deposits.length; i++) {
            Deposit storage dep = _users[_address].deposits[i];

            uint256 time_end = dep.time+ dep.duration*86400;
            uint256 from = lastClaim> dep.time ? lastClaim : dep.time;
            uint256 to = block.timestamp > time_end ? time_end : uint40(block.timestamp);

            if(from < to) {
                if(dep.enable){
                reward = reward.add(
                    dep
                        .amount
                        .mul(to.sub(from))
                        .div(REWARD_INTERVAL)
                        .mul(dep.price)
                        .div(1000000)
                );
            }
            }
        }
        return reward;
        
    }




    function stats() view public returns (
        uint256 currentLevel,
        uint256 currentLevelYield,
        uint256 currentLevelSupply,
        uint256 mintedCurrentLevel,
        uint256 totalRET,
        uint256 totalStaked,
        uint256 platformFees,
        uint256 DevFee,
        uint256 Balance,
        uint256 time
    ) {
        currentLevel = _currentLevel;
        currentLevelYield = LEVEL_YIELD[_currentLevel];
        currentLevelSupply = LEVEL_LIMIT[_currentLevel];
        mintedCurrentLevel = _mintedCurrentLevel;
        totalStaked = _totalStaked;
        totalRET = rewardToken.totalSupply();
        platformFees = _platformFees;
        DevFee = _DevFee;
        Balance = address(this).balance;
        time = block.timestamp;
    }

    function user() view public returns (
        uint256, uint256, uint256,address,  uint256, uint256, uint256, uint256, uint256
    ) {
        return user(msg.sender);
    }

    function user(address _address) view public returns (
        uint256 investment,
        uint256 lastClaim,
        uint256 lastStake,
        address referrer,
        uint256 referralReward,
        uint256 totalReferrals,
        uint256 pendingRewards,
        uint256 tokenBalance,
        uint256 balance
    ) {
        investment = _users[_address].investment;
        lastClaim = _users[_address].lastClaim;
        lastStake = _users[_address].lastStake;
        referrer = _users[_address].referrer;
        referralReward = _users[_address].referralReward;
        totalReferrals = _users[_address].totalReferrals;
        pendingRewards = pendingReward(_address);
        tokenBalance = rewardToken.balanceOf(_address);
        balance = _address.balance;
    }


    function safeTokenTransfer(address _to, uint256 _amount) internal returns (uint256 amount) {
        uint256 balance = rewardToken.balanceOf(address(this));
        amount = (_amount > balance) ? balance : _amount;

        rewardToken.transfer(_to, _amount);
    }

    function safeSendValue(address payable _to, uint256 _amount) internal returns (uint256 amount) {
        amount = (_amount < address(this).balance) ? _amount : address(this).balance;
        _to.transfer(_amount);
    }
    
    function transferRETOwner(address _newOwner)public onlyOwner returns(bool) {
       rewardToken.transferOwnership(_newOwner);
       return(true);
    }
}


//SourceUnit: SafeMath.sol

pragma solidity 0.5.12;

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
     *
     * - Addition cannot overflow.
     */
    function add(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);

        return c;
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
        return add(a, b, 'SafeMath: addition overflow');
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
        return sub(a, b, 'SafeMath: subtraction overflow');
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
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
     *
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
        require(c / a == b, 'SafeMath: multiplication overflow');

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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
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
     *
     * - The divisor cannot be zero.
     */
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