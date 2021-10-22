/**
 *Submitted for verification at BscScan.com on 2021-10-22
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



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

// File: @openzeppelin/contracts/utils/math/SafeMath.sol



pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol



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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol



pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol



pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/security/Pausable.sol



pragma solidity ^0.8.0;


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

// File: GLAHeroStaking.sol

//  SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;







contract GLAHeroStaking is Ownable {
    using SafeMath for uint256;
    struct Plan {
        uint256 time;
        uint256 rewardRate;
    }

    struct HeroStakingData {
        uint256 heroId;
        address owner;
        uint256 plan;
        uint256 start;
        uint256 finish;
        uint256 rewardEstimate;
    }
    uint256 public constant BASE_REWARD = 128 * 10**18;
    uint256 constant STEP_TIME = 1 days;
    address public mintOperator;
    address public gameManager;
    mapping(uint256 => mapping(uint256 => uint256))
        public maxHeroStakedInPlanByRare;
    mapping(uint256 => mapping(uint256 => uint256))
        public currentHeroStakedInPlanByRare;
    mapping(address => uint256) public amountHeroStaking;
    mapping(address => mapping(uint256 => uint256)) listHero; //address => index => heroId
    mapping(uint256 => HeroStakingData) public heroesStakingData; //heroId => Hero staking data
    mapping(uint256 => uint256) stakedHeroIndex;
    mapping(uint256 => Plan) public plans;
    
    event StakeHero(address user, uint256[] heroIds, uint256 plan);
    event Withdraw(address user, uint256 heroId, uint256 glaAmount);

    constructor(address _gameManager, address _mintOperator) {
        plans[0] = Plan(30, 45);
        plans[1] = Plan(60, 110);
        plans[2] = Plan(90, 180);
        mintOperator = _mintOperator;
        gameManager = _gameManager;
        maxHeroStakedInPlanByRare[0][1] = 600;
        maxHeroStakedInPlanByRare[0][2] = 300;
        maxHeroStakedInPlanByRare[0][3] = 250;
        maxHeroStakedInPlanByRare[0][4] = 200;
        maxHeroStakedInPlanByRare[0][5] = 100;
        maxHeroStakedInPlanByRare[0][6] = 50;

        maxHeroStakedInPlanByRare[1][1] = 400;
        maxHeroStakedInPlanByRare[1][2] = 200;
        maxHeroStakedInPlanByRare[1][3] = 150;
        maxHeroStakedInPlanByRare[1][4] = 100;
        maxHeroStakedInPlanByRare[1][5] = 100;
        maxHeroStakedInPlanByRare[1][6] = 50;

        maxHeroStakedInPlanByRare[2][1] = 200;
        maxHeroStakedInPlanByRare[2][2] = 100;
        maxHeroStakedInPlanByRare[2][3] = 75;
        maxHeroStakedInPlanByRare[2][4] = 50;
        maxHeroStakedInPlanByRare[2][5] = 50;
        maxHeroStakedInPlanByRare[2][6] = 25;
    }

    function stakeHero(uint256[] memory heroIds, uint256 plan) public {
        uint256 totalRewardEstimate;
        for(uint256 i = 0; i < heroIds.length; i++){
            address glaHeroAddress = IGameManager(gameManager).getContract("GLAHeroNFT");
            address owner = IGLAHeroNFT(glaHeroAddress).ownerOf(heroIds[i]);
            require(
                owner == msg.sender,
                "GLAHeroStaking: Stake hero that is not own"
            );
            uint8 rare = IGLAHeroNFT(glaHeroAddress).getHeroRarity(heroIds[i]);
            require(
                currentHeroStakedInPlanByRare[plan][rare] <
                    maxHeroStakedInPlanByRare[plan][rare],
                "This plan is full!"
            );
            IGLAHeroNFT(glaHeroAddress).transferFrom(
                owner,
                address(this),
                heroIds[i]
            );
            uint256 rewardEstimate;
            rewardEstimate = plans[plan].rewardRate.mul(rare).mul(BASE_REWARD);
            totalRewardEstimate = totalRewardEstimate.add(rewardEstimate);
            heroesStakingData[heroIds[i]] = HeroStakingData(
                heroIds[i],
                owner,
                plan,
                block.timestamp,
                block.timestamp.add(plans[plan].time.mul(STEP_TIME)),
                rewardEstimate
            );

            stakedHeroIndex[heroIds[i]] = amountHeroStaking[owner];
            listHero[owner][amountHeroStaking[owner]] = heroIds[i];
            amountHeroStaking[owner] += 1;
        }
        IMintOperator(mintOperator).mint(address(this), totalRewardEstimate);
        emit StakeHero(msg.sender, heroIds, plan);

    }

    function withdraw(uint256 heroId) public {
        address glaHeroAddress = IGameManager(gameManager).getContract("GLAHeroNFT");
        address glaTokenAddress = IGameManager(gameManager).getContract("GLAToken");
        //now >= start time + plantime * 1 day
        require(
            block.timestamp >=
                heroesStakingData[heroId].start.add(
                    plans[heroesStakingData[heroId].plan].time.mul(STEP_TIME)
                ),
            "Please wait for hero to complete the mission"
        );
        require(
            heroesStakingData[heroId].owner == msg.sender,
            "GLAHeroStaking: Withdraw hero that is not own "
        );
        IGLAHeroNFT(glaHeroAddress).transferFrom(
            address(this),
            msg.sender,
            heroId
        );
        IERC20(glaTokenAddress).transfer(
            msg.sender,
            heroesStakingData[heroId].rewardEstimate
        );
        emit Withdraw(msg.sender, heroId, heroesStakingData[heroId].rewardEstimate);
        _removeHero(msg.sender, heroId);
        
    }
    
    function setMintOperator(address _mintOperator) public onlyOwner{
        mintOperator = _mintOperator;
    }
    
    function setGameManager(address _gameManager) public onlyOwner{
        gameManager = _gameManager;
    }

    function listHeroIdOf(address owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory result = new uint256[](amountHeroStaking[owner]);
        for (uint256 i = 0; i < amountHeroStaking[msg.sender]; i++) {
            result[i] = listHero[owner][i];
        }
        return result;
    }

    function listHeroData(address owner)
        public
        view
        returns (HeroStakingData[] memory)
    {
        HeroStakingData[] memory result = new HeroStakingData[](
            amountHeroStaking[owner]
        );
        for (uint256 i = 0; i < amountHeroStaking[owner]; i++) {
            result[i] = heroesStakingData[listHero[owner][i]];
        }
        return result;
    }

    function heroStakingInfo(uint256 heroId)
        public
        view
        returns (
            address owner,
            uint256 plan,
            uint256 start,
            uint256 finish,
            uint256 reward
        )
    {
        owner = heroesStakingData[heroId].owner;
        plan = heroesStakingData[heroId].plan;
        start = heroesStakingData[heroId].start;
        finish = heroesStakingData[heroId].start.add(
            plans[plan].time.mul(STEP_TIME)
        );
        reward = heroesStakingData[heroId].rewardEstimate;
    }
    
    function emergencyWithdraw(uint256 amount) public onlyOwner{
        address glaHeroAddress = IGameManager(gameManager).getContract("GLAHeroNFT");
        address glaTokenAddress = IGameManager(gameManager).getContract("GLAToken");
        uint256 heroBalance = IGLAHeroNFT(glaHeroAddress).balanceOf(address(this));
        uint256[] memory heroIds = new uint256[](heroBalance);
        heroIds = IGLAHeroNFT(glaHeroAddress).getListHeroIdsOf(address(this));
        amount = amount > heroBalance ? heroBalance : amount;
        for(uint256 i; i < amount; i++){
            IGLAHeroNFT(glaHeroAddress).transferFrom(address(this), msg.sender, heroIds[i]);
        }
        uint256 glaBalance = IERC20(glaTokenAddress).balanceOf(address(this));
        if(glaBalance>0){
            IERC20(glaTokenAddress).transfer(msg.sender, glaBalance);
        }

    }

    function _removeHero(address owner, uint256 heroId) internal {
        uint256 lastTokenIndex = amountHeroStaking[owner] - 1;
        uint256 tokenIndex = stakedHeroIndex[heroId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = listHero[owner][lastTokenIndex];

            listHero[owner][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            stakedHeroIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }
        // This also deletes the contents at the last position of the array
        delete stakedHeroIndex[heroId];
        delete listHero[owner][lastTokenIndex];
        delete heroesStakingData[heroId];
        amountHeroStaking[owner] -= 1;
    }
}

interface IGLAHeroNFT is IERC721, IERC721Enumerable {
    function getHeroRarity(uint256 heroId_) external returns (uint8);
    function getListHeroIdsOf(address owner) external view returns(uint256[] memory);
}

interface IMintOperator {
    function mint(address account, uint256 amount) external;
}

interface IGameManager {
    function getContract(string memory contract_)
        external
        view
        returns (address);
}