/**
 *Submitted for verification at BscScan.com on 2021-12-31
*/

// SPDX-License-Identifier: Unlicensed

/*

CALLED - FEE_SPLIT_CONTRACT


Needs

Add the contract ID for iPay and ability to update if needed
Add the wallets for the people and the ability to update them

At this stage just send the tokens and the BNB to this address and then let this address deal with it!

this contract can swap the BNB to BUSD as needed and also send out the tokens to people - this address will be able to add teh liquidity 


So.....

1. tokens and BNB arrive (not BUSD)
2. The BNB is for marketing! And also some used for the 

Can this contract sell iPay tokens? to get the BUSD for the LP?

If it can not then we need to allow contract 1 to sell the iPay tokens. If can do this from contract one on a bool - sell iPay to BUSD 

Bool - SwapIPAY = yes = Contract one will swap the IPAY To BUSD and send the iPAY and BUSD here. 

If this contract can sell iPay to BUSD we do not need to do that!








*/

pragma solidity ^0.8.2;



interface IERC20 {
    
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

}




abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; 
        return msg.data;
    }
}


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        _owner = 0x627C95B6fD9026E00Ab2c373FB08CC47E02629a0;
        emit OwnershipTransferred(address(0), _owner);
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }


    
}

contract PrizePool is Ownable{
    
  
     address payable private wallet_prizePool_1 = payable(0xcf427cffaF76027Ee1bc5540F283cEa650ee96bf);
     address payable private wallet_prizePool_2 = payable(0xA3C0A499C29E5e73Ee8540BCc9508987cACae495);
     address payable private wallet_prizePool_3 = payable(0x7D15025D421c5fF186017e8809C584De9036772A);
     address payable private wallet_devFee = payable(0x9266EfB1f7938D564C5cbf9a2De6545Df3e463BF);



    //address private BUSD_T = address(0xe9e7cea3dedca5984780bafc599bd69add087d56); // Binance BUSD Token
    address private BUSD_T = address(0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7); // Test Net BUSD

    // Address of iPay token - need to be able to update this
    address private iPAY_T = address(0xF0eb9D0cBE80E2d9563865dCa0FFc8067B2eA69D); // Test Net iPAY - TEST ON SCBv2
 
    
   
     
    
  
  
    
    
    receive() external payable {}
    
    
     //manually purge BNB from contract to promo wallet
    function distributeBNB(uint256 bnbAmount) public onlyOwner {
        uint256 contractBNB = address(this).balance;
        if (contractBNB > 0) {
        if (bnbAmount > contractBNB) {bnbAmount = contractBNB;}
        
        uint256 toDev = bnbAmount/3;
        uint256 prizePool = bnbAmount-toDev;
        uint256 splitPrizePool = prizePool/6;
        uint256 toFirst = splitPrizePool*3;
        uint256 toSecond = splitPrizePool*2;
        uint256 toThird = splitPrizePool;

        sendToWallet(toDev, wallet_devFee);
        sendToWallet(toFirst, wallet_prizePool_1);
        sendToWallet(toSecond, wallet_prizePool_2);
        sendToWallet(toThird, wallet_prizePool_3);
        
        }
    }
    
    
    
    function sendToWallet(uint256 amount, address payable sendTo) private {
            sendTo.transfer(amount);
        }

        // SEND RANDOM 

    function remove_Random_Tokens(address random_Token_Address, address send_to_wallet, uint256 number_of_tokens) public onlyOwner returns(bool _sent){
        require(random_Token_Address != address(this), "Can not remove native token");
        uint256 randomBalance = IERC20(random_Token_Address).balanceOf(address(this));
        if (number_of_tokens > randomBalance){number_of_tokens = randomBalance;}
        _sent = IERC20(random_Token_Address).transfer(send_to_wallet, number_of_tokens);
    }


    // Swap iPay to Make BUSD LP

    // This would need a liquidity pool to work ! Test with new iPAY!

    // need function below wrapped in function and needs to get contract balance to split - needs to be only the 

    // if this contract sell iPAY to make LP then it will trigger a sell! And so will the first contract!!! So we have the 2 sell problem again

    // From here do... disperse tokens > send team allocations, send the BUSD from the sell on contract one and send the iPay to Lp wallet

    // Contract one must send BNB to trigger this contract to do stuff! So we need to use BNB for the LP and swap it to BUSD when we add LP 

    // So this contract only gets BNB and iPAy - the BNB is for marketing and Lp the iPay is for team and LP 

    // Get BNB - and iPay - swap some BNB to BUSD to pair with iPAY Tokens and add to LP - 

    // this will not be an accurate swap - check that the extra comes back to this contract

    // Could ahve 2 contracts... LP contract and Team Contract 

    // Sell tokens to BNB in Contract one and send BNB/iPAY to LP_CONTRACT 

    // Swap iPay to BNB on C1 put BNB back onto the contract. Use balance to get correct amounts to send the BNB to marketing or to C_LP

    // Take Tokens for the team and send to contract 2 with marketing funds. 

    // Send iPay and BNB to LP contract - Use that contract to swap BNB to BUSD and add LP 
/*

     uint256 tokens_to_LP_Half = contractTokenBalance / 2;

            address[] memory path = new address[](2);
            path[0] = iPAY_T;
            path[1] = BUSD_T;
            _approve(address(this), address(uniswapV2Router), tokens_to_LP_Half);
            uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokens_to_LP_Half,
            0,
            path,
            Wallet_BUSD_LP,
            block.timestamp
            );


        */
   
        
        
    }