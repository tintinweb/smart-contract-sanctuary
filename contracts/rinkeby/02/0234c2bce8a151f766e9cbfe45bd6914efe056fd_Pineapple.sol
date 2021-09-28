/**
 *Submitted for verification at Etherscan.io on 2021-09-28
*/

// File: contracts/Context.sol



pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: contracts/Ownable.sol



pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
// File: contracts/Pineapple.sol



pragma solidity ^0.8.0;


/**
 * ---------------------------------------------------------
 * WELCOME TO THE PINEAPPLE LOTTERY
 * The Lottery Master Wishes You All The Best
 * ---------------------------------------------------------
 */
 
contract Pineapple is Ownable {
    address payable private _headPineapple;
    address payable private _devPineapple;
    
    
    uint public ticketsSold;
    bool public isSaleOpen;
    bool private _locked;
    
    uint public constant MAX_TICKETS = 2600;
    uint public constant MAX_PURCHASE = 100;
    uint256 private constant PAYMENT_GAS_LIMIT = 5000;
    uint256 public constant PRICE_PER_TICKET = 12500000 gwei;
    
    mapping (uint => address) public ticketOwner;
    mapping (address => uint) public ticketsPuchasedByAddress;
    
    bytes32 private _purchaseHash;
    uint private _randomUint;
    
    mapping (string => uint[]) public winnerList; // This mapping is to track winners. Prize Position => Ticket Number
    mapping (uint => bool) public selectedTickets; //This is to ensure ticket has not already been selected. Ticket Number => Prize position. IF !=0, then that ticket has already won something
    
    bool private _smallPrizeAllotted = false;
    bool private _mediumPrizeAllotted = false;

    
    constructor (address payable pineappleAddress, address payable devAddress, bool saleOpen) {
        _headPineapple = pineappleAddress; //Address
        _devPineapple = devAddress; //Address
        isSaleOpen = saleOpen;
        _purchaseHash = keccak256(abi.encodePacked(block.difficulty, block.timestamp, msg.sender));
        _randomUint = uint(keccak256(abi.encodePacked(block.coinbase, block.basefee, block.number)));
    }
    
    // Event functions here
    event Purchased(address indexed sender, uint[] ticketsBought);
    event Giveaway(address indexed reciever, uint[] ticketsReceived);
    event WinnerSelection(string indexed prize, uint[] ticketsSelected);
    
    // Setter functions here
    function setIsPublicSalesOpen(bool status) public onlyOwner {
        isSaleOpen = status;
    }

    
    // Prevent function from being called while still being executed.
    modifier functionLock() {
        require(!_locked, "Function Locked");
        _locked = true;
        _;
        _locked = false;
    }
    
    // Buy Ticket Function. Remove onlyOwner
    function buyTicket (uint ticketQty) public payable functionLock {
        // Check that sale is open
        require (isSaleOpen, "Sale is not open"); 
        
        // Check that ticketsSold + ticketQty is less than MAX_TICKETS
        require (ticketsSold + ticketQty <= MAX_TICKETS, "Not enough tickets remaining");
        
        // Check that ticketqty is less than  MAX_PURCHASE
        require (ticketQty <= MAX_PURCHASE, "Purchase qty > 100");
        
        // Check that amount sent is equivalent to qty x PRICE_PER_TICKET
        require (msg.value >= ticketQty*PRICE_PER_TICKET, "Insufficient payment"); 
        
        // get how many tickets have been sold
        uint currentTicket = ticketsSold + 1;
        
        // Track ticket numbers to emit event
        uint[] memory purchasedTicketsArray = new uint[](ticketQty);
        
        // create tickets in ticket owner (based on how many have already been sold)
        for (uint i = 0; i < ticketQty; i++){
            ticketOwner[currentTicket + i] = msg.sender;
            purchasedTicketsArray[i] = currentTicket + i;
        }
        
        // add tickets to ticketsPuchasedByAddress (ensure to add any existing purchase tickets)
        ticketsPuchasedByAddress[msg.sender] = ticketsPuchasedByAddress[msg.sender] + ticketQty;
        
        //add number purchased to tally of tickets sold
        ticketsSold = ticketsSold + ticketQty;
        
        // calculate a purchase purchaseHash
        _purchaseHash = bytes32(keccak256(abi.encodePacked(_purchaseHash, block.difficulty, block.timestamp, msg.sender)));
        
        // calculate amounts to transfer
        uint devAmount = (msg.value / 10000) * 2000;
        uint pineappleAmount = msg.value - devAmount;
        
        // transfer amounts to dev wallet
        (bool devSuccess, ) = _devPineapple.call{ value:devAmount, gas: PAYMENT_GAS_LIMIT }("");
        require(devSuccess, "Dev payment failed");
        
        // transfer amounts to pineapple wallet
        (bool pineappleSuccess, ) = _headPineapple.call{ value:pineappleAmount, gas: PAYMENT_GAS_LIMIT }("");
        require(pineappleSuccess, "Pineapple payment failed");
        
        emit Purchased(msg.sender, purchasedTicketsArray);

    }
    
    // Bonus ticket giveaway. Ensure that its onlyOwner
    function bonusGiveway (uint winners, address[] calldata winnerAddress, uint giveawayQty) public onlyOwner functionLock {
        // Check that ticketsSold + ticketQty is less than MAX_TICKETS
        require (ticketsSold + (winners*giveawayQty) <= MAX_TICKETS, "Not enough tickets remaining");
        
        // get how many tickets have been sold
        uint currentTicket = ticketsSold + 1;
        
        bytes32 hashGeneration = _purchaseHash;
        
        
        // create tickets in ticket recipient (based on how many have already been sold)
        for (uint i = 0; i < winners; i++){
            address giveawayAddress = winnerAddress[i];
            
            // Track ticket numbers to emit event
            uint[] memory giveawayTicketsArray = new uint[](giveawayQty);
            
            for (uint j = 0; j < giveawayQty; j++){
                ticketOwner[currentTicket] = giveawayAddress;
                giveawayTicketsArray[j] = currentTicket;
                currentTicket++;
            }
            
            // add tickets to ticketsPuchasedByAddress (ensure to add any existing purchase tickets)
            ticketsPuchasedByAddress[giveawayAddress] = ticketsPuchasedByAddress[giveawayAddress] + giveawayQty;
            
            // Emit tickets given away for this address
            emit Giveaway(giveawayAddress, giveawayTicketsArray);
            
            // calculate a purchase purchaseHash
            hashGeneration = bytes32(keccak256(abi.encodePacked(hashGeneration, block.difficulty, block.timestamp, giveawayAddress)));
        }
        
        //add number given away to tally of tickets sold
        ticketsSold = ticketsSold + (winners*giveawayQty);
        
        _purchaseHash = hashGeneration;
    }
    
    
 
    // Generic function to determine winner. Aim to be called any number of timestamp
    function drawTicket (uint randomiserNumber, bytes32 randomHash) internal view returns(uint pickedTicket, bytes32 newGeneratedRandomHash) {
        bytes32 newRandomHash;
        uint pickTicket;
        
        for (int i = 0; i < 5; i++) {
            newRandomHash = keccak256(abi.encodePacked(randomHash, block.difficulty, block.timestamp, randomiserNumber));
            pickTicket = (uint(newRandomHash)%ticketsSold)+1;
            
            if (selectedTickets[pickTicket] == false) return (pickTicket, newRandomHash);
        }
        
        return (pickTicket, newRandomHash);
    }
    
    // Calculate small prize. Ensure that it is onlyOwner
    function smallPrize (uint prizes) public onlyOwner functionLock {
        // Check that this function has not been run previously
        require (_smallPrizeAllotted != true, "Small prize winner selection already done");
        
        // Ensure that all tickets are sold out or that the public sale has been closed
        require (ticketsSold == MAX_TICKETS || isSaleOpen == false, "Tickets not sold out or sale not yet closed");
        
        // get _purchaseHash
        bytes32 generatorHash = _purchaseHash;
        
        // get a random number
        uint generatorNumber = _randomUint;
        
        //Temporary storage for winner selection
        uint[] memory selectedTicketsArray = new uint[](prizes);
        
        for (uint i = 0; i < prizes; i++){
           // Draw the winning ticket
           (uint selectedTicket, bytes32 newGeneratorHash) = drawTicket(generatorNumber, generatorHash);
           
           // store winning item in winnersList
           selectedTicketsArray[i] = selectedTicket;
           
           // store ticket in selectedTickets
           selectedTickets[selectedTicket] = true;
           
           //update generatorHash & generatorNumber
           generatorHash = newGeneratorHash;
           generatorNumber = selectedTicket;
          
        }
        
        //Store winning list on winnerList
        winnerList["Small Prize"] = selectedTicketsArray;
        
        //Emit tickets selectedTicketsArray
        emit WinnerSelection("Small Prize", selectedTicketsArray);
        
        // Update _purchaseHash hash
        _purchaseHash = generatorHash;
        _randomUint = generatorNumber;
        
        // Close smallPrizeAllotted
        _smallPrizeAllotted = true;
    }
    
    
    // Calculate medium prices
    function mediumPrize (uint prizes) public onlyOwner functionLock {
        // Check that this function has not been run previously
        require (_mediumPrizeAllotted != true, "Medium prize winner selection already done");
        
        // Ensure that all tickets are sold out or that the public sale has been closed
        require (ticketsSold == MAX_TICKETS || isSaleOpen == false, "Tickets not sold out or sale not yet closed");
        
        // Check that small prizes have been selected first
        require(_smallPrizeAllotted == true, "Small Prizes Not Yet Selected");
        
        // get _purchaseHash
        bytes32 generatorHash = _purchaseHash;
        
        // get a random number
        uint generatorNumber = _randomUint;
        
        //Temporary storage for winner selection
        uint[] memory selectedTicketsArray = new uint[](prizes);
        
        for (uint i = 0; i < prizes; i++){
           // Draw the winning ticket
           (uint selectedTicket, bytes32 newGeneratorHash) = drawTicket(generatorNumber, generatorHash);
           
           // store winning item in winnersList
           selectedTicketsArray[i] = selectedTicket;
           
           // store ticket in selectedTickets
           selectedTickets[selectedTicket] = true;
           
           //update generatorHash & generatorNumber
           generatorHash = newGeneratorHash;
           generatorNumber = selectedTicket;
          
        }
        
        //Store winning list on winnerList
        winnerList["Medium Prize"] = selectedTicketsArray;
        
        //Emit tickets selectedTicketsArray
        emit WinnerSelection("Medium Prize", selectedTicketsArray);
        
        // Update _purchaseHash hash
        _purchaseHash = generatorHash;
        _randomUint = generatorNumber;
        
        // Close smallPrizeAllotted
        _mediumPrizeAllotted = true;
    }
    
    // Winner selector function. Use this to select any winner due to bug, as well as select Big Prize and Grand Prize
    function winnerSelector(string memory prize, uint prizes) public onlyOwner functionLock {
        // Ensure that all tickets are sold out or that the public sale has been closed
        require (ticketsSold == MAX_TICKETS || isSaleOpen == false, "Tickets not sold out or sale not yet closed");
        
        // Ensure that prize position has not been allocated previously
        require (winnerList[prize].length == 0, "Winner for this place already allocated");
        
        // get _purchaseHash
        bytes32 generatorHash = _purchaseHash;
        
        // get a random number
        uint generatorNumber = _randomUint;
        
        //Temporary storage for winner selection
        uint[] memory selectedTicketsArray = new uint[](prizes);
        
        for (uint i = 0; i < prizes; i++){
           // Draw the winning ticket
           (uint selectedTicket, bytes32 newGeneratorHash) = drawTicket(generatorNumber, generatorHash);
           
           // store winning item in winnersList
           selectedTicketsArray[i] = selectedTicket;
           
           // store ticket in selectedTickets
           selectedTickets[selectedTicket] = true;
           
           //update generatorHash & generatorNumber
           generatorHash = newGeneratorHash;
           generatorNumber = selectedTicket;
          
        }
        
        //Store winning list on winnerList
        winnerList[prize] = selectedTicketsArray;
        
        //Emit tickets selectedTicketsArray
        emit WinnerSelection(prize, selectedTicketsArray);
        
        // Update _purchaseHash hash
        _purchaseHash = generatorHash;
        _randomUint = generatorNumber;
        
    }
    
}