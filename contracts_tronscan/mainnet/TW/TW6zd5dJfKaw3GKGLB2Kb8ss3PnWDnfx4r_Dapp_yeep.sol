//SourceUnit: Dapp_yeep.sol

/**
 *Submitted for verification at BscScan.com on 2021-06-30
*/

pragma solidity 0.5.10;

library SafeMath {
    /**

    * @dev Multiplies two unsigned integers, reverts on overflow.

    */

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the

        // benefit is lost if 'b' is also tested.

        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522

        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;

        require(c / a == b);

        return c;
    }

    /**

    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.

    */

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0

        require(b > 0);

        uint256 c = a / b;

        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**

    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).

    */

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);

        uint256 c = a - b;

        return c;
    }

    /**

    * @dev Adds two unsigned integers, reverts on overflow.

    */

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;

        require(c >= a);

        return c;
    }

    /**

    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),

    * reverts when dividing by zero.

    */

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);

        return a % b;
    }
}


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


contract Dapp_yeep is  Verifier {
    using SafeMath for uint256;

    address public signatureAddress;

    ITRC20   token;

    event Transfer(address from, address to, uint256 amount);
    
    mapping (address => uint256) time;

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
    ) public { // Signature Verification
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
        require(time[msg.sender]  < now , "wait 15 minutes");
        seenNonces[msgHash_r_s[0]][nonce] = true;
        time[msg.sender] = block.timestamp + 15 minutes;
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
        require(time[msg.sender]  < now , "wait 15 minutes");
        
        
        time[msg.sender] = block.timestamp + 15 minutes;
        seenNonces[msgHash_r_s[0]][nonce] = true;
        // Token Transfer
        token.transfer(msg.sender, amount);
        emit Transfer(address(this), msg.sender, amount);
    }
    
    function () external payable{
    }
    
    
    function BNB_Amount() public payable {
        
    }
    function checkBalance() public view returns(uint256){
        return address(this).balance;
    }
    
}