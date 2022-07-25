/**
 *Submitted for verification at cronoscan.com on 2022-06-07
*/

pragma solidity ^0.8.14;

// SPDX-License-Identifier: MIT

interface ICRC20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}
interface ICRC721{
    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory  data) external payable;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function approve(address _approved, uint256 _tokenId) external payable;
    function setApprovalForAll(address _operator, bool _approved) external;
    function getApproved(uint256 _tokenId) external view returns (address);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed_tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

}

contract NFTStakeContract {

    //Variables
    //tokens
    ICRC20 public RewardToken;
    ICRC721 public NFT;

    //address
    address payable public owner;
    address payable public rewardAddress;

    //uint
    uint256 public totalNewUser;
    uint256 public totalStaked;

    //arrays
    uint256[4] public tireRewardAmount = [30_000, 60_100, 90_400, 120_900];
    uint256[4] public durations = [30 days, 90 days, 180 days, 365 days];

    
    //structures
    struct Stake {
        ICRC721 token;
        uint256 stakeTime;
        uint256 withdrawTime;
        uint256 amount;
        uint256 [] ids;
        uint256 bonus;
        uint256 plan;
        bool withdrawan;
        bool unstaked;
    }

    struct User {
        uint256 totalstakeduser;
        uint256 stakecount;
        uint256 claimedTokens;
        uint256 unStakedTokens;
        mapping(uint256 => Stake) stakerecord;
    }

    //mappings
    mapping(address => User) public users;
    mapping(address => bool) public newuser;

    //modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: Not an owner");
        _;
    }

    //events
    event Staked(
        address indexed _user,
        uint256 [] _ids,
        uint256 indexed _Time
    );

    event UnStaked(
        address indexed _user,
        uint256 [] _ids,
        uint256 indexed _Time
    );

    event Withdrawn(
        address indexed _user,
        uint256 indexed _reward,
        uint256 [] _ids,
        uint256 indexed _Time
    );

    event NewUser(address indexed _user);

    // constructor
    constructor(ICRC20 _RewardToken,ICRC721 _NFT){
        owner = payable(msg.sender);//owner address
        rewardAddress =  payable(msg.sender);//rewar address
        RewardToken = _RewardToken;//reward token address
        NFT = _NFT;//nft token address
        tireRewardAmount[0] = 1_500*(10**(RewardToken.decimals()));
        tireRewardAmount[1] = 2_100*(10**(RewardToken.decimals()));
        tireRewardAmount[2] = 4_400*(10**(RewardToken.decimals()));
        tireRewardAmount[3] = 6_900*(10**(RewardToken.decimals()));
        
    }

    // functions


    //writeable
    function stake(uint256 [] memory ids, uint256 plan,ICRC721 _nft) public {
        require(plan < durations.length, "put valid plan details");
        require(_nft == NFT , "put valid nft address");
        if (!newuser[msg.sender]) {
            newuser[msg.sender] = true;
            totalNewUser++;
            emit NewUser(msg.sender);
        }
        User storage user = users[msg.sender];
        
        
        for(uint256 index = 0; index <ids.length;index++){
          NFT.transferFrom(msg.sender, address(this), ids[index]);
        }
         uint256 rewardPerNFT = tireRewardAmount[plan];

        user.totalstakeduser += ids.length;
        user.stakerecord[user.stakecount].plan = plan;
        user.stakerecord[user.stakecount].stakeTime = block.timestamp;
        user.stakerecord[user.stakecount].amount = ids.length;
        user.stakerecord[user.stakecount].ids = ids;
        user.stakerecord[user.stakecount].withdrawTime = block.timestamp+(durations[plan]);
        user.stakerecord[user.stakecount].bonus = ids.length*(rewardPerNFT);
        user.stakerecord[user.stakecount].token = _nft;
        user.stakecount++;
        totalStaked += ids.length;
        emit Staked(msg.sender, ids, block.timestamp);
    }


    function withdraw(uint256 count) public {
        User storage user = users[msg.sender];
        require(user.stakecount >= count, "Invalid Stake index");
        require(
            !user.stakerecord[count].withdrawan,
            " withdraw completed "
        );
        require(
            !user.stakerecord[count].unstaked,
            " withdraw completed "
        );
        //return nfts
        for(uint256 index = 0; index <user.stakerecord[count].ids.length;index++){
          user.stakerecord[count].token.transferFrom(address(this), msg.sender, user.stakerecord[count].ids[index]);
        }
        RewardToken.transferFrom(
            rewardAddress,
            msg.sender,
            (user.stakerecord[count].bonus)
        );
        user.claimedTokens += user.stakerecord[count].amount;
        user.claimedTokens += user.stakerecord[count].bonus;
        user.stakerecord[count].withdrawan = true;
        emit Withdrawn(
            msg.sender,
            user.stakerecord[count].bonus,
            user.stakerecord[count].ids,
            block.timestamp);
    }

    function unstake(uint256 count) public {
        User storage user = users[msg.sender];
        require(user.stakecount >= count, "Invalid Stake index");
        require(
            !user.stakerecord[count].withdrawan,
            " withdraw completed "
        );
        require(
            !user.stakerecord[count].unstaked,
            " unstake completed "
        );
        //return nfts
        for(uint256 index = 0; index <user.stakerecord[count].ids.length;index++){
          user.stakerecord[count].token.transferFrom(address(this), msg.sender, user.stakerecord[count].ids[index]);
        }
        user.unStakedTokens += user.stakerecord[count].amount;
        user.stakerecord[count].unstaked = true;
        emit UnStaked(
            msg.sender,
            user.stakerecord[count].ids,
            block.timestamp
        );
    }

    function changeOwner(address payable _newOwner) external onlyOwner {
        owner = _newOwner;
    }
    function changeRewardAddress(address payable _newRewardAddress) external onlyOwner {
        rewardAddress = _newRewardAddress;
    }

    function migrateStuckFunds() external onlyOwner {
        owner.transfer(address(this).balance);
    }

    function migratelostToken(address lostToken) external onlyOwner {
        ICRC20(lostToken).transfer(
            owner,
            ICRC20(lostToken).balanceOf(address(this))
        );
    }
    function migratelostNFT(address lostNFT) external onlyOwner {
        ICRC721(lostNFT).transferFrom(
            address(this),
            owner,
            ICRC721(lostNFT).balanceOf(address(this))
        );
    }

    function setTokenaddress(ICRC20 _rewardToken,ICRC721 _nft)external onlyOwner{
        RewardToken = _rewardToken;
        NFT = _nft;
    }
    function settireRewardAmount(uint256 _tireRewardAmount,uint256 _tireRewardAmount2,uint256 _tireRewardAmount3,uint256 _tireRewardAmount4)external onlyOwner{
        tireRewardAmount[0] = _tireRewardAmount;
        tireRewardAmount[1] = _tireRewardAmount2;
        tireRewardAmount[2] = _tireRewardAmount3;
        tireRewardAmount[3] = _tireRewardAmount4;
    }
    function setDuration(uint256 _duration,uint256 _duration2,uint256 _duration3,uint256 _duration4)external onlyOwner{
        durations[0] = _duration;
        durations[1] = _duration2;
        durations[2] = _duration3;
        durations[3] = _duration4;
    }

    //readable
    
    function stakedetails(address add, uint256 count)
        public
        view
        returns (
        ICRC721 token,
        uint256 withdrawTime,
        uint256 [] memory ids,
        uint256 bonus,
        bool withdrawan,
        bool unstaked
        )
    {
        return (
            users[add].stakerecord[count].token,
            users[add].stakerecord[count].withdrawTime,
            users[add].stakerecord[count].ids,
            users[add].stakerecord[count].bonus,
            users[add].stakerecord[count].withdrawan,
            users[add].stakerecord[count].unstaked
        );
    }

    function calculateRewards(uint256 [] calldata ids, uint256 plan)
        external
        view
        returns (uint256)
    {
          uint256 rewardPerNFT = tireRewardAmount[plan];
        
        return (ids.length*(rewardPerNFT));
    }

    function currentStaked(address add) external view returns (uint256) {
        uint256 currentstaked;
        for (uint256 i; i < users[add].stakecount; i++) {
            if (!users[add].stakerecord[i].withdrawan) {
                currentstaked += users[add].stakerecord[i].amount;
            }
        }
        return currentstaked;
    }
    function getContractTokenBalanceRewardToken() external view returns (uint256) {
        return RewardToken.allowance(owner, address(this));
    }
    function getContractTokenBalanceNFTToken() external view returns (uint256) {
        return NFT.balanceOf(address(this));
    }

    function getCurrentwithdrawTime() external view returns (uint256) {
        return block.timestamp;
    }
}