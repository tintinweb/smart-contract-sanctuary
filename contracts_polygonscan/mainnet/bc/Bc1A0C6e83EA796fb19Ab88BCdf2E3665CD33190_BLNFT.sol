// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC1155.sol";
import "./Ownable.sol";

/**
 * https://github.com/maticnetwork/pos-portal/blob/master/contracts/common/ContextMixin.sol
 */
abstract contract ContextMixin {
    function msgSender()
        internal
        view
        returns (address payable sender)
    {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = payable(msg.sender);
        }
        return sender;
    }
}

contract BLNFT is ERC1155, ContextMixin, Ownable {
    //Event to tell OpenSea that this item is frozen
    event PermanentURI(string _value, uint256 indexed _id);
    
    string public name = "BLNFT";
    
    mapping(uint256=>string) public frozenUris;
    mapping(address=>bool) public minters;

    constructor() ERC1155("http://3.64.40.5/api/token/{id}") {
       
    }
    
    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSender()
        internal
        override
        view
        returns (address sender)
    {
        return ContextMixin.msgSender();
    }
    
    
    function uri(uint256 _input) public view virtual override returns (string memory) {
        if (bytes(frozenUris[_input]).length > 0) {
            return frozenUris[_input];
        }
        return ERC1155.uri(_input);
    }
    
    /**
   * Override isApprovedForAll to auto-approve OS's proxy contract
   */
    function isApprovedForAll(
        address _owner,
        address _operator
    ) public override view returns (bool isOperator) {
        // if OpenSea's ERC1155 Proxy Address is detected, auto-return true
       if (_operator == address(0x207Fa8Df3a17D96Ca7EA4f2893fcdCb78a304101)) {
            return true;
        }
        // otherwise, use the default ERC1155.isApprovedForAll()
        return ERC1155.isApprovedForAll(_owner, _operator);
    }
    
    function freeze(string memory _value, uint256 _id) public onlyOwner {
        frozenUris[_id] = _value;
        emit PermanentURI(_value, _id);
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function setMintable(address _minter, bool _isMinter) public onlyOwner {
        minters[_minter] = _isMinter;
    }
    
    function burn(address account, uint256 id, uint256 amount) public {
        require(minters[msgSender()], "Not a minter");

        _burn(account, id, amount);
    }

    function burnBatch(address to, uint256[] memory ids, uint256[] memory amounts) public {
        require(minters[msgSender()], "Not a minter");

        _burnBatch(to, ids, amounts);
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data) public {
        require(minters[msgSender()], "Not a minter");
        
        _mint(account, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public {
        require(minters[msgSender()], "Not a minter");

        _mintBatch(to, ids, amounts, data);
    }
}