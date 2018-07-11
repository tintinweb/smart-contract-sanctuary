pragma solidity ^0.4.23;
contract Ownable {
  address public owner;

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

  function withdraw() public onlyOwner{
      owner.transfer(address(this).balance);
  }

}


contract SimpleERC721{
    function ownerOf(uint256 _tokenId) external view returns (address owner);
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    function transfer(address _to, uint256 _tokenId) external;
}

contract Solitaire is Ownable {
    event NewAsset(uint256 index,address nft, uint256 token, address owner, string url,string memo);

    struct Asset{
        address nft;
        uint256 tokenId;
        address owner;
        string url;
        string memo;
    }
    uint256 public fee = 5 finney;
    Asset[] queue;

    function init(address _nft,uint256 _id,address _owner,string _url,string _memo) public onlyOwner{
        require(queue.length<=1);
        Asset memory a = Asset({
            nft: _nft,
            tokenId: _id,
            owner: _owner,
            url: _url,
            memo: _memo
        });
        if (queue.length==0){
            queue.push(a);
        }else{
            queue[0] = a;
        }
        emit NewAsset(0,_nft,_id,_owner,_url,_memo);
    }
    
    function refund(address _nft,uint256 _id,address _owner) public onlyOwner{
        require(_owner != address(0));
        SimpleERC721 se = SimpleERC721(_nft);
        require(se.ownerOf(_id) == address(this));
        se.transfer(_owner,_id);
    }
    
    function setfee(uint256 _fee) public onlyOwner{
        require(_fee>=0);
        fee = _fee;
    }
    
    function totalAssets() public view returns(uint256){
        return queue.length;
    }
    
    function getAsset(uint256 _index) public view returns(address _nft,uint256 _id,address _owner,string _url,string _memo){
        require(_index<queue.length);
        Asset memory _a = queue[_index];
        _nft = _a.nft;
        _id = _a.tokenId;
        _owner = _a.owner;
        _url = _a.url;
        _memo = _a.memo;
    }
    
    function addLayer(address _nft,uint256 _id,string _url,string _memo) public payable{
        require(msg.value >=fee);
        require(_nft != address(0));
        SimpleERC721 se = SimpleERC721(_nft);
        require(se.ownerOf(_id) == msg.sender);
        se.transferFrom(msg.sender,address(this),_id);
        // double check
        require(se.ownerOf(_id) == address(this));
        Asset memory last = queue[queue.length -1];
        SimpleERC721 lastse = SimpleERC721(last.nft);
        lastse.transfer(msg.sender,last.tokenId);
        Asset memory newasset = Asset({
            nft: _nft,
            tokenId: _id,
            owner: msg.sender,
            url: _url,
            memo: _memo
        });
        uint256 index = queue.push(newasset) - 1;
        emit NewAsset(index,_nft,  _id,  msg.sender,_url,_memo);
    }

}