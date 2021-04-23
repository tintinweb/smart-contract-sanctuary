/**
 *Submitted for verification at Etherscan.io on 2021-04-23
*/

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.5.16;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

pragma solidity ^0.5.16;

contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) public view returns (uint256 balance);
    function ownerOf(uint256 tokenId) public view returns (address owner);
    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);
    function transferFrom(address from, address to, uint256 tokenId) public;
    function safeTransferFrom(address from, address to, uint256 tokenId) public;
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}

pragma solidity ^0.5.16;

contract IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public returns (bytes4);
}

pragma solidity ^0.5.16;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

pragma solidity ^0.5.16;

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

pragma solidity ^0.5.16;

contract ERC165 is IERC165 {
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff);
        _supportedInterfaces[interfaceId] = true;
    }
}

pragma solidity ^0.5.16;

contract ERC721 is ERC165, IERC721 {
    using SafeMath for uint256;
    using Address for address;

    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;
    mapping (uint256 => address) private _tokenOwner;
    mapping (uint256 => address) private _tokenApprovals;
    mapping (address => uint256) private _ownedTokensCount;
    mapping (address => mapping (address => bool)) private _operatorApprovals;
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    constructor () public {
        _registerInterface(_INTERFACE_ID_ERC721);
    }

    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0));
        return _ownedTokensCount[owner];
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _tokenOwner[tokenId];
        require(owner != address(0));
        return owner;
    }

    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(to != owner);
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId));
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address to, bool approved) public {
        require(to != msg.sender);
        _operatorApprovals[msg.sender][to] = approved;
        emit ApprovalForAll(msg.sender, to, approved);
    }

    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId));
        _transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
        transferFrom(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data));
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        address owner = _tokenOwner[tokenId];
        return owner != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0));
        require(!_exists(tokenId));

        _tokenOwner[tokenId] = to;
        _ownedTokensCount[to] = _ownedTokensCount[to].add(1);

        emit Transfer(address(0), to, tokenId);
    }

    function _transferFrom(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from);
        require(to != address(0));

        _clearApproval(tokenId);

        _ownedTokensCount[from] = _ownedTokensCount[from].sub(1);
        _ownedTokensCount[to] = _ownedTokensCount[to].add(1);
        _tokenOwner[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        internal returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }

        bytes4 retval = IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data);
        return (retval == _ERC721_RECEIVED);
    }

    function _clearApproval(uint256 tokenId) private {
        if (_tokenApprovals[tokenId] != address(0)) {
            _tokenApprovals[tokenId] = address(0);
        }
    }

}

pragma solidity ^0.5.16;

contract IERC721Enumerable is IERC721 {
    function totalSupply() public view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256 tokenId);
    function tokenByIndex(uint256 index) public view returns (uint256);
}

pragma solidity ^0.5.16;

contract ERC721Enumerable is ERC165, ERC721, IERC721Enumerable {

    mapping(address => uint256[]) private _ownedTokens;
    mapping(uint256 => uint256) private _ownedTokensIndex;
    uint256[] private _allTokens;
    mapping(uint256 => uint256) private _allTokensIndex;
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    constructor () public {
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        require(index < balanceOf(owner));
        return _ownedTokens[owner][index];
    }

    function totalSupply() public view returns (uint256) {
        return _allTokens.length;
    }

    function tokenByIndex(uint256 index) public view returns (uint256) {
        require(index < totalSupply());
        return _allTokens[index];
    }

    function _transferFrom(address from, address to, uint256 tokenId) internal {
        super._transferFrom(from, to, tokenId);
        _removeTokenFromOwnerEnumeration(from, tokenId);
        _addTokenToOwnerEnumeration(to, tokenId);
    }

    function _mint(address to, uint256 tokenId) internal {
        super._mint(to, tokenId);
        _addTokenToOwnerEnumeration(to, tokenId);
        _addTokenToAllTokensEnumeration(tokenId);
    }

    function _tokensOfOwner(address owner) internal view returns (uint256[] storage) {
        return _ownedTokens[owner];
    }

    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        _ownedTokensIndex[tokenId] = _ownedTokens[to].length;
        _ownedTokens[to].push(tokenId);
    }

    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        uint256 lastTokenIndex = _ownedTokens[from].length.sub(1);
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];
            _ownedTokens[from][tokenIndex] = lastTokenId;
            _ownedTokensIndex[lastTokenId] = tokenIndex;
        }

        _ownedTokens[from].length--;
    }

    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {

        uint256 lastTokenIndex = _allTokens.length.sub(1);
        uint256 tokenIndex = _allTokensIndex[tokenId];
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId;
        _allTokensIndex[lastTokenId] = tokenIndex;

        _allTokens.length--;
        _allTokensIndex[tokenId] = 0;
    }
}

pragma solidity ^0.5.16;

contract IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}


pragma solidity ^0.5.16;

contract ERC721Metadata is ERC165, ERC721, IERC721Metadata {

    string private _name;
    string private _symbol;

    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

}

