/**
 *Submitted for verification at Etherscan.io on 2021-11-12
*/

pragma solidity ^0.8.9;


// 
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

// 
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

// 
interface IHiV_Hub {
    function getOracle(address warrant) external view returns (address);
    function isRegistered(address warrant) external view returns(bool);
    function getWarrant(uint256 warrantID) external returns(address);
    function isWithdrawAllowed(uint256 warrantID, uint256 dealID) view external returns (bool);

    event Register(address indexed warrant, address indexed metadata, address indexed sender);
    event Unregister(address indexed warrant, address indexed sender);
}

interface IDeposit {
    function depositToDeal(address person, uint256 warrantID, uint256 dealID, uint256 amount) external;
}

// 
interface IWarrant {
    enum DealState {Created, Accepted, Completed, Canceled}
    struct BasicSettings {
        string deliveryType;
        uint256 basePointsList;
        uint256 periodDeliverySideL;
        uint256 periodDeliverySideS;
        bool isStepL;
        bool isStepS;
        bool hasProfitCurveL;
        bool hasProfitCurveS;
    }

    struct Settings {
        address underlyingAsset;
        address oracle;
        address coinUnderlyingAssetAxis;
        address coinOfContract;
        address coinDepositL;
        address coinDepositS;
        address coinPaymentL;
        address coinPaymentS;
        uint256 period;
        uint256 periodDeliverySideL;
        uint256 periodDeliverySideS;
    }

    struct Deal {
        uint256 SCentre;   //Price
        uint256 contractsCount;
        uint256 depositLPercent;
        uint256 depositSPercent;
        uint256 periodOrderExpiration;
        address makerAddress;
        address takerAddress;
        bool isStandart;
        DealState status;
    }

    struct FullInfo {
        uint256 warrantId;
        BasicSettings basic;
        Settings main;
        Deal deal;
    }

    enum SIDE {Maker, Taker}

    function newDeal(uint256 warrantSettingsID, Deal memory sealSettings, uint256 amount) external returns(uint256);

    function takeDeal(address sender, uint256 dealID, uint256 amount) external;

    function topUpDeal(address sender, uint256 dealID, SIDE side, uint256 amount) external;

    function profitCurveL(uint256 x) view external returns (uint256 y);

    function profitCurveS(uint256 x) view external returns (uint256 y);


    event AcceptProposal(address indexed investor, address indexed miner, uint64 proposalId);
    event ProposalSuccess(address indexed investor, address indexed miner, uint64 proposalId);
    event Withdraw(address indexed owner, uint256 value);
}

contract HiV_Hub is IHiV_Hub, Ownable {
    mapping(uint256 => address) _warrants;
    mapping(address => bool) _registeredWarrants;
    mapping(address => address) _oracles;
    mapping(uint256 => mapping(uint256 => IWarrant.FullInfo)) _deals;
    mapping(bytes32 => bool) _withdraws;

    IDeposit _deposit;

    constructor() {

    }

    function getDeposit() view external returns (address) {
        return address(_deposit);
    }

    function setDeposit(address deposit) external onlyOwner {
        _deposit = IDeposit(deposit);
    }

    function register(address warrant, uint256 warrantID) external onlyOwner {
        _warrants[warrantID] = warrant;
        _registeredWarrants[warrant] = true;
    }

    function isRegistered(address warrant) view external returns (bool) {
        return _registeredWarrants[warrant];
    }

    function getWarrant(uint256 warrantID) view external returns (address) {
        address warrant = _warrants[warrantID];
        require(warrant == address(0), "Wrong warrantID");

        return warrant;
    }

    function getRegistered(uint256 warrantID, uint256 dealID) view external returns (IWarrant.FullInfo memory) {
        IWarrant.FullInfo memory info = _deals[warrantID][dealID];
        require(info.warrantId > 0, "Wrong dealId");

        return info;
    }

    function registerOracle(address warrant, address oracle) external onlyOwner {
        require(_registeredWarrants[warrant] && oracle != address(0), "Wrong oracle");
        _oracles[warrant] = oracle;
    }

    function getOracle(address warrant) view external returns (address) {
        return _oracles[warrant];
    }

    function setWithdrawAllowed(uint256 warrantID, uint256 dealID, bool allow) external onlyOwner {
        bytes32 key = keccak256(abi.encode(warrantID, dealID));
        _withdraws[key] = allow;
    }

    function isWithdrawAllowed(uint256 warrantID, uint256 dealID) view external returns (bool) {
        bytes32 key = keccak256(abi.encode(warrantID, dealID));
        return _withdraws[key];
    }
}