/**
 *Submitted for verification at BscScan.com on 2021-12-12
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
    address public feeWallet = 0xEd708471D98D8F005DA0c7F83CBB5d628E7ec27B;

    IERC20 public token;

    mapping(address => mapping(uint => bool)) public processedNonces;
    mapping (address => uint256) public accounts;
    
    mapping(address => uint) public nextNonce;

    uint256 public _basefees = 300000000000000000; //0.3 bnb
    uint256 public _withdrawfees = 10; //1%  /1000

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
        Step indexed step
    );
    event Withdraw(
        address from,
        uint256 amount
    );

    constructor (address _token) {
        admin = 0xEd708471D98D8F005DA0c7F83CBB5d628E7ec27B;
        token = IERC20(_token);
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

    function setWithdrawFees (uint256 _fees ) external {
        require(msg.sender == admin, "only admin");
        _withdrawfees = _fees;
    }

    function setFeeWallet (address _wallet ) external {
        require(msg.sender == admin, "only admin");
        feeWallet = _wallet;
    }


    function deposit(address from, uint256 amount, uint nonce, bytes calldata signature) external payable{
        require(msg.value >= _basefees, "insufficient fees");
        payable(admin).transfer(msg.value);
        
        require(processedNonces[msg.sender][nonce] == false, 'transfer already processed');
        processedNonces[msg.sender][nonce] = true;
        token.burn(msg.sender, amount);
        nextNonce[msg.sender] = nextNonce[msg.sender] + 1;

        emit Deposit(
            from,
            amount,
            block.timestamp,
            nonce,
            signature,
            Step.Burn
        );
    }

    function calculateWithdrawFee(uint256 _amount) private view returns (uint256) {
        return _amount*(_withdrawfees)/(10**3);

    }

    fallback () external payable {
    }

    receive () external payable {
    }

    function withdraw( ) external {
        // require(amount > 0 , "invalid amount: 0");
        require(accounts[msg.sender] > 0, "invalid amount");
        uint256 amount = accounts[msg.sender];
        uint256 _fees = calculateWithdrawFee(amount);

        bool succ = token.mint(msg.sender, amount - _fees);
        require(succ, "tokens not minted");

        bool succ2 = token.mint(feeWallet , _fees);
        require(succ2, "fees tokens not minted");

        accounts[msg.sender] = 0;

        emit Withdraw(msg.sender, accounts[msg.sender]);
    }

    function mint(
        address to, 
        uint256 amount, 
        uint nonce,
        bytes calldata signature
    ) external {
        require(msg.sender == admin, "only admin");
        bytes32 message = prefixed(keccak256(abi.encodePacked(to, amount, nonce )));
        require(recoverSigner(message, signature) == to , 'wrong signature');
        require(processedNonces[to][nonce] == false, 'transfer already processed');
        processedNonces[to][nonce] = true;
        nextNonce[to] = nextNonce[to] + 1;
        accounts[to] += amount;
        
        emit Mint(
            to,
            amount,
            block.timestamp,
            nonce,
            signature,
            Step.Mint
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