pragma solidity ^0.5.16;

contract ERC721Full is ERC721, ERC721Enumerable, ERC721Metadata {
    constructor (string memory name, string memory symbol) public ERC721Metadata(name, symbol) {
    }
}
pragma solidity ^0.5.16;

contract IRadicalNFT is IERC165 {
    function round(uint256 _tokenid) external view returns (uint256 _round);
    function price(uint256 _round) public returns (uint256 _price);
    function getBidStartTime(uint256 tokenid)external view returns(uint64);
    function bid(address inviterAddress, uint256 tokenid) external payable;
}
contract RadicalNFT is ERC165,IRadicalNFT {

    bytes4 private constant _INTERFACE_ID_RADICALNFT = 0x9203c74e;
 //       bytes4(keccak256('round(uint256)')) ^
 //       bytes4(keccak256('price(uint256)')) ^
 //       bytes4(keccak256('getBidStartTime(uint256)')) ^
 //       bytes4(keccak256('bid(address,uint256)'));

    constructor () public {
        _registerInterface(_INTERFACE_ID_RADICALNFT);
    }
}

contract Ownable {
  address public owner;

    constructor() public {
    owner = msg.sender;
  }


  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) onlyOwner public {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor ()public {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}
contract ArtistBase is Ownable,ERC721Full,RadicalNFT,ReentrancyGuard {
    
    using SafeMath for uint256;
    
    bool public paused = false;
    address public cfoAddress;
    address public cooAddress;
    
    address public bonusPoolAddress;
    address public devPoolAddress;  
    uint256[] private priceList;



    /// @dev The main art struct. 
    struct Art {
        uint256 id;
        uint64 bidStartTime;
        uint64 round;
        //bid issue privileges
        bool bid;
        string ipfs;
    }


    uint256 public lastBidTime=0;
    Art[]  arts;

    //current id 
    uint256 curid;
    
    uint256 public bidInterval;
    uint256 public defaultBidTokenId;
    
    modifier onlyCLevel() {
        require(
            msg.sender == cooAddress 
        );
        _;
    }
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /// @dev Modifier to allow actions only when the contract IS paused
    modifier whenPaused {
        require(paused);
        _;
    }


    function pause() external onlyCLevel whenNotPaused {
        paused = true;
    }

    function unpause() public onlyCLevel whenPaused {
        paused = false;
    }

    function creatArt(
        bool bidflag,
        string calldata ipfsaddr,
        uint64 startTime

    )
        external
        whenNotPaused
        returns (uint256)
    {
         require(msg.sender == owner, "ERR_NOT_OWNER");


        if(lastBidTime==0){
            bidflag=false;
        }else if((now-lastBidTime)<bidInterval){
            bidflag=false;
        }else{
            if(bidflag){
                lastBidTime=now;
            }
        }

        Art memory _art = Art({
            id: curid,
            bidStartTime: startTime,
            round: 0,
            bid: bidflag,
            ipfs: ipfsaddr

        });
        curid = arts.push(_art) ;

        require(curid == uint256(uint32(curid)));

        _mint(owner, curid-1);

        return curid;
    }
    
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId));
        return arts[tokenId].ipfs;
    }

    function checkArtBidable(uint256 tokenId) external view returns (bool) {
        require(_exists(tokenId));
        return arts[tokenId].bid;
    }

    function openBidTokenAuthority() 
        external
        onlyCLevel
        {
            lastBidTime=now - bidInterval;
        }

    function closeBidTokenAuthority() 
        external
        onlyCLevel
        {
            lastBidTime=0;
        }

    function setBidInterval(uint256 interval) 
        external
        onlyCLevel
        {
            bidInterval=interval;
        }
        

    function changeArtData(uint256 tokenid,string calldata ipfs) 
        external
        onlyCLevel
        {
            require(tokenid<curid, "ERR_ARTID_TOOBIG");
            arts[tokenid].ipfs=ipfs;
        }
    function editArtData(uint256 tokenid,string calldata ipfs) 
        external
        onlyOwner
        {
            require(tokenid<curid, "ERR_ARTID_TOOBIG");
            require(arts[tokenid].bidStartTime>now,"ERR_ALREADY_START");
            arts[tokenid].ipfs=ipfs;
        }

    function checkBidable() view
        external
        returns (bool){
        
            if(lastBidTime==0){
                return false;
            }else if((now-lastBidTime)<bidInterval){
                return false;
            }else{
                return true;
            }
        
        }
    function getLatestTokenID() view
        external
        returns (uint256){
            return curid;
        }
        
    function setBidStartTime(uint256 tokenid,uint64 startTime) 
        external
        onlyOwner
        {
            require(tokenid<curid, "ERR_TOKEN_ID_ERROR");
            require(arts[tokenid].bidStartTime>now,"ERR_ALREADY_START");
            arts[tokenid].bidStartTime=startTime;
        }
    function getBidStartTime(uint256 tokenid) view
        external
        returns(uint64)
        {
            require(tokenid<curid, "ERR_TOKEN_ID_ERROR");
            return arts[tokenid].bidStartTime;
        }
    function setDefaultBidId(uint256 tokenid) 
        external
        onlyOwner
        {
            require(tokenid<curid, "ERR_TOKEN_ID_ERROR");

            defaultBidTokenId=tokenid;
        }
        
    function round(uint256 tokenid) view 
        external
        returns (uint256){
            return arts[tokenid].round;
        }

    event LOG_AUCTION(
        uint256  artid,
        uint256  lastPrice,
        uint256  curPrice,
        uint256  bid,
        address  lastOwner,
        address  buyer,
        address  inviterAddress
    );
    //bid token address
    IERC20 public bidtoken;
    function () external
    whenNotPaused
     payable {
        _bid(devPoolAddress,defaultBidTokenId);
         
    }
   
      function bid(address inviterAddress, uint256 artid) payable
    whenNotPaused
     public {
        _bid(inviterAddress,artid); 
     }
     
     function price(uint256 _round) public
     returns (uint256)
     {
         if(_round>priceList.length){
             uint256 lastValue=priceList[priceList.length-1];
             for(uint256 i=priceList.length;i<_round;i++){
                 lastValue=lastValue.mul(11).div(10);
                 priceList.push(lastValue);
             }
             return lastValue;
         }
         return priceList[_round-1];
     }     
     
     function initRoundPrice() internal
     returns (uint256)
     {
         uint256 lastValue=0;
         for(uint256 i=1;i<12;i++){
            if(i<11){
                lastValue=i.mul(0.05 ether);
            }else{
                lastValue=lastValue.mul(11).div(10);
            }
            priceList.push(lastValue);
         }
     }
    
    function _bid(address inviterAddress, uint256 artid) nonReentrant internal
     {
         require(artid<curid, "ERR_ARTID_TOOBIG");  
         address lastOwner=ownerOf(artid);
         require(lastOwner!=msg.sender, "ERR_CAN_NOT_PURCHASE_OWN_ART");       
         require(arts[artid].bidStartTime<now,"ERR_BID_NOT_START_YET");
         uint256 r=arts[artid].round;
         
         if(r==0){
             uint256 payprice=0.05 ether;
             require(msg.value>=payprice, "ERR_NOT_ENOUGH_MONEY");
              msg.sender.send(msg.value.sub(payprice));
              address(uint160(owner)).send(payprice);
              uint256 x=0;
              if(arts[artid].bid){
                  x=50 ether;
                  if(bidtoken.balanceOf(cfoAddress)>=x){
                      bidtoken.transferFrom(cfoAddress,msg.sender,x);                  
                  }else{
                      x=0;
                  }
             }
             arts[artid].round++;
            _transferFrom(lastOwner, msg.sender, artid);

            emit LOG_AUCTION(artid, payprice,payprice,x,lastOwner,msg.sender,inviterAddress );
            return;
         }
        uint256 curprice=price(r);
        uint256 payprice=price(r+1);
        require(msg.value>=payprice, "ERR_NOT_ENOUGH_MONEY");
        
         //refund extra money
         msg.sender.send(msg.value-payprice);
         
         uint256 smoney=payprice-curprice;
         
         //we don't check any send process,only 2300 gas provided
         address(uint160(owner)).send(smoney.mul(5).div(10));

         address(uint160(bonusPoolAddress)).send(smoney.mul(18).div(100));
        
         address(uint160(inviterAddress)).send(smoney.mul(2).div(100));
        
         address(uint160(lastOwner)).send(smoney.mul(30).div(100).add(curprice));

         uint256 x=0;
         if(arts[artid].bid){
             //r is last round
            x=r<10?50 ether:((r+1).mul(5 ether));
            if(bidtoken.balanceOf(cfoAddress)>=x){
                bidtoken.transferFrom(cfoAddress,msg.sender,x);
            }else{
                x=0;
            }
         }

         arts[artid].round++;
    
          _transferFrom(lastOwner, msg.sender, artid);

        emit LOG_AUCTION(artid, curprice,payprice,x,lastOwner,msg.sender,inviterAddress );

    }

}

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
}
contract Artist is ArtistBase{

    constructor(string memory _name,string memory _symbol,address artistaddr,
    address auditor,address _bid,address _bonusPool,address _devPool) ERC721Full(_name, _symbol) public {
        bonusPoolAddress=_bonusPool;
        devPoolAddress=_devPool;
        bidtoken=IERC20(_bid);
        curid=0;
        owner=artistaddr;
        cfoAddress=msg.sender;
        cooAddress=auditor;
        bidInterval=30 days;
        defaultBidTokenId=0;
        initRoundPrice();
    }
    function setCOO(address _newCOO) external onlyCLevel {
        require(_newCOO != address(0));

        cooAddress = _newCOO;
    }
    function rescueETH(address _address) external onlyCLevel {
        address(uint160(_address)).transfer(address(this).balance);
  }
 
}