pragma solidity ^0.8.4;

//SPDX-License-Identifier: MIT Licensed

abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    modifier isHuman() {
        require(tx.origin == msg.sender, "sorry humans only");
        _;
    }
}

pragma solidity ^0.8.4;

// SPDX-License-Identifier: MIT

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external;
    function transfer(address to, uint value) external;
    function transferFrom(address from, address to, uint value) external;
}

pragma solidity ^0.8.4;

// SPDX-License-Identifier:MIT

interface IPancakeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

pragma solidity ^0.8.4;

// SPDX-License-Identifier: MIT

import './IERC20.sol';
import '../Libraries/SafeMath.sol';
import './IPancakeRouter02.sol';
import '../AbstractContracts/ReentrancyGuard.sol';

interface IPreSale{

    function admin() external view returns(address);
    function tokenOwner() external view returns(address);
    function deployer() external view returns(address);
    function token() external view returns(address);

    function tokenPrice() external view returns(uint256);
    function preSaleTime() external view returns(uint256);
    function claimTime() external view returns(uint256);
    function minAmount() external view returns(uint256);
    function maxAmount() external view returns(uint256);
    function softCap() external view returns(uint256);
    function hardCap() external view returns(uint256);
    function listingPrice() external view returns(uint256);
    function liquidityPercent() external view returns(uint256);

    function allow() external view returns(bool);

    function initialize(
        address _admin,
        address _tokenOwner,
        IERC20 _token,
        address _routerAddress,
        uint256 _adminFeePercent,
        uint256[] memory _data
        // uint256 _minAmount,
        // uint256 _maxAmount,
        // uint256 _presaleEndTime,
        // uint256 _vestingTime,
        // uint256 _vestingPercent,
        // uint256 _tokenPricePublic,
        // uint256 _hardCapPublic,
        // uint256 _tokenPricePrivate
        // uint256 _hardCapPrivate,
        // uint256 _tokenPriceSeed,
        // uint256 _hardCapSeed,
        // uint256 _listingPrice,        
        // uint256 _liquidityPercent
    ) external ;

    function initializeRemaining(
        uint256 _tokenPricePublic,
        uint256 _presaleEndTime,
        uint256 _hardCap,
        uint256 _softCap,
        uint256 _listingPrice,
        uint256 _listingTime,
        uint256 _liquidityPercent
    ) external ;
    
}

pragma solidity ^0.8.4;

//  SPDX-License-Identifier: MIT

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: MIT

import "./Interfaces/IPreSale.sol";

