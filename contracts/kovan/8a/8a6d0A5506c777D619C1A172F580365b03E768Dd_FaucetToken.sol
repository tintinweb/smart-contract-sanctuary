pragma solidity ^0.5.16;

//-----Decoded View---------------
//Arg [0] : _initialAmount (uint256): 732246278000000
//Arg [1] : _tokenName (string): USD Coin
//Arg [2] : _decimalUnits (uint8): 6
//Arg [3] : _tokenSymbol (string): USDC
import "../../SafeMath.sol";

interface ERC20Base {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function totalSupply() external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function balanceOf(address who) external view returns (uint256);
}

contract ERC20 is ERC20Base {
    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

contract ERC20NS is ERC20Base {
    function transfer(address to, uint256 value) external;

    function transferFrom(address from, address to, uint256 value) external;
}

/**
 * @title Standard ERC20 token
 * @dev Implementation of the basic standard token.
 *  See https://github.com/ethereum/EIPs/issues/20
 */
contract StandardToken is ERC20 {
    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) public balanceOf;

    constructor(uint256 _initialAmount, string memory _tokenName, uint8 _decimalUnits, string memory _tokenSymbol) public {
        totalSupply = _initialAmount;
        balanceOf[msg.sender] = _initialAmount;
        name = _tokenName;
        symbol = _tokenSymbol;
        decimals = _decimalUnits;
    }

    function transfer(address dst, uint256 amount) external returns (bool) {
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(amount, "Insufficient balance");
        balanceOf[dst] = balanceOf[dst].add(amount, "Balance overflow");
        emit Transfer(msg.sender, dst, amount);
        return true;
    }

    function transferFrom(address src, address dst, uint256 amount) external returns (bool) {
        allowance[src][msg.sender] = allowance[src][msg.sender].sub(amount, "Insufficient allowance");
        balanceOf[src] = balanceOf[src].sub(amount, "Insufficient balance");
        balanceOf[dst] = balanceOf[dst].add(amount, "Balance overflow");
        emit Transfer(src, dst, amount);
        return true;
    }

    function approve(address _spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][_spender] = amount;
        emit Approval(msg.sender, _spender, amount);
        return true;
    }
}

/**
 * @title Non-Standard ERC20 token
 * @dev Version of ERC20 with no return values for `transfer` and `transferFrom`
 *  See https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
 */
contract NonStandardToken is ERC20NS {
    using SafeMath for uint256;

    string public name;
    uint8 public decimals;
    string public symbol;
    uint256 public totalSupply;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) public balanceOf;

    constructor(uint256 _initialAmount, string memory _tokenName, uint8 _decimalUnits, string memory _tokenSymbol) public {
        totalSupply = _initialAmount;
        balanceOf[msg.sender] = _initialAmount;
        name = _tokenName;
        symbol = _tokenSymbol;
        decimals = _decimalUnits;
    }

    function transfer(address dst, uint256 amount) external {
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(amount, "Insufficient balance");
        balanceOf[dst] = balanceOf[dst].add(amount, "Balance overflow");
        emit Transfer(msg.sender, dst, amount);
    }

    function transferFrom(address src, address dst, uint256 amount) external {
        allowance[src][msg.sender] = allowance[src][msg.sender].sub(amount, "Insufficient allowance");
        balanceOf[src] = balanceOf[src].sub(amount, "Insufficient balance");
        balanceOf[dst] = balanceOf[dst].add(amount, "Balance overflow");
        emit Transfer(src, dst, amount);
    }

    function approve(address _spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][_spender] = amount;
        emit Approval(msg.sender, _spender, amount);
        return true;
    }
}

contract ERC20Harness is StandardToken {
    // To support testing, we can specify addresses for which transferFrom should fail and return false
    mapping(address => bool) public failTransferFromAddresses;

    // To support testing, we allow the contract to always fail `transfer`.
    mapping(address => bool) public failTransferToAddresses;

    constructor(uint256 _initialAmount, string memory _tokenName, uint8 _decimalUnits, string memory _tokenSymbol) public
    StandardToken(_initialAmount, _tokenName, _decimalUnits, _tokenSymbol) {}

    function harnessSetFailTransferFromAddress(address src, bool _fail) public {
        failTransferFromAddresses[src] = _fail;
    }

    function harnessSetFailTransferToAddress(address dst, bool _fail) public {
        failTransferToAddresses[dst] = _fail;
    }

    function harnessSetBalance(address _account, uint _amount) public {
        balanceOf[_account] = _amount;
    }

    function transfer(address dst, uint256 amount) external returns (bool success) {
        // Added for testing purposes
        if (failTransferToAddresses[dst]) {
            return false;
        }
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(amount, "Insufficient balance");
        balanceOf[dst] = balanceOf[dst].add(amount, "Balance overflow");
        emit Transfer(msg.sender, dst, amount);
        return true;
    }

    function transferFrom(address src, address dst, uint256 amount) external returns (bool success) {
        // Added for testing purposes
        if (failTransferFromAddresses[src]) {
            return false;
        }
        allowance[src][msg.sender] = allowance[src][msg.sender].sub(amount, "Insufficient allowance");
        balanceOf[src] = balanceOf[src].sub(amount, "Insufficient balance");
        balanceOf[dst] = balanceOf[dst].add(amount, "Balance overflow");
        emit Transfer(src, dst, amount);
        return true;
    }
}
/**
 * @title The Compound Faucet Test Token
 * @author Compound
 * @notice A simple test token that lets anyone get more of it.
 */
