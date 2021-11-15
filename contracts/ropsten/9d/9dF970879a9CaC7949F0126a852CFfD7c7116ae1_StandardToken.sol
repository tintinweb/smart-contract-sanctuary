// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./IERC20.sol";
import "../Treasury.sol";
import "../lib/SafeMath.sol";

/**
    @title Token
    @notice Variable supply ERC20 token for tokens and shares.
*/
contract StandardToken is IERC20 {
    using SafeMath for uint256;

    event Mint(address _to, uint256 _amount);
    event Burn(address _to, uint256 _amount);

    /** @notice The address of the treasury. Initially assigned to whoever deploys the contract, but automatically transfered. */
    address public minter;
    Treasury public treasury;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _initialAmount
    ) public IERC20(_name, _symbol, 18, _initialAmount) {
        minter = msg.sender; // Temporary.

        totalSupply = _initialAmount;
        balances[msg.sender] = _initialAmount;
    }

    function setTreasury(address _treasury) public {
        require(msg.sender == minter, "Minter only");
        minter = _treasury;
        treasury = Treasury(_treasury);
    }

    /**
        @notice Mints new shares
        @param _to Where to send the new shares
        @param _amount The amount of shares to mint
    */
    function mint(address _to, uint256 _amount) public treasuryOnly {
        totalSupply += _amount;
        balances[_to] += _amount;

        emit Mint(_to, _amount);
    }

    /**
        @notice Burns shares.
        @param _amount The amount of shares to burn.
    */
    function burn(uint256 _amount) public {
        require(balanceOf(msg.sender) >= _amount, "Insufficent balance.");
        require(_amount <= totalSupply, "Insufficent supply.");

        totalSupply -= _amount;
        balances[msg.sender] -= _amount;

        emit Burn(msg.sender, _amount);
    }

    /**
        @notice Burns shares from a specified address. Only callable by treasury.
        @param _from Address to burn from.
        @param _amount The amount to burn.
    */
    function burnFrom(address _from, uint256 _amount) public treasuryOnly {
        require(_from != address(0), "Null address");
        require(balances[_from] >= _amount, "Insufficient balance.");

        totalSupply -= _amount;
        balances[_from] -= _amount;

        emit Burn(_from, _amount);
    }

    /**
        @notice Function can only be called by treasury.
    */
    modifier treasuryOnly() {
        require(msg.sender == minter, "Minter only.");
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../lib/SafeMath.sol";

/**
    @title Bare-bones Token implementation
    @notice Based on the ERC-20 token standard as defined at
            https://eips.ethereum.org/EIPS/eip-20
 */
contract IERC20 {
    using SafeMath for uint256;

    string public symbol;
    string public name;
    uint256 public decimals;
    uint256 public totalSupply;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    event Transfer(address from, address to, uint256 value);
    event Approval(address owner, address spender, uint256 value);

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _decimals,
        uint256 _totalSupply
    ) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = totalSupply;
    }

    /**
        @notice Getter to check the current balance of an address
        @param _owner Address to query the balance of
        @return Token balance
     */
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    /**
        @notice Getter to check the amount of tokens that an owner allowed to a spender
        @param _owner The address which owns the funds
        @param _spender The address which will spend the funds
        @return The amount of tokens still available for the spender
     */
    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }

    /**
        @notice Approve an address to spend the specified amount of tokens on behalf of msg.sender
        @dev Beware that changing an allowance with this method brings the risk that someone may use both the old
             and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
             race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
             https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        @param _spender The address which will spend the funds.
        @param _value The amount of tokens to be spent.
        @return Success boolean
     */
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /** shared logic for transfer and transferFrom */
    function _transfer(
        address _from,
        address _to,
        uint256 _value
    ) internal {
        require(balances[_from] >= _value, "Insufficient balance");
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
    }

    /**
        @notice Transfer tokens to a specified address
        @param _to The address to transfer to
        @param _value The amount to be transferred
        @return Success boolean
     */
    function transfer(address _to, uint256 _value) public returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /**
        @notice Transfer tokens from one address to another
        @param _from The address which you want to send tokens from
        @param _to The address which you want to transfer to
        @param _value The amount of tokens to be transferred
        @return Success boolean
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool) {
        require(allowed[_from][msg.sender] >= _value, "Insufficient allowance");
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./token/StandardToken.sol";
import "./lib/SafeMath.sol";
import "./interfaces/IDataFeed.sol";

/**
    @title Treasury
    @notice The Treasury is essentially the entry point. It controls the creation and destruction of shares and tokens etc.
*/
contract Treasury {
    StandardToken public token; // Token contract.
    StandardToken public share; // Share contract.
    address public oracle;

    enum Policy {Neutral, Expand, Contract}
    struct Cycle {
        Policy policy;
        uint256 toMint; // # of shares or tokens to mint.
        uint256 startBlock;
        uint256 totalBid;
        mapping(address => uint256) bids; // User -> Bid Amount
    }

    uint256 public index = 0;
    mapping(uint256 => Cycle) public cycles;

    uint256 public constant TIME_BETWEEN_CYCLES = 5; // Time between cycles in blocks.
    uint256 public constant PEG_PRICE = 1e6; // $1 USD

    uint256 public sharePrice = 100e6; // 100 coins to a share.
    uint256 public coinPrice = PEG_PRICE; // $1 to a coin.

    constructor(address _token, address _share) public {
        token = StandardToken(_token);
        share = StandardToken(_share);

        require(
            share.decimals() == 18 && token.decimals() == 18,
            "18 Decimals required."
        );
        cycles[index++] = Cycle(Policy.Neutral, 0, block.number, 0);

        oracle = msg.sender;
    }

    // TODO: update the cycle function with better algo.
    function newCycle() public {
        Cycle memory prevCycle = cycles[index];
        require(block.number > prevCycle.startBlock + TIME_BETWEEN_CYCLES);

        if (prevCycle.policy == Policy.Contract) token.burn(prevCycle.totalBid);
        else if (prevCycle.policy == Policy.Expand)
            share.burn(prevCycle.totalBid);

        Policy newPolicy;
        uint256 amountToMint;
        uint256 target = (token.totalSupply() * coinPrice) / PEG_PRICE;

        if (coinPrice == PEG_PRICE) newPolicy = Policy.Neutral;
        else if (coinPrice > PEG_PRICE) {
            newPolicy = Policy.Expand;
            amountToMint =
                ((token.totalSupply() - target) * PEG_PRICE) /
                sharePrice;
        } else {
            newPolicy = Policy.Contract;
            amountToMint = ((target - token.totalSupply()) * 10) / 100;
        }

        index++;
        cycles[index] = Cycle(newPolicy, amountToMint, block.number, 0);

        if (newPolicy == Policy.Contract) {
            share.mint(address(this), amountToMint);
        } else if (newPolicy == Policy.Expand) {
            token.mint(address(this), amountToMint);
        }
    }

    function updateCoinPrice(uint256 _price) public {
        require(msg.sender == oracle, "Oracle only");
        require(_price > (coinPrice * 9) / 10, "Price change was over 10%.");
        require(_price < (coinPrice * 11) / 10, "Price change was over 10%.");
        coinPrice = _price;
    }

    function placeBid(uint256 amount) public {
        Cycle storage c = cycles[index];

        require(block.number < c.startBlock + TIME_BETWEEN_CYCLES);
        require(c.policy != Policy.Neutral);
        require(amount > PEG_PRICE);

        if (c.policy == Policy.Expand)
            share.transferFrom(msg.sender, address(this), amount);
        else if (c.policy == Policy.Contract)
            token.transferFrom(msg.sender, address(this), amount);

        c.bids[msg.sender] += amount;
        c.totalBid += amount;
    }

    function claimBid(uint256 c) public {
        uint256 bidAmount = cycles[c].bids[msg.sender];

        require(
            block.number > cycles[c].startBlock + TIME_BETWEEN_CYCLES &&
                bidAmount > 0 &&
                cycles[c].policy != Policy.Neutral
        );

        uint256 amountToPay =
            (bidAmount * cycles[c].toMint) / cycles[c].totalBid;

        if (cycles[c].policy == Policy.Expand)
            share.transfer(msg.sender, amountToPay);
        else if (cycles[c].policy == Policy.Contract)
            token.transfer(msg.sender, amountToPay);

        delete cycles[c].bids[msg.sender];
    }

    function updateSharePrice(uint256 _price) public {
        require(msg.sender == oracle, "Oracle only");
        require(_price > (sharePrice * 9) / 10, "Price change was over 10%.");
        require(_price < (sharePrice * 11) / 10, "Price change was over 10%.");
        sharePrice = _price;
    }

    function getUserBids(uint256 id, address user)
        public
        view
        returns (uint256)
    {
        return cycles[id].bids[user];
    }

    function getCurrentBidPrice() public view returns (uint256) {
        Cycle storage c = cycles[index];
        return (c.totalBid * PEG_PRICE) / c.toMint;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
    @title SafeMath
    @dev Math library for uints.
*/
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b <= a);
        c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b > 0);
        c = a / b;
        return c;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

// @title IDataFeed
// @dev Interface for oracles/data feeds.
interface IDataFeed {
    function getValue() external view returns (uint256);
}

