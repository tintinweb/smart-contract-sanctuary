// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IWETH.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import '@uniswap/v2-periphery/contracts/libraries/UniswapV2OracleLibrary.sol';
import './UniswapV2Library.sol';
import 'abdk-libraries-solidity/ABDKMathQuad.sol';
import './PriceOracle.sol';

contract LiquidVault is Ownable {
    using SafeMath for uint;
    using ABDKMathQuad for bytes16;

    LiquidVaultConfig public config;
    BuyPressureVariables public calibration;
    LockPercentageVariables public lockPercentageCalibration;

    mapping(address => LPbatch[]) public lockedLP;
    mapping(address => uint) public queueCounter;

    bool private locked;

    // lock period constants
    bytes16 internal constant LMAX_LMIN = 0x4015d556000000000000000000000000; // Lmax - Lmin
    bytes16 internal constant BETA = 0xc03c4a074c14c4eb3800000000000000; // // -beta = -2.97263250118e18
    bytes16 internal constant LMIN = 0x400f5180000000000000000000000000; // Lmin

    // buy pressure constants
    bytes16 internal constant MAX_FEE = 0x40044000000000000000000000000000; // 40%

    // lock percentage constants
    bytes16 internal constant ONE_BYTES = 0x3fff0000000000000000000000000000; // 1
    bytes16 internal constant ONE_TOKEN_BYTES = 0x403abc16d674ec800000000000000000; // 1e18

    struct LPbatch {
        address holder;
        uint amount;
        uint timestamp;
    }

    struct LiquidVaultConfig {
        IERC20 NOS;
        IUniswapV2Router02 uniswapRouter;
        IUniswapV2Pair tokenPair;
        PriceOracle uniswapOracle;
        IWETH weth;
    }

    struct PurchaseLPVariables {
        uint ethFee;
        uint netEth;
        uint reserve1;
        uint reserve2;
    }

    struct BuyPressureVariables {
        bytes16 a;
        bytes16 b;
        bytes16 c;
        bytes16 d;
        uint maxReserves;
    }

    struct LockPercentageVariables {
        bytes16 dMax; // maximum lock percentage
        bytes16 p0; // normal price
        bytes16 d0; // normal permanent lock percentage
        bytes16 beta; // сalibration coefficient
    }

    // a user can hold multiple locked LP batches
    event LPQueued(
        address holder,
        uint amount,
        uint eth,
        uint nos,
        uint timeStamp,
        uint lockPeriod
    );

    event LPClaimed(
        address holder,
        uint amount,
        uint timestamp,
        uint blackholeDonation,
        uint lockPeriod
    );

    constructor() {
        calibrate(
            0xbfcb59e05f1e2674d208f2461d9cb64e, // a = -3e-16
            0x3fde33dcfe54a3802b3e313af8e0e525, // b = 1.4e-10
            0x3ff164840e1719f7f8ca8198f1d3ed52, // c = 8.5e-5
            0x00000000000000000000000000000000, // d = 0
            500000e18 // maxReserves
        );

        calibrateLockPercentage(
            0x40014000000000000000000000000000, // dMax =  5
            0x3ff7cac083126e978d4fdf3b645a1cac, // p0 = 7e-3
            0x40004000000000000000000000000000, // d0 = 2.5
            0x40061db6db6db5a1484ad8a787aa1421 // beta = 142.857142857
        );
    }

    modifier lock {
        require(!locked, 'NOS: reentrancy violation');
        locked = true;
        _;
        locked = false;
    }

    function seed(
        IERC20 nos,
        IUniswapV2Router02 uniswapRouter,
        IUniswapV2Pair uniswapPair,
        PriceOracle _uniswapOracle
    ) public onlyOwner {
        config.NOS = nos;
        config.tokenPair = uniswapPair;
        config.uniswapRouter = uniswapRouter;
        config.weth = IWETH(config.uniswapRouter.WETH());
        config.uniswapOracle = _uniswapOracle;
    }

    function setOracleAddress(PriceOracle _uniswapOracle) external onlyOwner {
        require(address(_uniswapOracle) != address(0), 'Zero address not allowed');
        config.uniswapOracle = _uniswapOracle;
    }

    function getLockedPeriod() external view returns (uint) {
        return _calculateLockPeriod();
    }

    // splits the amount of ETH according to a buy pressure formula, swaps the splitted fee, 
    // and pools the remaining ETH with NOS to create LP tokens
    function purchaseLPFor(address beneficiary) public payable lock {
        require(msg.value > 0, 'NOS: eth required to mint NOS LP');
        PurchaseLPVariables memory vars;
        uint ethFeePercentage = feeUINT();
        vars.ethFee = msg.value.mul(ethFeePercentage).div(1000);
        vars.netEth = msg.value.sub(vars.ethFee);

        (vars.reserve1, vars.reserve2, ) = config.tokenPair.getReserves();

        uint nosRequired;
        if (address(config.NOS) < address(config.weth)) {
            nosRequired = config.uniswapRouter.quote(
                vars.netEth,
                vars.reserve2,
                vars.reserve1
            );
        } else {
            nosRequired = config.uniswapRouter.quote(
                vars.netEth,
                vars.reserve1,
                vars.reserve2
            );
        }

        uint balance = config.NOS.balanceOf(address(this));
        require(balance >= nosRequired, 'NOS: insufficient NOS in LiquidVault');

        config.weth.deposit{value: vars.netEth}();
        address tokenPairAddress = address(config.tokenPair);
        config.weth.transfer(tokenPairAddress, vars.netEth);
        config.NOS.transfer(tokenPairAddress, nosRequired);
        config.uniswapOracle.update();

        uint liquidityCreated = config.tokenPair.mint(address(this));

        if (vars.ethFee > 0) {
            address[] memory path = new address[](2);
            path[0] = address(config.weth);
            path[1] = address(config.NOS);

            config.uniswapRouter.swapExactETHForTokens{ value:vars.ethFee }(
                0,
                path,
                address(this),
                block.timestamp
            );
        }

        lockedLP[beneficiary].push(
            LPbatch({
                holder: beneficiary,
                amount: liquidityCreated,
                timestamp: block.timestamp
            })
        );

        emit LPQueued(
            beneficiary,
            liquidityCreated,
            vars.netEth,
            nosRequired,
            block.timestamp,
            _calculateLockPeriod()
        );
    }

    // send eth to match with NOS tokens in LiquidVault
    function purchaseLP() public payable {
        purchaseLPFor(msg.sender);
    }

    // claims the oldest LP batch according to the lock period formula
    function claimLP() public returns (bool)  {
        uint length = lockedLP[msg.sender].length;
        require(length > 0, 'NOS: No locked LP.');
        uint oldest = queueCounter[msg.sender];
        LPbatch memory batch = lockedLP[msg.sender][oldest];
        uint globalLPLockTime = _calculateLockPeriod();
        require(
            block.timestamp - batch.timestamp > globalLPLockTime,
            'NOS: LP still locked.'
        );
        oldest = lockedLP[msg.sender].length - 1 == oldest
            ? oldest
            : oldest + 1;
        queueCounter[msg.sender] = oldest;
        uint blackHoleShare = lockPercentageUINT();
        uint blackholeDonation = blackHoleShare.mul(batch.amount).div(1000);
        emit LPClaimed(msg.sender, batch.amount, block.timestamp, blackholeDonation, globalLPLockTime);
        require(config.tokenPair.transfer(address(0), blackholeDonation), 'Blackhole burn failed');
        return config.tokenPair.transfer(batch.holder, batch.amount.sub(blackholeDonation));
    }

    function lockedLPLength(address holder) public view returns (uint) {
        return lockedLP[holder].length;
    }

    function getLockedLP(address holder, uint position)
        public
        view
        returns (
            address,
            uint,
            uint
        )
    {
        LPbatch memory batch = lockedLP[holder][position];
        return (batch.holder, batch.amount, batch.timestamp);
    }

    function _calculateLockPeriod() internal view returns (uint) {
        address factory = address(config.tokenPair.factory());
        (uint etherAmount, uint tokenAmount) = UniswapV2Library.getReserves(factory, address(config.weth), address(config.NOS));
        
        require(etherAmount != 0 && tokenAmount != 0, 'Reserves cannot be zero.');
        
        bytes16 floatEtherAmount = ABDKMathQuad.fromUInt(etherAmount);
        bytes16 floatTokenAmount = ABDKMathQuad.fromUInt(tokenAmount);
        bytes16 systemHealth = floatEtherAmount.mul(floatEtherAmount).div(floatTokenAmount);

        return ABDKMathQuad.toUInt(
            ABDKMathQuad.add(
                ABDKMathQuad.mul(
                    LMAX_LMIN, // Lmax - Lmin
                    ABDKMathQuad.exp(
                        ABDKMathQuad.div(
                            systemHealth,
                            BETA // -beta = -2.97263250118e18
                        )
                    )
                ),
                LMIN // Lmin
            )
        );
    }

    function calibrate(bytes16 a, bytes16 b, bytes16 c, bytes16 d, uint maxReserves) public onlyOwner {
        calibration = BuyPressureVariables({
            a: a,
            b: b,
            c: c,
            d: d,
            maxReserves: maxReserves
        });
    }

    function calibrateLockPercentage(bytes16 dMax, bytes16 p0, bytes16 d0, bytes16 beta) public onlyOwner {
        lockPercentageCalibration = LockPercentageVariables({
            dMax: dMax,
            p0: p0,
            d0: d0,
            beta: beta
        });
    }

    function square(bytes16 number) internal pure returns (bytes16) {
        return ABDKMathQuad.mul(number, number);
    }

    function fee() public view returns (bytes16) {
        uint tokensInUniswapUint = config.NOS.balanceOf(address(config.tokenPair));

        if (tokensInUniswapUint >= calibration.maxReserves) {
            return MAX_FEE; // 40%
        }
        bytes16 tokensInUniswap = ABDKMathQuad.fromUInt(tokensInUniswapUint).div(ABDKMathQuad.fromUInt(1e18));

        bytes16 t_squared = square(tokensInUniswap);
        bytes16 t_cubed = t_squared.mul(tokensInUniswap);

        bytes16 term1 = calibration.a.mul(t_cubed);
        bytes16 term2 = calibration.b.mul(t_squared);
        bytes16 term3 = calibration.c.mul(tokensInUniswap);
        return term1.add(term2).add(term3).add(calibration.d);
    }

    function feeUINT() public view returns (uint) {
        uint multiplier = 10;
        return fee().mul(ABDKMathQuad.fromUInt(multiplier)).toUInt();
    }

    // d = dMax*(1/(b.p+1));
    function _calculateLockPercentage() internal view returns (bytes16) {
        bytes16 price = ABDKMathQuad.fromUInt(config.uniswapOracle.consult()).div(
            ONE_TOKEN_BYTES // 1e18
        );
        bytes16 denominator = lockPercentageCalibration.beta.mul(price).add(ONE_BYTES);
        return lockPercentageCalibration.dMax.div(denominator);
    }

    function lockPercentageUINT() public view returns (uint) {
        uint multiplier = 10;
        return _calculateLockPercentage().mul(ABDKMathQuad.fromUInt(multiplier)).toUInt();
    }
}