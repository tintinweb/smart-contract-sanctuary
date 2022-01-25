// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import '@rari-capital/solmate/src/utils/ReentrancyGuard.sol';
import '@rari-capital/solmate/src/tokens/ERC20.sol';
import "../libraries/ExtraMath.sol";
import "../interfaces/IAuraNFT.sol";

contract AuraChefNFT is Ownable, ReentrancyGuard {

    // Total Aura Points staked in Pool across all NFTs by all users.
    uint public totalAuraPoints;
    // Last block that rewards were calculated.
    uint public lastRewardBlock;
    // instance of AuraNFT
    IAuraNFT private auraNFT;

    // Here is a main formula to stake. Basically, any point in time, the amount of rewards entitled to a user but is pending to be distributed is:
    //
    //   pending reward = (user.auraPointAmount * rewardTokens.accCakePerShare) - user.rewardDebt
    //
    // Whenever a user stake/unstake/withdraw. Here's what happens:
    //   1. The RewardToken's `accCakePerShare` (and `lastRewardBlock`) gets updated in `updatePool` function
    //   2. User receives the pending reward sent to user's address.
    //   3. User's `auraPointAmount` (and `totalAuraPoints`) gets updated.
    //   4. User's `rewardDebt` gets updated.

    // Info of each user who took part in staking
    struct UserInfo {
        // list of staked NFT's ID
        uint[] stakedNFTsId;
        // AuraPoint Amount user gain with staked(A auraNFT has auraPoint amount initially)
        uint auraPointAmount;
    }

    // Info of reward token
    struct RewardToken {
        // reward will be accrued per block, must not be zero.
        uint rewardPerBlock;
        // block number which reward token is created.
        uint startBlock;
        // Accumulated Tokens per share, times 1e12.(1e12 is for suming as integer)
        uint accTokenPerShare;
        // true - enable; false - disable
        bool enabled;
    }

    // users took part in staking : UserAddress => UserInfo
    mapping (address => UserInfo) public users;
    // list of reward token's address
    address[] public rewardTokenAddresses;
    // RewardTokenAddress => RewardToken
    mapping (address => RewardToken) public rewardTokens;
    // rewardDebt is for removing duplicated reward that means whatever you’ve already received: UserAddress => (RewardTokenAddress => amount of rewardDebt)
    mapping (address => mapping(address => uint)) public rewardDebt;

    event AddNewRewardToken(address token);
    event DisableRewardToken(address token);
    event ChangeRewardToken(address indexed token, uint rewardPerBlock);
    event StakeTokens(address indexed user, uint amountRB, uint[] tokensId);
    event UnstakeToken(address indexed user, uint amountRB, uint[] tokensId);
    event BoostAuraNFT(uint indexed tokenId, uint boostedAP);

    constructor(IAuraNFT _auraNFT, uint _lastRewardBlock) {
        auraNFT = _auraNFT;
        lastRewardBlock = _lastRewardBlock;
    }

    //Public functions -------------------------------------------------------
    
    /**
     * @dev Update reward variables of the pool to be up-to-date.
     *
     * NOTE: - Update `lastRewardBlock` with current block number.
     *       - Update `accTokenPerShare` of all `rewardTokens` to current time.
     */
    function updatePool() public {
        uint _fromLastRewardToNow = getDiffBlock(lastRewardBlock, block.number);
        uint _totalAuraPoints = totalAuraPoints;

        if(_fromLastRewardToNow == 0){
            return;
        }
        lastRewardBlock = block.number;
        if(_totalAuraPoints == 0){
            return;
        }
        for(uint i = 0; i < rewardTokenAddresses.length; i++){
            address _tokenAddress = rewardTokenAddresses[i];
            RewardToken memory curRewardToken = rewardTokens[_tokenAddress];
            if(curRewardToken.enabled == true && curRewardToken.startBlock < block.number){
                uint fromRewardStartToNow = getDiffBlock(curRewardToken.startBlock, block.number);
                uint curMultiplier = ExtraMath.min(fromRewardStartToNow, _fromLastRewardToNow);
                rewardTokens[_tokenAddress].accTokenPerShare += (curRewardToken.rewardPerBlock * curMultiplier * 1e12) / _totalAuraPoints;
            }
        }
    }

    /**
     * @dev Used by owner to add new reward Token
     * @param newToken address of reward Token to be added
     * @param startBlock startBlock of new reward Token
     * @param rewardPerBlock rewardPerBlock of new reward Token
     *
     * Requirements:
     *
     * - `newToken` cannot be the zero address and it must be what doesn't exist.
     * - `rewardPerBlock` cannot be the zero.
     */
    function addNewRewardToken(address newToken, uint startBlock, uint rewardPerBlock) public onlyOwner {
        require(newToken != address(0), "Address shouldn't be 0");
        require(isRewardToken(newToken) == false, "Token is already in the list");
        require(rewardPerBlock != 0, "rewardPerBlock shouldn't be 0");

        rewardTokenAddresses.push(newToken);
        if(startBlock == 0){
            rewardTokens[newToken].startBlock = block.number + 1;
        } else {
            rewardTokens[newToken].startBlock = startBlock;
        }
        rewardTokens[newToken].rewardPerBlock = rewardPerBlock;
        rewardTokens[newToken].enabled = true;

        emit AddNewRewardToken(newToken);
    }

    /**
     * @dev Used by owner to disable rewardToken
     * @param token address of reward Token to be disabled
     * 
     * NOTE: UpdatePool() is required to reward users so far before token is disabled.
     *
     * Requirements:
     * - `token` must exist.
     * - `token` must be enabled.
     */
    function disableRewardToken(address token) public onlyOwner {
        require(isRewardToken(token), "Token not in the list");
        require(rewardTokens[token].enabled == true, "Reward token is already disabled");

        updatePool();
        rewardTokens[token].enabled = false;
        emit DisableRewardToken(token);
    }

    /**
     * @dev Used by owner to enable rewardToken 
     * @param token address of reward Token to be enabled
     * @param startBlock startBlock of reward Token to be enabled
     * @param rewardPerBlock rewardPerBlock of reward Token to be enabled
     *
     * NOTE: UpdatePool() is required to refresh once token is enabled.
     *
     * Requirements:
     *
     * - `token` must exist.
     * - `token` must be diabled.
     * - `rewardPerBlock` cannot be the zero.
     * - `startBlock` must be later than current.
     */
    function enableRewardToken(address token, uint startBlock, uint rewardPerBlock) public onlyOwner {
        require(isRewardToken(token), "Token not in the list");
        require(rewardTokens[token].enabled == false, "Reward token is already enabled");
        require(rewardPerBlock != 0, "rewardPerBlock shouldn't be 0");

        if(startBlock == 0){
            startBlock = block.number + 1;
        }
        require(startBlock >= block.number, "Start block Must be later than current");
        rewardTokens[token].enabled = true;
        rewardTokens[token].startBlock = startBlock;
        rewardTokens[token].rewardPerBlock = rewardPerBlock;
        emit ChangeRewardToken(token, rewardPerBlock);

        updatePool();
    }

    /**
     * @dev staking
     *
     * NOTE: 1. UpdatePool and User receives the pending reward sent to user's address.
     *       2. Push new NFT to be staked
     *       3. User's `auraPointAmount`(and `totalAuraPoints`) gets updated.
     *       4. User's `rewardDebt` gets updated.
     *
     * Requirements:
     *
     * - `tokensId`'s owner must be sender
     * - `tokensId` must be unstaked
     */
    function stake(uint[] memory tokensId) public nonReentrant {
        
        _withdrawRewardToken();// --------1
        
        UserInfo storage user = users[msg.sender];
        uint depositedAPs = 0;
        for(uint i = 0; i < tokensId.length; i++){
            (address tokenOwner, bool isStaked, uint auraPoints) = auraNFT.getInfoForStaking(tokensId[i]);
            require(tokenOwner == msg.sender, "Not token owner");
            require(isStaked == false, "Token has already been staked");
            auraNFT.setIsStaked(tokensId[i], true);
            depositedAPs += auraPoints;
            user.stakedNFTsId.push(tokensId[i]);// --------2
        }
        if(depositedAPs > 0){
            user.auraPointAmount += depositedAPs;// --------3
            totalAuraPoints += depositedAPs;
        }
        _updateRewardDebt(msg.sender);// --------4
        emit StakeTokens(msg.sender, depositedAPs, tokensId);
    }

    /**
     * @dev unstaking
     *
     * NOTE: 1. UpdatePool and User receives the pending reward sent to user's address.
     *       2. Remove NFTs to be unstaked
     *       3. User's `auraPointAmount`(and `totalAuraPoints`) gets updated.
     *       4. User's `rewardDebt` gets updated.
     *
     * Requirements:
     *
     * - `tokensId`'s owner must be sender
     * - `tokensId` must be staked
     */
    function unstake(uint[] memory tokensId) public nonReentrant {
        
        _withdrawRewardToken();// --------1
        
        UserInfo storage user = users[msg.sender];
        uint withdrawalAPs = 0;
        for(uint i = 0; i < tokensId.length; i++){
            (address tokenOwner, bool isStaked, uint auraPoints) = auraNFT.getInfoForStaking(tokensId[i]);
            require(tokenOwner == msg.sender, "Not token owner");
            require(isStaked == true, "Token has already been unstaked");
            auraNFT.setIsStaked(tokensId[i], false);
            withdrawalAPs += auraPoints;
            removeTokenIdFromUsers(tokensId[i], msg.sender);// --------2
        }
        if(withdrawalAPs > 0){
            user.auraPointAmount -= withdrawalAPs;// --------3
            totalAuraPoints -= withdrawalAPs;
        }
        _updateRewardDebt(msg.sender);// --------4
        emit UnstakeToken(msg.sender, withdrawalAPs, tokensId);
    }

    //External functions -----------------------------------------------------
    
    /**
     * @dev To withdraw reward token
     */
    function withdrawRewardToken() external {
        _withdrawRewardToken();
    }

    /**
     * @dev Boost auraNFT `tokenId` with accumulated AuraPoints `amount` by an user
     * @param tokenId uint ID of the token to be boosted
     * @param amount uint amount of AuraPoints to boost for the token
     *
     * Requirements:
     *      - sender must be an owner of token to be boosted.
     *      - The current held AuraPoints amount must be sufficient.
     *      - The counted auraPoints amount must be not over limit by level.
     */
    function boostAuraNFT(uint tokenId, uint amount) external {
        (address tokenOwner, bool isStaked, uint auraPoints) = auraNFT.getInfoForStaking(tokenId);
        require(tokenOwner == msg.sender, "Not token owner");
        uint _accumulatedAP = auraNFT.getAccumulatedAP(msg.sender);
        require(amount <= _accumulatedAP, "Insufficient amount of AuraPoints");
        uint _remainAP = auraNFT.remainAPToNextLevel(tokenId);
        uint _amount = ExtraMath.min(amount, _remainAP);

        uint[] memory tokensId = new uint[](1);
        tokensId[0] = tokenId;
        if (isStaked) {
            unstake(tokensId);
        }
        auraNFT.setAccumulatedAP(msg.sender, _accumulatedAP - _amount);
        uint newAP = auraPoints + _amount;
        auraNFT.setAuraPoints(tokenId, newAP);
        if (_amount == _remainAP) {
            auraNFT.levelUp(tokenId);
        }
        if (isStaked) {
            stake(tokensId);
        }
        emit BoostAuraNFT(tokenId, newAP);
    }

    /**
     * @dev See the list of the NFT ids that `_user` has staked
     */
    function getUserStakedTokens(address _user) external view returns(uint[] memory){
        uint[] memory tokensId = new uint[](users[_user].stakedNFTsId.length);
        tokensId = users[_user].stakedNFTsId;
        return tokensId;
    }

    /**
     * @dev See AuraPoint Amount by `_user`
     */
    function getUserAuraPointAmount(address _user) external view returns(uint){
        return users[_user].auraPointAmount;
    }

    /**
     * @dev See the list of Reward Tokens
     */
    function getListRewardTokens() external view returns(address[] memory){
        address[] memory list = new address[](rewardTokenAddresses.length);
        list = rewardTokenAddresses;
        return list;
    }

    /**
     * @dev See pending Reward on frontend.
     */
    function pendingReward(address _user) external view returns (address[] memory, uint[] memory) {
        UserInfo memory user = users[_user];
        uint[] memory rewards = new uint[](rewardTokenAddresses.length);
        if(user.auraPointAmount == 0){
            return (rewardTokenAddresses, rewards);
        }
        uint _totalAuraPoints = totalAuraPoints;
        uint _fromLastRewardToNow = getDiffBlock(lastRewardBlock, block.number);
        uint _accTokenPerShare = 0;
        for(uint i = 0; i < rewardTokenAddresses.length; i++){
            address _tokenAddress = rewardTokenAddresses[i];
            RewardToken memory curRewardToken = rewardTokens[_tokenAddress];
            if (_fromLastRewardToNow != 0 && _totalAuraPoints != 0 && curRewardToken.enabled == true) {
                uint fromRewardStartToNow = getDiffBlock(curRewardToken.startBlock, block.number);
                uint curMultiplier = ExtraMath.min(fromRewardStartToNow, _fromLastRewardToNow);
                _accTokenPerShare = curRewardToken.accTokenPerShare + (curMultiplier * curRewardToken.rewardPerBlock * 1e12 / _totalAuraPoints);
            } else {
                _accTokenPerShare = curRewardToken.accTokenPerShare;
            }
            rewards[i] = (user.auraPointAmount * _accTokenPerShare / 1e12) - rewardDebt[_user][_tokenAddress];
        }
        return (rewardTokenAddresses, rewards);
    }

    //internal functions -----------------------------------------------------

    /**
     * @dev Withdraw rewardToken from AuraChefNFT.
     *
     * NOTE: 1. updatePool()
     *       2. User receives the pending reward sent to user's address.
     *       3. User's `rewardDebt` gets updated.
     */
    function _withdrawRewardToken() internal {
        updatePool();// -----1
        UserInfo memory user = users[msg.sender];
        address[] memory _rewardTokenAddresses = rewardTokenAddresses;
        if(user.auraPointAmount == 0){
            return;
        }
        for(uint i = 0; i < _rewardTokenAddresses.length; i++){
            RewardToken memory curRewardToken = rewardTokens[_rewardTokenAddresses[i]];
            uint pending = user.auraPointAmount * curRewardToken.accTokenPerShare / 1e12 - rewardDebt[msg.sender][_rewardTokenAddresses[i]];
            if(pending > 0){
                ERC20(_rewardTokenAddresses[i]).transfer(address(msg.sender), pending);// ------2
                rewardDebt[msg.sender][_rewardTokenAddresses[i]] = user.auraPointAmount * curRewardToken.accTokenPerShare / 1e12;// -----3
            }
        }
    }

    /**
     * @dev check if `token` is RewardToken
     * @return true if so, false otherwise.
     */
    function isRewardToken(address token) internal view returns(bool){
        return rewardTokens[token].rewardPerBlock != 0;
    }
    
    /**
     * @dev Return difference block between _from and _to
     */
    function getDiffBlock(uint _from, uint _to) internal pure returns (uint) {
        if(_to > _from)
            return _to - _from;
        else
            return 0;
    }
    
    /**
     * @dev Update RewardDebt by user who is staking
     *
     * NOTE: Why divided by 1e12 is that `accTokenPerShare` is the value multiplied by 1e12.
     */
    function _updateRewardDebt(address _user) internal {
        for(uint i = 0; i < rewardTokenAddresses.length; i++){
            rewardDebt[_user][rewardTokenAddresses[i]] = users[_user].auraPointAmount * rewardTokens[rewardTokenAddresses[i]].accTokenPerShare / 1e12;
        }
    }

    /**
     * @dev Remove TokenId to be unstaked from userInfo
     * @param tokenId to be removed
     * @param user who is unstaking
     */
    function removeTokenIdFromUsers(uint tokenId, address user) internal {
        uint[] storage tokensId = users[user].stakedNFTsId;
        for (uint i = 0; i < tokensId.length; i++) {
            if (tokenId == tokensId[i]) {
                tokensId[i] = tokensId[tokensId.length - 1];
                tokensId.pop();
                return;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private reentrancyStatus = 1;

    modifier nonReentrant() {
        require(reentrancyStatus == 1, "REENTRANCY");

        reentrancyStatus = 2;

        _;

        reentrancyStatus = 1;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                             EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*///////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*///////////////////////////////////////////////////////////////
                              ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*///////////////////////////////////////////////////////////////
                              EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

// Library when openzepplin Math is not enough
library ExtraMath {
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

interface IAuraNFT {
    function accrueAuraPoints(address account, uint amount) external;
    function setIsStaked(uint tokenId, bool isStaked) external;
    function getAuraPoints(uint tokenId) external view returns(uint);
    function setAuraPoints(uint tokenId, uint amount) external;
    function getInfoForStaking(uint tokenId) external view returns(address tokenOwner, bool isStaked, uint auraPoints);
    function remainAPToNextLevel(uint tokenId) external view returns (uint);
    function getAccumulatedAP(address user) external view returns (uint);
    function setAccumulatedAP(address user, uint amount) external;
    function levelUp(uint tokenId) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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