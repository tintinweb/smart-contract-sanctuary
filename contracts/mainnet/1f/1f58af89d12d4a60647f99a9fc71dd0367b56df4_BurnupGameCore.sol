pragma solidity ^0.4.18;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


/**
 * @title Claimable
 * @dev Extension for the Ownable contract, where the ownership needs to be claimed.
 * This allows the new owner to accept the transfer.
 */
contract Claimable is Ownable {
  address public pendingOwner;

  /**
   * @dev Modifier throws if called by any account other than the pendingOwner.
   */
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

  /**
   * @dev Allows the current owner to set the pendingOwner address.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    pendingOwner = newOwner;
  }

  /**
   * @dev Allows the pendingOwner address to finalize the transfer.
   */
  function claimOwnership() onlyPendingOwner public {
    OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}


/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}


/**
 * @title Contracts that should be able to recover tokens
 * @author SylTi
 * @dev This allow a contract to recover any ERC20 token received in a contract by transferring the balance to the contract owner.
 * This will prevent any accidental loss of tokens.
 */
contract CanReclaimToken is Ownable {
  using SafeERC20 for ERC20Basic;

  /**
   * @dev Reclaim all ERC20Basic compatible tokens
   * @param token ERC20Basic The address of the token contract
   */
  function reclaimToken(ERC20Basic token) external onlyOwner {
    uint256 balance = token.balanceOf(this);
    token.safeTransfer(owner, balance);
  }

}


/// @dev Implements access control to the DWorld contract.
contract BurnupGameAccessControl is Claimable, Pausable, CanReclaimToken {
    address public cfoAddress;
    address public cooAddress;
    
    function BurnupGameAccessControl() public {
        // The creator of the contract is the initial CFO.
        cfoAddress = msg.sender;
    
        // The creator of the contract is the initial COO.
        cooAddress = msg.sender;
    }
    
    /// @dev Access modifier for CFO-only functionality.
    modifier onlyCFO() {
        require(msg.sender == cfoAddress);
        _;
    }
    
    /// @dev Access modifier for COO-only functionality.
    modifier onlyCOO() {
        require(msg.sender == cooAddress);
        _;
    }

    /// @dev Assigns a new address to act as the CFO. Only available to the current contract owner.
    /// @param _newCFO The address of the new CFO.
    function setCFO(address _newCFO) external onlyOwner {
        require(_newCFO != address(0));

        cfoAddress = _newCFO;
    }
    
    /// @dev Assigns a new address to act as the COO. Only available to the current contract owner.
    /// @param _newCOO The address of the new COO.
    function setCOO(address _newCOO) external onlyOwner {
        require(_newCOO != address(0));

        cooAddress = _newCOO;
    }
}


