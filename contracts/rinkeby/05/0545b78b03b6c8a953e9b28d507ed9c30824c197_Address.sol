/**
 *Submitted for verification at Etherscan.io on 2021-09-04
*/

/*
 .----------------.  .----------------.  .----------------.  .----------------.  .-----------------. .----------------.  .----------------. 
| .--------------. || .--------------. || .--------------. || .--------------. || .--------------. || .--------------. || .--------------. |
| |  ________    | || |     ____     | || |     ____     | || |   _____      | || | ____  _____  | || |     _____    | || |   ________   | |
| | |_   ___ `.  | || |   .'    `.   | || |   .'    `.   | || |  |_   _|     | || ||_   \|_   _| | || |    |_   _|   | || |  |  __   _|  | |
| |   | |   `. \ | || |  /  .--.  \  | || |  /  .--.  \  | || |    | |       | || |  |   \ | |   | || |      | |     | || |  |_/  / /    | |
| |   | |    | | | || |  | |    | |  | || |  | |    | |  | || |    | |   _   | || |  | |\ \| |   | || |      | |     | || |     .'.' _   | |
| |  _| |___.' / | || |  \  `--'  /  | || |  \  `--'  /  | || |   _| |__/ |  | || | _| |_\   |_  | || |     _| |_    | || |   _/ /__/ |  | |
| | |________.'  | || |   `.____.'   | || |   `.____.'   | || |  |________|  | || ||_____|\____| | || |    |_____|   | || |  |________|  | |
| |              | || |              | || |              | || |              | || |              | || |              | || |              | |
| '--------------' || '--------------' || '--------------' || '--------------' || '--------------' || '--------------' || '--------------' |
 '----------------'  '----------------'  '----------------'  '----------------'  '----------------'  '----------------'  '----------------' */

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

//============================================================
interface IERC165 
{
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
//============================================================
interface IERC721 is IERC165 
{
    event   Transfer(      address indexed from,  address indexed to,       uint256  indexed tokenId);
    event   Approval(      address indexed owner, address indexed approved, uint256  indexed tokenId);
    event   ApprovalForAll(address indexed owner, address indexed operator, bool             approved);

