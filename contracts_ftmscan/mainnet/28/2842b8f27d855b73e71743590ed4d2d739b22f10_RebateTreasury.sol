/**
 *Submitted for verification at FtmScan.com on 2022-01-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IOracle {
    function update() external;
    function consult(address _token, uint256 _amountIn) external view returns (uint144 amountOut);
    function twap(address _token, uint256 _amountIn) external view returns (uint144 _amountOut);
}

interface ITreasury {
    function epoch() external view returns (uint256);
}

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

contract RebateTreasury is Ownable {

    struct Asset {
        bool isAdded;
        uint256 multiplier;
        address oracle;
        bool isLP;
        address pair;
    }

    struct VestingSchedule {
        uint256 amount;
        uint256 period;
        uint256 end;
        uint256 claimed;
        uint256 lastClaimed;
    }

    IERC20 public Tomb;
    IOracle public TombOracle;
    ITreasury public Treasury;

    mapping (address => Asset) assets;
    mapping (address => VestingSchedule) vesting;

    uint256 public bondThreshold = 20 * 1e4;
    uint256 public bondFactor = 120 * 1e4;
    uint256 public secondaryThreshold = 100 * 1e4;
    uint256 public secondaryFactor = 40 * 1e4;

    uint256 public bondVesting = 3 days;
    uint256 public totalVested = 0;

    uint256 public lastBuyback;
    uint256 public buybackAmount = 1000;

    uint256 public constant DENOMINATOR = 1e6;

    /*
     * ---------
     * MODIFIERS
     * ---------
     */
    
    // Only allow a function to be called with a bondable asset

    modifier onlyAsset(address token) {
        require(assets[token].isAdded, "RebateTreasury: token is not a bondable asset");
        _;
    }

    /*
     * ------------------
     * EXTERNAL FUNCTIONS
     * ------------------
     */

    // Initialize parameters

    constructor() {
        Tomb = IERC20(0x0000000000000000000000000000000000000000);
        TombOracle = IOracle(0x0000000000000000000000000000000000000000);
        Treasury = ITreasury(0x0000000000000000000000000000000000000000);
    }
    
    // Bond asset for discounted Tomb at bond rate

    function bond(address token, uint256 amount) external onlyAsset(token) {
        require(amount > 0, "RebateTreasury: invalid bond amount");
        uint256 tombAmount = getTombReturn(token, amount);
        require(tombAmount <= Tomb.balanceOf(address(this)) - totalVested, "RebateTreasury: insufficient tomb balance");

        IERC20(token).transferFrom(msg.sender, address(this), amount);
        _claimVested(msg.sender);

        VestingSchedule storage schedule = vesting[msg.sender];
        schedule.amount = schedule.amount - schedule.claimed + tombAmount;
        schedule.period = bondVesting;
        schedule.end = block.timestamp + bondVesting;
        schedule.claimed = 0;
        schedule.lastClaimed = block.timestamp;
        totalVested += tombAmount;
    }

    // Claim available Tomb rewards from bonding

    function claimRewards() external {
        _claimVested(msg.sender);
    }

    /*
     * --------------------
     * RESTRICTED FUNCTIONS
     * --------------------
     */
    
    // Set Tomb token

    function setTomb(address tomb) external onlyOwner {
        Tomb = IERC20(tomb);
    }

    // Set Tomb oracle

    function setTombOracle(address oracle) external onlyOwner {
        TombOracle = IOracle(oracle);
    }

    // Set Tomb treasury

    function setTreasury(address treasury) external onlyOwner {
        Treasury = ITreasury(treasury);
    }
    
    // Set bonding parameters of token
    
    function setAsset(
        address token,
        bool isAdded,
        uint256 multiplier,
        address oracle,
        bool isLP,
        address pair
    ) external onlyOwner {
        assets[token].isAdded = isAdded;
        assets[token].multiplier = multiplier;
        assets[token].oracle = oracle;
        assets[token].isLP = isLP;
        assets[token].pair = pair;
    }

    // Set bond pricing parameters

    function setBondParameters(
        uint256 primaryThreshold,
        uint256 primaryFactor,
        uint256 secondThreshold,
        uint256 secondFactor,
        uint256 vestingPeriod
    ) external onlyOwner {
        bondThreshold = primaryThreshold;
        bondFactor = primaryFactor;
        secondaryThreshold = secondThreshold;
        secondaryFactor = secondFactor;
        bondVesting = vestingPeriod;
    }

    // Redeem assets for buyback under peg

    function redeemAssetsForBuyback(address[] calldata tokens) external onlyOwner {
        require(getTombPrice() < 1e18, "RebateTreasury: unable to buy back");
        uint256 epoch = Treasury.epoch();
        require(lastBuyback != epoch, "RebateTreasury: already bought back");
        lastBuyback = epoch;

        for (uint256 t = 0; t < tokens.length; t ++) {
            require(assets[tokens[t]].isAdded, "RebateTreasury: invalid token");
            IERC20 Token = IERC20(tokens[t]);
            Token.transfer(owner(), Token.balanceOf(address(this)) * buybackAmount / DENOMINATOR);
        }
    }

    /*
     * ------------------
     * INTERNAL FUNCTIONS
     * ------------------
     */

    function _claimVested(address account) internal {
        VestingSchedule storage schedule = vesting[account];
        if (schedule.amount == 0 || schedule.amount == schedule.claimed) return;
        if (block.timestamp <= schedule.lastClaimed || schedule.lastClaimed >= schedule.end) return;

        uint256 duration = (block.timestamp > schedule.end ? schedule.end : block.timestamp) - schedule.lastClaimed;
        uint256 claimable = schedule.amount * duration / schedule.period;
        if (claimable == 0) return;

        schedule.claimed += claimable;
        schedule.lastClaimed = block.timestamp > schedule.end ? schedule.end : block.timestamp;
        totalVested -= claimable;
        Tomb.transfer(account, claimable);
    }

    /*
     * --------------
     * VIEW FUNCTIONS
     * --------------
     */

    // Calculate Tomb return of bonding amount of token

    function getTombReturn(address token, uint256 amount) public view onlyAsset(token) returns (uint256) {
        uint256 tombPrice = getTombPrice();
        uint256 tokenPrice = getTokenPrice(token);
        uint256 bondPremium = getBondPremium();
        return amount * tokenPrice * (bondPremium + DENOMINATOR) * assets[token].multiplier / (DENOMINATOR * DENOMINATOR) / tombPrice;
    }

    // Calculate premium for bonds based on bonding curve

    function getBondPremium() public view returns (uint256) {
        uint256 tombPrice = getTombPrice();
        if (tombPrice < 1e18) return 0;

        uint256 tombPremium = tombPrice * DENOMINATOR / 1e18 - DENOMINATOR;
        if (tombPremium < bondThreshold) return 0;
        if (tombPremium <= secondaryThreshold) {
            return (tombPremium - bondThreshold) * bondFactor / DENOMINATOR;
        } else {
            uint256 primaryPremium = (secondaryThreshold - bondThreshold) * bondFactor / DENOMINATOR;
            return primaryPremium + (tombPremium - secondaryThreshold) * secondaryFactor / DENOMINATOR;
        }
    }

    // Get TOMB price from Oracle

    function getTombPrice() public view returns (uint256) {
        return TombOracle.consult(address(Tomb), 1e18);
    }

    // Get token price from Oracle

    function getTokenPrice(address token) public view onlyAsset(token) returns (uint256) {
        Asset memory asset = assets[token];
        uint256 tokenPrice = IOracle(asset.oracle).consult(token, 1e18);
        if (!asset.isLP) return tokenPrice;

        IUniswapV2Pair Pair = IUniswapV2Pair(asset.pair);
        uint256 totalPairSupply = Pair.totalSupply();
        address token0 = Pair.token0();
        (uint256 reserve0, uint256 reserve1,) = Pair.getReserves();

        if (token0 == token) {
            return tokenPrice * reserve0 * 1e18 / totalPairSupply / 1e18 +
                   reserve1 * 1e18 / totalPairSupply;
        } else {
            return tokenPrice * reserve1 * 1e18 / totalPairSupply / 1e18 +
                   reserve0 * 1e18 / totalPairSupply;
        }
    }

    // Get claimable vested Tomb for account

    function claimableTomb(address account) external view returns (uint256) {
        VestingSchedule memory schedule = vesting[account];
        if (block.timestamp <= schedule.lastClaimed || schedule.lastClaimed >= schedule.end) return 0;
        uint256 duration = (block.timestamp > schedule.end ? schedule.end : block.timestamp) - schedule.lastClaimed;
        return schedule.amount * duration / schedule.period;
    }

}