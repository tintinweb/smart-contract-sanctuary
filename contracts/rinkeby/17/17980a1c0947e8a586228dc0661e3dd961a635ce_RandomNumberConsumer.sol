// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./VRFConsumerBase.sol";

/**
 * THIS IS AN EXAMPLE CONTRACT WHICH USES HARDCODED VALUES FOR CLARITY.
 * PLEASE DO NOT USE THIS CODE IN PRODUCTION.
 */

/**
 * Request testnet LINK and ETH here: https://faucets.chain.link/
 * Find information on LINK Token Contracts and get the latest ETH and LINK faucets here: https://docs.chain.link/docs/link-token-contracts/
 */
 
contract RandomNumberConsumer is VRFConsumerBase {
    
    bytes32 internal keyHash;
    uint256 internal fee;
    
    uint256 public randomResult;
    uint256 lastIndex = 1;
    mapping(bytes32 => uint256) randomValues;
    mapping(bytes32 => address) users;
    address public owner;


    modifier onlyOwner(){
        require(msg.sender == owner, "Only Owner Allowed!");
        _;
    }

    /**
     * Constructor inherits VRFConsumerBase
     * 
     * Network: Rinkeby
     * Chainlink VRF Coordinator address: 0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B
     * LINK token address:                0x01BE23585060835E02B77ef475b0Cc51aA1e0709
     * Key Hash: 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311
     */
    
    uint256[] public rarities = [30,20,15,10,8,6,5,3,2,1];
    string[] public raritiesName = ["H","G","F","E","D","C","B","A","S","SS"];
    // Rarities Declaraion
    uint256[] public availbleRarities = [100,239,34,40,52,64,74,83,95,7];

    // Rarities NFT Id List
    uint256[] public SSAvailableRarities = [3];
    uint256[] public SAvailableRarities = [4,5,6];
    uint256[] public AAvailableRarities = [7,8,9];
    uint256[] public BAvailableRarities = [10,11,12];
    uint256[] public CAvailableRarities = [13,14,15];
    uint256[] public DAvailableRarities = [16,17,18];
    uint256[] public EAvailableRarities = [19,20,21];
    uint256[] public FAvailableRarities = [22,23,24];
    uint256[] public GAvailableRarities = [25,26,27];
    uint256[] public HAvailableRarities = [28,29,30];

    mapping(uint256 => uint256) nftsAvailable;

    event RandomNumber(address indexed forUser, bytes32 indexed reqestID, uint256 value);
    event RandomNess(address indexed forUser, uint256 value);
    event NFTMinted(address indexed user,uint256 indexed id,uint256 value,string name);
    constructor() 
        VRFConsumerBase(
            0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B, // VRF Coordinator
            0x01BE23585060835E02B77ef475b0Cc51aA1e0709  // LINK Token
        )
    {
        owner = msg.sender;
        keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311;
        fee = 0.1 * 10 ** 18; // 0.2 LINK (Varies by network)

        nftsAvailable[3] = 1;
        nftsAvailable[4] = 10;
        nftsAvailable[5] = 12;
        nftsAvailable[6] = 13;
        nftsAvailable[7] = 15;
        nftsAvailable[8] = 16;
        nftsAvailable[9] = 17;
        nftsAvailable[10] = 18;
        nftsAvailable[11] = 300;
        nftsAvailable[12] = 400;
        nftsAvailable[13] = 400;
        nftsAvailable[14] = 400;
        nftsAvailable[15] = 400;
        nftsAvailable[16] = 400;
        nftsAvailable[18] = 400;
        nftsAvailable[19] = 400;
        nftsAvailable[20] = 400;
        nftsAvailable[21] = 400;
        nftsAvailable[22] = 400;
        nftsAvailable[23] = 400;
        nftsAvailable[24] = 400;
        nftsAvailable[25] = 400;
        nftsAvailable[26] = 400;
        nftsAvailable[27] = 400;
        nftsAvailable[28] = 400;
        nftsAvailable[29] = 400;
        nftsAvailable[30] = 400;
    }
    
    /** 
     * Requests randomness 
     */
    // 63684257038186651791413484182035186976695072704910703140681176277184861250185
    // 75316996132243315590439400681594235784647528810848954137078979221785549907928
    // 28470347246966003448803601405671699602482332940818584716460459149173072291266
    function getRandomValues(uint256 number, uint256 length) internal pure returns(uint256 value){
        uint256 random_ = number/(10**76);
        random_ = random_ * length;

        // uint256 randomNumber = random_ * rarityArray.length;
        if(random_ < 10){
            random_ = 0;
        }else{
            random_ = random_ / 10;
        }
        return (random_);
    }

    function getRandomNumber() public virtual {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        bytes32 reqId = requestRandomness(keyHash, fee);
        users[reqId] = msg.sender;
        // users[reqId] = msg.sender;
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        randomResult = randomness;
        // randomValues[requestId] = randomness;
        uint256 randomNumber = randomness/(10**75);
        randomValues[requestId] = randomness;
        uint256 _index = _selectRandomNFT(randomNumber);
        (uint256 id,uint256 qty, string memory name) = _mintSelectedNFT(_index,randomness);
        emit NFTMinted(users[requestId],id,qty,name);
        emit RandomNumber(users[requestId],requestId,_index);
    }
    function getRandomness(bytes32 reqId) public virtual view returns(uint256 randomness){
        return randomValues[reqId];
    }
    function getUser(bytes32 reqId) public virtual view returns(address user){
        return users[reqId];
    }
    function withdrawLink(uint256 amount) external onlyOwner{
        LINK.transfer(msg.sender,amount);
    }

    function _selectRandomNFT(uint256 randomNumber) internal virtual returns(uint256 id){
        for(uint16 i=0;i< rarities.length;i++){
            if(randomNumber <= rarities[i] && availbleRarities[i] >= 1){
                return i;
            }else{
                randomNumber -= rarities[i];
            }
        }
        if(availbleRarities[rarities.length-1] >= 1){
            return 0;
        }
    }

    function _mintSelectedNFT(uint256 index,uint256 randomness) internal virtual returns(uint256 id,uint256 qty, string memory rarity){
        availbleRarities[index] -= 1;

        uint256[] storage rarityArray = getRarityAvailableArray(index);
        uint256 randomNumber = getRandomValues(randomness,rarityArray.length);

        uint256 _id = rarityArray[randomNumber];
        nftsAvailable[_id] -= 1;

        if(nftsAvailable[_id] <= 0){
            if(rarityArray.length <= 1){
                rarityArray.pop();
            }else{
                for(uint256 i=randomNumber; i < rarityArray.length; i++){
                    rarityArray[i] = rarityArray[i+1];
                }
                rarityArray.pop();
            }

            removeNFTfromRarity(index,rarityArray);
        }
        return(_id,1,raritiesName[index]);
    }
    function getRarityAvailableArray(uint256 index) internal virtual returns(uint256[] storage raritySelected){
        if(index == 1){
            return HAvailableRarities;
        }
        if(index == 2){
            return GAvailableRarities;
        }
        if(index == 3){
            return FAvailableRarities;
        }
        if(index == 4){
            return EAvailableRarities;
        }
        if(index == 5){
            return DAvailableRarities;
        }
        if(index == 6){
            return CAvailableRarities;
        }
        if(index == 7){
            return BAvailableRarities;
        }
        if(index == 8){
            return AAvailableRarities;
        }
        if(index == 9){
            return SAvailableRarities;
        }else{
            return SSAvailableRarities;
        }
    }
    // function removeSelectedIndex(){

    // }
    function removeNFTfromRarity(uint256 index,uint256[] storage newArray) internal virtual {
        if(index == 1){
            HAvailableRarities = newArray;
        }
        if(index == 2){
            GAvailableRarities = newArray;
        }
        if(index == 3){
            FAvailableRarities = newArray;
        }
        if(index == 4){
            EAvailableRarities = newArray;
        }
        if(index == 5){
            DAvailableRarities = newArray;
        }
        if(index == 6){
            CAvailableRarities = newArray;
        }
        if(index == 7){
            BAvailableRarities = newArray;
        }
        if(index == 8){
            AAvailableRarities = newArray;
        }
        if(index == 9){
            SAvailableRarities = newArray;
        }else{
            SSAvailableRarities = newArray;
        }
    }
}