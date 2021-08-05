/**
 *Submitted for verification at Etherscan.io on 2021-08-04
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;

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

interface I8020 {
    function buy(address _referredAdd) external payable returns(uint256);
}

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


contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor ()  {
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


contract NFTRewadPool is Context, Ownable {
    IERC721 accessToken;
    I8020 GS50Token;
    uint256 public balance; 
    
    address[] public stakeHolderArrays;
    
    
    mapping(address => bool) public isStaked;
    mapping(address => uint256) public stakedNft;
    
    mapping(address => uint256) public claimAmount;
    mapping(address => uint256) public stakeHolderArrayindex;
    
    
    constructor(address _tokenAddress,address _GS50TokenAddress)  {
        accessToken = IERC721(_tokenAddress);
        GS50Token = I8020(_GS50TokenAddress);
    }
    
      
    fallback() external payable {
        balance += msg.value;
    } 
    
    receive() external payable {
        balance += msg.value;
    }
    
    function receiveEth() public payable{
        require(msg.value > 0,'ERROR: not enough ETH');
        balance += msg.value;
    }
    
    function stake(uint256 _tokenId) public {
        require(!isStaked[_msgSender()],'ERROR: you have already staked');
        require(accessToken.ownerOf(_tokenId) == _msgSender(),"ERROR: you don't own this nft");
        
        accessToken.transferFrom(_msgSender(),address(this),_tokenId);
        
        isStaked[_msgSender()] = true;
        stakedNft[_msgSender()] = _tokenId;
        stakeHolderArrays.push(_msgSender());
        stakeHolderArrayindex[_msgSender()] = stakeHolderArrays.length - 1;
        
    }
    
    function claimReward() public {
        require(isStaked[_msgSender()],"ERROR: stake to claim");
        require(claimAmount[_msgSender()] > 0,"ERROR: not enough reward");
        
        uint256 rewardAmount = claimAmount[_msgSender()];
        claimAmount[_msgSender()] = 0;
        payable(_msgSender()).transfer(rewardAmount);
        
    }
    
    function unStake() public{
        require(isStaked[_msgSender()],"ERROR: you haven't stake");
        
        accessToken.transferFrom(address(this), _msgSender(), stakedNft[_msgSender()]);
        
        isStaked[_msgSender()] = false;
        stakedNft[_msgSender()] = 0;
        uint256 index = stakeHolderArrayindex[_msgSender()];       
        removeAtIndex(index);
       
       if(claimAmount[_msgSender()] > 0){
            uint256 amount = claimAmount[_msgSender()];
            claimAmount[_msgSender()] = 0;
            payable(_msgSender()).transfer(amount); 
       }
        
    }

    function reinvestInGs50() public {
        require(claimAmount[_msgSender()] > 0,"ERROR: you don't have any reward");
        uint256 rewardAmount = claimAmount[_msgSender()];
        claimAmount[_msgSender()] = 0;
        
        GS50Token.buy{value: rewardAmount}(address(0));
        
    }
    
    function checkBalance() public view returns(uint256) {
        return address(this).balance;
    }

     function calculateReward() public onlyOwner {
        uint256 stakeHolders = stakeHolderArrays.length;
        if(stakeHolders == 0) return;
        
        if(balance >= 1 ether) {
             uint256 distributedAmount = balance/stakeHolders;
             for(uint256 i=0; i<stakeHolders; i++){
                 claimAmount[stakeHolderArrays[i]] += distributedAmount;
             }
             balance = 0;
        }
    }
    
    
    function removeAtIndex(uint index) internal {
        if (index >= stakeHolderArrays.length) return;
    
        for (uint i = index; i < stakeHolderArrays.length-1; i++) {
          stakeHolderArrays[i] = stakeHolderArrays[i+1];
        }
    
        delete stakeHolderArrays[stakeHolderArrays.length-1];
        stakeHolderArrays.pop();
    
  }
  
}