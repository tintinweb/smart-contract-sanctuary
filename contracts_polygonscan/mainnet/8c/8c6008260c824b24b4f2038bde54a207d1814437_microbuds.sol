pragma solidity 0.8.10;
import "./erc721.sol";
import "./iGoo.sol";

contract microbuds {
    mapping (uint256 => SellDetails) sellDetails;
    uint256[] tokensInContract;

    struct SellDetails {
        ERC721 nftContract;
        address payable seller;
        uint256 tokenId;
        uint256 balance;
        uint price;
        uint256 maxSell;
        uint256 amountSold;
        bool sellAll;
    }

    mapping (uint256 => bool) public tokenInContract;
    uint256 totalForSale = 0;
    uint256 totalSold = 0;
    uint256 totalMaticSeen = 0;
    uint256 totalBuddiesSeen = 0;

    uint minimumSaleAmount = 10000000000000000;

    address payable owner;
    IGoo gooContract;
    ERC721 buddyContract;
    address buddyContractAddress;

    function getStats() external view returns(uint256, uint256, uint256, uint256) {
        return (totalForSale, totalSold, totalMaticSeen, totalBuddiesSeen);
    }

    function allBuddiesOwned() external view returns(uint256[] memory) {
        return tokensInContract;
    }

    function getForSale() external view returns(uint256[] memory) { // errors
        uint256[] memory forSale;
        uint ii = 0;
        for (uint i=0; i<tokensInContract.length; i++) {
            if ((sellDetails[tokensInContract[i]].maxSell - sellDetails[tokensInContract[i]].amountSold) * sellDetails[tokensInContract[i]].price >= minimumSaleAmount) {
                forSale[ii] = tokensInContract[i];
                ii++;
            }
        }
        return forSale;
    }

    function getOfferData(uint256 tokenId) external view returns(address, uint256, uint256, uint, uint256, uint256, bool) {
        require(tokenInContract[tokenId], "Token doesn't exist in contract");
        SellDetails storage details = sellDetails[tokenId];
        return (
            details.seller,
            details.tokenId,
            details.balance,
            details.price,
            details.maxSell,
            details.amountSold,
            details.sellAll
        );
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor(address _buddyContract, address _gooContract, address payable _owner) {
        owner = _owner;
        gooContract = IGoo(_gooContract);
        buddyContract = ERC721(_buddyContract);
        buddyContractAddress = _buddyContract;
    }

    function transferOwnership(address payable _owner) external onlyOwner {
        owner = _owner;
    }

    function setGooContract(address _gooContract) external onlyOwner {
        gooContract = IGoo(_gooContract);
    }

    function setBuddyContract(address _buddyContract) external onlyOwner {
        buddyContract = ERC721(_buddyContract);
    }

    function setMinimumSaleAmount(uint _minimumSaleAmount) external onlyOwner {
        minimumSaleAmount = _minimumSaleAmount;
    }

    function onERC721Received(address, address payable from, uint256 tokenId, bytes calldata) external returns(bytes4) {
        require(msg.sender == buddyContractAddress, "What is this nft, don't want this kind :p");
        sellDetails[tokenId] = SellDetails({
            nftContract: ERC721(msg.sender),
            seller: from,
            tokenId: tokenId,
            balance: gooContract.balanceOf(tokenId),
            price: 0,
            maxSell: 0,
            amountSold: 0,
            sellAll: false
        });
        tokenInContract[tokenId] = true;
        totalBuddiesSeen++;
        tokensInContract.push(tokenId);
        return 0x150b7a02;
    }

    uint256[] tempInContract;

    function withdraw(uint256 tokenId) external {
        require(tokenInContract[tokenId], "Token doesn't exist in contract");
        SellDetails storage details = sellDetails[tokenId];

        require(msg.sender == details.seller, "Why are you here?");

        details.nftContract.safeTransferFrom(address(this), details.seller, tokenId);
        delete sellDetails[tokenId];

        for (uint i = 0; i < tokensInContract.length; i++) {
            if (tokensInContract[i] != tokenId) {
                tempInContract.push(tokensInContract[i]);
            }
        }
        tokensInContract = tempInContract;
        tempInContract = new uint256[](0);
        delete tokenInContract[tokenId];
    }

    function setPrice(uint256 tokenId, uint pricePerGoo) external {
        require(tokenInContract[tokenId], "Token doesn't exist in contract");
        SellDetails storage details = sellDetails[tokenId];

        require(msg.sender == details.seller, "Why are you here?");

        sellDetails[tokenId].price = pricePerGoo;
    }

    function setMaxSell(uint256 tokenId, uint256 maximumSale) external {
        require(tokenInContract[tokenId], "Token doesn't exist in contract");
        SellDetails storage details = sellDetails[tokenId];

        require(msg.sender == details.seller, "Why are you here?");
        totalForSale -= details.maxSell;

        sellDetails[tokenId].maxSell = maximumSale;
        sellDetails[tokenId].amountSold = 0;
        totalForSale += maximumSale;
    }

    function setPriceAndMaxSell(uint256 tokenId, uint pricePerGoo, uint256 maximumSale) external {
        require(tokenInContract[tokenId], "Token doesn't exist in contract");
        SellDetails storage details = sellDetails[tokenId];

        require(msg.sender == details.seller, "Why are you here?");
        totalForSale -= details.maxSell;

        sellDetails[tokenId].maxSell = maximumSale;
        sellDetails[tokenId].amountSold = 0;
        totalForSale += maximumSale;
        sellDetails[tokenId].price = pricePerGoo;
    }

    function sellAll(uint256 tokenId, uint yes) external {
        require(tokenInContract[tokenId], "Token doesn't exist in contract");
        SellDetails storage details = sellDetails[tokenId];

        require(msg.sender == details.seller, "Why are you here?");

        if (yes == 1) {
            sellDetails[tokenId].sellAll = true;
        } else {
            sellDetails[tokenId].sellAll = false;
        }
    }

    function reCheck(uint256 tokenId) external {
        uint256 bal = gooContract.balanceOf(tokenId);
        if (bal < sellDetails[tokenId].maxSell || sellDetails[tokenId].sellAll) {
            totalForSale -= sellDetails[tokenId].maxSell;
            sellDetails[tokenId].maxSell = bal;
            totalForSale += bal;
        }
    }

    function buy(uint256 tokenId, uint256 amount, uint256 toBuddyId) external payable { // "Execution reverted"
        require(tokenInContract[tokenId], "Token doesn't exist in contract");
        SellDetails storage details = sellDetails[tokenId];

        require(details.price != 0, "Buddy goo not on sale");
        require(details.maxSell - details.amountSold >= amount, "Not enough goo available");
        require(msg.value >= details.price * amount);

        uint256 buddyBalance = gooContract.balanceOf(tokenId);
        require(buddyBalance >= amount, "Not enough balance on buddy");

        gooContract.transfer(tokenId, toBuddyId, amount);
        (bool sent, ) = payable(details.seller).call{value: msg.value*99/100}("");
        require(sent, "Failed to send Matic to owner");
        (bool sentComm, ) = payable(owner).call{value: msg.value*1/100}("");
        require(sentComm, "Failed to send Matic commision");

        totalForSale -= amount;
        sellDetails[tokenId].amountSold += amount;
        totalSold += amount;
        totalMaticSeen += msg.value;
    }
}