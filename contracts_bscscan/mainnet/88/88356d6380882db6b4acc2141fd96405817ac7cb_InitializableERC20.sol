/**
 *Submitted for verification at BscScan.com on 2021-07-08
*/

/**
 *Submitted for verification at BscScan.com on 2021-01-22
*/

// File: contracts/lib/CloneFactory.sol

/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.6.9;
pragma experimental ABIEncoderV2;

interface ICloneFactory {
    function clone(address prototype) external returns (address proxy);
}

// introduction of proxy mode design: https://docs.openzeppelin.com/upgrades/2.8/
// minimum implementation of transparent proxy: https://eips.ethereum.org/EIPS/eip-1167

contract CloneFactory is ICloneFactory {
    function clone(address prototype) external override returns (address proxy) {
        bytes20 targetBytes = bytes20(prototype);
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(
                add(clone, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            proxy := create(0, clone, 0x37)
        }
        return proxy;
    }
}

// File: contracts/lib/SafeMath.sol



/**
 * @title SafeMath
 * @author DODO Breeder
 *
 * @notice Math operations with safety checks that revert on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "MUL_ERROR");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "DIVIDING_ERROR");
        return a / b;
    }

    function divCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 quotient = div(a, b);
        uint256 remainder = a - quotient * b;
        if (remainder > 0) {
            return quotient + 1;
        } else {
            return quotient;
        }
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SUB_ERROR");
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "ADD_ERROR");
        return c;
    }

    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = x / 2 + 1;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}

// File: contracts/external/ERC20/InitializableERC20.sol



contract InitializableERC20 {
    using SafeMath for uint256;

    string public name;
    uint256 public decimals;
    string public symbol;
    uint256 public totalSupply;

    bool public initialized;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) internal allowed;

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    function init(
        address _creator,
        uint256 _totalSupply,
        string memory _name,
        string memory _symbol,
        uint256 _decimals
    ) public {
        require(!initialized, "TOKEN_INITIALIZED");
        initialized = true;
        totalSupply = _totalSupply;
        balances[_creator] = _totalSupply;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        emit Transfer(address(0), _creator, _totalSupply);
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        require(to != address(0), "TO_ADDRESS_IS_EMPTY");
        require(amount <= balances[msg.sender], "BALANCE_NOT_ENOUGH");

        balances[msg.sender] = balances[msg.sender].sub(amount);
        balances[to] = balances[to].add(amount);
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function balanceOf(address owner) public view returns (uint256 balance) {
        return balances[owner];
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        require(to != address(0), "TO_ADDRESS_IS_EMPTY");
        require(amount <= balances[from], "BALANCE_NOT_ENOUGH");
        require(amount <= allowed[from][msg.sender], "ALLOWANCE_NOT_ENOUGH");

        balances[from] = balances[from].sub(amount);
        balances[to] = balances[to].add(amount);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(amount);
        emit Transfer(from, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return allowed[owner][spender];
    }
}

// File: contracts/lib/InitializableOwnable.sol


/**
 * @title Ownable
 * @author DODO Breeder
 *
 * @notice Ownership related functions
 */
contract InitializableOwnable {
    address public _OWNER_;
    address public _NEW_OWNER_;
    bool internal _INITIALIZED_;

    // ============ Events ============

    event OwnershipTransferPrepared(address indexed previousOwner, address indexed newOwner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // ============ Modifiers ============

    modifier notInitialized() {
        require(!_INITIALIZED_, "DODO_INITIALIZED");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == _OWNER_, "NOT_OWNER");
        _;
    }

    // ============ Functions ============

    function initOwner(address newOwner) public notInitialized {
        _INITIALIZED_ = true;
        _OWNER_ = newOwner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        emit OwnershipTransferPrepared(_OWNER_, newOwner);
        _NEW_OWNER_ = newOwner;
    }

    function claimOwnership() public {
        require(msg.sender == _NEW_OWNER_, "INVALID_CLAIM");
        emit OwnershipTransferred(_OWNER_, _NEW_OWNER_);
        _OWNER_ = _NEW_OWNER_;
        _NEW_OWNER_ = address(0);
    }
}

// File: contracts/external/ERC20/InitializableMintableERC20.sol




contract InitializableMintableERC20 is InitializableOwnable {
    using SafeMath for uint256;

    string public name;
    uint256 public decimals;
    string public symbol;
    uint256 public totalSupply;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) internal allowed;

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    event Mint(address indexed user, uint256 value);
    event Burn(address indexed user, uint256 value);

    function init(
        address _creator,
        uint256 _initSupply,
        string memory _name,
        string memory _symbol,
        uint256 _decimals
    ) public {
        initOwner(_creator);
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _initSupply;
        balances[_creator] = _initSupply;
        emit Transfer(address(0), _creator, _initSupply);
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        require(to != address(0), "TO_ADDRESS_IS_EMPTY");
        require(amount <= balances[msg.sender], "BALANCE_NOT_ENOUGH");

        balances[msg.sender] = balances[msg.sender].sub(amount);
        balances[to] = balances[to].add(amount);
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function balanceOf(address owner) public view returns (uint256 balance) {
        return balances[owner];
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        require(to != address(0), "TO_ADDRESS_IS_EMPTY");
        require(amount <= balances[from], "BALANCE_NOT_ENOUGH");
        require(amount <= allowed[from][msg.sender], "ALLOWANCE_NOT_ENOUGH");

        balances[from] = balances[from].sub(amount);
        balances[to] = balances[to].add(amount);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(amount);
        emit Transfer(from, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return allowed[owner][spender];
    }

    function mint(address user, uint256 value) external onlyOwner {
        balances[user] = balances[user].add(value);
        totalSupply = totalSupply.add(value);
        emit Mint(user, value);
        emit Transfer(address(0), user, value);
    }

    function burn(address user, uint256 value) external onlyOwner {
        balances[user] = balances[user].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Burn(user, value);
        emit Transfer(user, address(0), value);
    }
}

// File: contracts/Factory/ERC20Factory.sol





/**
 * @title DODO ERC20Factory
 * @author DODO Breeder
 *
 * @notice Help user to create erc20 token
 */
contract ERC20Factory {
    // ============ Templates ============

    address public immutable _CLONE_FACTORY_;
    address public immutable _ERC20_TEMPLATE_;
    address public immutable _MINTABLE_ERC20_TEMPLATE_;

    // ============ Events ============

    event NewERC20(address erc20, address creator, bool isMintable);

    // ============ Functions ============

    constructor(
        address cloneFactory,
        address erc20Template,
        address mintableErc20Template
    ) public {
        _CLONE_FACTORY_ = cloneFactory;
        _ERC20_TEMPLATE_ = erc20Template;
        _MINTABLE_ERC20_TEMPLATE_ = mintableErc20Template;
    }

    function createStdERC20(
        uint256 totalSupply,
        string memory name,
        string memory symbol,
        uint256 decimals
    ) external returns (address newERC20) {
        newERC20 = ICloneFactory(_CLONE_FACTORY_).clone(_ERC20_TEMPLATE_);
        InitializableERC20(newERC20).init(msg.sender, totalSupply, name, symbol, decimals);
        emit NewERC20(newERC20, msg.sender, false);
    }

    function createMintableERC20(
        uint256 initSupply,
        string memory name,
        string memory symbol,
        uint256 decimals
    ) external returns (address newMintableERC20) {
        newMintableERC20 = ICloneFactory(_CLONE_FACTORY_).clone(_MINTABLE_ERC20_TEMPLATE_);
        InitializableMintableERC20(newMintableERC20).init(
            msg.sender,
            initSupply,
            name,
            symbol,
            decimals
        );
        emit NewERC20(newMintableERC20, msg.sender, true);
    }
}