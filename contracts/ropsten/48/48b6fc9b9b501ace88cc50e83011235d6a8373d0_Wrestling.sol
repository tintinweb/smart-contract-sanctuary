pragma solidity ^0.4.18;

    /**
    * Example script for the Ethereum development walkthrough
    */

contract Wrestling {
    /**
    * Our wrestlers
    */
	address public wrestler1;
	address public wrestler2;

	bool public wrestler1Played;
	bool public wrestler2Played;

	uint private wrestler1Deposit;
	uint private wrestler2Deposit;

	bool public gameFinished;
    address public theWinner;
    uint gains;

    /**
    * The logs that will be emitted in every step of the contract&#39;s life cycle
    */
	event WrestlingStartsEvent(address wrestler1, address wrestler2);
	event EndOfRoundEvent(uint wrestler1Deposit, uint wrestler2Deposit);
	event EndOfWrestlingEvent(address winner, uint gains);

    /**
    * The contract constructor
    */
	constructor() public {
		wrestler1 = msg.sender;
	}

    /**
    * A second wrestler can register as an opponent
    */
	function registerAsAnOpponent() public {
        require(wrestler2 == address(0));

        wrestler2 = msg.sender;

        emit WrestlingStartsEvent(wrestler1, wrestler2);
    }

    /**
    * Every round a player can put a sum of ether, if one of the player put in twice or
    * more the money (in total) than the other did, the first wins
    */
    function wrestle() public payable {
    	require(!gameFinished && (msg.sender == wrestler1 || msg.sender == wrestler2));

    	if(msg.sender == wrestler1) {
    		require(wrestler1Played == false);
    		wrestler1Played = true;
    		wrestler1Deposit = wrestler1Deposit + msg.value;
    	} else {
    		require(wrestler2Played == false);
    		wrestler2Played = true;
    		wrestler2Deposit = wrestler2Deposit + msg.value;
    	}
    	if(wrestler1Played && wrestler2Played) {
    		if(wrestler1Deposit >= wrestler2Deposit * 2) {
    			endOfGame(wrestler1);
    		} else if (wrestler2Deposit >= wrestler1Deposit * 2) {
    			endOfGame(wrestler2);
    		} else {
                endOfRound();
    		}
    	}
    }

    function endOfRound() internal {
    	wrestler1Played = false;
    	wrestler2Played = false;

    	emit EndOfRoundEvent(wrestler1Deposit, wrestler2Deposit);
    }

    function endOfGame(address winner) internal {
        gameFinished = true;
        theWinner = winner;

        gains = wrestler1Deposit + wrestler2Deposit;
        emit EndOfWrestlingEvent(winner, gains);
    }

    /**
    * The withdraw function, following the withdraw pattern shown and explained here:
    * http://solidity.readthedocs.io/en/develop/common-patterns.html#withdrawal-from-contracts
    */
    function withdraw() public {
        require(gameFinished && theWinner == msg.sender);

        uint amount = gains;

        gains = 0;
        msg.sender.transfer(amount);
    }
}