// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

pragma experimental ABIEncoderV2;

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor ()  {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() external view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() external onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function sqrrt(uint256 a) internal pure returns (uint c) {
        if (a > 3) {
            c = a;
            uint b = add(div(a, 2), 1);
            while (b < c) {
                c = b;
                b = div(add(div(a, b), b), 2);
            }
        } else if (a != 0) {
            c = 1;
        }
    }
}

library Address {

    function isContract(address account) internal view returns (bool) {

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {size := extcodesize(account)}
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success,) = recipient.call{value : amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value : value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value : weiValue}(data);
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

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns (bytes memory) {
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

    function addressToString(address _address) internal pure returns (string memory) {
        bytes32 _bytes = bytes32(uint256(_address));
        bytes memory HEX = "0123456789abcdef";
        bytes memory _addr = new bytes(42);

        _addr[0] = '0';
        _addr[1] = 'x';

        for (uint256 i = 0; i < 20; i++) {
            _addr[2 + i * 2] = HEX[uint8(_bytes[i + 12] >> 4)];
            _addr[3 + i * 2] = HEX[uint8(_bytes[i + 12] & 0x0f)];
        }

        return string(_addr);

    }
}

interface IBEP20 {
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

library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IBEP20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IBEP20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IBEP20 token, address spender, uint256 value) internal {

        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeBEP20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IBEP20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IBEP20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeBEP20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function _callOptionalReturn(IBEP20 token, bytes memory data) private {

        bytes memory returndata = address(token).functionCall(data, "SafeBEP20: low-level call failed");
        if (returndata.length > 0) {// Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeBEP20: BEP20 operation did not succeed");
        }
    }
}

interface IStaking {
    function stake(uint _amount, address _recipient) external returns (bool);
}

interface ITreasury {
    function deposit(address _token, uint _lpAmount, uint256 _milkyAmount) external returns (uint);
}

interface IPriceData {
    struct ResponsePriceData {
        uint128 rate; // base/quote exchange rate, multiplied by 1e18.
        uint64 lastUpdatedBase;
        uint64 lastUpdatedQuote; // UNIX epoch of the last time when quote price gets updated.
    }

    function getPrice(string memory _base, string memory _quote) external view returns (ResponsePriceData memory);
}

contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;


    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() onlyOwner whenNotPaused external {
        paused = true;
        Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() onlyOwner whenPaused external {
        paused = false;
        Unpause();
    }
}

contract SignData {
    bytes32 public DOMAIN_SEPARATOR;
    string public NAME;
    bytes32 public DEPOSIT_HASH;
    mapping(address => uint256) public nonces;


    constructor() public {
        NAME = "MilkyBondingLP";
        uint chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(NAME)),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );

        DEPOSIT_HASH = keccak256("Data(uint256 _amount,address depositor,uint256 nonce)");
    }

    function verify(bytes32 data, address sender, uint8 v, bytes32 r, bytes32 s) internal view {
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                data
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == sender, "Invalid nonce");
    }
}

