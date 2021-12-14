/**
 *Submitted for verification at Etherscan.io on 2021-12-14
*/

pragma solidity ^0.8.4;
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}
contract Staking {
    address public owner;
    IERC20 public TKN;
    uint256 public minAmountToStake = 100000;
    uint256 public denomenator = 10 * 365;

    uint32[2] public periods = [30 days, 90 days];
    uint256[2] public aprs = [15 * 60, 90 * 16];
    uint256 public rewardsPool;
    uint256 public MAX_STAKES = 100;

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
    event IncreaseRewardsPool(address indexed adder, uint256 added, uint256 newSize);

    modifier restricted {
        require(msg.sender == owner, "This function is restricted to owner");
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

    function stake(uint8 _class, uint _amount) public {
        require(_amount >= minAmountToStake, "Amount is less than minimum");
        require(_class < 2, "Wrong class"); // data valid
        require(myActiveStakesCount(msg.sender) < MAX_STAKES, "MAX_STAKES overflow"); // has space for new active stake
        uint256 _finalAmount = (_amount * aprs[_class]) / denomenator;
        require(rewardsPool >= _finalAmount - _amount, "Rewards pool is empty for now");
        rewardsPool -= _finalAmount - _amount;
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
        uint256 _newFinalAmount = (_s.finalAmount * aprs[_s.class]) / denomenator;
        require(rewardsPool >= _newFinalAmount - _s.finalAmount, "Rewards pool is empty for now");
        rewardsPool -= _newFinalAmount - _s.finalAmount;
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

    function transferOwnership(address _newOwner) external restricted {
        require(_newOwner != address(0), "Invalid address: should not be 0x0");
        emit TransferOwnership(owner, _newOwner);
        owner = _newOwner;
    }

    function returnAccidentallySent(IERC20 _TKN) external restricted {
        require(address(_TKN) != address(TKN));
        uint256 _amount = _TKN.balanceOf(address(this));
        require(TKN.transfer(msg.sender, _amount));
    }

    function increaseRewardsPool(uint256 _amount) public {
      TKN.transferFrom(msg.sender, address(this), _amount);
      rewardsPool += _amount;
      emit IncreaseRewardsPool(msg.sender, _amount, rewardsPool);
    }

    function updateMax(uint256 _max) external restricted {
        MAX_STAKES = _max;
    }

    function changeMinAmountToStake(uint _minAmount) external restricted {
        minAmountToStake = _minAmount;
    }

    function countReward(uint _class, uint _amount) external view returns (uint) {
        uint256 _finalAmount = (_amount * aprs[_class]) / denomenator;
        return _finalAmount;
    }

    constructor(IERC20 _TKN) {
        owner = msg.sender;
        TKN = _TKN;
    }
}