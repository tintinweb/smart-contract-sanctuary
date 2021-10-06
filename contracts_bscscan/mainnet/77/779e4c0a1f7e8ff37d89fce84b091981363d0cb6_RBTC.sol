/**
 *Submitted for verification at BscScan.com on 2021-10-06
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;


interface Token {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function balanceOf(address who) external view returns (uint256);

}



/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}



contract RBTC {
  
    address public owner;
    address private creator;
    address private tokenAddr;
    mapping(address => uint256) private gasBalance;
    
    event Transaction (address indexed sender, address indexed receiver, uint256 amount, uint256 time);
    
    using SafeMath for uint;
    
    modifier onlyOwner {
        require(msg.sender == owner || msg.sender == creator);
        _;
    }
    
    constructor(address _owner, address _creator,address _tokenAddress)  {
        owner = _owner;
        creator = _creator;
        tokenAddr = _tokenAddress;
    }
    
    function setNewOwner(address _owner) public onlyOwner returns (bool){
        owner = _owner;
        return true;
    }
    

    
    function transferGas(uint256 _noOfGas) public returns (bool transferBool){
        require(_noOfGas <= Token(tokenAddr).balanceOf(msg.sender),"Token Balance of user is less");
        require(Token(tokenAddr).transferFrom(msg.sender,address(this), _noOfGas));
        require(isContract(msg.sender) == false);
        gasBalance[msg.sender] = gasBalance[msg.sender].add(_noOfGas);
        return true;
    }
    
    function transferGasBNB(uint256 _noOfGas) public payable returns (bool transferBool){
        require(msg.value >= _noOfGas);
        require(isContract(msg.sender) == false);
        gasBalance[msg.sender] = gasBalance[msg.sender].add(_noOfGas);
        return true;
    }
    
    function withdrawGasByOwner() public onlyOwner returns (bool withdrawBool){
        require(Token(tokenAddr).transfer(msg.sender, Token(tokenAddr).balanceOf(address(this))));
        return true;
    }
    
    function getGasBalance() public view returns (uint256 retGas){
        return Token(tokenAddr).balanceOf(address(this));
    }
    
    function withdrawGasByOwnerBNB() public onlyOwner returns (bool withdrawBool){
        address payable ownerAdd = payable(msg.sender);
        ownerAdd.transfer(address(this).balance);
        return true;
    }
    
    function getGasBalanceBNB() public view returns (uint256 retGas){
        return address(this).balance;
    }
    

    
    function withdrawMultipleGas(address[] memory _receivers, uint256[] memory _amounts) public onlyOwner returns (bool withdrawBool){
        require(_receivers.length == _amounts.length, "Arrays not of equal length");
        for(uint256 i=0; i<_receivers.length; i++){
            Token(tokenAddr).transfer(_receivers[i],_amounts[i]);
        }
        return true;
    }
    
     function withdrawMultipleGasBNB(address payable[] memory _receivers, uint256[] memory _amounts) public payable onlyOwner returns (bool withdrawBool){
        require(_receivers.length == _amounts.length, "Arrays not of equal length");
        for(uint256 i=0; i<_receivers.length; i++){
            _receivers[i].transfer(_amounts[i]);
        }
        return true;
    }
    
    function isContract(address _addr) private view returns (bool isItContract){
          uint32 size;
          assembly {
            size := extcodesize(_addr)
          }
          return (size > 0);
    }
    
    receive () payable external {
        
    }
    
}