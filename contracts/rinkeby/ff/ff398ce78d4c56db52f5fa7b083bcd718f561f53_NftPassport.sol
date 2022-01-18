// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";

contract NftPassport is ERC721, Ownable {
    string public baseURI;
    address payable public feeReceiver;
    uint public mintFee;
    uint public passportsMinted = 0;
    mapping(uint => string) public nicknames;

    event PassportMint(address indexed owner, uint indexed id, string nickname);
    event PassportUpdate(address indexed owner, uint indexed id, string nickname);
    event PassportBurn(address indexed owner, uint indexed id);

    constructor(string memory _newBaseURI, uint _mintFee, address payable _feeReceiver) ERC721("NFT Passport", "NFTP") {
        baseURI = _newBaseURI;
        mintFee = _mintFee;
        feeReceiver = _feeReceiver;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setMintFee(uint _mintFee) public onlyOwner {
        mintFee = _mintFee;
    }

    function setFeeReceiver(address payable _feeReceiver) public onlyOwner {
        feeReceiver = _feeReceiver;
    }

    function mintPassport(string calldata _nickname) external payable {
        require(msg.value == mintFee, "Incorrect fee amount");
        feeReceiver.transfer(msg.value);
        uint id = passportsMinted;
        _safeMint(msg.sender, id);
        nicknames[id] = _nickname;
        passportsMinted++;
        emit PassportMint(msg.sender, id, _nickname);
    }

    function updateNickname(uint _id, string calldata _nickname) external {
        require(_isApprovedOrOwner(msg.sender, _id), "Forbidden");
        nicknames[_id] = _nickname;
        emit PassportUpdate(msg.sender, _id, _nickname);
    }

    function burnPassport(uint _id) external {
        require(_isApprovedOrOwner(msg.sender, _id), "Forbidden");
        _burn(_id);
        nicknames[_id] = '';
        emit PassportBurn(msg.sender, _id);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
}