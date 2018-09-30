pragma solidity ^0.4.24;

 /**                                                                                                                      
  aaaaaaaaaa:               aaaaaaaa`         aaaaaaaa         aaaaaaaaa+          aaaaaaaaaaaaaaaaaa+                
  a`        ,:              +        .       .       ,`        aa       &#39;         ;                  +                
  aa         :,             a         :      :        a        aa,       a        &#39;                   a               
  aa          :,            aa         +     &#39;         a       aaa        &#39;       a                   `.              
  aa;          :,           aa`         #    +,        ,`      aaaa       +       aa                   a              
  aaa           :,          aaa          #   a&#39;         a      aaaa        a      aa.                   +             
  aaa            ;.         aaa;          +  aa          a     aaaaa        ;     aaa        #aaaaaaaaaaa             
  aaaa            ;.        aaaa           : aa          ..    aaaaa;       #     aaa#        aaaaaaaaaaa             
  aaaa             &#39;.       aaaaa           .aa           a    aaaaaa        a    aaaa        .aaaaaaaaaa&#39;            
  aaaa;             &#39;.      aaaaa             a            a   aaaaaaa       `,   aaaaa                   :           
  aaaaa              &#39;.     aaaaaa                         ..  aaaaaaa`       a   aaaaa;                   a          
  aaaaa               &#39;.    aaaaaa,                         a  aaaaaaaa        a  aaaaaa                    +         
  aaaaaa               &#39;`   aaaaaaa                          a aaaaaaaa&#39;       .. aaaaaaa                   &#39;         
  aaaaaa       +        +`  aaaaaaa+                         `,,aaaaaaaa        a aaaaaaa+                   a        
   aaaaa;       a        +` aaaaaaaa                          a  aaaaaaaa        a,aaaaaaaaaaaaaaaaaaa        ;       
   :aaaaa       +#        +` aaaaaaaa                          a  aaaaaaa.       ,``aaaaaaaaaaaaaaaaaa+       #       
    aaaaa        a;        +` +aaaaaa`                         `,  aaaaaaa        a `aaaaaaaaaaaaaaaaaa        a      
     aaaaa       +a.        +` ,aaaaaa                          a   aaaaaa#        #  aaaaaaaaaaaaaaaaaa       `,     
      aaaa                   #`  aaaaa;        .        &#39;        a   &#39;aaaaa        :`  aaaaaa                   a     
      `aaa;                   #   aaaaa         ,       a        `,   .aaaaa        a   aaaaa                    a    
       &#39;aaa                    #   aaaa#        ::      aa        #     aaaa:        +   &#39;aaaa                   :`   
        aaa                     #   #aaa         a;     &#39;a#        a     aaaa        ;     aaa.                   a   
         aaa        aaaa.        #   :aaa         a+    ,aa`        :     aaaa        a     aaa                    #  
          aa        aaaaa         a    aa.        #aa   ; aa        #      #aaaaaaaaaaa&#39;    :aaaaaaaaaaaaaaaaaaaaaaa  
          ,aaaaaaaaaaaaaaaaaaaaaaaaa    aaaaaaaaaaa#aaaaa  aaaaaaaaaa:      ;aaaaaaaaaaa     :aaaaaaaaaaaaaaaaaaaaaa  
           #aaaaaaaaa   aaaaaaaaaaa;     #aaaaaaaaa  .&#39;#a   aaaaaaaaa:       `aaaaaaaaaa      `aaaaaaaaaaaaaaaaaaaa`                                                                                                                        
 */                                                                                                                      


contract Conferencev02 {  // can be killed, so the owner gets sent the money in the end

	address public organizer;
	mapping (address => uint) public registrantsPaid;
	uint public numRegistrants;
	uint public quota;

	event Deposit(address _from, uint _amount); // so you can log the event
	event Refund(address _to, uint _amount); // so you can log the event

	function Conference() {
		organizer = msg.sender;		
		quota = 100;
		numRegistrants = 0;
	}

	function buyTicket() public payable {
		if (numRegistrants >= quota) { 
			revert(); // throw ensures funds will be returned
		}
		registrantsPaid[msg.sender] = msg.value;
		numRegistrants++;
		Deposit(msg.sender, msg.value);
	}

	function changeQuota(uint newquota) public {
		if (msg.sender != organizer) { return; }
		quota = newquota;
	}

	function refundTicket(address recipient, uint amount) public {
		if (msg.sender != organizer) { return; }
		if (registrantsPaid[recipient] == amount) { 
			address myAddress = this;
			if (myAddress.balance >= amount) { 
				recipient.transfer(amount);
				Refund(recipient, amount);
				registrantsPaid[recipient] = 0;
				numRegistrants--;
			}
		}
		return;
	}

	function destroy() {
		if (msg.sender == organizer) { // without this funds could be locked in the contract forever!
			suicide(organizer);
		}
	}
}