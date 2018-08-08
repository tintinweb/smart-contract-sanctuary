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
    mapping (uint => address) public teamIndexToOwner;

    // @dev maps team id to a price
    mapping (uint => uint) private teamIndexToPrice;

    // @dev maps address to how many tokens they own
    mapping (address => uint) private ownershipTokenCount;


    /*** DATATYPES ***/
    //@dev struct for a baller team
    struct Team {
      string name;
    }

    //@dev array which holds each team
    Team[] private ballerTeams;

    /*** PUBLIC FUNCTIONS ***/

    /**
    * @dev public function to create team, can only be called by owner of smart contract
    * @param _name the name of the team
    */

    function createTeam(string _name, uint _price) public onlyOwner {
      _createTeam(_name, this, _price);
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
    * @dev changes the name of a specific team.
    * @param _tokenId The id of the team which you want to change.
    * @param _newName The name you want to set the team to be.
    */
    function changeTeamName(uint _tokenId, string _newName) public onlyOwner {
      require(_tokenId < ballerTeams.length);
      ballerTeams[_tokenId].name = _newName;
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
    function priceOfTeam(uint _teamId) public view returns (uint price, uint teamId) {
      price = teamIndexToPrice[_teamId];
      teamId = _teamId;
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
     * @dev gets how many tokens an address owners
     * @param _owner is address of owner
     * @return numTeamsOwned how much teams he has
    */
    function balanceOf(address _owner) public view returns (uint numTeamsOwned) {
      numTeamsOwned = ownershipTokenCount[_owner];
    }

    /*
     * @dev gets total number of teams
     * @return totalNumTeams which is the number of teams
    */
    function totalSupply() public view returns (uint totalNumTeams) {
      totalNumTeams = ballerTeams.length;
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

      uint payment =  _calculatePaymentToOwner(sellingPrice);
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
    * @dev internal function to calculate how much to give to owner of contract
    * @param _sellingPrice the current price of the team
    * @return payment amount the owner gets after commission.
    */
    function _calculatePaymentToOwner(uint _sellingPrice) private pure returns (uint payment) {
      if (_sellingPrice < FIRST_PRICE_LIMIT) {
        payment = uint256(_sellingPrice.mul(100-FIRST_COMMISSION_LEVEL).div(100));
      }
      else if (_sellingPrice < SECOND_PRICE_LIMIT) {
        payment = uint256(_sellingPrice.mul(100-SECOND_COMMISSION_LEVEL).div(100));
      }
      else if (_sellingPrice < THIRD_PRICE_LIMIT) {
        payment = uint256(_sellingPrice.mul(100-THIRD_COMMISSION_LEVEL).div(100));
      }
      else {
        payment = uint256(_sellingPrice.mul(100-FOURTH_COMMISSION_LEVEL).div(100));
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