pragma solidity ^0.4.13;

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract ERC721Basic {
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);  

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function exists(uint256 _tokenId) public view returns (bool _exists);
  
  function approve(address _to, uint256 _tokenId) public;
  function getApproved(uint256 _tokenId) public view returns (address _operator);
  
  function setApprovalForAll(address _operator, bool _approved) public;
  function isApprovedForAll(address _owner, address _operator) public view returns (bool);

  function transferFrom(address _from, address _to, uint256 _tokenId) public;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) public;  
  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data) public;
}

contract ERC721Receiver {
  /**
   * @dev Magic value to be returned upon successful reception of an NFT
   *  Equals to `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`,
   *  which can be also obtained as `ERC721Receiver(0).onERC721Received.selector`
   */
  bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba; 

  /**
   * @notice Handle the receipt of an NFT
   * @dev The ERC721 smart contract calls this function on the recipient
   *  after a `safetransfer`. This function MAY throw to revert and reject the
   *  transfer. This function MUST use 50,000 gas or less. Return of other
   *  than the magic value MUST result in the transaction being reverted.
   *  Note: the contract address is always the message sender.
   * @param _from The sending address 
   * @param _tokenId The NFT identifier which is being transfered
   * @param _data Additional data with no specified format
   * @return `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`
   */
  function onERC721Received(address _from, uint256 _tokenId, bytes _data) public returns(bytes4);
}

contract DeusMarketplace is Ownable, ERC721Receiver {
  address public owner;
  address public wallet;
  uint256 public fee_percentage;
  ERC721Basic public token;
  
  mapping(uint256 => uint256) public priceList;
  mapping(uint256 => address) public holderList;
  
  event Stored(uint256 indexed id, uint256 price, address seller);
  event Cancelled(uint256 indexed id, address seller);
  event Sold(uint256 indexed id, uint256 price, address seller, address buyer);
  
  event TokenChanged(address old_token, address new_token);
  event WalletChanged(address old_wallet, address new_wallet);
  event FeeChanged(uint256 old_fee, uint256 new_fee);
  
  function DeusMarketplace(address _token, address _wallet) public {
    owner = msg.sender;
    token = ERC721Basic(_token);
    wallet = _wallet;
    fee_percentage = 10;
  }
  
  function setToken(address _token) public onlyOwner {
    address old = token;
    token = ERC721Basic(_token);
    emit TokenChanged(old, token);
  }
  
  function setWallet(address _wallet) public onlyOwner {
    address old = wallet;
    wallet = _wallet;
    emit WalletChanged(old, wallet);
  }
  
  function changeFeePercentage(uint256 _percentage) public onlyOwner {
    uint256 old = fee_percentage;
    fee_percentage = _percentage;
    emit FeeChanged(old, fee_percentage);
  }
  
  function onERC721Received(address _from, uint256 _tokenId, bytes _data) public returns(bytes4) {
    require(msg.sender == address(token));
    
    uint256 _price = uint256(convertBytesToBytes32(_data));
    
    require(_price > 0);
    
    priceList[_tokenId] = _price;
    holderList[_tokenId] = _from;
  
    emit Stored(_tokenId, _price, _from);
    
    return ERC721Receiver.ERC721_RECEIVED;
  }
  
  function cancel(uint256 _id) public returns (bool) {
    require(holderList[_id] == msg.sender);
    
    holderList[_id] = 0x0;
    priceList[_id] = 0;
    
    token.safeTransferFrom(this, msg.sender, _id);
  
    emit Cancelled(_id, msg.sender);
    
    return true;
  }
  
  function buy(uint256 _id) public payable returns (bool) {
    require(priceList[_id] == msg.value);
    
    address oldHolder = holderList[_id];
    uint256 price = priceList[_id];
    
    uint256 toWallet = price / 100 * fee_percentage;
    uint256 toHolder = price - toWallet;
    
    holderList[_id] = 0x0;
    priceList[_id] = 0;
    
    token.safeTransferFrom(this, msg.sender, _id);
    wallet.transfer(toWallet);
    oldHolder.transfer(toHolder);
    
    emit Sold(_id, price, oldHolder, msg.sender);
    
    return true;
  }
  
  function getPrice(uint _id) public view returns(uint256) {
    return priceList[_id];
  }
  
  function convertBytesToBytes32(bytes inBytes) internal returns (bytes32 out) {
    if (inBytes.length == 0) {
      return 0x0;
    }
    
    assembly {
      out := mload(add(inBytes, 32))
    }
  }
}