    function balanceOf(        address owner)                                   external view returns (uint256 balance);
    function ownerOf(          uint256 tokenId)                                 external view returns (address owner);
    function safeTransferFrom( address from,     address to, uint256 tokenId)   external;
    function transferFrom(     address from,     address to, uint256 tokenId)   external;
    function approve(          address to,       uint256 tokenId)               external;
    function getApproved(      uint256 tokenId)                                 external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved)                external;
    function isApprovedForAll( address owner,    address operator)              external view returns (bool);
    function safeTransferFrom( address from,     address to, uint256 tokenId, bytes calldata data) external;
}
//============================================================
interface IERC721Metadata is IERC721 
{
    function name()                     external view returns (string memory);
    function symbol()                   external view returns (string memory);
    function tokenURI(uint256 tokenId)  external view returns (string memory);
}
//============================================================
interface IERC721Enumerable is IERC721 
{
    function totalSupply()                                      external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index)  external view returns (uint256 tokenId);
    function tokenByIndex(uint256 index)                        external view returns (uint256);
}
//============================================================
interface IERC721Receiver 
{
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}
//============================================================
abstract contract ERC165 is IERC165 
{
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) 
    {
        return (interfaceId == type(IERC165).interfaceId);
    }
}
//============================================================
abstract contract Context 
{
    function _msgSender() internal view virtual returns (address) 
    {
        return msg.sender;
    }
    //--------------------------------------------------------
    function _msgData() internal view virtual returns (bytes calldata) 
    {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
//============================================================
library Strings 
{
    bytes16 private constant alphabet = "0123456789abcdef";

    //--------------------------------------------------------
    function toString(uint256 value) internal pure returns (string memory) 
    {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value==0)       return "0";
    
        uint256 temp = value;
        uint256 digits;
    
        while (temp!=0) 
        {
            digits++;
            temp /= 10;
        }
        
        bytes memory buffer = new bytes(digits);
        
        while (value != 0) 
        {
            digits        -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value         /= 10;
        }
        
        return string(buffer);
    }
    //--------------------------------------------------------
    function toHexString(uint256 value) internal pure returns (string memory) 
    {
        if (value==0)       return "0x00";
        
        uint256 temp   = value;
        uint256 length = 0;
        
        while (temp != 0) 
        {
            length++;
            temp >>= 8;
        }
        
        return toHexString(value, length);
    }
    //--------------------------------------------------------
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) 
    {
        bytes memory buffer = new bytes(2 * length + 2);
        
        buffer[0] = "0";
        buffer[1] = "x";
        
        for (uint256 i=2*length+1; i>1; --i) 
        {
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}
//============================================================
library Address 
{
    function isContract(address account) internal view returns (bool) 
    {
        uint256 size;
        
        assembly { size := extcodesize(account) }   // solhint-disable-next-line no-inline-assembly
        return size > 0;
    }
    //--------------------------------------------------------
    function sendValue(address payable recipient, uint256 amount) internal 
    {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{ value: amount }(""); // solhint-disable-next-line avoid-low-level-calls, avoid-call-value

        require(success, "Address: unable to send value, recipient may have reverted");
    }
    //--------------------------------------------------------
    function functionCall(address target, bytes memory data) internal returns (bytes memory) 
    {
        return functionCall(target, data, "Address: low-level call failed");
    }
    //--------------------------------------------------------
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) 
    {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    //--------------------------------------------------------
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) 
    {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
    //--------------------------------------------------------
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) 
    {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target),             "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{ value: value }(data);    // solhint-disable-next-line avoid-low-level-calls

        return _verifyCallResult(success, returndata, errorMessage);
    }
    //--------------------------------------------------------
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) 
    {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    //--------------------------------------------------------
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) 
    {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);  // solhint-disable-next-line avoid-low-level-calls

        return _verifyCallResult(success, returndata, errorMessage);
    }
    //--------------------------------------------------------
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) 
    {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
    //--------------------------------------------------------
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) 
    {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);    // solhint-disable-next-line avoid-low-level-calls
        
        return _verifyCallResult(success, returndata, errorMessage);
    }
    //--------------------------------------------------------
    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) 
    {
        if (success) 
        {
            return returndata;
        } 
        else 
        {
            if (returndata.length > 0)      // Look for revert reason and bubble it up if present
            {
                // The easiest way to bubble the revert reason is using memory via assembly
                // solhint-disable-next-line no-inline-assembly
                assembly 
                {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } 
            else 
            {
                revert(errorMessage);
            }
        }
    }
}
//============================================================
abstract contract Ownable is Context 
{
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    //--------------------------------------------------------
    constructor () 
    {
        address msgSender = _msgSender();
                   _owner = msgSender;
                   
        emit OwnershipTransferred(address(0), msgSender);
    }
    //--------------------------------------------------------
    function owner() public view virtual returns (address) 
    {
        return _owner;
    }
    //--------------------------------------------------------
    modifier onlyOwner() 
    {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    //--------------------------------------------------------
    function renounceOwnership() public virtual onlyOwner 
    {
        emit OwnershipTransferred(_owner, address(0));
        
        _owner = address(0);
    }
    //--------------------------------------------------------
    function transferOwnership(address newOwner) public virtual onlyOwner 
    {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        
        emit OwnershipTransferred(_owner, newOwner);
        
        _owner = newOwner;
    }
}
//============================================================
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata, Ownable 
{
    using Address for address;
    using Strings for uint256;

    string private _name;   // Token name
    string private _symbol; // Token symbol

    mapping(uint256 => address)                  internal _owners;              // Mapping from token ID to owner address
    mapping(address => uint256)                  internal _balances;            // Mapping owner address to token count
    mapping(uint256 => address)                  private  _tokenApprovals;      // Mapping from token ID to approved address
    mapping(address => mapping(address => bool)) private  _operatorApprovals;   // Mapping from owner to operator approvals

    //--------------------------------------------------------
    constructor(string memory name_, string memory symbol_) 
    {
        _name   = name_;
        _symbol = symbol_;
    }
    //--------------------------------------------------------
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool)
    {
        return  interfaceId == type(IERC721).interfaceId         ||
                interfaceId == type(IERC721Metadata).interfaceId ||
                super.supportsInterface(interfaceId);
    }
    //--------------------------------------------------------
    function balanceOf(address owner) public view virtual override returns (uint256)
    {
        require(owner != address(0), "ERC721: balance query for the zero address");
        
        return _balances[owner];
    }
    //--------------------------------------------------------
    function ownerOf(uint256 tokenId) public view virtual override returns (address)
    {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }
    //--------------------------------------------------------
    function name() public view virtual override returns (string memory) 
    {
        return _name;
    }
    //--------------------------------------------------------
    function symbol() public view virtual override returns (string memory) 
    {
        return _symbol;
    }
    //--------------------------------------------------------
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        
        return (bytes(baseURI).length>0) ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }
    //--------------------------------------------------------
    function _baseURI() internal view virtual returns (string memory) 
    {
        return "";
    }
    //--------------------------------------------------------
    function approve(address to, uint256 tokenId) public virtual override 
    {
        address owner = ERC721.ownerOf(tokenId);
    
        require(to!=owner, "ERC721: approval to current owner");
        require(_msgSender()==owner || ERC721.isApprovedForAll(owner, _msgSender()), "ERC721: approve caller is not owner nor approved for all");

        _approve(to, tokenId);
    }
    //--------------------------------------------------------
    function getApproved(uint256 tokenId) public view virtual override returns (address)
    {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }
    //--------------------------------------------------------
    function setApprovalForAll(address operator, bool approved) public virtual override
    {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
    
        emit ApprovalForAll(_msgSender(), operator, approved);
    }
    //--------------------------------------------------------
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }
    //--------------------------------------------------------
    function transferFrom(address from, address to, uint256 tokenId) public virtual override 
    {
        //----- solhint-disable-next-line max-line-length
        
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }
    //--------------------------------------------------------
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override 
    {
        safeTransferFrom(from, to, tokenId, "");
    }
    //--------------------------------------------------------
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override 
    {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        
        _safeTransfer(from, to, tokenId, _data);
    }
    //--------------------------------------------------------
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual 
    {
        _transfer(from, to, tokenId);
    
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }
    //--------------------------------------------------------
    function _exists(uint256 tokenId) internal view virtual returns (bool) 
    {
        return _owners[tokenId] != address(0);
    }
    //--------------------------------------------------------
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool)
    {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        
        address owner = ERC721.ownerOf(tokenId);
        
        return (spender == owner || getApproved(tokenId) == spender || ERC721.isApprovedForAll(owner, spender));
    }
    //--------------------------------------------------------
    function _safeMint(address to, uint256 tokenId) internal virtual 
    {
        _safeMint(to, tokenId, "");
    }
    //--------------------------------------------------------
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual 
    {
        _mint(to, tokenId);
    
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }
    //--------------------------------------------------------
    function _mint(address to, uint256 tokenId) internal virtual 
    {
        require(to != address(0),  "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to]   += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }
    //--------------------------------------------------------
    function _batchMint(address to, uint256[] memory tokenIds) internal virtual
    {
        require(to != address(0), "ERC721: mint to the zero address");
        
        _balances[to] += tokenIds.length;

        for (uint256 i; i < tokenIds.length; i++) 
        {
            require(!_exists(tokenIds[i]), "ERC721: token already minted");

            _beforeTokenTransfer(address(0), to, tokenIds[i]);

            _owners[tokenIds[i]] = to;

            emit Transfer(address(0), to, tokenIds[i]);
        }
    }
    //--------------------------------------------------------
    function _burn(uint256 tokenId) internal virtual 
    {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        _approve(address(0), tokenId);      // Clear approvals

        _balances[owner] -= 1;

        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }
    //--------------------------------------------------------
    function _transfer(address from, address to, uint256 tokenId) internal virtual 
    {
        require(ERC721.ownerOf(tokenId)==from,  "ERC721: transfer of token that is not own");
        require(to != address(0),               "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        _approve(address(0), tokenId);      // Clear approvals from the previous owner

        _balances[from] -= 1;
        _balances[to]   += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }
    //--------------------------------------------------------
    function _approve(address to, uint256 tokenId) internal virtual 
    {
        _tokenApprovals[tokenId] = to;
    
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }
    //--------------------------------------------------------
    function _checkOnERC721Received(address from,address to,uint256 tokenId,bytes memory _data) private returns (bool) 
    {
        if (to.isContract()) 
        {
            try
            
                IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data)
            
            returns (bytes4 retval) 
            {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } 
            catch (bytes memory reason) 
            {
                if (reason.length==0) 
                {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } 
                else 
                {
                    assembly { revert(add(32, reason), mload(reason)) }     //// solhint-disable-next-line no-inline-assembly
                }
            }
        } 
        else 
        {
            return true;
        }
    }
    //--------------------------------------------------------
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual 
    {
        //
    }
}

/***
 *     ___ ___  ____ ____ ____          __  ___  ____  ______ ____   ____    __ ______ 
 *    |   |   |/    |    |    \        /  ]/   \|    \|      |    \ /    |  /  |      |
 *    | _   _ |  o  ||  ||  _  |      /  /|     |  _  |      |  D  |  o  | /  /|      |
 *    |  \_/  |     ||  ||  |  |     /  / |  O  |  |  |_|  |_|    /|     |/  / |_|  |_|
 *    |   |   |  _  ||  ||  |  |    /   \_|     |  |  | |  | |    \|  _  /   \_  |  |  
 *    |   |   |  |  ||  ||  |  |    \     |     |  |  | |  | |  .  |  |  \     | |  |  
 *    |___|___|__|__|____|__|__|     \____|\___/|__|__| |__| |__|\_|__|__|\____| |__|  
 *                                                                                     
 */ 
contract TheDoolniz     is ERC721 
{
    modifier callerIsUser() 
    {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    struct TPartners    
    { 
        address walletAddress;
        uint256 cut;                // a share amount from >0 t 100 (+ add 00 for exact value)
    }
    
    uint256 private     presalesDate = 0;
    uint256 private     salesDate    = 0;

    uint256 private     presalesPrice = 0.04 ether;
    uint256 private     salesPrice    = 0.07 ether;

    uint256 private     presalesMaxCount  = 400;
    uint256 private     presalesSoldCount = 0;

    uint256 private     totalTokens        = 10000;
    uint256 private     totalMintedTokens  = 0;
    uint256 private     maxClaimsPerWallet = 50;
    
    string private      baseURI = "https://ipfs.io/ipfs/QmRPGJWkqdF9hhqrNjwGW7tuFHduSrtoeDA2PtnU65HYjX/";

/*
    uint256 private startClaimDate = 1629990000; //26th August 2021 3PM UTC
    uint256 private claimPrice =  0.08 ether;
    uint256 private totalTokens = 10000;
    uint256 private totalMintedTokens = 0;
    uint256 private maxClaimsPerWallet = 50;
    uint128 private basisPoints = 10000;
    uint128 private resDjens = 240; //total reserved token for rewards and wages
    uint256 private totalReserved = 0;
    string private baseURI = "https://ipfs.io/ipfs/QmRPGJWkqdF9hhqrNjwGW7tuFHduSrtoeDA2PtnU65HYjX/";
*/

    mapping(address => uint256) private claimedTokensPerWallet;

    uint16[]                        availableTokens;
    TPartners[] private             partners;                   // ERI / JEA / ELI
    uint16[]    private             tokenIdsMap;

    //-------------------------------------------------------------------
    constructor() ERC721("The Adorably Dangerous DOOLNIZ", "DOOLNIZ") 
    {
        totalTokens = 10000;
        
        //ERC721._name   = "The Adorably Dangerous DOOLNIZ";
        //ERC721._symbol = "DOOLNIZ";
        
        //forgeIdsMap(totalTokens);
    }
    //-------------------------------------------------------------------
    function    forgeIdsMap(uint256 totalCount) private
    {/*
        uint256      i;        
        uint256      j;
        uint256      k;
        uint256      v;

        for(i=0; i<totalCount; i++)
        {
            tokenIdsMap[i] = uint16(i+1);
        }
        
        for(i=0; i<totalCount; i++)
        {
            j =          _getRandomNumber(totalCount);
            k = (j + 1 + _getRandomNumber(totalCount-1)) % totalCount;
            
            v              = tokenIdsMap[j];
            tokenIdsMap[j] = tokenIdsMap[k];
            tokenIdsMap[k] = uint16(v);
        }*/
    }
    //-------------------------------------------------------------------
    function    getTokenIndex(uint16 idx) external view returns(uint256)
    {
        return uint256(tokenIdsMap[idx]);
    }
    //-------------------------------------------------------------------  Sets the collaborators of the project with their cuts
    function    setPartners(TPartners[] memory partnerList) external onlyOwner
    {
        require(partners.length==0, "Partners already set");

        uint128 totalCut;
        uint256 i;
        uint256 n;
        
        n = partnerList.length;
        
        for (i=0; i<n; i++) 
        {
            totalCut += uint128(partnerList[i].cut);
        }

        require(totalCut==10000, "Total cut does not add to 100%");

        for (i=0; i<n; i++)        // no problem, on ajout
        {
            partners.push(partnerList[i]);
        }
    }
    //-------------------------------------------------------------------
    function withdraw() external onlyOwner 
    {
        uint256 totalBalance = address(this).balance;

        for (uint256 i; i < partners.length; i++) 
        {
            payable(partners[i].walletAddress).transfer(mulScale(totalBalance, partners[i].cut, 10000));
        }
    }
    //-------------------------------------------------------------------
    function setBaseTokenURI(string memory newUri) external onlyOwner 
    {
        baseURI = newUri;
    }
    //-------------------------------------------------------------------
    function setPresalesPrice(uint256 newPresalesPrice) external onlyOwner 
    {
        salesPrice = newPresalesPrice;
    }
    //-------------------------------------------------------------------
    function setSalesPrice(uint256 newSalesPrice) external onlyOwner 
    {
        salesPrice = newSalesPrice;
    }
    //-------------------------------------------------------------------
    function addAvailableTokens(uint16 from, uint16 to) external onlyOwner
    {
        for (uint16 i = from; i <= to; i++) 
        {
            availableTokens.push(i);
        }
    }
    //-------------------------------------------------------------------
    function setPresalesDate(uint256 newPresalesDate) external onlyOwner
    {
        presalesDate = newPresalesDate;
    }
    //-------------------------------------------------------------------
    function setSalesDate(uint256 newSalesDate) external onlyOwner
    {
        salesDate = newSalesDate;
    }
    //-------------------------------------------------------------------
    function reserveDjens() external onlyOwner 
    {/*
        require(availableTokens.length>=80, "No tokens left to reserve");
        require(totalReserved<resDjens,     "240 DJens have been already reserved, you can not reserve more");
        
        uint256[] memory tokenIds = new uint256[](80);

        totalMintedTokens += 80;
		totalReserved     += 80;

        for (uint256 i; i < 80; i++) 
        {
            tokenIds[i] = getTokenToBeClaimed();
        }
        
        _batchMint(msg.sender, tokenIds);*/
    }
    //-------------------------------------------------------------------
    function claimToken() external payable callerIsUser 
    {
        if (block.timestamp>=salesDate)
        {
            require(salesDate!=0 && salesDate<=block.timestamp, "Sales did not start yet");
            require(msg.value>=salesPrice,                      "Not enough Ether to claim a token");
        }
        else if (block.timestamp>=presalesDate)
        {
            require(presalesDate!=0 && presalesDate<=block.timestamp, "Presales did not start yet");
            require(msg.value>=presalesPrice,                         "Not enough Ether to claim a token");
        }

        //------
        
        require(claimedTokensPerWallet[msg.sender]<maxClaimsPerWallet, "You cannot claim more tokens");

        require(availableTokens.length>0, "No tokens left to be claimed");

        claimedTokensPerWallet[msg.sender]++;
        totalMintedTokens++;

        _mint(msg.sender, getTokenToBeClaimed());
    }
    //-------------------------------------------------------------------
    function claimTokens(uint256 qty) external payable callerIsUser //claimStarted
    {
        if (block.timestamp>=salesDate)
        {
            require(salesDate!=0 && salesDate<=block.timestamp, "Sales did not start yet");
            require(msg.value>=salesPrice*qty,               "Not enough Ether to claim a token");
        }
        else if (block.timestamp>=presalesDate)
        {
            require(presalesDate!=0 && presalesDate<=block.timestamp, "Presales did not start yet");
            require(msg.value>=presalesPrice*qty,                  "Not enough Ether to claim a token");
        }
        
        //-----

        require((claimedTokensPerWallet[msg.sender]+qty)<=maxClaimsPerWallet, "You cannot claim more tokens");
        require(availableTokens.length>=qty,                                  "No tokens left to be claimed");

        uint256[] memory tokenIds = new uint256[](qty);

        claimedTokensPerWallet[msg.sender] += qty;
        totalMintedTokens                  += qty;

        for (uint256 i=0; i<qty; i++) 
        {
            tokenIds[i] = getTokenToBeClaimed();
        }

        _batchMint(msg.sender, tokenIds);
    }
    //-------------------------------------------------------------------
    function tokenByIndex(uint256 tokenId) external view returns (uint256) 
    {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );

        return tokenId;
    }
    //-------------------------------------------------------------------
    function baseTokenURI() external view returns (string memory) 
    {
        return baseURI;
    }
    //-------------------------------------------------------------------
    function getAvailableTokens() external view returns (uint256) 
    {
        return availableTokens.length;
    }
    //-------------------------------------------------------------------
    function getpresalesPrice() external view returns (uint256) 
    {
        return presalesPrice;
    }
    //-------------------------------------------------------------------
    function getsalesPrice() external view returns (uint256) 
    {
        return salesPrice;
    }
    //-------------------------------------------------------------------
    function totalSupply() external view virtual returns (uint256) 
    {
        return totalMintedTokens;
    }
    //-------------------------------------------------------------------
    function getTokenToBeClaimed() private returns (uint256) 
    {
        uint256 random  = _getRandomNumber(availableTokens.length);
        uint256 tokenId = uint256(availableTokens[random]);

        availableTokens[random] = availableTokens[availableTokens.length - 1];
        availableTokens.pop();

        return tokenId;
    }
    //-------------------------------------------------------------------
    function _getRandomNumber(uint256 _upper) private view returns (uint256) 
    {
        uint256 random = uint256
        (
            keccak256(abi.encodePacked
            (
                availableTokens.length,
                blockhash(block.number - 1),
                block.coinbase,
                block.difficulty,
                msg.sender
            )
        ));

        return random % _upper;
    }
    //-------------------------------------------------------------------
    function _baseURI() internal view virtual override returns (string memory) 
    {
        return baseURI;
    }
    //-------------------------------------------------------------------
    function mulScale(uint256 x, uint256 y, uint128 scale) internal pure returns (uint256) 
    {
        uint256 a = x / scale;
        uint256 b = x % scale;
        uint256 c = y / scale;
        uint256 d = y % scale;

        return a * c * scale + a * d + b * c + (b * d) / scale;
    }
}