// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/presets/ERC1155PresetMinterPauser.sol)

pragma solidity ^0.8.0;

import "./ERC1155Pausable.sol";
import "./AccessControlEnumerable.sol";
import "./MetaTransaction.sol";

contract CloudERC1155CreaturePolygon is AccessControlEnumerable, ERC1155Pausable, ContextMixin, NativeMetaTransaction {
    
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    
    // Contract name
    string public name;

    constructor (string memory _name, address _owner, string memory _uri) ERC1155(_uri) {
        name = _name;
        _initializeEIP712(name);

        _setupRole(DEFAULT_ADMIN_ROLE, _owner);
        _setupRole(MINTER_ROLE, _owner);
        _setupRole(PAUSER_ROLE, _owner);
    }

    function _msgSender() internal override view returns (address sender) {
        return ContextMixin.msgSender();
    }

    function isApprovedForAll(
        address _owner,
        address _operator
    ) public override view returns (bool isOperator) {
        return ERC1155.isApprovedForAll(_owner, _operator);
    }

    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC1155PresetMinterPauser: must have minter role to mint");

        _mint(to, id, amount, data);
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC1155PresetMinterPauser: must have minter role to mint");

        _mintBatch(to, ids, amounts, data);
    }

    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC1155PresetMinterPauser: must have pauser role to pause");
        _pause();
    }

    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC1155PresetMinterPauser: must have pauser role to unpause");
        _unpause();
    }

    function supportsInterface(bytes4 interfaceId) public view virtual 
        override(AccessControlEnumerable, ERC1155) returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}