/// @dev Defines base data structures for DWorld.
contract BurnupGameBase is BurnupGameAccessControl {
    using SafeMath for uint256;
    
    event NextGame(uint256 rows, uint256 cols, uint256 activityTimer, uint256 unclaimedTilePrice, uint256 buyoutReferralBonusPercentage, uint256 buyoutPrizePoolPercentage, uint256 buyoutDividendPercentage, uint256 buyoutFeePercentage);
    event Start(uint256 indexed gameIndex, address indexed starter, uint256 timestamp, uint256 prizePool, uint256 rows, uint256 cols, uint256 activityTimer, uint256 unclaimedTilePrice, uint256 buyoutReferralBonusPercentage, uint256 buyoutPrizePoolPercentage, uint256 buyoutDividendPercentage, uint256 buyoutFeePercentage);
    event End(uint256 indexed gameIndex, address indexed winner, uint256 indexed identifier, uint256 x, uint256 y, uint256 timestamp, uint256 prize);
    event Buyout(uint256 indexed gameIndex, address indexed player, uint256 indexed identifier, uint256 x, uint256 y, uint256 timestamp, uint256 timeoutTimestamp, uint256 newPrice, uint256 newPrizePool);
    event SpiceUpPrizePool(uint256 indexed gameIndex, address indexed spicer, uint256 spiceAdded, string message, uint256 newPrizePool);
    
    /// @dev Struct to hold game settings.
    struct GameSettings {
        uint256 rows; // 5
        uint256 cols; // 8
        
        /// @dev Time after last trade after which tiles become inactive.
        uint256 activityTimer; // 3600
        
        /// @dev Base price for unclaimed tiles.
        uint256 unclaimedTilePrice; // 0.01 ether
        
        /// @dev Percentage of the buyout price that goes towards the referral
        /// bonus. In 1/1000th of a percentage.
        uint256 buyoutReferralBonusPercentage; // 750
        
        /// @dev Percentage of the buyout price that goes towards the prize
        /// pool. In 1/1000th of a percentage.
        uint256 buyoutPrizePoolPercentage; // 10000
    
        /// @dev Percentage of the buyout price that goes towards dividends
        /// surrounding the tile that is bought out. In in 1/1000th of
        /// a percentage.
        uint256 buyoutDividendPercentage; // 5000
    
        /// @dev Buyout fee in 1/1000th of a percentage.
        uint256 buyoutFeePercentage; // 2500
    }
    
    /// @dev Struct to hold game state.
    struct GameState {
        /// @dev Boolean indicating whether the game is live.
        bool gameStarted;
    
        /// @dev Time at which the game started.
        uint256 gameStartTimestamp;
    
        /// @dev Keep track of tile ownership.
        mapping (uint256 => address) identifierToOwner;
        
        /// @dev Keep track of the timestamp at which a tile was flipped last.
        mapping (uint256 => uint256) identifierToBuyoutTimestamp;
        
        /// @dev Current tile price.
        mapping (uint256 => uint256) identifierToBuyoutPrice;
        
        /// @dev Keep track of the tile that was flipped last.
        uint256 lastFlippedTile;
        
        /// @dev The prize pool.
        uint256 prizePool;
    }
    
    /// @notice Mapping from game indices to game settings.
    mapping (uint256 => GameSettings) public gameSettings;
    
    /// @notice Mapping from game indices to game states.
    mapping (uint256 => GameState) public gameStates;
    
    /// @notice The index of the current game.
    uint256 public gameIndex = 0;
    
    /// @dev Settings for the next game
    GameSettings public nextGameSettings;
    
    function BurnupGameBase() public {
        // Initial settings.
        setNextGameSettings(
            4, // rows
            5, // cols
            3600, // activityTimer
            0.01 ether, // unclaimedTilePrice
            750, // buyoutReferralBonusPercentage
            10000, // buyoutPrizePoolPercentage
            5000, // buyoutDividendPercentage
            2500 // buyoutFeePercentage
        );
    }
    
    /// @dev Test whether the coordinate is valid.
    /// @param x The x-part of the coordinate to test.
    /// @param y The y-part of the coordinate to test.
    function validCoordinate(uint256 x, uint256 y) public view returns(bool) {
        return x < gameSettings[gameIndex].cols && y < gameSettings[gameIndex].rows;
    }
    
    /// @dev Represent a 2D coordinate as a single uint.
    /// @param x The x-coordinate.
    /// @param y The y-coordinate.
    function coordinateToIdentifier(uint256 x, uint256 y) public view returns(uint256) {
        require(validCoordinate(x, y));
        
        return (y * gameSettings[gameIndex].cols) + x;
    }
    
    /// @dev Turn a single uint representation of a coordinate into its x and y parts.
    /// @param identifier The uint representation of a coordinate.
    /// Assumes the identifier is valid.
    function identifierToCoordinate(uint256 identifier) public view returns(uint256 x, uint256 y) {
        y = identifier / gameSettings[gameIndex].cols;
        x = identifier - (y * gameSettings[gameIndex].cols);
    }
    
    /// @notice Sets the settings for the next game.
    function setNextGameSettings(
        uint256 rows,
        uint256 cols,
        uint256 activityTimer,
        uint256 unclaimedTilePrice,
        uint256 buyoutReferralBonusPercentage,
        uint256 buyoutPrizePoolPercentage,
        uint256 buyoutDividendPercentage,
        uint256 buyoutFeePercentage
    )
        public
        onlyCFO
    {
        // Buyout dividend must be 2% at the least.
        // Buyout dividend percentage may be 12.5% at the most.
        require(2000 <= buyoutDividendPercentage && buyoutDividendPercentage <= 12500);
        
        // Buyout fee may be 5% at the most.
        require(buyoutFeePercentage <= 5000);
        
        nextGameSettings = GameSettings({
            rows: rows,
            cols: cols,
            activityTimer: activityTimer,
            unclaimedTilePrice: unclaimedTilePrice,
            buyoutReferralBonusPercentage: buyoutReferralBonusPercentage,
            buyoutPrizePoolPercentage: buyoutPrizePoolPercentage,
            buyoutDividendPercentage: buyoutDividendPercentage,
            buyoutFeePercentage: buyoutFeePercentage
        });
        
        NextGame(rows, cols, activityTimer, unclaimedTilePrice, buyoutReferralBonusPercentage, buyoutPrizePoolPercentage, buyoutDividendPercentage, buyoutFeePercentage);
    }
}


