/**
 *Submitted for verification at Etherscan.io on 2020-08-20
*/

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.8;

// ERC20 Interface
interface ERC20 {
    function transfer(address, uint256) external returns (bool);

    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

library SafeMath {

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

contract PerlinXRewards {
    using SafeMath for uint256;
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    address public PERL;
    address public treasury;

    address[] public arrayAdmins;
    address[] public arrayPerlinPools;
    address[] public arraySynths;
    address[] public arrayMembers;

    uint256 public currentEra;

    mapping(address => bool) public isAdmin; // Tracks admin status
    mapping(address => bool) public poolIsListed; // Tracks current listing status
    mapping(address => bool) public poolHasMembers; // Tracks current staking status
    mapping(address => bool) public poolWasListed; // Tracks if pool was ever listed
    mapping(address => uint256) public mapAsset_Rewards; // Maps rewards for each asset (PERL, BAL, UNI etc)
    mapping(address => uint256) public poolWeight; // Allows a reward weight to be applied; 100 = 1.0
    mapping(uint256 => uint256) public mapEra_Total; // Total PERL staked in each era
    mapping(uint256 => bool) public eraIsOpen; // Era is open of collecting rewards
    mapping(uint256 => mapping(address => uint256)) public mapEraAsset_Reward; // Reward allocated for era
    mapping(uint256 => mapping(address => uint256)) public mapEraPool_Balance; // Perls in each pool, per era
    mapping(uint256 => mapping(address => uint256)) public mapEraPool_Share; // Share of reward for each pool, per era
    mapping(uint256 => mapping(address => uint256)) public mapEraPool_Claims; // Total LP tokens locked for each pool, per era

    mapping(address => address) public mapPool_Asset; // Uniswap pools provide liquidity to non-PERL asset
    mapping(address => address) public mapSynth_EMP; // Synthetic Assets have a management contract

    mapping(address => bool) public isMember; // Is Member
    mapping(address => uint256) public mapMember_poolCount; // Total number of Pools member is in
    mapping(address => address[]) public mapMember_arrayPools; // Array of pools for member
    mapping(address => mapping(address => uint256))
        public mapMemberPool_Balance; // Member's balance in pool
    mapping(address => mapping(address => bool)) public mapMemberPool_Added; // Member's balance in pool
    mapping(address => mapping(uint256 => bool))
        public mapMemberEra_hasRegistered; // Member has registered
    mapping(address => mapping(uint256 => mapping(address => uint256)))
        public mapMemberEraPool_Claim; // Value of claim per pool, per era
    mapping(address => mapping(uint256 => mapping(address => bool)))
        public mapMemberEraAsset_hasClaimed; // Boolean claimed

    // Events
    event Snapshot(
        address indexed admin,
        uint256 indexed era,
        uint256 rewardForEra,
        uint256 perlTotal,
        uint256 validPoolCount,
        uint256 validMemberCount,
        uint256 date
    );
    event NewPool(
        address indexed admin,
        address indexed pool,
        address indexed asset,
        uint256 assetWeight
    );
    event NewSynth(
        address indexed pool,
        address indexed synth,
        address indexed expiringMultiParty
    );
    event MemberLocks(
        address indexed member,
        address indexed pool,
        uint256 amount,
        uint256 indexed currentEra
    );
    event MemberUnlocks(
        address indexed member,
        address indexed pool,
        uint256 balance,
        uint256 indexed currentEra
    );
    event MemberRegisters(
        address indexed member,
        address indexed pool,
        uint256 amount,
        uint256 indexed currentEra
    );
    event MemberClaims(address indexed member, uint256 indexed era, uint256 totalClaim);

    // Only Admin can execute
    modifier onlyAdmin() {
        require(isAdmin[msg.sender], "Must be Admin");
        _;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }

    constructor() public {
        arrayAdmins.push(msg.sender);
        isAdmin[msg.sender] = true;
        PERL = 0xeca82185adCE47f39c684352B0439f030f860318;
        treasury = 0x3F2a2c502E575f2fd4053c76f4E21623143518d8; 
        currentEra = 1;
        _status = _NOT_ENTERED;
    }

    //==============================ADMIN================================//

    // Lists a synth and its parent EMP address
    function listSynth(
        address pool,
        address synth,
        address emp,
        uint256 weight
    ) public onlyAdmin {
        require(emp != address(0), "Must pass address validation");
        if (!poolWasListed[pool]) {
            arraySynths.push(synth); // Add new synth
        }
        listPool(pool, synth, weight); // List like normal pool
        mapSynth_EMP[synth] = emp; // Maps the EMP contract for look-up
        emit NewSynth(pool, synth, emp);
    }

    // Lists a pool and its non-PERL asset (can work for Balance or Uniswap V2)
    // Use "100" to be a normal weight of "1.0"
    function listPool(
        address pool,
        address asset,
        uint256 weight
    ) public onlyAdmin {
        require(
            (asset != PERL) && (asset != address(0)) && (pool != address(0)),
            "Must pass address validation"
        );
        require(
            weight >= 10 && weight <= 1000,
            "Must be greater than 0.1, less than 10"
        );
        if (!poolWasListed[pool]) {
            arrayPerlinPools.push(pool);
        }
        poolIsListed[pool] = true; // Tracking listing
        poolWasListed[pool] = true; // Track if ever was listed
        poolWeight[pool] = weight; // Note: weight of 120 = 1.2
        mapPool_Asset[pool] = asset; // Map the pool to its non-perl asset
        emit NewPool(msg.sender, pool, asset, weight);
    }

    function delistPool(address pool) public onlyAdmin {
        poolIsListed[pool] = false;
    }

    // Quorum Action 1
    function addAdmin(address newAdmin) public onlyAdmin {
        require(
            (isAdmin[newAdmin] == false) && (newAdmin != address(0)),
            "Must pass address validation"
        );
        arrayAdmins.push(newAdmin);
        isAdmin[newAdmin] = true;
    }

    function transferAdmin(address newAdmin) public onlyAdmin {
        require(
            (isAdmin[newAdmin] == false) && (newAdmin != address(0)),
            "Must pass address validation"
        );
        arrayAdmins.push(newAdmin);
        isAdmin[msg.sender] = false;
        isAdmin[newAdmin] = true;
    }

    // Snapshot a new Era, allocating any new rewards found on the address, increment Era
    // Admin should send reward funds first
    function snapshot(address rewardAsset) public onlyAdmin {
        snapshotInEra(rewardAsset, currentEra); // Snapshots PERL balances
        currentEra = currentEra.add(1); // Increment the eraCount, so users can't register in a previous era.
    }

    // Snapshot a particular rewwardAsset, but don't increment Era (like Balancer Rewards)
    // Do this after snapshotPools()
    function snapshotInEra(address rewardAsset, uint256 era) public onlyAdmin {
        uint256 start = 0;
        uint256 end = poolCount();
        snapshotInEraWithOffset(rewardAsset, era, start, end);
    }

    // Snapshot with offset (in case runs out of gas)
    function snapshotWithOffset(
        address rewardAsset,
        uint256 start,
        uint256 end
    ) public onlyAdmin {
        snapshotInEraWithOffset(rewardAsset, currentEra, start, end); // Snapshots PERL balances
        currentEra = currentEra.add(1); // Increment the eraCount, so users can't register in a previous era.
    }

    // Snapshot a particular rewwardAsset, with offset
    function snapshotInEraWithOffset(
        address rewardAsset,
        uint256 era,
        uint256 start,
        uint256 end
    ) public onlyAdmin {
        require(rewardAsset != address(0), "Address must not be 0x0");
        require(
            (era >= currentEra - 1) && (era <= currentEra),
            "Must be current or previous era only"
        );
        uint256 amount = ERC20(rewardAsset).balanceOf(address(this)).sub(
            mapAsset_Rewards[rewardAsset]
        );
        require(amount > 0, "Amount must be non-zero");
        mapAsset_Rewards[rewardAsset] = mapAsset_Rewards[rewardAsset].add(
            amount
        );
        mapEraAsset_Reward[era][rewardAsset] = mapEraAsset_Reward[era][rewardAsset]
            .add(amount);
        eraIsOpen[era] = true;
        updateRewards(era, amount, start, end); // Snapshots PERL balances
    }

    // Note, due to EVM gas limits, poolCount should be less than 100 to do this before running out of gas
    function updateRewards(
        uint256 era,
        uint256 rewardForEra,
        uint256 start,
        uint256 end
    ) internal {
        // First snapshot balances of each pool
        uint256 perlTotal;
        uint256 validPoolCount;
        uint256 validMemberCount;
        for (uint256 i = start; i < end; i++) {
            address pool = arrayPerlinPools[i];
            if (poolIsListed[pool] && poolHasMembers[pool]) {
                validPoolCount = validPoolCount.add(1);
                uint256 weight = poolWeight[pool];
                uint256 weightedBalance = (
                    ERC20(PERL).balanceOf(pool).mul(weight)).div(100); // (depth * weight) / 100
                perlTotal = perlTotal.add(weightedBalance);
                mapEraPool_Balance[era][pool] = weightedBalance;
            }
        }
        mapEra_Total[era] = perlTotal;
        // Then snapshot share of the reward for the era
        for (uint256 i = start; i < end; i++) {
            address pool = arrayPerlinPools[i];
            if (poolIsListed[pool] && poolHasMembers[pool]) {
                validMemberCount = validMemberCount.add(1);
                uint256 part = mapEraPool_Balance[era][pool];
                mapEraPool_Share[era][pool] = getShare(
                    part,
                    perlTotal,
                    rewardForEra
                );
            }
        }
        emit Snapshot(
            msg.sender,
            era,
            rewardForEra,
            perlTotal,
            validPoolCount,
            validMemberCount,
            now
        );
    }

    // Quorum Action
    // Remove unclaimed rewards and disable era for claiming
    function removeReward(uint256 era, address rewardAsset) public onlyAdmin {
      uint256 amount = mapEraAsset_Reward[era][rewardAsset];
      mapEraAsset_Reward[era][rewardAsset] = 0;
      mapAsset_Rewards[rewardAsset] = mapAsset_Rewards[rewardAsset].sub(
          amount
      );
      eraIsOpen[era] = false;
      require(
            ERC20(rewardAsset).transfer(treasury, amount),
            "Must transfer"
        );
    }

    // Quorum Action - Reuses adminApproveEraAsset() logic since unlikely to collide
    // Use in anger to sweep off assets (such as accidental airdropped tokens)
    function sweep(address asset, uint256 amount) public onlyAdmin {
      require(
            ERC20(asset).transfer(treasury, amount),
            "Must transfer"
        );
    }

    //============================== USER - LOCK/UNLOCK ================================//
    // Member locks some LP tokens
    function lock(address pool, uint256 amount) public nonReentrant {
        require(poolIsListed[pool] == true, "Must be listed");
        if (!isMember[msg.sender]) {
            // Add new member
            arrayMembers.push(msg.sender);
            isMember[msg.sender] = true;
        }
        if (!poolHasMembers[pool]) {
            // Records existence of member
            poolHasMembers[pool] = true;
        }
        if (!mapMemberPool_Added[msg.sender][pool]) {
            // Record all the pools member is in
            mapMember_poolCount[msg.sender] = mapMember_poolCount[msg.sender]
                .add(1);
            mapMember_arrayPools[msg.sender].push(pool);
            mapMemberPool_Added[msg.sender][pool] = true;
        }
        require(
            ERC20(pool).transferFrom(msg.sender, address(this), amount),
            "Must transfer"
        ); // Uni/Bal LP tokens return bool
        mapMemberPool_Balance[msg.sender][pool] = mapMemberPool_Balance[msg.sender][pool]
            .add(amount); // Record total pool balance for member
        registerClaim(msg.sender, pool, amount); // Register claim
        emit MemberLocks(msg.sender, pool, amount, currentEra);
    }

    // Member unlocks all from a pool
    function unlock(address pool) public nonReentrant {
        uint256 balance = mapMemberPool_Balance[msg.sender][pool];
        require(balance > 0, "Must have a balance to claim");
        mapMemberPool_Balance[msg.sender][pool] = 0; // Zero out balance
        require(ERC20(pool).transfer(msg.sender, balance), "Must transfer"); // Then transfer
        if (ERC20(pool).balanceOf(address(this)) == 0) {
            poolHasMembers[pool] = false; // If nobody is staking any more
        }
        emit MemberUnlocks(msg.sender, pool, balance, currentEra);
    }

    //============================== USER - CLAIM================================//
    // Member registers claim in a single pool
    function registerClaim(
        address member,
        address pool,
        uint256 amount
    ) internal {
        mapMemberEraPool_Claim[member][currentEra][pool] += amount;
        mapEraPool_Claims[currentEra][pool] = mapEraPool_Claims[currentEra][pool]
            .add(amount);
        emit MemberRegisters(member, pool, amount, currentEra);
    }

    // Member registers claim in all pools
    function registerAllClaims(address member) public {
        require(
            mapMemberEra_hasRegistered[msg.sender][currentEra] == false,
            "Must not have registered in this era already"
        );
        for (uint256 i = 0; i < mapMember_poolCount[member]; i++) {
            address pool = mapMember_arrayPools[member][i];
            // first deduct any previous claim
            mapEraPool_Claims[currentEra][pool] = mapEraPool_Claims[currentEra][pool]
                .sub(mapMemberEraPool_Claim[member][currentEra][pool]);
            uint256 amount = mapMemberPool_Balance[member][pool]; // then get latest balance
            mapMemberEraPool_Claim[member][currentEra][pool] = amount; // then update the claim
            mapEraPool_Claims[currentEra][pool] = mapEraPool_Claims[currentEra][pool]
                .add(amount); // then add to total
            emit MemberRegisters(member, pool, amount, currentEra);
        }
        mapMemberEra_hasRegistered[msg.sender][currentEra] = true;
    }

    // Member claims in a era
    function claim(uint256 era, address rewardAsset)
        public
        nonReentrant
    {
        require(
            mapMemberEraAsset_hasClaimed[msg.sender][era][rewardAsset] == false,
            "Reward asset must not have been claimed"
        );
        require(eraIsOpen[era], "Era must be opened");
        uint256 totalClaim = checkClaim(msg.sender, era);
        if (totalClaim > 0) {
            mapMemberEraAsset_hasClaimed[msg.sender][era][rewardAsset] = true; // Register claim
            mapEraAsset_Reward[era][rewardAsset] = mapEraAsset_Reward[era][rewardAsset]
                .sub(totalClaim); // Decrease rewards for that era
            mapAsset_Rewards[rewardAsset] = mapAsset_Rewards[rewardAsset].sub(
                totalClaim
            ); // Decrease rewards in total
            require(
                ERC20(rewardAsset).transfer(msg.sender, totalClaim),
                "Must transfer"
            ); // Then transfer
        }
        emit MemberClaims(msg.sender, era, totalClaim);
        if (mapMemberEra_hasRegistered[msg.sender][currentEra] == false) {
            registerAllClaims(msg.sender); // Register another claim
        }
    }

    // Member checks claims in all pools
    function checkClaim(address member, uint256 era)
        public
        view
        returns (uint256 totalClaim)
    {
        for (uint256 i = 0; i < mapMember_poolCount[member]; i++) {
            address pool = mapMember_arrayPools[member][i];
            totalClaim += checkClaimInPool(member, era, pool);
        }
        return totalClaim;
    }

    // Member checks claim in a single pool
    function checkClaimInPool(
        address member,
        uint256 era,
        address pool
    ) public view returns (uint256 claimShare) {
        uint256 poolShare = mapEraPool_Share[era][pool]; // Requires admin snapshotting for era first, else 0
        uint256 memberClaimInEra = mapMemberEraPool_Claim[member][era][pool]; // Requires member registering claim in the era
        uint256 totalClaimsInEra = mapEraPool_Claims[era][pool]; // Sum of all claims in a era
        if (totalClaimsInEra > 0) {
            // Requires non-zero balance of the pool tokens
            claimShare = getShare(
                memberClaimInEra,
                totalClaimsInEra,
                poolShare
            );
        } else {
            claimShare = 0;
        }
        return claimShare;
    }

    //==============================UTILS================================//
    // Get the share of a total
    function getShare(
        uint256 part,
        uint256 total,
        uint256 amount
    ) public pure returns (uint256 share) {
        return (amount.mul(part)).div(total);
    }

    function adminCount() public view returns (uint256) {
        return arrayAdmins.length;
    }

    function poolCount() public view returns (uint256) {
        return arrayPerlinPools.length;
    }

    function synthCount() public view returns (uint256) {
        return arraySynths.length;
    }

    function memberCount() public view returns (uint256) {
        return arrayMembers.length;
    }
}