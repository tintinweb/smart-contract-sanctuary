/**
 *Submitted for verification at Etherscan.io on 2022-01-18
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

library Address {
 
    function isContract(address account) internal view returns (bool) {

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
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

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) internal pure returns (bytes memory) {
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

interface IERC721Receiver {

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

interface IERC165 {

    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

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

interface IERC721Enumerable is IERC721 {

    function totalSupply() external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
    function tokenByIndex(uint256 index) external view returns (uint256);
}

interface IERC721Metadata is IERC721 {

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

abstract contract ERC165 is IERC165 {

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

abstract contract NFTOptimized is Context, ERC165, IERC721, IERC721Metadata, IERC721Enumerable {
    using Address for address;

    string private _name;
    string private _symbol;
    uint256 private burnCount;

    address[] internal _owners;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }     

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = NFTOptimized.ownerOf(tokenId);
        require(to != owner, "Approval for Owner is not necessary");
        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()), "Approve function call by non-approved caller");

        _approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "Approval for Owner is not necessary");
        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Transfer function call by non-approved caller");
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "safeTransfer function call by non-approved caller");
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "Error from ERC721Receiver check");
    }

	function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }
	function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "Error from ERC721Receiver check");
    }
	function _mint(address to, uint256 tokenId) internal virtual {
        require(!_exists(tokenId), "Token already exists");
        require(to != address(0), "Cannot mint to Null Address");
        
        _beforeTokenTransfer(address(0), to, tokenId);
        _owners.push(to);

        emit Transfer(address(0), to, tokenId);
    }

	function _burn(uint256 tokenId) internal virtual {
        address owner = NFTOptimized.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);
        _approve(address(0), tokenId);
        _owners[tokenId] = address(0);
        burnCount++;

        emit Transfer(owner, address(0), tokenId);
    }

	function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(NFTOptimized.ownerOf(tokenId) == from, "Caller does not own token");
        require(to != address(0), "Cannot transfer to Null Address");

        _beforeTokenTransfer(from, to, tokenId);
        _approve(address(0), tokenId);
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

	function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(NFTOptimized.ownerOf(tokenId), to, tokenId);
    }

	function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
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
    //Leaving this in incase anyone needs to overwrite this function for additional functionality
	function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual {}

    /**
    VIEW FUNCTIONS
     */
     
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId || interfaceId == type(IERC721Metadata).interfaceId || interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "Cannot measure balance of Null Address");
        uint count = 0;
        uint length = _owners.length;
        for(uint i = 0; i < length; i++){
          if(owner == _owners[i] ){
            count++;
          }
        }
        delete length;
        return count;
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "Checking for Owner of nonexistent tokenid");
        return owner;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "Checking for Owner of nonexistent tokenid");
        return _tokenApprovals[tokenId];
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return tokenId < _owners.length && _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "Checking for Owner of nonexistent tokenid");
        address owner = NFTOptimized.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _owners.length - burnCount;
    }

    function totalCreated() public view virtual returns (uint256) {
        return _owners.length;
    }

    function totalBurned() public view virtual returns (uint256) {
        return burnCount;
    }

    function tokensOfOwner(address owner) public view returns (uint256[] memory) {
        require(0 < NFTOptimized.balanceOf(owner), "Address owns no tokens");
        uint256 tokenCount = balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](tokenCount);

        for (uint256 i = 0; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokenIds;
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256 tokenId) {
        require(index < NFTOptimized.balanceOf(owner), "Token does not exist");
        uint count;

        for( uint i; i < _owners.length; ++i ){
            if( owner == _owners[i] ){
                if( count == index )
                    return i;
                else
                    ++count;
            }
        }
        require(false, "Token does not exist");
    }

    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < NFTOptimized.totalCreated(), "Token does not exist");
        return index;
    }

}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


