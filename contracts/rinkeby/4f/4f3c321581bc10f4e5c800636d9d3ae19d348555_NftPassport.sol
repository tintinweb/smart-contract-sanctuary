// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";

contract NftPassport is ERC721, Ownable {
    string public baseURI;
    address public dataSigner;
    address payable public feeReceiver;
    uint16 public chainId;
    uint public mintFee;
    uint public passportsMinted = 0;

    struct PassportData {
        address owner;
        string nickname;
        uint16 country;
        uint32 birthDate;
    }
    mapping(uint => PassportData) public passports;

    event PassportMint(address indexed owner, uint indexed id, string nickname);
    event PassportUpdate(address indexed owner, uint indexed id, uint16 country, uint32 birthDate);
    event PassportBurn(address indexed owner, uint indexed id);
    event NicknameUpdate(address indexed owner, uint indexed id, string nickname);

    constructor(
        string memory _newBaseURI,
        uint16 _chainId,
        uint _mintFee,
        address payable _feeReceiver,
        address _dataSigner
    ) ERC721("NFT Passport", "NFTP") {
        baseURI = _newBaseURI;
        chainId = _chainId;
        mintFee = _mintFee;
        feeReceiver = _feeReceiver;
        dataSigner = _dataSigner;
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

    function setDataSigner(address _dataSigner) public onlyOwner {
        dataSigner = _dataSigner;
    }

    function mintPassport(string calldata _nickname) external payable {
        require(msg.value == mintFee, "Incorrect fee amount");
        feeReceiver.transfer(msg.value);
        uint id = passportsMinted;
        _safeMint(msg.sender, id);
        passports[id] = PassportData(msg.sender, _nickname, 0, 0);
        passportsMinted++;
        emit PassportMint(msg.sender, id, _nickname);
    }

    function updateNickname(uint _id, string calldata _nickname) external {
        require(_isApprovedOrOwner(msg.sender, _id), "Forbidden");
        passports[_id].nickname = _nickname;
        emit NicknameUpdate(msg.sender, _id, _nickname);
    }

    function setPassportData(uint _id, uint16 _country, uint32 _birthDate, bytes memory _sign) external {
        require(_isApprovedOrOwner(msg.sender, _id), "Forbidden");
        require(passports[_id].country == 0 && passports[_id].birthDate == 0, "The data is already specified");
        require(_verifySignature(_id, _country, _birthDate, _sign), "Incorrect signature");
        passports[_id].country = _country;
        passports[_id].birthDate = _birthDate;
        emit PassportUpdate(msg.sender, _id, _country, _birthDate);
    }

    function burnPassport(uint _id) external {
        require(_isApprovedOrOwner(msg.sender, _id), "Forbidden");
        _burn(_id);
        passports[_id] = PassportData(address(0), "", 0, 0);
        emit PassportBurn(msg.sender, _id);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _verifySignature(uint _id, uint16 _country, uint32 _birthDate, bytes memory _sign) internal view returns (bool) {
        bytes32 hash = keccak256(abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encode(chainId, _id, _country, _birthDate))
            ));
        address[] memory signList = _recoverAddresses(hash, _sign);
        return signList[0] == dataSigner;
    }

    function _recoverAddresses(bytes32 _hash, bytes memory _signatures) pure internal returns (address[] memory addresses) {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint count = _countSignatures(_signatures);
        addresses = new address[](count);
        for (uint i = 0; i < count; i++) {
            (v, r, s) = _parseSignature(_signatures, i);
            addresses[i] = ecrecover(_hash, v, r, s);
        }
    }

    function _parseSignature(bytes memory _signatures, uint _pos) pure internal returns (uint8 v, bytes32 r, bytes32 s) {
        uint offset = _pos * 65;
        assembly {
            r := mload(add(_signatures, add(32, offset)))
            s := mload(add(_signatures, add(64, offset)))
            v := and(mload(add(_signatures, add(65, offset))), 0xff)
        }
        if (v < 27) v += 27;
        require(v == 27 || v == 28);
    }

    function _countSignatures(bytes memory _signatures) pure internal returns (uint) {
        return _signatures.length % 65 == 0 ? _signatures.length / 65 : 0;
    }
}