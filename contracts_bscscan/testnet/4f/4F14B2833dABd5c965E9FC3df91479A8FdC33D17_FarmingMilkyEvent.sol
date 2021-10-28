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

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() internal {
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

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract SignData {
    bytes32 public DOMAIN_SEPARATOR;
    string public NAME;
    bytes32 public DEPOSIT_HASH;
    bytes32 public WITHDRAW_HASH;
    mapping(address => uint) public nonces;


    constructor() internal {
        NAME = "FarmingMilkyEvent";
        uint chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(NAME)),
                keccak256(bytes('1')),
                chainId,
                this
            )
        );


        DEPOSIT_HASH = keccak256("Data(address sender,uint256 amount,uint256 nonce)");
        WITHDRAW_HASH = keccak256("Data(address sender,uint256 amount,uint256 nonce)");
    }

    function verify(bytes32 data, address sender, uint8 v, bytes32 r, bytes32 s) internal view {
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                data
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == sender, "Invalid nonce");
    }
}

interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
    external
    returns (bool);

    function allowance(address owner, address spender)
    external
    view
    returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function mint(address to, uint256 amount) external;

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeBEP20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(
            value
        );
        callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeBEP20: decreased allowance below zero"
        );
        callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function callOptionalReturn(IBEP20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeBEP20: call to non-contract");
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeBEP20: low-level call failed");
        if (returndata.length > 0) {
            require(
                abi.decode(returndata, (bool)),
                "SafeBEP20: BEP20 operation did not succeed"
            );
        }
    }
}

contract BEP20 is Context, IBEP20 {
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

    function allowance(address owner, address spender)
    public
    view
    returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "BEP20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
    public
    returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
    public
    returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "BEP20: decreased allowance below zero"
            )
        );
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(
            amount,
            "BEP20: transfer amount exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "BEP20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "BEP20: burn from the zero address");

        _balances[account] = _balances[account].sub(
            amount,
            "BEP20: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(
            account,
            _msgSender(),
            _allowances[account][_msgSender()].sub(
                amount,
                "BEP20: burn amount exceeds allowance"
            )
        );
    }
}

contract FarmingMilkyEvent is Ownable, SignData {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    struct UserInfo {
        uint256 stakingAmount; //amount of staking Token
        uint256 rewardAmount; //reward before update balance.
        uint256 lastTimeUpdate; // block.number when update.
    }
    // The input token ! kawaii
    address public stakingToken;
    // The reward token
    address public milkyToken;
    // AIRI toke (mul 10**12).
    uint256 public milkyPerSecond;
    uint256 public stakingEndTime;
    uint256 public claimableTime;

    mapping(address => UserInfo) public userInfo;

    event Deposit(address user, uint256 amount);
    event Withdraw(address user, uint256 amount);
    event UpdateReward(
        uint256 lastTimeUpdate,
        uint256 currUpdate,
        uint256 rewardBefore,
        uint256 rewardBalance,
        uint256 userBalance,
        address user
    );

    constructor (
        address _stakingToken,
        address _milkyToken,
        uint256 _milkyPerSecond,
        uint256 _stakingEndTime,
        uint256 _claimableTime
    ) public {
        stakingToken = _stakingToken;
        milkyToken = _milkyToken;
        milkyPerSecond = _milkyPerSecond;
        stakingEndTime = _stakingEndTime;
        claimableTime = _claimableTime;
    }

    modifier onlyValidTime() {
        require(block.timestamp <= stakingEndTime, "Staking ended");
        _;
    }

    function setMilkyToken(address _milkyToken) public onlyOwner {
        milkyToken = _milkyToken;
    }

    function setStakingToken(address _stakingToken) public onlyOwner {
        stakingToken = _stakingToken;
    }

    function setMilkyRewardPerSecond(uint256 _milkyPerSecond) public onlyOwner {
        milkyPerSecond = _milkyPerSecond;
    }

    function setStakingEndTimestamp(uint256 _stakingEndTime) public onlyOwner {
        stakingEndTime = _stakingEndTime;
    }

    function setClaimableTime(uint256 _claimableTime) public onlyOwner {
        claimableTime = _claimableTime;
    }

    function inCaseTokenStuck(
        address token,
        uint256 amount,
        address to
    ) public onlyOwner {
        IBEP20(token).safeTransfer(to, amount);
    }

    function calculateReward(
        uint256 from,
        uint256 to,
        uint256 amount
    ) internal view returns (uint256) {
        if (to <= stakingEndTime) {
            return to.sub(from).mul(milkyPerSecond).mul(amount).div(10 ** 12);
        } else if (from >= stakingEndTime) {
            return 0;
        } else {
            return stakingEndTime.sub(from).mul(milkyPerSecond).mul(amount).div(10 ** 12);
        }
    }

    function reward(address _user) external view returns (uint256, uint256) {
        return
        (
        userInfo[_user].rewardAmount.add(
            calculateReward(
                userInfo[_user].lastTimeUpdate,
                block.timestamp,
                userInfo[_user].stakingAmount
            )
        ),
        block.timestamp
        );
    }

    function _updateReward(address _user) internal {
        uint256 reward = 0;
        uint256 amount = userInfo[_user].stakingAmount;
        if (userInfo[_user].lastTimeUpdate != 0) {
            reward = calculateReward(
                userInfo[_user].lastTimeUpdate,
                block.timestamp,
                amount
            );
        }
        emit UpdateReward(
            userInfo[_user].lastTimeUpdate,
            block.timestamp,
            userInfo[_user].rewardAmount,
            reward,
            userInfo[_user].stakingAmount,
            _user
        );
        userInfo[_user].rewardAmount = userInfo[_user].rewardAmount.add(reward);
        userInfo[_user].lastTimeUpdate = block.timestamp;
    }

    function depositPermit(address sender, uint256 _amount, uint8 v, bytes32 r, bytes32 s) public {
        verify(keccak256(abi.encode(DEPOSIT_HASH, sender, _amount, nonces[sender]++)), sender, v, r, s);
        _deposit(sender, _amount);
    }

    function deposit(uint256 _amount) public {
        _deposit(msg.sender, _amount);
    }

    function _deposit(address sender, uint256 _amount) internal onlyValidTime {
        _updateReward(sender);
        IBEP20(stakingToken).safeTransferFrom(
            sender,
            address(this),
            _amount
        );
        userInfo[sender].stakingAmount = userInfo[sender].stakingAmount.add(_amount);
        emit Deposit(sender, _amount);
    }

    function withdrawPermit(address sender, uint256 _amount, uint8 v, bytes32 r, bytes32 s) external {
        verify(keccak256(abi.encode(WITHDRAW_HASH, sender, _amount, nonces[sender]++)), sender, v, r, s);
        _withdraw(sender, _amount);
    }

    function withdraw(uint256 _amount) external {
        _withdraw(msg.sender, _amount);
    }

    function _withdraw(address sender, uint256 _amount) internal {
        _updateReward(sender);
        require(userInfo[sender].stakingAmount >= _amount, "withdraw: not good");
        IBEP20(stakingToken).safeTransfer(sender, _amount);
        userInfo[sender].stakingAmount = userInfo[sender].stakingAmount.sub(_amount);
        emit Withdraw(sender, _amount);
    }

    function claimAll(address sender) external {
        require(block.timestamp > claimableTime, "!claim");
        _updateReward(sender);
        uint256 reward = userInfo[sender].rewardAmount;
        userInfo[sender].rewardAmount = 0;
        IBEP20(milkyToken).transfer(sender, reward);
    }
}