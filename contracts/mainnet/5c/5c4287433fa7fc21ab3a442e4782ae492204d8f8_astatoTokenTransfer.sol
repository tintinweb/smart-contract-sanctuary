/**
 *Submitted for verification at Etherscan.io on 2021-07-18
*/

pragma solidity >= 0.4.24;

interface token {
    function totalSupply() external constant returns (uint);
    function transfer(address receiver, uint amount) external;
	function transferFrom(address from, address to, uint value) external;
    function balanceOf(address tokenOwner) constant external returns (uint balance);
    function allowance(address _owner, address _spender) constant external returns (uint remaining);     
}

contract astatoTokenTransfer {
    string public name = 'ASTATO TUSD Pool';
    string public symbol = 'ATPOOL';
    string public comment = 'TUSD <=> ASTATO';
    uint public capitalAcum = 0; //only TUSD

    function getCapital() constant public returns (uint capital) {
       return capitalAcum;
    }

    function getPrize() constant public returns (uint vPrize) {
       return capitalAcum/6000000; 
    }

    function sendCapital(uint value) public payable { 
       token tokenReward = token(0x0000000000085d4780B73119b644AE5ecd22b376); //Mainnet
       //token tokenReward = token(0xd73a31d61308Db20cD5F51230086C94151821e8c); //Ropsten
       require(tokenReward.allowance(msg.sender, address(this)) >= value, 'First you need to authorize a value');       
       require(tokenReward.balanceOf(msg.sender) >= value, 'No balance to allowance');
       tokenReward.transferFrom(msg.sender, address(this), value);
       capitalAcum = capitalAcum+value;
    } 
	
	function exchangeIt(bool _tusd) public payable {
       // _tusd true  => ASTATO to TUSD
       // _tusd false => TSUD to ASTATO     
       token tokenReward = token(0x91D88227cd0A11199cabD163c95eAA54EF8C02A5); //Mainnet
       token tokenSwap = token(0x0000000000085d4780B73119b644AE5ecd22b376); //Mainnet
       //token tokenReward = token(0x5e340d148cAc4DDC8D985c7CF148314032DAC9F8); //Ropsten
       //token tokenSwap = token(0xd73a31d61308Db20cD5F51230086C94151821e8c); //Ropsten
       uint prize = 0;  
       if (_tusd) {
          tokenReward = token(0x0000000000085d4780B73119b644AE5ecd22b376); //Mainnet
          tokenSwap = token(0x91D88227cd0A11199cabD163c95eAA54EF8C02A5); //Mainnet
          //tokenReward = token(0xd73a31d61308Db20cD5F51230086C94151821e8c); //Ropsten
          //tokenSwap = token(0x5e340d148cAc4DDC8D985c7CF148314032DAC9F8); //Ropsten
          prize =  (tokenSwap.allowance(msg.sender, address(this))*capitalAcum)/token(tokenSwap).totalSupply();
       }
       require(tokenSwap.allowance(msg.sender, address(this)) > 0, 'First you need to authorize a value');       
       uint tokenAmountSwap = tokenSwap.allowance(msg.sender, address(this));
       require(tokenAmountSwap <= tokenSwap.balanceOf(msg.sender),'Low balance to swap');
       uint tokenAmountReward = tokenAmountSwap+prize;    
       require(tokenReward.balanceOf(address(this)) >= tokenAmountReward,'No contract Funds');
       tokenSwap.transferFrom(msg.sender, address(this), tokenAmountSwap);
       uint fee = tokenAmountReward/100;              
       capitalAcum = capitalAcum-prize;   
	   tokenReward.transfer(msg.sender, tokenAmountReward-fee);
       tokenReward.transfer(address(0x5D11B9e7b0ec9C9e70b63b266346Bc9136eEd523), fee);       
	}	
}