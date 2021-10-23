/**
 *Submitted for verification at Etherscan.io on 2021-10-22
*/

// SPDX-License-Identifier: MIT

interface TokenInterfaceV5{
    function burn(address, uint256) external;
    function mint(address, uint256) external;
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns(bool);
    function balanceOf(address) external view returns(uint256);
    function hasRole(bytes32, address) external view returns (bool);
    function approve(address, uint256) external returns (bool);
    function allowance(address, address) external view returns (uint256);
}
interface LpInterfaceV5{
   	function getReserves() external view returns (uint112, uint112, uint32);
    function token0() external view returns (address);
    function transfer(address, uint) external returns (bool);
    function transferFrom(address, address, uint256) external;
    function totalSupply() external view returns (uint);
    function balanceOf(address) external view returns (uint);
    function approve(address, uint256) external returns (bool);
}
interface NftInterfaceV5{
    function balanceOf(address) external view returns (uint);
    function ownerOf(uint) external view returns (address);
    function transferFrom(address, address, uint) external;
    function tokenOfOwnerByIndex(address, uint) external view returns(uint);
}
interface QuickStakingContractInterfaceV5{
	function earned(address) external view returns (uint256);
	function getReward() external;
	function stake(uint) external;
	function withdraw(uint) external;
	function balanceOf(address) external view returns (uint256);
}
pragma solidity 0.8.7;

