pragma solidity ^0.4.17;

library Pairing {
    struct G1Point {
        uint X;
        uint Y;
    }
    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint[2] X;
        uint[2] Y;
    }
    /// @return the generator of G1
    function P1() internal returns (G1Point) {
        return G1Point(1, 2);
    }
    /// @return the generator of G2
    function P2() internal returns (G2Point) {
        return G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );
    }
    /// @return the negation of p, i.e. p.add(p.negate()) should be zero.
    function negate(G1Point p) internal returns (G1Point) {
        // The prime q in the base field F_q for G1
        uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0)
            return G1Point(0, 0);
        return G1Point(p.X, q - (p.Y % q));
    }
    /// @return the sum of two points of G1
    function add(G1Point p1, G1Point p2) internal returns (G1Point r) {
        uint[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;
        assembly {
            success := call(sub(gas, 2000), 6, 0, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid }
        }
        require(success);
    }
    /// @return the product of a point on G1 and a scalar, i.e.
    /// p == p.mul(1) and p.add(p) == p.mul(2) for all points p.
    function mul(G1Point p, uint s) internal returns (G1Point r) {
        uint[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        assembly {
            success := call(sub(gas, 2000), 7, 0, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid }
        }
        require (success);
    }
    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.
    function pairing(G1Point[] p1, G2Point[] p2) internal returns (bool) {
        require(p1.length == p2.length);
        uint elements = p1.length;
        uint inputSize = elements * 6;
        uint[] memory input = new uint[](inputSize);
        for (uint i = 0; i < elements; i++)
        {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[0];
            input[i * 6 + 3] = p2[i].X[1];
            input[i * 6 + 4] = p2[i].Y[0];
            input[i * 6 + 5] = p2[i].Y[1];
        }
        uint[1] memory out;
        bool success;
        assembly {
            success := call(sub(gas, 2000), 8, 0, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid }
        }
        require(success);
        return out[0] != 0;
    }
    /// Convenience method for a pairing check for two pairs.
    function pairingProd2(G1Point a1, G2Point a2, G1Point b1, G2Point b2) internal returns (bool) {
        G1Point[] memory p1 = new G1Point[](2);
        G2Point[] memory p2 = new G2Point[](2);
        p1[0] = a1;
        p1[1] = b1;
        p2[0] = a2;
        p2[1] = b2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for three pairs.
    function pairingProd3(
            G1Point a1, G2Point a2,
            G1Point b1, G2Point b2,
            G1Point c1, G2Point c2
    ) internal returns (bool) {
        G1Point[] memory p1 = new G1Point[](3);
        G2Point[] memory p2 = new G2Point[](3);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for four pairs.
    function pairingProd4(
            G1Point a1, G2Point a2,
            G1Point b1, G2Point b2,
            G1Point c1, G2Point c2,
            G1Point d1, G2Point d2
    ) internal returns (bool) {
        G1Point[] memory p1 = new G1Point[](4);
        G2Point[] memory p2 = new G2Point[](4);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p1[3] = d1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        p2[3] = d2;
        return pairing(p1, p2);
    }
}

contract RPS {
	// Rock =0, Paper = 1, Scissors = 2
	address public user1;
	address public user2;
	bytes32 public hash1;
	bytes32 public hash2;
	int public claimed1;
	int public claimed2;
	uint  public firstRevealTime;
	bool public verified = false;
	// 0 for even, 1 for user1 wins, 2 for user2 wins.
	uint public result;

	// Check if required minimum amount is present
	modifier checkbalance() {
		require(msg.value>=10000000000000000);
		_;
	}
	// Check if user is already registered
	modifier isRegistered() {
		require(msg.sender==user1 || msg.sender==user2);
		_;
	}
	// Check if user is already registered
	modifier isNotRegistered() {
		require(msg.sender!=user1 && msg.sender!=user2);
		_;
	}
	// Check if both users have locked their choices, so the game can go to reveal stage
	modifier bothLocked(){
		require( hash1!=0 && hash2!=0);
		_;
	}


	// Check if string is valid
	modifier validChoice(string choice){
		require(keccak256(choice) == keccak256("rock") || keccak256(choice) == keccak256("paper") || keccak256(choice) == keccak256("scissors"));
		_;
	}
	modifier resultVerified(){
		require( verified);
		_;
	}


	function register() public payable isNotRegistered checkbalance{
		if(user1==0){
			user1 = msg.sender;
		}
		else {
			if(user2==0)
				user2 = msg.sender;
		}
	}
	function lock(string choice,string randStr) public isRegistered validChoice(choice) returns (bool) {
		if(msg.sender ==user1 && hash1==bytes32(0)){
			hash1 = keccak256(keccak256(choice) ^ keccak256(randStr));
			return true;
		}
		if(msg.sender ==user2 && hash2==bytes32(0)){
			hash2 = keccak256(keccak256(choice) ^ keccak256(randStr));
			return true;
		}
		return false;
	}

	function processRewards() public bothLocked resultVerified{
		// In case of no result, send half money to either parties
		if(result ==0){
			user1.transfer(9000000000000000);
			user2.transfer(9000000000000000);
		}
		// 3 choices in which user 1 wins
		if((claimed1==1 && claimed2==3) || (claimed1==2 && claimed2==1) || (claimed1==3 && claimed2==2) || claimed2==0)
			user1.transfer(18000000000000000);
		// 3 choices in which user 1 wins
		if((claimed1==3 && claimed2==1) || (claimed1==1 && claimed2==2) || (claimed1==2 && claimed2==3) || claimed1==0)
			user2.transfer(18000000000000000);
		// Reset all variables
		user1 = 0;
		user2 = 0;
		hash1 = bytes32(0);
		hash2 = bytes32(0);
		claimed1 = 0;
		claimed2 = 0;
		firstRevealTime = 0;
		result = 0;
		verified = false;
	}

	// Function to get state of game
	/* States : 			0  	Users have not locked yet
							1  	User 2 has locked, user 1 hasn&#39;t
							2  	User 1 has locked, user 2 hasn&#39;t
							421	Both users have locked, user1 claimed &#39;paper&#39;, user2 claimed &#39;rock&#39;
							413	Both users have locked, user1 claimed &#39;rock&#39;, user2 claimed &#39;scissors&#39;
							402 Both users have locked, user1 hasn&#39;t claimed anything yet, user2 claimed &#39;scissors&#39;
							441 Both users have locked, user1 coulnd&#39;t claim (timed-out), user2 claimed &#39;rock&#39;
	*/
	function getState() public view returns (int) {
	  	if(hash1==bytes32(0) && hash2==bytes32(0))
	  		return 0;
	  	if(hash1==bytes32(0) && hash2!=bytes32(0))
	  		return 1;
	  	if(hash1!=bytes32(0) && hash2==bytes32(0))
	  		return 2;
	  	// Both users have locked at this point of time, return values if claimed
	  	int ans = 400 + (claimed1*10 + claimed2);

	  	// Check the case of a user not able to claim a choice for long
	  	if(firstRevealTime!=0 && (now-firstRevealTime)>=120){
	  		if(claimed1 == 0)
	  			ans = 400 + (40 + claimed2);
	  		if(claimed2 == 0)
	  			ans = 400 + (claimed1*10 + 4);
	  	}

	  	return ans;
	}
	 using Pairing for *;
    struct VerifyingKey {
        Pairing.G2Point A;
        Pairing.G1Point B;
        Pairing.G2Point C;
        Pairing.G2Point gamma;
        Pairing.G1Point gammaBeta1;
        Pairing.G2Point gammaBeta2;
        Pairing.G2Point Z;
        Pairing.G1Point[] IC;
    }
    struct Proof {
        Pairing.G1Point A;
        Pairing.G1Point A_p;
        Pairing.G2Point B;
        Pairing.G1Point B_p;
        Pairing.G1Point C;
        Pairing.G1Point C_p;
        Pairing.G1Point K;
        Pairing.G1Point H;
    }
    function verifyingKey() internal returns (VerifyingKey vk) {
        vk.A = Pairing.G2Point([0x200432fc84ea809f9530c59eb276f8160fb24757ddae28f434834497ee36a510, 0x280cd18dc3b21ed97202b1b1149380e6e4e2d9e0f7b6e965136198e6c70bba1a], [0x1b7ce58b2d87db738fbfd1f7ea8255641292ccc4d105457c3ab0b7f107faa78a, 0xbbfe8830f7096d49395ed4ebefee52de39c8bbd28312941d54fc3efc1e2c3f8]);
        vk.B = Pairing.G1Point(0x893b0c7dec49b9123e2c318a90b556d2e072e44b134d1afe1a65575cffad9f4, 0x13629a74a3834fc48044b7b75aefbca94daa36770737859af3e13f863ff69843);
        vk.C = Pairing.G2Point([0xff38f66bce3e8bee5eb8c769cdddde0537ae0bfb98915409c03d34beaccf9b, 0x17dce55ace613b11cbfdd2255d913b57eee53a7de4218976fddca036676696f1], [0x1240182f9d3c40d1b85ac16b3684d0580b2a4c2b1f54f89c06ae6fd9f6a35a4, 0x2cbed2573ebd5174fbb71a16fdaf7ee24a0d33f3552187dff0455429a6aa38cf]);
        vk.gamma = Pairing.G2Point([0xc1f89f44f7666e51c7baa9e579517ce595c2a99e7908283da37711996df97d7, 0x1e522c32e8102f07f48dd5b1ce15544aa2a9be95ff831635eb0a8c8762957096], [0xce831e74cccf137d8c88e63844c40353506fe036b9ddb62dc5a557ccd52a288, 0x375113cd66c4a381d99ea411a3fa54c5c12c5acd835917edb611f0a737a2654]);
        vk.gammaBeta1 = Pairing.G1Point(0x7bb3bd1e0bb382c450ae6fafa2af3330889d5abfe7e94b0e59b65c35b5a181a, 0xf22a8652cae3945ecb338be5a32e6ca9e488a565a6bf2ce0e529913b6759cc3);
        vk.gammaBeta2 = Pairing.G2Point([0x575776b206f09d217fd375f356ab0a651a18bba99112c8a15536232a89394b5, 0xcba5bfbd7599a86e94d6deff70721705db66e287321ae55846123e32cf20929], [0x136874d206a619ae8afb710209ec4a80b851d91e8622d97d7666d7dd10e34321, 0x2f1b9531dd1176da0dbbb313a7fd83bb800edc1600f15d87e6f298e630d4feb3]);
        vk.Z = Pairing.G2Point([0xaa6bf05aa73c25ef72b2a648d7241c131c4b40cf6f340c5ee2e751924526a1a, 0x2e926df5ddb780489a7cbd3e9dde719b7443a6e42c15f012d8709f02c5136048], [0x1faf0c2b1bd783e087f1a4a685c82af86310c4b9cfe4cfe89e1032087eeb1247, 0x15c01f4a29151221e057be84e0e03b8926ba184344a5e1e6888e6a3afe7398bd]);
        vk.IC = new Pairing.G1Point[](2);
        vk.IC[0] = Pairing.G1Point(0x2370edbfcd3ca293ce5a0abfbcf79c6003404bddae16d19263398e7155771518, 0x10cf131f6f2c7997e479ea15a01fbac4d9d57bf0a98e11d083b9bfe5a2afce2a);
        vk.IC[1] = Pairing.G1Point(0x4bdf2a3fa104d0baf7cbe79b5922fce8e128949e16c67b47e119834650a01ad, 0x250cbd71835da0d5639f51c03c3d09213751d9ad943a00aeb1bb4bee2655dbb8);
    }
    function verify(uint[] input, Proof proof) internal returns (uint) {
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.IC.length);
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++)
            vk_x = Pairing.add(vk_x, Pairing.mul(vk.IC[i + 1], input[i]));
        vk_x = Pairing.add(vk_x, vk.IC[0]);
        if (!Pairing.pairingProd2(proof.A, vk.A, Pairing.negate(proof.A_p), Pairing.P2())) return 1;
        if (!Pairing.pairingProd2(vk.B, proof.B, Pairing.negate(proof.B_p), Pairing.P2())) return 2;
        if (!Pairing.pairingProd2(proof.C, vk.C, Pairing.negate(proof.C_p), Pairing.P2())) return 3;
        if (!Pairing.pairingProd3(
            proof.K, vk.gamma,
            Pairing.negate(Pairing.add(vk_x, Pairing.add(proof.A, proof.C))), vk.gammaBeta2,
            Pairing.negate(vk.gammaBeta1), proof.B
        )) return 4;
        if (!Pairing.pairingProd3(
                Pairing.add(vk_x, proof.A), proof.B,
                Pairing.negate(proof.H), vk.Z,
                Pairing.negate(proof.C), Pairing.P2()
        )) return 5;
        return 0;
    }
    event Verified(string);
    function verifyTx(
            uint[2] a,
            uint[2] a_p,
            uint[2][2] b,
            uint[2] b_p,
            uint[2] c,
            uint[2] c_p,
            uint[2] h,
            uint[2] k,
            uint[1] input
        ) bothLocked returns (bool r) {
        Proof memory proof;
        proof.A = Pairing.G1Point(a[0], a[1]);
        proof.A_p = Pairing.G1Point(a_p[0], a_p[1]);
        proof.B = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.B_p = Pairing.G1Point(b_p[0], b_p[1]);
        proof.C = Pairing.G1Point(c[0], c[1]);
        proof.C_p = Pairing.G1Point(c_p[0], c_p[1]);
        proof.H = Pairing.G1Point(h[0], h[1]);
        proof.K = Pairing.G1Point(k[0], k[1]);
        uint[] memory inputValues = new uint[](input.length);
        for(uint i = 0; i < input.length; i++){
            inputValues[i] = input[i];
        }
        if (verify(inputValues, proof) == 0) {
            result = input[0];
            Verified("Transaction successfully verified.");
            verified = true;
            return true;
        } else {
            return false;
        }
    }
}