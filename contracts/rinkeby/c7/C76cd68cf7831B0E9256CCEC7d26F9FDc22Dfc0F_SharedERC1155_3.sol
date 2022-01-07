/**
 *Submitted for verification at Etherscan.io on 2022-01-07
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface ERC1155TokenReceiver {
    function onERC1155Received(address operator,address from,uint256 id,uint256 amount, bytes calldata data) external returns (bytes4);
    function onERC1155BatchReceived(address operator,address from,uint256[] calldata ids,uint256[] calldata amounts,bytes calldata data) external returns (bytes4);
}

contract SharedERC1155_3 {
    event TransferSingle(address indexed operator,address indexed from,address indexed to,uint256 id,uint256 amount);
    event TransferBatch(address indexed operator,address indexed from,address indexed to,uint256[] ids,uint256[] amounts);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event URI(string value, uint256 indexed id);

    mapping(address => mapping(uint256 => uint256)) public balanceOf;
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    function setApprovalForAll(address operator, bool approved) external{
        isApprovedForAll[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }
    function safeTransferFrom(address from,address to,uint256 id,uint256 amount,bytes memory data) external {
        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");
        balanceOf[from][id] -= amount;
        balanceOf[to][id] += amount;
        emit TransferSingle(msg.sender, from, to, id, amount);
        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
    function safeBatchTransferFrom(address from,address to,uint256[] memory ids,uint256[] memory amounts,bytes memory data) external{
        uint256 idsLength = ids.length;
        require(idsLength == amounts.length, "LENGTH_MISMATCH");
        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");
        for (uint256 i = 0; i < idsLength; ) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];
            balanceOf[from][id] -= amount;
            balanceOf[to][id] += amount;
            unchecked {
                i++;
            }
        }
        emit TransferBatch(msg.sender, from, to, ids, amounts);
        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }
    function balanceOfBatch(address[] memory owners, uint256[] memory ids) external view returns (uint256[] memory balances){
        uint256 ownersLength = owners.length;
        require(ownersLength == ids.length, "LENGTH_MISMATCH");
        balances = new uint256[](owners.length);
        unchecked {
            for (uint256 i = 0; i < ownersLength; i++) {
                balances[i] = balanceOf[owners[i]][ids[i]];
            }
        }
    }
    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return
            interfaceId == 0x01ffc9a7 ||
            interfaceId == 0xd9b67a26 ||
            interfaceId == 0x0e89341c;
    }

    function _mint(address to,uint256 id,uint256 amount,bytes memory data) internal {
        balanceOf[to][id] += amount;
        emit TransferSingle(msg.sender, address(0), to, id, amount);
        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, address(0), id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchMint(address to,uint256[] memory ids,uint256[] memory amounts,bytes memory data) internal {
        uint256 idsLength = ids.length; // Saves MLOADs.
        require(idsLength == amounts.length, "LENGTH_MISMATCH");
        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[to][ids[i]] += amounts[i];
            unchecked {
                i++;
            }
        }
        emit TransferBatch(msg.sender, address(0), to, ids, amounts);
        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, address(0), ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

//@ukishima

    string public constant name = "Shared ERC1155";
    mapping(uint256 => string) public uri;
    //mapping(bytes32 => address) internal usedSignature;

    function create(address to,uint256 nonce,string calldata _uri,uint256 amount,bytes memory signature) external{
        //bytes32 signaturehash = keccak256(signature);        
        //require(usedSignature[signaturehash] == address(0),"USED SIGNATURE");
        //usedSignature[signaturehash] = msg.sender;

        bytes32 messagehash = keccak256(abi.encode(to,nonce,_uri, amount));
        require(verify(messagehash,signature),"NOT_AUTHORIZED");

        uint256 id = uint(keccak256(bytes(_uri)));
        if(bytes(uri[id]).length == 0){
            uri[id] = _uri;
            emit URI(_uri,id);
        }
        _mint(to,id,amount,"");
    }

 
    //function uri(uint256 id) external view returns (string memory){
        //return string(abi.encodePacked("https://",uris[id]));
    //}

    function verify(bytes32 hash,bytes memory sig) public pure returns (bool) {
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
        return keccak256(abi.encodePacked(ecrecover(hash, v, r, s))) == 0xddc8e02dcd816f76b8a3f185785cd995996e1d01d976b1d4c05a9bc7718a3b1d;
    }

}