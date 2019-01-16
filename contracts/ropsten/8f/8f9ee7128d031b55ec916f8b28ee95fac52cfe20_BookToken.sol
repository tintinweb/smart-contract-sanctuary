pragma solidity ^0.4.21;

// File: contracts/SafeMath.sol

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

// File: contracts/AddressUtils.sol

/**
 * Utility library of inline functions on addresses
 */
library AddressUtils {

  /**
   * Returns whether the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract,
   *  as the code is not actually created until after the constructor finishes.
   * @param addr address to check
   * @return whether the target address is a contract
   */
  function isContract(address addr) internal view returns (bool) {
    uint256 size;
    // XXX Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address.
    // See https://ethereum.stackexchange.com/a/14016/36603
    // for more details about how this works.
    // TODO Check this again before the Serenity release, because all addresses will be
    // contracts then.
    assembly { size := extcodesize(addr) }  // solium-disable-line security/no-inline-assembly
    return size > 0;
  }

}

// File: contracts/ERC721.sol

contract ERC721Receiver {
  bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba;

  function onERC721Received(address _from, uint256 _tokenId, bytes _data) public returns(bytes4);
}


contract ERC721Interface {
    // events
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    // interface
    function balanceOf(address _owner) public view returns (uint256);
    function ownerOf(uint256 _tokenId) public view returns (address);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) public;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public;
    function transferFrom(address _from, address _to, uint256 _tokenId) public;
    function approve(address _approved, uint256 _tokenId) public;
    function setApprovalForAll(address _operator, bool _approved) public;
    function getApproved(uint256 _tokenId) public view returns (address);
    function isApprovedForAll(address _owner, address _operator) public view returns (bool);
}

contract ERC721 is ERC721Interface {
    using SafeMath for uint256;
    using AddressUtils for address;

    // Equals to `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`
    // which can be also obtained as `ERC721Receiver(0).onERC721Received.selector`
    bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba;

    // who owns which NFT
    mapping(uint256 => address) internal tokenOwner;

    // how many NFT an owner has (ownerAddress => tokenCounter)
    mapping (address => uint256) internal ownedTokensCount;

    // which account is approved to transfer a NFT (tokenId => approvedAddress)
    mapping (uint256 => address) internal tokenApprovals;

    // Mapping from owner to operator approvals
    // address "A" allows address "B" to operate all A&#39;s assets
    mapping (address => mapping (address => bool)) internal operatorApprovals;


    modifier canTransfer(uint256 _tokenId) {
        require(isApprovedOrOwner(msg.sender, _tokenId));
        _;
    }

    function isApprovedOrOwner(address _spender, uint256 _tokenId) internal view returns (bool) {
        address owner = ownerOf(_tokenId);
        return _spender == owner || getApproved(_tokenId) == _spender || isApprovedForAll(owner, _spender);
    }

    function balanceOf(address _owner) public view returns (uint256) {
        require(_owner != address(0));
        return ownedTokensCount[_owner];
    }

    function ownerOf(uint256 _tokenId) public view returns (address) {
        address owner = tokenOwner[_tokenId];
        require(owner != address(0));
        return owner;
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) public {
        // if target address is a contract, make sure it supports ERC721 interface
        if (_to.isContract()) {
            bytes4 retval = ERC721Receiver(_to).onERC721Received(_from, _tokenId, data);
            require(retval == ERC721_RECEIVED);
        }
        transferFrom(_from, _to, _tokenId);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public {
        safeTransferFrom(_from, _to, _tokenId, "");
    }

    function clearApproval(address _owner, uint256 _tokenId) internal {
        require(ownerOf(_tokenId) == _owner);
        if (tokenApprovals[_tokenId] != address(0)) {
            tokenApprovals[_tokenId] = address(0);
            emit Approval(_owner, address(0), _tokenId);
        }
    }

    function removeTokenFrom(address _from, uint256 _tokenId) internal {
        require(ownerOf(_tokenId) == _from);
        ownedTokensCount[_from] = ownedTokensCount[_from].sub(1);
        tokenOwner[_tokenId] = address(0);
    }

    function addTokenTo(address _to, uint256 _tokenId) internal {
        require(tokenOwner[_tokenId] == address(0));
        tokenOwner[_tokenId] = _to;
        ownedTokensCount[_to] = ownedTokensCount[_to].add(1);
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public canTransfer(_tokenId) {
        require(_from != address(0));
        require(_to != address(0));

        clearApproval(_from, _tokenId);
        removeTokenFrom(_from, _tokenId);
        addTokenTo(_to, _tokenId);

        emit Transfer(_from, _to, _tokenId);
    }

    function approve(address _approved, uint256 _tokenId) public {
        address owner = ownerOf(_tokenId);
        require(_approved != owner);
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

        if (getApproved(_tokenId) != address(0) || _approved != address(0)) {
            tokenApprovals[_tokenId] = _approved;
            emit Approval(owner, _approved, _tokenId);
        }
    }

    function setApprovalForAll(address _operator, bool _approved) public {
        require(_operator != msg.sender);
        operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function getApproved(uint256 _tokenId) public view returns (address) {
        return tokenApprovals[_tokenId];
    }

    function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
        return operatorApprovals[_owner][_operator];
    }

    function onERC721Received(address, uint256, bytes) public returns (bytes4) {
        return ERC721_RECEIVED;
    }
}

// File: contracts/BookToken.sol

contract BookToken is ERC721 {
    /*
     * NFT representing books
     */

    using SafeMath for uint256;
    using AddressUtils for address;

    string public constant name = "Book Token";
    string public constant symbol = "BOOK";

    enum Genre { ScienceFiction, Satire, Drama, Adventure, Romance, Horror }

    struct Book {
        string author;
        string title;
        uint256 publishedAt;
        Genre genre;
    }
    Book[] private books;

    event Mint(uint256 bookIndex, address creator);

    function BookToken() public {
        // mint initial books
        _mintBook(msg.sender, "J. K. Rowling", "Harry Potter and the Philosophers Stone", Genre.ScienceFiction);
        _mintBook(msg.sender, "William Shakespeare", "Hamlet", Genre.Drama);
        _mintBook(msg.sender, "J. R. R. Tolkien", "The Lord of the Rings", Genre.ScienceFiction);
    }

    function _mintBook(address owner, string author, string title, Genre genre) internal returns (uint256) {
        Book memory book = Book({
            author: author,
            title: title,
            publishedAt: now,
            genre: genre
        });
        uint256 index = books.push(book) - 1;
        emit Mint(index, msg.sender);

        addTokenTo(owner, index);
        emit Transfer(address(0), owner, index);

        return index;
    }

    function getTotalBooks() public view returns (uint) { return books.length; }
    function getAuthor(uint256 bookIndex) public view returns (string) { return books[bookIndex].author; }
    function getTitle(uint256 bookIndex) public view returns (string) { return books[bookIndex].title; }
    function getGenre(uint256 bookIndex) public view returns (Genre) { return books[bookIndex].genre; }
}