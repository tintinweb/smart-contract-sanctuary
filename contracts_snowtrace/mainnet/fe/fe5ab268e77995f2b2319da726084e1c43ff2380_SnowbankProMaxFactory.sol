/**
 *Submitted for verification at snowtrace.io on 2021-11-22
*/

/**
 *Submitted for verification at Etherscan.io on 2021-09-23
 */

// File contracts/interfaces/ISnowbankProMaxFactoryStorage.sol

pragma solidity 0.7.5;

interface ISnowbankProMaxFactoryStorage {
    function pushBond(
        address _payoutToken,
        address _principleToken,
        address _customTreasury,
        address _customBond,
        address _initialOwner,
        uint256[] calldata _tierCeilings,
        uint256[] calldata _fees
    ) external returns (address _treasury, address _bond);
}

// File contracts/types/Ownable.sol

pragma solidity 0.7.5;

contract Ownable {
    address public policy;

    constructor() {
        policy = msg.sender;
    }

    modifier onlyPolicy() {
        require(policy == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function transferManagment(address _newOwner) external onlyPolicy {
        require(_newOwner != address(0));
        policy = _newOwner;
    }
}

// File contracts/libraries/SafeMath.sol

pragma solidity 0.7.5;

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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function sqrrt(uint256 a) internal pure returns (uint256 c) {
        if (a > 3) {
            c = a;
            uint256 b = add(div(a, 2), 1);
            while (b < c) {
                c = b;
                b = div(add(div(a, b), b), 2);
            }
        } else if (a != 0) {
            c = 1;
        }
    }
}

// File contracts/libraries/Address.sol

pragma solidity 0.7.5;

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(
            data
        );
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }

    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }

    function addressToString(address _address)
        internal
        pure
        returns (string memory)
    {
        bytes32 _bytes = bytes32(uint256(_address));
        bytes memory HEX = "0123456789abcdef";
        bytes memory _addr = new bytes(42);

        _addr[0] = "0";
        _addr[1] = "x";

        for (uint256 i = 0; i < 20; i++) {
            _addr[2 + i * 2] = HEX[uint8(_bytes[i + 12] >> 4)];
            _addr[3 + i * 2] = HEX[uint8(_bytes[i + 12] & 0x0f)];
        }

        return string(_addr);
    }
}

// File contracts/interfaces/IERC20.sol

pragma solidity 0.7.5;

interface IERC20 {
    function decimals() external view returns (uint8);

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

// File contracts/libraries/SafeERC20.sol

pragma solidity 0.7.5;

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(
            value
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeERC20: decreased allowance below zero"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

// File contracts/libraries/FullMath.sol

pragma solidity 0.7.5;

library FullMath {
    function fullMul(uint256 x, uint256 y)
        private
        pure
        returns (uint256 l, uint256 h)
    {
        uint256 mm = mulmod(x, y, uint256(-1));
        l = x * y;
        h = mm - l;
        if (mm < l) h -= 1;
    }

    function fullDiv(
        uint256 l,
        uint256 h,
        uint256 d
    ) private pure returns (uint256) {
        uint256 pow2 = d & -d;
        d /= pow2;
        l /= pow2;
        l += h * ((-pow2) / pow2 + 1);
        uint256 r = 1;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        return l * r;
    }

    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 d
    ) internal pure returns (uint256) {
        (uint256 l, uint256 h) = fullMul(x, y);
        uint256 mm = mulmod(x, y, d);
        if (mm > l) h -= 1;
        l -= mm;
        require(h < d, "FullMath::mulDiv: overflow");
        return fullDiv(l, h, d);
    }
}

// File contracts/libraries/FixedPoint.sol

pragma solidity 0.7.5;

library Babylonian {
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;

        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) {
            xx >>= 128;
            r <<= 64;
        }
        if (xx >= 0x10000000000000000) {
            xx >>= 64;
            r <<= 32;
        }
        if (xx >= 0x100000000) {
            xx >>= 32;
            r <<= 16;
        }
        if (xx >= 0x10000) {
            xx >>= 16;
            r <<= 8;
        }
        if (xx >= 0x100) {
            xx >>= 8;
            r <<= 4;
        }
        if (xx >= 0x10) {
            xx >>= 4;
            r <<= 2;
        }
        if (xx >= 0x8) {
            r <<= 1;
        }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return (r < r1 ? r : r1);
    }
}

