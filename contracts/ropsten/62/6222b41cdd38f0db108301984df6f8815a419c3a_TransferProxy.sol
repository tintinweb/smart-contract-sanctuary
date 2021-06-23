/**
 *Submitted for verification at Etherscan.io on 2021-06-23
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns(bool);
}

interface IERC20{
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint256);
    
    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);
    
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}


library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

abstract contract IERC721 is IERC165 {
    
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    
    // Returns the number of NFTs in 'owner''s account.
    
    function balanceOf(address owner) public view virtual returns(uint256 balance);
    
    // Returns the owner of the NFT specified by 'tokenId'.
    
    function ownerOf(uint256 tokenId) public view virtual returns(address owner);
    
    // Transfers a specific NFT('tokenId') from one account ('from') to another ('to').
    
    function safeTransferFrom(address from,address to,uint256 tokenId) public virtual;
    
    function transferFrom(address from, address to, uint256 tokenId) public virtual;
    
    // Requirements
    // If the caller is not 'from',it must be approved to move this NFT by either {approve} or setApprovalForAll}.
    
    function approve(address to,uint256 tokenId) public virtual;
    function getApproved(uint256 tokenId) public view virtual returns(address operator);
    function setApprovalForAll(address operator,bool _approved) public virtual;
    function isApprovedForAll(address owner,address operator) public view virtual returns(bool);
    
}

abstract contract IERC1155 is IERC165 {
    
        event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);
        event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);
        event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
        event URI(string _value, uint256 indexed _id);
        
        
        function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external virtual;
        function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external virtual;
        function balanceOf(address _owner, uint256 _id) external view virtual returns (uint256);
        function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view virtual returns (uint256[] memory);
        function setApprovalForAll(address _operator, bool _approved) external virtual;
        function isApprovedForAll(address _owner, address _operator) external view virtual returns (bool);
}

contract TransferProxy  {

    function erc721safeTransferFrom(IERC721 token, address from, address to, uint256 tokenId) external  {
        token.safeTransferFrom(from, to, tokenId);
    }

    function erc1155safeTransferFrom(IERC1155 token, address from, address to, uint256 id, uint256 value, bytes calldata data) external  {
        token.safeTransferFrom(from, to, id, value, data);
    }
}

contract TransferProxyForDeprecated  {

    function erc721TransferFrom(IERC721 token, address from, address to, uint256 tokenId) external  {
        token.transferFrom(from, to, tokenId);
    }
}