//SourceUnit: SUN_Once.sol

/*! ume_to_token.sol | SPDX-License-Identifier: MIT License */

pragma solidity 0.5.12;

interface IEasyTRC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    function totalSupply() external view returns(uint256);
    function balanceOf(address owner) external view returns(uint256);
}

interface ITRC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function approve(address spender, uint256 value) external returns(bool);
    function transfer(address to, uint256 value) external returns(bool);
    function transferFrom(address from, address to, uint256 value) external returns(bool);

    function name() external view returns(string memory);
    function symbol() external view returns(string memory);
    function decimals() external view returns(uint8);
    function allowance(address owner, address spender) external view returns(uint256);
}

library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns(uint256 z) {
        require((z = x + y) >= x, "SafeMath: MATH_ADD_OVERFLOW");
    }

    function sub(uint256 x, uint256 y) internal pure returns(uint256 z) {
        require((z = x - y) <= x, "SafeMath: MATH_SUB_UNDERFLOW");
    }

    function mul(uint256 x, uint256 y) internal pure returns(uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "SafeMath: MATH_MUL_OVERFLOW");
    }
}

library SafeTRC20 {
    function safeApprove(ITRC20 token, address to, uint256 value) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(ITRC20 token, address to, uint256 value) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (address(token) == 0xa614f803B6FD780986A42c78Ec9c7f77e6DeD13C || data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(ITRC20 token, address from, address to, uint256 value) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }
}

contract EasyTRC20 is IEasyTRC20 {
    using SafeMath for uint256;

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    function _mint(address to, uint256 value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);

        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);

        emit Transfer(from, address(0), value);
    }
}

contract UME_SUN is EasyTRC20 {
    using SafeMath for uint256;
    using SafeMath for uint40;
    using SafeTRC20 for ITRC20;

    uint40 constant public DURATION = 14 days;
    
    address public regulator;
    
    ITRC20 public token;
    ITRC20 public ume;
    
    uint40 public start;
    uint40 public finish;
    uint40 public last_update;

    uint256 public rate;
    uint256 public last_rate;

    mapping(address => uint256) public paids;
    mapping(address => uint256) public rewards;

    event Stake(address indexed member, uint256 amount);
    event Reward(address indexed user, uint256 reward);
    event Withdraw(address indexed member, uint256 amount);
    event Repayment(uint256 amount);
    
    modifier onlyRegulator() {
        require(msg.sender == regulator, "UMEFinance: ACCESS_DENIED");
        _;
    }

    modifier started() {
        require(block.timestamp >= start, "UMEFinance: NOT_STARTED");
        _;
    }

    modifier upReward(address member) {
        last_rate = this.calcRate();
        last_update = this.lastTime();

        if(member != address(0)) {
            rewards[member] = this.earned(member);
            paids[member] = last_rate;
        }
        
        _;
    }

    constructor(address _token, address _ume, uint40 _start) public {
        regulator = msg.sender;

        token = ITRC20(_token);
        ume = ITRC20(_ume);

        start = _start;
    }
    
    function stake(uint256 amount) external started upReward(msg.sender) {
        require(amount > 0, "UMEFinance: ZERO_AMOUNT");

        token.safeTransferFrom(msg.sender, address(this), amount);
        
        _mint(msg.sender, amount);

        emit Stake(msg.sender, amount);
    }

    function withdraw(uint256 amount) public started upReward(msg.sender) {
        require(amount > 0, "UMEFinance: ZERO_AMOUNT");

        token.safeTransfer(msg.sender, amount);

        _burn(msg.sender, amount);

        emit Withdraw(msg.sender, amount);
    }

    function reward() public started upReward(msg.sender) {
        uint256 amount = this.earned(msg.sender);

        if(amount > 0) {
            rewards[msg.sender] = 0;

            ume.safeTransfer(msg.sender, amount);

            emit Reward(msg.sender, amount);
        }
    }

    function withdraws(uint256 amount) public started upReward(msg.sender) {
        require(amount <= this.balanceOf(msg.sender), "UMEFinance: INSUFFICIENT_FUNDS");

        withdraw(amount);
        reward();
    }

    function repayment(uint256 amount) external onlyRegulator upReward(address(0)) {
        if(block.timestamp > start) {
            if(block.timestamp >= finish) {
                rate = amount / DURATION;
            }
            else rate = amount.add(finish.sub(block.timestamp).mul(rate)) / DURATION;
            
            last_update = uint40(block.timestamp);
            finish = uint40(block.timestamp.add(DURATION));
        }
        else {
            rate = amount / DURATION;

            last_update = start;
            finish = uint40(start.add(DURATION));
        }
        
        emit Repayment(amount);
    }
    
    function rescue(ITRC20 _token, address payable to, uint256 amount) external onlyRegulator {
        require(to != address(0), "UMEFinance: ZERO_ADDRESS");
        require(amount > 0, "UMEFinance: ZERO_AMOUNT");

        if(address(_token) != address(0)) {
            require(_token != token && _token != ume, "UMEFinance: BAD_TOKEN");

            _token.safeTransfer(to, amount);
        }
        else to.transfer(amount);
    }
    
    function lastTime() external view returns(uint40) {
        return block.timestamp > finish ? finish : uint40(block.timestamp);
    }

    function calcRate() external view returns(uint256) {
        if(this.totalSupply() == 0) return last_rate;
        
        return last_rate.add(this.lastTime().sub(last_update).mul(rate).mul(1e18) / this.totalSupply());
    }

    function earned(address member) external view returns(uint256) {
        return (this.balanceOf(member).mul(this.calcRate().sub(paids[member])) / 1e18).add(rewards[member]);
    }
    
    function info(address member) external view returns(uint256 total_supply, uint256 ume_balance, uint256 reserve0, uint256 reserve1, uint256 member_balance, uint256 member_reserve, uint256 _earned) {
        return (
            this.totalSupply(),
            IEasyTRC20(address(ume)).balanceOf(address(this)),
            0,
            0,
            this.balanceOf(member),
            IEasyTRC20(address(token)).balanceOf(member),
            this.earned(member)
        );
    }
}