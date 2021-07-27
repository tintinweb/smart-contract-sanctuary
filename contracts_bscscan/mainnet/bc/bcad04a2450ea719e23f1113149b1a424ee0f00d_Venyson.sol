/**
 *Submitted for verification at BscScan.com on 2021-07-27
*/

pragma solidity ^0.6.12;

// SPDX-License-Identifier: MIT

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {

            if (returndata.length > 0) {

                // solhint-disable-next-line no-inline-assembly
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

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
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

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Venyson is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;
    
    mapping (address => uint256) private _lastRewardTime;
    mapping (address => bool) private _isExcluded;
    
    uint256 private _totalSupply = 21000000 * 10**18;
    uint8 private _decimals = 18;
    string private _symbol = "VENY";
    string private _name = "Venyson";
    address public deployer;
    
    uint256 public genisisBlock;
    uint256 public genisisBlockNumber;
    uint256 private _lastBlockTime;
    uint256 private _lastBlock;
    
    uint256 private _circulatingSupply = 1000000 * 10**18;
    uint256 private _mining = 0;
    uint256 private _blockReward = 200 * 10**18;

    uint private _blockTime = 600; // time
    uint256 public maxTxAmount = 50000 * 10**18;
    
    uint256 private _totalBlockRewards = 0; 
    uint256 private _totalBlocksMined = 1;
    bool private _enableMine = true;
    
    event blockMined (address _by, uint256 _time, uint256 _blockNumber);

    constructor() public {
        genisisBlock = block.timestamp;
        genisisBlockNumber = block.number;
        _lastBlock = genisisBlockNumber;
        _lastBlockTime = genisisBlock;
        _lastRewardTime[_msgSender()] = _totalBlocksMined;
        _balances[_msgSender()] = _circulatingSupply;
        _mining = _circulatingSupply;
        
        emit Transfer(address(0), _msgSender(), _circulatingSupply);
    }

    function getOwner() public view returns (address) {
    return owner();
  }

    function decimals() public view returns (uint8) {
    return _decimals;
  }

    function symbol() public view returns (string memory) {
    return _symbol;
  }

    function name() public view returns (string memory) {
        return _name;
    }

    function totalSupply() public view override returns (uint256) {
    return _totalSupply;
  }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account])
            return _balances[account];
        return _balances[account]+_calcReward(account);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
      _transfer(_msgSender(), recipient, amount);
      return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
    return _allowances[owner][spender];
  }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
    return true;
  }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");
        if (sender != owner())
            require(amount <= maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        
        
        if (_isExcluded[sender]) {
            if (!_isExcluded[recipient]) _mining = _mining + amount;
        }else {
            if (_isExcluded[recipient]) _mining = _mining - amount;
        }
        if (_balances[recipient] <= 0) _lastRewardTime[recipient] = _totalBlocksMined;
        
        if (_lastRewardTime[sender] < _totalBlocksMined && !_isExcluded[sender]) {
            uint256 _reward = _calcReward(sender);
            _balances[sender] = _balances[sender]+_reward;
            _lastRewardTime[sender] = _totalBlocksMined;
        }
        _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        if (_lastRewardTime[recipient] < _totalBlocksMined && !_isExcluded[recipient]) {
            uint256 _reward = _calcReward(recipient);
            _balances[recipient] = _balances[recipient]+_reward;
            _lastRewardTime[recipient] = _totalBlocksMined;
        }
        mine(sender);
      
        emit Transfer(sender, recipient, amount);
    }
    
    function _calcReward (address account) private view returns (uint256) {
        if (_lastRewardTime[account] == _totalBlocksMined)
            return 0;
        uint256 _reward = 0;
        uint256 _prevBlockReward = 0;
        uint256 _lastReward = _lastRewardTime[account];
        
        if (_lastReward >= 1 && _lastReward < 17280) {
            _prevBlockReward = 200 * 10**18;
            if (_totalBlocksMined > 17280) {
                _reward = ((17280 - _lastReward) * _prevBlockReward).mul(_balances[account]).div(_mining);
                _lastReward = 17280;
            }else {
                _reward = ((_totalBlocksMined - _lastReward) * _prevBlockReward).mul(_balances[account]).div(_mining);
                _lastReward = _totalBlocksMined;
            }
        }
        if (_lastReward >= 17280 && _lastReward < 69120) {
            _prevBlockReward = 100 * 10**18;
            if (_totalBlocksMined > 69120) {
                _reward = _reward + (((69120 - _lastReward) * _prevBlockReward).mul(_balances[account]).div(_mining));
                _lastReward = 69120;
            }else {
                _reward = _reward +  (((_totalBlocksMined - _lastReward) * _prevBlockReward).mul(_balances[account]).div(_mining));
                _lastReward = _totalBlocksMined;
            }
        }
        if (_lastReward >= 69120 && _lastReward < 207360) {
            _prevBlockReward = 50 * 10**18;
            if (_totalBlocksMined > 207360) {
                _reward = _reward +  (((207360 - _lastReward) * _prevBlockReward).mul(_balances[account]).div(_mining));
                _lastReward = 207360;
            }else {
                _reward = _reward +  (((_totalBlocksMined - _lastReward) * _prevBlockReward).mul(_balances[account]).div(_mining));
                _lastReward = _totalBlocksMined;
            }
        }
        if (_lastReward >= 207360 && _lastReward < 385280) {
            _prevBlockReward = 25 * 10**18;
            if (_totalBlocksMined >= 385280) {
                _reward = _reward +  (((385280 - _lastReward) * _prevBlockReward).mul(_balances[account]).div(_mining));
                _lastReward = 385280;
            }else {
                _reward = _reward +  (((_totalBlocksMined - _lastReward) * _prevBlockReward).mul(_balances[account]).div(_mining));
                _lastReward = _totalBlocksMined;
            }
        }
        
        return _reward;
    }
    
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");
    
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function mine(address account) private {
        if (!_enableMine) return;
        if (block.number < _lastBlock+_blockTime) return;
        _totalBlockRewards = _totalBlockRewards+_blockReward;
        _circulatingSupply = _circulatingSupply+_blockReward;
        _mining = _mining+_blockReward;
        _lastBlock = block.number;
        _lastBlockTime = block.timestamp;
        _totalBlocksMined++;
        
        emit blockMined (account, _lastBlockTime, _lastBlock);

        if (_totalBlocksMined == 17280) {
            _blockTime = 400;
            _blockReward = _blockReward.div(2);
        }else if (_totalBlocksMined == 69120) {
            _blockTime = 300;
            _blockReward = _blockReward.div(2);
        }else if (_totalBlocksMined == 207360) {
            _blockTime = 200;
            _blockReward = _blockReward.div(2);
        }
        
        if (_totalBlocksMined >= 385280-1) _enableMine = false; // end mining
    }
    
    function exlude (address account) external onlyOwner {
         _exclude(account);
    }
    function include (address account) external onlyOwner {
        _include(account);
    }
    
    function _exclude (address account) private {
        _isExcluded[account] = true;
        _mining = _mining - _balances[account];
    }
    function _include (address account) private {
        _isExcluded[account] = false;
        _mining = _mining+ _balances[account];
    }
    
    function isExcluded (address account) public view returns (bool) {
        return _isExcluded[account];
    }
    function circulatingSupply() public view returns (uint256) {
        return _circulatingSupply;
    }
    function totalBlockRewards() public view returns (uint256) {
        return _totalBlockRewards;
    }
    function totalBlocksMined() public view returns (uint256) {
        return _totalBlocksMined;
    }
    function enableMine() public view returns (bool) {
        return _enableMine;
    }
    function lastBlockTime() public view returns (uint256) {
        return _lastBlockTime;
    }
    function lastBlock() public view returns (uint256) {
        return _lastBlock;
    }
    function blockReward() public view returns (uint256) {
        return _blockReward;
    }

    function miningReward() public view returns (uint256) {
        return _mining;
    }
    function blockTime() public view returns (uint) {
        return _blockTime;
    }
}