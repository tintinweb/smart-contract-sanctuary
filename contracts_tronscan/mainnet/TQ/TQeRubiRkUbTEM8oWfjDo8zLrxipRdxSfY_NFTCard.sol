//SourceUnit: Context.sol

pragma solidity ^0.5.8;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

//SourceUnit: Counters.sol

pragma solidity ^0.5.8;

import "./SafeMath.sol";

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the {SafeMath}
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library Counters {
    using SafeMath for uint256;

    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

//SourceUnit: IERC20.sol

pragma solidity ^0.5.8;

/**
 * @title TRC20 interface
 */
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

//SourceUnit: NFTCard.sol

pragma solidity ^0.5.8;

import "./SafeMath.sol";
import './IERC20.sol';
import './TransferHelper.sol';
import "./WhitelistAdminRole.sol";
import "./Ownable.sol";

contract NFTCard is Ownable, WhitelistAdminRole {
    using SafeMath for uint256;

    enum TokenType {
        NONE,
        LIU,
        GUAN,
        ZHANG,
        MULAN,
        GUIYING,
        LIHUA,
        LOYALTY,
        WOMAN,
        ALLIAN
    }

    address public bt;
    address public bee;

    mapping(address => uint256) public btBalances;
    mapping(address => uint256) public beeBalances;

    mapping(address => uint256) public btRewards;
    mapping(address => uint256) public beeRewards;

    mapping (address => mapping(uint256 => uint256)) public cards;

    address public sysBurnPool = 0x41329Daa6f0F475155a380A027a079CE9682b2dA;

    uint256 public MINT_COST_BT = 1 * (10 ** 18);
    uint256 public MINT_COST_BEE = 1 * (10 ** 18);

    uint256 public sysLoyaltyRewardBT = 7 * (10 ** 18);
    uint256 public sysWomanRewardBEE = 7 * (10 ** 18);
    uint256 public sysAllianReward = 8 * (10 ** 18);
    uint256 public sysAllian3Reward = 28 * (10 ** 18);
    uint256 public sysAllian5Reward = 48 * (10 ** 18);
    uint256 public sysAllian10Reward = 108 * (10 ** 18);
    uint256 public sysAllian20Reward = 238 * (10 ** 18);
    uint256 public sysAllian30Reward = 420 * (10 ** 18);

    // total burned token
    uint256 public totalBTBurned;
    uint256 public totalBEEBurned;

    // init BT and BEE token address
    constructor(address _bt, address _bee) public {
        bt = _bt;
        bee = _bee;
    }

    function removeWhitelistAdmin(address account) public onlyOwner {
        _removeWhitelistAdmin(account);
    }

    function depositBT(uint256 amount) public {
        TransferHelper.safeTransferFrom(bt, msg.sender, address(this), amount);
        btBalances[msg.sender] = btBalances[msg.sender].add(amount);
    }

    function withdrawBT(uint256 amount) public {
        require(btBalances[msg.sender] >= amount, "amount not good");

        btBalances[msg.sender] = btBalances[msg.sender].sub(amount);
        TransferHelper.safeTransfer(bt, msg.sender, amount);
    }

    function depositBEE(uint256 amount) public {
        TransferHelper.safeTransferFrom(bee, msg.sender, address(this), amount);
        beeBalances[msg.sender] = beeBalances[msg.sender].add(amount);
    }

    function withdrawBEE(uint256 amount) public {
        require(beeBalances[msg.sender] >= amount, "amount not good");

        beeBalances[msg.sender] = beeBalances[msg.sender].sub(amount);
        TransferHelper.safeTransfer(bee, msg.sender, amount);
    }

    function getTokens(address owner) public view returns (uint256[] memory) {
        uint256[] memory tokenCounts = new uint256[](10);
        for (uint256 i = 0; i < 10; i++) {
            tokenCounts[i] = cards[owner][i];
        }
        return tokenCounts;
    }

    function canMintLoyalty(address owner) public view returns (bool) {
        uint256 liu = cards[owner][uint256(TokenType.LIU)];
        uint256 guan = cards[owner][uint256(TokenType.GUAN)];
        uint256 zhang = cards[owner][uint256(TokenType.ZHANG)];

        return (liu > 0) && (guan > 0) && (zhang > 0);
    }

    function canMintWoman(address owner) public view returns (bool) {
        uint256 m = cards[owner][uint256(TokenType.MULAN)];
        uint256 g = cards[owner][uint256(TokenType.GUIYING)];
        uint256 l = cards[owner][uint256(TokenType.LIHUA)];

        return (m > 0) && (g > 0) && (l > 0);
    }

    function canMintAllian(address to) public view returns (bool) {
        uint256 loyalty = cards[to][uint256(TokenType.LOYALTY)];
        uint256 woman = cards[to][uint256(TokenType.WOMAN)];

        return (loyalty > 0) && (woman > 0);
    }

    // mint hero, for type 1 - 6
    function mintHero(uint256 tokenType, address to) public onlyWhitelistAdmin {
        require(tokenType < uint256(TokenType.LOYALTY) && tokenType > uint256(TokenType.NONE), "tokenType not good");

        if (tokenType <= uint256(TokenType.ZHANG)) {
            // consume 1 BT
            btBalances[to] = btBalances[to].sub(MINT_COST_BT);
            TransferHelper.safeTransfer(bt, sysBurnPool, MINT_COST_BT);
            totalBTBurned = totalBTBurned.add(MINT_COST_BT);
        } else {
            // consume 1 BEE
            beeBalances[to] = beeBalances[to].sub(MINT_COST_BEE);
            TransferHelper.safeTransfer(bee, sysBurnPool, MINT_COST_BEE);
            totalBEEBurned = totalBEEBurned.add(MINT_COST_BT);
        }

        // update card count
        cards[to][tokenType] = cards[to][tokenType].add(1);
    }

    function mintLoyalty() public {
        address sender = msg.sender;
        require(canMintLoyalty(sender), "can't mint loyalty");

        // burn
        cards[sender][uint256(TokenType.LIU)] = 0;
        cards[sender][uint256(TokenType.GUAN)] = 0;
        cards[sender][uint256(TokenType.ZHANG)] = 0;

        // mint
        cards[sender][uint256(TokenType.LOYALTY)] = cards[sender][uint256(TokenType.LOYALTY)].add(1);
    }

    function mintWoman() public {
        address sender = msg.sender;
        require(canMintWoman(sender), "can't mint woman");

        // burn
        cards[sender][uint256(TokenType.MULAN)] = 0;
        cards[sender][uint256(TokenType.GUIYING)] = 0;
        cards[sender][uint256(TokenType.LIHUA)] = 0;

        // mint
        cards[sender][uint256(TokenType.WOMAN)] = cards[sender][uint256(TokenType.WOMAN)].add(1);
    }

    // Hero alliance
    function mintAllian() public {
        address sender = msg.sender;

        // check
        require(canMintAllian(sender), "can't mint allian");

        // burn
        cards[sender][uint256(TokenType.LOYALTY)] = cards[sender][uint256(TokenType.LOYALTY)].sub(1);
        cards[sender][uint256(TokenType.WOMAN)] = cards[sender][uint256(TokenType.WOMAN)].sub(1);

        // mint
        cards[sender][uint256(TokenType.ALLIAN)] = cards[sender][uint256(TokenType.ALLIAN)].add(1);
    }

    function burn(uint256 tokenType, uint256 num) public {
        address sender = msg.sender;
        cards[sender][tokenType] = cards[sender][tokenType].sub(num);

        if (tokenType == uint256(TokenType.LOYALTY)) {
            getLoyaltyReward(sender, num);
        } else if (tokenType == uint256(TokenType.WOMAN)) {
            getWomanReward(sender, num);
        } else if (tokenType == uint256(TokenType.ALLIAN)) {
            getAllianReward(sender, num);
        }
    }

    function getLoyaltyReward(address usr, uint256 num) internal {
        uint256 reward = sysLoyaltyRewardBT.mul(num);
        btRewards[usr] = btRewards[usr].add(reward);
        TransferHelper.safeTransfer(bt, usr, reward);
    }

    function getWomanReward(address usr, uint256 num) internal {
        uint256 reward = sysWomanRewardBEE.mul(num);
        beeRewards[usr] = beeRewards[usr].add(reward);
        TransferHelper.safeTransfer(bee, usr, reward);
    }

    function getAllianReward(address usr, uint256 num) internal {
        uint256 reward;
        if (num >= 30) {
            reward = sysAllian30Reward;
        } else if (num >= 20) {
            reward = sysAllian20Reward;
        } else if (num >= 10) {
            reward = sysAllian10Reward;
        } else if (num >= 5) {
            reward = sysAllian5Reward;
        } else if (num >= 3) {
            reward = sysAllian3Reward;
        } else if (num >= 1) {
            reward = sysAllianReward;
        }

        btRewards[usr] = btRewards[usr].add(reward);
        beeRewards[usr] = beeRewards[usr].add(reward);

        TransferHelper.safeTransfer(bt, usr, reward);
        TransferHelper.safeTransfer(bee, usr, reward);
    }

    function queryStats(address owner) public view
        returns
        (uint256 btRewardsx, uint256 beeRewardsx,
            uint256 sysLoyaltyRewardBTx, uint256 sysWomanRewardBEEx, uint256 sysAllianRewardx,
            uint256 sysAllian3Rewardx, uint256 sysAllian5Rewardx, uint256 sysAllian10Rewardx,
            uint256 sysAllian20Rewardx, uint256 sysAllian30Rewardx,
            bool canMintLoyaltyx, bool canMintWomanx, bool canMintAllianx)
    {
        btRewardsx = btRewards[owner];
        beeRewardsx = beeRewards[owner];
        sysLoyaltyRewardBTx = sysLoyaltyRewardBT;
        sysWomanRewardBEEx = sysWomanRewardBEE;
        sysAllianRewardx = sysAllianReward;
        sysAllian3Rewardx = sysAllian3Reward;
        sysAllian5Rewardx = sysAllian5Reward;
        sysAllian10Rewardx = sysAllian10Reward;
        sysAllian20Rewardx = sysAllian20Reward;
        sysAllian30Rewardx = sysAllian30Reward;
        canMintLoyaltyx = canMintLoyalty(owner);
        canMintWomanx = canMintWoman(owner);
        canMintAllianx = canMintAllian(owner);
    }

    //////////////////////////////////////////////////////
    // admin operations
    function setLoyaltyRewardBT(uint256 value) public onlyWhitelistAdmin {
        sysLoyaltyRewardBT = value;
    }

    function setWomanRewardBEE(uint256 value) public onlyWhitelistAdmin {
        sysWomanRewardBEE = value;
    }

    function setAllianReward(uint256 value) public onlyWhitelistAdmin {
        sysAllianReward = value;
    }

    function setAllian3Reward(uint256 value) public onlyWhitelistAdmin {
        sysAllian3Reward = value;
    }

    function setAllian5Reward(uint256 value) public onlyWhitelistAdmin {
        sysAllian5Reward = value;
    }

    function setAllian10Reward(uint256 value) public onlyWhitelistAdmin {
        sysAllian10Reward = value;
    }

    function setAllian20Reward(uint256 value) public onlyWhitelistAdmin {
        sysAllian20Reward = value;
    }

    function setAllian30Reward(uint256 value) public onlyWhitelistAdmin {
        sysAllian30Reward = value;
    }

    function setBEE(address _bee) public onlyOwner {
        bee = _bee;
    }

    function setBT(address _bt) public onlyOwner {
        bt = _bt;
    }

    function setBurnPool(address account) public onlyOwner {
        sysBurnPool = account;
    }
    //////////////////////////////////////////////////////
}


//SourceUnit: Ownable.sol

pragma solidity ^0.5.8;

import "./Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


//SourceUnit: Roles.sol

pragma solidity ^0.5.8;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}


