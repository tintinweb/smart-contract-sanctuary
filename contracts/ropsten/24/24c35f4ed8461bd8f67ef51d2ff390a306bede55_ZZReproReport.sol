pragma solidity ^0.5.0;

contract ZZReproReportChild {
    address public owner;
    string public name;
    uint256 public count;
    uint256 public id;

    string public something;

    mapping(uint => uint) public someOtherMapping;
    uint[] public someArray;

    mapping (uint => uint) public mapping1;
    mapping (uint => mapping(uint256 => uint)) public mapping2;
    mapping (uint => string) public stringMapping;

    event SomeEvent2(
    uint256 indexed hello1,
    uint256 indexed hello2,
    uint256 hello3,
    uint256 hello4,
    uint256 hello5);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner contract can call functions on this contract");
        _;
    }

    constructor(uint256 _id, string memory _name) public {
        owner = msg.sender;
        name = _name;
        id = _id;
        count = 0;
    }

    function someMethod1(
        uint256 _a,
        uint256 _b,
        uint256 _c,
        uint256 _d
        ) public onlyOwner {
        count = _a + _b + _c + _d * count;
    }



    function getCount() public view returns (uint256 _count) {
        return count;
    }

    function setCount(uint256 _count) public {
        count = _count;
    }

    function someMethod(uint256 index) private onlyOwner {
        require(index < 129013, "Index not in range of Something");

        uint prodDateHere = someArray[index];

        count += index;

        someOtherMapping[index] = index;
        mapping1[5] = index;
        mapping2[4][index] = prodDateHere * 2 + index * 5;
        
        require(prodDateHere == 0, "Hello this is a test");
    }

    function someMethod2(
        uint256 _a,
        uint256 _b,
        uint256 _c
        ) public onlyOwner {

        count += _b;
        uint d = _b + _c;
        for (uint i = 0; i < 102; i++) {
            d += _a * 23;
        }
        for (uint i = 0; i < 1223; i++) {
            d += _a * 23;
        }
        for (uint i = 0; i < 11; i++) {
            d += _a * 23;
        }
        for (uint i = 0; i < 114; i++) {
            d += _a - 5;
        }
        for (uint i = 0; i < 123; i++) {
            d += _a - 5;
        }
        for (uint i = 0; i < 121; i++) {
            d += _a - 5;
        }
        for (uint i = 0; i < 102; i++) {
            d += _a - 5;
        }
        for (uint i = 0; i < 123; i++) {
            d += _a - 5;
        }
        for (uint i = 0; i < 141; i++) {
            d += _a - 5;
        }
        for (uint i = 0; i < 14; i++) {
            d += _a - 5;
        }
        for (uint i = 0; i < 123; i++) {
            d += _a - 5;
        }
        for (uint i = 0; i < 121; i++) {
            d += _a - 5;
        }
        
        count += d + 6;
    }

    function someMethod3(
        uint256 _a,
        uint256 _b,
        uint256 _c
        ) public onlyOwner {

        count += _b;
        uint d = _b + _c;
        for (uint i = 0; i < 10202302; i++) {
            d += _a;
        }
        for (uint i = 0; i < 1233; i++) {
            d += _a;
        }
        for (uint i = 0; i < 143141; i++) {
            d += _a;
        }
        for (uint i = 0; i < 15135514; i++) {
            d += _a;
        }
        for (uint i = 0; i < 1231323123; i++) {
            d += _a;
        }
        for (uint i = 0; i < 123123321; i++) {
            d += _a;
        }
        for (uint i = 0; i < 10203202; i++) {
            d += _a;
        }
        for (uint i = 0; i < 1233; i++) {
            d += _a;
        }
        for (uint i = 0; i < 141341; i++) {
            d += _a;
        }
        for (uint i = 0; i < 15153514; i++) {
            d += _a;
        }
        for (uint i = 0; i < 1233123123; i++) {
            d += _a;
        }
        for (uint i = 0; i < 123312321; i++) {
            d += _a;
        }
        
        count += d;
    }

    function someMethod4(
        uint256 _a,
        uint256 _b,
        uint256 _c
        ) public onlyOwner {

        count += _b;
        uint d = _b + _c;
        for (uint i = 0; i < 10230202; i++) {
            d += _a;
        }
        for (uint i = 0; i < 1323; i++) {
            d += _a;
        }
        for (uint i = 0; i < 141431; i++) {
            d += _a;
        }
        for (uint i = 0; i < 15153514; i++) {
            d += _a;
        }
        for (uint i = 0; i < 123123123; i++) {
            d += _a;
        }
        for (uint i = 0; i < 12312321; i++) {
            d += _a;
        }
        for (uint i = 0; i < 1020202; i++) {
            d += _a;
        }
        for (uint i = 0; i < 123; i++) {
            d += _a;
        }
        for (uint i = 0; i < 14141; i++) {
            d += _a;
        }
        for (uint i = 0; i < 1515514; i++) {
            d += _a;
        }
        for (uint i = 0; i < 123123123; i++) {
            d += _a;
        }
        for (uint i = 0; i < 12312321; i++) {
            d += _a;
        }
        
        count += d;
    }

    function someMethod5(
        uint256 _a,
        uint256 _b,
        uint256 _c
        ) public onlyOwner {

        count += _b;
        uint d = _b + _c;
        for (uint i = 0; i < 1020202; i++) {
            d += _a;
        }
        for (uint i = 31; i < 123; i++) {
            d += _a;
        }
        for (uint i = 0; i < 14141; i++) {
            d += _a;
        }
        for (uint i = 0; i < 1515514; i++) {
            d += _a;
        }
        for (uint i = 3; i < 123123123; i++) {
            d += _a;
        }
        for (uint i = 4; i < 12312321; i++) {
            d += _a;
        }
        for (uint i = 5; i < 1020202; i++) {
            d += _a;
        }
        for (uint i = 5; i < 123; i++) {
            d += _a;
        }
        for (uint i = 5; i < 14141; i++) {
            d += _a;
        }
        for (uint i = 0; i < 1515514; i++) {
            d += _a;
        }
        for (uint i = 0; i < 123123123; i++) {
            d += _a;
        }
        for (uint i = 0; i < 12312321; i++) {
            d += _a;
        }

        for (int y = 2; y < 2000; y++) {
            d += 1;
            d += 2;
            d += 3;
            d += 4;
            d += 5;
        }

        if (count == 1) {
            something = "oaiwjefoaiwjefoawieawefefawefawefawefjfoawiejfoawijefoawijefoiawejf";
        } else if (count == 2) {
            something = "eoawafeeaewijweoifjaeowifaweawefeawefawefwfaeaweawefawefaweffeaweffafwejawoefijwaoiejf";
        } else if (count == 3) {
            something = "eoaijweoifjaeowfaaweaewaefawefawefawefawefawefweawaefefwfwifjawoefijwaoiejf";
        } else {
            something = "SOIEJOFEIJMTHING";
        }
        
        count += d;

        stringMapping[d++] = "aawejofijajio;jio;wefoiwaefoia;jio;jio;iwjefoawij";
        stringMapping[d++] = "awewefawefawjio;jio;jio;jiefwaefawefawefawef";
        stringMapping[d++] = "awefawefaiho;jio;wefawefawoi;oijo;jio;;ijoefawef";
        stringMapping[d++] = "awewefawefawefwaefa12e12e3qw;jio;jio;efawefawef";
        stringMapping[d++] = "awewefawefawekgiulhofwaefac34r34tvwg54wefawefawef";
        stringMapping[d++] = "awewefawefawefwaefa545f54f545f4wefawefawef";
        stringMapping[d++] = "awewefawefawefhtyjyuwaef23424ajio;jio;wefawefawef";
        stringMapping[d++] = "awewefawefawefwaergserhdrtefafaweg5f3wefawefawef";
        stringMapping[d++] = "awewefawefawefwaefa2342o;io;jjio;io;io;wefawefawef";
        stringMapping[d++] = "awewefawefawefw12341243aefawefjio;jio;jio;jioawefawef";
        stringMapping[d++] = "awewefawefawefwaeffawefawe34234awefawefawef";
        stringMapping[d++] = "awewefawefawefwa23o;ijo;jio;4efawefawefawef";
        stringMapping[d++] = "awewefawefawefq223efwaefwerwaefawefawefawef";
        stringMapping[d++] = "awewefawefawefwaefawefqr;jio;jio;jiwaefawefawefawef";
        stringMapping[d++] = "awewefawefawefwfaawefawefawwaefawefawefawef";
        stringMapping[d++] = "awewefawefawefawarawae;jio;jiofawefawefawef";
        stringMapping[d++] = "awewefawefawefawrwaefaw;jio;jio;jioefawefawef";
        stringMapping[d++] = "awewefawefawefww3aijo;jio;jiofaefawefawefawef";
    }

    
    function AnotherMethod(
        uint256 _a,
        uint256 _b,
        uint256 _c
        ) public onlyOwner {
        count = 12345 + _a + _b + _c;
    }
}