library BitMath {
    function mostSignificantBit(uint256 x) internal pure returns (uint8 r) {
        require(x > 0, "BitMath::mostSignificantBit: zero");

        if (x >= 0x100000000000000000000000000000000) {
            x >>= 128;
            r += 128;
        }
        if (x >= 0x10000000000000000) {
            x >>= 64;
            r += 64;
        }
        if (x >= 0x100000000) {
            x >>= 32;
            r += 32;
        }
        if (x >= 0x10000) {
            x >>= 16;
            r += 16;
        }
        if (x >= 0x100) {
            x >>= 8;
            r += 8;
        }
        if (x >= 0x10) {
            x >>= 4;
            r += 4;
        }
        if (x >= 0x4) {
            x >>= 2;
            r += 2;
        }
        if (x >= 0x2) r += 1;
    }
}

library FixedPoint {
    struct uq112x112 {
        uint224 _x;
    }

    struct uq144x112 {
        uint256 _x;
    }

    uint8 private constant RESOLUTION = 112;
    uint256 private constant Q112 = 0x10000000000000000000000000000;
    uint256 private constant Q224 =
        0x100000000000000000000000000000000000000000000000000000000;
    uint256 private constant LOWER_MASK = 0xffffffffffffffffffffffffffff; // decimal of UQ*x112 (lower 112 bits)

    function decode(uq112x112 memory self) internal pure returns (uint112) {
        return uint112(self._x >> RESOLUTION);
    }

    function decode112with18(uq112x112 memory self)
        internal
        pure
        returns (uint256)
    {
        return uint256(self._x) / 5192296858534827;
    }

    function fraction(uint256 numerator, uint256 denominator)
        internal
        pure
        returns (uq112x112 memory)
    {
        require(denominator > 0, "FixedPoint::fraction: division by zero");
        if (numerator == 0) return FixedPoint.uq112x112(0);

        if (numerator <= uint144(-1)) {
            uint256 result = (numerator << RESOLUTION) / denominator;
            require(result <= uint224(-1), "FixedPoint::fraction: overflow");
            return uq112x112(uint224(result));
        } else {
            uint256 result = FullMath.mulDiv(numerator, Q112, denominator);
            require(result <= uint224(-1), "FixedPoint::fraction: overflow");
            return uq112x112(uint224(result));
        }
    }

    // square root of a UQ112x112
    // lossy between 0/1 and 40 bits
    function sqrt(uq112x112 memory self)
        internal
        pure
        returns (uq112x112 memory)
    {
        if (self._x <= uint144(-1)) {
            return uq112x112(uint224(Babylonian.sqrt(uint256(self._x) << 112)));
        }

        uint8 safeShiftBits = 255 - BitMath.mostSignificantBit(self._x);
        safeShiftBits -= safeShiftBits % 2;
        return
            uq112x112(
                uint224(
                    Babylonian.sqrt(uint256(self._x) << safeShiftBits) <<
                        ((112 - safeShiftBits) / 2)
                )
            );
    }
}

// File contracts/interfaces/ITreasury.sol

pragma solidity 0.7.5;

interface ITreasury {
    function deposit(
        address _principleTokenAddress,
        uint256 _amountPrincipleToken,
        uint256 _amountPayoutToken
    ) external;

    function valueOfToken(address _principleTokenAddress, uint256 _amount)
        external
        view
        returns (uint256 value_);
}

// File contracts/SnowbankProMaxCustomBond.sol

pragma solidity 0.7.5;

