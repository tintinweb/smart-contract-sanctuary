//SourceUnit: PoolOne.sol

pragma solidity ^0.5.0;
library Math {
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

pragma solidity ^0.5.0;
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

pragma solidity ^0.5.0;
contract Context {
    constructor () internal {}
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }
    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}


pragma solidity ^0.5.0;
contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


pragma solidity ^0.5.0;


interface IERC20 {

    function totalSupply() external view returns (uint256);


    function balanceOf(address account) external view returns (uint256);


    function transfer(address recipient, uint256 amount) external returns (bool);


    function allowance(address owner, address spender) external view returns (uint256);


    function approve(address spender, uint256 amount) external returns (bool);

    function burn(uint256 amount) external;


    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);


    event Approval(address indexed owner, address indexed spender, uint256 value);
}


pragma solidity ^0.5.5;


library Address {

    function isContract(address account) internal view returns (bool) {

        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly {codehash := extcodehash(account)}
        return (codehash != 0x0 && codehash != accountHash);
    }


    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }


    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success,) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}


pragma solidity ^0.5.0;


library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }


    function callOptionalReturn(IERC20 token, bytes memory data) private {

        require(address(token).isContract(), "SafeERC20: call to non-contract");

        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


pragma solidity ^0.5.0;


contract LPTokenWrapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public y = IERC20(0x412F294A54DE8F37A2682AED4138709A7C35CA5D58);


    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function stake(uint256 amount) internal {
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        y.safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount) internal {
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        y.safeTransfer(msg.sender, amount);
    }
}
pragma solidity ^0.5.5;

interface IMembers {
    function getInviter(address _msgSender) external view returns (address);
    function setInviter(address sender, address _inviter) external;
    function getReffersLength(address account) external view returns(uint256);
}

interface MotherPool {
    function balanceOf(address account) external view returns (uint256) ;
}

pragma solidity ^0.5.5;
contract PoolOneReward is LPTokenWrapper {

    IMembers members = IMembers(0x413D0BA8706774F2BF5C7413B7B058188B3AE5696D);
    MotherPool motherPool = MotherPool(0x413310540FB3AA3DF3DCC79DC0C8D3F727598EC612);
    IERC20 public rewardToken = IERC20(0x412F294A54DE8F37A2682AED4138709A7C35CA5D58);
    address myaddress = address(0x413CD8602F4DB1F4214B8E1809C16D7A6601754CD8) ;
    uint256[3] refBonus = [20, 30, 50] ;

    uint256 public starttime = 1634025600;
    uint256 public lastUpdateTime;
    mapping(address => uint256)public referrers ; 
    mapping(address => uint256)public stakeTime ; 
    mapping(address => uint256) public rewards;
    

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);


    constructor() public {
    }

    uint256 timelong = 10 * 24 * 3600 ;
    uint256 totalRate = 6 ;

    function earned(address account) public view returns (uint256) {
        uint256 time = block.timestamp.sub(stakeTime[account]);
        if(time > timelong) {
            time = timelong ;
        }
        uint256 balance = balanceOf(account);
        return
        balance
        .mul(1e6).mul(totalRate)
        .mul(time)
        .div(100).div(timelong).div(1e6).add(rewards[account]) ;
    }

    function stake(uint256 amount,address ref) public checkStart {
        require(amount >= 100 * 1e6, "stake must >= 100");
        require(balanceOf(msg.sender) == 0, "Can stake once only");

        uint256 motherBalance = motherPool.balanceOf(msg.sender);
        require(motherBalance > 0, "Mother pool stake required");

        stakeTime[msg.sender] = block.timestamp;
        super.stake(amount);

        address m = members.getInviter(msg.sender);
        if(m == address(0) && ref != msg.sender && ref != address(0)){
          members.setInviter(msg.sender, ref);
        }

        emit Staked(msg.sender, amount);
    }

    function withdraw() internal {
        uint256 amount = balanceOf(msg.sender) ;
        require(amount > 0, "Cannot withdraw 0");
        require(block.timestamp > stakeTime[msg.sender] + timelong, "Lock time");

        rewards[msg.sender] = earned(msg.sender);
        super.withdraw(amount);
        emit Withdrawn(msg.sender, amount);
    }

    function exit() external {
        withdraw();
        getReward();
    }

    function getReward() internal {

        require(block.timestamp > stakeTime[msg.sender] + timelong, "Lock time");

        uint256 reward = rewards[msg.sender];
        rewards[msg.sender] = 0 ;
        if (reward > 0) {
            require(rewardToken.balanceOf(address(this)) > 0, "getReward: total SE is zero");
            if (rewardToken.balanceOf(address(this)) <= reward) {
                reward = rewardToken.balanceOf(address(this));
            }

            rewardToken.safeTransfer(msg.sender, reward);

            //referrer
            address u = members.getInviter(msg.sender);
            if(u != address(0) && u != address(0x410000000000000000000000000000000000000000)){
              for(uint256 i = 0;i<refBonus.length;i++){
                uint256 amount = reward.mul(refBonus[i]).div(100);
                if(balanceOf(u) > 0){
                    rewardToken.safeTransfer(u, amount);
                    referrers[u] = referrers[u].add(amount);
                }else{
                    rewardToken.safeTransfer(myaddress, amount);
                }

                u = members.getInviter(u);
                if(u == address(0) || u == address(0x410000000000000000000000000000000000000000)){
                  break;
                }
              }
            }

            emit RewardPaid(msg.sender, reward);
        }
    }

    modifier checkStart(){
        require(block.timestamp > starttime, "not start");
        _;
    }

}