pragma solidity ^0.4.24;

interface FoundationInterface {
    function deposit() external payable returns(bool);
}

interface PlayerBookReceiverInterface {
    function receivePlayerInfo(uint256 _pID, address _addr, bytes32 _name, uint256 _laff) external;
    function receivePlayerNameList(uint256 _pID, bytes32 _name) external;
}

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not owner.");
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Invalid address.");

        owner = _newOwner;

        emit OwnershipTransferred(owner, _newOwner);
    }
}

contract PlayerBook is Ownable {
    using SafeMath for uint256;
    using NameFilter for string;

    FoundationInterface private foundation = FoundationInterface(0x63E7D8c389f0288d287bcE31c96737e94014754B);

    uint256 public registrationFee_ = 10 finney;
    mapping(uint256 => PlayerBookReceiverInterface) public games_;
    mapping(address => bytes32) public gameNames_;
    mapping(address => uint256) public gameIDs_;

    uint256 public gID_;
    uint256 public pID_;
    mapping (address => uint256) public pIDxAddr_;
    mapping (bytes32 => uint256) public pIDxName_;

    struct Player {
        address addr;
        bytes32 name;
        uint256 laff;
        uint256 names;
    }

    mapping (uint256 => Player) public plyr_;
    mapping (uint256 => mapping (bytes32 => bool)) public plyrNames_;
    mapping (uint256 => mapping (uint256 => bytes32)) public plyrNameList_;

    event onNewName(
        uint256 indexed playerID,
        address indexed playerAddress,
        bytes32 indexed playerName,
        bool isNewPlayer,
        uint256 affiliateID,
        address affiliateAddress,
        bytes32 affiliateName,
        uint256 amountPaid,
        uint256 timeStamp
    );

    modifier isHuman() {
        address _addr = msg.sender;
        uint256 _codeLength;

        assembly {
            _codeLength := extcodesize(_addr)
        }

        require(_codeLength == 0, "sorry humans only");
        _;
    }

    modifier isRegisteredGame() {
        require(gameIDs_[msg.sender] != 0);
        _;
    }

    constructor() public {
        plyr_[1].addr = 0xC464F4001C76558AD802bBA405A9E0658dcb1F75;
        plyr_[1].name = "asia";
        plyr_[1].names = 1;
        pIDxAddr_[0xC464F4001C76558AD802bBA405A9E0658dcb1F75] = 1;
        pIDxName_["asia"] = 1;
        plyrNames_[1]["asia"] = true;
        plyrNameList_[1][1] = "asia";

        pID_ = 1;
    }

    function setFoundationInterface(address _who) public onlyOwner {
        foundation = FoundationInterface(_who);
    }

    function checkIfNameValid(string _nameStr) public view returns(bool) {
        bytes32 _name = _nameStr.nameFilter();
        if (pIDxName_[_name] == 0) {
            return (true);
        } else {
            return (false);
        }
    }

    function registerNameXID(string _nameString, uint256 _affCode, bool _all) public payable isHuman {
        require (msg.value >= registrationFee_, "umm.....  you have to pay the name fee");

        bytes32 _name = NameFilter.nameFilter(_nameString);
        address _addr = msg.sender;

        bool _isNewPlayer = determinePID(_addr);

        uint256 _pID = pIDxAddr_[_addr];

        if (_affCode != 0 && _affCode != plyr_[_pID].laff && _affCode != _pID) {
            plyr_[_pID].laff = _affCode;
        } else if (_affCode == _pID) {
            _affCode = 0;
        }

        registerNameCore(_pID, _addr, _affCode, _name, _isNewPlayer, _all);
    }

    function registerNameXaddr(string _nameString, address _affCode, bool _all) public payable isHuman {
        require (msg.value >= registrationFee_, "umm.....  you have to pay the name fee");

        bytes32 _name = NameFilter.nameFilter(_nameString);
        address _addr = msg.sender;

        bool _isNewPlayer = determinePID(_addr);

        uint256 _pID = pIDxAddr_[_addr];

        uint256 _affID;
        if (_affCode != address(0) && _affCode != _addr) {
            _affID = pIDxAddr_[_affCode];
            if (_affID != plyr_[_pID].laff) {
                plyr_[_pID].laff = _affID;
            }
        }

        registerNameCore(_pID, _addr, _affID, _name, _isNewPlayer, _all);
    }

    function registerNameXname(string _nameString, bytes32 _affCode, bool _all) public payable isHuman {
        require (msg.value >= registrationFee_, "umm.....  you have to pay the name fee");

        bytes32 _name = NameFilter.nameFilter(_nameString);
        address _addr = msg.sender;

        bool _isNewPlayer = determinePID(_addr);

        uint256 _pID = pIDxAddr_[_addr];

        uint256 _affID;
        if (_affCode != "" && _affCode != _name) {
            _affID = pIDxName_[_affCode];
            if (_affID != plyr_[_pID].laff) {
                plyr_[_pID].laff = _affID;
            }
        }

        registerNameCore(_pID, _addr, _affID, _name, _isNewPlayer, _all);
    }

    function addMeToGame(uint256 _gameID) public isHuman {
        require(_gameID <= gID_, "silly player, that game doesn&#39;t exist yet");

        address _addr = msg.sender;

        uint256 _pID = pIDxAddr_[_addr];
        require(_pID != 0, "hey there buddy, you dont even have an account");

        games_[_gameID].receivePlayerInfo(_pID, _addr, plyr_[_pID].name, plyr_[_pID].laff);

        uint256 _totalNames = plyr_[_pID].names;
        if (_totalNames > 1) {
            for (uint256 ii = 1; ii <= _totalNames; ii++) {
                games_[_gameID].receivePlayerNameList(_pID, plyrNameList_[_pID][ii]);
            }
        }
    }

    function addMeToAllGames() public isHuman {
        address _addr = msg.sender;

        uint256 _pID = pIDxAddr_[_addr];
        require(_pID != 0, "hey there buddy, you dont even have an account");

        uint256 _laff = plyr_[_pID].laff;
        uint256 _totalNames = plyr_[_pID].names;
        bytes32 _name = plyr_[_pID].name;

        for (uint256 i = 1; i <= gID_; i++) {
            games_[i].receivePlayerInfo(_pID, _addr, _name, _laff);
            if (_totalNames > 1) {
                for (uint256 ii = 1; ii <= _totalNames; ii++) {
                    games_[i].receivePlayerNameList(_pID, plyrNameList_[_pID][ii]);
                }
            }
        }

    }

    function useMyOldName(string _nameString) public isHuman {
        bytes32 _name = _nameString.nameFilter();
        uint256 _pID = pIDxAddr_[msg.sender];

        require(plyrNames_[_pID][_name] == true, "umm... thats not a name you own");

        plyr_[_pID].name = _name;
    }

    function registerNameCore(uint256 _pID, address _addr, uint256 _affID, bytes32 _name, bool _isNewPlayer, bool _all) private {
        if (pIDxName_[_name] != 0) {
            require(plyrNames_[_pID][_name] == true, "sorry that names already taken");
        }

        plyr_[_pID].name = _name;
        pIDxName_[_name] = _pID;
        if (plyrNames_[_pID][_name] == false) {
            plyrNames_[_pID][_name] = true;
            plyr_[_pID].names++;
            plyrNameList_[_pID][plyr_[_pID].names] = _name;
        }

        foundation.deposit.value(address(this).balance)();

        if (_all == true) {
            for (uint256 i = 1; i <= gID_; i++) {
                games_[i].receivePlayerInfo(_pID, _addr, _name, _affID);
            }
        }

        emit onNewName(_pID, _addr, _name, _isNewPlayer, _affID, plyr_[_affID].addr, plyr_[_affID].name, msg.value, now);
    }

    function determinePID(address _addr) private returns (bool) {
        if (pIDxAddr_[_addr] == 0) {
            pID_++;
            pIDxAddr_[_addr] = pID_;
            plyr_[pID_].addr = _addr;

            return (true);
        } else {
            return (false);
        }
    }

    function getPlayerID(address _addr) external isRegisteredGame returns (uint256) {
        determinePID(_addr);

        return (pIDxAddr_[_addr]);
    }

    function getPlayerName(uint256 _pID) external view returns (bytes32) {
        return (plyr_[_pID].name);
    }

    function getPlayerLAff(uint256 _pID) external view returns (uint256) {
        return (plyr_[_pID].laff);
    }

    function getPlayerAddr(uint256 _pID) external view returns (address) {
        return (plyr_[_pID].addr);
    }

    function getNameFee() external view returns (uint256) {
        return(registrationFee_);
    }

    function registerNameXIDFromDapp(address _addr, bytes32 _name, uint256 _affCode, bool _all) external payable isRegisteredGame returns(bool, uint256) {
        require (msg.value >= registrationFee_, "umm.....  you have to pay the name fee");

        bool _isNewPlayer = determinePID(_addr);

        uint256 _pID = pIDxAddr_[_addr];

        uint256 _affID = _affCode;
        if (_affID != 0 && _affID != plyr_[_pID].laff && _affID != _pID) {
            plyr_[_pID].laff = _affID;
        } else if (_affID == _pID) {
            _affID = 0;
        }

        registerNameCore(_pID, _addr, _affID, _name, _isNewPlayer, _all);

        return(_isNewPlayer, _affID);
    }

    function registerNameXaddrFromDapp(address _addr, bytes32 _name, address _affCode, bool _all) external payable isRegisteredGame returns(bool, uint256) {
        require (msg.value >= registrationFee_, "umm.....  you have to pay the name fee");

        bool _isNewPlayer = determinePID(_addr);

        uint256 _pID = pIDxAddr_[_addr];

        uint256 _affID;
        if (_affCode != address(0) && _affCode != _addr) {
            _affID = pIDxAddr_[_affCode];
            if (_affID != plyr_[_pID].laff) {
                plyr_[_pID].laff = _affID;
            }
        }

        registerNameCore(_pID, _addr, _affID, _name, _isNewPlayer, _all);

        return(_isNewPlayer, _affID);
    }

    function registerNameXnameFromDapp(address _addr, bytes32 _name, bytes32 _affCode, bool _all) external payable isRegisteredGame returns(bool, uint256) {
        require (msg.value >= registrationFee_, "umm.....  you have to pay the name fee");

        bool _isNewPlayer = determinePID(_addr);

        uint256 _pID = pIDxAddr_[_addr];

        uint256 _affID;
        if (_affCode != "" && _affCode != _name) {
            _affID = pIDxName_[_affCode];
            if (_affID != plyr_[_pID].laff) {
                plyr_[_pID].laff = _affID;
            }
        }

        registerNameCore(_pID, _addr, _affID, _name, _isNewPlayer, _all);

        return(_isNewPlayer, _affID);
    }

    function addGame(address _gameAddress, string _gameNameStr) public onlyOwner {
        require(gameIDs_[_gameAddress] == 0, "derp, that games already been registered");

        gID_++;
        bytes32 _name = _gameNameStr.nameFilter();
        gameIDs_[_gameAddress] = gID_;
        gameNames_[_gameAddress] = _name;
        games_[gID_] = PlayerBookReceiverInterface(_gameAddress);

        games_[gID_].receivePlayerInfo(1, plyr_[1].addr, plyr_[1].name, 0);
    }

    function setRegistrationFee(uint256 _fee) public onlyOwner {
        registrationFee_ = _fee;
    }
}

