/**
 *Submitted for verification at Etherscan.io on 2021-02-01
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.0;

contract DocVerification {
    
    address public owner;
    mapping(address => Account) private accounts;
    mapping(address => bool) public isValiduser;
    
    mapping(string => Document) private document;
    Document[] public docs;

    struct Account {
        string name;
        string email;
        string logo;
        string description;
    }
    
    struct Document {
        address verifier;
        string authName;
        string docTitle;
        string docAddress;
        string studentId;
    }

    event Registered(address user, string name);
    event DocumentAdded (address user, string authName, string docTitle, string docAddress, string stdId);

    // Check OwnerShip of Contract
    modifier isOwner() {
        require(msg.sender == owner, "is not owner!");
        _;
    }
    
    // Check isValid or not!
    modifier isValid() {
        require(isValiduser[msg.sender] == true, "you are not authorized user!");
        _;
    }
    
    
    constructor() public {
        owner = msg.sender;
         isValiduser[msg.sender] = true;
    }

    function register(
        string memory _name,
        string memory _email,
        string memory _logo,
        string memory _description
    ) public {
        accounts[msg.sender] = Account({
            name: _name,
            email: _email,
            logo: _logo,
            description: _description
        });
        emit Registered(msg.sender, _name);
    }

    function getAccount()
        public
        view
        returns (
            string memory name,
            string memory email,
            string memory logo,
            string memory description
        )
    {
        name = accounts[msg.sender].name;
        email = accounts[msg.sender].email;
        logo = accounts[msg.sender].logo;
        description = accounts[msg.sender].description;
        return (name, email, logo, description);
    }
    
    
    function addToValidUser(address _user) public isOwner {
       isValiduser[_user] = true;
    }
    
    
    function addDocument(
        
        string memory _authName, 
        string memory _docTitle, 
        string memory _docAddress,
        string memory  _studentId) public  isValid {
            
        emit DocumentAdded(msg.sender, _authName, _docTitle, _docAddress, _studentId);
    
        document[_docAddress] = Document({
            verifier: msg.sender,
            authName: _authName,
            docTitle: _docTitle,
            docAddress: _docAddress,
            studentId: _studentId
        });
        
        docs.push(
            Document({
            verifier: msg.sender,
            authName: _authName,
            docTitle: _docTitle,
            docAddress: _docAddress,
            studentId: _studentId
            })
        );
    }
    
    
    function getDocument(string memory _id) public view returns 
    (
      string memory _authName, 
      address _verifier, 
      string memory _docTitle,
      string memory _docAddress,
    string memory _studentId
    ) {
        
    for (uint i=0; i<docs.length; i++) {
    if(StringUtils.equal( docs[i].studentId , _id)){
        
        _verifier = docs[i].verifier;
        _authName = docs[i].authName;
        _docTitle = docs[i].docTitle;
        _docAddress = docs[i].docAddress;
        _studentId = docs[i].studentId;
        break;
      }
    }
    return (_authName, _verifier, _docTitle, _docAddress, _studentId);
  }
  
    function transferOwnership(address _newOwner) public isOwner {
      owner = _newOwner;
    }

    function contractDestruct() public isOwner {
        selfdestruct(msg.sender);
    }
    
}


library StringUtils {
 
  function compare(string memory _a, string memory _b) public pure returns (int) {
      bytes memory a = bytes(_a);
      bytes memory b = bytes(_b);
      uint minLength = a.length;
      if (b.length < minLength) minLength = b.length;
      
      for (uint i = 0; i < minLength; i ++)
        if (a[i] < b[i])
          return -1;
        else if (a[i] > b[i])
          return 1;
      if (a.length < b.length)
        return -1;
      else if (a.length > b.length)
        return 1;
      else
        return 0;
  }

  function equal(string memory _a, string memory _b) public pure returns (bool) {
      return compare(_a, _b) == 0;
  }

  function indexOf(string memory _haystack, string memory _needle) public pure returns (int)
  {
    bytes memory h = bytes(_haystack);
    bytes memory n = bytes(_needle);
    if(h.length < 1 || n.length < 1 || (n.length > h.length)) 
      return -1;
    // since we have to be able to return -1 (if the char isn't found or input error), 
    // this function must return an "int" type with a max length of (2^128 - 1)
    else if(h.length > (2**128 -1)) 
      return -1;                                  
    else
    {
      uint subindex = 0;
      for (uint i = 0; i < h.length; i ++)
      {
        if (h[i] == n[0]) // found the first char of b
        {
          subindex = 1;
          // search until the chars don't match or until we reach the end of a or b
          while(subindex < n.length && (i + subindex) < h.length && h[i + subindex] == n[subindex]) 
          {
            subindex++;
          }   
          if(subindex == n.length)
            return int(i);
        }
      }
    }
  }
}