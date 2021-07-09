/**
 *Submitted for verification at Etherscan.io on 2021-07-08
*/

pragma solidity ^0.8.4;
interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract StakingLime1{

  IERC20 public TKN;
  address public owner;
  address public worker;
  
  event TransferOwnership(address indexed previousOwner, address indexed newOwner);
  event WorkerRights(address indexed worker, bool value);
  event LIMEisStaked(string internalTxIdaddress, bool Stacked);
  event LIMEisUnstaked(string internalTxIdaddress, bool Unstacked);
  
  modifier restricted {
        require(msg.sender == owner, 'This function is restricted to owner');
        _;
    }
    
  modifier workerOnly {
        require(msg.sender == worker, "You do not have worker rights");
        _;
    }
  
  uint256[4] periods = [30, 90, 180, 360];
  uint256[6] amounts = [25 ,50 , 100 ,500, 1000, 10000];
  struct Stake {
    uint256 start;
    uint8 period;
    uint256 passed;
    uint256 amount;
    string internalTxIdaddress;
    address client;
  }

  mapping(string => Stake) public stakes;
  
  

  function stake(string memory _internalTxIdaddress, address _client, uint8 _period, uint256 _amount) public workerOnly {
    require(stakes[_internalTxIdaddress].start == 0, "Already staking");
    require(_period < 4, "Invalid period, must be from 0 to 3");
    require(_amount < 6, "Invalid amount, must be from 0 to 5");
    require(TKN.transferFrom(_client, address(this), amounts[_amount] * uint256(1e3)), "Transfer failed, check allowance");
    stakes[_internalTxIdaddress] = Stake({passed: 0, start: block.timestamp, period: _period, internalTxIdaddress : _internalTxIdaddress, client : _client, amount : _amount});
    emit LIMEisStaked(_internalTxIdaddress, true);
  }

  function unstake(string memory _internalTxIdaddress) public workerOnly {
    require(stakes[_internalTxIdaddress].start != 0, "Not staking");
    Stake storage _s = stakes[_internalTxIdaddress];
    uint8 _t = _s.period;
    require(block.timestamp >= _s.start + periods[_t], "Period not passed yet");

    uint256 amount = amounts[_s.amount];
    require(TKN.transfer(_s.client, amount * uint256(1e3)), "Transfer failed, check contract balance");
    emit LIMEisUnstaked(_internalTxIdaddress, true);
    delete stakes[_internalTxIdaddress];
  }



    function setWorkerRights(address _worker) public restricted {
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