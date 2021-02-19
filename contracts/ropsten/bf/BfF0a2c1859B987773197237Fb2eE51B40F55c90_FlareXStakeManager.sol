/**
 *Submitted for verification at Etherscan.io on 2021-02-19
*/

//SPDX-License-Identifier: None
pragma solidity =0.8.1;

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

interface IERC20Permit is IERC20 {
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

contract FlareXStakeManager { 
    using SafeMath for uint;

    struct Checkpoint {
        uint fromBlock;
        uint votes;
    }

    IERC20Permit public immutable stakingToken;
    uint public totalSupply;
    
    mapping (address => uint) public balanceOf;
    mapping (address => mapping (uint => Checkpoint)) public checkpoints;
    mapping (address => uint) public numCheckpoints;

    event StakeVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

    constructor(address _stakingToken) { 
        stakingToken = IERC20Permit(_stakingToken);
    }

    function getCurrentVotes(address account) external view returns (uint) {
        uint nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    function getPriorVotes(address account, uint blockNumber) public view returns (uint) {
        require(blockNumber < block.number, "FlareXGovernorYFLR_V1: not yet determined");

        uint nCheckpoints = numCheckpoints[account];
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

        uint lower = 0;
        uint upper = nCheckpoints - 1;
        while (upper > lower) {
            uint center = upper - (upper - lower) / 2; // ceil, avoiding overflow
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

    function stake(uint amount) external {
        require(amount > 0, "FlareXGovernorYFLR_V1: amount is zero");
        _stake(amount);
    }

    function stakeWithPermit(uint amount, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(amount > 0, "LockStakingRewardFixedAPY: Cannot stake 0");
        // permit
        stakingToken.permit(msg.sender, address(this), amount, deadline, v, r, s);
        _stake(amount);
    }

    function _stake(uint amount) private {
        stakingToken.transferFrom(msg.sender, address(this), amount);
        balanceOf[msg.sender] = balanceOf[msg.sender].add(amount);
        totalSupply = totalSupply.add(amount);
        
        uint dstRepNum = numCheckpoints[msg.sender];
        uint dstRepOld = dstRepNum > 0 ? checkpoints[msg.sender][dstRepNum - 1].votes : 0;
        uint dstRepNew = dstRepOld.add(amount);
        _writeCheckpoint(msg.sender, dstRepNum, dstRepOld, dstRepNew);
    }

    function withdraw(uint amount, address recipient) external {
        require(amount > 0, "FlareXGovernorYFLR_V1: amount is zero");
        stakingToken.transfer(recipient, amount);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(amount);
        totalSupply = totalSupply.sub(amount);
        
        uint srcRepNum = numCheckpoints[msg.sender];
        uint srcRepOld = srcRepNum > 0 ? checkpoints[msg.sender][srcRepNum - 1].votes : 0;
        uint srcRepNew = srcRepOld.sub(amount);
        _writeCheckpoint(msg.sender, srcRepNum, srcRepOld, srcRepNew);
    }

    function _writeCheckpoint(address user, uint nCheckpoints, uint oldVotes, uint newVotes) internal {
      uint blockNumber = block.number;

      if (nCheckpoints > 0 && checkpoints[user][nCheckpoints - 1].fromBlock == blockNumber) {
          checkpoints[user][nCheckpoints - 1].votes = newVotes;
      } else {
          checkpoints[user][nCheckpoints] = Checkpoint(blockNumber, newVotes);
          numCheckpoints[user] = nCheckpoints + 1;
      }

      emit StakeVotesChanged(user, oldVotes, newVotes);
    }
}