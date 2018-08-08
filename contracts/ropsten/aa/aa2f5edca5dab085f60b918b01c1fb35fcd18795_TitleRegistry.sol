pragma solidity ^0.4.8;

contract Owned {

    function owned() { owner = msg.sender; }

    address public owner;
    string public name;

    modifier onlyOwner {
        if (msg.sender != owner)
            throw;
        _;
    }

    function getName() constant returns (string) {
      return name;
    }

    function getOwner() constant returns (address) {
      return owner;
    }

}

contract Mortal is Owned {

    function close() onlyOwner {
        selfdestruct(owner);
    }

    function toAsciiString(address x) internal returns (string) {
        bytes memory s = new bytes(40);
        for (uint256 i = 0; i < 20; i++) {
            byte b = byte(uint8(uint256(x) / (2**(8*(19 - i)))));
            byte hi = byte(uint8(b) / 16);
            byte lo = byte(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);
        }
        return string(s);
    }

    function char(byte b) internal returns (byte c) {
        if (b < 10) return byte(uint8(b) + 0x30);
        else return byte(uint8(b) + 0x57);
    }

    function csvConcat(string _a, string _b, string _c, string _d) internal constant returns (string){
        string memory _s = ",";
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _bsep = bytes(_s);
        string memory abcd = new string(_ba.length + _bb.length + _bc.length + _bd.length +  4 * (_bsep.length));
        bytes memory babcd = bytes(abcd);
        uint256 k = 0;
        for (uint256 i = 0; i < _ba.length; i++) babcd[k++] = _ba[i];
        for (i = 0; i < _bsep.length; i++) babcd[k++] = _bsep[i];
        for (i = 0; i < _bb.length; i++) babcd[k++] = _bb[i];
        for (i = 0; i < _bsep.length; i++) babcd[k++] = _bsep[i];
        for (i = 0; i < _bc.length; i++) babcd[k++] = _bc[i];
        for (i = 0; i < _bsep.length; i++) babcd[k++] = _bsep[i];
        for (i = 0; i < _bd.length; i++) babcd[k++] = _bd[i];
        return string(babcd);
    }

}

contract TitleRegistry is Mortal{

    struct IndexValue { uint256 keyIndex; string tttId; string khasraNo; string adhaarNo; }
    struct KeyFlag { bytes32 key; bool deleted; }
	 

	 struct itmap
    {
        mapping(bytes32 => IndexValue) data;
        KeyFlag[] keys;
        uint256 size;
    }

    itmap tttIdToTransfers;

    function TitleRegistry(){
       name = "TitleRegistry";
       owned();
   }
   
 

    // Insert new TitleTransfer
    function addTitleTransfer(string tttId, string khasraNo, string adhaarNo) returns (uint256 size)
    {
        // Actually calls itmap_impl.insert, auto-supplying the first parameter for us.
        insert(tttId, khasraNo, adhaarNo);
        // We can still access members of the struct - but we should take care not to mess with them.
        size = tttIdToTransfers.size;
    }
	
	
	
	 // Insert new TitleTransfer
    function removeTitleTransfer(string tttId) returns (uint256 size)
    {
        // Actually calls itmap_impl.insert, auto-supplying the first parameter for us.
        remove(tttId);
        // We can still access members of the struct - but we should take care not to mess with them.
        size = tttIdToTransfers.size;
    }
    
     // Insert new TitleTransfer
    function updateTitleTransfer(string tttId, string khasraNo, string adhaarNo) returns (uint256 size)
    {
        update(tttId, khasraNo,  adhaarNo);
        // We can still access members of the struct - but we should take care not to mess with them.
        size = tttIdToTransfers.size;
    }
	
	
	
    // Get loan address
    function getTTTAddress(string tttId)  constant returns (string , string )
    {
        // We can still access members of the struct - but we should take care not to mess with them.
        //(khasraNo,adhaarNo) = 
		return get(tttId);
    }

    // Get loan address
    function getTTTInfo(uint256 index) constant returns (string , string , string )
    {
       // (tttId,khasraNo,adhaarNo) = iterate_get(index);
        
        return iterate_get(index);
    }


    // Get loan address
    function getTTTCount() constant returns (uint256)
    {
        // We can still access members of the struct - but we should take care not to mess with them.
      	return tttIdToTransfers.size;    
    }

    function insert(string tttId, string khasraNo, string adhaarNo) internal returns (bool replaced)
    {
        bytes32 key = sha3(tttId);
        uint256 keyIndex = tttIdToTransfers.data[key].keyIndex;
        tttIdToTransfers.data[key].tttId = tttId;
        tttIdToTransfers.data[key].khasraNo = khasraNo;
		tttIdToTransfers.data[key].adhaarNo = adhaarNo;
        if (keyIndex > 0)
            return true;
        else
        {
            keyIndex = tttIdToTransfers.keys.length++;
            tttIdToTransfers.data[key].keyIndex = keyIndex + 1;
            tttIdToTransfers.keys[keyIndex].key = key;
            tttIdToTransfers.size++;
            return false;
        }
    }

    function remove(string tttId) internal returns (bool success)
    {
        bytes32 key = sha3(tttId);
        uint256 keyIndex = tttIdToTransfers.data[key].keyIndex;
        if (keyIndex == 0)
        return false;
        delete tttIdToTransfers.data[key];
        tttIdToTransfers.keys[keyIndex - 1].deleted = true;
        //tttIdToTransfers.size --;
    }
	
	 function update(string tttId,string khasraNo, string adhaarNo) internal returns (bool success)
    {
        bytes32 key = sha3(tttId);
        uint256 keyIndex = tttIdToTransfers.data[key].keyIndex;
        if (keyIndex == 0)
        return false;
        tttIdToTransfers.data[key].khasraNo = khasraNo;
        tttIdToTransfers.data[key].adhaarNo = adhaarNo;
       
    }
	
	

    function get(string tttId) internal  returns (string, string)
    {
        bytes32 key = sha3(tttId);
        return (tttIdToTransfers.data[key].khasraNo, tttIdToTransfers.data[key].adhaarNo);
    }

    function contains(string tttId) internal  returns (bool)
    {
        bytes32 key = sha3(tttId);
        return tttIdToTransfers.data[key].keyIndex > 0;
    }

    function iterate_start() internal  returns (uint256 keyIndex)
    {
        return iterate_next( uint256(-1));
    }

    function iterate_valid(uint256 keyIndex) internal returns (bool)
    {
        return keyIndex < tttIdToTransfers.keys.length;
    }

    function iterate_next(uint256 keyIndex) internal returns (uint256 r_keyIndex)
    {
        keyIndex++;
        while (keyIndex < tttIdToTransfers.keys.length && tttIdToTransfers.keys[keyIndex].deleted)
        keyIndex++;
        return keyIndex;
    }

    function iterate_get(uint256 keyIndex) internal returns (string tttId, string khasraNo, string adhaarNo)
    {
		KeyFlag flag = tttIdToTransfers.keys[keyIndex];
		if(!flag.deleted){
			bytes32 key = tttIdToTransfers.keys[keyIndex].key;
			tttId = tttIdToTransfers.data[key].tttId;
			khasraNo = tttIdToTransfers.data[key].khasraNo;
			adhaarNo = tttIdToTransfers.data[key].adhaarNo;
		}
    }
	
	
	
	 
}