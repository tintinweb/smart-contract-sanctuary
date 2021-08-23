/**
 *Submitted for verification at Etherscan.io on 2021-08-23
*/

pragma solidity ^0.8.0;


interface IERC721 {
    function tokenURI(uint256) external view returns (string memory);

    function setApprovalForAll(address operator, bool _approved) external;

    function mint(address, string calldata) external returns (uint256);

    function transferFrom(address, address, uint256) external;
}

contract BridgeContract {
    address constant hotwallet = address(0x9266798B4469275e844C94f747b4e35Dc6aD8D77);
    address constant contr = address(0x9C1c3cB34e06F21cc0F867794ae00a45Bd7B7c51);

    mapping(uint256 => bool) public withdrawals;

    // version of the contract to prevent reusing signatures
    uint256 constant public CONTRACT_VERSION = 3;

    // asset_code that related to this bridge,
    // this contract operate with only one asset
    string constant ASSET_CODE = "bnft";

    // indexes for packed signature parameters

    event Deposited(string tokendID, uint256 tokenID, string indexed asset_code);
    event Minted(string tokendID, string edition, uint256 tokenID, uint8 amount, string indexed asset_code);
    event Withdrawn(uint256 reqID, uint256 tokenID, string indexed asset_code);

    function checkSignature(
        uint256 _timestamp,
        uint256 _requestID,
        uint256 _tokenID,
        bytes32 _r,
        bytes32 _s,
        uint8 _v
    ) view internal returns (bool) {
        require(_timestamp >= block.timestamp, "signature-expired");
        bytes32 _hash = keccak256(abi.encodePacked(CONTRACT_VERSION, _timestamp, msg.sender, _requestID, _tokenID));
        address signer = ecrecover(_hash, _v, _r, _s);
        require(signer != address(0), "signature-invalid");

        return hotwallet == signer;
    }

    function mint(
        string memory tokendID,
        string memory tokenURI
    ) external {
        uint256 tokenID = IERC721(contr).mint(hotwallet, tokenURI);
        emit Minted(tokendID, "", tokenID, 1, ASSET_CODE);
    }

    function batchMint(string memory tokendID, string memory tokenURI, uint8 amount) external {
        uint256 startID = IERC721(contr).mint(hotwallet, tokenURI);

        for (uint8 i = 1; i < amount; i++) {
            IERC721(contr).mint(hotwallet, tokenURI);
        }
        emit Minted(tokendID, "", startID, amount, ASSET_CODE);
    }

    function mintBySelf(string memory tokendID, string memory tokenURI) external {
        uint256 tokenID = IERC721(contr).mint(msg.sender, tokenURI);
        IERC721(contr).transferFrom(msg.sender, hotwallet, tokenID);
        emit Minted(tokendID, "", tokenID, 1, ASSET_CODE);
    }

    function batchMintBySelf(
        string memory tokendID,
        string memory tokenURI,
        string memory edition,
        uint8 amount
    ) external {
        uint256 startID = IERC721(contr).mint(hotwallet, tokenURI);
        IERC721(contr).transferFrom(msg.sender, hotwallet, startID);

        for (uint8 i = 1; i < amount; i++) {
            IERC721(contr).transferFrom(msg.sender, hotwallet, IERC721(contr).mint(msg.sender, tokenURI));
        }

        emit Minted(tokendID, edition, startID, amount, ASSET_CODE);
    }

    function deposit(
        string memory tokendID,
        uint256 tokenID
    ) external {
        IERC721(contr).transferFrom(msg.sender, hotwallet, tokenID);
        emit Deposited(tokendID, tokenID, ASSET_CODE);
    }

    function _withdrawFromHotwallet(
        address receiver,
        uint256 tokenID,
        uint256 withdrawID
    ) internal {
        IERC721(contr).transferFrom(hotwallet, receiver, tokenID);
        withdrawals[withdrawID] = true;
        emit Withdrawn(withdrawID, tokenID, ASSET_CODE);
    }

    function withdraw(
        uint256 withdrawID,
        uint256 timestamp,
        uint256 tokenID,
        bytes32 _r,
        bytes32 _s,
        uint8 _v
    ) external {
        require(!withdrawals[withdrawID], "such-withdraw-already-used");
        require(checkSignature(timestamp, withdrawID, tokenID, _r, _s, _v), "bad-signature");
        _withdrawFromHotwallet(msg.sender, tokenID, withdrawID);
    }

    function lazyWithdraw(
        uint256 withdrawID,
        uint256 timestamp,
        string memory tokenURI,
        bytes32 _r,
        bytes32 _s,
        uint8 _v
    ) external {
        require(!withdrawals[withdrawID], "such-withdraw-already-used");
        require(checkSignature(timestamp, withdrawID, 0, _r, _s, _v), "bad-signature");
        _withdrawFromHotwallet(msg.sender, IERC721(contr).mint(hotwallet, tokenURI), withdrawID);
    }
}