/**
 *Submitted for verification at Etherscan.io on 2021-09-08
*/

//SPDX-License-Identifier: GPL-3.0
 
//pragma solidity >=0.5.0 <0.9.0;
pragma solidity 0.8.6;
 
contract MyTestNFT //is NFTokenMetadata
{
    event Mint(address indexed _to, uint256 indexed _tokenId,string  _ipfsHash);
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    
    
    string public nftName;
    string public nftSymbol;
    address payable public owner;
    address payable public mint_owner;
    uint public startBlock;
    uint public endBlock;
    string  ipfsHash;
    uint256 public tokenId;
 
    
    enum State {Started, Running, Ended, Canceled}
    State public auctionState;
    
    uint public highestBid;
    uint public fee;
    
    
    address payable public highestBidder;
    mapping(address => uint) public bids;
    uint bidIncrement;
    
 
    constructor()
    {
        owner = payable(msg.sender);
        nftName = "My First NFT";
        nftSymbol = "TESTNFT";
        fee = 10; // bidding in multiple of ETH
    }
    
    modifier notOwner()
    {
        require(msg.sender != owner);
        _;
    }
    
    modifier notMintOwner()
    {
        require(msg.sender != mint_owner);
        _;
    }
    
    modifier onlyOwner()
    {
        require(msg.sender == owner);
        _;
    }
    

    modifier afterStart()
    {
        require(block.timestamp >= startBlock);
        _;
    }
    
    modifier beforeEnd()
    {
        require(block.timestamp <= endBlock,"Bidding period is over");
        _;
    }
    

    function mint(address _to, string memory _ipfsHash, uint256 _tokenId, uint biddig_duration) public 
    {
        // uint256 _tokenId = tokenCounter;
        // idToOwner[_tokenId] = _to;
        // tokenCounter++;
        mint_owner=payable(msg.sender);
        auctionState = State.Running;
        startBlock = block.timestamp;
        endBlock = block.timestamp + biddig_duration* 1 minutes;
        tokenId=_tokenId;
        ipfsHash=_ipfsHash;
        emit Mint(_to, _tokenId, _ipfsHash);
    }

    // function transfer(address _to, uint256 _tokenId) public onlyOwner
    // {
    //     emit Transfer(msg.sender, _to, _tokenId);
    // }


    function cancelAuction() public onlyOwner
    {
        auctionState = State.Canceled;
    }
    
    
    function placeBid() public payable notOwner notMintOwner afterStart beforeEnd returns(bool)
    {
        require(auctionState == State.Running);

        uint currentBid = bids[msg.sender] + msg.value;

        require(currentBid > highestBid);

        bids[msg.sender] = currentBid;
        
        highestBidder = payable(msg.sender);
        
        highestBid = bids[msg.sender];
        

    return true;
    }
    
    
    
    function finalizeAuction() public
    {
       require(auctionState == State.Canceled || block.timestamp > endBlock); 
       
       require(msg.sender == owner || msg.sender == mint_owner || (bids[msg.sender] > 0 && msg.sender!=highestBidder));

       address payable recipient;
       uint value;
       
       if(auctionState == State.Canceled)
       {
           recipient = payable(msg.sender);
           value = bids[msg.sender];
       }
       else
       {
           if(msg.sender == owner)
           {
               recipient = owner;
               value = highestBid / fee;
               
           }
           else if(msg.sender == mint_owner)
           {
               emit Transfer(mint_owner, highestBidder, tokenId);
               recipient = mint_owner;
               value = highestBid - (highestBid / fee);
           }
           else
           {
                recipient = payable(msg.sender);
                value = bids[msg.sender];
           }
       }
       
       bids[recipient] = 0;
       recipient.transfer(value);

    }
}