pragma solidity ^0.7.0;

// SPDX-License-Identifier: MIT

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "add overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "sub underflow");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "mul overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "div by zero");
        uint256 c = a / b;
        return c;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

contract DegensToken {
    using SafeMath for uint256;

    string public constant name = "Degens Token";
    string public constant symbol = "DEGENS";
    uint8 public constant decimals = 18;
    uint256 immutable public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) public nonces;

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");
    bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    constructor(uint256 amountToDistribute) {
        totalSupply = amountToDistribute;
        balanceOf[msg.sender] = amountToDistribute;
        emit Transfer(address(0), msg.sender, amountToDistribute);
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        return transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address from, address recipient, uint256 amount) public returns (bool) {
        require(balanceOf[from] >= amount, "insufficient balance");
        if (from != msg.sender && allowance[from][msg.sender] != uint256(-1)) {
            require(allowance[from][msg.sender] >= amount, "insufficient allowance");
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(amount);
        }
        balanceOf[from] = balanceOf[from].sub(amount);
        balanceOf[recipient] = balanceOf[recipient].add(amount);
        emit Transfer(from, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));

        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "permit: invalid signature");
        require(signatory == owner, "permit: unauthorized");
        require(block.timestamp <= deadline, "permit: signature expired");

        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function getChainId() private pure returns (uint chainId) {
        assembly { chainId := chainid() }
    }
}

contract DegensTokenDistributor {
    using SafeMath for uint256;

    bytes32 immutable public merkleRoot;
    uint256 public unclaimed;
    mapping(uint256 => uint256) public claimed; // index -> tokens claimed

    DegensToken immutable public token;
    uint64 immutable public timeDeployed;

    constructor(bytes32 merkleRoot_, uint256 unclaimed_) {
        merkleRoot = merkleRoot_;
        unclaimed = unclaimed_;

        token = new DegensToken(unclaimed_);
        timeDeployed = uint64(block.timestamp);
    }

    function amountClaimable(uint256 index, uint256 allocation, uint256 vestingYears) public view returns (uint256) {
        uint256 yearsElapsed = block.timestamp.sub(timeDeployed).mul(1e18).div(86400 * 365);

        uint256 fractionVested = vestingYears == 0 ? 1e18 : yearsElapsed.div(vestingYears).min(1e18);

        uint256 amountVested = allocation.mul(fractionVested).div(1e18).min(allocation);

        return amountVested.sub(claimed[index]);
    }

    function claim(uint256 index, address claimer, uint256 allocation, uint256 vestingYears, bytes32[] memory witnesses, uint256 path) public {
        // Validate proof

        bytes32 node = keccak256(abi.encodePacked(index, claimer, allocation, vestingYears));

        for (uint256 i = 0; i < witnesses.length; i++) {
            if ((path & 1) == 0) {
                node = keccak256(abi.encodePacked(node, witnesses[i]));
            } else {
                node = keccak256(abi.encodePacked(witnesses[i], node));
            }

            path >>= 1;
        }

        require(node == merkleRoot, "incorrect proof");

        // Compute amount claimable

        uint256 toClaim = amountClaimable(index, allocation, vestingYears);
        require(toClaim > 0, "nothing claimable");

        // Update distributor records

        claimed[index] = claimed[index].add(toClaim);
        unclaimed = unclaimed.sub(toClaim);

        // Transfer tokens

        token.transfer(claimer, toClaim);
    }
}