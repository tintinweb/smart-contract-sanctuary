pragma solidity ^0.8.0;

import "./Token.sol";
import "./interfaces/IOracle.sol";

contract Treasury {
    Token public shares;
    Token public tokens;
    IOracle public oracle;

    enum Policy { Neutral, Expand, Contract }
    struct Cycle {
        Policy policy;
        uint256 timeStarted;
        uint256 amountToMint;
        uint256 totalBids;
    }

    uint256 public constant PEG_PRICE = 1e6;
    uint256 public constant CYCLE_INTERVAL = 10;

    uint256 currCycle = 0;
    
    uint256 public tokenPrice;
    uint256 public sharePrice;

    mapping(uint256 => Cycle) public cycles;
    mapping(uint256 => uint256) public bids;

    event CycleStarted(uint256 indexed id, Policy policy, uint256 blockNumber);

    constructor(
        address _token,
        address _shares,
        address _oracle
    ) {
        shares = Token(_shares);
        tokens = Token(_token);
        oracle = IOracle(_oracle);

        cycles[currCycle] = Cycle(Policy.Neutral, block.number, 0, 0);
        emit CycleStarted(currCycle, Policy.Neutral, block.number);
    }

    function startCycle() public {
        require(block.number > cycles[currCycle].timeStarted + CYCLE_INTERVAL);

        // Burn old bids
        if (cycles[currCycle].policy == Policy.Expand) tokens.burn(cycles[currCycle].totalBids);
        else if (cycles[currCycle].policy == Policy.Contract) shares.burn(cycles[currCycle].totalBids);

        uint target =  tokens.totalSupply() * tokenPrice / PEG_PRICE;
        Policy newPolicy;
        uint256 amountToMint;
        
        currCycle += 1;
        if(tokenPrice == PEG_PRICE)
            newPolicy = Policy.Neutral;
        else if(getTokenPrice() > PEG_PRICE) {
            newPolicy = Policy.Expand;
            amountToMint = (tokens.totalSupply() - target) * 10 / 100;
        }
        else if(getTokenPrice() < PEG_PRICE) {
            newPolicy = Policy.Contract;
            amountToMint = (tokens.totalSupply() - target) * PEG_PRICE / sharePrice;
        }

        currCycle += 1;
        
        cycles[currCycle] = Cycle(newPolicy, block.number, amountToMint, 0);
        emit CycleStarted(currCycle, newPolicy, block.number);
    }

    function setCoinPrice(uint256 _price) public {
        require(msg.sender == address(oracle));
        tokenPrice = _price;
    }
    
    function setSharePrice(uint256 _price) public {
        require(msg.sender == address(oracle));
        sharePrice = _price;
    }

    function getTokenPrice() view public returns (uint256) {
        return tokenPrice;
    }

    function getSharePrice() view public returns (uint256) {
        return sharePrice;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IERC20.sol";

contract Token is IERC20 {
    string public name;
    string public symbol;

    uint256 public decimals;
    uint256 public totalSupply;

    address treasury;

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowances;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _decimals,
        uint256 _initialSupply
    ) {
        name = _name;
        symbol = _symbol;

        decimals = _decimals;
        totalSupply = _initialSupply;

        treasury = msg.sender;

        balances[msg.sender] = _initialSupply;
        emit Transfer(address(0), msg.sender, _initialSupply);
    }

    /**********  Utility Functions  **********/
    function transferTreasury(address _new) public onlyTreasury {
        treasury = _new;
    }

    /**********  ERC20 Functions  **********/
    function balanceOf(address _owner) external view override returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) external override returns (bool success) {
        require(_to != address(0));
        require(balances[msg.sender] >= _value);

        balances[msg.sender] -= _value;
        balances[_to] += _value;

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

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

    function approve(address _spender, uint256 _value) external override returns (bool success) {
        allowances[msg.sender][_spender] += _value;

        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) external view override returns (uint256 remaining) {
        return allowances[_owner][_spender];
    }

    /**********  ERC20 Extensions  **********/
    function mint(address _to, uint256 _amount) public onlyTreasury {
        totalSupply += _amount;
        balances[_to] += _amount;

        emit Transfer(address(0), _to, _amount);
    }

    function burn(uint256 _amount) public {
        require(balances[msg.sender] >= _amount);

        totalSupply -= _amount;
        balances[msg.sender] -= _amount;

        emit Transfer(msg.sender, address(0), _amount);
    }

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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOracle {
    function getPrice() external view returns (uint256);
}

// https://eips.ethereum.org/EIPS/eip-20
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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