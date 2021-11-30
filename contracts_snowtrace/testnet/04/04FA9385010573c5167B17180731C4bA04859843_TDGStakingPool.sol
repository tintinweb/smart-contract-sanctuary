/**
 *Submitted for verification at testnet.snowtrace.io on 2021-11-29
*/

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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


// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

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

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721Receiver.sol)

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

// File: contracts/TDGStakingPool.sol


pragma solidity >=0.4.22 <0.9.0;





contract TDGStakingPool is IERC721Receiver, Ownable {		
	string public name = "The Detectives Guild Staking";
	address public tdgowner;
	// RUGPULL public rugpull;
	address public detectivesGuild;
	// ERC721 public dtDoaNFT;	

	address[] public stakedNFTS;
	uint256[]  public stakeTokenIds;
	string[]  public stakeIds;
	string[]  public stakeUris;
	address[] public stakers;
	mapping(address => uint256) public stakingBalance;
	mapping(address => bool) public hasStaked;
	mapping(address => bool) public isStaking;
    mapping(address => uint256) public startTime;
	mapping(address => uint256) public dappBalance;

	uint256 annualEmmissions = 1000000000000000000000000000;
	uint256 rewardPerSecond = 3170979198376459000;
	event Stake(address _user, uint256 _tokenID);						 
	event Unstake(address _user, uint256 _tokenID);	
	event Claimed(address _user);					 
	struct MyStakedNFTS {
		uint256 id;
		address nft;
		string uri;
	}


	constructor(address _tdg) public {
		detectivesGuild = _tdg;
		// dtDaoNft = _dtDaoNft;
		tdgowner = msg.sender;
	}

    /**
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

	function stakeNFT(uint256 nftTOKENID, address dtDaoNft, string memory stakeId, string memory uri) public returns(uint256 _tokenID){				
        IERC721 _dtDaoNft = IERC721(dtDaoNft);
		require(_dtDaoNft.ownerOf(nftTOKENID) == msg.sender, "Only the owner can Stake the NFT");

		// transfer NFT token to this contract for staking
		// Keep a list of TokenIDS Staked
		_dtDaoNft.safeTransferFrom(msg.sender, address(this), nftTOKENID);

        if(isStaking[msg.sender]){
             uint256 toTransfer = calculateRewardTotal(msg.sender);
             dappBalance[msg.sender] += toTransfer;
         } else {
             dappBalance[msg.sender] = 0;
		 }

		// add user to stakers array *only* if they haven't staked already
		if(!hasStaked[msg.sender]) {
			stakingBalance[msg.sender] = 1;
		} else {
			// update staking balance
			stakingBalance[msg.sender] = stakingBalance[msg.sender] + 1;		

		}

		// update staking status
        startTime[msg.sender] = block.timestamp;
		isStaking[msg.sender] = true;
		hasStaked[msg.sender] = true;
		stakedNFTS.push(dtDaoNft);
		stakeTokenIds.push(nftTOKENID);
		stakeIds.push(stakeId);
		stakeUris.push(uri);
		stakers.push(msg.sender);
    	emit Stake(msg.sender, nftTOKENID);
		return (nftTOKENID);

	}

    function transferOut(address _token, address _to, uint256 _nftTOKENID) internal {
        IERC721 dtDaoNft = IERC721(_token);
		dtDaoNft.safeTransferFrom(address(this), _to, _nftTOKENID);
    }

	function emergencyWithdrawAll() public onlyOwner(){
		for (uint256 i = stakedNFTS.length - 1; i >= 0 ; i--){
			transferOut(stakedNFTS[i], stakers[i], stakeTokenIds[i]);
			dappBalance[stakers[i]] = 0;
			isStaking[stakers[i]] = false;
			hasStaked[stakers[i]] = false;
			removeNFT(i);
		}
	}

	function emergencyWithdraw() public {
		for (uint256 i = 0; i < stakedNFTS.length ; i--){
			if(stakers[i] == msg.sender){					
				transferOut(stakedNFTS[i], stakers[i], stakeTokenIds[i]);
				dappBalance[stakers[i]] = 0;
				isStaking[stakers[i]] = false;
				hasStaked[stakers[i]] = false;
				removeNFT(i);
			}
		}
	}

	function removeNFT(uint256 location) internal{
		stakers[location] = stakers[stakedNFTS.length - 1];
		stakeUris[location] = stakeUris[stakedNFTS.length - 1];
		stakeIds[location] = stakeIds[stakedNFTS.length - 1];
		stakedNFTS[location] = stakedNFTS[stakeIds.length - 1];
		stakeTokenIds[location] = stakeTokenIds[stakeIds.length - 1];
		stakers.pop();
		stakedNFTS.pop();
		stakeIds.pop();
		stakeTokenIds.pop();
		stakeUris.pop();
	}

	// Unstaking NFT: Withdraw NFT from DApp.
    /// @notice Retrieves NFT locked in contract and sends it back to the user
    /// @dev The rewardTransfer variable transfers the calculatedRewardTotal result to dappBalance
    ///      in order to save the user's unrealized rewards
    /// @param nftTOKENID The NFT(TokenID) the user wishes to unStake
	function unstakeNFT(uint256 nftTOKENID, address dtDaoNft, string memory stakeId) public {
		// fetch staking balance
		uint balance = stakingBalance[msg.sender];
		// require amount greater than 0
		require(balance > 0, "There are no NFT's to unStake");
		for (uint256 i = 0; i < stakedNFTS.length; i++){
			if(keccak256(bytes(stakeIds[i])) == keccak256(bytes(stakeId))){
				require(stakers[i] == msg.sender, "NFT can only be unstaked by the Owner");
				claimDappTokens(msg.sender);

				// transfer RPTokens tokens to this contract for staking
				transferOut(dtDaoNft, msg.sender, nftTOKENID);
				removeNFT(i);

				// reset staking balance to balance less amount unstaked
				stakingBalance[msg.sender] = balance - 1;

				// update staking status
				if (stakingBalance[msg.sender] == 0){
					isStaking[msg.sender] = false;
				}
			}
		}
		emit Unstake(msg.sender, nftTOKENID);
	}

	function claimDappTokens(address user) public returns (uint256){
		IERC20 _dtg = IERC20(detectivesGuild);
		uint256 rewardAmount = calculateRewardTotal(user);
		dappBalance[user]+=rewardAmount;
		uint256 totalClaimed = dappBalance[user];
		_dtg.transfer(user,totalClaimed);
		dappBalance[user]=0;
		startTime[msg.sender] = block.timestamp;
		emit Claimed(user);
		return totalClaimed;

	}


    function calculateRewardTime(address user) public view returns(uint256){
        uint256 end = block.timestamp;
        uint256 totalTime = end - startTime[user];
        return totalTime;
    }

    function calculateRewardTotal(address user) public view returns(uint256) {
        uint256 totalStaked = getTotalStaked();
		uint256 totalTime = calculateRewardTime(user);
		uint256 stakePerToken = (totalTime * rewardPerSecond) / totalStaked;
        uint256 reward = stakingBalance[user] * stakePerToken;
        return reward;
    } 

    function calculateRewardforTokenValue(address user, uint256 amount) public view returns(uint256) {
		require(amount > 0, "Amount must be greater than 0");
        uint256 totalStaked = getTotalStaked();
		uint256 totalTime = calculateRewardTime(user);
		uint256 totalReward = totalTime * rewardPerSecond;
		uint256 stakePerToken = totalReward / totalStaked;
		amount = amount / 10**18;
        uint256 reward = amount * stakePerToken;
        return reward;
    } 

    /// @notice Returns a list of the users Staked NFTs to the user
	function getStakedNFTs() public view returns(MyStakedNFTS[] memory tokenlist){
		uint256 count=0;
        for (uint256 i = 0; i < stakeIds.length; i++) {
			if(stakers[i] == msg.sender){
				count++;
			}
        }

		MyStakedNFTS[] memory myList = new MyStakedNFTS[](count);
		uint256 j=0;
        for (uint256 i = 0; i < stakeIds.length; i++) {
			if(stakers[i] == msg.sender){
	            myList[j] = MyStakedNFTS(stakeTokenIds[i], stakedNFTS[i], stakeUris[i]);
			}
        }
		return myList;
	}

	function getTotalStaked() public view returns(uint256){
		uint256 totalStaked = stakedNFTS.length;
		return totalStaked;
	}

	function getWeeklyEmmissions() public view returns(uint256){
		uint256 weeklyEmmissions = annualEmmissions / 52;
		return weeklyEmmissions;
	}

	function getDailyEmmissions() public view returns(uint256){
		uint256 dailyEmmissions = annualEmmissions / 365;
		return dailyEmmissions;
	}

	function getDappBalance(address user) public view returns(uint256){
		return dappBalance[user];
	}

	function getStakeTime(address user) public view returns(uint256){
		return startTime[user];
	}

	function getRewardPerSecond() public view returns(uint256){
		return (getDailyEmmissions() / 86400);
	}

}