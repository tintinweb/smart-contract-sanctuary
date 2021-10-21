/**
 *Submitted for verification at BscScan.com on 2021-10-21
*/

pragma solidity >=0.7.0;

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
    function withdraw(uint) external;
    function withdrawAll() external returns (uint);
    function balanceOf() external view returns (uint);
}

interface Converter {
    function convert(address) external returns (uint);
}

contract Controller {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;
    
    address public governance;
    address public strategist;
    
    mapping(address => address) public vaults;
    mapping(address => address) public strategies;
    mapping(address => mapping(address => address)) public converters;
    
    mapping(address => mapping(address => bool)) public approvedStrategies;
    
    constructor() {
        governance = msg.sender;
        strategist = msg.sender;
    }
    
    function setStrategist(address _strategist) public {//
        require(msg.sender == governance, "!governance");
        require(_strategist != address(0), "ADDRESS ERROR!");
        strategist = _strategist;
    }
    
    function setGovernance(address _governance) public {//
        require(msg.sender == governance, "!governance");
        require(_governance != address(0), "ADDRESS ERROR!");
        governance = _governance;
    }
    
    function setVault(address _token, address _vault) public {//
        require(msg.sender == strategist || msg.sender == governance, "!strategist");
        require(_vault != address(0), "ADDRESS ERROR!");
        require(_token != address(0), "ADDRESS ERROR!");
        require(vaults[_token] == address(0), "vault");
        vaults[_token] = _vault;
    }
    
    function approveStrategy(address _token, address _strategy) public {
        require(msg.sender == governance, "!governance");
        require(_strategy != address(0), "ADDRESS ERROR!");
        require(_token != address(0), "ADDRESS ERROR!");
        approvedStrategies[_token][_strategy] = true;
    }
    
    function revokeStrategy(address _token, address _strategy) public {
        require(msg.sender == governance, "!governance");
        require(_strategy != address(0), "ADDRESS ERROR!");
        require(_token != address(0), "ADDRESS ERROR!");
        approvedStrategies[_token][_strategy] = false;
    }
    
    function setConverter(address _input, address _output, address _converter) public {
        require(msg.sender == strategist || msg.sender == governance, "!strategist");
        require(_input != address(0), "ADDRESS ERROR!");
        require(_output != address(0), "ADDRESS ERROR!");
        require(_converter != address(0), "ADDRESS ERROR!");
        converters[_input][_output] = _converter;
    }
    
    function setStrategy(address _token, address _strategy) public {//
        require(msg.sender == strategist || msg.sender == governance, "!strategist");
        require(approvedStrategies[_token][_strategy] == true, "!approved");
        require(_strategy != address(0), "ADDRESS ERROR!");
        require(_token != address(0), "ADDRESS ERROR!");
        
        address _current = strategies[_token];
        if (_current != address(0)) {
           Strategy(_current).withdrawAll();
        }
        strategies[_token] = _strategy;
    }
    
    function earn(address _token, uint _amount) public {
        require(_token != address(0), "ADDRESS ERROR!");
        address _strategy = strategies[_token];
        address _want = Strategy(_strategy).want();
        if (_want != _token) {
            address converter = converters[_token][_want];
            IERC20(_token).safeTransfer(converter, _amount);
            _amount = Converter(converter).convert(_strategy);
            IERC20(_want).safeTransfer(_strategy, _amount);
        } else {
            IERC20(_token).safeTransfer(_strategy, _amount);
        }
        Strategy(_strategy).deposit();
    }
    
    function balanceOf(address _token) external view returns (uint) {
        require(_token != address(0), "ADDRESS ERROR!");
        return Strategy(strategies[_token]).balanceOf();
    }
    
    function withdrawAll(address _token) public {
        require(msg.sender == strategist || msg.sender == governance, "!strategist");
        require(_token != address(0), "ADDRESS ERROR!");
        Strategy(strategies[_token]).withdrawAll();
    }
    
    function inCaseTokensGetStuck(address _token, uint _amount) public {
        require(msg.sender == strategist || msg.sender == governance, "!governance");
        require(_token != address(0), "ADDRESS ERROR!");
        IERC20(_token).safeTransfer(msg.sender, _amount);
    }
    
    function inCaseStrategyTokenGetStuck(address _strategy, address _token) public {
        require(msg.sender == strategist || msg.sender == governance, "!governance");
        require(_strategy != address(0), "ADDRESS ERROR!");
        require(_token != address(0), "ADDRESS ERROR!");
        Strategy(_strategy).withdraw(_token);
    }
    
    function withdraw(address _token, uint _amount) public {
        require(msg.sender == vaults[_token], "!vault");
        require(_token != address(0), "ADDRESS ERROR!");
        Strategy(strategies[_token]).withdraw(_amount);
    }

    function rewards() public view returns (address) {
        return strategist;
    }
}