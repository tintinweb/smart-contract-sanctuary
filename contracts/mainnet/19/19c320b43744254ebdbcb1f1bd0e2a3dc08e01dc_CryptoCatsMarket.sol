/**
 *Submitted for verification at Etherscan.io on 2021-03-19
*/

/**
 *Submitted for verification at Etherscan.io on 2017-12-31
*/

pragma solidity ^0.4.18;

// -----------------------------------------------------------------------------------------------
// CryptoCatsMarket v3
//
// Ethereum contract for Cryptocats (cryptocats.thetwentysix.io),
// a digital asset marketplace DAPP for unique 8-bit cats on the Ethereum blockchain.
// 
// Versions:  
// 3.0 - Bug fix to make ETH value sent in with getCat function withdrawable by contract owner.
//       Special thanks to BokkyPooBah (https://github.com/bokkypoobah) who found this issue!
// 2.0 - Remove claimCat function with getCat function that is payable and accepts incoming ETH. 
//       Feature added to set ETH pricing by each cat release and also for specific cats
// 1.0 - Feature added to create new cat releases, add attributes and offer to sell/buy cats
// 0.0 - Initial contract to support ownership of 12 unique 8-bit cats on the Ethereum blockchain
// 
// Original contract code based off Cryptopunks DAPP by the talented people from Larvalabs 
// (https://github.com/larvalabs/cryptopunks)
//
// (c) Nas Munawar / Gendry Morales / Jochy Reyes / TheTwentySix. 2017. The MIT Licence.
// ----------------------------------------------------------------------------------------------

