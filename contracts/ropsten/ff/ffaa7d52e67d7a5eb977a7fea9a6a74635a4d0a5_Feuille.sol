/**
 *Submitted for verification at Etherscan.io on 2021-09-14
*/

pragma solidity >=0.4.22 <0.9.0;

contract Feuille {

	address public player1;
	address public player2;

	bytes32 public hash1;
	bytes32 public hash2;
	uint public rev1;
	uint public rev2;	

	uint public score1;
	uint public score2;

	uint public state;

	uint public maxscore = 3;

	address public winner;

	constructor () public {
		player1 = msg.sender;
	}

	function joinGame() public {
		require(state == 0,"La partie est complete.");
		require(msg.sender != player1,"Vous etes deja dans la partie.");
		player2 = msg.sender;
		state = 1;
	}

	function sendHash(bytes32 hash) public {
		require(msg.sender == player1 || msg.sender == player2, "Vous n'etes pas dans la partie.");
		if(state == 1) {
			if(msg.sender == player1){
				hash1 = hash;
				state = 2;
			} else if (msg.sender == player2) {
				hash2 = hash;
				state = 3;
			} 
		} else if (state == 2) {
			require(msg.sender == player2, "Vous avez deja joue.");
			hash2 = hash;
			state = 4;
		} else if (state == 3) {
			require(msg.sender == player1, "Vous avez deja joue.");
			hash1 = hash;
			state = 4;
		} else {
			revert("La phase du jeu ne correspond pas avec cet appel.");
		}
	}

	function reveal(uint played, uint code) public {
		require(msg.sender == player1 || msg.sender == player2, "Vous n'etes pas dans la partie.");
		if(state == 4) {
			if(msg.sender == player1){
				require(hash1 == keccak256(abi.encodePacked(played,code)), "hashage incorrect.");
				rev1 = played;
				state = 5;
			} else if (msg.sender == player2) {
				require(hash2 == keccak256(abi.encodePacked(played,code)), "hashage incorrect.");
				rev2 = played;
				state = 6;
			}
		} else if (state == 5) {
			require(msg.sender == player2, "Vous avez deja joue.");
			require(hash2 == keccak256(abi.encodePacked(played,code)), "hashage incorrect.");
			rev2 = played;
			endTurn();
		} else if (state == 6) {
			require(msg.sender == player1, "Vous avez deja joue.");
			require(hash1 == keccak256(abi.encodePacked(played,code)), "hashage incorrect.");
			rev1 = played;
			endTurn();
		} else {
			revert("La phase du jeu ne correspond pas avec cet appel.");
		}
	}
// pierre = 1, feuille = 2, ciseaux = 3

	
	function endTurn() private {
		if(rev1 == rev2) {
			state = 1;
		} else {
			if((rev1 == 1 && rev2 == 2) || (rev1 == 2 && rev2 == 3) || (rev1 == 3 && rev2 == 1)) {
				score2 += 1;
				if(score2 < maxscore) {
					state = 1;
				} else {
					winner = player2;
					state = 7;
				}	
			} else {
				score1 += 1;
				if(score1 < maxscore) {
					state = 1;
				} else {
					winner = player1;
					state = 7;
				}	
			}
		}
	}
}