/// @dev Holds ownership functionality such as transferring.
contract BurnupGameOwnership is BurnupGameBase {
    
    event Transfer(address indexed from, address indexed to, uint256 indexed deedId);
    
    /// @notice Name of the collection of deeds (non-fungible token), as defined in ERC721Metadata.
    function name() public pure returns (string _deedName) {
        _deedName = "Burnup Tiles";
    }
    
    /// @notice Symbol of the collection of deeds (non-fungible token), as defined in ERC721Metadata.
    function symbol() public pure returns (string _deedSymbol) {
        _deedSymbol = "BURN";
    }
    
    /// @dev Checks if a given address owns a particular tile.
    /// @param _owner The address of the owner to check for.
    /// @param _identifier The tile identifier to check for.
    function _owns(address _owner, uint256 _identifier) internal view returns (bool) {
        return gameStates[gameIndex].identifierToOwner[_identifier] == _owner;
    }
    
    /// @dev Assigns ownership of a specific deed to an address.
    /// @param _from The address to transfer the deed from.
    /// @param _to The address to transfer the deed to.
    /// @param _identifier The identifier of the deed to transfer.
    function _transfer(address _from, address _to, uint256 _identifier) internal {
        // Transfer ownership.
        gameStates[gameIndex].identifierToOwner[_identifier] = _to;
        
        // Emit the transfer event.
        Transfer(_from, _to, _identifier);
    }
    
    /// @notice Returns the address currently assigned ownership of a given deed.
    /// @dev Required for ERC-721 compliance.
    function ownerOf(uint256 _identifier) external view returns (address _owner) {
        _owner = gameStates[gameIndex].identifierToOwner[_identifier];

        require(_owner != address(0));
    }
    
    /// @notice Transfer a deed to another address. If transferring to a smart
    /// contract be VERY CAREFUL to ensure that it is aware of ERC-721, or your
    /// deed may be lost forever.
    /// @param _to The address of the recipient, can be a user or contract.
    /// @param _identifier The identifier of the deed to transfer.
    /// @dev Required for ERC-721 compliance.
    function transfer(address _to, uint256 _identifier) external whenNotPaused {
        // One can only transfer their own deeds.
        require(_owns(msg.sender, _identifier));
        
        // Transfer ownership
        _transfer(msg.sender, _to, _identifier);
    }
}


/**
 * @title PullPayment
 * @dev Base contract supporting async send for pull payments. Inherit from this
 * contract and use asyncSend instead of send.
 */
