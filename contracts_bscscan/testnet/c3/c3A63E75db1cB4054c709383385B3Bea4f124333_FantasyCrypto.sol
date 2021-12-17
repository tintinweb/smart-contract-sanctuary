/**
 *Submitted for verification at BscScan.com on 2021-12-17
*/

// File: @openzeppelin/contracts/utils/Context.sol



pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity ^0.8.0;


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

// File: RoboDoge/test.sol


pragma solidity 0.8.3;

interface IERC20 {
    function transfer(address recipient, uint256 amount)
        external    
        returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}
interface AggregatorV3Interface {
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}
interface RoboDogeCoin {
    function balanceOf(address _address) external view returns (uint256);
}
interface RoboDogeStaking {
    struct Stake {
        uint256 tAmount;
        uint256 rAmount;
        uint256 time;
        uint256 period;
        uint256 rate;
        bool isActive;
    }
    function getAllStakes(address _address)
        external
        view
        returns (Stake[] memory);
}
contract FantasyCrypto is Ownable {
    RoboDogeCoin private token;
    RoboDogeStaking private staking;
    struct pool {
        uint256 entryFee;
        address tokenAddress;
        uint256 startTime;
        uint256 endTime;
        address[] userAddress;
    }
    struct userDetails {
        address[10] aggregatorAddresses;
    }
    struct winner {
        address[] user;
        uint256[] amount;
    }
    uint256 public minimumTokenBalance;
    address public AuthAddress;
    uint256 public poolCounter = 0;
    mapping(uint256 => pool) public pools;
    mapping(uint256 => mapping(address => userDetails)) internal userSelection;
    mapping(address => uint256) public feeAmount;
    mapping(uint256 => winner) internal winnerDetails;
    event poolCreated(
        uint256 poolID,
        uint256 entryFees,
        uint256 startTime,
        uint256 endTime,
        address tokenAddress
    );
    event enteredPool(
        address user,
        uint256 poolID,
        address[10] aggregatorAddress
    );
    event rewardsDistributed(
        uint256 poolID,
        address[] winner,
        uint256[] amount
    );
    constructor(
        address auth,
        uint256 _minimumTokenBalance,
        address _robodogeToken,
        address _roboDogeStaking
    ) {
        AuthAddress = auth;
        minimumTokenBalance = _minimumTokenBalance;
        token = RoboDogeCoin(_robodogeToken);
        staking = RoboDogeStaking(_roboDogeStaking);
    }
    modifier isAuth() {
        require(msg.sender == AuthAddress, "Address is not AuthAddress");
        _;
    }
    function createPool(
        uint256 entryFees,
        address _tokenAddress,
        uint256 _startTime,
        uint256 _endTime
    ) external onlyOwner {
        require(
            _startTime < _endTime,
            "Start time cannot be greater than end time."
        );
        require(
            _startTime > block.timestamp,
            "Start time must be greator than current time"
        );
        require(
            _tokenAddress != address(0),
            "Token Address must not be zero address"
        );
        pools[poolCounter].entryFee = entryFees;
        pools[poolCounter].startTime = _startTime;
        pools[poolCounter].endTime = _endTime;
        pools[poolCounter].tokenAddress = _tokenAddress;
        emit poolCreated(
            poolCounter,
            entryFees,
            _startTime,
            _endTime,
            _tokenAddress
        );
        poolCounter++;
    }
    function enterPool(uint256 _poolID, address[10] memory _aggregatorAddress)
        external
        payable
    {
        uint256 sum = 0;
        // if (token.balanceOf(msg.sender) < minimumTokenBalance) {
        //     for (
        //         uint256 i = 0;
        //         i < staking.getAllStakes(msg.sender).length;
        //         i++
        //     ) {
        //         if (staking.getAllStakes(msg.sender)[i].isActive) {
        //             sum += staking.getAllStakes(msg.sender)[i].tAmount;
        //         }
        //     }
        // }
        require(
            // token.balanceOf(msg.sender) >= minimumTokenBalance ||
            sum >= minimumTokenBalance,
            "You dont have minimum RoboDoge Tokens."
        );
        require(
            userSelection[_poolID][msg.sender].aggregatorAddresses[0] ==
                address(0),
            "User already entered the pool"
        );
        require(
            block.timestamp < pools[_poolID].startTime,
            "Pool has already started."
        );
        require(_poolID < poolCounter, "Pool ID must exist");
        // for (uint256 i = 0; i < 10; i++) {
        //     address _address = _aggregatorAddress[i];
        //     int256 answer;
        //     (, answer, , , ) = AggregatorV3Interface(_address)
        //         .latestRoundData();
        //     require(answer > 0, "Aggregator address does not exists");
        // }
        userSelection[_poolID][msg.sender]
            .aggregatorAddresses = _aggregatorAddress;
        IERC20(pools[_poolID].tokenAddress).transferFrom(
            msg.sender,
            address(this),
            pools[_poolID].entryFee
        );
        pools[_poolID].userAddress.push(msg.sender);
        emit enteredPool(msg.sender, _poolID, _aggregatorAddress);
    }
    function withdrawFees(address tokenAddress) external onlyOwner {
        require(feeAmount[tokenAddress] > 0, "No fees has been collected yet.");
        uint256 fee = feeAmount[tokenAddress];
        delete feeAmount[tokenAddress];
        IERC20(tokenAddress).transfer(msg.sender, fee);
    }
    function setWinner(
        uint256 _poolID,
        address[] memory winners,
        uint256[] memory amount
    ) external isAuth {
        require(
            block.timestamp > pools[_poolID].endTime,
            "The pool has not been ended yet."
        );
        require(
            winnerDetails[_poolID].user.length == 0,
            "Winners are already set for this pool."
        );
        require(
            winners.length < pools[_poolID].userAddress.length,
            "Winners must be less than total users."
        );
        winnerDetails[_poolID].user = winners;
        winnerDetails[_poolID].amount = amount;
    }
    function claimReward(uint256 _poolID, uint256 position) external {
        require(
            msg.sender == winnerDetails[_poolID].user[position],
            "You are not the winner for this position."
        );
        require(
            block.timestamp > pools[_poolID].endTime,
            "The pool has not been ended yet"
        );
        winnerDetails[_poolID].user[position] = address(0);
        IERC20(pools[_poolID].tokenAddress).transfer(
            msg.sender,
            winnerDetails[_poolID].amount[position]
        );
    }
    function setAuth(address _auth) external onlyOwner {
        AuthAddress = _auth;
    }
    function setminimumTokenBalance(uint256 _minimumTokenBalance)
        external
        onlyOwner
    {
        minimumTokenBalance = _minimumTokenBalance;
    }
    function viewActivePools()
        external
        view
        returns (uint256[] memory, uint256)
    {
        uint256[] memory activePools = new uint256[](poolCounter);
        uint256 count = 0;
        for (uint256 i = 0; i < poolCounter; i++) {
            if(block.timestamp < pools[i].endTime){
                activePools[count] = i;
                count++;
            }
        }
        return (activePools, count);
    }
    function getPoolInfo(uint256 _poolID) external view returns (pool memory) {
        return pools[_poolID];
    }
    function getUserSelectionInfo(uint256 _poolID, address _address)
        external
        view
        returns (userDetails memory)
    {
        return userSelection[_poolID][_address];
    }
}