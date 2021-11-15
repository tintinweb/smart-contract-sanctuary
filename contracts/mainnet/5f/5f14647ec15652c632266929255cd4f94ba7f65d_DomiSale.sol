pragma solidity 0.8.1;

import "./DominoERC20.sol";

contract DomiSale {
    address payable admin;
    DominoERC20 public tokenContract;
    uint256 public tokenPrice;
    uint256 public tokensSold;

    event Sold(address buyer, uint256 amount);

    constructor(DominoERC20 _tokenContract, uint256 _price) {
        admin = payable(msg.sender);
        tokenContract = _tokenContract;
        tokenPrice = _price;
    }

    function multiply(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function buyTokens(uint256 _numberOfTokens) public payable {
        require(msg.value == multiply(_numberOfTokens, tokenPrice), "number of tokens is wrong");
        // input is number without 18 zeros, add 18 zeros to the end
        uint256 scaledAmount = multiply(_numberOfTokens, uint256(10) ** tokenContract.decimals());
        require(tokenContract.balanceOf(address(this)) >= scaledAmount);
        require(tokenContract.transfer(msg.sender, scaledAmount));

        tokensSold += _numberOfTokens;

        emit Sold(msg.sender, _numberOfTokens);
    }

    function buyTokens2() public payable {
        require(msg.value > 0, "no eth is sent");
        uint256 _numberOfTokens = div(msg.value, tokenPrice);
        uint256 scaledAmount = multiply(_numberOfTokens, uint256(10) ** tokenContract.decimals());
        require(tokenContract.balanceOf(address(this)) >= scaledAmount);
        require(tokenContract.transfer(msg.sender, scaledAmount));

        tokensSold += _numberOfTokens;

        emit Sold(msg.sender, _numberOfTokens);
    }

    function endSale() public {
        require(msg.sender == admin);
        require(tokenContract.transfer(admin, tokenContract.balanceOf(address(this))));

        // UPDATE: Let's not destroy the contract here
        // Just transfer the balance to the admin
        admin.transfer(address(this).balance);
    }    
    
    function setPrice(uint256 _price) public {
        require(msg.sender == admin, "must be admin to set price");
        tokenPrice = _price;
    }

    //the owner can withdraw from the contract because payable was added to the state variable above
    function withdraw (uint _amount) public {
        require(msg.sender == admin, "must be admin to withdraw");
        admin.transfer(_amount); 
    }
    
    //to.transfer works because we made the address above payable.
    function transfer(address payable _to, uint _amount) public {
        require(msg.sender == admin, "must be admin to transfer");
        _to.transfer(_amount); //to.transfer works because we made the address above payable.
    }
}