/**
::::::ccclccccclloooollooodxxxxxxxxdddxxkkkkkkkkO00000000OOkkkkkkxxdddxxxxxxxdoolllooolccccccc::::::
ccccllcccccllloooollooddxxxxxxxddxxxkkkkkkkOO000000000000000OOOkkkkkkxxxxxxxxxxxddoollloollccccccc::
llcccclllooooollooddxxxxxxxxxxxxkkkkkkkOO000OOO0KKK0000KK000OOOOOOkkkkkOkkkxxxxxxxxxddoolllolllccccc
cclllooooollloodxxxxxxxxxxxkkOkkkOOO00000OkkOkOOK00kxkkkkxxkkkkkkOO0OOkkkkOOkkkxxxxxxxxxddoooloollcc
looooolllooddxxxxxxxxxkkkOOkOOO000000OkkOkkO0Oxoc,.. .';coddddxxdxkkkkOOOOkkkkOOkkxxxdxxxxxxddoollll
oooolooddxxxxxxxxxkkkkOOOOO000000OOOOOkk0Oxoc,.          .';coddddxxxxkkkkkOOOkkkkOOkkxxxddxxxxxdool
oooloxxxxxxxxxkkkkOOOO0000O000O00OkkOOxoc,.                  .';coxxdxxxxxkkkxkkOOkkkOOOkkxxddxxxxxx
oolldxxdxxkkkkkOOO000OO000O000OOOOxo:,.                          .';coxxdxkkkxkkxxkkkOkkkOOOkxddxxxx
oolldxxdxOkkkOO00OO00OOO0OOkOOxo:,.                                  .';coxxdk0K0OkxkOOOOkkkkOxdxxxx
oolldxddkOxk00O00OOOOOxxkkxl:,.                                          .';:oxkO0K0000OO00xxOxdxxxx
oolldxddkOkkO0OOOkxxkkdl:,.                                                  ..,ckKKK0KKOO0kxOxdxxxx
oocldxddkOxxkkxxxkdc:,.                                                          lkkK0KKOO0kxOxdxxxx
oollxxdxkkxxddxxkc.                                                              :dd00KKOO0kxOxdxxxx
ooloxxdxOkxxdddxk,                                                               :ddOOKKOO0kxOxdxxxx
ooloxxxxOkxxxxxxk,                                                               :ddOO00OO0kxOxdxxxx
ooldxxxxOkxkOOxxk,            ..'''.                           .',;;,.           :ddOkk0OO0kkOxdxxxx
ooldxxxxOkxkO0xxk,           'kOdodkxc.     'c.              cOOkkkko.           :ddOkk0OO0kkOkxxxxx
ooodxxdxOxkk00dxk,           :Kl   .c0d.    cXo       ::    .dWx.                :ddOkk0OO0kkOkxxxxx
olodxxdxOxkO00dxk,           :Kc    .dO.    lW0,     .OO'    lNx.                :doOkk0OO0kkOkdxxxx
olodxxdxOxkO00kkk,           ;Kk::::o0o     oWWd.    :XNl    :Xk.                :doOkk0OO0kkOkdxxxx
olldxxdxOxkO0K0KO,           ;KOcccldkkc.  .dX0O;   .xKKO'   ,KO.                :dokkk0OO0kkOxdxxxx
olldxxdxOkkOOK00k,           ;0l      ;Ok. .k0:xx.  ;0lc0l   .O0'                :dokkk0OO0kkOxdxxxx
ollxxxdxOkkOOK0Od,           ,0l       ,Oc .Ok.,k: .dO'.xO.  .xK,                :dokkx0OO0kxOxdxxxx
oclxxxdkOkkkOK0kd,           ,0o       .kl '0x. lxclOo  :Kl   dX:                :dokkxOOO0xxOxddxxx
ocoxxxdkkkOk000kd,           ,0o       :O; ,0d  .xXX0,  .kO.  lXc                :dokxxOOO0xkOxodxxx
oloxxddkkkOO00Okd,           '0x.  ..,lkc  ;0l   :OXx.   cKc  ;Kd.               :dokkOKOO0kkOxodxxx
oloxxddkkkOO0kkkd,           .lxlclool:.   ;O:   .'c;    'Ok. .d0kxdxxo.         :dokO0KOO0xkOxodxxx
lldxxdokkkOO0kxkd,                         ...            ,:.   ';cloo:.         :dokk0XOOOxxOkddxxx
lldxxddkkkO0Kxxkd,                                                               :dokO0X00OxxOkddxxx
lldxxddkxkO0Kxxxd,                                                               :dokO0X0OOxkOkddxxx
lldxxddkxkOO0kxxo,                                                               :od000XOOOxkOkddxxx
lldxxdxkxkOO0kxdo,                                                               :od0O0X0OOxkOkddxxx
loxxxdxkxkOOKkxdo,                                                              .lod00KXOOOxkOkddxxx
loxxxdxkxkO0Kkxdo,                                                          .':cdkxkK0KKOOOxkOkddxxx
loxxxdxkxOO0K00xol,..                                                   .':ldkkxxkO00000O0OxkOkddxxx
loxxxdxkkOOO000Oxxxdl:,.                                            .,:ldkkxxkOOO00000000OkkOOkddxxx
loxxxxkkkO00O0000Okkxxxxdoloc'.                                 .':ldkkxxkOOO000000000OOkkOOOkxddxxx
loxxxdxOkkkkO0000000OOkkk000Okdc;'.                         .,:ldkkxxxkOO00000000OOOOOOOOkkxxddxxxxd
llodxddxxkOkkkkkO00000000Okkkkxxxxoc;'.                 .,:ldkkxxkkkO00000000OkkkkOOOkkxxxdxxxxxdool
oollodxxxxxxkOkkxkkO0000000KKK0Okkddddoc:,.         .,:ldkkxdkOOO00000000OkkkkkOOkkxxddxxxxxddoolloo
lloooloodxxxxxxkkkkxkkO000000000000Okxddxxol:,..,:cldkkxdxkOO00000000OkkkkkOOkkxxddxxxxxdddoollooooo
ccllloooooddxxxxxxkkOkkkkO0000000000000OOOOO0KOOOOkxdxkkO0000O000OkkkkkOOkkxxxdxxxxxxddoooloooooollc
lccccllooolooddxxxxxxxkOkkkkkkkkOO00O000KKKKKKK00OOOO000000000OkkkkOOOkxxddxxxxxxddoooloooooollccccc
ccclccccloooolloodxxxxdxxkOOOOOOkkkkO00OO0000KKKKKK0000000OkkkkkOOkxxxddxxxxxddoolloooooollcccccccll
:::clllccclloooolloodxxxxxxxkkkkkOOkkkkOO00O0000000000OOkkkkOOkxxxxxxxxxxxdoollloooooollccccclclllll
:::::ccllccccllooollloddxxxxxxxxxxkkOOkkkkOO00000OOOkkkkOOkxxxddxxxxxxdooolloooooollccccccllcllllcc:
;:::;::cccllcccllooooolloddxxxxxxxxxxxkkOOkkkOOOkkkkOOkxxxddxxxxxxddoolllooooolllcccclllcclllccc::::
',;;::::::ccllcccclloooooloooddxxxxxxxxxxkkOOOOOOkkkxxddxxxxxxxdoolllooooolllccccclccllllccc::::::::
''',;;::::::cclccccccllllooollloodxxxxxxxxxxxkxxxdddxxxxxxxdoollloooooollcccccllcllcclcc::::::::::;;
''''',;:::::::cccllcccccccooooolllodxxxxxxxxxdddxxxxxxxxxdolllooooooolccccccclllllllcc:;::::::::;,,'

    Ultraminers are synthesized from the burning of two BMCs. They are hand drawn rare and unique artworks inspired by Bitcoin miners (AntminerS19j ASIC Pro). 

*/

