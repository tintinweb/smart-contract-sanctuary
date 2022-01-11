// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./Ownable.sol";
import "./Token.sol";



contract TokenSwap is Ownable {


    
    //create state variables

    FrogToken frogToken;
    
    IERC20 public USDC_token;
    IERC20 public BFSC_token;
    address public Buyer;
    address public VendorContract;
    uint amountAfterFee;
    
    constructor(
        address _USDCtoken,
        address _BFSCtoken,
        address _Seller
        
    )
       {
            USDC_token = IERC20(_USDCtoken);
            BFSC_token = IERC20(_BFSCtoken);
            VendorContract = _Seller;
            frogToken = FrogToken(_USDCtoken);
       }
        
        function USDCtoBFSC(address _Buyer, uint _amount) public {
            require(msg.sender == _Buyer, "Not authorized");
            
            // exchange USDC for BlackFrogStableCoin
            _safeTransferFrom(USDC_token, Buyer, VendorContract, _amount);
            
            amountAfterFee = _amount * 95 / 100;
            
            frogToken.mint (Buyer, amountAfterFee);

        }
        //This is a private function that the function above is going to call
        //the result of this transaction(bool) is assigned in a variable called sent
        //then we require the transfer to be successful
        function _safeTransferFrom(IERC20 token, address sender, address recipient, uint amount) private {bool sent = token.transferFrom(sender, recipient, amount);
            require(sent, "Token transfer failed");
            
        }
}