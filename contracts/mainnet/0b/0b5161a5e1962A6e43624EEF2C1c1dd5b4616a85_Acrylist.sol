// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

// import "@openzeppelin/[email protected]/token/ERC721/ERC721.sol";
// import "@openzeppelin/[email protected]/access/Ownable.sol";
import "ERC721.sol";
import "Ownable.sol";

/**
 * @dev The main smart contract which implements the blockchain code of the 
 * acrylist NFT. The contract inherits from the openzeppelin ERC721 and Ownable
 * to allow for a quick away to comply with the ERC721 standard.
 */
contract Acrylist is ERC721, Ownable {
    
    // The following variables define the maximum number of tokens which exist
    // in each of the categories. They all use the word `max` to distinguish 
    // themselves from other variables. 
    uint256 public constant maxTotalTokens = 1533;
    uint256 public constant maxWhitelistTokens = 333;
    uint256 public constant maxAirdropTokens = 200;

    // The following are counters to keep track of how many have been minted,
    // how many have been minted to the whitelist, and how many have been 
    // airdropped so far
    uint256 public currentMintedCount = 0;
    uint256 public currentWhitelistMintedCount = 0;
    uint256 public currentAirdroppedCount = 0;

    // The following define the prices of the tokens for the whitelist and the
    // fair launch
    uint256 public priceOfToken = 0.15 * (10 ** 18); // 0.15 ETH
    uint256 public priceOfWhitelistToken = 0.1 * (10 ** 18); // 0.1 ETH

    // The following variables define whether minting is currently allowed or not
    // for the fair launch and for the whitelist too
    bool public isMintingAllowed = false;
    bool public isWhitelistMintingAllowed = false;

    // The following variable is used to control whether the transfer of the NFTs
    // is allowed or not
    bool public isTransferAllowed = false;

    // The following variable defines the maximum number of tokens which can be 
    // minted in a single transaction
    uint256 public constant maxQuantity = 10;

    // The following mapping holds a map addresses and a boolen. It controls who is 
    // whitelisted and who is not. This is implemented in thsi way in order to save
    // up on gas fees. In other non-blockchain languages this should've bene a list.
    mapping(address => bool) public whitelistedAddresses;

    // A number of events which the code uses when somebody mints a token, or when 
    // the minting status changes for the whitelist or the fair launch mint
    event Mint(address receiverAddress, uint256 currentMintedCount);
    event MintStatus(bool isMintingAllowed, bool isWhitelistMintingAllowed);

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token 
     * collection.
     */
    constructor() public ERC721("Acrylist", "\u1D538") {}

    /**
     * @dev The baseURI of the tokens where the metadata is stored. 
     */
    function _baseURI() internal pure override returns (string memory) {
        return "https://gateway.pinata.cloud/ipfs/QmPvtrrnT7xCN8tikZ3TSx4zbcDm7vfBfF5YEPXhqJn9pB/";
    }

    /**
     * @dev A function used to return multiple variables from the smart contract. 
     * the main usage of this function is to initialize the website's content by
     * retrieving all of the needed variables in one call
     */
    function initData(
        address userAddress
    ) public view returns (
        uint256,    // maxTotalTokens
        uint256,    // maxWhitelistTokens
        uint256,    // maxAirdropTokens

        uint256,    // currentMintedCount
        uint256,    // currentWhitelistMintedCount
        uint256,    // currentAirdroppedCount

        uint256,    // priceOfToken
        uint256,    // priceOfWhitelistToken

        bool,       // isMintingAllowed
        bool,       // isWhitelistMintingAllowed

        uint256,    // maxQuantity

        bool        // isWhitelisted
    ) {
        bool isWhitelisted = whitelistedAddresses[userAddress];

        return (
            maxTotalTokens,
            maxWhitelistTokens,
            maxAirdropTokens,

            currentMintedCount,
            currentWhitelistMintedCount,
            currentAirdroppedCount,

            priceOfToken,
            priceOfWhitelistToken,
            
            isMintingAllowed,
            isWhitelistMintingAllowed,
            
            maxQuantity,
            
            isWhitelisted
        );
    }

    /**
     * @dev A method which is executed before the transfer of any token
     * from any address to another. This includes minting and burning of
     * tokens.
     *
     * Requirements:
     *
     * - The token transferes should be allowed by the contract.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        
        // The documentation and the code of the ERC721 openzeppelin contract
        // describe the transfer and the burning events as events where one of
        // the from or two addresses is equal to zero. Therefore, when this is
        // the case, we would like this function to be skipped. 
        address zero = address(0);
        if (from == zero || to == zero)
            return;

        // If the function has not returned, then check if the transfer of tokens
        // is currently allowed or not. 
        require(isTransferAllowed, "Tokens can not be transfered from one account to another at the current moment of time.");
    }

    /**
     * @dev A function used to mint a token to an address which has been whitelisted
     * 
     * Requirements:
     *
     * - Whitelisted minting is currently allowed
     * - The address of the sender is in the list of whitelisted addresses
     * - Total number of tokens owned + requestedQuantity does not surpass maxQuantity
     * - There are enough tokens left in total to cover this transaction
     * - There are enough tokens left in the whitelist to cover this transaction
     * - Enough Ethereum is provided in the transaction
     */
    function safeMintWhitelist(uint256 requestedQuantity) public payable {
        // Doing all of the require checks to ensure that all of the requirements are
        // met
        require(
            isWhitelistMintingAllowed,
            "The whitelisted token minting is not currently allowed"
        );
        require(
            whitelistedAddresses[msg.sender],
            "Your Ethereum address is not whitelisted"
        );
        require(
            balanceOf(msg.sender) + requestedQuantity <= maxQuantity,
            "Your balance + requestedQuantity exceeds the current allowable limits"
        );
        require(
            (requestedQuantity + currentMintedCount <= maxTotalTokens - maxAirdropTokens) && 
            (requestedQuantity + currentWhitelistMintedCount <= maxWhitelistTokens),
            "Not enough tokens are left to fullfil this transaction"
        );
        require(
            msg.value >= requestedQuantity * priceOfWhitelistToken,
            "Not enough ETH is provided in the transaction for the minting"
        );

        for(uint256 i = 0; i<requestedQuantity; i++){
            _safeMint(msg.sender, currentMintedCount);
            currentMintedCount++;
            currentWhitelistMintedCount++;
        }

        emit Mint(msg.sender, currentMintedCount);
    }

    /**
     * @dev A function used to mint a token to an address which has been whitelisted
     * 
     * Requirements:
     *
     * - Minting is currently allowed
     * - Total number of tokens owned + requestedQuantity does not surpass maxQuantity
     * - There are enough tokens left in total to cover this transaction
     * - Enough Ethereum is provided in the transaction
     */
    function safeMint(uint256 requestedQuantity) public payable {
        // Doing all of the require checks to ensure that all of the requirements are
        // met
        require(
            isMintingAllowed,
            "The token minting is not currently allowed"
        );
        require(
            balanceOf(msg.sender) + requestedQuantity <= maxQuantity,
            "Your balance + requestedQuantity exceeds the current allowable limits"
        );
        require(
            requestedQuantity + currentMintedCount <= maxTotalTokens - maxAirdropTokens,
            "Not enough tokens are left to fullfil this transaction"
        );
        require(
            msg.value >= requestedQuantity * priceOfWhitelistToken,
            "Not enough ETH is provided in the transaction for the minting"
        );

        for(uint256 i = 0; i<requestedQuantity; i++){
            _safeMint(msg.sender, currentMintedCount);
            currentMintedCount++;
        }

        emit Mint(msg.sender, currentMintedCount);
    }

    /**
     * @dev An internal function used for the airdropping of tokens. No checks are done here.
     */
    function _airdrop(
        address receiverAddress, 
        uint256 quantity
    ) internal onlyOwner {
        for (uint256 i = 0; i<quantity; i++){
            _safeMint(receiverAddress, maxTotalTokens - maxAirdropTokens + currentAirdroppedCount );
            currentAirdroppedCount++;
            currentMintedCount++;
        }
    }

    /**
     * @dev An onlyOwner function used to airdrop tokens to users' addresses
     * 
     * Requirements:
     *
     * - That there are enough tokens in general and airdrop tokens to do an airdrop
     */
    function airdrop(
        address receiverAddress, 
        uint256 quantity
    ) public onlyOwner {
        // Doing all of the require checks to ensure that all of the requirements are
        // met
        require(
            (quantity + currentAirdroppedCount <= maxAirdropTokens) && (quantity + currentMintedCount <= maxTotalTokens),
            "Not enough tokens available to use for the airdrop"
        );

        _airdrop(receiverAddress, quantity);
    }

    /**
     * @dev An onlyOwner function used to airdrop tokens multiple users all in one transaction
     * 
     * Requirements:
     *
     * - That the addresses and quantites arrays have matching lengths
     * - That the sum of the quantites requested can be fulfilled by the contract
     */
    function multipleAirdrop(
        address[] memory addresses,
        uint256[] memory quantites
    ) public onlyOwner {
        // Doing all of the require checks to ensure that all of the requirements are
        // met
        require( 
            addresses.length == quantites.length, 
            "The length of the addresses and quantites do not match"
         );

        // Summing up the quantites in order to make sure that there are enough tokens
        // to complete the entire transaction
        uint256 sum = 0;
        for (uint256 i = 0; i<quantites.length; i++)
            sum += quantites[i];

        // Check if we have enough airdrop tokens and tokens to accomodate for the sum 
        // calculated
        require(
            (currentAirdroppedCount + sum <= maxAirdropTokens) && (currentMintedCount + sum <= maxTotalTokens),
            "Not enough tokens available to use for the airdrop"
        );

        for (uint256 i = 0; i<quantites.length; i++)
            _airdrop(addresses[i], quantites[i]);
    }

    /**
     * @dev An onlyOwner function used to add people to the whitelist
     */
    function whitelist(address[] memory addresses) public onlyOwner {
        for(uint256 i = 0; i<addresses.length; i++)
            whitelistedAddresses[addresses[i]] = true;
    }

    /**
     * @dev An onlyOwner function to toggle the minting of tokens
     */
    function toggleMinting() public onlyOwner {
        isMintingAllowed = !isMintingAllowed;
        emit MintStatus(isMintingAllowed, isWhitelistMintingAllowed);
    }

    /**
     * @dev An onlyOwner function to toggle the minting of whitelisted tokens
     */
    function toggleWhitelistMinting() public onlyOwner {
        isWhitelistMintingAllowed = !isWhitelistMintingAllowed;
        emit MintStatus(isMintingAllowed, isWhitelistMintingAllowed);
    }

    /**
     * @dev An onlyOwner function to change the minting status without a toggle
     */
    function setMintingStatus(
        bool _isMintingAllowed,
        bool _isWhitelistMintingAllowed
    ) public onlyOwner {
        isMintingAllowed = _isMintingAllowed;
        isWhitelistMintingAllowed = _isWhitelistMintingAllowed;
        emit MintStatus(isMintingAllowed, isWhitelistMintingAllowed);
    }

    /**
     * @dev An only owner method which is used to allow the transfer of the NFTs 
     * between accounts.
     * @notice Notice that this is a one way street. Once the token transferes are
     * allowed, there is no code at all to disable the token transfer. The feature
     * of enabling and disabling the transfer is done so that during the period of 
     * the whitelist, people would not be allowed to sell their tokens. Only after
     * the fair launch minting has taken place are people allowed to sell their tokens
     */ 
    function enableTokenTransfer() public onlyOwner {
        isTransferAllowed = true;
    }

    /**
     * @dev An onlyOwner function to withdraw the current funds in the smart contract
     */
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);  // msg.sender has comply with "onlyOwner"
    }
}

// Note: Consider adding the whitelisted addresses when deploying the smart contract 
// as a constructor in order to reduce the gas fees by a small amount and to have a 
// single transaction which performs the deployment and the addition of the addresses
// to the whitelist