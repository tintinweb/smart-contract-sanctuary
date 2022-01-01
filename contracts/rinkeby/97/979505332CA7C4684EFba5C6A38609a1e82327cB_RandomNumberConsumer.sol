// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./VRFConsumerBase.sol";

interface INFTCollection{
    function safeMint(address to, uint256 tokenId,uint256 _qty) external ;
}
 
contract RandomNumberConsumer is VRFConsumerBase {
    
    bytes32 internal keyHash;
    uint256 internal fee;
    
    uint256 public randomResult;
    uint256 lastIndex = 1;
    mapping(bytes32 => uint256) randomValues;
    mapping(bytes32 => address) users;
    address public owner;

    INFTCollection nftCollection;

    modifier onlyOwner(){
        require(msg.sender == owner, "Only Owner Allowed!");
        _;
    }
    mapping(address => uint256) _totalMinted;

    
    uint256[] public nfts;
    uint256 totalNfts = 0;
    mapping(uint256 => uint256) nftsAvailable;

    event RandomNumber(address indexed forUser, bytes32 indexed reqestID, uint256 value);
    event RandomNess(address indexed forUser, uint256 value);
    event NFTMinted(address indexed user,uint256 indexed id,uint256 value);
    event Running(string value);
    constructor(address _nft) 
        VRFConsumerBase(
            0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B,
            0x01BE23585060835E02B77ef475b0Cc51aA1e0709
        )
    {
        owner = msg.sender;
        keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311;
        fee = 0.1 * 10 ** 18; // 2 LINK (Varies by network)
        nftCollection = INFTCollection(_nft);
    }

    function getRandomValues(uint256 number, uint256 length) external pure returns(uint256 value){
        return _getRandomValues(number,length);
    }

    function _getRandomValues(uint256 number, uint256 length) internal pure returns(uint256 value){
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

    function getRandomNumber(uint256 _qty) public virtual payable {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        require(_totalMinted[msg.sender] + _qty < 60, "Max Limit is 60");
        require(msg.value == (24 * (10**15) * _qty),"0.024 Ether must be sent!");
        require(totalNfts >= _qty,"Not Enough NFT's available");

        for(uint256 i=0; i<_qty;i++){
            bytes32 reqId = requestRandomness(keyHash, fee);
            users[reqId] = msg.sender;
            _totalMinted[msg.sender] += 1;
        }
    }

    function generateNFT(uint256 tokenId,uint256 _supply) public onlyOwner{
        for(uint256 i=0; i < _supply; i++){
            if(i<7){
                try nftCollection.safeMint(msg.sender,tokenId+i,1) {
                }catch{}
            }else{
                totalNfts += 1;
                nfts.push(tokenId+i);
                nftsAvailable[tokenId+i] = 1;
            }
        }
    }
    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        randomResult = randomness;
        // randomValues[requestId] = randomness;
        // uint256 randomNumber = randomness/(10**75);
        randomValues[requestId] = randomness;
        uint256 _index = _getRandomValues(randomness,nfts.length);
        try nftCollection.safeMint(users[requestId],nfts[_index],1){
            emit NFTMinted(users[requestId],nfts[_index],1);
        }catch{}
        nftsAvailable[nfts[_index]] = nftsAvailable[nfts[_index]] - 1;
        if(nftsAvailable[nfts[_index]] == 0){
            _removeNft(_index);
        }
        emit RandomNumber(users[requestId],requestId, _index);
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

    function _removeNft(uint256 _index) internal {
        nfts[_index] = nfts[nfts.length - 1];
        nfts.pop();
    }
}