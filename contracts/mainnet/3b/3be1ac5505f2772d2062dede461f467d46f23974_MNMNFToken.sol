//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

import "./erc721-token-receiver.sol";

contract MNMNFToken
{
  mapping (uint256 => bytes32) internal _id_to_token_name;
  mapping (uint256 => uint256) internal _id_to_index;
  mapping (uint256 => uint256) internal _id_to_owner_index;
  mapping (uint256 => address) internal _id_to_owner;
  mapping (uint256 => address) internal _id_to_approval;
  mapping (uint256 => uint256) internal _id_to_value;
  mapping (address => uint256[]) internal _owner_to_ids;
  mapping (address => uint256) internal _owner_to_nftoken_count;
  mapping (address => mapping (address => bool)) internal _owner_to_operators;

  uint256[] internal _tokens;
  uint256 internal _next_token_id = 1;

  mapping (bytes32 => address) internal _token_name_to_token_contract;
  mapping (bytes32 => address) internal _token_name_to_nft_factory;

  uint256 public customPrice;

  address internal _owner;
  string public constant name = "MNM NFT";
  string public constant symbol = "MNMN";
  uint256 public constant decimals = 0;

  bytes4 internal constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;

  event Transfer(address indexed from, address indexed to, uint256 indexed token_id);
  event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
  event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

  constructor()
  {
    _owner = msg.sender;
    customPrice = 1e17;
  }

  receive() external payable {}
  fallback() external payable {}

  function supportsInterface(bytes4 id)
    external pure returns(bool)
  {
    return (
         id == 0x5b5e139f // ERC721Metadata
      || id == 0x780e9d63 // ERC721Enumerable
      || id == 0x80ac58cd // ERC721
    );
  }

  function setCustomPrice(uint256 price)
    external
  {
    _only_owner();
    customPrice = price;
  }

  function setContractOwner(address new_owner)
    external
  {
    _only_owner();
    _owner = new_owner;
  }

  function withdrawEth()
    external
  {
    _only_owner();
    (bool success,) = msg.sender.call{value:address(this).balance}("");
    require(success, 'transfer failed');
  }

  function setTokenContractAddress(bytes32 token_name, address token_contract)
    external
  {
    _only_owner();
    _token_name_to_token_contract[token_name] = token_contract;
  }

  function setImageContractAddress(bytes32 token_name, address image_contract)
    external
  {
    _only_owner();
    _token_name_to_nft_factory[token_name] = image_contract;
  }

  function safeTransferFrom(address from, address to, uint256 token_id, bytes calldata data)
    external
  {
    _safe_transfer_from(from, to, token_id, data);
  }

  function safeTransferFrom(address from, address to, uint256 token_id)
    external
  {
    _safe_transfer_from(from, to, token_id, "");
  }

  function _safe_transfer_from(address from, address to, uint256 token_id, bytes memory data)
    internal
  {
    _valid_nftoken(token_id);
    _can_transfer(token_id);
    address token_owner = _id_to_owner[token_id];
    require(token_owner == from, 'nft is not owned by from address');
    require(to != address(0), 'cannot transfer nft to address 0');

    _transfer(to, token_id);

    if (_is_contract(to))
    {
      bytes4 retval = ERC721TokenReceiver(to).onERC721Received(msg.sender, from, token_id, data);
      require(retval == MAGIC_ON_ERC721_RECEIVED, 'failed to transfer to token receiver');
    }
  }

  function transferFrom(address from, address to, uint256 token_id)
    external
  {
    _valid_nftoken(token_id);
    _can_transfer(token_id);
    address token_owner = _id_to_owner[token_id];
    require(token_owner == from, 'nft is not owned by from address');
    require(to != address(0), 'cannot transfer nft to address 0');

    _transfer(to, token_id);
  }

  function _transfer(address to, uint256 token_id)
    internal
  {
    address from = _id_to_owner[token_id];

    _remove_nftoken(from, token_id);
    _add_nftoken(to, token_id);

    emit Transfer(from, to, token_id);
  }

  function tokenURI(uint256 token_id)
    external view returns (string memory)
  {
    _valid_nftoken(token_id);
    address img_contract = _token_name_to_nft_factory[_id_to_token_name[token_id]];
    return NFTFactory(img_contract).tokenURI(token_id);
  }

  function tokenByIndex(uint256 index)
    external view returns(uint256)
  {
    require(index < _tokens.length, 'invalid nft index');
    return _tokens[index];
  }

  function tokenOfOwnerByIndex(address owner, uint256 index)
    external view returns(uint256)
  {
    require(index < _owner_to_ids[owner].length, 'invalid nft index');
    return _owner_to_ids[owner][index];
  }

  function totalSupply()
    external view returns(uint256)
  {
    return _tokens.length;
  }

  function balanceOf(address owner)
    external view returns(uint256)
  {
    require(owner != address(0), 'address 0 is not an owner');
    return _owner_to_ids[owner].length;
  }

  function ownerOf(uint256 token_id)
    external view returns(address)
  {
    _valid_nftoken(token_id);
    return _id_to_owner[token_id];
  }

  function getApproved(uint256 token_id)
    external view returns(address)
  {
    _valid_nftoken(token_id);
    return _id_to_approval[token_id];
  }

  function isApprovedForAll(address owner, address operator)
    external view returns(bool)
  {
    return _owner_to_operators[owner][operator];
  }

  function getIncludedTokenType(uint256 token_id)
    external view returns(bytes32)
  {
    _valid_nftoken(token_id);
    return _id_to_token_name[token_id];
  }

  function getIncludedTokenAmount(uint256 token_id)
    external view returns(uint256)
  {
    _valid_nftoken(token_id);
    return _id_to_value[token_id];
  }

  function mintNFTCustom(uint256 num_whole_tokens, bytes32 token_data, bytes32 token_name)
    external payable
  {
    require(msg.value >= customPrice, 'not enough eth sent');
    _mint_nft_custom(num_whole_tokens, token_data, token_name);
  }

  function mintNFTCustomBatch(uint256[] calldata num_whole_tokens, bytes32[] calldata token_data, bytes32 token_name)
    external payable
  {
    require(msg.value >= customPrice * token_data.length, 'not enough eth sent');
    require(num_whole_tokens.length == token_data.length, 'array lengths must match');
    uint256 i;
    for (i=0; i<token_data.length; i++) {
      _mint_nft_custom(num_whole_tokens[i], token_data[i], token_name);
    }
  }

  function _mint_nft_custom(uint256 num_whole_tokens, bytes32 token_data, bytes32 token_name)
    internal
  {
    require(num_whole_tokens >= 9, 'not enough tokens sent');

    uint256 token_id = _next_token_id;
    _next_token_id += 1;
    require(_id_to_owner[token_id] == address(0), 'nft already exists');

    address token_contract = _token_name_to_token_contract[token_name];
    require(token_contract != address(0), 'no token contract associated with this token name');

    address image_contract = _token_name_to_nft_factory[token_name];
    require(image_contract != address(0), 'no nft factory associated with this token name');

    address token_owner = msg.sender;

    MNMTokenA(token_contract).withdrawWhole(token_owner, num_whole_tokens);
    NFTFactory(image_contract).mintNFTCustom(token_id, token_data);

    _add_nftoken(token_owner, token_id);

    _tokens.push(token_id);
    _id_to_index[token_id] = _tokens.length - 1;

    _id_to_token_name[token_id] = token_name;

    emit Transfer(address(0), token_owner, token_id);
  }

  function mintNFT(uint256 num_whole_tokens, bytes32 token_name)
    external
  {
    _mint_nft(num_whole_tokens, token_name);
  }

  function mintNFTBatch(uint256[] calldata num_whole_tokens, bytes32 token_name)
    external
  {
    uint256 i;
    for (i=0; i<num_whole_tokens.length; i++) {
      _mint_nft(num_whole_tokens[i], token_name);
    }
  }

  function _mint_nft(uint256 num_whole_tokens, bytes32 token_name)
    internal
  {
    require(num_whole_tokens > 0, 'must send at least 1 token');

    uint256 token_id = _next_token_id;
    _next_token_id += 1;

    address token_contract = _token_name_to_token_contract[token_name];
    require(token_contract != address(0), 'no token contract associated with this token name');

    address image_contract = _token_name_to_nft_factory[token_name];
    require(image_contract != address(0), 'no nft factory associated with this token name');

    require(_id_to_owner[token_id] == address(0), 'nft already exists');

    address token_owner = msg.sender;

    MNMTokenA(token_contract).withdrawWhole(token_owner, num_whole_tokens);
    NFTFactory(image_contract).mintNFT(token_id, num_whole_tokens, uint256(uint160(token_owner)));

    _add_nftoken(token_owner, token_id);

    _tokens.push(token_id);
    _id_to_index[token_id] = _tokens.length - 1;

    _id_to_value[token_id] = num_whole_tokens;

    _id_to_token_name[token_id] = token_name;

    emit Transfer(address(0), token_owner, token_id);
  }

  function meltNFT(uint256 token_id)
    external
  {
    _valid_nftoken(token_id);
    address token_owner = _id_to_owner[token_id];
    address img_contract = _token_name_to_nft_factory[_id_to_token_name[token_id]];
    address token_contract = _token_name_to_token_contract[_id_to_token_name[token_id]];

    MNMTokenA(token_contract).depositWhole(msg.sender, _id_to_value[token_id]);
    NFTFactory(img_contract).burnNFT(token_id);

    _remove_nftoken(token_owner, token_id);

    uint256 token_index = _id_to_index[token_id];
    uint256 last_token_index = _tokens.length - 1;
    uint256 last_token = _tokens[last_token_index];
    _tokens[token_index] = last_token;
    _id_to_index[last_token] = token_index;

    _tokens.pop();
    delete _id_to_index[token_id];
    delete _id_to_token_name[token_id];
    delete _id_to_value[token_id];

    emit Transfer(token_owner, address(0), token_id);
  }

  function approve(address approved, uint256 token_id)
    external
  {
    _valid_nftoken(token_id);
    _can_operate(token_id);
    address token_owner = _id_to_owner[token_id];
    require(approved != token_owner, 'already token owner');

    _id_to_approval[token_id] = approved;

    emit Approval(token_owner, approved, token_id);
  }

  function setApprovalForAll(address operator, bool approved)
    external
  {
    _owner_to_operators[msg.sender][operator] = approved;

    emit ApprovalForAll(msg.sender, operator, approved);
  }

  function _remove_nftoken(address from, uint256 token_id)
    internal
  {
    require(_id_to_owner[token_id] == from, 'not the owner');
    delete _id_to_owner[token_id];
    delete _id_to_approval[token_id];

    _owner_to_nftoken_count[from] -= 1;

    uint256 token_to_remove_index = _id_to_owner_index[token_id];
    uint256 last_token_index = _owner_to_ids[from].length - 1;

    if (last_token_index != token_to_remove_index)
    {
      uint256 last_token = _owner_to_ids[from][last_token_index];
      _owner_to_ids[from][token_to_remove_index] = last_token;
      _id_to_owner_index[last_token] = token_to_remove_index;
    }

    _owner_to_ids[from].pop();
  }

  function _add_nftoken(address to, uint256 token_id)
    internal
  {
    require(_id_to_owner[token_id] == address(0), 'token is already owned');
    _id_to_owner[token_id] = to;

    _owner_to_ids[to].push(token_id);
    _id_to_owner_index[token_id] = _owner_to_ids[to].length - 1;

    _owner_to_nftoken_count[to] += 1;
  }

  function getTokenData(uint256 token_id)
    external view returns(bytes memory)
  {
    address img_contract = _token_name_to_nft_factory[_id_to_token_name[token_id]];
    return NFTFactory(img_contract).getTokenData(token_id);
  }

  function _is_contract(address addr)
    internal view returns(bool)
  {
    // This method relies in extcodesize, which returns 0 for contracts in
    // construction, since the code is only stored at the end of the
    // constructor execution.

    // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
    // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
    // for accounts without code, i.e. `keccak256('')`
    bytes32 account_hash;
    bytes32 code_hash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
    assembly { account_hash := extcodehash(addr) } // solhint-disable-line
    return (account_hash != 0x0 && account_hash != code_hash);
  }

  function _can_operate(uint256 token_id)
    internal view
  {
    address token_owner = _id_to_owner[token_id];
    require(
      token_owner == msg.sender || _owner_to_operators[token_owner][msg.sender],
      'not owner or authorized operator'
    );
  }

  function _can_transfer(uint256 token_id)
    internal view
  {
    address token_owner = _id_to_owner[token_id];
    require(
      token_owner == msg.sender
      || _id_to_approval[token_id] == msg.sender
      || _owner_to_operators[token_owner][msg.sender],
      'not owner or authorized approver or operator'
    );
  }

  function _valid_nftoken(uint256 token_id)
    internal view
  {
    require(_id_to_owner[token_id] != address(0), 'not a valid nft');
  }

  function _only_owner()
    internal view
  {
    require(msg.sender == _owner, 'not the contract owner');
  }
}

contract MNMTokenA
{
  function symbol() external pure returns(string memory) {}
  function depositWhole(address to, uint256 num_whole_tokens) public {}
  function withdrawWhole(address from, uint256 num_whole_tokens) public {}
}

contract NFTFactory
{
  function getTokenData(uint256 token_id) external view returns(bytes memory) {}
  function tokenURI(uint256 token_id) external view returns(string memory) {}
  function mintNFT(uint256 token_id, uint256 entropy, uint256 entropy2) external {}
  function mintNFTCustom(uint256 token_id, bytes32 token_data) external {}
  function burnNFT(uint256 token_id) external {}
}