contract PullPayment {
  using SafeMath for uint256;

  mapping(address => uint256) public payments;
  uint256 public totalPayments;

  /**
  * @dev withdraw accumulated balance, called by payee.
  */
  function withdrawPayments() public {
    address payee = msg.sender;
    uint256 payment = payments[payee];

    require(payment != 0);
    require(this.balance >= payment);

    totalPayments = totalPayments.sub(payment);
    payments[payee] = 0;

    assert(payee.send(payment));
  }

  /**
  * @dev Called by the payer to store the sent amount as credit to be pulled.
  * @param dest The destination address of the funds.
  * @param amount The amount to transfer.
  */
  function asyncSend(address dest, uint256 amount) internal {
    payments[dest] = payments[dest].add(amount);
    totalPayments = totalPayments.add(amount);
  }
}


/// @dev Implements access control to the BurnUp wallet.
contract BurnupHoldingAccessControl is Claimable, Pausable, CanReclaimToken {
    address public cfoAddress;
    
    /// Boolean indicating whether an address is a BurnUp Game contract.
    mapping (address => bool) burnupGame;

    function BurnupHoldingAccessControl() public {
        // The creator of the contract is the initial CFO.
        cfoAddress = msg.sender;
    }
    
    /// @dev Access modifier for CFO-only functionality.
    modifier onlyCFO() {
        require(msg.sender == cfoAddress);
        _;
    }
    
    /// @dev Access modifier for functionality that may only be called by a BurnUp game.
    modifier onlyBurnupGame() {
        // The sender must be a recognized BurnUp game address.
        require(burnupGame[msg.sender]);
        _;
    }

    /// @dev Assigns a new address to act as the CFO. Only available to the current contract owner.
    /// @param _newCFO The address of the new CFO.
    function setCFO(address _newCFO) external onlyOwner {
        require(_newCFO != address(0));

        cfoAddress = _newCFO;
    }
    
    /// @dev Add a Burnup game contract address.
    /// @param addr The address of the Burnup game contract.
    function addBurnupGame(address addr) external onlyOwner {
        burnupGame[addr] = true;
    }
    
    /// @dev Remove a Burnup game contract address.
    /// @param addr The address of the Burnup game contract.
    function removeBurnupGame(address addr) external onlyOwner {
        delete burnupGame[addr];
    }
}


/// @dev Implements the BurnUp wallet.
contract BurnupHoldingReferral is BurnupHoldingAccessControl {

    event SetReferrer(address indexed referral, address indexed referrer);

    /// Referrer of player.
    mapping (address => address) addressToReferrerAddress;
    
    /// Get the referrer of a player.
    /// @param player The address of the player to get the referrer of.
    function referrerOf(address player) public view returns (address) {
        return addressToReferrerAddress[player];
    }
    
    /// Set the referrer for a player.
    /// @param playerAddr The address of the player to set the referrer for.
    /// @param referrerAddr The address of the referrer to set.
    function _setReferrer(address playerAddr, address referrerAddr) internal {
        addressToReferrerAddress[playerAddr] = referrerAddr;
        
        // Emit event.
        SetReferrer(playerAddr, referrerAddr);
    }
}