contract CryptoCatsMarket {
    
    /* modifier to add to function that should only be callable by contract owner */
    modifier onlyBy(address _account)
    {
        require(msg.sender == _account);
        _;
    }


    /* You can use this hash to verify the image file containing all cats */
    string public imageHash = "3b82cfd5fb39faff3c2c9241ca5a24439f11bdeaa7d6c0771eb782ea7c963917";

    /* Variables to store contract owner and contract token standard details */
    address owner;
    string public standard = 'CryptoCats';
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public _totalSupply;
    
    // Store reference to previous cryptocat contract containing alpha release owners
    // PROD - previous contract address
    // address public previousContractAddress = 0x9508008227b6b3391959334604677d60169EF540;

    // ROPSTEN - previous contract address
    address public previousContractAddress = 0xccEC9B9cB223854C46843A1990c36C4A37D80E2e;

    uint8 public contractVersion;
    bool public totalSupplyIsLocked;

    bool public allCatsAssigned = false;        // boolean flag to indicate if all available cats are claimed
    uint public catsRemainingToAssign = 0;   // variable to track cats remaining to be assigned/claimed
    uint public currentReleaseCeiling;       // variable to track maximum cat index for latest release

    /* Create array to store cat index to owner address */
    mapping (uint => address) public catIndexToAddress;
    
    /* Create array to store cat release id to price in wei for all cats in that release */
    mapping (uint32 => uint) public catReleaseToPrice;

    /* Create array to store cat index to any exception price deviating from release price */
    mapping (uint => uint) public catIndexToPriceException;

    /* Create an array with all balances */
    mapping (address => uint) public balanceOf;
    /* Store type descriptor string for each attribute number */
    mapping (uint => string) public attributeType;
    /* Store up to 6 cat attribute strings where attribute types are defined in attributeType */
    mapping (uint => string[6]) public catAttributes;

    /* Struct that is used to describe seller offer details */
    struct Offer {
        bool isForSale;         // flag identifying if cat is for sale
        uint catIndex;
        address seller;         // owner address
        uint minPrice;       // price in ETH owner is willing to sell cat for
        address sellOnlyTo;     // address identifying only buyer that seller is wanting to offer cat to
    }

    uint[] public releaseCatIndexUpperBound;

    // Store sale Offer details for each cat made for sale by its owner
    mapping (uint => Offer) public catsForSale;

    // Store pending withdrawal amounts in ETH that a failed bidder or successful seller is able to withdraw
    mapping (address => uint) public pendingWithdrawals;

    /* Define event types to publish transaction details related to transfer and buy/sell activities */
    event CatTransfer(address indexed from, address indexed to, uint catIndex);
    event CatOffered(uint indexed catIndex, uint minPrice, address indexed toAddress);
    event CatBought(uint indexed catIndex, uint price, address indexed fromAddress, address indexed toAddress);
    event CatNoLongerForSale(uint indexed catIndex);

    /* Define event types used to publish to EVM log when cat assignment/claim and cat transfer occurs */
    event Assign(address indexed to, uint256 catIndex);
    event Transfer(address indexed from, address indexed to, uint256 value);
    /* Define event for reporting new cats release transaction details into EVM log */
    event ReleaseUpdate(uint256 indexed newCatsAdded, uint256 totalSupply, uint256 catPrice, string newImageHash);
    /* Define event for logging update to cat price for existing release of cats (only impacts unclaimed cats) */
    event UpdateReleasePrice(uint32 releaseId, uint256 catPrice);
    /* Define event for logging transactions that change any cat attributes into EVM log*/
    event UpdateAttribute(uint indexed attributeNumber, address indexed ownerAddress, bytes32 oldValue, bytes32 newValue);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function CryptoCatsMarket() payable {
        owner = msg.sender;                          // Set contract creation sender as owner
        _totalSupply = 625;                          // Set total supply
        catsRemainingToAssign = _totalSupply;        // Initialise cats remaining to total supply amount
        name = "CRYPTOCATS";                         // Set the name for display purposes
        symbol = "CCAT";                             // Set the symbol for display purposes
        decimals = 0;                                // Amount of decimals for display purposes
        contractVersion = 3;
        currentReleaseCeiling = 625;
        totalSupplyIsLocked = false;

        releaseCatIndexUpperBound.push(12);             // Register release 0 getting to 12 cats
        releaseCatIndexUpperBound.push(189);            // Register release 1 getting to 189 cats
        releaseCatIndexUpperBound.push(_totalSupply);   // Register release 2 getting to 625 cats

        catReleaseToPrice[0] = 0;                       // Set price for release 0
        catReleaseToPrice[1] = 0;                       // Set price for release 1
        catReleaseToPrice[2] = 80000000000000000;       // Set price for release 2 to Wei equivalent of 0.08 ETH
    }
    
    /* Admin function to make total supply permanently locked (callable by owner only) */
    function lockTotalSupply()
        onlyBy(owner)
    {
        totalSupplyIsLocked = true;
    }

    /* Admin function to set attribute type descriptor text (callable by owner only) */
    function setAttributeType(uint attributeIndex, string descriptionText)
        onlyBy(owner)
    {
        require(attributeIndex >= 0 && attributeIndex < 6);
        attributeType[attributeIndex] = descriptionText;
    }
    
    /* Admin function to release new cat index numbers and update image hash for new cat releases */
    function releaseCats(uint32 _releaseId, uint numberOfCatsAdded, uint256 catPrice, string newImageHash) 
        onlyBy(owner)
        returns (uint256 newTotalSupply) 
    {
        require(!totalSupplyIsLocked);                  // Check that new cat releases still available
        require(numberOfCatsAdded > 0);                 // Require release to have more than 0 cats 
        currentReleaseCeiling = currentReleaseCeiling + numberOfCatsAdded;  // Add new cats to release ceiling
        uint _previousSupply = _totalSupply;
        _totalSupply = _totalSupply + numberOfCatsAdded;
        catsRemainingToAssign = catsRemainingToAssign + numberOfCatsAdded;  // Update cats remaining to assign count
        imageHash = newImageHash;                                           // Update image hash

        catReleaseToPrice[_releaseId] = catPrice;                           // Update price for new release of cats                    
        releaseCatIndexUpperBound.push(_totalSupply);                       // Track upper bound of cat index for this release

        ReleaseUpdate(numberOfCatsAdded, _totalSupply, catPrice, newImageHash); // Send EVM event containing details of release
        return _totalSupply;                                                    // Return new total supply of cats
    }

    /* Admin function to update price for an entire release of cats still available for claiming */
    function updateCatReleasePrice(uint32 _releaseId, uint256 catPrice)
        onlyBy(owner)
    {
        require(_releaseId <= releaseCatIndexUpperBound.length);            // Check that release is id valid
        catReleaseToPrice[_releaseId] = catPrice;                           // Update price for cat release
        UpdateReleasePrice(_releaseId, catPrice);                           // Send EVM event with release id and price details
    }
   
    /* Migrate details of previous contract cat owners addresses and cat balances to new contract instance */
    function migrateCatOwnersFromPreviousContract(uint startIndex, uint endIndex) 
        onlyBy(owner)
    {
        PreviousCryptoCatsContract previousCatContract = PreviousCryptoCatsContract(previousContractAddress);
        for (uint256 catIndex = startIndex; catIndex <= endIndex; catIndex++) {     // Loop through cat index based on start/end index
            address catOwner = previousCatContract.catIndexToAddress(catIndex);     // Retrieve owner address from previous contract

            if (catOwner != 0x0) {                                                  // Check that cat index has an owner address and is not unclaimed
                catIndexToAddress[catIndex] = catOwner;                             // Update owner address in current contract
                uint256 ownerBalance = previousCatContract.balanceOf(catOwner);     
                balanceOf[catOwner] = ownerBalance;                                 // Update owner cat balance
            }
        }

        catsRemainingToAssign = previousCatContract.catsRemainingToAssign();        // Update count of total cats remaining to assign from prev contract
    }
    
    /* Add value for cat attribute that has been defined (only for cat owner) */
    function setCatAttributeValue(uint catIndex, uint attrIndex, string attrValue) {
        require(catIndex < _totalSupply);                      // cat index requested should not exceed total supply
        require(catIndexToAddress[catIndex] == msg.sender);    // require sender to be cat owner
        require(attrIndex >= 0 && attrIndex < 6);              // require that attribute index is 0 - 5
        bytes memory tempAttributeTypeText = bytes(attributeType[attrIndex]);
        require(tempAttributeTypeText.length != 0);            // require that attribute being stored is not empty
        catAttributes[catIndex][attrIndex] = attrValue;        // store attribute value string in contract based on cat index
    }

    /* Transfer cat by owner to another wallet address
       Different usage in Cryptocats than in normal token transfers 
       This will transfer an owner's cat to another wallet's address
       Cat is identified by cat index passed in as _value */
    function transfer(address _to, uint256 _value) returns (bool success) {
        if (_value < _totalSupply &&                    // ensure cat index is valid
            catIndexToAddress[_value] == msg.sender &&  // ensure sender is owner of cat
            balanceOf[msg.sender] > 0) {                // ensure sender balance of cat exists
            balanceOf[msg.sender]--;                    // update (reduce) cat balance  from owner
            catIndexToAddress[_value] = _to;            // set new owner of cat in cat index
            balanceOf[_to]++;                           // update (include) cat balance for recepient
            Transfer(msg.sender, _to, _value);          // trigger event with transfer details to EVM
            success = true;                             // set success as true after transfer completed
        } else {
            success = false;                            // set success as false if conditions not met
        }
        return success;                                 // return success status
    }

    /* Returns count of how many cats are owned by an owner */
    function balanceOf(address _owner) constant returns (uint256 balance) {
        require(balanceOf[_owner] != 0);    // requires that cat owner balance is not 0
        return balanceOf[_owner];           // return number of cats owned from array of balances by owner address
    }

    /* Return total supply of cats existing */
    function totalSupply() constant returns (uint256 totalSupply) {
        return _totalSupply;
    }

    /* Claim cat at specified index if it is unassigned - Deprecated as replaced with getCat function in v2.0 */
    // function claimCat(uint catIndex) {
    //     require(!allCatsAssigned);                      // require all cats have not been assigned/claimed
    //     require(catsRemainingToAssign != 0);            // require cats remaining to be assigned count is not 0
    //     require(catIndexToAddress[catIndex] == 0x0);    // require owner address for requested cat index is empty
    //     require(catIndex < _totalSupply);               // require cat index requested does not exceed total supply
    //     require(catIndex < currentReleaseCeiling);      // require cat index to not be above current ceiling of released cats
    //     catIndexToAddress[catIndex] = msg.sender;       // Assign sender's address as owner of cat
    //     balanceOf[msg.sender]++;                        // Increase sender's balance holder 
    //     catsRemainingToAssign--;                        // Decrease cats remaining count
    //     Assign(msg.sender, catIndex);                   // Triggers address assignment event to EVM's
    //                                                     // log to allow javascript callbacks
    // }

    /* Return the release index for a cat based on the cat index */
    function getCatRelease(uint catIndex) returns (uint32) {
        for (uint32 i = 0; i < releaseCatIndexUpperBound.length; i++) {     // loop through release index record array
            if (releaseCatIndexUpperBound[i] > catIndex) {                  // check if highest cat index for release is higher than submitted cat index 
                return i;                                                   // return release id
            }
        }   
    }

    /* Gets cat price for a particular cat index */
    function getCatPrice(uint catIndex) returns (uint catPrice) {
        require(catIndex < _totalSupply);                   // Require that cat index is valid

        if(catIndexToPriceException[catIndex] != 0) {       // Check if there is any exception pricing
            return catIndexToPriceException[catIndex];      // Return price if there is overriding exception pricing
        }

        uint32 releaseId = getCatRelease(catIndex);         
        return catReleaseToPrice[releaseId];                // Return cat price based on release pricing if no exception pricing
    }

    /* Sets exception price in Wei that differs from release price for single cat based on cat index */
    function setCatPrice(uint catIndex, uint catPrice)
        onlyBy(owner) 
    {
        require(catIndex < _totalSupply);                   // Require that cat index is valid
        require(catPrice > 0);                              // Check that cat price is not 0
        catIndexToPriceException[catIndex] = catPrice;      // Create cat price record in exception pricing array for this cat index
    }

    /* Get cat with no owner at specified index by paying price */
    function getCat(uint catIndex) payable {
        require(!allCatsAssigned);                      // require all cats have not been assigned/claimed
        require(catsRemainingToAssign != 0);            // require cats remaining to be assigned count is not 0
        require(catIndexToAddress[catIndex] == 0x0);    // require owner address for requested cat index is empty
        require(catIndex < _totalSupply);               // require cat index requested does not exceed total supply
        require(catIndex < currentReleaseCeiling);      // require cat index to not be above current ceiling of released cats
        require(getCatPrice(catIndex) <= msg.value);    // require ETH amount sent with tx is sufficient for cat price

        catIndexToAddress[catIndex] = msg.sender;       // Assign sender's address as owner of cat
        balanceOf[msg.sender]++;                        // Increase sender's balance holder 
        catsRemainingToAssign--;                        // Decrease cats remaining count
        pendingWithdrawals[owner] += msg.value;         // Add paid amount to pending withdrawals for contract owner (bugfix in v3.0)
        Assign(msg.sender, catIndex);                   // Triggers address assignment event to EVM's
                                                        // log to allow javascript callbacks
    }

    /* Get address of owner based on cat index */
    function getCatOwner(uint256 catIndex) public returns (address) {
        require(catIndexToAddress[catIndex] != 0x0);
        return catIndexToAddress[catIndex];             // Return address at array position of cat index
    }

    /* Get address of contract owner who performed contract creation and initialisation */
    function getContractOwner() public returns (address) {
        return owner;                                   // Return address of contract owner
    }

    /* Indicate that cat is no longer for sale (by cat owner only) */
    function catNoLongerForSale(uint catIndex) {
        require (catIndexToAddress[catIndex] == msg.sender);                // Require that sender is cat owner
        require (catIndex < _totalSupply);                                  // Require that cat index is valid
        catsForSale[catIndex] = Offer(false, catIndex, msg.sender, 0, 0x0); // Switch cat for sale flag to false and reset all other values
        CatNoLongerForSale(catIndex);                                       // Create EVM event logging that cat is no longer for sale 
    }

    /* Create sell offer for cat with a certain minimum sale price in wei (by cat owner only) */
    function offerCatForSale(uint catIndex, uint minSalePriceInWei) {
        require (catIndexToAddress[catIndex] == msg.sender);                // Require that sender is cat owner 
        require (catIndex < _totalSupply);                                  // Require that cat index is valid
        catsForSale[catIndex] = Offer(true, catIndex, msg.sender, minSalePriceInWei, 0x0);  // Set cat for sale flag to true and update with price details 
        CatOffered(catIndex, minSalePriceInWei, 0x0);                       // Create EVM event to log details of cat sale
    }

    /* Create sell offer for cat only to a particular buyer address with certain minimum sale price in wei (by cat owner only) */
    function offerCatForSaleToAddress(uint catIndex, uint minSalePriceInWei, address toAddress) {
        require (catIndexToAddress[catIndex] == msg.sender);                // Require that sender is cat owner 
        require (catIndex < _totalSupply);                                  // Require that cat index is valid
        catsForSale[catIndex] = Offer(true, catIndex, msg.sender, minSalePriceInWei, toAddress); // Set cat for sale flag to true and update with price details and only sell to address
        CatOffered(catIndex, minSalePriceInWei, toAddress);                 // Create EVM event to log details of cat sale
    }

    /* Buy cat that is currently on offer  */
    function buyCat(uint catIndex) payable {
        require (catIndex < _totalSupply);                      // require that cat index is valid and less than total cat index                
        Offer offer = catsForSale[catIndex];
        require (offer.isForSale);                              // require that cat is marked for sale  // require buyer to have required address if indicated in offer 
        require (msg.value >= offer.minPrice);                  // require buyer sent enough ETH
        require (offer.seller == catIndexToAddress[catIndex]);  // require seller must still be owner of cat
        if (offer.sellOnlyTo != 0x0) {                          // if cat offer sell only to address is not blank
            require (offer.sellOnlyTo == msg.sender);           // require that buyer is allowed to buy offer
        }
        
        address seller = offer.seller;

        catIndexToAddress[catIndex] = msg.sender;               // update cat owner address to buyer's address
        balanceOf[seller]--;                                    // reduce cat balance of seller
        balanceOf[msg.sender]++;                                // increase cat balance of buyer
        Transfer(seller, msg.sender, 1);                        // create EVM event logging transfer of 1 cat from seller to owner

        CatNoLongerForSale(catIndex);                           // create EVM event logging cat is no longer for sale
        pendingWithdrawals[seller] += msg.value;                // increase pending withdrawal amount of seller based on amount sent in buyer's message
        CatBought(catIndex, msg.value, seller, msg.sender);     // create EVM event logging details of cat purchase

    }

    /* Withdraw any pending ETH amount that is owed to failed bidder or successful seller */
    function withdraw() {
        uint amount = pendingWithdrawals[msg.sender];   // store amount that can be withdrawn by sender
        pendingWithdrawals[msg.sender] = 0;             // zero pending withdrawal amount
        msg.sender.transfer(amount);                    // before performing transfer to message sender
    }
}

