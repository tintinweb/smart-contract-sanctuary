// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./IStaking.sol";
import "./IVITA.sol";

contract Raphael is ERC721Holder, Ownable, ReentrancyGuard {
    // Different stages of a proposal
    enum ProposalStatus {
        VOTING_NOT_STARTED,
        VOTING,
        VOTES_FINISHED,
        RESOLVED,
        CANCELLED,
        QUORUM_FAILED
    }

    struct Proposal {
        string details;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 startBlock;
        uint256 endBlock;
        ProposalStatus status;
    }

    // key is a self-incrementing number
    mapping(uint256 => Proposal) private proposals;

    mapping(uint256 => mapping(address => bool)) private voted; //global voted mapping

    uint256 public proposalCount;

    uint256 private minVotesNeeded;
    address private nativeTokenAddress;
    address private stakingContractAddress;
    address[] private nftContractAddresses;

    bool private shutdown = false;

    uint256 public CREATE_TO_VOTE_PROPOSAL_DELAY = 13091; // ~2 days
    uint256 public VOTING_DURATION = 91636; // ~14 days

    uint256 public constant MIN_DURATION = 5; // ~ 1 minute
    uint256 public constant MAX_DURATION = 200000; // ~1 month

    event VotingDelayChanged(uint256 newDuration);
    event VotingDurationChanged(uint256 newDuration);
    event NativeTokenChanged(
        address newAddress,
        address oldAddress,
        address changedBy
    );
    event StakingAddressChanged(
        address newAddress,
        address oldAddress,
        address changedBy
    );
    event NativeTokenTransferred(
        address authorizedBy,
        address to,
        uint256 amount
    );
    event NFTReceived(address nftContract, address sender, uint256 tokenId);
    event NFTTransferred(address nftContract, address to, uint256 tokenId);
    event EmergencyShutdown(address triggeredBy, uint256 currentBlock);
    event EmergencyNFTApproval(
        address triggeredBy,
        address[] nftContractAddresses,
        uint256 startIndex,
        uint256 endIndex
    );
    event EmergencyNFTApprovalFail(address nftContractAddress);

    event ProposalCreated(
        uint256 proposalId,
        string details,
        uint256 vote_start,
        uint256 vote_end
    );
    event ProposalStatusChanged(uint256 proposalId, ProposalStatus newStatus);

    event Voted(address voter, uint256 proposalId, uint256 weight, bool direction);

    modifier notShutdown() {
        require(!shutdown, "cannot be called after shutdown");
        _;
    }

    modifier onlyShutdown() {
        require(shutdown, "can only call after shutdown");
        _;
    }

    constructor() Ownable() {
        proposalCount = 0; //starts with 0 proposals
        minVotesNeeded = 965390 * 1e18; // 5% of initial distribution
    }

    function getDidVote(uint256 proposalIndex) public view returns (bool) {
        return voted[proposalIndex][_msgSender()];
    }

    /**
     * @dev returns all data for a specified proposal
     * @param proposalIndex           uint index of proposal
     * @return string, 5 x uint (the parts of a Proposal object)
     */
    function getProposalData(uint256 proposalIndex)
        public
        view
        returns (
            string memory,
            uint256,
            uint256,
            uint256,
            uint256,
            uint8
        )
    {
        require(proposalIndex <= proposalCount && proposalIndex !=0, "Proposal doesn't exist");
        return (
            proposals[proposalIndex].details,
            proposals[proposalIndex].votesFor,
            proposals[proposalIndex].votesAgainst,
            proposals[proposalIndex].startBlock,
            proposals[proposalIndex].endBlock,
            uint8(proposals[proposalIndex].status)
        );
    }

    /**
     * @dev returns result of a proposal
     * @param proposalIndex           uint index of proposal
     * @return true if proposal passed, otherwise false
     */
    function getProposalResult(uint256 proposalIndex)
        public
        view
        returns (bool)
    {
        require(proposalIndex <= proposalCount && proposalIndex !=0, "Proposal doesn't exist");
        require(
            proposals[proposalIndex].status == ProposalStatus.VOTES_FINISHED ||
                proposals[proposalIndex].status == ProposalStatus.RESOLVED ||
                proposals[proposalIndex].status == ProposalStatus.QUORUM_FAILED,
            "Proposal must be after voting"
        );
        bool result; // is already false, only need to cover the true case
        if (proposals[proposalIndex].votesFor >
            proposals[proposalIndex].votesAgainst && (
                proposals[proposalIndex].status == ProposalStatus.VOTES_FINISHED ||
                proposals[proposalIndex].status == ProposalStatus.RESOLVED   
            )) {
            result = true;
        }

        return result;
    }

    /**
     * @dev returns minimum amount of votes needed for a proposal to pass
     * @return minVotesNeeded value
     */
    function getMinVotesNeeded() public view returns (uint256) {
        return minVotesNeeded;
    }

    /**
     * @dev returns address of the token associated with the DAO
     *
     * @return the address of the token contract
     */
    function getNativeTokenAddress() public view returns (address) {
        return nativeTokenAddress;
    }

    /**
     * @dev returns the DAO's balance of the native token
     */
    function getNativeTokenBalance() public view returns (uint256) {
        IVITA nativeTokenContract = IVITA(nativeTokenAddress);
        return nativeTokenContract.balanceOf(address(this));
    }

    /**
     * @dev returns an array of the NFTs owned by the DAO
     *
     * @return an array of nft structs
     */
    function getNftContractAddresses() public view returns (address[] memory) {
        return nftContractAddresses;
    }

    function getStakingAddress() public view returns (address) {
        return stakingContractAddress;
    }

    /**
     * @dev returns if DAO is shutdown or not
     */
    function isShutdown() public view returns (bool) {
        return shutdown;
    }

    /****************************
     * STATE CHANGING FUNCTIONS *
     ***************************/

    ////////////////////////
    // PLATFORM VARIABLES //
    ////////////////////////

    function setVotingDelayDuration(uint256 newDuration) public onlyOwner {
        require(
            newDuration > MIN_DURATION && newDuration < MAX_DURATION,
            "duration must be >5 <190000"
        );
        CREATE_TO_VOTE_PROPOSAL_DELAY = newDuration;

        emit VotingDelayChanged(newDuration);
    }

    function setVotingDuration(uint256 newDuration) public onlyOwner {
        require(
            newDuration > MIN_DURATION && newDuration < MAX_DURATION,
            "duration must be >5 <190000"
        );
        VOTING_DURATION = newDuration;

        emit VotingDurationChanged(newDuration);
    }

    /**
     * @dev Updates the min total votes needed for a proposal to pass
     * @param newVotesNeeded          uint new min vote threshold
     */
    function setMinVotesNeeded(uint256 newVotesNeeded)
        public
        onlyOwner
        notShutdown
    {
        IVITA nativeTokenContract = IVITA(nativeTokenAddress);
        require(newVotesNeeded > 0, "quorum cannot be 0");
        require(
            newVotesNeeded <= nativeTokenContract.totalSupply(),
            "votes needed > token supply"
        );
        minVotesNeeded = newVotesNeeded;
    }

    /**
     * @dev allows admins to set the address of the staking contract associated with the DAO
     *
     * @param _stakingContractAddress  the (new) address of the staking contract
     */
    function setStakingAddress(address _stakingContractAddress)
        public
        onlyOwner
        notShutdown
    {
        address oldAddress = stakingContractAddress;
        stakingContractAddress = _stakingContractAddress;
        emit StakingAddressChanged(
            stakingContractAddress,
            oldAddress,
            _msgSender()
        );
    }

    /**
     * @dev allows admins to set the address of the token associated with the DAO
     *
     * @param tokenContractAddress  the address of the ERC20 asset
     */
    function setNativeTokenAddress(address tokenContractAddress)
        public
        onlyOwner
        notShutdown
    {
        address oldAddress = nativeTokenAddress;
        nativeTokenAddress = tokenContractAddress;
        emit NativeTokenChanged(nativeTokenAddress, oldAddress, _msgSender());
    }

    //////////////////////////
    // PROPOSALS AND VOTING //
    //////////////////////////

    /**
     * @dev Creates a proposal
     * @param details           string with proposal details
     *
     */
    function createProposal(string memory details)
        public
        notShutdown
        nonReentrant
    {
        IStaking stakingContract = IStaking(stakingContractAddress);
        require(
            stakingContract.getStakedBalance(_msgSender()) > 0,
            "must stake to create proposal"
        );
        uint256 start_block = block.number + CREATE_TO_VOTE_PROPOSAL_DELAY;
        uint256 end_block = start_block + VOTING_DURATION;

        Proposal memory newProposal =
            Proposal(
                details,
                0, //votesFor
                0, //votesAgainst
                start_block,
                end_block,
                ProposalStatus.VOTING_NOT_STARTED
            );

        require(
            stakingContract.voted(_msgSender(), newProposal.endBlock),
            "createProposal: token lock fail"
        );
        proposalCount += 1;
        // Add new Proposal instance
        proposals[proposalCount] = newProposal;

        // lock staked tokens for duration of proposal

        emit ProposalCreated(proposalCount, details, start_block, end_block);
    }

    /**
     * @dev Moves proposal to the status it should be in
     *
     * @param proposalIndex          uint proposal key
     */
    function updateProposalStatus(uint256 proposalIndex) public notShutdown {
        require(proposalIndex <= proposalCount && proposalIndex !=0, "Proposal doesn't exist");

        Proposal storage currentProp = proposals[proposalIndex];
        // Can't change status of CANCELLED or RESOLVED proposals
        require(
            currentProp.status != ProposalStatus.CANCELLED,
            "Proposal cancelled"
        );
        require(
            currentProp.status != ProposalStatus.RESOLVED,
            "Proposal already resolved"
        );
        require(
            currentProp.status != ProposalStatus.QUORUM_FAILED,
            "Proposal failed to meet quorum"
        );

        // revert if no change needed
        if (
            // still before voting period
            currentProp.status == ProposalStatus.VOTING_NOT_STARTED &&
            block.number < currentProp.startBlock
        ) {
            revert("Too early to move to voting");
        } else if (
            // still in voting period
            currentProp.status == ProposalStatus.VOTING &&
            block.number >= currentProp.startBlock &&
            block.number <= currentProp.endBlock
        ) {
            revert("Still in voting period");
        }

        if (
            block.number >= currentProp.startBlock &&
            block.number <= currentProp.endBlock &&
            currentProp.status != ProposalStatus.VOTING
        ) {
            currentProp.status = ProposalStatus.VOTING;
        } else if (
            block.number < currentProp.startBlock &&
            currentProp.status != ProposalStatus.VOTING_NOT_STARTED
        ) {
            currentProp.status = ProposalStatus.VOTING_NOT_STARTED;
        } else if (
            block.number > currentProp.endBlock &&
            currentProp.status != ProposalStatus.VOTES_FINISHED
        ) {
            if (
                currentProp.votesFor + currentProp.votesAgainst >=
                minVotesNeeded
            ) {
                currentProp.status = ProposalStatus.VOTES_FINISHED;
            } else {
                currentProp.status = ProposalStatus.QUORUM_FAILED;
            }
        }

        // Save changes in the proposal mapping
        proposals[proposalIndex] = currentProp;

        emit ProposalStatusChanged(proposalIndex, currentProp.status);
    }

    /**
     * @dev Only for setting proposal to RESOLVED.
     * @dev Only callable from the multi-sig
     * @param proposalIndex          uint proposal key
     *
     */
    function setProposalToResolved(uint256 proposalIndex)
        public
        onlyOwner
        notShutdown
    {
        require(proposalIndex <= proposalCount && proposalIndex !=0, "Proposal doesn't exist");
        require(
            proposals[proposalIndex].status == ProposalStatus.VOTES_FINISHED,
            "Proposal not in VOTES_FINISHED"
        );
        proposals[proposalIndex].status = ProposalStatus.RESOLVED;
        emit ProposalStatusChanged(proposalIndex, ProposalStatus.RESOLVED);
    }

    /**
     * @dev Only for setting proposal to CANCELLED.
     * @dev Only callable from the multi-sig
     * @param proposalIndex          uint proposal key
     *
     */
    function setProposalToCancelled(uint256 proposalIndex)
        public
        onlyOwner
        notShutdown
    {
        require(proposalIndex <= proposalCount && proposalIndex !=0, "Proposal doesn't exist");
        require(
            proposals[proposalIndex].status != ProposalStatus.VOTES_FINISHED,
            "Can't cancel if vote finished"
        );
        require(
            proposals[proposalIndex].status != ProposalStatus.RESOLVED,
            "Proposal already resolved"
        );
        require(
            proposals[proposalIndex].status != ProposalStatus.QUORUM_FAILED,
            "Proposal already failed quorum"
        );
        require(
            proposals[proposalIndex].status != ProposalStatus.CANCELLED,
            "Proposal already cancelled"
        );

        proposals[proposalIndex].status = ProposalStatus.CANCELLED;
        emit ProposalStatusChanged(proposalIndex, ProposalStatus.CANCELLED);
    }

    /**
     * @dev Allows any address to vote on a proposal
     * @param proposalIndex           key to proposal in mapping
     * @param _vote                   true = for, false = against
     */
    function vote(uint256 proposalIndex, bool _vote) public notShutdown nonReentrant {
        require(proposalIndex <= proposalCount && proposalIndex !=0, "Proposal doesn't exist");

        IStaking stakingContract = IStaking(stakingContractAddress);
        uint256 stakedBalance = stakingContract.getStakedBalance(_msgSender());
        require(stakedBalance > 0, "must stake to vote");
        // check msg.sender hasn't already voted
        require(
            voted[proposalIndex][_msgSender()] == false,
            "Already voted from this address"
        );

        Proposal storage currentProp = proposals[proposalIndex];

        // Call updateProposalStatus() if proposal should be in VOTING stage
        require(
            currentProp.status == ProposalStatus.VOTING &&
                block.number <= currentProp.endBlock,
            "Proposal not in voting period"
        );

        if (_vote) {
            currentProp.votesFor += stakedBalance;
        } else {
            currentProp.votesAgainst += stakedBalance;
        }

        voted[proposalIndex][_msgSender()] = true;
        require(
            stakingContract.voted(
                _msgSender(),
                proposals[proposalIndex].endBlock
            ),
            "vote: token lock fail"
        );

        // Save changes in the proposal mapping
        proposals[proposalIndex] = currentProp;

        emit Voted(_msgSender(), proposalIndex, stakedBalance, _vote);
    }

    //////////////////////
    // ASSET MANAGEMENT //
    //////////////////////

    /**
     * @dev                 enables DAO to mint native tokens
     * @param _amount       the amount of tokens to mint
     */
    function mintNativeToken(uint256 _amount) public onlyOwner notShutdown {
        require(_amount > 0, "Can't mint 0 tokens");
        IVITA nativeTokenContract = IVITA(nativeTokenAddress);
        
        nativeTokenContract.mint(address(this), _amount);
    } 

    /**
     * @dev enables DAO to transfer the token it is associated with
     *
     * @param to                    the address to send tokens to
     * @param amount                the amount to send
     *
     * @return success or fail bool
     */
    function transferNativeToken(address to, uint256 amount)
        public
        onlyOwner
        notShutdown
        returns (bool)
    {
        IVITA nativeTokenContract = IVITA(nativeTokenAddress);
        require(
            nativeTokenContract.transfer(to, amount),
            "ERC20 transfer failed"
        );

        emit NativeTokenTransferred(_msgSender(), to, amount);
        return true;
    }

    /**
     * @dev enables DAO to transfer NFTs received
     *
     * @param nftContractAddress    the address of the NFT contract
     * @param recipient             the address to send the NFT to
     * @param tokenId               the id of the token in the NFT contract
     *
     * @return success or fail bool
     */
    function transferNFT(
        address nftContractAddress,
        address recipient,
        uint256 tokenId
    ) public onlyOwner notShutdown returns (bool) {
        IERC721 nftContract = IERC721(nftContractAddress);
        nftContract.safeTransferFrom(
            address(this),
            recipient,
            tokenId // what if there isn't one?
        );
        require(
            nftContract.ownerOf(tokenId) == recipient,
            "NFT transfer failed"
        );

        emit NFTTransferred(nftContractAddress, recipient, tokenId);
        return true;
    }

    ////////////////////////
    // EMERGENCY SHUTDOWN //
    ////////////////////////

     /**
      * @dev cancels unfinished proposals in a specific range
      * @param startIndex       the index to start cancelling from
      * @param endIndex         the index the cancelling will stop before
      *
      * @notice can only be called after shutdown, is called during shutdown
      */
    function emergencyProposalCancellation(uint256 startIndex, uint256 endIndex) external onlyShutdown onlyOwner {
        require(endIndex > startIndex, "end index must be > start index");
        // there is no proposal in the zero slot
        require(startIndex > 0, "starting index must exceed 0");
        // needs to be proposal count + 1 since end index is one past the last cancelled proposal
        require(endIndex <= proposalCount + 1, "end index > proposal count + 1");
        for (uint256 i = startIndex; i < endIndex; i++) {
            if (
                proposals[i].status != ProposalStatus.RESOLVED &&
                proposals[i].status != ProposalStatus.QUORUM_FAILED
            ) {
                proposals[i].status = ProposalStatus.CANCELLED;
                emit ProposalStatusChanged(i, ProposalStatus.CANCELLED);
            }
        }
    }

    /**
      * @dev approves admin on all NFT contracts
      * @param startIndex       the index to start cancelling from
      * @param endIndex         the index the cancelling will stop before
      *
      * @notice can only be called after shutdown, is called during shutdown
      */
    function emergencyNftApproval(uint256 startIndex, uint256 endIndex) external onlyOwner onlyShutdown nonReentrant {
        require(endIndex > startIndex, "end index must be > start index");
        require(endIndex <= nftContractAddresses.length, "end index > nft array len");
        for (uint256 i = startIndex; i < endIndex; i++) {
            if (nftContractAddresses[i] != address(0)) {
                IERC721 nftContract = IERC721(nftContractAddresses[i]);
                if (!nftContract.isApprovedForAll(address(this), owner())) {
                    try nftContract.setApprovalForAll(owner(), true) {
                    } catch {
                        emit EmergencyNFTApprovalFail(nftContractAddresses[i]);
                    }
                }
            }
        }

        emit EmergencyNFTApproval(_msgSender(), nftContractAddresses, startIndex, endIndex);
    }

    /**
     * @dev allows the admins to shut down the DAO (proposals, voting, transfers)
     * and also sweeps out any NFTs and native tokens owned by the DAO
     *
     * @notice this is an irreversible process!
     */
    function emergencyShutdown() public onlyOwner notShutdown nonReentrant {  
        IStaking stakingContract = IStaking(stakingContractAddress);
        stakingContract.emergencyShutdown(_msgSender());
        shutdown = true;
        emit EmergencyShutdown(_msgSender(), block.number);
    }

    /**
     * @dev function for receiving and recording an NFT
     * @notice calls "super" to the OpenZeppelin function inherited
     *
     * @param operator          the sender of the NFT (I think)
     * @param from              not really sure, has generally been the zero address
     * @param tokenId           the tokenId of the NFT
     * @param data              any additional data sent with the NFT
     *
     * @return `IERC721Receiver.onERC721Received.selector`
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory data
    ) public override notShutdown returns (bytes4) {
        nftContractAddresses.push(_msgSender());

        emit NFTReceived(_msgSender(), operator, tokenId);

        return super.onERC721Received(operator, from, tokenId, data);
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

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

  /**
   * @dev Implementation of the {IERC721Receiver} interface.
   *
   * Accepts all token transfers.
   * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
   */
contract ERC721Holder is IERC721Receiver {

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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

    constructor () {
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IStaking{
    function getStakedBalance(address staker) external view returns(uint256);
    function getUnlockTime(address staker) external view returns(uint256);
    function isShutdown() external view returns(bool);
    function voted(address voter, uint256 endBlock) external returns(bool);
    function stake(uint256 amount) external;
    function withdraw(uint256 amount) external;
    function emergencyShutdown(address admin) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVITA is IERC20 {
    function mint(address account, uint256 amount) external;
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
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
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

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}