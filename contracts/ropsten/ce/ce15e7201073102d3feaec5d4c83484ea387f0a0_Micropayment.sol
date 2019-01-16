pragma solidity ^0.4.22;   
// ECE 398 SC - Smart Contracts and Blockchain Security 
// http://soc1024.ece.illinois.edu/teaching/ece398sc/spring2018/

// Simpest possible duplex-micropayment channel
// - Funded with an up front amount at initialization
// - The contract creator is called "alice". The other party, "bob", is passed
// as an argument to the Constructor
// - There is no fixed deadline, but instead any party can initiate a dispute,
// which lasts for a fixed time

// For a web-based signature tool you can use (via metamask), see:
//    https://jsfiddle.net/q3Lpgtop/40/

// To demonstrate the script in Remix JavascriptVM:
// 1. Create an instance of the Micropayment contract in javascriptVM
// --- Pass in your metamask address as "bob" 
// --- Your javascriptVM address will be "alice" 
// --- Include an initial funding amount, say 10 ether
// 2. Use the hashAmount(amountToBob, serno) view function to see a hash
//   for an updated state
// 3. Use the web-based signature tool above to sign this hash as "bob"
// --- Copy the entire signature
// 4. Call the "update" function, passing in an amountTotBob, serno, 
//   the empty array [], and the signature from "bob"
// example:
/* 
10, 2, [], ["0x37","0x80","0xef","0x58","0x72","0x42","0x92","0x2e","0x7f","0xe3",
"0x57","0x67","0x64","0xe7","0x14","0x30","0xbe","0x36","0xb4","0x27","0x08","0x04",
"0x66","0x4b","0x35","0xe3","0x65","0x16","0x8c","0xd2","0xe5","0x70","0x00","0x09",
"0x65","0x68","0xc5","0x85","0xff","0xa2","0x06","0xfc","0x42","0x2f","0xf4","0x87",
"0xd4","0x26","0xa3","0x46","0x65","0x40","0xf4","0x89","0x93","0xc8","0x80","0x61",
"0x20","0x63","0x90","0xc6","0x70","0xc6","0x1c"]
*/

// import "./ecverify.sol"; 
// this imports ECVerify with the following:
//   function ecverify(bytes32 hash, bytes sig, address signer) public pure returns (bool);


contract ECVerify {
    function ecrecovery(bytes32 hash, bytes sig) public pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        if (sig.length != 65) {
            return 0;
        }

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := and(mload(add(sig, 65)), 255)
        }

        // https://github.com/ethereum/go-ethereum/issues/2053
        if (v < 27) v += 27;
        if (v != 27 && v != 28) return 0;
        return ecrecover(hash, v, r, s);
    }

    function ecverify(bytes32 hash, bytes sig, address signer) public pure returns (bool) {
        return signer == ecrecovery(hash, sig);
    }
}

contract Micropayment is ECVerify {                                                                                                                                                  
    address public alice;                                                                                                                                                                     
    address public bob; 
    event InitialFunding(address alice, address bob, uint amount);

    // Deadline is controlled by "dispute"
    uint public deadline = uint(0)-uint(1); // set to UINT_MAX initially
    event Close(uint deadline);
    event Finalize(uint amountToBob);
    
    // Most recent accepted state
    event Update(uint amountToBob, uint serno);
    uint public serno;
    uint public amountToBob;
    
    // Initial funding amount
    function Micropayment(address _bob) public payable {
        // Constructor: initialize variables                                             
        alice = msg.sender;                                                      
        bob = _bob;
        emit InitialFunding(alice, bob, address(this).balance);
    }
    
    // Any party can submit a state with a higher serial number. 
    // This updates the current balance
    function update(uint _amountToBob, uint _serno, bytes sigA, bytes sigB) public {
        require(_serno > serno, "new serial number must be greater");
        bytes32 hash = keccak256(address(this), _amountToBob, _serno);
        if (msg.sender != alice) 
            require( ecverify(hash, sigA, alice), "sigA failed" );
        if (msg.sender != bob)
            require( ecverify(hash, sigB, bob  ), "sigB failed" );
        serno = _serno;
        amountToBob = _amountToBob;
        emit Update(amountToBob, serno);
    }
    
    function close() public {
        require(msg.sender == alice || msg.sender == bob);
        uint _deadline = block.number + 2; // set the deadline
        if (_deadline < deadline) {
            deadline = _deadline;
            emit Close(deadline);
        }
    }

    function finalize() public {
        // Can be called by anyone after deadline
        require(block.number >= deadline);
        bob.transfer(amountToBob);   // Security hazard! Why?
        alice.transfer(address(this).balance); 
        emit Finalize(amountToBob);
    }
    // Helper functions
    function hashAmount(uint _amountToBob, uint _serno) public view returns(bytes32) {
        return keccak256(address(this), _amountToBob, _serno);
    }
    function mine() public { }
    function blockno() public view returns(uint) { return block.number; } 
}