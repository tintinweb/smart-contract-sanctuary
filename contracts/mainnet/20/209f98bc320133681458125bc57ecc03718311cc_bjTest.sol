pragma solidity ^0.4.21;
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
        if(a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a / b;
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        assert(b <= a);
        return a - b;
    }
    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}
contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    modifier onlyOwner() { require(msg.sender == owner); _; }
    function Ownable() public { 
	    owner = msg.sender; 
		}
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(this));
        owner = newOwner;
        emit OwnershipTransferred(owner, newOwner);
    }
}
contract bjTest is Ownable {
    using SafeMath for uint256;
    uint256 public JoustNum = 1; 
    uint256 public NumberOfPart = 0; 
    uint256 public Commission = 0.024 * 1 ether; 
    uint256 public RateEth = 0.3 * 1 ether; 
    uint256 public TotalRate = 2.4 * 1 ether; 
    struct BJJtab { 
        uint256 JoustNumber;
        uint256 UserNumber;       
        address UserAddress; 
        uint256 CoincidNum;   
        uint256 Winning; 
    }
    mapping(uint256 => mapping(uint256 => BJJtab)) public BJJtable; 
    struct BJJraundHis{
        uint256 JoustNum; 
        uint256 CapAmouth; 
        uint256 BetOverlap; 
        string Cap1;
        string Cap2;
        string Cap3;
    }
    mapping(uint256 => BJJraundHis) public BJJhis;
    uint256 public AllCaptcha = 0; 
    uint256 public BetOverlap = 0; 
    event BJJraund (uint256 UserNum, address User, uint256 CoincidNum, uint256 Winning);
    event BJJhist (uint256 JoustNum, uint256 CapAllAmouth, uint256 CapPrice, string Cap1, string Cap2, string Cap3);
    /*Всупление в игру*/
    function ApushJoustUser(address _address) public onlyOwner{       
        NumberOfPart += 1;      
        BJJtable[JoustNum][NumberOfPart].JoustNumber = JoustNum;
        BJJtable[JoustNum][NumberOfPart].UserNumber = NumberOfPart; 
        BJJtable[JoustNum][NumberOfPart].UserAddress = _address;
        BJJtable[JoustNum][NumberOfPart].CoincidNum = 0;
        BJJtable[JoustNum][NumberOfPart].Winning = 0; 
        if(NumberOfPart == 8){
            toAsciiString();
            NumberOfPart = 0;
            JoustNum += 1;
            AllCaptcha = 0;
        }
    }
    function ArJoust(uint256 _n, uint256 _n2) public view returns(uint256){
        //var Tab = BJJtable[_n][_n2];
        return BJJtable[_n][_n2].CoincidNum;
    }    
    string public Ast;
    string public Bst;
    string public Cst;
    uint256 public  captcha = 0;     
    uint public gasprice = tx.gasprice;
    uint public blockdif = block.difficulty;
    function substring(string str, uint startIndex, uint endIndex, uint256 Jnum, uint256 Usnum) public returns (string) {
    bytes memory strBytes = bytes(str);
    bytes memory result = new bytes(endIndex-startIndex);
    for(uint i = startIndex; i < endIndex; i++) {
        result[i-startIndex] = strBytes[i];
        if(keccak256(strBytes[i]) == keccak256(Ast) || keccak256(strBytes[i]) == keccak256(Bst) || keccak256(strBytes[i]) == keccak256(Cst)){ 
            BJJtable[Jnum][Usnum].CoincidNum += 1; 
            AllCaptcha += 1;
        }
    }
    return string(result);
    }
    uint256 public Winn;
    function Distribution() public {

        BetOverlap = (TotalRate - Commission) / AllCaptcha; 
        BJJhis[JoustNum].JoustNum = JoustNum;
        BJJhis[JoustNum].CapAmouth = AllCaptcha; 
        BJJhis[JoustNum].BetOverlap = BetOverlap; 
        BJJhis[JoustNum].Cap1 = Ast;
        BJJhis[JoustNum].Cap2 = Bst;
        BJJhis[JoustNum].Cap3 = Cst;        
        emit BJJhist(JoustNum, AllCaptcha, BetOverlap, Ast, Bst, Cst);         
        for(uint i = 1; i<9; i++){
            BJJtable[JoustNum][i].Winning = BJJtable[JoustNum][i].CoincidNum * BetOverlap;
            Winn = BJJtable[JoustNum][i].Winning;
            emit BJJraund(BJJtable[JoustNum][i].UserNumber, BJJtable[JoustNum][i].UserAddress, BJJtable[JoustNum][i].CoincidNum, Winn);
        }
    }
    function toAsciiString() public returns (string) {
    Random();
    for(uint a = 1; a < 9; a++){  
    address x = BJJtable[JoustNum][a].UserAddress; 
    bytes memory s = new bytes(40);
    for (uint i = 0; i < 20; i++) {
        byte b = byte(uint8(uint(x) / (2**(8*(19 - i)))));
        byte hi = byte(uint8(b) / 16);
        byte lo = byte(uint8(b) - 16 * uint8(hi));
        s[2*i] = char(hi);
        s[2*i+1] = char(lo);            
    }
    substring(string(s), 20, 40, JoustNum, a); 
    }
    Distribution();
    return string(s);
    }

    function char(byte b) public pure returns(byte c) {
        if (b < 10){ return byte(uint8(b) + 0x30); } else {
            return byte(uint8(b) + 0x57); }
    }
    string[] public arrint = ["0","1","2","3","4","5","6","7","8","9"];
    string[] public arrstr = ["a","b","c","d","e","f"];
    uint256 public randomA;
    uint256 public randomB;
    uint256 public randomC;
    function Random() public{
        randomA = uint256(block.blockhash(block.number-1))%9 + 1; //uint
        randomC = uint256(block.timestamp)%9 +1; //uint
        randomB = uint256(block.timestamp)%5 +1; // str
        Ast = arrint[randomA];
        Cst = arrint[randomC]; 
        Bst = arrstr[randomB];
    }   
    function kill() public onlyOwner {
        selfdestruct(msg.sender);
    }

}