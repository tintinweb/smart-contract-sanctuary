/**
 *Submitted for verification at Etherscan.io on 2020-12-16
*/

/**
 *Submitted for verification at Etherscan.io on 2020-12-16
*/

pragma solidity ^0.7.0;


// SPDX-License-Identifier: MIT
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
    assert(c / a == b);
    return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
        uint256 c = add(a,m);
        uint256 d = sub(c,1);
        return mul(div(d,m),m);
    }
}

contract SecretSanta {
	
	using SafeMath for uint;
	
	address payable public owner;
	uint public amountMinimumToPlay;
	uint public fee;
	uint public basepercent = 100;

	// Thursday 24 December 2020 04:20:00
	uint public christmaseve = 1608783600;
	
	// Friday 25 December 2020 04:20:00
	uint public christmasday = 1608870000;

	struct Santa {
		address payable wallet;
		uint amount;
	}
	
	Santa[] santas;
	Santa[] assignedSantas;
	
	mapping(address => uint) allSantas;

	event NewSanta(
		uint indexed _now,
		address indexed _wallet,
		uint _amount
	);
	event AssignSantas(
		uint indexed _now,
		uint _overallSantas,
		uint _overallFunds
	);
	event PlayFinish(
		uint indexed _now,
		bool _finish
	);
	
	constructor(
		uint amountMinimumToPlayArg
	) {
		amountMinimumToPlay = amountMinimumToPlayArg;
		owner = msg.sender; 
	}
	
	/* Deposit a gift for someone and become a sekret vitalik ! */ 
	function enter() payable external {
		require(msg.value >= amountMinimumToPlay, 'gift the min amount to become a secret santa');
        require(allSantas[msg.sender] == uint(0x0), 'you can only enter once');
        require(block.timestamp <= christmaseve, 'you are to late to the christmas party!');
        
		uint fee_amount = calcFee(msg.value);
		uint value = msg.value.sub(fee_amount);

		Santa memory santa = Santa({
			wallet: msg.sender, 
			amount: value
		});
		
		santas.push(santa);
		allSantas[msg.sender] = value;

		emit NewSanta(block.timestamp, msg.sender, msg.value);
	}
	

	/* When the right time has come anyone can call this function
		- This function will pay out all assigned santas !
		- Will selfdestruct the contract and transfer the fees to sekretvitalik.eth 
	*/ 
	function finishPlay() public payable {
		require(block.timestamp >= christmasday, 'you can not finish before christmasday');
		require(assignedSantas.length > 2, 'there must be min 2 Santas assigned before you can finish');

		for(uint i = 0; i < assignedSantas.length; i++) {
			Santa  memory recipient =  assignedSantas[i];
			recipient.wallet.transfer(recipient.amount);
		}
		
		emit PlayFinish(
			block.timestamp,
			true
		);
		
		destruct();
	}
	
	
	/* Public view functions */

	function getOverallSantas() view public returns (uint) {
		return santas.length;
	}
	
	function getOverallFunds() public view returns (uint overallFunds) {
		overallFunds = 0;
		
		for(uint i = 0; i < santas.length; i++) {
			overallFunds += santas[i].amount;
		}
		
		return overallFunds;
	}
	
	function checkPlayer(address payable playerAddress) public view returns (bool checkResult, uint checkAmount) {
		checkResult = false;
		checkAmount = 0;
		
		for(uint i = 0; i < santas.length; i++) {
			if(santas[i].wallet == playerAddress) {
				checkResult = true;
				if (msg.sender == owner || msg.sender == santas[i].wallet) {
					checkAmount = santas[i].amount;
				}
				break;
			}
		}
		
		return (checkResult, checkAmount);
		
	}
	
	function checkSender() public view returns (bool checkResult, uint checkAmount) {
		return checkPlayer(msg.sender);
	}
	
	/* Owner only functions */
	
	function setOwner (address payable newOwner) external onlyOwner {
		owner = newOwner;
	}
	
	// Just in case there is a problem and we need to change dates */
	function setchristmasday (uint newDay) external onlyOwner {
	    christmasday = newDay; 
	}

	// Just in case there is a problem and we need to change dates
    function setchristmaseve (uint newDay) external onlyOwner {
	    christmaseve = newDay; 
	}
    
    function assignSantas() external onlyOwner  {
		require(santas.length > 2);
		
		Santa[] memory shuffledSantas = shuffleSantas();
		
		for(uint i = 0; i < shuffledSantas.length; i++) {
			Santa memory santa = shuffledSantas[i];
			Santa memory recipient;
			
			if(i != shuffledSantas.length - 1) {
				recipient = shuffledSantas[i + 1];
			} else {
				recipient = shuffledSantas[0];
			}
			
			assignedSantas.push( Santa(recipient.wallet, santa.amount) );
		}
		
	}

	/* Internal functions */
	
	function shuffleSantas() internal view returns(Santa[] memory shuffledSantas) {
		shuffledSantas = santas;
		uint n = shuffledSantas.length;
		
		require(n > 2);
		
		uint i;
		Santa memory tmpSanta;
		
		while(n > 0) {
			i = random(block.timestamp, n--);
			tmpSanta = shuffledSantas[n];
			shuffledSantas[n] = shuffledSantas[i];
			shuffledSantas[i] = tmpSanta;
		}
		
		return shuffledSantas;
	}

    function random(uint seed, uint n) internal view returns (uint256) {
       uint256(
            keccak256(
                abi.encode(
                    block.difficulty, 
                    block.timestamp, 
                    tx.origin,
					blockhash(block.number),
					seed,
					n
                    )
                )
            );
    }

	function calcFee(uint _value) internal view returns(uint) {
		uint roundValue = SafeMath.ceil(_value, basepercent);
        uint onePercent = SafeMath.div(SafeMath.mul(roundValue, basepercent), 10000);
        return onePercent;
	}

	function destruct() onlyOwner internal {
		selfdestruct(owner);
	}

	modifier onlyOwner {
        require(msg.sender == owner, 
        'only manager can call this function');
        _;
    }

}