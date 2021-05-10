// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./ERC721Royalties.sol";
import "./ERC721BatchMintableStore.sol";

/**
 * @title ERC721 Printable Token
 * @dev ERC721 Token that can be be printed before being sold and not incur high gas fees
 */
contract ERC721Printable is ERC721, Royalties {
    bytes4 private constant _INTERFACE_ID_ERC721ROYALTIES = 0x46e80720;

    uint256 public totalSeries;
    address payable public MintableAddress;
    mapping(uint256 => PreMint) public PreMintData;
    mapping(uint256 => bool) public PrintSeries;
    struct PreMint {
        uint256 amount_of_tokens_left;
        uint256 price;
        address payable creator;
        string url;
    }
    event SeriesMade(
        address indexed creator,
        uint256 indexed price,
        uint256 indexed amount_made
    );
    event SeriesPurchased(
        address indexed buyer,
        uint256 indexed token_id,
        uint256 indexed price
    );
    event TransferPayment(address indexed to, uint256 indexed amount);
    event TransferFee(address indexed to, uint256 indexed fee);

    constructor(
        string memory name,
        string memory symbol,
        string memory baseURI,
        uint256 batch_amount,
        uint256 royalty_amount,
        address creator
    )
        public
        ERC721(name, symbol, baseURI, batch_amount)
        Royalties(royalty_amount, creator)
    {
        MintableAddress = msg.sender;
        _registerInterface(_INTERFACE_ID_ERC721ROYALTIES);
    }

    function _createPrintSeries(
        uint256 _totalAmount,
        uint256 _price,
        string memory _url
    ) internal returns (bool) {
        totalSeries = totalSeries.add(1);
        PrintSeries[totalSeries] = true;

        PreMintData[totalSeries].amount_of_tokens_left = _totalAmount;
        PreMintData[totalSeries].price = _price;
        PreMintData[totalSeries].url = _url;
        PreMintData[totalSeries].creator = msg.sender;

        emit SeriesMade(msg.sender, _price, _totalAmount);
        return true;
    }

    function createPrintSeries(
        uint256 _amount,
        uint256 _price,
        string memory _url
    ) public returns (bool) {
        return _createPrintSeries(_amount, _price, _url);
    }

    function mintSeries(uint256 _seriesID, address _to)
        public
        payable
        returns (bool)
    {
        require(PrintSeries[_seriesID], "Not a valid series");
        require(
            PreMintData[_seriesID].amount_of_tokens_left >= 1,
            "Series is SOLD OUT!"
        );
        require(
            msg.value >= PreMintData[_seriesID].price,
            "Invalid amount sent to purchase this NFT"
        );
        //get total supply
        //change the amount of tokens left to be one less
        PreMintData[_seriesID].amount_of_tokens_left = PreMintData[_seriesID]
            .amount_of_tokens_left
            .sub(1);
        //check if tokens left are 0 if so, set to sold out
        if (PreMintData[_seriesID].amount_of_tokens_left == 0) {
            PrintSeries[_seriesID] = false;
        }
        emit SeriesPurchased(msg.sender, super.totalSupply().add(1), msg.value);
        //mint tokens and send to buyer
        super._mintWithURI(_to, PreMintData[_seriesID].url);
        //calculate fees to be removed
        uint256 fee = (msg.value.mul(5)).div(100);
        uint256 creatorsPayment = msg.value.sub(fee);
        //transfer payment to creator's address
        PreMintData[_seriesID].creator.transfer(creatorsPayment);
        require(address(this).balance >= fee, "Not enough balance to send fee");
        emit TransferPayment(PreMintData[_seriesID].creator, creatorsPayment);
        MintableAddress.transfer(fee);
        emit TransferFee(MintableAddress, fee);
        return true;
    }
}