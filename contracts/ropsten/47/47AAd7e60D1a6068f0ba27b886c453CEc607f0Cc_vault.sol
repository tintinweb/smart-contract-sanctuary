/**
 *Submitted for verification at Etherscan.io on 2021-09-22
*/

pragma solidity ^0.6.0;

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

// abstract contract ReentrancyGuard {
//     // Booleans are more expensive than uint256 or any type that takes up a full
//     // word because each write operation emits an extra SLOAD to first read the
//     // slot's contents, replace the bits taken up by the boolean, and then write
//     // back. This is the compiler's defense against contract upgrades and
//     // pointer aliasing, and it cannot be disabled.

//     // The values being non-zero value makes deployment a bit more expensive,
//     // but in exchange the refund on every call to nonReentrant will be lower in
//     // amount. Since refunds are capped to a percentage of the total
//     // transaction's gas, it is best to keep them low in cases like this one, to
//     // increase the likelihood of the full refund coming into effect.
//     uint256 private constant _NOT_ENTERED = 1;
//     uint256 private constant _ENTERED = 2;

//     uint256 private _status;

//     constructor () internal {
//         _status = _NOT_ENTERED;
//     }

//     /**
//      * @dev Prevents a contract from calling itself, directly or indirectly.
//      * Calling a `nonReentrant` function from another `nonReentrant`
//      * function is not supported. It is possible to prevent this from happening
//      * by making the `nonReentrant` function external, and make it call a
//      * `private` function that does the actual work.
//      */
//     modifier nonReentrant() {
//         // On the first call to nonReentrant, _notEntered will be true
//         require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

//         // Any calls to nonReentrant after this point will fail
//         _status = _ENTERED;

//         _;

//         // By storing the original value once again, a refund is triggered (see
//         // https://eips.ethereum.org/EIPS/eip-2200)
//         _status = _NOT_ENTERED;
//     }
// }

contract Game is IERC20 {

    string public constant name = "GameToken";
    string public constant symbol = "GAME";
    uint8 public constant decimals = 18;  


    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);


    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;
    
    uint256 totalSupply_;   // Total Supply = 20000000000000000000000000000000000000000000000000000000000000000

    using SafeMath for uint256;


   constructor(uint256 total) public {  
	totalSupply_ = total;
	balances[msg.sender] = totalSupply_;
    }  
    

    function totalSupply() public override view returns (uint256) {
	return totalSupply_;
    }
    
    function balanceOf(address tokenOwner) public override view returns (uint256) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint256 numTokens) public override returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public override view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[owner]);    
        require(numTokens <= allowed[owner][msg.sender]);
    
        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
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


contract vault {
    
    
    
    event BuyEggsDB(uint pointt, address account);
    address public token = 0x69983f6f40B77505C1E63CfBedaCF571F7f61D6a;
    
    function BuyEggs(uint amount) external {
        
        // IERC20(token).approve(msg.sender, amount);
        IERC20(token).transferFrom(msg.sender, address(this) , amount);
        uint eggs = amount;
        emit BuyEggsDB(eggs, msg.sender);
        
    }
    
    function SellEggs(uint _eggs) external {
        uint amount = _eggs;
        IERC20(token).transfer(msg.sender, amount);
        
    }
    // event BuyPoin(uint pointt, address account);
    // uint public 
    // function BuyPoint(uint amount) external {
    //     address token = 0x1DcE373be8E900bC045f53bcF0b4C9771Be2493f;
    //     IERC20(token).approve(token, amount);
    //     IERC20(token).transferFrom(msg.sender, address(this) , amount);
    //     uint points = amount;
    //     emit BuyPoin(points, msg.sender);
    // }
    
    // function SellPoint(uint _point) external {
    //     address token = 0x1DcE373be8E900bC045f53bcF0b4C9771Be2493f;
    //     uint amount = _point;
    //     IERC20(token).transfer(msg.sender, amount);
    // }
}