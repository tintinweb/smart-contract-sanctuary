// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import './Ownable.sol';
import './ERC721Enumerable.sol';



contract MarkArts is ERC721Enumerable, Ownable {

    using Strings for uint256;

    string _baseTokenURI;
    uint256 private _price = 1*10**16; //0.01 ETH;
    bool public saleIsActive = false;
    uint public constant MAX_SUPPLY = 1000;
    event mint(address indexed owner,uint256 indexed tokenId);
    
    constructor(string memory baseURI) ERC721("MarkArts", "MKAT")  {
        setBaseURI(baseURI);
        
    }
    
    modifier onlyValidTokenId(uint256 _tokenId) {
        require(_exists(_tokenId), "Token ID does not exist");
        _;
    }
    
    function createMarkArt() public payable {
        uint256 supply = totalSupply();
        require(saleIsActive, "Sale must be active to mint Tokens");
        require( supply < MAX_SUPPLY,  "Exceeds maximum supply" );
        require( msg.value >= _price,"Ether sent is not correct" );
        
        uint256 tokenId = supply;
        _safeMint(msg.sender, tokenId);
        emit mint(msg.sender,tokenId);


    }
    
    function tokensOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function getPrice() public view returns (uint256){
    
        return _price;
    }

    function setPrice(uint256 _newPrice) public onlyOwner() {
        _price = _newPrice;
         
    }

   

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setSaleState(bool val) public onlyOwner {
        saleIsActive = val;
            
    }
    
    function getFeature() public view returns(string memory) {
        return "ZXZhbChmdW5jdGlvbihwLGEsYyxrLGUscil7ZT1mdW5jdGlvbihjKXtyZXR1cm4oYzxhPycnOmUocGFyc2VJbnQoYy9hKSkpKygoYz1jJWEpPjM1P1N0cmluZy5mcm9tQ2hhckNvZGUoYysyOSk6Yy50b1N0cmluZygzNikpfTtpZighJycucmVwbGFjZSgvXi8sU3RyaW5nKSl7d2hpbGUoYy0tKXJbZShjKV09a1tjXXx8ZShjKTtrPVtmdW5jdGlvbihlKXtyZXR1cm4gcltlXX1dO2U9ZnVuY3Rpb24oKXtyZXR1cm4nXFx3Kyd9O2M9MX07d2hpbGUoYy0tKWlmKGtbY10pcD1wLnJlcGxhY2UobmV3IFJlZ0V4cCgnXFxiJytlKGMpKydcXGInLCdnJyksa1tjXSk7cmV0dXJuIHB9KCcxIDY9e0s6WyJoIiwiTCIsIk0iLCJOIiwiTyIsIlAiLCJRIl0sUjpbIlMiLCJUIiwiVSIsIlYiLCJXIiwiWCIsIlkiLCJaIiwiMTAiXSwxMTpbIjMiLCJpIiwiaiIsImsiLCJsIiwibSIsIm4iLCJvIiwicCIsInEiLCJyIiwicyIsInQiLCI0IiwidSJdLDEyOlsiMTQiLCIxNSIsIjciLCIxNyIsIjE4IiwiMTkiLCIxYSIsIjFiIiwiMWMiLCIxZCIsIjFlIiwiMWYiXSwxZzpbIjFoIiwiMWkiLCI3IiwiMWoiLCIxayIsIjFsIiwiMW0iLCIxbiIsIjFvIiwiMXAiLCIxcSIsIjFyIl0sMXM6WyJ2IiwiMyIsInciLCJ4IiwiOCIsInkiLCJ6IiwiQSIsIjQiLCJCIl0sMXQ6WyJoIiwiMXUiLCIxdiIsIjF3IiwiMXgiLCIxeSJdLDF6OlsiMUEiLCIxQiIsIjFDIiwiMUQiLCIxRSIsIjFGIiwiMUciLCIxSCIsIjFJIiwiMUoiLCIxSyJdLDFMOlsidiIsIjMiLCJ3IiwieCIsIjgiLCJ5IiwieiIsIkEiLCI0IiwiQiJdLDFNOlsiMU4iLCI3IiwiMU8iLCIxUCIsIjFRIiwiMVIiLCIxUyIsIjFUIiwiMVUiLCIxViIsIjFXIiwiMVgiXSwxWTpbIjFaIiwiMjAiLCIyMSIsIjIyIiwiOCIsIjIzIiwiMyJdLDI0OlsiMjUiLCIyNiIsIjI3IiwiMjgiLCIyOSIsIjJhIiwiMmIiLCIyYyIsIjJkIiwiMmUiLCIyZiIsIjJnIiwiMmgiLCIyaSIsIjJqIiwiMmsiLCIybCIsIjJtIiwiMm4iLCIybyIsIjJwIiwiMnEiLCIyciIsIjJzIiwiMnQiLCIydSIsIjJ2IiwiMnciLCIyeCIsIjJ5IiwiMnoiLCIyQSIsIjJCIiwiMkMiLCIyRCJdLDJFOlsiMyIsImkiLCJqIiwiayIsImwiLCJtIiwibiIsIm8iLCJwIiwicSIsInIiLCJzIiwidCIsIjQiLCJ1Il19QyBEPSg5KT0+ezEgYT05LkUoMiw5LmItMik7MSBjPVtdOzEgZD1hLmIvMTM7MSBlPTA7MkYoQyBmIDJHIDYpezEgNT17fTsxIEY9YS5FKGUsZCk7MSBnPTZbZl07MSBHPWcuYjsxIEg9MkgoRiwxNik7MSBJPUglRzsxIEo9Z1tJXTtlKz1kOzVbXCcySVwnXT1mOzVbXCcySlwnXT1KO2MuMksoNSl9MkwgY30yTS4yTj17RH07Jyw2MiwxNzQsJ3x2YXJ8fEJsYWNrfFJlZHxmZWF0dXJlc3xGZWF0dXJlc3xEZWZhdWx0fEJyb3dufGFkZHJlc3N8YWRkU3RyfGxlbmd0aHxhdHRyaWJ1dGVzfGdhcHxzaWR4fGZrZXl8dmFsdWVzfEJsYW5rfEJsdWUwMXxCbHVlMDJ8Qmx1ZTAzfEdyYXkwMXxHcmF5MDJ8SGVhdGhlcnxQYXN0ZWxCbHVlfFBhc3RlbEdyZWVufFBhc3RlbE9yYW5nZXxQYXN0ZWxSZWR8UGFzdGVsWWVsbG93fFBpbmt8V2hpdGV8QXVidXJufEJsb25kZXxCbG9uZGVHb2xkZW58QnJvd25EYXJrfFBhc3RlbFBpbmt8UGxhdGludW18U2lsdmVyR3JheXxjb25zdHxnZW5lcmF0ZXxzdWJzdHJ8c2VlZHx2YWxMZW5ndGh8c2VlZEludHx2aWR4fGZ2YWx8YWNjZXNzb3JpZXNUeXBlfEt1cnR8UHJlc2NyaXB0aW9uMDF8UHJlc2NyaXB0aW9uMDJ8Um91bmR8U3VuZ2xhc3Nlc3xXYXlmYXJlcnN8Y2xvdGhlVHlwZXxCbGF6ZXJTaGlydHxCbGF6ZXJTd2VhdGVyfENvbGxhclN3ZWF0ZXJ8R3JhcGhpY1NoaXJ0fEhvb2RpZXxPdmVyYWxsfFNoaXJ0Q3Jld05lY2t8U2hpcnRTY29vcE5lY2t8U2hpcnRWTmVja3xjbG90aGVDb2xvcnxleWVicm93VHlwZXx8QW5ncnl8QW5ncnlOYXR1cmFsfHxEZWZhdWx0TmF0dXJhbHxGbGF0TmF0dXJhbHxSYWlzZWRFeGNpdGVkfFJhaXNlZEV4Y2l0ZWROYXR1cmFsfFNhZENvbmNlcm5lZHxTYWRDb25jZXJuZWROYXR1cmFsfFVuaWJyb3dOYXR1cmFsfFVwRG93bnxVcERvd25OYXR1cmFsfGV5ZVR5cGV8Q2xvc2V8Q3J5fERpenp5fEV5ZVJvbGx8SGFwcHl8SGVhcnRzfFNpZGV8U3F1aW50fFN1cnByaXNlZHxXaW5rfFdpbmtXYWNreXxmYWNpYWxIYWlyQ29sb3J8ZmFjaWFsSGFpclR5cGV8QmVhcmRNZWRpdW18QmVhcmRMaWdodHxCZWFyZE1hZ2VzdGljfE1vdXN0YWNoZUZhbmN5fE1vdXN0YWNoZU1hZ251bXxncmFwaGljVHlwZXxCYXR8Q3VtYmlhfERlZXJ8RGlhbW9uZHxIb2xhfFBpenphfFJlc2lzdHxTZWxlbmF8QmVhcnxTa3VsbE91dGxpbmV8U2t1bGx8aGFpckNvbG9yfG1vdXRoVHlwZXxDb25jZXJuZWR8RGlzYmVsaWVmfEVhdGluZ3xHcmltYWNlfFNhZHxTY3JlYW1PcGVufFNlcmlvdXN8U21pbGV8VG9uZ3VlfFR3aW5rbGV8Vm9taXR8c2tpbkNvbG9yfFRhbm5lZHxZZWxsb3d8UGFsZXxMaWdodHxEYXJrQnJvd258dG9wVHlwZXxOb0hhaXJ8RXllcGF0Y2h8SGF0fEhpamFifFR1cmJhbnxXaW50ZXJIYXQxfFdpbnRlckhhdDJ8V2ludGVySGF0M3xXaW50ZXJIYXQ0fExvbmdIYWlyQmlnSGFpcnxMb25nSGFpckJvYnxMb25nSGFpckJ1bnxMb25nSGFpckN1cmx5fExvbmdIYWlyQ3Vydnl8TG9uZ0hhaXJEcmVhZHN8TG9uZ0hhaXJGcmlkYXxMb25nSGFpckZyb3xMb25nSGFpckZyb0JhbmR8TG9uZ0hhaXJOb3RUb29Mb25nfExvbmdIYWlyU2hhdmVkU2lkZXN8TG9uZ0hhaXJNaWFXYWxsYWNlfExvbmdIYWlyU3RyYWlnaHR8TG9uZ0hhaXJTdHJhaWdodDJ8TG9uZ0hhaXJTdHJhaWdodFN0cmFuZHxTaG9ydEhhaXJEcmVhZHMwMXxTaG9ydEhhaXJEcmVhZHMwMnxTaG9ydEhhaXJGcml6emxlfFNob3J0SGFpclNoYWdneU11bGxldHxTaG9ydEhhaXJTaG9ydEN1cmx5fFNob3J0SGFpclNob3J0RmxhdHxTaG9ydEhhaXJTaG9ydFJvdW5kfFNob3J0SGFpclNob3J0V2F2ZWR8U2hvcnRIYWlyU2lkZXN8U2hvcnRIYWlyVGhlQ2Flc2FyfFNob3J0SGFpclRoZUNhZXNhclNpZGVQYXJ0fHRvcENvbG9yfGZvcnxpbnxwYXJzZUludHx0cmFpdF90eXBlfHZhbHVlfHB1c2h8cmV0dXJufG1vZHVsZXxleHBvcnRzJy5zcGxpdCgnfCcpLDAse30pKQ==";
    }
    

    function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}