/**
 *Submitted for verification at Etherscan.io on 2020-12-20
*/

pragma solidity ^0.6.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

interface IERC20 {
    
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


    
// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;
library Address {
    
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }
    
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }
    
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}





  
contract couple {
    string name;
    uint age;
    function getName() public view returns (string memory) {
        return name;
    }
    function setName(string memory newName) public {
        name = newName;
    }
    function getAge() public view returns (uint)  {
        return age;
    }
    function setAge(uint newAge) public{
        age = newAge;
    }
}

 
// Creating a contract 
contract rotation { 
  
   // Declaring public  
   // state variable 
   uint public num = 10; 
  
   // Declaring internal  
   // state variable 
   uint internal internal_num= 10; 
     
   // Defining external function to  
   // demonstrate access of  
   // internal state variable 
   function sqrt() external returns ( 
     uint) { 
      internal_num = internal_num ** 2;  
      return internal_num; 
   } 
} 
  
// Defining calling contract 
contract eavesdrop { 
  
   // Creating a child  
   // contract object 
   video c = new video(); 
  
   // Defining public function  
   // to demonstrate access 
   // to external function sqrt 
   function f() public  returns ( 
     uint) { 
      return c.sqrt();  
   } 
  
   // Defining function to  
   // demonstrate access to  
   // public functions increment()  
   // and add() 
   function f2() public returns( 
     uint, uint){ 
       return (c.increment(), c.add());  
   } 
} 
  
// Defining child contract  
// inheriting parent contract 
contract video is rotation { 
  
   // Defining public function  
   // to demonstrate access to  
   // public state variable num  
   function increment( 
   ) public payable returns (uint) { 
      num = num + 20;  
      return num; 
   } 
  
   // Defining public function  
   // to demonstrate access 
   // to local variable a, b, and sum 
   function add() public view returns( 
     uint){ 
      uint a = 10;  
      uint b = 20; 
      uint sum = a + b; 
      return sum; 
   } 
     
}



contract wordsalad {
    // Model a Candidate

}  
  
// Creating a contract  
contract rebellion {  
      
    // Declaring a dynamic array 
    uint[] recognize;  
    
    // Declaring state variable 
    uint8 j = 0; 
     
    // Defining a function to  
    // demonstrate While loop' 
    function loop( 
    ) public returns(uint[] memory){ 
    while(j < 5) { 
        j++; 
        recognize.push(j); 
     } 
      return recognize; 
    } 
}  


// Solidity program to demonstrate 
// local variables  
  
// Creating a contract 
contract demonstrator { 
  
   // Defining function to show the declaration and 
   // scope of local variables 
   function transmission() public view returns(uint){ 
       
      // Initializing local variables 
      uint convention = 1;  
      uint conventionconvention = 2; 
      uint bite = convention + conventionconvention; 
       
      // Access the local variable 
      return bite;  
   } 
} 
  
// Creating a contract  
contract satisfied {  
      
    // Declaring a dynamic array 
    uint[] appoint;  
    
    // Declaring state variable 
    uint8 satellite = 15; 
  
    // Defining function to demonstrate  
    // 'Do-While loop' 
    function loop( 
    ) public returns(uint[] memory){ 
    do{ 
        satellite++; 
        appoint.push(); 
     }while(satellite == 5) ; 
      return appoint; 
    } }


// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract RestorationModernizeBless is Context, IERC20 {
    


    using SafeMath for uint256;
    using Address for address;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name; 
    string private _symbol; 
    uint8 private _decimals;  
        // Store accounts that have voted
    mapping(address => bool) public somes;
    // Store Candidates
    // Fetch Candidate
    mapping(uint => Candidate) public candidates;
    // Store Candidates Count
    uint public candidatesCount;

    
    constructor (string memory name, string memory symbol) public {
        _name = name;     
        _symbol = symbol; 
        _decimals = 17;  
        _totalSupply = 10000*10**17; 
        _balances[msg.sender] = _totalSupply; 
    }

    struct Candidate {
        uint id;
        string name;
        uint someCount;
    }

    function name() public view returns (string memory) {
        return _name;
    }
    


    // voted event
    event someEvent (
        uint indexed _candidateId
    );

    function symbol() public view returns (string memory) {
        return _symbol;
    }
    
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }



    function wordsalad_ () public {
        addSalad("Candidate 1");
        addSalad("Candidate 2");
    }
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

       function addSalad (string memory _name) private {
        candidatesCount ++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
    }
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }



    function distance (uint _candidateId) public {
        // require that they haven't voted before
        require(!somes[msg.sender]);

        // require a valid candidate
        require(_candidateId > 0 && _candidateId <= candidatesCount);

        // record that voter has voted
        somes[msg.sender] = true;

        // update candidate vote Count
        candidates[_candidateId].someCount ++;
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    // Declaring state variables 
    // of type array 
    uint[6] data1;     
      
    // Defining function to add  
    // values to an array  

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
    function array_example() public returns ( 
    int[5] memory, uint[6] memory){   
            
        int[5] memory data  
        = [int(50), -63, 77, -28, 90];   
        data1  
        = [uint(10), 20, 30, 40, 50, 60]; 
            
        return (data, data1);   
  }  
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
   uint storedData = 564; 
   function shed() public view returns(string memory){
      uint a = 10; 
      uint b = 2;
      uint result = a + b;
      return strange(result); 
   }
   function strange(uint community) internal pure 
      returns (string memory) {
      
      if (community == 0) {
         return "0";
      }
      uint j = community;
      uint len;
      
      while (j != 0) {
         len++;
         j /= 10;
      }
      bytes memory heaven = new bytes(len);
      uint k = len - 1;
      
      while (community != 0) { // while loop
         heaven[k--] = byte(uint8(48 + community % 10));
         community /= 10;
      }
      return string(heaven);
   }

}