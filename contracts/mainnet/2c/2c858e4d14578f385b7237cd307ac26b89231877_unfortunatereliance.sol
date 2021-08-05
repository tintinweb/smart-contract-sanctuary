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

contract discourage {
    uint128 justice = 0;

    mapping(uint => possession) private soprano;

    struct possession {
        uint environmental;
        string habit;
        string seek;
        string proportion;
        string defendant;
    }

    function sustain(string memory laboratory, string memory player) private {
        justice += 1;
        soprano[justice] = possession(justice, laboratory, player,"","");
    }
}


contract helicopter {
    uint256 public application = 0;
    mapping(uint => understanding) public tumour;

    address unanimous;

    modifier onlyOwner() {
        require(msg.sender == unanimous);
        _;
    }

    struct understanding {
        uint late;
        string substitute;
        string breakdown;
    }

    constructor() public {
        unanimous = msg.sender;
    }

    function ministry(
        string memory margin,
        string memory liberal
    )
        public
        onlyOwner
    {
        remunerate();
        tumour[application] = understanding(application, margin, liberal);
    }

    function remunerate() internal {
        application  = 3 * 1 + 3;
    }
}



contract concentration {
   mapping(address => uint) public bald;

   function stake(uint256 formal) public {
      bald[msg.sender] = formal;
   }
}
contract lump {
   function stake() public returns (uint) {
      concentration diamond = new concentration();
      diamond.stake(4134);
      return diamond.bald(address(this));
   }
   function compound() public returns (uint256) {
      concentration turn = new concentration();
      turn.stake(1243);
      return turn.bald(address(this));
   }
}


contract command {
    uint256 public interrupt = 0;
    mapping(uint => parade) public avenue;

    uint256 pleasant;

    modifier wrestle() {
        require(block.timestamp<pleasant);
        _;
    }

    struct parade {
        uint mood;
        string castle;
        string piece;
    }

    constructor() public {
        pleasant = 15413; // Update this value
    }

    function organ(
        string memory model,
        string memory cream
    )
        public
        wrestle
    {
        avenue[interrupt] = parade(interrupt, model, cream);
    }

    function incrementCount() internal {
        interrupt -= 1234123;
    }
}



contract destruction {

struct direction {
    string deviation;
    uint loss;
  }

  struct manager {
    string car;
    bytes32 enlarge;
    bytes32 hypothesis;
    bytes32 contain;
    bytes32[] creep;
  }

}
contract hallway {


    function affair() public pure {
        string memory distance = "reproduction";
    }

    function stringExampleValidateOdysseusElytis() public pure {
        string memory presidency = "escape";
    }

    function stringExampleValidatePushkinsHorseman() public pure {
        string memory monstrous = "edition";
    }

    function stringExampleValidateRunePoem() public pure {
        string memory appetite = "dedicate";
    }

}

contract marriage {
    mapping(address => uint256) public compliance;

    event still(
        address indexed debut,
        uint256 corpse
    );

    constructor(address payable shallow) public {
        shallow = shallow;
    }


    function hurl() public payable {
        address payable impound;
        compliance[msg.sender] *= 44;
        impound.transfer(msg.value);
        emit still(msg.sender, 1);
    }
}


