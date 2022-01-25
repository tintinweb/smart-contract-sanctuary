/**
 *Submitted for verification at FtmScan.com on 2022-01-24
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;
pragma abicoder v2;

contract OwnableData {
    address public owner;
    address public pendingOwner;
}

contract Ownable is OwnableData {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice `owner` defaults to msg.sender on construction.
    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /// @notice Transfers ownership to `newOwner`. Either directly or claimable by the new pending owner.
    /// Can only be invoked by the current `owner`.
    /// @param newOwner Address of the new owner.
    /// @param direct True if `newOwner` should be set immediately. False if `newOwner` needs to use `claimOwnership`.
    /// @param renounce Allows the `newOwner` to be `address(0)` if `direct` and `renounce` is True. Has no effect otherwise.
    function transferOwnership(
        address newOwner,
        bool direct,
        bool renounce
    ) public onlyOwner {
        if (direct) {
            // Checks
            require(newOwner != address(0) || renounce, "Ownable: zero address");

            // Effects
            emit OwnershipTransferred(owner, newOwner);
            owner = newOwner;
            pendingOwner = address(0);
        } else {
            // Effects
            pendingOwner = newOwner;
        }
    }

    /// @notice Needs to be called by `pendingOwner` to claim ownership.
    function claimOwnership() public {
        address _pendingOwner = pendingOwner;

        // Checks
        require(msg.sender == _pendingOwner, "Ownable: caller != pending owner");

        // Effects
        emit OwnershipTransferred(owner, _pendingOwner);
        owner = _pendingOwner;
        pendingOwner = address(0);
    }

    /// @notice Only allows the `owner` to execute the function.
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
}

library LowGasSafeMath {
    /// @notice Returns x + y, reverts if sum overflows uint256
    /// @param x The augend
    /// @param y The addend
    /// @return z The sum of x and y
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x);
    }

    function add32(uint32 x, uint32 y) internal pure returns (uint32 z) {
        require((z = x + y) >= x);
    }

    /// @notice Returns x - y, reverts if underflows
    /// @param x The minuend
    /// @param y The subtrahend
    /// @return z The difference of x and y
    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }

    function sub32(uint32 x, uint32 y) internal pure returns (uint32 z) {
        require((z = x - y) <= x);
    }

    /// @notice Returns x * y, reverts if overflows
    /// @param x The multiplicand
    /// @param y The multiplier
    /// @return z The product of x and y
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(x == 0 || (z = x * y) / x == y);
    }

    /// @notice Returns x + y, reverts if overflows or underflows
    /// @param x The augend
    /// @param y The addend
    /// @return z The sum of x and y
    function add(int256 x, int256 y) internal pure returns (int256 z) {
        require((z = x + y) >= x == (y >= 0));
    }

    /// @notice Returns x - y, reverts if overflows or underflows
    /// @param x The minuend
    /// @param y The subtrahend
    /// @return z The difference of x and y
    function sub(int256 x, int256 y) internal pure returns (int256 z) {
        require((z = x - y) <= x == (y >= 0));
    }

    function div(uint256 x, uint256 y) internal pure returns(uint256 z){
        require(y > 0);
        z=x/y;
    }
}

library Address {

    function isContract(address account) internal view returns (bool) {

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target, 
        bytes memory data, 
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target, 
        bytes memory data, 
        uint256 value, 
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
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
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
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

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
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
    ) private pure returns(bytes memory) {
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

    function addressToString(address _address) internal pure returns(string memory) {
        bytes32 _bytes = bytes32(uint256(_address));
        bytes memory HEX = "0123456789abcdef";
        bytes memory _addr = new bytes(42);

        _addr[0] = '0';
        _addr[1] = 'x';

        for(uint256 i = 0; i < 20; i++) {
            _addr[2+i*2] = HEX[uint8(_bytes[i + 12] >> 4)];
            _addr[3+i*2] = HEX[uint8(_bytes[i + 12] & 0x0f)];
        }

        return string(_addr);

    }
}
interface IERC20 {
    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeERC20 {
    using LowGasSafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {

        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender)
            .sub(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

library FullMath {
    function fullMul(uint256 x, uint256 y) private pure returns (uint256 l, uint256 h) {
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
        require(h < d, 'FullMath::mulDiv: overflow');
        return fullDiv(l, h, d);
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
    uint256 private constant Q224 = 0x100000000000000000000000000000000000000000000000000000000;
    uint256 private constant LOWER_MASK = 0xffffffffffffffffffffffffffff; // decimal of UQ*x112 (lower 112 bits)

    function decode(uq112x112 memory self) internal pure returns (uint112) {
        return uint112(self._x >> RESOLUTION);
    }

    function decode112with18(uq112x112 memory self) internal pure returns (uint) {

        return uint(self._x) / 5192296858534827;
    }

    function fraction(uint256 numerator, uint256 denominator) internal pure returns (uq112x112 memory) {
        require(denominator > 0, 'FixedPoint::fraction: division by zero');
        if (numerator == 0) return FixedPoint.uq112x112(0);

        if (numerator <= uint144(-1)) {
            uint256 result = (numerator << RESOLUTION) / denominator;
            require(result <= uint224(-1), 'FixedPoint::fraction: overflow');
            return uq112x112(uint224(result));
        } else {
            uint256 result = FullMath.mulDiv(numerator, Q112, denominator);
            require(result <= uint224(-1), 'FixedPoint::fraction: overflow');
            return uq112x112(uint224(result));
        }
    }
}

interface IAugmentations {
    function useExtractBoost (address _recipient, uint32 _duration) external returns (uint32);
}

interface IExtractorCalculator {
    function valuation (address _LP, uint _amount) external view returns (uint);
    function markdown (address _LP) external view returns (uint);
}

interface IQuests {
    function extraction (address _recipient, address _principle, uint256 _payout, uint256 _amount, uint32 _duration) external;
}

interface IReactor {
    function fuse (uint _amount, address _recipient) external returns (uint256);
}

interface ITreasury {
    function deposit (uint _amount, address _token, uint _profit) external returns (uint);
    function cyberValueOf (address _token, uint _amount) external view returns (uint);
}

contract Extractor is Ownable {

    using FixedPoint for *;
    using SafeERC20 for IERC20;
    using LowGasSafeMath for uint;
    using LowGasSafeMath for uint32;

    event ExtractCreated (uint deposit, uint indexed payout, uint indexed expires, uint indexed priceInUSD);
    event ExtractRedeemed (address indexed recipient, uint payout, uint remaining);
    event ExtractPriceChanged (uint indexed priceInUSD, uint indexed internalPrice, uint indexed debtRatio);
    event ControlVariableAdjustment (uint initialBCV, uint newBCV, uint adjustment, bool addition);
    event InitTerms (Terms terms);
    event LogSetTerms (PARAMETER param, uint value);
    event LogSetAdjustment (Adjust adjust);
    event LogSetReactor (address indexed reactor);
    event LogRecoverLostToken (address indexed tokenToRecover, uint amount);

    IERC20 public immutable Cyber;
    IERC20 public immutable Nox;
    IExtractorCalculator public immutable extractorCalculator;
    IERC20 public immutable principle;
    IReactor public immutable reactor;
    ITreasury public immutable treasury;

    IAugmentations public augmentations;
    IQuests public quests;
    address public DAO;

    mapping (address => bool) public allowedZappers;
    bool public immutable isLiquidExtract;

    uint public totalDebt;
    uint32 public lastDecay;

    struct Adjust {
        bool add;
        uint rate;
        uint target;
        uint32 buffer;
        uint32 lastTime;
    }
    Adjust public adjustment;

    struct Extraction {
        uint payout;
        uint pricePaid;
        uint32 lastTime;
        uint32 extraction;
    }
    mapping (address => Extraction[]) public extractions;

    enum VESTING { FIXED, LINEAR }

    struct Terms {
        uint controlVariable;
        uint32 extractionDuration;
        uint fee;
        uint maxPayout;
        uint maxDebt;
        uint minimumPrice;
        VESTING vesting;
    }
    Terms public terms;

    constructor (
        address _Cyber,
        address _Nox,
        address _principle,
        address _reactor,
        address _treasury,
        address _extractorCalculator,
        address _DAO
    ) {
        require(_Cyber != address(0));
        Cyber = IERC20(_Cyber);
        require(_Nox != address(0));
        Nox = IERC20(_Nox);
        require(_principle != address(0));
        principle = IERC20(_principle);
        require(_reactor != address(0));
        reactor = IReactor(_reactor);
        require(_treasury != address(0));
        treasury = ITreasury(_treasury);
        require(_DAO != address(0));
        DAO = _DAO;
        // extractorCalculator should be address(0) if not LP extract
        extractorCalculator = IExtractorCalculator(_extractorCalculator);
        isLiquidExtract = (_extractorCalculator != address(0));
    }

    /**
     *  @notice update DAO address
     *  @param _DAO address
     */
    function setDAOAddress (address _DAO) external onlyOwner {
        require(_DAO != address(0));
        DAO = _DAO;
    }

    /**
     *  @notice initializes extract parameters
     *  @param _controlVariable uint
     *  @param _minimumPrice uint
     *  @param _maxPayout uint
     *  @param _fee uint
     *  @param _maxDebt uint
     *  @param _extractionDuration uint32
     *  @param _vesting VESTING
     */
    function initializeExtractTerms (
        uint _controlVariable,
        uint _minimumPrice,
        uint _maxPayout,
        uint _fee,
        uint _maxDebt,
        uint32 _extractionDuration,
        VESTING _vesting
    ) external onlyOwner {
        require(terms.controlVariable == 0, "Extracts must be initialized from 0");
        require(_controlVariable >= 40, "Can lock adjustment");
        require(_maxPayout <= 1000, "Payout cannot be above 1 percent");
        require(_extractionDuration >= 129600, "Extraction must be longer than 36 hours");
        require(_fee <= 10000, "DAO fee cannot exceed payout");
        require(_vesting == VESTING.LINEAR || _vesting == VESTING.FIXED, "Invalid vesting setting");
        terms = Terms ({
            controlVariable: _controlVariable,
            extractionDuration: _extractionDuration,
            fee: _fee,
            maxPayout: _maxPayout,
            maxDebt: _maxDebt,
            minimumPrice: _minimumPrice,
            vesting: _vesting
        });
        lastDecay = uint32(block.timestamp);
        emit InitTerms(terms);
    }

    enum PARAMETER { EXTRACTION_DURATION, PAYOUT, FEE, DEBT, MIN_PRICE }

    /**
     *  @notice set parameters for new extracts
     *  @param _parameter PARAMETER
     *  @param _input uint
     */
    function setExtractTerms (PARAMETER _parameter, uint _input) external onlyOwner {
        if (_parameter == PARAMETER.EXTRACTION_DURATION) {
            require(_input >= 129600, "extraction must be longer than 36 hours");
            terms.extractionDuration = uint32(_input);
        } else if (_parameter == PARAMETER.PAYOUT) {
            require(_input <= 1000, "Payout cannot be above 1 percent");
            terms.maxPayout = _input;
        } else if (_parameter == PARAMETER.FEE) {
            require(_input <= 10000, "DAO fee cannot exceed payout");
            terms.fee = _input;
        } else if (_parameter == PARAMETER.DEBT) {
            terms.maxDebt = _input;
        } else if (_parameter == PARAMETER.MIN_PRICE) {
            terms.minimumPrice = _input;
        }

        emit LogSetTerms(_parameter, _input);
    }

    enum CONTRACTS { AUGMENTATIONS, QUESTS }

    /**
     *  @notice set auxiliary contract
     */
    function setContract (CONTRACTS _contract, address _address) external onlyOwner {
        if (_contract == CONTRACTS.AUGMENTATIONS) {
            augmentations = IAugmentations(_address);
        } else if (_contract == CONTRACTS.QUESTS) {
            quests = IQuests(_address);
        }
    }

    /**
     *  @notice set control variable adjustment
     *  @param _addition bool
     *  @param _increment uint
     *  @param _target uint
     *  @param _buffer uint
     */
    function setAdjustment (bool _addition, uint _increment, uint _target, uint32 _buffer) external onlyOwner {
        require(_target >= 40, "Next adjustment could be locked");
        adjustment = Adjust({
            add: _addition,
            rate: _increment,
            target: _target,
            buffer: _buffer,
            lastTime: uint32(block.timestamp)
        });

        emit LogSetAdjustment(adjustment);
    }

    function allowZapper (address zapper) external onlyOwner {
        require(zapper != address(0), "Invalid address");
        allowedZappers[zapper] = true;
    }

    function removeZapper (address zapper) external onlyOwner {
        allowedZappers[zapper] = false;
    }

    /**
     *  @notice extract
     *  @param _amount uint
     *  @param _maxPrice uint
     *  @param _recipient address
     *  @return noxPayout_ uint256
     */
    function extract (uint _amount, uint _maxPrice, address _recipient) external returns (uint256 noxPayout_) {
        require(_recipient != address(0), "Invalid address");
        require(msg.sender == _recipient || allowedZappers[msg.sender], "Depositor not allowed");
        _decayDebt();

        uint priceInFrax = extractPriceInFrax();
        uint nativePrice = extractPrice();

        require(_maxPrice >= nativePrice, "Slippage limit: more than max price");

        uint value = treasury.cyberValueOf(address(principle), _amount);
        uint payout = payoutFor(value);
        require(totalDebt.add(value) <= terms.maxDebt, "Max capacity reached");
        require(payout >= 10000000, "Deposit too small");
        require(payout <= maxPayout(), "Deposit too large");

        uint fee = payout.mul(terms.fee) / 10000;
        uint profit = value.sub(payout).sub(fee);

        principle.safeTransferFrom(msg.sender, address(this), _amount);
        principle.approve(address(treasury), _amount);
        treasury.deposit(_amount, address(principle), profit);

        if (fee != 0) {
           Cyber.safeTransfer(DAO, fee);
        }

        totalDebt = totalDebt.add(value);

        Cyber.approve(address(reactor), payout);
        noxPayout_ = reactor.fuse(payout, address(this));

        uint32 extractionDuration = terms.extractionDuration;
        if (address(augmentations) != address(0)) {
            extractionDuration = augmentations.useExtractBoost(_recipient, extractionDuration);
        }

        if (address(quests) != address(0)) {
            quests.extraction(_recipient, address(principle), payout, _amount, extractionDuration);
        }

        extractions[_recipient].push(Extraction({
            payout: noxPayout_,
            extraction: extractionDuration,
            lastTime: uint32(block.timestamp),
            pricePaid: priceInFrax
        }));

        emit ExtractCreated(_amount, noxPayout_, block.timestamp.add(terms.extractionDuration), priceInFrax);
        emit ExtractPriceChanged(extractPriceInFrax(), extractPrice(), debtRatio());

        adjust();
    }

    /** 
     *  @notice redeem extract
     *  @param _index uint256
     */
    function redeem (uint256 _index) external {
        Extraction memory info = extractions[msg.sender][_index];
        uint percentExtracted = percentExtractedFor(msg.sender, _index);

        if (percentExtracted >= 10000) {
            extractions[msg.sender][_index] = extractions[msg.sender][extractions[msg.sender].length - 1];
            extractions[msg.sender].pop();
            Nox.transfer(msg.sender, info.payout);
            emit ExtractRedeemed(msg.sender, info.payout, 0);
        } else if (terms.vesting == VESTING.LINEAR) {
            uint payout = info.payout.mul(percentExtracted) / 10000;
            extractions[msg.sender][_index] = Extraction({
                payout: info.payout.sub(payout),
                extraction: info.extraction.sub32(uint32(block.timestamp).sub32(info.lastTime)),
                lastTime: uint32(block.timestamp),
                pricePaid: info.pricePaid
            });

            Nox.transfer(msg.sender, payout);
            emit ExtractRedeemed(msg.sender, payout, extractions[msg.sender][_index].payout);
        }
    }

    /**
     *  @notice makes incremental adjustment to control variable
     */
    function adjust () internal {
        uint timeCanAdjust = adjustment.lastTime.add32(adjustment.buffer);
        if (adjustment.rate != 0 && block.timestamp >= timeCanAdjust) {
            uint initial = terms.controlVariable;
            if (adjustment.add) {
                terms.controlVariable = terms.controlVariable.add(adjustment.rate);
                if (terms.controlVariable >= adjustment.target) {
                    terms.controlVariable = adjustment.target;
                    adjustment.rate = 0;
                }
            } else {
                terms.controlVariable = terms.controlVariable.sub(adjustment.rate);
                if (terms.controlVariable <= adjustment.target) {
                    terms.controlVariable = adjustment.target;
                    adjustment.rate = 0;
                }
            }

            adjustment.lastTime = uint32(block.timestamp);
            emit ControlVariableAdjustment(initial, terms.controlVariable, adjustment.rate, adjustment.add);
        }
    }

    /**
     *  @notice reduce total debt
     */
    function _decayDebt () internal {
        totalDebt = totalDebt.sub(debtDecay());
        lastDecay = uint32(block.timestamp);
    }

    /**
     *  @notice determine maximum extract size
     *  @return uint
     */
    function maxPayout () public view returns (uint) {
        return Cyber.totalSupply().mul(terms.maxPayout).div(100000);
    }

    /**
     *  @notice calculate interest due for new extract
     *  @param _value uint
     *  @return uint
     */
    function payoutFor (uint _value) public view returns (uint) {
        return FixedPoint.fraction(_value, extractPrice()).decode112with18().div(1e16);
    }

    /**
     *  @notice calculate current extract premium
     *  @return price_ uint
     */
    function extractPrice () public view returns (uint price_) {
        price_ = terms.controlVariable.mul(debtRatio()).add(1000000000).div(1e7);
        if (price_ < terms.minimumPrice) {
            price_ = terms.minimumPrice;
        }
    }

    /**
     *  @notice converts extract price to Frax value
     *  @return price_ uint
     */
    function extractPriceInFrax () public view returns (uint price_) {
        if (isLiquidExtract) {
            price_ = extractPrice().mul(extractorCalculator.markdown(address(principle))).div(100);
        } else {
            price_ = extractPrice().mul(10 ** principle.decimals()).div(100);
        }
    }

    /**
     *  @notice the number of extractions in progress for the recipient
     *  @param _recipient address
     *  @return uint256
     */
    function extractionsInProgress (address _recipient) public view returns (uint256) {
        return extractions[_recipient].length;
    }

    /**
     *  @notice calculate current ratio of debt to Cyber supply
     *  @return debtRatio_ uint
     */
    function debtRatio () public view returns (uint debtRatio_) {
        uint supply = Cyber.totalSupply();
        debtRatio_ = FixedPoint.fraction(currentDebt().mul(1e9), supply).decode112with18().div(1e18);
    }

    /**
     *  @notice debt ratio in same terms for reserve or liquid extracts
     *  @return uint
     */
    function standardizedDebtRatio () external view returns (uint) {
        if (isLiquidExtract) {
            return debtRatio().mul(extractorCalculator.markdown(address(principle))).div(1e9);
        } else {
            return debtRatio();
        }
    }

    /**
     *  @notice calculate debt factoring in decay
     *  @return uint
     */
    function currentDebt () public view returns (uint) {
        return totalDebt.sub(debtDecay());
    }

    /**
     *  @notice amount to decay total debt by
     *  @return decay_ uint
     */
    function debtDecay () public view returns (uint decay_) {
        uint32 timeSinceLast = uint32(block.timestamp).sub32(lastDecay);
        decay_ = totalDebt.mul(timeSinceLast) / terms.extractionDuration;
        if (decay_ > totalDebt) {
            decay_ = totalDebt;
        }
    }

    /**
     *  @notice calculate how far into extraction a depositor is
     *  @param _recipient address
     *  @param _index uint256
     *  @return percentExtracted_ uint
     */
    function percentExtractedFor (address _recipient, uint256 _index) public view returns (uint percentExtracted_) {
        Extraction memory extraction = extractions[_recipient][_index];
        uint secondsSinceLast = uint32(block.timestamp).sub32(extraction.lastTime);
        if (extraction.extraction > 0) {
            percentExtracted_ = secondsSinceLast.mul(10000) / extraction.extraction;
        } else {
            percentExtracted_ = 0;
        }
    }

    /**
     *  @notice calculate amount of Cyber available for claim by depositor
     *  @param _recipient address
     *  @param _index uint256
     *  @return pendingPayout_ uint
     */
    function pendingPayoutFor (address _recipient, uint256 _index) external view returns (uint pendingPayout_) {
        uint percentExtracted = percentExtractedFor(_recipient, _index);
        uint payout = extractions[_recipient][_index].payout;

        if (percentExtracted >= 10000) {
            pendingPayout_ = payout;
        } else {
            pendingPayout_ = payout.mul(percentExtracted) / 10000;
        }
    }

    /**
     *  @notice allow anyone to send lost tokens (excluding principle or Cyber) to the DAO
     *  @return bool
     */
    function recoverLostToken (address _token) external returns (bool) {
        require(_token != address(Cyber), "Attempt to recover Cyber");
        require(_token != address(principle), "Attempt to recover principle");
        uint balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(DAO, balance);
        emit LogRecoverLostToken(address(_token), balance);
        return true;
    }
}