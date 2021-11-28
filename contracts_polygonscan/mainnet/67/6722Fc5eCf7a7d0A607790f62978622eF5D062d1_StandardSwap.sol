/**
 *Submitted for verification at polygonscan.com on 2021-11-27
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/******************************************/
/*           IERC20 starts here           */
/******************************************/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/******************************************/
/*      IUniswapV2Pair starts here        */
/******************************************/

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

/******************************************/
/*       BenchmarkSync starts here        */
/******************************************/

abstract contract BenchmarkSync 
{
    function syncPools() external virtual;
}

/******************************************/
/*        Benchmark starts here           */
/******************************************/

contract Benchmark {

    address public owner;              // Used for authentication
    address public newOwner;

    uint8 public decimals;
    uint256 public totalSupply;
    string public name;
    string public symbol;

    uint256 private constant MAX_UINT256 = ~uint256(0);   // (2^256) - 1
    uint256 private constant MAXSUPPLY = ~uint128(0);  // (2^128) - 1

    uint256 private totalAtoms;
    uint256 internal atomsPerMolecule;

    int256 public latestPrice;
    int256 public targetPrice;
    address public pairAddress;

    BenchmarkSync public SYNC = BenchmarkSync(0x4C3aA5160aE34210CC5B783Cd642e4bAACF34b40);

    mapping (address => uint256) internal atomBalances;
    mapping (address => mapping (address => uint256)) private allowedMolecules;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event LogRebase(uint256 _totalSupply);
    event LogNewRebaseOracle(address _rebaseOracle);
    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor()
    {
        decimals = 9;                               // decimals  
        totalSupply = 10000000*10**9;               // initialSupply
        name = "Benchmark";                         // Set the name for display purposes
        symbol = "MARK";                            // Set the symbol for display purposes

        owner = msg.sender;
        totalAtoms = MAX_UINT256 - (MAX_UINT256 % totalSupply);
        atomBalances[address(this)] = totalAtoms;
        atomsPerMolecule = totalAtoms / totalSupply;

        emit Transfer(address(0), address(this), totalSupply);
    }

    /**
     * @dev Propose a new owner.
     * @param _newOwner The address of the new owner.
     */
    function transferOwnership(address _newOwner) public
    {
        require(msg.sender == owner, "Can only be executed by owner.");
        require(_newOwner != address(0), "0x00 address not allowed.");
        newOwner = _newOwner;
    }

    /**
     * @dev Accept new owner.
     */
    function acceptOwnership() public
    {
        require(msg.sender == newOwner, "Sender not authorized.");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }

    /**
     * @dev Set the pair address for price discovery.
     * @param _pairAddress The DEX address of the token pair.
     */
    function setPairAddress(address _pairAddress) public
    {
        require(msg.sender == owner, "Can only be executed by owner.");
        require(_pairAddress != address(0), "0x00 address not allowed.");
        pairAddress = _pairAddress;
    }

    /**
     * @dev Set the target price for rebase.
     * @param _targetPrice The new target price.
     */
    function setTargetPrice(int256 _targetPrice) public
    {
        require(msg.sender == owner, "Can only be executed by owner.");
        targetPrice = _targetPrice;
    }

    /**
     * @dev Set the contract for syncing DEX pools.
     * @param _SYNC The SYNC address.
     */
    function setSync(address _SYNC) public
    {
        require(msg.sender == owner, "Can only be executed by owner.");
        require(_SYNC != address(0), "0x00 address not allowed.");
        SYNC = BenchmarkSync(_SYNC);
    }

    /**
     * @dev Notifies Benchmark contract about a new rebase cycle.
     * @param supplyDelta The number of new molecule tokens to add into or remove from circulation.
     * @param increaseSupply Whether to increase or decrease the total supply.
     * @return The total number of molecules after the supply adjustment.
     */
    function rebase(uint256 supplyDelta, bool increaseSupply) internal returns (uint256) {
        
        if (supplyDelta == 0) {
            emit LogRebase(totalSupply);
            return totalSupply;
        }

        if (increaseSupply == true) {
            totalSupply = totalSupply + supplyDelta;
        } else {
            totalSupply = totalSupply - supplyDelta;
        }

        if (totalSupply > MAXSUPPLY) {
            totalSupply = MAXSUPPLY;
        }

        atomsPerMolecule = totalAtoms / totalSupply;

        emit LogRebase(totalSupply);
        return totalSupply;
    }

    /**
     * @param who The address to query.
     * @return The balance of the specified address.
     */
    function balanceOf(address who) public view returns (uint256) {
        return atomBalances[who] / atomsPerMolecule;
    }

    /**
     * @dev Transfer tokens to a specified address.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     * @return True on success, false otherwise.
     */
    function transfer(address to, uint256 value) public returns (bool) {
        require(to != address(0),"Invalid address.");
        require(to != address(this),"Molecules contract can't receive MARK.");

        initiateRebase();
        uint256 atomValue = value * atomsPerMolecule;

        atomBalances[msg.sender] = atomBalances[msg.sender] - atomValue;
        atomBalances[to] = atomBalances[to] + atomValue;

        emit Transfer(msg.sender, to, value);
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner has allowed to a spender.
     * @param owner_ The address which owns the funds.
     * @param spender The address which will spend the funds.
     * @return The number of tokens still available for the spender.
     */
    function allowance(address owner_, address spender) public view returns (uint256) {
        return allowedMolecules[owner_][spender];
    }

    /**
     * @dev Transfer tokens from one address to another.
     * @param from The address you want to send tokens from.
     * @param to The address you want to transfer to.
     * @param value The amount of tokens to be transferred.
     */
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(to != address(0),"Invalid address.");
        require(to != address(this),"Molecules contract can't receive MARK.");

        initiateRebase();
        allowedMolecules[from][msg.sender] = allowedMolecules[from][msg.sender] - value;

        uint256 atomValue = value * atomsPerMolecule;
        atomBalances[from] = atomBalances[from] - atomValue;
        atomBalances[to] = atomBalances[to] + atomValue;
        
        emit Transfer(from, to, value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of
     * msg.sender. This method is included for ERC20 compatibility.
     * IncreaseAllowance and decreaseAllowance should be used instead.
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value) public returns (bool) {
        allowedMolecules[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner has allowed to a spender.
     * This method should be used instead of approve() to avoid the double approval vulnerability.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        allowedMolecules[msg.sender][spender] = allowedMolecules[msg.sender][spender] + addedValue;

        emit Approval(msg.sender, spender, allowedMolecules[msg.sender][spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner has allowed to a spender.
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 oldValue = allowedMolecules[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            allowedMolecules[msg.sender][spender] = 0;
        } else {
            allowedMolecules[msg.sender][spender] = oldValue - subtractedValue;
        }
        emit Approval(msg.sender, spender, allowedMolecules[msg.sender][spender]);
        return true;
    }

    /**
     * @dev Returns the absolute value of a signed integer.
     */
    function abs(int x) private pure returns (int) {
        return x >= 0 ? x : -x;
    }

    /**
     * @dev Returns the current token price from the DEX pair.
     */
    function getTokenPrice() public view returns(uint) {
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
        (uint Res0, uint Res1,) = pair.getReserves();
        return(Res0 * 1e12/Res1);
    }

    /**
     * @dev Prepares rebase and calculates new total supply.
     */
    function initiateRebase() public {
        latestPrice = int(getTokenPrice());
        int256 rebasePercentage = (latestPrice - targetPrice) * 1e18 / targetPrice;
        uint256 absolutePercentage = uint256(abs(rebasePercentage));
        uint256 supplyDelta = this.totalSupply() * absolutePercentage / 1e18;
        bool increaseSupply = rebasePercentage >= 0 ? true : false;
       
        rebase(supplyDelta, increaseSupply);
        SYNC.syncPools();
    }
}

/******************************************/
/*       StandardSwap starts here         */
/******************************************/

contract StandardSwap is Benchmark {
    
    uint256 public constant atomsPerStandard = 5483741274165310000000000000000000000000000000000000000000000;
    IERC20 public constant STANDARD = IERC20(0xf153EfF70DC0bf3b085134928daeEA248d9B30d0);
    
    event SwapIn(address indexed _from, address indexed _to, uint256 _standardValue, uint256 _markValue);
    event SwapOut(address indexed _from, address indexed _to, uint256 _standardValue, uint256 _markValue);
    


    /**
     * @dev Swaps Standard into Benchmark at a fixed atom ratio.
     */
    function swapIn(uint256 value) public returns (bool) {
        STANDARD.transferFrom(msg.sender, address(this), value);

        uint256 atomValue = value * atomsPerStandard;

        atomBalances[address(this)] = atomBalances[address(this)] - atomValue;
        atomBalances[msg.sender] = atomBalances[msg.sender] + atomValue;

        emit SwapIn(address(this), msg.sender, value, atomValue / atomsPerMolecule);
        return true;
    }
    
    /**
     * @dev Swaps Benchmark into Standard at a fixed atom ratio.
     */
    function swapOut(uint256 value) public returns (bool) {
        uint256 atomValue = value * atomsPerMolecule;
        
        atomBalances[msg.sender] = atomBalances[msg.sender] - atomValue;
        atomBalances[address(this)] = atomBalances[address(this)] + atomValue;
        
        STANDARD.transfer(msg.sender, atomValue / atomsPerStandard);
        
        emit SwapOut(msg.sender, address(this), atomValue / atomsPerStandard, value);
        return true;
    }
}