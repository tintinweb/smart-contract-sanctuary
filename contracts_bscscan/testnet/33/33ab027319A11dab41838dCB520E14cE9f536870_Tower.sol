/**
 *Submitted for verification at BscScan.com on 2021-11-20
*/

pragma solidity ^0.8.10;

contract Tower {
    
    //    Tower    of    Babel 
    //    ▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇         
    //    ▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇        
    //    ▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇      
    //    ▇▇▇▇▇▇▇▇▇ ▇▇▇▇▇▇▇▇▇▇         
    //    ▇▇▇▇▇▇▇▇▇ ▇▇▇▇▇▇▇▇▇▇  
    //    ▇▇▇▇▇▇▇▇▇ ▇▇▇▇▇▇▇▇▇▇      
    //    ▇▇▇▇ ▇▇▇▇ ▇▇▇▇ ▇▇▇▇▇
    //    ▇▇▇▇ ▇▇▇▇ ▇▇▇▇ ▇▇▇▇▇
    //    ▇▇ ▇▇ ▇▇ ▇▇ ▇▇ ▇▇ ▇▇ 
    //    ▇▇ ▇▇ ▇▇ ▇▇ ▇▇ ▇▇ ▇▇
    //    ▇▇ ▇▇ ▇▇ ▇▇ ▇▇ ▇▇ ▇▇
    //    ▇▇ ▇▇ ▇▇ ▇▇ ▇▇ ▇▇ ▇▇
    //    ▇▇ ▇▇ ▇▇ ▇▇ ▇▇ ▇▇ ▇▇
    
    
    struct Block {
        uint256 blockPrice; 
        uint256 number;
        address owner;
        string  imageUrl;
        string  description;
        string  webSite;
    }
    
    // Blocks of address
    mapping (address =>  uint256[]) public blocksOfAddress;
    
    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;
    
    // Blocks of number
    mapping (uint256 =>  Block) public blockOfNumber;
    
    // Blocks in balloon
    mapping (uint256 =>  Block) public blockInBaloon;
    
    // Time frozen block in balloon
    mapping (uint256 => uint256) public timeFrozenBlock;
    
    // Referrals Map
    mapping (address => address) public referralsMap;
    
    // Block counter
    uint8 public lastBlockNumber = 0;
    
    address private _owner;
    
    uint256 public blockStepPrice;
    
    uint256 public lastBlockPrice;
    
    uint256 public systemBlockPrice;
    
    uint256 public referralBlockPrice;
    
    uint256 public balloonBlockPrice;
    
    constructor () {
        _owner = msg.sender;
        blockStepPrice = 10**12; // 0.000001
        systemBlockPrice = 10**11; // 0.0000001
        referralBlockPrice = 10**10; //  0.00000001
        lastBlockPrice = systemBlockPrice + 10**8; // 0.0000000001
        balloonBlockPrice = 10**12; // 0.000001
    }
    
    modifier onlyOwner() {
        require(_owner == msg.sender, "Error: caller is not the owner");
        _;
    }
    
    
    
    function addBlock(string memory _imageUrl,string memory _description,string memory _webSite) public payable {
        Block memory newBlock;
        
        lastBlockNumber += 1;
        require(msg.value >= lastBlockPrice,'Error: The price should be higher');
        
        newBlock.owner = msg.sender;
        newBlock.imageUrl = _imageUrl;
        newBlock.description = _description;
        newBlock.blockPrice = lastBlockPrice;
        newBlock.number = lastBlockNumber;
        newBlock.webSite = _webSite;
        lastBlockPrice += blockStepPrice + systemBlockPrice;
        
        _addTokenToOwnerEnumeration(msg.sender,lastBlockNumber);
        blockOfNumber[lastBlockNumber] = newBlock;
        _addAddressToReferralProgram(msg.sender,address(this));
        distribute();
    }
    
    function addBlockWithReferralSystem(string memory _imageUrl,string memory _description,string memory _webSite,address _invitingAddress) public payable {
        Block memory newBlock;
        
        lastBlockNumber += 1;
        require(msg.value >= lastBlockPrice,'Error: The price should be higher');
        
        newBlock.owner = msg.sender;
        newBlock.imageUrl = _imageUrl;
        newBlock.description = _description;
        newBlock.blockPrice = lastBlockPrice;
        newBlock.number = lastBlockNumber;
        newBlock.webSite = _webSite;
        lastBlockPrice += blockStepPrice + systemBlockPrice;
        
        _addTokenToOwnerEnumeration(msg.sender,lastBlockNumber);
        blockOfNumber[lastBlockNumber] = newBlock;
        _addAddressToReferralProgram(msg.sender,_invitingAddress);
        distribute();
    }
    
    function addBlockToBalloon(string memory _imageUrl,string memory _description,uint256 _blockNumber) public payable {
        Block memory newBlock;
        
        require(_blockNumber > 0,'Error: First is 1 block');
        require(_blockNumber <= 4,'Error: Balloon have 4 blocks');
        require(msg.value >= balloonBlockPrice,'Error: The price should be higher');
        require(timeFrozenBlock[_blockNumber] < block.timestamp,'Error: block is frozen');
        
        newBlock.owner = msg.sender;
        newBlock.imageUrl = _imageUrl;
        newBlock.description = _description;
        newBlock.blockPrice = balloonBlockPrice;
        newBlock.number = _blockNumber;
        blockInBaloon[_blockNumber] = newBlock;
        timeFrozenBlock[_blockNumber] = 86400 + block.timestamp; // frozen 24h
    }
    
    function distribute() public payable {
        uint256 distributeValue = msg.value - systemBlockPrice;
        
        if(lastBlockNumber > 1) {
            uint8 index = lastBlockNumber - 1;
            address payable address1 = payable(address(uint160(blockOfNumber[index].owner)));
            address1.transfer(getQuantityByTotalAndPercent(distributeValue,250));
        }
        
        if(lastBlockNumber > 2) {
            uint8 index = lastBlockNumber - 2;
            address payable address2 = payable(address(uint160(blockOfNumber[index].owner)));
            address2.transfer(getQuantityByTotalAndPercent(distributeValue,250));
        }
        
         if(lastBlockNumber > 3) {
            uint8 index = lastBlockNumber - 3;
            address payable address3 = payable(address(uint160(blockOfNumber[index].owner)));
            address3.transfer(getQuantityByTotalAndPercent(distributeValue,125));
         }
        
        if(lastBlockNumber > 4) {
            uint8 index = lastBlockNumber - 4;
            address payable address4 = payable(address(uint160(blockOfNumber[index].owner)));
            address4.transfer(getQuantityByTotalAndPercent(distributeValue,125));
        }
        
        if(lastBlockNumber > 5) {
            uint8 index = lastBlockNumber - 5;
            address payable address5 = payable(address(uint160(blockOfNumber[index].owner)));
            address5.transfer(getQuantityByTotalAndPercent(distributeValue,125));
        }
        
        if(lastBlockNumber > 6) {
            uint8 index = lastBlockNumber - 6;
            address payable address6 = payable(address(uint160(blockOfNumber[index].owner)));
            address6.transfer(getQuantityByTotalAndPercent(distributeValue,125));
        }
        
        // Send to _invitingAddress  => systemFee - referralBlockPrice
        if(referralsMap[msg.sender] != address(this)) {
            address payable _invitingAddress = payable(address(uint160(referralsMap[msg.sender])));
            _invitingAddress.transfer(referralBlockPrice);
        }

    }
    
    function changeBlockInfo(string memory _imageUrl,string memory _description,string memory _webSite,uint256 _blockNumber) public  {

        require(msg.sender == blockOfNumber[_blockNumber].owner,'Error: You are not the owner of the block');
         
        Block memory newBlock = blockOfNumber[_blockNumber];
       
        if(bytes(_imageUrl).length != 0){
          newBlock.imageUrl = _imageUrl;
        }
        if(bytes(_description).length != 0){
          newBlock.description = _description;
        }
        if(bytes(_webSite).length != 0){
          newBlock.webSite = _webSite;
        }
        blockOfNumber[_blockNumber] = newBlock;
    }
    
    function changeBalloonBlockInfo(string memory _imageUrl,string memory _description,string memory _webSite,uint256 _blockNumber) public  {
        require(_blockNumber > 0,'Error: First is 1 block');
        require(_blockNumber <= 4,'Error: Balloon have 4 blocks');
       
        require(msg.sender == blockInBaloon[_blockNumber].owner,'Error: You are not the owner of the block');
         
        Block memory newBlock = blockInBaloon[_blockNumber];
       
        if(bytes(_imageUrl).length != 0){
          newBlock.imageUrl = _imageUrl;
        }
        if(bytes(_description).length != 0){
          newBlock.description = _description;
        }
        if(bytes(_webSite).length != 0){
          newBlock.webSite = _webSite;
        }
        blockInBaloon[_blockNumber] = newBlock;
    }

    function getQuantityByTotalAndPercent(uint256 totalCount,uint256 percent) public pure returns (uint256) {
        if(percent == 0) return 0;
        require(percent <= 1000 ,'Incorrect percent');
        return (totalCount * percent / 100) / 10;
    }
    
    function getDefrostTime(uint256 _blockNumber) public view returns (uint256) {
        return timeFrozenBlock[_blockNumber] - block.timestamp;
    }
    

    function totalSupply() public view returns (uint256) {
        return lastBlockNumber;
    }
    
    function transferOwnership(address newOwner) public  onlyOwner {
        require(newOwner != address(0), "Error: new owner is the zero address");
        _owner = newOwner;
    }
    
    function withdraw(uint256 _qauntity) public onlyOwner {
        address payable owner = payable(address(uint160(msg.sender)));
        owner.transfer(_qauntity);
    }

    
    function tokensOfOwner(address owner) public view returns (uint256[] memory) {
        return _tokensOfOwner(owner);
    }

    function _tokensOfOwner(address owner) internal view returns (uint256[] storage) {
        return blocksOfAddress[owner];
    }

    function _addTokenToOwnerEnumeration(address to,  uint256 tokenId) private {
        _ownedTokensIndex[tokenId] = blocksOfAddress[to].length;
        blocksOfAddress[to].push(tokenId);
    }

    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = blocksOfAddress[from].length - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = blocksOfAddress[from][lastTokenIndex];

            blocksOfAddress[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }
        blocksOfAddress[from].pop();
    }
    
    function _addAddressToReferralProgram(address _referralAddress,address _invitingAddress) private {
        if(referralsMap[_referralAddress] == address(0)){
            referralsMap[_referralAddress] = _invitingAddress;
        }
    }


    
    //  @admin
    function setBlockStepPrice(uint256 _price) public {
        blockStepPrice = _price;
    }
    //  @admin 
    function setSystemBlockPrice(uint256 _price) public {
        systemBlockPrice = _price;
    }
    //  @admin 
    function setLastBlockPrice(uint256 _price) public {
        lastBlockPrice = _price;
    }
    //  @admin 
    function setBalloonBlockPrice(uint256 _price) public {
        balloonBlockPrice = _price;
    }
     // @admin 
    function setReferralBlockPrice(uint256 _price) public {
        referralBlockPrice = _price;
    }
    
}