/// @dev Implements the BurnUp wallet.
contract BurnupHoldingCore is BurnupHoldingReferral, PullPayment {
    using SafeMath for uint256;
    
    address public beneficiary1;
    address public beneficiary2;
    
    function BurnupHoldingCore(address _beneficiary1, address _beneficiary2) public {
        // The creator of the contract is the initial CFO.
        cfoAddress = msg.sender;
        
        // Set the two beneficiaries.
        beneficiary1 = _beneficiary1;
        beneficiary2 = _beneficiary2;
    }
    
    /// Pay the two beneficiaries. Sends both beneficiaries
    /// a halve of the payment.
    function payBeneficiaries() external payable {
        uint256 paymentHalve = msg.value.div(2);
        
        // We do not want a single wei to get stuck.
        uint256 otherPaymentHalve = msg.value.sub(paymentHalve);
        
        // Send payment for manual withdrawal.
        asyncSend(beneficiary1, paymentHalve);
        asyncSend(beneficiary2, otherPaymentHalve);
    }
    
    /// Sets a new address for Beneficiary one.
    /// @param addr The new address.
    function setBeneficiary1(address addr) external onlyCFO {
        beneficiary1 = addr;
    }
    
    /// Sets a new address for Beneficiary two.
    /// @param addr The new address.
    function setBeneficiary2(address addr) external onlyCFO {
        beneficiary2 = addr;
    }
    
    /// Set a referrer.
    /// @param playerAddr The address to set the referrer for.
    /// @param referrerAddr The address of the referrer to set.
    function setReferrer(address playerAddr, address referrerAddr) external onlyBurnupGame whenNotPaused returns(bool) {
        if (referrerOf(playerAddr) == address(0x0) && playerAddr != referrerAddr) {
            // Set the referrer, if no referrer has been set yet, and the player
            // and referrer are not the same address.
            _setReferrer(playerAddr, referrerAddr);
            
            // Indicate success.
            return true;
        }
        
        // Indicate failure.
        return false;
    }
}


