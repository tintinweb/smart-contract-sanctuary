// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface ICareToken is IERC20 {
  function mintToApprovedContract(uint256 amount, address mintToAddress) external;
  function burn(address sender, uint256 paymentAmount) external;
}

interface ISpiritOrbPetsv1 is IERC721, IERC721Enumerable {
  function getPetInfo(uint16 id) external view returns (
    uint8 level,
    bool active
  );

  function getPetCooldowns(uint16 id) external view returns (
    uint64 cdPlay,
    uint64 cdFeed,
    uint64 cdClean,
    uint64 cdTrain,
    uint64 cdDaycare
  );

  function getPausedState() external view returns (bool);
  function getMaxPetLevel() external view returns (uint8);
  function petName(uint16 id) external view returns (string memory);

  function setPetName(uint16 id, string memory name) external;
  function setPetLevel(uint16 id, uint8 level) external;
  function setPetActive(uint16 id, bool active) external;
  function setPetCdPlay(uint16 id, uint64 cdPlay) external;
  function setPetCdFeed(uint16 id, uint64 cdFeed) external;
  function setPetCdClean(uint16 id, uint64 cdClean) external;
  function setPetCdTrain(uint16 id, uint64 cdTrain) external;
  function setPetCdDaycare(uint16 id, uint64 cdDaycare) external;
}

