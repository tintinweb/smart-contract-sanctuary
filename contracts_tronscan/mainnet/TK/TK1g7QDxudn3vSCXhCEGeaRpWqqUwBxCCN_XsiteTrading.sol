//SourceUnit: xsitetrading.sol

pragma solidity 0.5.14;


contract Verifier {
    function recoverAddr(
        bytes32 msgHash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public pure returns (address) {
        return ecrecover(msgHash, v, r, s);
    }

    function isSigned(
        address _addr,
        bytes32 msgHash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public pure returns (bool) {
        return ecrecover(msgHash, v, r, s) == _addr;
    }
}
interface ITRC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract XsiteTrading is  Verifier {

    address public signatureAddress;

    ITRC20   token;

    event Transfer(address from, address to, uint256 amount);

    constructor(ITRC20 _token , address _sigAddress) public {
        signatureAddress = _sigAddress;
        token = _token;
    }

    // event Multisended(uint256 total, addr
    mapping(bytes32 => mapping(uint256 => bool)) public seenNonces;


    function userTRXWithdraw(
        uint256 amount,
        uint256 nonce,
        bytes32[] memory msgHash_r_s,
        uint8 v
    ) public {
        // Signature Verification
        require(
            isSigned(
                signatureAddress,
                msgHash_r_s[0],
                v,
                msgHash_r_s[1],
                msgHash_r_s[2]
            ),
            "Signature Failed"
        );
        // Duplication check
        require(seenNonces[msgHash_r_s[0]][nonce] == false);
        seenNonces[msgHash_r_s[0]][nonce] = true;
        // TRX Transfer
        msg.sender.transfer(amount);
        emit Transfer(address(this), msg.sender, amount);
    }
    
    
    function userTokenWithdraw(
        uint256 amount,
        uint256 nonce,
        bytes32[] memory msgHash_r_s,
        uint8 v
    ) public {
        // Signature Verification
        require(
            isSigned(
                signatureAddress,
                msgHash_r_s[0],
                v,
                msgHash_r_s[1],
                msgHash_r_s[2]
            ),
            "Signature Failed"
        );
        // Duplication check
        require(seenNonces[msgHash_r_s[0]][nonce] == false);
        seenNonces[msgHash_r_s[0]][nonce] = true;
        // Token Transfer
        token.transfer(msg.sender, amount);
        emit Transfer(address(this), msg.sender, amount);
    }
    
    
}