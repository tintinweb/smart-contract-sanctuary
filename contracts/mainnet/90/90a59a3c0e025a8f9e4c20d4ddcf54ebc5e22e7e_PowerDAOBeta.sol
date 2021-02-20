/**
 *Submitted for verification at Etherscan.io on 2021-02-19
*/

pragma solidity ^0.4.25;

// UniPower.Network - PowerDAO beta

contract PowerDAOBeta {
    
    ERC20 constant power = ERC20(0xF2f9A7e93f845b3ce154EfbeB64fB9346FCCE509);
    ERC20 constant liquidity = ERC20(0x49F9316EB22de90d9343C573fbD7Cc0B5ec6e19f);
    PowerLock constant powerLock = PowerLock(0xAE7B530Be880457523Eb46d8ec6484e067c018B4);
    StaticPower constant staticPower = StaticPower(0xBaB61589f963534460E2764A1C0d840B745A9140);
    
    address blobby = msg.sender; // For beta (updating proposal cost)
    uint256 proposalDeposit = 50 * (10 ** 18); // 50 POWER
    uint256 proposalExpiration = 7 days;
    //uint256 removalCap = 5; // No cap for beta
    uint256 removalCooldown = 24 hours;
    uint256 nextRemoval;
    
    Proposal[] public proposals;
    
    struct Proposal {
        address creator;
        uint200 liquidityRemoved;
        uint40 expiration;
        bool executed;
        address recipient;
        string title;
        string message;
    }
    
    function startProposal(uint200 liquidityRemoved, address recipient, string title, string message) external {
        //uint256 maxRemoval = (removalCap * liquidity.balanceOf(this)) / 100; TODO No cap for beta
        //require(liquidityRemoved <= maxRemoval);
        power.transferFrom(msg.sender, this, proposalDeposit);
        proposals.push(Proposal(msg.sender, liquidityRemoved, uint40(now + proposalExpiration), false, recipient, title, message));
    }
    
    function updateProposalDeposit(uint256 newCost) external {
        require(msg.sender == blobby);
        require(newCost <= 500 * (10 ** 18)); // upto 500 POWER
        proposalDeposit = newCost;
    }
    
    function updateProposalExpiration(uint256 newTime) external {
        require(msg.sender == blobby);
        require(newTime > 3 days && newTime < 31 days);
        proposalExpiration = newTime;
    }
    
    /*function updateProposalCap(uint256 newCap) external {
        require(msg.sender == blobby);
        require(newCap <= 10);
        removalCap = newCap;
    }*/
    
    function updateRemovalFrequency(uint256 newLimit) external {
        require(msg.sender == blobby);
        require(newLimit > 12 hours && newLimit < 7 days);
        removalCooldown = newLimit;
    }
    
    function removeExpiredDeposits(address recipient, uint256 amount) external {
        require(msg.sender == blobby);
        power.transfer(recipient, amount);
    }
    
    function executeProposal(uint256 proposalId, bytes signatures) external {
        Proposal memory proposal = proposals[proposalId];
        require(proposal.creator != 0);
        require(!proposal.executed);
        
        // Check signatures add up to required 50%
        uint256 tally;
        bytes32 hashedTx = recoverPreSignedHash(proposalId);
        address previousAddress;
        for (uint256 i = 0; (i * 65) < signatures.length; i++) {
            address user = recover(hashedTx, slice(signatures, i * 65, 65));
            require(user > previousAddress);
            previousAddress = user;
            if (user != 0) {
                tally += powerLock.playersStakePower(user);
                tally += staticPower.balanceOf(user);
            }
        }
        
        if (proposalId > 0) { // 0 is test proposal
            require(tally >= ((powerLock.totalStakePower() + staticPower.totalSupply()) * 50) / 100); // 50% in PowerLock & StaticPower
        }
        
        if (proposal.liquidityRemoved > 0) {
            require(nextRemoval < now);
            liquidity.transfer(proposal.recipient, proposal.liquidityRemoved);
            nextRemoval = now + removalCooldown;
        }
        
        proposal.executed = true;
        proposal.expiration = uint40(now);
        proposals[proposalId] = proposal;
        power.transfer(proposal.creator, proposalDeposit);
    }
    
    function numProposals() view external returns(uint256) {
        return proposals.length;
    }
    
    function recoverPreSignedHash(uint256 proposalId) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("powerdao", proposalId));
    }
    
    function signaturesAddress(bytes signature, uint256 proposalId) external pure returns (address) {
        bytes32 hashedTx = recoverPreSignedHash(proposalId);
        return recover(hashedTx, signature);
    }

    function recover(bytes32 hash, bytes sig) public pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;
        
        // Check the signature length
        if (sig.length != 65) {
            return address(0);
        }
        
        // Divide the signature in r, s and v variables
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
        
        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }
        
        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            bytes memory prefix = "\x19Ethereum Signed Message:\n32";
            bytes32 prefixedHash = keccak256(prefix, hash);
            return ecrecover(prefixedHash, v, r, s);
        }
    }
    
    function getTally(bytes signatures, uint256 proposalId) external view returns (uint256, uint256) {
        uint256 tally;
        bytes32 hashedTx = recoverPreSignedHash(proposalId);
        address previousAddress;
        
        for (uint256 i = 0; (i * 65) < signatures.length; i++) {
            address user = recover(hashedTx, slice(signatures, i * 65, 65));
            require(user > previousAddress);
            previousAddress = user;
            if (user != 0) {
                tally += powerLock.playersStakePower(user);
                tally += staticPower.balanceOf(user);
            }
        }
        
        uint256 required = ((powerLock.totalStakePower() + staticPower.totalSupply()) * 50) / 100;
        return (tally, required);
    }
    
    function slice(bytes memory _bytes, uint256 _start, uint256 _length) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, "slice_overflow");
        require(_start + _length >= _start, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }
    
}


contract PowerLock {
    uint256 public totalStakePower;
    mapping(address => uint256) public playersStakePower;
    function distributeDivs(uint256 amount) external;
}

contract StaticPower {
    function distribute(uint256 _amount) public returns(uint256);
    function balanceOf(address _customerAddress) public view returns(uint256);
    function totalSupply() public view returns(uint256);
}

contract Uniswap {
    function removeLiquidityETH(address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline) public;
    function swapExactETHForTokens(uint amountOutMin, address[] path, address to, uint deadline) external payable returns (uint[] memory amounts);
}

contract ERC20 {
    function totalSupply() external constant returns (uint);
    function balanceOf(address tokenOwner) external constant returns (uint balance);
    function allowance(address tokenOwner, address spender) external constant returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function approveAndCall(address spender, uint tokens, bytes data) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}