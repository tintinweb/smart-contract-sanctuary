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



////////////////////////////////////////////////////////
//:                                                  ://
//:            ESSENTIA Public Engagement            ://
//:               https://essentia.one               ://
//:..................................................://
////////////////////////////////////////////////////////




contract TokenCHK {


  function balanceOf(address _owner) public pure returns (uint256 balance) {}


}




contract ESSENTIA_PE is Ownable {

    using SafeMath for uint256;

    string public name = "ESSENTIA Public Engagement";      // Extended name of this contract
    uint256 public tokenPrice = 0;        // Set the fixed ESS token price
    uint256 public maxCap = 0;            // Set the target maximum cap in ETH
    address public FWDaddrETH;            // Set the address to forward the received ETH to
    address public ESSgenesis;            // Set the ESSENTIA Genesis contract address
    uint256 public totalSold;             // Keep track of the contributions total
    uint256 public decimals = 18;         // The decimals to consider

    mapping (address => uint256) public sold;       // Map the ESS token allcations

    uint256 public pubEnd = 0;                      // Set the unixtime END for the public engagement
    address contractAddr=this;                      // Better way to point to this from this

    // Constant to simplify the conversion of token amounts into integer form
    uint256 public tokenUnit = uint256(10)**decimals;



    //
    // "toETHaddr" is the address to which the ETH contributions are forwarded to, aka FWDaddrETH
    // "addrESSgenesis" is the address of the Essentia ERC20 token contract, aka ESSgenesis
    //
    // NOTE: this contract will sell only its token balance on the ERC20 specified in addrESSgenesis
    //       the maxCap in ETH and the tokenPrice will indirectly set the ESS token amount on sale
    //
    // NOTE: this contract should have sufficient ESS token balance to be > maxCap / tokenPrice
    //
    // NOTE: this contract will stop REGARDLESS of the above (maxCap) when its token balance is all sold 
    //
    // The Owner of this contract can set: Price, End, MaxCap, ESS Genesis and ETH Forward address
    //
    // The received ETH are directly forwarded to the external FWDaddrETH address
    // The ESS tokens are transferred to the contributing addresses once withdrawPUB is executed
    //


    constructor
        (
        address toETHaddr,
        address addrESSgenesis
        ) public {
        FWDaddrETH = toETHaddr;
        ESSgenesis = addrESSgenesis;
        
    }



    function () public payable {
        buy();               // Allow to buy tokens sending ETH directly to the contract, fallback
    }




    function setFWDaddrETH(address _value) public onlyOwner{
      FWDaddrETH=_value;     // Set the forward address default toETHaddr

    }


    function setGenesis(address _value) public onlyOwner{
      ESSgenesis=_value;     // Set the ESS erc20 genesis contract address default ESSgenesis

    }


    function setMaxCap(uint256 _value) public onlyOwner{
      maxCap=_value;         // Set the max cap in ETH default 0

    }


    function setPrice(uint256 _value) public onlyOwner{
      tokenPrice=_value;     // Set the token price default 0

    }


    function setPubEnd(uint256 _value) public onlyOwner{
      pubEnd=_value;         // Set the END of the public engagement unixtime default 0

    }




    function buy() public payable {

        require(block.timestamp < pubEnd);          // Require the current unixtime to be lower than the END unixtime
        require(msg.value > 0);                     // Require the sender to send an ETH tx higher than 0
        require(msg.value <= msg.sender.balance);   // Require the sender to have sufficient ETH balance for the tx

        // Requiring this to avoid going out of tokens, aka we are getting just true/false from the transfer call
        require(msg.value + totalSold <= maxCap);

        // Calculate the amount of tokens per contribution
        uint256 tokenAmount = (msg.value * tokenUnit) / tokenPrice;

        // Requiring sufficient token balance on this contract to accept the tx
        require(tokenAmount<=TokenCHK(ESSgenesis).balanceOf(contractAddr));

        transferBuy(msg.sender, tokenAmount);       // Instruct the accounting function
        totalSold = totalSold.add(msg.value);       // Account for the total contributed/sold
        FWDaddrETH.transfer(msg.value);             // Forward the ETH received to the external address

    }




    function withdrawPUB() public returns(bool){

        require(block.timestamp > pubEnd);          // Require the PE to be over - actual time higher than end unixtime
        require(sold[msg.sender] > 0);              // Require the ESS token balance to be sent to be higher than 0

        // Send ESS tokens to the contributors proportionally to their contribution/s
        if(!ESSgenesis.call(bytes4(keccak256("transfer(address,uint256)")), msg.sender, sold[msg.sender])){revert();}

        delete sold[msg.sender];
        return true;

    }




    function transferBuy(address _to, uint256 _value) internal returns (bool) {

        require(_to != address(0));                 // Require the destination address being non-zero

        sold[_to]=sold[_to].add(_value);            // Account for multiple txs from the same address

        return true;

    }



        //
        // Probably the sky would fall down first but, in case skynet feels funny..
        // ..we try to make sure anyway that no ETH would get stuck in this contract
        //
    function EMGwithdraw(uint256 weiValue) external onlyOwner {
        require(block.timestamp > pubEnd);          // Require the public engagement to be over
        require(weiValue > 0);                      // Require a non-zero value

        FWDaddrETH.transfer(weiValue);              // Transfer to the external ETH forward address
    }

}