// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./nf-token-metadata.sol";
import "./Ownable.sol";
import "./AggregatorV3Interface.sol";

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract EllufaNFT is NFTokenMetadata, Ownable {
    AggregatorV3Interface internal priceFeed;

    uint16 public totalMinted;
    uint256 public currentPrice;
    address public master_address;
    address public _temp_address = 0x706Df7e819E6e6FF0e142FA701202C7bF0A6877c;
    address payable public companyaddress;

    uint256 public usd_multiplier;
    uint256 public bnb_multiplier;
    uint16 public service_charge = 10;

    using SafeMath for uint256;

    constructor() {
        nftName = "Eluffa Watch - Frank Muller ";
        nftSymbol = "FM-001";
        // priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);

        usd_multiplier = 100000000;
        bnb_multiplier = 10000000000;
        companyaddress = payable(_temp_address);
    }

    /**function getLatestPrice() public view returns (int) {
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return price;
    }**/

    function getLatestPrice() public pure returns (uint256) {
        return 40000000000;
    }

    function mintNewWatch(
        address _to,
        uint256 _tokenId,
        string calldata _uri
    ) external onlyOwner {
        super._mint(_to, _tokenId);
        super._setTokenUri(_tokenId, _uri);
        totalMinted++;
    }

    function addMasterAddress(address _address) external onlyOwner {
        require(_address != address(0), "VALUID ADDRESS REQUIRED");

        master_address = _address;
    }

    function updatePrice(uint256 current_price) public {
        require(
            msg.sender == owner || msg.sender == master_address,
            "PRIVILAGED USER ONLY"
        );

        require(current_price >= 1000, "Minimu Price");

        currentPrice = current_price.mul(usd_multiplier);
    }

    function buyNFT(uint256 _tokenId, address payable _current_owner)
        external
        payable
    {
        require(
            address(this) == this.getApproved(_tokenId),
            " Contract Dont have Permission "
        );

        uint256 _newvalue = msg.value.div(bnb_multiplier);

        uint256 _reqvalue = currentPrice.div(getLatestPrice()).mul(
            usd_multiplier
        );

        require(_newvalue >= _reqvalue, " New Value Not Matched ");

        require(
            _current_owner == this.ownerOf(_tokenId),
            "Current Owner Wrong"
        );

        _current_owner.transfer(msg.value.div(100).mul(90));

        companyaddress.transfer(msg.value.div(100).mul(service_charge));

        this.safeTransferFrom(this.ownerOf(_tokenId), msg.sender, _tokenId);
    }
}