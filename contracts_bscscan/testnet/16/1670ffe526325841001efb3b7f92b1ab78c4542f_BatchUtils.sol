/**
 *Submitted for verification at BscScan.com on 2021-10-30
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBEP20 {
    function totalSupply() external view returns (uint);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

interface IERC165 {
  function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {

  event Transfer(
    address indexed from,
    address indexed to,
    uint indexed tokenId
  );

  event Approval(
    address indexed owner,
    address indexed approved,
    uint indexed tokenId
  );

  event ApprovalForAll(
    address indexed owner,
    address indexed operator,
    bool approved
  );

  function balanceOf(address owner) external view returns (uint balance);

  function ownerOf(uint tokenId) external view returns (address owner);

  function safeTransferFrom(
    address from,
    address to,
    uint tokenId
  ) external;

  function transferFrom(
    address from,
    address to,
    uint tokenId
  ) external;

  function approve(address to, uint tokenId) external;

  function getApproved(uint tokenId)
    external
    view
    returns (address operator);

  function setApprovalForAll(address operator, bool _approved) external;

  function isApprovedForAll(address owner, address operator)
    external
    view
    returns (bool);

  function safeTransferFrom(
    address from,
    address to,
    uint tokenId,
    bytes calldata data
  ) external;
}

interface IERC721Enumerable is IERC721 {
  function totalSupply() external view returns (uint);
  function tokenOfOwnerByIndex(address owner, uint index) external view returns (uint tokenId);
  function tokenByIndex(uint index) external view returns (uint);
}

contract BatchUtils {
    function erc721BatchOwnerOf(address nftAddress, uint[] memory ids) external view returns (address[] memory) {
        IERC721 nftContract = IERC721(nftAddress);
        address[] memory _addresses = new address[](ids.length);

        for (uint i = 0; i < ids.length; i++) {
            _addresses[i] = nftContract.ownerOf(ids[i]);
        }

        return _addresses;
    }

    function erc20BatchBalanceOf(address tokenAddress, address[] memory addresses) external view returns (uint[] memory) {
        IBEP20 tokenContract = IBEP20(tokenAddress);

        uint[] memory balances = new uint[](addresses.length);

        for (uint i = 0; i < addresses.length; i++) {
            balances[i] = tokenContract.balanceOf(addresses[i]);
        }

        return balances;
    }

    function erc721GetAllTokensOfOwner(address nftAddress, address user) external view returns (uint[] memory) {
        IERC721Enumerable nftContract = IERC721Enumerable(nftAddress);
        uint numTokens = nftContract.balanceOf(user);
        uint[] memory tokens = new uint[](numTokens);

        for (uint i = 0; i < numTokens; i++) {
            tokens[i] = nftContract.tokenOfOwnerByIndex(user, i);
        }

        return tokens;
    }
}