contract preSale {
    using SafeMath for uint256;
    using SafeMath for uint256;

    address payable public admin;
    address payable public tokenOwner;
    address public deployer;
    IERC20 public token;
    IPancakeRouter02 public routerAddress;

    uint256 public adminFeePercent;
    uint256 public tokenPricePublic;
    uint256 public tokenPricePrivate;
    uint256 public tokenPriceSeed;
    uint256 public preSaleEndTime;
    uint256 public minAmount;
    uint256 public maxAmount;
    uint256 public vestingTime;
    uint256 public hardCapPublic;
    uint256 public hardCapPrivate;
    uint256 public hardCapSeed;
    uint256 public softCapPublic;
    uint256 public softCapPrivate;
    uint256 public softCapSeed;
    uint256 public listingPrice;
    uint256 public listingTime;
    uint256 public liquidityPercent;
    uint256 public saleType;
    uint256 public vestingPercent;
    uint256 public currentClaimCycle;
    uint256 public totalUser;
    uint256 public amountRaisedPublic;
    uint256 public amountRaisedPrivate;
    uint256 public amountRaisedSeed;
    uint256 public soldTokensPublic;
    uint256 public soldTokensPrivate;
    uint256 public soldTokensSeed;
    uint256 public tokenOwnerProfit;
    uint256 public voteUp;
    uint256 public voteDown;
    uint256 public votingStartTime;
    uint256 public votingEndTime;
    uint256 public currentVotingCycle;

    bool public allow;
    bool public profitClaim;
    bool public votingStatus;
    bool public canClaim;

    struct VotingData {
        // uint256 amount;
        bool vote;
        bool voteCasted;
    }

    mapping(address => bool) public whiteListPrivate;
    mapping(address => bool) public whiteListSeed;
    mapping(address => uint256) private coinBalancePublic;
    mapping(address => uint256) private tokenBalancePublic;
    mapping(address => uint256) private coinBalancePrivate;
    mapping(address => uint256) private tokenBalancePrivate;
    mapping(address => uint256) private coinBalanceSeed;
    mapping(address => uint256) private tokenBalanceSeed;
    mapping(address => uint256) public activeClaimAmountCoinPublic;
    mapping(address => uint256) public activeClaimAmountTokenPublic;
    mapping(address => uint256) public activeClaimAmountCoinPrivate;
    mapping(address => uint256) public activeClaimAmountTokenPrivate;
    mapping(address => uint256) public activeClaimAmountCoinSeed;
    mapping(address => uint256) public activeClaimAmountTokenSeed;
    mapping(address => uint256) public claimCount;
    mapping(address => mapping(uint256 => VotingData)) internal usersVoting;

    modifier onlyAdmin() {
        require(msg.sender == admin, "PRESALE: Not an admin");
        _;
    }

    modifier onlyTokenOwner() {
        require(msg.sender == tokenOwner, "PRESALE: Not a token owner");
        _;
    }

    modifier allowed() {
        require(allow, "PRESALE: Not allowed");
        _;
    }

    event TokenBought(
        address indexed user,
        uint256 indexed numberOfTokens,
        uint256 indexed amountBusd
    );

    event TokenClaimed(address indexed user, uint256 indexed numberOfTokens);

    event CoinClaimed(address indexed user, uint256 indexed numberOfCoins);

    event TokenUnSold(address indexed user, uint256 indexed numberOfTokens);

    constructor() {
        deployer = msg.sender;
        voteUp = 1;
    }
    
/*

    _presaleTime,
    _vestingTime,
    _vestingPercent,
    _liquidityPercent,
    _minAmount,
    _maxAmount,
    _tokenPricePublic,
    _hardCapPublic,
    _softCapPublic,
    _tokenPricePrivate,
    _hardCapPrivate,
    _softCapPrivate,
    _tokenPriceSeed,
    _hardCapSeed,
    _softCapSeed,
    _listingPrice,

*/

    // called once by the deployer contract at time of deployment
    function initialize(
        address _admin,
        address _tokenOwner,
        IERC20 _token,
        address _routerAddress,
        uint256 _adminFeePercent,
        uint256[] memory _data
    ) external {
        require(msg.sender == deployer, "PRESALE: FORBIDDEN"); // sufficient check
        admin = payable(_admin);
        tokenOwner = payable(_tokenOwner);
        token = _token;
        routerAddress = IPancakeRouter02(_routerAddress);
        adminFeePercent = _adminFeePercent;
        preSaleEndTime = _data[0];
        vestingTime = _data[1];
        vestingPercent = _data[2];
        liquidityPercent = _data[3];
        minAmount = _data[4];
        maxAmount = _data[5];
        tokenPricePublic = _data[6];
        hardCapPublic = _data[7];
        softCapPublic = _data[8];
        tokenPricePrivate = _data[9];
        hardCapPrivate = _data[10];
        softCapPrivate = _data[11];
        tokenPriceSeed = _data[12];
        hardCapSeed = _data[13];
        softCapSeed = _data[14];
        listingPrice = _data[15];
    }

    receive() external payable {}

    // to buy token during preSale time => for web3 use
    function buyToken(uint256 _type) public payable allowed {
        require(block.timestamp < preSaleEndTime, "PRESALE: Time over"); // time check

        uint256 numberOfTokens;

        if (_type == 1) {
            require(
                msg.value >= minAmount &&
                    coinBalancePublic[msg.sender].add(msg.value) <= maxAmount,
                "PRESALE: Invalid Amount"
            );
            require(
                amountRaisedPublic.add(msg.value) <= hardCapPublic,
                "PRESALE: Hardcap reached"
            );
            numberOfTokens = coinToToken(msg.value, tokenPricePublic);
            if (tokenBalancePublic[msg.sender] == 0) totalUser++;
            tokenBalancePublic[msg.sender] = tokenBalancePublic[msg.sender].add(
                numberOfTokens
            );
            soldTokensPublic = soldTokensPublic.add(numberOfTokens);
            coinBalancePublic[msg.sender] = coinBalancePublic[msg.sender].add(
                msg.value
            );
            amountRaisedPublic = amountRaisedPublic.add(msg.value);
        } else if (_type == 2) {
            require(
                msg.value >= minAmount &&
                    coinBalancePrivate[msg.sender].add(msg.value) <= maxAmount,
                "PRESALE: Invalid Amount"
            );
            require(
                amountRaisedPrivate.add(msg.value) <= hardCapPrivate,
                "PRESALE: Hardcap reached"
            );
            require(whiteListPrivate[msg.sender], "PRESALE: Not whiteListed");
            numberOfTokens = coinToToken(msg.value, tokenPricePrivate);
            if (tokenBalancePrivate[msg.sender] == 0) totalUser++;
            tokenBalancePrivate[msg.sender] = tokenBalancePrivate[msg.sender]
                .add(numberOfTokens);
            soldTokensPrivate = soldTokensPrivate.add(numberOfTokens);
            coinBalancePrivate[msg.sender] = coinBalancePrivate[msg.sender].add(
                msg.value
            );
            amountRaisedPrivate = amountRaisedPrivate.add(msg.value);
        } else {
            require(
                msg.value >= minAmount &&
                    coinBalanceSeed[msg.sender].add(msg.value) <= maxAmount,
                "PRESALE: Invalid Amount"
            );
            require(
                amountRaisedSeed.add(msg.value) <= hardCapSeed,
                "PRESALE: Hardcap reached"
            );
            require(whiteListSeed[msg.sender], "PRESALE: Not whiteListed");
            numberOfTokens = coinToToken(msg.value, tokenPriceSeed);
            if (tokenBalanceSeed[msg.sender] == 0) totalUser++;
            tokenBalanceSeed[msg.sender] = tokenBalanceSeed[msg.sender].add(
                numberOfTokens
            );
            soldTokensSeed = soldTokensSeed.add(numberOfTokens);
            coinBalanceSeed[msg.sender] = coinBalanceSeed[msg.sender].add(
                msg.value
            );
            amountRaisedSeed = amountRaisedSeed.add(msg.value);
        }

        emit TokenBought(msg.sender, numberOfTokens, msg.value);
    }

    // to claim token after launch => for web3 use
    function claim() public allowed {
        require(
            block.timestamp > preSaleEndTime,
            "PRESALE: Presale time not over"
        );
        require(canClaim, "PRESALE: Wait for the owner to end preSale");
        require(
            tokenBalancePublic[msg.sender]
                .add(tokenBalancePrivate[msg.sender])
                .add(tokenBalancePrivate[msg.sender]) > 0,
            "PRESALE: Public zero balance"
        );
        require(
            block.timestamp >= preSaleEndTime + vestingTime &&
                claimCount[msg.sender] <= currentClaimCycle,
            "PRESALE: Wait for next claim date"
        );

        // >>>> Public Sale
        if (
            amountRaisedPublic >= softCapPublic &&
            voteUp >= voteDown &&
            tokenBalancePublic[msg.sender] > 0
        ) {
            if (claimCount[msg.sender] == 0) {
                activeClaimAmountTokenPublic[msg.sender] = tokenBalancePublic[
                    msg.sender
                ].mul(vestingPercent).div(100);
                activeClaimAmountCoinPublic[msg.sender] = coinBalancePublic[
                    msg.sender
                ].mul(vestingPercent).div(100);

                token.transfer(
                    msg.sender,
                    activeClaimAmountTokenPublic[msg.sender]
                );
                tokenBalancePublic[msg.sender] = tokenBalancePublic[msg.sender]
                    .sub(activeClaimAmountTokenPublic[msg.sender]);
                coinBalancePublic[msg.sender] = coinBalancePublic[msg.sender]
                    .sub(activeClaimAmountCoinPublic[msg.sender]);
            } else {
                if (
                    tokenBalancePublic[msg.sender] >
                    activeClaimAmountTokenPublic[msg.sender]
                ) {
                    token.transfer(
                        msg.sender,
                        activeClaimAmountTokenPublic[msg.sender]
                    );
                    tokenBalancePublic[msg.sender] = tokenBalancePublic[
                        msg.sender
                    ].sub(activeClaimAmountTokenPublic[msg.sender]);
                    coinBalancePublic[msg.sender] = coinBalancePublic[
                        msg.sender
                    ].sub(activeClaimAmountCoinPublic[msg.sender]);
                } else {
                    token.transfer(msg.sender, tokenBalancePublic[msg.sender]);
                    tokenBalancePublic[msg.sender] = 0;
                    coinBalancePublic[msg.sender] = 0;
                }
            }

            emit TokenClaimed(
                msg.sender,
                activeClaimAmountTokenPublic[msg.sender]
            );
        } else {
            uint256 numberOfTokens = coinBalancePublic[msg.sender];

            payable(msg.sender).transfer(numberOfTokens);
            coinBalancePublic[msg.sender] = 0;

            emit CoinClaimed(msg.sender, numberOfTokens);
        }

        // >>>> Private Sale
        if (
            amountRaisedPrivate >= softCapPrivate &&
            voteUp >= voteDown &&
            whiteListPrivate[msg.sender] &&
            tokenBalancePrivate[msg.sender] > 0
        ) {
            if (claimCount[msg.sender] == 0) {
                activeClaimAmountTokenPrivate[msg.sender] = tokenBalancePrivate[
                    msg.sender
                ].mul(vestingPercent).div(100);
                activeClaimAmountCoinPrivate[msg.sender] = coinBalancePrivate[
                    msg.sender
                ].mul(vestingPercent).div(100);

                token.transfer(
                    msg.sender,
                    activeClaimAmountTokenPrivate[msg.sender]
                );
                tokenBalancePrivate[msg.sender] = tokenBalancePrivate[
                    msg.sender
                ].sub(activeClaimAmountTokenPrivate[msg.sender]);
                coinBalancePrivate[msg.sender] = coinBalancePrivate[msg.sender]
                    .sub(activeClaimAmountCoinPrivate[msg.sender]);
            } else {
                if (
                    tokenBalancePrivate[msg.sender] >
                    activeClaimAmountTokenPrivate[msg.sender]
                ) {
                    token.transfer(
                        msg.sender,
                        activeClaimAmountTokenPrivate[msg.sender]
                    );
                    tokenBalancePrivate[msg.sender] = tokenBalancePrivate[
                        msg.sender
                    ].sub(activeClaimAmountTokenPrivate[msg.sender]);
                    coinBalancePrivate[msg.sender] = coinBalancePrivate[
                        msg.sender
                    ].sub(activeClaimAmountCoinPrivate[msg.sender]);
                } else {
                    token.transfer(msg.sender, tokenBalancePublic[msg.sender]);
                    tokenBalancePrivate[msg.sender] = 0;
                    coinBalancePrivate[msg.sender] = 0;
                }
            }

            emit TokenClaimed(
                msg.sender,
                activeClaimAmountTokenPrivate[msg.sender]
            );
        } else {
            uint256 numberOfTokens = coinBalancePrivate[msg.sender];

            payable(msg.sender).transfer(numberOfTokens);
            coinBalancePrivate[msg.sender] = 0;

            emit CoinClaimed(msg.sender, numberOfTokens);
        }

        // >>>> Seed Sale
        if (
            amountRaisedSeed >= softCapSeed &&
            voteUp >= voteDown &&
            whiteListSeed[msg.sender] &&
            tokenBalanceSeed[msg.sender] > 0
        ) {
            if (claimCount[msg.sender] == 0) {
                activeClaimAmountTokenSeed[msg.sender] = tokenBalanceSeed[
                    msg.sender
                ].mul(vestingPercent).div(100);
                activeClaimAmountCoinSeed[msg.sender] = coinBalanceSeed[
                    msg.sender
                ].mul(vestingPercent).div(100);

                token.transfer(
                    msg.sender,
                    activeClaimAmountTokenSeed[msg.sender]
                );
                tokenBalanceSeed[msg.sender] = tokenBalanceSeed[msg.sender].sub(
                    activeClaimAmountTokenSeed[msg.sender]
                );
                coinBalanceSeed[msg.sender] = coinBalanceSeed[msg.sender].sub(
                    activeClaimAmountCoinSeed[msg.sender]
                );
            } else {
                if (
                    tokenBalanceSeed[msg.sender] >
                    activeClaimAmountTokenSeed[msg.sender]
                ) {
                    token.transfer(
                        msg.sender,
                        activeClaimAmountTokenSeed[msg.sender]
                    );
                    tokenBalanceSeed[msg.sender] = tokenBalanceSeed[msg.sender]
                        .sub(activeClaimAmountTokenSeed[msg.sender]);
                    coinBalanceSeed[msg.sender] = coinBalanceSeed[msg.sender]
                        .sub(activeClaimAmountCoinSeed[msg.sender]);
                } else {
                    token.transfer(msg.sender, tokenBalancePublic[msg.sender]);
                    tokenBalanceSeed[msg.sender] = 0;
                    coinBalanceSeed[msg.sender] = 0;
                }
            }

            emit TokenClaimed(
                msg.sender,
                activeClaimAmountTokenSeed[msg.sender]
            );
        } else {
            uint256 numberOfTokens = coinBalanceSeed[msg.sender];

            payable(msg.sender).transfer(numberOfTokens);
            coinBalanceSeed[msg.sender] = 0;

            emit CoinClaimed(msg.sender, numberOfTokens);
        }

        claimCount[msg.sender]++;
    }

    // withdraw the funds and initialize the liquidity pool
    function endPreSale() public onlyTokenOwner allowed {
        require(block.timestamp > listingTime, "PRESALE: Listing time not met");

        // >>>> Public Sale
        if (tokenPricePublic != 0) {
            if (amountRaisedPublic >= softCapPublic && voteUp >= voteDown) {
                if (!profitClaim) {
                    activeClaimAmountCoinPublic[address(this)] = (
                        amountRaisedPublic.mul(liquidityPercent).div(100)
                    ).mul(vestingPercent).div(100);
                    activeClaimAmountTokenPublic[address(this)] = (
                        listingTokens(
                            activeClaimAmountCoinPublic[address(this)]
                        )
                    ).mul(vestingPercent).div(100);
                    uint256 _adminFee = amountRaisedPublic
                        .mul(adminFeePercent)
                        .div(100);
                    admin.transfer(_adminFee);
                    token.transfer(
                        admin,
                        soldTokensPublic.mul(adminFeePercent).div(100)
                    );
                    uint256 refundToken = coinToToken(hardCapPublic, tokenPricePublic)
                        .add(listingTokens(hardCapPublic))
                        .sub(soldTokensPublic)
                        .sub(activeClaimAmountTokenPublic[address(this)]);
                    if (refundToken > 0)
                        token.transfer(tokenOwner, refundToken);
                    uint256 remainingCoin = amountRaisedPublic.sub(
                        amountRaisedPublic.mul(liquidityPercent).div(100)
                    );
                    tokenOwnerProfit = remainingCoin.mul(vestingPercent).div(
                        100
                    );
                    tokenOwner.transfer(tokenOwnerProfit.sub(_adminFee));

                    emit TokenUnSold(tokenOwner, refundToken);
                } else {
                    require(
                        block.timestamp >= preSaleEndTime + vestingTime &&
                            claimCount[address(this)] <= currentClaimCycle,
                        "PRESALE: Wait for next claim date"
                    );
                    tokenOwner.transfer(tokenOwnerProfit);
                }
                token.approve(
                    address(routerAddress),
                    activeClaimAmountTokenPublic[address(this)]
                );
                addLiquidity(
                    activeClaimAmountTokenPublic[address(this)],
                    activeClaimAmountCoinPublic[address(this)]
                );
                claimCount[address(this)]++;
            } else {
                uint256 numberOfTokens = coinToToken(hardCapPublic, tokenPricePublic).add(listingTokens(hardCapPublic));
                token.transfer(tokenOwner, numberOfTokens);

                emit TokenUnSold(tokenOwner, numberOfTokens);
            }
        }

        // >>>> Private Sale
        if (tokenPricePrivate != 0) {
            if (amountRaisedPrivate >= softCapPrivate && voteUp > voteDown) {
                if (!profitClaim) {
                    uint256 _adminFee = amountRaisedPrivate
                        .mul(adminFeePercent)
                        .div(100);
                    admin.transfer(_adminFee);
                    token.transfer(
                        admin,
                        soldTokensPrivate.mul(adminFeePercent).div(100)
                    );
                    tokenOwnerProfit = amountRaisedPrivate
                        .mul(vestingPercent)
                        .div(100);
                    uint256 refundToken = coinToToken(hardCapPrivate, tokenPricePrivate).sub(soldTokensPrivate);
                    if (refundToken > 0)
                        token.transfer(tokenOwner, refundToken);
                    tokenOwner.transfer(tokenOwnerProfit.sub(_adminFee));

                    emit TokenUnSold(tokenOwner, refundToken);
                } else {
                    require(
                        block.timestamp >= preSaleEndTime + vestingTime &&
                            claimCount[msg.sender] <= currentClaimCycle,
                        "PRESALE: Wait for next claim date"
                    );
                    token.transfer(tokenOwner, tokenOwnerProfit);
                }
            } else {
                uint256 numberOfTokens = coinToToken(hardCapPrivate, tokenPricePrivate);
                token.transfer(tokenOwner, numberOfTokens);

                emit TokenUnSold(tokenOwner, numberOfTokens);
            }
        }

        // >>>> Seed Sale
        if (tokenPriceSeed != 0) {
            if (amountRaisedSeed >= softCapSeed && voteUp > voteDown) {
                if (!profitClaim) {
                    uint256 _adminFee = amountRaisedSeed
                        .mul(adminFeePercent)
                        .div(100);
                    admin.transfer(_adminFee);
                    token.transfer(
                        admin,
                        soldTokensSeed.mul(adminFeePercent).div(100)
                    );
                    tokenOwnerProfit = amountRaisedSeed.mul(vestingPercent).div(
                            100
                        );
                    uint256 refundToken = coinToToken(hardCapSeed, tokenPriceSeed).sub(
                        soldTokensSeed
                    );
                    if (refundToken > 0)
                        token.transfer(tokenOwner, refundToken);
                    tokenOwner.transfer(tokenOwnerProfit.sub(_adminFee));

                    emit TokenUnSold(tokenOwner, refundToken);
                } else {
                    require(
                        block.timestamp >= preSaleEndTime + vestingTime &&
                            claimCount[msg.sender] <= currentClaimCycle,
                        "PRESALE: Wait for next claim date"
                    );
                    token.transfer(tokenOwner, tokenOwnerProfit);
                }
            } else {
                uint256 numberOfTokens = coinToToken(hardCapSeed, tokenPriceSeed);
                token.transfer(tokenOwner, numberOfTokens);

                emit TokenUnSold(tokenOwner, numberOfTokens);
            }
        }
        if (!profitClaim) {
            profitClaim = true;
            preSaleEndTime = block.timestamp;
            canClaim = true;
        }
    }

    function vote(bool _vote) public {
        require(
            token.balanceOf(msg.sender) > 0,
            "VOTING: Voter must be a holder"
        );
        require(
            !usersVoting[msg.sender][currentVotingCycle].voteCasted,
            "VOTING: Already cast a vote"
        );
        require(votingStatus, "VOTING: Not Allowed");
        require(
            block.timestamp >= votingStartTime &&
                block.timestamp < votingEndTime,
            "VOTING: Wrong Timing"
        );

        usersVoting[msg.sender][currentVotingCycle].vote = _vote;
        usersVoting[msg.sender][currentVotingCycle].voteCasted = true;

        if (_vote) {
            voteUp = voteUp.add(1);
        } else {
            voteDown = voteDown.add(1);
        }
    }

    function addLiquidity(uint256 tokenAmount, uint256 coinAmount) internal {
        IPancakeRouter02 pancakeRouter = IPancakeRouter02(routerAddress);

        // add the liquidity
        pancakeRouter.addLiquidityETH{value: coinAmount}(
            address(token),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            tokenOwner,
            block.timestamp + 360
        );
    }

    function startVoting(uint256 _endTime) external onlyAdmin {
        require(!votingStatus, "VOTING: Already started");
        require(
            block.timestamp > preSaleEndTime.add(vestingTime),
            "VOTING: Presale not end"
        );
        votingStatus = true;
        voteUp = 0;
        voteDown = 0;
        votingStartTime = block.timestamp;
        votingEndTime = block.timestamp.add(_endTime);
        currentVotingCycle++;
    }

    function endVoting() external onlyAdmin {
        require(votingStatus, "VOTING: Already ended");
        votingStatus = false;
        vestingTime = vestingTime.add(vestingTime);
        currentClaimCycle++;
    }

    function setWhiteListPrivate(address[] memory _users)
        external
        onlyTokenOwner
    {
        for (uint256 i = 0; i < _users.length; i++) {
            whiteListPrivate[_users[i]] = true;
        }
    }

    function setWhiteListSeed(address[] memory _users) external onlyTokenOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            whiteListSeed[_users[i]] = true;
        }
    }

    // to check number of token for buying
    function coinToToken(uint256 _amount, uint256 _tokenPrice)
        public
        view
        returns (uint256)
    {
        uint256 numberOfTokens = _amount.mul(_tokenPrice);
        return numberOfTokens.mul(10**(token.decimals())).div(1e18);
    }

    // to calculate number of tokens for listing price
    function listingTokens(uint256 _amount) public view returns (uint256) {
        uint256 numberOfTokens = _amount.mul(listingPrice);
        return numberOfTokens.mul(10**(token.decimals())).div(1e18);
    }

    // to check contribution
    function userContribution(address _user) public view returns (uint256) {
        return coinBalancePublic[_user];
    }

    // to check token balance of user
    function userTokenBalancePublic(address _user)
        public
        view
        returns (uint256)
    {
        return tokenBalancePublic[_user];
    }

    // to Stop preSale in case of scam
    function setAllow(bool _enable) external onlyAdmin {
        allow = _enable;
    }

    function getContractcoinBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getContractTokenBalance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function getCurrentTime() public view returns (uint256) {
        return block.timestamp;
    }

    // get user voting data
    function getUserVotingData(address _user, uint256 _votingIndex)
        public
        view
        returns (bool _vote, bool _voteCasted)
    {
        return (
            usersVoting[_user][_votingIndex].vote,
            usersVoting[_user][_votingIndex].voteCasted
        );
    }

    function setTime(uint256 _presaleEndTime) external onlyTokenOwner {
        preSaleEndTime = _presaleEndTime;
    }
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: MIT

