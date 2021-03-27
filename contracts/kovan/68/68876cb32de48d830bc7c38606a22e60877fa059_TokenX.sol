/**
 *Submitted for verification at Etherscan.io on 2021-03-27
*/

// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.0;


/// @author CryptosWarehouse, Hélio Rosa
/// @title Ownable interface
interface IOwnable {

    /// @notice OwnershipTransfer is emitted when a transfer of ownership occurs
    /// @param owner The current owner address
    /// @param newOwner The new owner address
    event OwnershipTransfer(address indexed owner, address indexed newOwner);

    /// @return The owner address
    function owner() external view returns (address payable);

    /// @notice Renounces ownership by setting the owner address to 0 and emits a OwnershipTransfer()
    function renounceOwnership() external;

    /// @notice Transfer ownership to the new owner address and emits a OwnershipTransfer()
    /// @param newOwner The new owner
    function transferOwnership(address payable newOwner) external;
}


/// @author CryptosWarehouse, Hélio Rosa
/// @title ERC20 token interface
interface IERC20 {

    /// @notice Approval is emitted when a token approval occurs
    /// @param owner The address that approved an allowance
    /// @param spender The address of the approved spender
    /// @param value The amount approved
    event Approval(address indexed owner, address indexed spender, uint value);

    /// @notice Transfer is emitted when a transfer occurs
    /// @param from The address that owned the tokens
    /// @param to The address of the new owner
    /// @param value The amount transfered
    event Transfer(address indexed from, address indexed to, uint value);

    /// @return Token name
    function name() external view returns (string memory);

    /// @return Token symbol
    function symbol() external view returns (string memory);

    /// @return Token decimals
    function decimals() external view returns (uint8);

    /// @return Total token supply
    function totalSupply() external view returns (uint);

    /// @param owner The address to query
    /// @return owner balance
    function balanceOf(address owner) external view returns (uint);

    /// @param owner The owner ot the tokens
    /// @param spender The approved spender of the tokens
    /// @return Allowed balance for spender
    function allowance(address owner, address spender) external view returns (uint);

    /// @notice Approves the provided amount to the provided spender address
    /// @param spender The spender address
    /// @param amount The amount to approve
    /// @return true on success
    function approve(address spender, uint256 amount) external returns (bool);

    /// @notice Transfers tokens to the provided address
    /// @param to The new owner address
    /// @param amount The amount to transfer
    /// @return true on success
    function transfer(address to, uint256 amount) external returns (bool);

    /// @notice Transfers tokens from an approved address to the provided address
    /// @param from The tokens owner address
    /// @param to The new owner address
    /// @param amount The amount to transfer
    /// @return true on success
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}


/// @author Hélio Rosa
/// @title Mintable ERC20 interface
interface IERC20Mintable {

    /// @notice Mint is emitted when a tokens are minted
    /// @param owner The owner address
    /// @param amount The amount minted
    event Mint(address indexed owner, uint256 amount);

    /// @notice Mints tokens and emits a Mint()
    /// @param owner The owner address
    /// @param amount The amount to mint
    function mint(address owner, uint256 amount) external;
}


/// @author Hélio Rosa
/// @title Burnable ERC20 interface
interface IERC20Burnable {

    /// @notice Burn is emitted when tokens are burned
    /// @param owner The owner address
    /// @param amount The amount burned
    event Burn(address indexed owner, uint256 amount);

    /// @notice Burns tokens and emits a Burn()
    /// @param owner The owner address
    /// @param amount The amount to burn
    function burn(address owner, uint256 amount) external;
}

/// @author CryptosWarehouse, Hélio Rosa
/// @title Ownable contract
contract Ownable is IOwnable {

    /// @return The owner address
    address payable public override owner;

    /// @notice contract constructor
    constructor () {
        owner = payable(msg.sender);
        emit OwnershipTransfer(address(0), owner);
    }

    /// @dev Checks if the calling address is the owner
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /// @notice Renounces ownership by setting the owner address to 0 and emits a OwnershipTransfer()
    function renounceOwnership() external override onlyOwner {
        address oldOwner = owner;
        owner = payable(0);
        emit OwnershipTransfer(oldOwner, owner);
    }

    /// @notice Transfer ownership to the new owner address and emits a OwnershipTransfer()
    /// @param newOwner The new owner
    function transferOwnership(address payable newOwner) external override onlyOwner {
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransfer(oldOwner, newOwner);
    }
}

