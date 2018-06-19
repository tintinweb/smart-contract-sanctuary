pragma solidity ^0.4.11;

contract Game{

    string public name;
    uint8 public gamblers;

    address public gambler1;
    address public gambler2;
    address public fee;
    
    uint256 public bet1;
    uint256 public bet2;
    
    uint lastblocknumberused;
    bytes32 lastblockhashused;
    uint hashymchasherton;

    event gamblerevent(address gambler,uint bid);
    event winner(address winner,uint price);
    event loser(address loser,uint change);

    event Transfer(address indexed from, address indexed to, uint256 value);


    function Game(address _fee){

        gamblers = 0;

        name = &#39;Bet 0.1ETH,no more no less.Get 0.195ETH if you win,or 0.003ETH if you lose. &#39;;

        fee = _fee;

    }


    function bet() payable  {

        require(msg.value == 100000000000000000);//0.1eth
        gamblerevent(msg.sender,msg.value);

        gamblers++;
        
        if(gamblers ==1){
            gambler1=msg.sender;
            bet1=msg.value;
        }   
        if(gamblers ==2){
            gambler2=msg.sender;
            bet2=msg.value;
            
        }
        if(gamblers ==2)
        {
    	    lastblocknumberused = block.number - 1 ;
        	lastblockhashused = block.blockhash(lastblocknumberused);
        	hashymchasherton = sha(uint128(lastblockhashused));
    	
	        if( hashymchasherton % 2 == 0 ){
	            winner(gambler1,199500000000000000);
                    gambler1.transfer(199500000000000000);
                    loser(gambler2,300000000000000);
                    gambler2.transfer(300000000000000);
	        }
                else{
                    winner(gambler2,199500000000000000);
                    gambler2.transfer(199500000000000000);
                    loser(gambler1,300000000000000);
                    gambler1.transfer(300000000000000);

                }
        	
        	fee.transfer(200000000000000);//0.002eth

            gamblers = 0;
            gambler1 = 0;
            gambler2 = 0;
        }

    }
    
    function sha(uint128 wager) constant private returns(uint256)  	// DISCLAIMER: This is pretty random... but not truly random.
    { 
        return uint256(sha3(block.difficulty, block.coinbase, now, lastblockhashused, wager));  
    }
}