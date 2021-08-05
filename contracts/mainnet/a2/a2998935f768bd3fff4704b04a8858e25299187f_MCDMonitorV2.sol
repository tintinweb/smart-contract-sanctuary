/**
 *Submitted for verification at Etherscan.io on 2020-08-13
*/

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

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
} 

abstract contract DSProxyInterface {
    function execute(address _target, bytes memory _data) public virtual payable returns (bytes32);
    function owner() public virtual returns (address);
} 

interface ERC20 {
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
} 

library Address {
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

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
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
}


library SafeERC20 {
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
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function _callOptionalReturn(ERC20 token, bytes memory data) private {

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
} 


contract AdminAuth {

    using SafeERC20 for ERC20;

    address public owner;
    address public admin;

    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }

    constructor() public {
        owner = msg.sender;
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
} 

contract MCDMonitorProxyV2 {
    function callExecute(address _owner, address _saverProxy, bytes memory _data) public payable {}
} 

contract ConstantAddressesMainnet {
    address public constant GAS_TOKEN_INTERFACE_ADDRESS = 0x0000000000b3F879cb30FE243b4Dfee438691c04;
    address public constant AUTOMATIC_LOGGER_ADDRESS = 0xAD32Ce09DE65971fFA8356d7eF0B783B82Fd1a9A;

    // new MCD contracts
    address public constant MANAGER_ADDRESS = 0x5ef30b9986345249bc32d8928B7ee64DE9435E39;
    address public constant VAT_ADDRESS = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;
    address public constant SPOTTER_ADDRESS = 0x65C79fcB50Ca1594B025960e539eD7A9a6D434A3;
}


contract ConstantAddresses is ConstantAddressesMainnet {} 


abstract contract GasTokenInterface is ERC20 {
    function free(uint256 value) public virtual returns (bool success);
} 

contract DSMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x);
    }


    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x);
    }


    uint256 constant WAD = 10**18;
    uint256 constant RAY = 10**27;

    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }


    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

} 

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
} 

abstract contract Vat {

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
} 

abstract contract PipInterface {
    function read() public virtual returns (bytes32);
} 

abstract contract Spotter {
    struct Ilk {
        PipInterface pip;
        uint256 mat;
    }

    mapping (bytes32 => Ilk) public ilks;

    uint256 public par;

} 

contract AutomaticLogger {
    event CdpRepay(uint indexed cdpId, address indexed caller, uint amount, uint beforeRatio, uint afterRatio, address logger);
    event CdpBoost(uint indexed cdpId, address indexed caller, uint amount, uint beforeRatio, uint afterRatio, address logger);

    function logRepay(uint cdpId, address caller, uint amount, uint beforeRatio, uint afterRatio) public {
        emit CdpRepay(cdpId, caller, amount, beforeRatio, afterRatio, msg.sender);
    }

    function logBoost(uint cdpId, address caller, uint amount, uint beforeRatio, uint afterRatio) public {
        emit CdpBoost(cdpId, caller, amount, beforeRatio, afterRatio, msg.sender);
    }
}


