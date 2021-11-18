/**
 *Submitted for verification at polygonscan.com on 2021-11-18
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract CreatorVsChallenger {
    
    struct Battle {
        uint battleNumber;
        address Creator;
        uint256 CreatorWager;
        // address CreatorNFT;
        // uint256 CreatorWager;
        // address challenger;
        // address challengerNFT;
        // uint256 challengerWager;
        // string startTime;
        // string joinTime;
        // string endTime;
    }
    
    Battle[] public battles;
    
    mapping(address=>address) private addressToBattle;
    
    function getBattleRandomNumByCreator(address _Creator) public view returns (uint256) {
        Battle memory result = Battle(stateBattleNumber,addressToBattle[_Creator],3);
        for (uint i = 0; i < battles.length; i++) {
            if(battles[i].Creator==_Creator) {
                 return battles[i].CreatorWager;
            }
        }
    }

    function getBattleNumberByCreator(address _Creator, uint256 _submittedBattleNumber) public view returns (uint256) {
        Battle memory result = Battle(stateBattleNumber,addressToBattle[_Creator],stateWagerAmount);
        for (uint i = 0; i < battles.length; i++) {
            if(battles[i].Creator==_Creator && battles[i].battleNumber==_submittedBattleNumber) {
                 return battles[i].battleNumber;
            }
        }
    }

    uint256 private stateBattleNumber;
    uint256 private stateWagerAmount;
    address private returnedNftOwnerAddress;
    address private owner;
    address private challenger;
    address private contractAddress;
    uint256 private challengerWager;
    uint256 private potSize;
    string private ownerNFTString;
    string private challengerNFTString;
    bool private readyForBattle;
    
    constructor() payable {
    owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
    contractAddress = address(this);
    stateBattleNumber=1;
    stateWagerAmount=0;
    }
    
    function createBattle(uint256 CreatorWager, address nftAddress) public payable {
        // verify creator (address,NFT address/ownership,wager<balance)
        require(address(msg.sender).balance>CreatorWager,"Not enough money to wager");
        // const userEthNFTs = await Moralis.Web3API.account.getNFTs();
        // require(userEthNFTs.contain(nftAddress),"You don't own this NFT on the Ethereum blockchain");
        Battle memory newBattle = Battle(stateBattleNumber,0x133dDA122B3C8371A2f4ceE0Cfd7084e3A30e6de,CreatorWager);
        stateBattleNumber++;
        battles.push(newBattle);
    }
    
    function retrieveOwnerOfNft(address nftAddress) private {
        
    }
    
    function joinBattle() public payable {
        // locate battle
        // verify challenger (address,NFT ownership,balance, address not equal to Creator address)
        // transfer money from challenger
        // transfer money from Creator
    }
    
    function executeBattle() private{
        // timer
        // coin flip
        // payment
    }
    
    function getChallengeByCreatorAddress() public{
        // 
    }
    
    function getChallengeByChallengerAddress() public {
        // 
    }
    
    
    
    // event for EVM logging
    // event OwnerSet(address indexed oldOwner, address indexed newOwner);
    // event ChallengerSet(address indexed challenger,address indexed newChallenger);
    
    // modifier to check if caller is owner
    // modifier isOwner() {
    //     // If the first argument of 'require' evaluates to 'false', execution terminates and all
    //     // changes to the state and to Ether balances are reverted.
    //     // This used to consume all gas in old EVM versions, but not anymore.
    //     // It is often a good idea to use 'require' to check if functions are called correctly.
    //     // As a second argument, you can also provide an explanation about what went wrong.
    //     require(msg.sender == owner, "Caller is not owner");
    //     _;
    // }
    
    // modifier isChallenger() {
    //     // If the first argument of 'require' evaluates to 'false', execution terminates and all
    //     // changes to the state and to Ether balances are reverted.
    //     // This used to consume all gas in old EVM versions, but not anymore.
    //     // It is often a good idea to use 'require' to check if functions are called correctly.
    //     // As a second argument, you can also provide an explanation about what went wrong.
    //     require(msg.sender == challenger, "Caller is not challenger");
    //     _;
    // }
    
    /**
     * @dev Set contract deployer as owner
     */


    /**
     * @dev Change newChallenger
     * @param newChallenger address of new owner
     */
    // function setChallenger(address newChallenger) public payable {
    //     require(newChallenger!=owner,"only non-owners can compete");
    //     if (challenger==newChallenger || challenger==0x0000000000000000000000000000000000000000) {
    //     require(readyForBattle!=true,"oops - this battle isn't taking any more challengers");
    //     challenger=newChallenger;
    //     require(newChallenger.balance>=CreatorWager);
    //     // require(amount == msg.value,"wager is the wrong amount");
    //     payable(address(this)).transfer(CreatorWager);
    //     readyForBattle=true;
    //     }
    // }

    /**
     * @dev Return owner address 
     * @return address of owner
     */
    // function getOwner() external view returns (address) {
    //     return owner;
    // }
    
        /**
     * @dev Return challenger address 
     * @return address of challenger
     */
    // function getChallenger() external view returns (address) {
    //     return challenger;
    // }
    
    // function getChallengerBalance() external view returns (uint256) {
    //     return challenger.balance;
    // }
    
    // function getPotSize() external view returns (uint256) {
    //     return address(this).balance;
    // }
    
    
}