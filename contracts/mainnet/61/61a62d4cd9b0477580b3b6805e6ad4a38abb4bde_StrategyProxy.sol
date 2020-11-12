// SPDX-License-Identifier: MIT

pragma solidity ^0.5.17;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function decimals() external view returns (uint);
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

interface Proxy {
    function execute(address to, uint value, bytes calldata data) external returns (bool, bytes memory);
}

interface Mintr {
    function mint_for(address, address) external;
}

contract StrategyProxy {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;
    
    Proxy constant public proxy = Proxy(0xF147b8125d2ef93FB6965Db97D6746952a133934);
    address constant public mintr = address(0xd061D61a4d941c39E5453435B6345Dc261C2fcE0);
    address constant public crv = address(0xD533a949740bb3306d119CC777fa900bA034cd52);
    
    mapping(address => bool) public strategies;
    address public governance;
    
    constructor() public {
        governance = msg.sender;
    }
    
    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }
    
    function approveStrategy(address _strategy) external {
        require(msg.sender == governance, "!governance");
        strategies[_strategy] = true;
    }
    
    function revokeStrategy(address _strategy) external {
        require(msg.sender == governance, "!governance");
        strategies[_strategy] = false;
    }
    
    
    function withdraw(address _gauge, address _token, uint _amount) public returns (uint) {
        require(strategies[msg.sender], "!strategy");
        uint _before = IERC20(_token).balanceOf(address(proxy));
        proxy.execute(_gauge, 0, abi.encodeWithSignature("withdraw(uint256)",_amount));
        uint _after = IERC20(_token).balanceOf(address(proxy));
        uint _net = _after.sub(_before);
        proxy.execute(_token, 0, abi.encodeWithSignature("transfer(address,uint256)",msg.sender,_net));
        return _net;
    }
    
    function balanceOf(address _gauge) public view returns (uint) {
        return IERC20(_gauge).balanceOf(address(proxy));
    }
    
    function withdrawAll(address _gauge, address _token) external returns (uint) {
        require(strategies[msg.sender], "!strategy");
        return withdraw(_gauge, _token, balanceOf(_gauge));
    }
    
    function deposit(address _gauge, address _token) external {
        uint _balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(address(proxy), _balance);
        
        _balance = IERC20(_token).balanceOf(address(proxy));
        proxy.execute(_token, 0, abi.encodeWithSignature("approve(address,uint256)",_gauge,0));
        proxy.execute(_token, 0, abi.encodeWithSignature("approve(address,uint256)",_gauge,_balance));
        proxy.execute(_gauge, 0, abi.encodeWithSignature("deposit(uint256)",_balance));
    }
    
    function harvest(address _gauge) external {
        require(strategies[msg.sender], "!strategy");
        uint _before = IERC20(crv).balanceOf(address(proxy));
        Mintr(mintr).mint_for(_gauge, address(proxy));
        uint _after = IERC20(crv).balanceOf(address(proxy));
        uint _balance = _after.sub(_before);
        proxy.execute(crv, 0, abi.encodeWithSignature("transfer(address,uint256)",msg.sender,_balance));
    }
}