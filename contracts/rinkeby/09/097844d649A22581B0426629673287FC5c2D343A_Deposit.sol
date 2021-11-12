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

contract Deposit is Ownable {
    // warrantID => dealID => callerAddress => amount
    //mapping(address => mapping(uint256 => mapping(address => uint256))) _pool;
    mapping(bytes32 => uint256) _pool;
    uint256 totalFee;
    // callerAddress => amount
    mapping(address => uint256) _balances;

    IHiV_Hub hub;

    constructor(address hive) {
        hub = IHiV_Hub(hive);
    }

    function calcFee(uint256 amount) view internal returns (uint256) {
        return 0;
    }

    function deposit(uint256 warrantID, uint256 warrantSettingsID, IWarrant.Deal memory dealSettings) external payable {
        uint256 amount = msg.value;
        require(amount > 0, "Wrong Amount");
        uint256 fee = calcFee(amount);
        totalFee += fee;
        _balances[msg.sender] += amount - fee;
        address temp = hub.getWarrant(warrantID);
        require(hub.isRegistered(temp), "Wrong warrantID");
        IWarrant warrant = IWarrant(temp);
        dealSettings.makerAddress = msg.sender;
        uint dealID = warrant.newDeal(warrantSettingsID, dealSettings, amount - fee);
        bytes32 key = keccak256(abi.encode(warrantID, dealID, msg.sender));
        _pool[key] = amount - fee;
    }

    function depositToTakeDeal(uint256 warrantID, uint256 dealID) external payable {
        uint256 amount = msg.value;
        require(amount > 0, "Wrong Amount");
        uint256 fee = calcFee(amount);
        totalFee += fee;
        _balances[msg.sender] += amount - fee;
        address temp = hub.getWarrant(warrantID);
        require(hub.isRegistered(temp), "Wrong warrantID");
        IWarrant warrant = IWarrant(temp);
        warrant.takeDeal(msg.sender, dealID, amount - fee);
        bytes32 key = keccak256(abi.encode(warrantID, dealID, msg.sender));
        _pool[key] += amount - fee;
    }

    function withdraw(uint256 warrantID, uint256 dealID) external {
        require(hub.isWithdrawAllowed(warrantID, dealID), "Withdraw not allow");
        bytes32 key = keccak256(abi.encode(warrantID, dealID, msg.sender));
        uint256 amount = _pool[key];
        (bool success, bytes memory data) = msg.sender.call{value : amount}("");
        require(success, "Failed to send Ether");

        _balances[msg.sender] -= amount;
        _pool[key] = 0;
    }

    function topUpDeal(uint256 warrantID, uint256 dealID, IWarrant.SIDE side) external payable {
        uint256 amount = msg.value;
        require(amount > 0, "Wrong Amount");
        uint256 fee = calcFee(amount);
        totalFee += fee;
        _balances[msg.sender] += amount - fee;
        address temp = hub.getWarrant(warrantID);
        require(hub.isRegistered(temp), "Wrong warrantID");
        IWarrant warrant = IWarrant(temp);
        warrant.topUpDeal(msg.sender, dealID, side, amount - fee);
        bytes32 key = keccak256(abi.encode(warrantID, dealID, msg.sender));
        _pool[key] += amount - fee;
    }

    function updateBalance(uint256 warrantID, uint256 dealID, address addr1, uint256 amount1, address addr2, uint256 amount2) external {
        require(hub.isRegistered(msg.sender), "Wrong sender");
        bytes32 key1 = keccak256(abi.encode(warrantID, dealID, addr1));
        bytes32 key2 = keccak256(abi.encode(warrantID, dealID, addr2));
        require(_pool[key1] + _pool[key2] == amount1 + amount2, "Wrong amount sum");
        _pool[key1] = amount1;
        _pool[key2] = amount2;
    }

    function getBalanceByDeal(uint256 warrantID, uint256 dealID) view external returns (uint256) {
        bytes32 key = keccak256(abi.encode(warrantID, dealID, msg.sender));
        return _pool[key];
    }

    function getBalanceByUser() view external returns (uint256) {
        return _balances[msg.sender];
    }

    function getFeeBalance() view external onlyOwner returns (uint256) {
        return totalFee;
    }

    function withdrawFee() external onlyOwner {
        (bool success, bytes memory data) = msg.sender.call{value : totalFee}("");
        require(success, "Failed to send Ether");

        totalFee = 0;
    }
}