pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT
import "./Interfaces.sol";

contract EthBotTest is ERC165, ERC721 {
    mapping(uint256 => address) public owner;
    mapping(address => mapping(address => bool)) public operatorList;
    mapping(uint256 => address) public approved;
    mapping(address => uint256) public balances;

    constructor() {
        owner[1] = 0x807a1752402D21400D555e1CD7f175566088b955;
    }

    function isContract(address addr) public view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    function balanceOf(address _owner)
        external
        view
        override
        returns (uint256)
    {
        return balances[_owner];
    }

    function ownerOf(uint256 _tokenId)
        external
        view
        override
        returns (address)
    {
        return owner[_tokenId];
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory data
    ) external payable override {
        require(
            msg.sender == owner[_tokenId] ||
                approved[_tokenId] == msg.sender ||
                operatorList[owner[_tokenId]][msg.sender] == true,
            "Msg.sender not allowed to transfer this NFT!"
        );
        require(_from == owner[_tokenId] && _from != address(0));
        if (isContract(_to)) {
            if (
                ERC721TokenReceiver(_to).onERC721Received(
                    msg.sender,
                    _from,
                    _tokenId,
                    data
                ) == 0x150b7a02
            ) {
                emit Transfer(_from, _to, _tokenId);
                balances[_from]--;
                balances[_to]++;
                approved[_tokenId] = address(0);
                owner[_tokenId] = _to;
            } else {
                revert("receiving address unable to hold ERC721!");
            }
        } else {
            emit Transfer(_from, _to, _tokenId);
            balances[_from]--;
            balances[_to]++;
            approved[_tokenId] = address(0);
            owner[_tokenId] = _to;
        }
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external payable override {
        require(
            msg.sender == owner[_tokenId] ||
                approved[_tokenId] == msg.sender ||
                operatorList[owner[_tokenId]][msg.sender] == true,
            "Msg.sender not allowed to transfer this NFT!"
        );
        require(_from == owner[_tokenId] && _from != address(0));
        if (isContract(_to)) {
            if (
                ERC721TokenReceiver(_to).onERC721Received(
                    msg.sender,
                    _from,
                    _tokenId,
                    ""
                ) == 0x150b7a02
            ) {
                emit Transfer(_from, _to, _tokenId);
                balances[_from]--;
                balances[_to]++;
                approved[_tokenId] = address(0);
                owner[_tokenId] = _to;
            } else {
                revert("receiving address unable to hold ERC721!");
            }
        } else {
            emit Transfer(_from, _to, _tokenId);
            balances[_from]--;
            balances[_to]++;
            approved[_tokenId] = address(0);
            owner[_tokenId] = _to;
        }
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external payable override {
        require(
            msg.sender == owner[_tokenId] ||
                approved[_tokenId] == msg.sender ||
                operatorList[owner[_tokenId]][msg.sender] == true,
            "Msg.sender not allowed to transfer this NFT!"
        );
        require(_from == owner[_tokenId] && _from != address(0));
        emit Transfer(_from, _to, _tokenId);
        balances[_from]--;
        balances[_to]++;
        approved[_tokenId] = address(0);
        owner[_tokenId] = _to;
    }

    function approve(address _approved, uint256 _tokenId)
        external
        payable
        override
    {
        require(
            msg.sender == owner[_tokenId] ||
                approved[_tokenId] == msg.sender ||
                operatorList[owner[_tokenId]][msg.sender] == true,
            "Msg.sender not allowed to approve this NFT!"
        );
        emit Approval(owner[_tokenId], _approved, _tokenId);
        approved[_tokenId] = _approved;
    }

    function setApprovalForAll(address _operator, bool _approved)
        external
        override
    {
        emit ApprovalForAll(msg.sender, _operator, _approved);
        operatorList[msg.sender][_operator] = _approved;
    }

    function getApproved(uint256 _tokenId)
        external
        view
        override
        returns (address)
    {
        return approved[_tokenId];
    }

    function isApprovedForAll(address _owner, address _operator)
        external
        view
        override
        returns (bool)
    {
        return operatorList[_owner][_operator];
    }

    function supportsInterface(bytes4 interfaceID)
        external
        pure
        override
        returns (bool)
    {
        return interfaceID == 0x80ac58cd || interfaceID == 0x01ffc9a7;
    }

    function tokenURI() public pure returns(string memory) {
        return "https://bonez.mypinata.cloud/ipfs/QmaE1RPE4cvczPungLemcbotNRmswR4vXdi7CqaojDJwRf";
    }

}

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

interface ERC721 {
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) external payable;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function approve(address _approved, uint256 _tokenId) external payable;
    function setApprovalForAll(address _operator, bool _approved) external;
    function getApproved(uint256 _tokenId) external view returns (address);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}
interface ERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}
interface ERC721TokenReceiver {
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes memory _data) external returns(bytes4);
}