// import './PreSaleOpt.sol';
import "./PreSale.sol";
import "./AbstractContracts/ReentrancyGuard.sol";

contract preSaledeployerOPT is ReentrancyGuard {
    using SafeMath for uint256;
    address payable public admin;
    // IERC20 public opttoken;
    address public routerAddress;
    // uint256 public adminFee;
    uint256 public adminFeePercent;

    mapping(address => mapping(uint8 => bool)) public isInitialized;
    mapping(address => mapping(uint8 => address)) public getPreSale;
    mapping(address => uint8) public preSaleCount;
    address[] public allPreSales;

    modifier onlyAdmin() {
        require(msg.sender == admin, "OPT: Not an admin");
        _;
    }

    event PreSaleCreated(
        address indexed _token,
        address indexed _preSale,
        uint256 indexed _length
    );

    constructor() {
        admin = payable(0x607541193dd9f7D3409f97b587EE3ab3d515C271); //0x2dC900A489DA7d5Eb5E1eAc7F6B9f9246f4dD16d
        // opttoken = IERC20(0x9EBb8eDa4Afa430801484d03ae26DDDe204E8cdE);
        // adminFee = 100e18;
        adminFeePercent = 3;
        routerAddress = (0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3); //0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
    }

    receive() external payable {}

    // 0 => _presaleTime,
    // 1 => _vestingTime,
    // 2 => _vestingPercent,
    // 3 => _liquidityPercent,
    // 4 => _minAmount,
    // 5 => _maxAmount,
    // 6 => _tokenPricePublic,
    // 7 => _hardCapPublic,
    // 8 => _softCapPublic,
    // 9 => _tokenPricePrivate,
    // 10 => _hardCapPrivate,
    // 11 => _softCapPrivate,
    // 12 => _tokenPriceSeed,
    // 13 => _hardCapSeed,
    // 14 => _softCapSeed,
    // 15 => _listingPrice,

    function createPreSale(IERC20 _token, uint256[] memory _preSaleData)
        external
        returns (address preSaleContract)
    {
        // require(opttoken.balanceOf(msg.sender)>=adminFee,"OPT: you have insufficient amount of opt tokens to create presale");
        // require(address(_token) != address(0), 'OPT: ZERO_ADDRESS');
        // opttoken.transferFrom(msg.sender, admin, adminFee);

        bytes memory bytecode = type(preSale).creationCode;
        bytes32 salt = keccak256(
            abi.encodePacked(_token, msg.sender, allPreSales.length)
        );

        assembly {
            preSaleContract := create2(
                0,
                add(bytecode, 32),
                mload(bytecode),
                salt
            )
        }

        IPreSale(preSaleContract).initialize(
            admin,
            msg.sender,
            _token,
            routerAddress,
            adminFeePercent,
            _preSaleData
        );
        getPreSale[address(_token)][
            ++preSaleCount[address(_token)]
        ] = preSaleContract;
        allPreSales.push(preSaleContract);

        uint256 tokensForPublicSale = getNumberOfTokensForSale(
            _preSaleData[6],
            _preSaleData[7]
        );
        tokensForPublicSale = tokensForPublicSale.mul(
            10**(IERC20(_token).decimals())
        );
        uint256 tokensForPrivateSale = getNumberOfTokensForSale(
            _preSaleData[9],
            _preSaleData[10]
        );
        tokensForPrivateSale = tokensForPrivateSale.mul(
            10**(IERC20(_token).decimals())
        );
        uint256 tokensForSeedSale = getNumberOfTokensForSale(
            _preSaleData[12],
            _preSaleData[13]
        );
        tokensForSeedSale = tokensForSeedSale.mul(
            10**(IERC20(_token).decimals())
        );
        uint256 tokensForListing = getNumberOfTokensForListing(
            _preSaleData[7],
            _preSaleData[15],
            _preSaleData[3]
        );
        tokensForListing = tokensForListing.mul(
            10**(IERC20(_token).decimals())
        );

        _token.transferFrom(
            msg.sender,
            preSaleContract,
            tokensForPublicSale
                .add(tokensForPrivateSale)
                .add(tokensForSeedSale)
                .add(tokensForListing)
        );

        emit PreSaleCreated(
            address(_token),
            preSaleContract,
            allPreSales.length
        );
    }

    // function initializePublicPreSale(
    //     address _token,
    //     uint256 _tokenPrice,
    //     uint256 _hardCap,
    //     uint256 _tokenPricePrivate,
    //     uint256 _hardCapPrivate,
    //     uint256 _tokenPriceSeed,
    //     uint256 _hardCapSeed,
    //     uint256 _listingPrice,
    //     uint256 _liquidityPercent
    // ) external isHuman () {
    //     require(getPreSale[_token][preSaleCount[_token]] != address(0),"OPT: No preSale found");
    //     require(!isInitialized[_token][preSaleCount[_token]],"OPT: Already initialized");

    //     uint256 tokenAmount = getTotalNumberOfTokens(
    //         _tokenPrice,
    //         _hardCap,
    //         _tokenPricePrivate,
    //         _hardCapPrivate,
    //         _tokenPriceSeed,
    //         _hardCapSeed,
    // _listingPrice,
    // _liquidityPercent
    //     );
    //     tokenAmount = tokenAmount.mul(10 ** (IERC20(_token).decimals()));
    //     IERC20(_token).transferFrom(msg.sender, getPreSale[_token][preSaleCount[_token]], tokenAmount);
    //     IPreSale(getPreSale[_token][preSaleCount[_token]]).initializeRemaining(
    //         _tokenPrice,
    //         _hardCap,
    //         _listingPrice,
    //         _liquidityPercent
    //     );
    //     isInitialized[_token][preSaleCount[_token]] = true;
    // }

    // function initializePrivatePreSale(
    //     address _token,
    //     uint256 _softCapPublic,
    //     uint256 _softCapPrivate,
    //     uint256 _softCapSeed,
    //     uint256 _listingTime
    // ) external isHuman () {
    //     require(getPreSale[_token][preSaleCount[_token]] != address(0),"OPT: No preSale found");
    //     require(!isInitialized[_token][preSaleCount[_token]],"OPT: Already initialized");

    // IPreSale(getPreSale[_token][preSaleCount[_token]]).initializeRemaining(
    //     _tokenPrice,
    //     _presaleTime,
    //     _hardCap,
    //     _softCap,
    //     _listingPrice,
    //     _listingTime,
    //     _liquidityPercent
    // );
    //     isInitialized[_token][preSaleCount[_token]] = true;
    // }

    function getNumberOfTokensForSale(uint256 _tokenPrice, uint256 _hardCap)
        public
        view
        returns (uint256)
    {
        uint256 tokensForSale = _hardCap.mul(_tokenPrice).mul(1e8).div(1e18);
        tokensForSale = tokensForSale.add(
            tokensForSale.mul(adminFeePercent).div(100)
        );
        return tokensForSale.div(1e8);
    }

    function getNumberOfTokensForListing(
        uint256 _hardCap,
        uint256 _listingPrice,
        uint256 _liquidityPercent
    ) public pure returns (uint256) {
        uint256 tokensForListing = (_hardCap.mul(_liquidityPercent).div(100))
            .mul(_listingPrice)
            .mul(1e8)
            .div(1e18);
        return tokensForListing.div(1e8);
    }

    function setAdmin(address payable _admin) external onlyAdmin {
        admin = _admin;
    }

    // function createPreSaleOpt(
    //     admin,
    //     IERC20 _token,
    //     uint256 _minAmount,
    //     uint256 _maxAmount,
    //     uint256 _vestingTime,
    //     uint8 _vestingPercent,
    //     uint8 _saleNo
    // ) external returns (address preSaleContractOpt) {
    //     require(opttoken.balanceOf(msg.sender)>=adminFee,"OPT: you have insufficient amount of opt tokens to create presale");
    //     require(address(_token) != address(0), 'OPT: ZERO_ADDRESS');
    //     opttoken.transferFrom(msg.sender, admin, adminFee);

    //     bytes memory bytecode = type(preSaleOpt).creationCode;
    //     bytes32 salt = keccak256(abi.encodePacked(_token, msg.sender));

    //     assembly {
    //         preSaleContractOpt := create2(0, add(bytecode, 32), mload(bytecode), salt)
    //     }

    //     IPreSale(preSaleContractOpt).initialize(
    //         msg.sender,
    //         _token,
    //         _minAmount,
    //         _maxAmount,
    //         routerAddress,
    //         adminFeePercent,
    //         _vestingTime,
    //         _vestingPercent,
    //         _saleNo
    //     );
    //     getPreSale[address(_token)][++preSaleCount[address(_token)]] = preSaleContractOpt;
    //     allPreSales.push(preSaleContractOpt);

    //     emit PreSaleCreated(address(_token), preSaleContractOpt, allPreSales.length);
    // }

    // function setAdminFee(uint256 _fee) external onlyAdmin{
    //     adminFee = _fee;
    // }

    function setAdminFeePercent(uint256 _percent) external onlyAdmin {
        adminFeePercent = _percent;
    }

    function getCurrentTime() public view returns (uint256) {
        return block.timestamp;
    }

    function setRouter(address _router) public onlyAdmin {
        routerAddress = _router;
    }
}

