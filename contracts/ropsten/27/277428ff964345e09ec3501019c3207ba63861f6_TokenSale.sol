/**
 *Submitted for verification at Etherscan.io on 2021-04-08
*/

pragma solidity ^0.4.19;

interface IERC20Token {
    function balanceOf(address owner) public returns (uint256);
    function transfer(address to, uint256 amount) public returns (bool);
    function transferFrom(address sender, address recepient, uint256 amt) public returns (bool);
    function decimals() public returns (uint256);
}

contract TokenSale {
    IERC20Token public tokenContract;  // the token being sold
    uint256 public price;              // the price, in wei, per token
    address owner;

    uint256 public tokensSold;

    event Sold(address buyer, uint256 amount);

    function TokenSale(IERC20Token _tokenContract, uint256 _price) public {
        owner = msg.sender;
        tokenContract = _tokenContract;
        price = _price;
    }

    function buyTokens(uint256 numberOfTokens) public payable {
        require(msg.value == (numberOfTokens * price));

        uint256 scaledAmount = numberOfTokens *
            (uint256(10) ** tokenContract.decimals());

        require(tokenContract.balanceOf(this) >= scaledAmount);

        // Sold(msg.sender, numberOfTokens);
        // tokensSold += numberOfTokens;

        require(tokenContract.transfer(msg.sender, scaledAmount));
    }

    function sellTokens0(uint256 numberOfTokens) public {
        require(address(this).balance >= numberOfTokens * price);
        uint256 scaledAmount = numberOfTokens *
            (uint256(10) ** tokenContract.decimals());
            
        require(tokenContract.balanceOf(msg.sender) >= numberOfTokens);

        require(tokenContract.transferFrom(msg.sender, address(this), scaledAmount));
        
        msg.sender.transfer(numberOfTokens * price);
    }
     function sellTokens1(uint256 numberOfTokens) public view returns(bool){
        require(address(this).balance >= numberOfTokens * price);
        return true;
    }
    
     function sellTokens2(uint256 numberOfTokens) public view returns(bool) {
        require(tokenContract.balanceOf(msg.sender) >= numberOfTokens);
        return true;
    }
    
    function gett(uint256 numberOfTokens) public view returns(uint256 scaledAmount) {
          uint256 _scaledAmount = numberOfTokens *
            (uint256(10) ** tokenContract.decimals());
            return _scaledAmount;
    }
}