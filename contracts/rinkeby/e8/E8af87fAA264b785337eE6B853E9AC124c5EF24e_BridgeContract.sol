pragma solidity ^0.8.0;

interface IERC1155 {
    function tokenURI(uint256) external view returns (string memory);

    function setApprovalForAll(address operator, bool _approved) external;

    function mint(address, string calldata, uint256, bytes memory) external returns (uint256);

    function safeTransferFrom(address, address, uint256, uint256, bytes memory) external;
}

contract BridgeContract {
    address constant hotwallet = address(0x0b216630Ec5adfA4ff7423A29b7f8a98F047DdD9);
    address constant contr = address(0xE3d445fea71b94AeFc5e9b2Fa3fae34b0A94B84B);

    mapping(uint256 => bool) public withdrawals;
    mapping(address => bool) public signers;

    mapping(string => bool) public editions;

    uint256 constant w = 0;

    event Deposited(string tokendID, uint256 tokenID);
    event Minted(string tokendID, string edition, uint256 tokenID, uint8 amount);
    event Withdrawn(uint256 reqID, uint256 tokenID);

    modifier isSigned(
        uint256 _prefix,
        uint256 _requestID,
        uint256 _tokenID,
        bytes32 _r,
        bytes32 _s,
        uint8 _v
    ) {
        bytes32 _hash = keccak256(abi.encodePacked(_prefix, msg.sender, _requestID, _tokenID));
        address signer = ecrecover(_hash, _v, _r, _s);

        require(hotwallet == signer, "bad-signer");
        _;
    }

    function isSigners(address[] memory _signers) internal view returns (bool) {
        for (uint8 i = 0; i < _signers.length; i++) {
            if (!signers[_signers[i]]) {
                return false;
            }
        }

        return true;
    }

    function mint(
        string memory tokendID,
        string memory tokenURI
    ) external {
        uint256 tokenID = IERC1155(contr).mint(hotwallet, tokenURI, 1, "");
        emit Minted(tokendID, "", tokenID, 1);
    }

    function batchMint(string memory tokendID, string memory tokenURI, uint8 amount) external {
        uint256 startID = IERC1155(contr).mint(hotwallet, tokenURI, 1, "");

        for (uint8 i = 1; i < amount; i++) {
            IERC1155(contr).mint(hotwallet, tokenURI, 1, "");
        }
        emit Minted(tokendID, "", startID, amount);
    }

    function mintBySelf(string memory tokendID, string memory tokenURI) external {
        uint256 tokenID = IERC1155(contr).mint(msg.sender, tokenURI, 1, "");
        IERC1155(contr).safeTransferFrom(msg.sender, hotwallet, tokenID, 1, "");
        emit Minted(tokendID, "", tokenID, 1);
    }

    function batchMintBySelf(string memory tokendID, string memory tokenURI, string memory edition, uint8 amount) external {
        require(!editions[edition], "such-edition-already-exist");
        uint256 startID = IERC1155(contr).mint(msg.sender, tokenURI, 1, "");
        IERC1155(contr).safeTransferFrom(msg.sender, hotwallet, startID, 1, "");

        for (uint8 i = 1; i < amount; i++) {
            IERC1155(contr).safeTransferFrom(msg.sender, hotwallet, IERC1155(contr).mint(msg.sender, tokenURI, 1, ""), 1, "");
        }

        editions[edition] = true;
        emit Minted(tokendID, edition, startID, amount);
    }

    function deposit(string memory tokendID, uint256 tokenID) external {
        IERC1155(contr).safeTransferFrom(msg.sender, hotwallet, tokenID, 1, "");
        emit Deposited(tokendID, tokenID);
    }

    function withdraw(
        uint256 withdrawID,
        uint256 tokenID,
        bytes32 _r,
        bytes32 _s,
        uint8 _v
    ) external isSigned(w, withdrawID, tokenID, _r, _s, _v) {
        require(!withdrawals[withdrawID], "such-withdraw-already-used");
        IERC1155(contr).safeTransferFrom(hotwallet, msg.sender, tokenID, 1, "");
        emit Withdrawn(withdrawID, tokenID);
    }

    function lazyWithdraw(
        uint256 withdrawID,
        string memory tokenURI,
        bytes32 _r,
        bytes32 _s,
        uint8 _v
    ) external isSigned(w, withdrawID, 0, _r, _s, _v) {
        require(!withdrawals[withdrawID], "such-withdraw-already-used");
        uint256 tokenID = IERC1155(contr).mint(hotwallet, tokenURI, 1, "");
        IERC1155(contr).safeTransferFrom(hotwallet, msg.sender, tokenID, 1, "");
        emit Withdrawn(withdrawID, tokenID);
    }
}

