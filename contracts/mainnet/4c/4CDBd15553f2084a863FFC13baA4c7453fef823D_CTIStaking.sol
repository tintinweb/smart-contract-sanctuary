/**
 *Submitted for verification at Etherscan.io on 2021-07-29
*/

pragma solidity ^0.8.6;
interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract CTIStaking{

  IERC20 public TKN;
  address public owner;
  address public worker;
  
  event TransferOwnership(address indexed previousOwner, address indexed newOwner);
  event WorkerRights(address indexed worker, bool indexed value);
  event CTIStaked(address indexed sender, bool indexed Stacked);
  event CTIUnstaked(address indexed sender , bool indexed Unstacked);
  
  modifier restricted {
        require(msg.sender == owner, 'This function is restricted to owner');
        _;
    }
    
  modifier workerOnly {
        require(msg.sender == worker, "You do not have worker rights");
        _;
    }
  
  struct Stake {
    uint256 start;
    uint256 period;
    uint256 amount;
    address client;
  }

  mapping(address => Stake) public stakes;
  
  function stake(address _client, uint256 _amount) public workerOnly {
    require(stakes[_client].start == 0, "Already staking!");
    require(_amount > 0, "Amount cant be zero!");
    require(_client != address(0),'Invalid address: should not be 0x0');
    require(TKN.transferFrom(_client, address(this), _amount), "Transfer failed, check allowance");
    stakes[_client] = Stake({start: block.timestamp, period: 360 days, amount : _amount, client :_client });
    emit CTIStaked(_client , true);
  }

  function unstake(address _client, address _to) public workerOnly {
    require(stakes[_client].start != 0, "Not staking");
    require(_client != address(0),'Invalid address: should not be 0x0');
    require(_to != address(0),'Invalid address: should not be 0x0');
    Stake storage _s = stakes[_client];
    address dead = 0x000000000000000000000000000000000000dEaD;
    require(block.timestamp > _s.start + _s.period, "Period not passed yet");
    require(TKN.transfer(_to, _s.amount * 8 / 10), "Transfer failed, check contract balance");
    require(TKN.transfer(dead, _s.amount * 2 / 10), "Transfer failed, check contract balance");
    
    emit CTIUnstaked(_client, true);
    delete stakes[_client];
  }



    function setWorkerRights(address _worker) public restricted {
        require(_worker != address(0), 'Invalid address: should not be 0x0');
        worker = _worker;
        emit WorkerRights(_worker, true);
    }
    
    
    function transferOwnership(address _newOwner) public restricted {
        require(_newOwner != address(0), 'Invalid address: should not be 0x0');
        emit TransferOwnership(owner, _newOwner);
        owner = _newOwner;
    }

  constructor (IERC20 _token) {
    TKN = _token;
    owner = msg.sender;
  }
}