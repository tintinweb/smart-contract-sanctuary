/**
 *Submitted for verification at snowtrace.io on 2021-12-01
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() {}

    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    function _now() internal view returns (uint256) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return block.timestamp;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// pragma solidity >=0.6.2;

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface ITreasury {
    function deposit(
        uint256 _amount,
        address _token,
        uint256 _profit
    ) external returns (uint256 send_);
}

contract DeathIDO is Ownable, ReentrancyGuard {
    struct RoundSale {
        uint256 price;
        uint256 minSpend;
        uint256 maxSpend;
        uint256 startingTimeStamp;
    }
    // DEATH token
    IERC20 public DEATH;
    // BuyingToken token
    IERC20 public BuyingToken;
    // Trader Joe router
    IUniswapV2Router02 public immutable uniswapV2Router;
    // Treasury Address
    address public treasury;

    uint256 public constant DEATH_ALLOCATION = 30000000000000; // hardcap 30k DEATH
    // Set round active 1 pre, 2 public
    uint256 public roundActive = 1;
    // Store detail earch round
    mapping(uint256 => RoundSale) public rounds;
    // Whitelisting list
    mapping(address => bool) public whiteListed;
    // Total DEATH user buy
    mapping(address => uint256) public tokenBoughtTotal;
    // Total BuyingToken spend for limits earch user
    mapping(uint256 => mapping(address => uint256))
        public totalBuyingTokenSpend;
    // Total DEATH sold
    uint256 public totalTokenSold = 0;
    // Claim token
    uint256[] public claimableTimestamp;
    mapping(uint256 => uint256) public claimablePercents;
    mapping(address => uint256) public claimCounts;

    event TokenBuy(address user, uint256 tokens);
    event TokenClaim(address user, uint256 tokens);

    constructor(address _DEATH, address _BuyingToken) {
        DEATH = IERC20(_DEATH);
        BuyingToken = IERC20(_BuyingToken);
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x60aE616a2155Ee3d9A68541Ba4544862310933d4
        );
        uniswapV2Router = _uniswapV2Router;
    }

    /* User methods */
    function buy(uint256 _amount) public nonReentrant {
        require(
            roundActive == 1 || roundActive == 2,
            "No open sale rounds found"
        );
        RoundSale storage roundCurrent = rounds[roundActive];
        require(
            block.timestamp >= roundCurrent.startingTimeStamp,
            "Presale has not started"
        );
        require(
            roundActive != 1 || whiteListed[_msgSender()] == true,
            "Not whitelisted"
        );
        require(
            totalBuyingTokenSpend[roundActive][_msgSender()] + _amount >=
                roundCurrent.minSpend,
            "Below minimum amount"
        );
        require(
            totalBuyingTokenSpend[roundActive][_msgSender()] + _amount <=
                roundCurrent.maxSpend,
            "You have reached maximum spend amount per user"
        );

        uint256 tokens = (_amount * 1e9 / roundCurrent.price);

        require(
            totalTokenSold + tokens <= DEATH_ALLOCATION,
            "Token presale hardcap reached"
        );

        BuyingToken.transferFrom(_msgSender(), address(this), _amount);

        tokenBoughtTotal[_msgSender()] += tokens;
        totalBuyingTokenSpend[roundActive][_msgSender()] += _amount;

        totalTokenSold += tokens;
        emit TokenBuy(_msgSender(), tokens);
    }

    function claim() external nonReentrant {
        uint256 userBought = tokenBoughtTotal[_msgSender()];
        require(userBought > 0, "Nothing to claim");
        require(claimableTimestamp.length > 0, "Can not claim at this time");
        require(_now() >= claimableTimestamp[0], "Can not claim at this time");

        uint256 startIndex = claimCounts[_msgSender()];
        require(
            startIndex < claimableTimestamp.length,
            "You have claimed all token"
        );

        uint256 tokenQuantity = 0;
        for (
            uint256 index = startIndex;
            index < claimableTimestamp.length;
            index++
        ) {
            uint256 timestamp = claimableTimestamp[index];
            if (_now() >= timestamp) {
                tokenQuantity +=
                    (userBought * claimablePercents[timestamp]) /
                    100;
                claimCounts[_msgSender()]++;
            } else {
                break;
            }
        }

        require(tokenQuantity > 0, "Token quantity is not enough to claim");
        require(
            DEATH.transfer(_msgSender(), tokenQuantity),
            "Can not transfer DEATH"
        );

        emit TokenClaim(_msgSender(), tokenQuantity);
    }

    function getTokenBought(address _buyer) public view returns (uint256) {
        require(_buyer != address(0), "Zero address");
        return tokenBoughtTotal[_buyer];
    }

    function getRoundActive() public view returns (uint256) {
        return roundActive;
    }

    /* Admin methods */

    function setActiveRound(uint256 _roundId) external onlyOwner {
        require(_roundId == 1 || _roundId == 2, "Round ID invalid");
        roundActive = _roundId;
    }

    function setRoundSale(
        uint256 _roundId,
        uint256 _price,
        uint256 _minSpend,
        uint256 _maxSpend,
        uint256 _startingTimeStamp
    ) external onlyOwner {
        require(_roundId == 1 || _roundId == 2, "Round ID invalid");
        require(_minSpend < _maxSpend, "Spend invalid");

        rounds[_roundId] = RoundSale({
            price: _price,
            minSpend: _minSpend,
            maxSpend: _maxSpend,
            startingTimeStamp: _startingTimeStamp
        });
    }

    function setClaimableBlocks(uint256[] memory _timestamp)
        external
        onlyOwner
    {
        require(_timestamp.length > 0, "Empty input");
        claimableTimestamp = _timestamp;
    }

    function setClaimablePercents(
        uint256[] memory _timestamps,
        uint256[] memory _percents
    ) external onlyOwner {
        require(_timestamps.length > 0, "Empty input");
        require(_timestamps.length == _percents.length, "Empty input");
        for (uint256 index = 0; index < _timestamps.length; index++) {
            claimablePercents[_timestamps[index]] = _percents[index];
        }
    }

    function setUsdcToken(address _newAddress) external onlyOwner {
        require(_newAddress != address(0), "Zero address");
        BuyingToken = IERC20(_newAddress);
    }

    function setDeathToken(address _newAddress) external onlyOwner {
        require(_newAddress != address(0), "Zero address");
        DEATH = IERC20(_newAddress);
    }

    function addToWhiteList(address[] memory _accounts) external onlyOwner {
        require(_accounts.length > 0, "Invalid input");
        for (uint256 i; i < _accounts.length; i++) {
            whiteListed[_accounts[i]] = true;
        }
    }

    function removeFromWhiteList(address[] memory _accounts)
        external
        onlyOwner
    {
        require(_accounts.length > 0, "Invalid input");
        for (uint256 index = 0; index < _accounts.length; index++) {
            whiteListed[_accounts[index]] = false;
        }
    }

    function getDeath() external onlyOwner {
        uint256 _BuyingBalance = BuyingToken.balanceOf(address(this));
        uint256 _amount;

        _amount = _BuyingBalance / 10; //10% of the presale funds for treasury to get tokens for you to claim
        _amount += _BuyingBalance / 40; //2.5% of the presale funds for treasury to get tokens for initial liquidity

        BuyingToken.approve(treasury, _amount); //Approve the number of token to send

        ITreasury(treasury).deposit( // send 15% of the funds to the treasury contract, gets the needed amount of death back (for claim and liquidity)
            _amount,
            address(BuyingToken),
            0
        );
    }

    function addLiquidity() external onlyOwner {
        // get contract balances
        uint256 _DeathBalance = DEATH.balanceOf(address(this));
        uint256 _BuyBalance = BuyingToken.balanceOf(address(this));
        uint256 _BuyLiquidity = _BuyBalance * 32 / 56; //0.875 * 32 / 56 = 0.5, 50% of the initial funds for liquidity (initial 12.5% went to treasury)
        uint256 _DeathLiquidity = _DeathBalance / 5; // 20% of the DEATH for the liquidity (listing price 20 BUY per DEATH), the rest is for the buyers to claim
        uint256 _TeamFunds = _BuyBalance - _BuyLiquidity; // the rest of the funds goes to the team for marketing, devs, and more..

        // Makes sure there's enough death
        require(_DeathBalance >= _DeathLiquidity, "Not Enough DEATH token");

        // approve token transfer to cover all possible scenarios
        DEATH.approve(address(uniswapV2Router), _DeathLiquidity);
        BuyingToken.approve(address(uniswapV2Router), _BuyBalance);

        // add the liquidity
        uniswapV2Router.addLiquidity(
            address(DEATH),
            address(BuyingToken),
            _DeathLiquidity,
            _BuyLiquidity,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(0), //Sends the LP token to the address 0, which is the burn address. Liquidity is burned before anyone can even access it, rug proof :)
            block.timestamp
        );

        //Send the rest to the team
        BuyingToken.transfer(_msgSender(), _TeamFunds);
    }

    function setTreasuryAddress(address _treasury) external onlyOwner {
        treasury = _treasury;
    }

    function withdrawUnsold() external onlyOwner {
        uint256 amount = DEATH.balanceOf(address(this)) - totalTokenSold;
        DEATH.transfer(_msgSender(), amount);
    }
}