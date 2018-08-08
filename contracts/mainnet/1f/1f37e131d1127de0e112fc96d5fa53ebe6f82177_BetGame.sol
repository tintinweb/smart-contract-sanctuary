pragma solidity ^0.4.17;
contract BetGame  {
    struct bet {
        address player;
        uint deposit;
    }

	modifier onlyowner {
		require(msg.sender == owner, "Only owner is allowed");
		_;
	 }

	bet[] private A ;
	bet[] private B;
	bet[] private D;

	uint private totalA; 
	uint private totalB;
	uint private totalD;
	uint private betEnd;
	string private teamA ;
	string private teamB ;
	bool private open;
	address private owner;

	constructor(uint t, string a, string b) public {
		owner = msg.sender;
		betEnd = t;
		teamA = a;
		teamB = b;
		open = true;
	}

	function close() public onlyowner {
		selfdestruct(owner);
	}

	function getInfo() view onlyowner public returns(string, string, uint, uint, uint, uint, bool, uint, uint, uint) {
		return (teamA, teamB, betEnd, totalA, totalB, totalD, open, A.length, B.length, D.length );
	}

	function getInfoA(uint index) view onlyowner public returns(address, uint) {
		return (A[index].player, A[index].deposit);
	}
	
	function getInfoB(uint index) view onlyowner public returns(address, uint) {
		return (B[index].player, B[index].deposit);
	}
	
	function getInfoD(uint index) view onlyowner public returns(address, uint) {
		return (D[index].player, D[index].deposit);
	}
	

	function winnerIsA() public onlyowner {
		if (totalA > 0) {
        	uint housefee = (totalB + totalD) /80;

			uint award = (totalB + totalD) - housefee;

			uint ratio = 1000000 * award/totalA;

			for (uint p = 0; p < A.length; p++) {
				if (A[p].deposit > 0 ) {
					if (A[p].player.send(A[p].deposit + A[p].deposit/1000000*ratio)) {
						A[p].deposit = 0;
					}
				}
        	}
			totalA = 0;
		}
		totalB = 0;
		totalD = 0;
		open = false;
    }

	function winnerIsB() public onlyowner{
		if (totalB > 0) {
			uint housefee = (totalA + totalD) /80;
			uint award = (totalA + totalD) - housefee;
			uint ratio = 1000000 * award/totalB;

			for (uint p = 0; p < B.length; p++) {
				if (B[p].deposit > 0 ) {
					if (B[p].player.send(B[p].deposit + B[p].deposit/1000000*ratio)) {
						B[p].deposit = 0;
					}
				}
        	}
			totalB = 0;
		}
		totalA = 0;
		totalD = 0;
		open = false;
    }

	function winnerIsDraw() public onlyowner{
		if (totalD > 0) {
       		uint housefee = (totalB + totalA) /80;
			uint award = (totalB + totalA) - housefee;
			uint ratio = 1000000 * award/totalD;

			for (uint p = 0; p < D.length; p++) {
				if (D[p].deposit > 0 ) {
					if (D[p].player.send(D[p].deposit + D[p].deposit/1000000*ratio)) {
						D[p].deposit = 0;
					}
				}
        	}
			totalD = 0;
		}
		totalA = 0;
		totalB = 0;
		open = false;
    }

	function status(address addr) public view returns(uint, uint, uint, uint, uint, uint, bool) {
		uint a;
		uint b;
		uint d;
		
		if (!open) {
			return (0,0,0,0,0,0, false);
		}
		 
		for (uint p = 0; p < D.length; p++) {
			if (D[p].player == addr) {
				d+=D[p].deposit;
			}
        }
		
		for (p = 0; p < A.length; p++) {
			if (A[p].player == addr) {
				a+=A[p].deposit;
			}
        }
		for (p = 0; p < B.length; p++) {
			if (B[p].player == addr) {
				b+=B[p].deposit;
			}
        }
		
		return (a,b,d, totalA, totalB, totalD, true);
	}


	function betA() public payable {
		require(
            now <= betEnd,
            "Betting already ended."
        );

		require(open, "Game closed");

		require(msg.value >= 0.01 ether, "Single bet must be at least 0.01 ether");
		totalA+=msg.value;
		for(uint p =0; p<A.length; p++) {
			if (A[p].player == msg.sender)
			{
				A[p].deposit += msg.value;
				return;
			}
		}
		A.push(bet({player:msg.sender, deposit:msg.value}));
	}

	function betB() public payable {
		require(
            now <= betEnd,
            "Betting already ended."
        );

		require(open, "Game closed");
		require(msg.value >= 0.01 ether, "Single bet must be at least 0.01 ether");
		totalB+=msg.value;
		for(uint p =0; p<B.length; p++) {
			if (B[p].player == msg.sender)
			{
				B[p].deposit += msg.value;
				return;
			}
		}

		B.push(bet({player:msg.sender, deposit:msg.value}));
	}
	
	function betD() public payable {
		require(
            now <= betEnd,
            "Betting already ended."
        );
		require(open, "Game closed");
		require(msg.value >= 0.01 ether, "Single bet must be at least 0.01 ether");
		totalD+=msg.value;
		for(uint p =0; p<D.length; p++) {
			if (D[p].player == msg.sender)
			{
				D[p].deposit += msg.value;
				return;
			}
		}

		D.push(bet({player:msg.sender, deposit:msg.value}));
	}
}