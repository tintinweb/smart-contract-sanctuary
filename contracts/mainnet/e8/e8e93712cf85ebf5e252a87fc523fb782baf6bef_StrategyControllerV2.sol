pragma solidity ^0.5.16;

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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;

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

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
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
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface Strategy {
    function want() external view returns (address);
    function deposit() external;
    function withdraw(address) external;
    function skim() external;
    function withdraw(uint) external;
    function withdrawAll() external returns (uint);
    function balanceOf() external view returns (uint);
}

interface Vault {
    function token() external view returns (address);
    function claimInsurance() external;
}

interface Converter {
    function convert(address) external returns (uint);
}

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

contract StrategyControllerV2 {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;
    
    address public governance;
    address public onesplit;
    address public rewards;
    
    // Vault to strategy mapping
    mapping(address => address) public vaults;
    // Strategy to vault mapping
    mapping(address => address) public strategies;
    
    mapping(address => mapping(address => address)) public converters;
    
    mapping(address => bool) public isVault;
    mapping(address => bool) public isStrategy;
    
    uint public split = 500;
    uint public constant max = 10000;
    
    constructor(address _rewards) public {
        governance = msg.sender;
        onesplit = address(0x50FDA034C0Ce7a8f7EFDAebDA7Aa7cA21CC1267e);
        rewards = _rewards;
    }
    
    function setSplit(uint _split) external {
        require(msg.sender == governance, "!governance");
        split = _split;
    }
    
    function setOneSplit(address _onesplit) external {
        require(msg.sender == governance, "!governance");
        onesplit = _onesplit;
    }
    
    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }
    
    function setConverter(address _input, address _output, address _converter) external {
        require(msg.sender == governance, "!governance");
        converters[_input][_output] = _converter;
    }
    
    function setStrategy(address _vault, address _strategy) external {
        require(msg.sender == governance, "!governance");
        address _current = strategies[_vault];
        if (_current != address(0)) {
           Strategy(_current).withdrawAll();
        }
        strategies[_vault] = _strategy;
        isStrategy[_strategy] = true;
        vaults[_strategy] = _vault;
        isVault[_vault] = true;
    }
    
    function want(address _vault) external view returns (address) {
        return Strategy(strategies[_vault]).want();
    }
    
    function earn(address _vault, uint _amount) public {
        address _strategy = strategies[_vault];
        address _want = Strategy(_strategy).want();
        IERC20(_want).safeTransfer(_strategy, _amount);
        Strategy(_strategy).deposit();
    }
    
    function balanceOf(address _vault) external view returns (uint) {
        return Strategy(strategies[_vault]).balanceOf();
    }
    
    function withdrawAll(address _strategy) external {
        require(msg.sender == governance, "!governance");
        // WithdrawAll sends 'want' to 'vault'
        Strategy(_strategy).withdrawAll();
    }
    
    function inCaseTokensGetStuck(address _token, uint _amount) external {
        require(msg.sender == governance, "!governance");
        IERC20(_token).safeTransfer(governance, _amount);
    }
    
    function inCaseStrategyGetStruck(address _strategy, address _token) external {
        require(msg.sender == governance, "!governance");
        Strategy(_strategy).withdraw(_token);
        IERC20(_token).safeTransfer(governance, IERC20(_token).balanceOf(address(this)));
    }
    
    function getExpectedReturn(address _strategy, address _token, uint parts) external view returns (uint expected) {
        uint _balance = IERC20(_token).balanceOf(_strategy);
        address _want = Strategy(_strategy).want();
        (expected,) = OneSplitAudit(onesplit).getExpectedReturn(_token, _want, _balance, parts, 0);
    }
    
    function claimInsurance(address _vault) external {
        require(msg.sender == governance, "!governance");
        Vault(_vault).claimInsurance();
    }
    
    // Only allows to withdraw non-core strategy tokens ~ this is over and above normal yield
    function delegatedHarvest(address _strategy, uint parts) external {
        // This contract should never have value in it, but just incase since this is a public call
        address _have = Strategy(_strategy).want();
        uint _before = IERC20(_have).balanceOf(address(this));
        Strategy(_strategy).skim();
        uint _after =  IERC20(_have).balanceOf(address(this));
        if (_after > _before) {
            uint _amount = _after.sub(_before);
            address _want = Vault(vaults[_strategy]).token();
            uint[] memory _distribution;
            uint _expected;
            _before = IERC20(_want).balanceOf(address(this));
            IERC20(_have).safeApprove(onesplit, 0);
            IERC20(_have).safeApprove(onesplit, _amount);
            (_expected, _distribution) = OneSplitAudit(onesplit).getExpectedReturn(_have, _want, _amount, parts, 0);
            OneSplitAudit(onesplit).swap(_have, _want, _amount, _expected, _distribution, 0);
            _after = IERC20(_want).balanceOf(address(this));
            if (_after > _before) {
                _amount = _after.sub(_before);
                uint _reward = _amount.mul(split).div(max);
                IERC20(_want).safeTransfer(vaults[_strategy], _amount.sub(_reward));
                IERC20(_want).safeTransfer(rewards, _reward);
            }
        }
    }
    
    // Only allows to withdraw non-core strategy tokens ~ this is over and above normal yield
    function harvest(address _strategy, address _token, uint parts) external {
        // This contract should never have value in it, but just incase since this is a public call
        uint _before = IERC20(_token).balanceOf(address(this));
        Strategy(_strategy).withdraw(_token);
        uint _after =  IERC20(_token).balanceOf(address(this));
        if (_after > _before) {
            uint _amount = _after.sub(_before);
            address _want = Strategy(_strategy).want();
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
    
    function withdraw(address _vault, uint _amount) external {
        require(isVault[msg.sender] == true, "!vault");
        Strategy(strategies[_vault]).withdraw(_amount);
    }
}