contract BondMilkyLp is Pausable, SignData {

    using SafeBEP20 for IBEP20;
    using SafeMath for uint;

    /* ======== EVENTS ======== */

    event BondCreated(uint deposit, uint indexed payout, uint indexed expires);
    event BondRedeemed(address indexed recipient, uint payout, uint remaining);


    /* ======== STATE VARIABLES ======== */

    address public immutable staking;
    address public DAO;
    address public immutable milky; // token given as payment for bond
    address public immutable principle; // token used to create bond
    address public immutable calculator;
    address public immutable treasury;

    Terms public terms; // stores terms for new bonds
    mapping(address => Bond) public bondInfo; // stores bond information for depositors

    /* ======== STRUCTS ======== */

    // Info for creating new bonds
    struct Terms {
        uint controlVariable; // scaling variable for price
        uint vestingTerm; // in blocks
        uint maxPayout; // in thousandths of a %. i.e. 500 = 0.5%
        uint fee; // as % of bond payout, in hundreths. ( 500 = 5% = 0.05 for every 1 paid)
    }

    // Info for bond holder
    struct Bond {
        uint payout; // OHM remaining to be paid
        uint vesting; // Blocks left to vest
        uint lastBlock; // Last interaction
    }

    /* ======== INITIALIZATION ======== */

    constructor (
        address _milky,
        address _principle,
        address _calculator,
        address _treasury,
        address _dao,
        address _staking
    ) {
        require(_milky != address(0));
        milky = _milky;
        require(_principle != address(0));
        principle = _principle;
        require(_calculator != address(0));
        calculator = _calculator;
        require(_treasury != address(0));
        treasury = _treasury;
        DAO = _dao;
        require(_staking != address(0));
        staking = _staking;
    }

    function setDAO(address _DAO) public onlyOwner {
        DAO = _DAO;
    }

    /**
     *  @notice initializes bond parameters
     *  @param _controlVariable uint
     *  @param _vestingTerm uint
     *  @param _maxPayout uint
     *  @param _fee uint
     */
    function initializeBondTerms(
        uint _controlVariable,
        uint _vestingTerm,
        uint _maxPayout,
        uint _fee
    ) external onlyOwner {
        require(terms.controlVariable == 0, "Bonds must be initialized from 0");
        terms = Terms({controlVariable : _controlVariable, vestingTerm : _vestingTerm, maxPayout : _maxPayout, fee : _fee});
    }


    /* ======== POLICY FUNCTIONS ======== */

    enum PARAMETER {VESTING, PAYOUT, FEE, DISCOUNT}
    /**
     *  @notice set parameters for new bonds
     *  @param _parameter PARAMETER
     *  @param _input uint
     */

    function setBondTerms(PARAMETER _parameter, uint _input) external onlyOwner {
        if (_parameter == PARAMETER.VESTING) {// 0
            require(_input >= 10000, "Vesting must be longer than 36 hours");
            terms.vestingTerm = _input;
        } else if (_parameter == PARAMETER.PAYOUT) {// 1
            require(_input <= 1000, "Payout cannot be above 1 percent");
            terms.maxPayout = _input;
        } else if (_parameter == PARAMETER.FEE) {// 2
            require(_input <= 10000, "DAO fee cannot exceed payout");
            terms.fee = _input;
        } else if (_parameter == PARAMETER.DISCOUNT) {// 3
            // input: 1k=> discount = (10k-1k)/10K = 90%
            terms.controlVariable = _input;
        }
    }


    /* ======== USER FUNCTIONS ======== */

    function depositPermit(uint _amount, address _depositor, address sender, uint8 v, bytes32 r, bytes32 s) external whenNotPaused returns (uint){
        verify(keccak256(abi.encode(DEPOSIT_HASH, _amount, _depositor, nonces[sender]++)), sender, v, r, s);
        require(_depositor != address(0), "Invalid address");
        //Calculate lp token to milky
        uint value = uint256(IPriceData(calculator).getPrice("MILKY-BNB", "MILKY").rate).mul(_amount).div(10 ** 18);
        //Apply discount
        uint payout = payoutFor(value);
        // must be > 0.01 milky ( underflow protection )
        require(payout <= maxPayout(), "Bond too large");
        // size protection because there is no slippage

        // profits are calculated
        uint fee = payout.mul(terms.fee).div(10000);

        /**
            principle is transferred in
            approved and
            deposited into
         */
        IBEP20(principle).safeTransferFrom(sender, address(this), _amount);
        IBEP20(principle).approve(address(treasury), _amount);
        ITreasury(treasury).deposit(principle, _amount, payout.add(fee));

        if (fee != 0) {// fee is transferred to dao
            IBEP20(milky).safeTransfer(DAO, fee);
        }

        // depositor info is stored
        bondInfo[_depositor] = Bond({
        payout : bondInfo[_depositor].payout.add(payout),
        vesting : terms.vestingTerm,
        lastBlock : block.number
        });
        // indexed events are emitted
        emit BondCreated(_amount, payout, block.number.add(terms.vestingTerm));
        // control variable is adjusted
        return payout;
    }

    /**
     *  @notice deposit bond
     *  @param _amount uint
     *  @param _depositor address
     *  @return uint
     */
    function deposit(uint _amount, address _depositor) external whenNotPaused returns (uint){
        require(_depositor != address(0), "Invalid address");
        //Calculate lp token to milky 
        uint value = uint256(IPriceData(calculator).getPrice("MILKY-BNB", "MILKY").rate).mul(_amount).div(10 ** 18);
        //Apply discount
        uint payout = payoutFor(value);
        // must be > 0.01 milky ( underflow protection )
        require(payout <= maxPayout(), "Bond too large");
        // size protection because there is no slippage

        // profits are calculated
        uint fee = payout.mul(terms.fee).div(10000);

        /**
            principle is transferred in
            approved and
            deposited into 
         */
        IBEP20(principle).safeTransferFrom(msg.sender, address(this), _amount);
        IBEP20(principle).approve(address(treasury), _amount);
        ITreasury(treasury).deposit(principle, _amount, payout.add(fee));

        if (fee != 0) {// fee is transferred to dao
            IBEP20(milky).safeTransfer(DAO, fee);
        }

        // depositor info is stored
        bondInfo[_depositor] = Bond({
        payout : bondInfo[_depositor].payout.add(payout),
        vesting : terms.vestingTerm,
        lastBlock : block.number
        });
        // indexed events are emitted
        emit BondCreated(_amount, payout, block.number.add(terms.vestingTerm));
        // control variable is adjusted
        return payout;
    }

    /**
     *  @notice redeem bond for user
     *  @param _recipient address
     *  @return uint
     */
    function redeem(address _recipient, bool _stake) external returns (uint) {
        Bond memory info = bondInfo[_recipient];
        uint percentVested = percentVestedFor(_recipient);
        // (blocks since last interaction / vesting term remaining)

        if (percentVested >= 1000000000) {// if fully vested
            delete bondInfo[_recipient];
            // delete user info
            emit BondRedeemed(_recipient, info.payout, 0);
            // emit bond data
            return stakeOrSend(_recipient, _stake, info.payout);
            // send payout


        } else {// if unfinished
            // calculate payout vested
            uint payout = info.payout.mul(percentVested).div(1000000000);

            // store updated deposit info
            bondInfo[_recipient] = Bond({
            payout : info.payout.sub(payout),
            vesting : info.vesting.sub(block.number.sub(info.lastBlock)),
            lastBlock : block.number
            });

            emit BondRedeemed(_recipient, payout, bondInfo[_recipient].payout);
            return stakeOrSend(_recipient, _stake, payout);
            // send payout
        }

    }

    /* ======== INTERNAL HELPER FUNCTIONS ======== */

    /**
     *  @notice allow user to stake payout automatically
     *  @param _stake bool
     *  @param _amount uint
     *  @return uint
     */
    function stakeOrSend(address _recipient, bool _stake, uint _amount) internal returns (uint) {
        if (!_stake) {// if user does not want to stake
            IBEP20(milky).transfer(_recipient, _amount);
            // send payout
        } else {// if user wants to stake
            IBEP20(milky).approve(staking, _amount);
            IStaking(staking).stake(_amount, _recipient);

        }
        return _amount;
    }

    /* ======== VIEW FUNCTIONS ======== */

    /**
     *  @notice determine maximum bond size
     *  @return uint
     */
    function maxPayout() public view returns (uint) {
        return IBEP20(milky).totalSupply().mul(terms.maxPayout).div(100000);
    }

    /**
     *  @notice calculate interest due for new bond
     *  @param _value uint
     *  @return uint
     */
    function payoutFor(uint _value) public view returns (uint) {
        return terms.controlVariable.mul(_value).div(10000);
    }

    /**
     *  @notice calculate how far into vesting a depositor is
     *  @param _depositor address
     *  @return percentVested_ uint
     */
    function percentVestedFor(address _depositor) public view returns (uint percentVested_) {
        Bond memory bond = bondInfo[_depositor];
        uint blocksSinceLast = block.number.sub(bond.lastBlock);
        uint vesting = bond.vesting;

        if (vesting > 0) {
            percentVested_ = blocksSinceLast.mul(1000000000).div(vesting);
        } else {
            percentVested_ = 0;
        }
    }

    /**
     *  @notice calculate amount of OHM available for claim by depositor
     *  @param _depositor address
     *  @return pendingPayout_ uint
     */
    function pendingPayoutFor(address _depositor) external view returns (uint pendingPayout_) {
        uint percentVested = percentVestedFor(_depositor);
        uint payout = bondInfo[_depositor].payout;

        if (percentVested >= 1000000000) {
            pendingPayout_ = payout;
        } else {
            pendingPayout_ = payout.mul(percentVested).div(1000000000);
        }
    }

}