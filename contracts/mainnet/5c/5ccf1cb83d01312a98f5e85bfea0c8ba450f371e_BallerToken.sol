pragma solidity ^0.4.18;

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
 * @title Destructible
 * @dev Base contract that can be destroyed by owner. All funds in contract will be sent to the owner.
 */
contract Destructible is Ownable {

  function Destructible() public payable { }

  /**
   * @dev Transfers the current balance to the owner and terminates the contract.
   */
  function destroy() onlyOwner public {
    selfdestruct(owner);
  }

  function destroyAndSend(address _recipient) onlyOwner public {
    selfdestruct(_recipient);
  }
}

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
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
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

contract BallerToken is Ownable, Destructible {
    using SafeMath for uint;
    /*** EVENTS ***/

    // @dev Fired whenever a new Baller token is created for the first time.
    event BallerCreated(uint256 tokenId, string name, address owner);

    // @dev Fired whenever a new Baller Player token is created for first time
    event BallerPlayerCreated(uint256 tokenId, string name, uint teamID, address owner);

    // @dev Fired whenever a Baller token is sold.
    event TokenSold(uint256 tokenId, uint256 oldPrice, uint256 newPrice, address prevOwner, address newOwner, string name);

    // @dev Fired whenever a team is transfered from one owner to another
    event Transfer(address from, address to, uint256 tokenId);

    /*** CONSTANTS ***/

    uint constant private DEFAULT_START_PRICE = 0.01 ether;
    uint constant private FIRST_PRICE_LIMIT =  0.5 ether;
    uint constant private SECOND_PRICE_LIMIT =  2 ether;
    uint constant private THIRD_PRICE_LIMIT =  5 ether;
    uint constant private FIRST_COMMISSION_LEVEL = 5;
    uint constant private SECOND_COMMISSION_LEVEL = 4;
    uint constant private THIRD_COMMISSION_LEVEL = 3;
    uint constant private FOURTH_COMMISSION_LEVEL = 2;
    uint constant private FIRST_LEVEL_INCREASE = 200;
    uint constant private SECOND_LEVEL_INCREASE = 135;
    uint constant private THIRD_LEVEL_INCREASE = 125;
    uint constant private FOURTH_LEVEL_INCREASE = 115;

    /*** STORAGE ***/

    // @dev maps team id to address of who owns it
    mapping (uint => address) private teamIndexToOwner;

    // @dev maps team id to a price
    mapping (uint => uint) private teamIndexToPrice;

    // @dev maps address to how many tokens they own
    mapping (address => uint) private ownershipTokenCount;


    // @dev maps player id to address of who owns it
    mapping (uint => address) public playerIndexToOwner;

    // @dev maps player id to a price
    mapping (uint => uint) private playerIndexToPrice;

    // @dev maps address to how many players they own
    mapping (address => uint) private playerOwnershipTokenCount;


    /*** DATATYPES ***/
    //@dev struct for a baller team
    struct Team {
        string name;
    }

    //@dev struct for a baller player
    struct Player {
        string name;
        uint teamID;
    }

    //@dev array which holds each team
    Team[] private ballerTeams;

    //@dev array which holds each baller
    Player[] private ballerPlayers;

    /*** PUBLIC FUNCTIONS ***/

    /**
    * @dev public function to create team, can only be called by owner of smart contract
    * @param _name the name of the team
    * @param _price the price of the team when created
    */

    function createTeam(string _name, uint _price) public onlyOwner {
        _createTeam(_name, this, _price);
    }

    /**
    * @dev public function to create a promotion team and assign it to some address
    * @param _name the name of the team
    * @param _owner the owner of the team when created
    * @param _price the price of the team when created
    */
    function createPromoTeam(string _name, address _owner, uint _price) public onlyOwner {
        _createTeam(_name, _owner, _price);
    }


    /**
    * @dev public function to create a player, can only be called by owner of smart contract
    * @param _name the name of the player
    * @param _teamID the id of the team the player belongs to
    * @param _price the price of the player when created
    */
    function createPlayer(string _name, uint _teamID, uint _price) public onlyOwner {
        _createPlayer(_name, _teamID, this, _price);
    }

    /**
    * @dev Returns all the relevant information about a specific team.
    * @param _tokenId The ID of the team.
    * @return teamName the name of the team.
    * @return currPrice what the team is currently worth.
    * @return owner address of whoever owns the team
    */
    function getTeam(uint _tokenId) public view returns(string teamName, uint currPrice, address owner) {
        Team storage currTeam = ballerTeams[_tokenId];
        teamName = currTeam.name;
        currPrice = teamIndexToPrice[_tokenId];
        owner = ownerOf(_tokenId);
    }

    /**
    * @dev Returns all relevant info about a specific player.
    * @return playerName the name of the player
    * @return currPrice what the player is currently worth.
    * @return owner address of whoever owns the player.
    * @return owningTeamID ID of team that the player plays on.
    */
    function getPlayer(uint _tokenId) public view returns(string playerName, uint currPrice, address owner, uint owningTeamID) {
        Player storage currPlayer = ballerPlayers[_tokenId];
        playerName = currPlayer.name;
        currPrice = playerIndexToPrice[_tokenId];
        owner = ownerOfPlayer(_tokenId);
        owningTeamID = currPlayer.teamID;
    }

    /**
    * @dev changes the name of a specific team.
    * @param _tokenId The id of the team which you want to change.
    * @param _newName The name you want to set the team to be.
    */
    function changeTeamName(uint _tokenId, string _newName) public onlyOwner {
        require(_tokenId < ballerTeams.length && _tokenId >= 0);
        ballerTeams[_tokenId].name = _newName;
    }

    /**
    * @dev changes name of a player.
    * @param _tokenId the id of the player which you want to change.
    * @param _newName the name you want to set the player to be.
    */
    function changePlayerName(uint _tokenId, string _newName) public onlyOwner {
        require(_tokenId < ballerPlayers.length && _tokenId >= 0);
        ballerPlayers[_tokenId].name = _newName;
    }

    /**
    * @dev changes the team the player is own
    * @param _tokenId the id of the player which you want to change.
    * @param _newTeamId the team the player will now be on.
    */

    function changePlayerTeam(uint _tokenId, uint _newTeamId) public onlyOwner {
        require(_newTeamId < ballerPlayers.length && _newTeamId >= 0);
        ballerPlayers[_tokenId].teamID = _newTeamId;
    }

    /**
    * @dev sends all ethereum in this contract to the address specified
    * @param _to address you want the eth to be sent to
    */

    function payout(address _to) public onlyOwner {
      _withdrawAmount(_to, this.balance);
    }

    /**
    * @dev Function to send some amount of ethereum out of the contract to an address
    * @param _to address the eth will be sent to
    * @param _amount amount you want to withdraw
    */
    function withdrawAmount(address _to, uint _amount) public onlyOwner {
      _withdrawAmount(_to, _amount);
    }

    /**
    * @dev Function to get price of a team
    * @param _teamId of team
    * @return price price of team
    */
    function priceOfTeam(uint _teamId) public view returns (uint price) {
      price = teamIndexToPrice[_teamId];
    }

    /**
    * @dev Function to get price of a player
    * @param _playerID id of player
    * @return price price of player
    */

    function priceOfPlayer(uint _playerID) public view returns (uint price) {
        price = playerIndexToPrice[_playerID];
    }

    /**
    * @dev Gets list of teams owned by a person.
    * @dev note: don&#39;t want to call this in the smart contract, expensive op.
    * @param _owner address of the owner
    * @return ownedTeams list of the teams owned by the owner
    */
    function getTeamsOfOwner(address _owner) public view returns (uint[] ownedTeams) {
      uint tokenCount = balanceOf(_owner);
      ownedTeams = new uint[](tokenCount);
      uint totalTeams = totalSupply();
      uint resultIndex = 0;
      if (tokenCount != 0) {
        for (uint pos = 0; pos < totalTeams; pos++) {
          address currOwner = ownerOf(pos);
          if (currOwner == _owner) {
            ownedTeams[resultIndex] = pos;
            resultIndex++;
          }
        }
      }
    }


    /**
    * @dev Gets list of players owned by a person.
    * @dev note: don&#39;t want to call this in smart contract, expensive op.
    * @param _owner address of owner
    * @return ownedPlayers list of all players owned by the address passed in
    */

    function getPlayersOfOwner(address _owner) public view returns (uint[] ownedPlayers) {
        uint numPlayersOwned = balanceOfPlayers(_owner);
        ownedPlayers = new uint[](numPlayersOwned);
        uint totalPlayers = totalPlayerSupply();
        uint resultIndex = 0;
        if (numPlayersOwned != 0) {
            for (uint pos = 0; pos < totalPlayers; pos++) {
                address currOwner = ownerOfPlayer(pos);
                if (currOwner == _owner) {
                    ownedPlayers[resultIndex] = pos;
                    resultIndex++;
                }
            }
        }
    }

    /*
     * @dev gets the address of owner of the team
     * @param _tokenId is id of the team
     * @return owner the owner of the team&#39;s address
    */
    function ownerOf(uint _tokenId) public view returns (address owner) {
      owner = teamIndexToOwner[_tokenId];
      require(owner != address(0));
    }

    /*
     * @dev gets address of owner of player
     * @param _playerId is id of the player
     * @return owner the address of the owner of the player
    */

    function ownerOfPlayer(uint _playerId) public view returns (address owner) {
        owner = playerIndexToOwner[_playerId];
        require(owner != address(0));
    }

    function teamOwnerOfPlayer(uint _playerId) public view returns (address teamOwner) {
        uint teamOwnerId = ballerPlayers[_playerId].teamID;
        teamOwner = ownerOf(teamOwnerId);
    }
    /*
     * @dev gets how many tokens an address owners
     * @param _owner is address of owner
     * @return numTeamsOwned how much teams he has
    */

    function balanceOf(address _owner) public view returns (uint numTeamsOwned) {
      numTeamsOwned = ownershipTokenCount[_owner];
    }

    /*
     * @dev gets how many players an owner owners
     * @param _owner is address of owner
     * @return numPlayersOwned how many players the owner has
    */

    function balanceOfPlayers(address _owner) public view returns (uint numPlayersOwned) {
        numPlayersOwned = playerOwnershipTokenCount[_owner];
    }

    /*
     * @dev gets total number of teams
     * @return totalNumTeams which is the number of teams
    */
    function totalSupply() public view returns (uint totalNumTeams) {
      totalNumTeams = ballerTeams.length;
    }

    /*
     * @dev gets total number of players
     * @return totalNumPlayers is the number of players
    */

    function totalPlayerSupply() public view returns (uint totalNumPlayers) {
        totalNumPlayers = ballerPlayers.length;
    }

    /**
    * @dev Allows user to buy a team from the old owner.
    * @dev Pays old owner minus commission, updates price.
    * @param _teamId id of the team they&#39;re trying to buy
    */
    function purchase(uint _teamId) public payable {
      address oldOwner = ownerOf(_teamId);
      address newOwner = msg.sender;

      uint sellingPrice = teamIndexToPrice[_teamId];

      // Making sure token owner is not sending to self
      require(oldOwner != newOwner);

      // Safety check to prevent against an unexpected 0x0 default.
      require(_addressNotNull(newOwner));

      // Making sure sent amount is greater than or equal to the sellingPrice
      require(msg.value >= sellingPrice);

      uint payment =  _calculatePaymentToOwner(sellingPrice, true);
      uint excessPayment = msg.value.sub(sellingPrice);
      uint newPrice = _calculateNewPrice(sellingPrice);
      teamIndexToPrice[_teamId] = newPrice;

      _transfer(oldOwner, newOwner, _teamId);
      // Pay old tokenOwner, unless it&#39;s the smart contract
      if (oldOwner != address(this)) {
        oldOwner.transfer(payment);
      }

      newOwner.transfer(excessPayment);
      string memory teamName = ballerTeams[_teamId].name;
      TokenSold(_teamId, sellingPrice, newPrice, oldOwner, newOwner, teamName);
    }


    /**
    * @dev allows user to buy a player from the old owner.
    * @dev pays old owner minus commission, updates price.
    * @dev commission includes house plus amount that goes to owner of team that player plays on
    * @param _playerId the id of the player they&#39;re trying to buy.
    */

    function purchasePlayer(uint _playerId) public payable {
        address oldOwner = ownerOfPlayer(_playerId);
        address newOwner = msg.sender;
        address teamOwner = teamOwnerOfPlayer(_playerId);

        uint sellingPrice = playerIndexToPrice[_playerId];

        // Making sure token owner is not sending to self
        require(oldOwner != newOwner);

        // Safety check to prevent against na unexpected 0x0 default
        require(_addressNotNull(newOwner));

        //Making sure sent amount is greater than or equal to selling price
        require(msg.value >= sellingPrice);

        bool sellingTeam = false;
        uint payment = _calculatePaymentToOwner(sellingPrice, sellingTeam);
        uint commission = msg.value.sub(payment);
        uint teamOwnerCommission = commission.div(2);
        uint excessPayment = msg.value.sub(sellingPrice);
        uint newPrice = _calculateNewPrice(sellingPrice);
        playerIndexToPrice[_playerId] = newPrice;

        _transferPlayer(oldOwner, newOwner, _playerId);

        // pay old token owner
        if (oldOwner != address(this)) {
            oldOwner.transfer(payment);
        }

        // pay team owner
        if (teamOwner != address(this)) {
            teamOwner.transfer(teamOwnerCommission);
        }

        newOwner.transfer(excessPayment);
        string memory playerName = ballerPlayers[_playerId].name;
        TokenSold(_playerId, sellingPrice, newPrice, oldOwner, newOwner, playerName);
    }


    /// Safety check on _to address to prevent against an unexpected 0x0 default.
    function _addressNotNull(address _to) private pure returns (bool) {
      return _to != address(0);
    }

    /**
    * @dev Internal function to send some amount of ethereum out of the contract to an address
    * @param _to address the eth will be sent to
    * @param _amount amount you want to withdraw
    */
    function _withdrawAmount(address _to, uint _amount) private {
      require(this.balance >= _amount);
      if (_to == address(0)) {
        owner.transfer(_amount);
      } else {
        _to.transfer(_amount);
      }
    }

    /**
    * @dev internal function to create team
    * @param _name the name of the team
    * @param _owner the owner of the team
    * @param _startingPrice the price of the team at the beginning
    */
    function _createTeam(string _name, address _owner, uint _startingPrice) private {
      Team memory currTeam = Team(_name);
      uint newTeamId = ballerTeams.push(currTeam) - 1;

      // make sure we never overflow amount of tokens possible to be created
      // 4 billion tokens...shouldn&#39;t happen.
      require(newTeamId == uint256(uint32(newTeamId)));

      BallerCreated(newTeamId, _name, _owner);
      teamIndexToPrice[newTeamId] = _startingPrice;
      _transfer(address(0), _owner, newTeamId);
    }

    /**
    * @dev internal function to create player
    * @param _name the name of the player
    * @param _teamID the id of the team the player plays on
    * @param _owner the owner of the player
    * @param _startingPrice the price of the player at creation
    */

    function _createPlayer(string _name, uint _teamID, address _owner, uint _startingPrice) private {
        Player memory currPlayer = Player(_name, _teamID);
        uint newPlayerId = ballerPlayers.push(currPlayer) - 1;

        // make sure we never overflow amount of tokens possible to be created
        // 4 billion players, shouldn&#39;t happen
        require(newPlayerId == uint256(uint32(newPlayerId)));
        BallerPlayerCreated(newPlayerId, _name, _teamID, _owner);
        playerIndexToPrice[newPlayerId] = _startingPrice;
        _transferPlayer(address(0), _owner, newPlayerId);
    }

    /**
    * @dev internal function to transfer ownership of team
    * @param _from original owner of token
    * @param _to the new owner
    * @param _teamId id of the team
    */
    function _transfer(address _from, address _to, uint _teamId) private {
      ownershipTokenCount[_to]++;
      teamIndexToOwner[_teamId] = _to;

      // Creation of new team causes _from to be 0
      if (_from != address(0)) {
        ownershipTokenCount[_from]--;
      }

      Transfer(_from, _to, _teamId);
    }


    /**
    * @dev internal function to transfer ownership of player
    * @param _from original owner of token
    * @param _to the new owner
    * @param _playerId the id of the player
    */

    function _transferPlayer(address _from, address _to, uint _playerId) private {
        playerOwnershipTokenCount[_to]++;
        playerIndexToOwner[_playerId] = _to;

        // creation of new player causes _from to be 0
        if (_from != address(0)) {
            playerOwnershipTokenCount[_from]--;
        }

        Transfer(_from, _to, _playerId);
    }

    /**
    * @dev internal function to calculate how much to give to owner of contract
    * @param _sellingPrice the current price of the team
    * @param _sellingTeam if you&#39;re selling a team or a player
    * @return payment amount the owner gets after commission.
    */
    function _calculatePaymentToOwner(uint _sellingPrice, bool _sellingTeam) private pure returns (uint payment) {
      uint multiplier = 1;
      if (! _sellingTeam) {
          multiplier = 2;
      }
      uint commissionAmount = 100;
      if (_sellingPrice < FIRST_PRICE_LIMIT) {
        commissionAmount = commissionAmount.sub(FIRST_COMMISSION_LEVEL.mul(multiplier));
        payment = uint256(_sellingPrice.mul(commissionAmount).div(100));
      }
      else if (_sellingPrice < SECOND_PRICE_LIMIT) {
        commissionAmount = commissionAmount.sub(SECOND_COMMISSION_LEVEL.mul(multiplier));

        payment = uint256(_sellingPrice.mul(commissionAmount).div(100));
      }
      else if (_sellingPrice < THIRD_PRICE_LIMIT) {
        commissionAmount = commissionAmount.sub(THIRD_COMMISSION_LEVEL.mul(multiplier));

        payment = uint256(_sellingPrice.mul(commissionAmount).div(100));
      }
      else {
        commissionAmount = commissionAmount.sub(FOURTH_COMMISSION_LEVEL.mul(multiplier));
        payment = uint256(_sellingPrice.mul(commissionAmount).div(100));
      }
    }

    /**
    * @dev internal function to calculate how much the new price is
    * @param _sellingPrice the current price of the team.
    * @return newPrice price the team will be worth after being bought.
    */
    function _calculateNewPrice(uint _sellingPrice) private pure returns (uint newPrice) {
      if (_sellingPrice < FIRST_PRICE_LIMIT) {
        newPrice = uint256(_sellingPrice.mul(FIRST_LEVEL_INCREASE).div(100));
      }
      else if (_sellingPrice < SECOND_PRICE_LIMIT) {
        newPrice = uint256(_sellingPrice.mul(SECOND_LEVEL_INCREASE).div(100));
      }
      else if (_sellingPrice < THIRD_PRICE_LIMIT) {
        newPrice = uint256(_sellingPrice.mul(THIRD_LEVEL_INCREASE).div(100));
      }
      else {
        newPrice = uint256(_sellingPrice.mul(FOURTH_LEVEL_INCREASE).div(100));
      }
    }
}