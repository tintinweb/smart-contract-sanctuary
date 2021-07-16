//SourceUnit: EverStakePool.sol

// SPDX-License-Identifier: UNLICENSED
/*
https://everin.one/
*/
pragma solidity >=0.5.8 <=0.5.14;



interface ITRC20 {
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
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

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Context {

    constructor() internal {}
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );


    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }


    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library TransferHelper {

    function safeTransfer(ITRC20 token, address to, uint value) internal returns (bool){
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0xa9059cbb, to, value));
        return (success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function safeTransferFrom(ITRC20 token, address from, address to, uint value) internal returns (bool){
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        return (success && (data.length == 0 || abi.decode(data, (bool))));
    }
}

contract EverStakePool is Ownable {
    using SafeMath for uint256;
    using TransferHelper for ITRC20;
    //using Address for address payable;

    struct UserInfo {
        uint32 id;
        uint256 initial_block;
        uint256 stake_amount;
    }
    struct PoolInfo {
        uint256 daily_income;
        uint256 total_stake;
    }

    mapping(uint32 => PoolInfo) public poolInfo;
    mapping(address => UserInfo) public usersInfo;

    ITRC20 public lpEverToken;
    uint256 public startBlock;
    uint256 public periodDuration; //86400;//1200 * 72 h
    uint256 public usersInStake;

    event Stake(uint256 period, address indexed user, uint256 amount);
    event PoolCharged(uint256 period, uint256 amount);
    event UnStake(uint256 period, address indexed user, uint256 amount);
    event Dividends(uint256 period, address indexed user, uint256 amount);

    constructor(
        address _lpEverToken,
        address _matrixesOwner,
        uint256 _periodDuration
    ) public {
        lpEverToken = ITRC20(_lpEverToken);
        startBlock = block.number;
        periodDuration = _periodDuration;
        usersInStake = 0;
        UserInfo memory user =
            UserInfo({id: 1, initial_block: 0, stake_amount: 0});
        usersInfo[_matrixesOwner] = user;
    }

    function() external payable {
        chargePool();
    }

    function stake(uint256 _amount) external {
        require(
            isUserExists(msg.sender),
            "user is not exists. Register first."
        );
        require(_amount > 0, "amount must be greater than 0");
        require(
            usersInfo[msg.sender].stake_amount == uint256(0),
            "you already have staked tokens, unstake first"
        );
        require(
            lpEverToken.allowance(address(msg.sender), address(this)) >=
                _amount,
            "Increase the allowance first,call the approve method"
        );

        require(lpEverToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        ));
        usersInfo[msg.sender].initial_block = block.number;
        uint32 period = blockToPeriod(usersInfo[msg.sender].initial_block);
        poolInfo[period].total_stake = lpEverToken.balanceOf(address(this));

        if (usersInStake == 0) {
            usersInfo[msg.sender].stake_amount = lpEverToken.balanceOf(
                address(this)
            );
            emit Stake(period, msg.sender, usersInfo[msg.sender].stake_amount);
            poolInfo[period].daily_income = address(this).balance;
            emit PoolCharged(period, poolInfo[period].daily_income);
        } else {
            usersInfo[msg.sender].stake_amount = _amount;
            emit Stake(period, msg.sender, _amount);
        }
        usersInStake++;
    }

    function isTokensFrozen(address userAddress) public view returns (bool) {
        return (periodDuration >
            (block.number.sub(usersInfo[userAddress].initial_block)));
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw()external {
        require(
            usersInfo[msg.sender].stake_amount > 0,
            "you do not have staked tokens, stake first"
        );
        require(isTokensFrozen(msg.sender) == false, "tokens are frozen");

        uint32 period = getCurrentPeriod();
        uint256 unstake_amount = usersInfo[msg.sender].stake_amount;
        usersInfo[msg.sender].stake_amount = 0;
        usersInfo[msg.sender].initial_block = block.number.add(1); 
        poolInfo[period].total_stake = lpEverToken.balanceOf(address(this)).sub(
            unstake_amount
        );
        usersInStake--;
        require(lpEverToken.safeTransfer(address(msg.sender), unstake_amount));
        emit UnStake(period, msg.sender, unstake_amount);

    }

    function unstake() external {
        require(
            usersInfo[msg.sender].stake_amount > 0,
            "you do not have staked tokens, stake first"
        );
        require(isTokensFrozen(msg.sender) == false, "tokens are frozen");

        uint256 dividends_amount = calculateDividends(msg.sender);

        if (dividends_amount > address(this).balance) {
            dividends_amount = address(this).balance;
        }

        uint32 period = getCurrentPeriod();
        uint256 unstake_amount = usersInfo[msg.sender].stake_amount;
        usersInfo[msg.sender].stake_amount = 0;
        usersInfo[msg.sender].initial_block = block.number.add(1);
        poolInfo[period].total_stake = lpEverToken.balanceOf(address(this)).sub(
            unstake_amount
        );
        usersInStake--;
        require(lpEverToken.safeTransfer(address(msg.sender), unstake_amount));
        if (dividends_amount > 0) {
            address(uint160(msg.sender)).transfer(dividends_amount);
            emit Dividends(period, msg.sender, dividends_amount);
        }
        emit UnStake(period, msg.sender, unstake_amount);
    }

    function getDividends() external {
        require(
            usersInfo[msg.sender].stake_amount > 0,
            "you do not have staked tokens, stake first"
        );
        uint256 dividends_amount = calculateDividends(msg.sender);
        require(
            dividends_amount>0,
            "The current available dividends is zero."
        );
        if (dividends_amount > address(this).balance) {
            dividends_amount = address(this).balance;
        }
        if (dividends_amount > 0) {
            uint256 period = getCurrentPeriod();
            usersInfo[msg.sender].initial_block = block.number.add(1);
            address(uint160(msg.sender)).transfer(dividends_amount);
            emit Dividends(period, msg.sender, dividends_amount);
        }
    }

    function calculateDividends(address userAddress)
        public
        view
        returns (uint256)
    {
        require(
            isUserExists(userAddress),
            "user is not exists. Register first."
        );
        UserInfo storage user = usersInfo[userAddress];
        uint256 dividends = 0;
        if (user.stake_amount > 0) {
            uint32 i = blockToPeriod(user.initial_block);
            uint32 end = getCurrentPeriod();
            for (i; i < end; i++) {
                if (poolInfo[i].daily_income > 0) {
                    uint256 dailyCharge = poolInfo[i].daily_income.mul(1e12)
                    .div(poolInfo[i].total_stake).mul(user.stake_amount).div(1e12);
                    dividends = dividends.add(
                        dailyCharge < poolInfo[i].daily_income
                            ? dailyCharge
                            : poolInfo[i].daily_income
                    );
                }
            }
        }

        return dividends;
    }

    function createUser(address userAddress, uint32 userID) external onlyOwner {
        UserInfo memory user =
            UserInfo({id: userID, initial_block: 0, stake_amount: 0});
        usersInfo[userAddress] = user;
    }

    function isUserExists(address userAddress) public view returns (bool) {
        return (usersInfo[userAddress].id != 0);
    }

    function getPool(uint32 period) external view returns (string memory, string memory) {
        return (uint2str(poolInfo[period].daily_income), uint2str(poolInfo[period].total_stake));
    }

    function getUser(address userAddress)
        external
        view
        returns (string memory, string memory)
    {
        return (
            uint2str(usersInfo[userAddress].initial_block),
            uint2str(usersInfo[userAddress].stake_amount)
        );
    }

    function getCurrentPeriod() public view returns (uint32) {
        return uint32(block.number.sub(startBlock).div(periodDuration));
    }

    function blockToPeriod(uint256 blockNumb) public view returns (uint32) {
        return uint32(blockNumb.sub(startBlock).div(periodDuration));
    }

    function chargePool() public payable {
        if (usersInStake > 0) {
            uint32 period = getCurrentPeriod();
            poolInfo[period].daily_income = poolInfo[period].daily_income.add(
                msg.value
            );
            poolInfo[period].total_stake = lpEverToken.balanceOf(address(this));
            emit PoolCharged(period, msg.value);
        }
    }

    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len - 1;
        while (_i != 0) {
            bstr[k--] = bytes1(uint8(48 + (_i % 10)));
            _i /= 10;
        }
        return string(bstr);
    }
}