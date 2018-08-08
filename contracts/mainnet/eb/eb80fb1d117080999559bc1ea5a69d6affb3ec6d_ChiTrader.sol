pragma solidity ^0.4.19;

// Aethia CHI sell contract. Not affiliated with the game developers. Use at your own risk.
//
// BUYERS: to protect against scams:
// 1) check the price by clicking on "Read smart contract" in etherscan. Two prices are published
//     a) price for 1 Chi in wei (1 wei = 10^-18 ETH), and b) number of Chi you get for 1 ETH
// 2) Make sure you use high enough gas price that your TX confirms within 1 hour, to avoid the scam
//    detailed below*
// 3) Check the hardcoded Chi address below givet to ChiToken() constructor. Make sure this is the real Chi
//    token. Scammers could clone this contract and modify the address to sell you fake tokens.
//
//
// This contract enables trustless exchange of Chi tokens for ETH.
// Anyone can use this contract to sell Chi, as long as it is in an empty state.
// Contract is in an empty state if it has no CHI or ETH in it and is not in cooldown
// The main idea behind the contract is to keep it very simple to use, especially for buyers.
// Sellers need to set allowance and call the setup() function using MEW, which is a little more involved.
// Buyers can use Metamask to send and receive Chi tokens.
//
// You are welcome to clone this contract as much as you want, as long as you dont&#39; try to scam anyone.
//
// To use the contract:
// 1) Call approve on the Chi ERC20 address for this contract. That will allow the contract
//    to hold your Chi tokens in escrow. You can always withdraw you Chi tokens back.
//    You can make this call using MEW. The Chi contract address and ABI are available here:
//    https://etherscan.io/address/0x71e1f8e809dc8911fcac95043bc94929a36505a5#code
// 2) Call setup(chi_amount, price) on this contract, for example by using MEW.
//    This call will take your tokens and hold them in escrow, while at the same time
//    you get the ownership of the contract. While you own the contract (i.e. while the contract
//    holds your tokens or your ETH, nobody else can call setup(). If they do, the call will fail.
//    If you call approve() on the Chi contract, but someone else calls setup() on this contract
//    nothing bad happens. You can either wait for this contract to go into empty state, or find
//    another contract (or publish your own). You will need to call approve() again for the new contract.
// 3) Advertise the contract address so others can buy Chi from it. Buying Chi is simple, the
//    buyer needs to send ETH to the contract address, and the contract sends them CHI. The buyer
//    can verify the price by viewing the contract.
// 4) To claim your funds back (both Chi and ETH resulting from any sales), simply send 0 ETH to
//    the contract. The contract will send you ETH and Chi back, and reset the contract for others to use.
//
// *) There is a cooldown period of 1 hour after the contract is reset, before it can be used again.
//    This is to avoid possible scams where the seller sees a pending TX on the contract, then resets
//    the contract and call setup() is a much higher price. If the seller does that with very high gas price,
//    they could change the price for the buyer&#39;s pending TX. A cooldown of 1 hour prevents this attac, as long
//    as the buyer&#39;s TX confirms within the hour.


interface ChiToken {
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

contract ChiTrader {
    ChiToken Chi = ChiToken(0x71E1f8E809Dc8911FCAC95043bC94929a36505A5); // hardcoded Chi address to avoid scams.
    address seller;
    uint256 price; // price is in wei, not ether
    uint256 Chi_available; // remaining amount of Chi. This is just a convenience variable for buyers, not really used in the contract.
    uint256 Amount_of_Chi_for_One_ETH; // shows how much Chi you get for 1 ETH. Helps avoid price scams.
    uint256 cooldown_start_time;

    function ChiTrader() public {
        seller = 0x0;
        price = 0;
        Chi_available = 0;
        Amount_of_Chi_for_One_ETH = 0;
        cooldown_start_time = 0;
    }

    // convenience is_empty function. Sellers should check this before using the contract
    function is_empty() public view returns (bool) {
        return (now - cooldown_start_time > 1 hours) && (this.balance==0) && (Chi.balanceOf(this) == 0);
    }
    
    // Before calling setup, the sender must call Approve() on the Chi token 
    // That sets allowance for this contract to sell the tokens on sender&#39;s behalf
    function setup(uint256 chi_amount, uint256 price_in_wei) public {
        require(is_empty()); // must not be in cooldown
        require(Chi.allowance(msg.sender, this) >= chi_amount); // contract needs enough allowance
        require(price_in_wei > 1000); // to avoid mistakes, require price to be more than 1000 wei
        
        price = price_in_wei;
        Chi_available = chi_amount;
        Amount_of_Chi_for_One_ETH = 1 ether / price_in_wei;
        seller = msg.sender;

        require(Chi.transferFrom(msg.sender, this, chi_amount)); // move Chi to this contract to hold in escrow
    }

    function() public payable{
        uint256 eth_balance = this.balance;
        uint256 chi_balance = Chi.balanceOf(this);
        if(msg.sender == seller){
            seller = 0x0; // reset seller
            price = 0; // reset price
            Chi_available = 0; // reset available chi
            Amount_of_Chi_for_One_ETH = 0; // reset price
            cooldown_start_time = now; // start cooldown timer

            if(eth_balance > 0) msg.sender.transfer(eth_balance); // withdraw all ETH
            if(chi_balance > 0) require(Chi.transfer(msg.sender, chi_balance)); // withdraw all Chi
        }        
        else{
            require(msg.value > 0); // must send some ETH to buy Chi
            require(price > 0); // cannot divide by zero
            uint256 num_chi = msg.value / price; // calculate number of Chi tokens for the ETH amount sent
            require(chi_balance >= num_chi); // must have enough Chi in the contract
            Chi_available = chi_balance - num_chi; // recalculate available Chi

            require(Chi.transfer(msg.sender, num_chi)); // send Chi to buyer
        }
    }
}