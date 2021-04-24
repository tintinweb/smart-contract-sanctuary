/**
 *Submitted for verification at Etherscan.io on 2021-04-24
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IERC20 {
    function balanceOf(address) external returns (uint256);

    // some tokens (like USDT) are not returning bool as ERC20 standard require
    function transfer(address, uint256) external;

    // we will not check for return value because lots of non-erc20 complaints (like USDT)
    function transferFrom(
        address,
        address,
        uint256
    ) external;

    function allowance(address, address) external returns (uint256);
}

contract UniqStaking {
    // Info of each user in pool
    struct UserInfo {
        uint256 depositTime;
        bool bonus;
    }

    // Info about staking pool
    struct PoolInfo {
        uint256 slots;
        uint256 stakeValue;
        uint256 closeTime; // last call to stake
        uint256 usedSlots;
        uint256 lockPeriod; // stake length
        address token;
        string image;
        string name;
    }

    address public owner;
    address public newOwner;

    // Info of each pool.
    PoolInfo[] private _poolInfo;

    // Info of each user that stakes.
    // [stake no][user]=UserInfo
    mapping(uint256 => mapping(address => UserInfo)) private _userInfo;

    // how many tokens users stake
    mapping(address => uint256) private _userStake;

    event Deposit(
        address indexed user,
        uint256 indexed pid,
        uint256 amount,
        uint256 timeout
    );
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);

    string private _baseURI;

    constructor(string memory baseURI) {
        _baseURI = baseURI;
        owner = msg.sender;
    }

    /**
    @dev Return the length of pool array.
    */
    function getPoolCount() external view returns (uint256) {
        return _poolInfo.length;
    }

    /**
    @dev Return current number of holders in a pool
     */
    function getSlotsCount(uint256 _pid) external view returns (uint256) {
        return _poolInfo[_pid].usedSlots;
    }

    function poolInfo(uint256 _pid) external view returns (PoolInfo memory) {
        return _poolInfo[_pid];
    }

    function userInfo(uint256 _pid, address user)
        external
        view
        returns (UserInfo memory)
    {
        return _userInfo[_pid][user];
    }

    // how long until user can withdraw from stake
    function getCountdown(address user, uint256 id)
        external
        view
        returns (uint256)
    {
        uint256 ts = _userInfo[id][user].depositTime + _poolInfo[id].lockPeriod;
        if (block.timestamp > ts) {
            return 0;
        } else {
            return ts - block.timestamp;
        }
    }

    // return full pool gift URL
    function stakingGift(uint256 id) external view returns (string memory) {
        return string(abi.encodePacked(_baseURI, _poolInfo[id].image));
    }

    /**
    Open a new staking pool, starting now.
    @param _slots: max number of stake users
    @param _stake: min token required
    @param _duration: lifetime of a pool in seconds
    @param _lockPeriod: time to stake (in seconds)
    @param _image: URL of image gift
    @param _name: staking name
   */
    function addStakePool(
        uint256 _slots,
        uint256 _stake,
        address _token,
        uint256 _duration,
        uint256 _lockPeriod,
        string calldata _image,
        string calldata _name
    ) external onlyOwner {
        _poolInfo.push(
            PoolInfo({
                slots: _slots,
                stakeValue: _stake,
                closeTime: block.timestamp + _duration,
                usedSlots: 0,
                lockPeriod: _lockPeriod,
                token: _token,
                image: _image,
                name: _name
            })
        );
    }

    /**
    Transfer ERC-20 token from sender's account to staking contract. 
   */
    function deposit(uint256 _pid, uint256 _amount) external {
        PoolInfo storage pool = _poolInfo[_pid];
        UserInfo storage user = _userInfo[_pid][msg.sender];

        // check if selected Pool restrictions are met
        require(block.timestamp < pool.closeTime, "Already closed");
        require(pool.usedSlots < pool.slots, "Pool is already full");
        require(user.depositTime == 0, "User already in staking pool");
        require(_amount == pool.stakeValue, "Needs exact stake");

        user.depositTime = block.timestamp;
        pool.usedSlots += 1;

        // move fund and update records
        IERC20(pool.token).transferFrom(
            address(msg.sender),
            address(this),
            _amount
        );

        // store amount
        _userStake[pool.token] += _amount;

        // emit event
        emit Deposit(
            msg.sender,
            _pid,
            _amount,
            pool.lockPeriod + block.timestamp
        );
    }

    /**
    Returns full funded amount of ERC-20 token to requester if lock period is over
   */
    function withdraw(uint256 _pid) external {
        PoolInfo storage pool = _poolInfo[_pid];
        UserInfo storage user = _userInfo[_pid][msg.sender];

        // check if caller is a stakeholder of the current pool
        require(user.depositTime > 0, "Not stakeholder");

        // check if lock period is over
        require(
            block.timestamp > user.depositTime + pool.lockPeriod,
            "Still locked"
        );

        // no double withdrawal
        require(user.bonus == false, "Already withdrawn");

        // make user happy
        user.bonus = true;

        // return fund
        IERC20(pool.token).transfer(address(msg.sender), pool.stakeValue);

        // reduce stored amount
        _userStake[pool.token] -= pool.stakeValue;

        // emit proper event
        emit Withdraw(msg.sender, _pid, pool.stakeValue);
    }

    function pastStakes(address user) external view returns (uint256[] memory) {
        uint256 max = _poolInfo.length;
        if (max == 0) {
            return new uint256[](0);
        }
        // need temporary storage
        // solidity disallow size changes
        uint256[] memory tmp = new uint256[](max);
        uint256 found;
        for (uint256 i = 0; i < max; i++) {
            if (_userInfo[i][user].bonus) {
                tmp[found] = i;
                found += 1;
            }
        }
        // copy to output
        uint256[] memory stakes = new uint256[](found);
        for (uint256 i = 0; i < found; i++) {
            stakes[i] = tmp[i];
        }
        return stakes;
    }

    function currentStakes(address user)
        external
        view
        returns (uint256[] memory)
    {
        uint256 max = _poolInfo.length;
        if (max == 0) {
            return new uint256[](0);
        }
        uint256[] memory tmp = new uint256[](max);
        uint256 found;
        for (uint256 i = 0; i < max; i++) {
            if (
                _userInfo[i][user].depositTime > 0 &&
                _userInfo[i][user].bonus == false
            ) {
                tmp[found] = i;
                found += 1;
            }
        }
        // copy to output
        uint256[] memory stakes = new uint256[](found);
        for (uint256 i = 0; i < found; i++) {
            stakes[i] = tmp[i];
        }
        return stakes;
    }

    function acceptOwnership() external {
        require(
            msg.sender != address(0) && msg.sender == newOwner,
            "Only NewOwner"
        );
        newOwner = address(0);
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only for contract Owner");
        _;
    }

    function changeOwner(address _newOwner) external onlyOwner {
        newOwner = _newOwner;
    }

    // Update baseURI for pool gifts
    function updateUri(string calldata uri) external onlyOwner {
        _baseURI = uri;
    }

    /**
    @dev Function to recover accidentally send ERC20 tokens
    @param _token ERC20 token address
    */
    function rescueERC20(address _token) external onlyOwner {
        uint256 amt = IERC20(_token).balanceOf(address(this));
        // leave users stake
        amt -= _userStake[_token];
        require(amt > 0, "Nothing to rescue");
        IERC20(_token).transfer(owner, amt);
    }

    /**
    @dev Function to recover any ETH send to contract
    */
    function rescueETH() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
}