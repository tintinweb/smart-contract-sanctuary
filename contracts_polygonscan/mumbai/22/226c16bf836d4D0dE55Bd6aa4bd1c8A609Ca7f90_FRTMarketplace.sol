// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// TODO: Questions in Sheet

interface IFRTNFT {
    function burn( address account, uint256 id, uint256 value) external;
    function uri(uint256 tokenId) external view returns (string memory); 
    function publisherOf(uint256 tokenId) external view returns (address);
    function getTokenURI(uint256 tokenId) external view returns(string memory);
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function isApprovedForAll(address account, address operator) external view returns (bool);
    function mint(address recipient, string memory _tokenURI, uint256 amount) external returns (uint256);
    function safeTransferFrom( address from, address to, uint256 id, uint256 amount, bytes memory data) external;
}

contract FRTMarketplace is Ownable{

    event ListNFT(uint256);
    event UnlistNFT(uint256);
    event NFTApproved(uint256);
    event NFTRejected(uint256);
    event BuyNFT(uint256, address);
    event VoteNFT(uint256, address, string);
    event MintNFT(uint256, address, string);
    event DownloadNFTForVoting(string, address);

    struct Vote{
        address[] up;
        address[] down;
    }
    
    struct Reward{
        uint256 reward;
        uint256 year;
        uint256 modules;
        uint256 publishedModules;
        uint256 issuedReward;
        uint256 maxReward;
    }

    IERC20 public baseToken;
    IFRTNFT public baseNFT;
    

    uint256 public l;
    uint256 public r;
    uint256 public initial_reward;
    mapping(uint256 => Reward) public rewardsData;
    uint256 contractCreatedAt;


    uint256 public baseTokenReward;
    uint256 public baseVoteReward;
    uint256 public baseNFTPrice;
    uint256 public baseTestingPrice;
    uint256 public baseNFTAmount;
    uint256 public approvalVotes;
    uint256 public maxVotes;
    

    mapping(string => bool) public mintedURIs;
    mapping(uint256 => bool) public pendingNFTQueue;
    mapping(uint256 => Vote) internal voteNFTQueue;
    mapping(uint256 => mapping(address => bool)) public votedAlready;
    mapping(uint256 => mapping(address => bool)) public testingAllowed;

    mapping(uint256 => bool) public listedNFTs;


    // set time when we deploy contract and each time when sending reward check timestamp difference since contract deployed
    // and convert into number years YEAR and get setting from yearlyReward[YEAR] and there you go.
    // Now we need populate setting into yearlyReward when we deploy contract using truffle, it can be done usin web# or twuffleJS
    // SEE https://github.com/pipermerriam/ethereum-datetime/blob/master/contracts/DateTime.sol
    // ALSO https://ethereum.stackexchange.com/questions/35793/how-do-you-best-calculate-whole-years-gone-by-in-solidity
    constructor( address tokenAddress, address nftAddress ){
        
        baseToken = IERC20(tokenAddress);
        baseNFT = IFRTNFT(nftAddress);

        maxVotes = 3;
        approvalVotes = 2;
        baseNFTPrice = 5*(10**18);
        baseTokenReward = 5*(10**18);
        baseNFTAmount = 1000000000;
        baseTestingPrice = 25 * (10**16);
        baseVoteReward = 5*baseTestingPrice;

        l = 31622.768 * 1000 ; // Square root of r answer will be divided by 1000
        r = 1000000000;
        initial_reward = 499999987.3 * 1000; // r/2.000000051
        contractCreatedAt = block.timestamp; 
        //365.24*24*60*60 <-- seconds in a year

    }

    /******UPDATE BASE VARIABLES START******/
    function updateBaseAddresses(address _tokenAddress, address _nftAddress ) external onlyOwner{
        baseToken = IERC20(_tokenAddress);
        baseNFT = IFRTNFT(_nftAddress);
    }

    // function updateTokenReward(uint256 _baseTokenReward) external onlyOwner{
    //    baseTokenReward = _baseTokenReward;
    // }

    function updateVoteReward(uint256 _baseVoteReward) external onlyOwner{
       baseVoteReward = _baseVoteReward;
    }

    function updateNFTPrice(uint256 _baseNFTPrice) external onlyOwner{
       baseNFTPrice = _baseNFTPrice;
    }

    function updateTestingPrice(uint256 _baseTestingPrice) external onlyOwner{
       baseTestingPrice = _baseTestingPrice;
    }

    function updateNFTAmount(uint256 _baseNFTAmount) external onlyOwner{
       baseNFTAmount = _baseNFTAmount;
    }

    function updateMaxVotes(uint256 _maxVotes, uint256 _approvalVotes) external onlyOwner{
       maxVotes = _maxVotes;
       approvalVotes = _approvalVotes;
    }
    /******UPDATE BASE VARIABLES END******/

    /******HANDLE NFTs START******/
    function mintNFT(string memory _tokenHash) public{

        uint256 newItemId = baseNFT.mint( msg.sender, _tokenHash, baseNFTAmount);

        pendingNFTQueue[newItemId] = true; // send token into queue

        emit MintNFT(newItemId, msg.sender, _tokenHash);
    }

    function buyNFT(uint256 _tokenId) public {
        require(listedNFTs[_tokenId]  == true, "FRTMarketplace: Token not listed for sale");
        require(checkTokenAlowance(msg.sender) >= baseNFTPrice, "FRTMarketplace: Transfer amount exceeds allowance");
        
        address nftOwner = baseNFT.publisherOf(_tokenId);
        
        baseToken.transferFrom(msg.sender, nftOwner, baseNFTPrice); // msg.sender, must have approved this Cointract to spend his coins
        baseNFT.safeTransferFrom(nftOwner, msg.sender, _tokenId, 1, ""); // nftOwner must have approved this Cointract to transfer his NFTs
        emit BuyNFT(_tokenId, msg.sender);
    }

    function downloadNFT(uint256 _tokenId) public view returns(string memory){
        require(baseNFT.balanceOf(msg.sender, _tokenId) > 0 , "FRTMarketplace: Unauthorised!");
        return baseNFT.uri(_tokenId);
    }

    function unlistNFT(uint256 _tokenId) public onlyOwner{
        delete listedNFTs[_tokenId];
        emit UnlistNFT(_tokenId);
    }

    function listNFT(uint256 _tokenId) public onlyOwner{
        // TODO: check if NFT exists
        require(!listedNFTs[_tokenId] && !pendingNFTQueue[_tokenId], "FRTMarketplace: NFT listed already");
        listedNFTs[_tokenId] = true;
        emit ListNFT(_tokenId);

    }

    /******HANDLE NFTs END******/


    /******HANDLE NFTs VERIFICATION START******/

    function voteNFT(uint256 _tokenId, bool _vote) public{
        require(pendingNFTQueue[_tokenId], "FRTMarketplace: NFT is not in queue");
        require(!votedAlready[_tokenId][msg.sender], "FRTMarketplace: already voted for this NFT");
        require(testingAllowed[_tokenId][msg.sender], "FRTMarketplace: not allowed to test");

        if(_vote){
            voteNFTQueue[_tokenId].up.push(msg.sender);
            emit VoteNFT(_tokenId, msg.sender, "Up");

        }else{
            voteNFTQueue[_tokenId].down.push(msg.sender);
            emit VoteNFT(_tokenId, msg.sender, "Down");
        }
        votedAlready[_tokenId][msg.sender] = true; // to remeber if this wallet voted already

        refreshQueue(_tokenId);
    }

    function refreshQueue(uint256 _tokenId) private{
        require(pendingNFTQueue[_tokenId] , "FRTMarketplace: NFT is not in queue");
        uint256 votes = voteNFTQueue[_tokenId].up.length + voteNFTQueue[_tokenId].down.length;
        //uint256 
        // TODO: approve when we have upvotes equal to approvalVotes
        // TODO: reject when we have more downvotes than maxVotes-approvalVotes


        if(votes >= maxVotes || voteNFTQueue[_tokenId].up.length >= approvalVotes ){
            _approveNFT(_tokenId);

        }else if(votes >= maxVotes || voteNFTQueue[_tokenId].down.length > (maxVotes-approvalVotes)){
            _rejectNFT(_tokenId);

        }

    }

    function _approveNFT(uint256 _tokenId) private {


        delete pendingNFTQueue[_tokenId];

        listedNFTs[_tokenId] = true; // we need to list and approve one by one because nfts must be avaliable for sell immidiatly  
        
        address publisher = baseNFT.publisherOf(_tokenId);
        string memory _tokenHash = baseNFT.getTokenURI(_tokenId);
        
        emit NFTApproved(_tokenId);

        if(!mintedURIs[_tokenHash]){
            giveReward(publisher);
            //baseToken.transfer(publisher, reward);
            mintedURIs[_tokenHash] = true;
        }

        // give reward to majority voters
        for (uint256 i = 0; i < voteNFTQueue[_tokenId].up.length; ++i) {
            baseToken.transfer(voteNFTQueue[_tokenId].up[i], baseVoteReward);
        }

    }

    function _rejectNFT(uint256 _tokenId) private {
        delete pendingNFTQueue[_tokenId];
        // delete listedNFTs[_tokenId];
        
        address publisher = baseNFT.publisherOf(_tokenId);
        uint256 amount = baseNFT.balanceOf(publisher, _tokenId);
        baseNFT.burn(publisher, _tokenId, amount);
        
        emit NFTRejected(_tokenId);

        // give reward to majority voters
        for (uint256 i = 0; i < voteNFTQueue[_tokenId].down.length; ++i) {
            baseToken.transfer(voteNFTQueue[_tokenId].down[i], baseVoteReward);
        }
    }

    // function payForNFTVoting(uint256 _tokenId) public{
    //     //require(baseNFT.balanceOf(msg.sender, _tokenId) > 0 , "FRTMarketplace: Unauthorised!");
    //     // TODO: Q2
    //     // TODO: stop USERS to vote for it's own NFT
    //     require(baseNFT.balanceOf(msg.sender, _tokenId) == 0, "FRTMarketplace: NFT owner can't vote");
    //     baseToken.transferFrom(msg.sender, address(this), baseTestingPrice);
    //     testingAllowed[_tokenId][msg.sender] = true;
    //     emit DownloadNFTForVoting(baseNFT.uri(_tokenId), msg.sender);
    // }

    function downloadNFTForTesting(uint256 _tokenId) public returns(string memory){
        require(baseNFT.publisherOf(_tokenId) != msg.sender, "FRTMarketplace: NFT owner can't download for vote");
        require(pendingNFTQueue[_tokenId] , "FRTMarketplace: NFT not in pending queue");
        // TODO: Q2 0.25
        // TODO: stop USERS to vote for it's own NFT
        if(!testingAllowed[_tokenId][msg.sender]){
            testingAllowed[_tokenId][msg.sender] = true;
            baseToken.transferFrom(msg.sender, address(this), baseTestingPrice);
        }
       
        emit DownloadNFTForVoting(baseNFT.uri(_tokenId), msg.sender);

        return baseNFT.uri(_tokenId);
    }

    /******HANDLE NFTs VERIFICATION END******/

    /******HELPERS START******/
    function checkTokenAlowance(address _account) internal view returns (uint256){
        return baseToken.allowance(_account, address(this));
    }

    function checkNFTApproved(uint256 _tokenId) internal view returns (bool){
        address _account = baseNFT.publisherOf(_tokenId);
        return baseNFT.isApprovedForAll(_account, address(this));
    }

    function contractTokenBalance() public view returns(uint256){
        return baseToken.balanceOf(address(this));
    }

    function withdrawTokens() public onlyOwner {
        baseToken.transfer(msg.sender, baseToken.balanceOf(address(this)));
    }
    /******HELPERS END******/

    /******REWARDS LOGIC START******/
    function setRewardsData(Reward[] memory _reward) public onlyOwner{
        for(uint256 i; i < _reward.length; i++ ){
            rewardsData[_reward[i].year] = _reward[i];
        }
    }

    function deleteRewardsData(uint256 _year) public onlyOwner{
        delete rewardsData[_year];
    }

    function getRewardsData(uint256 _year) public view returns(Reward memory){
        return rewardsData[_year];
    }

    function giveReward(address _publisher) internal {
        // TODO: handle what after 30 years
        // TODO: remove test values 

         uint256 _year = ((block.timestamp - contractCreatedAt) / 1 hours)+1; // get ongoing year since contract deployed
        if((rewardsData[_year].issuedReward + rewardsData[_year].reward) <= rewardsData[_year].maxReward && rewardsData[_year].publishedModules < rewardsData[_year].modules ){
            baseToken.transfer(_publisher, rewardsData[_year].reward); 
            rewardsData[_year].issuedReward += rewardsData[_year].reward;
            rewardsData[_year].publishedModules++;
        }

    }

    /******REWARDS LOGIC END******/





 
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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