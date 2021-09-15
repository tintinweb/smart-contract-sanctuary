/**
 *Submitted for verification at Etherscan.io on 2021-09-15
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;



// Part: IERC165

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// Part: IKongNaming

interface IKongNaming {
    event SetName(uint256 indexed tokenID, bytes32 name);

    event SetBio(uint256 indexed tokenID, string bio);

    function setName(bytes32 name, uint256 tokenID) external payable;

    function setBio(string memory bio, uint256 tokenID) external payable;
}

// Part: IERC721

interface IERC721 is IERC165 {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// File: KongNaming.sol

contract KongNaming is IKongNaming {
    mapping(uint256 => bytes32) public names;
    mapping(uint256 => string) public bios;

    mapping(uint256 => bool) private nameWasSet;
    mapping(uint256 => bool) private bioWasSet;

    IERC721 public immutable rkl;
    address public immutable admin;
    address payable public immutable beneficiary;

    constructor(
        address newAdmin,
        address payable newBeneficiary,
        address newRkl
    ) {
        ensureAddressNotZero(newAdmin);
        ensureAddressNotZero(newBeneficiary);
        ensureAddressNotZero(newRkl);

        admin = newAdmin;
        beneficiary = newBeneficiary;
        rkl = IERC721(newRkl);
    }

    function setName(bytes32 name, uint256 tokenID) external payable override {
        bool isOwner = isOwnerOfKong(tokenID);
        bool isAdmin = msg.sender == admin;
        require(isAdmin || isOwner, "KongNaming::unauthorized to set");
        bool firstSet = nameWasSet[tokenID] == false;
        if (firstSet) {
            names[tokenID] = name;
            nameWasSet[tokenID] = true;
        } else {
            if (isOwner) {
                require(
                    msg.value == 0.025 ether,
                    "KongNaming::send 0.025 ether to set name"
                );
            }
            names[tokenID] = name;
        }
        emit IKongNaming.SetName(tokenID, name);
    }

    function setBio(string memory bio, uint256 tokenID)
        external
        payable
        override
    {
        bool isOwner = isOwnerOfKong(tokenID);
        bool isAdmin = msg.sender == admin;
        require(isAdmin || isOwner, "KongNaming::unauthorized to set");
        bool firstSet = bioWasSet[tokenID] == false;
        if (firstSet) {
            bios[tokenID] = bio;
            bioWasSet[tokenID] = true;
        } else {
            if (isOwner) {
                require(
                    msg.value == 0.025 ether,
                    "KongNaming::send 0.025 ether to set bio"
                );
            }
            bios[tokenID] = bio;
        }
        emit IKongNaming.SetBio(tokenID, bio);
    }

    function isOwnerOfKong(uint256 tokenID) private view returns (bool) {
        address ownerOfKong = rkl.ownerOf(tokenID);
        return msg.sender == ownerOfKong;
    }

    function ensureAddressNotZero(address checkThis) private pure {
        require(checkThis != address(0), "KongNaming::address is zero");
    }

    function withdraw() external {
        require(msg.sender == admin, "KongNaming::unauthorized");
        uint256 balance = address(this).balance;
        beneficiary.transfer(balance);
    }
}