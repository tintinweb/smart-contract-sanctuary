/**
 *Submitted for verification at Etherscan.io on 2021-04-02
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}
contract Staking {
    address public owner;
    IERC20 public TKN;
    
    uint256[] public periods = [30 days, 90 days, 150 days];
    uint256[] public rates = [106, 121, 140];
    uint256 public limit = 20000000000000000000000000;
    uint256 public finish_timestamp = 1633046400; // 00:00 1 Oct 2021 UTC
    
    struct Stake {
        uint8 class;
        uint8 cycle;
        uint256 initialAmount;
        uint256 finalAmount;
        uint256 timestamp;
    }
    
    mapping(address => Stake) public stakeOf;
    
    event Staked(address sender, uint8 class, uint256 amount, uint256 finalAmount);
    event Prolonged(address sender, uint8 class, uint8 cycle, uint256 newAmount, uint256 newFinalAmount);
    event Unstaked(address sender, uint8 class, uint8 cycle, uint256 amount);
    
    function stake(uint8 _class, uint256 _amount) public {
        require(_class < 3 && _amount >= 10000000000000000000); // data valid
        require(stakeOf[msg.sender].cycle == 0); // not staking currently
        require(finish_timestamp > block.timestamp + periods[_class]); // not staking in the end of program
        uint256 _finalAmount = _amount * rates[_class] / 100;
        limit -= _finalAmount - _amount;
        require(TKN.transferFrom(msg.sender, address(this), _amount));
        stakeOf[msg.sender] = Stake(_class, 1, _amount, _finalAmount, block.timestamp);
        emit Staked(msg.sender, _class, _amount, _finalAmount);
    }
    
    function prolong() public {
        Stake storage _s = stakeOf[msg.sender];
        require(_s.cycle > 0); // staking currently
        require(block.timestamp >= _s.timestamp + periods[_s.class]); // staking period finished
        require(finish_timestamp > block.timestamp + periods[_s.class]); // not prolonging in the end of program
        uint256 _newFinalAmount = _s.finalAmount * rates[_s.class] / 100;
        limit -= _newFinalAmount - _s.finalAmount;
        _s.timestamp = block.timestamp;
        _s.cycle++;
        emit Prolonged(msg.sender, _s.class, _s.cycle, _s.finalAmount, _newFinalAmount);
        _s.finalAmount = _newFinalAmount;
    }

    function unstake() public {
        Stake storage _s = stakeOf[msg.sender];
        require(_s.cycle > 0); // staking currently
        require(block.timestamp >= _s.timestamp + periods[_s.class]); // staking period finished
        require(TKN.transfer(msg.sender, _s.finalAmount));
        emit Unstaked(msg.sender, _s.class, _s.cycle, _s.finalAmount);
        delete stakeOf[msg.sender];
    }
    
    function transferOwnership(address _owner) public {
        require(msg.sender == owner);
        owner = _owner;
    }
    
    function drain(address _recipient) public {
        require(msg.sender == owner);
        require(block.timestamp > finish_timestamp); // after 1st Oct
        require(TKN.transfer(_recipient, limit));
        limit = 0;
    }
    
    function drainFull(address _recipient) public {
        require(msg.sender == owner);
        require(block.timestamp > finish_timestamp + 31 days); // After 1st Nov
        uint256 _amount = TKN.balanceOf(address(this));
        require(TKN.transfer(_recipient, _amount));
        limit = 0;
    }
    
    constructor(IERC20 _TKN) {
        owner = msg.sender;
        TKN = _TKN;
    }
}