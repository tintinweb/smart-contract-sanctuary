//SourceUnit: Chef.sol

pragma solidity >= 0.5.6;

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
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
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

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, 'SafeMath: modulo by zero');
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

interface iERC20 {

    function totalSupply()external view returns(uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);

    function increaseAllowance(address spender, uint addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint subtractedValue) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract KOwnerable {

    address public owner;

    modifier onlyOwner() {
        require(owner == msg.sender, "NotAuther");
        _;
    }

    modifier KRejectContractCall() {
        uint256 size;
        address payable safeAddr = msg.sender;
        assembly {
            size := extcodesize(safeAddr)
        }
        require(size == 0, "Sender Is Contract");
        _;
    }
}

contract KStoragePayable is KOwnerable {
    address public KImplementAddress;

    function SetKImplementAddress(address impl) external onlyOwner {
        KImplementAddress = impl;
    }

    function() external payable {
        address impl_address = KImplementAddress;
        assembly {
            if eq(calldatasize(), 0) {
                return(0, 0)
            }

            calldatacopy(0x0, 0x0, calldatasize())
            let success := delegatecall(
                gas(),
                impl_address,
                0x0,
                calldatasize(),
                0,
                0
            )
            let retSz := returndatasize()
            returndatacopy(0, 0, retSz)
            switch success
                case 0 {
                    revert(0, retSz)
                }
                default {
                    return(0, retSz)
                }
        }
    }
}

pragma experimental ABIEncoderV2;

contract ChefStorage is KStoragePayable{
    using SafeMath for uint256;

    address constant public rootAddress = address(0x000000000000000000000000000000000000dEaD);

    uint public totalAddresses;
    
    mapping (address => address) public _recommerMapping;


    struct UserInfo {
        uint256 amount;
        uint256 award;
        uint256 shareAward;
        uint256 rewardDebt;
    }

    struct PoolInfo {
        iERC20 lpToken;
        uint256 cakePerBlock;
        uint256 lastRewardBlock;
        uint256 accCakePerShare;
        uint256 apy;
    }

    iERC20 public mineToken;

    PoolInfo[] public poolInfo;
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event Draw(address indexed user, uint256 indexed pid, uint256 amount);


    uint internal shareConfig = 10;

    constructor(
        address _mineToken,
        address _ownerAddress
    ) public {
        _recommerMapping[rootAddress] = address(0xdeaddead);
        mineToken = iERC20(_mineToken);
        owner = _ownerAddress;
    }
}

contract MasterChef is ChefStorage(address(0),address(0)){

    function setCakePerBlock(uint index,uint cakePerBlock)external onlyOwner{
        poolInfo[index].cakePerBlock = cakePerBlock;
    }

    function addRelationEx(address recommer) external returns (bool) {

        require(recommer != msg.sender,"your_self");

        require(_recommerMapping[msg.sender] == address(0x0),"binded");

        require(recommer == rootAddress || _recommerMapping[recommer] != address(0x0),"p_not_bind");

        totalAddresses++;

        _recommerMapping[msg.sender] = recommer;
        return true;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }


    function add(uint256 _startBlock, address _lpToken, uint256 _cakePerBlock) public onlyOwner {

        uint256 lastRewardBlock = block.number > _startBlock ? block.number : _startBlock;

        poolInfo.push(PoolInfo(
            iERC20(_lpToken),
            _cakePerBlock,
            lastRewardBlock,
            0,
            0
        ));
    }


    function getMultiplier(uint256 _from, uint256 _to) internal pure returns (uint256) {
        return _to.sub(_from);
    }

    function pendingCake(uint256 _pid, address _user) external view returns (uint256,uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];

        uint256 accCakePerShare = pool.accCakePerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));

        if (block.number > pool.lastRewardBlock && lpSupply != 0) {

            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);

            uint256 cakeReward = multiplier.mul(pool.cakePerBlock);
            accCakePerShare = accCakePerShare.add(cakeReward.mul(1e12).div(lpSupply));
        }
        return (user.amount.mul(accCakePerShare).div(1e12).sub(user.rewardDebt) + user.award,user.shareAward);
    }

    function updatePool(uint256 _pid) internal {
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
        uint256 cakeReward = multiplier.mul(pool.cakePerBlock);

        pool.accCakePerShare = pool.accCakePerShare.add(cakeReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    function deposit(uint256 _pid, uint256 _amount) public {

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);

        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accCakePerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                user.award += pending;
            }
        }

        if (_amount > 0) {
            pool.lpToken.transferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accCakePerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    function withdraw(uint256 _pid, uint256 _amount) public {

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");

        updatePool(_pid);

        uint256 pending = user.amount.mul(pool.accCakePerShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0) {
            user.award += pending;
        }

        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.transfer(address(msg.sender), _amount);
        }

        user.rewardDebt = user.amount.mul(pool.accCakePerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    function draw(uint256 _pid) external returns(uint award) {

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        updatePool(_pid);

        uint256 pending = user.amount.mul(pool.accCakePerShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0) {
            user.award += pending;
        }

        user.rewardDebt = user.amount.mul(pool.accCakePerShare).div(1e12);

        award = user.award;

        if( award > 0 ){
            user.award = 0;
            mineToken.transfer(msg.sender,award);

            address parent = _recommerMapping[msg.sender];

            if( parent != rootAddress && parent != address(0)){
                uint sa = award * shareConfig / 100;
                userInfo[_pid][parent].shareAward += sa;
            }
        }
        emit Draw(msg.sender, _pid, award);
    }

    function getShareAward(address user)external view returns(uint v){

        uint len = poolInfo.length;

        for( uint i = 0; i < len; i++ ){
            v += userInfo[i][user].shareAward;
        }
    }

    function drawShare() external {

        uint len = poolInfo.length;

        uint v = 0;
        for( uint i = 0; i < len; i++ ){

            uint award = userInfo[i][msg.sender].shareAward;

            if( award > 0 ){
                userInfo[i][msg.sender].shareAward = 0;
                v += award;
            }
        }

        if( v > 0 ){
            mineToken.transfer(msg.sender,v);
        }
    }
}