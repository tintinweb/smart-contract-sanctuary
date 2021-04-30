// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ERC165 {
  mapping(bytes4 => bool) private _supportedInterfaces;

  bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

  constructor() {
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC165.sol";

contract ERC721Metadata is Ownable, ERC165 {
  bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;
  string private _baseTokenURI;
  string private _NFTName = " ";
  string private _NFTSymbol = " ";

  constructor() {
    _registerInterface(_INTERFACE_ID_ERC721_METADATA);
    _baseTokenURI = " ";
  }

  function name() external view returns (string memory) {
    return _NFTName;
  }

  function symbol() external view returns (string memory) {
    return _NFTSymbol;
  }

  function setBaseURI(string calldata newBaseTokenURI) public onlyOwner {
    _baseTokenURI = newBaseTokenURI;
  }

  function baseURI() public view returns (string memory) {
    return _baseURI();
  }

  function _baseURI() internal view returns (string memory) {
    return _baseTokenURI;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title PaymentSplitter
 * @dev This contract allows to split Ether payments among a group of accounts. The sender does not need to be aware
 * that the Ether will be split in this way, since it is handled transparently by the contract.
 *
 * The split can be in equal parts or in any other arbitrary proportion. The way this is specified is by assigning each
 * account to a number of shares. Of all the Ether that this contract receives, each account will then be able to claim
 * an amount proportional to the percentage of total shares they were assigned.
 *
 * `PaymentSplitter` follows a _pull payment_ model. This means that payments are not automatically forwarded to the
 * accounts but kept in this contract, and the actual transfer is triggered as a separate step by calling the {release}
 * function.
 */
contract PaymentSplitter is Context {
  event PayeeAdded(address account, uint256 shares);
  event PaymentReleased(address to, uint256 amount);
  event PaymentReceived(address from, uint256 amount);

  uint256 private _totalShares;
  uint256 private _totalReleased;

  mapping(address => uint256) private _shares;
  mapping(address => uint256) private _released;
  address[] private _payees;

  /**
   * @dev Creates an instance of `PaymentSplitter` where each account in `payees` is assigned the number of shares at
   * the matching position in the `shares` array.
   *
   * All addresses in `payees` must be non-zero. Both arrays must have the same non-zero length, and there must be no
   * duplicates in `payees`.
   */
  constructor() {
    address[2] memory initialPayees =
      [
        address(0x9386efb02a55A1092dC19f0E68a9816DDaAbDb5b),
        address(0xF2353AD0930B9F7cf16b4b8300B843349581E817)
      ];
    uint256[2] memory initialShares = [uint256(7), uint256(3)];

    for (uint256 i = 0; i < initialPayees.length; i++) {
      _addPayee(initialPayees[i], initialShares[i]);
    }
  }

  /**
   * @dev The Ether received will be logged with {PaymentReceived} events. Note that these events are not fully
   * reliable: it's possible for a contract to receive Ether without triggering this function. This only affects the
   * reliability of the events, and not the actual splitting of Ether.
   *
   * To learn more about this see the Solidity documentation for
   * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
   * functions].
   */
  receive() external payable {
    emit PaymentReceived(_msgSender(), msg.value);
  }

  /**
   * @dev Getter for the total shares held by payees.
   */
  function totalShares() public view returns (uint256) {
    return _totalShares;
  }

  /**
   * @dev Getter for the total amount of Ether already released.
   */
  function totalReleased() public view returns (uint256) {
    return _totalReleased;
  }

  /**
   * @dev Getter for the amount of shares held by an account.
   */
  function shares(address account) public view returns (uint256) {
    return _shares[account];
  }

  /**
   * @dev Getter for the amount of Ether already released to a payee.
   */
  function released(address account) public view returns (uint256) {
    return _released[account];
  }

  /**
   * @dev Getter for the address of the payee number `index`.
   */
  function payee(uint256 index) public view returns (address) {
    return _payees[index];
  }

  /**
   * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
   * total shares and their previous withdrawals.
   */
  function release(address payable account) public virtual {
    require(_shares[account] > 0, "PaymentSplitter: account has no shares");

    uint256 totalReceived = address(this).balance + _totalReleased;
    uint256 payment =
      (totalReceived * _shares[account]) / _totalShares - _released[account];

    require(payment != 0, "PaymentSplitter: account is not due payment");

    _released[account] = _released[account] + payment;
    _totalReleased = _totalReleased + payment;

    Address.sendValue(account, payment);
    emit PaymentReleased(account, payment);
  }

  /**
   * @dev Add a new payee to the contract.
   * @param account The address of the payee to add.
   * @param shares_ The number of shares owned by the payee.
   */
  function _addPayee(address account, uint256 shares_) private {
    require(
      account != address(0),
      "PaymentSplitter: account is the zero address"
    );
    require(shares_ > 0, "PaymentSplitter: shares are 0");
    require(
      _shares[account] == 0,
      "PaymentSplitter: account already has shares"
    );

    _payees.push(account);
    _shares[account] = shares_;
    _totalShares = _totalShares + shares_;
    emit PayeeAdded(account, shares_);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./chainBeingFactory.sol";
import "./ERC721Metadata.sol";
import "./PaymentSplitter.sol";

contract chainBeing is ERC721Metadata, PaymentSplitter {
    using Address for address;
    using Strings for uint256;

    // EVENTS
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    event Generated(uint256 indexed index, address indexed _address, string value);

    mapping(uint256 => uint256) internal idToSeed;
    mapping(uint256 => uint256) internal seedToId;
    mapping(uint256 => address) internal idToOwner;
    mapping(address => uint256[]) internal ownerToIds;
    mapping(uint256 => uint256) internal idToOwnerIndex;
    mapping(address => mapping(address => bool)) internal ownerToOperators;
    mapping(uint256 => address) internal idToApproval;
    uint256 internal numTokens = 0;

    uint256 public constant TOKEN_LIMIT = 4520;
    bool public hasSaleStarted = false;

    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    modifier validNFToken(uint256 tokenId) {
        require(
            idToOwner[tokenId] != address(0),
            "ERC721: query for nonexistent token"
        );
        _;
    }

    modifier canOperate(uint256 tokenId) {
        address owner = idToOwner[tokenId];

        require(
            owner == _msgSender() || ownerToOperators[owner][_msgSender()],
            "ERC721: approve caller is not owner nor approved for all"
        );
        _;
    }

    modifier canTransfer(uint256 tokenId) {
        address tokenOwner = idToOwner[tokenId];

        require(
            tokenOwner == _msgSender() ||
                idToApproval[tokenId] == _msgSender() ||
                ownerToOperators[tokenOwner][_msgSender()],
            "ERC721: transfer caller is not owner nor approved"
        );
        _;
    }

    constructor() {
        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    function createChainBeing(uint256 seed)
        external
        payable
        returns (string memory)
    {
        return _mint(_msgSender(), seed);
    }

    function calculatePrice() internal view returns (uint256) {
        uint256 price;
        if (numTokens < 1000) {
            price = 0.085 ether;
        } else if (numTokens >= 1000 && numTokens < 1750) {
            price = 0.135 ether;
        } else if (numTokens >= 1750 && numTokens < 2500) {
            price = 0.185 ether;
        } else if (numTokens >= 2500 && numTokens < 3250) {
            price = 0.235 ether;
        } else {
            price = 0.285 ether;
        }
        return price;
    }

    function _mint(address to, uint256 _seed) internal returns (string memory) {
        require(hasSaleStarted == true, "Sale hasn't started");
        require(to != address(0), "ERC721: mint to the zero address");
        require(
            numTokens < TOKEN_LIMIT,
            "ERC721: maximum number of tokens already minted"
        );
        require(msg.value >= calculatePrice(), "ERC721: insufficient ether");

        require(seedToId[_seed] == 0, "ERC721: seed already used");

        uint256 id = numTokens + 1;

        idToSeed[id] = _seed;
        seedToId[_seed] = id;

        string memory chainBeingCharacter = chainBeingFactory.art(idToSeed[id], 1);
        emit Generated(id, to, chainBeingCharacter);

        numTokens = numTokens + 1;
        _registerToken(to, id);

        emit Transfer(address(0), to, id);

        return chainBeingCharacter;
    }

    function _registerToken(address to, uint256 tokenId) internal {
        require(idToOwner[tokenId] == address(0));
        idToOwner[tokenId] = to;

        ownerToIds[to].push(tokenId);
        uint256 length = ownerToIds[to].length;
        idToOwnerIndex[tokenId] = length - 1;
    }

    function draw(uint256 tokenId, uint256 _frame)
        external
        view
        validNFToken(tokenId)
        returns (string memory)
    {
        string memory uri = chainBeingFactory.art(idToSeed[tokenId], _frame);
        return uri;
    }

    function totalSupply() public view returns (uint256) {
        return numTokens;
    }

    function tokenByIndex(uint256 index) public view returns (uint256) {
        require(
            index < numTokens,
            "ERC721Enumerable: global index out of bounds"
        );
        return index;
    }

    function tokenOfOwnerByIndex(address owner, uint256 _index)
        external
        view
        returns (uint256)
    {
        require(
            _index < ownerToIds[owner].length,
            "ERC721Enumerable: owner index out of bounds"
        );
        return ownerToIds[owner][_index];
    }

    function balanceOf(address owner) external view returns (uint256) {
        require(
            owner != address(0),
            "ERC721: balance query for the zero address"
        );
        return ownerToIds[owner].length;
    }

    function ownerOf(uint256 tokenId) external view returns (address) {
        return _ownerOf(tokenId);
    }

    function _ownerOf(uint256 tokenId)
        internal
        view
        validNFToken(tokenId)
        returns (address)
    {
        address owner = idToOwner[tokenId];
        require(owner != address(0), "ERC721: query for nonexistent token");
        return owner;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external validNFToken(tokenId) canTransfer(tokenId) {
        address tokenOwner = idToOwner[tokenId];
        require(
            tokenOwner == from,
            "ERC721: transfer of token that is not own"
        );
        require(to != address(0), "ERC721: transfer to the zero address");
        _transfer(to, tokenId);
    }

    function _transfer(address to, uint256 tokenId) internal {
        address from = idToOwner[tokenId];
        _clearApproval(tokenId);
        emit Approval(from, to, tokenId);

        _removeNFToken(from, tokenId);
        _registerToken(to, tokenId);

        emit Transfer(from, to, tokenId);
    }

    function _removeNFToken(address from, uint256 tokenId) internal {
        require(idToOwner[tokenId] == from);
        delete idToOwner[tokenId];

        uint256 tokenToRemoveIndex = idToOwnerIndex[tokenId];
        uint256 lastTokenIndex = ownerToIds[from].length - 1;

        if (lastTokenIndex != tokenToRemoveIndex) {
            uint256 lastToken = ownerToIds[from][lastTokenIndex];
            ownerToIds[from][tokenToRemoveIndex] = lastToken;
            idToOwnerIndex[lastToken] = tokenToRemoveIndex;
        }

        ownerToIds[from].pop();
    }

    function approve(address approved, uint256 tokenId)
        external
        validNFToken(tokenId)
        canOperate(tokenId)
    {
        address owner = idToOwner[tokenId];
        require(approved != owner, "ERC721: approval to current owner");
        idToApproval[tokenId] = approved;
        emit Approval(owner, approved, tokenId);
    }

    function _clearApproval(uint256 tokenId) private {
        if (idToApproval[tokenId] != address(0)) {
            delete idToApproval[tokenId];
        }
    }

    function getApproved(uint256 tokenId)
        external
        view
        validNFToken(tokenId)
        returns (address)
    {
        return idToApproval[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) external {
        require(operator != _msgSender(), "ERC721: approve to caller");
        ownerToOperators[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool)
    {
        return ownerToOperators[owner][operator];
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external {
        _safeTransferFrom(from, to, tokenId, data);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external {
        _safeTransferFrom(from, to, tokenId, "");
    }

    function _safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private validNFToken(tokenId) canTransfer(tokenId) {
        address tokenOwner = idToOwner[tokenId];
        require(
            tokenOwner == from,
            "ERC721: transfer of token that is not own"
        );
        require(to != address(0), "ERC721: transfer to the zero address");

        _transfer(to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function tokenURI(uint256 tokenId)
        external
        view
        validNFToken(tokenId)
        returns (string memory)
    {
        string memory uri = _baseURI();
        return
            bytes(uri).length > 0
                ? string(abi.encodePacked(uri, tokenId.toString()))
                : "";
    }

    function startSale() public onlyOwner {
        hasSaleStarted = true;
    }

    function pauseSale() public onlyOwner {
        hasSaleStarted = false;
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721: transfer to non ERC721Receiver implementer"
                    );
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library chainBeingFactory {
/* enum Animations{ STATIC, BLINK_LEFT_EYE, BLINK_RIGHT_EYE,
BLINK_BOTH_EYES,MOVE_NOSE_LEFT,MOVE_NOSE_RIGHT,
MOVE_HEAD_DOWN,MOVE_HAT_UP,MOVE_LEFT_BROW,MOVE_RIGHT_BROW,MOVE_BOTH_BROWS } */

function charcterType(uint256 _seed) public pure returns (string memory){
   uint256 rand = uint256(keccak256(abi.encodePacked(_seed)))%1e18;
   uint256 id =((rand/1e16 )% 1e2)%10;
   if(id == 0) {
      return "Face0";
    }
    else if(id == 1) {
      return "Face1";

    }
    else if(id == 2){
      return "Face2";
    }
    else if(id == 3) {
     return "Face3";
    }
    else if(id == 4) {
      return "Face4";
    }
    else if(id == 5) {
     return "Face5";
    }
    else if(id == 6) {
      return "Face6";
    }
    else if(id == 7) {
     return "Face7";
    }
    else if(id == 8) {
     return "Face8";
    }
    else if(id == 9) {
     return "Face9";
    }
    else {
      return string(abi.encodePacked("ERROR"));
    }    
}

  function art(uint256 _seed,uint256 _frame) public pure returns (string memory) {
    uint256 rand = uint256(keccak256(abi.encodePacked(_seed)))%1e18;
    uint256 color_rand=(rand/1e12)%1e2;   
  string[4][13] memory colors=[
  [unicode"\x1B[38;5;53m",unicode"\x1B[38;5;54m",unicode"\x1B[38;5;55m",unicode"\x1B[38;5;56m"],
  [unicode"\x1B[38;5;125m",unicode"\x1B[38;5;126m",unicode"\x1B[38;5;127m",unicode"\x1B[38;5;128m"],
  [unicode"\x1B[38;5;15m",unicode"\x1B[38;5;15m",unicode"\x1B[38;5;15m",unicode"\x1B[38;5;15m"],
  [unicode"\x1B[38;5;197m",unicode"\x1B[38;5;198m",unicode"\x1B[38;5;199m",unicode"\x1B[38;5;200m"],  
  [unicode"\x1B[38;5;202m",unicode"\x1B[38;5;203m",unicode"\x1B[38;5;204m",unicode"\x1B[38;5;205m"],
  [unicode"\x1B[38;5;209m",unicode"\x1B[38;5;210m",unicode"\x1B[38;5;211m",unicode"\x1B[38;5;212m"],
  [unicode"\x1B[38;5;15m",unicode"\x1B[38;5;15m",unicode"\x1B[38;5;15m",unicode"\x1B[38;5;15m"],
  [unicode"\x1B[38;5;33m",unicode"\x1B[38;5;69m",unicode"\x1B[38;5;105m",unicode"\x1B[38;5;141m"],
  [unicode"\x1B[38;5;34m",unicode"\x1B[38;5;70m",unicode"\x1B[38;5;106m",unicode"\x1B[38;5;142m"],
  [unicode"\x1B[38;5;15m",unicode"\x1B[38;5;15m",unicode"\x1B[38;5;15m",unicode"\x1B[38;5;15m"],
  [unicode"\x1B[38;5;51m",unicode"\x1B[38;5;87m",unicode"\x1B[38;5;123m",unicode"\x1B[38;5;159m"],  
  [unicode"\x1B[38;5;45m",unicode"\x1B[38;5;81m",unicode"\x1B[38;5;117m",unicode"\x1B[38;5;153m"],
  [unicode"\x1B[38;5;47m",unicode"\x1B[38;5;83m",unicode"\x1B[38;5;119m",unicode"\x1B[38;5;155m"] 
  ];
 

    
    string memory hair =  _chooseTops(rand,_frame);
    string memory brows = _chooseEyeBrows(rand,_frame);
    string memory eyes = _chooseEyes(rand,_frame);
    string memory nose = _chooseNose(rand,_frame); 
    string memory mouth = _chooseMouth(rand);       
    return string(abi.encodePacked( colors[color_rand%13][0],hair, colors[color_rand%13][1],brows,colors[color_rand%13][2],eyes,nose,colors[color_rand%13][3], mouth,unicode"\x1B[0m"));
    
  }
function _chooseTops(uint256 _rand,uint256 _frame) internal pure returns(string memory){

   string[27] memory hairs =  [
      unicode"     _______",
      unicode"     ///////",
      unicode"     !!!!!!!",
      unicode"     ║║║║║║║",
      unicode"     ▄▄▄▄▄▄▄",
      unicode"     ███████",
      unicode"     ┌─────┐   \n"
      unicode"     │     │  \n"
      unicode"    ─┴─────┴─  ",       
      unicode"     ┌─────┐   \n"       
      unicode"     ├─────│    \n"
      unicode"    ─┴─────┴─ ",       
      unicode"     ┌▄▄▄▄▄┐  \n"       
      unicode"     ├─────┤  \n"       
      unicode"    ─┴─────┴─ ",       
      unicode"     ┌─────┐  \n"
      unicode"     ├─────┤  \n"
      unicode"    ─┴▀▀▀▀▀┴─ ",
      unicode"     ┌▄▄▄▄▄┐  \n"
      unicode"     ├─────┤  \n"
      unicode"    ─┴▀▀▀▀▀┴─ ",
      unicode"     ┌▄▄▄▄▄┐  \n"
      unicode"     ├█████┤  \n"
      unicode"    ─┴▀▀▀▀▀┴─ ",
      unicode"     ┌─────┐  \n"
      unicode"     │     │  \n"
      unicode"    ─┴▀▀▀▀▀┴─ ",
      unicode"              \n"
      unicode"     ┌─────┐  \n"
      unicode"    ─┴─────┴─ ",
      unicode"              \n"
      unicode"     ┌─────┐  \n"
      unicode"    ─┴▀▀▀▀▀┴─ ",
      unicode"              \n"
      unicode"      /███    \n"
      unicode"    ─┴▀▀▀▀▀┴─  ",
      unicode"               \n"
      unicode"      /▓▓▓    \n"
      unicode"    ─┴▀▀▀▀▀┴─  ",
      unicode"               \n"
      unicode"      ┌───┐    \n"
      unicode"   └─┴─────┴── ",
      unicode"            ,/ \n"
      unicode"      ┌───┐/'  \n"
      unicode"   └─┴─────┴── ",
      unicode"               \n"
      unicode"      .▄▄▄.    \n"
      unicode"   └─┴▀▀▀▀▀┴── ",
      unicode"            ,/ \n"
      unicode"      .▄▄▄./'  \n"
      unicode"   └─┴▀▀▀▀▀┴── ",
      unicode"               \n"
      unicode"      /ˇˇˇ    \n"
      unicode"     ┴─────┴   ",
      unicode"     ┌─────┐   \n"
      unicode"    ┌┴─────┴┐  \n"
      unicode"    └───────┘  ",
      unicode"               \n"
      unicode"     ┌─────┐   \n"
      unicode"    |░░░░░░░|  ",
      unicode"      ,.O.,    \n"
      unicode"     /»»»»»   \n"
      unicode"    /«««««««  ",
      unicode"      ,.O.,    \n"
      unicode"     /AAAAA   \n"
      unicode"    /VVVVVVV  ",
      unicode"      ,.O.,   \n"
      unicode"     /WWWWW   \n"
      unicode"    /MMMMMMM  "
    ];
    string memory beforeTop=unicode"\n\n";
    string memory afterTop=unicode"\n";
    uint256 tops_rand=(_rand/1e8)%1e2;
    uint256 animations_rand=(_rand/1e14)%1e2;
     if (  _frame==2){
      if( animations_rand%11==6){
        beforeTop=unicode"\n\n";
        afterTop=unicode"\n";       
      }
      if(animations_rand%11 ==7 && tops_rand%27>=6){
        beforeTop=unicode"\n";
        afterTop=unicode"\n\n";         
      }
     }
     return  string(abi.encodePacked(beforeTop,hairs[tops_rand%27],afterTop));
}
  function _chooseEyeBrows(uint256 _rand,uint256 _frame) internal pure returns(string memory){
    uint256 id =((_rand/1e16 )% 1e2)%10;
     uint256 brows_rand=(_rand/1e6)%1e2;
    uint256 animations_rand=(_rand/1e14)%1e2;
    string[3] memory brows = [
      unicode"_",
      unicode"~",
      unicode"¬"
    ];
    string memory leftBrow=brows[brows_rand%3];
    string memory rightBrow=brows[brows_rand%3];    
    if(_frame==2){
      if(animations_rand%11==8 && brows_rand%3==0){
          leftBrow="-";
        }
         else if(animations_rand%11==9 && brows_rand%3==0){
          rightBrow="-";
        }
         else if(animations_rand%11==10 && brows_rand%3==0){
          rightBrow="-";
          leftBrow="-";
        }
    }
    
    if(id == 0) {
      return string(abi.encodePacked("    # ",leftBrow, "   ",rightBrow," #" , unicode" \n"));
    }
    else if(id == 1) {
      return string(abi.encodePacked("    ! ",leftBrow, "   ",rightBrow," !" , unicode" \n"));
    }
    else if(id == 2){
      return string(abi.encodePacked("    | ",leftBrow, "   ",rightBrow," |" , unicode" \n"));
    }
    else if(id == 3) {
      return string(abi.encodePacked("    { ",leftBrow, "   ",rightBrow," }" , unicode" \n"));
    }
    else if(id == 4) {
      return string(abi.encodePacked(unicode"    ║ ",leftBrow, "   ",rightBrow,unicode" ║" , unicode" \n"));
    }
    else if(id == 5) {
      return string(abi.encodePacked(unicode"    # ",leftBrow, "   ",rightBrow,unicode" #" , unicode" \n"));
    }
    else if(id == 6) {
      return string(abi.encodePacked(unicode"    ) ",leftBrow, "   ",rightBrow,unicode"  )" , unicode" \n"));
    }
    else if(id == 7) {
      return string(abi.encodePacked("   (# ",leftBrow, "   ",rightBrow," #)" , unicode" \n"));
    }
    else if(id == 8) {
      return string(abi.encodePacked(unicode"   |  ",leftBrow, "   ",rightBrow,unicode"  |" , unicode" \n"));
    }
    else if(id == 9) {
      return string(abi.encodePacked(unicode"   .´       `.",unicode"\n",unicode"   |  ",leftBrow, "   ",rightBrow,unicode"  |" , unicode" \n"));
    }
    else {
      return string(abi.encodePacked("ERROR"));
    }
  }

  function _chooseEyes(uint256 _rand,uint256 _frame) internal pure returns (string memory) {
    uint256 id =((_rand/1e16 )% 1e2)%10;
     uint256 eyeGlass_rand=(_rand/1e4)%1e2;
    uint256 animations_rand=(_rand/1e14)%1e2;
    uint256 isEyeOrGlass=(_rand/1e10)%1e2;
    
    if(isEyeOrGlass % 2 == 0 && id != 9) {
      return _chooseGlasses(eyeGlass_rand,id);
    }
 
    string[22] memory Eyes =
      [
        unicode"0",
        unicode"9",
        unicode"o",
        unicode"O",
        unicode"p",
        unicode"P",
        unicode"q",
        unicode"°",
        unicode"Q",
        unicode"Ö",
        unicode"ö",
        unicode"ó",
        unicode"Ô",
        unicode"■",
        unicode"Ó",
        unicode"Ő",
        unicode"ő",
        unicode"○",
        unicode"╬",
        unicode"♥",
        unicode"¤",
        unicode"đ"
      ];

     string memory leftEye=Eyes[eyeGlass_rand % 22];
    string memory rightEye=Eyes[eyeGlass_rand % 22];
    
    if(_frame==2){
      if(animations_rand%11==1){
          leftEye="-";
        }
         else if(animations_rand%11==2){
          rightEye="-";
        }
         else if(animations_rand%11==3){
          rightEye="-";
          leftEye="-";
        }
    }
   


    if(id == 0) {
       return
        string(
          abi.encodePacked(
            "   d| ",
            leftEye,
            "   ",
            rightEye,
            " |b",
            unicode" \n"
          )
      );
    }
    else if(id == 1) {
      return
        string(
          abi.encodePacked(
            unicode"   «│ ",
            leftEye,
            "   ",
            rightEye,
            unicode" │»",
            unicode" \n"
          )
        );
    
    }
    else if(id == 2){
       return
        string(
          abi.encodePacked(
            "    ( ",
            leftEye,
            "   ",
            rightEye,
            " )",
            unicode" \n"
          )
        );
    }
    else if(id == 3) {
      return
        string(
          abi.encodePacked(
            "   d| ",
            leftEye,
            "   ",
            rightEye,
            " |b",
            unicode" \n"
          )
      );
    }
    else if(id == 4) {
      return
      string(
        abi.encodePacked(
          unicode"   d║ ",
          leftEye,
          "   ",
          rightEye,
          unicode" ║b",
          unicode" \n"
        )
      );
    }
    else if(id == 5) {
      return
      string(
        abi.encodePacked(
          unicode"   d| ",
          leftEye,
          "   ",
          rightEye,
          unicode" |b",
          unicode" \n"
        )
      );
    }
    else if(id == 6) {
      return
      string(
        abi.encodePacked(
          unicode"   (  ",
          leftEye,
          "   ",
          rightEye,
          unicode" (",
          unicode" \n"
        )
      );
    }
    else if(id == 7) {
      return
        string(
          abi.encodePacked(
            unicode"   @| ",
            leftEye,
            "   ",
            rightEye,
            unicode" |@",
            unicode" \n"
          )
        );
    }
    else if(id == 8) {
      return
      string(
        abi.encodePacked(
          unicode" |\\|  ",
          leftEye,
          "   ",
          rightEye,
          unicode"  |/|",
          unicode" \n"
        )
      );
    }
    else if(id == 9) {
      return
      string(
        abi.encodePacked(
          unicode"   \\ (",
          leftEye,
          "   ",
          rightEye,
          unicode") /",
          unicode" \n"
        )
      );
    }
    else {
      return string(abi.encodePacked("ERROR"));
    }
    
  }

  function _chooseNose(uint256 _rand,uint256 _frame) internal pure returns (string memory) {
  uint256 id =((_rand/1e16 )% 1e2)%10;
     uint256 nose_rand=(_rand/1e2)%1e2;
    uint256 animations_rand=(_rand/1e14)%1e2;
    
    string[15] memory noses =
      [
        unicode"<",
        unicode">",
        unicode"V",
        unicode"W",
        unicode"v",
        unicode"u",
        unicode"c",
        unicode"C",
        unicode"┴",
        unicode"L",
        unicode"Ł",
        unicode"└",
        unicode"┘",
        unicode"╚",
        unicode"╝"
    ];
    string memory leftNose=" ";
    string memory rightNose=" ";
    
    if(_frame==2 &&   id != 9){
      if(animations_rand%11==5){
          leftNose="";
          rightNose="  ";
        }
         else if(animations_rand%11==6){
          leftNose="  ";
          rightNose="";
        }
         
    }
    if(id == 0) {
      return string(abi.encodePacked("    (  ",leftNose,noses[nose_rand % 15],rightNose,"  )", unicode" \n"));
    }
    else if(id == 1){
      return string(abi.encodePacked("    \\  ",leftNose,noses[nose_rand % 15],rightNose,"  /", unicode" \n"));
    }
    else if(id == 2){
      return string(abi.encodePacked("  <(   ",leftNose,noses[nose_rand % 15],rightNose,"   )>", unicode" \n"));
    }
    else if(id == 3) {
      return string(abi.encodePacked("    \\  ",leftNose,noses[nose_rand % 15],rightNose,"  /", unicode" \n"));
    }
    else if(id == 4) {
      return string(abi.encodePacked(unicode"    ║  ",leftNose,noses[nose_rand % 15],rightNose,unicode"  ║", unicode" \n"));
    }
    else if(id == 5) {
      return string(abi.encodePacked(unicode"    (  ",leftNose,noses[nose_rand % 15],rightNose,unicode"  )", unicode" \n"));
    }
    else if(id == 6) {
      return string(abi.encodePacked(unicode"    )  ",leftNose,noses[nose_rand % 15],rightNose,unicode"   )", unicode" \n"));
    }
    else if(id == 7){
      return string(abi.encodePacked("   (/  ",leftNose,noses[nose_rand % 15],rightNose,"  \\)", unicode" \n"));
    }
    else if(id == 8) {
      return string(abi.encodePacked(unicode"  \\│   ",leftNose,noses[nose_rand % 15],rightNose,unicode"   │/", unicode" \n"));
    } 
    else if(id == 9){
      return string(abi.encodePacked("    '. /V\\ ,'", unicode" \n"));
    }
    else {
      return string(abi.encodePacked("ERROR"));
    }

  }

  
  function _chooseMouth(uint256 _rand) internal pure returns (string memory) {
   uint256 id =((_rand/1e16 )% 1e2)%10;
     uint256 mouth_rand=(_rand/1e0)%1e2;
  
    string[5] memory mouths =
      [
      unicode"---",
      unicode"___",
      unicode"===",
      unicode"~~~",
      unicode"═══"
      ];

    if(id == 0){
      return string(abi.encodePacked("     ) ",mouths[mouth_rand % 5]," (",unicode" \n",unicode"     (_____)"));
    }
    else if (id == 1){
      return string(abi.encodePacked(unicode"     ├ ",mouths[mouth_rand % 5],unicode" ┤",unicode"  \n",unicode"      \'───\'"));
    }
    else if(id == 2) {
      return string(abi.encodePacked("    \\  ",mouths[mouth_rand % 5],"  /",unicode" \n",unicode"      \\ˍˍˍ/"));
    }
    else if(id == 3){
      return string(abi.encodePacked("     { ",mouths[mouth_rand % 5]," }",unicode" \n",unicode"      └~~~┘"));
    }
    else if(id == 4){
      return string(abi.encodePacked(unicode"    ╚╗ ",mouths[mouth_rand % 5],unicode" ╔╝",unicode" \n",unicode"     ╚═════╝"));
    }
    else if(id == 5){
      return string(abi.encodePacked(unicode"     |\\",mouths[mouth_rand % 5],unicode"/|",unicode" \n",unicode"      \\_‿_/"));
    }
    else if(id == 6){
      return string(abi.encodePacked(unicode"   (   ",mouths[mouth_rand % 5],unicode"  (",unicode" \n",unicode"    `─ ─ ─ ─´"));
    }
    else if(id == 7){
      return string(abi.encodePacked(unicode"   (|  ",mouths[mouth_rand % 5],unicode"  |)",unicode" \n",unicode"     `─────´"));
    }
    else if(id == 8){
      return string(abi.encodePacked(unicode"    \\  ",mouths[mouth_rand % 5],unicode"  /",unicode" \n",unicode"      \\___/"));
    }
    else if (id == 9){
      return string(abi.encodePacked(unicode"     \\ ",mouths[mouth_rand % 5],unicode" /",unicode"  \n",unicode"      '---'"));
    }
    else {
      return string(abi.encodePacked("ERROR"));
    }
    
  }


  function _chooseGlasses(uint256 _rand,uint256 id) internal pure returns(string memory) {
   
    
    string[16] memory glasses = [
      unicode"-O---O-",
      unicode"-O-_-O-",
      unicode"-┴┴-┴┴-",
      unicode"-┬┬-┬┬-",
      unicode"-▄---▄-",
      unicode"-▄-_-▄-",
      unicode"-▀---▀-",
      unicode"-▀-_-▀-",
      unicode"-█---█-",
      unicode"-█-_-█-",
      unicode"-▓---▓-",
      unicode"-▓-_-▓-",
      unicode"-▒---▒-",
      unicode"-▒-_-▒-",
      unicode"-░---░-",
      unicode"-░-_-░-"
    ];

  string memory glass = glasses[_rand%16];

    if(id == 0) {
       return
        string(
          abi.encodePacked(
            "   d|",
            glass,
            "|b",
            unicode" \n"
          )
      );
    }
    else if(id == 1) {
      return
        string(
          abi.encodePacked(
            unicode"   «│",
            glass,
            unicode"│»",
            unicode" \n"
          )
        );
    
    }
    else if(id == 2){
       return
        string(
          abi.encodePacked(
            "    (",
            glass,
            ")",
            unicode" \n"
          )
        );
    }else if(id == 3) {
      return
        string(
          abi.encodePacked(
            "   d|",
            glass,
            "|b",
            unicode" \n"
          )
      );
    }else if(id == 4) {
      return
      string(
        abi.encodePacked(
          unicode"   d║",
          glass,
          unicode"║b",
          unicode" \n"
        )
      );
    }else if(id == 5) {
      return
      string(
        abi.encodePacked(
          unicode"   d|",
          glass,
          unicode"|b",
          unicode" \n"
        )
      );
    }else if(id == 6) {
      return
      string(
        abi.encodePacked(
          unicode"   ( ",
          glass,
          unicode"(",
          unicode" \n"
        )
      );
    }
    else if(id == 7) {
      return
        string(
          abi.encodePacked(
            unicode"  @| ",
            glass,
            unicode" |@",
            unicode" \n"
          )
        );
    }
    else if(id == 8) {
      return
      string(
        abi.encodePacked(
          unicode" |\\| ",
          glass,
          unicode" |/|",
          unicode" \n"
        )
      );
    }
    else if(id == 9) {
      return
      string(
        abi.encodePacked(
          unicode" \\  ",
          glass,
          unicode"  /",
          unicode" \n"
        )
      );
    }
    else {
      return string(abi.encodePacked("ERROR"));
    }

  } 
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 1300
  },
  "evmVersion": "byzantium",
  "libraries": {
    "/E/fiverr/April/AsciiMan/asciiman-contract/contracts/ChainBeing/chainBeingFactory.sol": {
      "chainBeingFactory": "0x07F5D1cA908d6aF373463D65f15f6c7EAd9f5041"
    }
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}