/**
 *Submitted for verification at polygonscan.com on 2021-09-07
*/

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

contract OneOfOneNonFungibleDigitalAsset {

    //arbitrary string to be stored at the top of the contract so it is visible first in etherscan
    string public constant arbitraryString = "Non-Fungible-Digital-Assets-2021";

    /*
    The MVP NFT is a lightweight 1/1 NFT contract that conforms to the ERC721 standard in a way that makes it extremely simple for someone to understand what is going on from etherscan.
    Since the token is a 1/1, the tokenId is set to 1, however this could in theory be any value and would just need to update the rest of the contract
    */
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

// string public constant name = "MetaGame Champion NFT";
// string public constant symbol = "MGNFT";
// string public constant uri = "https://bafybeibohh7ignnq54unvyqztkyzhw3jukx35e2an3losghcebt6zwyvjm.ipfs.infura-ipfs.io/";

// string public constant name = "MetaGame Champion NFT";
// string public constant symbol = "MGNFT";
// string public constant uri = "https://bafybeidmiyhxizgjzok3u37hrlmnxzd2zyo2e7vih6enykt6e4jw2tw6d4.ipfs.infura-ipfs.io/";

// string public constant name = "MetaGame Champion NFT";
// string public constant symbol = "MGNFT";
// string public constant uri = "https://bafybeicaar7dpfuc6gzdgpbauam3fumz6sdfe4epjos32t3uxhtnikgwki.ipfs.infura-ipfs.io/";

// string public constant name = "MetaGame Champion NFT";
// string public constant symbol = "MGNFT";
// string public constant uri = "https://bafybeihpxrnu4qxpnzvi6p3npltdostrezrjcts3jnvzahlhwlxg2yesvu .ipfs.infura-ipfs.io/";

// string public constant name = "MetaGame Champion NFT";
// string public constant symbol = "MGNFT";
// string public constant uri = "https://bafybeiemxsj6k5xttfa6zumghyaw6obszros5sdtp3cp5laho2ficet7ce.ipfs.infura-ipfs.io/";

// string public constant name = "MetaGame Champion NFT";
// string public constant symbol = "MGNFT";
// string public constant uri = "https://bafybeidms3faz72l6o3fot6yv2vrtwxurlxc74voaz2g33zyhneal3hghy.ipfs.infura-ipfs.io/";

// string public constant name = "MetaGame Champion NFT";
// string public constant symbol = "MGNFT";
// string public constant uri = "https://bafybeigylqopygivcmouraq4ahyovcrd4kuibtbd5emxru3xqfakavtbme.ipfs.infura-ipfs.io/";

// string public constant name = "MetaGame Champion NFT";
// string public constant symbol = "MGNFT";
// string public constant uri = "https://bafybeiglgwlgsq4g5vdrxiwqeeqcwwbutx5zxkmydo3gvchzlff4fxzp4i.ipfs.infura-ipfs.io/";

string public constant name = "MetaGame Champion NFT";
string public constant symbol = "MGNFT";
string public constant uri = "https://bafybeibiitmctayrpgjqcwhksfh45ugd43x7y5e3qe4l2ob2ryjhbqb4my.ipfs.infura-ipfs.io/";



    uint constant tokenId = 1;
    address public owner;
    address public approved;
    //currently declaring the owner as my local acct on scaffold-eth
    constructor(address _owner) {
        owner = _owner;
        emit Transfer(address(0), _owner, tokenId);
    }

    function totalSupply() public pure returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 _tokenId) external pure returns (string memory){
        require(_tokenId == tokenId, "URI query for nonexistent token");
        return uri;
    }

    function balanceOf(address _queryAddress) external view returns (uint) {
        if(_queryAddress == owner) {
            return 1;
        } else {
            return 0;
        }
    }

    function ownerOf(uint _tokenId) external view returns (address) {
        require(_tokenId == tokenId, "owner query for nonexistent token");
        return owner;
    }

    function safeTransferFrom(address _from, address _to, uint _tokenId, bytes memory data) public payable {
        require(msg.sender == owner || approved == msg.sender, "Msg.sender not allowed to transfer this NFT!");
        require(_from == owner && _from != address(0) && _tokenId == tokenId);
        emit Transfer(_from, _to, _tokenId);
        approved = address(0);
        owner = _to;
        if(isContract(_to)) {
            if(ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, data) != 0x150b7a02) {
                revert("receiving address unable to hold ERC721!");
            }
        }
    }

    //changed the first safeTransferFrom's visibility to make this more readable.
    function safeTransferFrom(address _from, address _to, uint _tokenId) external payable {
        safeTransferFrom(_from, _to, _tokenId, "");
    }

    function transferFrom(address _from, address _to, uint _tokenId) external payable{
        require(msg.sender == owner || approved == msg.sender, "Msg.sender not allowed to transfer this NFT!");
        require(_from == owner && _from != address(0) && _tokenId == tokenId);
        emit Transfer(_from, _to, _tokenId);
        approved = address(0);
        owner = _to;
    }

    function approve(address _approved, uint256 _tokenId) external payable {
        require(msg.sender == owner, "Msg.sender not owner!");
        require(_tokenId == tokenId, "tokenId invald");
        emit Approval(owner, _approved, _tokenId);
        approved = _approved;
    }

    function setApprovalForAll(address _operator, bool _approved) external {
        require(msg.sender == owner, "Msg.sender not owner!");
        if (_approved) {
            emit ApprovalForAll(owner, _operator, _approved);
            approved = _operator;
        } else {
            emit ApprovalForAll(owner, address(0), _approved);
            approved = address(0);
        }
    }

    function getApproved(uint _tokenId) external view returns (address) {
        require(_tokenId == tokenId, "approved query for nonexistent token");
        return approved;
    }

    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        if(_owner == owner){
            return approved == _operator;
        } else {
            return false;
        }
    }

    function isContract(address addr) public view returns(bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    function supportsInterface(bytes4 interfaceID) external pure returns (bool) {
        return interfaceID == 0x80ac58cd ||
             interfaceID == 0x01ffc9a7;
    }

}

interface ERC721TokenReceiver {
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes memory _data) external returns(bytes4);
}