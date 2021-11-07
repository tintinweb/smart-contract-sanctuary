pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Ownable.sol";

/*this address has to be excluded from fees on ibnb contract and its usage allows the user to manually decide at anytime when his max claim time would be
*even when the user is in accumulation period,
*or if the claimable amount is not right the usage of this contract will fix that forcing a refresh of it and of the claimTime
*/
contract ClaimableAmountRefresher is Ownable{

    IERC20 public ibnb_token;
    constructor (IERC20 _ibnb_token) {
        ibnb_token=_ibnb_token;
    }

/**
* Function to update collectable dividends to immediately refresh the total amount to include any recent purchases.
*
*/
    function refreshCollectables() external {
      uint256 token_amount = ibnb_token.balanceOf(msg.sender);
      ibnb_token.transferFrom(msg.sender, address(this), token_amount);
      ibnb_token.transfer(msg.sender, token_amount);
    }

/**
* Function to rescue tokens incorrectly sent to the address of this smart-contract.
*
*/
    function rescueTokens(IERC20 tokenAddress)  external onlyOwner{
        IERC20 tokenBEP = tokenAddress;
        uint256 tokenAmt = tokenBEP.balanceOf(address(this));
        require(tokenAmt > 0, 'BEP-20 balance is 0');
        address payable wallet = payable(msg.sender);
        tokenBEP.transfer(wallet, tokenAmt);
    }

}