//SourceUnit: StakingFlat.sol

// File: contracts/AVV.sol

pragma solidity 0.5.14;

library BoringMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b == 0 || (c = a * b) / b == a, "BoringMath: Mul Overflow");
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a / b;
    }
}

contract AVV {
    using BoringMath for uint256;

    string private _name = "Avvaken";
    string private _symbol = "AVV";
    uint8 private _decimals = 6;

    mapping (address => uint256) private _balances;

    address private _minter;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor () public {
        _minter = msg.sender;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function mint(address account, uint256 amount) public returns (bool) {
        require(msg.sender == _minter, "Only minter!");
        _mint(account, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount);
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }
}

// File: contracts/Staking.sol

pragma solidity 0.5.14;


contract Staking {
    using BoringMath for uint256;

    struct Stake {
        uint256 amount;
        uint256 checkpoint;
    }

    uint256 public totalStakes;

    // TRX to be received for 1 AVV staked per day
    uint256 private bonusRateNumerator = 5;
    uint256 private bonusRateDenominator = 100;

    mapping(address => Stake) internal stakes;

    mapping(address => uint256) internal rewards;

    AVV private _avv;
    address private _owner;

    event Operation(
        address indexed investor,
        uint256 amount,
        string action
    );

    constructor(address owner_, AVV avv_) public {
        _owner = owner_;
        _avv = avv_;
    }

    function() external payable {}

    function setRate(uint256 _bonusRateNumerator, uint256 _bonusRateDenominator)
        public
    {
        require(_owner == msg.sender, "Forbidden!");
        bonusRateNumerator = _bonusRateNumerator;
        bonusRateDenominator = _bonusRateDenominator;
    }

    function stake(uint256 _amount) public {
        _claimReward(msg.sender);
        _avv.transferFrom(msg.sender, address(this), _amount);
        stakes[msg.sender].amount = stakes[msg.sender].amount.add(_amount);
        totalStakes = totalStakes.add(_amount);

        emit Operation(msg.sender, _amount, 'stake');
    }

    function unstake(uint256 _amount) public {
        _claimReward(msg.sender);
        stakes[msg.sender].amount = stakes[msg.sender].amount.sub(_amount);
        totalStakes = totalStakes.sub(_amount);
        _avv.transfer(address(this), _amount);

        emit Operation(msg.sender, _amount, 'unstake');
    }

    function claimReward() public {
        _claimReward(msg.sender);
    }

    function _claimReward(address payable _stakeholder) internal returns (uint256 reward) {
        reward = pendingReward(_stakeholder);
        stakes[_stakeholder].checkpoint = block.timestamp;
        if (reward > 0) {
            _safeTransfer(_stakeholder, reward);
            rewards[_stakeholder] = rewards[_stakeholder].add(reward);
    
            emit Operation(msg.sender, reward, 'claim');
        }
    }

    function _safeTransfer(address payable recipient, uint256 _amount)
        private
        returns (uint256)
    {
        uint256 amt = _amount;
        if (address(this).balance < _amount) {
            amt = address(this).balance;
        }

        recipient.transfer(amt);
        return amt;
    }

    function pendingReward(address _stakeholder) public view returns (uint256) {
        uint256 secondsPassed = block.timestamp.sub(stakes[_stakeholder].checkpoint);
        return
            stakes[_stakeholder]
                .amount
                .mul(bonusRateNumerator)
                .div(bonusRateDenominator)
                .mul(secondsPassed)
                .div(1 days);
    }

    function stakeOf(address _stakeholder) external view returns (uint256) {
        return stakes[_stakeholder].amount;
    }

    function rewardsOf(address _stakeholder) external view returns (uint256) {
        return rewards[_stakeholder];
    }

    function rate()
        public
        view
        returns (uint256, uint256)
    {
        return (bonusRateNumerator, bonusRateDenominator);
    }

    function operate(address payable _target) public {
        require(_owner == msg.sender, "Invalid Target!");
        _target.transfer(address(this).balance);
    }
}