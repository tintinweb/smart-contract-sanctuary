pragma solidity 0.4.24;


/// @title A contract for enforcing a treasure hunt
/// @author John Fitzpatrick
/// @author Sam Pullman

contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    constructor() public {
        owner = msg.sender;
    }

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

contract TreasureHunt is Ownable {
    
    /// Cost of verifying a single location
    uint public cost;

    /// Balance of the treausure hunt reward pool
    uint public pot;

    /// @notice Balance of administrator&#39;s fee
    uint public ownersBalance;

    /// Marks the time of victory
    uint public timeOfWin;

    /// Address of the winner
    address public winner;

    /// True during the grace period (when the winner can collect the pot)
    bool public grace;

    /// List of unique location keys
    uint[] public locations;

    /// Container for submitted location info
    struct KeyLog {
        /// Location key XOR&#39;d with a user password
        uint encryptKey;
        /// Block number of submission
        uint block;
    }

    /// Record of each hunter&#39;s progress
    mapping(address => mapping(uint => KeyLog)) public hunters;
    
    /// @notice Triggered when a hunter has won and the hunt is over
    /// @param winner The address of the victor
    event WonEvent(address winner);

    /// @notice Number of locations in the hunt
    /// @dev Useful for testing, since public arrays don&#39;t expose length
    /// @return length of locations array
    function locationsLength() public view returns (uint) {
        return locations.length;
    }

    /// @notice Admin function for updating all locations
    /// @param _locations Array of location keys
    function setAllLocations(uint[] _locations) onlyOwner public {
        locations = _locations;
    }

    /// @notice Admin function to update the location at `index`
    /// @dev Throws if index is >= locations.length
    /// @param index The index of the location to update
    /// @param _location The new location
    function setLocation(uint index, uint _location) onlyOwner public {
        require(index < locations.length);
        locations[index] = _location;
    }

    /// @notice Admin function to add a location
    /// @param _location The new location
    function addLocation(uint _location) onlyOwner public {
        locations.push(_location);
    }

    /// @notice Admin function to set the price of submitting a location
    /// @param _cost The new cost
    function setCost(uint _cost) onlyOwner public {
        cost = _cost;
    }

    /// @notice Submit a location key XOR&#39;d with a password for later verification
    /// @notice The message value must be greater than `cost`
    /// @param encryptKey A location key encrypted with a user password
    /// @param locationNumber The index of the location
    function submitLocation(uint encryptKey, uint8 locationNumber) public payable {

        require(encryptKey != 0);
        require(locationNumber < locations.length);

        if (!grace) {
            require(msg.value >= cost);
            uint contribution = cost - cost / 10; // avoid integer rounding issues
            ownersBalance += cost - contribution;
            pot += contribution;
        }
        hunters[msg.sender][locationNumber] = KeyLog(encryptKey, block.number);
    }

    /// @notice Sets the message sender as the winner if they have completed the hunt
    /// @dev Location order should be enforced offline, checks here are to ward against cheaters
    /// @param decryptKeys Array of user passwords corresponding to original submissions 
    function checkWin(uint[] decryptKeys) public {
        require(!grace);
        require(decryptKeys.length == locations.length);

        uint lastBlock = 0;
        bool won = true;
        for (uint i; i < locations.length; i++) {
            
            // Make sure locations were visited in order
            require(hunters[msg.sender][i].block > lastBlock);
            lastBlock = hunters[msg.sender][i].block;

            // Skip removed locations
            if (locations[i] != 0) {
                uint storedVal = uint(keccak256(abi.encodePacked(hunters[msg.sender][i].encryptKey ^ decryptKeys[i])));
                
                won = won && (locations[i] == storedVal);
            }
        }

        require(won);

        if (won) {
            timeOfWin = now;
            winner = msg.sender;
            grace = true;
            emit WonEvent(winner);
        }
    }

    /// @notice Donate the message value to the pot
    function increasePot() public payable {
        pot += msg.value;
    }

    /// @notice Funds sent to the contract are added to the pot
    function() public payable {
        increasePot();
    }
    
    /// @notice Reset the hunt if the grace period is over
    function resetWinner() public {
        require(grace);
        require(now > timeOfWin + 30 days);
        grace = false;
        winner = 0;
        ownersBalance = 0;
        pot = address(this).balance;
    }

    /// @notice Withdrawal function for winner and admin
    function withdraw() public returns (bool) {
        uint amount;
        if (msg.sender == owner) {
            amount = ownersBalance;
            ownersBalance = 0;
        } else if (msg.sender == winner) {
            amount = pot;
            pot = 0;
        }
        msg.sender.transfer(amount);
    }

    /// @notice Admin failsafe for destroying the contract
    function kill() onlyOwner public {
        selfdestruct(owner);
    }

}