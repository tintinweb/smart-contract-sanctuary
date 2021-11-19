/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";
import "./Ownable.sol";
import "./AccessControl.sol";
import "./ERC1155.sol";
import "./ERC1155Burnable.sol";
import "./ERC1155Pausable.sol";


contract OwnableDelegateProxy { }

contract ProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}


contract FirstTest is Context, AccessControl, Ownable, ERC1155Burnable, ERC1155Pausable {
  bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');
  bytes32 public constant PAUSER_ROLE = keccak256('PAUSER_ROLE');
  string public BaseUri;
  
    // Contract name
  string public name;
  // Contract symbol
  string public symbol;
  
    mapping (uint256 => uint256) public tokenSupply;
  
address proxyRegistryAddress;

  /**
   * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE`, and `PAUSER_ROLE` to the account that
   * deploys the contract.
   */
  constructor(string memory _name, string memory _symbol, string memory _uri, address _proxyRegistryAddress)  ERC1155(_uri) {
      BaseUri = _uri;
      name = _name;
      symbol = _symbol;
      proxyRegistryAddress = _proxyRegistryAddress;
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setupRole(MINTER_ROLE, _msgSender());
    _setupRole(PAUSER_ROLE, _msgSender());
    
    _mint(msg.sender, 1, 256, "");
    tokenSupply[1] += 256;
    _mint(msg.sender, 2, 256, "");
    tokenSupply[2] += 256;
    _mint(msg.sender, 3, 256, "");
    tokenSupply[3] += 256;
  }

  /**
   * @dev Creates `amount` new tokens for `to`, of token type `id`.

   * See {ERC1155-_mint}.
   *
   * Requirements:
   *
   * - the caller must have the `MINTER_ROLE`.
   */
  function mint(
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) public virtual {
      require(hasRole(MINTER_ROLE, _msgSender()), 'ERC1155: must have minter role to mint');

    _mint(to, id, amount, data);
    tokenSupply[id] += amount;
  }

  /**
   * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] variant of {mint}.
   */
  function mintBatch(
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) public  {
    require(hasRole(MINTER_ROLE, _msgSender()), 'ERC1155: must have minter role to mint');
    
    _mintBatch(to, ids, amounts, data);
    
    for (uint256 i = 0; i < ids.length; i++) {
      uint256 id = ids[i];
      uint256 quantity = amounts[i];
      tokenSupply[id] += quantity;
    }
  }
  
  
  
  
  function burn(
        address account,
        uint256 id,
        uint256 value
    ) public override {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burn(account, id, value);
        tokenSupply[id] -= value;
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public override {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burnBatch(account, ids, values);
        
        for (uint256 i = 0; i < ids.length; i++) {
          uint256 id = ids[i];
          uint256 quantity = values[i];
          tokenSupply[id] -= quantity;
        }
    }
  
  
  
 
 function totalSupply(
    uint256 _id
  ) public view returns (uint256) {
    return tokenSupply[_id];
  }
  
  
//   proxyRegistryAddress = _proxyRegistryAddress;
  function isApprovedForAll(
    address _owner,
    address _operator
  ) public view override returns (bool isOperator) {
    // Whitelist OpenSea proxy contract for easy trading.
    ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
    if (address(proxyRegistry.proxies(_owner)) == _operator) {
      return true;
    }

    return ERC1155.isApprovedForAll(_owner, _operator);
  }
  
  function contractURI() public pure returns (string memory) {
        return "https://gateway.pinata.cloud/ipfs/QmNszG51ZpaeuppUzcmMsKjxv7kHUJMyPZUg4kpnaSECqE/ContractMeta.json";
    }
    
    
//     function tokenURI(uint256 tId) public view returns (string memory) {
//     return string(
//         abi.encodePacked(
//         bUri,
//         Strings.toString(tId),
//         ".json"
//         )
//     );
//   }


    function uri(uint256 tId) public view override returns (string memory) {
        return string(
            abi.encodePacked(
                BaseUri,
                Strings.toString(tId),
                ".json"
                )
            );
    }



  /**
   * @dev Pauses all token transfers.
   *
   * See {ERC1155Pausable} and {Pausable-_pause}.
   *
   * Requirements:
   *
   * - the caller must have the `PAUSER_ROLE`.
   */
  function pause() public virtual {
    require(hasRole(PAUSER_ROLE, _msgSender()), 'ERC1155: must have pauser role to pause');

    _pause();
  }

  /**
   * @dev Unpauses all token transfers.
   *
   * See {ERC1155Pausable} and {Pausable-_unpause}.
   *
   * Requirements:
   *
   * - the caller must have the `PAUSER_ROLE`.
   */
  function unpause() public virtual {
    require(hasRole(PAUSER_ROLE, _msgSender()), 'ERC1155: must have pauser role to unpause');

    _unpause();
  }

  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual override(ERC1155, ERC1155Pausable) {
    super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
  }
  
  
  function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC1155) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}