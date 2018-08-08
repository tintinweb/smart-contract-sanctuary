contract SHA3_512 {
    function SHA3_512() public {}

    function keccak_f(uint[25] A) pure internal returns(uint[25]) {
        uint[5] memory C;
        uint[5] memory D;
        //uint x;
        //uint y;
        //uint D_0; uint D_1; uint D_2; uint D_3; uint D_4;
        uint[25] memory B;

        uint[24] memory RC= [
                   uint(0x0000000000000001),
                   0x0000000000008082,
                   0x800000000000808A,
                   0x8000000080008000,
                   0x000000000000808B,
                   0x0000000080000001,
                   0x8000000080008081,
                   0x8000000000008009,
                   0x000000000000008A,
                   0x0000000000000088,
                   0x0000000080008009,
                   0x000000008000000A,
                   0x000000008000808B,
                   0x800000000000008B,
                   0x8000000000008089,
                   0x8000000000008003,
                   0x8000000000008002,
                   0x8000000000000080,
                   0x000000000000800A,
                   0x800000008000000A,
                   0x8000000080008081,
                   0x8000000000008080,
                   0x0000000080000001,
                   0x8000000080008008 ];

        for( uint i = 0 ; i < 24 ; i++ ) {
            /*
            for( x = 0 ; x < 5 ; x++ ) {
                C[x] = A[5*x]^A[5*x+1]^A[5*x+2]^A[5*x+3]^A[5*x+4];
            }*/

            C[0]=A[0]^A[1]^A[2]^A[3]^A[4];
            C[1]=A[5]^A[6]^A[7]^A[8]^A[9];
            C[2]=A[10]^A[11]^A[12]^A[13]^A[14];
            C[3]=A[15]^A[16]^A[17]^A[18]^A[19];
            C[4]=A[20]^A[21]^A[22]^A[23]^A[24];

            /*
            for( x = 0 ; x < 5 ; x++ ) {
                D[x] = C[(x+4)%5]^((C[(x+1)%5] * 2)&0xffffffffffffffff | (C[(x+1)%5]/(2**63)));
            }*/


            D[0]=C[4] ^ ((C[1] * 2)&0xffffffffffffffff | (C[1] / (2 ** 63)));
            D[1]=C[0] ^ ((C[2] * 2)&0xffffffffffffffff | (C[2] / (2 ** 63)));
            D[2]=C[1] ^ ((C[3] * 2)&0xffffffffffffffff | (C[3] / (2 ** 63)));
            D[3]=C[2] ^ ((C[4] * 2)&0xffffffffffffffff | (C[4] / (2 ** 63)));
            D[4]=C[3] ^ ((C[0] * 2)&0xffffffffffffffff | (C[0] / (2 ** 63)));

            /*
            for( x = 0 ; x < 5 ; x++ ) {
                for( y = 0 ; y < 5 ; y++ ) {
                    A[5*x+y] = A[5*x+y] ^ D[x];
                }
            }*/



            A[0]=A[0] ^ D[0];
            A[1]=A[1] ^ D[0];
            A[2]=A[2] ^ D[0];
            A[3]=A[3] ^ D[0];
            A[4]=A[4] ^ D[0];
            A[5]=A[5] ^ D[1];
            A[6]=A[6] ^ D[1];
            A[7]=A[7] ^ D[1];
            A[8]=A[8] ^ D[1];
            A[9]=A[9] ^ D[1];
            A[10]=A[10] ^ D[2];
            A[11]=A[11] ^ D[2];
            A[12]=A[12] ^ D[2];
            A[13]=A[13] ^ D[2];
            A[14]=A[14] ^ D[2];
            A[15]=A[15] ^ D[3];
            A[16]=A[16] ^ D[3];
            A[17]=A[17] ^ D[3];
            A[18]=A[18] ^ D[3];
            A[19]=A[19] ^ D[3];
            A[20]=A[20] ^ D[4];
            A[21]=A[21] ^ D[4];
            A[22]=A[22] ^ D[4];
            A[23]=A[23] ^ D[4];
            A[24]=A[24] ^ D[4];

            /*Rho and pi steps*/
            B[0]=A[0];
            B[8]=((A[1] * (2 ** 36))&0xffffffffffffffff | (A[1] / (2 ** 28)));
            B[11]=((A[2] * (2 ** 3))&0xffffffffffffffff | (A[2] / (2 ** 61)));
            B[19]=((A[3] * (2 ** 41))&0xffffffffffffffff | (A[3] / (2 ** 23)));
            B[22]=((A[4] * (2 ** 18))&0xffffffffffffffff | (A[4] / (2 ** 46)));
            B[2]=((A[5] * (2 ** 1))&0xffffffffffffffff | (A[5] / (2 ** 63)));
            B[5]=((A[6] * (2 ** 44))&0xffffffffffffffff | (A[6] / (2 ** 20)));
            B[13]=((A[7] * (2 ** 10))&0xffffffffffffffff | (A[7] / (2 ** 54)));
            B[16]=((A[8] * (2 ** 45))&0xffffffffffffffff | (A[8] / (2 ** 19)));
            B[24]=((A[9] * (2 ** 2))&0xffffffffffffffff | (A[9] / (2 ** 62)));
            B[4]=((A[10] * (2 ** 62))&0xffffffffffffffff | (A[10] / (2 ** 2)));
            B[7]=((A[11] * (2 ** 6))&0xffffffffffffffff | (A[11] / (2 ** 58)));
            B[10]=((A[12] * (2 ** 43))&0xffffffffffffffff | (A[12] / (2 ** 21)));
            B[18]=((A[13] * (2 ** 15))&0xffffffffffffffff | (A[13] / (2 ** 49)));
            B[21]=((A[14] * (2 ** 61))&0xffffffffffffffff | (A[14] / (2 ** 3)));
            B[1]=((A[15] * (2 ** 28))&0xffffffffffffffff | (A[15] / (2 ** 36)));
            B[9]=((A[16] * (2 ** 55))&0xffffffffffffffff | (A[16] / (2 ** 9)));
            B[12]=((A[17] * (2 ** 25))&0xffffffffffffffff | (A[17] / (2 ** 39)));
            B[15]=((A[18] * (2 ** 21))&0xffffffffffffffff | (A[18] / (2 ** 43)));
            B[23]=((A[19] * (2 ** 56))&0xffffffffffffffff | (A[19] / (2 ** 8)));
            B[3]=((A[20] * (2 ** 27))&0xffffffffffffffff | (A[20] / (2 ** 37)));
            B[6]=((A[21] * (2 ** 20))&0xffffffffffffffff | (A[21] / (2 ** 44)));
            B[14]=((A[22] * (2 ** 39))&0xffffffffffffffff | (A[22] / (2 ** 25)));
            B[17]=((A[23] * (2 ** 8))&0xffffffffffffffff | (A[23] / (2 ** 56)));
            B[20]=((A[24] * (2 ** 14))&0xffffffffffffffff | (A[24] / (2 ** 50)));

            /*Xi state*/
            /*
            for( x = 0 ; x < 5 ; x++ ) {
                for( y = 0 ; y < 5 ; y++ ) {
                    A[5*x+y] = B[5*x+y]^((~B[5*((x+1)%5)+y]) & B[5*((x+2)%5)+y]);
                }
            }*/


            A[0]=B[0]^((~B[5]) & B[10]);
            A[1]=B[1]^((~B[6]) & B[11]);
            A[2]=B[2]^((~B[7]) & B[12]);
            A[3]=B[3]^((~B[8]) & B[13]);
            A[4]=B[4]^((~B[9]) & B[14]);
            A[5]=B[5]^((~B[10]) & B[15]);
            A[6]=B[6]^((~B[11]) & B[16]);
            A[7]=B[7]^((~B[12]) & B[17]);
            A[8]=B[8]^((~B[13]) & B[18]);
            A[9]=B[9]^((~B[14]) & B[19]);
            A[10]=B[10]^((~B[15]) & B[20]);
            A[11]=B[11]^((~B[16]) & B[21]);
            A[12]=B[12]^((~B[17]) & B[22]);
            A[13]=B[13]^((~B[18]) & B[23]);
            A[14]=B[14]^((~B[19]) & B[24]);
            A[15]=B[15]^((~B[20]) & B[0]);
            A[16]=B[16]^((~B[21]) & B[1]);
            A[17]=B[17]^((~B[22]) & B[2]);
            A[18]=B[18]^((~B[23]) & B[3]);
            A[19]=B[19]^((~B[24]) & B[4]);
            A[20]=B[20]^((~B[0]) & B[5]);
            A[21]=B[21]^((~B[1]) & B[6]);
            A[22]=B[22]^((~B[2]) & B[7]);
            A[23]=B[23]^((~B[3]) & B[8]);
            A[24]=B[24]^((~B[4]) & B[9]);

            /*Last step*/
            A[0]=A[0]^RC[i];
        }


        return A;
    }


    function sponge(uint[9] M) pure internal returns(uint[16]) {
        require( (M.length * 8) == 72 );
        M[8] = 0x8000000000000001;

        uint r = 72;
        uint w = 8;
        uint size = M.length * 8;

        uint[25] memory S;
        uint i; uint y; uint x;
        /*Absorbing Phase*/
        for( i = 0 ; i < size/r ; i++ ) {
            for( y = 0 ; y < 5 ; y++ ) {
                for( x = 0 ; x < 5 ; x++ ) {
                    if( (x+5*y) < (r/w) ) {
                        S[5*x+y] = S[5*x+y] ^ M[i*9 + x + 5*y];
                    }
                }
            }
            S = keccak_f(S);
        }

        /*Squeezing phase*/
        uint[16] memory result;
        uint b = 0;
        while( b < 16 ) {
            for( y = 0 ; y < 5 ; y++ ) {
                for( x = 0 ; x < 5 ; x++ ) {
                    if( (x+5*y)<(r/w) && (b<16) ) {
                        result[b] = S[5*x+y] & 0xFFFFFFFF;
                        result[b+1] = S[5*x+y] / 0x100000000;
                        b+=2;
                    }
                }
            }
        }

        return result;
   }

   function hash(uint64[8] input) pure internal returns(uint32[16] output) {

       uint i;
       uint[9] memory M;
       for(i = 0 ; i < 8 ; i++) {
           M[i] = uint(input[i]);
       }

       uint[16] memory result = sponge(M);

       for(i = 0 ; i < 16 ; i++) {
           output[i] = uint32(result[i]);
       }
   }

}


