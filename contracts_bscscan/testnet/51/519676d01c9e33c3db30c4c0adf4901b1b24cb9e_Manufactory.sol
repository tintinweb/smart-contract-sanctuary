/**
 *Submitted for verification at BscScan.com on 2021-11-04
*/

pragma solidity <=0.7.4;
// SPDX-License-Identifier: UNLICENSED
interface IBEP721Receiver {
    function onBEP721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

interface IBEP165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IBEP721 is IBEP165 {

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function name() external view returns(string memory);
    function symbol() external view returns(string memory);
    function totalSupply() external view returns(string memory);
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

contract Manufactory {

     string private _name;
     string private _symbol;
     uint256 private _totalSupply;

     struct Info {
         bytes logoURI;
         bytes name;
         bytes description;
         bytes additionalInfo;
     }

     mapping(uint256 => address) private _owners;
     mapping(address => uint256) private _balances;
     mapping(uint256 => address) private _tokenApprovals;
     mapping(address => mapping(address => bool)) private _operatorApprovals;
     mapping(uint256 => Info) private _info;

     event Approval(address indexed from, address indexed to, uint256 tokenId);
     event ApprovalForAll(address indexed owner, address indexed operator,bool approved);
     event Transfer(address indexed from, address indexed to, uint256 tokenId);
    
     modifier exists(uint256 tokenId){
        require(_owners[tokenId] != address(0),"Invalid TokenId");
        _;
     }

     constructor(string memory name_ , string memory symbol_ ){
         _name = name_;
         _symbol = symbol_;
     }

     function name() public view virtual returns(string memory){
         return _name;
     }

     function symbol() public view virtual returns(string memory){
         return _symbol;
     }

     function totalSupply() public view virtual returns(uint256){
         return _totalSupply;
     }

     function balanceOf(address owner) public view virtual returns(uint256){
         require(
             owner != address(0), "Query Error : Zero Address : 01"
         );
         return _balances[owner];
     }

     function ownerOf(uint256 tokenId) public view virtual returns(address){
         address owner = _owners[tokenId];
         require(owner != address(0),"Query Error : Zero Address : 01");
         return owner;
     }

     function tokenInfo(uint256 tokenId) public view virtual exists(tokenId) returns(string memory, string memory, string memory, string memory){
        Info storage i = _info[tokenId];
        return(
            string(i.logoURI),
            string(i.name),
            string(i.description),
            string(i.additionalInfo)
        );
     }

     function approve(address to, uint256 tokenId) public virtual{
         address owner = _owners[tokenId];
         require(to != owner, "Error : Approval to Owner : 02");
         require(
             msg.sender == owner || isApprovedForAll(owner,msg.sender),
            "Error Approval : 02"
         );
         _approve(to,tokenId);
     }

    function _approve(address to, uint256 tokenId) internal virtual{
         _tokenApprovals[tokenId] = to;
         emit Approval(ownerOf(tokenId), to, tokenId);
     }

     function getApproved(uint256 tokenId) public view virtual exists(tokenId) returns(address){
         return _tokenApprovals[tokenId];
     }

     function setApprovalForAll(address operator, bool approved) public virtual {
         require(operator != address(0),"Error : Zero Address : 01");
         _operatorApprovals[msg.sender][operator] = approved;
         emit ApprovalForAll(msg.sender, operator, approved);
     }

    function isApprovedForAll(address owner, address operator) public view virtual returns(bool){
        return _operatorApprovals[owner][operator];
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        /* solhint-disable */
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function transferFrom(address from, address to,uint256 tokenId) public virtual{
        require(
            _isApprovedOrOwner(msg.sender,tokenId),"Access Error : 03"
        );
        _transfer(from,to,tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual {
        safeTransferFrom(from,to,tokenId,"");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual{
        require(
            _isApprovedOrOwner(msg.sender,tokenId),"Access Error : No Owner : 04"
        );
        _safeTransfer(from, to, tokenId, data);
    }

    function mint(
        uint256 tokenId, 
        string memory _tLogo, 
        string memory _tName, 
        string memory _tDescription,
        string memory _additionalInfo
    ) public virtual {
        mint(tokenId,_tLogo,_tName,_tDescription,_additionalInfo,"");
    }

    function mint(
        uint256 tokenId, 
        string memory _tokenLogo, 
        string memory _tokenName, 
        string memory _tokenDescription, 
        string memory _additionalInfo,
        bytes memory _data
    ) public virtual {
        _mint(msg.sender , tokenId, _tokenName, _tokenDescription, _tokenLogo, _additionalInfo);
        require(
            _checkOnBEP721Received(address(0), msg.sender , tokenId, _data),
            "Error : Unsupported Address"
        );
    }

    function _mint(
        address to, 
        uint256 tokenId, 
        string memory nameOfToken, 
        string memory descriptionOfToken, 
        string memory logoOfToken,
        string memory additionalInfo
    ) internal virtual{
        require( to != address(0),"Error : Zero Address : 01");
        require( _owners[tokenId] == address(0), "Error, Already Minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;
        _totalSupply += 1;
        
        Info storage i = _info[tokenId];
        i.name = bytes(nameOfToken);
        i.description = bytes(descriptionOfToken);
        i.logoURI = bytes(logoOfToken);
        i.additionalInfo = bytes(additionalInfo);
        emit Transfer(address(0),to,tokenId);

    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual{
        _transfer(from,to,tokenId);
        require(_checkOnBEP721Received(from,to,tokenId,_data),"Error : Unsupported Contract");
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ownerOf(tokenId) == from, "Access Error : No Owner : 04");
        require(to != address(0),"Error : Zero Address : 01");
        _beforeTokenTransfer(from, to, tokenId);

        _approve(address(0),tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _isApprovedOrOwner(address spender,uint256 tokenId) internal view virtual exists(tokenId) returns(bool){
        address owner = ownerOf(tokenId);
        return(
            spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner,spender)
        );
    }

    function _checkOnBEP721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (isContract(to)) {
            try IBEP721Receiver(to).onBEP721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
                return retval == IBEP721Receiver(to).onBEP721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("BEP721: transfer to non BEP721Receiver implementer");
                } else {
                    /* solhint-disable */
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