/// @dev Holds functionality for finance related to tiles.
contract BurnupGameFinance is BurnupGameOwnership, PullPayment {
    /// Address of Burnup wallet
    BurnupHoldingCore burnupHolding;
    
    function BurnupGameFinance(address burnupHoldingAddress) public {
        burnupHolding = BurnupHoldingCore(burnupHoldingAddress);
    }
    
    /// @dev Find the _claimed_ tiles surrounding a tile.
    /// @param _deedId The identifier of the tile to get the surrounding tiles for.
    function _claimedSurroundingTiles(uint256 _deedId) internal view returns (uint256[] memory) {
        var (x, y) = identifierToCoordinate(_deedId);
        
        // Find all claimed surrounding tiles.
        uint256 claimed = 0;
        
        // Create memory buffer capable of holding all tiles.
        uint256[] memory _tiles = new uint256[](8);
        
        // Loop through all neighbors.
        for (int256 dx = -1; dx <= 1; dx++) {
            for (int256 dy = -1; dy <= 1; dy++) {
                if (dx == 0 && dy == 0) {
                    // Skip the center (i.e., the tile itself).
                    continue;
                }
                
                uint256 nx = uint256(int256(x) + dx);
                uint256 ny = uint256(int256(y) + dy);
                
                if (nx >= gameSettings[gameIndex].cols || ny >= gameSettings[gameIndex].rows) {
                    // This coordinate is outside the game bounds.
                    continue;
                }
                
                // Get the coordinates of this neighboring identifier.
                uint256 neighborIdentifier = coordinateToIdentifier(
                    nx,
                    ny
                );
                
                if (gameStates[gameIndex].identifierToOwner[neighborIdentifier] != address(0x0)) {
                    _tiles[claimed] = neighborIdentifier;
                    claimed++;
                }
            }
        }
        
        // Memory arrays cannot be resized, so copy all
        // tiles from the buffer to the tile array.
        uint256[] memory tiles = new uint256[](claimed);
        
        for (uint256 i = 0; i < claimed; i++) {
            tiles[i] = _tiles[i];
        }
        
        return tiles;
    }
    
    /// @dev Calculate the next buyout price given the current total buyout cost.
    /// @param price The current buyout price.
    function nextBuyoutPrice(uint256 price) public pure returns (uint256) {
        if (price < 0.02 ether) {
            return price.mul(200).div(100); // * 2.0
        } else {
            return price.mul(150).div(100); // * 1.5
        }
    }
    
    /// @dev Assign the proceeds of the buyout.
    function _assignBuyoutProceeds(
        address currentOwner,
        uint256[] memory claimedSurroundingTiles,
        uint256 fee,
        uint256 currentOwnerWinnings,
        uint256 totalDividendPerBeneficiary,
        uint256 referralBonus,
        uint256 prizePoolFunds
    )
        internal
    {
    
        if (currentOwner != 0x0) {
            // Send the current owner&#39;s winnings.
            _sendFunds(currentOwner, currentOwnerWinnings);
        } else {
            // There is no current owner.
            fee = fee.add(currentOwnerWinnings);
        }
        
        // Assign dividends to owners of surrounding tiles.
        for (uint256 i = 0; i < claimedSurroundingTiles.length; i++) {
            address beneficiary = gameStates[gameIndex].identifierToOwner[claimedSurroundingTiles[i]];
            _sendFunds(beneficiary, totalDividendPerBeneficiary);
        }
        
        /// Distribute the referral bonuses (if any) for an address.
        address referrer1 = burnupHolding.referrerOf(msg.sender);
        if (referrer1 != 0x0) {
            _sendFunds(referrer1, referralBonus);
        
            address referrer2 = burnupHolding.referrerOf(referrer1);
            if (referrer2 != 0x0) {
                _sendFunds(referrer2, referralBonus);
            } else {
                // There is no second-level referrer.
                fee = fee.add(referralBonus);
            }
        } else {
            // There are no first and second-level referrers.
            fee = fee.add(referralBonus.mul(2));
        }
        
        // Send the fee to the holding contract.
        burnupHolding.payBeneficiaries.value(fee)();
        
        // Increase the prize pool.
        gameStates[gameIndex].prizePool = gameStates[gameIndex].prizePool.add(prizePoolFunds);
    }
    
    /// @dev Calculate and assign the proceeds from the buyout.
    /// @param currentOwner The current owner of the tile that is being bought out.
    /// @param _deedId The identifier of the tile that is being bought out.
    /// @param claimedSurroundingTiles The surrounding tiles that have been claimed.
    function _calculateAndAssignBuyoutProceeds(address currentOwner, uint256 _deedId, uint256[] memory claimedSurroundingTiles)
        internal 
        returns (uint256 price)
    {
        // The current price.
        
        if (currentOwner == 0x0) {
            price = gameSettings[gameIndex].unclaimedTilePrice;
        } else {
            price = gameStates[gameIndex].identifierToBuyoutPrice[_deedId];
        }
        
        // Calculate the variable dividends based on the buyout price
        // (only to be paid if there are surrounding tiles).
        uint256 variableDividends = price.mul(gameSettings[gameIndex].buyoutDividendPercentage).div(100000);
        
        // Calculate fees, referral bonus, and prize pool funds.
        uint256 fee            = price.mul(gameSettings[gameIndex].buyoutFeePercentage).div(100000);
        uint256 referralBonus  = price.mul(gameSettings[gameIndex].buyoutReferralBonusPercentage).div(100000);
        uint256 prizePoolFunds = price.mul(gameSettings[gameIndex].buyoutPrizePoolPercentage).div(100000);
        
        // Calculate and assign buyout proceeds.
        uint256 currentOwnerWinnings = price.sub(fee).sub(referralBonus.mul(2)).sub(prizePoolFunds);
        
        uint256 totalDividendPerBeneficiary;
        if (claimedSurroundingTiles.length > 0) {
            // If there are surrounding tiles, variable dividend is to be paid
            // based on the buyout price.
            // Calculate the dividend per surrounding tile.
            totalDividendPerBeneficiary = variableDividends / claimedSurroundingTiles.length;
            
            currentOwnerWinnings = currentOwnerWinnings.sub(variableDividends);
            // currentOwnerWinnings = currentOwnerWinnings.sub(totalDividendPerBeneficiary * claimedSurroundingTiles.length);
        }
        
        _assignBuyoutProceeds(
            currentOwner,
            claimedSurroundingTiles,
            fee,
            currentOwnerWinnings,
            totalDividendPerBeneficiary,
            referralBonus,
            prizePoolFunds
        );
    }
    
    /// @dev Send funds to a beneficiary. If sending fails, assign
    /// funds to the beneficiary&#39;s balance for manual withdrawal.
    /// @param beneficiary The beneficiary&#39;s address to send funds to
    /// @param amount The amount to send.
    function _sendFunds(address beneficiary, uint256 amount) internal {
        if (!beneficiary.send(amount)) {
            // Failed to send funds. This can happen due to a failure in
            // fallback code of the beneficiary, or because of callstack
            // depth.
            // Send funds asynchronously for manual withdrawal by the
            // beneficiary.
            asyncSend(beneficiary, amount);
        }
    }
}


