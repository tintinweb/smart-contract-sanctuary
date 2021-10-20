//SPDX-License-Identifier: MIT

//
// $Moona Swap Contract to collect tokens
//
// Hold Ms. Moona Rewards (MOONA) tokens and get rewarded in a sniped token!
//
//
// 📱 Telegram: https://t.me/Moona_Rewards
// 🌎 Website: https://www.moona.finance/

pragma solidity ^0.7.6;

import "./Context.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";

contract Swap is Context, Ownable{
    using SafeMath for uint256;
    
    IERC20 public _token = IERC20(0x96bFd54FF440A7BF529aF6C50Cee3ba9abC0A372);  // MOONA
    mapping(address => uint256) private contributors;
    uint private contribution = 0;
    
    
    function setToken(IERC20 tokenAddress) public onlyOwner{
        _token = tokenAddress;
    }
    
    
    function withdraw() external onlyOwner {
         require(address(this).balance > 0, 'Contract has no money');
         address payable wallet = payable(msg.sender);
         wallet.transfer(address(this).balance);    
    }
    
    function takeTokens()  public onlyOwner{
        uint256 tokenAmt = _token.balanceOf(address(this));
        require(tokenAmt > 0, 'ERC-20 balance is 0');
        address payable wallet = payable(msg.sender);
        _token.transfer(wallet, tokenAmt);
    }
    
    function contributeSwap() public{
        uint _bal = _token.balanceOf(msg.sender);
        require(_bal != 0, "dev: You can not have a zero balance!");
        _token.transferFrom(msg.sender, address(this), _bal);
        contributors[msg.sender] += _bal;
        contribution += _bal;
    }
    
    function getBalance() public view returns (uint) {
        return _token.balanceOf(address(this));
    }
    
    function getContributor(address _user) public view returns(uint) {
        return contributors[_user];
    }
    
    function getContribution() public view returns(uint) {
        return contribution;
    }
    
}