// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.2;

//import "hardhat/console.sol";

/* 
TODO
trait table import
*/

contract ChainPunk {
  bytes[10000] public punks;
  bytes[10000] public punk_traits;
  
  bytes[256] trait_table;
  
  uint8[10000] public punk_mode;
  uint16[10000] public punk_template;  

  event Encoded(uint32 punk_id);
  
  bytes3[256] public color_table;

  constructor() {
  }

  /*
  function setTraitTable(uint8[] memory tid, bytes[] memory b) public {
    for (int i=0;i<tid.length;i++) {
      trait_table[tid[i]] = b[i];
    }
  }
  */
  
  function getTraits(uint32 id) public view returns (string memory) {
    require(id < 10000);

    bytes memory s = new bytes(1000); //need to estimate the length here
    
    uint p = 0;
    uint k = 0;
    uint m = punk_traits[id].length;
    while (k < m) {
      uint8 tid = uint8(punk_traits[id][k++]);
      for (uint z=0;z<trait_table[tid].length;z++) s[p++] = trait_table[tid][z];

      if (k < m) {
	s[p++] = ",";
	s[p++] = " ";
      }
    }
    return string(s);
  }
  
  function setPunkTrait(uint32 id, bytes memory b) public {
    require(id < 10000);
    punk_traits[id] = b;
  }

  //TODO add way to add multiple traits in one transaction
  function setPunkTraits(bytes memory b) public {
    //set many traits all at once
  }  

  //add single punk encoding in one transaction
  function setPunk(uint32 id, uint8 mode, uint16 tid, bytes memory encoding) public {
    punk_mode[id] = mode;
    punk_template[id] = tid;    
    punks[id] = encoding;
  }

  //Add multiple punk encodings in one transaction
  function setPunks(bytes calldata b) public {
    uint i = 0;
    uint32 id;
    while (i < b.length) {
      id = uint8(b[i]) *(2**8) + uint8(b[i+1]);      
      uint8 mode = uint8(b[i+2]);
      uint16 tid = uint8(b[i+3]) *(2**8) + uint8(b[i+4]);
      uint16 len = uint8(b[i+5]) *(2**8) + uint8(b[i+6]);

      //      console.log("encoding punk %d, mode %d, len %d",id,mode,len);
      
      punk_mode[id] = mode;
      if (mode==1) 
	punk_template[id] = tid;
      
      i += 7;
      //      punks[id] = new bytes(len);
      for (uint k=0;k<len;k++) {
	//	punks[id][k] = b[i+k];
	punks[id].push(b[i+k]);
      }
      i += len;
    }
    emit Encoded(id);    
  }

  //format byte 0: index, byte1: r value, byte2: g value, byte3: b value
  function setColors(bytes memory b) public {
    for (uint k = 0;k<b.length;k+=4) {
      uint8 i= uint8(b[k]);
      bytes3 c = b[k+1] | bytes3(b[k+2]) >> 8 | bytes3(b[k+3]) >> 8*2;
      color_table[i] = c;
    }
  }

  //gets rgb value
  function getColor(uint8 i) public view returns (uint8 r, uint8 g, uint8 b) {
    r =  uint8(color_table[i][0]);
    g =  uint8(color_table[i][1]);
    b =  uint8(color_table[i][2]);        
  }

  //decodes punk into array of bytes of length 24x24  
  function decodePunk(uint32 id) public view returns (uint8[576] memory) {
    require(id < 10000);
    
    uint8[576] memory dst;
    uint32 tid = id;
    if (punk_mode[id]==1) {
      //in mode 1, we first decode another similar punk, and then just add the differecne
      tid = punk_template[id];
    }

    //undo run length encoding of punk tid
    uint k = 0;
    uint p=0;
    uint p2 = 0;
    while (k < 24*24 && p < punks[tid].length) {
      uint8 col = uint8(punks[tid][p++]);
      uint8 rl = uint8(punks[tid][p++]);
      for (uint i=0;i<rl;i++)
	dst[k++] = col;
    }

    //now optionally add difference encoded
    if (punk_mode[id]==1) {
      //in mode 1, after decoding the base template punk, 
      // we add the delta (difference)
      
      k=0;
      p=0;
      p2=0;
      while (k < 24*24 && p < punks[id].length) {
	uint8 col = uint8(punks[id][p++]);
	uint8 rl = uint8(punks[id][p++]);
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
  //return SVG representation of the punk
  function getPunkSVG(uint32 id) public view returns (string memory) {
    require(id < 10000);

    uint8[576] memory dst = decodePunk(id);
    bytes memory h = "<svg version='1.1'  baseProfile='full'  width='240' height='240' xmlns='http://www.w3.org/2000/svg'>\n";
    bytes memory b = "<rect x='X' y='Y' width='10' height='10' style='fill:rgb(R,G,B);' />\n";
    bytes memory f = "</svg>\n";
    
    bytes memory s = new bytes(30000); //need to estimate the length here
    
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
	    num = numtostring(uint8(color_table[dst[k]][0]));
	    for (uint z=0;z<num.length;z++) s[p++] = num[z];	    
	  } else if (b[i]=='G') {
	    num = numtostring(uint8(color_table[dst[k]][1]));
	    for (uint z=0;z<num.length;z++) s[p++] = num[z];	    
	  } else if (b[i]=='B') {
	    num = numtostring(uint8(color_table[dst[k]][2]));
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

  function numtostring(uint i) public view returns (bytes memory) {
    bytes memory s;
    uint h = i/100;
    uint t = (i-h*100)/10;
    uint o = (i-h*100-t*10);
    //    console.log("%d %d %d\n",h,t,o);

    //s = (o+48) | bytes3(t+48) >> 8 | bytes3(h+48) >> 8*2;
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

