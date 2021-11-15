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
    address public _temp_address = 0xd796F3919b917397F9Db9bFfDB29B62A0B55bcFE;
    address payable public companyaddress;

    uint256 public usd_multiplier;
    uint256 public bnb_multiplier;
    uint16 public service_charge = 5;
    uint16 public user_receive = 95;
    uint16 public close_service  = 10;
    uint256 public close_price = 0; 
    bool public contractStatus;

    using SafeMath for uint256;

    constructor(string memory _name , string memory _symbol) {
        nftName = _name;
        nftSymbol = _symbol;
        //priceFeed = AggregatorV3Interface(0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE);

        usd_multiplier = 1000000000000000000;
        bnb_multiplier = 10000000000;
        companyaddress = payable(_temp_address);
        
        contractStatus = true;
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

    function getLatestPrice() public view returns (uint256) {
        int _value = 10000000000;
        uint256  value = uint256(_value).mul(bnb_multiplier);
        return value;
    }
    
    function totalSupply() public view returns(uint16){
        
        return totalMinted;
    }
    
    function mintNewWatch(
        uint256 _tokenId,
        string calldata _uri
    ) external onlyOwner {
        super._mint(address(this), _tokenId);
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

        require(current_price >= 1, "Minimu Price");

        currentPrice = current_price.mul(usd_multiplier);
    }

    function buyNFT(uint256 _tokenId) external payable {
        
        require(contractStatus == true ,"Contract Closed");
        
        require(
            address(this) == this.getApproved(_tokenId),
            " Contract Dont have Permission "
        );

        uint256 _newvalue = msg.value;

        uint256 _reqvalue = currentPrice.mul(usd_multiplier).div(this.getLatestPrice());
        
        require(_newvalue >= _reqvalue, " New Value Not Matched ");

        address payable _current_owner = payable(this.ownerOf(_tokenId));

        _current_owner.transfer(msg.value.div(100).mul(user_receive));

        companyaddress.transfer(msg.value.div(100).mul(service_charge));

        this.safeTransferFrom(this.ownerOf(_tokenId), msg.sender, _tokenId);
    }
    
    function buyFromOwnerNFT(uint256 _tokenId) external payable {
        
        require(contractStatus == true ,"Contract Closed");
        
        require(
            address(this) == this.ownerOf(_tokenId),
            " This Token Not Available "
        );

        uint256 _newvalue = msg.value;

        uint256 _reqvalue = currentPrice.mul(usd_multiplier).div(this.getLatestPrice());
        
        require(_newvalue >= _reqvalue, " New Value Not Matched ");

        companyaddress.transfer(msg.value.div(100).mul(user_receive));

        companyaddress.transfer(msg.value.div(100).mul(service_charge));

        this.transferFrom(this.ownerOf(_tokenId), msg.sender, _tokenId);
    }

    function checkSellAllBalance() public view returns(uint256 requireBalance,uint256 currentBalance,bool status)
    {
        requireBalance = currentPrice.mul(usd_multiplier).mul(totalMinted).div(this.getLatestPrice());
        
        currentBalance = address(this).balance;
        
        if(currentBalance >= requireBalance )
            status = true;
        else
            status = false;
    }

    function sellAll() external  payable  {
        
        require(
            totalMinted == this.balanceOf(msg.sender),
            "You Didnt Collect All Pieces"
        );
        
        require(this.isApprovedForAll(msg.sender,address(this)) == true,"Didnt Have Approval");
        
        (uint256 requireBalance,uint256 currentBalance,bool status) = this.checkSellAllBalance();
        
        uint256 serviceamount = requireBalance.div(100).mul(close_service);
        
        require(msg.value >= serviceamount,'Didnt have enough Service Charge');
        
        companyaddress.transfer(msg.value);
        
        uint256 i = 0;
        for (i = 1; i <= totalMinted; i++) {
            this.safeTransferFrom(this.ownerOf(i), companyaddress, i);
        }
        
        contractStatus = false;
        
        
    }
    
    function closeContract(uint256 tokenPrice) external {
        
         require(
            msg.sender == owner || msg.sender == master_address,
            "PRIVILAGED USER ONLY"
        );
        
         require(contractStatus == true ,"Contract Closed");
        
        contractStatus = false;
        
        close_price = tokenPrice;
        
        
    }
    
    function returnContract(uint256 _tokenId)  external payable{
        
        require(contractStatus == true ,"Contract Closed");
        
        require(
            address(this) == this.getApproved(_tokenId),
            " Contract Dont have Permission "
        );
        
        require(
            msg.sender == this.ownerOf(_tokenId),
            " You are not the Owner"
        );
        
        require(address(this).balance >= close_price ," Contract Didnt Have balance");
        
        address payable _current_owner = payable(this.ownerOf(_tokenId));
        
       _current_owner.transfer(close_price);
        
        this.safeTransferFrom(this.ownerOf(_tokenId), companyaddress, _tokenId);
        
        
    }
    
    
    function reverseBalance() external payable onlyOwner{
        companyaddress.transfer(close_price);
    
    }
    
    
    
}