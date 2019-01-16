pragma solidity ^0.4.24;

// //import "./MyToken.sol";
//import "../node_modules/openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
// import "../node_modules/openzeppelin-solidity/contracts/lifecycle/Pausable.sol";
// import "../node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol";
 


// // import "../node_modules/openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol";
// // import "../node_modules/openzeppelin-solidity/contracts/token/ERC20/ERC20Pausable.sol";
// // import "../node_modules/openzeppelin-solidity/contracts/token/ERC20/ERC20Capped.sol";




// // contract MyToken is ERC20Capped, ERC20Pausable, ERC20Detailed {

// //     constructor(string _name, string _symbol, uint8 _decimals, uint256 _cap) 
// //         ERC20Detailed(_name, _symbol, _decimals)
// //         ERC20Capped(_cap)
// //         public {

// //     }
    
    
// // }


// contract SWAPTOKEN  is  Ownable, Pausable{
    
//     struct Transfer {  
//         address contract_;  
//         address to_;  
//         uint amount_;  
//         bool failed_;  
// }

//     ERC20 public ERC20Interface;

//     address public owner;  
//     mapping(bytes32 => address) public tokens;  
//     mapping(address => uint[]) public transactionIndexesToSender;
//     event TransferSuccessful(address indexed from_, address indexed to_, uint256 amount_);
//     event TransferFailed(address indexed from_, address indexed to_, uint256 amount_);
//     Transfer[] public transactions;



//         constructor() public {  
//         owner = msg.sender;  
//         }  


//     // constructor(){

//     //     //address contract_ = "0x58a65c1f674b3c42fbf4cf5bb92715b54a7bd554";
//     //     //Token = [_Contract_Addr];

//     // }
    
//     function addNewToken(bytes32 symbol_, address address_) public onlyOwner returns (bool) {  
//   tokens[symbol_] = address_;  
  
//   return true;  
//  }  


//     function transferTokens(bytes32 symbol_, address to_, uint256 amount_){
//         require(tokens[symbol_] != 0x0);
//         require(amount_ > 0);

//         address contract_ = tokens[symbol_];
//         address from_ = msg.sender;
//         ERC20Interface = ERC20(contract_);
        
           

//             uint256 transactionId = transactions.push(
//             Transfer({
//             contract_:  contract_,
//             to_: to_,
//             amount_: amount_,
//             failed_: true
//             })
//         );
//         transactionIndexesToSender[from_].push(transactionId - 1);

//         if(amount_ > ERC20Interface.allowance(from_, address(this))) {
//             emit TransferFailed(from_, to_, amount_);
//             revert();
//         }

//         ERC20Interface.transferFrom(from_, to_, amount_);

//         transactions[transactionId - 1].failed_ = false;

//          emit TransferSuccessful(from_, to_, amount_);

//     }
        
// }

contract ERC20 {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract SWAPTOKEN {
    //ERC20 public ERC20Interface;
    address tracker_0x_address = 0x58a65c1f674b3c42fbf4cf5bb92715b54a7bd554; // ContractA Address
    mapping ( address => uint256 ) public balances;

    function deposit( address to ,uint tokens) public {

    // add the deposited tokens into existing balance 
        balances[msg.sender]+= tokens;

    // transfer the tokens from the sender to this contract
        ERC20(tracker_0x_address).transferFrom(msg.sender, address(this), tokens);
    }

    // function returnTokens() public {
    //     balances[msg.sender] = 0;
    //     ERC20Interface(tracker_0x_address).transfer(msg.sender, balances[msg.sender]);
    // }


}