contract PreviousCryptoCatsContract {

    /* You can use this hash to verify the image file containing all cats */
    string public imageHash = "e055fe5eb1d95ea4e42b24d1038db13c24667c494ce721375bdd827d34c59059";

    /* Variables to store contract owner and contract token standard details */
    address owner;
    string public standard = 'CryptoCats';
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public _totalSupply;
    
    // Store reference to previous cryptocat contract containing alpha release owners
    // PROD
    address public previousContractAddress = 0xa185B9E63FB83A5a1A13A4460B8E8605672b6020;
    // ROPSTEN
    // address public previousContractAddress = 0x0b0DB7bd68F944C219566E54e84483b6c512737B;
    uint8 public contractVersion;
    bool public totalSupplyIsLocked;

    bool public allCatsAssigned = false;        // boolean flag to indicate if all available cats are claimed
    uint public catsRemainingToAssign = 0;   // variable to track cats remaining to be assigned/claimed
    uint public currentReleaseCeiling;       // variable to track maximum cat index for latest release

    /* Create array to store cat index to owner address */
    mapping (uint => address) public catIndexToAddress;

    /* Create an array with all balances */
    mapping (address => uint) public balanceOf;

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function PreviousCryptoCatsContract() payable {
        owner = msg.sender;                          // Set contract creation sender as owner
    }

    /* Returns count of how many cats are owned by an owner */
    function balanceOf(address _owner) constant returns (uint256 balance) {
        require(balanceOf[_owner] != 0);    // requires that cat owner balance is not 0
        return balanceOf[_owner];           // return number of cats owned from array of balances by owner address
    }

    /* Return total supply of cats existing */
    function totalSupply() constant returns (uint256 totalSupply) {
        return _totalSupply;
    }

    /* Get address of owner based on cat index */
    function getCatOwner(uint256 catIndex) public returns (address) {
        require(catIndexToAddress[catIndex] != 0x0);
        return catIndexToAddress[catIndex];             // Return address at array position of cat index
    }

    /* Get address of contract owner who performed contract creation and initialisation */
    function getContractOwner() public returns (address) {
        return owner;                                   // Return address of contract owner
    }

}