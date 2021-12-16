/**
 *Submitted for verification at Etherscan.io on 2021-12-16
*/

// File: @openzeppelin/contracts/utils/Context.sol

// SPDX-License-Identifier: MIT

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

// (SPDX)-License-Identifier: MIT

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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol

// (SPDX)-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: contracts/IERC1155Mintable.sol

pragma solidity ^0.8.0;

interface IERC1155Mintable {
    function create(
        address to,
        uint256 amount,
        bytes memory _data
    ) external returns (uint256);
}

// File: contracts/IERC20.sol

pragma solidity ^0.8.0;


interface IERC20 {

    function balanceOf(address account) external view returns (uint256);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    function mint(address to, uint256 amount) external;
    function burnFrom(address from, uint256 amount) external;
}

// File: contracts/Genesis.sol

// (SPDX)-License-Identifier: MIT






pragma solidity ^0.8.0;

contract Genesis is Ownable, ReentrancyGuard {
    // Mapping from address to stakerInfoMap
    // @dev see StakerInfo struct
    mapping(address => StakerInfo) private _stakerInfoMap;

    struct StakerInfo {
        uint256 amount; // staked tokens
        bool claimedNFT; // boolean if user has claimed NFT
    }

    // events
    event Stake(address indexed staker, uint256 amount);
    event Lock(address indexed user);
    event Unlock(address indexed user);
    event Claim(address indexed user);
    event RemoveStake(address indexed staker, uint256 amount);
    event GenesisUnlocked(address indexed user);

    // contract interfaces
    IERC20 rio; // RIO token
    IERC20 xRio; // xRIO token
    IERC1155Mintable realioNFTContract; // Realio NFT Factory contract

    // contract level vars
    address _stakingContractAddress; // Realio LP contract address
    uint256 public stakedSupply; // Supply of genesis tokens available
    uint256 public whaleThreshold; // Threshold for NFT claim
    bool public locked; // contract is locked no staking
    bool public networkGenesis; // realio network launch complete

    constructor() public {
        locked = true;
        networkGenesis = false;
        setWhaleThreshold(10000 ether); // 10,000 RIO
    }

    function getStakingContractAddress() public view virtual returns (address) {
        return _stakingContractAddress;
    }

    function init(address _stakingContractAddress, address _xRIOContractAddress, address _rioContractAddress) public onlyOwner {
        setStakingContractAddress(_stakingContractAddress);
        setxRIOToken(_xRIOContractAddress);
        setRIOToken(_rioContractAddress);
        flipLock();
    }

    function setWhaleThreshold(uint256 amount) public onlyOwner {
        whaleThreshold = amount;
    }

    function setRealioNFTContract(address a) public onlyOwner {
        realioNFTContract = IERC1155Mintable(a);
    }

    function setStakingContractAddress(address a) public onlyOwner {
        _stakingContractAddress = a;
    }

    function setRIOToken(address _rioAddress) public onlyOwner {
        rio = IERC20(_rioAddress);
    }

    function setxRIOToken(address _xrioAddress) public onlyOwner {
        xRio = IERC20(_xrioAddress);
    }

    function setNetworkGenesis() public onlyOwner {
        networkGenesis = true;
        emit GenesisUnlocked(_msgSender());
    }

    function flipLock() public onlyOwner {
        locked = !locked;
    }

    function updateStakeHolding(address staker, uint256 amount) internal {
        StakerInfo storage stakerInfo = _stakerInfoMap[staker];
        uint256 stakedBal = stakerInfo.amount;
        stakerInfo.amount = amount + stakedBal;
    }

    function stake(uint256 amount) public nonReentrant {
        // staker must approve the stake amount to be controlled by the genesis contract
        require(!locked, "Genesis contract is locked");
        require(rio.balanceOf(_msgSender()) >= amount, "Sender does not have enough RIO");
        // solidity 0.8 now includes SafeMath as default; overflows not an issue
        uint256 amountShare = amount / 2;
        uint256 mintAmount = calculateMintAmount(amount);
        rio.transferFrom(_msgSender(), _stakingContractAddress, amountShare);
        rio.burnFrom(_msgSender(), amountShare);
        xRio.mint(_msgSender(), mintAmount);
        stakedSupply = stakedSupply + amount;
        updateStakeHolding(_msgSender(), amount);
        emit Stake(_msgSender(), amount);
    }

    // determine the appropriate bonus share based on stakedSupply and users staked amount
    // if newSupply crossed a tier threshold calculate appropriate bonusShare
    function calculateMintAmount(uint256 amount) internal view returns (uint256) {
        uint256 tierOne = 100000 ether; // 100,000 RIO
        uint256 tierTwo = 500000 ether; // 500,000 RIO
        uint256 bonusShare = 0;
        uint256 newSupply = stakedSupply + amount;
        if (newSupply < tierOne) {
            // tierOne stake level
            bonusShare = amount * 3;
        } else if (newSupply < tierTwo) {
            // tierTwo stake level
            if (stakedSupply < tierOne) {
                // check if staked amount crosses tierOne threshold
                // ie stakedSupply + user staked amount crosses tierOne
                uint256 partialShare = 0;
                uint256 overflowShare = 0;
                partialShare = tierOne - stakedSupply;
                overflowShare = newSupply - tierOne;
                bonusShare = (partialShare * 3) + (overflowShare * 2);
            } else {
                bonusShare = amount * 2;
            }
        } else {
            if (stakedSupply < tierTwo) {
                // check if staked amount crosses tierTwo threshold
                // ie stakedSupply + user staked amount crosses tierTwo
                uint256 partialShare = 0;
                uint256 overflowShare = 0;
                partialShare = tierTwo - stakedSupply;
                overflowShare = newSupply - tierTwo;
                bonusShare = (partialShare * 2) + (overflowShare + (overflowShare/2));
            } else {
                bonusShare = amount + (amount/2);
            }
        }
        return bonusShare;
    }

    // allow any whales that have staked to receive an NFT at Genesis
    function claim() public nonReentrant {
        require(hasClaim(_msgSender()), "sender has no NFT claim");
        if (_stakerInfoMap[_msgSender()].amount >= whaleThreshold) {
            realioNFTContract.create(_msgSender(), 1, '');
            _stakerInfoMap[_msgSender()].claimedNFT = true;
        }
        emit Claim(_msgSender());
    }

    // check if the account has an NFT claim
    function hasClaim(address _to) internal view returns (bool) {
        return !_stakerInfoMap[_to].claimedNFT && _stakerInfoMap[_to].amount > whaleThreshold;
    }

    function getStakedBalance() public view returns (uint256) {
        return _stakerInfoMap[_msgSender()].amount;
    }

    function getStakedBalanceForAddress(address staker) public view returns (uint256) {
        return _stakerInfoMap[staker].amount;
    }
}