/*
Website: 
   -  TTT.finance
*/

pragma solidity ^0.5.0;

interface Token{
    
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);

}

contract SafeMath {
    function safeAdd(uint256 x, uint256 y) internal pure returns(uint256) {
        uint256 z = x + y;
        assert((z >= x) && (z >= y));
        return z;
    }

    function safeSubtract(uint256 x, uint256 y) internal pure returns(uint256) {
        assert(x >= y);
        uint256 z = x - y;
        return z;
    }

    function safeMult(uint256 x, uint256 y) internal pure returns(uint256) {
        uint256 z = x * y;
        assert((x == 0)||(z/x == y));
        return z;
    }

}

contract TttTokenSale is SafeMath {
    address payable admin;
    Token public tokenContract;
    uint256 public tokenPrice;
    uint256 public tokensSold;

    event Sell(address _buyer, uint256 _amount);

    constructor(Token _tokenContract, uint256 _tokenPrice) public {
        admin = msg.sender;
        tokenContract = _tokenContract;
        tokenPrice = _tokenPrice;
    }

    function buyTokens(uint256 _numberOfTokens) public payable {
        uint256 numberOfTokens =safeMult(_numberOfTokens,1e18);
        require(
            msg.value == safeMult(_numberOfTokens,tokenPrice),
            "Number of tokens does not match with the value"
        );
        require(
            tokenContract.balanceOf(address(this)) >= numberOfTokens,
            "Contact does not have enough tokens"
        );
        require(
            tokenContract.transfer(msg.sender, numberOfTokens),
            "Some problem with token transfer"
        );
        tokensSold += _numberOfTokens;
        emit Sell(msg.sender, numberOfTokens);
    }
    
    function withdraw() external { 
    require(msg.sender == admin, "Only the admin can call this function");
    admin.transfer(address(this).balance);
    }
   function setTokenExchangeRate(uint256 _tokenExchangeRate) external {
       require(msg.sender == admin, "Only the admin can call this function");
        require(_tokenExchangeRate != 0);
        require(_tokenExchangeRate != tokenPrice);

        tokenPrice = _tokenExchangeRate;
    }

    function endSale() public {
        require(msg.sender == admin, "Only the admin can call this function");
        require(
            tokenContract.transfer(
                msg.sender,
                tokenContract.balanceOf(address(this))
            ),
            "Unable to transfer tokens to admin"
        );
        // destroy contract
        selfdestruct(admin);
    }
}