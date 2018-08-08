pragma solidity ^0.4.19;

// Axie AOC sell contract. Not affiliated with the game developers. Use at your own risk.
//
// BUYERS: to protect against scams:
// 1) check the price by clicking on "Read smart contract" in etherscan. Two prices are published
//     a) price for 1 AOC in wei (1 wei = 10^-18 ETH), and b) number of AOC you get for 1 ETH
// 2) Make sure you use high enough gas price that your TX confirms within 1 hour, to avoid the scam
//    detailed below*
// 3) Check the hardcoded AOC address below givet to AOCToken() constructor. Make sure this is the real AOC
//    token. Scammers could clone this contract and modify the address to sell you fake tokens.
//

// This contract enables trustless exchange of AOC tokens for ETH.
// Anyone can use this contract to sell AOC, as long as it is in an empty state.
// Contract is in an empty state if it has no AOC or ETH in it and is not in cooldown
// The main idea behind the contract is to keep it very simple to use, especially for buyers.
// Sellers need to set allowance and call the setup() function using MEW, which is a little more involved.
// Buyers can use Metamask to send and receive AOC tokens.
//
// To use the contract:
// 1) Call approve on the AOC ERC20 address for this contract. That will allow the contract
//    to hold your AOC tokens in escrow. You can always withdraw you AOC tokens back.
//    You can make this call using MEW. The AOC contract address and ABI are available here:
//    https://etherscan.io/address/0x73d7b530d181ef957525c6fbe2ab8f28bf4f81cf#code
// 2) Call setup(AOC_amount, price) on this contract, for example by using MEW.
//    This call will take your tokens and hold them in escrow, while at the same time
//    you get the ownership of the contract. While you own the contract (i.e. while the contract
//    holds your tokens or your ETH, nobody else can call setup(). If they do, the call will fail.
//    If you call approve() on the AOC contract, but someone else calls setup() on this contract
//    nothing bad happens. You can either wait for this contract to go into empty state, or find
//    another contract (or publish your own). You will need to call approve() again for the new contract.
// 3) Advertise the contract address so others can buy AOC from it. Buying AOC is simple, the
//    buyer needs to send ETH to the contract address, and the contract sends them AOC. The buyer
//    can verify the price by viewing the contract.
// 4) To claim your funds back (both AOC and ETH resulting from any sales), simply send 0 ETH to
//    the contract. The contract will send you ETH and AOC back, and reset the contract for others to use.
//
// *) There is a cooldown period of 1 hour after the contract is reset, before it can be used again.
//    This is to avoid possible scams where the seller sees a pending TX on the contract, then resets
//    the contract and call setup() is a much higher price. If the seller does that with very high gas price,
//    they could change the price for the buyer&#39;s pending TX. A cooldown of 1 hour prevents this attac, as long
//    as the buyer&#39;s TX confirms within the hour.


interface AOCToken {
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

contract AOCTrader {
    AOCToken AOC = AOCToken(0x73d7B530d181ef957525c6FBE2Ab8F28Bf4f81Cf); // hardcoded AOC address to avoid scams.
    address public seller;
    uint256 public price; // price is in wei, not ether
    uint256 public AOC_available; // remaining amount of AOC. This is just a convenience variable for buyers, not really used in the contract.
    uint256 public Amount_of_AOC_for_One_ETH; // shows how much AOC you get for 1 ETH. Helps avoid price scams.
    uint256 cooldown_start_time;

    function AOCTrader() public {
        seller = 0x0;
        price = 0;
        AOC_available = 0;
        Amount_of_AOC_for_One_ETH = 0;
        cooldown_start_time = 0;
    }

    // convenience is_empty function. Sellers should check this before using the contract
    function is_empty() public view returns (bool) {
        return (now - cooldown_start_time > 1 hours) && (this.balance==0) && (AOC.balanceOf(this) == 0);
    }
    
    // Before calling setup, the sender must call Approve() on the AOC token 
    // That sets allowance for this contract to sell the tokens on sender&#39;s behalf
    function setup(uint256 AOC_amount, uint256 price_in_wei) public {
        require(is_empty()); // must not be in cooldown
        require(AOC.allowance(msg.sender, this) >= AOC_amount); // contract needs enough allowance
        require(price_in_wei > 1000); // to avoid mistakes, require price to be more than 1000 wei
        
        price = price_in_wei;
        AOC_available = AOC_amount;
        Amount_of_AOC_for_One_ETH = 1 ether / price_in_wei;
        seller = msg.sender;

        require(AOC.transferFrom(msg.sender, this, AOC_amount)); // move AOC to this contract to hold in escrow
    }

    function() public payable{
        uint256 eth_balance = this.balance;
        uint256 AOC_balance = AOC.balanceOf(this);
        if(msg.sender == seller){
            seller = 0x0; // reset seller
            price = 0; // reset price
            AOC_available = 0; // reset available AOC
            Amount_of_AOC_for_One_ETH = 0; // reset price
            cooldown_start_time = now; // start cooldown timer

            if(eth_balance > 0) msg.sender.transfer(eth_balance); // withdraw all ETH
            if(AOC_balance > 0) require(AOC.transfer(msg.sender, AOC_balance)); // withdraw all AOC
        }        
        else{
            require(msg.value > 0); // must send some ETH to buy AOC
            require(price > 0); // cannot divide by zero
            uint256 num_AOC = msg.value / price; // calculate number of AOC tokens for the ETH amount sent
            require(AOC_balance >= num_AOC); // must have enough AOC in the contract
            AOC_available = AOC_balance - num_AOC; // recalculate available AOC

            require(AOC.transfer(msg.sender, num_AOC)); // send AOC to buyer
        }
    }
}