contract CustomBond is Ownable {
    using FixedPoint for *;
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    /* ======== EVENTS ======== */

    event BondCreated(uint256 deposit, uint256 payout, uint256 expires);
    event BondRedeemed(address recipient, uint256 payout, uint256 remaining);
    event BondPriceChanged(uint256 internalPrice, uint256 debtRatio);
    event ControlVariableAdjustment(
        uint256 initialBCV,
        uint256 newBCV,
        uint256 adjustment,
        bool addition
    );

    /* ======== STATE VARIABLES ======== */

    IERC20 payoutToken; // token paid for principal
    IERC20 principalToken; // inflow token
    ITreasury customTreasury; // pays for and receives principal
    address snowbankDAO;
    address snowbankTreasury; // receives fee

    uint256 public totalPrincipalBonded;
    uint256 public totalPayoutGiven;

    Terms public terms; // stores terms for new bonds
    Adjust public adjustment; // stores adjustment to BCV data
    FeeTiers[] private feeTiers; // stores fee tiers

    mapping(address => Bond) public bondInfo; // stores bond information for depositors

    uint256 public totalDebt; // total value of outstanding bonds; used for pricing
    uint256 public lastDecay; // reference block for debt decay

    address subsidyRouter; // pays subsidy in OHM to custom treasury
    uint256 payoutSinceLastSubsidy; // principal accrued since subsidy paid

    /* ======== STRUCTS ======== */

    struct FeeTiers {
        uint256 tierCeilings; // principal bonded till next tier
        uint256 fees; // in ten-thousandths (i.e. 33300 = 3.33%)
    }

    // Info for creating new bonds
    struct Terms {
        uint256 controlVariable; // scaling variable for price
        uint256 vestingTerm; // in second
        uint256 minimumPrice; // vs principal value
        uint256 maxPayout; // in thousandths of a %. i.e. 500 = 0.5%
        uint256 maxDebt; // payout token decimal debt ratio, max % total supply created as debt
    }

    // Info for bond holder
    struct Bond {
        uint256 payout; // payout token remaining to be paid
        uint256 vesting; // second left to vest
        uint256 lastTime; // Last interaction
        uint256 truePricePaid; // Price paid (principal tokens per payout token) in ten-millionths - 4000000 = 0.4
    }

    // Info for incremental adjustments to control variable
    struct Adjust {
        bool add; // addition or subtraction
        uint256 rate; // increment
        uint256 target; // BCV when adjustment finished
        uint256 buffer; // minimum length (in second) between adjustments
        uint256 lastTime; // block when last adjustment made
    }

    /* ======== CONSTRUCTOR ======== */

    constructor(
        address _customTreasury,
        address _payoutToken,
        address _principalToken,
        address _snowbankTreasury,
        address _subsidyRouter,
        address _initialOwner,
        address _snowbankDAO,
        uint256[] memory _tierCeilings,
        uint256[] memory _fees
    ) {
        require(_customTreasury != address(0));
        customTreasury = ITreasury(_customTreasury);
        require(_payoutToken != address(0));
        payoutToken = IERC20(_payoutToken);
        require(_principalToken != address(0));
        principalToken = IERC20(_principalToken);
        require(_snowbankTreasury != address(0));
        snowbankTreasury = _snowbankTreasury;
        require(_subsidyRouter != address(0));
        subsidyRouter = _subsidyRouter;
        require(_initialOwner != address(0));
        policy = _initialOwner;
        require(_snowbankDAO != address(0));
        snowbankDAO = _snowbankDAO;
        require(
            _tierCeilings.length == _fees.length,
            "tier length and fee length not the same"
        );

        for (uint256 i; i < _tierCeilings.length; i++) {
            feeTiers.push(
                FeeTiers({tierCeilings: _tierCeilings[i], fees: _fees[i]})
            );
        }
    }

    /* ======== INITIALIZATION ======== */

    /**
     *  @notice initializes bond parameters
     *  @param _controlVariable uint
     *  @param _vestingTerm uint
     *  @param _minimumPrice uint
     *  @param _maxPayout uint
     *  @param _maxDebt uint
     *  @param _initialDebt uint
     */
    function initializeBond(
        uint256 _controlVariable,
        uint256 _vestingTerm,
        uint256 _minimumPrice,
        uint256 _maxPayout,
        uint256 _maxDebt,
        uint256 _initialDebt
    ) external onlyPolicy {
        require(currentDebt() == 0, "Debt must be 0 for initialization");
        terms = Terms({
            controlVariable: _controlVariable,
            vestingTerm: _vestingTerm,
            minimumPrice: _minimumPrice,
            maxPayout: _maxPayout,
            maxDebt: _maxDebt
        });
        totalDebt = _initialDebt;
        lastDecay = block.timestamp;
    }

    /* ======== POLICY FUNCTIONS ======== */

    enum PARAMETER {
        VESTING,
        PAYOUT,
        DEBT,
        MINPRICE
    }

    /**
     *  @notice set parameters for new bonds
     *  @param _parameter PARAMETER
     *  @param _input uint
     */
    function setBondTerms(PARAMETER _parameter, uint256 _input)
        external
        onlyPolicy
    {
        if (_parameter == PARAMETER.VESTING) {
            // 0
            terms.vestingTerm = _input;
        } else if (_parameter == PARAMETER.PAYOUT) {
            // 1
            require(_input <= 1000, "Payout cannot be above 1 percent");
            terms.maxPayout = _input;
        } else if (_parameter == PARAMETER.DEBT) {
            // 2
            terms.maxDebt = _input;
        } else if ( _parameter == PARAMETER.MINPRICE ) { 
            // 3
            terms.minimumPrice = _input;
        }

    }

    /**
     *  @notice set control variable adjustment
     *  @param _addition bool
     *  @param _increment uint
     *  @param _target uint
     *  @param _buffer uint
     */
    function setAdjustment(
        bool _addition,
        uint256 _increment,
        uint256 _target,
        uint256 _buffer
    ) external onlyPolicy {
        adjustment = Adjust({
            add: _addition,
            rate: _increment,
            target: _target,
            buffer: _buffer,
            lastTime: block.timestamp
        });
    }

    /**
     *  @notice change address of Olympus Treasury
     *  @param _snowbankTreasury uint
     */
    function changeSnowbankTreasury(address _snowbankTreasury) external {
        require(msg.sender == snowbankDAO, "Only Snowbank DAO");
        snowbankTreasury = _snowbankTreasury;
    }

    /**
     *  @notice subsidy controller checks payouts since last subsidy and resets counter
     *  @return payoutSinceLastSubsidy_ uint
     */
    function paySubsidy() external returns (uint256 payoutSinceLastSubsidy_) {
        require(msg.sender == subsidyRouter, "Only subsidy controller");

        payoutSinceLastSubsidy_ = payoutSinceLastSubsidy;
        payoutSinceLastSubsidy = 0;
    }

    /* ======== USER FUNCTIONS ======== */

    /**
     *  @notice deposit bond
     *  @param _amount uint
     *  @param _maxPrice uint
     *  @param _depositor address
     *  @return uint
     */
    function deposit(
        uint256 _amount,
        uint256 _maxPrice,
        address _depositor
    ) external returns (uint256) {
        require(_depositor != address(0), "Invalid address");

        decayDebt();
        require(totalDebt <= terms.maxDebt, "Max capacity reached");

        uint256 nativePrice = trueBondPrice();

        require(
            _maxPrice >= nativePrice,
            "Slippage limit: more than max price"
        ); // slippage protection

        uint256 value = customTreasury.valueOfToken(
            address(principalToken),
            _amount
        );
        uint256 payout = _payoutFor(value); // payout to bonder is computed

        require(payout >= 10**payoutToken.decimals() / 100, "Bond too small"); // must be > 0.01 payout token ( underflow protection )
        require(payout <= maxPayout(), "Bond too large"); // size protection because there is no slippage

        // profits are calculated
        uint256 fee = payout.mul(currentSnowbankFee()).div(1e6);

        /**
            principal is transferred in
            approved and
            deposited into the treasury, returning (_amount - profit) payout token
         */
        principalToken.safeTransferFrom(msg.sender, address(this), _amount);
        principalToken.approve(address(customTreasury), _amount);
        customTreasury.deposit(address(principalToken), _amount, payout);

        if (fee != 0) {
            // fee is transferred to dao
            payoutToken.transfer(snowbankTreasury, fee);
        }

        // total debt is increased
        totalDebt = totalDebt.add(value);

        // depositor info is stored
        bondInfo[_depositor] = Bond({
            payout: bondInfo[_depositor].payout.add(payout.sub(fee)),
            vesting: terms.vestingTerm,
            lastTime: block.timestamp,
            truePricePaid: trueBondPrice()
        });

        // indexed events are emitted
        emit BondCreated(
            _amount,
            payout,
            block.timestamp.add(terms.vestingTerm)
        );
        emit BondPriceChanged(_bondPrice(), debtRatio());

        totalPrincipalBonded = totalPrincipalBonded.add(_amount); // total bonded increased
        totalPayoutGiven = totalPayoutGiven.add(payout); // total payout increased
        payoutSinceLastSubsidy = payoutSinceLastSubsidy.add(payout); // subsidy counter increased

        adjust(); // control variable is adjusted
        return payout;
    }

    /**
     *  @notice redeem bond for user
     *  @return uint
     */
    function redeem(address _depositor) external returns (uint256) {
        Bond memory info = bondInfo[_depositor];
        uint256 percentVested = percentVestedFor(_depositor); // (second since last interaction / vesting term remaining)

        if (percentVested >= 10000) {
            // if fully vested
            delete bondInfo[_depositor]; // delete user info
            emit BondRedeemed(_depositor, info.payout, 0); // emit bond data
            payoutToken.transfer(_depositor, info.payout);
            return info.payout;
        } else {
            // if unfinished
            // calculate payout vested
            uint256 payout = info.payout.mul(percentVested).div(10000);

            // store updated deposit info
            bondInfo[_depositor] = Bond({
                payout: info.payout.sub(payout),
                vesting: info.vesting.sub(block.timestamp.sub(info.lastTime)),
                lastTime: block.timestamp,
                truePricePaid: info.truePricePaid
            });

            emit BondRedeemed(_depositor, payout, bondInfo[_depositor].payout);
            payoutToken.transfer(_depositor, payout);
            return payout;
        }
    }

    /* ======== INTERNAL HELPER FUNCTIONS ======== */

    /**
     *  @notice makes incremental adjustment to control variable
     */
    function adjust() internal {
        uint256 blockCanAdjust = adjustment.lastTime.add(adjustment.buffer);
        if (adjustment.rate != 0 && block.timestamp >= blockCanAdjust) {
            uint256 initial = terms.controlVariable;
            if (adjustment.add) {
                terms.controlVariable = terms.controlVariable.add(
                    adjustment.rate
                );
                if (terms.controlVariable >= adjustment.target) {
                    adjustment.rate = 0;
                }
            } else {
                terms.controlVariable = terms.controlVariable.sub(
                    adjustment.rate
                );
                if (terms.controlVariable <= adjustment.target) {
                    adjustment.rate = 0;
                }
            }
            adjustment.lastTime = block.timestamp;
            emit ControlVariableAdjustment(
                initial,
                terms.controlVariable,
                adjustment.rate,
                adjustment.add
            );
        }
    }

    /**
     *  @notice reduce total debt
     */
    function decayDebt() internal {
        totalDebt = totalDebt.sub(debtDecay());
        lastDecay = block.timestamp;
    }

    /**
     *  @notice calculate current bond price and remove floor if above
     *  @return price_ uint
     */
    function _bondPrice() internal returns (uint256 price_) {
        price_ = terms.controlVariable.mul(debtRatio()).div(
            10**(uint256(payoutToken.decimals()).sub(5))
        );
        if (price_ < terms.minimumPrice) {
            price_ = terms.minimumPrice;
        } else if (terms.minimumPrice != 0) {
            terms.minimumPrice = 0;
        }
    }

    /* ======== VIEW FUNCTIONS ======== */

    /**
     *  @notice calculate current bond premium
     *  @return price_ uint
     */
    function bondPrice() public view returns (uint256 price_) {
        price_ = terms.controlVariable.mul(debtRatio()).div(
            10**(uint256(payoutToken.decimals()).sub(5))
        );
        if (price_ < terms.minimumPrice) {
            price_ = terms.minimumPrice;
        }
    }

    /**
     *  @notice calculate true bond price a user pays
     *  @return price_ uint
     */
    function trueBondPrice() public view returns (uint256 price_) {
        price_ = bondPrice().add(bondPrice().mul(currentSnowbankFee()).div(1e6));
    }

    /**
     *  @notice determine maximum bond size
     *  @return uint
     */
    function maxPayout() public view returns (uint256) {
        return payoutToken.totalSupply().mul(terms.maxPayout).div(100000);
    }

    /**
     *  @notice calculate total interest due for new bond
     *  @param _value uint
     *  @return uint
     */
    function _payoutFor(uint256 _value) internal view returns (uint256) {
        return
            FixedPoint.fraction(_value, bondPrice()).decode112with18().div(
                1e11
            );
    }

    /**
     *  @notice calculate user's interest due for new bond, accounting for Olympus Fee
     *  @param _value uint
     *  @return uint
     */
    function payoutFor(uint256 _value) external view returns (uint256) {
        uint256 total = FixedPoint
            .fraction(_value, bondPrice())
            .decode112with18()
            .div(1e11);
        return total.sub(total.mul(currentSnowbankFee()).div(1e6));
    }

    /**
     *  @notice calculate current ratio of debt to payout token supply
     *  @notice protocols using Olympus Pro should be careful when quickly adding large %s to total supply
     *  @return debtRatio_ uint
     */
    function debtRatio() public view returns (uint256 debtRatio_) {
        debtRatio_ = FixedPoint
            .fraction(
                currentDebt().mul(10**payoutToken.decimals()),
                payoutToken.totalSupply()
            )
            .decode112with18()
            .div(1e18);
    }

    /**
     *  @notice calculate debt factoring in decay
     *  @return uint
     */
    function currentDebt() public view returns (uint256) {
        return totalDebt.sub(debtDecay());
    }

    /**
     *  @notice amount to decay total debt by
     *  @return decay_ uint
     */
    function debtDecay() public view returns (uint256 decay_) {
        uint256 secondSinceLast = block.timestamp.sub(lastDecay);
        decay_ = totalDebt.mul(secondSinceLast).div(terms.vestingTerm);
        if (decay_ > totalDebt) {
            decay_ = totalDebt;
        }
    }

    /**
     *  @notice calculate how far into vesting a depositor is
     *  @param _depositor address
     *  @return percentVested_ uint
     */
    function percentVestedFor(address _depositor)
        public
        view
        returns (uint256 percentVested_)
    {
        Bond memory bond = bondInfo[_depositor];
        uint256 secondSinceLast = block.timestamp.sub(bond.lastTime);
        uint256 vesting = bond.vesting;

        if (vesting > 0) {
            percentVested_ = secondSinceLast.mul(10000).div(vesting);
        } else {
            percentVested_ = 0;
        }
    }

    /**
     *  @notice calculate amount of payout token available for claim by depositor
     *  @param _depositor address
     *  @return pendingPayout_ uint
     */
    function pendingPayoutFor(address _depositor)
        external
        view
        returns (uint256 pendingPayout_)
    {
        uint256 percentVested = percentVestedFor(_depositor);
        uint256 payout = bondInfo[_depositor].payout;

        if (percentVested >= 10000) {
            pendingPayout_ = payout;
        } else {
            pendingPayout_ = payout.mul(percentVested).div(10000);
        }
    }

    /**
     *  @notice current fee Olympus takes of each bond
     *  @return currentFee_ uint
     */
    function currentSnowbankFee() public view returns (uint256 currentFee_) {
        uint256 tierLength = feeTiers.length;
        for (uint256 i; i < tierLength; i++) {
            if (
                totalPrincipalBonded < feeTiers[i].tierCeilings ||
                i == tierLength - 1
            ) {
                return feeTiers[i].fees;
            }
        }
    }
}

