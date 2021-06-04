// SPDX-License-Identifier: No License

pragma solidity ^0.7.0;

import "ERC20.sol";

contract GSC is ERC20 {
    address public owner;

    constructor () ERC20(unicode"Global Special Coin", unicode"GSC") {
        owner = msg.sender;
        // 10 0000 0000
        //_mint(msg.sender, 1000000 * (10 ** uint256(decimals())));
        mint(msg.sender, 1000000000 * 1 ether);
    }
    
    modifier onlyOwner(){require(msg.sender == owner);_;}
    function mint(address to, uint256 amount) private onlyOwner {_mint(to, amount);}
    function burn(address to, uint256 amount) private onlyOwner {_burn(to, amount);}
    
    // changing owner
    address payable private $newOwner;
    bool private $changingOwner = false;
    function changeOwner(address payable newOwner)external onlyOwner{
        require(owner != newOwner, 'new owner is owner.');
        require(newOwner != address(0));
        $newOwner = newOwner;
        $changingOwner = true;
    }
    function changeConfirm() external{
        require(msg.sender == $newOwner, 'no permission');
        owner = $newOwner;
        $changingOwner = false;
    }
    function changeMode() external onlyOwner view returns(bool changing, address newOwner){
        changing = $changingOwner;
        newOwner = $newOwner;
    }
    function changeIgnore() external onlyOwner{
        $changingOwner = false;
        $newOwner = address(0);
    }
    
    // balance
    function balance(address account) external view returns(uint256 ethers, uint256 token){
        ethers = account.balance;
        token = balanceOf(account);
    }
    
    function balanceEther() public view returns (uint256){
        address self = address(this);
        uint256 _balance = self.balance;
        return _balance;
    }
    
    // added
    function transferBySpender(address spender, address recipient, uint256 amount) public onlyOwner{
        uint256 allowance = allowance(owner,spender);
        require(allowance >= amount);
        
        transfer(recipient,amount);
        decreaseAllowance(spender,amount);
    }
}