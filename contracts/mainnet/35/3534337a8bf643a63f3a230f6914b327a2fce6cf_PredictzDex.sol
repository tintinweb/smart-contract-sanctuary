/**
 *Submitted for verification at Etherscan.io on 2020-11-07
*/

pragma solidity 0.6.12;

// SPDX-License-Identifier: No License

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b >0 ) ;
    uint256 c = a / b;
    return c;
  }

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
 
library EnumerableSet {
   

    struct Set {
        bytes32[] _values;
        mapping (bytes32 => uint256) _indexes;
    }

    
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

     
    function _remove(Set storage set, bytes32 value) private returns (bool) {
      
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {  
             
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

         

            bytes32 lastvalue = set._values[lastIndex];

         
            set._values[toDeleteIndex] = lastvalue;
            
            set._indexes[lastvalue] = toDeleteIndex + 1; 
            
            set._values.pop();
 
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

 
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

  
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }
 

    struct AddressSet {
        Set _inner;
    }

    
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }

    
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

   
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }

   
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }


  
    struct UintSet {
        Set _inner;
    }

    
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

   
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

 
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

     
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }
 
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}


interface Token {
    function transferFrom(address, address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
}


contract PredictzDex is Ownable {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;
 
  
    
    

    /*
    swapOwners[i] = [
        0 => Swap ID,
        1 => Swap Owner,
        2 => Swap Token,
        3 => Swap Quanitiy,
        4 => Swap Deadline,
        5 => Swap Status, 0 => Pending, 1 => Received, 2 => Finished 
    ]
    */

  
  
     
    struct Swap {
        address owner;
        address token;
        uint256 quantity;
        uint256 balance;
        uint256 decimals;
        uint256 rate;
        uint256 deadline;
        uint256 status;   
        bool exists;    
    }
    

    mapping(uint256 => Swap)  swaps;
     
 
    uint256[] public swapOwners;

 
   function getAllSwaps() view public  returns (uint256[] memory){
       return swapOwners;
   }
    
    function swap(uint256 swapID , address token, uint256 quantity,uint256 rate , uint256 decimals , uint256 deadline) public returns (uint256)  {
        require(quantity > 0, "Cannot Swap with 0 Tokens");
        require(deadline > now, "Cannot Swap for before time");
        require(Token(token).transferFrom(msg.sender, address(this), quantity), "Insufficient Token Allowance");
        
        require(swaps[swapID].exists !=  true  , "Swap already Exists" );
        
        

        Swap storage newswap = swaps[swapID];
        newswap.owner =  msg.sender;
        newswap.token =  token; 
        newswap.quantity =  quantity ;
        newswap.balance =  quantity ;
        newswap.decimals =  decimals ;
        newswap.rate =  rate ;
        newswap.deadline =  deadline; 
        newswap.status =  0 ;
        newswap.exists =  true ;
         
        swapOwners.push(swapID) ;


    }
     


        function getSwap(uint256  _swapID ) view public returns (address , address , uint256,  uint256 , uint256 , uint256 , uint256  ) {
                    return (swaps[_swapID].owner , swaps[_swapID].token , swaps[_swapID].rate , swaps[_swapID].deadline , swaps[_swapID].quantity , swaps[_swapID].status , swaps[_swapID].balance   );
        }
    
      function getSwapDecimals(uint256  _swapID ) view public returns (uint256 ) {
                    return ( swaps[_swapID].decimals  );
        }
        
       function calculateFee(uint256  _swapID , uint256 tokenAmt ) view public returns ( uint256 , uint256 , uint256 ) {
                    return  (swaps[_swapID].balance , swaps[_swapID].deadline , swaps[_swapID].rate.mul(tokenAmt) );
        }
        
         function calculateToken(uint256  _swapID , uint256 bidamt ) view public returns ( uint256 ) {
                    return  (bidamt.div(swaps[_swapID].rate))  ;
        }
        
        function calculateRate(uint256  equivalentToken)  pure public returns ( uint256 ) {
                uint256 base = 1e18 ;
                return  (base.div(equivalentToken)) ;
        }
    
        function buy(uint256 amount, uint256 _swapID , uint256 tokenAmt) payable public {
           require(swaps[_swapID].balance >= tokenAmt, "Not Enough Tokens");
           require(swaps[_swapID].deadline > now, "Pool Expired");
           require(msg.value == amount);
           require(msg.value == swaps[_swapID].rate.mul(tokenAmt));
            
		   Swap storage singleswap = swaps[_swapID];
           
		   singleswap.balance = singleswap.balance.sub(tokenAmt.mul(singleswap.decimals)) ;

           transferAnyERC20Tokens(singleswap.token, msg.sender , tokenAmt.mul(singleswap.decimals) ); 
        
         }
         
           function withdraw() public onlyOwner{
                msg.sender.transfer(address(this).balance);
            }
    
    function transferAnyERC20Tokens(address _tokenAddr, address _to, uint256 _amount) private {
        Token(_tokenAddr).transfer(_to, _amount);
    }
    
        function OwnertransferAnyERC20Tokens(address _tokenAddr, address _to, uint256 _amount) public onlyOwner {
        
        Token(_tokenAddr).transfer(_to, _amount);
    }

}