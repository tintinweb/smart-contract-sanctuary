//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
//BNF-02
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
contract MountSapphire is Ownable, ReentrancyGuard ,IERC721Receiver {
    using SafeMath for uint;
    uint public totalPowerInPool;
    address[] public listRewardTokens;
    address[] public listUserUpdate;
    IERC721 private nftToken;
    uint256 constant SECONDS_PER_DAY = 24 * 60 * 60;
    // Info of each user
    struct UserInfo {
        uint[] blucamonTokenIds;
        uint powerAll;
        uint startTime;
        uint stakedRbAmount;
    }
    struct Blucamon{
        uint tokenId;
        uint power;
    }
    struct RewardToken {
        uint currentRewardPerDay;
        uint oldRewardPerDay;
        uint totalSupply;
        uint startTime;
        bool enabled; // true - enable; false - disable
    }
    mapping (address => UserInfo) public userInfo;
    mapping (address => bool) public hasUser;
    mapping (address => mapping(address => uint)) public rewardDebt; //user => (rewardToken => rewardDebt);
    mapping (address => RewardToken) public rewardTokens;
    mapping (uint => uint) public blucamonPower; // tokenID => Power
    event AddNewTokenReward(address token);
    event DisableTokenReward(address token);
    event ChangeTokenReward(address indexed token, uint rewardPerBlock);
    event StakeTokens(address indexed user, uint power, uint[] blucamons);
    event UnstakeToken(address indexed user, uint[] blucamons);
    event EmergencyWithdraw(address indexed user, uint tokenCount);
    constructor(address _nftTokenAddress) {
        nftToken = IERC721(_nftTokenAddress);
    }
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
    function isTokenInList(address _token) internal view returns(bool){
        address[] memory _listRewardTokens = listRewardTokens;
        bool thereIs = false;
        for(uint i = 0; i < _listRewardTokens.length; i++){
            if(_listRewardTokens[i] == _token){
                thereIs = true;
                break;
            }
        }
        return thereIs;
    }
    function getUserStakedTokens(address _user) public view returns(uint[] memory){
        uint[] memory blucamonTokenIds = new uint[](userInfo[_user].blucamonTokenIds.length);
         for (uint i = 0; i < userInfo[_user].blucamonTokenIds.length; i++) {
            blucamonTokenIds[i] = userInfo[_user].blucamonTokenIds[i];
        }
        return blucamonTokenIds;
    }
     function getListBlucamonPower(uint[] memory tokenIds) public view returns(Blucamon[] memory){
         Blucamon[] memory blucamons = new Blucamon[](tokenIds.length);
         for (uint i = 0; i < tokenIds.length; i++) {
            blucamons[i].tokenId = tokenIds[i];
            blucamons[i].power = blucamonPower[tokenIds[i]];
        }
        return blucamons;
    }
    function getUserStakedPower(address _user) public view returns(uint){
        return userInfo[_user].powerAll;
    }
    function getListRewardTokens() public view returns(address[] memory,uint[] memory){
        address[] memory list = new address[](listRewardTokens.length);
        uint[] memory listRewardPerDay = new uint[](listRewardTokens.length);
        list = listRewardTokens;
        for (uint i = 0; i < list.length; i++) {
            listRewardPerDay[i] = rewardTokens[list[i]].currentRewardPerDay;
        }
        return (list,listRewardPerDay);
    }
     function getTotalPowerInPool() public view returns(uint){
        return totalPowerInPool;
    }
       function getListUserUpdate() public view returns(address[] memory){
        address[] memory list = new address[](listUserUpdate.length);
        list = listUserUpdate;
        return list;
    }
    function addNewTokenReward(address _newToken, uint _rewardPerDay) public onlyOwner {
        require(_newToken != address(0), "Address shouldn't be 0");
        require(isTokenInList(_newToken) == false, "Token is already in the list");
        listRewardTokens.push(_newToken);
        rewardTokens[_newToken].currentRewardPerDay = _rewardPerDay;
        rewardTokens[_newToken].oldRewardPerDay = _rewardPerDay;
        rewardTokens[_newToken].enabled = true;
        rewardTokens[_newToken].startTime = block.timestamp; 
        emit AddNewTokenReward(_newToken);
    }
    function disableTokenReward(address _token) public onlyOwner {
        require(isTokenInList(_token), "Token not in the list");
        rewardTokens[_token].enabled = false;
        emit DisableTokenReward(_token);
    }
    function enableTokenReward(address _token, uint _rewardPerDay) public onlyOwner {
        require(isTokenInList(_token), "Token not in the list");
        require(!rewardTokens[_token].enabled, "Reward token is enabled");
        rewardTokens[_token].enabled = true;
        rewardTokens[_token].oldRewardPerDay = rewardTokens[_token].currentRewardPerDay;
        rewardTokens[_token].currentRewardPerDay = _rewardPerDay;
        rewardTokens[_token].startTime = block.timestamp; 
        emit ChangeTokenReward(_token, _rewardPerDay);
    }
    function changeTokenReward(address _token, uint _rewardPerDay) public onlyOwner {
        require(isTokenInList(_token), "Token not in the list");
        rewardTokens[_token].oldRewardPerDay = rewardTokens[_token].currentRewardPerDay;
        rewardTokens[_token].currentRewardPerDay = _rewardPerDay;
        rewardTokens[_token].startTime = block.timestamp; 
        _updateRewardDebtAllUser();
    }
       // View function to see pending Reward on frontend.
    function pendingReward(address _user) external view returns (address[] memory, uint[] memory) {
        uint[] memory rewards = new uint[](listRewardTokens.length);
        for(uint i = 0; i < listRewardTokens.length; i++){
            address curToken = listRewardTokens[i];
            RewardToken memory curRewardToken = rewardTokens[curToken];
            if (curRewardToken.enabled == true) {
                if (totalPowerInPool == 0 || userInfo[_user].powerAll == 0) {
                    rewards[i] = 0;
                } else {
                    uint userTimeStamp = userInfo[_user].startTime;
                    uint userWeight = _getUserWeight(_user);
                   
                    if (userTimeStamp < curRewardToken.startTime) {
                        uint oldRewardPerSeconds = rewardTokens[listRewardTokens[i]].oldRewardPerDay.div(SECONDS_PER_DAY);
                        rewards[i] = oldRewardPerSeconds.mul(userWeight).div(10**18).mul(curRewardToken.startTime.sub(userTimeStamp));
                        userTimeStamp = curRewardToken.startTime;
                        uint rewardPerSeconds = rewardTokens[listRewardTokens[i]].currentRewardPerDay.div(SECONDS_PER_DAY);
                        uint currentReward = rewardPerSeconds.mul(userWeight).div(10**18).mul(_getDepositTime(_user));
                        rewards[i] = rewards[i].add(currentReward);
                        rewards[i] = rewards[i].add(rewardDebt[_user][listRewardTokens[i]]);
                    } else {
                        uint rewardPerSeconds = rewardTokens[listRewardTokens[i]].currentRewardPerDay.div(SECONDS_PER_DAY);
                        rewards[i] = rewardPerSeconds.mul(userWeight).div(10**18).mul(_getDepositTime(_user));
                        rewards[i] = rewards[i].add(rewardDebt[_user][listRewardTokens[i]]);
                        }
                }
            } 
        }
        return (listRewardTokens, rewards);
    }
    function debug(address _user) view public returns (uint,uint,uint){
        uint rewardPerSeconds = rewardTokens[0x710a9EAbA8bf87B62030e089A0F7126C825b7375].currentRewardPerDay.div(SECONDS_PER_DAY);
        uint  rewards = rewardPerSeconds.mul(_getUserWeight(_user)).div(10**18).mul(_getDepositTime(_user));
        uint baba = rewardPerSeconds.mul(_getUserWeight(_user)).div(10**18);
        return (rewardPerSeconds,rewards,baba);
    }
    function withdrawReward() public {
        _withdrawReward();
    }
    function _updateRewardDebtAllUser() public {
        for(uint i = 0; i < listUserUpdate.length; i++){
               _updateRewardDebt(listUserUpdate[i]);
        }
    }
     function _updateRewardDebt(address _user) internal {
        for(uint i = 0; i < listRewardTokens.length; i++){
            address curToken = listRewardTokens[i];
            RewardToken memory curRewardToken = rewardTokens[curToken];
            if (curRewardToken.enabled == true) {
                if (totalPowerInPool > 0 && userInfo[_user].powerAll > 0) {
                    uint userWeight = _getUserWeight(_user);
                    if (userInfo[_user].startTime < curRewardToken.startTime) {
                        uint reward;
                        uint oldRewardPerSeconds = rewardTokens[listRewardTokens[i]].oldRewardPerDay.div(SECONDS_PER_DAY);
                        reward = oldRewardPerSeconds.mul(userWeight).div(10**18).mul(curRewardToken.startTime.sub(userInfo[_user].startTime));
                        userInfo[_user].startTime = curRewardToken.startTime;
                        
                        uint rewardPerSeconds = rewardTokens[listRewardTokens[i]].currentRewardPerDay.div(SECONDS_PER_DAY);
                        reward = reward.add(rewardPerSeconds.mul(userWeight).div(10**18).mul(_getDepositTime(_user)));
                        rewardDebt[_user][listRewardTokens[i]] = rewardDebt[_user][listRewardTokens[i]].add(reward);
                        userInfo[_user].startTime = block.timestamp;
                    } else {
                        uint reward;
                        uint rewardPerSeconds = rewardTokens[listRewardTokens[i]].currentRewardPerDay.div(SECONDS_PER_DAY);
                        reward = rewardPerSeconds.mul(userWeight).div(10**18).mul(_getDepositTime(_user));
                        rewardDebt[_user][listRewardTokens[i]] = rewardDebt[_user][listRewardTokens[i]].add(reward);
                        userInfo[_user].startTime = block.timestamp;
                    }
                } 
            } 
        }
    }
    function _getDepositTime(address _user) view internal returns (uint){
        return block.timestamp.sub(userInfo[_user].startTime);
    }
    
      function _getUserWeight(address _user) view public returns (uint){
        uint power = userInfo[_user].powerAll * 10 ** 18;
        return power.div(totalPowerInPool);
    }
   
    function _withdrawReward() internal {
        _updateRewardDebtAllUser();
        address[] memory _listRewardTokens = listRewardTokens;
        for(uint i = 0; i < _listRewardTokens.length; i++){
            uint pending = rewardDebt[msg.sender][_listRewardTokens[i]];
            if(pending > 0){
                rewardDebt[msg.sender][_listRewardTokens[i]] = 0;
                IERC20(_listRewardTokens[i]).transfer(address(msg.sender), pending);
            }
        }
    }
    function removeBlucamonFromUserInfo(uint index, address user) internal {
        uint[] storage blucamonTokenIds = userInfo[user].blucamonTokenIds;
        
        userInfo[user].powerAll = userInfo[user].powerAll.sub(blucamonPower[blucamonTokenIds[index]]);
        totalPowerInPool = totalPowerInPool.sub(blucamonPower[blucamonTokenIds[index]]);
        blucamonTokenIds[index] = blucamonTokenIds[blucamonTokenIds.length - 1];
        blucamonTokenIds.pop();
    }
     function _initListUser(address _user) internal {
       if(hasUser[_user] != true){
           listUserUpdate.push(_user);
           hasUser[_user] = true;
        }
    }
    function stake(uint[] memory _blucamonsTokenIds)
        external
    {
        _initListUser(msg.sender);
        _withdrawReward();
        for (uint i = 0; i < _blucamonsTokenIds.length; i++) {
            nftToken.safeTransferFrom(msg.sender, address(this), _blucamonsTokenIds[i]);
            userInfo[msg.sender].blucamonTokenIds.push(_blucamonsTokenIds[i]);
            userInfo[msg.sender].powerAll = userInfo[msg.sender].powerAll.add(blucamonPower[_blucamonsTokenIds[i]]);
            totalPowerInPool = totalPowerInPool.add(blucamonPower[_blucamonsTokenIds[i]]);
        }
        
        userInfo[msg.sender].startTime = block.timestamp;
        emit StakeTokens(msg.sender, userInfo[msg.sender].powerAll, _blucamonsTokenIds);
    }
    // Withdraw _NFT tokens from STAKING.
    function unstake(uint[] memory blucamonTokenIds) public nonReentrant {
        require(userInfo[msg.sender].blucamonTokenIds.length >= blucamonTokenIds.length, "Wrong token count given");
        _withdrawReward();
        bool findToken;
        for(uint i = 0; i < blucamonTokenIds.length; i++){
            findToken = false;
            for(uint j = 0; j < userInfo[msg.sender].blucamonTokenIds.length; j++){
                if(blucamonTokenIds[i] == userInfo[msg.sender].blucamonTokenIds[j]){
                    nftToken.safeTransferFrom(address(this),msg.sender,blucamonTokenIds[i]);
                    removeBlucamonFromUserInfo(j, msg.sender);
                    findToken = true;
                    break;
                }
            }
            require(findToken, "Token not staked by user");
        }
        emit UnstakeToken(msg.sender, blucamonTokenIds);
    }
    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyUnstake() public {
        uint[] memory blucamonTokenIds = userInfo[msg.sender].blucamonTokenIds;
        delete userInfo[msg.sender];
        for(uint i = 0; i < listRewardTokens.length; i++){
            delete rewardDebt[msg.sender][listRewardTokens[i]];
        }
        for(uint i = 0; i < blucamonTokenIds.length; i++){
            nftToken.safeTransferFrom(address(this),msg.sender,blucamonTokenIds[i]);
            totalPowerInPool = totalPowerInPool.sub(blucamonPower[blucamonTokenIds[i]]);
        }
        emit EmergencyWithdraw(msg.sender, blucamonTokenIds.length);
    }
    // Withdraw reward token. EMERGENCY ONLY.
    function emergencyRewardTokenWithdraw(address _token, uint256 _amount) public onlyOwner {
        require(IERC20(_token).balanceOf(address(this)) >= _amount, "Not enough balance");
        IERC20(_token).transfer(msg.sender, _amount);
    }
    function updateBlucamonPower(Blucamon[] memory blucamons) public onlyOwner {
         for (uint i = 0; i < blucamons.length; i++) {
            blucamonPower[blucamons[i].tokenId] = blucamons[i].power;
        }
    }
    function setOwner(address address_) external onlyOwner {
        require(address_ != address(0));
        transferOwnership(address_);
    }
}

// SPDX-License-Identifier: MIT

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

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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