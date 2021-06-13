pragma solidity 0.8.4;

import "./Erc20.sol";

contract Sale {

    Token tokenManager;
    address owner;
    uint256 tokenPrice;
    uint256 ethAmmount;

    constructor(address _tokenManager, uint256 _tokenPrice){

        tokenManager = Token(_tokenManager);
        owner = msg.sender;
        tokenPrice = _tokenPrice;
    }

    function buyTokens(uint256 _tokensAmmount) payable public {
        require (_tokensAmmount * tokenPrice == msg.value, "incorrect ethereum value");
        require (tokenManager.balanceOf(address(this)) > _tokensAmmount, "cannot buy that ammount of tokens");
        require (tokenManager.transfer(msg.sender, _tokensAmmount), "tranfer not succed");
        ethAmmount += msg.value;
    }

    function getRate() public view returns (uint256) {

        return tokenPrice;
    }

    function withdrawEth() external payable {

        require(msg.sender == owner, "you are not the owner");

        payable(owner).transfer(ethAmmount);
    }

    receive() external payable {
        buyTokens(msg.value / tokenPrice);
    }
}