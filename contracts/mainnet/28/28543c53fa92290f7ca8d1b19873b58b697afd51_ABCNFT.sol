/**
 *Submitted for verification at Etherscan.io on 2021-08-26
*/

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

contract ABCNFT {

    	string public constant ABCNotation = 
   	 "X:1"
    	"T:This Song Will Never Die" 
    	"L:1/4"
    	"Q:1/4=165"
    	"M:4/4"
    	"I:linebreak $"
     	"K:Bb"
   	 "V:1 treble nm=\"Voice\""
    	"V:2 bass transpose=-12 nm=\"Bass Guitar\" snm=\"B. Guit.\""
  	  "V:1"
   	 "\"^Swing\" B,3/2 C/- C C | B,/ B, G,/- G, z | B,3/2 C/- C C | D/ D F/- F z |$ G3/2 F/- F .B | "
   	 "w: This song * will|ne- ver die *|this song * will|ne- ver die *|this song * will|"
   	 "B/ B B/- B B,/B,/ | B, B, C C/-C/ | C B, z2 ||$ z2 z G,/F,/ | B, z z2 | z4 || B/ B B/- B z |"
   	 "w: ne- ver die * til the|heat death of the un-|i- verse|oh _|_||here i am *|"
   	 "A/ B B/- B z |$ G/ A B/- B/B/c/c/ | c B B D/D/ || D C/C/- C z G,/ | G,/ C B,/- B, z |$ "
   	 "w: here i am *|here i am _ is what i|want to say what i|want to say _ is|i was here _|"
   	 "D/ D C/- C G, | G,/ B, B,/- B, z | D F/F/ F F | G/G/ G G F |$ "
   	 "w: full of an- * xie-|ty and fear _|feel kind of weird a|lit- lie bit funk- y|"
    	"[K:treble-8 m=B,] B,/B,/B,/B,/ B,/B,/B,/B,/ | C C C F, | (G, F,) z2 z || B,,3/2 C,/- C, z .G,,/ |$ "
    	"w: feel- ing like an ov- er- e- du-|cat- ed- mon- key|_ _|this song _ will|"
    	"[K:treble] B,/ B, G,/- G, z | B,3/2 C/- C!mp! C | D/ D F/- F z | G3/2 F/- F!mp! B |$ "
    	"w: ne- ver die _|this song _ will|ne- ver die _|this song _ will|"
    	"B/ B B/- B .B,/B,/ | B, B, C3/2 C/ | C/C/ B, z2 || z2 z G, |$ B, z z2 | z2 z G, || "
    	"w: ne- ver die _ til the|heat death of the|u- ni- verse|oh|_|oh|"
    	"!p! B,/ B, C/- C z | D/ D F/- F F/(G/ |$ G/) F3/2- F2 | z7/2 |!p! B,/ B, C/- C z | "
    	"w: you could be _|hear- ing this _ to- mo-|* rrow _||you could be _|"
    	"D/ D F/- F/ F (F/ |$ F) F/G/- G c | B2 B/ c/!mf!G/ | B/ G .B/- B B/G/- | G/ F3/2 z B |$ "
    	"w: hear- ing this _ one thous-|* sand years _ from|now but if you're|lis- ten- ing _ to- mo-|* row or|"
    	"[K:treble-8 m=B,] B, B, C3/2 C/- | C C z/ B, z | F, F, z/ B,, B,, | B,, B,,/B,,/- B,, B,,/B,,/ |$ "
    	"w: in some far flung|_ fut- ture|i want you to|sing a- long _ and i|"
    	"C, C, C, C, |$[K:treble] F2 z2 || B,3/2 C/- C!mp! C | B,/ B, G,/- G, z | B,3/2 C/- C!mp! C | "
   	 "w: think that you know|how|this song * will|ne- ver die *|this song _ will|"
    	"D/ D F/- F z |$ G3/2 F/- F .B | B/ B B/- B .B,/B,/ | C B, C3/2 C/ | C/B,/ B, z2 ||$ "
    	"w: ne- ver die *|this song * will|ne- ver die * til the|heat death of the|u- ni- verse|"
   	 "[K:treble-8 m=B,] z2 z G,, | B,, B,, z2 | z4 || B,3/2 G,/- G, z B,/ | B, A, F, G, |$ "
   	 "w: oh|_ _||some day _ the|world will be con-|"
    	"[K:treble] d2 c c/(B/ | G) z z2 z/ | B3/2 G/- G z | B/ B B/-!mp! B/ G (d/ |$ d/) d d/- d/ c B/ | "
    	"w: sumed by the sun|_|some day _|you and me _ will die|_ just like _ ev- ery-|"
   	 "B z z2 | c3/2 c/- c d | c/ B G/ z z C/ |$[K:treble-8 m=B,] C/ C C/ C/ D3/2 | C z z/ z z3/2 B,/ | "
    	"w: one|Mean- while _ we|do our best to|be kind and to have|fun the|"
    	"B, B, B, G, | .B,/ .B, B,/- B,/ B, B,/ |$ C/C/ C G, F, | F,2 F, z || B,,3/2 C,/- C, z .G,,/ | "
   	 "w: end is the be-|gin- ing and * the be|gin- ning has just be|gun oh|this song * will|"
   	 "B,,/ B,, G,,/- G,, z |$[K:treble] B,3/2 C/- C .C | D/ D F/- F z | G3/2 F/- F!mp! B | "
   	 "w: ne- ver die *|this song * will|ne- ver die *|this song * will|"
   	 "B/ B B/- B .B,/B,/ |$ B, B, C3/2 C/ | C/B,/ B, z .G,/G,/ || G, B, C3/2 C/ | C/B,/ B, z .G,/G,/ |$ "
   	 "w: ne- ver die * til the|heat death of the|un- i- verse ti the|heat death of the|un- i- verse til the|"
   	 "B, B, C3/2 C/ | C/B,/ B, z F,/F,/ | C C C3/2 C/ |$ C/B,/ B, z F,/F,/ | F, B, C3/2 C/ | "
   	 "w: heat death of the|un- i- verse til the|heat death of the|uni- i- verse till the|heat death of the|"
   	 "C/B,/ B, z2 |]"
   	 "w: un- i- verse|"  
   	 "V:2"
   	 "B,, F,/- z/ F, z | B,, G,,/- z/ G,, z | B,, F,/- z/ F, z | B,, D,/- z/ D, z |$ B,, F,/- z/ F, z | "
   	 "G, E,/- z/ E, z | E, z F, z | B,, B,, B,, F,,/B,,/ ||$ z .B,, .B,, F,, | B,, B,, B,, B,,/ z/ | "
   	 "z4 || .B,, z z2 | .F, z z2 |$ .G, z z2 | E, E,/E,/ E, z || B,, z/ F,/- F, z z/ | "
    	"G, F,/E,/- E, A,, |$ B,, F,/- z/ F, z | G, E,/- z/ E, z | B,, B,,2 B,, | C,/C,/ C,2 z |$ "
   	 "E, E, E, z | F, F, F, F, | F, F, F,2 z || B,, F,/- z/ F, z z/ |$ B,, G,,/- z/ G,, z | "
   	 "B,, F,/- z/ F, z | B,, D,/- z/ D, z | B,, F,/- z/ F, z |$ G, E,/- z/ E, E, | E, z F, z | "
    	"B,, B,, B,, B,,/ z/ || z .B,, .B,, G,, |$ B,, B,, B,, F,,/B,,/ | z4 || G, F,/- z/ F, z | "
   	 "G, E,/- z/ E, z |$ B,, F,/- F, z z/ | G, E,/- E, A,, | B,, F,/- z/ F, z | G, E,/- z/ E, z |$ "
   	 "B, z/ F,/- F, z | G, E,/- E, z | B,, F,/- z/ F, z | G, E,/- E, z z/ |$ B,, z F, z | "
   	 "G, z E,/- E, z | B,, z F,/- F, z | G, z/ E,/- E, z |$ C, C, C, E |$ F, F, F, F,, || "
   	 "B,, F,/- z/ F, z | B,, G,,/- z/ G,, z | B,, F,/- z/ F, z | B,, D,/- z/ D, z |$ B,, F,/- z/ F, z | "
   	 "G, E,/- z/ E, E, | E, z F, z | B,, B,, B,, z/ B,,/ ||$ z B,, B,, G,, | B,, B,, B,, B,,/ z/ | z4 || "
   	 "E, E, E, E, z/ | F, F, F, .F, |$ G,3/2 E,/ F, B,, | E, E, E,/E,/E,/ E, | E, E, E, E, | "
   	 "F, F,2 F, |$ G,2 F, D, | E, E,/E,/ E,/E,/ E, | C, C,/C,/ C, .C, | E, E, E, E, z/ |$ C, C, C, A,, | "
   	 "E, E,/E,/E,/ E, E,/ E, z/ | B,, z F, z | G, E,/- z/ E,/E,/ .E, |$ F,/F,/F,/F,/ F,/F,/ F, | "
   	 "F,2 z2 || B,, F,/- z/ F, z z/ | B,, G,,/- z/ G,, z |$ B,, F,/- z/ F, z | B,, D,/- z/ D, z | "
   	 "B,, F,/- z/ F, z | G, E,/- z/ E, z |$ E, z F, z | B,, B,, B,, z || E, E, F, B,,/ z/ | "
    	"B,, B,, B,, z |$ E, E, F, B,,/ z/ | B,, B,, z F,, | E, z F, z |$ B,, B,, B,, F,,/B,,/ | "
    	"E, z F, z | B,, B,, B,, z |] ";
    
    string public constant name = "This Song Will Never Die";
    string public constant symbol = "TSWND";
    string public constant uri = "https://ipfs.io/ipfs/QmdqeDLv5WoX2VWQTBN2GgUJL99XEo8nA2CvZPARwAPekw";

    /*
    The MVP NFT is a lightweight 1/1 NFT contract that conforms to the ERC721 standard in a way that makes it extremely simple for someone to understand what is going on from etherscan.
    Since the token is a 1/1, the tokenId is set to 1, however this could in theory be any value and would just need to update the rest of the contract
    */
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    

    uint constant tokenId = 1;
    address public owner;
    address public approved;
    //currently declaring the owner as my local acct on scaffold-eth
    constructor(address _owner) {
        owner = _owner;
        emit Transfer(address(0), _owner, tokenId);
    }

    function totalSupply() public pure returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 _tokenId) external pure returns (string memory){
        require(_tokenId == tokenId, "URI query for nonexistent token");
        return uri;
    }

    function balanceOf(address _queryAddress) external view returns (uint) {
        if(_queryAddress == owner) {
            return 1;
        } else {
            return 0;
        }
    }

    function ownerOf(uint _tokenId) external view returns (address) {
        require(_tokenId == tokenId, "owner query for nonexistent token");
        return owner;
    }

    function safeTransferFrom(address _from, address _to, uint _tokenId, bytes memory data) public payable {
        require(msg.sender == owner || approved == msg.sender, "Msg.sender not allowed to transfer this NFT!");
        require(_from == owner && _from != address(0) && _tokenId == tokenId);
        emit Transfer(_from, _to, _tokenId);
        approved = address(0);
        owner = _to;
        if(isContract(_to)) {
            if(ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, data) != 0x150b7a02) {
                revert("receiving address unable to hold ERC721!");
            }
        }
    }

    //changed the first safeTransferFrom's visibility to make this more readable.
    function safeTransferFrom(address _from, address _to, uint _tokenId) external payable {
        safeTransferFrom(_from, _to, _tokenId, "");
    }

    function transferFrom(address _from, address _to, uint _tokenId) external payable{
        require(msg.sender == owner || approved == msg.sender, "Msg.sender not allowed to transfer this NFT!");
        require(_from == owner && _from != address(0) && _tokenId == tokenId);
        emit Transfer(_from, _to, _tokenId);
        approved = address(0);
        owner = _to;
    }

    function approve(address _approved, uint256 _tokenId) external payable {
        require(msg.sender == owner, "Msg.sender not owner!");
        require(_tokenId == tokenId, "tokenId invald");
        emit Approval(owner, _approved, _tokenId);
        approved = _approved;
    }

    function setApprovalForAll(address _operator, bool _approved) external {
        require(msg.sender == owner, "Msg.sender not owner!");
        if (_approved) {
            emit ApprovalForAll(owner, _operator, _approved);
            approved = _operator;
        } else {
            emit ApprovalForAll(owner, address(0), _approved);
            approved = address(0);
        }
    }

    function getApproved(uint _tokenId) external view returns (address) {
        require(_tokenId == tokenId, "approved query for nonexistent token");
        return approved;
    }

    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        if(_owner == owner){
            return approved == _operator;
        } else {
            return false;
        }
    }

    function isContract(address addr) public view returns(bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    function supportsInterface(bytes4 interfaceID) external pure returns (bool) {
        return interfaceID == 0x80ac58cd ||
             interfaceID == 0x01ffc9a7;
    }

}

