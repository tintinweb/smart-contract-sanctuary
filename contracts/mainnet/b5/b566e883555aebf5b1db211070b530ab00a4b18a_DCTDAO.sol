/**
 *Submitted for verification at Etherscan.io on 2021-02-10
*/

pragma solidity =0.6.6;
contract DCTDAO {
    string public constant name = "DCTDAO";
    string public constant symbol = "DCTD";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;

    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) internal allowances;
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;
    mapping (address => uint32) public numCheckpoints;

    struct Checkpoint {
        uint32 fromBlock;
        uint256 balance;
    }

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    constructor () public {
        mint(address(msg.sender), 10000000 * 1e18);
    }

    function mint(address _account, uint256 _number) internal {
        balances[_account] = _number;
        totalSupply += _number;
        emit Transfer(address(0), _account, _number);
        _moveDelegates(address(0), _account, _number);
    }

    function allowance(address account, address spender) external view returns (uint) {
        return allowances[account][spender];
    }

    function approve(address spender, uint256 rawAmount) external returns (bool) {
        uint256 amount;
        if (rawAmount == uint256(-1)) {
            amount = uint256(-1);
        } else {
            amount = safe256(rawAmount, "DCTD::approve: amount exceeds 256 bits");
        }

        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function balanceOf(address account) external view returns (uint) {
        return balances[account];
    }

    function transfer(address dst, uint rawAmount) external returns (bool) {
        uint256 amount = safe256(rawAmount, "DCTD::transfer: amount exceeds 256 bits");
        _transferTokens(msg.sender, dst, amount);
        return true;
    }

    function transferFrom(address src, address dst, uint rawAmount) external returns (bool) {
        address spender = msg.sender;
        uint256 spenderAllowance = allowances[src][spender];
        uint256 amount = safe256(rawAmount, "DCTD::approve: amount exceeds 256 bits");

        if (spender != src && spenderAllowance != uint256(-1)) {
            uint256 newAllowance = sub256(spenderAllowance, amount, "DCTD::transferFrom: transfer amount exceeds spender allowance");
            allowances[src][spender] = newAllowance;
            emit Approval(src, spender, newAllowance);
        }

        _transferTokens(src, dst, amount);
        return true;
    }

    function _transferTokens(address src, address dst, uint256 amount) internal {
        require(src != address(0), "DCTD::_transferTokens: cannot transfer from the zero address");
        require(dst != address(0), "DCTD::_transferTokens: cannot transfer to the zero address");

        balances[src] = sub256(balances[src], amount, "DCTD::_transferTokens: transfer amount exceeds balance");
        balances[dst] = add256(balances[dst], amount, "DCTD::_transferTokens: transfer amount overflows");

        emit Transfer(src, dst, amount);
        _moveDelegates(src, dst, amount);
    }

    function _moveDelegates(address srcRep, address dstRep, uint256 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint256 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].balance : 0;
                uint256 srcRepNew = sub256(srcRepOld, amount, "DCTD::_moveDelegates: amount underflows");
                _writeCheckpoint(srcRep, srcRepNum, srcRepNew);
            }

            if (dstRep != address(0)) {
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint256 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].balance : 0;
                uint256 dstRepNew = add256(dstRepOld, amount, "DCTD::_moveDelegates: amount overflows");
                _writeCheckpoint(dstRep, dstRepNum, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(address account, uint32 nCheckpoints, uint256 newBalance) internal {
      uint32 blockNumber = safe32(block.number, "DCTD::_writeCheckpoint: block number exceeds 32 bits");

      if (nCheckpoints > 0 && checkpoints[account][nCheckpoints - 1].fromBlock == blockNumber) {
          checkpoints[account][nCheckpoints - 1].balance = newBalance;
      } else {
          checkpoints[account][nCheckpoints] = Checkpoint(blockNumber, newBalance);
          numCheckpoints[account] = nCheckpoints + 1;
      }
    }

    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function safe256(uint256 n, string memory errorMessage) internal pure returns (uint256) {
        require(n <= uint(2**256-1), errorMessage);
        return uint256(n);
    }

    function add256(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function sub256(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }
}