/**
 *Submitted for verification at polygonscan.com on 2021-08-11
*/

// SPDX-License-Identifier: true

pragma solidity ^0.7.4;


// 
/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// 
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

// 
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

// 
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

// 
contract Governance {

    address public _governance;

    constructor() {
        _governance = tx.origin;
    }

    event GovernanceTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyGovernance {
        require(msg.sender == _governance, "not governance");
        _;
    }

    function setGovernance(address governance)  public  onlyGovernance
    {
        require(governance != address(0), "new governance the zero address");
        emit GovernanceTransferred(_governance, governance);
        _governance = governance;
    }


}

// 
interface IPool {
    function totalPowa( ) external view returns (uint256);
    function balanceOf( address owner ) external view returns (uint256);
}

// 
interface ICifi_Token {

    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function mint(address account, uint amount) external;
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

// 
abstract contract INftAsset is IERC721 {
    
    function tokensOfOwner(address) external view virtual returns (uint256[] memory);
    function mint(address to, uint256 tokenId) external virtual returns (bool) ;
    function burn(uint256 tokenId) external virtual;
    function exists(uint256 tokenId) external view virtual returns (bool) ;
}

// 
interface INftFactory {
    function getFaceValue(uint256) external view returns (uint256);

    function getStakingPowaBase() external view returns (uint256);
}

// 
contract NftStakingV2 is IPool, Governance {
    using SafeMath for uint256;

    ICifi_Token public _cifi = ICifi_Token(0x0);
    INftAsset public _nftAsset = INftAsset(0x0);
    INftFactory public _nftFactory = INftFactory(0x0);
    uint256 public _initReward = 600 * 1e18;
    uint256 public _startTime = block.timestamp + 365 days;
    uint256 public _rewardRate = 0;
    uint256 public _lastUpdateTime;
    uint256 public _rewardPerTokenStored;

    uint256 public _penaltyRate = 500;
    uint256 public _baseRate = 10000;
    uint256 public _punishTime =7 days;

    mapping(address => uint256) public _userRewardPerTokenPaid;
    mapping(address => uint256) public _rewards;
    mapping(address => uint256) public _lastStakedTime;

    bool public _hasStart = false;
    uint256 public _fixRateBase = 10000;

    uint256 public _stakingPowaBase = 10000;
    uint256 public _totalPowa;

    mapping(address => uint256) public _powaBalances;
    mapping(uint256 => uint256) public _powas;
    mapping(uint256 => uint256) public _stakeBalances;

    uint256 public _totalBalance;
    mapping(address => uint256) public _faceValues;
    uint256 public _maxStakedCifi = 500 * 1e18;

    mapping(address => uint256[]) public _tokensOfUser;
    mapping(uint256 => uint256) public _nftMapIndex;

    event RewardAdded(uint256 reward);
    event StakedNFT(address indexed user, uint256 amount);
    event WithdrawnNFT(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event NFTReceived(
        address operator,
        address from,
        uint256 tokenId,
        bytes data
    );

    constructor(
        address cifi,
        address nftAsset,
        address nftFactory
    ) {
        _cifi = ICifi_Token(cifi);
        _nftAsset = INftAsset(nftAsset);
        _nftFactory = INftFactory(nftFactory);
    }

    modifier updateReward(address account) {
        _rewardPerTokenStored = rewardPerToken();
        _lastUpdateTime = block.timestamp;
        if (account != address(0)) {
            _rewards[account] = earned(account);
            _userRewardPerTokenPaid[account] = _rewardPerTokenStored;
        }
        _;
    }

    function setMaxStakedCifi(uint256 amount) external onlyGovernance {
        _maxStakedCifi = amount;
    }

    /* Fee collection for any other token */
    function seize(ICifi_Token token, uint256 amount) external onlyGovernance {
        require(token != _cifi, "reward");
        token.transfer(_governance, amount);
    }

    /* Fee collection for any other token */
    function seizeErc721(IERC721 token, uint256 tokenId) external {
        require(token != _nftAsset, "nft stake");
        token.safeTransferFrom(address(this), _governance, tokenId);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalPowa() == 0) {
            return _rewardPerTokenStored;
        }
        return
            _rewardPerTokenStored.add(
                block
                    .timestamp
                    .sub(_lastUpdateTime)
                    .mul(_rewardRate)
                    .mul(1e18)
                    .div(totalPowa())
            );
    }

    function earned(address account) public view returns (uint256) {
        return
            balanceOf(account)
                .mul(rewardPerToken().sub(_userRewardPerTokenPaid[account]))
                .div(1e18)
                .add(_rewards[account]);
    }

    //the class is a number between 1-6
    //the stakingPowa is a number between 1-10000
    /*
    1   stakingPowa	1.1+ 1*stakingPowa/5000
    2	stakingPowa	1.2+ 1*(stakingPowa-5000)/3000
    3	stakingPowa	1.3+ 1*(stakingPowa-8000/2000
    4	stakingPowa	1.4+ 1.5*(stakingPowa-9000)/1000
    5	stakingPowa	1.5+ 1.5*(stakingPowa-9800)/500
    6	stakingPowa	1.6+ 1.5*(stakingPowa-9980)/100
    */

    function getMiningPowa(uint256 class, uint256 stakingPowa)
        public
        pure
        returns (uint256)
    {
        require(class > 0 && class < 7, "the nft not Cifi");

        uint256 unfold = 0;

        if (class == 1) {
            unfold = (stakingPowa * 10000) / 5000;
            return unfold.add(11000);
        } else if (class == 2) {
            unfold = (stakingPowa.sub(5000) * 10000) / 3000;
            return unfold.add(12000);
        } else if (class == 3) {
            unfold = (stakingPowa.sub(8000) * 10000) / 2000;
            return unfold.add(13000);
        } else if (class == 4) {
            unfold = (stakingPowa.sub(9000) * 15000) / 1000;
            return unfold.add(14000);
        } else if (class == 5) {
            unfold = (stakingPowa.sub(9800) * 15000) / 500;
            return unfold.add(15000);
        } else {
            unfold = (stakingPowa.sub(9980) * 15000) / 100;
            return unfold.add(16000);
        }
    }

    function getClass(uint256 stakingPowa) public view returns (uint256) {
        if (stakingPowa < _stakingPowaBase.mul(500).div(1000)) {
            return 1;
        } else if (
            _stakingPowaBase.mul(500).div(1000) <= stakingPowa &&
            stakingPowa < _stakingPowaBase.mul(800).div(1000)
        ) {
            return 2;
        } else if (
            _stakingPowaBase.mul(800).div(1000) <= stakingPowa &&
            stakingPowa < _stakingPowaBase.mul(900).div(1000)
        ) {
            return 3;
        } else if (
            _stakingPowaBase.mul(900).div(1000) <= stakingPowa &&
            stakingPowa < _stakingPowaBase.mul(980).div(1000)
        ) {
            return 4;
        } else if (
            _stakingPowaBase.mul(980).div(1000) <= stakingPowa &&
            stakingPowa < _stakingPowaBase.mul(998).div(1000)
        ) {
            return 5;
        } else {
            return 6;
        }
    }

    function getRarity(uint256 class) internal pure returns (uint256 rarity) {
        if (class == 1) {
            rarity = 5000;
        } else if (class == 2) {
            rarity = 3000;
        } else if (class == 3) {
            rarity = 2000;
        } else if (class == 4) {
            rarity = 1000;
        } else if (class == 5) {
            rarity = 500;
        } else {
            rarity = 100;
        }
    }

    // stake NFT
    function stakeNFT(uint256 nftId, uint256 stakingPowa)
        public
        updateReward(msg.sender)
        checkStart
    {
        uint256[] storage nftIds = _tokensOfUser[msg.sender];
        uint256 face_value = _nftFactory.getFaceValue(nftId);
        nftIds.push(nftId);
        _nftMapIndex[nftId] = nftIds.length - 1;

        uint256 miningPowa;
        uint256 class;
        class = getClass(stakingPowa);
        miningPowa = getMiningPowa(class, stakingPowa);

        uint256 stakedface_value = _faceValues[msg.sender];
        uint256 stakingface_value = stakedface_value.add(face_value) <=
            _maxStakedCifi
            ? face_value
            : _maxStakedCifi.sub(stakedface_value);

        if (stakingface_value > 0) {
            uint256 stake_powa = miningPowa.mul(stakingface_value).div(
                _fixRateBase
            );
            _faceValues[msg.sender] = _faceValues[msg.sender].add(
                stakingface_value
            );

            _powaBalances[msg.sender] = _powaBalances[msg.sender].add(
                stake_powa
            );

            _stakeBalances[nftId] = stakingface_value;
            _powas[nftId] = stake_powa;

            _totalBalance = _totalBalance.add(stakingface_value);
            _totalPowa = _totalPowa.add(stake_powa);
        }

        _nftAsset.safeTransferFrom(msg.sender, address(this), nftId);

        _lastStakedTime[msg.sender] = block.timestamp;
        emit StakedNFT(msg.sender, nftId);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory data
    ) public returns (bytes4) {
        if (_hasStart == false) {
            return 0;
        }

        emit NFTReceived(operator, from, tokenId, data);
        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }

    function withdrawNFT(uint256 nftId)
        public
        updateReward(msg.sender)
        checkStart
    {
        require(nftId > 0, "the nftId error");

        uint256[] memory nftIds = _tokensOfUser[msg.sender];
        uint256 nftIndex = _nftMapIndex[nftId];

        require(nftIds[nftIndex] == nftId, "not nftId owner");

        uint256[] memory newIds = new uint256[](nftIds.length - 1);
        uint256 j = 0;
        for (uint256 i = 0; i < nftIds.length; i++) {
            if (nftIds[i] != nftId) {
                _nftMapIndex[nftIds[i]] = j;
                newIds[j++] = (nftIds[i]);
            }
        }
        _tokensOfUser[msg.sender] = newIds;

        uint256 stake_powa = _powas[nftId];
        _powaBalances[msg.sender] = _powaBalances[msg.sender].sub(stake_powa);
        _totalPowa = _totalPowa.sub(stake_powa);

        uint256 stakeBalance = _stakeBalances[nftId];
        _faceValues[msg.sender] = _faceValues[msg.sender].sub(stakeBalance);
        _totalBalance = _totalBalance.sub(stakeBalance);

        _nftAsset.safeTransferFrom(address(this), msg.sender, nftId);

        _stakeBalances[nftId] = 0;
        _powas[nftId] = 0;

        emit WithdrawnNFT(msg.sender, nftId);
    }

    function withdraw() public checkStart {
        uint256[] memory nftIds = _tokensOfUser[msg.sender];
        for (uint8 index = 0; index < nftIds.length; index++) {
            if (nftIds[index] > 0) {
                withdrawNFT(nftIds[index]);
            }
        }
    }

    function getNftIds(address account)
        public
        view
        returns (uint256[] memory nftIds)
    {
        nftIds = _tokensOfUser[account];
    }

    function exit() external {
        withdraw();
        getReward();
    }

    function getReward() public updateReward(msg.sender) checkStart {
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            _rewards[msg.sender] = 0;

            uint256 penaltyReward = 0;

            //withdraw time check

            if (block.timestamp < (_lastStakedTime[msg.sender] + _punishTime)) {
                penaltyReward = reward.mul(_penaltyRate).div(_baseRate);
            }
            if (penaltyReward > 0) {
                reward = reward.sub(penaltyReward);
            }

            if (reward > 0) {
                _cifi.transfer(msg.sender, reward);
            }

            emit RewardPaid(msg.sender, reward);
        }
    }

    modifier checkStart() {
        require(_hasStart == true, "not started");
        require(block.timestamp > _startTime, "not start");
        _;
    }

    // set fix time to start reward
    function startNFTReward() external onlyGovernance updateReward(address(0)) {
        require(_hasStart == false, "has started");
        _hasStart = true;

        _startTime = block.timestamp;

        _rewardRate = _initReward;
        _cifi.mint(address(this), _initReward);

        _lastUpdateTime = _startTime;

        emit RewardAdded(_initReward);
    }

    function setPenaltyRate(uint256 penaltyRate) public onlyGovernance {
        _penaltyRate = penaltyRate;
    }

    function totalPowa() public view override returns (uint256) {
        return _totalPowa;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _powaBalances[account];
    }

    function setWithDrawPunishTime(uint256 punishTime) public onlyGovernance {
        _punishTime = punishTime;
    }
}