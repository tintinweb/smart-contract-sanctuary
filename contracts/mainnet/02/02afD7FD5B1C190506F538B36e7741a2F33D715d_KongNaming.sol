/**
 *Submitted for verification at Etherscan.io on 2021-09-24
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

    function setNameAndBio(
        bytes32 name,
        string memory bio,
        uint256 tokenID
    ) external payable;

    function batchSetName(bytes32[] memory names, uint256[] memory tokenIDs)
        external
        payable;

    function batchSetBio(string[] memory bios, uint256[] memory tokenIDs)
        external
        payable;

    function batchSetNameAndBio(
        bytes32[] memory names,
        string[] memory bios,
        uint256[] memory tokenIDs
    ) external payable;
}

// Part: OpenZeppelin/[email protected]/ReentrancyGuard

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
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

contract KongNaming is IKongNaming, ReentrancyGuard {
    mapping(uint256 => bytes32) public names;
    mapping(uint256 => string) public bios;

    mapping(uint256 => bool) private nameWasSet;
    mapping(uint256 => bool) private bioWasSet;

    address public admin;
    address payable public beneficiary;
    IERC721 public immutable rkl;
    uint256 public changePrice = 0.025 ether;

    constructor(
        address newAdmin,
        address payable newBeneficiary,
        address newRkl
    ) {
        ensureAddressNotZero(newAdmin);
        ensureAddressNotZero(newBeneficiary);
        ensureAddressNotZero(newRkl);
        rkl = IERC721(newRkl);
        admin = newAdmin;
        beneficiary = newBeneficiary;
    }

    function setName(bytes32 name, uint256 tokenID)
        external
        payable
        override
        nonReentrant
    {
        // check that the caller is either an owner or admin
        bool isOwner = isOwnerOfKong(tokenID);
        require(msg.sender == admin || isOwner, "KongNaming::unauthorized");

        // if this is the first time the name is set, mark that the
        // next time won't be and set the name
        if (nameWasSet[tokenID] == false) {
            nameWasSet[tokenID] = true;
        } else {
            // if it was the owner that called the function, require
            // the payment
            if (isOwner) {
                require(
                    msg.value == changePrice,
                    "KongNaming::insufficient ether sent"
                );
            }
        }

        names[tokenID] = name;
        emit IKongNaming.SetName(tokenID, name);
    }

    function setBio(string memory bio, uint256 tokenID)
        external
        payable
        override
        nonReentrant
    {
        // check that the caller is either an owner or admin
        bool isOwner = isOwnerOfKong(tokenID);
        require(msg.sender == admin || isOwner, "KongNaming::unauthorized");

        // if this is the first time the bio is set, mark that the
        // next time won't be and set the bio
        if (bioWasSet[tokenID] == false) {
            bioWasSet[tokenID] = true;
        } else {
            // if it was the owner that called the function, require
            // the payment
            if (isOwner) {
                require(
                    msg.value == changePrice,
                    "KongNaming::insufficient ether sent"
                );
            }
        }

        bios[tokenID] = bio;
        emit IKongNaming.SetBio(tokenID, bio);
    }

    function setNameAndBio(
        bytes32 name,
        string memory bio,
        uint256 tokenID
    ) external payable override nonReentrant {
        bool isOwner = isOwnerOfKong(tokenID);
        require(msg.sender == admin || isOwner, "KongNaming::unauthorized");

        uint256 payableSets = 0;

        if (bioWasSet[tokenID] == false) {
            bioWasSet[tokenID] = true;
        } else {
            payableSets += 1;
        }

        if (nameWasSet[tokenID] == false) {
            nameWasSet[tokenID] = true;
        } else {
            payableSets += 1;
        }

        if (isOwner) {
            require(
                msg.value == payableSets * changePrice,
                "KongNaming::insufficient ether sent"
            );
        }

        names[tokenID] = name;
        bios[tokenID] = bio;
        emit IKongNaming.SetName(tokenID, name);
        emit IKongNaming.SetBio(tokenID, bio);
    }

    function batchSetName(bytes32[] memory _names, uint256[] memory tokenIDs)
        external
        payable
        override
        nonReentrant
    {
        // sanity checks
        require(
            _names.length == tokenIDs.length,
            "KongNaming::different length names and tokenIDs"
        );
        // returns true if the sender is owner of all the passed tokenIDs
        bool ownerOfAllKongs = isOwnerOfKongs(tokenIDs);
        // require the caller to be the owner of all of the tokenIDs or be
        // an admin
        require(
            msg.sender == admin || ownerOfAllKongs,
            "KongNaming::unauthorized"
        );

        // counter to check how much ether should be sent
        uint256 payableSets = 0;

        for (uint256 i = 0; i < _names.length; i) {
            if (nameWasSet[tokenIDs[i]] == false) {
                nameWasSet[tokenIDs[i]] = true;
            } else {
                payableSets += 1;
            }

            names[tokenIDs[i]] = _names[i];
            emit IKongNaming.SetName(tokenIDs[i], _names[i]);
        }

        // if it is owner who called, ensure that they have sent adequate
        // payment
        if (ownerOfAllKongs) {
            require(
                msg.value == payableSets * changePrice,
                "KongNaming::insufficient ether sent"
            );
        }
    }

    function batchSetBio(string[] memory _bios, uint256[] memory tokenIDs)
        external
        payable
        override
        nonReentrant
    {
        require(
            _bios.length == tokenIDs.length,
            "KongNaming::different length bios and tokenIDs"
        );
        bool ownerOfAllKongs = isOwnerOfKongs(tokenIDs);
        require(
            msg.sender == admin || ownerOfAllKongs,
            "KongNaming::not authorized"
        );

        uint256 payableSets = 0;

        for (uint256 i = 0; i < _bios.length; i) {
            if (bioWasSet[tokenIDs[i]] == false) {
                bioWasSet[tokenIDs[i]] = true;
            } else {
                payableSets += 1;
            }

            bios[tokenIDs[i]] = _bios[i];
            emit IKongNaming.SetBio(tokenIDs[i], _bios[i]);
        }

        if (ownerOfAllKongs) {
            require(
                msg.value == payableSets * changePrice,
                "KongNaming::insufficient ether sent"
            );
        }
    }

    function batchSetNameAndBio(
        bytes32[] memory _names,
        string[] memory _bios,
        uint256[] memory tokenIDs
    ) external payable override nonReentrant {
        require(
            _names.length == _bios.length,
            "KongNaming::different length names and bios"
        );
        require(
            _bios.length == tokenIDs.length,
            "KongNaming::different length bios and tokenIDs"
        );
        bool ownerOfAllKongs = isOwnerOfKongs(tokenIDs);
        require(
            msg.sender == admin || ownerOfAllKongs,
            "KongNaming::not authorized"
        );

        uint256 payableSets = 0;

        for (uint256 i = 0; i < _names.length; i++) {
            if (bioWasSet[tokenIDs[i]] == false) {
                bioWasSet[tokenIDs[i]] = true;
            } else {
                payableSets += 1;
            }
            if (nameWasSet[tokenIDs[i]] == false) {
                nameWasSet[tokenIDs[i]] = true;
            } else {
                payableSets += 1;
            }

            names[tokenIDs[i]] = _names[i];
            bios[tokenIDs[i]] = _bios[i];
            emit IKongNaming.SetName(tokenIDs[i], _names[i]);
            emit IKongNaming.SetBio(tokenIDs[i], _bios[i]);
        }

        if (ownerOfAllKongs) {
            require(
                msg.value == payableSets * changePrice,
                "KongNaming::insufficient ether sent"
            );
        }
    }

    function isOwnerOfKong(uint256 tokenID) private view returns (bool) {
        return msg.sender == rkl.ownerOf(tokenID);
    }

    function isOwnerOfKongs(uint256[] memory tokenIDs)
        private
        view
        returns (bool)
    {
        for (uint256 i = 0; i < tokenIDs.length; i++) {
            if (!isOwnerOfKong(tokenIDs[i])) {
                return false;
            }
        }
        return true;
    }

    function ensureAddressNotZero(address checkThisAddress) private pure {
        require(checkThisAddress != address(0), "KongNaming::address is zero");
    }

    function editPrice(uint256 newChangePrice) external {
        require(msg.sender == admin, "KongNaming::unauthorized");
        changePrice = newChangePrice;
    }

    function editBeneficiary(address payable newBeneficiary) external {
        require(msg.sender == admin, "KongNaming::unauthorized");
        beneficiary = newBeneficiary;
    }

    function editAdmin(address newAdmin) external {
        require(msg.sender == admin, "KongNaming::unauthorized");
        admin = newAdmin;
    }

    function withdraw() external {
        require(msg.sender == admin, "KongNaming::unauthorized");
        beneficiary.transfer(address(this).balance);
    }
}