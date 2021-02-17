/**
 *Submitted for verification at Etherscan.io on 2021-02-17
*/

pragma solidity ^0.6.0;

pragma experimental ABIEncoderV2;

 abstract contract Manager {
    function last(address) virtual public returns (uint);
    function cdpCan(address, uint, address) virtual public view returns (uint);
    function ilks(uint) virtual public view returns (bytes32);
    function owns(uint) virtual public view returns (address);
    function urns(uint) virtual public view returns (address);
    function vat() virtual public view returns (address);
    function open(bytes32, address) virtual public returns (uint);
    function give(uint, address) virtual public;
    function cdpAllow(uint, address, uint) virtual public;
    function urnAllow(address, uint) virtual public;
    function frob(uint, int, int) virtual public;
    function flux(uint, address, uint) virtual public;
    function move(uint, address, uint) virtual public;
    function exit(address, uint, address, uint) virtual public;
    function quit(uint, address) virtual public;
    function enter(address, uint) virtual public;
    function shift(uint, uint) virtual public;
} abstract contract Vat {

    struct Urn {
        uint256 ink;   // Locked Collateral  [wad]
        uint256 art;   // Normalised Debt    [wad]
    }

    struct Ilk {
        uint256 Art;   // Total Normalised Debt     [wad]
        uint256 rate;  // Accumulated Rates         [ray]
        uint256 spot;  // Price with Safety Margin  [ray]
        uint256 line;  // Debt Ceiling              [rad]
        uint256 dust;  // Urn Debt Floor            [rad]
    }

    mapping (bytes32 => mapping (address => Urn )) public urns;
    mapping (bytes32 => Ilk)                       public ilks;
    mapping (bytes32 => mapping (address => uint)) public gem;  // [wad]

    function can(address, address) virtual public view returns (uint);
    function dai(address) virtual public view returns (uint);
    function frob(bytes32, address, address, address, int, int) virtual public;
    function hope(address) virtual public;
    function move(address, address, uint) virtual public;
    function fork(bytes32, address, address, int, int) virtual public;
} abstract contract PipInterface {
    function read() public virtual returns (bytes32);
} abstract contract Spotter {
    struct Ilk {
        PipInterface pip;
        uint256 mat;
    }

    mapping (bytes32 => Ilk) public ilks;

    uint256 public par;

} contract DSMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x);
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function div(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x / y;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x <= y ? x : y;
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x >= y ? x : y;
    }

    function imin(int256 x, int256 y) internal pure returns (int256 z) {
        return x <= y ? x : y;
    }

    function imax(int256 x, int256 y) internal pure returns (int256 z) {
        return x >= y ? x : y;
    }

    uint256 constant WAD = 10**18;
    uint256 constant RAY = 10**27;

    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }

    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, WAD), y / 2) / y;
    }

    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    // This famous algorithm is called "exponentiation by squaring"
    // and calculates x^n with x as fixed-point and n as regular unsigned.
    //
    // It's O(log n), instead of O(n) for naive repeated multiplication.
    //
    // These facts are why it works:
    //
    //  If n is even, then x^n = (x^2)^(n/2).
    //  If n is odd,  then x^n = x * x^(n-1),
    //   and applying the equation for even x gives
    //    x^n = x * (x^2)^((n-1) / 2).
    //
    //  Also, EVM division is flooring and
    //    floor[(n-1) / 2] = floor[n / 2].
    //
    function rpow(uint256 x, uint256 n) internal pure returns (uint256 z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
} interface ERC20 {
    function totalSupply() external view returns (uint256 supply);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function transfer(address _to, uint256 _value) external returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value)
        external
        returns (bool success);

    function approve(address _spender, uint256 _value) external returns (bool success);

    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    function decimals() external view returns (uint256 digits);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
} library Address {
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
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
} library SafeMath {
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

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
} library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(ERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     */
    function safeApprove(ERC20 token, address spender, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(ERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(ERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function _callOptionalReturn(ERC20 token, bytes memory data) private {

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
} contract AdminAuth {

    using SafeERC20 for ERC20;

    address public owner;
    address public admin;

    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }

    modifier onlyAdmin() {
        require(admin == msg.sender);
        _;
    }

    constructor() public {
        owner = msg.sender;
        admin = 0x25eFA336886C74eA8E282ac466BdCd0199f85BB9;
    }

    /// @notice Admin is set by owner first time, after that admin is super role and has permission to change owner
    /// @param _admin Address of multisig that becomes admin
    function setAdminByOwner(address _admin) public {
        require(msg.sender == owner);
        require(admin == address(0));

        admin = _admin;
    }

    /// @notice Admin is able to set new admin
    /// @param _admin Address of multisig that becomes new admin
    function setAdminByAdmin(address _admin) public {
        require(msg.sender == admin);

        admin = _admin;
    }

    /// @notice Admin is able to change owner
    /// @param _owner Address of new owner
    function setOwnerByAdmin(address _owner) public {
        require(msg.sender == admin);

        owner = _owner;
    }

    /// @notice Destroy the contract
    function kill() public onlyOwner {
        selfdestruct(payable(owner));
    }

    /// @notice  withdraw stuck funds
    function withdrawStuckFunds(address _token, uint _amount) public onlyOwner {
        if (_token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            payable(owner).transfer(_amount);
        } else {
            ERC20(_token).safeTransfer(owner, _amount);
        }
    }
} contract DefisaverLogger {
    event LogEvent(
        address indexed contractAddress,
        address indexed caller,
        string indexed logName,
        bytes data
    );

    // solhint-disable-next-line func-name-mixedcase
    function Log(address _contract, address _caller, string memory _logName, bytes memory _data)
        public
    {
        emit LogEvent(_contract, _caller, _logName, _data);
    }
} abstract contract GasTokenInterface is ERC20 {
    function free(uint256 value) public virtual returns (bool success);

    function freeUpTo(uint256 value) public virtual returns (uint256 freed);

    function freeFrom(address from, uint256 value) public virtual returns (bool success);

    function freeFromUpTo(address from, uint256 value) public virtual returns (uint256 freed);
} contract GasBurner {
    // solhint-disable-next-line const-name-snakecase
    GasTokenInterface public constant gasToken = GasTokenInterface(0x0000000000b3F879cb30FE243b4Dfee438691c04);

    modifier burnGas(uint _amount) {
        if (gasToken.balanceOf(address(this)) >= _amount) {
            gasToken.free(_amount);
        }

        _;
    }
} contract BotRegistry is AdminAuth {

    mapping (address => bool) public botList;

    constructor() public {
        botList[0x776B4a13093e30B05781F97F6A4565B6aa8BE330] = true;

        botList[0xAED662abcC4FA3314985E67Ea993CAD064a7F5cF] = true;
        botList[0xa5d330F6619d6bF892A5B87D80272e1607b3e34D] = true;
        botList[0x5feB4DeE5150B589a7f567EA7CADa2759794A90A] = true;
        botList[0x7ca06417c1d6f480d3bB195B80692F95A6B66158] = true;
    }

    function setBot(address _botAddr, bool _state) public onlyOwner {
        botList[_botAddr] = _state;
    }

}  

contract DFSExchangeData {

    // first is empty to keep the legacy order in place
    enum ExchangeType { _, OASIS, KYBER, UNISWAP, ZEROX }

    enum ActionType { SELL, BUY }

    struct OffchainData {
        address wrapper;
        address exchangeAddr;
        address allowanceTarget;
        uint256 price;
        uint256 protocolFee;
        bytes callData;
    }

    struct ExchangeData {
        address srcAddr;
        address destAddr;
        uint256 srcAmount;
        uint256 destAmount;
        uint256 minPrice;
        uint256 dfsFeeDivider; // service fee divider
        address user; // user to check special fee
        address wrapper;
        bytes wrapperData;
        OffchainData offchainData;
    }

    function packExchangeData(ExchangeData memory _exData) public pure returns(bytes memory) {
        return abi.encode(_exData);
    }

    function unpackExchangeData(bytes memory _data) public pure returns(ExchangeData memory _exData) {
        _exData = abi.decode(_data, (ExchangeData));
    }
} /// @title Implements enum Method
abstract contract StaticV2 {

    enum Method { Boost, Repay }

    struct CdpHolder {
        uint128 minRatio;
        uint128 maxRatio;
        uint128 optimalRatioBoost;
        uint128 optimalRatioRepay;
        address owner;
        uint cdpId;
        bool boostEnabled;
        bool nextPriceEnabled;
    }

    struct SubPosition {
        uint arrPos;
        bool subscribed;
    }
}  



abstract contract ISubscriptionsV2 is StaticV2 {

    function getOwner(uint _cdpId) external view virtual returns(address);
    function getSubscribedInfo(uint _cdpId) public view virtual returns(bool, uint128, uint128, uint128, uint128, address, uint coll, uint debt);
    function getCdpHolder(uint _cdpId) public view virtual returns (bool subscribed, CdpHolder memory);
} abstract contract DSProxyInterface {

    /// Truffle wont compile if this isn't commented
    // function execute(bytes memory _code, bytes memory _data)
    //     public virtual
    //     payable
    //     returns (address, bytes32);

    function execute(address _target, bytes memory _data) public virtual payable returns (bytes32);

    function setCache(address _cacheAddr) public virtual payable returns (bool);

    function owner() public virtual returns (address);
} /// @title Implements logic for calling MCDSaverProxy always from same contract
contract MCDMonitorProxyV2 is AdminAuth {

    uint public CHANGE_PERIOD;
    uint public MIN_CHANGE_PERIOD = 6 * 1 hours;
    address public monitor;
    address public newMonitor;
    address public lastMonitor;
    uint public changeRequestedTimestamp;

    event MonitorChangeInitiated(address oldMonitor, address newMonitor);
    event MonitorChangeCanceled();
    event MonitorChangeFinished(address monitor);
    event MonitorChangeReverted(address monitor);

    modifier onlyMonitor() {
        require (msg.sender == monitor);
        _;
    }

    constructor(uint _changePeriod) public {
        CHANGE_PERIOD = _changePeriod * 1 hours;
    }

    /// @notice Only monitor contract is able to call execute on users proxy
    /// @param _owner Address of cdp owner (users DSProxy address)
    /// @param _saverProxy Address of MCDSaverProxy
    /// @param _data Data to send to MCDSaverProxy
    function callExecute(address _owner, address _saverProxy, bytes memory _data) public payable onlyMonitor {
        // execute reverts if calling specific method fails
        DSProxyInterface(_owner).execute{value: msg.value}(_saverProxy, _data);

        // return if anything left
        if (address(this).balance > 0) {
            msg.sender.transfer(address(this).balance);
        }
    }

    /// @notice Allowed users are able to set Monitor contract without any waiting period first time
    /// @param _monitor Address of Monitor contract
    function setMonitor(address _monitor) public onlyOwner {
        require(monitor == address(0));
        monitor = _monitor;
    }

    /// @notice Allowed users are able to start procedure for changing monitor
    /// @dev after CHANGE_PERIOD needs to call confirmNewMonitor to actually make a change
    /// @param _newMonitor address of new monitor
    function changeMonitor(address _newMonitor) public onlyOwner {
        require(changeRequestedTimestamp == 0);

        changeRequestedTimestamp = now;
        lastMonitor = monitor;
        newMonitor = _newMonitor;

        emit MonitorChangeInitiated(lastMonitor, newMonitor);
    }

    /// @notice At any point allowed users are able to cancel monitor change
    function cancelMonitorChange() public onlyOwner {
        require(changeRequestedTimestamp > 0);

        changeRequestedTimestamp = 0;
        newMonitor = address(0);

        emit MonitorChangeCanceled();
    }

    /// @notice Anyone is able to confirm new monitor after CHANGE_PERIOD if process is started
    function confirmNewMonitor() public onlyOwner {
        require((changeRequestedTimestamp + CHANGE_PERIOD) < now);
        require(changeRequestedTimestamp != 0);
        require(newMonitor != address(0));

        monitor = newMonitor;
        newMonitor = address(0);
        changeRequestedTimestamp = 0;

        emit MonitorChangeFinished(monitor);
    }

    /// @notice Its possible to revert monitor to last used monitor
    function revertMonitor() public onlyOwner {
        require(lastMonitor != address(0));

        monitor = lastMonitor;

        emit MonitorChangeReverted(monitor);
    }

    function setChangePeriod(uint _periodInHours) public onlyOwner {
        require(_periodInHours * 1 hours > MIN_CHANGE_PERIOD);

        CHANGE_PERIOD = _periodInHours * 1 hours;
    }

}  

















/// @title Implements logic that allows bots to call Boost and Repay
contract MCDMonitorV2 is DSMath, AdminAuth, GasBurner, StaticV2 {

    uint public REPAY_GAS_TOKEN = 25;
    uint public BOOST_GAS_TOKEN = 25;

    uint public MAX_GAS_PRICE = 500000000000; // 500 gwei

    uint public REPAY_GAS_COST = 1000000;
    uint public BOOST_GAS_COST = 1000000;

    bytes4 public REPAY_SELECTOR = 0xf360ce20;
    bytes4 public BOOST_SELECTOR = 0x8ec2ae25;

    MCDMonitorProxyV2 public monitorProxyContract;
    ISubscriptionsV2 public subscriptionsContract;
    address public mcdSaverTakerAddress;

    address public constant BOT_REGISTRY_ADDRESS = 0x637726f8b08a7ABE3aE3aCaB01A80E2d8ddeF77B;

    address public constant PROXY_PERMISSION_ADDR = 0x5a4f877CA808Cca3cB7c2A194F80Ab8588FAE26B;

    Manager public manager = Manager(0x5ef30b9986345249bc32d8928B7ee64DE9435E39);
    Vat public vat = Vat(0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B);
    Spotter public spotter = Spotter(0x65C79fcB50Ca1594B025960e539eD7A9a6D434A3);

    DefisaverLogger public constant logger = DefisaverLogger(0x5c55B921f590a89C1Ebe84dF170E655a82b62126);

    modifier onlyApproved() {
        require(BotRegistry(BOT_REGISTRY_ADDRESS).botList(msg.sender), "Not auth bot");
        _;
    }

    constructor(address _monitorProxy, address _subscriptions, address _mcdSaverTakerAddress) public {
        monitorProxyContract = MCDMonitorProxyV2(_monitorProxy);
        subscriptionsContract = ISubscriptionsV2(_subscriptions);
        mcdSaverTakerAddress = _mcdSaverTakerAddress;
    }

    /// @notice Bots call this method to repay for user when conditions are met
    /// @dev If the contract ownes gas token it will try and use it for gas price reduction
    function repayFor(
        DFSExchangeData.ExchangeData memory _exchangeData,
        uint _cdpId,
        uint _nextPrice,
        address _joinAddr
    ) public payable onlyApproved burnGas(REPAY_GAS_TOKEN) {

        (bool isAllowed, uint ratioBefore) = canCall(Method.Repay, _cdpId, _nextPrice);
        require(isAllowed);

        uint gasCost = calcGasCost(REPAY_GAS_COST);

        address owner = subscriptionsContract.getOwner(_cdpId);

        monitorProxyContract.callExecute{value: msg.value}(
            owner,
            mcdSaverTakerAddress,
            abi.encodeWithSelector(REPAY_SELECTOR, _exchangeData, _cdpId, gasCost, _joinAddr, 0));


        (bool isGoodRatio, uint ratioAfter) = ratioGoodAfter(Method.Repay, _cdpId, _nextPrice);
        require(isGoodRatio);

        returnEth();

        logger.Log(address(this), owner, "AutomaticMCDRepay", abi.encode(ratioBefore, ratioAfter));
    }

    /// @notice Bots call this method to boost for user when conditions are met
    /// @dev If the contract ownes gas token it will try and use it for gas price reduction
    function boostFor(
        DFSExchangeData.ExchangeData memory _exchangeData,
        uint _cdpId,
        uint _nextPrice,
        address _joinAddr
    ) public payable onlyApproved burnGas(BOOST_GAS_TOKEN)  {

        (bool isAllowed, uint ratioBefore) = canCall(Method.Boost, _cdpId, _nextPrice);
        require(isAllowed);

        uint gasCost = calcGasCost(BOOST_GAS_COST);

        address owner = subscriptionsContract.getOwner(_cdpId);

        monitorProxyContract.callExecute{value: msg.value}(
            owner,
            mcdSaverTakerAddress,
            abi.encodeWithSelector(BOOST_SELECTOR, _exchangeData, _cdpId, gasCost, _joinAddr, 0));

        (bool isGoodRatio, uint ratioAfter) = ratioGoodAfter(Method.Boost, _cdpId, _nextPrice);
        require(isGoodRatio);

        returnEth();

        logger.Log(address(this), owner, "AutomaticMCDBoost", abi.encode(ratioBefore, ratioAfter));
    }

/******************* INTERNAL METHODS ********************************/
    function returnEth() internal {
        // return if some eth left
        if (address(this).balance > 0) {
            msg.sender.transfer(address(this).balance);
        }
    }

/******************* STATIC METHODS ********************************/

    /// @notice Returns an address that owns the CDP
    /// @param _cdpId Id of the CDP
    function getOwner(uint _cdpId) public view returns(address) {
        return manager.owns(_cdpId);
    }

    /// @notice Gets CDP info (collateral, debt)
    /// @param _cdpId Id of the CDP
    /// @param _ilk Ilk of the CDP
    function getCdpInfo(uint _cdpId, bytes32 _ilk) public view returns (uint, uint) {
        address urn = manager.urns(_cdpId);

        (uint collateral, uint debt) = vat.urns(_ilk, urn);
        (,uint rate,,,) = vat.ilks(_ilk);

        return (collateral, rmul(debt, rate));
    }

    /// @notice Gets a price of the asset
    /// @param _ilk Ilk of the CDP
    function getPrice(bytes32 _ilk) public view returns (uint) {
        (, uint mat) = spotter.ilks(_ilk);
        (,,uint spot,,) = vat.ilks(_ilk);

        return rmul(rmul(spot, spotter.par()), mat);
    }

    /// @notice Gets CDP ratio
    /// @param _cdpId Id of the CDP
    /// @param _nextPrice Next price for user
    function getRatio(uint _cdpId, uint _nextPrice) public view returns (uint) {
        bytes32 ilk = manager.ilks(_cdpId);
        uint price = (_nextPrice == 0) ? getPrice(ilk) : _nextPrice;

        (uint collateral, uint debt) = getCdpInfo(_cdpId, ilk);

        if (debt == 0) return 0;

        return rdiv(wmul(collateral, price), debt) / (10 ** 18);
    }

    /// @notice Checks if Boost/Repay could be triggered for the CDP
    /// @dev Called by MCDMonitor to enforce the min/max check
    function canCall(Method _method, uint _cdpId, uint _nextPrice) public view returns(bool, uint) {
        bool subscribed;
        CdpHolder memory holder;
        (subscribed, holder) = subscriptionsContract.getCdpHolder(_cdpId);

        // check if cdp is subscribed
        if (!subscribed) return (false, 0);

        // check if using next price is allowed
        if (_nextPrice > 0 && !holder.nextPriceEnabled) return (false, 0);

        // check if boost and boost allowed
        if (_method == Method.Boost && !holder.boostEnabled) return (false, 0);

        // check if owner is still owner
        if (getOwner(_cdpId) != holder.owner) return (false, 0);

        uint currRatio = getRatio(_cdpId, _nextPrice);

        if (_method == Method.Repay) {
            return (currRatio < holder.minRatio, currRatio);
        } else if (_method == Method.Boost) {
            return (currRatio > holder.maxRatio, currRatio);
        }
    }

    /// @dev After the Boost/Repay check if the ratio doesn't trigger another call
    function ratioGoodAfter(Method _method, uint _cdpId, uint _nextPrice) public view returns(bool, uint) {
        CdpHolder memory holder;

        (, holder) = subscriptionsContract.getCdpHolder(_cdpId);

        uint currRatio = getRatio(_cdpId, _nextPrice);

        if (_method == Method.Repay) {
            return (currRatio < holder.maxRatio, currRatio);
        } else if (_method == Method.Boost) {
            return (currRatio > holder.minRatio, currRatio);
        }
    }

    /// @notice Calculates gas cost (in Eth) of tx
    /// @dev Gas price is limited to MAX_GAS_PRICE to prevent attack of draining user CDP
    /// @param _gasAmount Amount of gas used for the tx
    function calcGasCost(uint _gasAmount) public view returns (uint) {
        uint gasPrice = tx.gasprice <= MAX_GAS_PRICE ? tx.gasprice : MAX_GAS_PRICE;

        return mul(gasPrice, _gasAmount);
    }

/******************* OWNER ONLY OPERATIONS ********************************/

    /// @notice Allows owner to change gas cost for boost operation, but only up to 3 millions
    /// @param _gasCost New gas cost for boost method
    function changeBoostGasCost(uint _gasCost) public onlyOwner {
        require(_gasCost < 3000000);

        BOOST_GAS_COST = _gasCost;
    }

    /// @notice Allows owner to change gas cost for repay operation, but only up to 3 millions
    /// @param _gasCost New gas cost for repay method
    function changeRepayGasCost(uint _gasCost) public onlyOwner {
        require(_gasCost < 3000000);

        REPAY_GAS_COST = _gasCost;
    }

    /// @notice Allows owner to change max gas price
    /// @param _maxGasPrice New max gas price
    function changeMaxGasPrice(uint _maxGasPrice) public onlyOwner {
        require(_maxGasPrice < 500000000000);

        MAX_GAS_PRICE = _maxGasPrice;
    }

    /// @notice Allows owner to change the amount of gas token burned per function call
    /// @param _gasAmount Amount of gas token
    /// @param _isRepay Flag to know for which function we are setting the gas token amount
    function changeGasTokenAmount(uint _gasAmount, bool _isRepay) public onlyOwner {
        if (_isRepay) {
            REPAY_GAS_TOKEN = _gasAmount;
        } else {
            BOOST_GAS_TOKEN = _gasAmount;
        }
    }
}