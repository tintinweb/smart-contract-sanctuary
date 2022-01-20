// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./Ownable.sol";

import "./Strings.sol";

import "./VRFConsumerBase.sol";

import "./Whitelist.sol";

import "./GFCGenesisWeapon.sol";

import "./SafeERC20.sol";

import "./GFCMysteryItem.sol";

contract GFCBlackSmith is Ownable, Whitelist, VRFConsumerBase {
    using SafeERC20 for IERC20;
    using Strings for uint256;

    GFCGenesisWeapon public genesisWeapon;
    GFCMysteryItem public mysteryItem;

    // ERC20 basic token contract being held
    IERC20 public immutable TOKEN;
    
    uint256 private constant ROLL_IN_PROGRESS = 42;

    //The amount of GCOIN burnt to forge
    uint256 public forgeCost = 200 ether;

    //constant for VRF function
    bytes32 internal keyHash;
    uint256 internal fee;

    //arrays of total number of melee weapons in each tier
    uint16[] public meleeWeaponCount;

    //arrays of total number of ranged weapons in each tier
    uint16[] public rangedWeaponCount;

    //arrays of number of weapon required to forge the next tier
    uint16[] public weaponForgeRate;

    //In case we need to pause weapon forge
    bool paused;

    uint256 public asteroidsForgeRewardId = 2;
    
    mapping(bytes32 => address) private s_rollers;
    mapping(address => uint256) private s_results;

    event DiceRolled(bytes32 indexed requestId, address indexed roller);
    event DiceLanded(bytes32 indexed requestId, uint256 indexed result);
    event WeaponForged(address account, uint256 tokenId);
    event RewardMinted(address account, uint256 tokenId);

    constructor(IERC20 token_)
        VRFConsumerBase(
                0x3d2341ADb2D31f1c5530cDC622016af293177AE0, 
                0xb0897686c545045aFc77CF20eC7A532E3120E0F1
        ) 
    {
        keyHash = 0xf86195cf7690c55907b2b611ebb7343a6f649bff128701cc542f0569e2c549da;
        fee = 1 * 10 ** 14; //0.0001 Link as fee on Polygon

        TOKEN = token_;

        //fill in the addresses for the corresponding contract addresses before deployment
        genesisWeapon = GFCGenesisWeapon(address(0xCbc964dd716F07b4965B4526E30541a66F414ccF));
        mysteryItem = GFCMysteryItem(address(0xFd24D200C6715f3C0a2DdF8a8b128952eFed7724));

        //Initalise the total number of weapons
        meleeWeaponCount =    [0, 3, 2, 1, 3, 2, 1, 1, 1];
        rangedWeaponCount =   [0, 2, 4, 11, 5, 6, 2, 1, 1];

        //Initalise the weapon forge rate;
        weaponForgeRate = [0, 4, 4, 3, 2, 2, 2, 2];
    }

    function chargeGCOIN() internal {
        //Charge user the GCOIN required from the forge
        IERC20(TOKEN).safeTransferFrom(msg.sender, address(this), forgeCost);
    }

    /** 
     * Requests randomness 
     */
    function getRandNum4Forge() public {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK to pay fee");
        require(s_results[msg.sender] == 0, "Already rolled");
        bytes32 requestId = requestRandomness(keyHash, fee);
        s_rollers[requestId] = msg.sender;
        s_results[msg.sender] = ROLL_IN_PROGRESS;
        emit DiceRolled(requestId, msg.sender);
    }

    function forgeWeapon(uint256 category, uint256 tier, uint256[] calldata amounts) public{
        require(!paused, "The contract have been paused");
        require(tier > 0 && tier < 9, "invalid tier input (must be between 1 and 8)");
        require(category > 0 && category < 3, "invalid category (must be 1 or 2)");
        checkIngedients(category, tier, amounts);
        burnIngedients(category, tier, amounts);
        chargeGCOIN();
        uint256 tokenId = mintNextTier(category, tier);
        emit WeaponForged(msg.sender, tokenId);
        s_results[msg.sender] = 0;
    }

    function forgeWithOGWeapon(uint256 category, uint256[] calldata amounts) public {
        require(!paused, "The contract have been paused");
        require(category > 0 && category < 3, "invalid category (must be 1 or 2)");
        uint256 tokenId;
        uint256 randNum;
        uint256 tier;
        if(category == 1) {
            require(genesisWeapon.balanceOf(msg.sender, 13001) > 0, "You must have at least 1 OG's boxing gloves");
            checkIngedients(category, 3, amounts);
            burnIngedients(category, 3, amounts);
            randNum = getResult(msg.sender);
            tier = 3;
            //33% chance to skip a tier
            if(randNum % 100 <= 33) {tier++;}
            chargeGCOIN();
            tokenId = mintNextTier(category, tier);
        }else if(category == 2) {
            require(genesisWeapon.balanceOf(msg.sender, 24005) > 0, "You must have at least 1 Doctore's crossbow");
            checkIngedients(category, 4, amounts);
            burnIngedients(category, 4, amounts);
            randNum = getResult(msg.sender);
            tier = 4;
            //50% chance to skip a tier
            if(randNum % 100 <= 50) {tier++;}
            chargeGCOIN();
            tokenId = mintNextTier(category, tier);
        }else{
            revert();
        }
        emit WeaponForged(msg.sender, tokenId);
        s_results[msg.sender] = 0;
    }

    function forgeAsteroids() public {
        require(!paused, "The contract have been paused");
        require(genesisWeapon.balanceOf(msg.sender, 26000) > 0, "You must have at least 1 Brown Asteroid");
        require(genesisWeapon.balanceOf(msg.sender, 26001) > 0, "You must have at least 1 Green Asteroid");
        require(genesisWeapon.balanceOf(msg.sender, 16000) > 0, "You must have at least 1 Pink Asteroid");
        genesisWeapon.burn(msg.sender, 26000, 1);
        genesisWeapon.burn(msg.sender, 26001, 1);
        genesisWeapon.burn(msg.sender, 16000, 1);
        chargeGCOIN();
        uint256 tokenId = mintNextTier(getResult(msg.sender)%2, 7);
        emit WeaponForged(msg.sender, tokenId);
        mysteryItem.devMint(msg.sender, asteroidsForgeRewardId, 1);
        emit RewardMinted(msg.sender, asteroidsForgeRewardId);
        s_results[msg.sender] = 0;
    }

    function checkIngedients(uint256 category, uint256 tier, uint256[] calldata amounts) internal view{
        uint256 totalAmount = 0;
        for(uint256 i = 0; i < amounts.length; i++) {
            if(category == 1){
                //when the weapon is melee category
                //use this check
                require(genesisWeapon.balanceOf(msg.sender, 1*10000 + tier*1000 + i) >= amounts[i], "You must have enough of that type of weapon");
            }else{
                //when the weapon is ranged category
                //use this check
                require(genesisWeapon.balanceOf(msg.sender, 1*20000 + tier*1000 + i) >= amounts[i], "You must have enough of that type of weapon");         
            }
            totalAmount += amounts[i];
        }
        require(totalAmount == weaponForgeRate[tier], "Number of weapons selected not equal to burn rate");
    }

    function burnIngedients(uint256 category, uint256 tier, uint256[] memory amounts) internal {
        for (uint256 i = 0; i < amounts.length; i++) {
            if (amounts[i] > 0) {
                if(category == 1){
                    genesisWeapon.burn(msg.sender, 1*10000 + tier*1000 + i, amounts[i]);
                }else{
                    genesisWeapon.burn(msg.sender, 1*20000 + tier*1000 + i, amounts[i]);
                }   
            }
        }
    }

    function mintNextTier(uint256 category, uint256 tier) internal returns (uint256){
        uint256 randNum = getResult(msg.sender);
        uint256 weaponId = 11000;
        tier++;
        if(category == 1){
            uint256 weaponType = randNum % meleeWeaponCount[tier];
            weaponId = 1*10000 + tier*1000 + weaponType; 
        }else{
            uint256 weaponType = randNum % rangedWeaponCount[tier];
            weaponId = 1*20000 + tier*1000 + weaponType; 
        }
        return genesisWeapon.mintWeapon(msg.sender, weaponId, 1);
    }

    function setGenesisWeapon(address _weapon) external onlyOwner {
		genesisWeapon = GFCGenesisWeapon(_weapon);
	}

    function setMysteryItem(address _item) external onlyOwner {
		mysteryItem = GFCMysteryItem(_item);
	}

    function setForgeCost(uint256 _cost) external onlyOwner {
		forgeCost = _cost;
	}

    function setAsteroidsForgeRewardId(uint256 _rewardId) external onlyOwner {
		asteroidsForgeRewardId = _rewardId;
	}

    function setMeleeCount(uint16[] calldata array) public onlyOwner{
        meleeWeaponCount = array;
    }

    function setRangedCount(uint16[] calldata array) public onlyOwner{
        rangedWeaponCount = array;
    }

    function setWeaponForgeRate(uint16[] calldata array) public onlyOwner{
        weaponForgeRate = array;
    }

    function togglePause() public onlyOwner{
        paused = !paused;
    }

    function withdrawLink() external onlyOwner {
        require(LINK.transfer(msg.sender, LINK.balanceOf(address(this))), "Unable to transfer");
    }

    function withdrawGCOIN() external onlyOwner {
        IERC20(TOKEN).safeTransfer(msg.sender, IERC20(TOKEN).balanceOf(address(this)));
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        s_results[s_rollers[requestId]] = randomness;
        emit DiceLanded(requestId, randomness);
    }
    
    /**
     * @notice Get the random number if VRF callback on the fulfillRandomness function
     * @return the random number generated by chainlink VRF
     */
    function getResult(address addr) public view returns (uint256) {
        require(s_results[addr] != 0, "Dice not rolled");
        require(s_results[addr] != ROLL_IN_PROGRESS, "Roll in progress");
        return s_results[addr];
    }

    /**
     * Used to airdrop OG weapons
     */
    function airdropWeapon(address[] calldata addrs, uint256 weaponId) external onlyOwner {
        for (uint256 i = 0; i < addrs.length; i++) {
            genesisWeapon.mintWeapon(addrs[i], weaponId, 1);
        }
    }
}