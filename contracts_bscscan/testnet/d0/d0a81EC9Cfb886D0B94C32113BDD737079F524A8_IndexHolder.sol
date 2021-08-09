/**
 *Submitted for verification at BscScan.com on 2021-08-08
*/

pragma solidity ^0.5.0;

contract Context {
    constructor () internal { }

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;
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

interface IIndexHolder {
    function latestAnswer () external view returns (int256);
    function latestTimestamp () external view returns (uint256);
}

contract Governance is Context{
    address internal _governance;
    mapping (address => bool) private _isRelayer;
    
    event GovernanceChanged(address oldGovernance, address newGovernance);
    event RelayerAdmitted(address target);
    event RelayerExpelled(address target);
    
    modifier GovernanceOnly () {
        require (_msgSender() == _governance, "Only Governance can do");
        _;
    }
    
    modifier RelayerOnly () {
        require (_isRelayer[_msgSender()], "Only Relayer can do");
        _;
    }
    
    function governance () external view returns (address) {
        return _governance;
    }
    
    function isRelayer (address target) external view returns (bool) {
        return _isRelayer[target];
    }
    
    function admitRelayer (address target) external GovernanceOnly {
        require (!_isRelayer[target], "Target is relayer already");
        _isRelayer[target] = true;
        emit RelayerAdmitted(target);
    }
    
    function expelRelayer (address target) external GovernanceOnly {
        require (_isRelayer[target], "Target is not relayer");
        _isRelayer[target] = false;
        emit RelayerExpelled(target);
    }
    
    function succeedGovernance (address newGovernance) external GovernanceOnly {
        _governance = newGovernance;
        emit GovernanceChanged(_msgSender(), newGovernance);
    }
}

contract IndexHolder is Governance, IIndexHolder {
    using SafeMath for uint256;
    
    int256 private _latestAnswer;
    uint256 private _latestTimestamp;

    uint256 public EXPIRE_TIME = 3600;
    
    event NewIndex(int256 index, uint256 timestamp, address relayer);
  
    constructor () public {
        _governance = _msgSender();
    }

    function changeExpireTime (uint256 expireTime) external GovernanceOnly {
        EXPIRE_TIME = expireTime;
    }

    function latestAnswer () external view returns (int256) {
        require (_latestTimestamp > block.timestamp - EXPIRE_TIME, "Index expired");
        return _latestAnswer;
    }

    function latestTimestamp () external view returns (uint256) {
        return _latestTimestamp;
    }
    
    function updateIndex (int256 _index) public RelayerOnly {
        _latestAnswer = _index;
        _latestTimestamp = block.timestamp;
        emit NewIndex(_latestAnswer, _latestTimestamp, _msgSender());
    }
}