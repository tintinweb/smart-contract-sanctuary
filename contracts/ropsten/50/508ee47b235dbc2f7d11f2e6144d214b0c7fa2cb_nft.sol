pragma solidity 0.5.0;

import "./ERC721.sol";

contract nft is ERC721Full {
  struct nfttoken{
    uint256 id;
    string name;
    address Tokenowner;
    address Tempowner;
    string typeoftoken;
    uint256 createdtime;
    string uri;
    uint256 bidopenedtime;
    uint256 initbidvalue;
    uint256 maxbidvalue;
    bool bidclosed;
  }
  struct Bid{
    uint256 id;
    uint256 bidvalues;
    address biduser;
  }
  struct bidding{
     Bid[] bidds;
  }
  mapping( uint256 => nfttoken) private detailsoftoken;
  mapping (uint256 => bidding) private bidd;
  uint256 public _id =0;

  constructor() ERC721Full("DINESH", "DK") public {

  }

  function mint(string memory _name, string memory _type, string memory _uri, uint256 _copies) public {

    for(uint i = 0;i<_copies;i++){
     _id =_id + 1;
      nfttoken memory token = nfttoken({
        id : _id,
        name : _name,
        Tokenowner : msg.sender,
        Tempowner : address(0),
        typeoftoken :_type,
        createdtime : block.timestamp,
        uri : _uri,
        bidopenedtime : 0,
        initbidvalue : 0,
        maxbidvalue : 0,
        bidclosed : false
     });
      detailsoftoken[_id] = token;
      _mint(msg.sender, _id);
      _setTokenURI(_id,_uri);
    } 
  }

  function details(uint _id) public view returns(uint256,string memory,string memory,address,address,uint256,string memory,uint256,uint256,uint256,bool) {
    nfttoken memory token = detailsoftoken[_id];
    return(token.id,token.name,token.typeoftoken,token.Tokenowner,token.Tempowner,token.createdtime,token.uri,token.initbidvalue,token.maxbidvalue,token.bidopenedtime,token.bidclosed);
  }

  function sell(uint _tokenid, address _to, uint256 amount)public payable returns(bool) {
    nfttoken memory token = detailsoftoken[_id];  
     transferFrom(msg.sender, _to, _tokenid);  
     detailsoftoken[_id].Tempowner = _to;
     return true;
  }

  function openbid(uint _id, uint256 _bidd) public returns (bool){
    require(msg.sender == ownerOf(_id),'your not a owner for this token id');
    detailsoftoken[_id].initbidvalue = _bidd;
    detailsoftoken[_id].bidopenedtime = block.timestamp;

  }
  function startbid(uint _id, uint256 _bidd) public returns(bool) {
    nfttoken memory token = detailsoftoken[_id];  
    require(_exists(_id),'token not exits');
    require(!token.bidclosed,'bidding closed by owner');
    bidding storage bid = bidd[_id];
    bid.bidds.push(Bid({
       id : _id,
       bidvalues : _bidd,
       biduser : msg.sender
    }));
    if ((detailsoftoken[_id].maxbidvalue) < _bidd) {
      detailsoftoken[_id].maxbidvalue = _bidd;

    }
  }  
  function biddingdetails(uint _id) public view returns(address[] memory, uint256[] memory) {
    require(_exists(_id),'token not exits');
    bidding storage bid = bidd[_id];
    Bid[] storage bidds = bid.bidds;
    address[] memory account = new address[](bidds.length);
    uint256[] memory values = new uint256[](bidds.length);
    uint8 k;
    for (uint i = 0; i < bidds.length; i++) {
      account[k] = bidds[i].biduser;
      values[k] = bidds[i].bidvalues;
      k++;
    }
    return(account, values); 
  }
}