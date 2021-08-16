pragma solidity 0.6.12;

import "./IBEP20.sol";
import "./SafeBEP20.sol";
import "./EnumerableSet.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./LibToken.sol";

contract LibStaking is Ownable {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;
    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many Lib tokens the user has provided.
        uint256 rewardDebt; 
    }
    // Info of each pool.
    uint256 public lastRewardBlock; // Last block number that SUSHIs distribution occurs.
    uint256 public accLibPerShare; // Accumulated LIBs per share.
    LibToken public lib;
    address public devaddr;
    uint256 public libPerBlock;//= 10*10**18;
    //1000000000000000000 978473581213
    uint256 public blockPerYear = 10220000;
    // Info of each user that stakes LP tokens.
    mapping(address => UserInfo) public userInfo;
    uint256 public startBlock;
    uint256 public lpSupply;
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 amount
    );
    constructor(
        address _lib,
        address _devaddr
    ) public {
        lib = LibToken(_lib);
        devaddr = _devaddr;
        lastRewardBlock= 1;
        accLibPerShare=0;

    }
    function setBlockPerYear(uint256 _blockPerYear)public onlyOwner{
        blockPerYear = _blockPerYear;
    }
    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256){
        return _to.sub(_from);
    }

    // View function to see pending LIBs on frontend.
    function pendingLib(address _user)
        external
        view
        returns (uint256)
    {
        UserInfo storage user = userInfo[_user];
        uint256 _accLibPerShare = accLibPerShare;
        if (block.number > lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(lastRewardBlock, block.number);
            uint256 libReward =  multiplier.mul(libPerBlock);
            _accLibPerShare = accLibPerShare.add(
                libReward.mul(1e12).div(lpSupply)
            );
        }
        return user.amount.mul(_accLibPerShare).div(1e12).sub(user.rewardDebt);
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool() public {
        if (block.number <= lastRewardBlock) {
            return;
        }
        if (lpSupply == 0) {
            lpSupply = lib.balanceOf(address(this));
            lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(lastRewardBlock, block.number);
        uint256 libReward = multiplier.mul(libPerBlock);

        lib.mint(address(this),libReward);
        accLibPerShare = accLibPerShare.add(
            libReward.mul(1e12).div(lpSupply)
        );
        lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterChef for SUSHI allocation.
    function deposit( uint256 _amount) public {
        UserInfo storage user = userInfo[msg.sender];
        updatePool();
        lpSupply = lpSupply.add(_amount);
        libPerBlock = lpSupply.div(blockPerYear).div(10);
        lib.transferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(accLibPerShare).div(1e12);

        emit Deposit(msg.sender, _amount);
    }
 
    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _amount) public {
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool();
        lpSupply = lpSupply.sub(_amount);
        libPerBlock = lpSupply.div(blockPerYear).div(10);
        uint256 pending =
            user.amount.mul(accLibPerShare).div(1e12).sub(
                user.rewardDebt
            );
        user.amount = user.amount.sub(_amount);
        safeLibreTransfer(msg.sender, pending);
        user.rewardDebt = user.amount.mul(accLibPerShare).div(1e12);
        lib.transfer(address(msg.sender), _amount);

        emit Withdraw(msg.sender, _amount);
    }

    // Safe sushi transfer function, just in case if rounding error causes pool to not have enough Libres.
    function safeLibreTransfer(address _to, uint256 _amount) internal {
        uint256 libBal = lib.balanceOf(address(this));
        if (_amount > libBal) {
            lib.transfer(_to, libBal);
        } else {
            lib.transfer(_to, _amount);
        }
    }

    // Update dev address by the previous dev.
    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
    }
}