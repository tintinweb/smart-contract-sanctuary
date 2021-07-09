/**
 *Submitted for verification at BscScan.com on 2021-07-09
*/

pragma solidity ^0.5.12;

interface ERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

  function owner() public view returns(address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}
    
contract airdrop is Ownable {
 
 
    ERC20 erc20token;
    uint256 tokenValue;
    
    mapping(address => bool) public hasClaimed;
  
    event Multisended(uint256 total, ERC20 tokenAddress);
    event TokenClaimed(uint256 amount, address userAddress);

    
    constructor(ERC20 _token) public {
        erc20token = _token;
        tokenValue = 10 ether;
    }
   
    function claimOneTimeTokens() public {
        
        address beneficiary = msg.sender;
        
        require(hasClaimed[beneficiary] == false,"You have already claimed the one time tokens reward !");
        
        erc20token.transfer(beneficiary, tokenValue);
        
        hasClaimed[beneficiary] = true;
        
        emit TokenClaimed(tokenValue, beneficiary);
    }
    
    function multiSendToken(address[] memory _contributors, uint256[] memory _balances) public onlyOwner  {
      
            uint256 total = 0;
            uint8 i = 0;
            for (i; i < _contributors.length; i++) {
                erc20token.transfer(_contributors[i], _balances[i]);
                total += _balances[i];
            }
            
            emit Multisended(total, erc20token);
    }
    
    function setTokenValueForReward(uint256 _tokenValue) public onlyOwner returns (bool success) {
        
        tokenValue = _tokenValue;    
    
        return true;
    }
    
    function setTokenAddressForReward(ERC20 _tokenAddress) public onlyOwner returns (bool success) {
       
        erc20token = _tokenAddress;   

        return true;
    }
    
    
      function exitBnbLiquidity(uint256 _wei) public onlyOwner returns (bool success) {
        
        msg.sender.transfer(_wei);
        
        return true;
    }
    
    function exitLiquidity(uint256 _tokens) public onlyOwner returns (bool success) {
        
        erc20token.transfer(msg.sender, _tokens);
        
        return true;
    }
}