/// @author CryptosWarehouse, Hélio Rosa
/// @title ERC20 token
contract ERC20 is IERC20 {

    /// @return Token name
    string public override name;

    /// @return Token symbol
    string public override symbol;

    /// @return Token decimals
    uint8 public override decimals;

    /// @return Total token supply
    uint256 public override totalSupply;

    /// @return Balance for owner
    mapping(address => uint256) public override balanceOf;

    /// @return Allowed balance for spender
    mapping(address => mapping(address => uint256)) public override allowance;

    /// @notice contract constructor
    /// @param _name The token name
    /// @param _symbol The token symbol
    /// @param _decimals The token decimals
    constructor (
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    /// @dev Checks if owner has enough balance
    /// @param owner The owner address
    /// @param amount The amount required
    modifier enoughBalance(address owner, uint256 amount) {
        require(balanceOf[owner] >= amount, "not enough balance");
        _;
    }

    /// @dev Checks if spender has enough approved balance
    /// @param owner The owner address
    /// @param spender The spender address
    /// @param amount The amount required
    modifier enoughAllowance(address owner, address spender, uint256 amount) {
        require(allowance[owner][spender] >= amount, "not enough allowance");
        _;
    }

    /// @dev Checks if the address is zero
    /// @param addr The address
    modifier noZeroAddress(address addr) {
        require(addr != address(0), "zero address is not allowed");
        _;
    }

    /// @notice Transfers tokens to the provided address
    /// @param to The new owner address
    /// @param amount The amount to transfer
    /// @return true on success
    function transfer(address to, uint256 amount)
        public virtual override
        enoughBalance(msg.sender, amount)
        noZeroAddress(to)
        returns (bool)
    {
        _transfer(msg.sender, to, amount);
        return true;
    }

    /// @notice Approves the provided amount to the provided spender address
    /// @param spender The spender address
    /// @param amount The amount to approve
    /// @return true on success
    function approve(address spender, uint256 amount)
        public override
        noZeroAddress(spender)
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /// @notice Transfers tokens from an approved address to the provided address
    /// @param from The tokens owner address
    /// @param to The new owner address
    /// @param amount The amount to transfer
    /// @return true on success
    function transferFrom(address from, address to, uint256 amount)
        public virtual override
        noZeroAddress(from)
        noZeroAddress(to)
        enoughBalance(from, amount)
        enoughAllowance(from, msg.sender, amount)
        returns (bool)
    {
        if (allowance[from][msg.sender] != uint256(int256(-1))) {
            allowance[from][msg.sender] -= amount;
        }
        _transfer(from, to, amount);
        return true;
    }

    /// @dev makes a token transfer and emits a Transfer()
    /// @param from The origin address
    /// @param to The destination address
    /// @param amount The amount to transfer
    function _transfer(address from, address to, uint256 amount) internal {
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
    }

    /// @dev approves an amount and emits an Approval()
    /// @param owner The owner address
    /// @param spender The spender address
    /// @param amount The amount to approve
    function _approve(address owner, address spender, uint256 amount) internal {
        allowance[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

/// @author Hélio Rosa
/// @title Mintable ERC20 token
abstract contract ERC20Mintable is IERC20Mintable, ERC20, Ownable {

    /// @notice Mints tokens and emits a Mint()
    /// @param owner The owner address
    /// @param amount The amount to mint
    function mint(address owner, uint256 amount)
        public override
        onlyOwner
    {
        _mint(owner, amount);
    }

    /// @dev Mints tokens and emits a Mint()
    /// @param owner The owner address
    /// @param amount The amount to mint
    function _mint(address owner, uint256 amount) internal {
        balanceOf[owner] += amount;
        totalSupply += amount;
        emit Mint(owner, amount);
    }
}


/// @author Hélio Rosa
/// @title Burnable ERC20 token
abstract contract ERC20Burnable is IERC20Burnable, ERC20, Ownable {

    /// @notice Burns tokens and emits a Burn()
    /// @param owner The owner address
    /// @param amount The amount to burn
    function burn(address owner, uint256 amount)
        public override
        onlyOwner
        enoughBalance(owner, amount)
    {
        _burn(owner, amount);
    }

    /// @dev Burns tokens and emits a Burn()
    /// @param owner The owner address
    /// @param amount The amount to burn
    function _burn(address owner, uint256 amount) internal {
        balanceOf[owner] -= amount;
        totalSupply -= amount;
        emit Burn(owner, amount);
    }
}

/// @author Hélio Rosa
/// @title TokenX is a mintable/burnable ERC20 token
contract TokenX is ERC20Mintable, ERC20Burnable {

    /// @notice contract constructor
    /// @param _name The token name
    /// @param _symbol The token symbol
    /// @param _decimals The token decimals
    /// @param _owner The owner address for any pre-minted tokens
    /// @param _amount The amount of tokens to pre-mint
    constructor (
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        address _owner,
        uint256 _amount
    ) ERC20(_name, _symbol, _decimals)
    {
        if (_amount > 0) {
        if (_owner == address(0)) {
            _owner = msg.sender;
        }
        _mint(_owner, _amount);
        }
    }
}