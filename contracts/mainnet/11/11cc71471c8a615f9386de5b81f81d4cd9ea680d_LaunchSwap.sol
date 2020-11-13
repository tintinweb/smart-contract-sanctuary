// SPDX-License-Identifier: GPL-3.0
//pragma solidity >=0.4.16 <0.7.0;
pragma solidity ^0.6.6;

//import "@openzeppelin/contracts/access/Ownable.sol";

// -- LaunchSwap, a contract for launching ventures --

// investor submit capital and can redeem it at a cost
// for now this is a single instance of the swap
// the owner of the contract defines the mechanics
// owner defines the mid price and the spread
// users swap at the resulting bid and ask
// in first iteration no liquidity pools

// to visualize this market think of MM as setting only 2 variables
// 1) midprice
// 2) spread

// resulting offer to buy and sell
// low spread
// ask  | bid
// wide spread
// ask      |     bid


contract LaunchSwap {

    //VARIABLES
    uint256 mid;
    uint256 spread;
    uint256 cap;
    address private _owner;
    uint deployedAt;

    //investor_balances mapping
    ////investor_balances[sender]+= tokens;

    //EVENTS
    //event Bought(uint256 amount);
    //event Sold(uint256 amount);

    //TODO
    // address constant tokenAddress = address(
    //     0x14eb2ab8e6d09000a98e3166b3cc994375071f69 //ERC20 token address
    // );

    //mid = 0.03/404
    //0.000075 ETH/RTT
    //74000000000000 
    //amountRaised
    //amountCap

    constructor() public {
        _owner = msg.sender;
        deployedAt = block.number;
        mid = 300; //cents
        spread = 20;

        //TODO!
        //token = new ERC20Basic();
    }

     modifier onlyOwner(){
        //require(msg.sender == owner);
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
     }

    function setCap(uint256 _cap) public onlyOwner {
        cap = _cap;
    }

    //only admin can set the mid
    //more complex operations here will make sense later
    //purely algorithmic or driven by pool
    function setMid(uint256 _mid) public { // onlyOwner {
        mid = _mid;
    }

    //only admin can set spread
    //more complex operations here will make sense later
    //purely algorithmic or driven by pool
    function setSpread(uint256 _spread) public onlyOwner {    
        spread = _spread;
    }

    //bid calculated from mid and spread
    function getBid() public returns (uint256) {
        uint256 offset = mid * spread;
        uint256 bid = mid - offset;
        return bid;
    }


    //put up capital
    //swap eth for tokens
    function investETHForTokens(uint256 amountETH) public payable {
        //TODO: check cap reached?
        //TODO: check if round is open
        
        uint256 ask = getAsk();
        
        uint256 tokensToReceive = amountETH / ask;

        //uint256 fundBalance = token.balanceOf(address(this));
        require(amountETH > 0, "Need to send Ether");
        //require(amountTobuy <= fundBalance, "Not enough tokens in the reserve");
        //token.transfer(msg.sender, tokensToReceive);

        //emit Bought(amountTobuy);

        //TODO: check variable passed correctly
        //require (msg.value == amountETH)

        //TODO: send the tokens to msg.sender
        //ERC20(tokenAddress).approve(address spender, uint tokens)
        
        //send tokens
        //ERC20Token invest_token = ERC20Token(tokenAddr);
        //invest_token.transferFrom(_owner, _recipient, 100);
        //token.transfer(msg.sender, tokensReceive);
    }

    //investUSDCForTokens
    //check cash is received

    //withdraw capital
    //swap tokens for eth
    function DivestToTokens(uint256 amountTokens) public {
        //check if round
        uint256 bid = getBid();
        
        //require (msg.value == amountETH)
        uint256 receive_eth = amountTokens / bid;
        //cash is received

        //send tokens
        //ERC20Token tok = ERC20Token(tokenAddr);
        //tok.transferFrom(_owner, _recipient, 100);
    }

    //ask calculated from mid and spread
    function getAsk() public returns (uint256) {        
        uint256 offset = (mid * spread)/100;
        uint256 ask = mid + offset;
        return ask;
    }

    function getMid() public view returns (uint) {
        return mid;
    }

    function getSpread() public view returns (uint) {
        return spread;
    }

    function getDeployedAt() public view returns (uint) {
        return deployedAt;
    }
        
}