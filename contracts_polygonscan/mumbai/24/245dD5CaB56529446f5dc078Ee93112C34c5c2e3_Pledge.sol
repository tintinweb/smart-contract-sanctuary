//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";
import "./interface/IRewardCard.sol";

contract Pledge is Context,KeeperCompatibleInterface,Ownable{


    address rewardCardAddress;

    //轮次详情
    struct roundInfo {
        uint256 sumPower;
        uint256 assetsNumber;
        uint256 startBlock;
        uint256 endBlock;
        uint256 unitReward;
    }

    //当前轮次
    uint256 public currentRounds;
    //每轮区块(以实际调用区块为准)
    uint256 public EachRoundBlockNumber = 30;
    //授权轮次
    mapping(uint256 => uint256) licensingRounds;
    //最后领取轮次 tokenId => rounds
    mapping(uint256 => uint256) lastGetRounds;
    //轮次详情
    mapping(uint256 => roundInfo) public roundsDetails;


    function setEachRoundBlockNumber(uint256 _EachRoundBlockNumber) public virtual onlyOwner() {
        EachRoundBlockNumber = _EachRoundBlockNumber;
    }

    function setRewardCardAddress(address _rewardCardAddress) public virtual onlyOwner() {
        rewardCardAddress = _rewardCardAddress;
    }

    constructor(){
        init();
    }

    function init() internal {
        currentRounds = 1;
        roundInfo storage info = roundsDetails[currentRounds];
        info.sumPower = 0;
        info.assetsNumber = 0;
        info.startBlock = block.number;
        info.endBlock = 0;
    }

    function openAward(uint256 _tokenId) public virtual {
        require(_msgSender() == IRewardCard(rewardCardAddress).ownerOf(_tokenId), "This NFT doesn't belong to this address");
        uint8 power = IRewardCard(rewardCardAddress).showPower(_tokenId);
        require(power > 0, "This NFT has not been initialized, please try again later");
        licensingRounds[_tokenId] = currentRounds;
        uint256 nextRound = currentRounds + 1;
        roundInfo storage info = roundsDetails[nextRound];
        info.sumPower += power;
        lastGetRounds[_tokenId] = currentRounds;
    }
    function checkUpkeep(bytes calldata  /* checkData */) external  override returns (bool upkeepNeeded, bytes memory /* checkData */) {
        upkeepNeeded = roundsDetails[currentRounds].startBlock + EachRoundBlockNumber < block.number;
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        require(roundsDetails[currentRounds].startBlock + EachRoundBlockNumber < block.number);
        roundInfo storage info = roundsDetails[currentRounds];
        info.endBlock = block.number;
        info.unitReward = bonusPerUnitOfCalculatingPower(info.assetsNumber,info.sumPower);
        currentRounds = currentRounds + 1;
        roundInfo storage newInfo = roundsDetails[currentRounds];
        newInfo.sumPower = newInfo.sumPower + info.sumPower;
        newInfo.startBlock = block.number;
    }

    //计算单算力奖励
    function bonusPerUnitOfCalculatingPower(uint256 _assetsNumber, uint256 _sumPower) internal returns (uint256){
        return _assetsNumber / _sumPower;
    }

    //查看奖励
    function showAward(uint256 _tokenId) public view virtual returns (uint256, uint256){
        uint8 power = IRewardCard(rewardCardAddress).showPower(_tokenId);
        uint256 last = lastGetRounds[_tokenId];
        uint256 lastUnitReward = roundsDetails[last].unitReward;
        uint256 calculateTheRounds = currentRounds - 1;
        uint256 unitReward = roundsDetails[calculateTheRounds].unitReward;
        return ((unitReward - lastUnitReward) * power, calculateTheRounds);
    }

    //领取奖励
    function claimAward(uint256 _tokenId) public virtual {
        require(_msgSender() == IRewardCard(rewardCardAddress).ownerOf(_tokenId), "This NFT doesn't belong to this address");
        (uint256 award,uint256 calculateTheRounds) = showAward(_tokenId);
//        address payable receivingAddress = address(uint160(_msgSender()));
        if (award > 0) {
            _safeTransfer(_msgSender(),award);
        }
        lastGetRounds[_tokenId] = calculateTheRounds;
    }


    /**
     * @notice Transfer  in a safe way
     * @param to: address to transfer  to
     * @param value:  amount to transfer (in wei)
     */
    function _safeTransfer(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}("");
        require(success, "TransferHelper: TRANSFER_FAILED");
    }


}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./KeeperBase.sol";
import "./interfaces/KeeperCompatibleInterface.sol";

abstract contract KeeperCompatible is KeeperBase, KeeperCompatibleInterface {}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IRewardCard{
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function showPower(uint256 tokenId) external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract KeeperBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easilly be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}