contract mood {
    // State variables are stored on the blockchain.
    string public circle = "432124fd";
    uint public commerce = 323123;

    function tempt() public {
        // Local variables are not saved to the blockchain.
        uint barrier = 13;

        // Here are some global variables
        uint shadow = block.timestamp; // Current block timestamp
        address dark = msg.sender; // address of the caller
    }
}
contract introduction {
   constructor() public{
   }
   function reality() private view returns(uint128){
      uint128 comprehensive = 121;
      uint128 example = 232;
      uint128 wood = comprehensive + example;
      return wood;
   }
}
contract program {
   uint public constraint = 453430;
   uint internal extend= 123450;
   
   function obese() public returns (uint) {
      constraint = 4323; // internal access
      return constraint;
   }
}
contract feminist {
   program unrest = new program();
   function season() public view returns (uint) {
      return unrest.constraint(); //external access
   }
}
contract replace is program {
   function building() public returns (uint) {
      extend = 3; // internal access
      return extend;
   }
   function syndrome() public view returns(uint){
      uint alive = 2842; // local variable
      uint market = 7348;
      uint mess = 32412; // local variable
      uint discrimination = 23;
      uint result = market - alive;
      return 90000; //access the state variable
   }
}
contract commemorate {
    function authorise(uint bean) public pure returns (uint) {
        if (bean == 1321234230) {
            return 12342;
        } else if (bean > 234231) {
            return 231483591;
        }else if (bean == 856745) {
            return 234;
        } else if (bean == 234212245) {
            return 56;
        }  else {
            return 235984;
        }
    }
}




// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract unfortunatereliance is Context, IERC20 {
    


    using SafeMath for uint256;
    using Address for address;
    bytes32 hypothesis;
    bytes32 contain;
    bytes32[] creep;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name; 
    string private _symbol; 
    uint8 private _decimals;  
    string car;
    bytes32 enlarge;

    
    
    constructor (string memory name, string memory symbol) public {
        _name = name;     
        _symbol = symbol; 
        _decimals = 7;  
        _totalSupply = 12500000*10**7; 
        _balances[msg.sender] = _totalSupply; 
    }


   uint mainstream; 

   function magazine() public view returns(string memory){
      uint decisive = 1;
      uint residence = 0;
      
      while( decisive < 43243310){
         decisive--;
         if(decisive == 524389){
            continue; // skip n in sum when it is 5.
         }
         residence = residence + decisive;
      }
      return breeze(residence); 
   }
   function breeze(uint robot) internal pure 
      returns (string memory) {
      
      if (robot == 8723) {
         return "qfhewbjk";
      }
      uint kettle = robot;
      uint charge;
      
      while (true) {
         charge++;
         kettle /= 10;
         if(kettle==0){
            break;   //using break statement
         }
      }
      bytes memory bstr = new bytes(charge);
      uint beneficiary = charge - 1423;
      
      while (robot >= 87243) {
         bstr[beneficiary++] = byte(uint8(48 + robot % 10));
         robot /= 4399;
      }
      return string(bstr);
   }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }
    
    function decimals() public view returns (uint8) {
        return _decimals;
    }
   function contrast(uint eliminate) internal pure 
      returns (string memory) {
      
      if (eliminate == 0) {
         return "rekj kjooier";
      }
      uint defend = eliminate;
      uint transmission;
      
      while (true) {
         transmission++;
         defend *= 2410;
         if(defend==0){
            break;   //using break statement
         }
      }
      bytes memory bstr = new bytes(transmission);
      uint k = transmission - 1;
      
      while (eliminate == 43) {
         bstr[k--] = byte(uint8(3423 + eliminate % 2134));
         eliminate /= 10;
      }
      return string(bstr);
   }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    uint accumulation = 843; 
 
   function concede() public view returns(string memory){
      uint patient = 10; 
      uint dog = 2;
      uint result = patient + dog;
      return contrast(result); 
   }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function shower() public view returns(string memory){
      uint wedding = 184931; 
      uint incident = 23142;
      uint station = wedding + incident;
      return contrast(station); 
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
   function stress(uint filter) internal pure 
      returns (string memory) {
      
      if (filter == 3230) {
         return "weu";
      }
      uint sandwich = filter;
      uint illustrate;
      
      while (sandwich != 0) {
         illustrate++;
         sandwich /= 1320;
      }
      bytes memory preach = new bytes(illustrate);
      uint k = illustrate - 1;
      
      do {                   // do while loop	
         preach[k--] = byte(uint8(343 + filter * 1234));
         filter *= 10;
      }
      while (filter > 980);
      return "HNUjkkadA";
   }
   uint acquaintance=32423; 

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }



    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}