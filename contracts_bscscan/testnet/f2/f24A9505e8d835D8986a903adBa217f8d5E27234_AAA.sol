/**
 *Submitted for verification at BscScan.com on 2021-08-06
*/

pragma solidity =0.6.6;
pragma experimental ABIEncoderV2;

contract TestCase {
    
    using IterableAppendOnlySet for IterableAppendOnlySet.Data;
    using IDToAddress for IDToAddress.Data;
    
    IterableAppendOnlySet.Data public data;
    IDToAddress.Data public data2;
    
    
    function insert(address _v) public returns (bool){
        return data.insert(_v);
    }
    function remove(address _v) public returns(bool){
        return data.remove(_v);
    }
    
    function contains(address _v) public view returns(bool){
        return data.contains(_v);
    }
    function first() public view returns(address){
        return data.first();
    }
    function last() public view returns(address){
        return data.last;
    }
    function front(address _v) public view returns(address){
        return data.front(_v);
    }
    function next(address _v) public view returns(address){
        return data.next(_v);
    }
    
    
    function idInsert(address addr) public returns (bool){
        require(data2.insert(addr));
        return true;
    }
    function idDo(uint16 id) public view returns (bool){
        return data2.isId(id);
    }
    function idDo(address addr) public view returns(bool){
        return data2.isAddress(addr);
    }
    function idAddress(uint16 id) public view returns (address){
        return data2.getAddressAt(id);
    }
    function idID(address addr) public view returns(uint16){
        return data2.getId(addr);
    }
    
    function idCount() public view returns (uint16){
        return data2.idCount;
    }
    
    
}

contract AAA {
    using SafeMath for *;
    
    using ABox for ABox.Data;
    
    ABox.Data public boxer;
    // address public callOwner;
    // uint public x;
    
    
    function aset1(address a, uint[] memory b , address c, uint8[] memory d) public{
        
    }
    function aset2(address a, uint8[] memory b , address c, uint[] memory d) public{
        
    }
    function aset3(address[] memory a, uint8[] memory b , address[] memory c, uint[] memory d) public{
        
    }
    function aset33(address[] memory a, uint[] memory b , address[] memory c, uint[] memory d) public{
        
    }
    function aset4(address[] memory a) public{
        
    }
    function aset5(uint8[] memory a) public{
        
    }
    function aset6(uint128[] memory a) public{
        
    }
    function aset7(uint[] memory a) public{
        
    }
    function aset8(string memory a) public{
        
    }
    function aset9(string[] memory a) public{
        
    }
    
    
    
    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
    
    function selfBurn() public {
        selfdestruct(msg.sender);
    }
    
    function setX(uint _x) public{
        //boxer.add(msg.sender , _x);
        boxer.owner = msg.sender;
        boxer.x = _x;
        
        // x = _x;
        // callOwner = msg.sender;
    }
    
    function addressToInt() public view returns (uint){
        return uint(msg.sender);
    }
    function intToAddress(uint v) public pure returns (address){
        return address(v);
    }
    function toBytes() public view returns (bytes memory) {
        return abi.encodePacked(msg.sender);
    }
    function bytesToAddress(bytes memory bys) private pure returns (address payable addr) {
        assembly {
            addr := mload(add(bys,20))
        }
    }
    
    receive() payable external{
        assert(msg.value > 0);
    }
    
    function mydie() public{
        selfdestruct(msg.sender);
    }
    
}

interface IC {
    function setX(uint _x) external;
}


contract BBB{
    using ABox for ABox.Data;
    
    ABox.Data public boxer;
    
    
    address public callOwner1;
    uint public x;
    
    
    
    address public callOwner;
    
    
    
    receive() payable external{
        
    }
    
    // function setX(uint _x) public{
    //     x = _x;
    //     callOwner2 = msg.sender;
    // }
    
    function callAAA(address aaa, uint _x) public{
        IC(aaa).setX(_x);
    }
    function callDelAAA(address aaa, uint _x) public returns (bytes memory re){
        (bool success, bytes memory data) = aaa.delegatecall(abi.encodeWithSignature("setX(uint256)", _x));
        require(success ,'ERR_1');
        re = data;
        
    }
    

    function callDelAAA2(address aaa, string memory funcName, uint _x) public {
        bytes memory buf = abi.encodeWithSignature(funcName, _x);
        uint bufSize = buf.length;
        
        
        address impl = aaa;
        assembly {
            let result := delegatecall(gas(), impl , buf , bufSize, 0,0)
            // let size := returndatasize()
            // returndatacopy(ptr, 0, size)
            
            switch result
            case 0 { revert(false, 'ERR_X') }
            
        }
        
        // require(result != 0, 'ERR_X');
    }
    
}
library ABox {
    struct Data {
        address owner;
        uint x;
    }
    
    function add(Data storage data, address _owner, uint _x) public {
        data.owner = _owner;
        data.x = _x;
    }
}







