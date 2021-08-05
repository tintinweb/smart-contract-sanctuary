/**
 *Submitted for verification at Etherscan.io on 2021-04-27
*/

// File: @openzeppelin/contracts/GSN/Context.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: @openzeppelin/contracts/math/SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
     *
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
     *
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
     *
     * - Subtraction cannot overflow.
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// File: @openzeppelin/contracts/utils/ReentrancyGuard.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
contract ReentrancyGuard {
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

    constructor () internal {
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

// File: contracts/IAlohaNFT.sol

pragma solidity ^0.6.6;

interface IAlohaNFT {
    function awardItem(
        address wallet,
        uint256 tokenImage,
        uint256 tokenRarity,
        uint256 tokenBackground
    ) external returns (uint256);

    function transferFrom(address from, address to, uint256 tokenId) external;
    function tokenRarity(uint256 tokenId) external returns (uint256);
    function tokenImage(uint256 tokenId) external returns (uint256);
    function tokenBackground(uint256 tokenId) external returns (uint256);
}

// File: contracts/AlohaStaking.sol

pragma solidity 0.6.6;
pragma experimental ABIEncoderV2;






contract AlohaStakingV2 is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeMath for uint8;

    /* Events */
    event SettedPool(
        uint256 indexed alohaAmount,
        uint256 indexed erc20Amount,
        uint256 duration,
        uint256 rarity,
        uint256 date
    );
    event Staked(
        address indexed wallet,
        address indexed erc20Address,
        uint256 rarity,
        uint256 endDate,
        uint256 tokenImage,
        uint256 tokenBackground,
        uint256 alohaAmount,
        uint256 erc20Amount,
        uint256 date
    );
    event Withdrawal(
        address indexed wallet,
        address indexed erc20Address,
        uint256 rarity,
        uint256 originalAlohaAmount,
        uint256 originalErc20Amount,
        uint256 receivedAlohaAmount,
        uint256 receivedErc20Amount,
        uint256 erc721Id,
        uint256 date
    );
    event Transfered(
        address indexed wallet,
        address indexed erc20Address,
        uint256 amount,
        uint256 date
    );

    /* Vars */
    uint256 public fee;
    address public alohaERC20;
    address public alohaERC721;
    uint256 public backgrounds;
    address[] public feesDestinators;
    uint256[] public feesPercentages;

    struct Pool {
        uint256 alohaAmount;
        uint256 erc20Amount; // 0 when is not a PairPool
        uint256 duration;
        uint256 rarity;
    }
    struct Stake {
        uint256 endDate;
        uint256 tokenImage;
        uint256 tokenBackground;
        uint256 alohaAmount;
        uint256 erc20Amount;  // 0 when is not a PairPool
    }

    // image => rarity
    mapping (uint256 => uint256) public rewardsMap;
    // rarity => [image]
    mapping (uint256 => uint256[]) public rarityByImages;
    // rarity => totalImages
    mapping (uint256 => uint256) public rarityByImagesTotal;
    // image => rarity => limit
    mapping (uint256 => mapping(uint256 => uint256)) public limitByRarityAndImage;
    // image => rarity => totalTokens
    mapping (uint256 => mapping(uint256 => uint256)) public totalTokensByRarityAndImage;
    // erc20Address => rarity => Pool
    mapping (address => mapping(uint256 => Pool)) public poolsMap;
    // userAddress => erc20Address => rarity => Stake 
    mapping (address => mapping(address => mapping(uint256 => Stake))) public stakingsMap;
    // erc20Address => totalStaked 
    mapping (address => uint256) public totalStaked;

    /* Modifiers */
    modifier imageNotExists(uint256 _image) {
        require(
            !_existsReward(_image),
            "AlohaStaking: Image for reward already exists"
        );
        _;
    }
    modifier validRarity(uint256 _rarity) {
        require(
            _rarity >= 1 && _rarity <= 3,
            "AlohaStaking: Rarity must be 1, 2 or 3"
        );
        _;
    }
    modifier poolExists(address _erc20, uint256 _rarity) {
        require(
            _existsPool(_erc20, _rarity),
            "AlohaStaking: Pool for ERC20 Token and rarity not exists"
        );
        _;
    }
    modifier rarityAvailable(uint256 _rarity) {
        require(
            !(rarityByImagesTotal[_rarity] == 0),
            "AlohaStaking: Rarity not available"
        );
        _;
    }
    modifier addressNotInStake(address _userAddress, address _erc20, uint256 _rarity) {
        require(
            (stakingsMap[msg.sender][_erc20][_rarity].endDate == 0),
            "AlohaStaking: Address already stakes in this pool"
        );
        _;
    }
    modifier addressInStake(address _userAddress, address _erc20, uint256 _rarity) {
        require(
            !(stakingsMap[msg.sender][_erc20][_rarity].endDate == 0),
            "AlohaStaking: Address not stakes in this pool"
        );
        _;
    }
    modifier stakeEnded(address _userAddress, address _erc20, uint256 _rarity) {
        require(
            (_getTime() > stakingsMap[msg.sender][_erc20][_rarity].endDate),
            "AlohaStaking: Stake duration has not ended yet"
        );
        _;
    }

    /* Public Functions */
    constructor(
        address _alohaERC20,
        address _alohaERC721,
        uint256 _backgrounds,
        uint256 _fee
    ) public {
        require(address(_alohaERC20) != address(0)); 
        require(address(_alohaERC721) != address(0));

        alohaERC20 = _alohaERC20;
        alohaERC721 = _alohaERC721;
        backgrounds = _backgrounds;
        fee = _fee;
    }

    /**
    * @dev Stake ALOHA to get a random token of the selected rarity
    */
    function simpleStake(
        uint256 _tokenRarity
    )
        public
    {
        pairStake(alohaERC20, _tokenRarity);
    }

    /**
    * @dev Stake ALOHA/TOKEN to get a random token of the selected rarity
    */
    function pairStake(
        address _erc20Token,
        uint256 _tokenRarity
    )
        public
        rarityAvailable(_tokenRarity)
        poolExists(_erc20Token, _tokenRarity)
        addressNotInStake(msg.sender, _erc20Token, _tokenRarity)
    {
        uint256 randomImage = _getRandomImage(_tokenRarity);
        uint256 _endDate = _getTime() + poolsMap[_erc20Token][_tokenRarity].duration;
        uint256 randomBackground = _randomB(backgrounds);

        uint256 alohaAmount = poolsMap[_erc20Token][_tokenRarity].alohaAmount;
        uint256 erc20Amount = poolsMap[_erc20Token][_tokenRarity].erc20Amount;

        _transferStake(msg.sender, alohaERC20, alohaAmount);
        totalStaked[alohaERC20] += alohaAmount;
        
        if (_erc20Token != alohaERC20) {
            _transferStake(msg.sender, _erc20Token, erc20Amount);
            totalStaked[_erc20Token] += erc20Amount;
        }

        stakingsMap[msg.sender][_erc20Token][_tokenRarity] = Stake({
            endDate: _endDate,
            tokenImage: randomImage,
            tokenBackground: randomBackground,
            alohaAmount: alohaAmount,
            erc20Amount: erc20Amount
        });

        emit Staked(
            msg.sender,
            _erc20Token,
            _tokenRarity,
            _endDate,
            randomImage,
            randomBackground,
            alohaAmount,
            erc20Amount,
            _getTime()
        );
    }

    /**
    * @dev Withdraw ALOHA and claim your random NFT for the selected rarity
    */
    function simpleWithdraw(
        uint256 _tokenRarity
    )
        public
    {
        pairWithdraw(alohaERC20, _tokenRarity);
    }

    /**
    * @dev Withdraw ALOHA/TOKEN and claim your random NFT for the selected rarity
    */
    function pairWithdraw(
        address _erc20Token,
        uint256 _tokenRarity
    )
        public
        nonReentrant()
        addressInStake(msg.sender, _erc20Token, _tokenRarity)
        stakeEnded(msg.sender, _erc20Token, _tokenRarity)
    {
        _withdraw(_erc20Token, _tokenRarity, true);
    }

    /**
    * @dev Withdra ALOHA without generating your NFT. This can be done before release time is reached.
    */
    function forceSimpleWithdraw(
        uint256 _tokenRarity
    )
        public
    {
        forcePairWithdraw(alohaERC20, _tokenRarity);
    }

    /**
    * @dev Withdraw ALOHA/TOKEN without generating your NFT. This can be done before release time is reached.
    */
    function forcePairWithdraw(
        address _erc20Token,
        uint256 _tokenRarity
    )
        public
        nonReentrant()
        addressInStake(msg.sender, _erc20Token, _tokenRarity)
    {
        _withdraw(_erc20Token, _tokenRarity, false);
    }

    /**
    * @dev Returns how many fees we collected from withdraws of one token.
    */
    function getAcumulatedFees(address _erc20Token) public view returns (uint256) {
        uint256 balance = IERC20(_erc20Token).balanceOf(address(this));

        if (balance > 0) {
            return balance.sub(totalStaked[_erc20Token]);
        }

        return 0; 
    } 

    /**
    * @dev Send all the acumulated fees for one token to the fee destinators.
    */
    function withdrawAcumulatedFees(address _erc20Token) public {
        uint256 total = getAcumulatedFees(_erc20Token);
        
        for (uint8 i = 0; i < feesDestinators.length; i++) {
            IERC20(_erc20Token).transfer(
                feesDestinators[i],
                total.mul(feesPercentages[i]).div(100)
            );
        }
    }

    /* Governance Functions */

    /**
    * @dev Sets the fee for every withdraw.
    */
    function setFee(uint256 _fee) public onlyOwner() {
        fee = _fee;
    }

    /**
    * @dev Adds a new NFT to the pools, so users can stake for it.
    */
    function createReward(
        uint256 _tokenImage,
        uint256 _tokenRarity,
        uint256 _limit
    )
        public
        onlyOwner()
        imageNotExists(_tokenImage)
        validRarity(_tokenRarity)
    {
        rewardsMap[_tokenImage] = _tokenRarity;
        rarityByImages[_tokenRarity].push(_tokenImage);
        rarityByImagesTotal[_tokenRarity] += 1;
        limitByRarityAndImage[_tokenImage][_tokenRarity] = _limit;
    }

    /**
    * @dev Configure staking time and amount in ALOHA pool for one rarity.
    */
    function setSimplePool(
        uint256 _alohaAmount,
        uint256 _duration,
        uint256 _tokenRarity
    )
        public
        onlyOwner()
        rarityAvailable(_tokenRarity)
    {
        poolsMap[alohaERC20][_tokenRarity] = Pool({
            alohaAmount: _alohaAmount,
            erc20Amount: 0,
            duration: _duration,
            rarity: _tokenRarity
        });

        emit SettedPool(
            _alohaAmount,
            0,
            _duration,
            _tokenRarity,
            _getTime()
        );
    }

    /**
    * @dev Configure staking time and amount in ALOHA/TOKEN pool for one rarity.
    */
    function setPairPool(
        uint256 _alohaAmount,
        address _erc20Address,
        uint256 _erc20Amount,
        uint256 _duration,
        uint256 _tokenRarity
    )
        public
        onlyOwner()
        rarityAvailable(_tokenRarity)
    {
        require(address(_erc20Address) != address(0));

        poolsMap[_erc20Address][_tokenRarity] = Pool({
            alohaAmount: _alohaAmount,
            erc20Amount: _erc20Amount,
            duration: _duration,
            rarity: _tokenRarity
        });

        emit SettedPool(
            _alohaAmount,
            _erc20Amount,
            _duration,
            _tokenRarity,
            _getTime()
        );
    }

    /**
    * @dev Creates a new background for NFTs. New stakers could get this background.
    */
    function addBackground(uint8 increase)
        public
        onlyOwner()
    {
        backgrounds += increase;
    }

    /**
    * @dev Configure how to distribute the fees for user's withdraws.
    */
    function setFeesDestinatorsWithPercentages(
        address[] memory _destinators,
        uint256[] memory _percentages
    )
        public
        onlyOwner()
    {
        require(_destinators.length <= 3, "AlohaStaking: Destinators lenght more then 3");
        require(_percentages.length <= 3, "AlohaStaking: Percentages lenght more then 3");
        require(_destinators.length == _percentages.length, "AlohaStaking: Destinators and percentageslenght are not equals");

        uint256 total = 0;
        for (uint8 i = 0; i < _percentages.length; i++) {
            total += _percentages[i];
        }
        require(total == 100, "AlohaStaking: Percentages sum must be 100");

        feesDestinators = _destinators;
        feesPercentages = _percentages;
    }

    /* Internal functions */
    function _existsReward(uint256 _tokenImage) internal view returns (bool) {
        return rewardsMap[_tokenImage] != 0;
    }

    function _existsPool(address _erc20Token, uint256 _rarity) internal view returns (bool) {
        return poolsMap[_erc20Token][_rarity].duration != 0;
    }

    function _getTime() internal view returns (uint256) {
        return block.timestamp;
    }

    /**
    * @dev Apply withdraw fees to the amounts.
    */
    function _applyStakeFees(
        address _erc20Token,
        uint256 _tokenRarity
    ) internal view returns (
        uint256 _alohaAmountAfterFees,
        uint256 _erc20AmountAfterFees
    ) {
        uint256 alohaAmount = poolsMap[_erc20Token][_tokenRarity].alohaAmount;
        uint256 alohaAmountAfterFees = alohaAmount.sub(alohaAmount.mul(fee).div(10000));
        uint256 erc20AmountAfterFees = 0;

        if (_erc20Token != alohaERC20) {
            uint256 erc20Amount = poolsMap[_erc20Token][_tokenRarity].erc20Amount;
            erc20AmountAfterFees = erc20Amount.sub(erc20Amount.mul(fee).div(10000));
        }

        return (alohaAmountAfterFees, erc20AmountAfterFees);
    }

    /**
    * @dev Transfers erc20 tokens to this contract.
    */
    function _transferStake(
        address _wallet,
        address _erc20,
        uint256 _amount
    ) internal {
        require(IERC20(_erc20).transferFrom(_wallet, address(this), _amount), "Must approve the ERC20 first");

        emit Transfered(_wallet, _erc20, _amount, _getTime());
    }

    /**
    * @dev Transfers erc20 tokens from this contract to the wallet.
    */
    function _transferWithdrawRewards(
        address _wallet,
        address _erc20,
        uint256 _amount
    ) internal {
        require(IERC20(_erc20).transfer(_wallet, _amount), "Must approve the ERC20 first");

        emit Transfered(_wallet, _erc20, _amount, _getTime());
    }

    /**
    * @dev Clear the stake state for a wallet and a rarity.
    */
    function _clearStake(address wallet, address _erc20Token, uint256 _tokenRarity) internal {
        stakingsMap[wallet][_erc20Token][_tokenRarity].endDate = 0;
        stakingsMap[wallet][_erc20Token][_tokenRarity].tokenImage = 0;
        stakingsMap[wallet][_erc20Token][_tokenRarity].tokenBackground = 0;
        stakingsMap[wallet][_erc20Token][_tokenRarity].alohaAmount = 0;
        stakingsMap[wallet][_erc20Token][_tokenRarity].erc20Amount = 0;
    }

    /**
    * @dev Withdraw tokens and mints the NFT if claimed.
    */
    function _withdraw(address _erc20Token, uint256 _tokenRarity, bool claimReward) internal {
        uint256 alohaAmount = poolsMap[_erc20Token][_tokenRarity].alohaAmount;
        uint256 erc20Amount = poolsMap[_erc20Token][_tokenRarity].erc20Amount;
        uint256 alohaAmountAfterFees;
        uint256 erc20AmountAfterFees;
    
        if (!claimReward) {
            alohaAmountAfterFees = alohaAmount;
            erc20AmountAfterFees = erc20Amount;
        } else {
            (alohaAmountAfterFees, erc20AmountAfterFees) = _applyStakeFees(_erc20Token, _tokenRarity);
        }

        _transferWithdrawRewards(msg.sender, alohaERC20, alohaAmountAfterFees);
        totalStaked[alohaERC20] -= alohaAmount;

        if (_erc20Token != alohaERC20) {
            _transferWithdrawRewards(msg.sender, _erc20Token, erc20AmountAfterFees);
            totalStaked[_erc20Token] -= erc20Amount;
        }

        uint256 tokenId = 0;
        uint256 image = stakingsMap[msg.sender][_erc20Token][_tokenRarity].tokenImage;
        if (claimReward) {
            uint256 background = stakingsMap[msg.sender][_erc20Token][_tokenRarity].tokenBackground;

            tokenId = IAlohaNFT(alohaERC721).awardItem(msg.sender, _tokenRarity, image, background);
        } else {
            totalTokensByRarityAndImage[image][_tokenRarity] -= 1;
        }

        emit Withdrawal(
            msg.sender,
            _erc20Token,
            _tokenRarity,
            alohaAmount,
            erc20Amount,
            alohaAmountAfterFees,
            erc20AmountAfterFees,
            tokenId,
            _getTime()
        );

        _clearStake(msg.sender, _erc20Token, _tokenRarity);
    }

    function _getRandomImage(uint256 _rarity) internal returns (uint256) {
        uint256 selectedImage = rarityByImages[_rarity][_randomA(rarityByImagesTotal[_rarity]) - 1];

        if (limitByRarityAndImage[selectedImage][_rarity] == 0 || 
            totalTokensByRarityAndImage[selectedImage][_rarity] < limitByRarityAndImage[selectedImage][_rarity]
        ) {
            totalTokensByRarityAndImage[selectedImage][_rarity] += 1;
            return selectedImage;
        }

        for (uint256 index = 1; index <= rarityByImagesTotal[_rarity]; index++) {
            selectedImage = rarityByImages[_rarity][index - 1];
            if (limitByRarityAndImage[selectedImage][_rarity] == 0 ||
                totalTokensByRarityAndImage[selectedImage][_rarity] < limitByRarityAndImage[selectedImage][_rarity]
            ) {
                totalTokensByRarityAndImage[selectedImage][_rarity] += 1;
                return selectedImage;
            }
        }

        revert("AlohaStaking: All images has reached the limit");
    }

    /**
    * @dev Generates a "random" number using the numbers of backgrounds that we have.
    */
    function _randomA(uint256 _limit) internal view returns (uint8) {
        uint256 _gasleft = gasleft();
        bytes32 _blockhash = blockhash(block.number-1);
        bytes32 _structHash = keccak256(
            abi.encode(
                _blockhash,
                backgrounds,
                _gasleft,
                _limit
            )
        );
        uint256 _randomNumber  = uint256(_structHash);
        assembly {_randomNumber := add(mod(_randomNumber, _limit),1)}
        return uint8(_randomNumber);
    }

    /**
    * @dev Generates a "random" number using the current block timestamp.
    */
    function _randomB(uint256 _limit) internal view returns (uint256) {
        uint256 _gasleft = gasleft();
        bytes32 _blockhash = blockhash(block.number-1);
        bytes32 _structHash = keccak256(
            abi.encode(
                _blockhash,
                _getTime(),
                _gasleft,
                _limit
            )
        );
        uint256 _randomNumber  = uint256(_structHash);
        assembly {_randomNumber := add(mod(_randomNumber, _limit),1)}
        return uint8(_randomNumber);
    }

}