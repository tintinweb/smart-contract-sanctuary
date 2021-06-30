/**
 *Submitted for verification at Etherscan.io on 2021-06-30
*/

/**
 *Submitted for verification at hecoinfo.com on 2021-05-20
*/

pragma solidity ^0.6.0;
//SPDX-License-Identifier: UNLICENSED
interface IaddressController {
    function isManager(address _mAddr) external view returns(bool);
    function getAddr(string calldata _name) external view returns(address);
}

contract Author{
    IaddressController public addrc;
    
    mapping(address => Author_S) public authorInfo;
    mapping(address => bool) public isAuthor;
    
    event RegisteredAuthor(address _author,string _url,string _name,string _introduction);
    event UpdateAuthor(address _author,string _url,string _name,string _introduction);
    event DelAuthor(address _author);
    event SetAuthorUrl(address _author,string _url);
    event SetAuthorName(address _author,string _name);
    event SetAuthorIntroduction(address _author,string _introduction);
    
    struct Author_S{
        string url;
        string name;
        string introduction;
    }
    constructor(IaddressController _addrc) public{
        addrc = _addrc;
    }
    
    function registeredAuthor(
        address _author,
        string memory _url,
        string memory _name,
        string memory _introduction
        ) public onlyManager{
        require(!isAuthor[_author],"is already registered this author");
        
        require(_author != address(0),"_author is address 0");
        
        authorInfo[_author] = Author_S({
            url:_url,
            name :_name,
            introduction: _introduction
        });
        isAuthor[_author] = true;
        emit RegisteredAuthor(_author,_url,_name,_introduction);
    }
    
    function updateAuthor(address _author,
        string memory _url,
        string memory _name,
        string memory _introduction
        ) public onlyManager{
            require(isAuthor[_author],"author not register");
            authorInfo[_author] = Author_S({
                url:_url,
                name :_name,
                introduction: _introduction
            });
            
            emit UpdateAuthor(_author,_url,_name,_introduction);
        
    }
    
    function delAuthor(address _author) public onlyManager{
        require(isAuthor[_author],"not registered  author");
        isAuthor[_author] = false;
        
        emit DelAuthor(_author);
    }
    function setAuthorUrl(address _author,string memory _url) public onlyManager{
        require(isAuthor[_author],"not registered  author");
        authorInfo[_author].url = _url;
        emit SetAuthorUrl(_author,_url);
    }
    function setAuthorName(address _author,string memory _name) public onlyManager{
        require(isAuthor[_author],"not registered  author");
        authorInfo[_author].name = _name;
        emit SetAuthorName(_author,_name);
    }
    function setAuthorIntroduction(address _author,string memory _introduction) public onlyManager{
        require(isAuthor[_author],"not registered  author");
        authorInfo[_author].introduction = _introduction;
        emit SetAuthorIntroduction(_author,_introduction);
    }
    
    function getAuthor(address _author) public view returns(bool _isAuthor,string memory _url,string  memory _name,string memory _introduction){
        _isAuthor = isAuthor[_author];
        _url   = authorInfo[_author].url;
        _name   = authorInfo[_author].name;
        _introduction   = authorInfo[_author].introduction;
    }
    
    function nameAddr(string memory _name) public view returns(address){
        return addrc.getAddr(_name);
    }
    
    modifier onlyManager(){
        require(addrc.isManager(msg.sender),"onlyManager");
        _;
    }
}