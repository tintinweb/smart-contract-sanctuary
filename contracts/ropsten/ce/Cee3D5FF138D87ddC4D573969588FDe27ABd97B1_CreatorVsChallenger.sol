/**
 *Submitted for verification at Etherscan.io on 2021-11-20
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract CreatorVsChallenger {
    
    event TestEvent(uint256 numba);
    
    struct Battle {
        uint battleNumber;
        address Creator;
        string NftUrl;
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
    
    function getWebsiteByCreator(address _Creator) public view returns (string memory) {
        Battle memory result = Battle(stateBattleNumber,addressToBattle[_Creator],"2");
        for (uint i = 0; i < battles.length; i++) {
            if(battles[i].Creator==_Creator) {
                 return battles[i].NftUrl;
            }
        }
    }

    // function getBattleNumberByCreator(address _Creator, uint256 _submittedBattleNumber) public view returns (uint256) {
    //     Battle memory result = Battle(stateBattleNumber,addressToBattle[_Creator],);
    //     for (uint i = 0; i < battles.length; i++) {
    //         if(battles[i].Creator==_Creator && battles[i].battleNumber==_submittedBattleNumber) {
    //              return battles[i].battleNumber;
    //         }
    //     }
    // }

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
    uint256 public newAmount;
    address public newOwner;
    uint256 public numba;
    
    
    constructor(address _contractCaller,uint256 _wager, uint256 numba) payable {
    emit TestEvent(numba);
    owner = msg.sender;
    newOwner = _contractCaller;
    newAmount=_wager; // 'msg.sender' is sender of current call, contract deployer for a constructor
    contractAddress = address(this);
    stateBattleNumber=1;
    stateWagerAmount=0;
    }
    
    
    
    function addNft(string memory NftUrl, address nftAddress) public {
        // verify creator (address,NFT address/ownership,wager<balance)
        // require(address(msg.sender).balance>CreatorWager,"Not enough money to wager");
        // const userEthNFTs = await Moralis.Web3API.account.getNFTs();
        // require(userEthNFTs.contain(nftAddress),"You don't own this NFT on the Ethereum blockchain");
        Battle memory newBattle = Battle(stateBattleNumber,nftAddress,NftUrl);
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
    
    
}