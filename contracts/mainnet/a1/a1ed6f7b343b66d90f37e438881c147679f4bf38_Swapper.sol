pragma solidity ^0.6.6;

abstract contract ERC20TokenObject {

  function totalSupply() virtual public view returns (uint);
  function balanceOf(address who) virtual public view returns (uint);
  function transferFrom(address from, address to, uint256 value) virtual public returns (bool);
  function transfer(address to, uint value) virtual public returns (bool);
  function allowance(address owner_, address spender) virtual public view returns (uint);
  function approve(address spender, uint value) virtual public returns (bool);
  function increaseAllowance(address spender, uint addedValue) virtual public returns (bool);
  function decreaseAllowance(address spender, uint subtractedValue) virtual public returns (bool);

}

contract Swapper {
    
    address public _owner;
    address public ERC20TokenAddress;
    bool public presaleActive = true;
    uint public weiHardcap = 250 * 1e18;
    uint public weiRaised = 0;
    ERC20TokenObject private ERC20Token;
    
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    
    event SetERC20TokenAddress(address);
    
    constructor() public {
        _owner = msg.sender;
    }
    
    function setERC20TokenAddress(address addr) onlyOwner public returns (bool) {
        ERC20TokenAddress = addr;
        ERC20Token = ERC20TokenObject(addr);
        emit SetERC20TokenAddress(addr);
        return true;
    } 
    
    function depositERC20Token(uint amount) public {
        ERC20Token.transferFrom(msg.sender, address(this), amount);
    }
    
    function swapETHForERC20Token() payable public returns (bool) {
        uint amountERC20TokenToTransfer = msg.value * 2 / 125 / 1e9;
        require(amountERC20TokenToTransfer > 0, "NOT_ENOUGH_ETH");
        ERC20Token.transfer(msg.sender, amountERC20TokenToTransfer);
        weiRaised = weiRaised + msg.value;
        return true;
    }
    
    function endPresale() onlyOwner public returns (bool) {
        
        ERC20Token.transfer(msg.sender, ERC20Token.balanceOf(address(this)));
        payable(msg.sender).transfer(address(this).balance);
        return true;
        
    }
    
}