contract FaucetToken is StandardToken {
    constructor(uint256 _initialAmount, string memory _tokenName, uint8 _decimalUnits, string memory _tokenSymbol) public
    StandardToken(_initialAmount, _tokenName, _decimalUnits, _tokenSymbol) {
    }

    function allocateTo(address _owner, uint256 value) public {
        balanceOf[_owner] += value;
        totalSupply += value;
        emit Transfer(address(this), _owner, value);
    }
}

/**
 * @title The Compound Faucet Test Token (non-standard)
 * @author Compound
 * @notice A simple test token that lets anyone get more of it.
 */
contract FaucetNonStandardToken is NonStandardToken {
    constructor(uint256 _initialAmount, string memory _tokenName, uint8 _decimalUnits, string memory _tokenSymbol) public
    NonStandardToken(_initialAmount, _tokenName, _decimalUnits, _tokenSymbol) {
    }

    function allocateTo(address _owner, uint256 value) public {
        balanceOf[_owner] += value;
        totalSupply += value;
        emit Transfer(address(this), _owner, value);
    }
}

/**
 * @title The Compound Faucet Re-Entrant Test Token
 * @author Compound
 * @notice A test token that is malicious and tries to re-enter callers
 */
contract FaucetTokenReEntrantHarness {
    using SafeMath for uint256;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 totalSupply_;
    mapping(address => mapping(address => uint256)) allowance_;
    mapping(address => uint256) balanceOf_;

    bytes public reEntryCallData;
    string public reEntryFun;

    constructor(uint256 _initialAmount, string memory _tokenName, uint8 _decimalUnits, string memory _tokenSymbol, bytes memory _reEntryCallData, string memory _reEntryFun) public {
        totalSupply_ = _initialAmount;
        balanceOf_[msg.sender] = _initialAmount;
        name = _tokenName;
        symbol = _tokenSymbol;
        decimals = _decimalUnits;
        reEntryCallData = _reEntryCallData;
        reEntryFun = _reEntryFun;
    }

    modifier reEnter(string memory funName) {
        string memory _reEntryFun = reEntryFun;
        if (compareStrings(_reEntryFun, funName)) {
            reEntryFun = "";
            // Clear re-entry fun
            (bool success, bytes memory returndata) = msg.sender.call(reEntryCallData);
            assembly {
                if eq(success, 0) {
                    revert(add(returndata, 0x20), returndatasize())
                }
            }
        }

        _;
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b)));
    }

    function allocateTo(address _owner, uint256 value) public {
        balanceOf_[_owner] += value;
        totalSupply_ += value;
        emit Transfer(address(this), _owner, value);
    }

    function totalSupply() public reEnter("totalSupply") returns (uint256) {
        return totalSupply_;
    }

    function allowance(address owner, address spender) public reEnter("allowance") returns (uint256 remaining) {
        return allowance_[owner][spender];
    }

    function approve(address spender, uint256 amount) public reEnter("approve") returns (bool success) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function balanceOf(address owner) public reEnter("balanceOf") returns (uint256 balance) {
        return balanceOf_[owner];
    }

    function transfer(address dst, uint256 amount) public reEnter("transfer") returns (bool success) {
        _transfer(msg.sender, dst, amount);
        return true;
    }

    function transferFrom(address src, address dst, uint256 amount) public reEnter("transferFrom") returns (bool success) {
        _transfer(src, dst, amount);
        _approve(src, msg.sender, allowance_[src][msg.sender].sub(amount));
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(spender != address(0));
        require(owner != address(0));
        allowance_[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address src, address dst, uint256 amount) internal {
        require(dst != address(0));
        balanceOf_[src] = balanceOf_[src].sub(amount);
        balanceOf_[dst] = balanceOf_[dst].add(amount);
        emit Transfer(src, dst, amount);
    }
}