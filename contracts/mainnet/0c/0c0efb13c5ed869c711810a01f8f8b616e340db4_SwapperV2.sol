/**
 *Submitted for verification at Etherscan.io on 2020-11-13
*/

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

contract SwapperV2 {
    
    address public _owner;
    address public ERC20TokenAddress0;
    address public ERC20TokenAddress1;
    address public ERC20TokenAddress2;
    address public ERC20TokenAddress3;
    bool public presaleActive = true;
    uint public weiRaised = 0;
    uint public token0Raised = 0;
    uint public token1Raised = 0;
    ERC20TokenObject private ERC20Token0;
    ERC20TokenObject private ERC20Token1;
    ERC20TokenObject private ERC20Token2;
    ERC20TokenObject private ERC20Token3;
    
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    
    event SetERC20TokenAddresses(address, address, address, address);
    
    constructor() public {
        _owner = msg.sender;
    }
    
    function setERC20TokenAddresses(address addr0, address addr1, address addr2, address addr3) onlyOwner public returns (bool) {
        ERC20TokenAddress0 = addr0;
        ERC20TokenAddress1 = addr1;
        ERC20TokenAddress2 = addr2;
        ERC20TokenAddress3 = addr3;
        ERC20Token0 = ERC20TokenObject(addr0);
        ERC20Token1 = ERC20TokenObject(addr1);
        ERC20Token2 = ERC20TokenObject(addr2);
        ERC20Token3 = ERC20TokenObject(addr3);
        emit SetERC20TokenAddresses(addr0, addr1, addr2, addr3);
        return true;
    } 
    
    function depositERC20Tokens(uint amount0, uint amount1, uint amount2, uint amount3) onlyOwner public {
        ERC20Token0.transferFrom(msg.sender, address(this), amount0);
        ERC20Token1.transferFrom(msg.sender, address(this), amount1);
        ERC20Token2.transferFrom(msg.sender, address(this), amount2);
        ERC20Token3.transferFrom(msg.sender, address(this), amount3);
    }
    
    function swapETHForERC20Token2() payable public returns (bool) {
        uint amountERC20TokenToTransfer = msg.value * 2 / 125 / 1e9;
        require(amountERC20TokenToTransfer > 0, "NOT_ENOUGH_ETH");
        ERC20Token2.transfer(msg.sender, amountERC20TokenToTransfer);
        weiRaised = weiRaised + msg.value;
        return true;
    }
    
    function swapETHForERC20Token3() payable public returns (bool) {
        uint amountERC20TokenToTransfer = msg.value * 2 / 125 / 1e9;
        require(amountERC20TokenToTransfer > 0, "NOT_ENOUGH_ETH");
        ERC20Token3.transfer(msg.sender, amountERC20TokenToTransfer);
        weiRaised = weiRaised + msg.value;
        return true;
    }
    
    function swapETHForERC20Tokens2And3() payable public returns (bool) {
        uint amountERC20TokenToTransfer = msg.value * 1 / 125 / 1e9;
        require(amountERC20TokenToTransfer > 0, "NOT_ENOUGH_ETH");
        ERC20Token2.transfer(msg.sender, amountERC20TokenToTransfer);
        ERC20Token3.transfer(msg.sender, amountERC20TokenToTransfer);
        weiRaised = weiRaised + msg.value;
        return true;
    }
    
    function swapERC20Token0ForERC20Token2(uint inputTokens) public returns (bool) {
        uint amountERC20TokenToTransfer = inputTokens * 1;
        require(amountERC20TokenToTransfer > 0, "NOT_ENOUGH_TOKENS");
        ERC20Token0.transferFrom(msg.sender, address(this), inputTokens);
        ERC20Token2.transfer(msg.sender, amountERC20TokenToTransfer);
        token0Raised = token0Raised + inputTokens;
        return true;
    }
    
    function swapERC20Token1ForERC20Token3(uint inputTokens) public returns (bool) {
        uint amountERC20TokenToTransfer = inputTokens * 1;
        require(amountERC20TokenToTransfer > 0, "NOT_ENOUGH_TOKENS");
        ERC20Token1.transferFrom(msg.sender, address(this), inputTokens);
        ERC20Token3.transfer(msg.sender, amountERC20TokenToTransfer);
        token1Raised = token1Raised + inputTokens;
        return true;
    }
    
    function swapERC20Token0And1ForERC20Token2And3(uint inputTokens0, uint inputTokens1) public returns (bool) {
        uint amountERC20TokenToTransfer0 = inputTokens0 * 1;
        uint amountERC20TokenToTransfer1 = inputTokens1 * 1;
        require(amountERC20TokenToTransfer0 > 0, "NOT_ENOUGH_TOKENS");
        require(amountERC20TokenToTransfer1 > 0, "NOT_ENOUGH_TOKENS");
        ERC20Token0.transferFrom(msg.sender, address(this), inputTokens0);
        ERC20Token2.transfer(msg.sender, amountERC20TokenToTransfer0);
        ERC20Token1.transferFrom(msg.sender, address(this), inputTokens1);
        ERC20Token3.transfer(msg.sender, amountERC20TokenToTransfer1);
        token0Raised = token0Raised + inputTokens0;
        token1Raised = token1Raised + inputTokens1;
        return true;
    }
    
    function endPresale() onlyOwner public returns (bool) {
        
        ERC20Token0.transfer(msg.sender, ERC20Token0.balanceOf(address(this)));
        ERC20Token1.transfer(msg.sender, ERC20Token1.balanceOf(address(this)));
        ERC20Token2.transfer(msg.sender, ERC20Token2.balanceOf(address(this)));
        ERC20Token3.transfer(msg.sender, ERC20Token3.balanceOf(address(this)));
        payable(msg.sender).transfer(address(this).balance);
        presaleActive = false;
        return true;
        
    }
    
}