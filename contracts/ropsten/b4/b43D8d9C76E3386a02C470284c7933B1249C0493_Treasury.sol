pragma solidity ^0.8.0;

import "./Token.sol";
import "./interfaces/IOracle.sol";

/// @title Treasury
/// @notice Handles creating and destroying new tokens and bonds.
contract Treasury {
    Token public bonds; // bonds contract
    Token public tokens; // Tokens contract
    IOracle public oracle; // Price oracle

    enum Policy { Neutral, Expand, Contract }
    struct Cycle {
        // A treasury cycle
        Policy policy;
        uint256 timeStarted;
        uint256 amountToMint;
        uint256 totalBids;
    }

    uint256 public constant PEG_PRICE = 1e6; // $1
    uint256 public constant CYCLE_INTERVAL = 10; // Time between cycles in block.

    uint256 currCycle = 0; // Current cycle index.

    uint256 public tokenPrice;
    uint256 public bondPrice;

    mapping(uint256 => Cycle) public cycles;
    mapping(uint256 => mapping(address => uint256)) public bids;

    event CycleStarted(uint256 indexed id, Policy policy, uint256 blockNumber);

    /// @notice Creates a new Treasury.
    /// @param _token Address of the token contract.
    /// @param _bonds Address of the bonds contract.
    /// @param _oracle Address of the oracle contract.
    constructor(
        address _token,
        address _bonds,
        address _oracle
    ) {
        bonds = Token(_bonds);
        tokens = Token(_token);
        oracle = IOracle(_oracle);

        cycles[currCycle] = Cycle(Policy.Neutral, block.number, 0, 0);
        emit CycleStarted(currCycle, Policy.Neutral, block.number);
    }

    function buyBonds(uint256 _amount) public {
        tokens.burnFrom(msg.sender, _amount);
        bonds.mint(msg.sender, _amount / getTokenPrice()); // ERC20 contract will handle saftey.

        bids[currCycle][msg.sender] += _amount;
        cycles[currCycle].totalBids += _amount;
    }

    function redeemBonds(uint256 _cycle) public {
        Cycle memory cycle = cycles[_cycle];

        require(block.number > cycle.timeStarted + CYCLE_INTERVAL);
        require(bids[_cycle][msg.sender] > 0);
        require(cycles[currCycle].policy == Policy.Expand);

        tokens.mint(msg.sender, bids[_cycle][msg.sender] * cycles[_cycle].amountToMint / cycles[_cycle].totalBids);
    }

    /// @notice Starts a new treasury cycle (burn old bids, set policy.)
    function startCycle() public {
        require(block.number > cycles[currCycle].timeStarted + CYCLE_INTERVAL);

        // Burn old bids
        if (cycles[currCycle].policy == Policy.Expand) tokens.burn(cycles[currCycle].totalBids);
        else if (cycles[currCycle].policy == Policy.Contract) bonds.burn(cycles[currCycle].totalBids);

        uint256 target = (tokens.totalSupply() * tokenPrice) / PEG_PRICE;
        Policy newPolicy;
        uint256 amountToMint;

        currCycle += 1;
        if (tokenPrice == PEG_PRICE) newPolicy = Policy.Neutral;
        else if (getTokenPrice() > PEG_PRICE) {
            newPolicy = Policy.Expand;
            amountToMint = ((tokens.totalSupply() - target) * 10) / 100;
        } else if (getTokenPrice() < PEG_PRICE) {
            newPolicy = Policy.Contract;
            amountToMint = ((tokens.totalSupply() - target) * PEG_PRICE) / bondPrice;
        }

        currCycle += 1;

        cycles[currCycle] = Cycle(newPolicy, block.number, amountToMint, 0);
        emit CycleStarted(currCycle, newPolicy, block.number);

        if (newPolicy == Policy.Contract) bonds.mint(address(this), amountToMint);
        else if (newPolicy == Policy.Expand) tokens.mint(address(this), amountToMint);
    }

    /// @notice Lets the oracle set the coin/token price.
    function setCoinPrice(uint256 _price) public {
        require(msg.sender == address(oracle));
        tokenPrice = _price;
    }

    /// @notice Lets the oracle set the bond price.
    function setbondPrice(uint256 _price) public {
        require(msg.sender == address(oracle));
        bondPrice = _price;
    }

    function getTokenPrice() public view returns (uint256) {
        return tokenPrice;
    }

    function getBondPrice() public view returns (uint256) {
        return bondPrice;
    }

    function getCurrentPolicy() view public returns (Policy) {
        return cycles[currCycle].policy;
    }

    fallback() external {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IERC20.sol";

/// @title StandardToken
/// @notice Implements a mintable, burnable ERC20 with a variable supply.
contract Token is IERC20 {
    string public name;
    string public symbol;

    uint256 public decimals;
    uint256 public totalSupply;

    address public treasury;

    mapping(address => uint256) public balances; // User balances
    mapping(address => mapping(address => uint256)) public allowances; // User -> User -> Allowed amount

    /// @notice Creates a new token.
    /// @param _name The token's name.
    /// @param _symbol The token's symbol.
    /// @param _decimals The number of decimals.
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _decimals,
        uint256 _initialSupply
    ) {
        // Set state variables
        name = _name;
        symbol = _symbol;

        decimals = _decimals;
        totalSupply = _initialSupply;

        // Temporary.
        treasury = msg.sender;

        balances[msg.sender] = _initialSupply;
        emit Transfer(address(0), msg.sender, _initialSupply);
    }

    /// @notice Transfer ownership.
    /// @param _new The new treasury's address.
    function transferTreasury(address _new) public onlyTreasury {
        treasury = _new;
    }

    /**********  ERC20 Functions  **********/
    /// @inheritdoc IERC20
    function balanceOf(address _owner) external view override returns (uint256 balance) {
        return balances[_owner];
    }

    /// @inheritdoc IERC20
    function transfer(address _to, uint256 _value) external override returns (bool success) {
        require(_to != address(0));
        require(balances[msg.sender] >= _value);

        balances[msg.sender] -= _value;
        balances[_to] += _value;

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /// @inheritdoc IERC20
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external override onlyTreasury returns (bool success) {
        require(_to != address(0));
        require(balances[_from] >= _value);

        balances[_from] -= _value;
        balances[_to] += _value;

        emit Transfer(_from, _to, _value);
        return true;
    }

    /// @inheritdoc IERC20
    function approve(address _spender, uint256 _value) external override returns (bool success) {
        allowances[msg.sender][_spender] += _value;

        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /// @inheritdoc IERC20
    function allowance(address _owner, address _spender) external view override returns (uint256 remaining) {
        return allowances[_owner][_spender];
    }

    /**********  ERC20 Extensions  **********/
    /// @notice Mints new tokens
    /// @param _to The address to send the tokens to.
    /// @param _amount The number of tokens to mint.
    function mint(address _to, uint256 _amount) public onlyTreasury {
        totalSupply += _amount;
        balances[_to] += _amount;

        emit Transfer(address(0), _to, _amount);
    }

    /// @notice Burns tokens.
    /// @param _amount The amount to burn.
    function burn(uint256 _amount) public {
        require(balances[msg.sender] >= _amount);

        totalSupply -= _amount;
        balances[msg.sender] -= _amount;

        emit Transfer(msg.sender, address(0), _amount);
    }

    /// @notice Burns tokens from the specified address (treasury only)
    /// @param _from The address to burn from
    /// @param _amount The amount to burn.
    function burnFrom(address _from, uint256 _amount) public onlyTreasury {
        require(balances[_from] >= _amount);

        totalSupply -= _amount;
        balances[_from] -= _amount;

        emit Transfer(_from, address(0), _amount);
    }

    /**********  Modifiers  **********/
    modifier onlyTreasury() {
        require(msg.sender == treasury);
        _;
    }

    fallback() external {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IOracle
/// @notice Interface for price oracles.
interface IOracle {
    /// @notice Gets the current price.
    function getPrice() external returns (uint256);
}

// https://eips.ethereum.org/EIPS/eip-20
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IERC20
/// @notice Implements the ERC20 interface.
interface IERC20 {
    /// @param _owner The address from which the balance will be retrieved
    /// @return balance the balance
    function balanceOf(address _owner) external view returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return success Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) external returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return success Whether the transfer was successful or not
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return success Whether the approval was successful or not
    function approve(address _spender, uint256 _value) external returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return remaining Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}