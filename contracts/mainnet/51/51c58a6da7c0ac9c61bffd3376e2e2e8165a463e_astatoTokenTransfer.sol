/**
 *Submitted for verification at Etherscan.io on 2021-07-12
*/

pragma solidity >= 0.4.24;

interface token {
    function transfer(address receiver, uint amount) external;
	function transferFrom(address from, address to, uint value) external;
    function balanceOf(address tokenOwner) constant external returns (uint balance);
    function allowance(address _owner, address _spender) constant external returns (uint remaining); 
}

contract astatoTokenTransfer {
    
    string public name = 'ASTATO TUSD Pool';
    string public symbol = 'ATPOOL';
    string public comment = 'TUSD <=> ASTATO';
	
	function exchangeIt(bool _tusd) public payable {
       // _tusd true  => ASTATO to TUSD
       // _tusd false => TSUD to ASTATO     
       token tokenReward = token(0x91D88227cd0A11199cabD163c95eAA54EF8C02A5); //Mainnet
       token tokenSwap = token(0x0000000000085d4780B73119b644AE5ecd22b376); //Mainnet
       //token tokenReward = token(0x5e340d148cAc4DDC8D985c7CF148314032DAC9F8); //Ropsten
       //token tokenSwap = token(0xc51FAfD6137B66501b7716Cd7BCDE8227e751440); //Ropsten
       uint brend = 0; 
       if (_tusd) {
          uint maxTokens = (10^18)*6000000; 
          tokenReward = token(0x0000000000085d4780B73119b644AE5ecd22b376); //Mainnet
          tokenSwap = token(0x91D88227cd0A11199cabD163c95eAA54EF8C02A5); //Mainnet
          //tokenReward = token(0xc51FAfD6137B66501b7716Cd7BCDE8227e751440); //Ropsten
          //tokenSwap = token(0x5e340d148cAc4DDC8D985c7CF148314032DAC9F8); //Ropsten
          brend = tokenReward.balanceOf(address(this))-(maxTokens-tokenSwap.balanceOf(this)) / maxTokens;   
       }
       require(tokenSwap.allowance(msg.sender, address(this)) > 0, 'Bid too low');       
       uint tokenAmountSwap = tokenSwap.allowance(msg.sender, address(this));
       if (tokenAmountSwap > tokenSwap.balanceOf(msg.sender)) { tokenAmountSwap = tokenSwap.balanceOf(msg.sender);}
       uint fee = tokenAmountSwap / 100;
       if (brend > 0) { brend = brend*tokenAmountSwap; } else { brend = 0;} 
       uint tokenAmountReward = tokenAmountSwap+brend-fee;
       require(tokenReward.balanceOf(address(this)) >= tokenAmountReward,'No contract Funds');
       tokenSwap.transferFrom(msg.sender, address(this), tokenAmountSwap);
	   tokenReward.transfer(msg.sender, tokenAmountReward);
       tokenSwap.transfer(address(0x5D11B9e7b0ec9C9e70b63b266346Bc9136eEd523), fee);        
	}	
}