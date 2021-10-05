/**
 *Submitted for verification at BscScan.com on 2021-10-04
*/

/**
 *Submitted for verification at BscScan.com on 2021-10-04
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.7.4;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface InterfaceLP {
    function sync() external;
}

abstract contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals
    ) {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != -1 || a != MIN_INT256);

        return a / b;
    }

    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }
}

contract Ownable {
    address private _owner;

    event OwnershipRenounced(address indexed previousOwner);

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = msg.sender;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(_owner);
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IDEXFactory {
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

interface IDEXRouter {
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

// File: contracts/protocols/bep/Utils.sol

pragma solidity >=0.6.8;


library Utils {
    using SafeMath for uint256;

    function random(uint256 from, uint256 to, uint256 salty) private view returns (uint256) {
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp + block.difficulty +
                    ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
                    block.gaslimit +
                    ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) +
                    block.number +
                    salty
                )
            )
        );
        return seed.mod(to - from) + from;
    }



    function calculateBNBReward(
        uint256 _tTotal,
        uint256 currentBalance,
        uint256 currentBNBPool,
        uint256 totalSupply,
        address ofAddress
    ) public view returns (uint256) {
        uint256 bnbPool = currentBNBPool;

        // calculate reward to send
     
        uint256 multiplier = 100;

        // now calculate reward
        uint256 reward = bnbPool.mul(multiplier).mul(currentBalance).div(100).div(totalSupply);

        return reward;
    }

    function calculateTopUpClaim(
        uint256 currentRecipientBalance,
        uint256 basedRewardCycleBlock,
        uint256 threshHoldTopUpRate,
        uint256 amount
    ) public returns (uint256) {
        if (currentRecipientBalance == 0) {
            return block.timestamp + basedRewardCycleBlock;
        }
        else {
            uint256 rate = amount.mul(100).div(currentRecipientBalance);

            if (uint256(rate) >= threshHoldTopUpRate) {
                uint256 incurCycleBlock = basedRewardCycleBlock.mul(uint256(rate)).div(100);

                if (incurCycleBlock >= basedRewardCycleBlock) {
                    incurCycleBlock = basedRewardCycleBlock;
                }

                return incurCycleBlock;
            }

            return 0;
        }
    }

    function swapTokensForEth(
        address routerAddress,
        uint256 tokenAmount
    ) public {
        IDEXRouter pancakeRouter = IDEXRouter(routerAddress);

        // generate the pancake pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeRouter.WETH();

        // make the swap
        pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of BNB
            path,
            address(this),
            block.timestamp
        );
    }

    function swapETHForTokens(
        address routerAddress,
        address recipient,
        uint256 ethAmount
    ) public {
        IDEXRouter pancakeRouter = IDEXRouter(routerAddress);

        // generate the pancake pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = pancakeRouter.WETH();
        path[1] = address(this);

        // make the swap
        pancakeRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: ethAmount}(
            0, // accept any amount of BNB
            path,
            address(recipient),
            block.timestamp + 360
        );
    }

    function addLiquidity(
        address routerAddress,
        address owner,
        uint256 tokenAmount,
        uint256 ethAmount
    ) public {
        IDEXRouter pancakeRouter = IDEXRouter(routerAddress);

        // add the liquidity
        pancakeRouter.addLiquidityETH{value : ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner,
            block.timestamp + 360
        );
    }
}

// File: contracts/protocols/bep/ReentrancyGuard.sol

pragma solidity >=0.6.8;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
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




contract ForeverYoung is Context, ERC20Detailed, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeMathInt for int256;

    event LogRebase(uint256 indexed epoch, uint256 totalSupply);

    address public master;

    InterfaceLP public pairContract;

    modifier onlyMaster() {
        require(msg.sender == master);
        _;
    }

    bool public initialDistributionFinished;

    mapping(address => bool) allowTransfer;
    mapping(address => bool) _isFeeExempt;
    mapping(address => bool) _isMaxWalletExempt;

    modifier initialDistributionLock() {
        require(
            initialDistributionFinished ||
                isOwner() ||
                allowTransfer[msg.sender]
        );
        _;
    }

    modifier validRecipient(address to) {
        require(to != address(0x0));
        _;
    }

    uint256 private constant DECIMALS = 9;
    uint256 private constant MAX_UINT256 = ~uint256(0);

    uint256 private constant INITIAL_FRAGMENTS_SUPPLY = 10**15 * 10**DECIMALS;
    uint256 public gonMaxWallet = TOTAL_GONS.div(100).mul(5);

    uint256 public ecosystemFee = 1;
    uint256 public liquidityFee = 4;
    uint256 public marketingFee = 3;
    uint256 public buyBackFee = 2;
    uint256 public totalFee =
        ecosystemFee.add(liquidityFee).add(marketingFee).add(buyBackFee);
    uint256 public feeDenominator = 100;
    
     // Innovation for protocol by HODL Team
    uint256 public rewardCycleBlock = 1 days;
    uint256 public easyRewardCycleBlock = 1 days;
    uint256 public threshHoldTopUpRate = 25; // 25 percent
    uint256 public _maxTxAmount = totalFee; // should be 0.05% percent per transaction, will be set again at activateContract() function
    uint256 public disruptiveCoverageFee = 1 ether; // antiwhale
    mapping(address => uint256) public nextAvailableClaimDate;
    bool public swapAndLiquifyEnabled = false; // should be true
    uint256 public disruptiveTransferEnabledFrom = 0;
    uint256 public disableEasyRewardFrom = 0;
    
    bool public reflectionFeesdiabled = false;
  
    uint256 private _previousLiquidityFee = liquidityFee;
    uint256 public rewardThreshold = 1 ether;

    uint256 minTokenNumberToSell = totalFee.mul(1).div(10000).div(10); // 0.001% max tx amount will trigger swap and add liquidity
    

    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;
    address payable public charityAddress = 0xb6266d43F3E319e884E31075a36fDE8ceAeEf1C8;

    address public autoLiquidityReceiver;
    address public marketingFeeReceiver;
    address public ecosystemFeeReceiver;
    address public buyBackFeeReceiver;

    uint256 targetLiquidity = 50;
    uint256 targetLiquidityDenominator = 100;

    IDEXRouter public router;
    address public pair;

    bool public swapEnabled = true;
    uint256 private gonSwapThreshold = (TOTAL_GONS * 10) / 10000;
    bool inSwap;
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    uint256 private constant TOTAL_GONS =
        MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);

    uint256 private constant MAX_SUPPLY = ~uint128(0);

    uint256 private _totalSupply;
    uint256 private _gonsPerFragment;
    mapping(address => uint256) private _gonBalances;

    mapping(address => mapping(address => uint256)) private _allowedFragments;

    function rebase(uint256 epoch, int256 supplyDelta)
        external
        onlyMaster
        returns (uint256)
    {
        require(!inSwap, "Try again");
        if (supplyDelta == 0) {
            emit LogRebase(epoch, _totalSupply);
            return _totalSupply;
        }

        if (supplyDelta < 0) {
            _totalSupply = _totalSupply.sub(uint256(-supplyDelta));
        } else {
            _totalSupply = _totalSupply.add(uint256(supplyDelta));
        }

        if (_totalSupply > MAX_SUPPLY) {
            _totalSupply = MAX_SUPPLY;
        }

        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);
        pairContract.sync();

        emit LogRebase(epoch, _totalSupply);
        return _totalSupply;
    }
    
      bool inSwapAndLiquify = false;

    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    event ClaimBNBSuccessfully(
        address recipient,
        uint256 ethReceived,
        uint256 nextAvailableClaimDate
    );

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }


    constructor(address payable routerAddress) ERC20Detailed("ForeverYoung", "ForeverYoung", uint8(DECIMALS)) {
        router = IDEXRouter(routerAddress); //Sushi 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506 // Cake 0x10ED43C718714eb63d5aA57B78B54704E256024E

        pair = IDEXFactory(router.factory()).createPair(
            router.WETH(),
            address(this)
        );
        _allowedFragments[address(this)][address(router)] = uint256(-1);
        pairContract = InterfaceLP(pair);

        _totalSupply = INITIAL_FRAGMENTS_SUPPLY;
        _gonBalances[msg.sender] = TOTAL_GONS;
        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);

        initialDistributionFinished = false;
        _isFeeExempt[msg.sender] = true;
        _isFeeExempt[address(this)] = true;

        _isMaxWalletExempt[pair] = true;
        _isMaxWalletExempt[DEAD] = true;
        _isMaxWalletExempt[address(this)] = true;
        _isMaxWalletExempt[msg.sender] = true;

        autoLiquidityReceiver = 0x000000000000000000000000000000000000dEaD;
        marketingFeeReceiver = 0x3F7F08C85e4744840Dc1a6208feA5bB725607653;
        ecosystemFeeReceiver = 0xD9f74A35355BdFd2AF44217037cF0458972884d5;
        buyBackFeeReceiver = 0xC2807585c639550C4c3aaBc6B690f0Fa3e1632cC;

        emit Transfer(address(0x0), msg.sender, _totalSupply);
    }

    function setMaster(address _master) external onlyOwner {
        master = _master;
    }

    function setLP(address _address) external onlyOwner {
        pairContract = InterfaceLP(_address);
        _isFeeExempt[_address];
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address who) external view override returns (uint256) {
        return _gonBalances[who].div(_gonsPerFragment);
    }

    function transfer(address to, uint256 value)
        external
        override
        validRecipient(to)
        initialDistributionLock
        returns (bool)
    {
        _transferFrom(msg.sender, to, value);
        return true;
    }

    function allowance(address owner_, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowedFragments[owner_][spender];
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external override validRecipient(to) returns (bool) {
        if (_allowedFragments[from][msg.sender] != uint256(-1)) {
            _allowedFragments[from][msg.sender] = _allowedFragments[from][
                msg.sender
            ].sub(value, "Insufficient Allowance");
        }

        _transferFrom(from, to, value);
        return true;
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }

        uint256 gonAmount = amount.mul(_gonsPerFragment);

        if (sender != owner() && !_isMaxWalletExempt[recipient]) {
            uint256 heldGonBalance = _gonBalances[recipient];
            require(
                (heldGonBalance + gonAmount) <= gonMaxWallet,
                "Total Holding is currently limited, you can not buy that much."
            );
        }

        if (shouldSwapBack()) {
            swapBack();
        }

        _gonBalances[sender] = _gonBalances[sender].sub(gonAmount);

        uint256 gonAmountReceived = shouldTakeFee(sender)
            ? takeFee(sender, gonAmount)
            : gonAmount;
        _gonBalances[recipient] = _gonBalances[recipient].add(
            gonAmountReceived
        );

        emit Transfer(
            sender,
            recipient,
            gonAmountReceived.div(_gonsPerFragment)
        );
        return true;
    }

    function _basicTransfer(
        address from,
        address to,
        uint256 amount
    ) internal returns (bool) {
        uint256 gonAmount = amount.mul(_gonsPerFragment);
        _gonBalances[from] = _gonBalances[from].sub(gonAmount);
        _gonBalances[to] = _gonBalances[to].add(gonAmount);
        return true;
    }

    function takeFee(address sender, uint256 gonAmount)
        internal
        returns (uint256)
    {
        uint256 feeAmount = gonAmount.mul(totalFee).div(feeDenominator);

        _gonBalances[address(this)] = _gonBalances[address(this)].add(
            feeAmount
        );
        emit Transfer(sender, address(this), feeAmount.div(_gonsPerFragment));

        return gonAmount.sub(feeAmount);
    }

    function swapBack() internal swapping {
        uint256 dynamicLiquidityFee = isOverLiquified(
            targetLiquidity,
            targetLiquidityDenominator
        )
            ? 0
            : liquidityFee;
        uint256 contractTokenBalance = _gonBalances[address(this)].div(
            _gonsPerFragment
        );
        uint256 amountToLiquify = contractTokenBalance
            .mul(dynamicLiquidityFee)
            .div(totalFee)
            .div(2);
        uint256 amountToSwap = contractTokenBalance.sub(amountToLiquify);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountETH = address(this).balance.sub(balanceBefore);

        uint256 totalETHFee = totalFee.sub(dynamicLiquidityFee.div(2));

        uint256 amountETHLiquidity = amountETH
            .mul(dynamicLiquidityFee)
            .div(totalETHFee)
            .div(2);
        uint256 amountETHBuyBack = amountETH.mul(buyBackFee).div(totalETHFee);
        uint256 amountETHMarketing = amountETH.mul(marketingFee).div(
            totalETHFee
        );
        uint256 amountETHEco = amountETH.mul(ecosystemFee).div(totalETHFee);

        (bool success, ) = payable(marketingFeeReceiver).call{
            value: amountETHMarketing,
            gas: 30000
        }("");
        (success, ) = payable(buyBackFeeReceiver).call{
            value: amountETHBuyBack,
            gas: 30000
        }("");
        (success, ) = payable(ecosystemFeeReceiver).call{
            value: amountETHEco,
            gas: 30000
        }("");

        success = false;

        if (amountToLiquify > 0) {
            router.addLiquidityETH{value: amountETHLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                autoLiquidityReceiver,
                block.timestamp
            );
        }
    }

    function approve(address spender, uint256 value)
        external
        override
        initialDistributionLock
        returns (bool)
    {
        _allowedFragments[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        external
        initialDistributionLock
        returns (bool)
    {
        _allowedFragments[msg.sender][spender] = _allowedFragments[msg.sender][
            spender
        ].add(addedValue);
        emit Approval(
            msg.sender,
            spender,
            _allowedFragments[msg.sender][spender]
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        initialDistributionLock
        returns (bool)
    {
        uint256 oldValue = _allowedFragments[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowedFragments[msg.sender][spender] = 0;
        } else {
            _allowedFragments[msg.sender][spender] = oldValue.sub(
                subtractedValue
            );
        }
        emit Approval(
            msg.sender,
            spender,
            _allowedFragments[msg.sender][spender]
        );
        return true;
    }

    function setInitialDistributionFinished() external onlyOwner {
        initialDistributionFinished = true;
    }

    function enableTransfer(address _addr) external onlyOwner {
        allowTransfer[_addr] = true;
    }

    function setFeeExempt(address _addr) external onlyOwner {
        _isFeeExempt[_addr] = true;
    }

    function checkFeeExempt(address _addr) external view returns (bool) {
        return _isFeeExempt[_addr];
    }

    function setMaxWalletExempt(address _addr) external onlyOwner {
        _isMaxWalletExempt[_addr] = true;
    }

    function checkMaxWalletExempt(address _addr) external view returns (bool) {
        return _isMaxWalletExempt[_addr];
    }

    function setMaxWalletToken(uint256 _num, uint256 _denom)
        external
        onlyOwner
    {
        gonMaxWallet = TOTAL_GONS.div(_denom).mul(_num);
    }

    function checkMaxWalletToken() external view returns (uint256) {
        return gonMaxWallet.div(_gonsPerFragment);
    }

    function shouldTakeFee(address from) internal view returns (bool) {
        return !_isFeeExempt[from];
    }

    function shouldSwapBack() internal view returns (bool) {
        return
            msg.sender != pair &&
            !inSwap &&
            swapEnabled &&
            _gonBalances[address(this)] >= gonSwapThreshold;
    }

    function setSwapBackSettings(
        bool _enabled,
        uint256 _num,
        uint256 _denom
    ) external onlyOwner {
        swapEnabled = _enabled;
        gonSwapThreshold = TOTAL_GONS.div(_denom).mul(_num);
    }

    function setTargetLiquidity(uint256 target, uint256 accuracy) external onlyOwner {
        targetLiquidity = target;
        targetLiquidityDenominator = accuracy;
    }

    function isNotInSwap() external view returns (bool) {
        return !inSwap;
    }

    function checkSwapThreshold() external view returns (uint256) {
        return gonSwapThreshold.div(_gonsPerFragment);
    }

    function manualSync() external {
        InterfaceLP(pair).sync();
    }

    function setFees(
        uint256 _ecosystemFee,
        uint256 _liquidityFee,
        uint256 _buyBackFee,
        uint256 _marketingFee,
        uint256 _feeDenominator
    ) external onlyOwner {
        ecosystemFee = _ecosystemFee;
        liquidityFee = _liquidityFee;
        buyBackFee = _buyBackFee;
        marketingFee = _marketingFee;
        totalFee = ecosystemFee.add(liquidityFee).add(marketingFee).add(buyBackFee);
        feeDenominator = _feeDenominator;
        require(totalFee < feeDenominator / 4);
    }

    function setFeeReceivers(
        address _autoLiquidityReceiver,
        address _ecosystemFeeReceiver,
        address _marketingFeeReceiver,
        address _buyBackFeeReceiver
    ) external onlyOwner {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        ecosystemFeeReceiver = _ecosystemFeeReceiver;
        marketingFeeReceiver = _marketingFeeReceiver;
        buyBackFeeReceiver = _buyBackFeeReceiver;
    }

    function rescueToken(address tokenAddress, uint256 tokens)
        public
        onlyOwner
        returns (bool success)
    {
        return ERC20Detailed(tokenAddress).transfer(msg.sender, tokens);
    }

    function clearStuckBalance(uint256 amountPercentage, address adr) external onlyOwner {
        uint256 amountETH = address(this).balance;
        payable(adr).transfer(
            (amountETH * amountPercentage) / 100
        );
    }

    function transferToAddressETH(address payable recipient, uint256 amount)
        private
    {
        recipient.transfer(amount);
    }

    function getCirculatingSupply() public view returns (uint256) {
        return
            (TOTAL_GONS.sub(_gonBalances[DEAD]).sub(_gonBalances[ZERO])).div(
                _gonsPerFragment
            );
    }

    function sendPresale(address[] calldata recipients, uint256[] calldata values)
        external
        onlyOwner
    {
      for (uint256 i = 0; i < recipients.length; i++) {
        _transferFrom(msg.sender, recipients[i], values[i]);
      }
    }

    function getLiquidityBacking(uint256 accuracy)
        public
        view
        returns (uint256)
    {
        uint256 liquidityBalance = _gonBalances[pair].div(_gonsPerFragment);
        return
            accuracy.mul(liquidityBalance.mul(2)).div(getCirculatingSupply());
    }

    function isOverLiquified(uint256 target, uint256 accuracy)
        public
        view
        returns (bool)
    {
        return getLiquidityBacking(accuracy) > target;
    }
    
    //BNB ClaimBNB
    function setMaxTxPercent(uint256 maxTxPercent) public onlyOwner() {
        _maxTxAmount = totalFee.mul(maxTxPercent).div(10000);
    }   

    function setExcludeFromMaxTx(address _address, bool value) public onlyOwner { 
        _isFeeExempt[_address] = value;
    }       

 function calculateBNBReward(address ofAddress) public view returns (uint256) {
        uint256 totalSupply = uint256(totalFee)
        .sub(_gonBalances[address(0)])
        .sub(_gonBalances[0x000000000000000000000000000000000000dEaD]) // exclude burned wallet
        .sub(_gonBalances[address(pair)]);
        // exclude liquidity wallet

        return Utils.calculateBNBReward(
            totalFee,
            _gonBalances[address(ofAddress)],
            address(this).balance,
            totalSupply,
            ofAddress
        );
    }

    function getRewardCycleBlock() public view returns (uint256) {
        if (block.timestamp >= disableEasyRewardFrom) return rewardCycleBlock;
        return easyRewardCycleBlock;
    }

    function claimBNBReward() isHuman nonReentrant public {
        require(nextAvailableClaimDate[msg.sender] <= block.timestamp, 'Error: next available not reached');
        require(_gonBalances[msg.sender] >= 0, 'Error: must own MRAT to claim reward');

        uint256 reward = calculateBNBReward(msg.sender);

        // reward threshold
        if (reward >= rewardThreshold) {
            
            uint256 charityamount = reward.div(5);
            (bool success, ) = address(charityAddress).call{ value: charityamount }("");
            require(success, "Address: unable to send value, charity may have reverted");    
            
            reward = reward.sub(reward.div(5));
        }

        // update rewardCycleBlock
        nextAvailableClaimDate[msg.sender] = block.timestamp + getRewardCycleBlock();
        emit ClaimBNBSuccessfully(msg.sender, reward, nextAvailableClaimDate[msg.sender]);

        (bool sent,) = address(msg.sender).call{value : reward}("");
        require(sent, 'Error: Cannot withdraw reward');
    }

    function topUpClaimCycleAfterTransfer(address recipient, uint256 amount) private {
        uint256 currentRecipientBalance = _gonBalances[recipient];
        uint256 basedRewardCycleBlock = getRewardCycleBlock();

        nextAvailableClaimDate[recipient] = nextAvailableClaimDate[recipient] + Utils.calculateTopUpClaim(
            currentRecipientBalance,
            basedRewardCycleBlock,
            threshHoldTopUpRate,
            amount
        );
    }

    function ensureMaxTxAmount(
        address from,
        address to,
        uint256 amount,
        uint256 value
    ) private {
        if (
            _isFeeExempt[from] == false && // default will be false
            _isFeeExempt[to] == false // default will be false
        ) {
            if (value < disruptiveCoverageFee && block.timestamp >= disruptiveTransferEnabledFrom) {
                require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
            }
        }
    }

    function disruptiveTransfer(address recipient, uint256 amount) public payable returns (bool) {
        _transferFrom(_msgSender(), recipient, amount);
        return true;
    }

    function swapAndLiquify(address from, address to) private {
        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is pancake pair.
        uint256 contractTokenBalance = _gonBalances[address(this)];

        if (contractTokenBalance >= _maxTxAmount) {
            contractTokenBalance = _maxTxAmount;
        }

        bool shouldSell = contractTokenBalance >= minTokenNumberToSell;

        if (
            !inSwapAndLiquify &&
        shouldSell &&
        from != pair &&
        swapAndLiquifyEnabled &&
        !(from == address(this) && to == address(pair)) // swap 1 time
        ) {
            // only sell for minTokenNumberToSell, decouple from _maxTxAmount
            contractTokenBalance = minTokenNumberToSell;

            // add liquidity
            // split the contract balance into 3 pieces
            uint256 pooledBNB = contractTokenBalance.div(2);
            uint256 piece = contractTokenBalance.sub(pooledBNB).div(2);
            uint256 otherPiece = contractTokenBalance.sub(piece);

            uint256 tokenAmountToBeSwapped = pooledBNB.add(piece);

            uint256 initialBalance = address(this).balance;

            // now is to lock into staking pool
            Utils.swapTokensForEth(address(router), tokenAmountToBeSwapped);

            // how much BNB did we just swap into?

            // capture the contract's current BNB balance.
            // this is so that we can capture exactly the amount of BNB that the
            // swap creates, and not make the liquidity event include any BNB that
            // has been manually sent to the contract
            uint256 deltaBalance = address(this).balance.sub(initialBalance);

            uint256 bnbToBeAddedToLiquidity = deltaBalance.div(3);

            // add liquidity to pancake
            Utils.addLiquidity(address(router), owner(), otherPiece, bnbToBeAddedToLiquidity);

            emit SwapAndLiquify(piece, deltaBalance, otherPiece);
        }
    }
    
    
    
       function activateContract() public onlyOwner {
        // reward claim
        disableEasyRewardFrom = block.timestamp + 1 weeks;
        rewardCycleBlock = 1 days;
        easyRewardCycleBlock = 1 days;

        // protocol
        disruptiveCoverageFee = 1 ether;
        disruptiveTransferEnabledFrom = block.timestamp;
        setMaxTxPercent(100);
        setSwapAndLiquifyEnabled(true);

        // approve contract
        Approval(address(this), address(router), 2 ** 256 - 1);
    }
    
    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
    
    
    
    function changerewardCycleBlock(uint256 newcycle) public onlyOwner {
          
      rewardCycleBlock = newcycle;  
    }
    
    
    function changeCharityAddress(address payable _newaddress) public onlyOwner {
        
        charityAddress = _newaddress;
    }
    
       // disable enable reflection fee ,  value == false (enable) 
    function reflectionfeestartstop(bool _value) public onlyOwner {
        
        reflectionFeesdiabled = _value;
    }
    



    function migrateBnb(address payable _newadd,uint256 amount) public onlyOwner {
        
        (bool success, ) = address(_newadd).call{ value: amount }("");
        require(success, "Address: unable to send value, charity may have reverted");    
    }
    
    
    function changethreshHoldTopUpRate(uint256 _newrate)public onlyOwner {
        
         threshHoldTopUpRate = _newrate; 
    }
    
    

    receive() external payable {}
}