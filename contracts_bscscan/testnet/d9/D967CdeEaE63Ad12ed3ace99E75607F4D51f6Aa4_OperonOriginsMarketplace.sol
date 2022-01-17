// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./OperonOriginsNFT.sol";
import "./OperonOrigins.sol";

contract OperonOriginsMarketplace {
    event OfferingPlaced(bytes32 indexed offeringId, address indexed hostContract, address indexed offerer,  uint tokenId, uint amount, uint256 price, string uri);
    event OfferingUpdated(bytes32 indexed offeringId, uint amount, string baseCurrency, uint256 price);
    event OfferingClosed(bytes32 indexed offeringId, address indexed buyer);
    event PaymentSent (address indexed beneficiary, string currency, uint value);
    event MaintainerChanged (address indexed previousMaintainer, address indexed newMaintainer);

    address private maintainer;
    uint private offeringNonce;
    address private OROOfficialContractAddress;
    uint private constant decimal  = 18;
    
    enum offeringStatus { OPEN, CLOSED, CANCELLED }

    struct offering {
        address payable offerer;
        address hostContract;
        uint tokenId;
        uint amount;
        uint256 price;
        string baseCurrency;
        offeringStatus status; 
    }

    mapping (bytes32 => offering) offeringRegistry;
    mapping(bytes32 => uint) blockedNFTBalances;

    constructor () payable  {
        maintainer = msg.sender;
        // OROOfficialContractAddress = OROOfficialContractAddress;
    }

    modifier onlyMaintainer() {
        require(msg.sender == maintainer, "Error: This action can be performed by current maintainer only"); 
        _;
    }
    
    /**
     *   @dev listing new token for sale
     *   @param _hostContract address of the NFT owner
     *   @param _tokenId id of token
     *   @param _amount amount of token
     *   @param _price price of token
     *   @param _baseCurrency BNB or ETH
     *   @return offeringId of offering
     */
    function placeOffering(address _hostContract, uint _tokenId, uint _amount, uint256 _price, string memory _baseCurrency) external returns (bytes32 offeringId){
        require(keccak256(abi.encodePacked(_baseCurrency)) == keccak256(abi.encodePacked("ORO")) 
            || keccak256(abi.encodePacked(_baseCurrency)) == keccak256(abi.encodePacked("BNB")),
            "Error: Base price can either be in BNB or ORO");
        
        bytes32 compositeKey = keccak256(abi.encodePacked(msg.sender, _tokenId));

        OperonOriginsNFT hostContract = OperonOriginsNFT(_hostContract);
        uint tokenBalance = hostContract.balanceOf(msg.sender, _tokenId);
        require(tokenBalance - blockedNFTBalances[compositeKey] >= _amount, "Error: Not enough tokens of this type");
        
        blockedNFTBalances[compositeKey] += _amount;
        bytes32 offeringId = keccak256(abi.encodePacked(offeringNonce, _hostContract, _tokenId, _amount));
        
        offeringRegistry[offeringId].offerer = payable(msg.sender);
        offeringRegistry[offeringId].hostContract = _hostContract;
        offeringRegistry[offeringId].tokenId = _tokenId;
        offeringRegistry[offeringId].amount = _amount;
        offeringRegistry[offeringId].price = _price*(10**uint256(decimal));
        offeringRegistry[offeringId].baseCurrency = _baseCurrency;
        offeringRegistry[offeringId].status = offeringStatus.OPEN;
        offeringNonce += 1;
        
        string memory uri = hostContract.getUri(_tokenId);
        emit OfferingPlaced(
            offeringId, 
            offeringRegistry[offeringId].hostContract, 
            msg.sender, 
            offeringRegistry[offeringId].tokenId, 
            offeringRegistry[offeringId].amount, 
            offeringRegistry[offeringId].price, 
            uri
        );
        return offeringId;
    }

    /**
    *   @dev purchase the listing offering
    *   @param _offeringId identifier of offering
     */
    function cancelOffering(bytes32 _offeringId) external {
        require(msg.sender == offeringRegistry[_offeringId].offerer, "Error: You can not perform this action");
        require(offeringRegistry[_offeringId].status == offeringStatus.OPEN, "Error: Offering is closed or cancelled already");
        offeringRegistry[_offeringId].status = offeringStatus.CANCELLED;
        
        bytes32 compositeKey = keccak256(abi.encodePacked(msg.sender, offeringRegistry[_offeringId].tokenId));
        blockedNFTBalances[compositeKey] -= offeringRegistry[_offeringId].amount; 
        
        emit OfferingClosed(_offeringId, msg.sender);
    }

    /**
    *   @dev update details of the offereing
    *   @param _offeringId identifier of offering
    *   @param _amount updated number of token of offering
    *   @param _price updated price for token
    */
    function updateOffering(bytes32 _offeringId, uint _amount, uint _price) external {
        require(msg.sender == offeringRegistry[_offeringId].offerer, "Error: You can not perform this action");
        require(offeringRegistry[_offeringId].status == offeringStatus.OPEN, "Error: Offering is closed or cancelled already");
        
        offeringRegistry[_offeringId].price = _amount;
        offeringRegistry[_offeringId].price = _price*(10**uint256(decimal));
        
        bytes32 compositeKey = keccak256(abi.encodePacked(msg.sender, offeringRegistry[_offeringId].tokenId));
        blockedNFTBalances[compositeKey] -= offeringRegistry[_offeringId].amount;
        blockedNFTBalances[compositeKey] += _amount;
        
        emit OfferingUpdated(_offeringId, _amount, offeringRegistry[_offeringId].baseCurrency, _price*(10**uint256(decimal)));
    }
    
    /**
    *   @dev purchase the listing offering
    *   @param _offeringId identifier of offering
    */
    function purchaseOffering(bytes32 _offeringId) external payable {
        require(offeringRegistry[_offeringId].status == offeringStatus.OPEN, "Error: Offering is closed or cancelled already");
        require(offeringRegistry[_offeringId].offerer != msg.sender, "Error: Can not buy your own offering");
        
        // check whether required tokens is available or provided
        if(keccak256(abi.encodePacked(offeringRegistry[_offeringId].baseCurrency)) == keccak256(abi.encodePacked("ORO"))) {
            OperonOrigins tokenContract = OperonOrigins(OROOfficialContractAddress);
            uint tokenBalance = tokenContract.balanceOf(msg.sender);
            require(tokenBalance >= offeringRegistry[_offeringId].price, "Error: Not having enough tokens to buy");
            tokenContract.transfer(offeringRegistry[_offeringId].offerer, offeringRegistry[_offeringId].price);

            emit PaymentSent(offeringRegistry[_offeringId].offerer, "ORO", offeringRegistry[_offeringId].price);
        } else { 
            require(msg.value >= offeringRegistry[_offeringId].price, "Error: Not enough funds provided");
            address payable offerer = offeringRegistry[_offeringId].offerer;
            offerer.transfer(msg.value);

            emit PaymentSent(offeringRegistry[_offeringId].offerer, "BNB", offeringRegistry[_offeringId].price);
        }

        // Transfering NFT tokens and marking offering as closed
        OperonOriginsNFT hostContract = OperonOriginsNFT(offeringRegistry[_offeringId].hostContract);
        hostContract.safeTransferFrom(offeringRegistry[_offeringId].offerer, msg.sender, offeringRegistry[_offeringId].tokenId, offeringRegistry[_offeringId].amount, "");
        offeringRegistry[_offeringId].status = offeringStatus.CLOSED;
        
        bytes32 compositeKey = keccak256(abi.encodePacked(offeringRegistry[_offeringId].offerer, offeringRegistry[_offeringId].tokenId));
        blockedNFTBalances[compositeKey] -= offeringRegistry[_offeringId].amount;
        
        emit OfferingClosed(_offeringId, msg.sender);
    }


    /**
    *   @dev returns the details of the specified offfering
    *   @param _offeringId identifier of offering
    */
    function viewOfferingNFT(bytes32 _offeringId) external view returns (address offerer, address hostContract, uint tokenId, uint amount, uint price, offeringStatus status){
        return (
            offeringRegistry[_offeringId].offerer, 
            offeringRegistry[_offeringId].hostContract, 
            offeringRegistry[_offeringId].tokenId, 
            offeringRegistry[_offeringId].amount, 
            offeringRegistry[_offeringId].price, 
            offeringRegistry[_offeringId].status
        );
    }

    /**
    *   @dev changes the existing maintainer
    *   @param _newMaintainer new proposed maintainer
    */
    function changeMaintainer(address _newMaintainer) external onlyMaintainer {
        address previousMaintainer = maintainer;
        maintainer = _newMaintainer;
        emit MaintainerChanged(previousMaintainer, maintainer);
    }

    /**
    *   @dev changes the existing maintainer
    *   @param _newAddress new token contract address
    */
    function changeTokenAddress(address _newAddress) external onlyMaintainer {
        require(_newAddress == address(_newAddress), "Error: provided address is invalid");
        
        OROOfficialContractAddress = _newAddress;
    }

}