interface ERC721TokenReceiver {
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes memory _data) external returns(bytes4);
}

/*
	__________________________________________
	To view the song in classical notation, and even hear the song as midi, copy paste the ABC notation below into this website:
	https://wellington.session.nz/addBlackboardABC/

	copy from here

X:1
T:This Song Will Never Die 
L:1/4
Q:1/4=165
M:4/4
I:linebreak $
K:Bb
V:1 treble nm="Voice"
V:2 bass transpose=-12 nm="Bass Guitar" snm="B. Guit."
V:1
"^Swing" B,3/2 C/- C C | B,/ B, G,/- G, z | B,3/2 C/- C C | D/ D F/- F z |$ G3/2 F/- F .B | 
w: This song * will|ne- ver die *|this song * will|ne- ver die *|this song * will|
B/ B B/- B B,/B,/ | B, B, C C/-C/ | C B, z2 ||$ z2 z G,/F,/ | B, z z2 | z4 || B/ B B/- B z | 
w: ne- ver die * til the|heat death of the un-|i- verse|oh _|_||here i am *|
A/ B B/- B z |$ G/ A B/- B/B/c/c/ | c B B D/D/ || D C/C/- C z G,/ | G,/ C B,/- B, z |$ 
w: here i am *|here i am _ is what i|want to say what i|want to say _ is|i was here _|
D/ D C/- C G, | G,/ B, B,/- B, z | D F/F/ F F | G/G/ G G F |$ 
w: full of an- * xie-|ty and fear _|feel kind of weird a|lit- lie bit funk- y|
[K:treble-8 m=B,] B,/B,/B,/B,/ B,/B,/B,/B,/ | C C C F, | (G, F,) z2 z || B,,3/2 C,/- C, z .G,,/ |$ 
w: feel- ing like an ov- er- e- du-|cat- ed- mon- key|_ _|this song _ will|
[K:treble] B,/ B, G,/- G, z | B,3/2 C/- C!mp! C | D/ D F/- F z | G3/2 F/- F!mp! B |$ 
w: ne- ver die _|this song _ will|ne- ver die _|this song _ will|
B/ B B/- B .B,/B,/ | B, B, C3/2 C/ | C/C/ B, z2 || z2 z G, |$ B, z z2 | z2 z G, || 
w: ne- ver die _ til the|heat death of the|u- ni- verse|oh|_|oh|
!p! B,/ B, C/- C z | D/ D F/- F F/(G/ |$ G/) F3/2- F2 | z7/2 |!p! B,/ B, C/- C z | 
w: you could be _|hear- ing this _ to- mo-|* rrow _||you could be _|
D/ D F/- F/ F (F/ |$ F) F/G/- G c | B2 B/ c/!mf!G/ | B/ G .B/- B B/G/- | G/ F3/2 z B |$ 
w: hear- ing this _ one thous-|* sand years _ from|now but if you're|lis- ten- ing _ to- mo-|* row or|
[K:treble-8 m=B,] B, B, C3/2 C/- | C C z/ B, z | F, F, z/ B,, B,, | B,, B,,/B,,/- B,, B,,/B,,/ |$ 
w: in some far flung|_ fut- ture|i want you to|sing a- long _ and i|
C, C, C, C, |$[K:treble] F2 z2 || B,3/2 C/- C!mp! C | B,/ B, G,/- G, z | B,3/2 C/- C!mp! C | 
w: think that you know|how|this song * will|ne- ver die *|this song _ will|
D/ D F/- F z |$ G3/2 F/- F .B | B/ B B/- B .B,/B,/ | C B, C3/2 C/ | C/B,/ B, z2 ||$ 
w: ne- ver die *|this song * will|ne- ver die * til the|heat death of the|u- ni- verse|
[K:treble-8 m=B,] z2 z G,, | B,, B,, z2 | z4 || B,3/2 G,/- G, z B,/ | B, A, F, G, |$ 
w: oh|_ _||some day _ the|world will be con-|
[K:treble] d2 c c/(B/ | G) z z2 z/ | B3/2 G/- G z | B/ B B/-!mp! B/ G (d/ |$ d/) d d/- d/ c B/ | 
w: sumed by the sun|_|some day _|you and me _ will die|_ just like _ ev- ery-|
B z z2 | c3/2 c/- c d | c/ B G/ z z C/ |$[K:treble-8 m=B,] C/ C C/ C/ D3/2 | C z z/ z z3/2 B,/ | 
w: one|Mean- while _ we|do our best to|be kind and to have|fun the|
B, B, B, G, | .B,/ .B, B,/- B,/ B, B,/ |$ C/C/ C G, F, | F,2 F, z || B,,3/2 C,/- C, z .G,,/ | 
w: end is the be-|gin- ing and * the be|gin- ning has just be|gun oh|this song * will|
B,,/ B,, G,,/- G,, z |$[K:treble] B,3/2 C/- C .C | D/ D F/- F z | G3/2 F/- F!mp! B | 
w: ne- ver die *|this song * will|ne- ver die *|this song * will|
B/ B B/- B .B,/B,/ |$ B, B, C3/2 C/ | C/B,/ B, z .G,/G,/ || G, B, C3/2 C/ | C/B,/ B, z .G,/G,/ |$ 
w: ne- ver die * til the|heat death of the|un- i- verse ti the|heat death of the|un- i- verse til the|
B, B, C3/2 C/ | C/B,/ B, z F,/F,/ | C C C3/2 C/ |$ C/B,/ B, z F,/F,/ | F, B, C3/2 C/ | 
w: heat death of the|un- i- verse til the|heat death of the|uni- i- verse till the|heat death of the|
C/B,/ B, z2 |] 
w: un- i- verse|
V:2
B,, F,/- z/ F, z | B,, G,,/- z/ G,, z | B,, F,/- z/ F, z | B,, D,/- z/ D, z |$ B,, F,/- z/ F, z | 
G, E,/- z/ E, z | E, z F, z | B,, B,, B,, F,,/B,,/ ||$ z .B,, .B,, F,, | B,, B,, B,, B,,/ z/ | 
z4 || .B,, z z2 | .F, z z2 |$ .G, z z2 | E, E,/E,/ E, z || B,, z/ F,/- F, z z/ | 
G, F,/E,/- E, A,, |$ B,, F,/- z/ F, z | G, E,/- z/ E, z | B,, B,,2 B,, | C,/C,/ C,2 z |$ 
E, E, E, z | F, F, F, F, | F, F, F,2 z || B,, F,/- z/ F, z z/ |$ B,, G,,/- z/ G,, z | 
B,, F,/- z/ F, z | B,, D,/- z/ D, z | B,, F,/- z/ F, z |$ G, E,/- z/ E, E, | E, z F, z | 
B,, B,, B,, B,,/ z/ || z .B,, .B,, G,, |$ B,, B,, B,, F,,/B,,/ | z4 || G, F,/- z/ F, z | 
G, E,/- z/ E, z |$ B,, F,/- F, z z/ | G, E,/- E, A,, | B,, F,/- z/ F, z | G, E,/- z/ E, z |$ 
B, z/ F,/- F, z | G, E,/- E, z | B,, F,/- z/ F, z | G, E,/- E, z z/ |$ B,, z F, z | 
G, z E,/- E, z | B,, z F,/- F, z | G, z/ E,/- E, z |$ C, C, C, E |$ F, F, F, F,, || 
B,, F,/- z/ F, z | B,, G,,/- z/ G,, z | B,, F,/- z/ F, z | B,, D,/- z/ D, z |$ B,, F,/- z/ F, z | 
G, E,/- z/ E, E, | E, z F, z | B,, B,, B,, z/ B,,/ ||$ z B,, B,, G,, | B,, B,, B,, B,,/ z/ | z4 || 
E, E, E, E, z/ | F, F, F, .F, |$ G,3/2 E,/ F, B,, | E, E, E,/E,/E,/ E, | E, E, E, E, | 
F, F,2 F, |$ G,2 F, D, | E, E,/E,/ E,/E,/ E, | C, C,/C,/ C, .C, | E, E, E, E, z/ |$ C, C, C, A,, | 
E, E,/E,/E,/ E, E,/ E, z/ | B,, z F, z | G, E,/- z/ E,/E,/ .E, |$ F,/F,/F,/F,/ F,/F,/ F, | 
F,2 z2 || B,, F,/- z/ F, z z/ | B,, G,,/- z/ G,, z |$ B,, F,/- z/ F, z | B,, D,/- z/ D, z | 
B,, F,/- z/ F, z | G, E,/- z/ E, z |$ E, z F, z | B,, B,, B,, z || E, E, F, B,,/ z/ | 
B,, B,, B,, z |$ E, E, F, B,,/ z/ | B,, B,, z F,, | E, z F, z |$ B,, B,, B,, F,,/B,,/ | 
E, z F, z | B,, B,, B,, z |] 

	to here
	*/