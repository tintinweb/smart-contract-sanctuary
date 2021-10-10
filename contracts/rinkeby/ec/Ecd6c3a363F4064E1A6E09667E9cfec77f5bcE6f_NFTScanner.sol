pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import "./interfaces/IMasterBarista.sol";
import "./interfaces/IOGNFT.sol";
import "./interfaces/ILatteNFT.sol";
import "./interfaces/IBooster.sol";
import "./interfaces/IBoosterConfig.sol";

contract NFTScanner is Context {
    using SafeMath for uint256;

    struct OGNFT {
        address nftAddress;
        uint256 nftCategoryId;
        uint256 nftTokenId;
        bool isStaking;
    }

    struct BoosterNFT {
        address nftAddress;
        uint256 nftCategoryId;
        uint256 nftTokenId;
        uint256 maxEnergy;
        uint256 currentEnergy;
        uint256 boostBps;
    }

    struct BoosterTokenInfo {
        address nftAddress;
        uint256 nftCategoryId;
        uint256 nftTokenId;
        uint256 maxEnergy;
        uint256 currentEnergy;
        uint256 boostBps;
    }

    struct BoosterStakingInfo {
        address nftAddress;
        uint256 nftCategoryId;
        uint256 nftTokenId;
        bool isOwner;
        bool isApproved;
        bool[] isAllowance;
        bool[] isStakingIn;
    }

    IMasterBarista public masterBarista;
    IOGNFT public ogNFT;
    ILatteNFT public latteNFT;
    IBooster public booster;
    IBoosterConfig public boosterConfig;

    constructor(
        IMasterBarista _masterBarista,
        IOGNFT _ogNFT,
        ILatteNFT _latteNFT,
        IBooster _booster,
        IBoosterConfig _boosterConfig
    ) public {
        masterBarista = _masterBarista;
        ogNFT = _ogNFT;
        latteNFT = _latteNFT;
        booster = _booster;
        boosterConfig = _boosterConfig;
    }

    function getOGNFTInfo(address _user)
        external
        view
        returns (OGNFT[] memory)
    {
        uint256 _balance = ogNFT.balanceOf(_user);

        OGNFT[] memory ogNFTInfo = new OGNFT[](_balance);

        for (uint256 i = 0; i < _balance; i++) {
            uint256 _nftTokenId = ogNFT.tokenOfOwnerByIndex(_user, i);
            uint256 _nftCategoryId = ogNFT.latteNFTToCategory(_nftTokenId);

            ogNFTInfo[i] = OGNFT({
                nftAddress: address(ogNFT),
                nftCategoryId: _nftCategoryId,
                nftTokenId: _nftTokenId,
                isStaking: false
            });
        }

        return ogNFTInfo;
    }

    function getOGNFTStakingInfo(address _user)
        public
        view
        returns (OGNFT[] memory)
    {
        uint256 _currentCategoryId = ogNFT.currentCategoryId();
        uint256 _currentTokenId = ogNFT.currentTokenId();

        OGNFT[] memory ogNFTStakingInfo = new OGNFT[](_currentTokenId);

        for (
            uint256 _nftCategoryId = 0;
            _nftCategoryId <= _currentCategoryId;
            _nftCategoryId++
        ) {
            uint256[] memory _nftTokenIds = ogNFT.userStakeTokenIds(
                _nftCategoryId,
                _user
            );

            if (_nftTokenIds.length != 0) {
                for (uint256 i = 0; i < _nftTokenIds.length; i++) {
                    uint256 _nftTokenId = _nftTokenIds[i];

                    ogNFTStakingInfo[_nftCategoryId] = OGNFT({
                        nftAddress: address(ogNFT),
                        nftCategoryId: _nftCategoryId,
                        nftTokenId: _nftTokenId,
                        isStaking: true
                    });
                }
            }
        }

        return ogNFTStakingInfo;
    }

    function getBoosterInfo(address _user)
        external
        view
        returns (BoosterNFT[] memory)
    {
        uint256 balance = latteNFT.balanceOf(_user);
        BoosterNFT[] memory boosterNFTInfo = new BoosterNFT[](balance);

        for (uint256 i = 0; i < balance; i++) {
            uint256 _nftTokenId = latteNFT.tokenOfOwnerByIndex(_user, i);
            uint256 _nftCategoryId = latteNFT.latteNFTToCategory(_nftTokenId);
            (
                uint256 _maxEnergy,
                uint256 _currentEnergy,
                uint256 _boostBps
            ) = boosterConfig.energyInfo(address(latteNFT), _nftTokenId);
            boosterNFTInfo[i] = BoosterNFT({
                nftAddress: address(ogNFT),
                nftCategoryId: _nftCategoryId,
                nftTokenId: _nftTokenId,
                maxEnergy: _maxEnergy,
                currentEnergy: _currentEnergy,
                boostBps: _boostBps
            });
        }

        return boosterNFTInfo;
    }

    function getBoosterStakingInfo(address[] memory _stakeTokens, address _user)
        external
        view
        returns (BoosterNFT[] memory)
    {
        BoosterNFT[] memory boosterNFTStakingInfo = new BoosterNFT[](
            _stakeTokens.length
        );

        for (uint256 i = 0; i < _stakeTokens.length; i++) {
            (address _nftAddress, uint256 _nftTokenId) = booster.userStakingNFT(
                _stakeTokens[i],
                _user
            );

            if (_nftAddress != address(0)) {
                uint256 _nftCategoryId = latteNFT.latteNFTToCategory(
                    _nftTokenId
                );
                (
                    uint256 _maxEnergy,
                    uint256 _currentEnergy,
                    uint256 _boostBps
                ) = boosterConfig.energyInfo(address(latteNFT), _nftTokenId);
                boosterNFTStakingInfo[i] = BoosterNFT({
                    nftAddress: _nftAddress,
                    nftCategoryId: _nftCategoryId,
                    nftTokenId: _nftTokenId,
                    maxEnergy: _maxEnergy,
                    currentEnergy: _currentEnergy,
                    boostBps: _boostBps
                });
            }
        }

        return boosterNFTStakingInfo;
    }

    function getBoosterTokenInfo(
        address _nftAddress,
        uint256 _nftCategoryId,
        uint256 _nftTokenId
    ) external returns (BoosterTokenInfo memory) {
        (
            uint256 _maxEnergy,
            uint256 _currentEnergy,
            uint256 _boostBps
        ) = boosterConfig.energyInfo(address(latteNFT), _nftTokenId);

        return
            BoosterTokenInfo({
                nftAddress: _nftAddress,
                nftCategoryId: _nftCategoryId,
                nftTokenId: _nftTokenId,
                maxEnergy: _maxEnergy,
                currentEnergy: _currentEnergy,
                boostBps: _boostBps
            });
    }

    function getBoosterStakingInfo(
        address[] memory _stakeTokens,
        address _nftAddress,
        uint256 _nftCategoryId,
        uint256 _nftTokenId,
        address _user
    ) external returns (BoosterStakingInfo memory) {
        address _owner = latteNFT.ownerOf(_nftTokenId);
        address _approvedAddress = latteNFT.getApproved(_nftTokenId);
        bool[] memory _isAllowance = new bool[](_stakeTokens.length);
        bool[] memory _isStakingIn = new bool[](_stakeTokens.length);

        for (uint256 i = 0; i < _stakeTokens.length; i++) {
            _isAllowance[i] = boosterConfig.boosterNftAllowance(
                _stakeTokens[i],
                _nftAddress,
                _nftTokenId
            );
            (address _stakingNFTAddress, uint256 _stakingNFTTokenId) = booster
                .userStakingNFT(_stakeTokens[i], _user);
            _isStakingIn[i] =
                _owner == address(booster) &&
                _nftAddress == _stakingNFTAddress &&
                _nftTokenId == _stakingNFTTokenId;
        }

        return
            BoosterStakingInfo({
                nftAddress: _nftAddress,
                nftCategoryId: _nftCategoryId,
                nftTokenId: _nftTokenId,
                isOwner: _owner == _user,
                isApproved: _approvedAddress == address(booster),
                isAllowance: _isAllowance,
                isStakingIn: _isStakingIn
            });
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;

interface IMasterBarista {
  /// @dev functions return information. no states changed.
  function poolLength() external view returns (uint256);

  function pendingLatte(address _stakeToken, address _user) external view returns (uint256);

  function userInfo(address _stakeToken, address _user)
    external
    view
    returns (
      uint256,
      uint256,
      uint256,
      address
    );

  function devAddr() external view returns (address);

  function devFeeBps() external view returns (uint256);

  /// @dev configuration functions
  function addPool(address _stakeToken, uint256 _allocPoint) external;

  function setPool(address _stakeToken, uint256 _allocPoint) external;

  function updatePool(address _stakeToken) external;

  function removePool(address _stakeToken) external;

  /// @dev user interaction functions
  function deposit(
    address _for,
    address _stakeToken,
    uint256 _amount
  ) external;

  function withdraw(
    address _for,
    address _stakeToken,
    uint256 _amount
  ) external;

  function depositLatte(address _for, uint256 _amount) external;

  function withdrawLatte(address _for, uint256 _amount) external;

  function harvest(address _for, address _stakeToken) external;

  function harvest(address _for, address[] calldata _stakeToken) external;

  function emergencyWithdraw(address _for, address _stakeToken) external;

  function mintExtraReward(
    address _stakeToken,
    address _to,
    uint256 _amount,
    uint256 _lastRewardBlock
  ) external;
}

pragma solidity 0.6.12;

import "./ILatteNFT.sol";

interface IOGNFT is ILatteNFT {
    function ogOwnerToken(uint256 _tokenId)
        external
        view
        returns (
            address,
            uint256,
            string calldata,
            string calldata
        );

    function userStakeTokenIds(uint256 _categoryId, address _user)
        external
        view
        returns (uint256[] memory);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Enumerable.sol";

interface ILatteNFT is IERC721, IERC721Metadata, IERC721Enumerable {
  // getter

  function latteNames(uint256 tokenId) external view returns (string calldata);

  function categoryInfo(uint256 tokenId)
    external
    view
    returns (
      string calldata,
      string calldata,
      uint256
    );

  function latteNFTToCategory(uint256 tokenId) external view returns (uint256);

  function categoryToLatteNFTList(uint256 categoryId) external view returns (uint256[] memory);

  function currentTokenId() external view returns (uint256);

  function currentCategoryId() external view returns (uint256);

  function categoryURI(uint256 categoryId) external view returns (string memory);

  function getLatteNameOfTokenId(uint256 tokenId) external view returns (string memory);

  // setter
  function mint(
    address _to,
    uint256 _categoryId,
    string calldata _tokenURI
  ) external returns (uint256);

  function mintBatch(
    address _to,
    uint256 _categoryId,
    string calldata _tokenURI,
    uint256 _size
  ) external returns (uint256[] memory);
}

pragma solidity 0.6.12;

interface IBooster {
    function userInfo(address _stakeToken, address _user)
        external
        view
        returns (uint256, uint256);

    function totalAccumBoostedReward(address _stakeToken)
        external
        view
        returns (uint256);

    function userStakingNFT(address _stakeToken, address _user)
        external
        view
        returns (address, uint256);

    function stakeNFT(
        address _stakeToken,
        address _nftAddress,
        uint256 _nftTokenId
    ) external;

    function unstakeNFT(address _stakeToken) external;

    function stake(address _stakeToken, uint256 _amount) external payable;

    function unstake(address _stakeToken, uint256 _amount) external;

    function unstakeAll(address _stakeToken) external;

    function harvest(address _stakeToken) external;

    function harvest(address[] memory _stakeTokens) external;

    function masterBaristaCall(
        address stakeToken,
        address userAddr,
        uint256 unboostedReward,
        uint256 lastRewardBlock
    ) external;

    function emergencyWithdraw(address _stakeToken) external;

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external returns (bytes4);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;

pragma experimental ABIEncoderV2;

interface IBoosterConfig {
  // getter

  function energyInfo(address nftAddress, uint256 nftTokenId)
    external
    view
    returns (
      uint256 maxEnergy,
      uint256 currentEnergy,
      uint256 boostBps
    );

  function boosterNftAllowance(
    address stakingToken,
    address nftAddress,
    uint256 nftTokenId
  ) external view returns (bool);

  function stakeTokenAllowance(address stakingToken) external view returns (bool);

  function callerAllowance(address caller) external view returns (bool);

  // external

  function consumeEnergy(
    address nftAddress,
    uint256 nftTokenId,
    uint256 energyToBeConsumed
  ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IERC721.sol";

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

pragma solidity >=0.6.0 <0.8.0;

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