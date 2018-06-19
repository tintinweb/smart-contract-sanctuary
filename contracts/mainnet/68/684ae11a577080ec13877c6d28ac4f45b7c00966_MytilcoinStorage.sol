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

    mapping(bytes32 => Picture) public pictures;
    mapping(bytes32 => bool) public hashes;

    event AddPicture(bytes32 indexed hash, uint32 rows, uint32 cols, uint32 width, uint32 height, string image, string name, string author);
    event SetHash(bytes32 indexed hash);

    function MytilcoinStorage() public {
        addManager(msg.sender);
        addManager(0x73b1046A185bF68c11b4c90d79Cffc2E07519951);
        addManager(0x7b15d3e5418E5140fF827127Ee1f44d2d65F8710);
        addManager(0x977482e6f7Ad897Ee70c33A20f30c369f4BF7265);
        addManager(0xa611D8C5183E533e13ecfFb3E9F9628e9dEF2755);
        addManager(0xe16BBd0Cf49F4cC1Eb92fFBbaa71d7580b966097);
        addManager(0x5c9E1b25113A5c18fBFd7655cCd5C160bf79B51E);
        addManager(0x0812B7182aC1C5285E10644CdF5E9BB6234d0AF0);
        addManager(0x52e5689a151CA40B56C217B5dB667F66A197e7Bb);
        addManager(0xA71396Fcb7efd57AeC5FaD1Eb7e5503cDE136123);
        addManager(0xF3f90257dAd60f8c4496D35117e04eAbb507b713);
        addManager(0x63B182305Bd56f0b250a4974Cc872169ab706c53);
        addManager(0x28d2446cE3F1F99B477DD77F9C6361f5b57DcFd8);
        addManager(0x5c3770785Ebd50Ef7bC91b8afC8a7F86F014c54E);
        addManager(0x0fDdAe9D4E6670e3699bdBA3058a84b92DFf95b2);
        addManager(0x5CB547C3fA7abd51E508C980470fb86B731cd0bf);
        addManager(0xEB9e2e0a32BD1De66762cCaef5438586C6C9ac3c);
        addManager(0x6dBA00A685e0E4485A838E31A3a7EB63A5935702);
        addManager(0x2EF9a68D2A9fB9aC4919e2D85cf22780e5EBFCfD);
        addManager(0x7e4FD70e4F8c355d51E2CCFb15aF87d47e6D2167);
        addManager(0x51ce146F1128Ff424Dc918441B46Cb56cC95a172);
        addManager(0x2f2eb8766EC9EaAc7EBa6E851794DB3B45669D2A);
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

    function setHash(string _hash) onlyManager public returns(bool success) {
        bytes32 key = str_to_bytes32(_hash);

        hashes[key] = true;

        SetHash(key);

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