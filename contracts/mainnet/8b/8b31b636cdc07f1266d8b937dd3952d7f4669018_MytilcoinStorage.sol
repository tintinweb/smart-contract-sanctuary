/*! mytilcoinstorage.sol | (c) 2018 Develop by BelovITLab LLC (smartcontract.ru), author @stupidlovejoy | License: MIT */

pragma solidity 0.4.21;

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() { require(msg.sender == owner); _; }

    function Ownable() public {
        owner = msg.sender;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
        OwnershipTransferred(owner, newOwner);
    }
}

contract Manageable is Ownable {
    mapping(address => bool) public managers;

    event ManagerAdded(address indexed manager);
    event ManagerRemoved(address indexed manager);

    modifier onlyManager() { require(managers[msg.sender]); _; }

    function addManager(address _manager) onlyOwner public {
        require(_manager != address(0));

        managers[_manager] = true;

        ManagerAdded(_manager);
    }

    function removeManager(address _manager) onlyOwner public {
        require(_manager != address(0));

        managers[_manager] = false;

        ManagerRemoved(_manager);
    }
}

contract MytilcoinStorage is Manageable {
    struct Picture {
        string hash;
        uint32 rows;
        uint32 cols;
        uint32 width;
        uint32 height;
        string image;
        string name;
        string author;
    }

    struct Segment {
        uint32 row;
        uint32 col;
        string hash;
        string image;
        string email;
        string login;
    }
    
    mapping(bytes32 => Picture) public pictures;
    mapping(bytes32 => mapping(uint32 => mapping(uint32 => Segment))) public segments;

    event AddPicture(bytes32 indexed hash, uint32 rows, uint32 cols, uint32 width, uint32 height, string image, string name, string author);
    event SetSegment(bytes32 indexed picture, uint32 indexed row, uint32 indexed col, bytes32 hash, string image);
    event SegmentOwner(bytes32 indexed picture, uint32 indexed row, uint32 indexed col, string email, string login);

    function MytilcoinStorage() public {
        addManager(msg.sender);
        addManager(0x209eba96c917871f78671a3ed3503ecc4144495c);
    }

    function addPicture(string _hash, uint32 _rows, uint32 _cols, uint32 _width, uint32 _height, string _image, string _name, string _author) onlyManager public returns(bool success) {
        bytes32 key = str_to_bytes32(_hash);

        require(!(pictures[key].rows > 0));
        require(_rows > 0 && _cols > 0 && _width > 0 && _height > 0);
        
        pictures[key] = Picture({
            hash: _hash,
            rows: _rows,
            cols: _cols,
            width: _width,
            height: _height,
            image: _image,
            name: _name,
            author: _author
        });

        AddPicture(key, _rows, _cols, _width, _height, _image, _name, _author);

        return true;
    }

    function setSegment(string _picture, uint32 _row, uint32 _col, string _hash, string _image, string _email, string _login) onlyManager public returns(bool success) {
        bytes32 key = str_to_bytes32(_picture);

        require(pictures[key].rows > 0);
        require(_row > 0 && _col > 0 && _row <= pictures[key].rows && _col <= pictures[key].cols);
        require(!(segments[key][_row][_col].row > 0));
        
        segments[key][_row][_col] = Segment({
            row: _row,
            col: _col,
            hash: _hash,
            image: _image,
            email: _email,
            login: _login
        });

        SetSegment(key, _row, _col, str_to_bytes32(_hash), _image);
        SegmentOwner(key, _row, _col, _email, _login);

        return true;
    }

    function setSegmentOwner(string _picture, uint32 _row, uint32 _col, string _email, string _login) onlyManager public returns(bool success) {
        bytes32 key = str_to_bytes32(_picture);

        require(pictures[key].rows > 0);
        require(_row > 0 && _col > 0 && _row <= pictures[key].rows && _col <= pictures[key].cols);
        require(segments[key][_row][_col].row > 0);
        
        segments[key][_row][_col].email = _email;
        segments[key][_row][_col].login = _login;

        SegmentOwner(key, _row, _col, _email, _login);

        return true;
    }

    function str_to_bytes32(string memory source) private pure returns(bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if(tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }
}