/// @title Implements logic that allows bots to call Boost and Repay
contract MCDMonitorV2 is AdminAuth, ConstantAddresses, DSMath, StaticV2 {

    uint public REPAY_GAS_TOKEN = 25;
    uint public BOOST_GAS_TOKEN = 25;

    uint public MAX_GAS_PRICE = 200000000000; // 200 gwei

    uint public REPAY_GAS_COST = 2000000;
    uint public BOOST_GAS_COST = 2000000;

    MCDMonitorProxyV2 public monitorProxyContract;
    ISubscriptionsV2 public subscriptionsContract;
    GasTokenInterface gasToken = GasTokenInterface(GAS_TOKEN_INTERFACE_ADDRESS);
    address public automaticSaverProxyAddress;

    Manager public manager = Manager(MANAGER_ADDRESS);
    Vat public vat = Vat(VAT_ADDRESS);
    Spotter public spotter = Spotter(SPOTTER_ADDRESS);
    AutomaticLogger public logger = AutomaticLogger(AUTOMATIC_LOGGER_ADDRESS);

    /// @dev Addresses that are able to call methods for repay and boost
    mapping(address => bool) public approvedCallers;

    modifier onlyApproved() {
        require(approvedCallers[msg.sender]);
        _;
    }

    constructor(address _monitorProxy, address _subscriptions, address _automaticSaverProxyAddress) public {
        approvedCallers[msg.sender] = true;
        approvedCallers[0xAED662abcC4FA3314985E67Ea993CAD064a7F5cF] = true;
        approvedCallers[0xa5d330F6619d6bF892A5B87D80272e1607b3e34D] = true;
        approvedCallers[0x5feB4DeE5150B589a7f567EA7CADa2759794A90A] = true;
        approvedCallers[0x7ca06417c1d6f480d3bB195B80692F95A6B66158] = true;

        monitorProxyContract = MCDMonitorProxyV2(_monitorProxy);
        subscriptionsContract = ISubscriptionsV2(_subscriptions);
        automaticSaverProxyAddress = _automaticSaverProxyAddress;
    }

    /// @notice Bots call this method to repay for user when conditions are met
    /// @dev If the contract ownes gas token it will try and use it for gas price reduction
    /// @param _data Array of uints representing [cdpId, daiAmount, minPrice, exchangeType, gasCost, 0xPrice]
    /// @param _nextPrice Next price in Maker protocol
    /// @param _joinAddr Address of collateral join for specific CDP
    /// @param _exchangeAddress Address to call 0x exchange
    /// @param _callData Bytes representing call data for 0x exchange
    function repayFor(
        uint[6] memory _data, // cdpId, daiAmount, minPrice, exchangeType, gasCost, 0xPrice
        uint256 _nextPrice,
        address _joinAddr,
        address _exchangeAddress,
        bytes memory _callData
    ) public payable onlyApproved {
        if (gasToken.balanceOf(address(this)) >= REPAY_GAS_TOKEN) {
            gasToken.free(REPAY_GAS_TOKEN);
        }

        uint ratioBefore;
        bool isAllowed;
        (isAllowed, ratioBefore) = canCall(Method.Repay, _data[0], _nextPrice);
        require(isAllowed);

        uint gasCost = calcGasCost(REPAY_GAS_COST);
        _data[4] = gasCost;

        monitorProxyContract.callExecute{value: msg.value}(subscriptionsContract.getOwner(_data[0]), automaticSaverProxyAddress, abi.encodeWithSignature("automaticRepay(uint256[6],address,address,bytes)", _data, _joinAddr, _exchangeAddress, _callData));

        uint ratioAfter;
        bool isGoodRatio;
        (isGoodRatio, ratioAfter) = ratioGoodAfter(Method.Repay, _data[0], _nextPrice);
        // doesn't allow user to repay too much
        require(isGoodRatio);

        returnEth();

        logger.logRepay(_data[0], msg.sender, _data[1], ratioBefore, ratioAfter);
    }

    /// @notice Bots call this method to boost for user when conditions are met
    /// @dev If the contract ownes gas token it will try and use it for gas price reduction
    /// @param _data Array of uints representing [cdpId, collateralAmount, minPrice, exchangeType, gasCost, 0xPrice]
    /// @param _nextPrice Next price in Maker protocol
    /// @param _joinAddr Address of collateral join for specific CDP
    /// @param _exchangeAddress Address to call 0x exchange
    /// @param _callData Bytes representing call data for 0x exchange
    function boostFor(
        uint[6] memory _data, // cdpId, daiAmount, minPrice, exchangeType, gasCost, 0xPrice
        uint256 _nextPrice,
        address _joinAddr,
        address _exchangeAddress,
        bytes memory _callData
    ) public payable onlyApproved {
        if (gasToken.balanceOf(address(this)) >= BOOST_GAS_TOKEN) {
            gasToken.free(BOOST_GAS_TOKEN);
        }

        uint ratioBefore;
        bool isAllowed;
        (isAllowed, ratioBefore) = canCall(Method.Boost, _data[0], _nextPrice);
        require(isAllowed);

        uint gasCost = calcGasCost(BOOST_GAS_COST);
        _data[4] = gasCost;

        monitorProxyContract.callExecute{value: msg.value}(subscriptionsContract.getOwner(_data[0]), automaticSaverProxyAddress, abi.encodeWithSignature("automaticBoost(uint256[6],address,address,bytes)", _data, _joinAddr, _exchangeAddress, _callData));

        uint ratioAfter;
        bool isGoodRatio;
        (isGoodRatio, ratioAfter) = ratioGoodAfter(Method.Boost, _data[0], _nextPrice);
        // doesn't allow user to boost too much
        require(isGoodRatio);

        returnEth();

        logger.logBoost(_data[0], msg.sender, _data[1], ratioBefore, ratioAfter);
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

    /// @notice Adds a new bot address which will be able to call repay/boost
    /// @param _caller Bot address
    function addCaller(address _caller) public onlyOwner {
        approvedCallers[_caller] = true;
    }

    /// @notice Removes a bot address so it can't call repay/boost
    /// @param _caller Bot address
    function removeCaller(address _caller) public onlyOwner {
        approvedCallers[_caller] = false;
    }

}