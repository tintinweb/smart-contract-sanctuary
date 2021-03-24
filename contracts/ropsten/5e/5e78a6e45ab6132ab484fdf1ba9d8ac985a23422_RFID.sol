// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;


import "./IERC20.sol";
import "./IERC1410.sol";
import "./IERC1594.sol";
import "./IERC1643.sol";
import "./Ownable.sol";
import "./Library.sol";


contract RFID is IERC20,IERC1410,IERC1594,IERC1643,Ownable {
    
    
    string name;
    string symbol;
    uint256 _totalSupply;
    
    bool isSaleOn;
    
    using SafeMath for uint;  
    
    
    
    constructor(string memory _name,string memory _symbol, uint256 totalSupply)  public
    {
        name = _name;
        symbol = _symbol;
        _totalSupply = totalSupply;
        isSaleOn = true;
    }
    
    modifier _isSaleOn() {
        require(isSaleOn, "Sale is off");
        _;
    } 
    
    
    // ERC1643 Implementation
    struct Document {
        bytes32 docHash; // Hash of the document
        uint256 lastModified; // Timestamp at which document details was last modified
        string uri; // URI of the document that exist off-chain
    }

    mapping(bytes32 => Document) internal _documents;
    bytes32[] _docNames;
    mapping(bytes32 => uint256) internal _docIndexes;
    
    function getDocument(bytes32 _Name) public override onlyOwner _isSaleOn view returns(string memory, bytes32, uint256){
         return (_documents[_Name].uri, _documents[_Name].docHash, _documents[_Name].lastModified);
    }
    
    function setDocument(bytes32 Name, string memory Uri, bytes32 _DocumentHash) public override _isSaleOn onlyOwner {
       
        require(Name != bytes32(0), "Zero value is not allowed");
        require(bytes(Uri).length > 0, "Should not be a empty uri");
        if (_documents[Name].lastModified == uint256(0)) {
            _docNames.push(Name);
            _docIndexes[Name] = _docNames.length;
        }
        _documents[Name] = Document(_DocumentHash, now, Uri);
        emit DocumentUpdated(Name, Uri, _DocumentHash);
    }
    
    function removeDocument(bytes32 _Name) public override _isSaleOn onlyOwner{
        
        require(_documents[_Name].lastModified != uint256(0), "Document should be existed");
        uint256 index = _docIndexes[_Name] - 1;
        if (index != _docNames.length - 1) {
            _docNames[index] = _docNames[_docNames.length - 1];
            _docIndexes[_docNames[index]] = index + 1; 
        }
       // _docNames.length = _docNames.length - 1;
       _docNames.pop();
        emit DocumentRemoved(_Name, _documents[_Name].uri, _documents[_Name].docHash);
        delete _documents[_Name];
    }
    function getAllDocuments() external override view returns (bytes32[] memory) {
        return _docNames;
    }
    
    
    
    //ERC1594 Implementation
    
    function isIssuable() external override view returns (bool)
    {
  
        return isSaleOn;
    }
    function issue(address tokenHolder, uint256 value, bytes calldata _data) external override
    {
        if (isSaleOn)
        {
            mint(tokenHolder,value);
        }
        
    }
    
    
    
    //ERC20 Implementation
    
    function changeSaleStatus() external
    {
        if (isSaleOn)
        {
            isSaleOn = false;
        }
        else
        {
            isSaleOn = true;
        }
    }
    mapping(address => uint256) _balances;
    function mint(address account, uint256 amount) internal onlyOwner {
        _mint(account, amount);
    }
    
    function _mint(address account, uint256 value) internal {
        
        _balances[account] = _balances[account].add(value);
       
         emit Issued(address(0),account,value,"0x00");
        
    }
    
    function totalSupply() external override view returns (uint256) 
    {
        return _totalSupply;
    }
    function balanceOf(address account) external override view returns (uint256) 
    {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) external override returns (bool)
    {
        if (_balances[msg.sender] >= amount)
        {
            
             _balances[recipient] = _balances[recipient].add(amount);
             _balances[msg.sender] = _balances[msg.sender].sub(amount);
             emit Transfer(msg.sender, recipient, amount);
        }
        else
        {
            revert();
        }
       
    }
    
}