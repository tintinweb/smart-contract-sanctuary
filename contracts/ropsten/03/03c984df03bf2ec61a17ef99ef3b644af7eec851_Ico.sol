pragma solidity ^0.4.11;

contract ERC20Token {
   /* Public variables of the token */
   string public name;
   string public symbol;
   uint8 public decimals;
   uint256 public totalSupply;

   /* This creates an array with all balances */
   mapping (address => uint256) public balanceOf;

   /* This generates a public event on the blockchain that will notify clients */
   event Transfer(address indexed from, address indexed to, uint256 value);

   /* Initializes contract with initial supply tokens to the creator of the contract */
   function ERC20Token() {
       totalSupply = 10000;                      // Сколько токенов эмитируем
       balanceOf[msg.sender] = totalSupply;
       name = &quot;ICO token&quot;;                        // Название токена
       symbol = &quot;ICO&quot;;                        // Символ токена
       decimals = 0;                             // Amount of decimals for display purposes
   }

   /* Internal transfer, only can be called by this contract */
   function _transfer(address _from, address _to, uint _value) internal {
       require (_to != 0x0);                               // Prevent transfer to 0x0 address. Use burn() instead
       require (balanceOf[_from] > _value);                // Check if the sender has enough
       require (balanceOf[_to] + _value > balanceOf[_to]); // Check for overflows
       balanceOf[_from] -= _value;                         // Subtract from the sender
       balanceOf[_to] += _value;                            // Add the same to the recipient
       Transfer(_from, _to, _value);
   }

   /// @notice Send `_value` tokens to `_to` from your account
   /// @param _to The address of the recipient
   /// @param _value the amount to send
   function transfer(address _to, uint256 _value) {
       _transfer(msg.sender, _to, _value);
   }


}


contract Ico is ERC20Token {

      address public distributor;
      
      function Ico(){
          distributor = msg.sender;
      }
      
      // 1 ETH = 1000 ICO Token
      function() payable { 
            _transfer( distributor,  msg.sender, msg.value / 1000000000000000 );
      }

}