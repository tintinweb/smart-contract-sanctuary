/**
 *Submitted for verification at BscScan.com on 2021-11-11
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

interface IBEP20 {
    function name() external view returns(string memory);
    function symbol() external view returns(string memory);
    function decimals() external view returns(uint256);
    function totalSupply() external view returns(uint256);
    function balanceOf(address account) external view returns(uint256);
    function transfer(address recipient, uint256 amount) external returns(bool);
}

contract Authorization{
    address public owner;
    bool public paused;
    mapping(address => bool) public blackListedAddresses;
  
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Pause();
    event Unpause();

    modifier onlyOwner(){
      require(msg.sender == owner, "Only Owner Can Call This Function");
      _;
    }

    modifier whenNotPaused(){
      require(!paused, "Contract Is Paused");
      _;
    }

    modifier whenPaused(){
      require(paused, "Contract Is Not Paused");
      _;
    }

    function transferOwnership(address newOwner) public onlyOwner{
      require(newOwner != address(0), "New Address Must Not Be 0x");
      emit OwnershipTransferred(owner, newOwner);
      owner = newOwner;
    }
    
    function unpause() onlyOwner whenPaused public{
        paused = false;
        emit Unpause();
    }

    function pause() onlyOwner whenNotPaused public{
        paused = true;
        emit Pause();
    }
}

library SafeMath{
    function mul(uint a, uint b) internal pure returns (uint){
        if (a == 0) {
            return 0;
        }
        uint c = a * b;
        assert(c / a == b);
        return c;
    }
  
    function div(uint a, uint b) internal pure returns (uint){
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }
  
    function sub(uint a, uint b) internal pure returns (uint){
        assert(b <= a);
        return a - b;
    }
  
    function add(uint a, uint b) internal pure returns (uint){
        uint c = a + b;
        assert(c >= a);
        return c;
    }
}

contract ShibYieldPreLaunch is Authorization{
    
    using SafeMath for uint;
    
    address public tokenAddress;
    uint public tokenPriceInBNB;
    
    constructor() {
        owner = msg.sender;
        tokenAddress = 0xFec52A5b77c6Fa6Fd4C6aC0878972EFfe655088b;
        paused = false;
        tokenPriceInBNB = 236400000000000;
    }
    
    function setTokenAddress(address _tokenAddress) public onlyOwner returns(bool success){
        require(_tokenAddress != address(0));
        tokenAddress = _tokenAddress;
        return true ;
    }
    
    function setTokenPriceInBNB(uint _tokenPriceInBNB) public onlyOwner returns(bool success){
        require(_tokenPriceInBNB != 0);
        tokenPriceInBNB = _tokenPriceInBNB;
        return true ;
    }
    
    function withdrawTokens(address _tokenAddress, uint _tokenAmount) public onlyOwner returns(bool success){
        require(_tokenAmount > 0);
        if (_tokenAddress == address(0) && address(this).balance >= _tokenAmount)
        {
            payable(msg.sender).transfer(_tokenAmount);
            return true ;
        }
        else if (_tokenAddress != address(0) && IBEP20(_tokenAddress).balanceOf(address(this)) >= _tokenAmount)
        {
            IBEP20(_tokenAddress).transfer(msg.sender, _tokenAmount);
            return true;
        }
        else
        {
            return false;
        }
    }
    
    function withdrawAllTokens(address _tokenAddress) public onlyOwner returns(bool success){
        if (_tokenAddress == address(0))
        {
            payable(msg.sender).transfer(address(this).balance);
            return true;
        }
        else if (_tokenAddress != address(0))
        {
            IBEP20(_tokenAddress).transfer(msg.sender, IBEP20(_tokenAddress).balanceOf(address(this)));
            return true;
        }
        else
        {
            return false;
        }
    }
    
    receive() external payable{
        require(msg.value > 0);
        require(tokenAddress != address(0));
        require(tokenPriceInBNB != 0);
        require(!paused, 'ShibYieldPreLaunch Is Not Running');
        
        uint tokenToSend = msg.value.div(tokenPriceInBNB);
        
        require(IBEP20(tokenAddress).balanceOf(address(this)) >= tokenToSend,'Insufficient Tokens To Send');
        
        IBEP20(tokenAddress).transfer(msg.sender, tokenToSend);
    }
}