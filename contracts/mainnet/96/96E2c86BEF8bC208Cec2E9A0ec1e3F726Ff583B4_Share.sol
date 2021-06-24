// SPDX-License-Identifier: MIT

/* Interface to allow shared access to edit parameters of a particular token.

   To be allowed access, must be an owner of another Deafbeef token.

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

contract Share {
  extDeafbeef721 public deafbeef;
  address admin_address;
  uint256 public sharedID;
  bool public allowCommit;
  
  event ParamsChanged(uint256 tokenID, uint32 p0,uint32 p1,uint32 p2,uint32 p3,uint32 p4,uint32 p5,uint32 p6);
  event GrantAccess(address a);
  event RevokeAccess(address a);  

  //Optionally, limit commits: once per address in 24hr period
  
  //each tokenID can have up to 3 editor addresses
  mapping(address => uint256) lastUpdate;
  mapping(address => bool) allowList;
  
  //only owners of other Deafbeef tokens are allowed to make commits
  modifier requireCommiter(uint256 tid) {
    require(msg.sender == deafbeef.ownerOf(tid) || allowList[msg.sender]);
    _;
  }
  
  modifier requireAdmin() {
    require(admin_address == msg.sender,"Requires admin privileges");
    _;
  }
  
  constructor(address _contract_address) {
    deafbeef = extDeafbeef721(_contract_address);
    admin_address = msg.sender;
    allowCommit = true;
  }

  //Change the contract address this applies to. Probably never needed
  function setDeafbeef(address _contract_address)  public requireAdmin virtual {
    deafbeef = extDeafbeef721(_contract_address);    
  }

  function onAllowList(address a) public view returns(bool) {
    return allowList[a];
  }
  
  function grantAccess(address a)  public requireAdmin virtual {
    if (!allowList[a]) {
      allowList[a] = true;
      emit GrantAccess(a);
    }
  }

  function revokeAccess(address a)  public requireAdmin virtual {
    if (allowList[a]) {
      allowList[a] = false;
      emit RevokeAccess(a);
    }
  }

  //Change the token ID that can be edited
  function setSharedID(uint256 tid) public requireAdmin virtual {
    sharedID = tid;
  }

  //Enable/Disable parameter commits from anyone except owner
  function setEnabled(bool e) public requireAdmin virtual {
    allowCommit = e;
  }
  
  //optionally include rate limiting
  function setParams(uint256 ownedID, uint32[] memory v) public requireCommiter(ownedID) virtual {
    require(allowCommit==true,"Committing disabled");
    require(v.length==7,"Must have all parameters in order from 0-6");
    
    //    require(now - lastUpdate[msg.sender] > 60*5, "Must wait 5 minutes between commits");
    
    for (uint j=0;j<v.length;j++) {
      deafbeef.setTokenParam(sharedID,j,v[j]);
    }
    emit ParamsChanged(sharedID,v[0],v[1],v[2],v[3],v[4],v[5],v[6]);
    //    lastUpdate[msg.sender] = now;
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