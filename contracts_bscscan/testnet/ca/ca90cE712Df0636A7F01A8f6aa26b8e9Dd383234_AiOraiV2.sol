pragma solidity 0.5.16;

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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

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

contract Context {
    constructor() internal {}

    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != 0x0 && codehash != accountHash);
    }

    function toPayable(address account)
    internal
    pure
    returns (address payable)
    {
        return address(uint160(account));
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-call-value
        (bool success,) = recipient.call.value(amount)("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0), "SafeERC20: approve from non-zero to non-zero allowance");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256){
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool){
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool){
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
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

        _balances[account] = _balances[account].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
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
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}

contract ERC20Detailed {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    function initializeErcDetail(string memory name, string memory symbol, uint8 decimals) internal {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
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
}

contract AiOraiV2 is ERC20, ERC20Detailed {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 rewardAmount; //reward before update balance.
        uint256 lastUpdate; // block.timestamp when update.
    }

    bool public initialized;
    // The input token vault!
    address public token;

    // The reward token
    address public orai;

    // Dev address.
    address public governance;
    // ORAI tokens created per second (mul 10**12).
    uint256 public oraiPerSecond;

    mapping(address => UserInfo) public userInfo;

    function initializeVault(address _token, address _orai, uint256 _oraiPerSecond)
    public {
        require(initialized == false, "initialized");
        governance = msg.sender;
        token = _token;
        orai = _orai;
        oraiPerSecond = _oraiPerSecond;
        initializeErcDetail(
            string(abi.encodePacked("yAI v2 ", ERC20Detailed(_token).name())),
            string(abi.encodePacked("ai v2 ", ERC20Detailed(_token).symbol())),
            ERC20Detailed(_token).decimals()
        );
        initialized = true;
    }

    modifier onlyOwner(){
        require(msg.sender == governance, "Forbidden");
        _;
    }
    function setGovernance(address _gov) public onlyOwner {
        governance = _gov;
    }


    function setOrai(address _orai) public onlyOwner {
        orai = _orai;
    }

    function setToken(address _token) public onlyOwner {
        token = _token;
    }

    function setOraiRewardPerBlock(uint256 _oraiPerSecond) public onlyOwner {
        oraiPerSecond = _oraiPerSecond;
    }

    function harvest(address token, uint256 amount, address to) public onlyOwner {
        IERC20(token).safeTransfer(to, amount);
    }

    function calculateReward(uint256 from, uint256 to, uint256 amount) internal view returns (uint256){
        return to.sub(from).mul(oraiPerSecond).mul(amount).div(10 ** 12);
    }

    function reward(address _user) external view returns (uint256) {
        return userInfo[_user].rewardAmount.add(calculateReward(userInfo[_user].lastUpdate, block.timestamp, balanceOf(_user)));
    }

    event UpdateReward(uint256 lastUpdate, uint256 currUpdate, uint256 rewardBefore, uint256 rewardBalance, uint256 userBalance, address user);

    function _updateReward(address _user) internal {
        uint256 reward = 0;
        if (userInfo[_user].lastUpdate != 0) {
            reward = calculateReward(userInfo[_user].lastUpdate, block.timestamp, balanceOf(_user));
        }
        emit UpdateReward(userInfo[_user].lastUpdate, block.timestamp, userInfo[_user].rewardAmount, reward, balanceOf(_user), _user);
        userInfo[_user].rewardAmount = userInfo[_user].rewardAmount.add(reward);
        userInfo[_user].lastUpdate = block.timestamp;
    }


    function deposit(uint256 _amount) public {
        _updateReward(msg.sender);
        uint256 _before = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransferFrom(msg.sender, address(this), _amount);
        uint256 _after = IERC20(token).balanceOf(address(this));
        _amount = _after.sub(_before);
        _mint(msg.sender, _amount);
    }

    function withdraw(uint256 _amount, address to) public {
        _updateReward(msg.sender);
        _burn(msg.sender, _amount);
        IERC20(token).safeTransfer(to, _amount);
    }


    function transfer(address recipient, uint256 amount) public returns (bool) {
        _updateReward(msg.sender);
        _updateReward(recipient);
        super.transfer(recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _updateReward(sender);
        _updateReward(recipient);
        super.transferFrom(sender, recipient, amount);
        return true;
    }

    function claim(address to, uint256 amount) external {
        _updateReward(to);
        require(amount <= userInfo[to].rewardAmount, "Claim: amount claim > rewardAmount");
        userInfo[to].rewardAmount = userInfo[to].rewardAmount.sub(amount);
        IERC20(orai).safeTransfer(to, amount);
    }

    function claimAll(address to) external returns (uint256 amount){
        _updateReward(to);
        amount = userInfo[msg.sender].rewardAmount;
        userInfo[msg.sender].rewardAmount = 0;
        IERC20(orai).safeTransfer(to, amount);
    }
}