// File contracts/SnowbankProMaxCustomTreasury.sol

pragma solidity 0.7.5;

contract CustomTreasury is Ownable {
    /* ======== DEPENDENCIES ======== */

    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    /* ======== STATE VARIABLS ======== */

    address public payoutToken;

    mapping(address => bool) public bondContract;

    /* ======== EVENTS ======== */

    event BondContractToggled(address bondContract, bool approved);
    event Withdraw(address token, address destination, uint256 amount);

    /* ======== CONSTRUCTOR ======== */

    constructor(address _payoutToken, address _initialOwner) {
        require(_payoutToken != address(0));
        payoutToken = _payoutToken;
        require(_initialOwner != address(0));
        policy = _initialOwner;
    }

    /* ======== BOND CONTRACT FUNCTION ======== */

    /**
     *  @notice deposit principle token and recieve back payout token
     *  @param _principleTokenAddress address
     *  @param _amountPrincipleToken uint
     *  @param _amountPayoutToken uint
     */
    function deposit(
        address _principleTokenAddress,
        uint256 _amountPrincipleToken,
        uint256 _amountPayoutToken
    ) external {
        require(bondContract[msg.sender], "msg.sender is not a bond contract");
        IERC20(_principleTokenAddress).safeTransferFrom(
            msg.sender,
            address(this),
            _amountPrincipleToken
        );
        IERC20(payoutToken).safeTransfer(msg.sender, _amountPayoutToken);
    }

    /* ======== VIEW FUNCTION ======== */

    /**
     *   @notice returns payout token valuation of priciple
     *   @param _principleTokenAddress address
     *   @param _amount uint
     *   @return value_ uint
     */
    function valueOfToken(address _principleTokenAddress, uint256 _amount)
        public
        view
        returns (uint256 value_)
    {
        // convert amount to match payout token decimals
        value_ = _amount.mul(10**IERC20(payoutToken).decimals()).div(
            10**IERC20(_principleTokenAddress).decimals()
        );
    }

    /* ======== POLICY FUNCTIONS ======== */

    /**
     *  @notice policy can withdraw ERC20 token to desired address
     *  @param _token uint
     *  @param _destination address
     *  @param _amount uint
     */
    function withdraw(
        address _token,
        address _destination,
        uint256 _amount
    ) external onlyPolicy {
        IERC20(_token).safeTransfer(_destination, _amount);

        emit Withdraw(_token, _destination, _amount);
    }

    /**
        @notice toggle bond contract
        @param _bondContract address
     */
    function toggleBondContract(address _bondContract) external onlyPolicy {
        bondContract[_bondContract] = !bondContract[_bondContract];
        emit BondContractToggled(_bondContract, bondContract[_bondContract]);
    }
}

