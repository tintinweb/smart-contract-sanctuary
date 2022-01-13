/**
 *Submitted for verification at BscScan.com on 2022-01-13
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;


library SafeMath {

    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }


    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */    

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }


    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

        /**
    * @dev Integer modulo of two numbers, truncating the remainder.
    */ 

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

} 

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

/**
 * @dev Required interface of an ERC721 compliant contract.
 */

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the owner of the NFT specified by `tokenId`.
     */

    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     *
     *
     * Requirements:
     * - `from`, `to` cannot be zero.
     * - `tokenId` must be owned by `from`.
     * - `tokenId` must be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this
     * NFT by either {approve} or {setApprovalForAll}.
     */

    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function transferFrom(address from, address to, uint256 tokenId) external ;

}

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
}

contract NftStaking  {
    using SafeMath for uint256;

    event Staked(address NftTokenAddress, uint256 TokenId, uint256 StakePool);
    event EmergencyClaimStake(address NftTokenAddress, uint256 TokenId, uint256 StakeRewards, uint256 Penalty, uint256 StakedSeconds);
    event ClaimStake(address NftTokenAddress, uint256 TokenId, uint256 StakeRewards, uint256 StakedSeconds);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    IERC20 public rewardToken;
    address public owner ;

    /* An ECDSA signature. */
    struct Sign {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    uint256 public NftAddressCounter;

    // Array to sore all staked nft address 
    address[] internal NFTtokens;

    //Struct to store each staked tokenData
    struct stakeTokenData{
        uint256 tokenId;
        uint256 stakePeriod;
        address stakeholder;
        uint256 stakePool;
        uint256 timestamp;
    }
    // @notice NFT_Address --> staked tokenIds (tokenIds).
    mapping (address => stakeTokenData[]) internal tokenStakes;

    //@notice NFT_Address --> Array of Token's Rarity 
    mapping (address => uint256[]) internal tokenRarity;     //[1,2,3] => Rarity of tokenId:1 = 1

    uint256 public baseTokenReward ;    // Base Token Rewards for staking
    uint256[] public poolPeriod ;         // staking period of each pool (days)
    uint256[] public poolMultiplier;  // actual multiplier * 10
    uint256[] public nftMultiplier;   // actual multiplier * 10
    uint256[] public penalty;         // Eary Harvest Penalty

    constructor(address _rewardTokenContract ){
        rewardToken = IERC20(_rewardTokenContract) ;
        owner = msg.sender ;

        baseTokenReward = 100000000000;
        poolPeriod = [15, 30, 90, 180];
        poolMultiplier = [10, 12, 15, 20] ;         // actual multiplier * 10
        nftMultiplier  = [5, 10, 15, 15, 50] ;     // actual multiplier * 10
        penalty = [28, 40, 52, 64];
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function ownerTransfership(address newOwner) public onlyOwner returns(bool){
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        return true;
    }

    function setBaseTokenReward(uint256 _baseTokenReward) public onlyOwner returns (bool){
        baseTokenReward = _baseTokenReward;
        return true;
    }

    function setPoolPeriod(uint256[] memory _poolPeriod) public onlyOwner returns (bool){
        poolPeriod = _poolPeriod;
        return true;
    }

    function setPoolMultiplier(uint256[] memory _poolMultiplier) public onlyOwner returns (bool){
        poolMultiplier = _poolMultiplier;
        return true;
    }

    function setPenalty(uint256[] memory _penalty) public onlyOwner returns (bool){
        penalty = _penalty;
        return true;
    }

    function setNFTMultiplier(uint256[] memory _nftMultiplier) public onlyOwner returns (bool){
        nftMultiplier = _nftMultiplier;
        return true;
    }

    //------------------------Staked NFT_Address arr methods --------------------

    /**
    * @notice A method to check if an NFTtokenAaddress is allowed .
    *         allowed : An address is Allowed , if its found in  NFTtokens Array
    * @param _NftToken The address to verify.
    * @return bool, uint256 Whether the address is Allowed , position in the NFTtokens array.
    */
    function isNftAddressAllowed(address _NftToken) public view returns (bool, uint256){
        for (uint i=0 ; i<NFTtokens.length ; i+=1){
            if (NFTtokens[i]==_NftToken) return (true, i);
        }
        return (false, 0);
    }

    function addNftAddress (address _NftToken) internal virtual returns (bool){
        (bool _isStakeAddress, ) = isNftAddressAllowed(_NftToken);
        if(!_isStakeAddress) {
            NFTtokens.push(_NftToken);
            NftAddressCounter+=1;
            return true ;
        }
        return false ;
    }

    function removeNftAddress(address _NftToken) internal virtual returns (bool){
        (bool _isStakeAddress, uint256 s) = isNftAddressAllowed(_NftToken);
        if(_isStakeAddress){
            NFTtokens[s] = NFTtokens[NFTtokens.length - 1];
            NFTtokens.pop();
            NftAddressCounter-=1;
            return true;
        }
        return false;
    }

    modifier verifyNftAddress(address _NftToken) {
        (bool _isStakeAddress, ) = isNftAddressAllowed(_NftToken);
        require(_isStakeAddress ,"NFT Token Address not Allowed .") ;
        _;
    }

    //-----------------------tokenRarity--------------------

    /**
    * @notice A method to add rarity of tokens ( [0,1,2,1] ==> Rarity of tokenId[1] is 0 (id = index+1).
    *         tokenRarity arr: Array of Rarity of each tokens where, tokenId = index+1 .
    *         Push rarity of a batch of tokens , as they are minted batchwise.
    * @param _NftTokenAddress The address to Nft contract.
    * @param _newTokenRarity rarity arr to be pushed into arr.
    * @return bool.
    */

    function pushtoTokenRarity(address _NftTokenAddress, uint256[] memory _newTokenRarity) public onlyOwner returns (bool){
        require(_NftTokenAddress != address(0), "NftTokenAddress cannot be zero address");
        addNftAddress(_NftTokenAddress);
        for (uint256 i = 0 ; i<_newTokenRarity.length ; i++){
            require(_newTokenRarity[i] < nftMultiplier.length , "Rarity value Out of Bound");
            tokenRarity[_NftTokenAddress].push(_newTokenRarity[i]) ;
        } 
        return true ;
    }

    /**
    * @notice A method to update rarity of tokens initially pushed .
    * @param _NftTokenAddress The address to Nft contract.
    * @param _newTokenRarity updated rarity arr .
    * @param _fromTokenId  @param _toTokenId : Range to be updated/ replaced with the new rarity
    * @return bool.
    */
    function updateTokenRarity(address _NftTokenAddress, uint256[] memory _newTokenRarity , uint256 _fromTokenId , uint256 _toTokenId )
     public onlyOwner verifyNftAddress(_NftTokenAddress) returns (bool){

        require(_toTokenId <= tokenRarity[_NftTokenAddress].length , "Index Out of Bounds");
        require((_toTokenId -_fromTokenId)+1==_newTokenRarity.length , "Mismatch in passed array length");
        for (uint256 i = 0 ; i<_newTokenRarity.length ; i++){
            require(_newTokenRarity[i] < nftMultiplier.length , "Rarity value Out of Bound");
            tokenRarity[_NftTokenAddress][_fromTokenId - 1 + i] = _newTokenRarity[i] ;
        } 
        return true ;
    }

    function TokenRarityof(address _NftTokenAddress, uint256 _tokenId) public verifyNftAddress(_NftTokenAddress) view returns (uint256){
        require(_tokenId>0 &&_tokenId <= tokenRarity[_NftTokenAddress].length , "Index Out of Bounds");
        return tokenRarity[_NftTokenAddress][_tokenId - 1] ;
    }

    /**
    * @notice A method to get the tokenId of the last Token whose rarity has been updated/pushed .
    * @param _NftTokenAddress The address to Nft contract.
    * @return uint256 : TokenId of the last token.
    */
    function RarityTokenCounter(address _NftTokenAddress) public view returns (uint256){
        return tokenRarity[_NftTokenAddress].length;
    }

    /**
    * @notice A method to remove Rarity arr linked with NftTokenAddress .
    *         Once removed , NFT's linked to the respective NftTokenAddress cannot be staked .
    * @param _NftTokenAddress The address of Nft contract .
    * @return bool
    */
    function RemoveNftToken(address _NftTokenAddress) public onlyOwner verifyNftAddress(_NftTokenAddress) returns (bool){
        require(tokenStakes[_NftTokenAddress].length==0 , "NFT Staked Pool not empty");
        delete tokenRarity[_NftTokenAddress];
        removeNftAddress(_NftTokenAddress);
        return true;
    }

    //-----------------------Stake Holder methods --------------------

    /**
    * @notice A method to check if an address is a stakeholder.
    * @param _address The address to verify.
    * @return bool, uint256 Whether the address is a stakeholder, position in the tokenStakes array.
    */
    function isStakeholder(address _address) public view returns(bool, uint256){
        for (uint i=0 ; i<NFTtokens.length ; i+=1){
            address nft = NFTtokens[i] ;
            for (uint256 s = 0; s < tokenStakes[nft].length; s += 1){
                if (_address == tokenStakes[nft][s].stakeholder) return (true, s);
            }
        }
        return (false, 0);
    }

    /**
    * @notice A method to retrieve the stakeholder for a stake  .
    * @param _NftToken : Nft Contract address.
    * @param _tokenId : The tokenId to retrieve the stakeholder for.
    * @return address : The address of stakeholder.
    */
    function stakeholderOf(address _NftToken , uint256 _tokenId) public view returns (address) {
        (bool _isStakeToken, uint256 index ) = isStakeToken(_NftToken , _tokenId);
        require(_isStakeToken ,"Token not found in staked Pool .") ;
        return tokenStakes[_NftToken][index].stakeholder;
    }

    /**
    * @notice A method to get the count of total Stakes Of StakeHolder.
    * @param _stakeholder : The address of stakeholder. .
    * @return uint256 The aggregated stakes of stakeholders.
    */
    function totalStakesOfStakeHolder(address _stakeholder ) public view returns(uint256){
        uint256 _totalStakes = 0;
        for (uint i=0 ; i<NFTtokens.length ; i+=1){
            address nft = NFTtokens[i] ;
            for (uint256 s = 0; s < tokenStakes[nft].length; s += 1){
                if (tokenStakes[nft][s].stakeholder== _stakeholder) _totalStakes = _totalStakes.add(1) ;
            }
        }
        return _totalStakes;
    }

    //------------------------tokenStakes arr methods --------------------
    
    function getTokenIdAtIndex(address _NftToken, uint256 _index) public verifyNftAddress(_NftToken) view returns (uint256){
        require(_index <= tokenStakes[_NftToken].length , "index out of bound");
        return tokenStakes[_NftToken][_index].tokenId;
    }
    
    function totalNFTstakedOf(address _NftToken) public verifyNftAddress(_NftToken) view returns (uint256){
        return tokenStakes[_NftToken].length;
    }

    function isStakeToken(address _NftToken , uint256 _tokenId) public verifyNftAddress(_NftToken) view returns(bool, uint256){
        for (uint256 s = 0; s < tokenStakes[_NftToken].length; s += 1){
            if (_tokenId == tokenStakes[_NftToken][s].tokenId) return (true, s);
        }
        return (false, 0);
    }

    function addStakeToken(address _NftToken, stakeTokenData memory _stakeInfo) internal virtual returns (bool){
        (bool _isStakeToken, ) = isStakeToken(_NftToken, _stakeInfo.tokenId);
        if(!_isStakeToken) {
            tokenStakes[_NftToken].push(_stakeInfo);
            return true ;
        }
        return false ;
    }

    function removeStakeToken(address _NftToken, uint256 _stakeTokenId) internal virtual returns (bool){
        (bool _isStakeToken, uint256 s) = isStakeToken(_NftToken, _stakeTokenId);
        if(_isStakeToken){
            tokenStakes[_NftToken][s] = tokenStakes[_NftToken][ tokenStakes[_NftToken].length - 1];
            tokenStakes[_NftToken].pop();
            return true;
        }
        return false;
    }

    //------------------------StakeRewards and StakeTime utils --------------------

    function verifyStakeAndAccess(address _NftToken, uint256 _stakeTokenId) verifyNftAddress(_NftToken) internal view returns (uint256) {
        (bool _isStakeToken, uint256 index ) = isStakeToken(_NftToken, _stakeTokenId);
        require(_isStakeToken ,"Token not found in staked Pool .") ;

        require(tokenStakes[_NftToken][index].stakeholder== msg.sender , "Unauthorized User ");
        return index;
    }
    
    function isTokenClaimable(address _NftToken, uint256 _stakeTokenId) public view returns (bool){
        uint256 s_index = verifyStakeAndAccess(_NftToken, _stakeTokenId);
        if((block.timestamp.sub(tokenStakes[_NftToken][s_index].timestamp))>=tokenStakes[_NftToken][s_index].stakePeriod) return true;
        return false;
    }

    function viewRemainingStakeTime(address _NftToken, uint256 _stakeTokenId) public view returns (uint256){
        uint256 s_index = verifyStakeAndAccess(_NftToken, _stakeTokenId);
        if (!isTokenClaimable(_NftToken, _stakeTokenId))
            return (tokenStakes[_NftToken][s_index].timestamp.add(tokenStakes[_NftToken][s_index].stakePeriod)).sub( block.timestamp) ;
        return 0;
    }

    function getStakePeriod(uint256 _stakePool) public view returns (uint256){
        require(_stakePool<poolPeriod.length , "stake Pool not found");
        return (poolPeriod[_stakePool] * 86400); // 1 day (24hrs) = 86400 seconds
    }

    function getRewards(address _NftToken, uint256 _stakeTokenId) public view returns(uint256, uint256){
        uint256 s_index = verifyStakeAndAccess(_NftToken, _stakeTokenId);
        uint256 pool = tokenStakes[_NftToken][s_index].stakePool ;
        uint256 myrarity = TokenRarityof(_NftToken, _stakeTokenId) ;

        uint256 rewardPerYear = (baseTokenReward.mul(poolMultiplier[pool]).mul(nftMultiplier[myrarity])).div(100);
       
        // 1 year (365 days) = 31536000 seconds
        uint256 stakedSeconds = (block.timestamp - tokenStakes[_NftToken][s_index].timestamp);
        uint256 rewards =  ( stakedSeconds.mul(rewardPerYear) ).div(31536000) ; 
        return (rewards , stakedSeconds);
    }

    function verifyStakerSign(address NftTokenAddress, address stakeholder, uint256 tokenId, uint256 _stakingPool, Sign memory sign) internal pure {
        bytes32 hash = keccak256(abi.encodePacked(NftTokenAddress, tokenId, _stakingPool));
        require(stakeholder == ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)), sign.v, sign.r, sign.s), "Stakeholder sign verification failed");
    }

    function verifyWithdrawSign(address NftTokenAddress, address stakeholder, uint256 tokenId, Sign memory sign) internal pure {
        bytes32 hash = keccak256(abi.encodePacked(NftTokenAddress, tokenId));
        require(stakeholder == ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)), sign.v, sign.r, sign.s), "Stakeholder sign verification failed");
    }

    /**
    * @notice A method for a stakeholder to create a stake.
    * @param _NftTokenAddress The NFTtokenAddress to be staked.
    * @param _stakeTokenId The tokenId to be staked.
    * @param _stakingPool The staking pool (0,1,2,3..).
    * @param sign : sign of [NftTokenAddress, tokenId, stakingPool] by stakeholder  .
    */
    function createStake(address _NftTokenAddress, uint256 _stakeTokenId, uint256 _stakingPool, Sign memory sign) public verifyNftAddress(_NftTokenAddress) returns (bool){
        
        stakeTokenData memory stakeInfo = stakeTokenData(_stakeTokenId, getStakePeriod(_stakingPool), msg.sender, _stakingPool, block.timestamp);
        require(addStakeToken(_NftTokenAddress , stakeInfo),"Token already in staked Pool .") ;
        
        require (msg.sender == IERC721(_NftTokenAddress).ownerOf(_stakeTokenId), "Staker must be owner of Token");
        require(_stakeTokenId <= tokenRarity[_NftTokenAddress].length,"Rarity yet to be set");
        verifyStakerSign(_NftTokenAddress, msg.sender, _stakeTokenId, _stakingPool, sign);

        // NFT transfer to contract (Locking NFT)
        IERC721(_NftTokenAddress).transferFrom(msg.sender, address(this), _stakeTokenId);

        emit Staked(_NftTokenAddress, _stakeTokenId, _stakingPool);
        return true ;
    }

    /**
    * @notice A method to claim before staking Period completed (No token rewards given).
    * @param _NftTokenAddress The NFTtokenAddress to be staked.
    * @param _stakeTokenId The tokenId to be claimed.
    * @param sign : sign of [NftTokenAddress, tokenId] by stakeholder  .
    */
    function emergencyWithdrawStake(address _NftTokenAddress, uint256 _stakeTokenId, Sign memory sign) public verifyNftAddress(_NftTokenAddress)  returns (bool) {
        uint256 s_index = verifyStakeAndAccess(_NftTokenAddress, _stakeTokenId);

        require(!isTokenClaimable(_NftTokenAddress, _stakeTokenId), "Staking period already completed");
        verifyWithdrawSign(_NftTokenAddress, msg.sender, _stakeTokenId, sign);
        

        // Calculation of Rewards(ERC20)
        (uint256 stakeRewards, uint256 stakedSeconds )  = getRewards(_NftTokenAddress, _stakeTokenId);

        // Penalty Calculation
        uint256 pool = tokenStakes[_NftTokenAddress][s_index].stakePool;
        uint256 penaltyPercent = penalty[pool];
        uint256 myPenalty = (stakeRewards.mul(penaltyPercent)).div(100);
        uint256 rewards = stakeRewards.sub(myPenalty);

        // NFT transfer from contract to stakeholder
        IERC721(_NftTokenAddress).transferFrom( address(this), msg.sender, _stakeTokenId) ;

        // Rewards(ERC20) transfer to stakeholder
        require(rewardToken.transferFrom(owner, msg.sender, rewards), "failure while transferring Rewards");

        removeStakeToken(_NftTokenAddress, _stakeTokenId) ;
        emit EmergencyClaimStake(_NftTokenAddress, _stakeTokenId, rewards, myPenalty, stakedSeconds);
        return true ;
    }

    /**
    * @notice A method for a stakeholder to withdraw a stake.
    * @param _NftTokenAddress The NFTtokenAddress to be staked.
    * @param _stakeTokenId : tokenId to be withdrawn from staking.
    * @param sign : sign of [NftTokenAddress, tokenId] by stakeholder  .
    */
    function withdrawStake(address _NftTokenAddress, uint256 _stakeTokenId, Sign memory sign) public verifyNftAddress(_NftTokenAddress) returns (bool) {
        verifyStakeAndAccess(_NftTokenAddress, _stakeTokenId);

        require(isTokenClaimable(_NftTokenAddress, _stakeTokenId), "Staking period not completed");
        verifyWithdrawSign(_NftTokenAddress, msg.sender, _stakeTokenId, sign);

        // NFT transfer from contract to stakeholder
        IERC721(_NftTokenAddress).transferFrom( address(this), msg.sender, _stakeTokenId) ;

        // Rewards(ERC20) transfer to stakeholder
        (uint256 _stakeRewards, uint256  _stakedSeconds)  = getRewards(_NftTokenAddress, _stakeTokenId);
        require(rewardToken.transferFrom(owner, msg.sender, _stakeRewards), "failure while transferring Rewards");

        removeStakeToken(_NftTokenAddress, _stakeTokenId) ;
        emit ClaimStake(_NftTokenAddress, _stakeTokenId, _stakeRewards , _stakedSeconds);
        return true ;
    }
}