//SourceUnit: SafeMath.sol

pragma solidity ^0.5.8;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


//SourceUnit: StringLibrary.sol

pragma solidity ^0.5.8;

import "./UintLibrary.sol";

library StringLibrary {
    using UintLibrary for uint256;

    function append(string memory _a, string memory _b) internal pure returns (string memory) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory bab = new bytes(_ba.length + _bb.length);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) bab[k++] = _ba[i];
        for (uint i = 0; i < _bb.length; i++) bab[k++] = _bb[i];
        return string(bab);
    }

    function append(string memory _a, string memory _b, string memory _c) internal pure returns (string memory) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory bbb = new bytes(_ba.length + _bb.length + _bc.length);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) bbb[k++] = _ba[i];
        for (uint i = 0; i < _bb.length; i++) bbb[k++] = _bb[i];
        for (uint i = 0; i < _bc.length; i++) bbb[k++] = _bc[i];
        return string(bbb);
    }

    function recover(string memory message, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        bytes memory msgBytes = bytes(message);
        bytes memory fullMessage = concat(
            bytes("\x19Ethereum Signed Message:\n"),
            bytes(msgBytes.length.toString()),
            msgBytes,
            new bytes(0), new bytes(0), new bytes(0), new bytes(0)
        );
        return ecrecover(keccak256(fullMessage), v, r, s);
    }

    function concat(bytes memory _ba, bytes memory _bb, bytes memory _bc, bytes memory _bd, bytes memory _be, bytes memory _bf, bytes memory _bg) internal pure returns (bytes memory) {
        bytes memory resultBytes = new bytes(_ba.length + _bb.length + _bc.length + _bd.length + _be.length + _bf.length + _bg.length);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) resultBytes[k++] = _ba[i];
        for (uint i = 0; i < _bb.length; i++) resultBytes[k++] = _bb[i];
        for (uint i = 0; i < _bc.length; i++) resultBytes[k++] = _bc[i];
        for (uint i = 0; i < _bd.length; i++) resultBytes[k++] = _bd[i];
        for (uint i = 0; i < _be.length; i++) resultBytes[k++] = _be[i];
        for (uint i = 0; i < _bf.length; i++) resultBytes[k++] = _bf[i];
        for (uint i = 0; i < _bg.length; i++) resultBytes[k++] = _bg[i];
        return resultBytes;
    }
}


