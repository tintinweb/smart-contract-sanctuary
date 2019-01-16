pragma solidity ^0.4.24;

contract DKG {

    uint256 constant GROUP_ORDER   = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    uint256 constant FIELD_MODULUS = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    uint256 constant g1x = 1;
    uint256 constant g1y = 2;

    uint256 constant g2xx = 11559732032986387107991004021392285783925812861821192530917403151452391805634;
    uint256 constant g2xy = 10857046999023057135944570762232829481370756359578518086990519993285655852781;
    uint256 constant g2yx = 4082367875863433681332203403145435568316851327593401208105741076214120093531;
    uint256 constant g2yy = 8495653923123431417604973247489272438418190587263600148770280649306958101930;

    struct Node {
        uint256 id;                 // the node&#39;s one based id, if id=0 the node has not registered or a dispute was successful
        uint256 deposit;            
        uint256[2] pk;              // the node&#39;s public key from group G1 (i.e. g1 * sk)
        uint256[4] bls_pk;          // the node&#39;s public key from group G2 (i.e. g2 * sk)
        bytes32 key_distribution_hash;
    }

    uint256[4] bls_group_pk;
    address[] registered_addresses;
    mapping (address => Node) nodes;

    bool public aborted;       

    uint256 public constant DELTA_INCLUDE = 20;            // TODO: set for production system
    uint256 public constant DELTA_CONFIRM = 2;             // TODO: increase for production system
    uint256 public constant PARTICIPATION_THRESHOLD = 3;   // minimum number of nodes which need to register (inclusive)
    // uint256 public constant PARTICIPATION_LIMIT = 256;  // maximum number of nodes allowed to register (inclusive)

    uint256 public T_CONTRACT_CREATION;     // block number in which the contract instance was created
    uint256 public T_REGISTRATION_END;      // block number of the last block where registration is possible
    uint256 public T_SHARING_END;           // block number of the last block where key sharing is possible
    uint256 public T_DISPUTE_END;           // block number of the last block where dispute is possible.
    uint256 public T_GROUP_KEY_UPLOAD;      // block number of the block in which the group key is uploaded (dynamic)
    
    event Registration(address node_adr, uint256 id, uint256 deposit, uint256[2] pk, uint256[4] bls_pk);
    event KeySharing(uint256 issuer, uint256[] encrypted_shares, uint256[] public_coefficients);
    event DisputeSuccessful(address bad_issuer_addr);

    constructor() public {
        // TODO: could set all this values as constants during compile time 
        // to save gas during deployment and for checking the guard conditions

        T_CONTRACT_CREATION = block.number;
        T_REGISTRATION_END = T_CONTRACT_CREATION + DELTA_CONFIRM + DELTA_INCLUDE;
        T_SHARING_END = T_REGISTRATION_END + DELTA_CONFIRM + DELTA_INCLUDE;
        T_DISPUTE_END = T_SHARING_END + DELTA_CONFIRM + DELTA_INCLUDE;
    }

    function in_registration_phase() 
    public view returns(bool) {
        return block.number <= T_REGISTRATION_END;
    }

    function in_sharing_phase() 
    public view returns(bool) {
        return (T_REGISTRATION_END < block.number) && (block.number <= T_SHARING_END);
    }

    function in_dispute_phase() 
    public view returns(bool) {
        return (T_SHARING_END < block.number) && (block.number <= T_DISPUTE_END);
    }

    function in_finalization_phase()
    public view returns(bool) {
        return (T_DISPUTE_END < block.number) && (T_GROUP_KEY_UPLOAD == 0);
    }

    function registrations_confirmed() 
    public view returns(bool) {
        return T_REGISTRATION_END + DELTA_CONFIRM <= block.number;
    }

    function sharing_confirmed()
    public view returns(bool) {
        return T_SHARING_END + DELTA_CONFIRM <= block.number;
    }

    function dispute_confirmed()
    public view returns(bool) {
        return T_DISPUTE_END + DELTA_CONFIRM <= block.number;
    }

    function group_key_confirmed()
    public view returns(bool) {
        return (T_GROUP_KEY_UPLOAD != 0) && (T_GROUP_KEY_UPLOAD + DELTA_CONFIRM <= block.number);
    }


    function register(uint256[2] pk, uint256[4] bls_pk, uint256[2] sk_knowledge_proof) 
    public payable 
    {
        require(in_registration_phase(), "registration failed (contract is not in registration phase)");
        require(nodes[msg.sender].id == 0, "registration failed (account already registered a public key)");
        require(
            bn128_check_pairing(                                    // ensures that the given pk and bls_pk correspond to each other
                [                                                   // i.e. that pk and bls_pk are of the form
                    pk[0], pk[1],                                   // pk     =  g1 * sk
                    g2xx, g2xy, g2yx, g2yy,                         // bls_pk = -g2 * sk
                    g1x, g1y,                                       // for some secret key sk
                    bls_pk[0], bls_pk[1], bls_pk[2], bls_pk[3]
                ]), 
            "registration failed (bls public key is invalid)"
        );
        require(
            verify_sk_knowledge(pk, sk_knowledge_proof), 
            "registration failed (invalid proof of secret key knowlegde)"
        );

        // TODO: check deposit amount is sufficient

        registered_addresses.push(msg.sender);
        uint256 id = registered_addresses.length;        

        nodes[msg.sender].id = id;
        nodes[msg.sender].deposit = msg.value;
        nodes[msg.sender].pk[0] = pk[0];
        nodes[msg.sender].pk[1] = pk[1];
        nodes[msg.sender].bls_pk[0] = bls_pk[0];
        nodes[msg.sender].bls_pk[1] = bls_pk[1];
        nodes[msg.sender].bls_pk[2] = bls_pk[2];
        nodes[msg.sender].bls_pk[3] = bls_pk[3];

        emit Registration(msg.sender, id, msg.value, pk, bls_pk);
    }

    function share_key(
        uint256[] encrypted_shares,     // Enc_kAB(s_i), each 256 bit
        uint256[] public_coefficients)  // Cj, each 512 bit
    public
    {
        uint256 n = registered_addresses.length;
        uint256 t = (n / 2) + 1;
        uint256 issuer_id = nodes[msg.sender].id;

        require(in_sharing_phase(), "key sharing failed (contract is not in sharing phase)");
        require(issuer_id > 0, "key sharing failed (ethereum account has not registered)");
        require(encrypted_shares.length == n - 1, "key sharing failed (invalid number of encrypted shares provided)");
        require(public_coefficients.length == t * 2 - 2, "key sharing failed (invalid number of commitments provided)");

        // for optimization we only store the hash of the submitted data
        // and emit an event with the actual data
        nodes[msg.sender].key_distribution_hash = keccak256(abi.encodePacked(encrypted_shares, public_coefficients));
        emit KeySharing(issuer_id, encrypted_shares, public_coefficients);
    }

    function dispute_public_coefficient(
        address issuer_addr,             // the node which is accussed to have distributed (at least one) invalid coefficient
        uint256[] encrypted_shares,      // the data from previous KeySharing event
        uint256[] public_coefficients,   // the data from previous KeySharing event
        uint256 invalid_coefficient_idx  // specifies any coefficient which is invalid (used for efficiency)
    ) 
    public
    {
        Node storage issuer = nodes[issuer_addr];
        Node storage verifier = nodes[msg.sender];

        require(in_dispute_phase(), "dispute failed (contract is not in sharing phase)");
        require(issuer.id > 0, "dispute failed/aborted (issuer not registered or slashed)");
        require(verifier.id > 0, "dispute failed/aborted (verifier not registered or slashed)");
        require(issuer.id != verifier.id, "dispute failed (self dispute is not allowed)");
        require(
            issuer.key_distribution_hash == keccak256(abi.encodePacked(encrypted_shares, public_coefficients)),
            "dispute failed (encrypted shares and/or public coefficients not matching)"
        );

        uint256 i = invalid_coefficient_idx * 2;
        require(
            !bn128_is_on_curve([public_coefficients[i], public_coefficients[i + 1]]),
            "dispute failed (coefficient is actually valid)"
        );

        __slash__(issuer_addr);
    }

    function dispute_share(
        address issuer_addr,             // the node which is accussed to have distributed an invalid share
        uint256[] encrypted_shares,      // the data from previous KeyDistribution event
        uint256[] public_coefficients,   // the data from previous KeyDistribution event
        uint256[2] decryption_key,       // shared key between issuer and calling node
        uint256[2] decryption_key_proof) // NIZK proof, showing that decryption key is valid
    public
    {
        Node storage issuer = nodes[issuer_addr];
        Node storage verifier = nodes[msg.sender];

        require(in_dispute_phase(), "dispute failed (contract is not in sharing phase)");
        require(issuer.id > 0, "dispute failed/aborted (issuer not registered or slashed)");
        require(verifier.id > 0, "dispute failed/aborted (verifier not registered or slashed)");
        require(issuer.id != verifier.id, "dispute failed (self dispute is not allowed)");
        require(
            issuer.key_distribution_hash == keccak256(abi.encodePacked(encrypted_shares, public_coefficients)),
            "dispute failed (encrypted shares and/or public coefficients not matching)"
        );
        require(
            verify_decryption_key(decryption_key, decryption_key_proof, verifier.pk, issuer.pk),
            "dispute failed (invalid decryption key or decryption key proof)"
        );

        // compute share index i:
        // the index i is one-based (which is required!) (indepent of the correction below)
        // as the issuer does not provide a share for itself the index has to be corrected
        uint256 i = verifier.id;
        if (i > issuer.id) {
            i--;
        }

        // decryption of the share, (correct for one-based index i to make it zero-based)
        uint256 share = encrypted_shares[i - 1] ^ uint256(keccak256(abi.encodePacked(decryption_key[0], verifier.id)));
        // require(false, "test assert here");
        
        // verify that share is actually invalid
        // evaluate the poly polynom F(x) for x = i
        uint256 x = i;
        uint256[2] memory Fx = [ issuer.pk[0], issuer.pk[1] ];
        uint256[2] memory tmp = bn128_multiply([public_coefficients[0], public_coefficients[1], x]);
        Fx = bn128_add([Fx[0], Fx[1], tmp[0], tmp[1]]);

        for (uint256 j = 2; j < public_coefficients.length; j += 2) { 
            x = mulmod(x, i, GROUP_ORDER);
            tmp = bn128_multiply([public_coefficients[j], public_coefficients[j + 1], x]);
            Fx = bn128_add([Fx[0], Fx[1], tmp[0], tmp[1]]);
        }
        // and compare the result (stored in Fx) with g1*si
        uint256[2] memory Fi = bn128_multiply([g1x, g1y, share]);   

        // require that share is actually invalid
        require(Fx[0] != Fi[0] || Fx[1] != Fi[1], "dispute failed (the provided share was valid)");

        __slash__(issuer_addr);
    }

    // compute the group key in the elliptic curve group G1
    // and verify the uploaded bls_group_pk from G2 with the pairing
    // only non-successfully-disputed keys form the group keys
    // calls abort if insufficient valid keys have been registered
    function upload_group_key(uint[4] _bls_group_pk) 
    public returns(bool success)
    {
        require(
            in_finalization_phase(),    
            "group key upload failed (key sharing / disputes not finsished, or group key already uploaded)"
        );

        uint256 n = registered_addresses.length;
        uint256 t = (n / 2) + 1;
        
        Node memory node;
        uint256[2] memory group_pk;
        
        // find first (i.e. lowest index) valid registered node
        uint256 i = 0;
        do {
            node = nodes[registered_addresses[i]];
            i += 1;
        } 
        while((node.id == 0 || node.key_distribution_hash == 0) && i < n);

        if (i == n) {
            // in this case at most one nodes actually shared a valid key
            __abort__();
            return false;
        }
        
        uint256 p = 1;  // number of nodes which provided valid keys
        group_pk = node.pk;
        for ( ; i < registered_addresses.length; i++) {  // sum up all valid pubic keys
            node = nodes[registered_addresses[i]];
            if (node.id != 0 && node.key_distribution_hash != 0) {
                p++;
                group_pk = bn128_add([group_pk[0], group_pk[1], node.pk[0], node.pk[1]]);
            }
        }

        if (p < t) {
            __abort__();
            return false;
        }

        // ensures that the given group_pk and bls_group_pk correspond to each other
        require(
            bn128_check_pairing(                                    
                [                       
                    group_pk[0], group_pk[1],
                    g2xx, g2xy, g2yx, g2yy,
                    g1x, g1y,
                    _bls_group_pk[0], _bls_group_pk[1], _bls_group_pk[2], _bls_group_pk[3]
                ]), 
            "upload of group key failed (the submitted bls_group_pk does not correspond to group_pk)"
        );

        bls_group_pk = _bls_group_pk;
        T_GROUP_KEY_UPLOAD = block.number;
    }

    function __slash__(address addr) 
    private 
    {
        emit DisputeSuccessful(addr);
        nodes[addr].id = 0;
    }

    // checks abort condition and aborts the contract if at least one abort condition is fulfilled
    function abort() 
    public 
    {
        // never abort during registration phase
        require(!in_registration_phase(), "abort failed (cannot abort during registration phase)");

        uint256 n = registered_addresses.length;
        uint256 t = (n / 2) + 1;

        // abort is possible if not enough nodes joined the DKG protocol
        if (n < PARTICIPATION_THRESHOLD) {
            __abort__();
        }

        // abort is possible if less then t nodes actually shared their keys without disputes
        else {
            require(
                T_SHARING_END < block.number, 
                "abort failed (abort is only possible after key sharing phase ended)"
            );
            uint256 p = 0;  // number of nodes with shared their key without disputes
            for (uint256 i = 0; i < n; i++) {
                Node memory node = nodes[registered_addresses[i]];

                // id != 0 ensures not was not slashed
                // hashkey_distribution_hash != 0 ensures that node has shared its key
                if ((node.id != 0) && node.key_distribution_hash != 0)  {
                    p++;
                }                
            }
            require(
                p < t,
                "abort failed (abort is only possible if less than t nodes shared their key successfully)"
            );
            __abort__();
        }
    }

    // aborts the contract and releases all the deposits to be withdrawn from the contract
    // slashed deposists are evenly distributed to all other nodes
    function __abort__() 
    private 
    {
        // TODO
        aborted = true;
    }


    // verifies that the sender account knows the private key corresponding to the given public key
    function verify_sk_knowledge(uint[2] public_key, uint[2] proof) 
    public returns (bool)
    {
        uint256[2] memory a = bn128_multiply([g1x, g1y, proof[1]]);
        uint256[2] memory b = bn128_multiply([public_key[0], public_key[1], proof[0]]);
        uint256[2] memory t = bn128_add([a[0], a[1], b[0], b[1]]);
        
        uint256 c = uint256(
            keccak256(abi.encodePacked(g1x, g1y, public_key[0], public_key[1], t[0], t[1], msg.sender)));

        return proof[0] == c;
    }


    // implement the verification procedure for the NIZK DLEQ (discrete logarithm equalty) proof
    function verify_decryption_key(
        uint256[2] decryption_key, 
        uint256[2] correctness_proof, // DLEQ challenge and response      
        uint256[2] verifier_pk,
        uint256[2] issuer_pk) 
    public returns (bool key_valid)
    {
        // equivalent to DLEQ_verify(G1, issuer_pk, verifier_pk, decryption_key, correctness_proof) in python

        uint256[2] memory tmp1;  // two temporary variables
        uint256[2] memory tmp2;

        tmp1 = bn128_multiply([g1x, g1y, correctness_proof[1]]);
        tmp2 = bn128_multiply([verifier_pk[0], verifier_pk[1], correctness_proof[0]]);
        uint256[2] memory a1 = bn128_add([tmp1[0], tmp1[1], tmp2[0], tmp2[1]]);
        
        tmp1 = bn128_multiply([issuer_pk[0], issuer_pk[1], correctness_proof[1]]);
        tmp2 = bn128_multiply([decryption_key[0], decryption_key[1], correctness_proof[0]]);
        uint256[2] memory a2 = bn128_add([tmp1[0], tmp1[1], tmp2[0], tmp2[1]]);

        uint256 challenge_computed = uint256(
            keccak256(abi.encodePacked(a1, a2, g1x, g1y, verifier_pk, issuer_pk, decryption_key)));

        key_valid = correctness_proof[0] == challenge_computed;
    }

    function verify_signature(uint256[4] bls_pk, bytes32 message, uint256[2] signature) 
    public returns (bool signature_valid)
    {
        uint[2] memory h = bn128_map_to_G1(message);
        signature_valid = bn128_check_pairing(                                   
            [                                                  
                signature[0], signature[1],                                  
                g2xx, g2xy, g2yx, g2yy,                        
                h[0], h[1],                                      
                bls_pk[0], bls_pk[1], bls_pk[2], bls_pk[3]
            ]);
    }
    
    function bn128_add(uint256[4] input) 
    public returns (uint256[2] result) {
        // computes P + Q 
        // input: 4 values of 256 bit each
        //  *) x-coordinate of point P
        //  *) y-coordinate of point P
        //  *) x-coordinate of point Q
        //  *) y-coordinate of point Q

        bool success;
        assembly {
            // 0x06     id of precompiled bn256Add contract
            // 0        number of ether to transfer
            // 128      size of call parameters, i.e. 128 bytes total
            // 64       size of call return value, i.e. 64 bytes / 512 bit for a BN256 curve point
            success := call(not(0), 0x06, 0, input, 128, result, 64)
        }
        require(success, "elliptic curve addition failed");
    }

    function bn128_multiply(uint256[3] input) 
    public returns (uint256[2] result) {
        // computes P*x 
        // input: 3 values of 256 bit each
        //  *) x-coordinate of point P
        //  *) y-coordinate of point P
        //  *) scalar x

        bool success;
        assembly {
            // 0x07     id of precompiled bn256ScalarMul contract
            // 0        number of ether to transfer
            // 96       size of call parameters, i.e. 96 bytes total (256 bit for x, 256 bit for y, 256 bit for scalar)
            // 64       size of call return value, i.e. 64 bytes / 512 bit for a BN256 curve point
            success := call(not(0), 0x07, 0, input, 96, result, 64)
        }
        require(success, "elliptic curve multiplication failed");
    }

    function bn128_is_on_curve(uint[2] point) 
    public returns(bool valid) {
        // checks if the given point is a valid point from the first elliptic curve group
        // by trying an addition with the generator point g1
        uint256[4] memory input = [point[0], point[1], g1x, g1y];
        assembly {
            // 0x06     id of precompiled bn256Add contract
            // 0        number of ether to transfer
            // 128      size of call parameters, i.e. 128 bytes total
            // 64       size of call return value, i.e. 64 bytes / 512 bit for a BN256 curve point
            valid := call(not(0), 0x06, 0, input, 128, input, 64)
        }
    }

    function bn128_check_pairing(uint256[12] input) 
    public returns (bool) {
        uint256[1] memory result;
        bool success;
        assembly {
            // 0x08     id of precompiled bn256Pairing contract     (checking the elliptic curve pairings)
            // 0        number of ether to transfer
            // 384       size of call parameters, i.e. 12*256 bits == 384 bytes
            // 32        size of result (one 32 byte boolean!)
            success := call(sub(gas, 2000), 0x08, 0, input, 384, result, 32)
        }
        require(success, "elliptic curve pairing failed");
        return result[0] == 1;
    }


    function bn128_map_to_G1(bytes32 data)
    public returns (uint[2] point) 
    {
        uint256 ctr = 0;
        while (true) {
            uint256 x = uint256(keccak256(abi.encodePacked(ctr, data)));
            bool b = x & 1 == 1;    // extract last bit of the hash
            x >>= 2;                // drop last 2 bits of the hash, a coordinate is a 254 bit number

            if (x < FIELD_MODULUS) { 
                // p...  FIELD_MODULUS
                // z = x**3 + 3 (mod p)
                uint256 z = (bigModExp([32, 32, 32, x, 3, FIELD_MODULUS]) + 3) % FIELD_MODULUS; 

                // y = sqrt(z) = z**((p + 1) / 4) mod p
                uint256 y = bigModExp([32, 32, 32, z, (FIELD_MODULUS + 1) >> 2, FIELD_MODULUS]);

                // checks if y is indeed a square root of z mod p
                if (bigModExp([32, 32, 32, y, 2, FIELD_MODULUS]) == z) {
                    if (b) {
                        y = (FIELD_MODULUS - y);
                    }
                    return [x, y]; 
                }
            }
            ctr++;
        }    
    }

    
    function bigModExp(uint256[6] input) 
    public returns (uint256) {
        // call the precompiled contract to compute the b^e mod m
        // used the following arguments in the given order
        //  - length of the base b
        //  - length of the exponent e
        //  - length of the modulus m
        //  - the base b itself
        //  - the exponent e itself
        //  - the modulus m itself
        // we use 256 bit integers for all of the above values

        bool success;
        uint256[1] memory result;
        assembly {
            // 0x05     id of precompiled bigModExp contract
            // 0        number of ether to transfer
            // 192      size of call parameters, i.e. 192 bytes total (6x 256 bit)
            // 32       size of call return value, i.e. 32 bytes / 256 bit
            success := call(not(0), 0x05, 0, input, 192, result, 32)
        }
        require(success, "bigModExp operation failed");
        return result[0];
    }

}