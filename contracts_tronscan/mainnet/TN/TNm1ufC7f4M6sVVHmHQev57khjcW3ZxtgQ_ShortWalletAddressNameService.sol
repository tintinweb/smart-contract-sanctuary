//SourceUnit: Username.sol

pragma solidity 0.5.10;

/*
                      _ __/\
                  /\_\      \
                 |           \
                 |             \           ___
                  \             \        /  _ \
                 _|              \      {  ( \^)
                 \                \     \  \  \|
                  \                \     \  \
                  --                \ ____)  \
                 \                            \
                  |                           )
                ___\_________________________/____________
                   ..........................             ~~~~
                  ............................
                  .............................
                 ...............................
                ...............................
                ..............................
    
               _____  __                  __     _       __        __ __       __           
              / ___/ / /_   ____   _____ / /_   | |     / /____ _ / // /___   / /_          
              \__ \ / __ \ / __ \ / ___// __/   | | /| / // __ `// // // _ \ / __/          
             ___/ // / / // /_/ // /   / /_     | |/ |/ // /_/ // // //  __// /_            
            /____//_/ /_/ \____//_/    \__/     |__/|__/ \__,_//_//_/ \___/ \__/            
         ___        __     __                           _   __                              
        /   |  ____/ /____/ /_____ ___   _____ _____   / | / /____ _ ____ ___   ___         
       / /| | / __  // __  // ___// _ \ / ___// ___/  /  |/ // __ `// __ `__ \ / _ \        
      / ___ |/ /_/ // /_/ // /   /  __/(__  )(__  )  / /|  // /_/ // / / / / //  __/        
     /_/  |_|\__,_/ \__,_//_/    \___//____//____/  /_/ |_/ \__,_//_/ /_/ /_/ \___/         
   _____               __                       __ _____ _       __ ___     _   __ _____  _ 
  / ___/ __  __ _____ / /_ ___   ____ ___     _/_// ___/| |     / //   |   / | / // ___/ | |
  \__ \ / / / // ___// __// _ \ / __ `__ \   / /  \__ \ | | /| / // /| |  /  |/ / \__ \  / /
 ___/ // /_/ /(__  )/ /_ /  __// / / / / /  / /  ___/ / | |/ |/ // ___ | / /|  / ___/ / / / 
/____/ \__, //____/ \__/ \___//_/ /_/ /_/  / /  /____/  |__/|__//_/  |_|/_/ |_/ /____/_/_/  
      /____/                               |_|                                       /_/    
    ///////////////////////////////////////////////////////////////////////////////////////
                                                                           
    // This contract is designed to help increase transparency of transactions on-chain.
    
    // This is achieved by enabling any address operator to set a 'Name Tag',
    // which will be used in place of anywhere an address may be shown.
    
    // For instance, this contract could be used for a "High Score" system,
    // Where users don't see addresses, but names - just like at the old arcades!
    
    // S.W.A.N.S. is a small part to a bigger machine - but anyone is welcome to use it!
    ///////////////////////////////////////////////////////////////////////////////////////
*/

library Address {
    function isContract(address account) internal view returns (bool) {
        uint size;
        assembly {size := extcodesize(account)}
        return size > 0;
    }
}

