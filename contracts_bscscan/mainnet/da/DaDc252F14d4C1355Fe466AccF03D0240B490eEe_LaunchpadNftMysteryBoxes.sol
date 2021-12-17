//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interface/ISquidBusNFT.sol";
import "./interface/ISquidPlayerNFT.sol";
import "./interface/IOracle.sol";


/**
 * @title Squid game NFT Mystery box Launchpad
 * @notice Sell Mystery boxes with NFT`s
 */
contract LaunchpadNftMysteryBoxes is Ownable, Pausable {
    using SafeERC20 for IERC20;

    ISquidPlayerNFT squidPlayerNFT;
    ISquidBusNFT squidBusNFT;

    address public treasuryAddress;
    IERC20 public immutable dealToken;

    uint public immutable probabilityBase;

    uint boxAmount = 10000; //TODO change in prod
    uint boxPrice = 50 ether / 1000; //TODO change in prod
    uint maxToUser = 5; //TODO change in prod
    uint boxSold;
    uint[] probability;

    struct PlayerNFTEntity {
        uint128 squidEnergy;
        uint8 rarity;
    }

    struct BusNFTEntity {
        uint8 busLevel;
    }

    struct Box {
        PlayerNFTEntity[] playerNFTEntity;
        BusNFTEntity[] busNFTEntity;
    }

    Box[10] boxes;
    mapping(address => uint) public userBoughtCount; //Bought boxes by user: address => count

    event LaunchpadExecuted(address indexed user, uint boxIndex);

    /**
     * @notice Constructor
     * @dev In constructor initialise Boxes
     * @param _squidPlayerNFT: squid player nft contract
     * @param _squidBusNFT: squid bus NFT contract
     * @param _dealToken: deal token contract
     * @param _treasuryAddress: treasury address
     */
    constructor(
        ISquidPlayerNFT _squidPlayerNFT,
        ISquidBusNFT _squidBusNFT,
        IERC20 _dealToken,
        address _treasuryAddress
    ) {
        squidPlayerNFT = _squidPlayerNFT;
        squidBusNFT = _squidBusNFT;
        dealToken = _dealToken;
        treasuryAddress = _treasuryAddress;


        //BOX 1 ----------------------------------------------------------------------------
        boxes[0].busNFTEntity.push(BusNFTEntity({busLevel: 2}));
        boxes[0].playerNFTEntity.push(PlayerNFTEntity({squidEnergy: 400 ether, rarity: 1}));

        //BOX 2 ----------------------------------------------------------------------------
        boxes[1].busNFTEntity.push(BusNFTEntity({busLevel: 3}));
        boxes[1].playerNFTEntity.push(PlayerNFTEntity({squidEnergy: 700 ether, rarity: 2}));

        //BOX 3 ----------------------------------------------------------------------------
        boxes[2].busNFTEntity.push(BusNFTEntity({busLevel: 3}));
        boxes[2].playerNFTEntity.push(PlayerNFTEntity({squidEnergy: 400 ether, rarity: 1}));
        boxes[2].playerNFTEntity.push(PlayerNFTEntity({squidEnergy: 400 ether, rarity: 1}));
        boxes[2].playerNFTEntity.push(PlayerNFTEntity({squidEnergy: 400 ether, rarity: 1}));
        boxes[2].playerNFTEntity.push(PlayerNFTEntity({squidEnergy: 400 ether, rarity: 1}));

        //BOX 4 ----------------------------------------------------------------------------
        boxes[3].busNFTEntity.push(BusNFTEntity({busLevel: 4}));
        boxes[3].playerNFTEntity.push(PlayerNFTEntity({squidEnergy: 1000 ether, rarity: 2}));

        //BOX 5 ----------------------------------------------------------------------------
        boxes[4].busNFTEntity.push(BusNFTEntity({busLevel: 3}));
        boxes[4].playerNFTEntity.push(PlayerNFTEntity({squidEnergy: 800 ether, rarity: 2}));

        //BOX 6 ----------------------------------------------------------------------------
        boxes[5].busNFTEntity.push(BusNFTEntity({busLevel: 2}));
        boxes[5].playerNFTEntity.push(PlayerNFTEntity({squidEnergy: 1000 ether, rarity: 2}));
        boxes[5].playerNFTEntity.push(PlayerNFTEntity({squidEnergy: 1000 ether, rarity: 2}));
        boxes[5].playerNFTEntity.push(PlayerNFTEntity({squidEnergy: 1000 ether, rarity: 2}));

        //BOX 7 ----------------------------------------------------------------------------
        boxes[6].busNFTEntity.push(BusNFTEntity({busLevel: 3}));
        boxes[6].playerNFTEntity.push(PlayerNFTEntity({squidEnergy: 1300 ether, rarity: 3}));
        boxes[6].playerNFTEntity.push(PlayerNFTEntity({squidEnergy: 1300 ether, rarity: 3}));
        boxes[6].playerNFTEntity.push(PlayerNFTEntity({squidEnergy: 1300 ether, rarity: 3}));

        //BOX 8 ----------------------------------------------------------------------------
        boxes[7].busNFTEntity.push(BusNFTEntity({busLevel: 2}));
        boxes[7].playerNFTEntity.push(PlayerNFTEntity({squidEnergy: 1700 ether, rarity: 4}));
        boxes[7].playerNFTEntity.push(PlayerNFTEntity({squidEnergy: 1700 ether, rarity: 4}));

        //BOX 9 ----------------------------------------------------------------------------
        boxes[8].busNFTEntity.push(BusNFTEntity({busLevel: 4}));
        boxes[8].playerNFTEntity.push(PlayerNFTEntity({squidEnergy: 700 ether, rarity: 2}));
        boxes[8].playerNFTEntity.push(PlayerNFTEntity({squidEnergy: 700 ether, rarity: 2}));
        boxes[8].playerNFTEntity.push(PlayerNFTEntity({squidEnergy: 700 ether, rarity: 2}));
        boxes[8].playerNFTEntity.push(PlayerNFTEntity({squidEnergy: 700 ether, rarity: 2}));
        boxes[8].playerNFTEntity.push(PlayerNFTEntity({squidEnergy: 700 ether, rarity: 2}));

        //BOX 10 ----------------------------------------------------------------------------
        boxes[9].busNFTEntity.push(BusNFTEntity({busLevel: 5}));
        boxes[9].playerNFTEntity.push(PlayerNFTEntity({squidEnergy: 3000 ether, rarity: 5}));
        boxes[9].playerNFTEntity.push(PlayerNFTEntity({squidEnergy: 3000 ether, rarity: 5}));



    probability = [2500, 2500, 2000, 1600, 600, 500, 125, 125, 40, 10];

        require(probability.length == boxes.length, "Wrong arrays length");
        uint _base;
        for (uint i = 0; i < probability.length; i++) {
            _base += probability[i];
        }
        probabilityBase = _base;
    }

    /**
     * @notice Checks if the msg.sender is a contract or a proxy
     */
    modifier notContract() {
        require(!_isContract(msg.sender), "contract not allowed");
        require(msg.sender == tx.origin, "proxy contract not allowed");
        _;
    }

    /**
     * @notice Buy Mystery box from launch
     * @dev Callable by user
     */
    function buyBOX() external whenNotPaused notContract {
        require(userBoughtCount[msg.sender] < maxToUser, "Limit by User reached");
        require(boxSold < boxAmount, "Box sold out");

        dealToken.safeTransferFrom(msg.sender, treasuryAddress, boxPrice);
        userBoughtCount[msg.sender] += 1;
        boxSold += 1;

        uint _index = getRandomBoxIndex();

        Box memory _box = boxes[_index];

        if (_box.busNFTEntity.length > 0) {
            for (uint i = 0; i < _box.busNFTEntity.length; i++) {
                squidBusNFT.mint(msg.sender, _box.busNFTEntity[i].busLevel);
            }
        }
        if (_box.playerNFTEntity.length > 0) {
            for (uint i = 0; i < _box.playerNFTEntity.length; i++) {
                squidPlayerNFT.mint(msg.sender, _box.playerNFTEntity[i].squidEnergy, 0, _box.playerNFTEntity[i].rarity - 1);
            }
        }

        emit LaunchpadExecuted(msg.sender, _index);
    }

    /*
     * @notice Get info
     * @param user: User address
     */
    function getInfo(address user) public view
    returns
    (
        uint _boxAmount,
        uint _boxPrice,
        uint _maxToUser,
        uint _boxSold,
        uint _userBoughtCount
    ) {
        _boxAmount = boxAmount;
        _boxPrice = boxPrice;
        _maxToUser = maxToUser;
        _boxSold = boxSold;
        _userBoughtCount = userBoughtCount[user];
    }

    /*
     * @notice Pause a contract
     * @dev Callable by contract owner
     */
    function pause() public onlyOwner {
        _pause();
    }

    /*
     * @notice Unpause a contract
     * @dev Callable by contract owner
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @notice Set treasury address to accumulate deal tokens from sells
     * @dev Callable by contract owner
     * @param _treasuryAddress: Treasury address
     */
    function setTreasuryAddress(address _treasuryAddress) public onlyOwner {
        require(_treasuryAddress != address(0), "Address cant be zero");
        treasuryAddress = _treasuryAddress;
    }

    /**
     * @notice Checks if address is a contract
     * @dev It prevents contract from being targeted
     */
    function _isContract(address addr) internal view returns (bool) {
        uint size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    /**
     * @notice Generate random and find box index
     */
    function getRandomBoxIndex() private view returns (uint) {
        uint min = 1;
        uint max = probabilityBase;
        uint diff = (max - min) + 1;
        uint random = (uint(keccak256(abi.encodePacked(blockhash(block.number - 1), gasleft(), boxSold))) % diff) + min;
        uint count = 0;
        for (uint i = 0; i < probability.length; i++) {
            count += probability[i];
            if (random <= count) {
                return (i);
            }
        }
        revert("Wrong random received");
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

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface ISquidBusNFT {
    function getToken(uint _tokenId)
    external
    view
    returns (
        uint tokenId,
        address tokenOwner,
        uint8 level,
        uint32 createTimestamp,
        string memory uri
    );

    function mint(address to, uint8 busLevel) external;

    function secToNextBus(address _user) external view returns(uint);

    function allowedBusBalance(address user) external view returns (uint);

    function allowedUserToMintBus(address user) external view returns (bool);

    function firstBusTimestamp(address user) external;

    function seatsInBuses(address user) external view returns (uint);

    function tokenOfOwnerByIndex(address owner, uint index) external view returns (uint tokenId);

    function balanceOf(address owner) external view returns (uint balance);

    function ownerOf(uint tokenId) external view returns (address owner);

    event Initialize(string baseURI);
    event TokenMint(address indexed to, uint indexed tokenId, uint8 level);

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface ISquidPlayerNFT {
    struct TokensViewFront {
        uint tokenId;
        uint8 rarity;
        address tokenOwner;
        uint128 squidEnergy;
        uint128 maxSquidEnergy;
        uint32 contractEndTimestamp;
        uint32 busyTo; //Timestamp until which the player is busy
        uint32 createTimestamp;
        bool stakeFreeze;
        string uri;
    }

    function getToken(uint _tokenId) external view returns (TokensViewFront memory);

    function mint(
        address to,
        uint128 squidEnergy,
        uint32 contractEndTimestamp,
        uint8 rarity
    ) external;

    function lockTokens(
        uint[] calldata tokenId,
        uint32 busyTo,
        bool willDecrease, //will decrease SE or not
        address user
    ) external returns (uint128);

    function setPlayerContract(uint[] calldata tokenId, uint32 contractEndTimestamp, address user) external;

    function squidEnergyDecrease(uint[] calldata tokenId, uint128[] calldata deduction, address user) external;

    function squidEnergyIncrease(uint[] calldata tokenId, uint128[] calldata addition, address user) external;

    function tokenOfOwnerByIndex(address owner, uint index) external view returns (uint tokenId);

    function arrayUserPlayers(address _user) external view returns (TokensViewFront[] memory);

    function balanceOf(address owner) external view returns (uint balance);

    function ownerOf(uint tokenId) external view returns (address owner);

    function availableSEAmount(address _user) external view returns (uint128 amount);

    function totalSEAmount(address _user) external view returns (uint128 amount);


}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IOracle {
    function consult(
        address tokenIn,
        uint amountIn,
        address tokenOut
    ) external view returns (uint amountOut);
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

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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