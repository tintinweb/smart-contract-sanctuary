// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Metadata.sol";
import "./IERC721Enumerable.sol";
import "./IERC1155.sol";

contract GoldenTicketNFT {
    IERC721 private bayc;
    IERC721Metadata private bayc_metadata;
    IERC721Enumerable private bayc_enumerable;
    IERC721 private mayc;
    IERC721Enumerable private mayc_enumerable;
    IERC1155 private goldenTicket;
    uint256 internal goldenTicketTokenId;
    uint256 internal goldenTicket2TokenId;
    address private TRANSFER_TO_ADDRESS;

    modifier onlyApeOwner(address _owner) {
        require(
            bayc.balanceOf(_owner) > 0 || mayc.balanceOf(_owner) > 0,
            "ApeOwner: Caller is not an ape owner"
        );
        _;
    }

    modifier onlyGoldenTicketOwner(address _owner) {
        require(
            goldenTicket.balanceOf(_owner, goldenTicketTokenId) > 0 ||
                goldenTicket.balanceOf(_owner, goldenTicket2TokenId) > 0,
            "GoldenTicketOwner: Caller is not a golden ticket owner"
        );
        _;
    }

    constructor(
        address _baycAddress,
        address _maycAddress,
        address _goldenTicketAddress,
        uint256 _goldenTicketTokenId,
        uint256 _goldenTicket2TokenId,
        address _transferToAddress
    ) {
        bayc = IERC721(_baycAddress);
        bayc_metadata = IERC721Metadata(_baycAddress);
        bayc_enumerable = IERC721Enumerable(_baycAddress);
        mayc = IERC721(_maycAddress);
        mayc_enumerable = IERC721Enumerable(_maycAddress);
        goldenTicket = IERC1155(_goldenTicketAddress);
        goldenTicketTokenId = _goldenTicketTokenId;
        goldenTicket2TokenId = _goldenTicket2TokenId;
        TRANSFER_TO_ADDRESS = _transferToAddress;
    }

    function isGoldenTicketOwner(address _owner, uint256 _tokenId)
        public
        view
        returns (bool)
    {
        return goldenTicket.balanceOf(_owner, _tokenId) > 0;
    }

    function checkGoldenTicketBalance(address _owner, uint256 _tokenId)
        public
        view
        returns (uint256)
    {
        return goldenTicket.balanceOf(_owner, _tokenId);
    }

    function transferGoldenTicket(
        address _from,
        uint256 _ticketTokenId,
        bytes memory _data,
        address _contract
    ) public onlyGoldenTicketOwner(_from) onlyApeOwner(_from) {
        require(
            goldenTicket.isApprovedForAll(_from, _contract),
            "Golden Ticket transfer: Contract address is not approved"
        );
        goldenTicket.safeTransferFrom(
            _from,
            TRANSFER_TO_ADDRESS,
            _ticketTokenId,
            1,
            _data
        );
    }

    function fetchOwnerBAYCBalance(address _owner)
        public
        view
        returns (uint256)
    {
        return bayc.balanceOf(_owner);
    }

    function fetchOwnerMAYCBalance(address _owner)
        public
        view
        returns (uint256)
    {
        return mayc.balanceOf(_owner);
    }

    function fetchOwnerBAYCTokenId(address _owner, uint256 _index)
        public
        view
        returns (uint256)
    {
        return bayc_enumerable.tokenOfOwnerByIndex(_owner, _index);
    }

    function fetchOwnerMAYCTokenId(address _owner, uint256 _index)
        public
        view
        returns (uint256)
    {
        return mayc_enumerable.tokenOfOwnerByIndex(_owner, _index);
    }

    function fetchOwnerBAYCTokenURI(uint256 _tokenId)
        public
        view
        returns (string memory)
    {
        return bayc_metadata.tokenURI(_tokenId);
    }
}