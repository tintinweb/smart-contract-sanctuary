/**
 *Submitted for verification at testnet.snowtrace.io on 2021-11-27
*/

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
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
        return msg.data;
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: composition.sol




pragma solidity ^0.8.0;

/*

    COMPOSITION FOR 
    
    8 SINE WAVE CONTROLLED FROM A SMART CONTRACT
    AND PERFORMERS
    
    premiere at "Albert Long Hall, Boğaziçi Üniversitesi, Istanbul" on "4th December of 2021"
    
    Performance starts when startMusic() function is called.
    The duration is minimum 1200 seconds (20 minutes)
    There are 6 sessions in the music, with their minimum time determined in sessionDurations variable.
    After time for each section
    Performance finishes if finishMusic() is called after musicDuration passes.
    
    This contract has 8 variables which are connected to 8 sine waves.
    
    During the performance, the variables in the contract will be periodically called and converted to OSC (Open Sound Control) messages to control the electronics. 

*/

contract COMPOSITIONFORASMARTCONTRACTANDINSTRUMENTS is Ownable {
    
    bool performanceOn;
    
    uint256 musicDuration = 3600; // 60 minutes
    uint256 public startTime;
    uint256 public endTime;
     
    uint256 sectionCueTime;
    uint256 currentSection;
    uint256 constant numOfSections = 6;
    uint256 sectionDuration = 180;
      
    event musicStarted(uint time, address _sender);
    event musicFinished(uint time, address _sender);
    event paramAdded(uint);
    event paramChanged(uint256 _parameterId, string name, address _sender, uint256 _value);
    event sectionChanged(uint256 _newSection, address _sender);
    
    struct Param {
         uint id;
         string name;
         uint minVal;
         uint maxVal;
         address lastAddress;
         uint lastChange;
         uint value;
    }

    struct Section {
        uint currentSection;
        uint lastCue;
    }
    
    mapping (uint => Param) public params;
    Section public _section;

    constructor() {
        
        params[0] = Param(0, "/param1", 0 , 1000 , address(0), 0, 0);
        params[1] = Param(1, "/param2", 0 , 1000 , address(0), 0, 0);
        params[2] = Param(2, "/param3", 0 , 1000 , address(0), 0, 0);
        params[3] = Param(3, "/param4", 0 , 1000 , address(0), 0, 0);
        params[4] = Param(4, "/param5", 0 , 1000 , address(0), 0, 0);
        params[5] = Param(5, "/param6", 0 , 1000 , address(0), 0, 0);
        params[6] = Param(6, "/param7", 0 , 1000 , address(0), 0, 0);
        params[7] = Param(7, "/param8", 0 , 1000 , address(0), 0, 0);
        
        startMusic();
    }
    
    // SECTIONS
    
    function getCurrentSection() public view returns(uint256) {
        return currentSection;
    }
    
    function advanceToNextSection() public {
        require( readyForNewSection(), "" );
        _nextSession();
    }
    
    function _nextSession() private {
        uint current = block.timestamp;
        sectionCueTime = current;
        currentSection = currentSection + 1;
    }
    
    function readyForNewSection() public view returns(bool) {
        return block.timestamp - sectionCueTime > sectionDuration;
    }
    
    // PARAMETERS
   
    function changeParameter(uint _parameter, uint value) public {   
        Param storage param = params[_parameter];     
        require(performanceOn);
        require(value > param.minVal && value <= param.maxVal);
        param.value = value;
        param.lastAddress = msg.sender;
        param.lastChange = block.timestamp - startTime;
        emit paramChanged(_parameter, param.name, msg.sender, value );
    }
    
    function getAllParamStruct() public view returns(Param[] memory) {
        Param[] memory _params = new Param[](10);

        for (uint i = 0; i < 10; i++) {
            _params[i] = params[i];
        }
        return _params;

    }

    function getAllLastAddresses() public view returns(address[] memory) {
        address[] memory _params = new address[](10);

        for (uint i = 0; i < 10; i++) {
            _params[i] = params[i].lastAddress;
        }
        return _params;
        
    }

    // TIME
    
    function showTime() public view returns (uint) {
        return block.timestamp - startTime;
    }

    function musicTimeLeft() public view returns(uint256) {
      if(block.timestamp - startTime < musicDuration) {
        return musicDuration - (block.timestamp - startTime);
      }
        return 0;
    }
    
    function finishMusic() public {
        require(musicTimeLeft() <= 0);
        performanceOn = false;
    }
    
    function startMusic() public onlyOwner {
        require(!performanceOn);
        performanceOn = true;
        startTime = block.timestamp;
        endTime = block.timestamp + musicDuration;
    }
    
    // /// BURAYI YAZMAYI UNUTMA
    // function timeLeftUntilNextSection() public view returns(uint256) {

    //   if(block.timestamp - startTime < musicDuration) {
    //     return musicDuration - (block.timestamp - startTime);
    //   }
    //     return 0;
        
    // }
     // function renderOscMessage() public view returns (string memory) {
        
    //     string memory fullMessage;
    //     for (uint i = 0; i<10;i++) {
    //         Param memory _param = params[i];
    //         string memory part = 
    //         string(
    //             abi.encodePacked(
    //                 '[' , _param.name , 
    //                 ", ", 
    //                 uint2str(_param.value), 
    //                 // ",",toAsciiString(_param.lastAddress),
    //                 '"], '
    //                 // ", " , 
    //                 // '"/address_"' , uint2str(i) , ", ")
    //         ));
    //         fullMessage = string(abi.encodePacked(fullMessage,part));
    //     }
        
    //     return fullMessage;
    // }

     // function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
    //     if (_i == 0) {
    //         return "0";
    //     }
    //     uint j = _i;
    //     uint len;
    //     while (j != 0) {
    //         len++;
    //         j /= 10;
    //     }
    //     bytes memory bstr = new bytes(len);
    //     uint k = len;
    //     while (_i != 0) {
    //         k = k-1;
    //         uint8 temp = (48 + uint8(_i - _i / 10 * 10));
    //         bytes1 b1 = bytes1(temp);
    //         bstr[k] = b1;
    //         _i /= 10;
    //     }
    //     return string(bstr);
    // }
    
    
    // ADD PARAMETER INFO
    
    // function addParameter(Param[] memory _params) public onlyOwner{
        
    //     for (uint i = 0; i < _params.length; i++) {
            
    //         params[i] = _params[i];    

    //     }
         
    // }
    
}