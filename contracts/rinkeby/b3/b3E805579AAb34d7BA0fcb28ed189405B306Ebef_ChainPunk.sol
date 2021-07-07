// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.2;

/* Punks ON CHAIN
   Not affiliated with Larva Labs.

   Stores a lossless encoding of every punk image and traits in contract storage.

   SVG representation of each punk is available directly from the solidity function getPunkSVG(id). 
   A string of traits is returned from getPunkTraits(id).

   0xDEAFBEEF
   Jul 2021
 */

abstract contract PunkContract {
  function balanceOf(address a) public view virtual returns (uint256);  
}

contract ChainPunk {
  address admin_address;
  PunkContract public punkContract;  
  
  //after data is written and verified, lock()
  // can be called once to permanently lock the contract
  // (no further updates permitted)
  bool public locked;
  
  //chunks of data for punk encodings
  bytes[256] public chunks;
  //chunks of data for trait encodings
  bytes[32] public trait_chunks;

  //table of trait textual strings 
  bytes[256] trait_table;

  //table of RGB values
  bytes3[256] public color_table;
  
  struct Punk {
    //stores index into chunk data
    uint16 index; //index into chunk data
    uint16 template; //if mode==1, punk ID of the base encoding (see 'mode below)
    uint16 len; //length of encoding in bytes            
    uint8 chunk; //chunk ID of where this punk is stored

    //mode 0: full run length encoding.
    //mode 1: use the encoding specified by 'template', and add the
    //difference(delta) encoded in this punks ecndoing.
    uint8 mode; 
  }

  Punk[10000] public punks;

  //events for tracking which chunks have been written so far
  event PunkChunk(uint32 cid);
  event TraitChunk(uint32 cid);

  /* Address that called endorse(), and number of punks owned by that address
     at the time of endorsement. Queries balanceOf() of the original punks contract. */
  event Endorse(address a, int numPunks); 
  
  //addresses permitted to write data,
  // but only while locked remains false
  mapping(address => bool) allowList;

  //toggle availability of endorsement mechanism
  bool public allowEndorse;
  
  //Keep track of addresses that have endorsed this project, both in a list and a mapping
  mapping(address => bool) endorseLookup;
  mapping(uint256 => address) endorseList;
  
  uint256 public numEndorsers; //number of addresses that have endorsed

  /* Cumulative total of the number of punks owned by addresses that have endorsed.
     Snapshot taken at the time of each endorsement. Meant as a rough estimate. */
  uint256 public numPunksEndorsed; 

  uint256 public secondsTimeLock; //time lock to guarantee write access will expire in at most 60 days

  constructor() {
    admin_address = msg.sender;
    secondsTimeLock = block.timestamp + 86400*60; //guarantee write access will be locked at most 60 days from now
  }

  /* Admin privilege is simply for writing the
     the punk image  encoding and traits data.
     After lock() is called, nothing can be written by 
     anyone, ever */
  
  modifier requireWriteAccess() {
    require(admin_address == msg.sender || allowList[msg.sender],"Requires admin privileges");
    require(!locked,"Write access has been permanently locked.");
    require(block.timestamp < secondsTimeLock,"Time lock has expired, write access locked");
    require(numPunksEndorsed < 300,"Addresses owning at least 300 punks have endorsed, write access locked");    
    _;
  }
  
  modifier requireAdmin() {
    require(admin_address == msg.sender || allowList[msg.sender],"Requires admin privileges");
    _;
  }  

  function isLocked() public view returns(bool) {
    if (locked) return true;
    if (block.timestamp >= secondsTimeLock) return true;
    if (numPunksEndorsed >= 300) return true;
    return false;	 
  }
  
  /* Lock contract permanently, preventing any further writes */
  function lock() public requireAdmin {
    locked=true;
  }


  /* pause endorsement until initial data is written,
     to prevent premature locking. */
  function toggleAllowEndorse(bool b) public requireWriteAccess {
    allowEndorse = b;
  }
  
  function setPunkContractAddress(address a) public requireWriteAccess {
    punkContract = PunkContract(a);
  }
  
  //mechanism for an address to "endorse" this contract.
  function endorse() public virtual {
    require(allowEndorse,"Endorsement access paused");
    
    address a = msg.sender;    
    require(!endorseLookup[a],"Address has already endorsed");

    uint256 num_owned_punks = punkContract.balanceOf(a);
    require(num_owned_punks > 0, "Only punk owners can endorse");
    
    endorseLookup[a] = true;
    endorseList[numEndorsers] = a;
    numEndorsers++;
    numPunksEndorsed += num_owned_punks;
  }

  //check if an address has endorsed
  function hasEndorsed(address a) public view returns (bool) {
    return (endorseLookup[a]);
  }

  //query list of endorsers by index
  function endorseListByIndex(uint256 i) public view returns (address){
    require(i < numEndorsers,"Out of range");
    return (endorseList[i]);
  }  

  // grant access for writing chunks of data. locked after
  function grantAccess(address a)  public requireWriteAccess virtual {
    if (!allowList[a]) {
      allowList[a] = true;
    }
  }
  
  /* Read the indexed table of traits */
  function getTraitTable(uint8 id) public view returns (string memory) {
    bytes memory s = new bytes(256);
    uint p = 0;
    for (uint z=0;z<trait_table[id].length;z++) s[p++] = trait_table[id][z];
    return string(s);
  }


  /* Returns comma delimited string of traits */
  function getPunkTraits(uint16 id) public view returns (string memory) {
    require(id < 10000);
    bytes memory s = new bytes(256); 

    //there are 500 punks in each trait_chunk, 16 bytes zero padded per punk
    uint16 cid = id/500; //calculate the chunk id
    uint16 a = (id-(cid*500)) * 16; //offset into chunk to read traits
    
    uint16 i= 0;
    uint k = 0;    
    while (i < 16) {
      uint8 tid = uint8(trait_chunks[cid][a + i]);
      if (tid==0) break;

      if (i > 0) {
	s[k++] = ",";
	s[k++] = " ";
      }            
      for (uint z=0;z<trait_table[tid].length;z++) s[k++] = trait_table[tid][z];
      i++;      
    }
    return string(s);
  }

  /* Upload a chunk of trait data */
  function setTraitChunk(uint8 cid, bytes calldata b) public requireWriteAccess {
    require(cid < 32);  
    trait_chunks[cid] = bytes(b);  
    emit TraitChunk(cid);    
  }

  /* Upload the indexed trait table */
  function setTraitTable(bytes calldata b) public requireWriteAccess {
    uint i = 0;
    while (i < b.length) {
      uint8 id = uint8(b[i]);
      uint8 len = uint8(b[i+1]);
      i += 2;
      trait_table[id] = bytes(b[i:i+len]);
      i += len;
    }
  }
  
  /* Upload chunk of punk encoding data */
  function setPunks(uint8 cid, bytes calldata b) public requireWriteAccess {
    require(cid < 256);

    chunks[cid] = bytes(b);

    uint i = 0;
    uint32 id;
    uint32 total_len = 0;

    while (i < b.length) {
      id = uint8(b[i]) *(2**8) + uint8(b[i+1]);      
      uint8 mode = uint8(b[i+2]);
      uint16 tid = 0;
      if (mode==1) tid = uint8(b[i+3]) *(2**8) + uint8(b[i+4]);
      uint16 len = uint8(b[i+5]) *(2**8) + uint8(b[i+6]);

      punks[id].mode = mode;
      if (mode==1) 
	punks[id].template = tid;
      
      i += 7;
      punks[id].chunk = cid; //chunk id
      punks[id].index = uint16(i); //index into chunk
      punks[id].len = len; //data length
      
      i += len;
      total_len += len;
    }
    emit PunkChunk(cid);    
  }

  /* Upload indexed table of RGB values 
     format byte 0: index, byte1: r value, byte2: g value, byte3: b value */
  function setColors(bytes memory b) public requireWriteAccess {
    for (uint k = 0;k<b.length;k+=4) {
      uint8 i= uint8(b[k]);
      bytes3 c = b[k+1] | bytes3(b[k+2]) >> 8 | bytes3(b[k+3]) >> 8*2;
      color_table[i] = c;
    }
  }

  /* Read the indexed color table. Returns RGB value for an index */
  function getColor(uint8 i) public view returns (uint8 r, uint8 g, uint8 b) {
    r =  uint8(color_table[i][0]);
    g =  uint8(color_table[i][1]);
    b =  uint8(color_table[i][2]);        
  }

  /* Retrieves an array of color table indexes corresponding to pixels of the punk image.
     
     In mode 0, expands a run length encoding (RE) of the punk image.
     In mode 1, a similar base punk specified by punks[id].templte is first decoded,
                followed by an update of the difference(delta) between them 
  */
  function decodePunk(uint32 id) public view returns (uint8[576] memory) {
    require(id < 10000);
    
    uint8[576] memory dst;
    uint32 tid = id;
    if (punks[id].mode==1) {
      //in mode 1, we first decode another similar punk, and then just add the difference
      tid = punks[id].template;
    }

    //undo run length encoding of punk tid
    uint k = 0;
    uint16 cid = punks[tid].chunk;    
    uint p=punks[tid].index;
    while (k < 24*24 && p < punks[tid].index + punks[tid].len) {
      uint8 col = uint8(chunks[cid][p++]);
      uint8 rl = uint8(chunks[cid][p++]);
      for (uint i=0;i<rl;i++)
	dst[k++] = col;
    }

    //now optionally add difference encoded
    if (punks[id].mode==1) {
      //in mode 1, after decoding the base template punk, 
      // we add the delta (difference)
      k=0;
      p=punks[id].index;
      cid = punks[id].chunk;
      while (k < 24*24 && p < punks[id].index + punks[id].len) {      
	uint8 col = uint8(chunks[cid][p++]);
	uint8 rl = uint8(chunks[cid][p++]);
	for (uint i=0;i<rl;i++) {
	  if (col ==255) {
	    dst[k] =0;
	  } else if (col != 0) {
	    dst[k] = col;
	  }
	  k++;	  
	}
      }      
    }
    return dst;
  }

  /* Calls decodePunk, then outputs an ASCII string of color table indices. */
  function getPunkASCII(uint32 id) public view returns (string memory) {
    require(id < 10000);

    uint8[576] memory dst = decodePunk(id);
    bytes memory s = new bytes(10000); 
    
    uint p = 0;
    uint k = 0;
    bytes memory num;    
    for (uint x=0;x<24;x++) {
      for (uint y=0;y<24;y++) {
	num = numtostring(dst[k]);
	for (uint z=0;z<num.length;z++) s[p++] = num[z];
	s[p++] = ' ';
	k++;
      }
      s[p++] = '\n';
    }

    return string(s);
  }

  /* Calls decodePunk, and using indices into RGB color table,
     directly outputs an SVG representation of the pixels.
  */
  function getPunkSVG(uint32 id) public view returns (string memory) {
    require(id < 10000);

    uint8[576] memory dst = decodePunk(id);
    bytes memory h = "<svg version='1.1'  baseProfile='full'  width='240' height='240' xmlns='http://www.w3.org/2000/svg'>";
    bytes memory b = "<rect x='X' y='Y' width='10' height='10' style='fill:#RGB;' />";
    bytes memory f = "</svg>";
    
    bytes memory s = new bytes(30000); 
    
    uint p = 0;
    uint k = 0;
    bytes memory num;
    //add svg header
    for (uint i=0;i<h.length;i++) s[p++] = h[i];

    //add svg rect for every non-transparent pixel
    for (uint y=0;y<24;y++) {    
      for (uint x=0;x<24;x++) {
	if (dst[k]==0) { k++; continue; }
	
	for (uint i=0;i<b.length;i++) {
	  if (b[i]=='X') {
	    num = numtostring(x*10);
	    for (uint z=0;z<num.length;z++) s[p++] = num[z];
	  } else if (b[i]=='Y') {
	    num = numtostring(y*10);
	    for (uint z=0;z<num.length;z++) s[p++] = num[z];	    
	  } else if (b[i]=='R') {
	    num = numtohex(uint8(color_table[dst[k]][0]));
	    for (uint z=0;z<num.length;z++) s[p++] = num[z];	    
	  } else if (b[i]=='G') {
	    num = numtohex(uint8(color_table[dst[k]][1]));
	    for (uint z=0;z<num.length;z++) s[p++] = num[z];	    
	  } else if (b[i]=='B') {
	    num = numtohex(uint8(color_table[dst[k]][2]));
	    for (uint z=0;z<num.length;z++) s[p++] = num[z];
	  } else {  
	    s[p++] = b[i];
	  }
	}
	k++;
      }
    }

    //add svg footer
    for (uint i=0;i<f.length;i++)s[p++] = f[i];
    return string(s);
  }

  /* helper function or translating uint8 to ASCII characters of
     hex values. For writing RGB values in the SVG */
  function numtohex(uint8 i) private pure returns (bytes memory) {
    bytes memory s = new bytes(2);
    
    uint8 a = i & 0x0f;
    a = (a < 10 ? a+48: a+55);

    uint8 b = i & 0xf0;
    b >>= 4;
    b = (b < 10 ? b+48: b+55);
    
    s = abi.encodePacked(b,a);
    return(s);
  }    

  /* helper function to translate uint to ASCII representation
     of decimal value (3 digits max) */
  function numtostring(uint i) private pure returns (bytes memory) {
    bytes memory s;
    uint h = i/100;
    uint t = (i-h*100)/10;
    uint o = (i-h*100-t*10);

    if (h != 0) {
      s = new bytes(3);
      s = abi.encodePacked(uint8(h+48),uint8(t+48),uint8(o+48));
    } else if (t != 0) {
      s = new bytes(2);            
      s = abi.encodePacked(uint8(t+48),uint8(o+48));      
    } else {
      s = new bytes(1);                  
      s = abi.encodePacked(uint8(o+48));            
    }
    return(s);
  }

}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}