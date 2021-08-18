/**
 *Submitted for verification at BscScan.com on 2021-08-17
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}
contract Staking {
    address public owner;
    IERC20 public TKN;

    uint256[5] public periods = [30 days, 60 days, 90 days, 180 days, 360 days];
    uint8[5] public rates = [101, 102, 103, 106, 112];
    uint256[5] public amounts = [10000e18, 20000e18, 30000e18, 50000e18, 100000e18];
    uint256 public limit = 1500000e18;
    uint256 public MAX_STAKES = 1;
    uint256 public start_timestamp;
    uint256 public finish_timestamp;

    struct Stake {
        uint8 class;
        uint8 cycle;
        uint256 initialAmount;
        uint256 finalAmount;
        uint256 timestamp;
        bool unstaked;
    }

    Stake[] public stakes;
    mapping(address => uint256[]) public stakesOf;
    mapping(uint256 => address) public ownerOf;

    event Staked(address indexed sender, uint8 indexed class, uint256 amount, uint256 finalAmount);
    event Prolonged(address indexed sender, uint8 indexed class, uint8 cycle, uint256 newAmount, uint256 newFinalAmount);
    event Unstaked(address indexed sender, uint8 indexed class, uint8 cycle, uint256 amount);
    event TransferOwnership(address indexed previousOwner, address indexed newOwner);

    modifier restricted {
        require(msg.sender == owner, 'This function is restricted to owner');
        _;
    }

    function stakesInfo(uint256 _from, uint256 _to) public view returns (Stake[] memory s) {
        s = new Stake[](_to - _from);
        for (uint256 i = _from; i <= _to; i++) s[i - _from] = stakes[i];
    }

    function stakesInfoAll() public view returns (Stake[] memory s) {
        s = new Stake[](stakes.length);
        for (uint256 i = 0; i < stakes.length; i++) s[i] = stakes[i];
    }

    function stakesLength() public view returns (uint256) {
        return stakes.length;
    }

    function myStakes(address _me) public view returns (Stake[] memory s, uint256[] memory indexes) {
        s = new Stake[](stakesOf[_me].length);
        indexes = new uint256[](stakesOf[_me].length);
        for (uint256 i = 0; i < stakesOf[_me].length; i++) {
            indexes[i] = stakesOf[_me][i];
            s[i] = stakes[indexes[i]];
        }
    }

    function myActiveStakesCount(address _me) public view returns (uint256 l) {
        uint256[] storage _s = stakesOf[_me];
        for (uint256 i = 0; i < _s.length; i++) if (!stakes[_s[i]].unstaked) l++;
    }

    function stake(uint8 _class) public {
        require(_class < 5, "Wrong class"); // data valid
        uint256 _amount = amounts[_class];
        require(myActiveStakesCount(msg.sender) < MAX_STAKES, "MAX_STAKES overflow"); // has space for new active stake
        require(finish_timestamp > block.timestamp + periods[_class], "Program will finish before this stake does"); // not staking in the end of program
        uint256 _finalAmount = (_amount * rates[_class]) / 100;
        limit -= _finalAmount - _amount;
        require(TKN.transferFrom(msg.sender, address(this), _amount));
        uint256 _index = stakes.length;
        stakesOf[msg.sender].push(_index);
        stakes.push(Stake({
            class: _class,
            cycle: 1,
            initialAmount: _amount,
            finalAmount: _finalAmount,
            timestamp: block.timestamp,
            unstaked: false
        }));
        ownerOf[_index] = msg.sender;
        emit Staked(msg.sender, _class, _amount, _finalAmount);
    }

    function prolong(uint256 _index) public {
        require(msg.sender == ownerOf[_index]);
        Stake storage _s = stakes[_index];
        require(!_s.unstaked); // not unstaked yet
        require(block.timestamp >= _s.timestamp + periods[_s.class]); // staking period finished
        require(finish_timestamp > block.timestamp + periods[_s.class]); // not prolonging in the end of program
        uint256 _newFinalAmount = (_s.finalAmount * rates[_s.class]) / 100;
        limit -= _newFinalAmount - _s.finalAmount;
        _s.timestamp = block.timestamp;
        _s.cycle++;
        require(_s.cycle * periods[_s.class] <= 360 days, "total staking time exceeds 360 days");
        emit Prolonged(msg.sender, _s.class, _s.cycle, _s.finalAmount, _newFinalAmount);
        _s.finalAmount = _newFinalAmount;
    }

    function unstake(uint256 _index) public {
        require(msg.sender == ownerOf[_index]);
        Stake storage _s = stakes[_index];
        require(!_s.unstaked); // not unstaked yet
        require(block.timestamp >= _s.timestamp + periods[_s.class]); // staking period finished
        require(TKN.transfer(msg.sender, _s.finalAmount));
        _s.unstaked = true;
        emit Unstaked(msg.sender, _s.class, _s.cycle, _s.finalAmount);
    }

    function transferOwnership(address _newOwner) public restricted {
        require(_newOwner != address(0), 'Invalid address: should not be 0x0');
        emit TransferOwnership(owner, _newOwner);
        owner = _newOwner;
    }

    function drain(address _recipient) public restricted {
        require(block.timestamp > finish_timestamp); // after 24st Oct
        require(TKN.transfer(_recipient, limit));
        limit = 0;
    }

    function drainFull(address _recipient) public restricted {
        require(block.timestamp > finish_timestamp + 31 days); // After 24st Nov
        uint256 _amount = TKN.balanceOf(address(this));
        require(TKN.transfer(_recipient, _amount));
        limit = 0;
    }

    function returnAccidentallySent(IERC20 _TKN) public restricted {
        require(address(_TKN) != address(TKN));
        uint256 _amount = _TKN.balanceOf(address(this));
        require(TKN.transfer(msg.sender, _amount));
    }

    function updateMax(uint256 _max) public restricted {
        MAX_STAKES = _max;
    }

    constructor(IERC20 _TKN, uint256 _start, uint256 _finish) {
        start_timestamp = _start;
        finish_timestamp = _finish;
        owner = msg.sender;
        TKN = _TKN;
    }
}