library NameFilter {
    function nameFilter(string _input) internal pure returns(bytes32) {
        bytes memory _temp = bytes(_input);
        uint256 _length = _temp.length;

        require (_length <= 32 && _length > 0, "string must be between 1 and 32 characters");

        require(_temp[0] != 0x20 && _temp[_length-1] != 0x20, "string cannot start or end with space");
        if (_temp[0] == 0x30) {
            require(_temp[1] != 0x78, "string cannot start with 0x");
            require(_temp[1] != 0x58, "string cannot start with 0X");
        }

        bool _hasNonNumber;

        for (uint256 i = 0; i < _length; i++) {
            if (_temp[i] > 0x40 && _temp[i] < 0x5b) {
                _temp[i] = byte(uint(_temp[i]) + 32);
                if (_hasNonNumber == false) {
                    _hasNonNumber = true;
                }
            } else {
                require(_temp[i] == 0x20 || (_temp[i] > 0x60 && _temp[i] < 0x7b) || (_temp[i] > 0x2f && _temp[i] < 0x3a), "string contains invalid characters");
                if (_temp[i] == 0x20) {
                    require( _temp[i + 1] != 0x20, "string cannot contain consecutive spaces");
                }
                if (_hasNonNumber == false && (_temp[i] < 0x30 || _temp[i] > 0x39)) {
                    _hasNonNumber = true;
                }
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

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a, "SafeMath add failed");
        return c;
    }
}