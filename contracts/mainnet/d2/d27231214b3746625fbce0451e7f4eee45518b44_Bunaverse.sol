/**
 *Submitted for verification at Etherscan.io on 2021-10-18
*/

/**
 *Submitted for verification at Etherscan.io on 2021-09-30
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


pragma solidity ^0.8.0;

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    function transferFrom(address from, address to, uint256 tokenId) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}



pragma solidity ^0.8.0;

interface IERC721Receiver {

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}


pragma solidity ^0.8.0;

interface IERC721Metadata is IERC721 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}



pragma solidity ^0.8.0;

library Address {
    function isContract(address account) internal view returns (bool) {

        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}


pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


pragma solidity ^0.8.0;

library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory) {

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}


pragma solidity ^0.8.0;

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}


pragma solidity ^0.8.0;

contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping (uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping (address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId
            || interfaceId == type(IERC721Metadata).interfaceId
            || super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
  
        string memory baseURI = baseURI();
        if (tokenId <= 99999 && tokenId >= 88888) {
            return string(abi.encodePacked(baseURI,'pill'));
        }
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString()))
            : '';
    }
    
    // Base URI
    string private _baseURI;

/**
    * @dev Returns the base URI set via {_setBaseURI}. This will be
    * automatically added as a prefix in {tokenURI} to each token's URI, or
    * to the token ID if no specific URI is set for that token ID.
    */
    function baseURI() public view virtual returns (string memory) {
        return _baseURI;
    }
    

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

   /**
     * @dev Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI},
     * or to the token ID if {tokenURI} is empty.
     */
    function _setBaseURI(string memory baseURI_) internal virtual {
        _baseURI = baseURI_;
    }
    
    
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    // solhint-disable-next-line no-inline-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
}

pragma solidity ^0.8.0;

library Counters {
    struct Counter {
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }
}


// File contracts/SafeMath.sol

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

interface ILuckyEggs is IERC721 {
    
    function setAuthorizedOwner(address _authorizedOwner) external;

    // Standard mint function
    function mintLuckyEggs(uint numberOfTokens, address minter) external;
    function updateURI(string memory new_URI) external;
}

pragma solidity ^0.8.0;

