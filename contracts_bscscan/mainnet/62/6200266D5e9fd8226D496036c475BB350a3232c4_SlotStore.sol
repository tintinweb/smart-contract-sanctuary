// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IMiningPool {
    function totalTokens() external view returns (uint256);
    function roundTokens(uint256 numberOfDays) external view returns (uint256);
    function lowerRoundTokens(uint256 numberOfDays) external view returns (uint256);
}

interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

contract SlotStore is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    address public constant USDT_BNB_PAIR = 0x16b9a82891338f9bA80E2D6970FddA79D1eb0daE;
    address public constant BNB_PK_PAIR = 0xCC98892f067559fd0316C65E984d3E93B682252E;

    address public immutable token;
    address public immutable pokerToken1;
    address public immutable poker;

    address private _fundReceiver;

    IMiningPool private _miningPool;

    uint256 private _opening;
    uint256 private _price;
    uint256 private _totalSales;
    uint256 private _startRound;
    uint256 private _slotSubstitutionCount;

    struct Team {
        address owner;
        string name;
        uint256 deposits;
        uint256 slots;
        uint256 minPower;
    }

    Team[] private _teams;

    mapping(address => mapping(uint256 => uint256)) private _teamRoundDeposits;
    mapping(address => mapping(uint256 => uint256)) private _teamRoundSlots;

    mapping(string => uint256) private _teamIndexes;

    mapping(address => uint256) private _ownedTeams;

    mapping(uint256 => uint256) private _roundDeposits;

    mapping(uint256 => uint256) private _roundSales;

    mapping(address => uint256) private _slotCount;

    mapping(address => uint256) private _slotBuyCount;

    event Registered(address indexed account, string name);
    event Deposited(address indexed account, uint256 amount);
    event Withdrawn(address indexed account, uint256 amount);
    event Purchased(address indexed account, uint256 amount);

    event SetMinPowered(address indexed account, uint256 amount);
    event Substitutioned(address indexed account, uint256 amount);

    constructor(address token_, address poker_, address poker1_) {
        token = token_;
        poker = poker_;
        pokerToken1 = poker1_;

        _fundReceiver = _msgSender();

        _price = 50 ether;

        _slotSubstitutionCount = 20;

        _opening = block.timestamp;
    }

    function fundReceiver() public view returns (address) {
        return _fundReceiver;
    }

    function setFundReceiver(address value) external onlyOwner {
        _fundReceiver = value;
    }

    function slotSubstitutionCount() public view returns (uint256) {
        return _slotSubstitutionCount;
    }

    function miningPool() public view returns (IMiningPool) {
        return _miningPool;
    }

    function setMiningPool(address value) external onlyOwner {
        _miningPool = IMiningPool(value);
    }

    function setStartRound() external onlyOwner {
        _startRound = 1;
        _opening = block.timestamp;
    }

    function opening() public view returns (uint256) {
        return _opening;
    }

    function today() public view returns (uint256) {
        return (block.timestamp - _opening) / 1 days + 1;
    }

    function period() public view returns (uint256) {
        uint256 numberOfPeriod = today() % 5;
        return numberOfPeriod > 0 ? numberOfPeriod : 5;
    }

    function round() public view returns (uint256) {
        uint256 contractRound;
        if (_startRound > 0) {
            contractRound = (block.timestamp - _opening) / (5 * 1 days) + 1;
        } else {
            contractRound = 0;
        }
        return contractRound;
    }

    function price() public view returns (uint256) {
        uint256 weiAmount = calculateToken0Price(USDT_BNB_PAIR, _price);
        return calculateToken1Price(BNB_PK_PAIR, weiAmount);
    }

    function setPrice(uint256 value) public onlyOwner {
        require(value >= 1e18, "Invalid value");
        _price = value;
    }

    function calculateToken0Price(address pairAddress, uint256 amount) public view returns(uint256) {
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        return amount * reserve1 / reserve0;
    }

    function calculateToken1Price(address pairAddress, uint256 amount) public view returns(uint256) {
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        return amount * reserve0 / reserve1;
    }

    function setSubstitutionCount(uint256 value) external onlyOwner {
        require(value > 0, "Invalid value");
        _slotSubstitutionCount = value;
    }

    function totalSales() public view returns (uint256) {
        return _totalSales;
    }

    function roundSales(uint256 numberOfRound) public view returns (uint256) {
        return _roundSales[numberOfRound];
    }

    function maxSupply(address account) public view returns (uint256) {
        return _slotCount[account];
    }

    function setTeamName(string memory name) external {
        address account = _msgSender();

        uint256 index = _ownedTeams[account];
        require(index > 0, "User can't operation team");

        Team storage teamData = _teams[index - 1];

        _teamIndexes[name] = _teamIndexes[teamData.name];

        teamData.name = name;
    }

    function teams(uint256 index) public view returns (address owner, string memory name, uint256 deposits, uint256 slots, uint256 minPower) {
        require(index < _teams.length, "Invalid index");

        Team memory team = _teams[index];
        return (team.owner, team.name, team.deposits, team.slots, team.minPower);
    }

    function teamsByIndex(uint256 startIndex, uint256 endIndex) public view returns (Team[] memory) {
        if (endIndex == 0) {
            endIndex = totalTeams();
        }
        require(startIndex < endIndex, "Invalid index");

        Team[] memory result = new Team[](endIndex - startIndex);
        uint256 resultLength = result.length;
        uint256 index = startIndex;
        for (uint256 i = 0; i < resultLength; i++) {
            result[i].owner = _teams[index].owner;
            result[i].name = _teams[index].name;
            result[i].deposits = _teams[index].deposits;
            result[i].slots = _teams[index].slots;
            result[i].minPower = _teams[index].minPower;
            index++;
        }
        return result;
    }

    function totalTeams() public view returns (uint256) {
        return _teams.length;
    }

    function teamIndexes(string calldata name) public view returns (uint256) {
        return _teamIndexes[name];
    }

    function ownedTeams(address account) public view returns (uint256) {
        return _ownedTeams[account];
    }

    function teamRoundDeposits(address account, uint256 numberOfRound) public view returns (uint256) {
        return _teamRoundDeposits[account][numberOfRound];
    }

    function teamRoundSlots(address account, uint256 numberOfRound) public view returns (uint256) {
        return _teamRoundSlots[account][numberOfRound];
    }

    function roundDeposits(uint256 numberOfRound) public view returns (uint256) {
        return _roundDeposits[numberOfRound];
    }

    function currentSupply() public view returns (uint256) {
        uint256 numberOfRound = round();
        if (numberOfRound == 0) {
            return 10000000;
        } else if (numberOfRound % 2 == 1) {
            return 0;
        }

        uint256 lower = _miningPool.lowerRoundTokens(numberOfRound);
        uint256 lastRoundSales = _roundSales[numberOfRound - 2];
        uint256 percentage = ((_miningPool.totalTokens() + lower - _miningPool.roundTokens(numberOfRound)) * 100) / ((_totalSales - _roundSales[numberOfRound] - (lastRoundSales / 2)) * 5);

        if (percentage >= 40 && lastRoundSales == 0) {
            lastRoundSales = 2000;
        }

        if (percentage >= 80) {
            return (lastRoundSales * 120) / 100;
        } else if (percentage >= 60) {
            return (lastRoundSales * 80) / 100;
        } else if (percentage >= 40) {
            return (lastRoundSales * 40) / 100;
        }

        return 0;
    }

    function getCurrentSupplyParam() public view returns (uint256, uint256) {
        uint256 numberOfRound = round();
        uint256 lower = _miningPool.lowerRoundTokens(numberOfRound);
        uint256 lastRoundSales = _roundSales[numberOfRound - 2];
        uint256 cardNum = _miningPool.totalTokens() + lower - _miningPool.roundTokens(numberOfRound);
        uint256 cardStoreNum = (_totalSales - _roundSales[numberOfRound] - (lastRoundSales / 2)) * 5;
        return (cardNum, cardStoreNum);
    }

    function preOrder(uint256 amount, string calldata name) external nonReentrant {
        uint256 numberOfRound = round();
        require(numberOfRound % 2 == 0 && period() <= 3, "Pre-order has not yet started");

        address account = _msgSender();

        Team storage team;

        uint256 teamIndex = _ownedTeams[account];
        if (teamIndex == 0) {
            require(bytes(name).length > 0, "Name cannot be empty");
            require(_teamIndexes[name] == 0, "this team already exists");

            team = _teams.push();
            team.owner = account;
            team.name = name;

            _teamIndexes[name] = _teams.length;
            _ownedTeams[account] = _teams.length;

            emit Registered(account, name);
        } else {
            team = _teams[teamIndex - 1];
        }

        team.deposits += amount;

        _teamRoundDeposits[team.owner][numberOfRound] += amount;

        _roundDeposits[numberOfRound] += amount;

        IERC20(token).safeTransferFrom(account, address(this), amount);

        emit Deposited(account, amount);
    }

    function withdraw() external nonReentrant {
        uint256 remainder = round() % 2;
        require(remainder > 0 || (remainder == 0 && period() > 3), "Withdrawal is not allowed at the current time");

        address account = _msgSender();

        uint256 teamIndex = _ownedTeams[account];
        require(teamIndex > 0, "Do not own team");

        Team storage team = _teams[teamIndex - 1];

        uint256 payment = team.deposits;
        if (payment > 0) {
            team.deposits = 0;

            IERC20(token).safeTransfer(account, payment);
        }

        emit Withdrawn(account, payment);
    }

    function zeroPurchase(uint256 amount, string calldata name) external nonReentrant {
        uint256 numberOfRound = round();

        require(numberOfRound == 0, "Not yet on sale");
        require((_roundSales[numberOfRound] + amount) <= currentSupply(), "Insufficient supply");

        address account = _msgSender();

        require(_slotBuyCount[account] + amount <= _slotCount[account], "Insufficient user supply");

        uint256 payment = price() * amount;
        IERC20(token).safeTransferFrom(account, address(this), payment);
        IERC20(token).safeTransfer(_fundReceiver, payment);

        uint256 teamIndex = _ownedTeams[account];

        Team storage team;
        if (teamIndex == 0) {
            require(bytes(name).length > 0, "Name cannot be empty");
            require(_teamIndexes[name] == 0, "this team already exists");

            team = _teams.push();
            team.owner = account;
            team.name = name;

            _teamIndexes[name] = _teams.length;
            _ownedTeams[account] = _teams.length;

            emit Registered(account, name);
        } else {
            team = _teams[teamIndex - 1];
        }

        team.slots += amount;
        team.minPower = 100;

        _teamRoundSlots[team.owner][numberOfRound] += amount;

        _roundSales[numberOfRound] += amount;

        _slotBuyCount[account] += amount;

        _totalSales += amount;

        emit Purchased(account, amount);
    }

    function purchase(uint256 amount) external nonReentrant {
        uint256 numberOfRound = round();
        uint256 numberOfPeriod = period();
        require(numberOfRound % 2 == 0 && numberOfPeriod > 3, "Not yet on sale");
        require((_roundSales[numberOfRound] + amount) <= currentSupply(), "Insufficient supply");

        address account = _msgSender();

        uint256 payment = price() * amount;
        IERC20(token).safeTransferFrom(account, address(this), payment);
        IERC20(token).safeTransfer(_fundReceiver, payment);

        uint256 teamIndex = _ownedTeams[account];
        require(teamIndex > 0, "Not own team");

        Team storage team = _teams[teamIndex - 1];
        team.slots += amount;

        if (numberOfPeriod == 4) {
            uint256 canBePurchased = (_teamRoundDeposits[team.owner][numberOfRound] * currentSupply()) / _roundDeposits[numberOfRound];
            require(_teamRoundSlots[team.owner][numberOfRound] + amount <= canBePurchased, "Purchase limit exceeded");
        }

        team.minPower = 100;

        _teamRoundSlots[team.owner][numberOfRound] += amount;

        _roundSales[numberOfRound] += amount;

        _totalSales += amount;

        emit Purchased(account, amount);
    }

    function setMinPower(uint256 amount) external {
        address account = _msgSender();

        uint256 teamIndex = _ownedTeams[account];
        require(teamIndex > 0, "Not own team");

        _teams[teamIndex - 1].minPower = amount;

        emit SetMinPowered(account, amount);
    }

    function substitution(uint256 amount) external nonReentrant {
        require(amount > 0, "The amount is less than 1");

        address account = _msgSender();

        _slotCount[account] += (amount / 1e18) * _slotSubstitutionCount;

        IERC20(pokerToken1).safeTransferFrom(account, address(this), amount);
        IERC20(pokerToken1).safeTransfer(_fundReceiver, amount);

        emit Substitutioned(account, amount);
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

/*
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

