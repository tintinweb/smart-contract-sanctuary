// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IPancakeFactory.sol";
import "./interfaces/IPancakePair.sol";
import "./XtraStaking.sol";
import "./XtraVesting.sol";
import "./XtraInvesting.sol";

/// @title Xtra Fund Contract - https://xtra.fund
/// @author bs
/// @notice Audited by Hacken
contract Xtra is
    ERC20,
    ERC20Burnable,
    Ownable,
    XtraStaking,
    XtraVesting,
    XtraInvesting
{
    /// ----- VARIABLES ----- ///

    /// Pool names
    uint256 internal constant POOL_SEED = 1;
    uint256 internal constant POOL_PRESALE = 2;
    uint256 internal constant POOL_PRESALE2 = 3;
    uint256 internal constant POOL_TEAM = 4;

    /// Max supply
    uint256 internal _seed_tokens = 1e9 ether; //1 mlrd
    uint256 internal _presale_tokens = 2e9 ether; //2 mlrd
    uint256 internal _presale2_tokens = 15e8 ether; //1,5 mlrd
    uint256 internal _sale_tokens = 15e8 ether; //1,5 mlrd
    uint256 internal _team_tokens = 2e9 ether; //2 mlrd
    uint256 internal _lp_tokens = 2e9 ether; //2 mlrd
    uint256 internal _loan_fund = 1e10 ether; //10 mlrd

    /// Token price
    uint256 internal constant _initialTokenPrice = 10**5;

    /// Pancakeswap addresses
    address internal immutable _pancakeFactoryAddress;
    address internal immutable _stableCoinAddress;

    /// Bep20 allocation token address
    address internal immutable _allocationTokenAddress;

    /// ----- CONSTRUCTOR ----- ///
    constructor(
        address _psFactoryAddress,
        address _stableAddress,
        address _allocationToken
    ) ERC20("Xtra Fund Token", "XTRA") {
        _pancakeFactoryAddress = _psFactoryAddress;
        _stableCoinAddress = _stableAddress;
        _allocationTokenAddress = _allocationToken;
        _mint(address(this), 2e10 ether);
    }

    /// ----- VIEWS ----- ///
    ///@notice Returns data with token pools information
    ///@return 0 mintedTokens - Sum of minted tokens
    ///@return 1 totalStaked - Sum of staked tokens
    ///@return 2 seedTokens - Remaining seed tokens
    ///@return 3 presaleTokens - Remaining presale tokens
    ///@return 4 presale2Tokens - Remaining presale round 2 tokens
    ///@return 5 saleTokens - Remaining sale tokens
    ///@return 6 teamTokens - Remaining team tokens
    ///@return 7 lpTokens - Remaining liqudity pool tokens
    ///@return 8 loanTokens - Remaining loan fund tokens
    ///@return 9 xtraTokens - Xtra fund tokens (can be max minted)
    ///@return 10 totalVestings - Sum of tokens in vestings
    ///@return 11 totalInvests - Sum of not activated tokens
    function getTokenStats()
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            totalSupply(),
            _totalStaked,
            _seed_tokens,
            _presale_tokens,
            _presale2_tokens,
            _sale_tokens,
            _team_tokens,
            _lp_tokens,
            _loan_fund,
            _xtra_fund,
            _totalVestings,
            _totalInvestitions
        );
    }

    ///@notice Returns token price
    ///@return tokenPrice - price of token
    function getTokenPrice() external view returns (uint256 tokenPrice) {
        return _getTokenPrice();
    }

    ///@notice Calculates return for selected staking slot with actual token price. If isFromXtra is true xtraAmount will be minted from xtra fund to staker address. Else xtra amount will be burn and added to xtra fund.
    ///@param _stakerAddress - Address of staker
    ///@param _slot - Slot of stake
    ///@return 0 userAmount - amount in xtra tokens returns to user
    ///@return 1 xtraAmount - amount in xtra tokens from/to xtra fund
    ///@return 2 isFromXtra - true if tokens need to be minted from xtra fund. false if tokens will burn and added to xtra fund
    function calculateWithdraw(address _stakerAddress, uint256 _slot)
        external
        view
        returns (
            uint256,
            uint256,
            bool
        )
    {
        (
            uint256 _userAmount,
            uint256 _xtraAmount,
            bool _isFromXtra
        ) = _calculateWithdraw(_stakerAddress, _slot, _getTokenPrice());
        return (_userAmount, _xtraAmount, _isFromXtra);
    }

    ///@notice Calculates liqudation return for selected staking slot with actual token price. The method is used when unstake date has not yet arrived.
    ///@param _stakerAddress - Address of staker
    ///@param _slot - Slot of stake
    ///@return 0 toReturn - tokens returns to staker
    ///@return 1 toBurn - tokens will be burnt
    function calculateLiquidationReturn(address _stakerAddress, uint256 _slot)
        external
        view
        returns (uint256, uint256)
    {
        (uint256 _toReturn, uint256 _toBurn) = _calculateLiquidationReturn(
            _stakerAddress,
            _slot,
            _getTokenPrice()
        );
        return (_toReturn, _toBurn);
    }

    ///@notice Returns address stats.
    ///@param _address - Address to check
    ///@return 0 balance - Token balance of address (available, free tokens)
    ///@return 1 sumStaked - Sum of all staked tokens of address
    ///@return 2 investNum - Number of invest slots of address
    ///@return 3 vestingNum - Number of vesting slots of address
    ///@return 4 stakesNum - Number of stake slots of address
    function userNums(address _address)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            balanceOf(_address),
            _sumStakedByUser(_address),
            _investitionsOfUser[_address],
            _vestingsOfUser[_address],
            _stakesOfUser[_address]
        );
    }

    /// ----- OWNERS FUNCTIONS ----- ///
    ///@notice Adding investors to smart contract. Executable by contract owner only.
    ///@dev Contract owner only. _stakingStartDate must be initialized first.
    ///@param _addresses - Array of investors addresses
    ///@param _amounts - Array of amount to add
    ///@param _pools - Array of invest pools (POOL_SEED, POOL_PRESALE etc)
    function addInvestors(
        address[] memory _addresses,
        uint256[] memory _amounts,
        uint256[] memory _pools
    ) external onlyOwner {
        require(_stakingStartDate > 0, "Initialize date first");
        _addInvestors(_addresses, _amounts, _pools);
    }

    ///@notice Distribute(mint) sale tokens. Executable by contract owner only.
    ///@dev Contract owner only. Cant withdraw more than _sale_tokens.
    ///@param _receiverAddress - Address which recieves sale tokens
    function distributeSale(address _receiverAddress) external onlyOwner {
        require(_sale_tokens > 0, "Cant distribute more than cap");
        _transfer(address(this), _receiverAddress, _sale_tokens);
        _sale_tokens = 0;
    }

    ///@notice Distribute(mint) lp tokens. Executable by contract owner only.
    ///@dev Contract owner only. Cant withdraw more than _lp_tokens.
    ///@param _receiverAddress - Address which recieves tokens
    ///@param _amount - Amount be minted
    function distributeLPTokens(uint256 _amount, address _receiverAddress)
        external
        onlyOwner
    {
        require(_lp_tokens  >= _amount, "Cant distribute more than cap");
        _lp_tokens -= _amount;
        _transfer(address(this), _receiverAddress, _amount);
    }

    ///@notice Distribute(mint) loan fund tokens. Executable by contract owner only.
    ///@dev Contract owner only. Cant withdraw more than _loan_fund.
    ///@param _receiverAddress - Address which recieves tokens
    ///@param _amount - Amount be minted
    function distributeLoanFund(uint256 _amount, address _receiverAddress)
        external
        onlyOwner
    {
        require(_loan_fund  >= _amount, "Cant distribute more than cap");
        _loan_fund -= _amount;
        _transfer(address(this), _receiverAddress, _amount);
    }

    /// ----- INTERNAL FUNCTIONS ----- ///
    ///@dev Returns actial token price from pancakeswap pair
    ///@return token price
    function _getTokenPrice() internal view returns (uint256) {
        address pairAddress = IPancakeFactory(_pancakeFactoryAddress).getPair(
            address(this),
            _stableCoinAddress
        );
        IPancakePair pair = IPancakePair(pairAddress);
        (uint256 Res0, uint256 Res1, ) = pair.getReserves();
        if (pair.token0() == address(this)) {
            return ((Res1 * 10**8) / Res0);
        } else return ((Res0 * 10**8) / Res1);
    }

    ///@dev Returns true if caller is contract
    ///@return true when caller addr is contract
    function _isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    /// ----- EXTERNAL FUNCTIONS ----- ///
    ///@notice Activate all investitions of address
    ///@dev _stakingStartDate must be in past
    function activateInvestitions() external {
        require(
            _stakingStartDate < block.timestamp,
            "Activation is not enabled yet"
        );
        uint256 investNum = _investitionsOfUser[msg.sender];
        uint256 sum = 0;
        for (uint256 i = 0; i < investNum; i++) {
            InvestData memory inv = _investitions[msg.sender][i];
            if (!inv.withdrawn) {
                sum++;
                _totalInvestitions -= inv.amount;
                _investitions[msg.sender][i].withdrawn = true;
                if (inv.pool == POOL_SEED) {
                    require(
                        _seed_tokens  >= inv.amount,
                        "Cant claim more than cap"
                    );
                    uint256 stakingTokens = (60 * inv.amount) / 100;
                    uint256 vestingTokens = (30 * inv.amount) / 100;
                    _transfer(
                        address(this),
                        msg.sender,
                        inv.amount - vestingTokens - stakingTokens
                    );
                    _addVesting(
                        msg.sender,
                        20,
                        vestingTokens,
                        _stakingStartDate
                    );
                    _stake(
                        msg.sender,
                        stakingTokens,
                        12 * 30,
                        _stakingStartDate,
                        _initialTokenPrice
                    );
                    _seed_tokens -= inv.amount;
                    emit withdrawInvest(msg.sender, POOL_SEED, inv.amount);
                } else if (inv.pool == POOL_PRESALE) {
                    require(
                        _presale_tokens  >= inv.amount,
                        "Cant claim more than cap"
                    );
                    uint256 stakingTokens = (50 * inv.amount) / 100;
                    uint256 vestingTokens = (40 * inv.amount) / 100;
                    _transfer(
                        address(this),
                        msg.sender,
                        inv.amount - vestingTokens - stakingTokens
                    );
                    _addVesting(
                        msg.sender,
                        18,
                        vestingTokens,
                        _stakingStartDate
                    );
                    _stake(
                        msg.sender,
                        stakingTokens,
                        9 * 30,
                        _stakingStartDate,
                        _initialTokenPrice
                    );
                    _presale_tokens -= inv.amount;
                    emit withdrawInvest(msg.sender, POOL_PRESALE, inv.amount);
                } else if (inv.pool == POOL_TEAM) {
                    require(
                        _team_tokens  >= inv.amount,
                        "Cant claim more than cap"
                    );
                    uint256 stakingTokens = (60 * inv.amount) / 100;
                    uint256 vestingTokens = (30 * inv.amount) / 100;
                    _transfer(
                        address(this),
                        msg.sender,
                        inv.amount - vestingTokens - stakingTokens
                    );
                    _addVesting(
                        msg.sender,
                        20,
                        vestingTokens,
                        _stakingStartDate
                    );
                    _stake(
                        msg.sender,
                        stakingTokens,
                        12 * 30,
                        _stakingStartDate,
                        _initialTokenPrice
                    );
                    _team_tokens -= inv.amount;
                    emit withdrawInvest(msg.sender, POOL_TEAM, inv.amount);
                }
            }
        }
        require(sum > 0, "Nothing to activate");
    }

    ///@notice Activates Allocation using exteranl erc20 token
    ///@dev Requires .approve() to this contract address for spending external token
    function activateAllocation() external {
        require(
            _stakingStartDate < block.timestamp,
            "Activation is not enabled yet"
        );
        IERC20 token = IERC20(_allocationTokenAddress);
        uint256 balance = token.balanceOf(msg.sender);
        require(balance > 1000 ether, "No allocation founded");
        require(_presale2_tokens  >= balance, "Cant activate more than cap");
        token.transferFrom(msg.sender, address(this), balance);
        uint256 stakingTokens = (60 * balance) / 100;
        uint256 vestingTokens = (30 * balance) / 100;
        _transfer(address(this), msg.sender, balance - vestingTokens - stakingTokens);
        _addVesting(msg.sender, 12, vestingTokens, _stakingStartDate);
        _stake(
            msg.sender,
            stakingTokens,
            6 * 30,
            _stakingStartDate,
            _initialTokenPrice
        );
        _presale2_tokens -= balance;
        _totalInvestitions -= balance;
        emit withdrawInvest(msg.sender, POOL_PRESALE2, balance);
    }

    ///@notice Stakes tokens for duration(days)
    ///@param _amount Amount of tokens to stake
    ///@param _duration Stake duration in days
    function stake(uint256 _amount, uint256 _duration) external {
        require(msg.sender == tx.origin && !_isContract(msg.sender), "Smart Contracts calls not allowed");
        _transfer(msg.sender, address(this), _amount);
        _stake(
            msg.sender,
            _amount,
            _duration,
            block.timestamp,
            _getTokenPrice()
        );
    }

    ///@notice Unstakes tokens for selected slot
    ///@dev Can be wthdrawn only once
    ///@param _slot Slot to unstake
    function unstake(uint256 _slot) external {
        require(msg.sender == tx.origin && !_isContract(msg.sender), "Smart Contracts calls not allowed");
        Stake memory s = _stakes[msg.sender][_slot];
        require(s.endPrice == 0, "Cant be unstaked again");
        uint256 actPrice = _getTokenPrice();
        require(
            block.timestamp >= (s.startDate + s.duration * 1 days),
            "Staking end date not reached"
        );
        _stakes[msg.sender][_slot].endPrice = actPrice;
        (
            uint256 tokensToUser,
            uint256 tokensToXtra,
            bool tokensFromXtra
        ) = _calculateWithdraw(msg.sender, _slot, actPrice);
        if (tokensFromXtra) {
            require(_xtra_fund >= tokensToXtra, "Xtra fund is empty");
            _mint(msg.sender, tokensToXtra);
            _transfer(address(this), msg.sender, tokensToUser);
            _xtra_fund -= tokensToXtra;
            _totalStaked -= tokensToUser;
            emit Unstaked(
                msg.sender,
                _slot,
                true,
                actPrice,
                tokensToXtra + tokensToUser,
                tokensToXtra,
                block.timestamp,
                false
            );
        } else {
            uint256 sum = 0;
            if (tokensToUser > 0) {
                _transfer(address(this), msg.sender, tokensToUser);
                sum += tokensToUser;
            }
            if (tokensToXtra > 0) {
                _burn(address(this), tokensToXtra);
                sum += tokensToXtra;
                _xtra_fund += tokensToXtra;
            }
            emit Unstaked(
                msg.sender,
                _slot,
                false,
                actPrice,
                tokensToUser,
                tokensToXtra,
                block.timestamp,
                false
            );
            _totalStaked -= sum;
        }
    }

    ///@notice Liquidate stake position
    ///@param _slot Stake slot
    function liquidateStake(uint256 _slot) external {
        require(msg.sender == tx.origin && !_isContract(msg.sender), "Smart Contracts calls not allowed");
        require(
            _stakes[msg.sender][_slot].endPrice == 0,
            "Cant be unstaked again"
        );
        Stake memory s = _stakes[msg.sender][_slot];
        require(
            block.timestamp < (s.startDate + s.duration * 1 days),
            "Staking end date is reached"
        );
        uint256 actPrice = _getTokenPrice();
        (
            uint256 tokensToWithdraw,
            uint256 tokensToBurn
        ) = _calculateLiquidationReturn(msg.sender, _slot, actPrice);
        if (tokensToWithdraw > 0) {
            _transfer(address(this), msg.sender, tokensToWithdraw);
        }
        if (tokensToBurn > 0) {
            _burn(address(this), tokensToBurn);
            _xtra_fund += tokensToBurn / 2;
        }
        _stakes[msg.sender][_slot].endPrice = actPrice;
        _totalStaked -= s.amount;
        emit Unstaked(
            msg.sender,
            _slot,
            false,
            actPrice,
            tokensToWithdraw,
            tokensToBurn / 2,
            block.timestamp,
            true
        );
    }

    ///@notice Claims tokens from vesting slot
    ///@param _slot Vesting slot
    function claimVesting(uint256 _slot) external {
        require(
            block.timestamp < _vestingLastDate,
            "Cant be claimed - time is up"
        );
        Vesting memory v = _vestings[msg.sender][_slot];
        uint256 completedMonths = (block.timestamp - v.startDate) / 30 days;
        uint256 toWithdrawParts = completedMonths - v.withdrawnParts;
        uint256 canBeWithdrawn = v.duration - v.withdrawnParts;
        if (toWithdrawParts >= canBeWithdrawn) {
            toWithdrawParts = canBeWithdrawn;
        }
        require(toWithdrawParts > 0, "No parts to withdraw");
        uint256 tokensToMint = (v.amount * toWithdrawParts) / v.duration;
        _vestings[msg.sender][_slot].withdrawnParts =
            _vestings[msg.sender][_slot].withdrawnParts +
            toWithdrawParts;
        _transfer(address(this), msg.sender, tokensToMint);
        emit MintedFromVesting(msg.sender, _slot, tokensToMint);
        _totalVestings -= tokensToMint;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >0.8.0;

interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface IPancakePair {
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Xtra Staking Contract
/// @author bs
/// @notice Audited by Hacken
contract XtraStaking is Ownable {
    /// ----- VARIABLES ----- ///
    uint256 internal _xtra_fund = 8e10 ether; //80 mlrd

    uint256 internal constant DAYS_LIMIT_1 = 729;
    uint256 internal constant DAYS_LIMIT_2 = 3649;
    uint256 internal constant DAYS_LIMIT_MAX = 6000;

    uint256 internal constant PERC_LIMIT_1 = 14;
    uint256 internal constant PERC_LIMIT_2 = 10;

    uint256 internal _totalStaked = 0;
    uint256 internal _stakingStartDate;

    struct Stake {
        uint256 startDate;
        uint256 duration;
        uint256 amount;
        uint256 startPrice;
        uint256 endPrice;
        uint256 roi;
        uint256 guarantee;
    }

    mapping(address => mapping(uint256 => Stake)) internal _stakes;
    mapping(address => uint256) internal _stakesOfUser;

    /// ----- EVENTS ----- ///
    event Staked(
        address indexed _staker,
        uint256 indexed _stakeNum,
        uint256 _duration,
        uint256 _amount,
        uint256 _startPrice,
        uint256 _roi,
        uint256 _startDate,
        uint256 _guarantee
    );

    event Unstaked(
        address indexed _staker,
        uint256 indexed _stakeNum,
        bool indexed _fromFund,
        uint256 _endPrice,
        uint256 _amountWithdrawed,
        uint256 _amountToXtra,
        uint256 _endDate,
        bool _isLiquidated
    );

    /// ----- CONSTRUCTOR ----- ///
    constructor() {}

    /// ----- VIEWS ----- ///
    ///@notice Returns sum of staked tokens of address
    ///@param _stakerAddress - address to check
    ///@return 0 sumStaked - sum of staked tokens
    function sumStakedByUser(address _stakerAddress)
        external
        view
        returns (uint256)
    {
        return (_sumStakedByUser(_stakerAddress));
    }

    ///@notice Returns stake params for requested staker address and stake slot
    ///@param _stakerAddress - staker address
    ///@param _slot - stake slot
    ///@return 0 startDate - stake Start Date
    ///@return 1 duration - stake duration in days
    ///@return 2 amount - stake amount in tokens
    ///@return 3 startPrice - the price of token when it was activated (staked)
    ///@return 4 endPrice - the price of token when it was unstaked
    ///@return 5 roi - expected roi of stake
    function getStake(address _stakerAddress, uint256 _slot)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        Stake memory s = _stakes[_stakerAddress][_slot];
        return (
            s.startDate,
            s.duration,
            s.amount,
            s.startPrice,
            s.endPrice,
            s.roi,
            s.guarantee
        );
    }

    ///@notice Returns number of all stakes of address
    ///@param _stakerAddress - staker address
    ///@return 0 stakesNum - number of all stakes of address
    function userStakesNum(address _stakerAddress)
        external
        view
        returns (uint256)
    {
        return _stakesOfUser[_stakerAddress];
    }

    ///@notice Calculates expected roi for stake amount and duration
    ///@param _amount - stake amount
    ///@param _duration - stake duration
    ///@return 0 durationBonus - duration bonus
    ///@return 1 amountBonus - amount bonus
    ///@return 2 roi - roi
    function calculateRoi(uint256 _amount, uint256 _duration)
        external
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        if (_amount < 1 ether) return (0, 0, 0);
        else if (_duration < 1) return (0, 0, 0);
        else if (_duration > DAYS_LIMIT_MAX) return (0, 0, 0);
        else {
            (
                uint256 _durationBonus,
                uint256 _amountBonus,
                uint256 _roi
            ) = _calculateRoi(_amount, _duration);
            return (_durationBonus, _amountBonus, _roi);
        }
    }

    /// ----- INTERNAL METHODS ----- ///
    ///@notice Returns sum of staked tokens of address
    ///@param _stakerAddress - address to check
    ///@return 0 sumStaked - sum of staked tokens
    function _sumStakedByUser(address _stakerAddress)
        internal
        view
        returns (uint256)
    {
        uint256 sum = 0;
        for (uint256 i = 0; i < _stakesOfUser[_stakerAddress]; i++) {
            Stake memory s = _stakes[_stakerAddress][i];
            if (s.endPrice == 0) {
                sum += s.amount;
            }
        }
        return sum;
    }

    ///@notice Returns percent duration bonus
    ///@param _amount - address to check
    ///@return 0 amountBonus - amount bonus in percent * 10**11
    function _biggerAmountBonus(uint256 _amount)
        internal
        pure
        returns (uint256)
    {
        uint256 tmp = _amount / 16 / 10**14;
        if (tmp < 10**11) {
            return (uint256(tmp));
        } else return (uint256(10**11));
    }

    ///@notice Returns percent amount bonus
    ///@param _duration - address to check
    ///@return 0 durationBonus - amount bonus in percent * 10**11
    function _longerDurationBonus(uint256 _duration)
        internal
        pure
        returns (uint256)
    {
        if (_duration <= DAYS_LIMIT_1) {
            uint256 bonusPerc = ((_duration * 10**10) / 365) * PERC_LIMIT_1;
            return (bonusPerc);
        } else if (_duration <= DAYS_LIMIT_2) {
            uint256 stakeYears = (_duration * 1000000000) / 365;
            uint256 bonusPerc = (stakeYears * stakeYears * 338) /
                10000000000 +
                58 *
                stakeYears +
                97700000000;
            return (bonusPerc);
        } else if (_duration <= DAYS_LIMIT_MAX) {
            uint256 stakeYears = (_duration * 1000000000) / 365;
            uint256 bonusPerc = (766 * stakeYears - 3500000000000);
            return (bonusPerc);
        }
        return (0);
    }

    ///@notice Calculates expected roi for stake amount and duration
    ///@param _amount - stake amount
    ///@param _duration - stake duration
    ///@return 0 durationBonus - duration bonus
    ///@return 1 amountBonus - amount bonus
    ///@return 2 roi - roi
    function _calculateRoi(uint256 _amount, uint256 _duration)
        internal
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 _durationBonus = _longerDurationBonus(_duration);
        uint256 _amountBonus = _biggerAmountBonus(_amount);
        uint256 _roi = (_durationBonus +
            (_durationBonus * _amountBonus) /
            10**12);
        return (_durationBonus, _amountBonus, _roi);
    }

    ///@notice Calculates return for selected staking slot with actual token price. If isFromXtra is true xtraAmount will be minted from xtra fund to staker address. Else xtra amount will be burn and added to xtra fund.
    ///@param _stakerAddress - Address of staker
    ///@param _slot - Slot of stake
    ///@param _actualPrice - price for which return be calculated
    ///@return 0 userAmount - amount in xtra tokens returns to user
    ///@return 1 xtraAmount - amount in xtra tokens from/to xtra fund
    ///@return 2 isFromXtra - true if tokens need to be minted from xtra fund. false if tokens will burn and added to xtra fund
    function _calculateWithdraw(
        address _stakerAddress,
        uint256 _slot,
        uint256 _actualPrice
    )
        internal
        view
        returns (
            uint256,
            uint256,
            bool
        )
    {
        Stake memory s = _stakes[_stakerAddress][_slot];
        uint256 actualPrice = _actualPrice;
        uint256 startValue = (s.startPrice * s.amount) / 10**8;
        uint256 endValue = (actualPrice * s.amount) / 10**8;
        uint256 roi = (startValue * s.roi) / 10**12;
        if (endValue == startValue) {
            return (s.amount, 0, false);
        } else if (endValue > startValue) {
            uint256 grossProfit = endValue - startValue;
            if (grossProfit <= roi) {
                return (s.amount, 0, false);
            } else if (grossProfit > roi) {
                uint256 diff = grossProfit - roi;
                uint256 toWithdraw = 0;
                if (diff >= startValue * 2) {
                    toWithdraw = ((roi + startValue * 2) * 10**8) / actualPrice;
                } else {
                    toWithdraw =
                        ((roi + startValue + diff / 2) * 10**8) /
                        actualPrice;
                }
                uint256 tokensToXtra = s.amount - toWithdraw;
                return (toWithdraw, tokensToXtra, false);
            }
        } else {
            uint256 guarantedPrice = s.startPrice -
                ((s.startPrice * s.guarantee) / 100);
            uint256 tokensFromXtra;
            if (guarantedPrice <= _actualPrice) {
                //100000 <= 600000 true
                uint256 diff = startValue - endValue; //10 000 -
                tokensFromXtra = (diff * 10**8) / actualPrice;
            } else {
                tokensFromXtra =
                    ((s.amount * startValue) /
                        ((s.amount * guarantedPrice) / 10**8)) -
                    s.amount;
            }
            if (tokensFromXtra > _xtra_fund) {
                tokensFromXtra = _xtra_fund;
            }
            return (s.amount, tokensFromXtra, true);
        }
        return (0, 0, false);
    }

    ///@notice Calculates guarantee in percents
    ///@param _days - duration in days
    ///@return 0 guarantee - guarantee in percents
    function _calculateGuarantee(uint256 _days)
        internal
        pure
        returns (uint256)
    {
        if (_days <= 365) {
            return 50;
        } else if (_days <= 1095) {
            return 60;
        } else if (_days <= 1825) {
            return 70;
        } else if (_days <= 3650) {
            return 80;
        } else if (_days > 3650) {
            return 90;
        }
        return (0);
    }

    ///@notice Stakes tokens for duration(days)
    ///@param _address Staker address
    ///@param _amount Amount of tokens to stake
    ///@param _duration Stake duration in days
    ///@param _startDate Stake start date
    ///@param _tokenPrice Stake start token price
    function _stake(
        address _address,
        uint256 _amount,
        uint256 _duration,
        uint256 _startDate,
        uint256 _tokenPrice
    ) internal {
        require(_amount >= 1 ether, "Amount must be greather than 1");
        require(_duration >= 1, "Duration must be greather than 1");
        require(
            _duration <= DAYS_LIMIT_MAX,
            "Duration must be lower then max limit"
        );
        // _transfer(_address, address(this), _amount);
        (, , uint256 roi) = _calculateRoi(_amount, _duration);
        uint256 stakesNum = _stakesOfUser[_address];
        Stake memory newStake;
        newStake.startDate = _startDate;
        newStake.amount = _amount;
        newStake.duration = _duration;
        newStake.startPrice = _tokenPrice;
        newStake.roi = roi;
        newStake.guarantee = _calculateGuarantee(_duration);
        _stakes[_address][stakesNum] = newStake;
        emit Staked(
            _address,
            stakesNum,
            _duration,
            _amount,
            _tokenPrice,
            roi,
            _startDate,
            newStake.guarantee
        );
        _stakesOfUser[_address]++;
        _totalStaked += _amount;
    }

    ///@notice Calculates liquidation return from stake
    ///@param _address Staker address
    ///@param _slot Stake slot
    ///@param _actualPrice price for which liquidation return be calculated
    ///@return 0 tokensToWithdraw - tokens send back to user
    ///@return 1 tokensToBurn - tokens to burn
    function _calculateLiquidationReturn(
        address _address,
        uint256 _slot,
        uint256 _actualPrice
    ) internal view returns (uint256, uint256) {
        Stake memory s = _stakes[_address][_slot];
        uint256 endStakeTime = s.startDate + s.duration * 1 days;
        require(block.timestamp < endStakeTime, "Stake is ended");
        uint256 pastTime = block.timestamp - s.startDate;
        uint256 pastPerc = (pastTime * 10**5) / (endStakeTime - s.startDate);
        uint256 invValue = (s.startPrice * s.amount) / 10**8;
        uint256 retValue = (invValue * pastPerc) / 10**5;
        uint256 retAmount = (retValue * 10**8) / s.startPrice;
        if (_actualPrice < s.startPrice) {
            uint256 toBurn = s.amount - retAmount;
            return (retAmount, toBurn);
        } else {
            uint256 invValue2 = (_actualPrice * s.amount) / 10**8;
            uint256 retValue2 = (invValue2 * pastPerc) / 10**5;
            if (retValue2 > retValue) {
                uint256 retAmount2 = (retValue * 10**8) / _actualPrice;
                uint256 toBurn = s.amount - retAmount2;
                return (retAmount2, toBurn);
            } else {
                uint256 toBurn = s.amount - retAmount;
                return (retAmount, toBurn);
            }
        }
    }

    ///@notice Sets start staking date
    ///@param _newDate Start Staking Date
    function setStakingStartDate(uint256 _newDate) external onlyOwner {
        require(_stakingStartDate == 0, "Cant be set again");
        _stakingStartDate = _newDate;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/// @title Xtra Vesting Contract
/// @author bs
/// @notice Audited by Hacken
contract XtraVesting {
    /// ----- VARIABLES ----- ///
    uint256 internal immutable _vestingLastDate;
    struct Vesting {
        uint256 startDate;
        uint256 duration;
        uint256 amount;
        uint256 withdrawnParts;
    }
    uint256 _totalVestings;
    mapping(address => mapping(uint256 => Vesting)) internal _vestings;
    mapping(address => uint256) internal _vestingsOfUser;

    /// ----- EVENTS ----- ///
    event AddedVesting(
        address indexed _participant,
        uint256 indexed _slot,
        uint256 _amount,
        uint256 _duration
    );
    event MintedFromVesting(
        address indexed _participant,
        uint256 indexed _slot,
        uint256 _amount
    );

    /// ----- CONSTRUCTOR ----- ///
    constructor() {
        _vestingLastDate = block.timestamp + 30 * 30 days;
    }

    /// ----- VIEWS ----- ///

    ///@notice Returns max date of minting from vesting
    function getVestingLastDate() external view returns (uint256) {
        return _vestingLastDate;
    }

    ///@notice Returns vesting info for slot
    ///@param _claimerAddress - claimer address
    ///@param _slot - vesting slot
    ///@return 0 startDate - staking start date
    ///@return 1 duration -  staking duration in months
    ///@return 2 amount - staking amount in tokens
    ///@return 3 withdrawnParts - staking withdrawn parts in months
    function getVesting(address _claimerAddress, uint256 _slot)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        Vesting memory v = _vestings[_claimerAddress][_slot];
        return (v.startDate, v.duration, v.amount, v.withdrawnParts);
    }

    ///@notice Returns number of all vestings of address
    ///@param _claimerAddress - claimer address
    ///@return 0 vestingNum - number of all invests of address
    function userVestingNum(address _claimerAddress)
        external
        view
        returns (uint256)
    {
        return _vestingsOfUser[_claimerAddress];
    }

    /// ----- INTERNAL METHODS ----- ///

    ///@notice Adds vesting
    ///@param _address - vesting receiver address
    ///@param _duration - vesting duration
    ///@param _amount - vesting amount
    ///@param _startDate - vesting start date
    function _addVesting(
        address _address,
        uint256 _duration,
        uint256 _amount,
        uint256 _startDate
    ) internal {
        uint256 vestingNum = _vestingsOfUser[_address];
        Vesting memory newVesting;
        newVesting.startDate = _startDate;
        newVesting.amount = _amount;
        newVesting.duration = _duration;
        _vestings[_address][vestingNum] = newVesting;
        _vestingsOfUser[_address]++;
        _totalVestings += _amount;
        emit AddedVesting(_address, vestingNum, _amount, _duration);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/// @title Xtra Invest Contract
/// @author bs
/// @notice Audited by Hacken
contract XtraInvesting {
    /// ----- VARIABLES ----- ///
    struct InvestData {
        uint256 amount;
        uint256 pool;
        bool withdrawn;
    }
    uint256 internal _totalInvestitions = 15e8 ether; //initial value = max allocation tokens 
    mapping(address => mapping(uint256 => InvestData)) internal _investitions;
    mapping(address => uint256) internal _investitionsOfUser;

    /// ----- EVENTS ----- ///
    event withdrawInvest(
        address indexed _investor,
        uint256 indexed _pool,
        uint256 _amount
    );

    /// ----- CONSTRUCTOR ----- ///
    constructor() {}

    /// ----- VIEWS ----- ///
    ///@notice Returns number of all invests of address
    ///@param _investorAddress - staker address
    ///@return 0 investsNum - number of all invests of address
    function getInvestNum(address _investorAddress)
        external
        view
        returns (uint256)
    {
        return _investitionsOfUser[_investorAddress];
    }

    ///@notice Returns invest params for requested investor address and invest slot
    ///@param _investorAddress - investor address
    ///@param _slot - invest slot
    ///@return 0 amount - invest amount in tokens
    ///@return 1 pool - invest pool (see POOL_SEED, POOL_PRESALE, ...)
    ///@return 2 withdrawn - true if invest activated
    function getInvestitionInfo(address _investorAddress, uint256 _slot)
        external
        view
        returns (
            uint256,
            uint256,
            bool
        )
    {
        InvestData memory i = _investitions[_investorAddress][_slot];
        return (i.amount, i.pool, i.withdrawn);
    }

    /// ----- INTERNAL METHODS ----- ///
    ///@notice Adding investors to smart contract. Executable by contract owner only.
    ///@dev Contract owner only. _stakingStartDate must be initialized first.
    ///@param _addresses - Array of investors addresses
    ///@param _amounts - Array of amount to add
    ///@param _pools - Array of invest pools (POOL_SEED, POOL_PRESALE etc)
    function _addInvestors(
        address[] memory _addresses,
        uint256[] memory _amounts,
        uint256[] memory _pools
    ) internal {
        uint256 len = _addresses.length;
        require(
            len == _amounts.length && len == _pools.length,
            "Arrays lengths mismatch"
        );
        uint256 sum = 0;
        for (uint256 i = 0; i < len; i++) {
            address actAddress = _addresses[i];
            uint256 actAmount = _amounts[i];
            uint256 actPool = _pools[i];
            uint256 investNum = _investitionsOfUser[actAddress];
            InvestData memory newInvestition;
            newInvestition.amount = actAmount;
            newInvestition.pool = actPool;
            _investitions[actAddress][investNum] = newInvestition;
            _investitionsOfUser[actAddress]++;
            sum += actAmount;
        }
        require(
            _totalInvestitions + sum <= 65e8 ether,
            "Max invest reached"
        );
        _totalInvestitions += sum;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}