// File contracts/SnowbankProMaxFactory.sol

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

contract SnowbankProMaxFactory is Ownable {
    /* ======== STATE VARIABLS ======== */

    address public constant snowbankTreasury =
        0xa82422A5FD4F9cB85cD4aAc393cD3296A27dD873;
    address public constant snowbankProMaxFactoryStorage =
        0x6a019FAC4954af6019836d3769920122fBf3b3bE;
    address public constant snowbankProSubsidyRouter =
        0xbbf060A065C918022006699Da8e300B0ca152706;
    address public constant snowbankDAO =
        0x561c56b6ea927c157A9F51fCcCfa50B777c1EA7C;

    /* ======== CONSTRUCTION ======== */

    // constructor() {
    //     // require(_olympusTreasury != address(0));
    //     olympusTreasury = 0xa82422A5FD4F9cB85cD4aAc393cD3296A27dD873;
    //     // require(_olympusProFactoryStorage != address(0));
    //     olympusProFactoryStorage = 0x58ABc3E2a3643a99931cF66672e648D3b5DaDD68;
    //     // require(_olumpusProSubsidyRouter != address(0));
    //     olumpusProSubsidyRouter = 0x9D4Ecd41f9334D4BD5f4aE225d2F5789CE2E30F2;
    //     // require(_olympusDAO != address(0));
    //     olympusDAO = 0x561c56b6ea927c157A9F51fCcCfa50B777c1EA7C;
    // }

    /* ======== POLICY FUNCTIONS ======== */

    /**
        @notice deploys custom treasury and custom bond contracts and returns address of both
        @param _payoutToken address
        @param _principleToken address
        @param _initialOwner address
        @return _treasury address
        @return _bond address
     */
    function createBondAndTreasury(
        address _payoutToken,
        address _principleToken,
        address _initialOwner,
        uint256[] calldata _tierCeilings,
        uint256[] calldata _fees
    ) external onlyPolicy returns (address _treasury, address _bond) {
        CustomTreasury treasury = new CustomTreasury(
            _payoutToken,
            _initialOwner
        );
        CustomBond bond = new CustomBond(
            address(treasury),
            _payoutToken,
            _principleToken,
            snowbankTreasury,
            snowbankProSubsidyRouter,
            _initialOwner,
            snowbankDAO,
            _tierCeilings,
            _fees
        );

        return
            ISnowbankProMaxFactoryStorage(snowbankProMaxFactoryStorage).pushBond(
                _payoutToken,
                _principleToken,
                address(treasury),
                address(bond),
                _initialOwner,
                _tierCeilings,
                _fees
            );
    }

    /**
        @notice deploys custom treasury and custom bond contracts and returns address of both
        @param _payoutToken address
        @param _principleToken address
        @param _customTreasury address
        @param _initialOwner address
        @return _treasury address
        @return _bond address
     */
    function createBond(
        address _payoutToken,
        address _principleToken,
        address _customTreasury,
        address _initialOwner,
        uint256[] calldata _tierCeilings,
        uint256[] calldata _fees
    ) external onlyPolicy returns (address _treasury, address _bond) {
        CustomBond bond = new CustomBond(
            _customTreasury,
            _payoutToken,
            _principleToken,
            _customTreasury,
            snowbankProSubsidyRouter,
            _initialOwner,
            snowbankDAO,
            _tierCeilings,
            _fees
        );

        return
            ISnowbankProMaxFactoryStorage(snowbankProMaxFactoryStorage).pushBond(
                _payoutToken,
                _principleToken,
                _customTreasury,
                address(bond),
                _initialOwner,
                _tierCeilings,
                _fees
            );
    }
}