/**
 *Submitted for verification at BscScan.com on 2021-08-24
*/

pragma solidity ^0.5.0;

contract Controlled {
    modifier onlyController { 
        require(msg.sender == controller); 
        _; 
    }

    address public controller;
    constructor () public {
        controller = msg.sender;
    }

    function changeController(address _newController) public onlyController {
        controller = _newController;
    }
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

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
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}


contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) public view returns (uint256 balance);
    function ownerOf(uint256 tokenId) public view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) public;
    function transferFrom(address from, address to, uint256 tokenId) public;
    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}

contract IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public returns (bytes4);
}

contract ERC721 is ERC165, IERC721 {
    using SafeMath for uint256;
    using Address for address;

    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;
    mapping (uint256 => address) private _tokenOwner;
    mapping (uint256 => address) private _tokenApprovals;
    uint256 internal _totalSupply;

    /**
     * @dev Enumerable takes care of this.
    **/
    //mapping (address => Counters.Counter) private _ownedTokensCount;
    mapping (address => mapping (address => bool)) private _operatorApprovals;
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    constructor () public {
        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
    }

    function totalSupply() public view returns (uint256) {
      return _totalSupply;
    }
    
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _tokenOwner[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");

        return owner;
    }
    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }
    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }
    function setApprovalForAll(address to, bool approved) public {
        require(to != msg.sender, "ERC721: approve to caller");

        _operatorApprovals[msg.sender][to] = approved;
        emit ApprovalForAll(msg.sender, to, approved);
    }
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }
    function transferFrom(address from, address to, uint256 tokenId) public {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");

        _transferFrom(from, to, tokenId);
    }
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransferFrom(from, to, tokenId, _data);
    }
    function _safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) internal {
        _transferFrom(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }
    function _exists(uint256 tokenId) internal view returns (bool) {
        address owner = _tokenOwner[tokenId];
        return owner != address(0);
    }
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }
    function _safeMint(address to, uint256 tokenId) internal {
        _safeMint(to, tokenId, "");
    }
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }
    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _tokenOwner[tokenId] = to;
        _totalSupply = _totalSupply.add(1);

        emit Transfer(address(0), to, tokenId);
    }
    function _burn(address owner, uint256 tokenId) internal {
        require(ownerOf(tokenId) == owner, "ERC721: burn of token that is not own");

        _clearApproval(tokenId);

        _tokenOwner[tokenId] = address(0);
        _totalSupply = _totalSupply.sub(1);

        emit Transfer(owner, address(0), tokenId);
    }
    function _burn(uint256 tokenId) internal {
        _burn(ownerOf(tokenId), tokenId);
    }
    function _transferFrom(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _clearApproval(tokenId);

        _tokenOwner[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)  internal returns (bool) {
        if (!to.isContract()) {
            return true;
        }
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = to.call(abi.encodeWithSelector(
            IERC721Receiver(to).onERC721Received.selector,
            msg.sender,
            from,
            tokenId,
            _data
        ));
        if (!success) {
            if (returndata.length > 0) {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert("ERC721: transfer to non ERC721Receiver implementer");
            }
        } else {
            bytes4 retval = abi.decode(returndata, (bytes4));
            return (retval == _ERC721_RECEIVED);
        }
    }
    function _clearApproval(uint256 tokenId) private {
        if (_tokenApprovals[tokenId] != address(0)) {
            _tokenApprovals[tokenId] = address(0);
        }
    }
}



contract ERC721Enumerable is ERC165, ERC721 {
    mapping(address => uint256[]) private _ownedTokens;
    mapping(uint256 => uint256) private _ownedTokensIndex;
    /**
     * @dev We've removed allTokens functionality.
    **/
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    constructor () public {
        // register the supported interface to conform to ERC721Enumerable via ERC165
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }
    
    /**
     * @dev Added for arNFT (removed from ERC721 basic).
    **/
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");

        return _ownedTokens[owner].length;
    }
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        require(index < balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }
    function _transferFrom(address from, address to, uint256 tokenId) internal {
        super._transferFrom(from, to, tokenId);

        _removeTokenFromOwnerEnumeration(from, tokenId);

        _addTokenToOwnerEnumeration(to, tokenId);
    }
    function _mint(address to, uint256 tokenId) internal {
        super._mint(to, tokenId);

        _addTokenToOwnerEnumeration(to, tokenId);
    }
    function _burn(address owner, uint256 tokenId) internal {
        super._burn(owner, tokenId);

        _removeTokenFromOwnerEnumeration(owner, tokenId);
        // Since tokenId will be deleted, we can clear its slot in _ownedTokensIndex to trigger a gas refund
        _ownedTokensIndex[tokenId] = 0;
    }
    function _tokensOfOwner(address owner) internal view returns (uint256[] storage) {
        return _ownedTokens[owner];
    }
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        _ownedTokensIndex[tokenId] = _ownedTokens[to].length;
        _ownedTokens[to].push(tokenId);
    }
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        uint256 lastTokenIndex = _ownedTokens[from].length.sub(1);
        uint256 tokenIndex = _ownedTokensIndex[tokenId];
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }
        _ownedTokens[from].length--;
    }
}