contract TeikhosBounty is SHA3_512 {

    // Proof-of-public-key in format 2xbytes32, to support xor operator and ecrecover r, s v format
    bytes32 proof_of_public_key1 = hex"bd7c2d389d79b574152c3d9d98e8671a4552f0c0c0e389460eb4e16df173faba";
    bytes32 proof_of_public_key2 = hex"fe0238309e6e2ee8e4fd0efbcecf0969c8a1084fab7137b124c830ecb016c936";
    
    function authenticate(bytes _publicKey) public { // Accepts an array of bytes, for example ["0x00","0xaa", "0xff"]

        // Get address from public key
        address signer = address(keccak256(_publicKey));

        require(signer == msg.sender);

        // Use SHA3_512 library to get a sha3_512 hash of public key

        uint64[8] memory input;

        // The evm is big endian, have to reverse the bytes

        bytes memory reversed = new bytes(64);

        for(uint i = 0; i < 64; i++) {
            reversed[i] = _publicKey[63 - i];
        }

        for(i = 0; i < 8; i++) {
            bytes8 oneEigth;
            // Load 8 byte from reversed public key at position 32 + i * 8
            assembly {
                oneEigth := mload(add(reversed, add(32, mul(i, 8)))) 
            }
            input[7 - i] = uint64(oneEigth);
        }

        uint32[16] memory output = hash(input);
        
        bytes memory reverseHash = new bytes(64);
        
        for(i = 0; i < 16; i++) {
            bytes4 oneSixteenth = bytes4(output[15 - i]);
            // Store 4 byte in keyHash at position 32 + i * 4
            assembly { mstore(add(reverseHash, add(32, mul(i, 4))), oneSixteenth) }
        }

        bytes memory keyHash = new bytes(64);

        for(i = 0; i < 64; i++) {
            keyHash[i] = reverseHash[63 - i];
        }

        // Split hash of public key in 2xbytes32, to support xor operator and ecrecover r, s v format

        bytes32 hash1;
        bytes32 hash2;

        assembly {
        hash1 := mload(add(keyHash,0x20))
        hash2 := mload(add(keyHash,0x40))
        }

        // Use xor (reverse cipher) to get signature in r, s v format
        bytes32 r = proof_of_public_key1 ^ hash1;
        bytes32 s = proof_of_public_key2 ^ hash2;

        // Get msgHash for use with ecrecover
        bytes32 msgHash = keccak256("\x19Ethereum Signed Message:\n64", _publicKey);

        // The value v is not known, try both 27 and 28
        if(ecrecover(msgHash, 27, r, s) == signer) selfdestruct(msg.sender);
        if(ecrecover(msgHash, 28, r, s) == signer) selfdestruct(msg.sender);
    }
    
    function() public payable {}

}