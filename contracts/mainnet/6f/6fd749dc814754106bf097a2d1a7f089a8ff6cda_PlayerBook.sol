pragma solidity ^0.4.24;

// File: contracts\utils\NameFilter.sol

library NameFilter {

    /**
     * @dev filters name strings
     * -converts uppercase to lower case.
     * -makes sure it does not start/end with a space
     * -makes sure it does not contain multiple spaces in a row
     * -cannot be only numbers
     * -cannot start with 0x
     * -restricts characters to A-Z, a-z, 0-9, and space.
     * @return reprocessed string in bytes32 format
     */
    function nameFilter(string _input)
        internal
        pure
        returns(bytes32)
    {
        bytes memory _temp = bytes(_input);
        uint256 _length = _temp.length;

        //sorry limited to 32 characters
        require (_length <= 32 && _length > 0, "string must be between 1 and 32 characters");
        // make sure it doesnt start with or end with space
        require(_temp[0] != 0x20 && _temp[_length-1] != 0x20, "string cannot start or end with space");
        // make sure first two characters are not 0x
        if (_temp[0] == 0x30)
        {
            require(_temp[1] != 0x78, "string cannot start with 0x");
            require(_temp[1] != 0x58, "string cannot start with 0X");
        }

        // create a bool to track if we have a non number character
        bool _hasNonNumber;

        // convert & check
        for (uint256 i = 0; i < _length; i++)
        {
            // if its uppercase A-Z
            if (_temp[i] > 0x40 && _temp[i] < 0x5b)
            {
                // convert to lower case a-z
                _temp[i] = byte(uint(_temp[i]) + 32);

                // we have a non number
                if (_hasNonNumber == false)
                    _hasNonNumber = true;
            } else {
                require
                (
                    // require character is a space
                    _temp[i] == 0x20 ||
                    // OR lowercase a-z
                    (_temp[i] > 0x60 && _temp[i] < 0x7b) ||
                    // or 0-9
                    (_temp[i] > 0x2f && _temp[i] < 0x3a),
                    "string contains invalid characters"
                );
                // make sure theres not 2x spaces in a row
                if (_temp[i] == 0x20)
                    require( _temp[i+1] != 0x20, "string cannot contain consecutive spaces");

                // see if we have a character other than a number
                if (_hasNonNumber == false && (_temp[i] < 0x30 || _temp[i] > 0x39))
                    _hasNonNumber = true;
            }
        }

        require(_hasNonNumber == true, "string cannot be only numbers");

        bytes32 _ret;
        assembly {
            _ret := mload(add(_temp, 32))
        }
        return (_ret);
    }
}

// File: contracts\utils\Ownable.sol

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

// File: contracts\PlayerBook.sol

interface PlayerBookReceiverInterface {
    function receivePlayerInfo(address _addr, string _name) external;
}

contract PlayerBook is Ownable {
    using NameFilter for string;
    
    string constant public name = "PlayerBook";
    string constant public symbol = "PlayerBook";    

    uint256 public registrationFee_ = 10 finney;            // price to register a name
    mapping (bytes32 => address) public nameToAddr;
    mapping (address => string[]) public addrToNames;
    
    PlayerBookReceiverInterface public currentGame; 
    
    address public CFO;
    address public COO; 
    
    modifier onlyCOO() {
        require(msg.sender == COO);
        _; 
    }
    
    constructor(address _CFO, address _COO) public {
        CFO = _CFO;
        COO = _COO; 
    }
    
    function setCFO(address _CFO) onlyOwner public {
        CFO = _CFO; 
    }  
  
    function setCOO(address _COO) onlyOwner public {
        COO = _COO; 
    }  

    modifier isHuman() {
        address _addr = msg.sender;
        uint256 _codeLength;

        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "sorry humans only");
        _;
    }
    

    function checkIfNameValid(string _nameStr) public view returns(bool) {
      bytes32 _name = _nameStr.nameFilter();
      if (nameToAddr[_name] == address(0))
        return (true);
      else
        return (false);
    }

    function getPlayerAddr(string _nameStr) public view returns(address) {
      bytes32 _name = _nameStr.nameFilter();
      return nameToAddr[_name];
    }

    function getPlayerName() public view returns(string) {
      address _addr = msg.sender;
      string[] memory names = addrToNames[_addr];
      if(names.length > 0) {
        return names[names.length-1];
      } else {
        return ""; 
      }
    }

    function registerName(string _nameString) public isHuman payable {
      // make sure name fees paid
      require (msg.value >= registrationFee_, "umm.....  you have to pay the name fee");

      // filter name + condition checks
      bytes32 _name = NameFilter.nameFilter(_nameString);
      require(nameToAddr[_name] == address(0), "name must not be taken by others");
      address _addr = msg.sender;
      nameToAddr[_name] = _addr;
      addrToNames[_addr].push(_nameString);
      // update current game user info 
      currentGame.receivePlayerInfo(_addr, _nameString); 
    }

    function registerNameByCOO(string _nameString, address _addr) public onlyCOO {
      bytes32 _name = NameFilter.nameFilter(_nameString);
      require(nameToAddr[_name] == address(0), "name must not be taken by others");
      nameToAddr[_name] = _addr;
      addrToNames[_addr].push(_nameString);
      // update current game user info 
      currentGame.receivePlayerInfo(_addr, _nameString);       
    }
    
    
    function setCurrentGame(address _addr) public onlyCOO {
        currentGame = PlayerBookReceiverInterface(_addr); 
    }

    function withdrawBalance() public onlyCOO {
      uint _amount = address(this).balance;
      CFO.transfer(_amount);
    }
}