contract IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract NFT is Controlled, ERC721Enumerable, IERC721Metadata {

    event Aucting(address indexed from, uint256 indexed amount, uint256 indexed tokenId);
    event FreshPrice(address winner, uint256 lastPrice, uint256 price, uint256 tokenId);
    event StartAction(address from, address token, uint256 amount, uint256 step, uint256 tokenId, uint256 end);

    using SafeMath for uint256;
    using Address for address;
    
    string private _name;
    string private _symbol;
    string private _baseURI;
    address private _feeToken;
    address private _dToken;
    mapping(uint256 => address) public tokenCreator;
    mapping(uint256 => string) private _tokenURIs;
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;
    mapping(uint256 => uint256)   private tokenAuctionPrice;
    mapping(uint256 => address)   private tokenAuctionWinner;
    mapping(uint256 => address)   private tokenAuctionTrans;
    mapping(uint256 => uint256)   private tokenAuctionEnd;
    mapping(uint256 => uint256)   private tokenAuctionPricePoint;
    mapping(uint256 => uint256)   private tokenAuctionBids;
    mapping(uint256 => address[])   private tokenAuctionBiders;
    mapping(uint256 => mapping(address => uint8))   private tokenAuctionBider;
    mapping(address => uint256)  private _userBidcount; //
    mapping(address => uint256)  private _userAmount; //
    mapping(address => uint256)  private _frozenAmount; //


    constructor (string memory name, string memory symbol, address feeToken, address dToken) public {
        _name = name;
        _symbol = symbol;
        _feeToken = feeToken;
        _dToken = dToken;
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
    }

    function setBaseURI(string memory _URI) public onlyController returns(bool){
        _setBaseURI(_URI);
        return true;
    }

    function publishToken(uint256 _tokenId, address _to, string memory _tokenURI) public onlyController returns(bool){
        super._mint(msg.sender, _tokenId);
        _setTokenURI(_tokenId, _tokenURI);
        tokenCreator[_tokenId] = _to;
        super.transferFrom(msg.sender, _to, _tokenId);
        return true;
    }

    function auctionToken(uint256 _tokenId, uint _baseAmount, uint _froAmount, uint _duration) public returns (bool) {
        require(_exists(_tokenId), "NFT: auction for nonexistent token");
        require(ownerOf(_tokenId)==msg.sender, "NFT: not owner");
        require(tokenAuctionPrice[_tokenId]==0, "NFT: already start auction");
        require(_baseAmount>0, "NFT: price param illage");
        require(_duration<=86400*7, "too long time");
        require(_userFee[msg.sender]>=_userFro[msg.sender].add(_froAmount), "NFT: promise too less");
        uint256 end = now+_duration;
        tokenAuctionPrice[_tokenId] = _baseAmount;
        tokenAuctionWinner[_tokenId] = msg.sender;
        tokenAuctionEnd[_tokenId] = end;
        tokenAuctionPricePoint[_tokenId] = now;
        _tokenFro[_tokenId] = _froAmount;
        _userFro[msg.sender] = _userFro[msg.sender].add(_froAmount);

        emit StartAction(msg.sender, _dToken, _baseAmount, 0, _tokenId, end);
        return true;
    }

    function joinAuction(uint256 _tokenId) public returns (bool) {
        require(tokenAuctionPrice[_tokenId]>0, "NFT: auction not start");
        require(now<tokenAuctionEnd[_tokenId], "NFT: already end");
        require(tokenAuctionBider[_tokenId][msg.sender] == 0, "NFT: repeat bid");
        require(_userBidcount[msg.sender] == 0, "NFT: busy!");
        uint256 lastPrice = tokenAuctionPrice[_tokenId];
        uint256 thisPrice = lastPrice.mul(106).div(100);
        require(_userAmount[msg.sender]>=thisPrice, "NFT: recharge amount");
        if(lastPrice>1000000000){
            require(tokenAuctionBids[_tokenId]<30||now >= (tokenAuctionPricePoint[_tokenId]+43200));
        }
        _userBidcount[msg.sender] = _userBidcount[msg.sender].add(1);
        tokenAuctionBider[_tokenId][msg.sender] = 1;
        tokenAuctionBiders[_tokenId].push(msg.sender);
        tokenAuctionBids[_tokenId] = tokenAuctionBids[_tokenId].add(1);
        _userAmount[msg.sender] = _userAmount[msg.sender].sub(thisPrice);
        _frozenAmount[msg.sender] = _frozenAmount[msg.sender].add(thisPrice);

        if(lastPrice>1000000000){
            if(now >= (tokenAuctionPricePoint[_tokenId]+43200)){
                refreshTokenPrice(_tokenId);
            }
        }else{
            if(tokenAuctionBids[_tokenId]>=10||now >= (tokenAuctionPricePoint[_tokenId]+600)){
                refreshTokenPrice(_tokenId);
            }
        }

        

        emit Aucting(msg.sender, lastPrice.mul(106).div(100), _tokenId);
        return true;
    }

    function refreshTokenPrice(uint256 _tokenId) internal returns(bool){
        uint256 lastPrice = tokenAuctionPrice[_tokenId];
        uint256 thisPrice = lastPrice.mul(106).div(100);
        address winner = tokenAuctionWinner[_tokenId];
        uint maxPromise = 0;
        address maxUser = address(0);
        address[] memory currJoins = tokenAuctionBiders[_tokenId];
        for(uint i = 0; i<currJoins.length; i++){
            address bidUser = currJoins[i];
            tokenAuctionBider[_tokenId][bidUser] = 0;
            _userBidcount[bidUser] = _userBidcount[bidUser].sub(1);
            _userAmount[bidUser] = _userAmount[bidUser].add(thisPrice);
            _frozenAmount[bidUser] = _frozenAmount[bidUser].sub(thisPrice);
            uint256 myPromise = userActivePromise(bidUser);
            if(myPromise>maxPromise||maxUser==address(0)){
                maxUser = bidUser;
                maxPromise = myPromise;
            }
        }

        emit FreshPrice(maxUser, lastPrice, lastPrice.mul(106).div(100), _tokenId);

        bool succ = distribeIncrease(_tokenId, maxUser, winner, lastPrice);
        require(succ,"distribe fail");
        delete tokenAuctionBiders[_tokenId];
        tokenAuctionBids[_tokenId]=0;
        tokenAuctionPricePoint[_tokenId] = now;
        tokenAuctionWinner[_tokenId] = maxUser;
        tokenAuctionPrice[_tokenId] = lastPrice.mul(106).div(100);
        return true;
    }

    function distribeIncrease(uint256 _tokenId, address newWiner, address oldWiner, uint256 lastPrice) internal returns(bool){
        address owner = ownerOf(_tokenId);
        uint256 newPrice = lastPrice.mul(106).div(100);
        uint256 increase = newPrice - lastPrice;
        _userAmount[newWiner] = _userAmount[newWiner].sub(newPrice);
        _userAmount[owner] = _userAmount[owner].add(increase/6);
        _userAmount[oldWiner] = _userAmount[oldWiner].add(lastPrice).add(increase/3);
        _userAmount[controller] = _userAmount[controller].add(increase/2);
        return true;

    }

    function finishAuction(uint256 _tokenId) public returns (bool){
        require(tokenAuctionPrice[_tokenId]>0, "NFT: auction not start");
        require(now>tokenAuctionEnd[_tokenId], "NFT: too early");
        if(tokenAuctionBids[_tokenId]>0){
            refreshTokenPrice(_tokenId);
        }

        address winner = tokenAuctionWinner[_tokenId];
        address oldOwner = ownerOf(_tokenId);
        super._transferFrom(oldOwner, winner, _tokenId);
        tokenAuctionPrice[_tokenId] = 0;
        uint256 tokenFrothen = _tokenFro[_tokenId];
        _userFro[oldOwner] = _userFro[oldOwner].sub(tokenFrothen);
        return true;
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        require(tokenAuctionPrice[tokenId]==0, "NFT: already start auction");
        super.transferFrom(from, to, tokenId);
    }
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        require(tokenAuctionPrice[tokenId]==0, "NFT: already start auction");
        super.safeTransferFrom(from, to, tokenId, "");
    }
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
        require(tokenAuctionPrice[tokenId]==0, "NFT: already start auction");
        super.safeTransferFrom(from, to, tokenId, _data);
    }

    function name() public view returns (string memory) {
        return _name;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function baseURI() public view returns (string memory) {
        return _baseURI;
    }
    function tokenAuctionStatus(uint256 _tokenId) public view returns (uint256 price, address winner, address priceToken, uint256 endPoint, uint256 pricePoint, uint bidCount, address[] memory bidUsers) {
        price = tokenAuctionPrice[_tokenId];
        winner = tokenAuctionWinner[_tokenId];
        priceToken = tokenAuctionTrans[_tokenId];
        endPoint = tokenAuctionEnd[_tokenId];
        pricePoint = tokenAuctionPricePoint[_tokenId];
        bidCount = tokenAuctionBids[_tokenId];
        bidUsers = tokenAuctionBiders[_tokenId];
    }
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];

        // Even if there is a base URI, it is only appended to non-empty token-specific URIs
        if (bytes(_tokenURI).length == 0) {
            return "";
        } else {
            // abi.encodePacked is being used to concatenate strings
            return string(abi.encodePacked(_baseURI, _tokenURI));
        }
    }
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }
    function _setBaseURI(string memory _URI) internal {
        _baseURI = _URI;
    }
    
    function burn(uint256 tokenId) public returns(bool){
        super._burn(msg.sender, tokenId);

        // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
        return true;
    }


    mapping(address => uint256)  private _userFee; //
    mapping(address => uint256)  private _userFro; //
    mapping(uint256 => uint256)  private _tokenFro; //


    function userActivePromise(address _from) internal view returns(uint256){
        uint256 active = SafeMath.sub(_userFee[_from], _userFro[_from]);
        return active;
    }


    function withdraw(uint256 _number) public returns (bool){
        require(_number>0,"illage param");
        uint256 activeAmount = userActivePromise(msg.sender);
        require(_userFee[msg.sender] >= _number,"Insufficient Balance");
        require(activeAmount >= _number,"some frozen, out of balance");
        IERC20 fee = IERC20(_feeToken);
        bool success = fee.transfer(msg.sender, _number);
        require(success);
        _userFee[msg.sender] = SafeMath.sub(_userFee[msg.sender], _number ); 
        return true;
    }

    function recharge(uint _number) public returns (bool){
        require(_number>0,"illage param");
        IERC20 fee = IERC20(_feeToken);
        bool success =fee.transferFrom(msg.sender, address(this), _number);
        require(success);
        _userFee[msg.sender] = SafeMath.add(_userFee[msg.sender], _number); 
        return true;
    }

    function withdrawD(uint256 _number) public returns (bool){
        require(_number>0,"illage param");
        require(_userAmount[msg.sender] >= _number,"Insufficient Balance");
        IERC20 fee = IERC20(_dToken);
        bool success = fee.transfer(msg.sender, _number);
        require(success);
        _userAmount[msg.sender] = SafeMath.sub(_userAmount[msg.sender], _number ); 
        
        return true;
    }

    function rechargeD(uint _number) public returns (bool){
        require(_number>0,"illage param");
        IERC20 fee = IERC20(_dToken);
        bool success =fee.transferFrom(msg.sender, address(this), _number);
        require(success);
        _userAmount[msg.sender] = SafeMath.add(_userAmount[msg.sender], _number ); 
        
        return true;
    }

    function userFee(address from) public view returns (uint activeAmount, uint frozenAmount, uint bidCount, uint dAmount, uint frozenD) {
        uint totalAmount = _userFee[from];
        frozenAmount = _userFro[from];
        activeAmount = totalAmount.sub(frozenAmount);
        bidCount = _userBidcount[from];
        dAmount = _userAmount[from];
        frozenD = _frozenAmount[from];
    }
}




interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function decimals() external returns (uint8);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}