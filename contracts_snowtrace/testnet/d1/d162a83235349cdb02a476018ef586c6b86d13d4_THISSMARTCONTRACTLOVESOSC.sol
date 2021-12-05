/**
 *Submitted for verification at testnet.snowtrace.io on 2021-12-04
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


    DEMO FOR SMART CONTRACT CONTROLLED LIVE ELECTRONICS / SMART DEVICES
    
    This smart contract is an utilization template for audiovisual compositions, live performances and installations.

    A Python code reads the smart contract data periodically, and broadcasts OSC messages to computers in local network.

    Example: 
                /param, [1, 450, 0x0000000000000, 300]
                /param, [2, 23, 0x23526345eff, 340]
                /time, 253
                /section, 3

    Then softwares like Supercollider, TouchDesigner uses the incoming data to interpret in real time.

    In this particular smart contract, there are 8 parameters which can be edited by any wallet, during the performance.




*/

contract THISSMARTCONTRACTLOVESOSC is Ownable {
    
    bool public eventRunning;
    
    uint256 public musicDuration = 36000; // 600 minutes
    uint256 public startTime;
    uint256 public endTime;
     
    uint256 totalParams = 8;
    uint256 sectionDuration = 60;
   
    event musicStarted(uint startTime, uint endTime);
    event musicFinished(uint time);
    event paramChanged(uint256 _parameterId, address _sender, uint256 _value, uint256 _time);
    event sectionChanged(uint256 _newSection, address _sender, uint256 _numOfParams, uint256 _time);
    
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
        uint numParams;
        address lastAddress;
    }

    struct ParamChange {
        uint id;
        uint value;
    }
    
    mapping (uint => Param) public params;
    Section public _section;

    constructor() {
        
        params[0] = Param(0, "scale", 0 , 5 , address(0), 0, 0);
        params[1] = Param(1, "fundamental_note", 0 , 11 , address(0), 0, 0);
        params[2] = Param(2, "seq1_speed", 1 , 10000 , address(0), 0, 0);
        params[3] = Param(3, "seq1_octave", 0 , 4 , address(0), 0, 0);
        params[4] = Param(4, "seq2_speed", 1 , 10000 , address(0), 0, 0);
        params[5] = Param(5, "seq2_octave" ,0 , 4 , address(0), 0, 0);
        params[6] = Param(6, "seq3_speed", 1 , 10000 , address(0), 0, 0);
        params[7] = Param(7, "seq3_octave", 0 , 4 , address(0), 0, 0);        

        startEvent();
        _section.numParams = 8;
        // _section.lastCue = startTime;

    }
    
    // SECTIONS

    
    // function advanceToNextSection(uint _numOfParams) public {
    //     require( readyForNewSection(), "" );
    //     _nextSession(_numOfParams);
    // }
    
    // function _nextSession(uint _numOfParams) private {
    //     require(_numOfParams > 0 && _numOfParams <= totalParams);
    //     _section.lastCue = block.timestamp;
    //     _section.currentSection = _section.currentSection + 1;
    //     _section.lastAddress = msg.sender;
    //     _section.numParams = _numOfParams;

    //     emit sectionChanged( _section.currentSection, msg.sender, _numOfParams, _section.lastCue );
    // }
    
    // function readyForNewSection() public view returns(bool) {
    //     return block.timestamp - _section.lastCue > sectionDuration;
    // }
    
    // PARAMETERS
   
    function changeParameter(uint _parameter, uint value) public {   
        Param storage param = params[_parameter];     
        require(eventRunning);
        require(_parameter < totalParams);
        require(value >= param.minVal && value <= param.maxVal);
        param.value = value;
        param.lastAddress = msg.sender;
        param.lastChange = block.timestamp - startTime;
        emit paramChanged(_parameter, msg.sender, value, param.lastChange);
    }


    function changeParameterMulti(ParamChange[] memory _input) public {  
        require(eventRunning && _input.length <= _section.numParams);
        for (uint i = 0; i < _input.length; i++) {
            require(_input[i].id < totalParams);
            Param storage param = params[_input[i].id];     
            require(_input[i].value >= param.minVal && _input[i].value <= param.maxVal);
            param.value = _input[i].value;
            param.lastAddress = msg.sender;
            param.lastChange = block.timestamp - startTime;
            emit paramChanged(_input[i].id, msg.sender, _input[i].value, param.lastChange );
        }
        
    }
    
    function getAllParamStruct() public view returns(Param[] memory) {
        Param[] memory _params = new Param[](8);

        for (uint i = 0; i < 8; i++) {
            _params[i] = params[i];
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

    function startEvent() public onlyOwner {
        require(!eventRunning);
        eventRunning = true;
        startTime = block.timestamp;
        endTime = block.timestamp + musicDuration;

        emit musicStarted(startTime, endTime);

    }
    function finishMusicAdmin() public onlyOwner {
        // require(musicTimeLeft() <= 0);
        eventRunning = false;

        emit musicFinished(block.timestamp);
    }

    function finishMusic() public {
        require(musicTimeLeft() <= 0);
        eventRunning = false;

        emit musicFinished(block.timestamp);
    }
    
    
    

     // function getAllLastAddresses() public view returns(address[] memory) {
    //     address[] memory _params = new address[](10);

    //     for (uint i = 0; i < 10; i++) {
    //         _params[i] = params[i].lastAddress;
    //     }
    //     return _params;
        
    // }

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