//SourceUnit: TransferHelper.sol

pragma solidity ^0.5.8;

// helper methods for interacting with TRC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, ) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success, 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, ) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success, 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferTRX(address to, uint value) internal {
        (bool success,) = to.call.value(value)(new bytes(0));
        require(success, 'TransferHelper: TRX_TRANSFER_FAILED');
    }
}

//SourceUnit: UintLibrary.sol

pragma solidity ^0.5.8;

library UintLibrary {
    function toString(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }
}


//SourceUnit: WhitelistAdminRole.sol

pragma solidity ^0.5.8;

import "./Context.sol";
import "./Roles.sol";

/**
 * @title WhitelistAdminRole
 * @dev WhitelistAdmins are responsible for assigning and removing Whitelisted accounts.
 */
contract WhitelistAdminRole is Context {
    using Roles for Roles.Role;

    event WhitelistAdminAdded(address indexed account);
    event WhitelistAdminRemoved(address indexed account);

    Roles.Role private _whitelistAdmins;

    constructor () internal {
        _addWhitelistAdmin(_msgSender());
    }

    modifier onlyWhitelistAdmin() {
        require(isWhitelistAdmin(_msgSender()), "WhitelistAdminRole: caller does not have the WhitelistAdmin role");
        _;
    }

    function isWhitelistAdmin(address account) public view returns (bool) {
        return _whitelistAdmins.has(account);
    }

    function addWhitelistAdmin(address account) public onlyWhitelistAdmin {
        _addWhitelistAdmin(account);
    }

    function renounceWhitelistAdmin() public {
        _removeWhitelistAdmin(_msgSender());
    }

    function _addWhitelistAdmin(address account) internal {
        _whitelistAdmins.add(account);
        emit WhitelistAdminAdded(account);
    }

    function _removeWhitelistAdmin(address account) internal {
        _whitelistAdmins.remove(account);
        emit WhitelistAdminRemoved(account);
    }
}