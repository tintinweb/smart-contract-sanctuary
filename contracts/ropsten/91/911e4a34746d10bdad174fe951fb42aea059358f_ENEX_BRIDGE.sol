/**
 *Submitted for verification at Etherscan.io on 2021-12-07
*/

pragma solidity ^0.8.0;

//import  "./15_ECDSA_interface.sol";


interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Ownable {

    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        owner = msg.sender;
    }

    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public isOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract ECDSA {
    
    uint nextValidatorId = 1;
    uint public validatorsCount = 0;
    mapping(address => uint) public validators;

    function verify(bytes32 hash, uint8[] memory v, bytes32[] memory r, bytes32[] memory s) public view returns (bool) {
        uint confirmations = 0;
        //sig array 
        //1 - owner
        //2 - r
        //3 - s
        //4 - v
        for (uint i=0; i<v.length; i++){
           // bytes32 
            if(validators[ecrecover(hash, v[i], r[i], s[i])] != 0){
                confirmations++;
            }
        }
        if(confirmations >= (validatorsCount/2))
            return true;
        else
            return false;
    }
}


contract ENEX_BRIDGE is Ownable, ECDSA{
    
   // ECDSA interface_ECDSA;

    mapping(address => mapping (address => uint256)) public balances;

    //mapping(address => mapping (address => uint256)) public c_balances;

    mapping(address => mapping (address => uint256))  allowed;
    
    mapping(bytes32 => bool) public invoices;
    
    using SafeMath for uint256;

  //  constructor() {
 //       interface_ECDSA = new ECDSA();
 //   }


    function addValidator(address validator) public isOwner {
        require(
             validators[validator] == 0, 
            "Owner exist"
        );
        validatorsCount++;
        validators[validator] = nextValidatorId;
        nextValidatorId++;
    }
    
    function removeValidator(address validator) public isOwner {
        require(
             validators[validator] != 0, 
            "dosnt exist owner"
        );
        validatorsCount--;
        delete validators[validator];
    }
    //
    //Deposit to contract
    //
    function lock(address token, uint256 amount, string memory enq_address) public {
        require(
            amount <= IERC20(token).balanceOf(msg.sender), 
            "Token balance is too low"
        );
        require(
            IERC20(token).allowance(msg.sender, address(this)) >= amount,
            "Token allowance too low"
        );
        require(
            bytes(enq_address).length == 66,
            "Invalid ENQ address format"
        );
        balances[msg.sender][token] = balances[msg.sender][token].add(amount);
        bool sent = IERC20(token).transferFrom(msg.sender, address(this), amount);
        require(sent, "Token transfer failed");
    }
    
    //
    //BRIDGE ENQ->ETH
    //Unlock from contract
    //
    function unlock(address token, address recipient, uint amount, uint8[] memory v, bytes32[] memory r, bytes32[] memory s) public {
        
        bytes32 invoice = ethInvoceHash(token, recipient, amount);
        bytes32 data_hash = ethMessageHash(invoice);
        bool exits = invoices[data_hash];
        require(!exits, "Invoice has already been used.");
        
        bool valid_sign = verify(data_hash, v, r, s);
        require(valid_sign, "Invalid signature. Unlock failed");

        bool sent = IERC20(token).transfer(recipient, amount);
        require(sent, "Token transfer failed");
        invoices[data_hash] = true;
    }


    /**
    * @dev prefix a bytes32 value with "\x19Ethereum Signed Message:" and hash the result
    */
    function ethMessageHash(bytes32 message) private pure returns (bytes32) {
        return keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32"  , message)
        );
    }
 
    function ethInvoceHash(address token, address recipient, uint amount) public pure returns (bytes32)  {
        return keccak256(abi.encodePacked(token, recipient,  amount));
    }
}

library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }
}