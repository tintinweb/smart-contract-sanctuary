/**
 *Submitted for verification at Etherscan.io on 2021-07-27
*/

pragma solidity ^0.5.16;


library Math {
    
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }
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

    
    function sub( uint256 a, uint256 b, string memory errorMessage ) internal pure returns (uint256) {
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

    function div( uint256 a, uint256 b, string memory errorMessage ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod( uint256 a, uint256 b, string memory errorMessage ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() internal {}

    // solhint-disable-previous-line no-empty-blocks
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library Address {

    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;

            bytes32 accountHash
         = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != 0x0 && codehash != accountHash);
    }

    function toPayable(address account) internal pure returns (address payable){
        return address(uint160(account));
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require( address(this).balance >= amount, "Address: insufficient balance" );

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require( success, "Address: unable to send value, recipient may have reverted" );
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom( address sender, address recipient, uint256 amount ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval( address indexed owner, address indexed spender, uint256 value );
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer( IERC20 token, address to, uint256 value ) internal { callOptionalReturn( token, abi.encodeWithSelector(token.transfer.selector, to, value) ); }
    function safeTransferFrom( IERC20 token, address from, address to, uint256 value ) internal { callOptionalReturn( token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value) ); }

    function safeApprove( IERC20 token, address spender, uint256 value ) internal {
        require( (value == 0) || (token.allowance(address(this), spender) == 0), "SafeERC20: approve from non-zero to non-zero allowance" );
        callOptionalReturn( token, abi.encodeWithSelector(token.approve.selector, spender, value) );
    }

    function safeIncreaseAllowance( IERC20 token, address spender, uint256 value ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add( value );
        callOptionalReturn( token, abi.encodeWithSelector( token.approve.selector, spender, newAllowance ) );
    }

    function safeDecreaseAllowance( IERC20 token, address spender, uint256 value ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub( value, "SafeERC20: decreased allowance below zero" );
        callOptionalReturn( token, abi.encodeWithSelector( token.approve.selector, spender, newAllowance ) );
    }

    function callOptionalReturn(IERC20 token, bytes memory data) private {

        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

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
    function allowance(address owner, address spender) public view returns (uint256) {
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
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
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

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
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

contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(string memory name, string memory symbol, uint8 decimals ) public {
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

/**
 * @dev Vaults Token StrategyController Interface
 */
interface IGOFStrategyController {
    function withdraw(address, uint256) external;
    function balanceOf(address) external view returns (uint256);
    function earn(address, uint256) external;
    function rewards() external view returns (address);
}

/**
 * @dev Vault Contract
 */
contract GOFVault is ERC20, ERC20Detailed{
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    //staking token
    IERC20 public token;

    IERC20 public GOF = IERC20(0x488E0369f9BC5C40C002eA7c1fe4fd01A198801c);

    uint256 public min = 9500;
    uint256 public constant max = 10000;
    uint256 public earnLowerlimit; //池内空余资金到这个值就自动earn

    address public governance;
    address public controller;

    //UserAssets
    struct UserAssets {
        uint256 stakeAmount; // 总质押总数
        uint256 payout; //
        uint256 totalRewardPaid; // 已经领取的分红
    }
    mapping(address => UserAssets) public userAssetsMapping;

    //Global
    struct Global {
        uint256 totalStakeAmount; // 总质押总数
        uint256 totalSharedAmount; //  总分红金额
        uint256 earningsPerShare; // 每股分红
    }
    Global public global;

    mapping(address => uint256) public lastDepositTime;

    uint256 internal constant magnitude = 10**40;

    constructor( address _token, address _controller, uint256 _earnLowerlimit ) public ERC20Detailed(
        string(abi.encodePacked("golff ", ERC20Detailed(_token).name())),
        string(abi.encodePacked("g", ERC20Detailed(_token).symbol())),
        ERC20Detailed(_token).decimals()
    ) { 
        token = IERC20(_token);
        
        earnLowerlimit = _earnLowerlimit * 1e18;
        governance = tx.origin;
        controller = _controller;
    }

    function stakeToken() external view returns (address) {
        return address(token);
    }

    function balance() public view returns (uint256) {
        return token.balanceOf(address(this)).add( IGOFStrategyController(controller).balanceOf(address(token)) );
    }

    function setMin(uint256 _min) external {
        require(msg.sender == governance, "Golff:!governance");
        min = _min;
    }

    function setGovernance(address _governance) public {
        require(msg.sender == governance, "Golff:!governance");
        governance = _governance;
    }

    function setController(address _controller) public {
        require(msg.sender == governance, "Golff:!governance");
        controller = _controller;
    }

    function setEarnLowerlimit(uint256 _earnLowerlimit) public {
        require(msg.sender == governance, "Golff:!governance");
        earnLowerlimit = _earnLowerlimit;
    }

    // Custom logic in here for how much the vault allows to be borrowed
    // Sets minimum required on-hand to keep small withdrawals cheap
    function available() public view returns (uint256) {
        return token.balanceOf(address(this)).mul(min).div(max);
    }

    /**
     * 通过控制调用策略，赚取收益
     */
    function earn() public {
        //获取余额,并将余额转到策略控制器
        uint256 _bal = available();
        token.safeTransfer(controller, _bal);
        //让策略控制进行进行收益投放
        IGOFStrategyController(controller).earn(address(token), _bal);
    }

    /**
     * 存入所有
     */
    function depositAll() external {
        deposit(token.balanceOf(msg.sender));
    }

    /**
     * 存款
     */
    function deposit(uint256 _amount) public {
        //用户授权，将资金存入Vault
        uint256 _before = token.balanceOf(address(this));
        token.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 _after = token.balanceOf(address(this));
        _amount = _after.sub(_before);
        
        _mint(msg.sender, _amount);

        UserAssets storage _userAssets = userAssetsMapping[msg.sender];

        //用户质押金额增加
        _userAssets.stakeAmount = _userAssets.stakeAmount.add(_amount);

        if (global.earningsPerShare != 0) {
            //计算用户的存入数量产生的收益
            _userAssets.payout = _userAssets.payout.add( global.earningsPerShare.mul(_amount).sub(1).div(magnitude).add( 1 ) );
        }
        //增加总质押金额
        global.totalStakeAmount = global.totalStakeAmount.add(_amount);

        //如果当前月余额高于阀值，投放资金获取收益
        if (token.balanceOf(address(this)) > earnLowerlimit) {
            earn();
        }
        //记录用户的质押时间
        lastDepositTime[msg.sender] = now;
    }

    /**
     * No rebalance implementation for lower fees and faster swaps
     * 用户提现
     */
    function withdraw(uint256 amount) external {
        //燃烧掉
        _burn(msg.sender, amount);
        //先领取收益
        getReward();
        require( amount <= userAssetsMapping[msg.sender].stakeAmount, "Golff:!balance" );
        uint256 _amount = amount;

        uint256 _before = token.balanceOf(address(this));
        //如果当前余额不够，从控制器中提现缺少资金过来
        if (_before < _amount) {
            uint256 _withdraw = _amount.sub(_before);
            IGOFStrategyController(controller).withdraw(address(token), _withdraw);
            uint256 _after = token.balanceOf(address(this));
            uint256 _diff = _after.sub(_before);
            if (_diff < _withdraw) {
                _amount = _before.add(_diff);
            }
        }

        //减少用户待付收益
        userAssetsMapping[msg.sender].payout = userAssetsMapping[msg.sender] .payout .sub(global.earningsPerShare.mul(amount).div(magnitude));
        //减少用户的质押额度
        userAssetsMapping[msg.sender].stakeAmount = userAssetsMapping[msg .sender] .stakeAmount .sub(amount);
        //减少总的质押额度
        global.totalStakeAmount = global.totalStakeAmount.sub(amount);
        //提现到用户的钱包
        token.safeTransfer(msg.sender, _amount);
    }
    
    /**
     * 分发收益，重新计算每股的分控收益
     */
    function distributeReward(uint256 amount) public {
        require(amount > 0, "Golff:not 0");
        require(global.totalStakeAmount > 0, "Golff: Total stake amount larger than 0");
        GOF.safeTransferFrom(msg.sender, address(this), amount);
        global.earningsPerShare = global.earningsPerShare.add(
            amount.mul(magnitude).div(global.totalStakeAmount)
        );
        global.totalSharedAmount = global.totalSharedAmount.add(amount);
    }

    /**
     * 计算用户当前收益
     */
    function earned(address user) public view returns (uint256) {
        uint256 _reward = global .earningsPerShare .mul(userAssetsMapping[user].stakeAmount) .div(magnitude);
        if (_reward <= userAssetsMapping[user].payout) {
            return 0;
        } else {
            return _reward.sub(userAssetsMapping[user].payout);
        }
    }

    function earnedPending(uint256 _pendingBalance, address user) public view returns (uint256) {
        uint256 _earningsPerShare = global.earningsPerShare.add( _pendingBalance.mul(magnitude).div(global.totalStakeAmount) );
        uint256 _reward = _earningsPerShare .mul(userAssetsMapping[user].stakeAmount) .div(magnitude);
        _reward = _reward.sub(earned(user));
        if (_reward <= userAssetsMapping[user].payout) {
            return 0;
        } else {
            return _reward.sub(userAssetsMapping[user].payout);
        }
    }

    /**
     * 领取收益
     */
    function getReward() public {
        uint256 _reward = earned(msg.sender);
        userAssetsMapping[msg.sender].payout = global .earningsPerShare .mul(userAssetsMapping[msg.sender].stakeAmount) .div(magnitude);
        userAssetsMapping[msg.sender].totalRewardPaid = userAssetsMapping[msg .sender] .totalRewardPaid .add(_reward);

        if (_reward > 0) {
            uint256 _depositTime = now - lastDepositTime[msg.sender];
            if (_depositTime < 1 days) {
                //deposit in 24h
                uint256 _actualReward = _depositTime .mul(_reward) .mul(1e18) .div(1 days) .div(1e18);
                uint256 _teamAomunt = _reward.sub(_actualReward);
                GOF.safeTransfer(IGOFStrategyController(controller).rewards(), _teamAomunt);
                _reward = _actualReward;
            }
            GOF.safeTransfer(msg.sender, _reward);
        }
    }
}