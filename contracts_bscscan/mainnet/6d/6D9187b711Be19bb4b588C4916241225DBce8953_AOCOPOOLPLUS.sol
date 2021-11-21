/**
 *Submitted for verification at BscScan.com on 2021-11-21
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'e0');
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, 'e0');
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, 'e0');
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'e0');
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}


interface IBEP20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}


library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, 'e0');
        (bool success,) = recipient.call{value : amount}('');
        require(success, 'e1');
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, 'e0');
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, 'e0');
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, 'e0');
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), 'e0');
        (bool success, bytes memory returndata) = target.call{value : weiValue}(data);
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
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

library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;
    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, 'e0');
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), 'e1');
        }
    }
}

contract Context {
    constructor() internal {}
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), 'e0');
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'e0');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface Token {
    function mint(address _to, uint256 _amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
}


contract AOCOPOOLPLUS is Ownable {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    struct PoolInfo {
        IBEP20 lpToken;
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 accCakePerShare;
        bool pool_status;
        uint256 staking_stock_length;
        bool if_tuijian_reward;
    }

    Token public cake;
    address public devaddr;
    uint256 public cakePerBlock;
    uint256 public stakingFee = 0;
    uint256 public withdrawFee = 0;
    uint256 public getRewardFee = 0;
    uint256 public BONUS_MULTIPLIER = 1;
    PoolInfo[] public poolInfo;
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    uint256 public totalAllocPoint = 0;
    uint256 public startBlock;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    mapping(uint256 => mapping(address => uint256)) public first_staking_time;
    mapping(uint256 => mapping(address => uint256)) public last_staking_time;
    mapping(address => address) public tuijianren;
    mapping(address => bool) public is_tuijianren;
    mapping(uint256 => mapping(address => uint256)) public pending_list;
    mapping(address => bool) public white_list;

    constructor(
    ) public {
        devaddr = msg.sender;
        startBlock = block.number;
        totalAllocPoint = 0;
    }

    function setWhiteList(address[] memory _address_list) public onlyOwner {
        for (uint256 i = 0; i < _address_list.length; i++) {
            white_list[_address_list[i]] = true;
        }
    }

    function setFees(uint256 _stakingFee, uint256 _withdrawFee, uint256 _getRewardFee) public onlyOwner {
        require(_stakingFee < 50 && _withdrawFee < 50 && _getRewardFee < 50, 'e0');
        stakingFee = _stakingFee;
        withdrawFee = _withdrawFee;
        getRewardFee = _getRewardFee;
    }

    function removeWhiteList(address[] memory _address_list) public onlyOwner {
        for (uint256 i = 0; i < _address_list.length; i++) {
            white_list[_address_list[i]] = false;
        }
    }

    function setStartBlock(uint256 _startBlock) public onlyOwner {
        startBlock = _startBlock;
    }

    function setCakePerBlockAndCake(uint256 _cakePerBlock, Token _cake) public onlyOwner {
        cake = _cake;
        cakePerBlock = _cakePerBlock;
    }

    function updateMultiplier(uint256 multiplierNumber) public onlyOwner {
        BONUS_MULTIPLIER = multiplierNumber;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function add(uint256 _allocPoint, IBEP20 _lpToken, bool _withUpdate, uint256 _staking_stock_length, bool _if_tuijian_reward) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
        lpToken : _lpToken,
        allocPoint : _allocPoint,
        lastRewardBlock : lastRewardBlock,
        accCakePerShare : 0,
        pool_status : true,
        staking_stock_length : _staking_stock_length,
        if_tuijian_reward : _if_tuijian_reward
        }));
        updateStakingPool();
    }

    function set(uint256 _pid, uint256 _allocPoint, IBEP20 _lpToken, bool _withUpdate, uint256 _staking_stock_length, bool _if_tuijian_reward) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        uint256 prevAllocPoint = poolInfo[_pid].allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].lpToken = _lpToken;
        poolInfo[_pid].staking_stock_length = _staking_stock_length;
        poolInfo[_pid].if_tuijian_reward = _if_tuijian_reward;
        if (prevAllocPoint != _allocPoint) {
            updateStakingPool();
        }
    }

    function enablePool(uint256 _pid) public onlyOwner {
        poolInfo[_pid].pool_status = true;
    }

    function disablePool(uint256 _pid) public onlyOwner {
        poolInfo[_pid].pool_status = false;
    }

    function updateStakingPool() internal {
        uint256 length = poolInfo.length;
        uint256 points = 0;
        for (uint256 pid = 1; pid < length; ++pid) {
            points = points.add(poolInfo[pid].allocPoint);
        }
        if (points != 0) {
            points = points.div(3);
            totalAllocPoint = totalAllocPoint.sub(poolInfo[0].allocPoint).add(points);
            poolInfo[0].allocPoint = points;
        }
    }

    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    function pendingCake(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accCakePerShare = pool.accCakePerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 cakeReward = multiplier.mul(cakePerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accCakePerShare = accCakePerShare.add(cakeReward.mul(1e12).div(lpSupply));
        }
        if (!pool.if_tuijian_reward || (pool.if_tuijian_reward && tuijianren[_user] == address(0))) {
            return (user.amount.mul(accCakePerShare).div(1e12).sub(user.rewardDebt)).add(pending_list[_pid][_user]);}
        else {
            return ((user.amount.mul(accCakePerShare).div(1e12).sub(user.rewardDebt)).add(pending_list[_pid][_user])).mul(99).div(100);
        }
    }

    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 cakeReward = multiplier.mul(cakePerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        //cake.mint(devaddr, cakeReward.div(10));
        cake.mint(address(this), cakeReward);
        pool.accCakePerShare = pool.accCakePerShare.add(cakeReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    function deposit(uint256 _pid, uint256 _amount, address tuijian) public {
        if (first_staking_time[_pid][msg.sender] == 0) {
            first_staking_time[_pid][msg.sender] = block.number;
        }
        if (tuijianren[msg.sender] == address(0) && tuijian != address(0) && tuijian != msg.sender && !is_tuijianren[msg.sender]) {
            tuijianren[msg.sender] = tuijian;
            is_tuijianren[tuijian] = true;
        }
        last_staking_time[_pid][msg.sender] = block.number;

        require(poolInfo[_pid].pool_status == true, 'e0');
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accCakePerShare).div(1e12).sub(user.rewardDebt);
            if (pending > 0) {
                pending_list[_pid][msg.sender] = pending_list[_pid][msg.sender].add(pending);
                //safeCakeTransfer(msg.sender, pending);
            }
        }
        if (_amount > 0) {
            uint256 fee = _amount.mul(stakingFee).div(100);
            uint256 left = _amount.sub(fee);
            if (fee > 0) {
                pool.lpToken.safeTransferFrom(address(msg.sender), devaddr, fee);
            }
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), left);
            user.amount = user.amount.add(left);
        }
        user.rewardDebt = user.amount.mul(pool.accCakePerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }


    function getReward(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (!white_list[msg.sender]) {
            require(block.number > last_staking_time[_pid][msg.sender] + pool.staking_stock_length, 'time limit');
        }
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accCakePerShare).div(1e12).sub(user.rewardDebt);
            if (pending > 0) {
                pending_list[_pid][msg.sender] = pending_list[_pid][msg.sender].add(pending);
            }
        }
        user.rewardDebt = user.amount.mul(pool.accCakePerShare).div(1e12);
        emit Deposit(msg.sender, _pid, 0);
        require(pending_list[_pid][msg.sender] > 0, 'e0');
        if (tuijianren[msg.sender] == address(0))
        {
            safeCakeTransfer(msg.sender, pending_list[_pid][msg.sender]);
        } else {
            uint256 all_reward = pending_list[_pid][msg.sender];
            uint256 fee = all_reward.mul(getRewardFee).div(100);
            uint256 left = all_reward.sub(fee);
            if (pool.if_tuijian_reward) {
                safeCakeTransfer(tuijianren[msg.sender], fee);
                safeCakeTransfer(msg.sender, left);
            } else {
                safeCakeTransfer(msg.sender, pending_list[_pid][msg.sender]);
            }
        }
        pending_list[_pid][msg.sender] = 0;
    }

    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "e0");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accCakePerShare).div(1e12).sub(user.rewardDebt);
        if (pending > 0) {
            pending_list[_pid][msg.sender] = pending_list[_pid][msg.sender].add(pending);
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            uint256 fee = _amount.mul(withdrawFee).div(100);
            uint256 left = _amount.sub(fee);
            if (fee > 0) {
                pool.lpToken.safeTransfer(devaddr, fee);
            }
            pool.lpToken.safeTransfer(address(msg.sender), left);
        }
        user.rewardDebt = user.amount.mul(pool.accCakePerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 fee = user.amount.mul(withdrawFee).div(100);
        uint256 left = user.amount.sub(fee);
        if (fee > 0) {
            pool.lpToken.safeTransfer(devaddr, fee);
        }
        pool.lpToken.safeTransfer(address(msg.sender), left);
        emit EmergencyWithdraw(msg.sender, _pid, left);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    function safeCakeTransfer(address _to, uint256 _amount) internal {
        uint256 cakeBal = cake.balanceOf(address(this));
        if (_amount > cakeBal) {
            cake.transfer(_to, cakeBal);
        } else {
            cake.transfer(_to, _amount);
        }
    }

    function setdev(address _devaddr) public {
        require(msg.sender == devaddr || msg.sender == owner(), "e0");
        devaddr = _devaddr;
    }
}