contract ZZReproReport {
    address public owner;

    mapping(uint256 => ZZReproReportChild) public children;
    uint256 public childCount;

    uint public randomValue;

    mapping (uint => string) public stringMapping;

    event SomeEvent(
    uint256 indexed hello1,
    uint256 indexed hello2,
    uint256 hello3,
    uint256 hello4,
    uint256 hello5);

    event SomeEvent2(
    uint256 indexed hello1,
    uint256 indexed hello2,
    uint256 hello3,
    uint256 hello4,
    uint256 hello5);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner contract can call functions on this contract");
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function requireContractExists(uint256 _id, bool _shouldExist) private view {
        address ctr = address(children[_id]);
        bool ctrExists = ctr != address(0);
        if (_shouldExist) {
            require(ctrExists == _shouldExist, "A contract does not yet exist.");
        } else {
            require(ctrExists == _shouldExist, "A contract already exists.");
        }
    }

    function createChild(string memory _name, uint256 _id) public onlyOwner {
        requireContractExists(_id, false);
        
        ZZReproReportChild child = new ZZReproReportChild(_id, _name);
        children[_id] = child;
        childCount++;
    }
   
    function callAMethod1(uint256 _id, uint _a, uint _b, uint _c) public {
        requireContractExists(_id, true);
        ZZReproReportChild child = children[_id];

        child.someMethod1(_a, _b, _c, 1234);
    }

    function callAMethod2(uint256 _id) public {
        requireContractExists(_id, true);
        ZZReproReportChild child = children[_id];

        child.someMethod2(_id, 5, 12);
    }

    function getCount(uint256 _id) public view returns (uint256 count) {
        requireContractExists(_id, true);
        ZZReproReportChild child = children[_id];

        count = child.getCount();
    }

    function setCount(uint256 _id, uint256 _count) public {
        requireContractExists(_id, true);
        ZZReproReportChild child = children[_id];

        child.setCount(_count);
    }
}