/**
 *Submitted for verification at Etherscan.io on 2021-10-21
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

interface IMoneyBag {
    function deposit(uint32 stakingId) external payable;

    function withdraw(uint32 stakingId) external;

    function currentInterest(uint32 stakingId) view external returns (uint256);
}

contract PoolToken is Ownable {
    enum State {Created, Transferred, Withdrawn}

    struct StakingInfo {
        uint256 totalAmount;
        uint256 totalProfit;
        uint256 profitability; // per hour * 1e18
        uint256 startTime;  //timestamp
        uint256 endTime;    //timestamp
        uint64 investorsCount;
        uint32 term;        //hours
        uint32 stakingId;
        State state;
    }

    struct BalanceView {
        uint32 stakingId;
        uint256 value;
    }

    uint32 MAX_UINT32 = 0;

    address moneyBag;
    mapping(uint32 => mapping(address => uint256)) public deposits;
    mapping(address => BalanceView[]) public investors;
    StakingInfo[] public stakes;
    mapping(uint32 => uint32[]) public stakesByTerm;

    constructor(address _moneyBag)  {
    unchecked {MAX_UINT32 = MAX_UINT32 - 1;}
        moneyBag = _moneyBag;
        stakes.push(StakingInfo(0, 0, 1e17, 0, 0, 0, 720, 0, State.Withdrawn));
    }

    function createStake(uint256 profitability, uint32 term) external onlyOwner returns (uint32) {
        stakesByTerm[term].push(uint32(stakes.length));
        stakes.push(StakingInfo(0, 0, profitability, 0, 0, 0, term, uint32(stakes.length), State.Created));
        return uint32(stakes.length) - 1;
    }

    function findIndex(address addr, uint32 stakingId) view internal returns (uint32){
        BalanceView[] memory list = investors[addr];
        for (uint32 i = 0; i < list.length; i++) {
            if (list[i].stakingId == stakingId) {
                return i;
            }
        }

        return MAX_UINT32;
    }

    function depositTo(uint32 stakingId) external payable {
        require(stakingId != 0 && stakingId < stakes.length && stakes[stakingId].state == State.Created, "The stakingId doesn't exist or finished.");

        uint256 totalUserAmount = deposits[stakingId][_msgSender()];
        deposits[stakingId][_msgSender()] = totalUserAmount + msg.value;
        stakes[stakingId].totalAmount += msg.value;
        if (totalUserAmount == 0) {
            stakes[stakingId].investorsCount += 1;
            investors[_msgSender()].push(BalanceView(stakingId, msg.value));
        } else {
            uint32 index = findIndex(_msgSender(), stakingId);
            investors[_msgSender()][index].value += msg.value;
        }
    }

    function deposit(uint32 term) external payable {
        uint32[] memory termStakes = stakesByTerm[term];
        require(termStakes.length > 0, "Doesn't exist stake for that term.");
        uint32 stakingId = termStakes[termStakes.length - 1];
        require(stakingId != 0 && stakingId < stakes.length && stakes[stakingId].state == State.Created, "The stakingId doesn't exist or finished.");

        uint256 totalUserAmount = deposits[stakingId][_msgSender()];
        deposits[stakingId][_msgSender()] = totalUserAmount + msg.value;
        stakes[stakingId].totalAmount += msg.value;
        if (totalUserAmount == 0) {
            stakes[stakingId].investorsCount += 1;
            investors[_msgSender()].push(BalanceView(stakingId, msg.value));
        } else {
            uint32 index = findIndex(_msgSender(), stakingId);
            investors[_msgSender()][index].value += msg.value;
        }
    }

    function withdraw(uint32 stakingId) external {
        require(stakingId < stakes.length && stakes[stakingId].state == State.Withdrawn, "The stakingId doesn't exist or not finished.");
        StakingInfo memory stakeInfo = stakes[stakingId];
        uint256 amount = deposits[stakingId][_msgSender()];
        uint256 profit = stakeInfo.totalProfit * amount / stakeInfo.totalAmount;
        (bool success, bytes memory data) = _msgSender().call{value : amount + profit}("");
        require(success, "Failed to send Ether");
        deposits[stakingId][_msgSender()] = 0;

        uint32 index = findIndex(_msgSender(), stakingId);
        uint256 last = investors[_msgSender()].length - 1;
        investors[_msgSender()][index] = investors[_msgSender()][last];
        delete investors[_msgSender()][last];
    }

    function getMyBalance() view external returns (BalanceView[] memory){
        return investors[_msgSender()];
    }

    function stake(uint32 stakingId) external onlyOwner returns (uint32 newStakingId) {
        require(stakingId < stakes.length && stakes[stakingId].state == State.Created, "The stakingId doesn't exist or finished.");
        require(stakes[stakingId].totalAmount > 0, "The stakingId is empty.");
        stakes[stakingId].startTime = block.timestamp;
        stakes[stakingId].endTime = block.timestamp + stakes[stakingId].term * 60 * 60;
        stakes[stakingId].state = State.Transferred;
        IMoneyBag(moneyBag).deposit{value : stakes[stakingId].totalAmount}(stakingId);
        //(bool success, bytes memory data) = address(moneyBag).call{value : stakes[stakingId].totalAmount}(abi.encodeWithSignature("deposit(uint32)", stakingId));
        //require(success, "Can't send money.");

        return this.createStake(stakes[stakingId].profitability, stakes[stakingId].term);
    }

    function withdrawStakedResources(uint32 stakingId) external onlyOwner {
        require(stakingId < stakes.length && stakes[stakingId].state == State.Transferred, "The stakingId doesn't exist or finished.");
        require(stakes[stakingId].endTime < block.timestamp, "The stakingId is in process.");

        IMoneyBag(moneyBag).withdraw(stakingId);
    }

    fallback() external payable {
        uint32 stakingId;
        stakingId = abi.decode(msg.data, (uint32));
        // (c, d) = abi.decode(msg.data[4:], (uint256, uint256));
        require(stakingId < stakes.length && stakes[stakingId].state == State.Transferred, "The stakingId doesn't exist or finished.");
        require(msg.value > stakes[stakingId].totalAmount, "Not sufficient");

        stakes[stakingId].totalProfit = msg.value - stakes[stakingId].totalAmount;
        stakes[stakingId].state = State.Withdrawn;
    }

    function supply(uint32 stakingId) view external returns (uint256) {
        require(stakingId < stakes.length, "The stakingId doesn't exist.");

        return stakes[stakingId].totalAmount;
    }

    function totalSupply() view external returns (uint256[] memory) {
        uint256[] memory result = new uint256[](stakes.length);
        for (uint32 i = 0; i < stakes.length; i++) {
            result[i] = stakes[i].totalAmount;
        }

        return result;
    }

    function investorsCount(uint32 stakingId) view external returns (uint64) {
        require(stakingId < stakes.length, "The stakingId doesn't exist.");

        return stakes[stakingId].investorsCount;
    }

    function investorsTotalCount() view external returns (uint64[] memory) {
        uint64[] memory result = new uint64[](stakes.length);
        for (uint32 i = 0; i < stakes.length; i++) {
            result[i] = stakes[i].investorsCount;
        }

        return result;
    }

    function currentInterest(uint32 stakingId) view external returns (uint256) {
        require(stakingId < stakes.length, "The stakingId doesn't exist.");

        return IMoneyBag(moneyBag).currentInterest(stakingId);
    }

    function currentReward(uint32 stakingId) view external returns (uint256) {
        uint256 interest = this.currentInterest(stakingId);
        //StakingInfo stake = stakes[stakingId];
        uint256 amount = deposits[stakingId][_msgSender()];
        return amount * interest / 1e18;
    }
}