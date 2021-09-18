// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// All ERC721 files are from openzeppelin as per standard, but names and locations were changed to put them in the same directory
import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract PIXLS is ERC721, Ownable {
    // Added for testing with different tokenId
    // Change/Remove after testing so that OpenSea can pull from api as expected
    using Strings for uint256;
    // could use safemath for safe division for even split of payment
    using SafeMath for uint256;
    
    // max supply
    uint256 public maxPIXLS = 100;
    // team reserve
    uint256 public teamReserved = 10;
    // .05 ether
    uint256 public price = .05 ether;
    // max per transaction
    uint256 public maxPerTx = 5;
    // whitelist amount
    uint256 public _PIXLSToBeReserved = 90;
    // total supply so far
    uint256 public totalSupply = 0;
    // time reservations open. Set to the year 99999. Changed by owner whenever time decided
    uint256 public reservationStartTime = 3093527998799;
    // time minting opens. Set to the year 99999. Changed by owner whenever time decided
    uint256 public mintingStartTime = 3093527998799;
    
    // can change to check timestamp instead of whether its live. Can be changed in case of flaws or issues tho
    bool public saleIsPaused = true;
    // once license is locked, none of the "changeable" things can be changed again
    bool public licenseLocked = false;
    // can be changed to check timestamp instead of whether reservations are live. Can be changed in case of flaws or issues tho
    bool public reservationsArePaused = true;
    
    // Set provenance once calculated, but optional
    // string public PIXLS_Provenance = "";
    
    // Base uri used to retrieve metadata by opensea 
    string public baseURI;
    
    // mapping to check allowed tokens per address
    mapping (address => uint256) allowedTokens;
    
    // could add parameters for name, symbol, max supply, and anything else
    constructor() ERC721("PIXLS", "PIXLS") {
        // Could add ptional minting for team right at deployment
    }
    
    // Reserve tokens per address and then allow them to mint at a later time
    // Can change payment to be made at minting, but that could cause reservations for people who dont have money for mint
    function reserve(uint256 amount) public payable {
        // Check that the time is right
        require(block.timestamp >= reservationStartTime, "It's not time to reserve tokens yet");
        // Check that reservations started
        require(!reservationsArePaused, "Reservations are not live");
        // Check to make sure its a user interacting with the contract, and not some bot
        require(msg.sender==tx.origin,"Only a user may interact with this contract");
        // Make sure no one reserves more tokens than are available
        require(_PIXLSToBeReserved - amount > 0, "Cannot exceed max reserved tokens");
        // Make sure no one reserves more than the limit per person
        require(amount <= maxPerTx, "Cannot reserve more than 5 token");
        // Optional check to make sure they havent already reserved tokens.
        // This would save on gas for people who might try multiple times
        require(allowedTokens[msg.sender] == 0, "You have already reserved tokens");
        // Check that sent amount is enough
        require(msg.value >= price * amount, "Ether sent is not correct");
        // reserve tokens for the person who called this function
        allowedTokens[msg.sender] = amount;
        // Decrease available reservations
        _PIXLSToBeReserved -= amount;
    }
    
    // Could change to payable
    function mint(uint256 amount) public {
        // Check to see if max supply has been reached already
        // Not needed because whitelisting deals with amount left
        // require(totalSupply <= maxPIXLS, "Sale has already ended");
        // Check to see that the time is right
        require(block.timestamp >= mintingStartTime, "It's not time to mint yet");
        // Check to see if sale is live or change to check timestamp
        require(!saleIsPaused, "Sale is not live");
        // Make sure people have the right amount reserved
        require(allowedTokens[msg.sender] >= amount, "You can't mint more tokens than you have reserved");
        // Check to see that person is only minting limited amount per transaction
        require(amount <= maxPerTx, "You cannot mint more than 1 PIXLS");
        // Minted tokens cannot exceed max supply. <= so that supply = totalpixls at the end
        // Same thing here, not needed bc whitelisting deals with that number
        // require(totalSupply + amount <= maxPIXLS - teamReserved, "Cannot exceed max number of PIXLS");
        
        // subtract minted tokens from allowedTokens
        allowedTokens[msg.sender] -= amount;
        
        // Mint requested amount
        for (uint256 i; i < amount; i++) {
            _safeMint(msg.sender, totalSupply + i);
        }
        
        // Add amount to total minted tokens so far
        totalSupply += amount;
    }
    
    /// All optional, but would require ERC721Enumerable which would cost a lot more gas for a not very useful function
    
    // As creator of COOL contract said, "Just in case ETH does some crazy stuff"
    function setPriceInEth(uint256 _newPrice) public onlyOwner {
        require(!licenseLocked, "License locked, cannot make changes anymore");
        price = _newPrice;
    }
    
    // Set reservation start time
    function setReservationStartTime(uint256 _startTime) public onlyOwner {
         require(!licenseLocked, "License locked, cannot make changes anymore");
         reservationStartTime = _startTime;
    }
    
    // Set minting start time 
    function setMintingStartTime(uint256 _startTime) public onlyOwner {
         require(!licenseLocked, "License locked, cannot make changes anymore");
         mintingStartTime = _startTime;
    }
    
    // Set base URI
    function setBaseURI(string memory _newURI) public onlyOwner {
        require(!licenseLocked, "License locked, cannot make changes anymore");
        baseURI = _newURI;
    }
    
    // Used for test because using IPFS folder for .json files
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        // Check that tokenId exists and has been minted 
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        // Check that baseURI is not an empty string
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }
    
    // Pause sale in case anything happens
    function pauseSale() public onlyOwner {
        require(!licenseLocked, "License locked, cannot make changes anymore");
        saleIsPaused = !saleIsPaused;
    }
    
    // Pause reservations in case anything happens
    function pauseReservations() public onlyOwner {
        require(!licenseLocked, "License locked, cannot make changes anymore");
        reservationsArePaused = !reservationsArePaused;
    }
    
    // Lock license so that no more owner only changes can be made
    function lockLicense() public onlyOwner {
        require(!licenseLocked, "License locked, cannot make changes anymore");
        licenseLocked = !licenseLocked;
    }
    
    // Override default baseURI function to return new URI
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
    
    // 
    // function getPrice() public view returns (uint256) {
    //     return price;
    // }
    
    // Returns number of reservations for given address
    function reservationsByOwner(address _owner) external view returns (uint256) {
        return allowedTokens[_owner];
    }
    
    // Function to mint reserved tokens
    function teamMint(address _to, uint256 _amount) external onlyOwner {
        require(_amount > 0, "Can't mint 0 tokens");
        // Check that amount doesnt exceed reserved amount
        require(_amount <= teamReserved, "Cannot exceed reserved supply");
        
        for(uint256 i; i < _amount; i++){
            _safeMint(_to, totalSupply + i);
        }
        
        // Subtract from reserved amount
        teamReserved -= _amount;
        // Add to total supply so far
        totalSupply += _amount;
    }
    
    // Send full balance to given address
    function withdraw(address _to, uint256 _amount) public onlyOwner {
        require(_amount <= address(this).balance, "Not enough money in the balance");
        (bool sent, ) = _to.call{value: _amount}("");
        require(sent, "Failed to send Ether");
    }
    
}