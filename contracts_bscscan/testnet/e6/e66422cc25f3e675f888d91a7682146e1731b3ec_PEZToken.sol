/**
 *Submitted for verification at BscScan.com on 2021-11-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

////////////////////////////////////////////////////////////////////////

struct TStakeInfo
{
    address         user;
    uint256         amount;
    uint256         since;
    uint256         claimable;  // This claimable field is new and used to tell how big of a reward is currently available
    bool            isDone;
}

struct TStaker
{
    address         wallet;
    TStakeInfo[]    stakes;
}
    
struct TWalletStakeInfo
{
     uint256        totalAmount;
     
     TStakeInfo[]   stakes;
}

struct TStakableNftCollectionInfo
{
    string      name;
    address     collectionAddress;
    uint256     periodDurationInSec;    // How long it will take to receive new reward. by default it's once a day = 86400 seconds
    uint256     periodGain;             // How many PEZ you will get for every period
    uint256     periodSuperGain;        // for example add +2 PEZ if the person buys during a whitelisting period
    uint256     endTimestamp;           // When will the NFT will stop producing reward
    uint256     halvingTimestamp;       // When will the NFT will produce half of its reward only
}

struct TNftStaker
{
    address     user;
    bool        isStaking;
    uint256     since;
    uint256     periodGain;             // can be a standard "periodGain" or a "periodSuperGain"
    uint256     periodDurationInSec;
    string      collection;
    uint256     endTimestamp;           // When will the NFT will stop producing reward
    uint256     halvingTimestamp;       // When will the NFT will produce half of its reward only
}

struct TNftReward
{
    uint256     tokenId;
    uint256     reward;
    address     wallet;
}

interface   INftToken
{
    function    isItTheNftOwner(              address walletAddress, uint256 tokenId)  external view returns(bool isTokenFound);
    function    isWhitelistUser(             address userWallet)                      external view returns(bool);
    function    isUserInValidWhitelistMoment(address userWallet)                      external view returns(bool);
}

////////////////////////////////////////////////////////////////////////

interface IERC20 
{
    function totalSupply()                                                      external view   returns (uint256);
    function balanceOf(address account)                                         external view   returns (uint256);
    function transfer(address recipient, uint256 amount)                        external        returns (bool);
    function allowance(address owner, address spender)                          external view   returns (uint256);
    function approve(address spender, uint256 amount)                           external        returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount)    external        returns (bool);

    event Transfer(address indexed from,  address indexed to,      uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
interface IERC20Metadata is IERC20 
{
    function name()         external view returns (string memory);
    function symbol()       external view returns (string memory);
    function decimals()     external view returns (uint8);
}
library Address 
{
    function isContract(address account) internal view returns (bool) 
    {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
    function sendValue(address payable recipient, uint256 amount) internal 
    {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) 
    {
        return functionCall(target, data, "Address: low-level call failed");
    }
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) 
    {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) 
    {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) 
    {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) 
    {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) 
    {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) 
    {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) 
    {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) internal pure returns (bytes memory) 
    {
        if (success) 
        {
            return returndata;
        } 
        else 
        {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}
library SafeERC20 
{
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal 
    {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal 
    {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }
    function safeApprove(IERC20 token, address spender, uint256 value) internal 
    {
        require((value==0) || (token.allowance(address(this),spender)==0), "SafeERC20: approve from non-zero to non-zero allowance");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal 
    {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal 
    {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }
    function _callOptionalReturn(IERC20 token, bytes memory data) private 
    {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) 
        {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");  // Return data is optional
        }
    }
}

abstract contract Context 
{
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context 
{
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() 
    {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) 
    {
        return _owner;
    }

    modifier onlyOwner() 
    {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    function renounceOwnership() public virtual onlyOwner 
    {
        _transferOwnership(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner 
    {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal virtual 
    {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

abstract contract ReentrancyGuard 
{
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() 
    {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant()         // On the first call to nonReentrant, _notEntered will be true
    {
        
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        
        _status = _ENTERED;     // Any calls to nonReentrant after this point will fail
        _;
        _status = _NOT_ENTERED;
    }
}

////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////

contract    UsageGuard
{
    mapping(string => mapping(address=>uint32))     internal    forbiddenWallets;
    mapping(string => uint256)                      internal    forbiddenWalletCounts;
    
    //----------------------------------------------------------------------
    function    forbidWallets(address[] memory wallets, string memory appName) public returns(uint256)
    {
        uint256     nWallet = wallets.length;

        for(uint256 i=0; i<nWallet; i++)
        {
            address addr = wallets[i];
            
            if (forbiddenWallets[appName][addr]==0)     // on compte le nombre de forbiden wallets pour cette app
            {
                forbiddenWalletCounts[appName]++;
            }
            
	        forbiddenWallets[appName][addr] = 1;        // Il est mainetnant FORBIDDEN
        }
        
        return forbiddenWalletCounts[appName];
    }
    //----------------------------------------------------------------------
    function    unForbidWallets(address[] memory wallets, string memory appName) public returns(uint256)
    {
        uint256     nWallet = wallets.length;

        for(uint256 i=0; i<nWallet; i++)
        {
            address addr = wallets[i];
            
            if (forbiddenWallets[appName][addr]!=0)     // on compte le nombre de forbiden wallets pour cette app
            {
                if (forbiddenWalletCounts[appName]!=0)
                {
                    forbiddenWalletCounts[appName]--;
                }
            }
            
	        delete forbiddenWallets[appName][addr];
        }
        
        return forbiddenWalletCounts[appName];
    }
    //----------------------------------------------------------------------
    function    getForbiddenWalletsCountForApp(string memory appName)   public view returns(uint256)
    {
        return forbiddenWalletCounts[appName];
    }
    //----------------------------------------------------------------------
    function    isForbiddenWalletForApp(string memory appName) public view returns(bool)
    {
        return (forbiddenWallets[appName][msg.sender]==1);
    }
    //----------------------------------------------------------------------
}


//--------------------------------------------------

contract Stakable   is Ownable,UsageGuard
{
    event       StakeGenerated(  address indexed wallet, uint256 amount, uint256 stakeIndex, uint256 timestamp);
    event       StakeWithdrawn(  address indexed wallet, uint256 amount, uint256 reward, uint256 total, uint256 activeStakeCount);
    event       StakeHolderAdded(address indexed wallet, uint256 userIndex);
    event       ClaimedNftReward(address indexed wallet, uint256 amount, string collectionName);
    
    event       Staked(address indexed user, uint256 amount, uint256 index, uint256 timestamp);

    modifier    requireAboveZero(uint256 amount)    { require(amount>0, "Cannot stake nothing");   _; }
    modifier    callerIsAContract()                 { require(tx.origin != msg.sender, "The caller must be a smart contract");  _;  }

    constructor() 
    {
        stakers.push();        // This push is needed so we avoid index 0 causing bug of index-1
    }

    TStaker[]   internal stakers;

    uint256     internal    yearAvgDurationInSec = ((366+365+365+365) * 86400)/4;      // 31557600

    mapping(address => uint256)                     internal stakeIndexes;
    mapping(string  => TStakableNftCollectionInfo)  internal stakableNftCollections;
    mapping(address => bool)                        internal allowedNftContractAddresses;   // Pour la fonction nftStake qui doit etre appeller par un contrat NFT autorisé uniquement
    
    mapping(uint256 => TNftStaker)                  internal nftStakers;



    //----------------------------------------------------------------------
    //----------------------------------------------------------------------
    //                  S T A K I N G    FOR NFT COLLECTIONS
    //----------------------------------------------------------------------
    //----------------------------------------------------------------------
    function    setStakableNftCollection(string memory  collectionName, 
                                         address        contractAddress, 
                                         uint256        periodDurationInSec, 
                                         uint256        periodGain,
                                         uint256        periodSuperGain,
                                         uint256        endTimestamp,
                                         uint256        halvingTimestamp)           external onlyOwner
    {
        stakableNftCollections[ collectionName ] = TStakableNftCollectionInfo
        ( 
            collectionName,
            contractAddress,
            periodDurationInSec,
            periodGain,
            periodSuperGain,
            endTimestamp,
            halvingTimestamp
        );
        
        allowedNftContractAddresses[contractAddress] = true;
    }
    //----------------------------------------------------------------------
    function    nftStakeForVIP(string memory collectionName, address userWallet, uint256 tokenId, uint256 periodDurationInSec, uint256 periodGain) external onlyOwner returns(bool)
    {
        return nftStakeEx(collectionName, tokenId, true, userWallet, periodDurationInSec, periodGain, true);
    }
    //----------------------------------------------------------------------
    function    doPezNftStake(string memory collectionName, uint256 tokenId, address userWallet) internal returns(bool)  
    {
        bool    isAllowedContract = allowedNftContractAddresses[msg.sender];
        
        require(isAllowedContract==true, "This contract is not allowed");           // Seulement le contrat du NFT peut utiliser cette fonctionnalité
        
        return nftStakeEx(collectionName, tokenId, false, userWallet, 0,0, false);
    }
    //----------------------------------------------------------------------
    function    pezNftStake(string memory collectionName, uint256 tokenId, address userWallet) external returns(bool)  
    {
        bool    isAllowedContract = allowedNftContractAddresses[msg.sender];
        
        require(isAllowedContract==true, "This contract is not allowed");           // Seulement le contrat du NFT peut utiliser cette fonctionnalité
        
        return nftStakeEx(collectionName, tokenId, false, userWallet, 0,0, false);
    }
    //----------------------------------------------------------------------
    function    nftStakeEx(string memory collectionName, uint256 tokenId, bool isVIP, 
                           address userWallet,
                           uint256 imposedPeriodDurationInSec, uint256 imposedPeriodGain,
                           bool isCalledByAdmin)                        internal returns(bool)
    {
        require(tokenId>0,  "Invalid NFT token ID");

        if (!isForbiddenWalletForApp(collectionName) || isCalledByAdmin)
        {
            TStakableNftCollectionInfo memory nft = stakableNftCollections[collectionName];
        
            if (INftToken(nft.collectionAddress).isItTheNftOwner(userWallet, tokenId))
            {
                uint256 stakingHash = forgeNftStakingHash(collectionName, userWallet, tokenId);
            
                TNftStaker memory staker = nftStakers[stakingHash];
            
                require(staker.isStaking==false, "NFT is already staked or disabled");
            
                staker.user             = userWallet;
                staker.isStaking        = true;
                staker.since            = block.timestamp;
                staker.collection       = collectionName;
                staker.halvingTimestamp = nft.halvingTimestamp;
                staker.endTimestamp     = nft.endTimestamp;

                if (isVIP)          // Nous offrons un meilleur taux au VIP. au cas par cas.
                {
                    staker.periodDurationInSec = imposedPeriodDurationInSec;
                    staker.periodGain          = imposedPeriodGain;
                }
                else 
                {
                    staker.periodDurationInSec = nft.periodDurationInSec;
                    
                    if (INftToken(nft.collectionAddress).isUserInValidWhitelistMoment(userWallet))
                    {
                        staker.periodGain = nft.periodSuperGain;      // BRAVO you've gained more tokens per period!!
                    }
                    else        // standard mode
                    {
                        staker.periodGain = nft.periodGain;
                    }
                }

                nftStakers[stakingHash] = staker;
            }
            else
            {
                return false;
            }
        }
        
        return true;
    }
    //----------------------------------------------------------------------
    function    listUserNftStakeRewards(string memory collectionName, address userWallet, uint256[] memory tokenIds) external view returns(TNftReward[] memory)
    {
        return listNftStakeRewardsEx(collectionName, userWallet, tokenIds);
    }
    //----------------------------------------------------------------------
    function    listNftStakeRewardsEx(string memory collectionName, address userWallet, uint256[] memory tokenIds) internal view returns(TNftReward[] memory)
    {
        TStakableNftCollectionInfo memory nft = stakableNftCollections[collectionName];
        
        uint256             n       = tokenIds.length;
        TNftReward[] memory rewards = new TNftReward[](n);
        
        for (uint i=0; i<n; i++)
        {
            uint256 tokenId = tokenIds[i];
            
            if (INftToken(nft.collectionAddress).isItTheNftOwner(userWallet, tokenId))
            {
                uint256 stakingHash = forgeNftStakingHash(collectionName, userWallet, tokenId);
            
                uint256 reward = calculateRewardForNft(nftStakers[stakingHash]);
                
                rewards[i] = TNftReward( tokenId, reward, userWallet );
            }
        }
        
        return rewards;
    }
    //----------------------------------------------------------------------
    function    isNftsStaked(string memory collectionName, uint256[] memory tokenIds) external view returns(uint256[] memory)
    {
        TStakableNftCollectionInfo memory nft = stakableNftCollections[collectionName];
        
        uint256          n = tokenIds.length;
        uint256[] memory r = new uint256[](n);
        
        uint256 g=0;
        for (uint i=0; i<n; i++)
        {
            uint256 tokenId = tokenIds[i];
            
            if (INftToken(nft.collectionAddress).isItTheNftOwner(msg.sender, tokenId))
            {
                uint256 stakingHash = forgeNftStakingHash(collectionName, msg.sender, tokenId);
            
                r[g++] = (nftStakers[stakingHash].isStaking) ? 1:0;
            }
        }

        return r;
    }
    //----------------------------------------------------------------------
    function    forgeNftStakingHash(string memory collectionName, address nftUserWallet, uint256 tokenId) internal pure returns(uint256)
    {
        return uint256
        (
            keccak256
            (
                abi.encodePacked
                (
                    collectionName,
                    nftUserWallet,
                    tokenId
                )
            )
        );
    }
    //----------------------------------------------------------------------
    function    calculateRewardForNft(TNftStaker memory staker) internal view returns(uint256)
    {
        if (staker.since > block.timestamp)     return 0;   // overflow error
        if (staker.periodDurationInSec==0)      return 0;   // div zero

        uint256 reward = 0;

        uint256                    since             = staker.since;
        uint256                    timeNow           = block.timestamp;
        uint256                    age               = block.timestamp - staker.since;

        if (timeNow < staker.endTimestamp)                      // Ya du reward a recuperer
        {
            if (timeNow < staker.halvingTimestamp)                  // on est dans la periode normale
            {
                reward = (age * staker.periodGain) / staker.periodDurationInSec;
            }
            else 
            {
                if (since >= staker.halvingTimestamp)               // on est dans la periode de Halving
                {
                    reward = ((age * staker.periodGain) / staker.periodDurationInSec) / 2;
                }
                else                                                // on est entre les deux. Faire 2 calcules
                {
                    age    = staker.halvingTimestamp - since;
                    reward = (age * staker.periodGain) / staker.periodDurationInSec;        // gain sur la tranche normale
                    
                    age     = timeNow - staker.halvingTimestamp;
                    reward += ((age * staker.periodGain) / staker.periodDurationInSec) / 2; // + gain divisé par deux
                }
            }
        }
        
        return reward;
    }
    //----------------------------------------------------------------------
    //----------------------------------------------------------------------
    //                  S T A K I N G    S T A N D A R D
    //----------------------------------------------------------------------
    //----------------------------------------------------------------------
    function    addStakeHolder(address stakerWallet) public returns (uint256)
    {
        stakers.push();                                 // Push a empty item to the Array to make space for our new stakeholder
        
        uint256 userIndex = stakers.length - 1;         // Calculate the index of the last item in the array by Len-1
        
        stakers[userIndex].wallet  = stakerWallet;      // Assign the address to the new index
        stakeIndexes[stakerWallet] = userIndex;         // Add index to the stakeHolders
        
        emit StakeHolderAdded(stakerWallet, userIndex);
        
        return userIndex; 
    }
    //----------------------------------------------------------------------
    function    calculateStakeReward(TStakeInfo memory stakeInfo) internal view returns(uint256)
    {
        if (stakeInfo.since > block.timestamp)      return 0;   // overflow error
        if (yearAvgDurationInSec==0)                return 0;   // div zero
        
        uint256 age = block.timestamp - stakeInfo.since;
        
        return (age * stakeInfo.amount) / yearAvgDurationInSec;
    }
    //----------------------------------------------------------------------
    function    getWalletStakes(address stakeWallet) public view returns(TWalletStakeInfo memory)    // isShowAll
    {
        uint256     totalStakeAmount;                                                           // totalStakeAmount is used to count total staked amount of the address
        
        TWalletStakeInfo memory summary = TWalletStakeInfo(0, stakers[stakeIndexes[stakeWallet]].stakes);   // Keep a summary in memory since we need to calculate this
        
        for (uint256 s=0; s<summary.stakes.length; s+=1)                                        // Iterate all stakes and grab amount of stakes
        {
            uint256 availableReward = calculateStakeReward(summary.stakes[s]);
           
            summary.stakes[s].claimable = availableReward;
            totalStakeAmount            = totalStakeAmount+summary.stakes[s].amount;
        }

        summary.totalAmount = totalStakeAmount;                    // Assign calculate amount to summary

        return summary;
    }
    //----------------------------------------------------------------------
    function    getWalletStakingSummaryAtStakeIndex(address stakeWallet, uint256 stakeIndex) public view returns(TStakeInfo memory)
    {
        TStaker memory   staker;
        
        staker = stakers[ stakeIndexes[stakeWallet] ];
        
        return staker.stakes[stakeIndex];
    }
    //----------------------------------------------------------------------
    function    getWalletStakeCount(address stakeWallet)    public view returns(uint256 count)
    {
        return stakers[ stakeIndexes[stakeWallet] ].stakes.length;      // Returns how many staking objects he has created   
    }
    //----------------------------------------------------------------------
    function    isWalletStaking(address stakeWallet)        public view returns(bool)
    {
        return (stakeIndexes[stakeWallet]>0);                           // Returns if a wallet is using the STAKING feature or not
    }
    //----------------------------------------------------------------------
    function    getStakingTotalRewards(address stakeWallet) public view returns(uint256 totalRewards)
    {
        uint256     totalStakeAmount;                                                                       // totalStakeAmount is used to count total staked amount of the address
        
        TWalletStakeInfo memory summary = TWalletStakeInfo(0, stakers[stakeIndexes[stakeWallet]].stakes);   // Keep a summary in memory since we need to calculate this
        
        for (uint256 s=0; s<summary.stakes.length; s+=1)                                                    // Iterate all stakes and grab amount of stakes
        {
           totalStakeAmount += calculateStakeReward(summary.stakes[s]);
        }
       
        return totalStakeAmount;                                                                            // Assign calculate amount to summary
    }
    //----------------------------------------------------------------------
    function    getStakingRewardsAtStakeIndex(address stakeWallet, uint256 stakeIndex) public view returns(uint256 reward)
    {
        TWalletStakeInfo memory summary = TWalletStakeInfo(0, stakers[stakeIndexes[stakeWallet]].stakes);   // Keep a summary in memory since we need to calculate this
        
        return calculateStakeReward(summary.stakes[stakeIndex]);
    }
    //----------------------------------------------------------------------
    function    getStakingAmount(address stakeWallet) public view returns(uint256 totalRewards)
    {
        uint256     totalAmount;
        
        TWalletStakeInfo memory summary = TWalletStakeInfo(0, stakers[stakeIndexes[stakeWallet]].stakes);   // Keep a summary in memory since we need to calculate this
        
        for (uint256 s=0; s<summary.stakes.length; s+=1)                                        // Iterate all stakes and grab amount of stakes
        {
           totalAmount += summary.stakes[s].amount;
        }
       
        return totalAmount;                     // Assign calculate amount to summary
    }
    //----------------------------------------------------------------------
    function    getStakingAmountAtStakeIndex(address stakeWallet, uint256 stakeIndex) public view returns(uint256 reward)
    {
        TWalletStakeInfo memory summary = TWalletStakeInfo(0, stakers[stakeIndexes[stakeWallet]].stakes);   // Keep a summary in memory since we need to calculate this
        
        return summary.stakes[stakeIndex].amount;
    }
}


////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////

contract    PEZToken    is  Context, IERC20, IERC20Metadata , Ownable, ReentrancyGuard, Stakable//, IPEZToken
{
    using SafeERC20 for IERC20;
    
    mapping(address => uint256)                     private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private     _totalSupply;
    string  private     _name;
    string  private     _symbol;
    
    function name()                                         public view virtual override returns (string memory)    { return _name;    }
    function symbol()                                       public view virtual override returns (string memory)    { return _symbol;    }
    function decimals()                                     public view virtual override returns (uint8)            { return 18;    }
    function totalSupply()                                  public view virtual override returns (uint256)          { return _totalSupply;    }
    function balanceOf(address account)                     public view virtual override returns (uint256)          { return _balances[account];  }


    function    transfer(address recipient, uint256 amount)    public virtual override returns (bool) 
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function    allowance(address owner, address spender) public view virtual override returns (uint256) 
    {
        return _allowances[owner][spender];
    }
    function    approve(address spender, uint256 amount) public virtual override returns (bool) 
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function    transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) 
    {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        
        unchecked { _approve(sender, _msgSender(), currentAllowance - amount); }

        return true;
    }
    function    increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) 
    {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }
    function    decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) 
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }
    function    _transfer(address sender, address recipient, uint256 amount) internal virtual 
    {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        
        unchecked { _balances[sender] = senderBalance - amount; }
        
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }
    function    _mint(address account, uint256 amount) internal virtual 
    {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply       += amount;
        _balances[account] += amount;
        
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }
    function    _burn(address account, uint256 amount) internal virtual 
    {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }
    function    _approve(address owner, address spender, uint256 amount) internal virtual 
    {
        require(owner   != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function    _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}
    function    _afterTokenTransfer( address from, address to, uint256 amount) internal virtual {}

    ////////////////////////
    

    uint256 private     tokenTotalSupply = 100 * (10**6) * (10**18);     // 100 Millions (a 18 decimals)
    
    
    //----------------------------------------------------------------------
    constructor()
    {
        _name   = "ZP01 Token";
        _symbol = "ZP01";
        
        mint(tokenTotalSupply);
    }
    //----------------------------------------------------------------------
    function    mint(uint256 amount)  public onlyOwner
    {
        _mint(owner(), amount);
    }
    //----------------------------------------------------------------------
    function    burn(uint256 amount)  public onlyOwner
    {
        _burn(owner(), amount);
    }
    //----------------------------------------------------------------------
    function    stake(uint256 amount)   public    requireAboveZero(amount)
    {
        address     wallet     = msg.sender;
        uint256     balance    = _balances[wallet];
        uint256     newBalance = balance - amount;
        
        require(balance>=amount,    "Your balance is too low for staking");
        require(newBalance<balance, "Staking balance amount error occurred");

        uint256 index = stakeIndexes[wallet];           // Mappings in solidity creates all values, but empty, so we can just check the address
        
        uint256 timestamp = block.timestamp;            // block.timestamp = timestamp of the current block in seconds since the epoch
        
        if(index == 0)                                  // See if the staker already has a staked index or if its the first time
        {                                               // This stakeholder stakes for the first time
                                                        // We need to add him to the stakeHolders and also map it into the Index of the stakes
                                                        // The index returned will be the index of the stakeholder in the stakeholders array
            index = addStakeHolder(wallet);
        }

        stakers[index].stakes.push( TStakeInfo(wallet, amount, timestamp, 0, false) );  // Use the index to push a new Stake
                                                                                        // push a newly created Stake with the current block timestamp.
        emit StakeGenerated(wallet, amount, index, timestamp);

        _balances[wallet] = newBalance;                 // Supprimer la somme de la balance pour que la personne ne l'utilise plus

        emit Transfer(msg.sender, address(this), amount);
    }
    //----------------------------------------------------------------------
    function    unStake(uint256 stakeIndex) public returns(uint256)
    {
        uint256 user_index = stakeIndexes[msg.sender];                  // Grab user_index which is the index to use to grab the Stake[]
        
        TStakeInfo memory current_stake = stakers[user_index].stakes[stakeIndex];
        
        uint256 reward      = calculateStakeReward(current_stake);      // Calculate available Reward first before we start modifying data
        uint256 stakeAmount = current_stake.amount;                     // Remove by substracting 100% of the staked money
         
        uint256 total = stakeAmount + reward;

        delete stakers[user_index].stakes[stakeIndex];

        _mint(msg.sender, total);
        
        emit StakeWithdrawn(msg.sender, stakeAmount, reward, total, stakeIndex);

        return total;
    }
    //---------------------------------------------------------------------
    function    claimNftRewards(string memory collectionName, uint256[] memory tokenIds) external  returns(bool)
    {
        return claimNftRewardsEx(collectionName, msg.sender, tokenIds);
    }
    //---------------------------------------------------------------------
    function    claimNftRewardsEx(string memory collectionName, address userWallet, uint256[] memory tokenIds) internal returns(bool)
    {
        uint256 n = tokenIds.length;
        
        require(n<=100, "Too many NFTs to be claimed at once");
        
        TNftReward[] memory rewards = listNftStakeRewardsEx(collectionName, userWallet, tokenIds);
        
        bool hasNftStaking = false;
        
        for (uint256 i=0; i<n; i++)
        {
            uint256 tokenId = tokenIds[i];
            
            if (tokenId==0) continue;

            //-----
            
            uint256 stakingHash         = forgeNftStakingHash(collectionName, userWallet, tokenId);
            TNftStaker memory nftStaker = nftStakers[stakingHash];

            if (nftStaker.isStaking==false)            continue;       // ne pas donner de reward, car il appartient plus ou pas staker
            
            hasNftStaking = true;
            
            //-----
            
            TNftReward memory rewardObj = rewards[i];
            uint256    reward           = rewardObj.reward;
        
            require(reward>0, "No reward to be claimed");
        
            nftStakers[stakingHash].since = block.timestamp;        // On repart a zero pour les calculs

            _mint(msg.sender, reward);
        
            emit ClaimedNftReward(msg.sender, reward, nftStaker.collection);
        }
        
        return hasNftStaking;
    }
    //---------------------------------------------------------------------
    function    getUserNftRewards(string memory collectionName, address userWallet, uint256[] memory tokenIds) view external returns(uint256[] memory)
    {
        uint256 n = tokenIds.length;
        
        uint256[] memory rewardAmounts = new uint256[](n);
        
        require(n<=100, "Too many NFTs to be claimed at once");
        
        TNftReward[] memory rewards = listNftStakeRewardsEx(collectionName, userWallet, tokenIds);
        
        for (uint256 i=0; i<n; i++)
        {
            uint256 tokenId = tokenIds[i];
            
            if (tokenId==0) continue;
            
            rewardAmounts[i] = rewards[i].reward;
        }
        
        return rewardAmounts;
    }
    //---------------------------------------------------------------------
    function    getUserNftRewardsObjects(string memory collectionName, address userWallet, uint256[] memory tokenIds) view external returns(TNftReward[] memory)
    {
        uint256 n = tokenIds.length;
        
        require(n<=100, "Too many NFTs to be claimed at once");
        
        TNftReward[] memory rewards = listNftStakeRewardsEx(collectionName, userWallet, tokenIds);
        
        return rewards;
    }
    //----------------------------------------------------------------------
    function    closeNftStaking(string memory collectionName, uint256 tokenId) external returns(bool)
    {
        return closeNftStakingEx(collectionName, tokenId, msg.sender);
    }
    //----------------------------------------------------------------------
    function    closeNftStakingEx(string memory collectionName, uint256 tokenId, address userWallet) internal returns(bool)
    {
        uint256[] memory tokenIds;
        
        tokenIds    = new uint256[](1);
        tokenIds[0] = tokenId;
        
        //----- Donnons tous les PEZ reward en attente, pour ce tokenID qui sera donné a quelqu'un d'autre
        
        bool hadNftStaking = claimNftRewardsEx(collectionName, userWallet, tokenIds);

        //----- Ce user n'a plus le droit a des rewards sur ce tokenId
        
        uint256 stakingHash = forgeNftStakingHash(collectionName, userWallet, tokenId);
        
        nftStakers[stakingHash].isStaking = false;
        
        return hadNftStaking;           // prevenir si avait du staking, dans le cas d'un transfer(...), alors donner les avantages de staking au nouveau proprio
    }
    //----------------------------------------------------------------------
    function    pezNftStakingTransfer(string memory collectionName, uint256 tokenId, address from, address to) external returns(bool)
    {
        bool isCallerAllowed =  allowedNftContractAddresses[msg.sender];
        
        require(isCallerAllowed==true, "You cannot call this function directly");
        
        if (closeNftStakingEx(collectionName, tokenId, from))
        {
            return doPezNftStake(collectionName, tokenId, to);
        }
        
        return false;           // il n'y a pas eu de transfer de NFT
    }
    //----------------------------------------------------------------------
}