// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity >=0.6.0;

import { Address } from "Address.sol";
import { ERC20 } from "ERC20.sol";
import { IERC1155 } from "IERC1155.sol";
import { ERC1155Receiver } from "ERC1155Receiver.sol";

contract Wrapped1155Metadata {
    // workaround which also arranges first storage slots of Wrapped1155
    Wrapped1155Factory public factory;
    IERC1155 public multiToken;
    uint256 public tokenId;

    modifier onlyFactory() {
        require(msg.sender == address(factory), "Wrapped1155: only factory allowed to perform operation");
        _;
    }
}

contract Wrapped1155 is Wrapped1155Metadata, ERC20 {
    constructor() public ERC20("Wrapped ERC-1155 Implementation", "WMT*") {}

    function mint(address account, uint256 amount) external onlyFactory {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external onlyFactory {
        _burn(account, amount);
    }
}

contract Wrapped1155Factory is ERC1155Receiver {
    using Address for address;

    Wrapped1155 public erc20Implementation;

    constructor() public {
        erc20Implementation = new Wrapped1155();
    }

    function onERC1155Received(
        address operator,
        address /* from */,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        override
        returns (bytes4)
    {
        address recipient = data.length > 0 ?
            abi.decode(data, (address)) :
            operator;

        Wrapped1155 wrapped1155 = requireWrapped1155(IERC1155(msg.sender), id);
        wrapped1155.mint(recipient, value);

        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address /* from */,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        override
        returns (bytes4)
    {
        address recipient = data.length > 0 ?
            abi.decode(data, (address)) :
            operator;

        for (uint i = 0; i < ids.length; i++) {
            requireWrapped1155(IERC1155(msg.sender), ids[i]).mint(recipient, values[i]);
        }

        return this.onERC1155BatchReceived.selector;
    }

    function unwrap(
        IERC1155 multiToken,
        uint256 tokenId,
        uint256 amount,
        address recipient,
        bytes calldata data
    )
        external
    {
        getWrapped1155(multiToken, tokenId).burn(msg.sender, amount);
        multiToken.safeTransferFrom(address(this), recipient, tokenId, amount, data);
    }

    function batchUnwrap(
        IERC1155 multiToken,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        address recipient,
        bytes calldata data
    )
        external
    {
        require(tokenIds.length == amounts.length, "Wrapped1155Factory: mismatched input arrays");
        for (uint i = 0; i < tokenIds.length; i++) {
            getWrapped1155(multiToken, tokenIds[i]).burn(msg.sender, amounts[i]);
        }
        multiToken.safeBatchTransferFrom(address(this), recipient, tokenIds, amounts, data);
    }

    function getWrapped1155DeployBytecode(IERC1155 multiToken, uint256 tokenId)
        public
        view
        returns (bytes memory)
    {
        return abi.encodePacked(
            // assign factory
            hex"73",
            this,
            hex"3d55",

            // assign multiToken
            hex"73",
            multiToken,
            hex"602055",

            // assign tokenId
            hex"7f",
            tokenId,
            hex"604055",

            // assign name
            hex"7f",
            "Wrapped ERC-1155", uint128(32),
            hex"60c055",

            // assign symbol
            hex"7f",
            "WMT", uint232(6),
            hex"60e055",

            // assign decimals
            hex"60",
            uint8(18),
            hex"61010055",

            // push 44 (length of runtime)
            hex"60", uint8(44),
            // load free memory pointer
            hex"604051",

            // dup runtime length
            hex"81",
            // push offset in this calldata to runtime object,
            hex"60", uint8(172),
            // dup free memory pointer
            hex"82"

            // codecopy runtime to memory and return
            hex"39f3",

            // greetz 0age for More-Minimal Proxy runtime bytecode:
            hex"3d3d3d3d363d3d37363d73",
            address(erc20Implementation),
            hex"5af43d3d93803e602a57fd5bf3"
        );
    }

    function getWrapped1155(IERC1155 multiToken, uint256 tokenId)
        public
        view
        returns (Wrapped1155)
    {
        return Wrapped1155(address(uint256(keccak256(abi.encodePacked(
            uint8(0xff),
            this,
            uint256(1155),
            keccak256(getWrapped1155DeployBytecode(multiToken, tokenId))
        )))));
    }

    function requireWrapped1155(IERC1155 multiToken, uint256 tokenId)
        public
        returns (Wrapped1155)
    {
        bytes memory deployBytecode = getWrapped1155DeployBytecode(multiToken, tokenId);

        address wrapped1155Address = address(uint256(keccak256(abi.encodePacked(
            uint8(0xff),
            this,
            uint256(1155),
            keccak256(deployBytecode)
        ))));

        if (!wrapped1155Address.isContract()) {
            address addr;
            assembly {
              addr := create2(0, add(deployBytecode, 0x20), mload(deployBytecode), 1155)
            }
            require(wrapped1155Address == addr, "Wrapped1155Factory: failed to deploy");
        }

        return Wrapped1155(wrapped1155Address);
    }
}