contract GNSPoolV5{

    // Constants
    bytes32 public constant MINTER_ROLE = 0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6;
    TokenInterfaceV5 public constant quick = TokenInterfaceV5(0xd9f7bAc803B178248465D7D9E5CcC397eAA2888F);
    QuickStakingContractInterfaceV5 public constant quickStakingContract = QuickStakingContractInterfaceV5(0x74B5166cA6575a98B05311162FEd05F492F39649);

    // Contracts & Addresses
    TokenInterfaceV5 public token; // GNS
    LpInterfaceV5 public lp; // GNS/DAI
    mapping(address => bool) public allowedContracts;
    address public govFund = 0xec9581354f7750Bc8194E3e801f8eE1D91e2a8Ac;

    // Pool variables
    uint public accTokensPerLp;
    uint public accQuickPerLp; // Dual rewards
    uint public lpBalance;

    // Pool parameters
    uint public maxNftsStaked = 3;
    uint public referralP = 6; // % 2 == 0
    uint[5] public boostsP = [3, 5, 8, 13, 21];

    // Pool stats
    uint public rewardsToken; // 1e18
    uint public rewardsQuick; // 1e18

    // Mappings
    mapping(address => User) public users;
    mapping(address => mapping(uint => StakedNft)) public userNfts;

    // Structs
    struct StakedNft{
        uint nftId;
        uint nftType;
    }
    struct User{
        uint provided;
        uint debtToken;
        uint debtQuick;
        uint stakedNftsCount;
        uint totalBoost;
        address referral;
        uint referralRewardsToken;
    }

    // Events
    event AddressUpdated(string name, address a);
    event ContractAllowed(address a, bool allowed);
    event BoostsUpdated(uint[5]);
    event NumberUpdated(string name, uint value);

    constructor(address _tradingStorage){
        require(_tradingStorage != address(0), "ADDRESS_0");
        allowedContracts[_tradingStorage] = true;
    }

    // GOV => UPDATE VARIABLES & MANAGE PAIRS

    // 0. Modifiers
    modifier onlyGov(){
        require(msg.sender == govFund, "GOV_ONLY");
        _;
    }

    // Set addresses
    function setGovFund(address _gov) external onlyGov{
        require(_gov != address(0), "ADDRESS_0");
        govFund = _gov;
        emit AddressUpdated("govFund", _gov);
    }
    function setToken(TokenInterfaceV5 _token) external onlyGov{
        require(address(_token) != address(0), "ADDRESS_0");
        require(address(token) == address(0), "ALREADY_SET");
        token = _token;
        emit AddressUpdated("token", address(_token));
    }
    function setLp(LpInterfaceV5 _lp) external onlyGov{
        require(address(_lp) != address(0), "ADDRESS_0");
        require(address(lp) == address(0), "ALREADY_SET");
        lp = _lp;
        emit AddressUpdated("lp", address(_lp));
    }
    function addAllowedContract(address c) external onlyGov{
        require(c != address(0), "ADDRESS_0");
        require(token.hasRole(MINTER_ROLE, c), "NOT_MINTER");
        allowedContracts[c] = true;
        emit ContractAllowed(c, true);
    }
    function removeAllowedContract(address c) external onlyGov{
        require(c != address(0), "ADDRESS_0");
        allowedContracts[c] = false;
        emit ContractAllowed(c, false);
    }
    function setBoostsP(uint _bronze, uint _silver, uint _gold, uint _platinum, uint _diamond) external onlyGov{
        require(_bronze < _silver && _silver < _gold && _gold < _platinum && _platinum < _diamond && _bronze > 0, "WRONG_VALUES");
        boostsP = [_bronze, _silver, _gold, _platinum, _diamond];
        emit BoostsUpdated(boostsP);
    }
    function setMaxNftsStaked(uint _maxNftsStaked) external onlyGov{
        require(_maxNftsStaked >= 3, "BELOW_3");
        maxNftsStaked = _maxNftsStaked;
        emit NumberUpdated("maxNftsStaked", _maxNftsStaked);
    }
    function setReferralP(uint _referralP) external onlyGov{
        require(_referralP % 2 == 0, "NOT_EVEN");
        referralP = _referralP;
        emit NumberUpdated("referralP", _referralP);
    }

    // USEFUL FUNCTIONS

    // Remove access to contracts
    modifier notContract(){
        require(tx.origin == msg.sender, "CONTRACT");
        _;
    }

    // Get reserves LP
    function reservesLp() public view returns(uint, uint){
        (uint112 reserves0, uint112 reserves1, ) = lp.getReserves();
        return lp.token0() == address(token) ? (reserves0, reserves1) : (reserves1, reserves0);
    }

    // Called by Gains.farm ecosystem allowed contracts (trading, casino, etc.)
    function increaseAccTokensPerLp(uint _amount) external{
        require(allowedContracts[msg.sender] && token.hasRole(MINTER_ROLE, msg.sender), "ONLY_ALLOWED_CONTRACTS");
        if(lpBalance > 0){
            accTokensPerLp += _amount * 1e18 / lpBalance;
            rewardsToken += _amount;
        }
    }

    // Compute NFT boosts
    function setBoosts() private{
        User storage u = users[msg.sender];
        u.totalBoost = 0;
        for(uint i = 0; i < u.stakedNftsCount; i++){
            u.totalBoost += u.provided * boostsP[userNfts[msg.sender][i].nftType-1] / 100;
        }
        u.debtToken = (u.provided + u.totalBoost) * accTokensPerLp / 1e18;
        u.debtQuick = (u.provided + u.totalBoost) * accQuickPerLp / 1e18;
    }

    // Rewards to be harvested
    function pendingRewardToken() view public returns(uint){
        User storage u = users[msg.sender];
        return (u.provided + u.totalBoost) * accTokensPerLp / 1e18 - u.debtToken;
    }
    function pendingRewardQuick() view public returns(uint){
        if(lpBalance == 0){ return 0; }
        User storage u = users[msg.sender];
        uint pendingAccQuickPerLp = accQuickPerLp + quickStakingContract.earned(address(this)) * 1e18 / lpBalance;
        return (u.provided + u.totalBoost) * pendingAccQuickPerLp / 1e18 - u.debtQuick;
    }

    // EXTERNAL FUNCTIONS

    // Harvest rewards
    function harvest() public{
        if(lpBalance == 0){ return; }
        
        User storage u = users[msg.sender];

        uint pendingTokens = pendingRewardToken();

        if(pendingTokens > 0){
            if(u.referral == address(0)){
                token.mint(msg.sender, pendingTokens - pendingTokens * referralP / 100);
            }else{
                uint referralReward = pendingTokens * referralP / 200;

                token.mint(msg.sender, pendingTokens - referralReward);
                token.mint(u.referral, referralReward);

                users[u.referral].referralRewardsToken += referralReward;
            }
        }

        u.debtToken = (u.provided + u.totalBoost) * accTokensPerLp / 1e18;

        uint pendingQuick = pendingRewardQuick();
        uint pendingQuickTotal = quickStakingContract.earned(address(this));

        quickStakingContract.getReward();
        accQuickPerLp += pendingQuickTotal * 1e18 / lpBalance;

        u.debtQuick = (u.provided + u.totalBoost) * accQuickPerLp / 1e18;
        rewardsQuick += pendingQuickTotal;

        if(pendingQuick > 0){ quick.transfer(msg.sender, pendingQuick); }
    }

    // Stake LPs
    function stake(uint amount, address referral) external{
        User storage u = users[msg.sender];
        
        // 1. Transfer the LPs to the contract
        lp.transferFrom(msg.sender, address(this), amount);

        // 2. Harvest pending rewards
        harvest();

        // 3. Stake in quickswap contract
        require(lp.approve(address(quickStakingContract), amount), "APPROVE_FAILED");
        quickStakingContract.stake(amount);

        // 4. Reset lp balance
        lpBalance -= (u.provided + u.totalBoost);

        // 5. Set user provided
        u.provided += amount;

        // 6. Set boosts and debt
        setBoosts();

        // 7. Update lp balance
        lpBalance += (u.provided + u.totalBoost);

        // 8. Set referral
        if(u.referral == address(0) && referral != address(0) && referral != msg.sender){
            u.referral = referral;
        }
    }

    // Stake NFT
    // NFT types: 1, 2, 3, 4, 5
    function stakeNft(uint nftType, uint nftId) external notContract{
        User storage u = users[msg.sender];

        // 0. If didn't already stake NFT + nft type is either platinum or diamond
        require(u.stakedNftsCount < maxNftsStaked, "MAX_NFTS_ALREADY_STAKED");
        require(nftType >= 1 && nftType <= 5, "WRONG_NFT_TYPE");

        // 1. Transfer the NFT to the contract
        require(nfts()[nftType-1].balanceOf(msg.sender) >= 1, "NOT_NFT_OWNER");
        nfts()[nftType-1].transferFrom(msg.sender, address(this), nftId);

        // 2. Harvest pending rewards
        harvest();

        // 3. Reset lp balance
        lpBalance -= (u.provided + u.totalBoost);

        // 4. Store NFT info
        StakedNft storage stakedNft = userNfts[msg.sender][u.stakedNftsCount];
        stakedNft.nftType = nftType;
        stakedNft.nftId = nftId;
        u.stakedNftsCount ++;

        // 5. Set user boosts & debt
        setBoosts();

        // 6. Update lp balance
        lpBalance += (u.provided + u.totalBoost);
    }

    // Unstake NFT
    function unstakeNft(uint nftIndex) external{
        User storage u = users[msg.sender];
        StakedNft memory stakedNft = userNfts[msg.sender][nftIndex];

        // 1. Harvest pending rewards
        harvest();

        // 2. Reset lp balance
        lpBalance -= (u.provided + u.totalBoost);

        // 3. Remove NFT from storage => replace by last one and remove last one
        userNfts[msg.sender][nftIndex] = userNfts[msg.sender][u.stakedNftsCount-1];
        delete userNfts[msg.sender][u.stakedNftsCount-1];
        u.stakedNftsCount -= 1;

        // 4. Set user boosts & debt
        setBoosts();

        // 5. Update lp balance
        lpBalance += (u.provided + u.totalBoost);

        // 6. Transfer the NFT to the user
        nfts()[stakedNft.nftType-1].transferFrom(address(this), msg.sender, stakedNft.nftId);
    }

    // Unstake LPs
    function unstake(uint amount) external{
        // 1. Verify he doesn't unstake more than provided
        User storage u = users[msg.sender];
        require(amount <= u.provided, "AMOUNT_TOO_BIG");

        // 2. Harvest pending rewards
        harvest();

        // 3. Unstake from quickswap contract
        quickStakingContract.withdraw(amount);

        // 4. Reset lp balance
        lpBalance -= (u.provided + u.totalBoost);

        // 5. Set user provided
        u.provided -= amount;

        // 6. Set boosts and debt
        setBoosts();

        // 7. Update lp balance
        lpBalance += (u.provided + u.totalBoost);

        // 8. Transfer the LPs to the address
        lp.transfer(msg.sender, amount);
    }

    // READ-ONLY VIEW FUNCTIONS

    // 1e5 precision
    function tvl() external view returns(uint){
        if(lp.totalSupply() == 0){ return 0; }

        (, uint reserveDai) = reservesLp();
        uint lpPriceDai = reserveDai * 1e5 * 2 / lp.totalSupply();

        return quickStakingContract.balanceOf(address(this)) * lpPriceDai / 1e18;
    }
    // 1e5 precision
    function tvlWithBoosts() external view returns(uint){
        if(lp.totalSupply() == 0){ return 0; }

        (, uint reserveDai) = reservesLp();
        uint lpPriceDai = reserveDai * 1e5 * 2 / lp.totalSupply();

        return lpBalance * lpPriceDai / 1e18;
    }

    // NFTs list
    function nfts() public pure returns(NftInterfaceV5[5] memory){
        return [
            NftInterfaceV5(0xa3b188D7E71Bf82A221952Eb5F7f7cFa0BBE1E6b),
            NftInterfaceV5(0xaB026f75baBAd737b5577A96aB9cF3fC73AEcCdB),
            NftInterfaceV5(0x53E538a7e64088dC38eA6c4F9ECa962D6a377499),
            NftInterfaceV5(0xd1d62dEe7d0Faad7d589dEcFd564AE19FfF14Eab),
            NftInterfaceV5(0xba62117a7fBb7e327f0277Ac39f420e83c220f60)
        ];
    }
}