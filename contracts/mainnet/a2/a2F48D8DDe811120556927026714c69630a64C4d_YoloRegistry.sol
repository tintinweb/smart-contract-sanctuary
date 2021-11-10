//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./YoloInterfaces.sol";

/**
  Manages the state of the PLayers in the Yolo Games Universe.
 */

contract YoloRegistry is Ownable, Pausable {

    event YoloGamertagUpdate(address indexed account, string gamertag);
    event YoloClantagUpdate(address indexed account, string clantag);
    event YoloProfilePicUpdate(address indexed account, string pfp);

    struct Player {
      string gamertag;
      string clantag;
      string pfp;
    }

    mapping (address => string) public gamertags;
    mapping (address => string) public clantags;
    mapping (address => string) public pfps;

    mapping (string => address) public gamertagToPlayer;

    uint public gamertagFee = 50 ether;
    uint public clantagFee = 50 ether;
    uint public pfpFee = 100 ether;

    uint16 public gamertagMaxLength = 80;
    uint16 public clantagMaxLength = 8;

    IYoloDice public diceV1;
    IYoloChips public chips;

    constructor(address _diceV1, address _chips) {
        diceV1 = IYoloDice(_diceV1);
        chips = IYoloChips(_chips);
    }

    // Pausable.

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // Setters.

    function setDiceV1(address _diceV1) external onlyOwner {
        diceV1 = IYoloDice(_diceV1);
    }

    function setChips(address _chips) external onlyOwner {
        chips = IYoloChips(_chips);
    }

    function setGamertagFee(uint256 _fee) external onlyOwner {
        gamertagFee = _fee;
    }

    function setClantagFee(uint256 _fee) external onlyOwner {
        clantagFee = _fee;
    }

    function setPfpFee(uint256 _fee) external onlyOwner {
        pfpFee = _fee;
    }

    function setGamertagMaxLength(uint16 _length) external onlyOwner {
        gamertagMaxLength = _length;
    }

    function setClantagMaxLength(uint16 _length) external onlyOwner {
        clantagMaxLength = _length;
    }

    function setMultiGamertags(string[] memory _gamertags, address[] memory _addresses) external onlyOwner {
        for (uint256 idx = 0; idx < _gamertags.length; idx++) {
            // Max length.
            require(bytes(_gamertags[idx]).length <= gamertagMaxLength, "Yolo Registry: Gamertag too long");
        
            // Ensure unique.
            require(!_isGamertagTaken(_gamertags[idx]), "Yolo Registry: Gamertag is taken");

            _setGamertagFor(_gamertags[idx], _addresses[idx]);
        }
    }

    // Dashboard functionality.

    /// @notice Returns token IDs of V1 Dice owned by the address.
    function getV1Dice(address _address) public view returns (uint256[] memory) {
        uint balance = diceV1.balanceOf(_address);

        uint256[] memory diceIds = new uint256[](balance);
        for (uint256 idx = 0; idx < balance; idx++) {
            diceIds[idx] = diceV1.tokenOfOwnerByIndex(_address, idx);
        }

        return diceIds;
    }

    /// @notice Returns the profile of the given address.
    function getProfile(address _address) public view returns (Player memory) {
        return Player(getGamertag(_address), getClantag(_address), getPfp(_address));
    }

    /// @notice Returns the full profile for the player with the given gamertag.
    function getProfileForTag(string memory _gamertag) public view returns (Player memory) {
        address playerAddress = gamertagToPlayer[_gamertag];
        if (playerAddress == address(0x0)) {
            return Player("", "", "");
        }

        return Player(
            getGamertag(playerAddress),
            getClantag(playerAddress),
            getPfp(playerAddress)
        );
    }

    function getGamertag(address _address) public view returns (string memory) {
        return gamertags[_address];
    }

    function setGamertag(string memory _gamertag) public whenNotPaused {
        // Max length.
        require(bytes(_gamertag).length <= gamertagMaxLength, "Yolo Registry: Gamertag too long");
        
        // Ensure unique.
        require(!_isGamertagTaken(_gamertag), "Yolo Registry: Gamertag is taken");

        chips.spend(msg.sender, gamertagFee);

        _setGamertagFor(_gamertag, msg.sender);
    }

    function getClantag(address _address) public view returns (string memory) {
        return clantags[_address];
    }

    function setClantag(string memory _clantag) public whenNotPaused {
        // Max length.
        require(bytes(_clantag).length <= clantagMaxLength, "Yolo Registry: Clantag too long");

        chips.spend(msg.sender, clantagFee);
        clantags[msg.sender] = _clantag;

        emit YoloClantagUpdate(msg.sender, _clantag);
    }

    function getPfp(address _address) public view returns (string memory) {
        return pfps[_address];
    }

    function setPfp(string memory _pfp) public whenNotPaused {
        chips.spend(msg.sender, pfpFee);
        pfps[msg.sender] = _pfp;

        emit YoloProfilePicUpdate(msg.sender, _pfp);
    }

    // Helpers.

    function _setGamertagFor(string memory _gamertag, address _address) internal {
        // Free up old gamertag.
        string memory previous = gamertags[_address];
        if (bytes(previous).length > 0) {
          gamertagToPlayer[previous] = address(0x0);
        }

        // Set new gamertag.
        gamertags[_address] = _gamertag;
        gamertagToPlayer[_gamertag] = _address;

        emit YoloGamertagUpdate(_address, _gamertag);
    }

    function _isGamertagTaken(string memory _gamertag) internal view returns (bool) {
        return gamertagToPlayer[_gamertag] != address(0x0);
    }

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IYoloDice {
    /// @notice IERC721, returns owner of token.
    function ownerOf(uint256 tokenId) external view returns (address);
    /// @notice IERC721, returns number of tokens owned.
    function balanceOf(address owner) external view returns (uint256);
    /// @notice IERC721, returns total number of tokens created.
    function totalSupply() external view returns (uint256);
    /// @notice IERC721Enumerable, returns token ID.
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
}

interface IYoloChips {
    /// @notice IERC20, returns number of tokens owned.
    function balanceOf(address account) external view returns (uint256);
    /// @notice Burns chips from whitelisted contracts.
    function spend(address account, uint256 amount) external;
    /// @notice Performs accounting before properties are transferred.
    function updateOwnership(address _from, address _to) external;
}

interface IYoloBoardDeed {
    /// @notice IERC721, returns number of tokens owned.
    function balanceOf(address owner) external view returns (uint256);
    /// @notice IERC721Enumerable, returns token ID.
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
    /// @notice Returns yield of the given token.
    function yieldRate(uint256 tokenId) external view returns (uint256);
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