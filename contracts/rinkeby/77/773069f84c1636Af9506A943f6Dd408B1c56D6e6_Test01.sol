/**
 *Submitted for verification at Etherscan.io on 2021-08-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Test01 {

    uint256 number;
    string private _name;
    string private _symbol;
    string[] private colors;
    mapping(string => bool)_colorExists;
    mapping(bytes32 => uint256) public hashToTokenId;

    constructor (string memory name, string memory symbol){
        _name = name;
        _symbol = symbol;
        
    }
    
    function name() public view returns(string memory) {
        return _name;
    }
    
    function symbol() public view returns(string memory) {
        return _symbol;
    }
    
    function mint( string memory _color)public {
        
        require(!_colorExists[_color]);
        colors.push(_color);
        _colorExists[_color] = true;

   
        
    }
    
    function totalSupply() public view returns(uint256){
        return colors.length;
        
    }
    
    function showAll() public view returns (string[] memory){
        return colors;
    }
    
    function colorByIndex( uint256 _index) public view returns (string memory){
        require(_index < colors.length,"out of bound");
        return colors[_index];
    }
    


    function mintToken( uint256 _tokenId) public returns (uint256) {

        uint256 tokenIdToBe =  _tokenId;
        bytes32 hash = keccak256(abi.encodePacked(tokenIdToBe));
        hashToTokenId[hash] = tokenIdToBe;
        return tokenIdToBe;
    }
    

  
  
}