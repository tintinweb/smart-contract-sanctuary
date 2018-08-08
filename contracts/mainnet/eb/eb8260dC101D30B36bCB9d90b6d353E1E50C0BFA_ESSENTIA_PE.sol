pragma solidity ^0.4.24;

/*

    Copyright 2018, Angelo A. M. & Vicent Nos & Mireia Puig

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

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
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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



contract Ownable {

    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() internal {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}



//////////////////////////////////////////////////////////////
//                                                          //
//                ESSENTIA Public Engagement                //
//                   https://essentia.one                   //
//                                                          //
//////////////////////////////////////////////////////////////



contract ESSENTIA_PE is Ownable {

    // Contract variables and constants
    using SafeMath for uint256;

    uint256 public tokenPrice=0;
    address public addrFWD;
    address public token;
    uint256 public decimals=18;
    string public name="ESSENTIA Public Engagement";

    mapping (address => uint256) public sold;

    uint256 public pubEnd=0;
    // constant to simplify conversion of token amounts into integer form
    uint256 public tokenUnit = uint256(10)**decimals;



    // destAddr is the address to which the contributions are forwarded
    // mastTokCon is the address of the main token contract corresponding to the erc20 to be sold
    // NOTE the contract will sell only its token balance on the erc20 specified in mastTokCon


    constructor
        (
        address destAddr,
        address mastTokCon
        ) public {
        addrFWD = destAddr;
        token = mastTokCon;
    }



    function () public payable {
        buy();   // Allow to buy tokens sending ether directly to the contract
    }



    function setPrice(uint256 _value) public onlyOwner{
      tokenPrice=_value;   // Set the price token default 0

    }

    function setaddrFWD(address _value) public onlyOwner{
      addrFWD=_value;   // Set the forward address default destAddr

    }

    function setPubEnd(uint256 _value) public onlyOwner{
      pubEnd=_value;   // Set the END of engagement unixtime default 0

    }



    function buy()  public payable {
        require(block.timestamp<pubEnd);
        require(msg.value>0);
        uint256 tokenAmount = (msg.value * tokenUnit) / tokenPrice;   // Calculate the amount of tokens

        transferBuy(msg.sender, tokenAmount);
        addrFWD.transfer(msg.value);
    }



    function withdrawPUB() public returns(bool){
        require(block.timestamp>pubEnd);   // Finalize and transfer
        require(sold[msg.sender]>0);


        bool result=token.call(bytes4(keccak256("transfer(address,uint256)")), msg.sender, sold[msg.sender]);
        delete sold[msg.sender];
        return result;
    }



    function transferBuy(address _to, uint256 _value) internal returns (bool) {
        require(_to != address(0));

        sold[_to]=sold[_to].add(_value);   // Account for multiple txs from the same address

        return true;

    }
}