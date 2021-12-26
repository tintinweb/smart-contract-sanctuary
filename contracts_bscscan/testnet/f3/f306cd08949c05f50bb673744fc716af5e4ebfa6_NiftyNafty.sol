// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './ERC721Enumerable.sol';
import './Strings.sol';
import './INiftyNafty.sol';
import './INiftyNaftyMetadata.sol';


contract NiftyNafty is ERC721Enumerable,  INiftyNafty, INiftyNaftyMetadata {
    using Strings for uint256;


    uint256 private constant startIDFrom=1;// The initial token ID
    uint256 public constant COUNT_PRESALE = 250;
    uint256 public  constant PUBLIC_MAX = 8999;
    uint256 public  constant GIFT_MAX = 1000;
    //uint256 public constant CP_MAX = 9999;
    uint256 public constant PURCHASE_LIMIT = 3;

    uint256 public saleMode = 0;//0-none, 1-presale, 2-public
    uint256 public PRICE_PRESALE = 0.05 ether;
    uint256 public PRICE_WHITE = 0.07 ether;
    uint256 public PRICE = 0.08 ether;


    bool public isActive = false;
    bool public isAllowListActive = false;
    string public proof;

    uint256 public allowListMaxMint = 3;

    uint256 public totalGiftSupply;
    uint256 public totalPublicSupply;
    uint256 public startDate;

    address[] internal _ownersList;

    mapping(address => bool) private _allowList;
    mapping(address => uint256) private _claimed;

    string private _contractURI = '';
    string private _tokenBaseURI = '';
    string private _tokenRevealedBaseURI = '';

    //---------------------------------------------------------------------------------------------------------------new
    // Used for random index assignment
    mapping(uint256 => uint256) private tokenMatrix;

    address public addressDAO;
    uint256 public constant DAO_PERCENT = 55;//  1/100
    uint256 private _allBalance;
    uint256 private _sentDAO;

    bytes32 public lastOperation;
    address public lastOwner;



    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
        _ownersList.push(_msgSender());
    }

    function updateOwnersList(address[] calldata addresses) external override onlyTwoOwners {
        _ownersList = addresses;
    }

    function onOwnersList(address addr) external view override returns (bool) {
        for(uint i = 0; i < _ownersList.length; i++) {
            if (_ownersList[i] == addr) {
                return true;
            }
        }
        return false;
    }

    function addToAllowList(address[] calldata addresses) external override onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Can't add the null address");

            _allowList[addresses[i]] = true;
            _claimed[addresses[i]] > 0 ? _claimed[addresses[i]] : 0;
        }
    }

    function onAllowList(address addr) external view override returns (bool) {
        return _allowList[addr];
    }

    function removeFromAllowList(address[] calldata addresses) external override onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Can't add the null address");
            _allowList[addresses[i]] = false;
        }
    }

    function setPricePreSale(uint256 newPrice) external  onlyOwner {
        PRICE_PRESALE = newPrice;
    }
    function setPriceWhite(uint256 newPrice) external  onlyOwner {
        PRICE_WHITE = newPrice;
    }

    function setPrice(uint256 newPrice) external override onlyOwner {
        PRICE = newPrice;
    }


    function setStartDate(uint256 newDate) external override onlyOwner {
        startDate = newDate;
    }

    function claimedBy(address owner) external view override returns (uint256){
        require(owner != address(0), "Can't check the null address");
        return _claimed[owner];
    }

    function purchase(uint256 numberOfTokens) external override payable {
        require(block.timestamp > startDate, 'Sale not started');
        require(isActive, 'Contract is not active');
        require(saleMode>0, 'The sale mode is not enabled');
        require(numberOfTokens <= PURCHASE_LIMIT, 'Would exceed PURCHASE_LIMIT');

        if (isAllowListActive) {
            require(_allowList[msg.sender], 'You are not on the Allow List');
        }

        //Mechanics of price selection
        uint256 Price=PRICE;
        if (saleMode == 1) {
            Price=PRICE_PRESALE;
        }
        else
        if(_allowList[msg.sender]){
            Price=PRICE_WHITE;
        }

        //optimistic set
        uint256 tokenCount=totalPublicSupply;
        _allBalance += msg.value;
        _claimed[msg.sender] += numberOfTokens;
        totalPublicSupply += numberOfTokens;

        //Mechanics of determining the end of the pre sale
        if (saleMode == 1) {
            require(totalPublicSupply <= COUNT_PRESALE, 'All PRESALE tokens have been minted');
            if(totalPublicSupply >= COUNT_PRESALE)
                saleMode=0;
        }

        require(_claimed[msg.sender] <= allowListMaxMint, 'Purchase exceeds max allowed');
        require(totalPublicSupply  <= PUBLIC_MAX, 'Purchase would exceed PUBLIC_MAX');
        require(Price * numberOfTokens <= msg.value, 'ETH amount is not sufficient');




        for (uint256 i = 0; i < numberOfTokens; i++) {

            uint256 tokenId = nextToken(tokenCount);
            tokenCount+=1;
            _safeMint(msg.sender, tokenId);

        }
    }

    function gift(address[] calldata to) external override onlyTwoOwners {
        require(totalGiftSupply + to.length <= GIFT_MAX, 'Not enough tokens left to gift');

        totalGiftSupply += to.length;
        for(uint256 i = 0; i < to.length; i++) {
            uint256 tokenId = totalGiftSupply + PUBLIC_MAX + 1;
            _safeMint(to[i], tokenId);
        }
    }

    function setIsActive(bool _isActive) external override onlyOwner {
        isActive = _isActive;
    }

    function setIsAllowListActive(bool _isAllowListActive) external override onlyOwner {
        isAllowListActive = _isAllowListActive;
    }
    function setSaleMode(uint256 _Mode) external onlyOwner {
        saleMode = _Mode;
    }



    function setAllowListMaxMint(uint256 maxMint) external override onlyOwner {
        allowListMaxMint = maxMint;
    }

    function setProof(string calldata proofString) external override onlyOwner {
        proof = proofString;
    }

    function withdraw() external override onlyTwoOwners {
        require(_ownersList.length > 0, "Can't withdraw where owners list empty");

        int256 balance=int256(address(this).balance)-int256(getProfitDAO());
        require(balance>0, "Can't withdraw - no funds available");
        

        uint256 part = uint256(balance) / _ownersList.length;
        if(part>0)
        {
            for(uint256 i = 0; i < _ownersList.length; i++) {
                payable(_ownersList[i]).transfer(part);
                //if(payable(_ownersList[i]).send(part)){}
            }
        }
    }

    function setContractURI(string calldata URI) external override onlyOwner {
        _contractURI = URI;
    }

    function setBaseURI(string calldata URI) external override onlyOwner {
        _tokenBaseURI = URI;
    }

    function setRevealedBaseURI(string calldata revealedBaseURI) external override onlyOwner {
        _tokenRevealedBaseURI = revealedBaseURI;
    }

    function contractURI() public view override returns (string memory) {
        return _contractURI;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), 'Token does not exist');

        string memory revealedBaseURI = _tokenRevealedBaseURI;
        return bytes(revealedBaseURI).length > 0 ?
            string(abi.encodePacked(revealedBaseURI, tokenId.toString(), '.json')) :
            _tokenBaseURI;
    }

    //---------------------------------------------------------------------------------------------------------------new

    function setDAO(address setAddress) external onlyOwner {
        require(setAddress != address(0), "Can't check the null address");
        addressDAO = setAddress;
    }

    function withdrawDAO() external onlyTwoOwners {
        uint256 ProfitDAO=getProfitDAO();

        require(ProfitDAO>0, "Can't withdraw - no funds available");
        require(addressDAO!= address(0), "Can't withdraw - DAO not set");

        //payable(addressDAO).transfer(ProfitDAO);
        (bool success,) = payable(addressDAO).call{value:ProfitDAO, gas: 100000}("");
        if(success)
        {
            _sentDAO += ProfitDAO;
        }


        
    }

    function getProfitDAO() public view returns (uint256 ProfitDAO) {
        int256 Balance = int256(_allBalance * DAO_PERCENT/100) - int256(_sentDAO);
        if(Balance>0)
            ProfitDAO=uint256(Balance);
        else
            ProfitDAO=0;
    }

    /// Get the next token ID
    /// @dev Randomly gets a new token ID and keeps track of the ones that are still available.
    /// @return the next token ID
    function nextToken(uint256 tokenCount) internal returns (uint256) {
        uint256 maxIndex = PUBLIC_MAX - tokenCount;
        uint256 random = uint256(keccak256(
                abi.encodePacked(
                    msg.sender,
                    block.coinbase,
                    block.difficulty,
                    block.gaslimit,
                    block.timestamp
                )
            )) % maxIndex;

        uint256 value = 0;
        if (tokenMatrix[random] == 0) {
            // If this matrix position is empty, set the value to the generated random number.
            value = random;
        } else {
            // Otherwise, use the previously stored number from the matrix.
            value = tokenMatrix[random];
        }

        // If the last available tokenID is still unused...
        if (tokenMatrix[maxIndex - 1] == 0) {
            // ...store that ID in the current matrix position.
            tokenMatrix[random] = maxIndex - 1;
        } else {
            // ...otherwise copy over the stored number to the current matrix position.
            tokenMatrix[random] = tokenMatrix[maxIndex - 1];
        }

        return value + startIDFrom;
    }

   
   //---------------------------------------------------------------------------------------------------------MultSig 2/N

     // MODIFIERS

    /**
    * @dev Allows to perform method by any of the owners
    */
    modifier onlyOwner {

        require(isOwner(), "onlyOwner: caller is not the owner");
        
        _;

    }

    /**
    * @dev Allows to perform method only after many owners call it with the same arguments
    */
    modifier onlyTwoOwners {

        require(isOwner(), "onlyTwoOwners: caller is not the owner");

        bytes32 operation = keccak256(msg.data);

        if(_ownersList.length == 1 || (lastOperation == operation && lastOwner != msg.sender))
        {
            resetVote();
            _;
        }
        else
        if(lastOperation != operation || lastOwner == msg.sender)
        {
            //new vote
            lastOperation = operation;
            lastOwner = msg.sender;
        }

     }



   function isOwner()internal view returns(bool) {

        for(uint256 i = 0; i < _ownersList.length; i++) 
        {
            if(_ownersList[i]==msg.sender)
            {
                return true;
            }
        }

        return false;
    }

    function resetVote()internal{

        lastOperation=0;
        lastOwner=address(0);
    }

    /**
    * @dev Allows owners to change their mind by cacnelling vote operations
    */
    function cancelVote() public onlyOwner {
        resetVote();
    }



}