contract Context {
    constructor () internal { }
    
    function _msgSender() internal view returns (address payable) {return msg.sender;}
    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract ShortWalletAddressNameService is Ownable {
    using Address for address;
    using SafeMath for uint256;
    
    address payable public fundsReceiver;
    
    uint public buffer;
    uint public costToSetRecord;
    
    uint256 internal currentPaid;
    uint256 internal totalPaid;
    
    uint256 public successfulUpdatesToRecords;
    
    mapping(address => string) private addressNameMap; // Used to find usernames tied to an address.
    mapping(string => address) private nameAddressMap; // Used to find addresses tied to a username.
    
    event onSetNameForAddress(address _caller, address _addr, string _name);
    event onDistributeFunds(address _caller, address _from, uint256 _amount, uint256 _timestamp);
    event onSetFundsReceiver(address _caller, address _addr, uint256 _timestamp);
    
    modifier requiresFee() {
        require(msg.value == costToSetRecord, "PAY_REQUIRED_FEE");
        _;
    }
    
    constructor(address payable _receiver, uint _buffer, uint _cost) public {
        buffer = _buffer;
        costToSetRecord = _cost;
        fundsReceiver = _receiver;
    }
    
    function distributionFund() external view returns (uint) {
        return address(this).balance;
    }
    
    function currentPayoutStats() external view returns (uint256) {
        return (currentPaid);
    }
    
    function totalPayoutStats() external view returns (uint256) {
        return (totalPaid);
    }
    
    function getAddressByName(string memory name) public view returns (address) {return nameAddressMap[name];}
    function getNameByAddress(address addr) external view returns (string memory name) {return addressNameMap[addr];}
    
    // Check availability
    function isAvailable(string memory name) public view returns (bool) {
        if (checkCharacters(bytes(name))) {
          return (nameAddressMap[name] == address(0));
        }
        return false;
    }
    
    ///////////////////////////////////////
    // PUBLIC & EXTERNAL WRITE FUNCTIONS //
    ///////////////////////////////////////

    // Distribute the funds from name-setting to the desired recipients.
    function distribute() external returns (bool _success) {
        uint funds = address(this).balance;
        
        if (funds >= buffer) {
            fundsReceiver.transfer(funds);
            
            currentPaid = 0;
            totalPaid += funds;
            
            emit onDistributeFunds(msg.sender, address(this), funds, block.timestamp);
            return true;
        }
        
        return false;
    }

    // Set a name. Caller's address receives the name passed as the _name argument.
    function setName(string calldata _name) requiresFee() external payable returns (bool _success) {
        
        _setNameRecordOf(msg.sender, _name);
        _addCallToRecord();
        _addSetToProfits();
        
        emit onSetNameForAddress(msg.sender, msg.sender, _name);
        return true;
    }
    
    function setNameFor(address _addr, string calldata _name) onlyOwner external returns (bool _success) {
        require(Address.isContract(_addr), 'CAN_ONLY_SET_RECORDS_FOR_CONTRACTS');
        
        _setNameRecordOf(_addr, _name);
        _addCallToRecord();
        
        emit onSetNameForAddress(msg.sender, _addr, _name);
        return true;
    }
    
    function setFundsReceiver(address payable _addr) onlyOwner external returns (bool _success) {
        require(_addr != address(0), "NEW_OWNER_MUST_NOT_BE_ZERO");
        require(!Address.isContract(_addr), "NEW_OWNER_MUST_BE_EOA");
        
        fundsReceiver = _addr;
        _addCallToRecord();
        
        emit onSetFundsReceiver(msg.sender, msg.sender, block.timestamp);
        return true;
    }
    
    //////////////////////////////////
    // INTERNAL & PRIVATE FUNCTIONS //
    //////////////////////////////////
    
    function _addCallToRecord() internal {
        successfulUpdatesToRecords += 1;
    }
    
    function _addSetToProfits() internal {
        currentPaid += costToSetRecord;
    }
    
    // Set name record
    function _setNameRecordOf(address _addr, string memory _name) internal {
        require(bytes(_name).length <= 32, "name must be fewer than 32 bytes");
        require(bytes(_name).length >= 3, "name must be more than 3 bytes");
        require(checkCharacters(bytes(_name)));

        require(nameAddressMap[_name] == address(0), "name in use");
        
        string memory oldName = addressNameMap[_addr];
        if (bytes(oldName).length > 0) {nameAddressMap[oldName] = address(0);}
        addressNameMap[_addr] = _name;
        nameAddressMap[_name] = _addr;
    }
    
    // Validation
    function checkCharacters(bytes memory name) internal pure returns (bool) {
        // Check for only letters and numbers
        for(uint i; i<name.length; i++){
            bytes1 char = name[i];
            if(
                !(char >= 0x30 && char <= 0x39) && //9-0
                !(char >= 0x41 && char <= 0x5A) && //A-Z
                !(char >= 0x61 && char <= 0x7A)    //a-z
            )
                return false;
        }
        return true;
    }
}

/////////////////////////////////////////////////
// SafeMath // Overflow & Underflow prevention //
/////////////////////////////////////////////////

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {return 0;}
        c = a * b;
        assert(c / a == b);
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function safeSub(uint a, uint b) internal pure returns (uint) {
        if (b > a) {return 0;} else {return a - b;}
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {return a / b;}
    function max(uint256 a, uint256 b) internal pure returns (uint256) {return a >= b ? a : b;}
    function min(uint256 a, uint256 b) internal pure returns (uint256) {return a < b ? a : b;}
}