interface IBMC {
    function burn(uint256 tokenId) external;
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
    function ownerOf(uint256 tokenId) external view returns (address);
}

contract Ultraminers is NFTOptimized, Ownable {
  using Strings for uint256;
  bool private synthesizerState = false;

  string public baseURI;
  address public umContract;
  IBMC public bmc;

  constructor(string memory _name, string memory _symbol, IBMC _bmc) NFTOptimized(_name, _symbol) {
    baseURI = "ipfs://QmVGRm43vSXRyzRRM3C8j3rvLDabuxS3nT6V5ftMjXPpL3/";
    bmc = _bmc;
    umContract = address(this);
  }

  modifier nonContract() {
    require(tx.origin == msg.sender, "No Smart Contracts allowed");
    _;
  }

  function synthesizeUltraminer(uint256 firstbmc, uint256 secondbmc) external nonContract{
    require(synthesizerState, "The Synthesizer is not active currently.");
    address caller = _msgSender();
    require(bmc.isApprovedForAll(caller, umContract), "Synthesizer is not approved to burn your NFTs.");
    require(bmc.ownerOf(firstbmc) == caller && bmc.ownerOf(secondbmc) == caller, "Synthesizer Caller is not Owner.");
    uint256 supply = totalCreated();
 
    bmc.burn(firstbmc);
    bmc.burn(secondbmc);

    _safeMint(caller, supply, "");

  }

  function synthesizeManyUltraminers(uint256[] memory bmcs) external nonContract{
    require(synthesizerState, "The Synthesizer is not active currently.");
    require(bmcs.length % 2 == 0, "Uneven number of BMCs inputted.");
    address caller = _msgSender();
    require(bmc.isApprovedForAll(caller, umContract), "Synthesizer is not approved to burn your NFTs.");
    uint256 supply = totalCreated();

    for (uint256 i = 0; i < bmcs.length; i += 2) {

        uint256 firstbmc = bmcs[i];
        uint256 secondbmc = bmcs[i + 1];
        require(bmc.ownerOf(firstbmc) == caller && bmc.ownerOf(secondbmc) == caller, "Synthesizer Caller is not Owner.");

        bmc.burn(firstbmc);
        bmc.burn(secondbmc);

        _safeMint(caller, supply + i/2, "");
    }

  }

  function setBaseURI(string memory _newBaseURI) external onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBmcContract(IBMC _newBmcContract) external onlyOwner {
    bmc = _newBmcContract;
  }

  function setSynthesizerState(bool _state) external onlyOwner {
        synthesizerState = _state;
  }

  function burn(uint256 tokenId) public {
    require(_isApprovedOrOwner(_msgSender(), tokenId));
    _burn(tokenId);
  }

   /**
    VIEW FUNCTIONS
   */

  function _baseURI() internal view virtual returns (string memory) {
	return baseURI;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
	require(_exists(tokenId), "Token does not exist");

	string memory currentBaseURI = _baseURI();
	return bytes(currentBaseURI).length > 0	? string(abi.encodePacked(currentBaseURI, tokenId.toString())) : "";
  }

  function getSynthesizerState() public view returns (bool){
        return synthesizerState;
  }

  function getBmcApprovalStatus(address _address) public view returns (bool){
        return bmc.isApprovedForAll(_address, umContract);
  }

  function isApprovedForAll(address _owner, address _operator) public override view returns (bool isOperator) {
        if (_operator == address(0xa5409ec958C83C3f309868babACA7c86DCB077c1)) {     // OpenSea Address
            return true;
        }
        
        return NFTOptimized.isApprovedForAll(_owner, _operator);
  }

}