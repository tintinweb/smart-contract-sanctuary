/**
 *Submitted for verification at Etherscan.io on 2021-05-16
*/

// SPDX-License-Identifier: MIT

/* Interface to allow Deafbeef owners to change token parameters all at once.
   
   Owners can also give editing access to up to 3 other users. 
   Signature can authenticate them on the deafbeef.com DAPP, to allow these
   editors to perform off-chain previews of parameter changes without gas cost.

   If editors have 'allowCommit' privilege, they can also commit those previews
   permanently with setParams().

*/

pragma solidity >=0.6.0 <0.8.2;

abstract contract  extDeafbeef721  {
  function numSeries() public pure virtual returns (uint256) ;
  function mint(uint256 sid, address to) public virtual returns (uint256 _tokenId);
  function setPrice(uint256 sid, uint256 p) public virtual;
  function setTokenParam(uint256 tokenID, uint256 i, uint32 v) public virtual;
  function ownerOf(uint256 tokenId) external virtual view returns (address owner);
}

contract Changer {
  extDeafbeef721 public deafbeef;
  address admin_address;


  event ParamsChanged(uint256 tokenID, uint32 p0,uint32 p1,uint32 p2,uint32 p3,uint32 p4,uint32 p5,uint32 p6);

  //indexes which address/tokenID pairs have access to change params

  struct EditStruct {
    address[3] editors;
    bool[3] allowCommit; //can editors also commit? or only preview
    bool editingDisabled;
  }
  
  //each tokenID can have up to 3 editor addresses
  mapping(uint256 => EditStruct) editorAccess;

  modifier requireOwner(uint256 tokenID) {
    require(msg.sender == deafbeef.ownerOf(tokenID),"Not owner of token");
    _;
  }
  modifier requireEditor(uint256 tokenID) {
    if (editorAccess[tokenID].editingDisabled && msg.sender != deafbeef.ownerOf(tokenID)) {
      revert("Editing, except by owner, is disabled");
    }
    
    require(msg.sender == deafbeef.ownerOf(tokenID) ||
	    msg.sender == editorAccess[tokenID].editors[0] ||
	    msg.sender == editorAccess[tokenID].editors[1] ||
	    msg.sender == editorAccess[tokenID].editors[2]
	    ,"Not owner of token,nor token editor");
    _;
  }

  //only with commit access
  modifier requireCommiter(uint256 tokenID) {
    if (editorAccess[tokenID].editingDisabled && msg.sender != deafbeef.ownerOf(tokenID)) {
      revert("Editing, except by owner, is disabled");
    }
    
    require(msg.sender == deafbeef.ownerOf(tokenID) ||
	    (msg.sender == editorAccess[tokenID].editors[0] && editorAccess[tokenID].allowCommit[0]) ||
	    (msg.sender == editorAccess[tokenID].editors[1] && editorAccess[tokenID].allowCommit[1]) ||
	    (msg.sender == editorAccess[tokenID].editors[2] && editorAccess[tokenID].allowCommit[2])
	    ,"Not owner of token,nor token editor");
    _;
  }
  
  modifier requireAdmin() {
    require(admin_address == msg.sender,"Requires admin privileges");
    _;
  }
  
  constructor(address _contract_address) {
    deafbeef = extDeafbeef721(_contract_address);
    admin_address = msg.sender;
  }

  //Change the contract address this applies to. Probably never needed
  function setDeafbeef(address _contract_address)  public requireAdmin virtual {
    deafbeef = extDeafbeef721(_contract_address);    
  }
  
  //only token owner can assign roles
  function setEditRole(uint256 tokenID, uint256 i, address a, bool allowCommit) public requireOwner(tokenID) virtual {
    editorAccess[tokenID].editors[i] = a;
    editorAccess[tokenID].allowCommit[i] = allowCommit;    
  }
  
  function getEditors(uint256 tokenID) public view returns(address editor0, address editor1, address editor2, bool allowCommit0, bool allowCommit1, bool allowCommit2, bool editingDisabled)  {
    editingDisabled = editorAccess[tokenID].editingDisabled;
    editor0 = editorAccess[tokenID].editors[0];
    editor1 = editorAccess[tokenID].editors[1];
    editor2 = editorAccess[tokenID].editors[2];

    allowCommit0 = editorAccess[tokenID].allowCommit[0];
    allowCommit1 = editorAccess[tokenID].allowCommit[1];
    allowCommit2 = editorAccess[tokenID].allowCommit[2];    
  }

  // Master switch allowing owner to temporarily disable editing, without deleting the authentication list
  function toggleEditing(uint256 tokenID, bool allowEditing) public requireOwner(tokenID) virtual {
    editorAccess[tokenID].editingDisabled = !allowEditing;
  }
  
  //sets many parameters at once. Must be an editor with allowCommit access
  /*
  function setParams(uint256 tokenID, uint[] memory i, uint32[] memory v) public requireCommiter(tokenID) virtual {
    require(v.length == i.length);
    for (uint j=0;j<v.length;j++) {
      deafbeef.setTokenParam(tokenID,i[j],v[j]);
    }
  }
  */
  
  function setParams(uint256 tokenID, uint32[] memory v) public requireCommiter(tokenID) virtual {
    require(v.length==7,"Must have all parameters in order from 0-6");
    for (uint j=0;j<v.length;j++) {
      deafbeef.setTokenParam(tokenID,j,v[j]);
    }
    emit ParamsChanged(tokenID,v[0],v[1],v[2],v[3],v[4],v[5],v[6]);
  }

}