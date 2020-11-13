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
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != 0x0 && codehash != accountHash);
    }

    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require( address(this).balance >= amount, "Address: insufficient balance" );

        (bool success, ) = recipient.call.value(amount)("");
        require( success, "Address: unable to send value, recipient may have reverted" );
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function mint(address account, uint256 amount) external;
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

    function safeTransferFrom( IERC20 token, address from, address to, uint256 value ) internal {
        callOptionalReturn( token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value) );
    }

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

        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            require( abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed" );
        }
    }
}

contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor( string memory name, string memory symbol, uint8 decimals ) public {
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
 * Vault Strategy Interface
 */
interface IGOFStrategy {
    function want() external view returns (address);
    function deposit() external;
    function withdraw(address) external;
    function withdraw(uint) external;
    function withdrawAll() external returns (uint);
    function balanceOf() external view returns (uint);
}

/**
 * 
 */
interface Converter {
    function convert(address) external returns (uint);
}

/**
 *
 */
interface OneSplitAudit {
    function swap(
        address fromToken,
        address destToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] calldata distribution,
        uint256 flags
    )
        external
        payable
        returns(uint256 returnAmount);
    
    function getExpectedReturn(
        address fromToken,
        address destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags // See constants in IOneSplit.sol
    )
        external
        view
        returns(
            uint256 returnAmount,
            uint256[] memory distribution
        );
}

/**
 *  @dev
 *  The controller of Strategy
 *  Distribute different strategies according to different tokens
 */
contract GOFStrategyControllerV2 {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;
    
    address public governance;
    address public strategist;

    address public onesplit;
    address public rewards;
    address public factory;
    mapping(address => address) public vaults;
    mapping(address => address) public strategies;
    mapping(address => mapping(address => address)) public converters;
    
    mapping(address => mapping(address => bool)) public approvedStrategies;

    uint public split = 500;
    uint public constant max = 10000;
    
    constructor(address _rewards) public {
        governance = tx.origin;
        strategist = tx.origin;

        onesplit = address(0x50FDA034C0Ce7a8f7EFDAebDA7Aa7cA21CC1267e);
        rewards = _rewards;
    }
    
    function setFactory(address _factory) public {
        require(msg.sender == governance, "Golff:!governance");
        factory = _factory;
    }
    
    function setSplit(uint _split) public {
        require(msg.sender == governance, "Golff:!governance");
        split = _split;
    }
    
    function setOneSplit(address _onesplit) public {
        require(msg.sender == governance, "Golff:!governance");
        onesplit = _onesplit;
    }
    
    function setGovernance(address _governance) public {
        require(msg.sender == governance, "Golff:!governance");
        governance = _governance;
    }

    function setRewards(address _rewards) public {
        require(msg.sender == governance, "Golff:!governance");
        rewards = _rewards;
    }
    
    function setVault(address _token, address _vault) public {
        require(msg.sender == strategist || msg.sender == governance, "Golff:!strategist");
        require(vaults[_token] == address(0), "Golff:vault");
        vaults[_token] = _vault;
    }
    
     function approveStrategy(address _token, address _strategy) public {
        require(msg.sender == governance, "Golff:!governance");
        approvedStrategies[_token][_strategy] = true;
    }

    function revokeStrategy(address _token, address _strategy) public {
        require(msg.sender == governance, "Golff:!governance");
        approvedStrategies[_token][_strategy] = false;
    }

    function setConverter(address _input, address _output, address _converter) public {
        require(msg.sender == strategist || msg.sender == governance, "Golff:!strategist");
        converters[_input][_output] = _converter;
    }
    
    function setStrategy(address _token, address _strategy) public {
        require(msg.sender == strategist || msg.sender == governance, "Golff:!strategist");
        require(approvedStrategies[_token][_strategy] == true, "Golff:!approved");
        address _current = strategies[_token];
        //之前存在策略,那就先把所有的资金提出来
        if (_current != address(0)) {
           IGOFStrategy(_current).withdrawAll();
        }
        strategies[_token] = _strategy;
    }
    
    /**
     * 获取收益
     * @param _token staking token
     * @param _amount staking amount
     */
    function earn(address _token, uint _amount) public {
        address _strategy = strategies[_token]; //获取策略的合约地址
        address _want = IGOFStrategy(_strategy).want();//策略需要的token地址
        if (_want != _token) {//如果策略需要的和输入的不一样,需要先转换
            address converter = converters[_token][_want];//转换器合约地址.
            IERC20(_token).safeTransfer(converter, _amount);//给转换器打钱
            _amount = Converter(converter).convert(_strategy);//执行转换...
            IERC20(_want).safeTransfer(_strategy, _amount);
        } else {
            IERC20(_token).safeTransfer(_strategy, _amount);
        }
        IGOFStrategy(_strategy).deposit();//存钱
    }
    
    /**
     * 获取token的余额
     * @param _token staking token
     */
    function balanceOf(address _token) external view returns (uint) {
        return IGOFStrategy(strategies[_token]).balanceOf();
    }
    
    /**
     * 提现全部
     * @param _token staking token
     */
    function withdrawAll(address _token) public {
        require(msg.sender == strategist || msg.sender == governance, "Golff:!governance");
        IGOFStrategy(strategies[_token]).withdrawAll();
    }
    
    /**
     *
     */
    function inCaseTokensGetStuck(address _token, uint _amount) public {
        require(msg.sender == strategist || msg.sender == governance, "Golff:!governance");
        IERC20(_token).safeTransfer(governance, _amount);
    }
    
    /**
     *
     */
    function getExpectedReturn(address _strategy, address _token, uint parts) public view returns (uint expected) {
        uint _balance = IERC20(_token).balanceOf(_strategy);//获取策略器 某个代币的余额
        address _want = IGOFStrategy(_strategy).want();//策略器需要的代币.
        (expected,) = OneSplitAudit(onesplit).getExpectedReturn(_token, _want, _balance, parts, 0);
    }
    
    // Only allows to withdraw non-core strategy tokens ~ this is over and above normal yield
    function yearn(address _strategy, address _token, uint parts) public {
        require(msg.sender == strategist || msg.sender == governance, "Golff:!governance");
        // This contract should never have value in it, but just incase since this is a public call
        uint _before = IERC20(_token).balanceOf(address(this));
        IGOFStrategy(_strategy).withdraw(_token);
        uint _after =  IERC20(_token).balanceOf(address(this));
        if (_after > _before) {
            uint _amount = _after.sub(_before);
            address _want = IGOFStrategy(_strategy).want();
            uint[] memory _distribution;
            uint _expected;
            _before = IERC20(_want).balanceOf(address(this));
            IERC20(_token).safeApprove(onesplit, 0);
            IERC20(_token).safeApprove(onesplit, _amount);
            (_expected, _distribution) = OneSplitAudit(onesplit).getExpectedReturn(_token, _want, _amount, parts, 0);
            OneSplitAudit(onesplit).swap(_token, _want, _amount, _expected, _distribution, 0);
            _after = IERC20(_want).balanceOf(address(this));
            if (_after > _before) {
                _amount = _after.sub(_before);
                uint _reward = _amount.mul(split).div(max);
                earn(_want, _amount.sub(_reward));
                IERC20(_want).safeTransfer(rewards, _reward);
            }
        }
    }
    
    /**
     * 提现
     * @param _token token to ben withdraw
     * @param _amount amount
     */
    function withdraw(address _token, uint _amount) public {
        require(msg.sender == vaults[_token], "Golff:!vault");
        IGOFStrategy(strategies[_token]).withdraw(_amount);
    }
}