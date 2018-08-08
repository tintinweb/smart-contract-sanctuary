pragma solidity ^0.4.11;


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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
  function Ownable() {
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
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}














/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

}







/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}



/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  /**
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   */
  function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}




/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}



contract NoteToken is StandardToken, Ownable {
    using SafeMath for uint256;

    string public constant NAME = "Note Token";
    string public constant SYMBOL = "NOTE";
    uint256 public tokensLeft;
    uint256 public endTime;
    address compositionAddress;

    modifier beforeEndTime() {
        require(now < endTime);
        _;
    }

    modifier afterEndTime() {
        require(now > endTime);
        _;
    }
    event TokensBought(uint256 _num, uint256 _tokensLeft);
    event TokensReturned(uint256 _num, uint256 _tokensLeft);

    function NoteToken(uint256 _endTime) public {
        totalSupply = 5000;
        tokensLeft = totalSupply;

        endTime = _endTime;
    }

    function purchaseNotes(uint256 _numNotes) beforeEndTime() external payable {
        require(_numNotes <= 100);
        require(_numNotes <= tokensLeft);
        require(_numNotes == (msg.value / 0.001 ether));

        balances[msg.sender] = balances[msg.sender].add(_numNotes);
        tokensLeft = tokensLeft.sub(_numNotes);

        emit TokensBought(_numNotes, tokensLeft);
    }

    function returnNotes(uint256 _numNotes) beforeEndTime() external {
        require(_numNotes <= balances[msg.sender]);
        
        uint256 refund = _numNotes * 0.001 ether;
        balances[msg.sender] = balances[msg.sender].sub(_numNotes);
        tokensLeft = tokensLeft.add(_numNotes);
        msg.sender.transfer(refund);
        emit TokensReturned(_numNotes, tokensLeft);
    }

    function setCompositionAddress(address _compositionAddress) onlyOwner() external {
        require(compositionAddress == address(0));

        compositionAddress = _compositionAddress;
    }

    function transferToComposition(address _from, uint256 _value) beforeEndTime() public returns (bool) {
        require(msg.sender == compositionAddress);
        require(_value <= balances[_from]);

        balances[_from] = balances[_from].sub(_value);
        balances[compositionAddress] = balances[compositionAddress].add(_value);
        Transfer(_from, compositionAddress, _value);
        return true;
    }

    function end() afterEndTime() external {
        selfdestruct(compositionAddress);
    }
}


contract CompositionPart {
    //note struct, holds pitch and place
    struct noteId {
        uint256 pitch;
        uint256 place;
    }

    //token contract
    NoteToken notes;

    //2d graph of notes and places, represents midi values 0-127 and position,
    bool[1000][128] composition;
    //2d graph representing who owns a placed note
    address[1000][128] composers;
    
    //time when composing freezes
    uint endTime;

    //keeps track of notes placed by an address
    mapping (address => noteId[]) ownedNotes;

    modifier beforeEndTime() {
        require(now < endTime);
        _;
    }

    modifier afterEndTime() {
        require(now > endTime);
        _;
    }

    modifier placeValidNotes(uint[] _pitches, uint[] _places, uint256 _numNotes) {
        require(_pitches.length == _places.length);
        require(_pitches.length <= 10);
        require(_pitches.length == _numNotes);

        for (uint256 i = 0; i < _pitches.length; i++) {
            if (_pitches[i] > 127 || _places[i] > 999) {
                revert();
            } else if (composition[_pitches[i]][_places[i]]) {
                revert();
            } 
        }
        _;
    }

    modifier removeValidNotes(uint[] _pitches, uint[] _places, uint256 _numNotes) {
        require(_pitches.length == _places.length);
        require(_pitches.length <= 10);
        require(_pitches.length == _numNotes);

        for (uint256 i = 0; i < _pitches.length; i++) {
            if (_pitches[i] > 127 || _places[i] > 999) {
                revert();
            } else if (composers[_pitches[i]][_places[i]] != msg.sender) {
                revert();
            }
        }
        _;
    }

    event NotePlaced(address composer, uint pitch, uint place);
    event NoteRemoved(address composer, uint pitch, uint place);

    //constructor
    function CompositionPart(uint _endTime, address _noteToken) public {
        endTime = _endTime;
        notes = NoteToken(_noteToken);
    }

    //places up to 10 valid notes in the composition
    function placeNotes(uint256[] _pitches, uint256[] _places, uint256 _numNotes) beforeEndTime() placeValidNotes(_pitches, _places, _numNotes) external {
        require(notes.transferToComposition(msg.sender, _numNotes));

        for (uint256 i = 0; i < _pitches.length; i++) {
            noteId memory note;
            note.pitch = _pitches[i];
            note.place = _places[i];

            ownedNotes[msg.sender].push(note);

            composition[_pitches[i]][_places[i]] = true;
            composers[_pitches[i]][_places[i]] = msg.sender;

            emit NotePlaced(msg.sender, _pitches[i], _places[i]);
        }
    }

    //removes up to 10 owned notes from composition
    function removeNotes(uint256[] _pitches, uint256[] _places, uint256 _numNotes) beforeEndTime() removeValidNotes(_pitches, _places, _numNotes) external {
        for (uint256 i = 0; i < _pitches.length; i++) {
            uint256 pitch = _pitches[i];
            uint256 place = _places[i];
            composition[pitch][place] = false;
            composers[pitch][place] = 0x0;

            removeOwnedNote(msg.sender, pitch, place);

            emit NoteRemoved(msg.sender, pitch, place);
        }

        require(notes.transfer(msg.sender, _numNotes));
    }

    //internal function to remove notes from ownedNotes array
    function removeOwnedNote(address sender, uint256 _pitch, uint256 _place) internal {
        uint256 length = ownedNotes[sender].length;

        for (uint256 i = 0; i < length; i++) {
            if (ownedNotes[sender][i].pitch == _pitch && ownedNotes[sender][i].place == _place) {
                ownedNotes[sender][i] = ownedNotes[sender][length-1];
                delete ownedNotes[sender][length-1];
                ownedNotes[sender].length = (length - 1);
                break;
            }
        }
    }

    //gets a line in the composition for viewing purposes and to prevent having to get the whole composition at once
    function getNoteLine(uint _pitch) external view returns (bool[1000], address[1000]) {
        bool[1000] memory _pitches = composition[_pitch];
        address[1000] memory _composers = composers[_pitch];

        return (_pitches, _composers);
    }

    //returns whether or note a note exists at a pitch and place
    function getNote(uint _pitch, uint _place) external view returns (bool) {
        bool _note = composition[_pitch][_place];
        return _note; 
    }

    //returns note owner
    function getNoteOwner(uint _pitch, uint _place) external view returns (address) {
        return composers[_pitch][_place];
    }

    //returns notes placed by sender
    function getPlacedNotes() external view returns (uint[], uint[]) {
        uint length = ownedNotes[msg.sender].length;

        uint[] memory pitches = new uint[](length);
        uint[] memory places = new uint[](length);
        
        for (uint i = 0; i < ownedNotes[msg.sender].length; i++) {
            pitches[i] = ownedNotes[msg.sender][i].pitch;
            places[i] = ownedNotes[msg.sender][i].place;
        }

        return (pitches, places);
    }

    function () external {
        revert();
    }
}