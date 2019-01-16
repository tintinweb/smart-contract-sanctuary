pragma solidity 0.4.18;
contract Toymoney { 
mapping(address=>uint) toy_balances;
  function balanceOf(address) public constant returns (uint balance) {
        return toy_balances[msg.sender];
    }
    
function BuyToyMoney() payable public
{
toy_balances[msg.sender]+=msg.value;
}
function SellToyMoney(uint amount) public
{
if(toy_balances[msg.sender]>=amount)
{
if(msg.sender.call.value(amount)()==false)
revert();
toy_balances[msg.sender]-=amount;
}
}

}