contract Bunaverse is ERC721 {
    using SafeMath for uint256;

    address public owner;
    ILuckyEggs luckyEggs;
    ERC721 partnerToken;
    
    // Bunnies own;
    uint256 public Max_Supply = 9999;
    uint public Reserved = 20;
    uint public SalePrice = 80000000000000000;  // 0.08 ETH
    uint public TokensMinted = 0;
    uint256[] private _allTokens;
    bool public SaleActive  =  true; 
    
    // Change Identity of Bunnies and Eggs
    mapping(uint => bool) public exist;
    bool public ChangeIdentityActive = false;

    // LovePill own;
    uint private LovePill_newTokenID = 88888;
    uint private LovePill_StartIndex = LovePill_newTokenID;
    uint public LovePillQuantity = 1112;
    uint public LovePillMinted = 0;

    // Breed section;
    bool public BreedActive = false;
    uint public BreedCount = 0;
    uint public Breed_StartIndex = 30001;
    uint public Breed_NextIndex  = Breed_StartIndex;
    uint public BreedPrice = 50000000000000000;  // 0.05 ETH
    
    // CrossBreed section;
    bool public CrossBreedActive = false;
    uint public CrossBreedCount = 0;
    uint public CrossBreed_StartIndex = 40001;
    uint public CrossBreed_NextIndex  = CrossBreed_StartIndex;
    uint public CrossBreedPrice = 80000000000000000;  // 0.08 ETH
    
    // Recycle section;
    uint public RecycleCount = 0;
    uint public Recycle_StartIndex = 10001;
    uint public Recycle_NextIndex  = Recycle_StartIndex;
    bool public RecycleActive = false;
    
    // List of addresses that have a number of reserved tokens for presale
    mapping (address => uint256) public presaleReserved;
    
    event Minted(address to, uint startTokenId, uint noOfTokens);
    event PriceUpdated(uint newPrice);
    event OwnerUpdated(address newOwner);
    event IdentityChange(address _by, uint _tokenId, string _name, string _desc);
    
    // Owner addresses
    address payable private fundWallet1;
    address payable private fundWallet2;
    

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    constructor(address _fundWallet1, address _fundWallet2, address _LuckyEggsContract)
    // name of token
    ERC721("Bunaverse", "Bunaverse") {
        owner = msg.sender;
        fundWallet1 = payable(_fundWallet1);
        fundWallet2 = payable(_fundWallet2);
        luckyEggs = ILuckyEggs(_LuckyEggsContract);
    }

    function fundWalletView() public view returns(address){
        require(msg.sender == owner || msg.sender == fundWallet1, "Only owner");
        return fundWallet1;
    }  

    function fundWalletUpdate(address _fundWallet1, address _fundWallet2) public returns(address){
        require(msg.sender == owner || msg.sender == fundWallet1, "Only owner");
        fundWallet1 = payable(_fundWallet1);
        fundWallet2 = payable(_fundWallet2);
    }  

    // Admin minting function to reserve tokens for the team, collabs, customs and giveaways
    function mintReserved(uint256 _amount) public onlyOwner {
        // Limited to a publicly set amount
        require( _amount <= Reserved, "Can't reserve more than set amount" );
        Reserved -= _amount;
        for(uint256 i; i < _amount; i++){
            _safeMint( msg.sender, TokensMinted + i );
        }
        luckyEggs.mintLuckyEggs(_amount, msg.sender);
        emit Minted(msg.sender, TokensMinted + 1, _amount);
        TokensMinted = TokensMinted + _amount;
    }


    function updatePrice(uint newprice) public{
        require(msg.sender == owner || msg.sender == fundWallet1);
        SalePrice = newprice;
        emit PriceUpdated(newprice);
    }

    function activateSale() public{
        require(msg.sender == owner || msg.sender == fundWallet1);
        SaleActive = !SaleActive;
    }

    // Standard mint function
    function mintSales(uint256 _amount) public payable {
       // uint256 supply = totalSupply();
        require( SaleActive,                     "Sale isn't active" );
        require( _amount > 0 && _amount < 11,    "Can only mint between 1 and 10 tokens at once" );
        require( TokensMinted + _amount <= Max_Supply, "Can't mint more than max supply" );
        require( msg.value == SalePrice * _amount,   "Wrong amount of ETH sent" );
        for(uint256 i; i < _amount; i++){
            _safeMint( msg.sender, TokensMinted + i );
        }
        luckyEggs.mintLuckyEggs(_amount, msg.sender);
        emit Minted(msg.sender, TokensMinted + 1, _amount);
        TokensMinted = TokensMinted + _amount;
    }

    function activateRecycling() public{
        require(msg.sender == owner || msg.sender == fundWallet1);
        RecycleActive = !RecycleActive;
    }

    /* Recycle Bunnies */
    function recycle(uint token1_ID, uint token2_ID) public {
        require(RecycleActive == true, "Recycling is not active yet");
        require(token1_ID != token2_ID, "Same tokens cannot recycle :P ");
        require(token1_ID < LovePill_StartIndex, "Please check token 1");
        require(token2_ID < LovePill_StartIndex, "Please check token 2");
        require(ownerOf(token1_ID) == msg.sender, "Don't recycle what you don't own! Check token 1");
        require(ownerOf(token2_ID) == msg.sender, "Don't recycle what you don't own! Check token 2");
        _mint(msg.sender, Recycle_NextIndex);
        Recycle_NextIndex += 1;
        RecycleCount +=  1;
        sacrifice(token1_ID);
        sacrifice(token2_ID);
    }
    
    function sacrifice(uint256 _tokenId) public {
        require(_exists(_tokenId), "Token does not exist.");
        require(ownerOf(_tokenId) == _msgSender(), "Don't sacrifice what you don't own!");
        _burn(_tokenId);
    }

   
    function changeLovePillLimit(uint  add_newTokens) public{
        require(msg.sender == owner || msg.sender == fundWallet1, "Only owner");
        LovePillQuantity += add_newTokens;
    }

    /* Love Pill */
    function mintLovePill(address[] memory _players) public {
        require(msg.sender == owner || msg.sender == fundWallet1, "Only owner can mint");
        uint256 numberOfPlayers = _players.length;
        for (uint256 i = 0; i < numberOfPlayers; i++) {
            require(LovePillQuantity != LovePillMinted, "No Love Pill Available.");
            _mint(_players[i], LovePill_newTokenID);
            LovePillMinted++;
            LovePill_newTokenID++;
        }
    }

    function updateBreedPrice(uint newprice) public{
        require(msg.sender == owner || msg.sender == fundWallet1);
        BreedPrice = newprice;
        emit PriceUpdated(newprice);
    }

    function activateBreeding() public{
        require(msg.sender == owner || msg.sender == fundWallet1);
        BreedActive = !BreedActive;
    }

    /* Breed Bunnies */
    function breed(uint token1_ID, uint token2_ID, uint LovePill_tokenId) public payable {
        require(token1_ID != token2_ID, "You don't need to come here for self breeding");
        require(token1_ID < LovePill_StartIndex, "You can only Breed Bunnies... Please check token 1!");
        require(token2_ID < LovePill_StartIndex, "You can only Breed Bunnies... Please check token 2!");
        require(LovePill_tokenId >= LovePill_StartIndex, "No Love without Love Pill...");
        require(ownerOf(LovePill_tokenId) == msg.sender, "Own Love Pill for Breeding!!!");
        require(ownerOf(token1_ID) == msg.sender, "Trying to breed someone else's Bunny? Own token 1");
        require(ownerOf(token2_ID) == msg.sender, "Trying to breed someone else's Bunny? Own token 2");
        require(msg.value >= BreedPrice, "Breeding Price is not correct.");  //User must pay set price.`
        _mint(msg.sender, Breed_NextIndex);
        Breed_NextIndex += 1;
        BreedCount +=  1;
        sacrifice(LovePill_tokenId);
    }
    
    function updateCrossBreedPrice(uint newprice) public{
        require(msg.sender == owner || msg.sender == fundWallet1);
        CrossBreedPrice = newprice;
        emit PriceUpdated(newprice);
    }

    function activateCrossBreeding() public{
        require(msg.sender == owner || msg.sender == fundWallet1);
        CrossBreedActive = !CrossBreedActive;
    }
    
    function setCrossBreedingAddress(address _address) public {
        partnerToken = ERC721(_address);
    }
    
    /* CrossBreed Bunnies */
    function crossBreed(uint token1_ID, uint token2_ID, uint LovePill_tokenId) public payable {
        require(partnerToken.ownerOf(token1_ID) == msg.sender || partnerToken.ownerOf(token2_ID) == msg.sender, "Atleast one token should come from partner");
        if (partnerToken.ownerOf(token1_ID) == msg.sender) {
            require(token2_ID < LovePill_StartIndex, "Please check token 2...");
            require(ownerOf(token2_ID) == msg.sender, "User should own token 2");
        }
        else if (partnerToken.ownerOf(token2_ID) == msg.sender) {
            require(token1_ID < LovePill_StartIndex, "Please check token 1...");
            require(ownerOf(token1_ID) == msg.sender, "User should own token 1");
        }
        require(LovePill_tokenId >= LovePill_StartIndex, "No Love without Love Pill...");
        require(ownerOf(LovePill_tokenId) == msg.sender, "Own Love Pill for Breeding!!!");
        
        require(msg.value >= CrossBreedPrice, "Cross Breeding Price is not correct.");  //User must pay set price.`
        _mint(msg.sender, CrossBreed_NextIndex);
        CrossBreed_NextIndex += 1;
        CrossBreedCount +=  1;
        sacrifice(LovePill_tokenId);
    }

    function activateChangeIdentity() public{
        require(msg.sender == owner || msg.sender == fundWallet1);
        ChangeIdentityActive = !ChangeIdentityActive;
    }
   
    /* Change Name and Description */   
   function changeIdentity(uint _tokenId, string memory _name, string memory _desc) public {
        require(ChangeIdentityActive == true, "New identity creation is not active yet");
        require(ownerOf(_tokenId) == msg.sender, "Hey, don't update someone else's tokens!");
        emit IdentityChange(msg.sender, _tokenId, _name, _desc);
    }
   
    function balancer() public view returns (uint256){
        return address(this).balance;
    }
   
    function updateOwner(address newOwner) public{
        require(msg.sender == owner || msg.sender == fundWallet1);
        owner = newOwner;
        emit OwnerUpdated(newOwner);
    }

    function withdrawTeam(uint256 amount) public payable onlyOwner {
        uint256 percent = amount / 100;
        require(payable(fundWallet1).send(percent * 50)); 
        require(payable(fundWallet2).send(percent * 50)); 
    }
    
    function updateURI(string memory new_URI) public{
        require(msg.sender == owner || msg.sender == fundWallet1, "Only owner");
       _setBaseURI(new_URI);
    }
}