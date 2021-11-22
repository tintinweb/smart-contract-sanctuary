// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./Ownable.sol";
import "./ERC721EnumerableB.sol";
import "./Strings.sol";

interface ApeContract {
    function ownerOf(uint256 id) external view returns (address);
}

/**
 * @title GalacticMonke smart contract
 * @author Michael Zen
 * @dev Inline assembly used for gas savings
 */
contract GalacticMonke is Ownable, ERC721EnumerableB {
    using Strings for uint256;

    mapping(address => bool) private authorized;
    string private _baseTokenURI = "";
    string private preRevealURI;
    bool public isActive = false;
    uint256 public revealMaxId;
    uint256 public revealTime;
    uint256 private nextMonkeId = 151;

    // Track which apes have been used to mint
    bool[9999] apeMinted;

    modifier onlyAuthorized() {
        require(
            owner() == msg.sender || authorized[msg.sender],
            "Ownable: caller is not the owner"
        );
        _;
    }

    error Ape_Already_Minted(uint256 apeId);
    error Not_Ape_Owner(uint256 apeId, address apeOwner);

    constructor() ERC721B("GalacticMonkes", "MONKES") {}

    //external
    fallback() external {}

    /**
     * @notice Mint token for each valid id
     * @dev Multiple checks to ensure ids are valid
     * @dev msg.sender must be holder of all apeIds
     * @param apeIds Array of ape ids to mint for msg.sender
     */
    function mint(uint256[] calldata apeIds) external {
        require(isActive, "Minting not active");

        uint256 next = nextMonkeId;
        uint256 id;
        bool minted;
        ApeContract apeContract = ApeContract(
            0x12d2D1beD91c24f878F37E66bd829Ce7197e4d14
        );
        address apeOwner;

        for (uint256 i = 0; i < apeIds.length; i++) {
            id = apeIds[i];
            minted = apeMinted[id];

            if (minted) {
                revert Ape_Already_Minted(id);
            }

            apeOwner = apeContract.ownerOf(id);

            if (msg.sender != apeOwner) {
                revert Not_Ape_Owner({apeId: id, apeOwner: apeOwner});
            }

            _safeMint(msg.sender, next + i, "");

            apeMinted[id] = true;
        }

        nextMonkeId += apeIds.length;
    }

    /**
     * @notice Used to mint for genesis holders or unclaimed monkes
     * @dev The ids and receivers arrays must be the same length
     * @param monkeIds The monke token ids to mint
     * @param receivers Addresses that will receive the monkes
     */
    function manualMint(
        uint256[] calldata monkeIds,
        address[] calldata receivers
    ) public onlyAuthorized {
        uint256 id;

        for (uint256 i = 0; i < monkeIds.length; i++) {
            id = monkeIds[i];

            _safeMint(receivers[i], id, "");
        }

        require(totalSupply() < 10150, "Mint exceeds max supply");
    }

    /**
     * @notice Sets isActive to the inverse
     */
    function toggleActive() public onlyOwner {
        isActive = !isActive;
    }

    function setNextMonkeId(uint256 id) public onlyAuthorized {
        nextMonkeId = id;
    }

    /**
     * @notice Determines if given Ape Ids can be used to mint.
     */
    function canMint(uint256[] calldata apeIds)
        public
        view
        returns (bool[] memory)
    {
        require(apeIds.length > 0, "No Ape Ids given.");
        bool[] memory mintables = new bool[](apeIds.length);

        for (uint256 i = 0; i < apeIds.length; i++) {
            uint256 id = apeIds[i];

            if (id < 0 || id > 9998) {
                mintables[i] = false;
            } else {
                bool minted = apeMinted[id];

                mintables[i] = !minted;
            }
        }

        return mintables;
    }

    /**
     * @notice Set reveal timestamp and monke id
     * @param _id Highest monke id to reveal
     * @param _time Timestamp used to calculate reveal timestamp
     */
    function setRevealData(
        uint256 _id,
        uint256 _time,
        bool automatic
    ) public onlyAuthorized {
        uint256 id = _id;
        uint256 time = _time;

        if (automatic) {
            if (id == 0) {
                uint256 supply = totalSupply();

                if (supply > 0) {
                    id = totalSupply() - 1;
                }
            }

            if (time == 0) {
                time = block.timestamp;
            }
        }

        revealMaxId = id;
        revealTime = time;
    }

    /**
     * @notice Returns current reveal data
     * @dev revealData.time needs to have 3600 added once retreived
     */
    function getRevealData() public view returns (uint256, uint256) {
        return (revealMaxId, revealTime);
    }

    function giveAuthorization(address target) public onlyOwner {
        authorized[target] = true;
    }

    function revokeAuthorization(address target) public onlyOwner {
        authorized[target] = false;
    }

    /**
     * @notice Set _baseTokenURI
     * @param _newBaseURI URI used for revealed monkes
     */
    function setBaseURI(string calldata _newBaseURI) public onlyOwner {
        _baseTokenURI = _newBaseURI;
    }

    /**
     * @notice Set preRevealURI
     * @param _preRevealURI URI used for pre-revealed monkes
     */
    function setPreReveaURI(string calldata _preRevealURI) public onlyOwner {
        preRevealURI = _preRevealURI;
    }

    /**
     * @notice Returns URI for given monke token id
     * @param tokenId Monke token id
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        // Give one hour buffer in case revealData.time was set automatically
        if (
            revealMaxId > 0 &&
            tokenId <= revealMaxId &&
            block.timestamp >= revealTime + 3600
        ) {
            return string(abi.encodePacked(_baseTokenURI, tokenId.toString()));
        } else {
            return string(abi.encodePacked(preRevealURI));
        }
    }

    function balanceOf(
        address owner,
        uint256 start,
        uint256 end
    ) public view returns (uint256) {
        require(
            owner != address(0),
            "ERC721: balance query for the zero address"
        );
        require(end < _owners.length, "end must be less than total supply");

        uint256 count = 0;
        for (uint256 i = start; i <= end; ++i) {
            if (owner == _owners[i]) {
                ++count;
            }
        }

        return count;
    }
}