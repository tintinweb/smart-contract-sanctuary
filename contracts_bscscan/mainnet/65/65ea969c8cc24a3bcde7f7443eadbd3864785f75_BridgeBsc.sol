/**
 *Submitted for verification at BscScan.com on 2021-12-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function mint(address to, uint256 value) external returns (bool);
    function burn(address from, uint256 value) external returns (bool);
}

contract BridgeBsc {
    address public admin;
    IERC20 public token;

    struct Balance {
        uint256 tokens;
        uint256 gas;
    }

    mapping(address => mapping(uint => bool)) public processedNonces;
    mapping (address => Balance) public accounts;
    
    mapping(address => uint) public nextNonce;

    uint256 public _basefees = 100000000000000000;
    enum Step { Burn, Mint }
    event Deposit(
        address from,
        uint256 amount,
        uint date,
        uint nonce,
        bytes signature,
        Step indexed step
    );
    event Mint(
        address to,
        uint256 amount,
        uint date,
        uint nonce,
        bytes signature,
        Step indexed step,
        uint256 gas
    );
    event Withdraw(
        address from,
        uint256 amount
    );

    constructor () {
        admin = 0xEd708471D98D8F005DA0c7F83CBB5d628E7ec27B;
        token = IERC20(0xDa53590eA0E1d0B5D3648a6Eb6726ff0AF692b84);
    }

    function setToken (address _token ) external {
        require(msg.sender == admin, "only admin");
        token = IERC20(_token);
    }

    function setAdmin (address _admin ) external {
        require(msg.sender == admin, "only admin");
        admin = _admin;
    }

    function setFees (uint256 _fees ) external {
        require(msg.sender == admin, "only admin");
        _basefees = _fees;
    }


    function deposit(address from, uint256 amount, uint nonce, bytes calldata signature) external {
        require(processedNonces[msg.sender][nonce] == false, 'transfer already processed');
        processedNonces[msg.sender][nonce] = true;
        token.burn(msg.sender, amount);
        nextNonce[msg.sender] = nextNonce[msg.sender] + 2;

        emit Deposit(
            from,
            amount,
            block.timestamp,
            nonce,
            signature,
            Step.Burn
        );
    }

    function calculateBurnFee(uint256 _amount) private pure returns (uint256) {
        return _amount*(5)/(10**3);

    }

    fallback () external payable {
    }

    receive () external payable {
    }

    function withdraw( ) external payable {
        // require(amount > 0 , "invalid amount: 0");
        require(accounts[msg.sender].tokens > 0, "invalid amount");
        require(msg.value >= accounts[msg.sender].gas, "insufficient fees");
        payable(admin).transfer(msg.value);
        
        bool succ = token.mint(msg.sender, accounts[msg.sender].tokens);
        require(succ, "tokens not minted");

        accounts[msg.sender].tokens = 0;
        accounts[msg.sender].gas = 0;

        emit Withdraw(msg.sender, accounts[msg.sender].tokens);
    }

    function mint(
        address to, 
        uint256 amount, 
        uint nonce,
        bytes calldata signature
    ) external {
        uint256 startGas = gasleft();
        require(msg.sender == admin, "only admin");
        bytes32 message = prefixed(keccak256(abi.encodePacked(to, amount, nonce )));
        require(recoverSigner(message, signature) == to , 'wrong signature');
        require(processedNonces[to][nonce] == false, 'transfer already processed');
        processedNonces[to][nonce] = true;
        nextNonce[msg.sender] = nextNonce[msg.sender] + 2;
        uint256 _burn = calculateBurnFee(amount);
        amount = amount - _burn;
        accounts[to].tokens += amount;
        
        uint256 gasUsed = (startGas - gasleft()) * tx.gasprice*2;
        gasUsed = gasUsed > _basefees ? gasUsed : _basefees;
        accounts[to].gas += gasUsed;
        emit Mint(
            to,
            amount,
            block.timestamp,
            nonce,
            signature,
            Step.Mint,
            gasUsed
        );
    }

    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(
        '\x19Ethereum Signed Message:\n32', 
        hash
        ));
    }

    function recoverSigner(bytes32 message, bytes memory sig)
        internal
        pure
        returns (address)
    {
        uint8 v;
        bytes32 r;
        bytes32 s;
    
        (v, r, s) = splitSignature(sig);
    
        return ecrecover(message, v, r, s);
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (uint8, bytes32, bytes32)
    {
        require(sig.length == 65);
    
        bytes32 r;
        bytes32 s;
        uint8 v;
    
        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }
    
        return (v, r, s);
    }
}