contract SpiritOrbPetsCarev1 is Ownable {

    ISpiritOrbPetsv1 public SOPv1;
    ICareToken public CareToken;

    uint256 public _timeUntilLevelDown = 72 hours; // 259200 uint value in seconds

    event Activated(address sender, uint16 id);
    event Deactivated(address sender, uint16 id);
    event PlayedWithPet(address sender, uint16 id, bool levelDownEventOccurred);
    event FedPet(address sender, uint16 id, uint careTokensToPay, bool levelDownEventOccurred);
    event CleanedPet(address sender,uint16 id, bool levelDownEventOccurred);
    event TrainedPet(address sender, uint16 id);
    event SentToDaycare(address sender, uint16 id, uint daysToPayFor);

    modifier notAtDaycare(uint16 id) {
      ( , , , , uint cdDaycare ) = SOPv1.getPetCooldowns(id);
      require(cdDaycare <= block.timestamp, "Cannot perform action while pet is at daycare.");
      _;
    }

    function setTimeUntilLevelDown(uint256 newTime) external onlyOwner {
      _timeUntilLevelDown = newTime;
    }

    function getTrueLevel(uint16 id) public view returns (uint8) {
      (uint64 cdPlay, uint64 cdFeed, uint64 cdClean, , ) = SOPv1.getPetCooldowns(id);
      (uint8 level, ) = SOPv1.getPetInfo(id);
      uint64 blockTimestamp = uint64(block.timestamp);
      bool hungry = cdFeed <= blockTimestamp;
      bool dirty = cdClean + _timeUntilLevelDown <= blockTimestamp;
      bool unhappy = cdPlay + _timeUntilLevelDown <= blockTimestamp;

      // if completely neglected, pet's level resets to 1
      if (hungry && dirty && unhappy && level != 30) {
        level = 1;
      }
      // Separated into 3 so it doesn't go below 1
      if (hungry && level > 1 && level != 30) {
        level = level - 1;
      }
      if (dirty && level > 1 && level != 30) {
        level = level - 1;
      }
      if (unhappy && level > 1 && level != 30) {
        level = level - 1;
      }
      return level;
    }

    function activatePet(uint16 id) external {
      ( , bool active) = SOPv1.getPetInfo(id);
      require(!SOPv1.getPausedState(), "Pet adoption has not yet begun.");
      require(SOPv1.ownerOf(id) == msg.sender);
      require(!active, "Pet is already active!");

      resetPetCooldowns(id);

      emit Activated(msg.sender, id);
    }

    function resetPetCooldowns(uint16 id) internal {
      (uint64 cdPlay, , , , ) = SOPv1.getPetCooldowns(id);
      SOPv1.setPetActive(id, true);
      if (cdPlay == 0) SOPv1.setPetCdPlay(id, uint64(block.timestamp));
      SOPv1.setPetCdFeed(id, uint64(block.timestamp + 1 hours));
      SOPv1.setPetCdClean(id, uint64(block.timestamp + 3 days - 1 hours));
      SOPv1.setPetCdTrain(id, uint64(block.timestamp + 23 hours));
    }

    /**
    * @dev Deactivating the pet will reduce the level to 1 unless they are at max level
    * @dev This is the only way to take a pet out of daycare as well before the time expires
    */
    function deactivatePet(uint16 id) external {
      ( , , , , uint cdDaycare) = SOPv1.getPetCooldowns(id);
      (  uint8 level, bool active) = SOPv1.getPetInfo(id);
      require(SOPv1.ownerOf(id) == msg.sender);
      require(active, "Pet is not active yet.");

      SOPv1.setPetActive(id, false);
      if (cdDaycare > uint64(block.timestamp)) {
        SOPv1.setPetCdDaycare(id, 0);
        SOPv1.setPetCdPlay(id, uint64(block.timestamp));
        // everything else is reset during reactivation
      }
      if (level < SOPv1.getMaxPetLevel()) {
        SOPv1.setPetLevel(id, 1);
      }

      emit Deactivated(msg.sender, id);
    }

    function levelDown(uint16 id) internal {
      (uint64 cdPlay, uint64 cdFeed, uint64 cdClean, , ) = SOPv1.getPetCooldowns(id);
      (uint8 level, ) = SOPv1.getPetInfo(id);
      uint64 blockTimestamp = uint64(block.timestamp);
      bool hungry = cdFeed <= blockTimestamp;
      bool dirty = cdClean + _timeUntilLevelDown <= blockTimestamp;
      bool unhappy = cdPlay + _timeUntilLevelDown <= blockTimestamp;

      if (level > 1 && level != 30) {
        SOPv1.setPetLevel(id, level - 1);
      }

      // if completely neglected, pet's level resets to 1
      if (hungry && dirty && unhappy && level != 30) {
        SOPv1.setPetLevel(id, 1);
      }
    }

    function levelUp(uint16 id) internal {
      (uint8 level, ) = SOPv1.getPetInfo(id);
      if (level < SOPv1.getMaxPetLevel()) {
        SOPv1.setPetLevel(id, level + 1);
      }
    }

    /**
    * @dev Playing with your pet is the primary way to earn CARE tokens.
    */
    function playWithPet(uint16 id) external {
      (uint64 cdPlay, uint64 cdFeed, uint64 cdClean, , ) = SOPv1.getPetCooldowns(id);
      ( , bool active) = SOPv1.getPetInfo(id);
      require(SOPv1.ownerOf(id) == msg.sender, "Only the owner of the pet can play with it!");
      require(active, "Pet needs to be active to receive CARE tokens.");
      require(cdFeed >= uint64(block.timestamp), "Pet is too hungry to play.");
      require(cdClean >= uint64(block.timestamp), "Pet is too dirty to play.");
      require(cdPlay <= uint64(block.timestamp), "You can only redeem CARE tokens every 23 hours.");

      // send CARE tokens to owner
      CareToken.mintToApprovedContract(10 * 10 ** 18, msg.sender);

      // check if the pet was played with on time, if not, level down
      bool levelDownEventOccurred = false;
      if (cdPlay + _timeUntilLevelDown <= uint64(block.timestamp)) {
        levelDown(id);
        levelDownEventOccurred = true;
      }

      // set new time for playing with pet
      SOPv1.setPetCdPlay(id, uint64(block.timestamp + 23 hours));

      emit PlayedWithPet(msg.sender, id, levelDownEventOccurred);
    }

    /**
    * @dev Sets the cdFeed timer when you activate it.  You MUST call approve on the
    * @dev ERC20 token AS the user before interacting with this function or it will not
    * @dev work. Pet will level down if you took too long to feed it.
    */
    function feedPet(uint16 id, uint careTokensToPay) external notAtDaycare(id) {
      ( , uint64 cdFeed, uint64 cdClean,  ,  ) = SOPv1.getPetCooldowns(id);
      ( , bool active) = SOPv1.getPetInfo(id);
      require(SOPv1.ownerOf(id) == msg.sender, "Only the owner of the pet can feed it!");
      require(active, "Pet needs to be active to feed pet.");
      require(cdClean >= uint64(block.timestamp), "Pet is too dirty to eat.");
      require(careTokensToPay <= 15, "You should not overfeed your pet.");
      require(careTokensToPay >= 5, "Too little CARE sent to feed pet.");
      // We could check to see if it's too soon to feed the pet, but it would become more expensive in gas
      // And we can otherwise control this from the front end
      // Plus players can top their pet's feeding meter whenever they want this way

      // take CARE tokens from owner
      uint paymentAmount = careTokensToPay * 10 ** 18;
      // Token must be approved from the CARE token's address by the owner
      CareToken.burn(msg.sender, paymentAmount);

      uint64 blockTimestamp = uint64(block.timestamp);

      // check if the pet was fed on time, if not, level down
      bool levelDownEventOccurred = false;
      if (cdFeed <= blockTimestamp) {
        levelDown(id);
        levelDownEventOccurred = true;
      }

      // set new time for feeding pet
      // if pet isn't starving yet, just add the time, otherwise set the time to now + 8hrs * tokens
      if (cdFeed > blockTimestamp) {
        uint64 newFeedTime = cdFeed + uint64(careTokensToPay/5 * 1 days);
        SOPv1.setPetCdFeed(id, newFeedTime);
        // Pet cannot be full for more than 3 days max
        if (newFeedTime > blockTimestamp + 3 days) {
          SOPv1.setPetCdFeed(id, blockTimestamp + 3 days);
        }
      } else {
        SOPv1.setPetCdFeed(id, uint64(blockTimestamp + (careTokensToPay/5 * 1 days))); //5 tokens per 24hrs up to 72hrs
      }

      emit FedPet(msg.sender, id, careTokensToPay, levelDownEventOccurred);
    }

    /**
    * @dev Cleaning your pet is a secondary way to earn CARE tokens.  If you don't clean
    * @dev your pet in time (24hrs after it reaches the timer) your pet will level down.
    */
    function cleanPet(uint16 id) external {
      ( , , uint64 cdClean, , ) = SOPv1.getPetCooldowns(id);
      ( , bool active) = SOPv1.getPetInfo(id);
      require(SOPv1.ownerOf(id) == msg.sender, "Only the owner of the pet can clean it!");
      require(active, "Pet needs to be active to feed pet.");
      uint64 blockTimestamp = uint64(block.timestamp);
      require(cdClean <= blockTimestamp, "Pet is not dirty yet.");

      // send CARE tokens to owner
      CareToken.mintToApprovedContract(30 * 10 ** 18, msg.sender);

      // check if the pet was cleaned on time, if not, level down
      bool levelDownEventOccurred = false;
      if ((cdClean + _timeUntilLevelDown) <= blockTimestamp) {
        levelDown(id);
        levelDownEventOccurred = true;
      }

      SOPv1.setPetCdClean(id, blockTimestamp + 3 days - 1 hours); // 3 tokens per 24hrs up to 72hrs
      emit CleanedPet(msg.sender, id, levelDownEventOccurred);
    }

    /**
    * @dev Training your pet is the only way to level it up.  You can do it once per
    * @dev day, 23 hours after activating it.
    */
    function trainPet(uint16 id) external notAtDaycare(id) {
      ( , uint64 cdFeed, uint64 cdClean, uint64 cdTrain, ) = SOPv1.getPetCooldowns(id);
      ( uint8 level, bool active) = SOPv1.getPetInfo(id);
      uint64 blockTimestamp = uint64(block.timestamp);
      require(SOPv1.ownerOf(id) == msg.sender, "Only the owner of the pet can train it!");
      require(active, "Pet needs to be active to train pet.");
      require(cdFeed >= blockTimestamp, "Pet is too hungry to train.");
      require(cdClean >= blockTimestamp, "Pet is too dirty to train.");
      require(cdTrain <= blockTimestamp, "Pet is too tired to train.");

      if (level < 30) {

        // take CARE tokens from owner
        uint paymentAmount = 10 * 10 ** 18;
        // Token must be approved from the CARE token's address by the owner
        CareToken.burn(msg.sender, paymentAmount);

        levelUp(id);
      } else {
        // send CARE tokens to owner
        CareToken.mintToApprovedContract(10 * 10 ** 18, msg.sender);
      }

      SOPv1.setPetCdTrain(id, blockTimestamp + 23 hours);
      emit TrainedPet(msg.sender, id);
    }

    /**
    * @dev Sending your pet to daycare is intended to freeze your pets status if you
    * @dev plan to be away from it for a while. There is no refund for bringing your
    * @dev pet back early. You can extend your stay by directly interacting with
    * @dev the contract. Note that it won't extend the stay, just set it to a new value.
    */
    function sendToDaycare(uint16 id, uint daysToPayFor) external notAtDaycare(id) {
      (uint8 level , bool active) = SOPv1.getPetInfo(id);
      require(SOPv1.ownerOf(id) == msg.sender, "Only the owner of the pet send it to daycare!");
      require(active, "Pet needs to be active to send it to daycare.");
      require(daysToPayFor >= 1, "Minimum 1 day of daycare required.");
      require(daysToPayFor <= 30, "You cannot send pet to daycare for that long.");

      // pet MUST NOT have a level-down event occuring; daycare would otherwise by-pass it
      require(getTrueLevel(id) == level, "Pet cannot go to daycare if it has been neglected.");

      // take CARE tokens from owner
      // each day is 10 whole CARE tokens
      uint paymentAmount = daysToPayFor * 10 * 10 ** 18;
      // Token must be approved from the CARE token's address by the owner
      CareToken.burn(msg.sender, paymentAmount);

      // calculate how many days to send pet to daycare
      uint timeToSendPet = daysToPayFor * 1 days;

      // set timer for daycare and caretaking activities
      uint64 timeToSetCareCooldowns = uint64(block.timestamp + timeToSendPet);
      SOPv1.setPetCdDaycare(id, timeToSetCareCooldowns);
      SOPv1.setPetCdPlay(id, timeToSetCareCooldowns);
      SOPv1.setPetCdFeed(id, timeToSetCareCooldowns);
      SOPv1.setPetCdClean(id, timeToSetCareCooldowns + 3 days - 1 hours);
      SOPv1.setPetCdTrain(id, timeToSetCareCooldowns);

      emit SentToDaycare(msg.sender, id, daysToPayFor);
    }

    /**
    * @dev Brings pet back from daycare. Funds are not refunded and cooldowns are
    * @dev reset as if from the state of activation again.
    */
    function retrieveFromDaycare(uint16 id) external {
      ( ,  ,  ,  , uint cdDaycare) = SOPv1.getPetCooldowns(id);
      ( , bool active) = SOPv1.getPetInfo(id);
      uint64 blockTimestamp = uint64(block.timestamp);
      require(SOPv1.ownerOf(id) == msg.sender, "Only the owner of the pet send it to daycare!");
      require(active, "Pet needs to be active to send it to daycare.");
      require(cdDaycare > blockTimestamp, "Cannot perform action if pet is not in daycare.");

      resetPetCooldowns(id);
      // Additional exceptions for daycare; allow play
      SOPv1.setPetCdDaycare(id, 0);
      SOPv1.setPetCdPlay(id, blockTimestamp);
    }

    /**
    * @dev Allows the user to rename their pet.  If the pet has a name already,
    * @dev it will cost 100 CARE tokens to execute.
    * @dev The front-end limits number of characters in the string arg as well
    * @dev as the output of getName. If you want to name your pet longer than
    * @dev what the front-end allows, it's pointless unless you build your own.
    */
    function namePet(uint16 id, string memory newName) external {
      ( , bool active) = SOPv1.getPetInfo(id);
      require(SOPv1.ownerOf(id) == msg.sender, "Only the owner of the pet can name it!");
      require(active, "Pet needs to be active to name it.");
      require(keccak256(abi.encodePacked(newName)) != keccak256(abi.encodePacked(SOPv1.petName(id))), "Pet already has this name.");

      if (keccak256(abi.encodePacked(SOPv1.petName(id))) == keccak256(abi.encodePacked(""))) {
        SOPv1.setPetName(id, newName);
      } else {
        // take CARE tokens from owner
        uint paymentAmount = 100 * 10 ** 18;
        // Token must be approved from the CARE token's address by the owner
        CareToken.burn(msg.sender, paymentAmount);

        SOPv1.setPetName(id, newName);
      }
    }

    function levelUpWithCare(uint16 id, uint levelsToGoUp) external notAtDaycare(id) {
      (uint8 level, bool active) = SOPv1.getPetInfo(id);
      require(SOPv1.ownerOf(id) == msg.sender, "Only the owner of the pet can level it up!");
      require(active, "Pet needs to be active to level up.");
      require(level < 30, "Pet is already at max level.");
      require(level + uint8(levelsToGoUp) <= 30, "This would make your pet exceed level 30 and waste tokens.");

      // take CARE tokens from owner
      // each level is 100 whole CARE tokens
      uint paymentAmount = levelsToGoUp * 100 * 10 ** 18;
      // Token must be approved from the CARE token's address by the owner
      CareToken.burn(msg.sender, paymentAmount);

      for (uint i = 0; i < levelsToGoUp; i++) {
        levelUp(id);
      }
    }

    function setCareToken(address careTokenAddress) external onlyOwner {
      CareToken = ICareToken(careTokenAddress);
    }

    function setSOPV1Contract(address sopv1Address) external onlyOwner {
      SOPv1 = ISpiritOrbPetsv1(sopv1Address);
    }

    // vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
    // CHEAT SECTION -- THIS WILL NOT BE IN THE FINAL CONTRACT
    // FOR TESTING PURPOSES ONLY!
    // vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv


    function cheatSetLevel(uint16 id, uint8 level) external {
      require(SOPv1.ownerOf(id) == msg.sender, "Only the owner of the pet can cheat!");
      SOPv1.setPetLevel(id, level);
    }

    /**
    * @dev test functions so you can test reaching level down states and
    * @dev reset daycare, playing (for CARE collecting), and cleaning states
    */
    function cheatResetCDTimer(uint16 id, uint256 daysOver) external {
      require(SOPv1.ownerOf(id) == msg.sender, "Only the owner of the pet can cheat!");
      SOPv1.setPetCdClean(id, uint64(block.timestamp - daysOver * 1 days));
      SOPv1.setPetCdFeed(id, uint64(block.timestamp - daysOver * 1 days));
      SOPv1.setPetCdPlay(id, uint64(block.timestamp - daysOver * 1 days));
    }

    function cheatResetCDTimerClean(uint16 id, uint256 daysOver) external {
      require(SOPv1.ownerOf(id) == msg.sender, "Only the owner of the pet can cheat!");
      SOPv1.setPetCdClean(id, uint64(block.timestamp - daysOver * 1 days));
    }

    function cheatResetCDTimerFeed(uint16 id, uint256 daysOver) external {
      require(SOPv1.ownerOf(id) == msg.sender, "Only the owner of the pet can cheat!");
      SOPv1.setPetCdFeed(id, uint64(block.timestamp - daysOver * 1 days));
    }

    function cheatResetCDTimerPlay(uint16 id, uint256 daysOver) external {
      require(SOPv1.ownerOf(id) == msg.sender, "Only the owner of the pet can cheat!");
      SOPv1.setPetCdPlay(id, uint64(block.timestamp - daysOver * 1 days));
    }

    function cheatResetCDTimerTrain(uint16 id, uint256 daysOver) external {
      require(SOPv1.ownerOf(id) == msg.sender, "Only the owner of the pet can cheat!");
      SOPv1.setPetCdTrain(id, uint64(block.timestamp - daysOver * 1 days));
    }

    function cheatResetCDTimerDaycare(uint16 id, uint256 daysOver) external {
      require(SOPv1.ownerOf(id) == msg.sender, "Only the owner of the pet can cheat!");
      SOPv1.setPetCdDaycare(id, uint64(block.timestamp - daysOver * 1 days));
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

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