//SafeMath :
library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'math_add_over');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'math_sub_over');
    }
    function sub128(uint x , uint y) internal pure returns (uint128 z){
        return uint128(sub(x , y));
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'math_mul_over');
    }

    function div(uint x, uint y) internal pure returns (uint z){
        require(y > 0, 'math_div_0');
        z = x / y;
    }

    function mod(uint x, uint y) internal pure returns (uint z){
        require(y != 0, 'math_mod_0');
        z = x % y;
    }

    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}



library IterableAppendOnlySet {
    struct Data {
        mapping(address => address) prevMap;
        mapping(address => address) nextMap;
        address last;
        uint256 size; // width is chosen to align struct size to full words
    }

    function insert(Data storage self, address value) public returns (bool) {
        if (contains(self, value)) {
            return false;
        }
        self.prevMap[value] = self.last;
        self.nextMap[self.last] = value;
        self.last = value;
        self.size += 1;
        return true;
    }
    function remove(Data storage self, address value) public returns(bool){
        require(value != address(0), "Inserting address(0) is not supported");
        if (self.nextMap[value] == address(0) && self.prevMap[value] == address(0)){
            if (self.nextMap[address(0)] != value){
                return false;
            }
        }
        
        if (self.last == value){
            if (self.size > 1){
                self.last = self.prevMap[value];
                delete self.prevMap[value];
                delete self.nextMap[self.last];
            }else{
                self.last = self.prevMap[value];
                //delete self.prevMap[value];
                delete self.nextMap[address(0)];
            }
        }else{
            address fC = value;
            address fB = self.prevMap[fC];
            address fD = self.nextMap[fC];
            self.prevMap[fD] = fB;
            self.nextMap[fB] = fD;
            
            delete self.prevMap[fC];
            delete self.nextMap[fC];
        }
        
        
        self.size -= 1;
        return true;
    }

    function contains(Data storage self, address value) public view returns (bool) {
        require(value != address(0), "Inserting address(0) is not supported");
        return self.nextMap[value] != address(0) || (self.last == value);
    }

    function first(Data storage self) public view returns (address) {
        return self.nextMap[address(0)];
    }
    
    function front(Data storage self, address value) public view returns(address){
        require(contains(self, value), "Trying to get before of non-existent element");
        return self.prevMap[value];
    }

    function next(Data storage self, address value) public view returns (address) {
        require(contains(self, value), "Trying to get next of non-existent element");
        return self.nextMap[value];
    }
}

library IDToAddress{
    struct Data{
        mapping(uint16 => address) idmap;
        mapping(address => uint16) addrmap;
        uint16 idCount;
        uint16 size;
    }
    function isId(Data storage self, uint16 id) public view returns (bool) {
        return self.idmap[id + 1] != address(0);
    }

    function isAddress(Data storage self, address addr) public view returns (bool) {
        return self.addrmap[addr] != 0;
    }

    function getAddressAt(Data storage self, uint16 id) public view returns (address) {
        require(self.idmap[id + 1] != address(0), "Must have ID to get Address");
        return self.idmap[id + 1];
    }

    function getId(Data storage self, address addr) public view returns (uint16) {
        require(self.addrmap[addr] != 0, "Must have Address to get ID");
        return self.addrmap[addr] - 1;
    }
    
    function insert(Data storage self, address addr) public returns (bool) {
        require(addr != address(0), "Cannot insert zero address");
        require(self.idCount != uint16(-1), "Cannot insert max uint16");
        // Ensure bijectivity of the mappings
        if (self.addrmap[addr] != 0) {
            return false;
        }
        self.idCount++;
        self.idmap[self.idCount] = addr;
        self.addrmap[addr] = self.idCount;
        self.size++;
        return true;
    }
    
    function remove(Data storage self, address addr) public returns(bool){
        require(addr != address(0) && self.addrmap[addr] != 0 && self.size != 0, "Cannot insert zero address");
        delete self.idmap[self.addrmap[addr]];
        delete self.addrmap[addr];
        self.size--;
        return true;
    }
    
    function remove(Data storage self, uint16 id) public returns(bool){
        require(self.idmap[id] != address(0) && self.size != 0 , "not found id");
        delete self.addrmap[self.idmap[id]];
        delete self.idmap[id];
        self.size--;
        return true;
    }
}