/// @dev Holds core game functionality.
contract BurnupGameCore is BurnupGameFinance {
    
    function BurnupGameCore(address burnupHoldingAddress) public BurnupGameFinance(burnupHoldingAddress) {}
    
    /// @notice Buy the current owner out of the tile.
    /// @param _gameIndex The index of the game to play on.
    /// @param startNewGameIfIdle Start a new game if the current game is idle.
    /// @param x The x-coordinate of the tile to buy.
    /// @param y The y-coordinate of the tile to buy.
    function buyout(uint256 _gameIndex, bool startNewGameIfIdle, uint256 x, uint256 y) public payable {
        // Check to see if the game should end. Process payment.
        _processGameEnd();
        
        if (!gameStates[gameIndex].gameStarted) {
            // If the game is not started, the contract must not be paused.
            require(!paused);
            
            // If the game is not started, the player must be willing to start
            // a new game.
            require(startNewGameIfIdle);
            
            // Set the price and timeout.
            gameSettings[gameIndex] = nextGameSettings;
            
            // Start the game.
            gameStates[gameIndex].gameStarted = true;
            
            // Set game started timestamp.
            gameStates[gameIndex].gameStartTimestamp = block.timestamp;
            
            // Emit start event.
            Start(gameIndex, msg.sender, block.timestamp, gameStates[gameIndex].prizePool, gameSettings[gameIndex].rows, gameSettings[gameIndex].cols, gameSettings[gameIndex].activityTimer, gameSettings[gameIndex].unclaimedTilePrice, gameSettings[gameIndex].buyoutReferralBonusPercentage, gameSettings[gameIndex].buyoutPrizePoolPercentage, gameSettings[gameIndex].buyoutDividendPercentage, gameSettings[gameIndex].buyoutFeePercentage);
        }
    
        // Check the game index.
        if (startNewGameIfIdle) {
            // The given game index must be the current game index, or the previous
            // game index.
            require(_gameIndex == gameIndex || _gameIndex.add(1) == gameIndex);
        } else {
            // Only play on the game indicated by the player.
            require(_gameIndex == gameIndex);
        }
        
        uint256 identifier = coordinateToIdentifier(x, y);
        
        address currentOwner = gameStates[gameIndex].identifierToOwner[identifier];
        
        // Tile must be unowned, or active.
        if (currentOwner == address(0x0)) {
            // Tile must still be flippable.
            require(gameStates[gameIndex].gameStartTimestamp.add(gameSettings[gameIndex].activityTimer) >= block.timestamp);
        } else {
            // Tile must be active.
            require(gameStates[gameIndex].identifierToBuyoutTimestamp[identifier].add(gameSettings[gameIndex].activityTimer) >= block.timestamp);
        }
        
        // Get existing surrounding tiles.
        uint256[] memory claimedSurroundingTiles = _claimedSurroundingTiles(identifier);
        
        // Assign the buyout proceeds and retrieve the total cost.
        uint256 price = _calculateAndAssignBuyoutProceeds(currentOwner, identifier, claimedSurroundingTiles);
        
        // Enough Ether must be supplied.
        require(msg.value >= price);
        
        // Transfer the tile.
        _transfer(currentOwner, msg.sender, identifier);
        
        // Set this tile to be the most recently bought out.
        gameStates[gameIndex].lastFlippedTile = identifier;
        
        // Calculate and set the new tile price.
        gameStates[gameIndex].identifierToBuyoutPrice[identifier] = nextBuyoutPrice(price);
        
        // Set the buyout timestamp.
        gameStates[gameIndex].identifierToBuyoutTimestamp[identifier] = block.timestamp;
        
        // Emit event
        Buyout(gameIndex, msg.sender, identifier, x, y, block.timestamp, block.timestamp + gameSettings[gameIndex].activityTimer, gameStates[gameIndex].identifierToBuyoutPrice[identifier], gameStates[gameIndex].prizePool);
        
        // Calculate the excess Ether sent.
        // msg.value is greater than or equal to price,
        // so this cannot underflow.
        uint256 excess = msg.value - price;
        
        if (excess > 0) {
            // Refund any excess Ether (not susceptible to re-entry attack, as
            // the owner is assigned before the transfer takes place).
            msg.sender.transfer(excess);
        }
    }
    
    /// @notice Buy the current owner out of the tile. Set the player&#39;s referrer.
    /// @param _gameIndex The index of the game to play on.
    /// @param startNewGameIfIdle Start a new game if the current game is idle.
    /// @param x The x-coordinate of the tile to buy.
    /// @param y The y-coordinate of the tile to buy.
    function buyoutAndSetReferrer(uint256 _gameIndex, bool startNewGameIfIdle, uint256 x, uint256 y, address referrerAddress) external payable {
        // Set the referrer.
        burnupHolding.setReferrer(msg.sender, referrerAddress);
    
        // Play.
        buyout(_gameIndex, startNewGameIfIdle, x, y);
    }
    
    /// @notice Spice up the prize pool.
    /// @param _gameIndex The index of the game to add spice to.
    /// @param message An optional message to be sent along with the spice.
    function spiceUp(uint256 _gameIndex, string message) external payable {
        // Check to see if the game should end. Process payment.
        _processGameEnd();
        
        // Check the game index.
        require(_gameIndex == gameIndex);
    
        // Game must be live or unpaused.
        require(gameStates[gameIndex].gameStarted || !paused);
        
        // Funds must be sent.
        require(msg.value > 0);
        
        // Add funds to the prize pool.
        gameStates[gameIndex].prizePool = gameStates[gameIndex].prizePool.add(msg.value);
        
        // Emit event.
        SpiceUpPrizePool(gameIndex, msg.sender, msg.value, message, gameStates[gameIndex].prizePool);
    }
    
    /// @notice End the game. Pay prize.
    function endGame() external {
        require(_processGameEnd());
    }
    
    /// @dev End the game. Pay prize.
    function _processGameEnd() internal returns(bool) {
        address currentOwner = gameStates[gameIndex].identifierToOwner[gameStates[gameIndex].lastFlippedTile];
    
        // The game must be started.
        if (!gameStates[gameIndex].gameStarted) {
            return false;
        }
    
        // The last flipped tile must be owned (i.e. there has been at
        // least one flip).
        if (currentOwner == address(0x0)) {
            return false;
        }
        
        // The last flipped tile must have become inactive.
        if (gameStates[gameIndex].identifierToBuyoutTimestamp[gameStates[gameIndex].lastFlippedTile].add(gameSettings[gameIndex].activityTimer) >= block.timestamp) {
            return false;
        }
        
        // Assign prize pool to the owner of the last-flipped tile.
        if (gameStates[gameIndex].prizePool > 0) {
            _sendFunds(currentOwner, gameStates[gameIndex].prizePool);
        }
        
        // Get coordinates of last flipped tile.
        var (x, y) = identifierToCoordinate(gameStates[gameIndex].lastFlippedTile);
        
        // Emit event.
        End(gameIndex, currentOwner, gameStates[gameIndex].lastFlippedTile, x, y, gameStates[gameIndex].identifierToBuyoutTimestamp[gameStates[gameIndex].lastFlippedTile].add(gameSettings[gameIndex].activityTimer), gameStates[gameIndex].prizePool);
        
        // Increment the game index. This won&#39;t overflow before the heat death of the universe.
        gameIndex++;
        
        // Indicate ending the game was successful.
        return true;
    }
}